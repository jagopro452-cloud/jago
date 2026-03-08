// Must be set before any DB or TLS connections are made
if (process.env.NODE_ENV !== "test") {
  process.env.NODE_TLS_REJECT_UNAUTHORIZED = "0";
}

import express, { type Request, Response, NextFunction } from "express";
import { registerRoutes } from "./routes";
import { serveStatic } from "./static";
import { createServer } from "http";
import { setupSocket } from "./socket";
import { parseEnv, validateProductionReadiness } from "./config/env";
import { makeErrorId, sendAlert } from "./observability";

const env = parseEnv();
validateProductionReadiness(env);

const app = express();
app.set("trust proxy", 1);
const httpServer = createServer(app);

declare module "http" {
  interface IncomingMessage {
    rawBody: unknown;
  }
}

app.use(
  express.json({
    verify: (req, _res, buf) => {
      req.rawBody = buf;
    },
  }),
);

app.use(express.urlencoded({ extended: false }));

export function log(message: string, source = "express") {
  const formattedTime = new Date().toLocaleTimeString("en-US", {
    hour: "numeric",
    minute: "2-digit",
    second: "2-digit",
    hour12: true,
  });

  console.log(`${formattedTime} [${source}] ${message}`);
}

// Security headers
app.use((_req, res, next) => {
  res.setHeader("X-Content-Type-Options", "nosniff");
  res.setHeader("X-Frame-Options", "SAMEORIGIN");
  res.setHeader("X-XSS-Protection", "1; mode=block");
  res.setHeader("Referrer-Policy", "strict-origin-when-cross-origin");
  next();
});

app.use((req, res, next) => {
  const start = Date.now();
  const path = req.path;
  let capturedJsonResponse: Record<string, any> | undefined = undefined;

  const originalResJson = res.json;
  res.json = function (bodyJson, ...args) {
    capturedJsonResponse = bodyJson;
    return originalResJson.apply(res, [bodyJson, ...args]);
  };

  res.on("finish", () => {
    const duration = Date.now() - start;
    if (path.startsWith("/api")) {
      let logLine = `${req.method} ${path} ${res.statusCode} in ${duration}ms`;
      if (capturedJsonResponse) {
        const sanitized = { ...capturedJsonResponse };
        if (sanitized.otp !== undefined) sanitized.otp = "[REDACTED]";
        if (sanitized.password !== undefined) sanitized.password = "[REDACTED]";
        if (sanitized.token !== undefined) sanitized.token = "[REDACTED]";
        if (sanitized.sessionToken !== undefined) sanitized.sessionToken = "[REDACTED]";
        logLine += ` :: ${JSON.stringify(sanitized)}`;
      }

      log(logLine);
    }
  });

  next();
});

(async () => {
  // Initialize Socket.IO for real-time driver-customer communication
  setupSocket(httpServer);

  await registerRoutes(httpServer, app);

  app.use((err: any, _req: Request, res: Response, next: NextFunction) => {
    const status = err.status || err.statusCode || 500;
    const message = err.message || "Internal Server Error";
    const errorId = makeErrorId();

    console.error(`Internal Server Error [${errorId}]:`, err);
    sendAlert({
      level: status >= 500 ? "critical" : "error",
      source: "express",
      message: `Request failed with status ${status} (${errorId})`,
      details: typeof err?.stack === "string" ? err.stack : String(err?.message || err),
    }).catch(() => {});

    if (res.headersSent) {
      return next(err);
    }

    return res.status(status).json({ message, errorId });
  });

  // importantly only setup vite in development and after
  // setting up all the other routes so the catch-all route
  // doesn't interfere with the other routes
  if (process.env.NODE_ENV === "production") {
    serveStatic(app);
  } else {
    const { setupVite } = await import("./vite");
    await setupVite(httpServer, app);
  }

  // ALWAYS serve the app on the port specified in the environment variable PORT
  // Other ports are firewalled. Default to 5000 if not specified.
  // this serves both the API and the client.
  // It is the only port that is not firewalled.
  const port = parseInt(process.env.PORT || "5000", 10);
  httpServer.listen(port, "0.0.0.0", () => {
    log(`serving on port ${port}`);
  });

  process.on("unhandledRejection", (reason: any) => {
    const errorId = makeErrorId();
    console.error(`[unhandledRejection] [${errorId}]`, reason);
    sendAlert({
      level: "critical",
      source: "process",
      message: `Unhandled promise rejection (${errorId})`,
      details: String(reason?.stack || reason),
    }).catch(() => {});
  });

  process.on("uncaughtException", (err: any) => {
    const errorId = makeErrorId();
    console.error(`[uncaughtException] [${errorId}]`, err);
    sendAlert({
      level: "critical",
      source: "process",
      message: `Uncaught exception (${errorId})`,
      details: String(err?.stack || err),
    }).catch(() => {});
  });
})();
