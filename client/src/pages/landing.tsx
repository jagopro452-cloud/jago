import { useEffect, useMemo, useState } from "react";
import { useTheme } from "@/components/theme-provider";

const jagoLogoWhite = "/jago-logo-white.png";
const jagoLogoBlue = "/jago-logo-blue.png";
const pilotLogo = "/pilot-logo.png";

function useReveal() {
  useEffect(() => {
    const observer = new IntersectionObserver(
      entries => {
        entries.forEach(entry => {
          if (entry.isIntersecting) {
            entry.target.classList.add("revealed");
            observer.unobserve(entry.target);
          }
        });
      },
      { threshold: 0.14 }
    );

    document.querySelectorAll(".reveal").forEach(el => observer.observe(el));
    return () => observer.disconnect();
  }, []);
}

type CardItem = {
  icon: string;
  title: string;
  desc: string;
};

export default function LandingPage() {
  const [menuOpen, setMenuOpen] = useState(false);
  const [scrolled, setScrolled] = useState(false);
  const { theme, setTheme } = useTheme();
  const isDark = theme === "dark";
  useReveal();

  const nav = [
    { label: "Rides", href: "#solutions" },
    { label: "Parcels", href: "#solutions" },
    { label: "Cities", href: "#cities" },
    { label: "Drive with Us", href: "#driver" },
    { label: "About", href: "/about-us" },
  ];

  useEffect(() => {
    const onScroll = () => setScrolled(window.scrollY > 12);
    window.addEventListener("scroll", onScroll);
    return () => window.removeEventListener("scroll", onScroll);
  }, []);

  const tokens = useMemo(
    () => ({
      bg: isDark
        ? "radial-gradient(1000px 700px at 80% -10%, rgba(58,124,255,0.2), transparent 60%), radial-gradient(900px 640px at 0% 110%, rgba(15,152,120,0.15), transparent 60%), #050a18"
        : "radial-gradient(900px 520px at 90% -10%, rgba(24,96,255,0.16), transparent 60%), radial-gradient(850px 560px at 0% 100%, rgba(4,161,123,0.14), transparent 60%), #f6f9ff",
      panel: isDark ? "rgba(13, 23, 46, 0.72)" : "rgba(255, 255, 255, 0.9)",
      panelStrong: isDark ? "#0f1c38" : "#ffffff",
      border: isDark ? "rgba(167, 196, 255, 0.2)" : "rgba(29, 78, 216, 0.15)",
      text: isDark ? "#f3f7ff" : "#0e1d3a",
      textSoft: isDark ? "rgba(236, 242, 255, 0.72)" : "#4e6487",
      accent: isDark ? "#7cb2ff" : "#1f5fe4",
      accentAlt: isDark ? "#36d0a4" : "#0ea977",
      navBg: scrolled
        ? isDark
          ? "rgba(4, 10, 24, 0.84)"
          : "rgba(246, 250, 255, 0.92)"
        : "transparent",
      navBorder: scrolled
        ? isDark
          ? "1px solid rgba(167,196,255,0.15)"
          : "1px solid rgba(29,78,216,0.12)"
        : "1px solid transparent",
      heroCard: isDark
        ? "linear-gradient(150deg, rgba(17,31,62,0.95), rgba(11,21,43,0.92))"
        : "linear-gradient(150deg, rgba(255,255,255,0.98), rgba(242,249,255,0.95))",
      glow: isDark ? "rgba(76, 145, 255, 0.35)" : "rgba(46, 115, 255, 0.2)",
      strip: isDark ? "#08112a" : "#e9f1ff",
      footer: isDark ? "#040a18" : "#eaf2ff",
    }),
    [isDark, scrolled]
  );

  const featureCards: CardItem[] = [
    {
      icon: "AI",
      title: "AI Voice Booking",
      desc: "Talk naturally in your language and get matched to the best ride flow instantly.",
    },
    {
      icon: "4X",
      title: "4 Service Models",
      desc: "Bike, auto, intercity share, and goods delivery inside one consistent journey.",
    },
    {
      icon: "ADM",
      title: "Super Admin Control",
      desc: "Live demand heatmaps, fleet status, and incident command center for operations teams.",
    },
  ];

  return (
    <div
      style={{
        fontFamily: "'Space Grotesk', 'Plus Jakarta Sans', 'Segoe UI', sans-serif",
        background: tokens.bg,
        color: tokens.text,
        minHeight: "100vh",
      }}
    >
      <style>{`
        @import url('https://fonts.googleapis.com/css2?family=Space+Grotesk:wght@500;600;700&family=Plus+Jakarta+Sans:wght@400;500;600;700;800&display=swap');
        * { box-sizing: border-box; }
        html, body { margin: 0; padding: 0; scroll-behavior: smooth; }
        a { color: inherit; text-decoration: none; }
        .reveal { opacity: 0; transform: translateY(24px); transition: opacity .6s ease, transform .6s ease; }
        .reveal.revealed { opacity: 1; transform: translateY(0); }
        .g1 { transition-delay: .06s; }
        .g2 { transition-delay: .12s; }
        .g3 { transition-delay: .18s; }
        .hero-grid { display: grid; grid-template-columns: 1.08fr .92fr; gap: 30px; align-items: center; }
        .feature-grid { display: grid; grid-template-columns: repeat(3, 1fr); gap: 16px; }
        .duo-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 18px; }
        .ecosystem-grid { display: grid; grid-template-columns: repeat(4, 1fr); gap: 16px; }
        .top-nav { display: flex; align-items: center; gap: 18px; }
        .section { padding: 82px 0; }
        .btn-raise { transition: transform .2s ease, box-shadow .2s ease; }
        .btn-raise:hover { transform: translateY(-2px); }
        @media (max-width: 980px) {
          .top-nav { display: none; }
          .hero-grid { grid-template-columns: 1fr; }
          .feature-grid { grid-template-columns: 1fr; }
          .duo-grid { grid-template-columns: 1fr; }
          .ecosystem-grid { grid-template-columns: 1fr 1fr; }
          .section { padding: 64px 0; }
        }
        @media (max-width: 640px) {
          .ecosystem-grid { grid-template-columns: 1fr; }
        }
      `}</style>

      <nav
        style={{
          position: "fixed",
          top: 0,
          left: 0,
          right: 0,
          zIndex: 30,
          backdropFilter: scrolled ? "blur(14px)" : "none",
          background: tokens.navBg,
          borderBottom: tokens.navBorder,
          transition: "all .25s ease",
        }}
      >
        <div
          style={{
            maxWidth: 1180,
            margin: "0 auto",
            padding: "14px 20px",
            display: "flex",
            alignItems: "center",
            justifyContent: "space-between",
          }}
        >
          <a href="/" style={{ display: "flex", alignItems: "center", gap: 10 }}>
            <img
              src={isDark ? jagoLogoWhite : jagoLogoBlue}
              alt="JAGO"
              style={{ height: 38, objectFit: "contain" }}
            />
          </a>

          <div className="top-nav">
            {nav.map(item => (
              <a key={item.label} href={item.href} style={{ fontSize: 13, fontWeight: 700, color: tokens.textSoft }}>
                {item.label}
              </a>
            ))}
          </div>

          <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
            <button
              onClick={() => setTheme(isDark ? "light" : "dark")}
              style={{
                border: `1px solid ${tokens.border}`,
                background: tokens.panel,
                color: tokens.text,
                borderRadius: 12,
                padding: "8px 12px",
                fontSize: 13,
                fontWeight: 700,
                cursor: "pointer",
              }}
            >
              {isDark ? "Light Mode" : "Dark Mode"}
            </button>
            <button
              aria-label="Toggle Menu"
              onClick={() => setMenuOpen(v => !v)}
              style={{
                border: `1px solid ${tokens.border}`,
                background: tokens.panel,
                color: tokens.text,
                borderRadius: 12,
                padding: "8px 12px",
                fontSize: 13,
                fontWeight: 700,
                cursor: "pointer",
              }}
            >
              Menu
            </button>
          </div>
        </div>
      </nav>

      {menuOpen && (
        <div
          onClick={() => setMenuOpen(false)}
          style={{
            position: "fixed",
            inset: 0,
            zIndex: 25,
            background: isDark ? "rgba(5,11,25,0.82)" : "rgba(237,244,255,0.82)",
            backdropFilter: "blur(10px)",
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
          }}
        >
          <div
            style={{
              width: "min(92vw, 440px)",
              borderRadius: 22,
              padding: 24,
              background: tokens.panelStrong,
              border: `1px solid ${tokens.border}`,
            }}
          >
            {nav.map((item, i) => (
              <a
                key={item.href + item.label}
                href={item.href}
                style={{
                  display: "block",
                  fontSize: 18,
                  fontWeight: 700,
                  padding: "12px 6px",
                  color: tokens.text,
                  borderBottom: i < nav.length - 1 ? `1px solid ${tokens.border}` : "none",
                }}
              >
                {item.label}
              </a>
            ))}
          </div>
        </div>
      )}

      <section className="section" style={{ paddingTop: 120 }}>
        <div style={{ maxWidth: 1180, margin: "0 auto", padding: "0 20px" }}>
          <div className="hero-grid">
            <div className="reveal g1">
              <div
                style={{
                  display: "inline-flex",
                  alignItems: "center",
                  gap: 8,
                  border: `1px solid ${tokens.border}`,
                  borderRadius: 999,
                  padding: "7px 14px",
                  background: tokens.panel,
                  marginBottom: 18,
                  fontSize: 12,
                  fontWeight: 700,
                  color: tokens.textSoft,
                }}
              >
                Next-Gen Mobility Network
              </div>
              <h1
                style={{
                  margin: "0 0 12px",
                  fontSize: "clamp(36px, 6vw, 72px)",
                  lineHeight: 1.02,
                  letterSpacing: "-1.5px",
                }}
              >
                Move Smarter.
              </h1>
              <p style={{ margin: "0 0 28px", color: tokens.textSoft, fontSize: 17, lineHeight: 1.7 }}>
                An intelligent ecosystem for rides, intercity sharing, goods logistics, and AI voice booking with one consistent premium experience.
              </p>
              <div style={{ display: "flex", flexWrap: "wrap", gap: 10 }}>
                <a
                  href="#download"
                  className="btn-raise"
                  style={{
                    padding: "12px 18px",
                    borderRadius: 12,
                    fontWeight: 800,
                    background: `linear-gradient(135deg, ${tokens.accent}, ${tokens.accentAlt})`,
                    color: "#fff",
                    boxShadow: `0 14px 34px ${tokens.glow}`,
                  }}
                >
                  Get Jago App
                </a>
                <a
                  href="/admin"
                  className="btn-raise"
                  style={{
                    padding: "12px 18px",
                    borderRadius: 12,
                    fontWeight: 700,
                    background: tokens.panel,
                    border: `1px solid ${tokens.border}`,
                    color: tokens.text,
                  }}
                >
                  Open Admin
                </a>
              </div>
            </div>

            <div className="reveal g2" style={{ position: "relative" }}>
              <div
                style={{
                  borderRadius: 26,
                  padding: 20,
                  background: tokens.heroCard,
                  border: `1px solid ${tokens.border}`,
                  boxShadow: `0 20px 46px ${tokens.glow}`,
                }}
              >
                <div
                  style={{
                    height: 236,
                    borderRadius: 18,
                    background: isDark
                      ? "linear-gradient(140deg, #10234a, #0c1732)"
                      : "linear-gradient(140deg, #f0f6ff, #deecff)",
                    padding: 16,
                    display: "flex",
                    flexDirection: "column",
                    justifyContent: "space-between",
                  }}
                >
                  <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between" }}>
                    <img src={isDark ? jagoLogoWhite : jagoLogoBlue} alt="JAGO" style={{ height: 26 }} />
                    <span
                      style={{
                        fontSize: 12,
                        fontWeight: 700,
                        color: isDark ? "#9cd8ff" : "#1e4ad9",
                      }}
                    >
                      Voice Ready
                    </span>
                  </div>
                  <div>
                    <div style={{ fontSize: 14, color: tokens.textSoft, marginBottom: 8 }}>Sample Intent</div>
                    <div
                      style={{
                        borderRadius: 12,
                        padding: "10px 12px",
                        border: `1px solid ${tokens.border}`,
                        background: isDark ? "rgba(5,11,24,0.58)" : "rgba(255,255,255,0.76)",
                        fontSize: 14,
                        color: tokens.text,
                      }}
                    >
                      "Book an auto to Gachibowli in 15 minutes"
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <div className="feature-grid" style={{ marginTop: 24 }}>
            {featureCards.map((item, idx) => (
              <div
                key={item.title}
                className={`reveal g${idx + 1}`}
                style={{
                  borderRadius: 18,
                  padding: 18,
                  border: `1px solid ${tokens.border}`,
                  background: tokens.panel,
                }}
              >
                <div
                  style={{
                    width: 42,
                    height: 42,
                    borderRadius: 12,
                    display: "grid",
                    placeItems: "center",
                    fontSize: 12,
                    fontWeight: 900,
                    letterSpacing: 0.4,
                    color: "#fff",
                    background: `linear-gradient(135deg, ${tokens.accent}, ${tokens.accentAlt})`,
                    marginBottom: 10,
                  }}
                >
                  {item.icon}
                </div>
                <h3 style={{ margin: "0 0 6px", fontSize: 19 }}>{item.title}</h3>
                <p style={{ margin: 0, color: tokens.textSoft, fontSize: 14, lineHeight: 1.6 }}>{item.desc}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      <section id="solutions" className="section" style={{ background: tokens.strip }}>
        <div style={{ maxWidth: 1180, margin: "0 auto", padding: "0 20px" }}>
          <h2 className="reveal" style={{ margin: "0 0 18px", fontSize: "clamp(28px, 4.2vw, 46px)", letterSpacing: "-0.8px" }}>
            Complete Mobility Ecosystem
          </h2>
          <div className="ecosystem-grid">
            {[
              ["Jago Bike", "Quick city rides"],
              ["Jago Auto", "Everyday transport"],
              ["Jago Share", "Intercity carpooling"],
              ["Jago Goods", "Delivery logistics"],
            ].map(([name, note], i) => (
              <div
                key={name}
                className={`reveal g${(i % 3) + 1}`}
                style={{
                  borderRadius: 18,
                  border: `1px solid ${tokens.border}`,
                  background: tokens.panelStrong,
                  padding: 18,
                }}
              >
                <div style={{ fontSize: 13, fontWeight: 800, color: tokens.accent, marginBottom: 8 }}>
                  0{i + 1}
                </div>
                <div style={{ fontSize: 20, fontWeight: 800, marginBottom: 6 }}>{name}</div>
                <div style={{ color: tokens.textSoft, fontSize: 14 }}>{note}</div>
              </div>
            ))}
          </div>
        </div>
      </section>

      <section id="driver" className="section">
        <div style={{ maxWidth: 1180, margin: "0 auto", padding: "0 20px" }}>
          <h2 className="reveal" style={{ margin: "0 0 18px", fontSize: "clamp(28px, 4vw, 44px)", letterSpacing: "-0.8px" }}>
            Jago & Pilot: Perfect Duo
          </h2>
          <div className="duo-grid">
            <div className="reveal g1" style={{ borderRadius: 20, padding: 20, border: `1px solid ${tokens.border}`, background: tokens.panel }}>
              <img src={isDark ? jagoLogoWhite : jagoLogoBlue} alt="JAGO" style={{ height: 38, marginBottom: 12 }} />
              <h3 style={{ margin: "0 0 8px" }}>For Passengers</h3>
              <p style={{ margin: 0, color: tokens.textSoft, lineHeight: 1.65 }}>
                AI-powered voice booking, transparent pricing, and ride options tuned for daily city and intercity movement.
              </p>
            </div>
            <div className="reveal g2" style={{ borderRadius: 20, padding: 20, border: `1px solid ${tokens.border}`, background: tokens.panel }}>
              <img src={pilotLogo} alt="Pilot" style={{ height: 38, marginBottom: 12 }} />
              <h3 style={{ margin: "0 0 8px" }}>For Drivers</h3>
              <p style={{ margin: 0, color: tokens.textSoft, lineHeight: 1.65 }}>
                Live demand guidance, optimized routes, and consistent earnings workflows with verified trip lifecycle control.
              </p>
            </div>
          </div>
        </div>
      </section>

      <section id="admin" className="section" style={{ background: tokens.strip }}>
        <div style={{ maxWidth: 1180, margin: "0 auto", padding: "0 20px" }}>
          <div className="reveal" style={{ borderRadius: 24, border: `1px solid ${tokens.border}`, background: tokens.heroCard, padding: "24px 22px" }}>
            <h2 style={{ margin: "0 0 10px", fontSize: "clamp(26px, 3.4vw, 40px)", letterSpacing: "-0.8px" }}>
              Super Admin Control Center
            </h2>
            <p style={{ margin: "0 0 18px", color: tokens.textSoft, maxWidth: 760, lineHeight: 1.7 }}>
              Monitor fleet and demand in real-time with issue flags, service breakdowns, and operational quality signals from one command surface.
            </p>
            <a
              href="/admin"
              className="btn-raise"
              style={{
                display: "inline-block",
                padding: "12px 18px",
                borderRadius: 12,
                background: `linear-gradient(135deg, ${tokens.accent}, ${tokens.accentAlt})`,
                color: "#fff",
                fontWeight: 800,
                boxShadow: `0 14px 30px ${tokens.glow}`,
              }}
            >
              View Admin Dashboard
            </a>
          </div>
        </div>
      </section>

      <section id="cities" className="section" style={{ background: tokens.strip }}>
        <div style={{ maxWidth: 1180, margin: "0 auto", padding: "0 20px" }}>
          <h2 className="reveal" style={{ margin: "0 0 18px", fontSize: "clamp(26px, 3.6vw, 40px)", letterSpacing: "-0.7px" }}>
            Cities We Serve
          </h2>
          <div className="ecosystem-grid" style={{ gridTemplateColumns: "repeat(auto-fit,minmax(180px,1fr))" }}>
            {["Hyderabad", "Secunderabad", "Vijayawada", "Guntur", "Warangal", "Visakhapatnam"].map((city, i) => (
              <div
                key={city}
                className={`reveal g${(i % 3) + 1}`}
                style={{
                  borderRadius: 14,
                  border: `1px solid ${tokens.border}`,
                  background: tokens.panelStrong,
                  padding: "14px 12px",
                  fontWeight: 700,
                }}
              >
                {city}
              </div>
            ))}
          </div>
        </div>
      </section>

      <section id="download" className="section">
        <div style={{ maxWidth: 1180, margin: "0 auto", padding: "0 20px" }}>
          <div
            className="reveal"
            style={{
              borderRadius: 24,
              border: `1px solid ${tokens.border}`,
              background: tokens.panel,
              padding: "24px 22px",
              display: "flex",
              alignItems: "center",
              justifyContent: "space-between",
              gap: 14,
              flexWrap: "wrap",
            }}
          >
            <div>
              <h3 style={{ margin: "0 0 6px", fontSize: 26 }}>Ready to See It in Action?</h3>
              <p style={{ margin: 0, color: tokens.textSoft }}>Install customer and pilot apps to test full booking and operations flows.</p>
            </div>
            <div style={{ display: "flex", gap: 10, flexWrap: "wrap" }}>
              <a
                href="https://play.google.com/store"
                target="_blank"
                rel="noreferrer"
                className="btn-raise"
                style={{
                  padding: "11px 16px",
                  borderRadius: 12,
                  fontWeight: 800,
                  background: isDark ? "#fff" : "#0f203f",
                  color: isDark ? "#09152d" : "#fff",
                }}
              >
                Download Jago
              </a>
              <a
                href="https://play.google.com/store"
                target="_blank"
                rel="noreferrer"
                className="btn-raise"
                style={{
                  padding: "11px 16px",
                  borderRadius: 12,
                  fontWeight: 800,
                  border: `1px solid ${tokens.border}`,
                  background: "transparent",
                  color: tokens.text,
                }}
              >
                Download Pilot
              </a>
            </div>
          </div>
        </div>
      </section>

      <footer style={{ borderTop: `1px solid ${tokens.border}`, background: tokens.footer }}>
        <div
          style={{
            maxWidth: 1180,
            margin: "0 auto",
            padding: "28px 20px 30px",
            display: "flex",
            alignItems: "center",
            justifyContent: "space-between",
            gap: 10,
            flexWrap: "wrap",
          }}
        >
          <div style={{ color: tokens.textSoft, fontSize: 13 }}>
            © {new Date().getFullYear()} MindWhile IT Solutions Pvt Ltd. All rights reserved.
          </div>
          <div style={{ display: "flex", gap: 14, flexWrap: "wrap", fontSize: 13, color: tokens.textSoft }}>
            <a href="/privacy">Privacy Policy</a>
            <a href="/terms">Terms & Conditions</a>
            <a href="/refund-policy">Refund Policy</a>
            <a href="/cookie-policy">Cookie Policy</a>
            <a href="/about-us">About</a>
            <a href="/contact-us">Contact</a>
          </div>
        </div>
      </footer>
    </div>
  );
}

