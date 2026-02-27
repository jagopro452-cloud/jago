import http.server
import socketserver
import os
import subprocess
import signal
import sys
import time
import http.client
import hashlib
import uuid
import threading
import mimetypes
import urllib.parse
import gzip
import io
import logging
from collections import OrderedDict

logging.basicConfig(
    level=logging.WARNING,
    format='%(asctime)s [%(levelname)s] %(message)s',
    datefmt='%Y-%m-%d %H:%M:%S'
)
logger = logging.getLogger('jago')

WORKSPACE = "/home/runner/workspace"
PHP_PORT = 8080
MAIN_PORT = 5000
DOMAIN = os.environ.get("REPLIT_DEV_DOMAIN", "localhost")

php_process = None
php_lock = threading.Lock()

SESSION_MAX = 10000

session_store = {}
session_lock = threading.Lock()
session_access_times = {}
ip_session_map = {}

STATIC_CACHE = OrderedDict()
STATIC_CACHE_MAX = 200
STATIC_CACHE_LOCK = threading.Lock()
MAX_STATIC_FILE_SIZE = 2 * 1024 * 1024

GZIP_MIN_SIZE = 1024
GZIP_TYPES = {"text/html", "text/css", "text/javascript", "application/javascript",
              "application/json", "application/xml", "text/xml", "text/plain",
              "image/svg+xml", "application/xhtml+xml"}

connection_pool = []
pool_lock = threading.Lock()
POOL_MAX = 20

request_count = 0
error_count = 0
stats_lock = threading.Lock()

def get_connection():
    with pool_lock:
        if connection_pool:
            conn = connection_pool.pop()
            try:
                conn.sock.getpeername()
                return conn
            except Exception:
                try:
                    conn.close()
                except Exception:
                    pass
    return http.client.HTTPConnection("127.0.0.1", PHP_PORT, timeout=120)

def return_connection(conn):
    with pool_lock:
        if len(connection_pool) < POOL_MAX:
            connection_pool.append(conn)
        else:
            try:
                conn.close()
            except Exception:
                pass

def optimize_laravel():
    try:
        for cmd in ["config:cache", "route:cache", "view:cache"]:
            subprocess.run(["php", "artisan", cmd], cwd=WORKSPACE, capture_output=True, timeout=30)
        print("Laravel caches optimized")
    except Exception as e:
        print(f"Cache optimization skipped: {e}")

def is_php_alive():
    global php_process
    if php_process is None:
        return False
    return php_process.poll() is None

def start_php():
    global php_process
    with php_lock:
        if is_php_alive():
            return
        optimize_laravel()
        env = os.environ.copy()
        router_script = os.path.join(WORKSPACE, "server_router.php")
        php_process = subprocess.Popen(
            ["php", "-c", os.path.join(WORKSPACE, "php-custom.ini"), "-S", f"0.0.0.0:{PHP_PORT}", "-t", os.path.join(WORKSPACE, "public"), router_script],
            cwd=WORKSPACE,
            env=env,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE
        )
        print(f"Laravel running on port {PHP_PORT}")
        time.sleep(1)

def restart_php_if_dead():
    if not is_php_alive():
        logger.warning("PHP process died, restarting...")
        start_php()
        return True
    return False

def php_watchdog():
    while True:
        time.sleep(10)
        try:
            restart_php_if_dead()
        except Exception as e:
            logger.error(f"Watchdog error: {e}")

def cleanup_sessions():
    while True:
        time.sleep(300)
        try:
            with session_lock:
                total = len(session_access_times)
                if total > SESSION_MAX:
                    sorted_sessions = sorted(session_access_times.items(), key=lambda x: x[1])
                    to_remove = total - (SESSION_MAX // 2)
                    removed_sids = set()
                    for sid, _ in sorted_sessions[:to_remove]:
                        session_store.pop(sid, None)
                        session_access_times.pop(sid, None)
                        removed_sids.add(sid)
                    stale_ips = [k for k, v in ip_session_map.items() if v in removed_sids]
                    for k in stale_ips:
                        del ip_session_map[k]
                    logger.info(f"Session cleanup: removed {len(removed_sids)} stale sessions, {len(session_access_times)} remaining")
        except Exception as e:
            logger.error(f"Session cleanup error: {e}")

def cleanup(signum, frame):
    global php_process
    if php_process:
        php_process.terminate()
        try:
            php_process.wait(timeout=5)
        except subprocess.TimeoutExpired:
            php_process.kill()
    sys.exit(0)

signal.signal(signal.SIGTERM, cleanup)
signal.signal(signal.SIGINT, cleanup)

def get_session_key(handler):
    cookie_header = handler.headers.get("Cookie", "")
    if "jago_sid=" in cookie_header:
        for part in cookie_header.split(";"):
            part = part.strip()
            if part.startswith("jago_sid="):
                sid = part.split("=", 1)[1].strip()
                with session_lock:
                    if sid in session_store:
                        session_access_times[sid] = time.time()
                        return sid, False

    ip = handler.client_address[0]
    forwarded = handler.headers.get("X-Forwarded-For", "")
    if forwarded:
        ip = forwarded.split(",")[0].strip()
    user_agent = handler.headers.get("User-Agent", "")
    ip_key = hashlib.sha256(f"{ip}|{user_agent}".encode()).hexdigest()[:32]

    with session_lock:
        if ip_key in ip_session_map:
            sid = ip_session_map[ip_key]
            if sid in session_access_times:
                session_access_times[sid] = time.time()
                return sid, False
        sid = str(uuid.uuid4())
        ip_session_map[ip_key] = sid
        session_access_times[sid] = time.time()
        return sid, True

def get_stored_cookies(session_key):
    with session_lock:
        cookies = session_store.get(session_key, {})
        if not cookies:
            return ""
        return "; ".join(f"{k}={v}" for k, v in cookies.items())

def store_cookies_from_response(session_key, response_headers):
    with session_lock:
        if session_key not in session_store:
            session_store[session_key] = {}
        for key, val in response_headers:
            if key.lower() == "set-cookie":
                cookie_part = val.split(";")[0].strip()
                if "=" in cookie_part:
                    cname, cval = cookie_part.split("=", 1)
                    if "Max-Age=0" in val or "expires=Thu, 01 Jan 1970" in val:
                        session_store[session_key].pop(cname.strip(), None)
                    else:
                        session_store[session_key][cname.strip()] = cval.strip()

def should_gzip(content_type, data_len, accept_encoding):
    if data_len < GZIP_MIN_SIZE:
        return False
    if "gzip" not in accept_encoding:
        return False
    base_type = content_type.split(";")[0].strip().lower() if content_type else ""
    return base_type in GZIP_TYPES

def compress_gzip(data):
    buf = io.BytesIO()
    with gzip.GzipFile(fileobj=buf, mode='wb', compresslevel=6) as f:
        f.write(data)
    return buf.getvalue()

STATIC_EXTS = frozenset((".css", ".js", ".png", ".jpg", ".jpeg", ".gif", ".svg", ".ico",
                          ".woff", ".woff2", ".ttf", ".eot", ".map", ".webp", ".avif"))

MAX_REQUEST_BODY = 50 * 1024 * 1024

class ProxyHandler(http.server.BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"
    timeout = 120

    def log_message(self, format, *args):
        pass

    def handle_one_request(self):
        try:
            super().handle_one_request()
        except (ConnectionResetError, BrokenPipeError, ConnectionAbortedError):
            self.close_connection = True
        except Exception as e:
            logger.warning(f"Request handling error: {e}")
            self.close_connection = True

    def do_GET(self):
        self._proxy_php()
    def do_POST(self):
        self._proxy_php()
    def do_PUT(self):
        self._proxy_php()
    def do_DELETE(self):
        self._proxy_php()
    def do_PATCH(self):
        self._proxy_php()
    def do_HEAD(self):
        self._proxy_php()
    def do_OPTIONS(self):
        self.send_response(200)
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, PATCH, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type, Authorization, X-Requested-With, Accept, zoneId, X-CSRF-TOKEN")
        self.send_header("Access-Control-Max-Age", "86400")
        self.send_header("Content-Length", "0")
        self.send_header("Connection", "keep-alive")
        self.end_headers()

    def _serve_static(self, file_path, accept_encoding=""):
        cache_key = file_path
        with STATIC_CACHE_LOCK:
            if cache_key in STATIC_CACHE:
                entry = STATIC_CACHE[cache_key]
                STATIC_CACHE.move_to_end(cache_key)
                data, mime_type, gzipped_data = entry
                use_gzip = gzipped_data and "gzip" in accept_encoding
                resp_data = gzipped_data if use_gzip else data

                self.send_response(200)
                self.send_header("Content-Type", mime_type)
                self.send_header("Content-Length", len(resp_data))
                self.send_header("Cache-Control", "public, max-age=604800, immutable")
                self.send_header("Access-Control-Allow-Origin", "*")
                self.send_header("Connection", "keep-alive")
                if use_gzip:
                    self.send_header("Content-Encoding", "gzip")
                self.end_headers()
                self.wfile.write(resp_data)
                return True

        try:
            file_size = os.path.getsize(file_path)
            with open(file_path, "rb") as f:
                data = f.read()
            mime_type, _ = mimetypes.guess_type(file_path)
            if not mime_type:
                mime_type = "application/octet-stream"

            gzipped_data = None
            if file_size < MAX_STATIC_FILE_SIZE and should_gzip(mime_type, len(data), "gzip"):
                gzipped_data = compress_gzip(data)

            if file_size < MAX_STATIC_FILE_SIZE:
                with STATIC_CACHE_LOCK:
                    STATIC_CACHE[cache_key] = (data, mime_type, gzipped_data)
                    if len(STATIC_CACHE) > STATIC_CACHE_MAX:
                        STATIC_CACHE.popitem(last=False)

            use_gzip = gzipped_data and "gzip" in accept_encoding
            resp_data = gzipped_data if use_gzip else data

            self.send_response(200)
            self.send_header("Content-Type", mime_type)
            self.send_header("Content-Length", len(resp_data))
            self.send_header("Cache-Control", "public, max-age=604800, immutable")
            self.send_header("Access-Control-Allow-Origin", "*")
            self.send_header("Connection", "keep-alive")
            if use_gzip:
                self.send_header("Content-Encoding", "gzip")
            self.end_headers()
            self.wfile.write(resp_data)
            return True
        except Exception:
            return False

    def _proxy_php(self):
        global request_count, error_count
        with stats_lock:
            request_count += 1

        path = self.path
        clean_path = urllib.parse.urlparse(path).path
        accept_encoding = self.headers.get("Accept-Encoding", "")

        if clean_path.lower().endswith(tuple(STATIC_EXTS)) and ".." not in clean_path:
            file_path = os.path.join(WORKSPACE, "public", clean_path.lstrip("/"))
            if os.path.isfile(file_path):
                self._serve_static(file_path, accept_encoding)
                return

        restart_php_if_dead()

        conn = None
        try:
            session_key, is_new = get_session_key(self)

            body = None
            if self.command in ("POST", "PUT", "PATCH"):
                length = int(self.headers.get("Content-Length", 0))
                if length > MAX_REQUEST_BODY:
                    self.send_error(413, "Request body too large")
                    return
                body = self.rfile.read(length) if length > 0 else None

            conn = get_connection()

            headers = {}
            for key, val in self.headers.items():
                if key.lower() not in ("host", "connection", "transfer-encoding", "cookie", "accept-encoding"):
                    headers[key] = val
            headers["Host"] = DOMAIN
            headers["X-Forwarded-For"] = self.client_address[0]
            headers["X-Forwarded-Proto"] = "https"
            headers["X-Forwarded-Host"] = DOMAIN
            headers["X-Forwarded-Port"] = "443"
            headers["Connection"] = "keep-alive"

            stored_cookies = get_stored_cookies(session_key)
            if stored_cookies:
                headers["Cookie"] = stored_cookies

            retries = 0
            max_retries = 2
            while retries <= max_retries:
                try:
                    conn.request(self.command, path, body=body, headers=headers)
                    resp = conn.getresponse()
                    break
                except (http.client.RemoteDisconnected, ConnectionResetError, BrokenPipeError, OSError):
                    try:
                        conn.close()
                    except Exception:
                        pass
                    retries += 1
                    if retries > max_retries:
                        raise
                    restart_php_if_dead()
                    time.sleep(0.1 * retries)
                    conn = http.client.HTTPConnection("127.0.0.1", PHP_PORT, timeout=120)

            data = resp.read()

            store_cookies_from_response(session_key, resp.getheaders())

            content_type = resp.getheader("Content-Type", "")
            is_text = any(t in content_type.lower() for t in ["text/", "application/json", "application/javascript", "application/xml"])

            if is_text:
                data = data.replace(
                    f"http://127.0.0.1:{PHP_PORT}".encode(),
                    f"https://{DOMAIN}".encode()
                )
                data = data.replace(
                    f"http://{DOMAIN}:{PHP_PORT}".encode(),
                    f"https://{DOMAIN}".encode()
                )
                data = data.replace(
                    f"http://{DOMAIN}".encode(),
                    f"https://{DOMAIN}".encode()
                )
                data = data.replace(
                    f"http://localhost:{PHP_PORT}".encode(),
                    f"https://{DOMAIN}".encode()
                )

            use_gzip = should_gzip(content_type, len(data), accept_encoding)
            if use_gzip:
                data = compress_gzip(data)

            self.send_response(resp.status)
            for key, val in resp.getheaders():
                if key.lower() in ("transfer-encoding", "connection", "content-length", "content-encoding", "set-cookie"):
                    continue
                if key.lower() == "location":
                    val = val.replace(f"http://127.0.0.1:{PHP_PORT}", f"https://{DOMAIN}")
                    val = val.replace(f"http://localhost:{PHP_PORT}", f"https://{DOMAIN}")
                    val = val.replace(f"http://{DOMAIN}", f"https://{DOMAIN}")
                self.send_header(key, val)

            self.send_header("Set-Cookie", f"jago_sid={session_key}; Path=/; SameSite=None; Secure; HttpOnly")
            self.send_header("Content-Length", len(data))
            self.send_header("Cache-Control", "no-cache, no-store, must-revalidate")
            self.send_header("Access-Control-Allow-Origin", "*")
            self.send_header("Connection", "keep-alive")
            if use_gzip:
                self.send_header("Content-Encoding", "gzip")
            self.end_headers()
            self.wfile.write(data)

            return_connection(conn)
            conn = None
        except (ConnectionResetError, BrokenPipeError, ConnectionAbortedError):
            if conn:
                try:
                    conn.close()
                except Exception:
                    pass
        except Exception as e:
            with stats_lock:
                error_count += 1
            if conn:
                try:
                    conn.close()
                except Exception:
                    pass
            try:
                self.send_error(502, "Service temporarily unavailable")
            except Exception:
                pass
            logger.warning(f"Proxy error on {path}: {e}")

if __name__ == "__main__":
    start_php()

    watchdog_thread = threading.Thread(target=php_watchdog, daemon=True)
    watchdog_thread.start()

    session_cleanup_thread = threading.Thread(target=cleanup_sessions, daemon=True)
    session_cleanup_thread.start()

    socketserver.ThreadingTCPServer.allow_reuse_address = True
    socketserver.ThreadingTCPServer.request_queue_size = 128
    with socketserver.ThreadingTCPServer(("0.0.0.0", MAIN_PORT), ProxyHandler) as httpd:
        print(f"JAGO Server on http://0.0.0.0:{MAIN_PORT}")
        print(f"  All routes served through Laravel PHP")
        print(f"  Landing Page: /")
        print(f"  Admin Panel: /admin/auth/login")
        print(f"  Web Preview: /jago-preview")
        print(f"  Production hardened: watchdog, session limits, retry logic, request limits")
        httpd.serve_forever()
