import { useState, useEffect } from "react";
import { useLocation } from "wouter";

function useAdminBootstrap() {
  useEffect(() => {
    const cssFiles = [
      { id: "admin-bootstrap-icons-css", href: "/admin-module/css/bootstrap-icons.min.css" },
      { id: "admin-bootstrap-css", href: "/admin-module/css/bootstrap.min.css" },
    ];
    const added: HTMLLinkElement[] = [];
    cssFiles.forEach(({ id, href }) => {
      let link = document.getElementById(id) as HTMLLinkElement | null;
      if (!link) {
        link = document.createElement("link");
        link.rel = "stylesheet";
        link.href = href;
        link.id = id;
        document.head.appendChild(link);
        added.push(link);
      }
    });
    return () => {
      added.forEach(el => el.remove());
      cssFiles.forEach(({ id }) => {
        const el = document.getElementById(id);
        if (el) el.remove();
      });
    };
  }, []);
}

const STATS = [
  { icon: "🏍️", value: "1,240+", label: "Active Drivers" },
  { icon: "🚗", value: "8,500+", label: "Trips Today" },
  { icon: "🌆", value: "12", label: "Cities Covered" },
];

const FEATURES = [
  { icon: "bi-geo-alt-fill", label: "Real-time GPS fleet tracking" },
  { icon: "bi-shield-fill-check", label: "Secure pilot verification & KYC" },
  { icon: "bi-graph-up-arrow", label: "Live revenue & analytics dashboard" },
  { icon: "bi-bell-fill", label: "Smart alerts & surge pricing" },
];

function genCaptcha() {
  const a = Math.floor(Math.random() * 9) + 1;
  const b = Math.floor(Math.random() * 9) + 1;
  return { a, b, ans: a + b };
}

export default function AdminLogin() {
  useAdminBootstrap();
  const [, setLocation] = useLocation();
  const [email, setEmail] = useState("admin@admin.com");
  const [password, setPassword] = useState("admin123");
  const [showPassword, setShowPassword] = useState(false);
  const [remember, setRemember] = useState(false);
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);
  const [mounted, setMounted] = useState(false);
  const [captcha, setCaptcha] = useState(genCaptcha);
  const [captchaVal, setCaptchaVal] = useState("");
  const [captchaErr, setCaptchaErr] = useState(false);

  useEffect(() => {
    setMounted(true);
    const saved = localStorage.getItem("jago-admin");
    if (saved) setLocation("/admin/dashboard");
  }, []);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError("");
    if (parseInt(captchaVal) !== captcha.ans) {
      setCaptchaErr(true);
      setCaptcha(genCaptcha());
      setCaptchaVal("");
      return;
    }
    setCaptchaErr(false);
    setLoading(true);
    try {
      const res = await fetch("/api/admin/login", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ email, password }),
      });
      const data = await res.json();
      if (res.ok) {
        localStorage.setItem("jago-admin", JSON.stringify(data.admin || data));
        setLocation("/admin/dashboard");
      } else {
        setError(data.message || "Invalid credentials. Please try again.");
      }
    } catch {
      setError("Connection error. Please check your network and try again.");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="jl-root" data-testid="login-page">

      {/* ── LEFT — Brand Panel ── */}
      <div className="jl-brand">
        {/* Animated orbs */}
        <div className="jl-orb jl-orb-1"></div>
        <div className="jl-orb jl-orb-2"></div>
        <div className="jl-orb jl-orb-3"></div>

        <div className="jl-brand-inner">
          {/* Logo */}
          <div className="jl-logo-wrap">
            <img src="/jago-logo.png" alt="JAGO" className="jl-logo" data-testid="brand-logo" />
            <span className="jl-logo-tag">Admin Console</span>
          </div>

          {/* Headline */}
          <h2 className="jl-headline">
            Power your city's<br />
            <span className="jl-headline-accent">mobility network</span>
          </h2>
          <p className="jl-sub">Complete ride & parcel management platform for operators across India.</p>

          {/* Live stat chips */}
          <div className="jl-stats">
            {STATS.map((s, i) => (
              <div key={i} className={`jl-stat ${mounted ? "jl-stat-in" : ""}`} style={{ animationDelay: `${i * 0.12}s` }}>
                <span className="jl-stat-icon">{s.icon}</span>
                <div>
                  <div className="jl-stat-val">{s.value}</div>
                  <div className="jl-stat-lbl">{s.label}</div>
                </div>
              </div>
            ))}
          </div>

          {/* Feature list */}
          <div className="jl-features">
            {FEATURES.map((f, i) => (
              <div key={i} className="jl-feat">
                <div className="jl-feat-icon"><i className={`bi ${f.icon}`}></i></div>
                <span>{f.label}</span>
              </div>
            ))}
          </div>

          {/* Floating live badge */}
          <div className="jl-live-badge">
            <span className="jl-live-dot"></span>
            Live platform — updated in real time
          </div>
        </div>
      </div>

      {/* ── RIGHT — Form Panel ── */}
      <div className="jl-form-panel">
        <div className="jl-form-card" data-testid="login-form-card">

          {/* Top mark */}
          <div className="jl-form-logo-row">
            <div className="jl-form-logo-circle">
              <i className="bi bi-shield-lock-fill"></i>
            </div>
            <div>
              <div className="jl-form-logo-title">JAGO Admin</div>
              <div className="jl-form-logo-sub">Secure access portal</div>
            </div>
          </div>

          <h1 className="jl-form-title">Welcome back</h1>
          <p className="jl-form-subtitle">Sign in to manage your platform</p>

          {error && (
            <div className="jl-alert" data-testid="login-error">
              <i className="bi bi-exclamation-triangle-fill"></i> {error}
            </div>
          )}

          <form onSubmit={handleSubmit}>
            <div className="jl-field">
              <label className="jl-label">Email Address</label>
              <div className="jl-input-wrap">
                <span className="jl-input-icon"><i className="bi bi-envelope"></i></span>
                <input
                  type="email"
                  className="jl-input"
                  placeholder="you@company.com"
                  value={email}
                  onChange={e => setEmail(e.target.value)}
                  required
                  data-testid="input-email"
                />
              </div>
            </div>

            <div className="jl-field">
              <label className="jl-label">Password</label>
              <div className="jl-input-wrap">
                <span className="jl-input-icon"><i className="bi bi-lock"></i></span>
                <input
                  type={showPassword ? "text" : "password"}
                  className="jl-input"
                  placeholder="Enter your password"
                  value={password}
                  onChange={e => setPassword(e.target.value)}
                  required
                  data-testid="input-password"
                />
                <button
                  type="button"
                  className="jl-eye-btn"
                  onClick={() => setShowPassword(!showPassword)}
                  data-testid="btn-toggle-password"
                >
                  <i className={`bi ${showPassword ? "bi-eye-fill" : "bi-eye-slash-fill"}`}></i>
                </button>
              </div>
            </div>

            {/* Math Captcha */}
            <div className="jl-field">
              <label className="jl-label">Security Check</label>
              <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
                <div style={{
                  background: "linear-gradient(135deg, #1e3a5f 0%, #0f3460 100%)",
                  color: "#60a5fa", fontFamily: "monospace", fontSize: 18, fontWeight: 800,
                  padding: "10px 18px", borderRadius: 10, letterSpacing: 2, flexShrink: 0,
                  border: "1px solid rgba(96,165,250,0.25)", userSelect: "none",
                }}>
                  {captcha.a} + {captcha.b} = ?
                </div>
                <div className="jl-input-wrap" style={{ flex: 1 }}>
                  <span className="jl-input-icon"><i className="bi bi-shield-check"></i></span>
                  <input
                    type="number"
                    className="jl-input"
                    placeholder="Answer"
                    value={captchaVal}
                    onChange={e => { setCaptchaVal(e.target.value); setCaptchaErr(false); }}
                    required
                    data-testid="input-captcha"
                    style={captchaErr ? { borderColor: "#ef4444" } : {}}
                  />
                </div>
                <button type="button" onClick={() => { setCaptcha(genCaptcha()); setCaptchaVal(""); setCaptchaErr(false); }}
                  style={{ background: "none", border: "1px solid #e2e8f0", borderRadius: 8, padding: "8px 10px", cursor: "pointer", color: "#64748b", flexShrink: 0 }}
                  title="Refresh captcha">
                  <i className="bi bi-arrow-clockwise"></i>
                </button>
              </div>
              {captchaErr && <div style={{ color: "#ef4444", fontSize: 12, marginTop: 4 }}>Incorrect answer. Try again.</div>}
            </div>

            <div className="jl-row">
              <label className="jl-check-label">
                <input type="checkbox" checked={remember} onChange={e => setRemember(e.target.checked)} data-testid="input-remember" />
                <span>Remember me</span>
              </label>
            </div>

            <button className={`jl-btn${loading ? " jl-btn-loading" : ""}`} type="submit" disabled={loading} data-testid="btn-login">
              {loading
                ? <><span className="jl-spinner"></span>Signing in…</>
                : <><i className="bi bi-box-arrow-in-right me-2"></i>Sign In to Dashboard</>
              }
            </button>
          </form>

          <div className="jl-demo-box">
            <div className="jl-demo-title"><i className="bi bi-info-circle me-1"></i>Demo Credentials</div>
            <div className="jl-demo-row"><span>Email:</span><code>admin@admin.com</code></div>
            <div className="jl-demo-row"><span>Password:</span><code>admin123</code></div>
          </div>
        </div>

        <div className="jl-footer">© 2025 JAGO Mobility Pvt. Ltd. · All rights reserved</div>
      </div>
    </div>
  );
}
