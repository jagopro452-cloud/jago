import { useState } from "react";
import { useLocation } from "wouter";

export default function AdminLogin() {
  const [, setLocation] = useLocation();
  const [email, setEmail] = useState("admin@jago.com");
  const [password, setPassword] = useState("admin123");
  const [showPassword, setShowPassword] = useState(false);
  const [loading, setLoading] = useState(false);

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    try {
      const res = await fetch("/api/admin/login", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ email, password }),
      });
      if (res.ok) {
        const data = await res.json();
        localStorage.setItem("jago-admin", JSON.stringify(data.admin));
        setLocation("/admin/dashboard");
      } else {
        localStorage.setItem("jago-admin", JSON.stringify({ name: "Admin", email, role: "superadmin" }));
        setLocation("/admin/dashboard");
      }
    } catch {
      localStorage.setItem("jago-admin", JSON.stringify({ name: "Admin", email, role: "superadmin" }));
      setLocation("/admin/dashboard");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="jago-login-bg">
      <div className="jago-login-card">
        {/* Logo */}
        <div className="jago-login-logo">
          <div className="logo-icon">
            <i className="bi bi-car-front-fill"></i>
          </div>
          <h2>JAGO Admin Panel</h2>
          <p>Sign in to manage your ride-sharing platform</p>
        </div>

        {/* Form */}
        <form onSubmit={handleLogin}>
          {/* Email */}
          <div className="jago-login-input-group">
            <label htmlFor="email">Email Address</label>
            <i className="bi bi-envelope-fill input-icon"></i>
            <input
              id="email"
              type="email"
              value={email}
              onChange={e => setEmail(e.target.value)}
              placeholder="admin@jago.com"
              required
              data-testid="input-email"
            />
          </div>

          {/* Password */}
          <div className="jago-login-input-group">
            <label htmlFor="password">Password</label>
            <i className="bi bi-lock-fill input-icon"></i>
            <input
              id="password"
              type={showPassword ? "text" : "password"}
              value={password}
              onChange={e => setPassword(e.target.value)}
              placeholder="Enter your password"
              required
              data-testid="input-password"
              style={{ paddingRight: "2.5rem" }}
            />
            <button
              type="button"
              className="show-pw"
              onClick={() => setShowPassword(!showPassword)}
              data-testid="btn-toggle-password"
            >
              <i className={`bi ${showPassword ? "bi-eye-slash-fill" : "bi-eye-fill"}`}></i>
            </button>
          </div>

          <button
            type="submit"
            className="btn-login"
            disabled={loading}
            data-testid="btn-login"
          >
            {loading ? (
              <>
                <i className="bi bi-arrow-repeat" style={{ animation: "spin 1s linear infinite" }}></i>
                Signing in...
              </>
            ) : (
              <>
                <i className="bi bi-box-arrow-in-right"></i>
                Sign In to Dashboard
              </>
            )}
          </button>
        </form>

        <p style={{ textAlign: "center", fontSize: "0.78rem", color: "var(--bs-body-color)", marginTop: "1rem" }}>
          Demo: <strong>admin@jago.com</strong> / any password
        </p>
      </div>

      <style>{`
        @keyframes spin { from { transform: rotate(0deg); } to { transform: rotate(360deg); } }
      `}</style>
    </div>
  );
}
