import { useState, useEffect, useRef, useCallback } from "react";
import { useTheme } from "@/components/theme-provider";

// ── Scroll Reveal Hook ────────────────────────────────────────────────────────
function useReveal() {
  useEffect(() => {
    const obs = new IntersectionObserver(
      (entries) => entries.forEach(e => {
        if (e.isIntersecting) { e.target.classList.add("revealed"); obs.unobserve(e.target); }
      }),
      { threshold: 0.12 }
    );
    document.querySelectorAll(".reveal").forEach(el => obs.observe(el));
    return () => obs.disconnect();
  }, []);
}

import jagoLogoWhite from "@assets/JAGO_LOGO_WightPNG_1772377612337.png";
import jagoLogoBlue  from "@assets/JAGO_LOGOPNG_(1)_1772377612339.png";
import pilotLogo     from "@assets/PILOT_LOGOPNG_1772377649091.png";

// ── Animated counter ─────────────────────────────────────────────────────────
function Counter({ to, suffix = "" }: { to: number; suffix?: string }) {
  const [val, setVal] = useState(0);
  const ref = useRef<HTMLSpanElement>(null);
  useEffect(() => {
    const obs = new IntersectionObserver(([e]) => {
      if (!e.isIntersecting) return;
      obs.disconnect();
      const start = Date.now();
      const dur = 1800;
      const tick = () => {
        const p = Math.min((Date.now() - start) / dur, 1);
        const ease = 1 - Math.pow(1 - p, 3);
        setVal(Math.floor(ease * to));
        if (p < 1) requestAnimationFrame(tick);
      };
      requestAnimationFrame(tick);
    }, { threshold: 0.3 });
    if (ref.current) obs.observe(ref.current);
    return () => obs.disconnect();
  }, [to]);
  return <span ref={ref}>{val.toLocaleString("en-IN")}{suffix}</span>;
}

// ── Phone mockup ─────────────────────────────────────────────────────────────
function PhoneMockup({ type }: { type: "customer" | "driver" }) {
  const isDriver = type === "driver";
  return (
    <div style={{
      width: 200, height: 410,
      background: isDriver ? "#060D1E" : "white",
      borderRadius: 40,
      border: "6px solid #1a2035",
      boxShadow: isDriver
        ? "0 40px 80px rgba(37,99,235,0.25), 0 20px 40px rgba(0,0,0,0.5), 0 0 0 1px rgba(37,99,235,0.15)"
        : "0 40px 80px rgba(30,109,229,0.18), 0 20px 40px rgba(0,0,0,0.15)",
      overflow: "hidden", position: "relative", flexShrink: 0,
    }}>
      <div style={{ position: "absolute", top: 0, left: "50%", transform: "translateX(-50%)", width: 80, height: 26, background: "#0a0a0a", borderRadius: "0 0 16px 16px", zIndex: 10 }} />
      <div style={{ padding: "32px 0 0" }}>
        {isDriver ? (
          <div style={{ height: "100%", background: "#060D1E", position: "relative" }}>
            <div style={{ position: "absolute", top: "30%", left: "50%", transform: "translate(-50%,-50%)", width: 200, height: 200, borderRadius: "50%", background: "radial-gradient(circle, rgba(37,99,235,0.2) 0%, transparent 70%)" }} />
            <div style={{ padding: "14px", position: "relative" }}>
              <div style={{ background: "#0D1B3E", borderRadius: 14, padding: "10px 12px", display: "flex", alignItems: "center", gap: 8, marginBottom: 10 }}>
                <div style={{ width: 7, height: 7, borderRadius: "50%", background: "#22C55E", boxShadow: "0 0 8px rgba(34,197,94,0.8)" }} />
                <img src={pilotLogo} style={{ height: 16, objectFit: "contain" }} alt="" />
                <span style={{ fontSize: 10, color: "rgba(255,255,255,0.6)", fontWeight: 600 }}>Online ✓</span>
              </div>
              <div style={{ background: "rgba(255,255,255,0.03)", borderRadius: 10, padding: 10, marginBottom: 8 }}>
                <div style={{ height: 70, background: "#0a1628", borderRadius: 8, marginBottom: 8, display: "flex", alignItems: "center", justifyContent: "center", position: "relative", overflow: "hidden" }}>
                  {[0,1,2,3].map(i=><div key={i} style={{ position: "absolute", left: `${i*30}px`, top: 0, bottom: 0, width: 1, background: "rgba(255,255,255,0.04)" }}/>)}
                  {[0,1,2,3,4].map(i=><div key={i} style={{ position: "absolute", top: `${i*18}px`, left: 0, right: 0, height: 1, background: "rgba(255,255,255,0.04)" }}/>)}
                  <div style={{ position: "absolute", width: 10, height: 10, borderRadius: "50%", background: "#2563EB", boxShadow: "0 0 0 6px rgba(37,99,235,0.15)" }} />
                </div>
                <div style={{ display: "flex", gap: 6 }}>
                  {[["💰","₹1,240","Earnings"],["🛺","8","Trips"],["👛","₹340","Wallet"]].map(([e,v,l],i)=>(
                    <div key={i} style={{ flex: 1, background: "#0D1B3E", borderRadius: 8, padding: "8px 4px", textAlign: "center" }}>
                      <div style={{ fontSize: 14, marginBottom: 2 }}>{e}</div>
                      <div style={{ fontSize: 11, fontWeight: 800, color: "white" }}>{v}</div>
                      <div style={{ fontSize: 8, color: "rgba(255,255,255,0.3)" }}>{l}</div>
                    </div>
                  ))}
                </div>
              </div>
              <div style={{ background: "linear-gradient(135deg,#16A34A,#15803D)", borderRadius: 10, height: 40, display: "flex", alignItems: "center", justifyContent: "center", fontSize: 12, fontWeight: 800, color: "white", boxShadow: "0 4px 14px rgba(22,163,74,0.4)" }}>
                Online — Ready ✓
              </div>
            </div>
          </div>
        ) : (
          <div style={{ height: "100%", background: "#F0F4FF", position: "relative" }}>
            <div style={{ height: 130, background: "#DDE8FF", position: "relative", overflow: "hidden", marginBottom: 0 }}>
              {[0,1,2,3,4].map(i=><div key={i} style={{ position: "absolute", left: `${i*45}px`, top: 0, bottom: 0, width: 1, background: "rgba(255,255,255,0.7)" }}/>)}
              {[0,1,2,3].map(i=><div key={i} style={{ position: "absolute", top: `${i*33}px`, left: 0, right: 0, height: 1, background: "rgba(255,255,255,0.7)" }}/>)}
              <div style={{ position: "absolute", inset: 0, background: "linear-gradient(0deg, rgba(240,244,255,1) 0%, transparent 100%)" }} />
              <div style={{ position: "absolute", bottom: 10, left: "50%", transform: "translateX(-50%)", width: 10, height: 10, borderRadius: "50%", background: "#1E6DE5", boxShadow: "0 0 0 8px rgba(30,109,229,0.15)" }} />
            </div>
            <div style={{ background: "white", borderRadius: "24px 24px 0 0", padding: "10px 10px 0", marginTop: -16 }}>
              <div style={{ width: 30, height: 3, background: "#E5E7EB", borderRadius: 2, margin: "0 auto 10px" }} />
              <div style={{ fontSize: 12, fontWeight: 900, color: "#0F172A", marginBottom: 8 }}>Where are you going?</div>
              <div style={{ background: "#F8FAFF", borderRadius: 10, border: "1px solid #E5EAFF", marginBottom: 8, overflow: "hidden" }}>
                <div style={{ display: "flex", alignItems: "center", gap: 6, padding: "7px 10px", borderBottom: "1px solid #F3F4F6" }}>
                  <div style={{ width: 7, height: 7, borderRadius: "50%", border: "2px solid #1E6DE5" }} />
                  <span style={{ fontSize: 10, color: "#1E6DE5", fontWeight: 600 }}>Current Location</span>
                </div>
                <div style={{ display: "flex", alignItems: "center", gap: 6, padding: "7px 10px" }}>
                  <div style={{ width: 7, height: 7, borderRadius: 2, background: "#EF4444" }} />
                  <span style={{ fontSize: 10, color: "#9CA3AF" }}>Where to?</span>
                </div>
              </div>
              <div style={{ display: "flex", gap: 5, marginBottom: 8 }}>
                {[["🏍","Bike","₹20+"],["🛺","Auto","₹35+"],["📦","Parcel","₹25+"]].map(([e,n,f],i)=>(
                  <div key={i} style={{ flex: 1, background: i===0?"linear-gradient(135deg,#1E6DE5,#1244A2)":"white", border: `1px solid ${i===0?"#1E6DE5":"#E5E7EB"}`, borderRadius: 8, padding: "7px 3px", textAlign: "center", boxShadow: i===0?"0 4px 10px rgba(30,109,229,0.3)":"none" }}>
                    <div style={{ fontSize: 14, marginBottom: 2 }}>{e}</div>
                    <div style={{ fontSize: 9, fontWeight: 700, color: i===0?"white":"#374151" }}>{n}</div>
                    <div style={{ fontSize: 8, fontWeight: 700, color: i===0?"rgba(255,255,255,0.8)":"#1E6DE5" }}>{f}</div>
                  </div>
                ))}
              </div>
              <div style={{ background: "linear-gradient(135deg,#1565C0,#1E6DE5)", borderRadius: 10, height: 36, display: "flex", alignItems: "center", justifyContent: "center", fontSize: 12, fontWeight: 800, color: "white", boxShadow: "0 4px 14px rgba(30,109,229,0.4)" }}>
                Find Ride →
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}

// ── Main Landing Page ─────────────────────────────────────────────────────────
export default function LandingPage() {
  const [menuOpen, setMenuOpen] = useState(false);
  const [scrolled, setScrolled] = useState(false);
  const [isMobile, setIsMobile] = useState(false);
  const { theme, setTheme } = useTheme();
  useReveal();

  useEffect(() => {
    const check = () => setIsMobile(window.innerWidth < 900);
    check();
    window.addEventListener("resize", check);
    return () => window.removeEventListener("resize", check);
  }, []);

  useEffect(() => {
    const onScroll = () => setScrolled(window.scrollY > 60);
    window.addEventListener("scroll", onScroll);
    return () => window.removeEventListener("scroll", onScroll);
  }, []);

  const nav = [
    { label: "Rides", href: "#solutions" },
    { label: "Parcels", href: "#solutions" },
    { label: "Cities", href: "#cities" },
    { label: "Drive with Us", href: "#driver" },
    { label: "About", href: "/about-us" },
  ];

  return (
    <div style={{ fontFamily: "'Manrope', 'Segoe UI', sans-serif", margin: 0, padding: 0, overflowX: "hidden" }}>
      <style>{`
        @import url('https://fonts.googleapis.com/css2?family=Manrope:wght@400;500;600;700;800&display=swap');
        *, *::before, *::after { box-sizing: border-box; }
        html, body { margin: 0; padding: 0; scroll-behavior: smooth; }
        #root { min-height: 100vh; }
        @keyframes float { 0%,100%{transform:translateY(0)} 50%{transform:translateY(-14px)} }
        @keyframes floatR { 0%,100%{transform:translateY(0) rotate(3deg)} 50%{transform:translateY(-10px) rotate(3deg)} }
        @keyframes pulse-ring { 0%{transform:scale(1);opacity:0.6} 100%{transform:scale(1.6);opacity:0} }
        @keyframes slide-up { from{opacity:0;transform:translateY(30px)} to{opacity:1;transform:translateY(0)} }
        @keyframes shimmer { 0%{background-position:200% 0} 100%{background-position:-200% 0} }
        @keyframes marquee { 0%{transform:translateX(0)} 100%{transform:translateX(-50%)} }
        .float-card { animation: float 4s ease-in-out infinite; }
        .float-card-r { animation: floatR 5s ease-in-out infinite; }
        .slide-up { animation: slide-up 0.7s ease-out forwards; }
        a { text-decoration: none; }
        section { padding: 80px 0; }
        @media(max-width:768px){ section { padding: 48px 0; } }
        .reveal { opacity:0; transform:translateY(36px); transition: opacity 0.75s cubic-bezier(.22,1,.36,1), transform 0.75s cubic-bezier(.22,1,.36,1); }
        .reveal.revealed { opacity:1; transform:translateY(0); }
        .reveal-delay-1 { transition-delay: 0.1s; }
        .reveal-delay-2 { transition-delay: 0.2s; }
        .reveal-delay-3 { transition-delay: 0.3s; }
        .reveal-delay-4 { transition-delay: 0.4s; }
        .service-card { background:#FAFAFA; border:1.5px solid #F1F5F9; border-radius:22px; padding:28px; transition:all 0.25s ease; cursor:default; }
        .service-card:hover { box-shadow:0 16px 40px rgba(30,109,229,0.12); border-color:#BFDBFE; transform:translateY(-4px); }
        .step-card { background:white; border-radius:22px; padding:28px; border:1px solid #F1F5F9; box-shadow:0 2px 12px rgba(0,0,0,0.05); position:relative; overflow:hidden; transition:all 0.25s ease; }
        .step-card:hover { box-shadow:0 12px 36px rgba(30,109,229,0.1); transform:translateY(-3px); }
        .testi-card { background:white; border-radius:24px; padding:28px; border:1.5px solid #F1F5F9; box-shadow:0 2px 16px rgba(0,0,0,0.05); transition:all 0.25s ease; }
        .testi-card:hover { box-shadow:0 16px 40px rgba(30,109,229,0.1); border-color:#BFDBFE; transform:translateY(-3px); }
        .ticker-wrap { overflow:hidden; width:100%; }
        .ticker-inner { display:flex; width:max-content; animation:marquee 28s linear infinite; }
        .ticker-inner:hover { animation-play-state:paused; }
        /* CTA button micro-interactions */
        .cta-primary { transition:all 0.2s ease !important; }
        .cta-primary:hover { transform:translateY(-2px) !important; box-shadow:0 8px 28px rgba(30,109,229,0.55) !important; }
        .cta-primary:active { transform:translateY(0) !important; }
        .cta-ghost { transition:all 0.2s ease !important; }
        .cta-ghost:hover { background:rgba(255,255,255,0.12) !important; border-color:rgba(255,255,255,0.4) !important; transform:translateY(-2px) !important; }
        /* Animated particle dots */
        @keyframes particle-float { 0%,100%{transform:translateY(0) scale(1);opacity:0.4} 50%{transform:translateY(-20px) scale(1.2);opacity:0.8} }
        .particle { position:absolute; border-radius:50%; background:rgba(30,109,229,0.5); animation:particle-float linear infinite; pointer-events:none; }
        /* Mobile nav */
        .mobile-menu { position:fixed; top:0; left:0; right:0; bottom:0; background:rgba(5,11,31,0.98); backdrop-filter:blur(20px); z-index:999; display:flex; flex-direction:column; align-items:center; justify-content:center; gap:32px; }
        .mobile-menu-link { color:rgba(255,255,255,0.85); font-size:22px; font-weight:700; text-decoration:none; letter-spacing:-0.3px; transition:color 0.2s; }
        .mobile-menu-link:hover { color:white; }
        /* Hamburger */
        .hamburger { display:flex; flex-direction:column; gap:5px; cursor:pointer; padding:8px; border:none; background:transparent; }
        .hamburger span { width:22px; height:2px; background:white; border-radius:2px; transition:all 0.3s ease; display:block; }
        /* Hide desktop nav on mobile */
        @media(max-width:900px){
          .desktop-nav { display:none !important; }
          .desktop-cta { display:none !important; }
        }
        @media(min-width:901px){ .hamburger { display:none !important; } }
        /* App store buttons */
        .store-btn { display:flex; align-items:center; gap:10px; border-radius:12px; padding:12px 20px; text-decoration:none; transition:all 0.2s ease; }
        .store-btn:hover { transform:translateY(-2px); box-shadow:0 8px 24px rgba(0,0,0,0.2); }
        /* Rating badge */
        @keyframes glow-pulse { 0%,100%{box-shadow:0 0 8px rgba(250,204,21,0.4)} 50%{box-shadow:0 0 20px rgba(250,204,21,0.7)} }
        /* Responsive grids */
        .footer-grid { display:grid; grid-template-columns:2fr 1fr 1fr 1fr; gap:48px; margin-bottom:48px; }
        @media(max-width:900px){ .footer-grid { grid-template-columns:1fr 1fr; gap:32px; } }
        @media(max-width:600px){ .footer-grid { grid-template-columns:1fr; gap:24px; } }
        .hero-phones { position:relative; display:flex; align-items:flex-end; gap:20px; justify-content:center; flex-shrink:0; }
        @media(max-width:900px){ .hero-phones { display:none !important; } }
        .solutions-grid { display:grid; grid-template-columns:repeat(3,1fr); gap:20px; }
        @media(max-width:900px){ .solutions-grid { grid-template-columns:repeat(2,1fr); } }
        @media(max-width:600px){ .solutions-grid { grid-template-columns:1fr; } }
        .driver-grid { display:grid; grid-template-columns:1fr 1fr; gap:32px; align-items:center; }
        @media(max-width:900px){ .driver-grid { grid-template-columns:1fr; } }
        .download-grid { display:grid; grid-template-columns:1fr 1fr; gap:24px; }
        @media(max-width:900px){ .download-grid { grid-template-columns:1fr; } }
        .control-grid { display:grid; grid-template-columns:repeat(4,1fr); gap:18px; }
        @media(max-width:1000px){ .control-grid { grid-template-columns:repeat(2,1fr); } }
        @media(max-width:600px){ .control-grid { grid-template-columns:1fr; } }
      `}</style>

      {/* ── MOBILE MENU OVERLAY ── */}
      {menuOpen && (
        <div className="mobile-menu" onClick={() => setMenuOpen(false)}>
          <img src={jagoLogoWhite} style={{ height: 56, objectFit: "contain", marginBottom: 16 }} alt="JAGO" />
          {nav.map(n => (
            <a key={n.label} href={n.href} className="mobile-menu-link" onClick={() => setMenuOpen(false)}>{n.label}</a>
          ))}
          <div style={{ display: "flex", flexDirection: "column", gap: 12, marginTop: 8, width: "80%", maxWidth: 320 }}>
            <a href="#driver" className="cta-ghost" style={{ padding: "13px 22px", borderRadius: 14, background: "rgba(255,255,255,0.06)", border: "1.5px solid rgba(255,255,255,0.2)", color: "white", fontSize: 15, fontWeight: 700, textDecoration: "none", textAlign: "center" }} onClick={() => setMenuOpen(false)}>
              Become a Pilot
            </a>
            <a href="#download" className="cta-primary" style={{ padding: "13px 22px", borderRadius: 14, background: "linear-gradient(135deg,#1E6DE5,#1244A2)", color: "white", fontSize: 15, fontWeight: 700, boxShadow: "0 4px 14px rgba(30,109,229,0.4)", textDecoration: "none", textAlign: "center" }} onClick={() => setMenuOpen(false)}>
              Download App
            </a>
            <button
              onClick={(e) => { e.stopPropagation(); setTheme(theme === "dark" ? "light" : "dark"); }}
              style={{ padding: "13px 22px", borderRadius: 14, background: "rgba(255,255,255,0.04)", border: "1.5px solid rgba(255,255,255,0.12)", color: "white", fontSize: 14, fontWeight: 600, cursor: "pointer", display: "flex", alignItems: "center", justifyContent: "center", gap: 8 }}
            >
              {theme === "dark" ? "☀️ Switch to Light Mode" : "🌙 Switch to Dark Mode"}
            </button>
          </div>
        </div>
      )}

      {/* ── NAVBAR ── */}
      <nav style={{
        position: "fixed", top: 0, left: 0, right: 0, zIndex: 1000,
        background: scrolled ? "rgba(8,12,30,0.97)" : "transparent",
        backdropFilter: scrolled ? "blur(20px)" : "none",
        borderBottom: scrolled ? "1px solid rgba(255,255,255,0.06)" : "none",
        transition: "all 0.3s ease",
      }}>
        <div style={{ maxWidth: 1200, margin: "0 auto", padding: "0 24px", height: 84, display: "flex", alignItems: "center", justifyContent: "space-between" }}>
          <a href="/">
            <img src={jagoLogoWhite} style={{ height: 52, objectFit: "contain" }} alt="JAGO" />
          </a>
          <div className="desktop-nav" style={{ display: "flex", alignItems: "center", gap: 36 }}>
            {nav.map(n => (
              <a key={n.label} href={n.href} style={{ color: "rgba(255,255,255,0.75)", fontSize: 14, fontWeight: 500, transition: "color 0.2s" }}
                onMouseEnter={e => (e.target as HTMLElement).style.color = "white"}
                onMouseLeave={e => (e.target as HTMLElement).style.color = "rgba(255,255,255,0.75)"}
              >{n.label}</a>
            ))}
          </div>
          <div className="desktop-cta" style={{ display: "flex", alignItems: "center", gap: 12 }}>
            {/* Theme Toggle */}
            <button
              onClick={() => setTheme(theme === "dark" ? "light" : "dark")}
              title={theme === "dark" ? "Switch to Light Mode" : "Switch to Dark Mode"}
              style={{
                width: 36, height: 36, borderRadius: 10, border: "1.5px solid rgba(255,255,255,0.2)",
                background: "rgba(255,255,255,0.06)", backdropFilter: "blur(8px)",
                color: "white", cursor: "pointer", display: "flex", alignItems: "center",
                justifyContent: "center", fontSize: 15, transition: "all 0.2s ease",
                flexShrink: 0,
              }}
              onMouseEnter={e => (e.currentTarget as HTMLElement).style.background = "rgba(255,255,255,0.12)"}
              onMouseLeave={e => (e.currentTarget as HTMLElement).style.background = "rgba(255,255,255,0.06)"}
            >
              {theme === "dark" ? "☀️" : "🌙"}
            </button>
            <a href="#driver" className="cta-ghost" style={{ padding: "9px 22px", borderRadius: 10, background: "transparent", border: "1.5px solid rgba(255,255,255,0.25)", color: "white", fontSize: 13, fontWeight: 600, textDecoration: "none" }}>
              Become a Pilot
            </a>
            <a href="#download" className="cta-primary" style={{ padding: "9px 22px", borderRadius: 10, background: "linear-gradient(135deg,#1E6DE5,#1244A2)", color: "white", fontSize: 13, fontWeight: 700, boxShadow: "0 4px 14px rgba(30,109,229,0.4)", textDecoration: "none" }}>
              Download App
            </a>
          </div>
          {/* Hamburger — mobile only */}
          <button className="hamburger" onClick={() => setMenuOpen(!menuOpen)} aria-label="Toggle menu">
            <span style={{ transform: menuOpen ? "rotate(45deg) translate(5px, 5px)" : "none" }}></span>
            <span style={{ opacity: menuOpen ? 0 : 1 }}></span>
            <span style={{ transform: menuOpen ? "rotate(-45deg) translate(5px, -5px)" : "none" }}></span>
          </button>
        </div>
      </nav>

      {/* ── HERO ── */}
      <section style={{
        minHeight: "100vh", background: "linear-gradient(140deg, #050b1f 0%, #071230 40%, #0a1a40 70%, #08122e 100%)",
        display: "flex", alignItems: "center", position: "relative", overflow: "hidden", padding: "80px 0 40px",
      }}>
        {/* Background effects */}
        <div style={{ position: "absolute", top: "20%", left: "60%", width: 600, height: 600, borderRadius: "50%", background: "radial-gradient(circle, rgba(30,109,229,0.12) 0%, transparent 70%)", pointerEvents: "none" }} />
        <div style={{ position: "absolute", bottom: "10%", left: "10%", width: 400, height: 400, borderRadius: "50%", background: "radial-gradient(circle, rgba(37,99,235,0.08) 0%, transparent 70%)", pointerEvents: "none" }} />
        {/* Grid */}
        <svg style={{ position: "absolute", inset: 0, opacity: 0.03, pointerEvents: "none" }} width="100%" height="100%">
          {Array.from({length:30},(_,i)=><line key={`v${i}`} x1={`${i*5}%`} y1="0%" x2={`${i*5}%`} y2="100%" stroke="white" strokeWidth="0.5"/>)}
          {Array.from({length:20},(_,i)=><line key={`h${i}`} x1="0%" y1={`${i*5}%`} x2="100%" y2={`${i*5}%`} stroke="white" strokeWidth="0.5"/>)}
        </svg>
        {/* Animated particles */}
        {[
          {w:6,h:6,top:"15%",left:"8%",dur:"6s",delay:"0s"},
          {w:4,h:4,top:"35%",left:"15%",dur:"8s",delay:"1s"},
          {w:8,h:8,top:"65%",left:"5%",dur:"7s",delay:"2s"},
          {w:5,h:5,top:"80%",left:"20%",dur:"9s",delay:"0.5s"},
          {w:4,h:4,top:"25%",left:"85%",dur:"6.5s",delay:"1.5s"},
          {w:7,h:7,top:"55%",left:"90%",dur:"8s",delay:"3s"},
          {w:5,h:5,top:"10%",left:"75%",dur:"7.5s",delay:"2.5s"},
          {w:3,h:3,top:"45%",left:"45%",dur:"5.5s",delay:"4s"},
        ].map((p,i) => (
          <div key={i} className="particle" style={{
            width: p.w, height: p.h, top: p.top, left: p.left,
            animationDuration: p.dur, animationDelay: p.delay,
          }} />
        ))}

        <div style={{ maxWidth: 1200, margin: "0 auto", padding: "0 24px", width: "100%", display: "flex", alignItems: "center", justifyContent: "space-between", gap: 48, flexWrap: "wrap" }}>
          {/* Left */}
          <div style={{ flex: 1, minWidth: 300, maxWidth: 580 }}>
            <div style={{ display: "inline-flex", alignItems: "center", gap: 8, background: "rgba(30,109,229,0.12)", border: "1px solid rgba(30,109,229,0.25)", borderRadius: 20, padding: "6px 16px", marginBottom: 28 }}>
              <div style={{ width: 7, height: 7, borderRadius: "50%", background: "#22C55E", boxShadow: "0 0 8px rgba(34,197,94,0.7)" }} />
              <span style={{ fontSize: 12, color: "rgba(255,255,255,0.7)", fontWeight: 600, letterSpacing: 0.3 }}>AI Smart Mobility Super Platform · Telangana &amp; Andhra Pradesh</span>
            </div>

            <h1 style={{ fontSize: "clamp(36px, 5vw, 64px)", fontWeight: 900, color: "white", lineHeight: 1.1, margin: "0 0 20px", letterSpacing: -1 }}>
              One App. Every Move.<br />
              <span style={{ background: "linear-gradient(135deg, #3B82F6, #60A5FA, #93C5FD)", WebkitBackgroundClip: "text", WebkitTextFillColor: "transparent" }}>
                Ride. Deliver. Scale.
              </span>
            </h1>

            <p style={{ fontSize: 18, color: "rgba(255,255,255,0.55)", lineHeight: 1.7, marginBottom: 36, maxWidth: 560 }}>
              JAGO is your AI-powered mobility network for city rides, intercity travel, parcel delivery, cargo movement, and business fleet operations with safety-first workflows.
            </p>

            {/* CTA Buttons */}
            <div style={{ display: "flex", gap: 14, flexWrap: "wrap", marginBottom: 48 }}>
              <a href="#download" className="cta-primary" style={{ display: "flex", alignItems: "center", gap: 10, background: "white", borderRadius: 14, padding: "14px 24px", color: "#0F172A", fontWeight: 700, fontSize: 15, boxShadow: "0 8px 24px rgba(0,0,0,0.2)", textDecoration: "none" }}>
                <svg width="20" height="20" viewBox="0 0 24 24"><path d="M3.609 1.814A.5.5 0 0 0 3 2.5v19a.5.5 0 0 0 .61.49l18-5.5a.5.5 0 0 0 0-.98l-18-13.7z" fill="#00C773"/></svg>
                Get JAGO App
              </a>
              <a href="#driver" className="cta-ghost" style={{ display: "flex", alignItems: "center", gap: 10, background: "rgba(255,255,255,0.07)", border: "1.5px solid rgba(255,255,255,0.15)", borderRadius: 14, padding: "14px 24px", color: "white", fontWeight: 700, fontSize: 15, backdropFilter: "blur(10px)", textDecoration: "none" }}>
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none"><circle cx="12" cy="12" r="10" stroke="rgba(255,255,255,0.4)" strokeWidth="1.5"/><path d="M12 8l4 4-4 4M8 12h8" stroke="white" strokeWidth="2" strokeLinecap="round"/></svg>
                Drive &amp; Earn
              </a>
            </div>

            {/* Stats */}
            <div style={{ display: "flex", gap: 36, flexWrap: "wrap" }}>
              {[
                { n: 9, sfx: "", label: "Cities Live" },
                { n: 6, sfx: "+", label: "Ride Categories" },
                { n: 100, sfx: "%", label: "OTP-Gated Trips" },
              ].map((s, i) => (
                <div key={i}>
                  <div style={{ fontSize: 32, fontWeight: 900, color: "white", lineHeight: 1 }}>
                    <Counter to={s.n} suffix={s.sfx} />
                  </div>
                  <div style={{ fontSize: 12, color: "rgba(255,255,255,0.4)", marginTop: 4, fontWeight: 500 }}>{s.label}</div>
                </div>
              ))}
            </div>
          </div>

          {/* Right — Phone mockups */}
          <div className="hero-phones">
            <div className="float-card" style={{ marginBottom: 30 }}>
              <PhoneMockup type="customer" />
            </div>
            <div className="float-card-r">
              <PhoneMockup type="driver" />
            </div>

            {/* Floating badges */}
            <div style={{ position: "absolute", top: -10, left: -20, background: "white", borderRadius: 14, padding: "10px 14px", display: "flex", alignItems: "center", gap: 8, boxShadow: "0 12px 30px rgba(0,0,0,0.2)", zIndex: 5 }}>
              <div style={{ width: 32, height: 32, borderRadius: "50%", background: "linear-gradient(135deg,#22C55E,#16A34A)", display: "flex", alignItems: "center", justifyContent: "center" }}>
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none"><path d="M20 6L9 17l-5-5" stroke="white" strokeWidth="2.5" strokeLinecap="round"/></svg>
              </div>
              <div>
                <div style={{ fontSize: 12, fontWeight: 800, color: "#0F172A" }}>Pilot Assigned!</div>
                <div style={{ fontSize: 10, color: "#6B7280" }}>ETA 3 min · Arjun</div>
              </div>
            </div>

            <div style={{ position: "absolute", bottom: 20, right: -30, background: "#0D1B3E", border: "1px solid rgba(37,99,235,0.25)", borderRadius: 14, padding: "10px 14px", boxShadow: "0 12px 30px rgba(0,0,0,0.4)", zIndex: 5 }}>
              <div style={{ fontSize: 10, color: "rgba(255,255,255,0.4)", marginBottom: 3, fontWeight: 600 }}>Today's Earnings</div>
              <div style={{ fontSize: 20, fontWeight: 900, color: "#22C55E" }}>₹1,240</div>
              <div style={{ fontSize: 9, color: "rgba(255,255,255,0.3)", marginTop: 2 }}>8 trips completed</div>
            </div>
          </div>
        </div>

        {/* Scroll indicator */}
        <div style={{ position: "absolute", bottom: 30, left: "50%", transform: "translateX(-50%)", display: "flex", flexDirection: "column", alignItems: "center", gap: 6 }}>
          <span style={{ fontSize: 11, color: "rgba(255,255,255,0.25)", letterSpacing: 2, textTransform: "uppercase" }}>Scroll</span>
          <div style={{ width: 1, height: 40, background: "linear-gradient(to bottom, rgba(255,255,255,0.2), transparent)" }} />
        </div>
      </section>

      {/* ── STATS BAR ── */}
      <section style={{ padding: "0", background: "linear-gradient(135deg, #1244A2, #1E6DE5)" }}>
        <div style={{ maxWidth: 1200, margin: "0 auto", padding: "40px 24px", display: "flex", justifyContent: "space-around", flexWrap: "wrap", gap: 24 }}>
          {[
            { icon: "🚀", n: 30, sfx: " sec", label: "Avg. Pilot Arrival" },
            { icon: "⭐", n: 48, sfx: "/5.0", label: "Average Rating" },
            { icon: "🛡️", n: 100, sfx: "%", label: "OTP Secured" },
            { icon: "📍", n: 9, sfx: "+", label: "Active Zones" },
          ].map((s, i) => (
            <div key={i} style={{ textAlign: "center", color: "white" }}>
              <div style={{ fontSize: 28, marginBottom: 4 }}>{s.icon}</div>
              <div style={{ fontSize: 32, fontWeight: 900, lineHeight: 1 }}>
                {s.sfx === "/5.0" ? "4.8" : <Counter to={s.n} suffix={s.sfx} />}
              </div>
              <div style={{ fontSize: 12, color: "rgba(255,255,255,0.7)", marginTop: 4, fontWeight: 500 }}>{s.label}</div>
            </div>
          ))}
        </div>
      </section>

      {/* ── TRUST TICKER ── */}
      <div style={{ background: "#0A0F23", borderTop: "1px solid rgba(255,255,255,0.05)", borderBottom: "1px solid rgba(255,255,255,0.05)", padding: "14px 0", overflow: "hidden" }}>
        <div className="ticker-wrap">
          <div className="ticker-inner">
            {[
              "✅ OTP Verified Rides", "🛡️ Insurance Covered Pilots", "📍 Real-time GPS Tracking",
              "💳 Secure UPI & Cash Payments", "🎧 In-App Customer Support", "🚀 Fast Pilot Matching",
              "🔒 End-to-End Safety", "💰 Transparent Pricing", "📦 OTP-Verified Parcel Delivery",
              "✅ OTP Verified Rides", "🛡️ Insurance Covered Pilots", "📍 Real-time GPS Tracking",
              "💳 Secure UPI & Cash Payments", "🎧 In-App Customer Support", "🚀 Fast Pilot Matching",
              "🔒 End-to-End Safety", "💰 Transparent Pricing", "📦 OTP-Verified Parcel Delivery",
            ].map((t, i) => (
              <span key={i} style={{ display: "inline-flex", alignItems: "center", gap: 8, padding: "0 32px", fontSize: 13, color: "rgba(255,255,255,0.55)", fontWeight: 600, whiteSpace: "nowrap" }}>
                {t}
                {i < 17 && <span style={{ width: 4, height: 4, borderRadius: "50%", background: "rgba(30,109,229,0.6)", display: "inline-block" }}></span>}
              </span>
            ))}
          </div>
        </div>
      </div>

      {/* ── HOW IT WORKS ── */}
      <section style={{ background: "#F8FAFF" }} id="solutions">
        <div style={{ maxWidth: 1200, margin: "0 auto", padding: "0 24px" }}>
          <div className="reveal" style={{ textAlign: "center", marginBottom: 64 }}>
            <div style={{ display: "inline-block", background: "#EFF6FF", border: "1px solid #BFDBFE", borderRadius: 20, padding: "6px 18px", fontSize: 12, fontWeight: 700, color: "#1E6DE5", marginBottom: 16, letterSpacing: 1 }}>HOW IT WORKS</div>
            <h2 style={{ fontSize: "clamp(28px, 4vw, 44px)", fontWeight: 900, color: "#0F172A", margin: "0 0 16px", letterSpacing: -0.5 }}>Ride in <span style={{ color: "#1E6DE5" }}>4 Simple Steps</span></h2>
            <p style={{ fontSize: 17, color: "#64748B", maxWidth: 600, margin: "0 auto" }}>From instant booking to verified completion, every trip is safety-scored, OTP-validated, and tracked in real time.</p>
          </div>

          <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(220px, 1fr))", gap: 24 }}>
            {[
              { n: "01", emoji: "📱", title: "Open App", desc: "Open JAGO app and tap 'Where are you going?'", color: "#EFF6FF", border: "#BFDBFE" },
              { n: "02", emoji: "📍", title: "Set Destination", desc: "Choose pickup point and enter your destination", color: "#F0FDF4", border: "#BBF7D0" },
              { n: "03", emoji: "🏍", title: "Pilot Assigned", desc: "Nearest verified pilot is assigned instantly to you", color: "#FFFBEB", border: "#FDE68A" },
              { n: "04", emoji: "✅", title: "Arrive Safely", desc: "Reach your destination safely with OTP-verified handoff", color: "#FFF1F2", border: "#FECDD3" },
            ].map((s, i) => (
              <div key={i} className={`step-card reveal reveal-delay-${i + 1}`}>
                <div style={{ position: "absolute", top: 16, right: 16, fontSize: 40, fontWeight: 900, color: "#F1F5F9", fontFamily: "monospace" }}>{s.n}</div>
                <div style={{ width: 56, height: 56, background: s.color, border: `1.5px solid ${s.border}`, borderRadius: 18, display: "flex", alignItems: "center", justifyContent: "center", fontSize: 26, marginBottom: 20 }}>{s.emoji}</div>
                <h4 style={{ fontSize: 18, fontWeight: 800, color: "#0F172A", margin: "0 0 8px" }}>{s.title}</h4>
                <p style={{ fontSize: 14, color: "#64748B", margin: 0, lineHeight: 1.6 }}>{s.desc}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* ── SERVICES ── */}
      <section style={{ background: "white" }}>
        <div style={{ maxWidth: 1200, margin: "0 auto", padding: "0 24px" }}>
          <div className="reveal" style={{ textAlign: "center", marginBottom: 56 }}>
            <div style={{ display: "inline-block", background: "#EFF6FF", border: "1px solid #BFDBFE", borderRadius: 20, padding: "6px 18px", fontSize: 12, fontWeight: 700, color: "#1E6DE5", marginBottom: 16, letterSpacing: 1 }}>OUR SERVICES</div>
            <h2 style={{ fontSize: "clamp(28px, 4vw, 44px)", fontWeight: 900, color: "#0F172A", margin: "0 0 14px", letterSpacing: -0.5 }}>Everything You Need</h2>
            <p style={{ fontSize: 17, color: "#64748B", maxWidth: 620, margin: "0 auto" }}>A super platform for consumers, pilots, and enterprises with transparent pricing, live operations, and compliance-ready workflows.</p>
          </div>

          <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(300px, 1fr))", gap: 20 }}>
            {[
              { emoji: "🏍", title: "Bike Rides", desc: "Beat traffic with quick, affordable bike rides. Fastest way to get around the city.", tag: "₹20+ /km", tagColor: "#EFF6FF", tagText: "#1E6DE5" },
              { emoji: "🛺", title: "Auto Rides", desc: "Comfortable auto rides for daily commutes with transparent fares and no surge.", tag: "₹35+ /km", tagColor: "#F0FDF4", tagText: "#16A34A" },
              { emoji: "📦", title: "Parcel Delivery", desc: "Send parcels across the city in under 60 minutes with real-time OTP tracking.", tag: "₹25+ /order", tagColor: "#FFFBEB", tagText: "#D97706" },
              { emoji: "🚛", title: "Cargo & Logistics", desc: "Move heavy goods and cargo with our trusted cargo pilots and smart fleet system.", tag: "₹200+", tagColor: "#FFF1F2", tagText: "#E11D48" },
              { emoji: "📅", title: "Scheduled Trips", desc: "Book in advance — set date, time, and destination. We'll be ready when you are.", tag: "Pre-book", tagColor: "#F5F3FF", tagText: "#7C3AED" },
              { emoji: "🏢", title: "B2B Solutions", desc: "Scalable fleet management and delivery solutions for businesses of all sizes.", tag: "Enterprise", tagColor: "#F0F9FF", tagText: "#0284C7" },
            ].map((s, i) => (
              <div key={i} className={`service-card reveal reveal-delay-${(i % 3) + 1}`}>
                <div style={{ display: "flex", alignItems: "flex-start", justifyContent: "space-between", marginBottom: 16 }}>
                  <div style={{ fontSize: 38 }}>{s.emoji}</div>
                  <div style={{ background: s.tagColor, color: s.tagText, fontSize: 11, fontWeight: 700, padding: "4px 10px", borderRadius: 8 }}>{s.tag}</div>
                </div>
                <h4 style={{ fontSize: 18, fontWeight: 800, color: "#0F172A", margin: "0 0 8px" }}>{s.title}</h4>
                <p style={{ fontSize: 14, color: "#64748B", margin: 0, lineHeight: 1.65 }}>{s.desc}</p>
              </div>
            ))}
          </div>
        </div>
      </section>


      {/* ── SMART MOBILITY CONTROL LAYER ── */}
      <section style={{ background: "linear-gradient(180deg, #f6fbff 0%, #eef6ff 100%)", borderTop: "1px solid #dbeafe", borderBottom: "1px solid #dbeafe" }}>
        <div style={{ maxWidth: 1200, margin: "0 auto", padding: "0 24px" }}>
          <div className="reveal" style={{ textAlign: "center", marginBottom: 42 }}>
            <div style={{ display: "inline-block", background: "#dbeafe", border: "1px solid #93c5fd", borderRadius: 20, padding: "6px 18px", fontSize: 12, fontWeight: 800, color: "#1d4ed8", marginBottom: 16, letterSpacing: 1 }}>SMART MOBILITY CORE</div>
            <h2 style={{ fontSize: "clamp(28px, 4vw, 42px)", fontWeight: 900, color: "#0f172a", margin: "0 0 12px", letterSpacing: -0.5 }}>
              Super Platform Control Layer
            </h2>
            <p style={{ fontSize: 16, color: "#64748b", maxWidth: 760, margin: "0 auto" }}>
              Built for high-volume city operations with dispatch intelligence, safety orchestration, and compliance-grade event trails.
            </p>
          </div>

          <div className="control-grid">
            {[
              { icon: "🧠", title: "AI Dispatch Brain", desc: "Demand prediction, pilot ranking, and assignment balancing tuned for low ETA and high trip completion.", tone: "#eff6ff", border: "#bfdbfe" },
              { icon: "🛡️", title: "Safety Protocol Mesh", desc: "OTP-gated lifecycle, live location confidence checks, and anomaly alerts across active trips.", tone: "#f0fdf4", border: "#bbf7d0" },
              { icon: "⚖️", title: "Policy & Legal Layer", desc: "Transparent terms, privacy controls, and auditable operations aligned with Indian compliance obligations.", tone: "#fefce8", border: "#fde68a" },
              { icon: "📈", title: "Growth Operations", desc: "Unified stack for consumer rides, parcel flows, and enterprise logistics with measurable SLAs.", tone: "#fff1f2", border: "#fecdd3" },
            ].map((item, i) => (
              <div key={item.title} className={`reveal reveal-delay-${(i % 4) + 1}`} style={{ background: "white", borderRadius: 18, border: `1.5px solid ${item.border}`, boxShadow: "0 10px 28px rgba(30, 109, 229, 0.08)", padding: 22 }}>
                <div style={{ width: 48, height: 48, borderRadius: 14, background: item.tone, border: `1px solid ${item.border}`, display: "flex", alignItems: "center", justifyContent: "center", fontSize: 22, marginBottom: 14 }}>{item.icon}</div>
                <h3 style={{ margin: "0 0 8px", fontSize: 18, color: "#0f172a", fontWeight: 800 }}>{item.title}</h3>
                <p style={{ margin: 0, fontSize: 14, lineHeight: 1.6, color: "#475569" }}>{item.desc}</p>
              </div>
            ))}
          </div>
        </div>
      </section>


      {/* ── DRIVER CTA ── */}
      <section id="driver" style={{ background: "linear-gradient(140deg, #050b1f 0%, #081535 50%, #0a1a40 100%)", position: "relative", overflow: "hidden" }}>
        <div style={{ position: "absolute", top: "50%", right: "5%", transform: "translateY(-50%)", width: 500, height: 500, borderRadius: "50%", background: "radial-gradient(circle, rgba(37,99,235,0.15) 0%, transparent 70%)" }} />
        <div style={{ maxWidth: 1200, margin: "0 auto", padding: "0 24px", position: "relative" }}>
          <div className="driver-grid">
            {/* Left */}
            <div>
              <img src={pilotLogo} style={{ height: 40, objectFit: "contain", marginBottom: 24 }} alt="JAGO Pilot" />
              <h2 style={{ fontSize: "clamp(28px, 3.5vw, 50px)", fontWeight: 900, color: "white", lineHeight: 1.15, margin: "0 0 20px", letterSpacing: -0.5 }}>
                Drive With JAGO.<br />
                <span style={{ background: "linear-gradient(135deg,#3B82F6,#60A5FA)", WebkitBackgroundClip: "text", WebkitTextFillColor: "transparent" }}>
                  Earn Every Day.
                </span>
              </h2>
              <p style={{ fontSize: 17, color: "rgba(255,255,255,0.55)", lineHeight: 1.7, marginBottom: 32 }}>
                Join high-performance JAGO Pilots with transparent earnings, fraud controls, support workflows, and flexible schedules.
              </p>

              <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 16, marginBottom: 36 }}>
                {[
                  { icon: "💰", title: "₹800–₹1,500/day", sub: "Average pilot earnings" },
                  { icon: "🕐", title: "Flexible Hours", sub: "Work on your schedule" },
                  { icon: "📊", title: "Weekly Payouts", sub: "Direct to your wallet" },
                  { icon: "🛡️", title: "Insurance Cover", sub: "Ride with protection" },
                ].map((b, i) => (
                  <div key={i} style={{ background: "rgba(255,255,255,0.04)", border: "1px solid rgba(255,255,255,0.08)", borderRadius: 16, padding: "16px" }}>
                    <div style={{ fontSize: 24, marginBottom: 8 }}>{b.icon}</div>
                    <div style={{ fontSize: 15, fontWeight: 800, color: "white", marginBottom: 3 }}>{b.title}</div>
                    <div style={{ fontSize: 12, color: "rgba(255,255,255,0.4)" }}>{b.sub}</div>
                  </div>
                ))}
              </div>

              <div style={{ display: "flex", gap: 14, flexWrap: "wrap" }}>
                <a href="https://play.google.com/store" target="_blank" rel="noreferrer" style={{ display: "flex", alignItems: "center", gap: 10, background: "linear-gradient(135deg,#2563EB,#1D4ED8)", borderRadius: 12, padding: "12px 22px", color: "white", fontSize: 14, fontWeight: 700, textDecoration: "none", boxShadow: "0 6px 20px rgba(37,99,235,0.4)" }}>
                  <svg width="18" height="18" viewBox="0 0 24 24"><path d="M3.609 1.814A.5.5 0 0 0 3 2.5v19a.5.5 0 0 0 .61.49l18-5.5a.5.5 0 0 0 0-.98l-18-13.7z" fill="white"/></svg>
                  Download Pilot App
                </a>
              </div>
            </div>

            {/* Right — Earnings card */}
            <div style={{ display: "flex", justifyContent: "center" }}>
              <div style={{ background: "#0D1B3E", border: "1px solid rgba(37,99,235,0.2)", borderRadius: 28, padding: 28, width: "100%", maxWidth: 360, boxShadow: "0 40px 80px rgba(0,0,0,0.5), 0 0 0 1px rgba(37,99,235,0.1)" }}>
                <div style={{ display: "flex", alignItems: "center", gap: 12, marginBottom: 24 }}>
                  <div style={{ width: 44, height: 44, borderRadius: "50%", background: "linear-gradient(135deg,#2563EB,#1D4ED8)", display: "flex", alignItems: "center", justifyContent: "center", fontWeight: 900, fontSize: 18, color: "white" }}>R</div>
                  <div>
                    <div style={{ fontWeight: 800, color: "white", fontSize: 15 }}>Ravi Kumar</div>
                    <div style={{ fontSize: 11, color: "rgba(255,255,255,0.4)" }}>⭐ 4.9 · JAGO Pilot · Hyderabad</div>
                  </div>
                </div>
                <div style={{ background: "#060D1E", borderRadius: 18, padding: 18, marginBottom: 16 }}>
                  <div style={{ fontSize: 11, color: "rgba(255,255,255,0.35)", fontWeight: 600, marginBottom: 6, textTransform: "uppercase", letterSpacing: 0.5 }}>This Month</div>
                  <div style={{ fontSize: 42, fontWeight: 900, color: "white", lineHeight: 1, marginBottom: 4 }}>₹32,400</div>
                  <div style={{ display: "flex", alignItems: "center", gap: 6 }}>
                    <div style={{ background: "rgba(34,197,94,0.15)", borderRadius: 6, padding: "2px 8px", fontSize: 11, fontWeight: 700, color: "#22C55E" }}>↑ +18%</div>
                    <span style={{ fontSize: 11, color: "rgba(255,255,255,0.3)" }}>vs last month</span>
                  </div>
                </div>
                <div style={{ display: "flex", gap: 12, marginBottom: 16 }}>
                  {[["186", "Trips"],["4.91","Rating"],["₹174","Avg/Trip"]].map(([v,l],i)=>(
                    <div key={i} style={{ flex: 1, background: "rgba(255,255,255,0.04)", borderRadius: 12, padding: "12px 8px", textAlign: "center" }}>
                      <div style={{ fontSize: 18, fontWeight: 900, color: "white" }}>{v}</div>
                      <div style={{ fontSize: 10, color: "rgba(255,255,255,0.3)", marginTop: 2 }}>{l}</div>
                    </div>
                  ))}
                </div>
                <div style={{ background: "linear-gradient(135deg,#16A34A,#15803D)", borderRadius: 14, padding: "14px", textAlign: "center", boxShadow: "0 6px 20px rgba(22,163,74,0.35)" }}>
                  <div style={{ fontSize: 13, fontWeight: 800, color: "white" }}>💰 Payout Today — ₹1,240</div>
                  <div style={{ fontSize: 11, color: "rgba(255,255,255,0.6)", marginTop: 3 }}>Credited to wallet ✓</div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* ── CITIES ── */}
      <section id="cities" style={{ background: "#F8FAFF" }}>
        <div style={{ maxWidth: 1200, margin: "0 auto", padding: "0 24px" }}>
          <div className="reveal" style={{ textAlign: "center", marginBottom: 48 }}>
            <div style={{ display: "inline-block", background: "#EFF6FF", border: "1px solid #BFDBFE", borderRadius: 20, padding: "6px 18px", fontSize: 12, fontWeight: 700, color: "#1E6DE5", marginBottom: 16, letterSpacing: 1 }}>COVERAGE</div>
            <h2 style={{ fontSize: "clamp(28px, 4vw, 44px)", fontWeight: 900, color: "#0F172A", margin: "0 0 14px", letterSpacing: -0.5 }}>Cities We Serve</h2>
            <p style={{ fontSize: 17, color: "#64748B" }}>Expanding across Telangana &amp; Andhra Pradesh</p>
          </div>

          <div style={{ display: "flex", flexWrap: "wrap", gap: 12, justifyContent: "center", marginBottom: 32 }}>
            {[
              { name: "Hyderabad", status: "live", zones: 5 },
              { name: "Secunderabad", status: "live", zones: 1 },
              { name: "Gachibowli", status: "live", zones: 1 },
              { name: "Hitec City", status: "live", zones: 1 },
              { name: "Vijayawada", status: "live", zones: 1 },
              { name: "Amaravathi", status: "live", zones: 1 },
              { name: "Mangalagiri", status: "live", zones: 1 },
              { name: "Narasaraopet", status: "live", zones: 1 },
              { name: "Guntur", status: "soon", zones: 0 },
              { name: "Visakhapatnam", status: "soon", zones: 0 },
              { name: "Warangal", status: "soon", zones: 0 },
            ].map((c, i) => (
              <div key={i} style={{
                display: "flex", alignItems: "center", gap: 8,
                background: c.status === "live" ? "white" : "#F8FAFF",
                border: `1.5px solid ${c.status === "live" ? "#BFDBFE" : "#E2E8F0"}`,
                borderRadius: 12, padding: "10px 18px",
                boxShadow: c.status === "live" ? "0 2px 8px rgba(30,109,229,0.1)" : "none",
              }}>
                <div style={{ width: 7, height: 7, borderRadius: "50%", background: c.status === "live" ? "#22C55E" : "#CBD5E1", boxShadow: c.status === "live" ? "0 0 6px rgba(34,197,94,0.6)" : "none" }} />
                <span style={{ fontSize: 14, fontWeight: 700, color: c.status === "live" ? "#0F172A" : "#94A3B8" }}>{c.name}</span>
                {c.status === "live" && <span style={{ fontSize: 11, background: "#EFF6FF", color: "#1E6DE5", borderRadius: 6, padding: "2px 7px", fontWeight: 600 }}>{c.zones} zone{c.zones > 1 ? "s" : ""}</span>}
                {c.status === "soon" && <span style={{ fontSize: 10, color: "#CBD5E1", fontWeight: 600 }}>Coming Soon</span>}
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* ── APP DOWNLOAD ── */}
      <section id="download" style={{ background: "linear-gradient(140deg, #050b1f 0%, #071230 60%, #0a1640 100%)", position: "relative", overflow: "hidden" }}>
        <div style={{ position: "absolute", top: "50%", left: "50%", transform: "translate(-50%,-50%)", width: 800, height: 800, borderRadius: "50%", background: "radial-gradient(circle, rgba(30,109,229,0.1) 0%, transparent 65%)" }} />
        <div style={{ maxWidth: 1200, margin: "0 auto", padding: "0 24px", position: "relative" }}>
          <div className="download-grid">
            {/* Customer */}
            <div style={{ background: "rgba(255,255,255,0.03)", border: "1px solid rgba(255,255,255,0.07)", borderRadius: 28, padding: 36 }}>
              <img src={jagoLogoWhite} style={{ height: 34, objectFit: "contain", marginBottom: 20 }} alt="JAGO" />
              <h3 style={{ fontSize: 28, fontWeight: 900, color: "white", margin: "0 0 12px", lineHeight: 1.2 }}>JAGO Customer App</h3>
              <p style={{ fontSize: 15, color: "rgba(255,255,255,0.5)", marginBottom: 24, lineHeight: 1.65 }}>
                Book rides, track parcels, and pay instantly — available on Android &amp; iOS.
              </p>
              <div style={{ display: "flex", gap: 12, flexWrap: "wrap" }}>
                <a href="https://play.google.com/store" target="_blank" rel="noreferrer" style={{ display: "flex", alignItems: "center", gap: 10, background: "white", borderRadius: 12, padding: "12px 20px", textDecoration: "none", transition: "transform 0.2s" }}>
                  <svg width="22" height="22" viewBox="0 0 24 24"><path d="M3.609 1.814A.5.5 0 0 0 3 2.5v19a.5.5 0 0 0 .61.49l18-5.5a.5.5 0 0 0 0-.98l-18-13.7z" fill="#00C773"/></svg>
                  <div>
                    <div style={{ fontSize: 9, color: "#374151", fontWeight: 600 }}>GET IT ON</div>
                    <div style={{ fontSize: 13, color: "#0F172A", fontWeight: 800 }}>Google Play</div>
                  </div>
                </a>
                <a href="https://apps.apple.com" target="_blank" rel="noreferrer" style={{ display: "flex", alignItems: "center", gap: 10, background: "white", borderRadius: 12, padding: "12px 20px", textDecoration: "none" }}>
                  <svg width="22" height="22" viewBox="0 0 24 24" fill="none"><path d="M18.71 19.5C17.88 20.74 17 21.95 15.66 21.97C14.32 22 13.89 21.18 12.37 21.18C10.84 21.18 10.37 21.95 9.1 22C7.78 22.05 6.8 20.68 5.96 19.47C4.25 17 2.94 12.45 4.7 9.39C5.57 7.87 7.13 6.91 8.82 6.88C10.1 6.86 11.32 7.75 12.11 7.75C12.89 7.75 14.37 6.68 15.92 6.84C16.57 6.87 18.39 7.1 19.56 8.82C19.47 8.88 17.39 10.1 17.41 12.63C17.44 15.65 20.06 16.66 20.09 16.67C20.06 16.74 19.67 18.11 18.71 19.5Z" fill="#1C1C1C"/></svg>
                  <div>
                    <div style={{ fontSize: 9, color: "#374151", fontWeight: 600 }}>DOWNLOAD ON</div>
                    <div style={{ fontSize: 13, color: "#0F172A", fontWeight: 800 }}>App Store</div>
                  </div>
                </a>
              </div>
            </div>

            {/* Driver */}
            <div style={{ background: "rgba(37,99,235,0.06)", border: "1px solid rgba(37,99,235,0.2)", borderRadius: 28, padding: 36 }}>
              <img src={pilotLogo} style={{ height: 34, objectFit: "contain", marginBottom: 20 }} alt="JAGO Pilot" />
              <h3 style={{ fontSize: 28, fontWeight: 900, color: "white", margin: "0 0 12px", lineHeight: 1.2 }}>JAGO Pilot App</h3>
              <p style={{ fontSize: 15, color: "rgba(255,255,255,0.5)", marginBottom: 24, lineHeight: 1.65 }}>
                Accept trips, track earnings, and manage your schedule — built for pilots.
              </p>
              <div style={{ display: "flex", gap: 12, flexWrap: "wrap" }}>
                <a href="https://play.google.com/store" target="_blank" rel="noreferrer" style={{ display: "flex", alignItems: "center", gap: 10, background: "linear-gradient(135deg,#2563EB,#1D4ED8)", borderRadius: 12, padding: "12px 20px", textDecoration: "none", boxShadow: "0 6px 20px rgba(37,99,235,0.35)" }}>
                  <svg width="22" height="22" viewBox="0 0 24 24"><path d="M3.609 1.814A.5.5 0 0 0 3 2.5v19a.5.5 0 0 0 .61.49l18-5.5a.5.5 0 0 0 0-.98l-18-13.7z" fill="white"/></svg>
                  <div>
                    <div style={{ fontSize: 9, color: "rgba(255,255,255,0.6)", fontWeight: 600 }}>GET IT ON</div>
                    <div style={{ fontSize: 13, color: "white", fontWeight: 800 }}>Google Play</div>
                  </div>
                </a>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* ── FOOTER ── */}
      <footer style={{ background: "#030810", borderTop: "1px solid rgba(255,255,255,0.05)" }}>
        <div style={{ maxWidth: 1200, margin: "0 auto", padding: "60px 24px 30px" }}>
          <div className="footer-grid">
            {/* Brand */}
            <div>
              <img src={jagoLogoWhite} style={{ height: 60, objectFit: "contain", marginBottom: 20 }} alt="JAGO" />
              <p style={{ fontSize: 14, color: "rgba(255,255,255,0.4)", lineHeight: 1.7, marginBottom: 20, maxWidth: 280 }}>
                JAGO is a trusted smart mobility network connecting riders, pilots, and businesses through secure, OTP-first, AI-assisted transportation and logistics.
              </p>
              <div style={{ display: "flex", gap: 10 }}>
                {[
                    ["Facebook", "https://jagopro.org", "M18 2h-3a5 5 0 0 0-5 5v3H7v4h3v8h4v-8h3l1-4h-4V7a1 1 0 0 1 1-1h3z"],
                    ["Instagram", "https://jagopro.org", "M16 11.37A4 4 0 1 1 12.63 8 4 4 0 0 1 16 11.37z M17.5 6.5h.01 M7 2h10a5 5 0 0 1 5 5v10a5 5 0 0 1-5 5H7a5 5 0 0 1-5-5V7a5 5 0 0 1 5-5z"],
                    ["Twitter", "https://jagopro.org", "M23 3a10.9 10.9 0 0 1-3.14 1.53 4.48 4.48 0 0 0-7.86 3v1A10.66 10.66 0 0 1 3 4s-4 9 5 13a11.64 11.64 0 0 1-7 2c9 5 20 0 20-11.5a4.5 4.5 0 0 0-.08-.83A7.72 7.72 0 0 0 23 3z"],
                  ].map(([name, href, path]) => (
                    <a key={name} href={href} target="_blank" rel="noreferrer" style={{ width: 36, height: 36, borderRadius: "50%", background: "rgba(255,255,255,0.05)", border: "1px solid rgba(255,255,255,0.08)", display: "flex", alignItems: "center", justifyContent: "center" }}>
                    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="rgba(255,255,255,0.5)" strokeWidth="2" strokeLinecap="round">
                      <path d={path}/>
                    </svg>
                  </a>
                ))}
              </div>
            </div>

            {/* Quick Links */}
            <div>
              <div style={{ fontSize: 12, fontWeight: 700, color: "rgba(255,255,255,0.3)", letterSpacing: 1.5, textTransform: "uppercase", marginBottom: 20 }}>Company</div>
              {[
                { label: "About Us", href: "/about-us" },
                { label: "Contact Us", href: "/contact-us" },
                { label: "Privacy Policy", href: "/privacy" },
                { label: "Terms & Conditions", href: "/terms" },
                { label: "Refund Policy", href: "/refund-policy" },
                { label: "Cookie Policy", href: "/cookie-policy" },
              ].map(l => (
                <a key={l.label} href={l.href} style={{ display: "block", fontSize: 14, color: "rgba(255,255,255,0.5)", marginBottom: 10, textDecoration: "none", transition: "color 0.2s" }}
                  onMouseEnter={e => (e.target as HTMLElement).style.color = "white"}
                  onMouseLeave={e => (e.target as HTMLElement).style.color = "rgba(255,255,255,0.5)"}
                >{l.label}</a>
              ))}
            </div>

            {/* Services */}
            <div>
              <div style={{ fontSize: 12, fontWeight: 700, color: "rgba(255,255,255,0.3)", letterSpacing: 1.5, textTransform: "uppercase", marginBottom: 20 }}>Services</div>
              {["Ride Sharing", "Parcel Delivery", "Cargo & Logistics", "B2B Solutions", "Scheduled Rides"].map(l => (
                <a key={l} href="#solutions" style={{ display: "block", fontSize: 14, color: "rgba(255,255,255,0.5)", marginBottom: 10, textDecoration: "none" }}>{l}</a>
              ))}
            </div>

            {/* Contact */}
            <div>
              <div style={{ fontSize: 12, fontWeight: 700, color: "rgba(255,255,255,0.3)", letterSpacing: 1.5, textTransform: "uppercase", marginBottom: 20 }}>Contact</div>
              {[
                { icon: "✉️", text: "info@jagopro.org", href: "mailto:info@jagopro.org" },
                { icon: "📞", text: "+91 80081 01119", href: "tel:+918008101119" },
                { icon: "📍", text: "Hyderabad, Telangana", href: "/contact-us" },
              ].map((c, i) => (
                <div key={i} style={{ display: "flex", alignItems: "flex-start", gap: 10, marginBottom: 14 }}>
                  <span style={{ fontSize: 14 }}>{c.icon}</span>
                  <a href={c.href} style={{ fontSize: 13, color: "rgba(255,255,255,0.5)", textDecoration: "none" }}>{c.text}</a>
                </div>
              ))}
            </div>
          </div>

          <div style={{ borderTop: "1px solid rgba(255,255,255,0.06)", paddingTop: 24, display: "flex", alignItems: "center", justifyContent: "space-between", flexWrap: "wrap", gap: 16 }}>
            <p style={{ fontSize: 13, color: "rgba(255,255,255,0.25)", margin: 0 }}>
              © {new Date().getFullYear()} MindWhile IT Solutions Pvt Ltd. All rights reserved.
            </p>
            <div style={{ display: "flex", gap: 24, flexWrap: "wrap" }}>
              {[
                { label: "Privacy Policy", href: "/privacy" },
                { label: "Terms & Conditions", href: "/terms" },
                { label: "Refund Policy", href: "/refund-policy" },
                { label: "Cookie Policy", href: "/cookie-policy" },
                { label: "About", href: "/about-us" },
                { label: "Contact", href: "/contact-us" },
              ].map(l => (
                <a key={l.label} href={l.href} style={{ fontSize: 12, color: "rgba(255,255,255,0.25)", textDecoration: "none" }}>{l.label}</a>
              ))}
            </div>
          </div>
        </div>
      </footer>
    </div>
  );
}
