import { useEffect, useState, useRef } from "react";
import { useTheme } from "@/components/theme-provider";

const jagoLogoWhite = "/jago-logo-white.png";
const jagoLogoBlue = "/jago-logo-blue.png";
const pilotLogo = "/pilot-logo.png";

function useReveal() {
  useEffect(() => {
    const observer = new IntersectionObserver(
      (entries) =>
        entries.forEach((e) => {
          if (e.isIntersecting) {
            e.target.classList.add("revealed");
            observer.unobserve(e.target);
          }
        }),
      { threshold: 0.1 }
    );
    document.querySelectorAll(".reveal").forEach((el) => observer.observe(el));
    return () => observer.disconnect();
  }, []);
}

function useCountUp(target: number, duration = 1800) {
  const [count, setCount] = useState(0);
  const [started, setStarted] = useState(false);
  const ref = useRef<HTMLDivElement>(null);
  useEffect(() => {
    const el = ref.current;
    if (!el) return;
    const io = new IntersectionObserver(
      ([entry]) => { if (entry.isIntersecting) { setStarted(true); io.disconnect(); } },
      { threshold: 0.5 }
    );
    io.observe(el);
    return () => io.disconnect();
  }, []);
  useEffect(() => {
    if (!started) return;
    let t = 0;
    const tick = (ts: number) => {
      if (!t) t = ts;
      const p = Math.min((ts - t) / duration, 1);
      const eased = 1 - Math.pow(1 - p, 3);
      setCount(Math.floor(eased * target));
      if (p < 1) requestAnimationFrame(tick);
    };
    requestAnimationFrame(tick);
  }, [started, target, duration]);
  return { count, ref };
}

/* ──────────── Vehicle SVGs ──────────── */
const BikeSvg = ({ c }: { c: string }) => (
  <svg width="58" height="30" viewBox="0 0 58 30" fill="none">
    <circle cx="11" cy="22" r="7.5" stroke={c} strokeWidth="2.4" />
    <circle cx="47" cy="22" r="7.5" stroke={c} strokeWidth="2.4" />
    <path d="M11 22 L21 7 L29 22" stroke={c} strokeWidth="2.3" strokeLinejoin="round" />
    <path d="M21 7 L36 7 L47 22" stroke={c} strokeWidth="2.3" strokeLinejoin="round" />
    <path d="M34 5 L38 3 M34 9 L38 7" stroke={c} strokeWidth="2" strokeLinecap="round" />
    <circle cx="21" cy="7" r="2.5" fill={c} />
  </svg>
);
const AutoSvg = ({ c }: { c: string }) => (
  <svg width="70" height="34" viewBox="0 0 70 34" fill="none">
    <path d="M8 13 Q23 3 45 8 L52 8 L56 13 L56 27 L8 27 Z" fill={c} fillOpacity="0.84" />
    <path d="M8 13 L45 8 L45 13 Z" fill={c} fillOpacity="0.5" />
    <rect x="56" y="15" width="10" height="10" rx="2.5" fill={c} fillOpacity="0.7" />
    <circle cx="18" cy="29" r="5.5" stroke="white" strokeWidth="2" fill="none" />
    <circle cx="52" cy="29" r="5.5" stroke="white" strokeWidth="2" fill="none" />
    <rect x="16" y="10" width="10" height="6" rx="1.5" fill="white" fillOpacity="0.35" />
    <rect x="29" y="10" width="10" height="6" rx="1.5" fill="white" fillOpacity="0.35" />
  </svg>
);
const CarSvg = ({ c }: { c: string }) => (
  <svg width="80" height="36" viewBox="0 0 80 36" fill="none">
    <rect x="6" y="18" width="68" height="13" rx="5" fill={c} fillOpacity="0.86" />
    <path d="M18 18 L27 8 L53 8 L64 18 Z" fill={c} fillOpacity="0.74" />
    <circle cx="19" cy="31" r="6" stroke="white" strokeWidth="2" fill="none" />
    <circle cx="61" cy="31" r="6" stroke="white" strokeWidth="2" fill="none" />
    <rect x="28" y="9" width="11" height="7" rx="1.5" fill="white" fillOpacity="0.32" />
    <rect x="42" y="9" width="11" height="7" rx="1.5" fill="white" fillOpacity="0.32" />
    <rect x="65" y="22" width="5" height="3" rx="1" fill="white" fillOpacity="0.45" />
  </svg>
);
const VanSvg = ({ c }: { c: string }) => (
  <svg width="88" height="38" viewBox="0 0 88 38" fill="none">
    <rect x="4" y="7" width="74" height="25" rx="4" fill={c} fillOpacity="0.8" />
    <rect x="4" y="7" width="24" height="25" rx="4" fill={c} fillOpacity="1" />
    <rect x="8" y="11" width="14" height="9" rx="2" fill="white" fillOpacity="0.38" />
    <rect x="34" y="14" width="38" height="14" rx="2" fill="white" fillOpacity="0.1" stroke="white" strokeWidth="0.8" strokeOpacity="0.25" />
    <text x="38" y="24" fontSize="7.5" fontWeight="900" fill="white" opacity="0.9" fontFamily="sans-serif" letterSpacing="0.6">JAGO</text>
    <circle cx="17" cy="34" r="5.5" stroke="white" strokeWidth="2" fill="none" />
    <circle cx="62" cy="34" r="5.5" stroke="white" strokeWidth="2" fill="none" />
    <rect x="77" y="19" width="6" height="9" rx="1" fill="white" fillOpacity="0.28" />
  </svg>
);

/* ──────────── Animated Road ──────────── */
function AnimatedRoad({ isDark }: { isDark: boolean }) {
  const lanes = [
    { Svg: BikeSvg, c: "#1E6DE5", top: 6,  dur: 6.2, del: 0 },
    { Svg: AutoSvg, c: "#10B981", top: 50, dur: 8.4, del: 1.6 },
    { Svg: CarSvg,  c: "#818CF8", top: 6,  dur: 10.2,del: 4.1 },
    { Svg: VanSvg,  c: "#F59E0B", top: 50, dur: 7.1, del: 2.9 },
    { Svg: BikeSvg, c: "#34D399", top: 6,  dur: 5.0, del: 7.3 },
    { Svg: AutoSvg, c: "#1E6DE5", top: 50, dur: 9.5, del: 5.8 },
    { Svg: CarSvg,  c: "#F472B6", top: 6,  dur: 11.4,del: 9.2 },
    { Svg: VanSvg,  c: "#2563EB", top: 50, dur: 6.6, del: 0.6 },
    { Svg: BikeSvg, c: "#FB923C", top: 6,  dur: 7.8, del: 12.1},
    { Svg: CarSvg,  c: "#22D3EE", top: 50, dur: 8.9, del: 3.4 },
  ];
  return (
    <div style={{ position: "relative", width: "100%", height: 104, background: isDark ? "#060e22" : "#111827", overflow: "hidden" }}>
      <div style={{ position: "absolute", inset: 0, background: "repeating-linear-gradient(180deg,rgba(255,255,255,0.018) 0,rgba(255,255,255,0.018) 1px,transparent 1px,transparent 12px)" }} />
      <div style={{ position: "absolute", top: 0, left: 0, right: 0, height: 2, background: "rgba(255,255,255,0.07)" }} />
      {/* animated dash lane divider */}
      <div style={{ position: "absolute", top: 48, left: 0, right: 0, height: 3, overflow: "hidden" }}>
        <div style={{ display: "flex", animation: "jago-lane-dash 0.48s linear infinite", width: "200%" }}>
          {Array.from({ length: 100 }).map((_, i) => (
            <div key={i} style={{ width: 22, height: 3, background: i % 2 === 0 ? "rgba(255,255,255,0.2)" : "transparent", flexShrink: 0 }} />
          ))}
        </div>
      </div>
      <div style={{ position: "absolute", bottom: 0, left: 0, right: 0, height: 2, background: "rgba(255,255,255,0.07)" }} />
      {lanes.map((v, i) => (
        <div key={i} style={{ position: "absolute", top: v.top, left: 0, animation: `jago-drive ${v.dur}s linear ${v.del}s infinite`, filter: "drop-shadow(0 3px 10px rgba(30,109,229,0.5))" }}>
          <v.Svg c={v.c} />
        </div>
      ))}
      <div style={{ position: "absolute", top: "50%", right: 16, transform: "translateY(-50%)", zIndex: 2, background: "rgba(4,9,28,0.9)", border: "1px solid rgba(30,109,229,0.4)", borderRadius: 8, padding: "4px 10px", fontSize: 9, fontWeight: 900, color: "#1E6DE5", letterSpacing: 1 }}>
        ● LIVE FLEET
      </div>
    </div>
  );
}

/* ──────────── Booking Flow Widget ──────────── */
function BookingFlow({ isDark }: { isDark: boolean }) {
  const [step, setStep] = useState(0);
  useEffect(() => {
    const t = setInterval(() => setStep((s) => (s + 1) % 3), 2800);
    return () => clearInterval(t);
  }, []);
  const steps = [
    { emoji: "📍", label: "BOOK",   title: "Customer Books Instantly",   desc: 'AI voice or tap — say "Book a bike to JNTU" and it\'s done in seconds.', color: "#1E6DE5" },
    { emoji: "⚡", label: "MATCH",  title: "Jago Pilot Accepts",          desc: "Nearest verified driver gets the trip request and accepts with one tap.",  color: "#10B981" },
    { emoji: "🛣️", label: "RIDE",   title: "Live Trip in Progress",       desc: "Real-time GPS tracking, voice ETA updates, and safe arrival confirmation.", color: "#818CF8" },
  ];
  const panelBg = isDark ? "rgba(8,18,46,0.94)" : "rgba(247,252,255,0.97)";
  const bdr     = isDark ? "rgba(80,140,255,0.22)" : "rgba(30,109,229,0.15)";
  const tMain   = isDark ? "#f0f6ff" : "#0e1d3a";
  const tSub    = isDark ? "rgba(200,220,255,0.62)" : "#4e6487";
  return (
    <div style={{ background: panelBg, border: `1px solid ${bdr}`, borderRadius: 24, padding: "28px 22px", backdropFilter: "blur(16px)", boxShadow: isDark ? "0 28px 70px rgba(0,0,0,0.6)" : "0 20px 56px rgba(30,109,229,0.12)" }}>
      <div style={{ fontSize: 11, fontWeight: 900, color: "#1E6DE5", letterSpacing: 1, marginBottom: 18 }}>HOW IT WORKS</div>
      {/* tabs */}
      <div style={{ display: "flex", gap: 6, marginBottom: 16 }}>
        {steps.map((s, i) => (
          <button key={i} onClick={() => setStep(i)} style={{ flex: 1, padding: "7px 2px", borderRadius: 9, cursor: "pointer", border: `1.5px solid ${i === step ? s.color + "55" : bdr}`, background: i === step ? `${s.color}16` : "transparent", color: i === step ? s.color : tSub, fontSize: 10, fontWeight: 900, letterSpacing: 0.5, transition: "all 0.3s" }}>
            {s.label}
          </button>
        ))}
      </div>
      {/* progress bar */}
      <div style={{ display: "flex", gap: 5, marginBottom: 22 }}>
        {steps.map((s, i) => (
          <div key={i} style={{ flex: 1, height: 3, borderRadius: 2, background: i <= step ? s.color : isDark ? "rgba(255,255,255,0.1)" : "rgba(30,109,229,0.1)", transition: "background 0.5s" }} />
        ))}
      </div>
      {/* active step */}
      <div style={{ minHeight: 90 }}>
        {steps.map((s, i) => i === step && (
          <div key={i} style={{ display: "flex", alignItems: "center", gap: 16, animation: "jago-fade-up 0.38s ease" }}>
            <div style={{ width: 62, height: 62, borderRadius: 18, background: `${s.color}18`, border: `2px solid ${s.color}45`, display: "grid", placeItems: "center", fontSize: 28, flexShrink: 0 }}>{s.emoji}</div>
            <div>
              <div style={{ fontSize: 16, fontWeight: 900, color: tMain, marginBottom: 7 }}>{s.title}</div>
              <div style={{ fontSize: 13, color: tSub, lineHeight: 1.58 }}>{s.desc}</div>
            </div>
          </div>
        ))}
      </div>
      {/* connector dots */}
      <div style={{ display: "flex", alignItems: "center", marginTop: 18 }}>
        {steps.flatMap((s, i) => {
          const items = [
            <div key={`d${i}`} style={{ width: 10, height: 10, borderRadius: "50%", background: i <= step ? s.color : isDark ? "rgba(255,255,255,0.14)" : "rgba(30,109,229,0.18)", transition: "background 0.4s" }} />,
          ];
          if (i < steps.length - 1) items.push(<div key={`l${i}`} style={{ flex: 1, height: 2, background: i < step ? `linear-gradient(90deg,${s.color},${steps[i+1].color})` : isDark ? "rgba(255,255,255,0.08)" : "rgba(30,109,229,0.1)", transition: "background 0.4s" }} />);
          return items;
        })}
      </div>
      {/* vehicle strip */}
      <div style={{ marginTop: 18, padding: "11px 14px", borderRadius: 12, background: isDark ? "rgba(30,109,229,0.08)" : "rgba(30,109,229,0.05)", border: `1px solid ${bdr}`, fontSize: 11, color: tSub, display: "flex", alignItems: "center", gap: 8 }}>
        <span style={{ fontSize: 18 }}>🏍️🛺🚗🚚</span>
        <span style={{ fontWeight: 700 }}>Bikes · Autos · Cars · Parcels · Intercity</span>
      </div>
    </div>
  );
}

/* ──────────── Main Landing Page ──────────── */
export default function LandingPage() {
  const [menuOpen, setMenuOpen] = useState(false);
  const [scrolled, setScrolled] = useState(false);
  const { theme, setTheme } = useTheme();
  const isDark = theme === "dark";
  useReveal();

  const rides   = useCountUp(50000);
  const cities  = useCountUp(6);
  const drivers = useCountUp(1200);

  useEffect(() => {
    const fn = () => setScrolled(window.scrollY > 50);
    window.addEventListener("scroll", fn);
    return () => window.removeEventListener("scroll", fn);
  }, []);

  const nav = [
    { label: "Rides",        href: "#solutions" },
    { label: "Parcel",       href: "#solutions" },
    { label: "Cities",       href: "#cities"    },
    { label: "Drive with Us",href: "#driver"    },
    { label: "About",        href: "/about-us"  },
  ];

  const blue   = "#1E6DE5";
  const green  = "#10B981";
  const violet = "#818CF8";
  const amber  = "#F59E0B";

  const bg = isDark
    ? `radial-gradient(ellipse 1300px 700px at 85% -8%,rgba(30,109,229,0.24) 0,transparent 55%),radial-gradient(ellipse 900px 620px at -5% 110%,rgba(16,185,129,0.14) 0,transparent 55%),#04091c`
    : `radial-gradient(ellipse 1200px 700px at 90% -8%,rgba(30,109,229,0.14) 0,transparent 55%),radial-gradient(ellipse 900px 600px at -5% 110%,rgba(16,185,129,0.1) 0,transparent 55%),#f4f7ff`;
  const panel       = isDark ? "rgba(10,22,52,0.76)" : "rgba(255,255,255,0.92)";
  const panelStrong = isDark ? "#0f1c38" : "#ffffff";
  const border      = isDark ? "rgba(100,160,255,0.18)" : "rgba(30,109,229,0.14)";
  const textMain    = isDark ? "#f0f6ff" : "#0e1d3a";
  const textSub     = isDark ? "rgba(200,222,255,0.64)" : "#4e6487";
  const strip       = isDark ? "#060d22" : "#edf4ff";
  const navBg       = scrolled ? (isDark ? "rgba(4,9,28,0.92)" : "rgba(244,247,255,0.95)") : "transparent";

  const services = [
    { icon: "🏍️", name: "Jago Bike",      cat: "Rides",     desc: "Fast solo bike rides — perfect for quick city hops through traffic.",              color: blue   },
    { icon: "🛺", name: "Jago Auto",      cat: "Rides",     desc: "Comfortable auto rides for 1–3 passengers, street-smart daily commuting.",         color: green  },
    { icon: "🚗", name: "Jago Car",       cat: "Premium",   desc: "AC sedans & SUVs for premium city rides with extra comfort.",                      color: violet },
    { icon: "🛣️", name: "Jago Intercity", cat: "Shared",    desc: "Affordable city-to-city car sharing between AP & Telangana cities.",               color: amber  },
    { icon: "📦", name: "Jago Parcel",    cat: "Delivery",  desc: "Same-day parcel & package delivery on bikes — fast, reliable, trackable.",         color: "#EF4444" },
    { icon: "🚚", name: "Jago Goods",     cat: "Logistics", desc: "Cargo trucks & mini-vehicles for business goods & bulk deliveries.",               color: "#A855F7" },
  ];
  const whys = [
    { icon: "🎤", title: "AI Voice Booking",    desc: "Book in Telugu, Hindi, or English — AI understands natural speech instantly.", color: blue   },
    { icon: "⚡", title: "30-Second Match",      desc: "Industry-leading driver matching speed — trip confirmed in under 30 seconds.", color: green  },
    { icon: "🔒", title: "Verified Pilots",      desc: "KYC, face verification, document checks & live ratings on every driver.",     color: violet },
    { icon: "💰", title: "Transparent Pricing",  desc: "Full fare breakdown before you confirm — zero surprise surges.",              color: amber  },
  ];

  return (
    <div style={{ fontFamily: "'Space Grotesk','Plus Jakarta Sans','Segoe UI',sans-serif", background: bg, color: textMain, minHeight: "100vh" }}>
      <style>{`
        @import url('https://fonts.googleapis.com/css2?family=Space+Grotesk:wght@500;600;700;800&family=Plus+Jakarta+Sans:wght@400;500;600;700;800&display=swap');
        *,*::before,*::after{box-sizing:border-box}
        html,body{margin:0;padding:0;scroll-behavior:smooth}
        a{color:inherit;text-decoration:none}
        button{font-family:inherit}
        .reveal{opacity:0;transform:translateY(24px);transition:opacity .65s ease,transform .65s ease}
        .reveal.revealed{opacity:1;transform:translateY(0)}
        .g1{transition-delay:.04s}.g2{transition-delay:.1s}.g3{transition-delay:.16s}.g4{transition-delay:.22s}

        @keyframes jago-drive{
          0%{transform:translateX(-220px);opacity:0}
          4%{opacity:1}96%{opacity:1}
          100%{transform:translateX(calc(100vw + 220px));opacity:0}
        }
        @keyframes jago-lane-dash{from{transform:translateX(0)}to{transform:translateX(-44px)}}
        @keyframes jago-fade-up{from{opacity:0;transform:translateY(12px)}to{opacity:1;transform:translateY(0)}}
        @keyframes jago-float{0%,100%{transform:translateY(0)}50%{transform:translateY(-8px)}}
        @keyframes jago-pulse{0%,100%{box-shadow:0 8px 30px rgba(30,109,229,.5)}50%{box-shadow:0 8px 56px rgba(30,109,229,.85)}}
        @keyframes jago-badge{0%,100%{opacity:1}50%{opacity:.35}}
        @keyframes jago-glow{0%,100%{opacity:.55;transform:scale(1)}50%{opacity:.85;transform:scale(1.08)}}

        .jago-float{animation:jago-float 3.2s ease-in-out infinite}
        .jago-pulse-btn{animation:jago-pulse 2.6s ease infinite}
        .nav-lnk:hover{color:#1E6DE5 !important}
        .svc-card:hover{transform:translateY(-5px) !important;box-shadow:0 22px 55px rgba(30,109,229,.18) !important}
        .dl-btn:hover{opacity:.86;transform:translateY(-2px)}

        .sec{padding:96px 0}
        .hero-grid{display:grid;grid-template-columns:1.12fr .88fr;gap:44px;align-items:center}
        .svc-grid{display:grid;grid-template-columns:repeat(3,1fr);gap:18px}
        .why-grid{display:grid;grid-template-columns:repeat(4,1fr);gap:16px}
        .duo-grid{display:grid;grid-template-columns:1fr 1fr;gap:22px}
        .cities-grid{display:grid;grid-template-columns:repeat(6,1fr);gap:12px}
        .footer-grid{display:grid;grid-template-columns:1.4fr 1fr 1fr 1fr;gap:36px}
        .dl-grid{display:grid;grid-template-columns:1fr auto;gap:24px;align-items:center}

        @media(max-width:1040px){
          .svc-grid{grid-template-columns:repeat(2,1fr)}
          .why-grid{grid-template-columns:repeat(2,1fr)}
          .cities-grid{grid-template-columns:repeat(3,1fr)}
          .footer-grid{grid-template-columns:1fr 1fr}
        }
        @media(max-width:768px){
          .hero-grid,.duo-grid,.dl-grid{grid-template-columns:1fr}
          .cities-grid{grid-template-columns:repeat(2,1fr)}
          .sec{padding:64px 0}
          .desktop-nav{display:none !important}
        }
        @media(max-width:520px){
          .svc-grid,.why-grid,.footer-grid{grid-template-columns:1fr}
        }
      `}</style>

      {/* ─── NAV ─── */}
      <nav style={{ position: "fixed", top: 0, left: 0, right: 0, zIndex: 50, background: navBg, borderBottom: scrolled ? `1px solid ${border}` : "1px solid transparent", backdropFilter: scrolled ? "blur(18px)" : "none", transition: "all 0.3s ease" }}>
        <div style={{ maxWidth: 1180, margin: "0 auto", padding: "0 20px", height: 68, display: "flex", alignItems: "center", justifyContent: "space-between" }}>
          <a href="/" style={{ display: "flex", alignItems: "center", gap: 10 }}>
            <img src={isDark ? jagoLogoWhite : jagoLogoBlue} alt="JAGO" style={{ height: 36, objectFit: "contain" }} />
          </a>
          <div className="desktop-nav" style={{ display: "flex", alignItems: "center", gap: 26 }}>
            {nav.map(item => (
              <a key={item.label} href={item.href} className="nav-lnk" style={{ fontSize: 13, fontWeight: 700, color: textSub, transition: "color 0.2s" }}>{item.label}</a>
            ))}
          </div>
          <div style={{ display: "flex", gap: 8 }}>
            <button onClick={() => setTheme(isDark ? "light" : "dark")} style={{ border: `1px solid ${border}`, background: panel, color: textMain, borderRadius: 10, padding: "7px 14px", fontSize: 12, fontWeight: 700, cursor: "pointer" }}>
              {isDark ? "☀️ Light" : "🌙 Dark"}
            </button>
            <button onClick={() => setMenuOpen(v => !v)} style={{ border: `1px solid ${border}`, background: panel, color: textMain, borderRadius: 10, padding: "7px 14px", fontSize: 14, fontWeight: 700, cursor: "pointer" }}>☰</button>
          </div>
        </div>
      </nav>

      {/* ─── MOBILE MENU ─── */}
      {menuOpen && (
        <div onClick={() => setMenuOpen(false)} style={{ position: "fixed", inset: 0, zIndex: 40, backdropFilter: "blur(14px)", background: isDark ? "rgba(4,9,28,0.86)" : "rgba(235,243,255,0.88)", display: "flex", alignItems: "center", justifyContent: "center" }}>
          <div style={{ width: "min(90vw,400px)", borderRadius: 22, padding: 24, background: panelStrong, border: `1px solid ${border}` }}>
            {nav.map((item, i) => (
              <a key={item.label} href={item.href} style={{ display: "block", fontSize: 18, fontWeight: 800, padding: "14px 6px", color: textMain, borderBottom: i < nav.length - 1 ? `1px solid ${border}` : "none" }}>{item.label}</a>
            ))}
            <a href="/admin" style={{ display: "block", marginTop: 16, padding: "13px 0", textAlign: "center", background: blue, color: "#fff", borderRadius: 14, fontWeight: 800, fontSize: 14 }}>Admin Login</a>
          </div>
        </div>
      )}

      {/* ─── HERO ─── */}
      <section className="sec" style={{ paddingTop: 108, paddingBottom: 0, position: "relative" }}>
        {/* glow blobs */}
        <div style={{ position: "absolute", top: 120, right: "8%", width: 520, height: 520, borderRadius: "50%", background: "radial-gradient(circle,rgba(30,109,229,0.17),transparent 70%)", animation: "jago-glow 5s ease infinite", pointerEvents: "none" }} />
        <div style={{ position: "absolute", top: 300, left: "5%", width: 360, height: 360, borderRadius: "50%", background: "radial-gradient(circle,rgba(16,185,129,0.1),transparent 70%)", animation: "jago-glow 7s ease 2s infinite", pointerEvents: "none" }} />

        <div style={{ maxWidth: 1180, margin: "0 auto", padding: "0 20px", position: "relative" }}>
          <div className="hero-grid">
            {/* Left */}
            <div>
              <div className="reveal g1" style={{ marginBottom: 16 }}>
                <span style={{ display: "inline-flex", alignItems: "center", gap: 8, border: `1px solid rgba(30,109,229,0.35)`, borderRadius: 999, padding: "7px 16px", background: isDark ? "rgba(30,109,229,0.13)" : "rgba(30,109,229,0.08)", fontSize: 12, fontWeight: 900, color: blue, letterSpacing: 0.4 }}>
                  <span style={{ width: 7, height: 7, borderRadius: "50%", background: blue, display: "inline-block", animation: "jago-badge 1.8s ease infinite" }} />
                  AI-Powered · Parcel &amp; Mobility Platform
                </span>
              </div>

              <h1 className="reveal g1" style={{ margin: "0 0 18px", fontSize: "clamp(40px,5.8vw,72px)", fontWeight: 900, lineHeight: 1.03, letterSpacing: "-2px", background: isDark ? "linear-gradient(130deg,#ffffff 0%,#a8c8ff 45%,#7cf4c0 90%)" : "linear-gradient(130deg,#0e1d3a 0%,#1e6de5 55%,#0ea977 100%)", WebkitBackgroundClip: "text", WebkitTextFillColor: "transparent", backgroundClip: "text" }}>
                India's Smartest<br />Mobility &amp;<br />Parcel Network
              </h1>

              <p className="reveal g2" style={{ margin: "0 0 30px", fontSize: 16, lineHeight: 1.75, color: textSub, maxWidth: 490 }}>
                Book bikes, autos, intercity rides &amp; same-day parcel delivery with AI voice in your language — instantly matched to a verified Jago Pilot near you.
              </p>

              <div className="reveal g2" style={{ display: "flex", flexWrap: "wrap", gap: 12, marginBottom: 36 }}>
                <a href="#download" className="jago-pulse-btn dl-btn" style={{ padding: "14px 24px", borderRadius: 14, fontWeight: 900, fontSize: 14, background: `linear-gradient(135deg,${blue},#4a8fef)`, color: "#fff", display: "inline-flex", alignItems: "center", gap: 9, transition: "transform 0.2s,opacity 0.2s" }}>
                  📱 Download Jago App
                </a>
                <a href="#solutions" className="dl-btn" style={{ padding: "14px 24px", borderRadius: 14, fontWeight: 700, fontSize: 14, border: `1.5px solid ${border}`, color: textMain, background: panel, display: "inline-flex", alignItems: "center", gap: 9, transition: "transform 0.2s,opacity 0.2s" }}>
                  🔍 Explore Services
                </a>
              </div>

              {/* Animated stats */}
              <div className="reveal g3" style={{ display: "flex", gap: 28, flexWrap: "wrap" }}>
                {[
                  { label: "Rides Completed", ref: rides.ref,   val: `${Math.floor(rides.count / 1000)}K+`   },
                  { label: "Cities Active",   ref: cities.ref,  val: `${cities.count}+`                       },
                  { label: "Verified Pilots", ref: drivers.ref, val: `${drivers.count}+`                      },
                ].map(s => (
                  <div key={s.label} ref={s.ref}>
                    <div style={{ fontSize: 26, fontWeight: 900, color: blue, lineHeight: 1, letterSpacing: "-0.5px" }}>{s.val}</div>
                    <div style={{ fontSize: 11, color: textSub, fontWeight: 700, marginTop: 3 }}>{s.label}</div>
                  </div>
                ))}
              </div>
            </div>

            {/* Right — Booking Flow */}
            <div className="reveal g2 jago-float">
              <BookingFlow isDark={isDark} />
            </div>
          </div>
        </div>
      </section>

      {/* ─── ANIMATED ROAD ─── */}
      <div style={{ marginTop: 60, borderTop: `1px solid ${border}`, borderBottom: `1px solid ${border}`, overflow: "hidden" }}>
        <AnimatedRoad isDark={isDark} />
      </div>

      {/* ─── SERVICES ─── */}
      <section id="solutions" className="sec">
        <div style={{ maxWidth: 1180, margin: "0 auto", padding: "0 20px" }}>
          <div className="reveal" style={{ marginBottom: 10 }}>
            <span style={{ fontSize: 11, fontWeight: 900, color: blue, letterSpacing: 1.4, textTransform: "uppercase" as const }}>What We Offer</span>
          </div>
          <h2 className="reveal" style={{ margin: "0 0 10px", fontSize: "clamp(28px,4.2vw,52px)", fontWeight: 900, letterSpacing: "-1px", lineHeight: 1.06 }}>
            One Platform,<br />Every Journey
          </h2>
          <p className="reveal" style={{ margin: "0 0 40px", color: textSub, fontSize: 16, maxWidth: 500, lineHeight: 1.68 }}>
            Whether you need a bike for 2 km or a truck for 200 kg — Jago finds you the right vehicle in seconds.
          </p>
          <div className="svc-grid">
            {services.map((s, i) => (
              <div key={s.name} className={`reveal g${(i % 4) + 1} svc-card`} style={{ borderRadius: 22, padding: "24px 20px", border: `1px solid ${border}`, background: panelStrong, transition: "transform 0.28s ease,box-shadow 0.28s ease", cursor: "default" }}>
                <div style={{ width: 50, height: 50, borderRadius: 15, background: `${s.color}16`, border: `1px solid ${s.color}30`, display: "grid", placeItems: "center", fontSize: 22, marginBottom: 16 }}>{s.icon}</div>
                <div style={{ fontSize: 10, fontWeight: 900, color: s.color, letterSpacing: 0.9, marginBottom: 7, textTransform: "uppercase" as const }}>{s.cat}</div>
                <div style={{ fontSize: 19, fontWeight: 900, marginBottom: 8, letterSpacing: "-0.3px" }}>{s.name}</div>
                <div style={{ fontSize: 13, color: textSub, lineHeight: 1.62 }}>{s.desc}</div>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* ─── WHY JAGO ─── */}
      <section style={{ background: strip, padding: "84px 0" }}>
        <div style={{ maxWidth: 1180, margin: "0 auto", padding: "0 20px" }}>
          <div className="reveal" style={{ marginBottom: 10 }}>
            <span style={{ fontSize: 11, fontWeight: 900, color: green, letterSpacing: 1.4, textTransform: "uppercase" as const }}>Why Jago</span>
          </div>
          <h2 className="reveal" style={{ margin: "0 0 40px", fontSize: "clamp(26px,3.8vw,48px)", fontWeight: 900, letterSpacing: "-0.9px", lineHeight: 1.1 }}>
            Built Different.<br />Built for India.
          </h2>
          <div className="why-grid">
            {whys.map((w, i) => (
              <div key={w.title} className={`reveal g${i + 1}`} style={{ borderRadius: 20, padding: "22px 20px", border: `1px solid ${border}`, background: panelStrong }}>
                <div style={{ width: 48, height: 48, borderRadius: 14, background: `${w.color}16`, border: `1px solid ${w.color}28`, display: "grid", placeItems: "center", fontSize: 22, marginBottom: 16 }}>{w.icon}</div>
                <div style={{ fontSize: 17, fontWeight: 900, marginBottom: 7 }}>{w.title}</div>
                <div style={{ fontSize: 13, color: textSub, lineHeight: 1.63 }}>{w.desc}</div>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* ─── JAGO + PILOT ─── */}
      <section id="driver" className="sec">
        <div style={{ maxWidth: 1180, margin: "0 auto", padding: "0 20px" }}>
          <div className="reveal" style={{ marginBottom: 10 }}>
            <span style={{ fontSize: 11, fontWeight: 900, color: violet, letterSpacing: 1.4, textTransform: "uppercase" as const }}>Two Apps, One Ecosystem</span>
          </div>
          <h2 className="reveal" style={{ margin: "0 0 10px", fontSize: "clamp(26px,4vw,50px)", fontWeight: 900, letterSpacing: "-0.9px" }}>Jago &amp; Jago Pilot</h2>
          <p className="reveal" style={{ margin: "0 0 38px", color: textSub, fontSize: 15, maxWidth: 500, lineHeight: 1.65 }}>
            A premium passenger app and a powerful operations tool for pilots — connected by real-time AI and sockets.
          </p>
          <div className="duo-grid">
            <div className="reveal g1" style={{ borderRadius: 24, padding: "30px 26px", border: `1.5px solid rgba(30,109,229,0.28)`, background: isDark ? "linear-gradient(145deg,rgba(30,109,229,0.12),rgba(8,18,48,0.7))" : "linear-gradient(145deg,rgba(30,109,229,0.07),rgba(255,255,255,0.95))" }}>
              <img src={isDark ? jagoLogoWhite : jagoLogoBlue} alt="JAGO" style={{ height: 42, marginBottom: 18 }} />
              <div style={{ fontSize: 10, fontWeight: 900, color: blue, letterSpacing: 1.2, marginBottom: 9 }}>PASSENGER APP</div>
              <h3 style={{ margin: "0 0 12px", fontSize: 22, fontWeight: 900, letterSpacing: "-0.4px" }}>For Riders &amp; Senders</h3>
              <p style={{ margin: "0 0 20px", color: textSub, lineHeight: 1.68, fontSize: 14 }}>
                AI voice booking in 9 Indian languages, live GPS tracking, Razorpay UPI &amp; cash payments, parcel delivery, intercity booking, wallet rewards, spin-to-win coins, and real-time driver ETA with TTS announcements.
              </p>
              <div style={{ display: "flex", flexWrap: "wrap", gap: 8 }}>
                {["🎤 Voice Book","📍 Live Track","💳 UPI/Cash","📦 Parcel","🏙️ Intercity","🪙 Coins"].map(tag => (
                  <span key={tag} style={{ fontSize: 11, fontWeight: 700, padding: "5px 11px", borderRadius: 20, background: `${blue}12`, border: `1px solid ${blue}28`, color: blue }}>{tag}</span>
                ))}
              </div>
            </div>
            <div className="reveal g2" style={{ borderRadius: 24, padding: "30px 26px", border: `1.5px solid rgba(16,185,129,0.28)`, background: isDark ? "linear-gradient(145deg,rgba(16,185,129,0.12),rgba(8,18,48,0.7))" : "linear-gradient(145deg,rgba(16,185,129,0.07),rgba(255,255,255,0.95))" }}>
              <img src={pilotLogo} alt="Pilot" style={{ height: 42, marginBottom: 18 }} />
              <div style={{ fontSize: 10, fontWeight: 900, color: green, letterSpacing: 1.2, marginBottom: 9 }}>DRIVER APP</div>
              <h3 style={{ margin: "0 0 12px", fontSize: 22, fontWeight: 900, letterSpacing: "-0.4px" }}>For Jago Pilots</h3>
              <p style={{ margin: "0 0 20px", color: textSub, lineHeight: 1.68, fontSize: 14 }}>
                Live trip requests with one-tap accept/reject, real-time earnings dashboard, break mode, KYC document uploads, fatigue detection alerts, wallet recharge, subscription plans, and performance reports.
              </p>
              <div style={{ display: "flex", flexWrap: "wrap", gap: 8 }}>
                {["⚡ Instant Trips","💰 Earnings","🛡️ KYC Verified","🗺️ Live Map","📊 Reports","😴 Break Mode"].map(tag => (
                  <span key={tag} style={{ fontSize: 11, fontWeight: 700, padding: "5px 11px", borderRadius: 20, background: `${green}12`, border: `1px solid ${green}28`, color: green }}>{tag}</span>
                ))}
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* ─── CITIES ─── */}
      <section id="cities" style={{ background: strip, padding: "76px 0" }}>
        <div style={{ maxWidth: 1180, margin: "0 auto", padding: "0 20px" }}>
          <div className="reveal" style={{ marginBottom: 10 }}>
            <span style={{ fontSize: 11, fontWeight: 900, color: amber, letterSpacing: 1.4, textTransform: "uppercase" as const }}>Coverage</span>
          </div>
          <h2 className="reveal" style={{ margin: "0 0 6px", fontSize: "clamp(26px,3.6vw,44px)", fontWeight: 900, letterSpacing: "-0.7px" }}>Cities We Operate</h2>
          <p className="reveal" style={{ margin: "0 0 34px", color: textSub, fontSize: 14 }}>Serving Andhra Pradesh &amp; Telangana — expanding to every major city.</p>
          <div className="cities-grid">
            {[
              { city: "Hyderabad",     tag: "🏙️ Flagship", hi: true  },
              { city: "Secunderabad",  tag: "📍 Active",   hi: false },
              { city: "Vijayawada",    tag: "📍 Active",   hi: false },
              { city: "Guntur",        tag: "📍 Active",   hi: false },
              { city: "Warangal",      tag: "📍 Active",   hi: false },
              { city: "Visakhapatnam", tag: "📍 Active",   hi: false },
            ].map((item, i) => (
              <div key={item.city} className={`reveal g${(i % 3) + 1}`} style={{ borderRadius: 16, border: `1px solid ${item.hi ? blue + "42" : border}`, background: item.hi ? (isDark ? "rgba(30,109,229,0.14)" : "rgba(30,109,229,0.07)") : panelStrong, padding: "16px 14px", textAlign: "center" as const }}>
                <div style={{ fontSize: 15, fontWeight: 900, marginBottom: 5 }}>{item.city}</div>
                <div style={{ fontSize: 10, color: item.hi ? blue : textSub, fontWeight: 800 }}>{item.tag}</div>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* ─── DOWNLOAD CTA ─── */}
      <section id="download" className="sec">
        <div style={{ maxWidth: 1180, margin: "0 auto", padding: "0 20px" }}>
          <div className="reveal dl-grid" style={{ borderRadius: 28, padding: "52px 44px", background: isDark ? "linear-gradient(135deg,rgba(30,109,229,0.2),rgba(16,185,129,0.12))" : "linear-gradient(135deg,rgba(30,109,229,0.09),rgba(16,185,129,0.06))", border: `1.5px solid ${border}`, position: "relative", overflow: "hidden" }}>
            <div style={{ position: "absolute", top: -60, right: -60, width: 280, height: 280, borderRadius: "50%", background: "radial-gradient(circle,rgba(30,109,229,0.12),transparent 70%)", pointerEvents: "none" }} />
            <div style={{ position: "relative" }}>
              <div style={{ fontSize: 11, fontWeight: 900, color: blue, letterSpacing: 1.4, marginBottom: 14 }}>GET STARTED TODAY</div>
              <h2 style={{ margin: "0 0 12px", fontSize: "clamp(24px,3.5vw,44px)", fontWeight: 900, letterSpacing: "-0.9px", lineHeight: 1.1 }}>
                Ready to Experience<br />Jago?
              </h2>
              <p style={{ margin: 0, color: textSub, fontSize: 15, lineHeight: 1.67, maxWidth: 440 }}>
                Download the Jago app to book rides &amp; parcels, or the Pilot app to start earning as a driver today.
              </p>
            </div>
            <div style={{ display: "flex", flexDirection: "column", gap: 11, minWidth: 200, position: "relative" }}>
              <a href="https://play.google.com/store" target="_blank" rel="noreferrer" className="dl-btn" style={{ padding: "15px 22px", borderRadius: 14, fontWeight: 900, fontSize: 14, background: `linear-gradient(135deg,${blue},#4a8fef)`, color: "#fff", textAlign: "center" as const, display: "flex", alignItems: "center", justifyContent: "center", gap: 10, transition: "transform 0.2s,opacity 0.2s", boxShadow: "0 8px 28px rgba(30,109,229,0.45)" }}>
                📱 Jago — Rider App
              </a>
              <a href="https://play.google.com/store" target="_blank" rel="noreferrer" className="dl-btn" style={{ padding: "15px 22px", borderRadius: 14, fontWeight: 800, fontSize: 14, border: `1.5px solid ${border}`, color: textMain, background: panel, textAlign: "center" as const, display: "flex", alignItems: "center", justifyContent: "center", gap: 10, transition: "transform 0.2s,opacity 0.2s" }}>
                🚗 Pilot — Driver App
              </a>
              <a href="/admin" style={{ padding: "10px 22px", borderRadius: 12, fontWeight: 700, fontSize: 12, border: `1px solid ${border}`, color: textSub, background: "transparent", textAlign: "center" as const }}>
                Admin Portal →
              </a>
            </div>
          </div>
        </div>
      </section>

      {/* ─── FOOTER ─── */}
      <footer style={{ borderTop: `1px solid ${border}`, background: isDark ? "#030812" : "#edf4ff", padding: "52px 0 32px" }}>
        <div style={{ maxWidth: 1180, margin: "0 auto", padding: "0 20px" }}>
          <div className="footer-grid" style={{ marginBottom: 40 }}>
            <div>
              <img src={isDark ? jagoLogoWhite : jagoLogoBlue} alt="JAGO" style={{ height: 36, marginBottom: 14 }} />
              <p style={{ margin: "0 0 16px", color: textSub, fontSize: 13, lineHeight: 1.68, maxWidth: 240 }}>
                India's AI-powered ride &amp; parcel platform — connecting journeys across AP &amp; Telangana.
              </p>
              <div style={{ fontSize: 11, color: textSub, fontWeight: 600 }}>📧 support@jagopro.org</div>
            </div>
            <div>
              <div style={{ fontSize: 11, fontWeight: 900, color: textMain, letterSpacing: 0.8, marginBottom: 14, textTransform: "uppercase" as const }}>Services</div>
              {["Bike Rides","Auto Rides","Car Rides","Parcel Delivery","Intercity Sharing","Goods Logistics"].map(s => (
                <div key={s} style={{ fontSize: 13, color: textSub, marginBottom: 7, fontWeight: 500 }}>{s}</div>
              ))}
            </div>
            <div>
              <div style={{ fontSize: 11, fontWeight: 900, color: textMain, letterSpacing: 0.8, marginBottom: 14, textTransform: "uppercase" as const }}>Company</div>
              {[{label:"About Us",href:"/about-us"},{label:"Contact",href:"/contact"},{label:"Privacy Policy",href:"/privacy"},{label:"Terms of Service",href:"/terms"},{label:"Driver Registration",href:"#driver"}].map(l => (
                <a key={l.label} href={l.href} style={{ display: "block", fontSize: 13, color: textSub, marginBottom: 7, fontWeight: 500 }}>{l.label}</a>
              ))}
            </div>
            <div>
              <div style={{ fontSize: 11, fontWeight: 900, color: textMain, letterSpacing: 0.8, marginBottom: 14, textTransform: "uppercase" as const }}>Cities</div>
              {["Hyderabad","Vijayawada","Guntur","Warangal","Visakhapatnam","Secunderabad"].map(c => (
                <div key={c} style={{ fontSize: 13, color: textSub, marginBottom: 7, fontWeight: 500 }}>{c}</div>
              ))}
            </div>
          </div>
          <div style={{ borderTop: `1px solid ${border}`, paddingTop: 22, display: "flex", justifyContent: "space-between", alignItems: "center", flexWrap: "wrap", gap: 10 }}>
            <div style={{ fontSize: 12, color: textSub, fontWeight: 600 }}>© 2026 JAGO Mobility Pvt. Ltd. All rights reserved.</div>
            <div style={{ fontSize: 12, color: textSub, fontWeight: 600 }}>🇮🇳 Made with ❤️ for India</div>
          </div>
        </div>
      </footer>
    </div>
  );
}
