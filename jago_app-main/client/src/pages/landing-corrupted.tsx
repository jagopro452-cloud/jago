import { useState, useEffect, useRef, useCallback, type ReactNode } from "react";

/* ═══════════════════════════════════════════════════════════════════════
   JAGO PRO — Premium Light Landing Page
   Bright Luxury Theme: Uber + Airbnb + Apple + Stripe in LIGHT MODE
   Primary: #f1dcfa · Royal Violet: #c98cff · Soft Pink: #ffd9f6
   Sky Blue: #dff4ff · Mint White: #f7fff8 · Warm Cream: #fffaf2
   ═══════════════════════════════════════════════════════════════════════ */

const P = {
  // Premium Light Color Palette
  primary: "#f1dcfa",           // Primary Lavender
  accent: "#c98cff",           // Royal Violet
  pink: "#ffd9f6",             // Soft Pink
  sky: "#dff4ff",              // Sky Blue
  mint: "#f7fff8",             // Mint White
  cream: "#fffaf2",            // Warm Cream
  white: "#ffffff",            // Pure White
  
  // Text Colors
  heading: "#4f4363",          // Heading Text
  textSoft: "#6f6a7d",         // Soft Grey Text
  textMuted: "#a8a3b8",        // Muted Text
  
  // Glass & Borders
  glass: "rgba(255,255,255,0.85)",
  glass2: "rgba(255,255,255,0.75)",
  glassBorder: "rgba(201,140,255,0.18)",
  glassBorder2: "rgba(201,140,255,0.12)",
  
  // Glow Effects
  glowAccent: "rgba(201,140,255,0.25)",
  glowPink: "rgba(255,217,246,0.35)",
  glowSky: "rgba(223,244,255,0.4)",
  glowPrimary: "rgba(241,220,250,0.3)",
  
  // Premium Gradients
  gradPrimary: "linear-gradient(135deg, #c98cff 0%, #ffd9f6 100%)",
  gradText: "linear-gradient(90deg, #f1dcfa, #c98cff, #ffd9f6, #dff4ff, #c98cff, #f1dcfa)",
  gradHero: "linear-gradient(135deg, #f1dcfa 0%, #dff4ff 25%, #ffd9f6 50%, #f7fff8 75%, #fffaf2 100%)",
  gradCard: "linear-gradient(160deg, rgba(241,220,250,0.4) 0%, rgba(255,217,246,0.3) 50%, rgba(223,244,255,0.2) 100%)",
  gradButton: "linear-gradient(135deg, #c98cff 0%, #b77dff 50%, #a86fee 100%)",
  gradBackground: "linear-gradient(135deg, #ffffff 0%, #f1dcfa 20%, #dff4ff 40%, #ffd9f6 60%, #f7fff8 80%, #fffaf2 100%)",
} as const;

/* ────────────────── HOOKS ────────────────── */
function useReveal(threshold = 0.1) {
  const ref = useRef<HTMLDivElement>(null);
  const [vis, setVis] = useState(false);
  useEffect(() => {
    const el = ref.current; if (!el) return;
    const io = new IntersectionObserver(([e]) => {
      if (e.isIntersecting) { setVis(true); io.disconnect(); }
    }, { threshold });
    io.observe(el);
    return () => io.disconnect();
  }, [threshold]);
  return { ref, vis };
}

function useCountUp(target: number, dur = 2200) {
  const [val, setVal] = useState(0);
  const ref = useRef<HTMLDivElement>(null);
  useEffect(() => {
    const el = ref.current; if (!el) return;
    const io = new IntersectionObserver(([e]) => {
      if (!e.isIntersecting) return; io.disconnect();
      const t0 = Date.now();
      const tick = () => {
        const p = Math.min((Date.now() - t0) / dur, 1);
        setVal(Math.round((1 - Math.pow(1 - p, 4)) * target));
        if (p < 1) requestAnimationFrame(tick);
      };
      requestAnimationFrame(tick);
    }, { threshold: 0.4 });
    io.observe(el);
    return () => io.disconnect();
  }, [target, dur]);
  return { ref, val };
}

function useMouse() {
  const [p, setP] = useState({ x: 0, y: 0 });
  useEffect(() => {
    const h = (e: MouseEvent) => setP({ x: e.clientX, y: e.clientY });
    window.addEventListener("mousemove", h, { passive: true });
    return () => window.removeEventListener("mousemove", h);
  }, []);
  return p;
}

/* ────────────────── PARTICLES ────────────────── */
function Particles() {
  const ref = useRef<HTMLCanvasElement>(null);
  useEffect(() => {
    const c = ref.current; if (!c) return;
    const ctx = c.getContext("2d"); if (!ctx) return;
    let id: number;
    const dots: { x: number; y: number; vx: number; vy: number; r: number; o: number }[] = [];
    const resize = () => { c.width = window.innerWidth; c.height = window.innerHeight; };
    resize(); window.addEventListener("resize", resize);
    for (let i = 0; i < 70; i++) dots.push({
      x: Math.random() * c.width, y: Math.random() * c.height,
      vx: (Math.random() - 0.5) * 0.25, vy: (Math.random() - 0.5) * 0.25,
      r: Math.random() * 1.8 + 0.4, o: Math.random() * 0.45 + 0.05,
    });
    const draw = () => {
      ctx.clearRect(0, 0, c.width, c.height);
      dots.forEach(d => {
        d.x += d.vx; d.y += d.vy;
        if (d.x < 0) d.x = c.width; if (d.x > c.width) d.x = 0;
        if (d.y < 0) d.y = c.height; if (d.y > c.height) d.y = 0;
        ctx.beginPath(); ctx.arc(d.x, d.y, d.r, 0, Math.PI * 2);
        ctx.fillStyle = `rgba(241,220,250,${d.o})`; ctx.fill();
      });
      // Draw connections between nearby particles
      for (let i = 0; i < dots.length; i++) {
        for (let j = i + 1; j < dots.length; j++) {
          const dx = dots[i].x - dots[j].x;
          const dy = dots[i].y - dots[j].y;
          const dist = Math.sqrt(dx * dx + dy * dy);
          if (dist < 120) {
            ctx.beginPath();
            ctx.moveTo(dots[i].x, dots[i].y);
            ctx.lineTo(dots[j].x, dots[j].y);
            ctx.strokeStyle = `rgba(200,107,255,${0.06 * (1 - dist / 120)})`;
            ctx.lineWidth = 0.5;
            ctx.stroke();
          }
        }
      }
      id = requestAnimationFrame(draw);
    };
    draw();
    return () => { cancelAnimationFrame(id); window.removeEventListener("resize", resize); };
  }, []);
  return <canvas ref={ref} style={{ position: "absolute", inset: 0, pointerEvents: "none", zIndex: 1 }} />;
}

/* ────────────────── PHONE MOCKUP ────────────────── */
const SCREENS = ["home", "route", "fare", "pilot", "track"] as const;
type Screen = typeof SCREENS[number];

function MiniScreen({ screen }: { screen: Screen }) {
  const [eta, setEta] = useState(3);
  useEffect(() => {
    if (screen !== "track") return;
    const t = setInterval(() => setEta(e => Math.max(0, e - 1)), 1400);
    return () => clearInterval(t);
  }, [screen]);

  const ft = "'Inter',system-ui,sans-serif";
  const Bar = () => (
    <div style={{ height: 26, background: P.primary, display: "flex", alignItems: "center", justifyContent: "space-between", padding: "0 14px", flexShrink: 0 }}>
      <span style={{ fontSize: 9, fontWeight: 700, color: P.heading, fontFamily: ft }}>9:41</span>
      <div style={{ width: 48, height: 6, borderRadius: 3, background: P.accent }} />
      <span style={{ fontSize: 8, color: P.textSoft }}>●●● ▮</span>
    </div>
  );

  if (screen === "home") return (
    <div style={{ width: "100%", height: "100%", display: "flex", flexDirection: "column", background: P.mint }}>
      <Bar />
      <div style={{ flex: 1, position: "relative", background: "linear-gradient(160deg,#f7fff8,#f1dcfa)", overflow: "hidden" }}>
        {[...Array(6)].map((_, i) => (
          <div key={i} style={{ position: "absolute", left: 0, right: 0, top: `${i * 18}%`, height: 1, background: "rgba(201,140,255,.08)" }} />
        ))}
        {[...Array(6)].map((_, i) => (
          <div key={`v${i}`} style={{ position: "absolute", top: 0, bottom: 0, left: `${i * 18}%", width: 1, background: "rgba(201,140,255,.08)" }} />
        ))}
        <div style={{ position: "absolute", left: "48%", top: "42%", transform: "translate(-50%,-50%)" }}>
          <div style={{ width: 16, height: 16, borderRadius: "50%", background: P.accent, border: "3px solid #fff", boxShadow: `0 0 0 8px rgba(201,140,255,0.15), 0 0 24px rgba(201,140,255,0.3)` }} />
        </div>
        <div style={{ position: "absolute", left: "68%", top: "28%", width: 10, height: 10, borderRadius: "50%", background: P.pink, boxShadow: "0 0 12px rgba(255,217,246,0.4)", animation: "jg-pulse 2s infinite" }} />
        <div style={{ position: "absolute", left: "25%", top: "65%", width: 7, height: 7, borderRadius: "50%", background: "#4ade80", boxShadow: "0 0 10px rgba(74,222,128,0.3)", animation: "jg-pulse 2.5s infinite" }} />
      </div>
      <div style={{ background: P.white, padding: "14px 12px 12px", boxShadow: "0 -6px 24px rgba(201,140,255,0.1)", borderRadius: "18px 18px 0 0" }}>
        <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", marginBottom: 8 }}>
          <span style={{ fontSize: 10, color: P.textSoft, fontFamily: ft }}>Good morning ✨</span>
          <div style={{ width: 22, height: 22, borderRadius: "50%", background: P.gradPrimary, display: "flex", alignItems: "center", justifyContent: "center" }}>
            <span style={{ fontSize: 8, color: "#fff", fontWeight: 800 }}>R</span>
          </div>
        </div>
        <div style={{ display: "flex", alignItems: "center", gap: 6, background: P.primary, borderRadius: 12, padding: "9px 10px", marginBottom: 10, border: "1px solid rgba(201,140,255,0.18)" }}>
          <div style={{ width: 7, height: 7, borderRadius: "50%", background: P.accent }} />
          <span style={{ fontSize: 10, color: P.textSoft, fontFamily: ft }}>Where do you want to go?</span>
        </div>
        <div style={{ display: "flex", justifyContent: "space-around" }}>
          {[["🏍️", "Bike"], ["🛺", "Auto"], ["🚗", "Car"], ["📦", "Parcel"]].map(([e, l]) => (
            <div key={l} style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: 3 }}>
              <div style={{ width: 36, height: 36, borderRadius: 12, background: P.primary, border: "1px solid rgba(201,140,255,0.18)", display: "flex", alignItems: "center", justifyContent: "center", fontSize: 15 }}>{e}</div>
              <span style={{ fontSize: 8, color: P.textSoft, fontWeight: 600, fontFamily: ft }}>{l}</span>
            </div>
          ))}
        </div>
      </div>
    </div>
  );

  if (screen === "route") return (
    <div style={{ width: "100%", height: "100%", display: "flex", flexDirection: "column", background: "#fff" }}>
      <Bar />
      <div style={{ background: `linear-gradient(135deg, ${P.accent}, ${P.pink})`, padding: "16px 12px 20px" }}>
        <p style={{ fontSize: 8.5, color: "rgba(255,255,255,.55)", margin: "0 0 8px", fontFamily: ft, textTransform: "uppercase", letterSpacing: 1.5 }}>Set Route</p>
        <div style={{ display: "flex", flexDirection: "column", gap: 4 }}>
          <div style={{ display: "flex", alignItems: "center", gap: 7, background: "rgba(255,255,255,.12)", borderRadius: 10, padding: "8px 10px" }}>
            <div style={{ width: 7, height: 7, borderRadius: "50%", background: "#4ade80" }} />
            <span style={{ fontSize: 10, color: "rgba(255,255,255,.85)", fontFamily: ft }}>Current Location</span>
          </div>
          <div style={{ display: "flex", alignItems: "center", gap: 7, background: "#fff", borderRadius: 10, padding: "8px 10px" }}>
            <div style={{ width: 7, height: 7, borderRadius: "50%", background: P.accent }} />
            <span style={{ fontSize: 10, color: P.accent, fontWeight: 700, fontFamily: ft }}>Hitech City Metro</span>
          </div>
        </div>
      </div>
      <div style={{ flex: 1, padding: "10px 12px", overflow: "hidden" }}>
        {[{ p: "Hitech City Metro", d: "3.2 km" }, { p: "Apollo Hospital", d: "5.8 km" }, { p: "Inorbit Mall", d: "2.1 km" }].map((x, i) => (
          <div key={i} style={{ display: "flex", alignItems: "center", gap: 10, padding: "9px 0", borderBottom: "1px solid #f1f5f9" }}>
            <div style={{ width: 28, height: 28, borderRadius: 8, background: "#f5f0ff", display: "flex", alignItems: "center", justifyContent: "center", fontSize: 12 }}>📍</div>
            <div><p style={{ margin: 0, fontSize: 10.5, fontWeight: 600, color: "#1e293b", fontFamily: ft }}>{x.p}</p><p style={{ margin: 0, fontSize: 8, color: "#94a3b8" }}>{x.d}</p></div>
          </div>
        ))}
      </div>
      <div style={{ padding: "0 12px 14px" }}>
        <div style={{ background: P.gradPrimary, borderRadius: 14, padding: "12px", textAlign: "center" }}>
          <span style={{ fontSize: 11, fontWeight: 700, color: "#fff", fontFamily: ft }}>Confirm Route →</span>
        </div>
      </div>
    </div>
  );

  if (screen === "fare") return (
    <div style={{ width: "100%", height: "100%", display: "flex", flexDirection: "column", background: "#faf5ff" }}>
      <Bar />
      <div style={{ flex: 1, background: "linear-gradient(140deg,#f0e6ff,#e8dbff)", position: "relative", overflow: "hidden" }}>
        <svg style={{ position: "absolute", inset: 0, width: "100%", height: "100%" }} viewBox="0 0 100 100" preserveAspectRatio="none">
          <defs>
            <linearGradient id="routeG" x1="0%" y1="0%" x2="100%" y2="0%"><stop offset="0%" stopColor={P.accent} /><stop offset="100%" stopColor={P.pink} /></linearGradient>
          </defs>
          <path d="M25 72 Q50 48 75 28" stroke="url(#routeG)" strokeWidth="2.5" fill="none" strokeDasharray="5 3" opacity="0.7" />
          <circle cx="25" cy="72" r="4" fill="#fff" stroke={P.accent} strokeWidth="1.5" />
          <circle cx="75" cy="28" r="4" fill={P.pink} />
        </svg>
        <div style={{ position: "absolute", right: 10, top: 10, background: "#fff", borderRadius: 8, padding: "4px 10px", boxShadow: "0 2px 12px rgba(0,0,0,.1)" }}>
          <span style={{ fontSize: 9, fontWeight: 700, color: P.accent, fontFamily: ft }}>3.2 km · 8 min</span>
        </div>
      </div>
      <div style={{ background: "#fff", padding: "14px 12px", boxShadow: "0 -6px 20px rgba(0,0,0,.06)", borderRadius: "18px 18px 0 0" }}>
        <div style={{ display: "flex", gap: 5, marginBottom: 12 }}>
          {[{ t: "Bike", f: "₹45", a: true }, { t: "Auto", f: "₹75", a: false }, { t: "Cab", f: "₹130", a: false }].map(o => (
            <div key={o.t} style={{ flex: 1, padding: "8px 4px", borderRadius: 12, border: `2px solid ${o.a ? P.accent : "transparent"}`, background: o.a ? "#f5f0ff" : "#f8fafc", textAlign: "center", transition: ".2s" }}>
              <p style={{ margin: 0, fontSize: 9, fontWeight: 700, fontFamily: ft, color: o.a ? P.accent : "#64748b" }}>{o.t}</p>
              <p style={{ margin: "2px 0 0", fontSize: 14, fontWeight: 900, color: o.a ? P.accent : "#94a3b8", fontFamily: ft }}>{o.f}</p>
            </div>
          ))}
        </div>
        <div style={{ background: P.gradPrimary, borderRadius: 14, padding: "12px", textAlign: "center", boxShadow: `0 4px 16px ${P.glowAccent}` }}>
          <span style={{ fontSize: 11.5, fontWeight: 700, color: "#fff", fontFamily: ft }}>Confirm Booking ✓</span>
        </div>
      </div>
    </div>
  );

  if (screen === "pilot") return (
    <div style={{ width: "100%", height: "100%", display: "flex", flexDirection: "column", background: "#fff" }}>
      <Bar />
      <div style={{ background: `linear-gradient(135deg,${P.mint},${P.accent})`, padding: "22px 12px 28px", textAlign: "center" }}>
        <div style={{ width: 42, height: 42, borderRadius: "50%", background: "rgba(255,255,255,.15)", margin: "0 auto 8px", display: "flex", alignItems: "center", justifyContent: "center", backdropFilter: "blur(8px)" }}>
          <span style={{ fontSize: 20, color: "#fff" }}>✓</span>
        </div>
        <p style={{ margin: 0, fontSize: 14, fontWeight: 800, color: "#fff", fontFamily: ft }}>Pilot Matched!</p>
        <p style={{ margin: "4px 0 0", fontSize: 10, color: "rgba(255,255,255,.6)", fontFamily: ft }}>Arriving in 2 min</p>
      </div>
      <div style={{ flex: 1, padding: "14px 12px", background: "#faf5ff" }}>
        <div style={{ background: "#fff", borderRadius: 16, padding: 14, boxShadow: "0 4px 20px rgba(0,0,0,.06)" }}>
          <div style={{ display: "flex", alignItems: "center", gap: 10, marginBottom: 12 }}>
            <div style={{ width: 42, height: 42, borderRadius: "50%", background: P.gradPrimary, display: "flex", alignItems: "center", justifyContent: "center", fontSize: 16, color: "#fff", fontWeight: 800 }}>R</div>
            <div style={{ flex: 1 }}>
              <p style={{ margin: 0, fontSize: 12, fontWeight: 700, color: "#1e293b", fontFamily: ft }}>Ravi Kumar</p>
              <span style={{ fontSize: 9.5, color: "#64748b", fontFamily: ft }}>⭐ 4.8 · 1,240 rides</span>
            </div>
            <div style={{ width: 32, height: 32, borderRadius: "50%", background: "#f5f0ff", display: "flex", alignItems: "center", justifyContent: "center", fontSize: 14 }}>📞</div>
          </div>
          <div style={{ display: "flex", justifyContent: "space-between", paddingTop: 10, borderTop: "1px solid #f1f5f9" }}>
            {[{ l: "Vehicle", v: "Activa" }, { l: "Plate", v: "TS09AB" }, { l: "OTP", v: "7482" }].map(x => (
              <div key={x.l} style={{ textAlign: "center" }}>
                <p style={{ margin: 0, fontSize: 7.5, color: "#94a3b8", fontFamily: ft }}>{x.l}</p>
                <p style={{ margin: "2px 0 0", fontSize: 11, fontWeight: 800, color: x.l === "OTP" ? P.accent : "#1e293b", fontFamily: ft }}>{x.v}</p>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );

  // track
  return (
    <div style={{ width: "100%", height: "100%", display: "flex", flexDirection: "column", background: "#faf5ff" }}>
      <Bar />
      <div style={{ flex: 1, background: "linear-gradient(140deg,#f0e6ff,#e8dbff)", position: "relative" }}>
        <svg style={{ position: "absolute", inset: 0, width: "100%", height: "100%" }} viewBox="0 0 100 100" preserveAspectRatio="none">
          <path d="M28 65 Q48 48 68 28" stroke="url(#routeG)" strokeWidth="2" fill="none" opacity=".4" />
          <circle cx="28" cy="65" r="3" fill="#fff" stroke={P.accent} strokeWidth="1.5" />
          <circle cx="68" cy="28" r="3" fill={P.pink} />
          <circle cx="45" cy="50" r="5" fill={P.accent} />
          <circle cx="45" cy="50" r="9" fill="rgba(200,107,255,.12)" />
        </svg>
        <div style={{ position: "absolute", top: 10, left: "50%", transform: "translateX(-50%)", background: "#fff", borderRadius: 20, padding: "5px 14px", boxShadow: "0 4px 16px rgba(0,0,0,.1)", display: "flex", alignItems: "center", gap: 6, whiteSpace: "nowrap" }}>
          <div style={{ width: 7, height: 7, borderRadius: "50%", background: P.accent, animation: "jg-pulse 1.5s infinite" }} />
          <span style={{ fontSize: 9.5, fontWeight: 700, color: "#1e293b", fontFamily: ft }}>Pilot arriving in {eta} min</span>
        </div>
      </div>
      <div style={{ background: "#fff", padding: "12px", boxShadow: "0 -6px 20px rgba(0,0,0,.05)", borderRadius: "18px 18px 0 0" }}>
        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 10 }}>
          <div>
            <p style={{ margin: 0, fontSize: 11, fontWeight: 700, color: "#1e293b", fontFamily: ft }}>Ravi Kumar · Bike</p>
            <p style={{ margin: "2px 0 0", fontSize: 8.5, color: "#94a3b8" }}>TS09AB1234</p>
          </div>
          <div style={{ textAlign: "right" }}>
            <p style={{ margin: 0, fontSize: 18, fontWeight: 900, background: P.gradPrimary, backgroundClip: "text", WebkitBackgroundClip: "text", color: "transparent" }}>₹45</p>
            <p style={{ margin: 0, fontSize: 8, color: "#64748b" }}>Cash</p>
          </div>
        </div>
        <div style={{ display: "flex", gap: 6 }}>
          {["Call", "Cancel", "Share"].map((l, ai) => (
            <div key={l} style={{ flex: 1, background: ai === 1 ? "#fff1f2" : "#f5f0ff", borderRadius: 10, padding: "8px 4px", textAlign: "center", border: `1px solid ${ai === 1 ? "#fecdd3" : "rgba(200,107,255,.1)"}` }}>
              <span style={{ fontSize: 9.5, fontWeight: 600, color: ai === 1 ? "#e11d48" : P.accent, fontFamily: ft }}>{l}</span>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}

function FloatingPhone() {
  const [idx, setIdx] = useState(0);
  const [key, setKey] = useState(0);
  useEffect(() => {
    const t = setInterval(() => { setKey(k => k + 1); setIdx(i => (i + 1) % SCREENS.length); }, 3600);
    return () => clearInterval(t);
  }, []);
  const labels = ["Home", "Route", "Fare", "Pilot", "Track"];

  return (
    <div style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: 24 }}>
      <div style={{ position: "relative", width: 272, height: 554 }}>
        {/* Rotating glow rings */}
        <div style={{ position: "absolute", inset: -60, border: `1.5px solid rgba(200,107,255,.08)`, borderRadius: "50%", animation: "jg-spin-slow 30s linear infinite" }} />
        <div style={{ position: "absolute", inset: -90, border: `1px solid rgba(255,125,232,.05)`, borderRadius: "50%", animation: "jg-spin-slow 45s linear infinite reverse" }} />
        <div style={{ position: "absolute", inset: -120, border: `1px solid rgba(241,220,250,.03)`, borderRadius: "50%", animation: "jg-spin-slow 60s linear infinite" }} />

        {/* Main glow */}
        <div style={{ position: "absolute", inset: -50, borderRadius: 60, background: `radial-gradient(ellipse, ${P.glowAccent} 0%, ${P.glowPink} 40%, transparent 70%)`, filter: "blur(50px)", animation: "jg-glow-pulse 5s ease-in-out infinite" }} />

        {/* Floating glass cards around phone */}
        <div style={{ position: "absolute", top: 40, left: -80, background: "rgba(255,255,255,.08)", backdropFilter: "blur(12px)", borderRadius: 14, padding: "8px 14px", border: "1px solid rgba(255,255,255,.1)", animation: "jg-float-card 5s ease-in-out infinite", zIndex: 5 }}>
          <div style={{ display: "flex", alignItems: "center", gap: 6 }}>
            <div style={{ width: 8, height: 8, borderRadius: "50%", background: "#4ade80" }} />
            <span style={{ fontSize: 10, color: "rgba(255,255,255,.8)", fontWeight: 600, fontFamily: "'Inter',sans-serif" }}>Live GPS</span>
          </div>
        </div>
        <div style={{ position: "absolute", bottom: 80, right: -90, background: "rgba(255,255,255,.08)", backdropFilter: "blur(12px)", borderRadius: 14, padding: "8px 14px", border: "1px solid rgba(255,255,255,.1)", animation: "jg-float-card 6s ease-in-out infinite 1s", zIndex: 5 }}>
          <div style={{ display: "flex", alignItems: "center", gap: 6 }}>
            <span style={{ fontSize: 11 }}>⭐</span>
            <span style={{ fontSize: 10, color: "rgba(255,255,255,.8)", fontWeight: 600, fontFamily: "'Inter',sans-serif" }}>4.9 Rating</span>
          </div>
        </div>
        <div style={{ position: "absolute", top: "55%", left: -70, background: "rgba(255,255,255,.06)", backdropFilter: "blur(12px)", borderRadius: 14, padding: "8px 14px", border: "1px solid rgba(255,255,255,.08)", animation: "jg-float-card 7s ease-in-out infinite 2s", zIndex: 5 }}>
          <span style={{ fontSize: 10, color: "rgba(255,255,255,.7)", fontWeight: 600, fontFamily: "'Inter',sans-serif" }}>₹45 · 8 min</span>
        </div>

        {/* Phone body */}
        <div style={{ position: "absolute", inset: 0, borderRadius: 46, animation: "jg-float 5.5s ease-in-out infinite" }}>
          <div style={{ position: "absolute", inset: 0, borderRadius: 46, background: "#0a0520", boxShadow: `0 60px 120px rgba(0,0,0,.7), inset 0 0 0 1.5px rgba(241,220,250,.08), 0 0 0 2px #1a1040, 0 0 100px ${P.glowAccent}`, overflow: "hidden" }}>
            {/* Side buttons */}
            <div style={{ position: "absolute", left: -3.5, top: 100, width: 3.5, height: 26, background: "#1a1040", borderRadius: "3px 0 0 3px" }} />
            <div style={{ position: "absolute", left: -3.5, top: 140, width: 3.5, height: 26, background: "#1a1040", borderRadius: "3px 0 0 3px" }} />
            <div style={{ position: "absolute", right: -3.5, top: 120, width: 3.5, height: 36, background: "#1a1040", borderRadius: "0 3px 3px 0" }} />
            {/* Screen */}
            <div style={{ position: "absolute", inset: 7, borderRadius: 40, overflow: "hidden", background: "#fff" }}>
              <div key={key} style={{ width: "100%", height: "100%", animation: "jg-screen-slide .4s cubic-bezier(.16,1,.3,1) forwards" }}>
                <MiniScreen screen={SCREENS[idx]} />
              </div>
            </div>
            {/* Glass reflection */}
            <div style={{ position: "absolute", top: 0, left: 0, right: "55%", bottom: "45%", background: "linear-gradient(150deg, rgba(255,255,255,.07), transparent)", borderRadius: "46px 0 0 0", pointerEvents: "none" }} />
          </div>
        </div>
      </div>
      {/* Dots */}
      <div style={{ display: "flex", gap: 8, alignItems: "center", zIndex: 2 }}>
        {SCREENS.map((_, i) => (
          <button key={i} onClick={() => { setIdx(i); setKey(k => k + 1); }}
            style={{ width: i === idx ? 28 : 8, height: 8, borderRadius: 4, background: i === idx ? P.gradPrimary : "rgba(255,255,255,.12)", border: "none", cursor: "pointer", transition: "all .35s cubic-bezier(.16,1,.3,1)", padding: 0 }}
          />
        ))}
      </div>
      <p style={{ fontSize: 10, fontWeight: 600, color: P.textMuted, fontFamily: "'Inter',sans-serif", margin: 0, letterSpacing: 2.5, textTransform: "uppercase" }}>{labels[idx]}</p>
    </div>
  );
}

/* ────────────────── MARQUEE ────────────────── */
function Marquee() {
  const items = ["Bike Taxi ✦", "Auto Ride ✦", "Cab Ride ✦", "Parcel ✦", "Intercity ✦", "Rentals ✦", "Safety First ✦", "Fair Pricing ✦", "60-Sec Match ✦", "Live Tracking ✦", "Top Pilots ✦", "Wallet Cashback ✦"];
  const dup = [...items, ...items];
  return (
    <div style={{ overflow: "hidden", background: P.glass2, borderTop: `1px solid ${P.glassBorder2}`, borderBottom: `1px solid ${P.glassBorder2}`, padding: "18px 0", position: "relative" }}>
      <div style={{ position: "absolute", left: 0, top: 0, bottom: 0, width: 100, background: `linear-gradient(90deg, ${P.white}, transparent)`, zIndex: 2 }} />
      <div style={{ position: "absolute", right: 0, top: 0, bottom: 0, width: 100, background: `linear-gradient(270deg, ${P.white}, transparent)`, zIndex: 2 }} />
      <div style={{ display: "flex", gap: 48, animation: "jg-marquee 32s linear infinite", width: "max-content" }}>
        {dup.map((t, i) => (
          <span key={i} style={{ fontSize: 13, fontWeight: 500, color: P.textMuted, fontFamily: "'Inter',sans-serif", letterSpacing: 1, whiteSpace: "nowrap" }}>{t}</span>
        ))}
      </div>
    </div>
  );
}

/* ────────────────── SECTION HEADER ────────────────── */
function SecHead({ tag, title, sub, align = "center" }: { tag: string; title: ReactNode; sub?: string; align?: "center" | "left" }) {
  return (
    <div style={{ textAlign: align, maxWidth: align === "center" ? 600 : undefined, margin: align === "center" ? "0 auto 52px" : "0 0 44px" }}>
      <div style={{ display: "inline-flex", alignItems: "center", gap: 8, background: "rgba(200,107,255,.08)", border: "1px solid rgba(200,107,255,.18)", borderRadius: 40, padding: "5px 16px 5px 12px", marginBottom: 18, backdropFilter: "blur(8px)" }}>
        <div style={{ width: 5, height: 5, borderRadius: "50%", background: P.accent, boxShadow: `0 0 8px ${P.glowAccent}`, animation: "jg-pulse 2s infinite" }} />
        <span style={{ fontSize: 10, fontWeight: 700, color: P.accent, textTransform: "uppercase", letterSpacing: 2.5, fontFamily: "'Inter',sans-serif" }}>{tag}</span>
      </div>
      <h2 style={{ fontSize: "clamp(26px, 3.5vw, 44px)", fontWeight: 900, fontFamily: "'Inter',sans-serif", letterSpacing: -1.5, lineHeight: 1.1, color: P.heading, marginBottom: sub ? 14 : 0 }}>{title}</h2>
      {sub && <p style={{ fontSize: 15, color: P.textSoft, lineHeight: 1.75, fontWeight: 400 }}>{sub}</p>}
    </div>
  );
}

/* ────────────────── GRADIENT WORD ────────────────── */
function GradWord({ children }: { children: string }) {
  return <span style={{ background: P.gradText, backgroundSize: "300% auto", backgroundClip: "text", WebkitBackgroundClip: "text", color: "transparent", animation: "jg-grad-shift 5s ease-in-out infinite" }}>{children}</span>;
}

/* ═══════════════════════════════════════════════════
   MAIN PAGE
   ═══════════════════════════════════════════════════ */
export default function LandingPage() {
  const [scrolled, setScrolled] = useState(false);
  const mouse = useMouse();

  const cRides = useCountUp(500000, 2400);
  const cCities = useCountUp(50, 1600);
  const cPilots = useCountUp(20000, 2000);
  const cRating = useCountUp(49, 1500);

  const rSvc = useReveal(); const rHow = useReveal(); const rWhy = useReveal();
  const rPilot = useReveal(); const rStats = useReveal(); const rCta = useReveal();

  useEffect(() => {
    const fn = () => setScrolled(window.scrollY > 30);
    window.addEventListener("scroll", fn, { passive: true });
    return () => window.removeEventListener("scroll", fn);
  }, []);

  const ft = "'Inter', -apple-system, BlinkMacSystemFont, system-ui, sans-serif";

  return (
    <>
      <style>{`
        @import url('https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800;900&display=swap');
        *,*::before,*::after{box-sizing:border-box;margin:0;padding:0}
        html{scroll-behavior:smooth;-webkit-font-smoothing:antialiased;-moz-osx-font-smoothing:grayscale}
        body{font-family:${ft};background:${P.gradBackground};overflow-x:hidden}
        ::selection{background:rgba(200,107,255,.3);color:#fff}

        @keyframes jg-float{0%,100%{transform:translateY(0)}50%{transform:translateY(-22px)}}
        @keyframes jg-float-card{0%,100%{transform:translateY(0) rotate(0deg)}50%{transform:translateY(-12px) rotate(1deg)}}
        @keyframes jg-glow-pulse{0%,100%{opacity:.6;transform:scale(1)}50%{opacity:.85;transform:scale(1.06)}}
        @keyframes jg-pulse{0%,100%{box-shadow:0 0 0 0 rgba(200,107,255,.5);opacity:1}50%{box-shadow:0 0 0 10px rgba(200,107,255,0);opacity:.6}}
        @keyframes jg-grad-shift{0%{background-position:0% 50%}50%{background-position:100% 50%}100%{background-position:0% 50%}}
        @keyframes jg-fade-up{from{opacity:0;transform:translateY(48px)}to{opacity:1;transform:translateY(0)}}
        @keyframes jg-marquee{from{transform:translateX(0)}to{transform:translateX(-50%)}}
        @keyframes jg-screen-slide{from{opacity:0;transform:translateX(20px) scale(.98)}to{opacity:1;transform:translateX(0) scale(1)}}
        @keyframes jg-spin-slow{from{transform:rotate(0deg)}to{transform:rotate(360deg)}}
        @keyframes jg-light{0%{transform:rotate(20deg) translateX(-120%)}100%{transform:rotate(20deg) translateX(250%)}}
        @keyframes jg-bar-grow{from{transform:scaleY(0)}to{transform:scaleY(1)}}
        @keyframes jg-orb-move{0%,100%{transform:scale(1) translate(0,0);opacity:.45}33%{transform:scale(1.15) translate(30px,-25px);opacity:.3}66%{transform:scale(.9) translate(-25px,20px);opacity:.55}}
        @keyframes jg-counter-glow{0%,100%{text-shadow:0 0 30px rgba(200,107,255,0)}50%{text-shadow:0 0 30px rgba(200,107,255,.3)}}
        @keyframes jg-tilt-subtle{0%,100%{transform:perspective(800px) rotateX(0) rotateY(0)}25%{transform:perspective(800px) rotateX(1deg) rotateY(-1deg)}75%{transform:perspective(800px) rotateX(-1deg) rotateY(1deg)}}
        @keyframes jg-stagger-in{from{opacity:0;transform:translateY(30px) scale(.97)}to{opacity:1;transform:translateY(0) scale(1)}}
        @keyframes jg-line-draw{from{width:0}to{width:100%}}
        @keyframes jg-dot-pulse{0%,100%{transform:scale(1);opacity:.6}50%{transform:scale(1.5);opacity:1}}
        @keyframes jg-icon-bounce{0%,100%{transform:translateY(0)}50%{transform:translateY(-4px)}}

        .rv{opacity:0;transform:translateY(40px);transition:opacity .9s cubic-bezier(.16,1,.3,1),transform .9s cubic-bezier(.16,1,.3,1)}
        .rv.v{opacity:1;transform:translateY(0)}
        .gc{background:${P.glass};backdrop-filter:blur(20px);-webkit-backdrop-filter:blur(20px);border:1px solid ${P.glassBorder};border-radius:22px;transition:transform .35s cubic-bezier(.16,1,.3,1),box-shadow .35s,border-color .35s}
        .gc:hover{transform:translateY(-6px);box-shadow:0 24px 60px rgba(200,107,255,.12)!important;border-color:rgba(241,220,250,.18)!important}
        .svc-card{animation:jg-stagger-in .7s cubic-bezier(.16,1,.3,1) both}
        .svc-card:nth-child(1){animation-delay:.05s}.svc-card:nth-child(2){animation-delay:.1s}.svc-card:nth-child(3){animation-delay:.15s}
        .svc-card:nth-child(4){animation-delay:.2s}.svc-card:nth-child(5){animation-delay:.25s}.svc-card:nth-child(6){animation-delay:.3s}
        .svc-card .svc-icon{transition:transform .35s cubic-bezier(.16,1,.3,1)}
        .svc-card:hover .svc-icon{transform:scale(1.15) translateY(-2px)}
        .svc-card .svc-arrow{transition:transform .3s,opacity .3s;opacity:.3}
        .svc-card:hover .svc-arrow{transform:translate(3px,-3px);opacity:.8}
        .step-card{animation:jg-stagger-in .8s cubic-bezier(.16,1,.3,1) both}
        .step-card:nth-child(1){animation-delay:.1s}.step-card:nth-child(2){animation-delay:.25s}.step-card:nth-child(3){animation-delay:.4s}
        .step-card:hover .step-icon{animation:jg-icon-bounce .5s ease}
        .btn-p{position:relative;overflow:hidden;transition:transform .25s cubic-bezier(.16,1,.3,1),box-shadow .25s}
        .btn-p:hover{transform:translateY(-3px) scale(1.02);box-shadow:0 24px 56px ${P.glowAccent}!important}
        .btn-p::before{content:'';position:absolute;top:0;left:-100%;width:60%;height:100%;background:linear-gradient(90deg,transparent,rgba(255,255,255,.12),transparent);transition:left .6s}
        .btn-p:hover::before{left:150%}
        .nav-a{color:${P.textSoft};text-decoration:none;font-size:14px;font-weight:500;transition:color .25s,transform .25s;position:relative;display:inline-block}
        .nav-a:hover{color:${P.accent};transform:translateY(-1px)}
        .nav-a::after{content:'';position:absolute;bottom:-4px;left:50%;width:0;height:2px;background:${P.gradPrimary};border-radius:2px;transition:width .3s,left .3s}
        .nav-a:hover::after{width:100%;left:0}
        .cx{max-width:1220px;margin:0 auto;padding:0 32px}
        .sec{padding:80px 0}

        @media(max-width:960px){
          .hero-g{grid-template-columns:1fr!important;text-align:center}
          .hero-l{align-items:center}
          .hero-badges{justify-content:center}
          .hero-btns{justify-content:center}
          .svc-g{grid-template-columns:1fr 1fr!important}
          .how-g{grid-template-columns:1fr!important}
          .bento-g{grid-template-columns:1fr 1fr!important}
          .pilot-g{grid-template-columns:1fr!important}
          .stat-g{grid-template-columns:1fr 1fr!important}
          .foot-g{grid-template-columns:1fr 1fr!important}
          .mob-hide{display:none!important}
        }
        @media(max-width:640px){
          .svc-g{grid-template-columns:1fr!important}
          .bento-g{grid-template-columns:1fr!important}
          .stat-g{grid-template-columns:1fr!important}
          .foot-g{grid-template-columns:1fr!important}
        }
      `}</style>

      <div style={{ background: P.gradBackground, color: P.heading, minHeight: "100vh" }}>

        {/* CURSOR GLOW */}
        <div className="mob-hide" style={{ position: "fixed", left: mouse.x - 250, top: mouse.y - 250, width: 500, height: 500, background: `radial-gradient(circle, rgba(201,140,255,.08) 0%, transparent 65%)`, pointerEvents: "none", zIndex: 9990, transition: "left .08s linear, top .08s linear" }} />

        {/* ═══ NAV ═══ */}
        <nav style={{ position: "fixed", top: 0, left: 0, right: 0, zIndex: 500, backdropFilter: scrolled ? "blur(24px) saturate(1.6)" : "blur(0px)", WebkitBackdropFilter: scrolled ? "blur(24px) saturate(1.6)" : "blur(0px)", background: scrolled ? P.glass : "transparent", borderBottom: scrolled ? `1px solid ${P.glassBorder}` : "1px solid transparent", transition: "all .5s cubic-bezier(.16,1,.3,1)", boxShadow: scrolled ? `0 8px 40px ${P.glowPrimary}` : "none" }}>
          <div className="cx" style={{ height: 80, display: "flex", alignItems: "center", justifyContent: "space-between" }}>
            <a href="/" style={{ display: "flex", alignItems: "center", gap: 10, textDecoration: "none" }}>
              <div style={{ width: 38, height: 38, borderRadius: 12, background: P.gradPrimary, display: "flex", alignItems: "center", justifyContent: "center", boxShadow: `0 4px 24px ${P.glowAccent}` }}>
                <span style={{ fontSize: 17, fontWeight: 900, color: "#fff", fontFamily: ft }}>J</span>
              </div>
              <span style={{ fontSize: 23, fontWeight: 900, color: P.heading, fontFamily: ft, letterSpacing: -.5 }}>JAGO</span>
            </a>
            <div className="mob-hide" style={{ display: "flex", gap: 40, alignItems: "center" }}>
              {[["#services", "Services"], ["#how", "How It Works"], ["#why", "Why JAGO"], ["#earn", "Earn"], ["#download", "Download"]].map(([h, l]) => (
                <a key={h} href={h} className="nav-a">{l}</a>
              ))}
            </div>
            <a href="#download" className="btn-p" style={{ padding: "11px 26px", borderRadius: 14, background: P.gradPrimary, color: "#fff", fontSize: 13.5, fontWeight: 700, textDecoration: "none", fontFamily: ft, boxShadow: `0 8px 28px ${P.glowAccent}` }}>
              Book Ride
            </a>
          </div>
        </nav>

        {/* ═══ HERO ═══ */}
        <section style={{ minHeight: "100vh", display: "flex", alignItems: "center", position: "relative", overflow: "hidden", paddingTop: 80 }}>
          <Particles />
          {/* Orbs */}
          <div style={{ position: "absolute", top: "5%", right: "-8%", width: 900, height: 900, borderRadius: "50%", background: `radial-gradient(circle, ${P.glowAccent} 0%, transparent 55%)`, animation: "jg-orb-move 20s ease-in-out infinite", pointerEvents: "none" }} />
          <div style={{ position: "absolute", bottom: "-5%", left: "-12%", width: 700, height: 700, borderRadius: "50%", background: `radial-gradient(circle, ${P.glowPink} 0%, transparent 55%)`, animation: "jg-orb-move 25s ease-in-out infinite reverse", pointerEvents: "none" }} />
          <div style={{ position: "absolute", top: "50%", left: "35%", width: 500, height: 500, borderRadius: "50%", background: `radial-gradient(circle, ${P.glowPrimary} 0%, transparent 55%)`, animation: "jg-orb-move 18s ease-in-out infinite 3s", pointerEvents: "none" }} />
          {/* Grid */}
          <div style={{ position: "absolute", inset: 0, backgroundImage: `linear-gradient(rgba(241,220,250,.03) 1px, transparent 1px), linear-gradient(90deg, rgba(241,220,250,.03) 1px, transparent 1px)`, backgroundSize: "80px 80px", pointerEvents: "none" }} />
          {/* Light beam */}
          <div style={{ position: "absolute", top: 0, left: "25%", width: 180, height: "160%", background: "linear-gradient(90deg, transparent, rgba(241,220,250,.02), transparent)", animation: "jg-light 10s linear infinite", pointerEvents: "none" }} />
          {/* Noise */}
          <div style={{ position: "absolute", inset: 0, opacity: .025, backgroundImage: `url("data:image/svg+xml,%3Csvg viewBox='0 0 256 256' xmlns='http://www.w3.org/2000/svg'%3E%3Cfilter id='n'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='.85' numOctaves='4' stitchTiles='stitch'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23n)' opacity='.5'/%3E%3C/svg%3E")`, backgroundSize: "128px", pointerEvents: "none" }} />

          <div className="cx hero-g" style={{ width: "100%", display: "grid", gridTemplateColumns: "1.15fr 0.85fr", gap: 56, alignItems: "center", padding: "88px 32px 110px", position: "relative", zIndex: 2 }}>
            {/* LEFT */}
            <div className="hero-l" style={{ display: "flex", flexDirection: "column", animation: "jg-fade-up 1.1s cubic-bezier(.16,1,.3,1) forwards" }}>
              {/* Live badge */}
              <div style={{ display: "inline-flex", alignItems: "center", gap: 8, background: "rgba(200,107,255,.08)", border: `1px solid rgba(200,107,255,.2)`, borderRadius: 40, padding: "7px 20px 7px 14px", marginBottom: 36, backdropFilter: "blur(12px)", alignSelf: "flex-start" }}>
                <div style={{ width: 7, height: 7, borderRadius: "50%", background: "#4ade80", animation: "jg-pulse 1.8s infinite" }} />
                <span style={{ fontSize: 12, fontWeight: 600, color: P.heading, fontFamily: ft }}>🚀 India's Smartest Mobility Super App</span>
              </div>

              {/* Heading */}
              <h1 style={{ fontSize: "clamp(36px, 4.8vw, 62px)", fontWeight: 900, lineHeight: 1.05, marginBottom: 24, fontFamily: ft, letterSpacing: -2.5 }}>
                <span style={{ color: P.heading, display: "block" }}>Smart Rides.</span>
                <span style={{ background: P.gradText, backgroundSize: "300% auto", backgroundClip: "text", WebkitBackgroundClip: "text", color: "transparent", animation: "jg-grad-shift 5s ease-in-out infinite", display: "inline-block" }}>
                  Smarter Journeys.
                </span>
              </h1>

              <p style={{ fontSize: 16, color: P.textSoft, lineHeight: 1.7, maxWidth: 480, marginBottom: 36, fontWeight: 400, letterSpacing: -.2 }}>
                India's smartest mobility super app for rides, deliveries, rentals and driver earnings. Book any ride in under 60 seconds.
              </p>

              {/* CTA */}
              <div className="hero-btns" style={{ display: "flex", gap: 16, flexWrap: "wrap", marginBottom: 36 }}>
                <a href="#download" className="btn-p" style={{ display: "inline-flex", alignItems: "center", gap: 10, background: P.gradPrimary, color: "#fff", padding: "17px 36px", borderRadius: 18, textDecoration: "none", fontFamily: ft, fontWeight: 800, fontSize: 16, boxShadow: `0 16px 48px ${P.glowAccent}` }}>
                  Book Ride
                  <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round"><path d="M5 12h14M12 5l7 7-7 7" /></svg>
                </a>
                <a href="/auth" className="btn-p" style={{ display: "inline-flex", alignItems: "center", gap: 10, background: P.glass, border: `1.5px solid ${P.glassBorder}`, backdropFilter: "blur(12px)", color: P.accent, padding: "17px 32px", borderRadius: 18, textDecoration: "none", fontFamily: ft, fontWeight: 700, fontSize: 16 }}>
                  Become Pilot
                </a>
              </div>

              {/* Store */}
              <div style={{ display: "flex", gap: 12, flexWrap: "wrap", marginBottom: 48 }}>
                {[
                  { l: "App Store", s: "Download on the", ic: <svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor"><path d="M17.05 20.28c-.98.95-2.05.8-3.08.35-1.09-.46-2.09-.48-3.24 0-1.44.62-2.2.44-3.06-.35C2.79 15.25 3.51 7.7 9.05 7.42c1.42.07 2.4.78 3.22.83 1.23-.24 2.4-1 3.72-.87 1.58.17 2.86.77 3.62 2.06-3.27 1.98-2.53 6.2.72 7.43-.6 1.65-1.36 3.26-3.28 5.41zM12.03 7.25c-.15-2.23 1.66-4.07 3.74-4.25.29 2.58-2.34 4.5-3.74 4.25z" /></svg> },
                  { l: "Google Play", s: "Get it on", ic: <svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor"><path d="M3 20.5v-17c0-.83.94-1.3 1.6-.8l14 8.5a1 1 0 010 1.6l-14 8.5c-.66.5-1.6.03-1.6-.8z" /></svg> },
                ].map(d => (
                  <a key={d.l} href="#download" style={{ display: "flex", alignItems: "center", gap: 10, background: P.glass, border: `1px solid ${P.glassBorder}`, backdropFilter: "blur(12px)", color: P.heading, padding: "11px 20px", borderRadius: 14, textDecoration: "none", fontFamily: ft, transition: "all .3s" }}>
                    <span style={{ color: P.primary, display: "flex" }}>{d.ic}</span>
                    <div><div style={{ fontSize: 8.5, color: P.textMuted, textTransform: "uppercase", letterSpacing: .8 }}>{d.s}</div><div style={{ fontSize: 13.5, fontWeight: 700 }}>{d.l}</div></div>
                  </a>
                ))}
              </div>

              {/* Trust */}
              <div className="hero-badges" style={{ display: "flex", gap: 40, flexWrap: "wrap" }}>
                {[{ v: "500K+", l: "Rides" }, { v: "20K+", l: "Drivers" }, { v: "50+", l: "Cities" }].map((s, i) => (
                  <div key={i} style={{ display: "flex", alignItems: "center", gap: 10 }}>
                    <span style={{ fontSize: 16 }}>⭐</span>
                    <div>
                      <p style={{ fontSize: 22, fontWeight: 900, color: P.heading, margin: 0, fontFamily: ft, lineHeight: 1 }}>{s.v}</p>
                      <p style={{ fontSize: 11, color: P.textMuted, margin: "2px 0 0", fontFamily: ft, letterSpacing: .8, textTransform: "uppercase" }}>{s.l}</p>
                    </div>
                  </div>
                ))}
              </div>
            </div>

            {/* RIGHT */}
            <div style={{ display: "flex", justifyContent: "center" }}>
              <FloatingPhone />
            </div>
          </div>

          <div style={{ position: "absolute", bottom: 0, left: 0, right: 0, height: 180, background: `linear-gradient(transparent, ${P.cream})`, pointerEvents: "none", zIndex: 3 }} />
        </section>

        <Marquee />

        {/* ═══ SERVICES ═══ */}
        <section id="services" className="sec" style={{ position: "relative" }}>
          <div className="cx">
            <div ref={rSvc.ref} className={`rv${rSvc.vis ? " v" : ""}`}>
              <SecHead tag="Our Services" title={<>Every ride, <GradWord>every need.</GradWord></>} sub="From city hops to long-distance hauls — JAGO handles it all." />
              <div className="svc-g" style={{ display: "grid", gridTemplateColumns: "repeat(3, 1fr)", gap: 14 }}>
                {[
                  { e: "🏍️", t: "Bike Taxi", d: "Fastest through city traffic.", tag: "Popular", c: "#c86bff" },
                  { e: "🛺", t: "Auto Ride", d: "Comfortable CNG auto rides.", tag: "Eco", c: "#ff7de8" },
                  { e: "🚗", t: "Cab Ride", d: "AC cabs for business & family.", tag: "Premium", c: "#f1dcfa" },
                  { e: "🔄", t: "Rentals", d: "Hourly & daily vehicle rentals.", tag: "Flexible", c: "#60a5fa" },
                  { e: "📦", t: "Parcel Delivery", d: "Same-day door to door delivery.", tag: "Express", c: "#4ade80" },
                  { e: "🛣️", t: "Outstation", d: "Transparent long-distance rides.", tag: "Long-haul", c: "#fbbf24" },
                ].map((s, i) => (
                  <div key={i} className={`gc svc-card`} style={{ padding: 0, overflow: "hidden", cursor: "pointer", position: "relative" }}>
                    {/* Gradient left edge */}
                    <div style={{ position: "absolute", left: 0, top: 0, bottom: 0, width: 3, background: `linear-gradient(180deg, ${s.c}, transparent)`, borderRadius: "22px 0 0 22px" }} />
                    <div style={{ padding: "20px 22px", display: "flex", alignItems: "center", gap: 16 }}>
                      <div className="svc-icon" style={{ width: 50, height: 50, borderRadius: 14, background: `${s.c}10`, border: `1px solid ${s.c}18`, display: "flex", alignItems: "center", justifyContent: "center", fontSize: 26, flexShrink: 0, filter: `drop-shadow(0 2px 8px ${s.c}25)` }}>{s.e}</div>
                      <div style={{ flex: 1, minWidth: 0 }}>
                        <div style={{ display: "flex", alignItems: "center", gap: 8, marginBottom: 4 }}>
                          <h3 style={{ fontSize: 15, fontWeight: 800, color: P.heading, fontFamily: ft, margin: 0, letterSpacing: -.3 }}>{s.t}</h3>
                          <span style={{ fontSize: 8, fontWeight: 700, color: s.c, textTransform: "uppercase", letterSpacing: 1.2, background: `${s.c}10`, border: `1px solid ${s.c}20`, borderRadius: 20, padding: "2px 8px", fontFamily: ft }}>{s.tag}</span>
                        </div>
                        <p style={{ fontSize: 12.5, color: P.textSoft, lineHeight: 1.5, margin: 0 }}>{s.d}</p>
                      </div>
                      <svg className="svc-arrow" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke={s.c} strokeWidth="2.5" strokeLinecap="round"><path d="M7 17l9.2-9.2M17 17V7.8H7.8" /></svg>
                    </div>
                    {/* Corner glow */}
                    <div style={{ position: "absolute", bottom: -10, right: -10, width: 50, height: 50, borderRadius: "50%", background: `${s.c}06`, filter: "blur(18px)", pointerEvents: "none" }} />
                  </div>
                ))}
              </div>
            </div>
          </div>
        </section>

        {/* ═══ HOW IT WORKS ═══ */}
        <section id="how" className="sec" style={{ background: P.cream, position: "relative", overflow: "hidden" }}>
          <div style={{ position: "absolute", top: "50%", left: "50%", transform: "translate(-50%,-50%)", width: 500, height: 500, borderRadius: "50%", background: `radial-gradient(circle, ${P.glowAccent} 0%, transparent 55%)`, opacity: .15, pointerEvents: "none" }} />
          <div className="cx" style={{ position: "relative", zIndex: 2 }}>
            <div ref={rHow.ref} className={`rv${rHow.vis ? " v" : ""}`}>
              <SecHead tag="How It Works" title={<>Ride in <GradWord>3 simple steps</GradWord></>} sub="From booking to destination — fast, safe, effortless." />
              <div className="how-g" style={{ display: "grid", gridTemplateColumns: "repeat(3,1fr)", gap: 16, position: "relative" }}>
                {/* Connecting line */}
                <div className="mob-hide" style={{ position: "absolute", top: 38, left: "17%", right: "17%", height: 2, overflow: "hidden", zIndex: 0 }}>
                  <div style={{ width: rHow.vis ? "100%" : "0%", height: "100%", background: `linear-gradient(90deg, ${P.accent}40, ${P.pink}40, ${P.primary}40)`, transition: "width 1.5s cubic-bezier(.16,1,.3,1) .3s", borderRadius: 2 }} />
                </div>
                {/* Connector dots */}
                {[33, 66].map((pos, di) => (
                  <div key={di} className="mob-hide" style={{ position: "absolute", top: 34, left: `${pos}%`, width: 10, height: 10, borderRadius: "50%", background: di === 0 ? P.accent : P.pink, border: `2px solid ${P.cream}`, zIndex: 1, opacity: rHow.vis ? 1 : 0, transform: rHow.vis ? "scale(1)" : "scale(0)", transition: `all .5s cubic-bezier(.16,1,.3,1) ${.6 + di * .3}s`, boxShadow: `0 0 12px ${di === 0 ? P.glowAccent : P.glowPink}` }} />
                ))}
                {[
                  { n: "01", ic: "📍", t: "Enter destination", d: "Type where you want to go. Instant fare estimates, zero surprises.", c: P.accent },
                  { n: "02", ic: "⚡", t: "Match instantly", d: "Verified pilot accepts in under 60 seconds. Track arrival live.", c: P.pink },
                  { n: "03", ic: "🎉", t: "Ride smoothly", d: "Confirm OTP, enjoy the ride. Pay via UPI, card, or wallet.", c: P.primary },
                ].map((s, i) => (
                  <div key={i} className="gc step-card" style={{ padding: "28px 24px", position: "relative", overflow: "hidden", zIndex: 2 }}>
                    <div style={{ position: "absolute", top: 12, right: 16, fontSize: 56, fontWeight: 900, color: `${s.c}08`, fontFamily: ft, lineHeight: 1, pointerEvents: "none" }}>{s.n}</div>
                    <div className="step-icon" style={{ width: 52, height: 52, borderRadius: 16, background: `${s.c}10`, border: `1px solid ${s.c}18`, display: "flex", alignItems: "center", justifyContent: "center", marginBottom: 18, fontSize: 24, position: "relative" }}>
                      {s.ic}
                      <div style={{ position: "absolute", inset: -3, borderRadius: 19, border: `1px solid ${s.c}12`, animation: "jg-pulse 3s infinite" }} />
                    </div>
                    <h3 style={{ fontSize: 16, fontWeight: 800, color: P.heading, fontFamily: ft, marginBottom: 8, letterSpacing: -.3 }}>{s.t}</h3>
                    <p style={{ fontSize: 13, color: P.textSoft, lineHeight: 1.65 }}>{s.d}</p>
                  </div>
                ))}
              </div>
            </div>
          </div>
        </section>

        {/* ═══ WHY JAGO ═══ */}
        <section id="why" className="sec" style={{ position: "relative" }}>
          <div className="cx">
            <div ref={rWhy.ref} className={`rv${rWhy.vis ? " v" : ""}`}>
              <SecHead tag="Why JAGO" title={<>Built different, <GradWord>built better.</GradWord></>} sub="Everything you need for safe, affordable, and lightning-fast rides." />
              <div className="bento-g" style={{ display: "grid", gridTemplateColumns: "repeat(4, 1fr)", gap: 16 }}>
                {[
                  { ic: "⚡", t: "60 sec booking", d: "Matched with a verified pilot in under a minute.", c: P.accent, span: 1 },
                  { ic: "📡", t: "Live tracking", d: "Real-time GPS with family share link.", c: P.pink, span: 1 },
                  { ic: "🛡️", t: "Verified drivers", d: "Background-checked, KYC verified, trained.", c: "#4ade80", span: 1 },
                  { ic: "💰", t: "Lowest fares", d: "No surge. Transparent billing, always.", c: "#fbbf24", span: 1 },
                  { ic: "💎", t: "Wallet cashback", d: "Earn JAGO coins on every ride. Redeem for rewards.", c: P.accent, span: 1 },
                  { ic: "🔒", t: "Safety shield", d: "SOS button, ride sharing, 24/7 monitoring.", c: P.primary, span: 1 },
                  { ic: "🎧", t: "24/7 support", d: "Round the clock via chat, call, and email.", c: "#60a5fa", span: 1 },
                  { ic: "⭐", t: "4.9 rating", d: "Highest rated ride app in South India.", c: "#fbbf24", span: 1 },
                ].map((w, i) => (
                  <div key={i} className="gc" style={{ padding: "28px 24px", gridColumn: w.span > 1 ? `span ${w.span}` : undefined, position: "relative", overflow: "hidden" }}>
                    <div style={{ width: 52, height: 52, borderRadius: 16, background: `${w.c}10`, border: `1px solid ${w.c}18`, display: "flex", alignItems: "center", justifyContent: "center", marginBottom: 18, fontSize: 24 }}>{w.ic}</div>
                    <h4 style={{ fontSize: 16, fontWeight: 800, color: P.heading, fontFamily: ft, marginBottom: 6, letterSpacing: -.3 }}>{w.t}</h4>
                    <p style={{ fontSize: 13, color: P.textSoft, lineHeight: 1.65 }}>{w.d}</p>
                    <div style={{ position: "absolute", bottom: -8, right: -8, width: 50, height: 50, borderRadius: "50%", background: `${w.c}06`, filter: "blur(18px)", pointerEvents: "none" }} />
                  </div>
                ))}
              </div>
            </div>
          </div>
        </section>

        {/* ═══ PILOT EARNINGS ═══ */}
        <section id="earn" className="sec" style={{ background: P.mint, position: "relative", overflow: "hidden" }}>
          <div style={{ position: "absolute", inset: 0, backgroundImage: `radial-gradient(circle at 78% 50%, ${P.glowAccent} 0%, transparent 45%)`, pointerEvents: "none", opacity: .3 }} />
          <div className="cx" style={{ position: "relative", zIndex: 2 }}>
            <div ref={rPilot.ref} className={`rv${rPilot.vis ? " v" : ""}`}>
              <div className="pilot-g" style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 64, alignItems: "center" }}>
                <div>
                  <SecHead tag="Pilot Earnings" title={<>Drive more. <span style={{ color: P.primary }}>Earn more.</span></>} sub="JAGO pilots earn industry-leading pay with daily payouts, surge bonuses, and zero commission for first 3 months." align="left" />
                  <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 14, marginBottom: 40 }}>
                    {[
                      { v: "₹2,500+", l: "Daily earnings", c: P.accent },
                      { v: "0%", l: "Commission · 90 days", c: P.pink },
                      { v: "Instant", l: "Daily payouts", c: P.primary },
                      { v: "₹8/L", l: "Fuel savings", c: "#4ade80" },
                    ].map((e, i) => (
                      <div key={i} style={{ background: `${e.c}08`, borderRadius: 20, padding: "22px 18px", border: `1px solid ${e.c}15` }}>
                        <p style={{ fontSize: 30, fontWeight: 900, color: e.c, fontFamily: ft, margin: "0 0 4px", lineHeight: 1 }}>{e.v}</p>
                        <p style={{ fontSize: 12, color: P.textSoft, margin: 0 }}>{e.l}</p>
                      </div>
                    ))}
                  </div>
                  <a href="/auth" className="btn-p" style={{ display: "inline-flex", alignItems: "center", gap: 10, padding: "15px 32px", borderRadius: 16, background: P.gradPrimary, color: "#fff", textDecoration: "none", fontSize: 15, fontWeight: 800, fontFamily: ft, boxShadow: `0 10px 32px ${P.glowAccent}` }}>
                    Become a Pilot <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round"><path d="M5 12h14M12 5l7 7-7 7" /></svg>
                  </a>
                </div>

                {/* Dashboard */}
                <div className="gc" style={{ padding: "36px", position: "relative", overflow: "hidden" }}>
                  <div style={{ marginBottom: 28 }}>
                    <p style={{ fontSize: 12, color: P.textMuted, margin: "0 0 6px", fontFamily: ft, textTransform: "uppercase", letterSpacing: 2 }}>This Week's Earnings</p>
                    <p style={{ fontSize: 52, fontWeight: 900, color: P.white, fontFamily: ft, margin: 0, lineHeight: 1, letterSpacing: -2 }}>₹17,500</p>
                    <div style={{ display: "inline-flex", alignItems: "center", gap: 4, marginTop: 8, background: "rgba(74,222,128,.1)", borderRadius: 20, padding: "3px 12px" }}>
                      <span style={{ fontSize: 12, color: "#4ade80", fontWeight: 700 }}>↑ 12%</span>
                      <span style={{ fontSize: 10, color: P.textMuted }}>vs last week</span>
                    </div>
                  </div>
                  {/* Chart */}
                  <div style={{ display: "flex", alignItems: "flex-end", gap: 10, height: 130, marginBottom: 28 }}>
                    {[60, 78, 42, 88, 65, 95, 82].map((h, i) => (
                      <div key={i} style={{ flex: 1, display: "flex", flexDirection: "column", alignItems: "center", gap: 6 }}>
                        <div style={{ width: "100%", height: `${h}%`, borderRadius: 8, background: i === 5 ? P.gradPrimary : `rgba(200,107,255,.15)`, border: i === 5 ? "none" : `1px solid rgba(200,107,255,.08)`, animation: rPilot.vis ? `jg-bar-grow .7s cubic-bezier(.16,1,.3,1) forwards` : "none", animationDelay: `${i * .08}s`, transformOrigin: "bottom" }} />
                        <span style={{ fontSize: 9, color: P.textMuted, fontFamily: ft, fontWeight: 600 }}>{["M", "T", "W", "T", "F", "S", "S"][i]}</span>
                      </div>
                    ))}
                  </div>
                  {/* Mini stats */}
                  <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr 1fr", gap: 10 }}>
                    {[{ v: "42", l: "Rides", ic: "🏍️" }, { v: "₹417", l: "Per ride", ic: "💰" }, { v: "4.9", l: "Rating", ic: "⭐" }].map((s, i) => (
                      <div key={i} style={{ background: P.glass2, borderRadius: 14, padding: "14px 12px", textAlign: "center", border: `1px solid ${P.glassBorder2}` }}>
                        <span style={{ fontSize: 18, display: "block", marginBottom: 4 }}>{s.ic}</span>
                        <p style={{ fontSize: 20, fontWeight: 900, color: P.white, fontFamily: ft, margin: "2px 0" }}>{s.v}</p>
                        <p style={{ fontSize: 10, color: P.textMuted, margin: 0 }}>{s.l}</p>
                      </div>
                    ))}
                  </div>
                  {/* Decorative ring */}
                  <div style={{ position: "absolute", top: -35, right: -35, width: 110, height: 110, borderRadius: "50%", border: `2px solid ${P.glassBorder}`, borderTopColor: P.primary, animation: "jg-spin-slow 10s linear infinite", pointerEvents: "none", opacity: .4 }} />
                </div>
              </div>
            </div>
          </div>
        </section>

        {/* ═══ STATS ═══ */}
        <section className="sec" style={{ position: "relative", overflow: "hidden" }}>
          <div style={{ position: "absolute", inset: 0, backgroundImage: `linear-gradient(rgba(241,220,250,.025) 1px, transparent 1px), linear-gradient(90deg, rgba(241,220,250,.025) 1px, transparent 1px)`, backgroundSize: "64px 64px", pointerEvents: "none" }} />
          <div className="cx" style={{ position: "relative", zIndex: 2 }}>
            <div ref={rStats.ref} className={`rv${rStats.vis ? " v" : ""}`}>
              <SecHead tag="By The Numbers" title={<>Numbers that <GradWord>speak volumes</GradWord></>} sub="Real performance. Real trust. Growing every day." />
              <div className="stat-g" style={{ display: "grid", gridTemplateColumns: "repeat(4,1fr)", gap: 18 }}>
                {[
                  { r: cRides.ref, v: `${(cRides.val / 1000).toFixed(0)}K+`, l: "Rides Completed", ic: "🚀", c: P.accent },
                  { r: cCities.ref, v: `${cCities.val}+`, l: "Cities Active", ic: "🌍", c: P.pink },
                  { r: cPilots.ref, v: `${(cPilots.val / 1000).toFixed(0)}K+`, l: "Verified Pilots", ic: "🏍️", c: P.primary },
                  { r: cRating.ref, v: `${(cRating.val / 10).toFixed(1)}★`, l: "Avg Rating", ic: "⭐", c: "#fbbf24" },
                ].map((s, i) => (
                  <div key={i} ref={s.r} className="gc" style={{ textAlign: "center", padding: "48px 20px", position: "relative", overflow: "hidden" }}>
                    <span style={{ fontSize: 36, display: "block", marginBottom: 16 }}>{s.ic}</span>
                    <p style={{ fontSize: 54, fontWeight: 900, color: P.heading, margin: "0 0 8px", fontFamily: ft, lineHeight: 1, letterSpacing: -2, animation: rStats.vis ? "jg-counter-glow 2s ease-in-out infinite" : "none" }}>{s.v}</p>
                    <p style={{ fontSize: 14, color: P.textSoft, fontFamily: ft }}>{s.l}</p>
                    <div style={{ position: "absolute", bottom: -15, left: "50%", transform: "translateX(-50%)", width: 100, height: 50, borderRadius: "50%", background: `${s.c}15`, filter: "blur(25px)", pointerEvents: "none" }} />
                  </div>
                ))}
              </div>
            </div>
          </div>
        </section>

        {/* ═══ FINAL CTA ═══ */}
        <section id="download" className="sec" style={{ background: P.sky }}>
          <div className="cx">
            <div ref={rCta.ref} className={`rv${rCta.vis ? " v" : ""}`}>
              <div style={{ borderRadius: 36, padding: "88px 56px", background: `linear-gradient(135deg, ${P.primary} 0%, rgba(201,140,255,.1) 50%, rgba(255,217,246,.06) 100%)`, border: `1px solid ${P.glassBorder}`, position: "relative", overflow: "hidden", textAlign: "center" }}>
                {/* Orbs */}
                <div style={{ position: "absolute", top: -100, right: -80, width: 350, height: 350, borderRadius: "50%", background: P.glowAccent, filter: "blur(100px)", pointerEvents: "none" }} />
                <div style={{ position: "absolute", bottom: -80, left: -60, width: 300, height: 300, borderRadius: "50%", background: P.glowPink, filter: "blur(100px)", pointerEvents: "none" }} />

                <div style={{ position: "relative", zIndex: 1 }}>
                  <div style={{ width: 80, height: 80, borderRadius: 24, background: P.gradPrimary, display: "flex", alignItems: "center", justifyContent: "center", margin: "0 auto 28px", boxShadow: `0 16px 48px ${P.glowAccent}` }}>
                    <span style={{ fontSize: 32, fontWeight: 900, color: "#fff", fontFamily: ft }}>J</span>
                  </div>
                  <h2 style={{ fontSize: "clamp(36px, 5.5vw, 64px)", fontWeight: 900, fontFamily: ft, letterSpacing: -2.5, marginBottom: 18 }}>
                    <span style={{ background: P.gradText, backgroundSize: "300% auto", backgroundClip: "text", WebkitBackgroundClip: "text", color: "transparent", animation: "jg-grad-shift 5s ease-in-out infinite" }}>Ready to Ride?</span>
                  </h2>
                  <p style={{ fontSize: 18, color: P.textSoft, maxWidth: 500, margin: "0 auto 20px", lineHeight: 1.7 }}>
                    Download now and get your first ride up to <strong style={{ color: P.primary }}>₹50 OFF</strong> with code{" "}
                    <strong style={{ background: P.glass, padding: "3px 12px", borderRadius: 8, border: `1px solid ${P.glassBorder}` }}>JAGOPRO50</strong>
                  </p>

                  <div style={{ display: "flex", gap: 16, justifyContent: "center", flexWrap: "wrap", marginTop: 40 }}>
                    {[
                      { l: "Customer App", ic: "📱", href: "/apks/jago-customer-latest.apk", primary: false },
                      { l: "Driver App", ic: "🏍️", href: "/apks/jago-driver-latest.apk", primary: false },
                      { l: "Become Pilot", ic: "🚀", href: "/auth", primary: true },
                    ].map(d => (
                      <a key={d.l} href={d.href} className="btn-p" style={{
                        display: "flex", alignItems: "center", gap: 10,
                        background: d.primary ? P.gradPrimary : P.white,
                        color: d.primary ? "#fff" : P.heading,
                        padding: "17px 32px", borderRadius: 18,
                        textDecoration: "none", fontFamily: ft, fontWeight: 800, fontSize: 15,
                        boxShadow: d.primary ? `0 14px 40px ${P.glowAccent}` : "0 10px 36px rgba(255,255,255,.12)",
                      }}>
                        <span style={{ fontSize: 20 }}>{d.ic}</span>{d.l}
                      </a>
                    ))}
                  </div>
                </div>
              </div>
            </div>
          </div>
        </section>

        {/* ═══ FOOTER ═══ */}
        <footer style={{ background: P.white, borderTop: `1px solid ${P.glassBorder2}`, padding: "72px 0 36px" }}>
          <div className="cx">
            <div className="foot-g" style={{ display: "grid", gridTemplateColumns: "1.6fr 1fr 1fr 1fr", gap: 48, marginBottom: 56 }}>
              <div>
                <div style={{ display: "flex", alignItems: "center", gap: 10, marginBottom: 18 }}>
                  <div style={{ width: 36, height: 36, borderRadius: 10, background: P.gradPrimary, display: "flex", alignItems: "center", justifyContent: "center" }}>
                    <span style={{ fontSize: 15, fontWeight: 900, color: "#fff" }}>J</span>
                  </div>
                  <span style={{ fontSize: 22, fontWeight: 900, color: P.heading, fontFamily: ft }}>JAGO</span>
                </div>
                <p style={{ fontSize: 14, color: P.textMuted, lineHeight: 1.7, maxWidth: 300 }}>India's smart ride-hailing platform. Book bike taxi, auto, cab, parcel delivery and more. Instantly.</p>
                <div style={{ display: "flex", gap: 10, marginTop: 20 }}>
                  {["𝕏", "in", "IG", "YT"].map(s => (
                    <div key={s} style={{ width: 36, height: 36, borderRadius: 10, background: P.glass, border: `1px solid ${P.glassBorder2}`, display: "flex", alignItems: "center", justifyContent: "center", cursor: "pointer", transition: "all .3s", fontSize: 12, fontWeight: 700, color: P.textMuted }}>
                      {s}
                    </div>
                  ))}
                </div>
              </div>
              {[
                { t: "Company", links: [["About Us", "/about-us"], ["Contact", "/contact-us"], ["Careers", "#"], ["Blog", "#"]] },
                { t: "Legal", links: [["Privacy Policy", "/privacy"], ["Terms of Service", "/terms"], ["Refund Policy", "/refund-policy"], ["Cookie Policy", "/cookie-policy"]] },
                { t: "Support", links: [["Help Center", "#"], ["Safety", "#"], ["FAQs", "#"], ["Partner Hub", "#"]] },
              ].map(col => (
                <div key={col.t}>
                  <h4 style={{ fontSize: 12, fontWeight: 700, color: P.textMuted, textTransform: "uppercase", letterSpacing: 2, marginBottom: 20, fontFamily: ft }}>{col.t}</h4>
                  {col.links.map(([l, h]) => (
                    <a key={l} href={h} style={{ display: "block", fontSize: 14, color: P.textMuted, textDecoration: "none", marginBottom: 12, transition: "color .2s", fontFamily: ft }}
                      onMouseOver={e => ((e.target as HTMLElement).style.color = P.primary)}
                      onMouseOut={e => ((e.target as HTMLElement).style.color = P.textMuted)}
                    >{l}</a>
                  ))}
                </div>
              ))}
            </div>
            <div style={{ borderTop: `1px solid ${P.glassBorder2}`, paddingTop: 24, display: "flex", justifyContent: "space-between", alignItems: "center", flexWrap: "wrap", gap: 16 }}>
              <p style={{ fontSize: 13, color: P.textMuted, fontFamily: ft, margin: 0, opacity: .6 }}>© 2024 JAGO Pro Mobility Pvt Ltd. All rights reserved.</p>
              <p style={{ fontSize: 13, color: P.textMuted, fontFamily: ft, margin: 0, opacity: .6 }}>Made with 💜 in India</p>
            </div>
          </div>
        </footer>

        {/* MOBILE STICKY CTA */}
        <div className="mob-cta" style={{ position: "fixed", bottom: 0, left: 0, right: 0, zIndex: 300, padding: "12px 16px", paddingBottom: "max(12px, env(safe-area-inset-bottom))", background: "rgba(7,5,17,.94)", backdropFilter: "blur(24px)", borderTop: `1px solid ${P.glassBorder}`, display: "none" }}>
          <a href="#download" style={{ display: "flex", alignItems: "center", justifyContent: "center", gap: 8, width: "100%", padding: "15px", borderRadius: 16, background: P.gradPrimary, color: "#fff", textDecoration: "none", fontFamily: ft, fontWeight: 800, fontSize: 15, boxShadow: `0 -4px 28px ${P.glowAccent}` }}>
            🚀 Book Ride
          </a>
        </div>
      </div>

      <style>{`
        @media(max-width:960px){
          .mob-cta{display:block!important}
          footer{padding-bottom:84px!important}
        }
      `}</style>
    </>
  );
}
