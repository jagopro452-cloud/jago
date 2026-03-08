import { useState, useEffect, useRef } from "react";
import { useTheme } from "@/components/theme-provider";

/* ───────────────────────────── hooks ───────────────────────────── */
function useReveal() {
  const ref = useRef<HTMLDivElement>(null);
  const [vis, setVis] = useState(false);
  useEffect(() => {
    const el = ref.current;
    if (!el) return;
    const io = new IntersectionObserver(
      ([e]) => { if (e.isIntersecting) { setVis(true); io.disconnect(); } },
      { threshold: 0.12 }
    );
    io.observe(el);
    return () => io.disconnect();
  }, []);
  return { ref, vis };
}

function useCountUp(target: number, duration = 2000) {
  const [val, setVal] = useState(0);
  const ref = useRef<HTMLDivElement>(null);
  useEffect(() => {
    const el = ref.current; if (!el) return;
    const io = new IntersectionObserver(([e]) => {
      if (!e.isIntersecting) return; io.disconnect();
      const start = Date.now();
      const tick = () => {
        const p = Math.min((Date.now() - start) / duration, 1);
        const ease = 1 - Math.pow(1 - p, 3);
        setVal(Math.round(ease * target));
        if (p < 1) requestAnimationFrame(tick);
      };
      requestAnimationFrame(tick);
    }, { threshold: 0.5 });
    io.observe(el);
    return () => io.disconnect();
  }, [target, duration]);
  return { ref, val };
}

/* ──────────────────────────── PhoneDemo ────────────────────────── */
const PHONE_SCREENS = ["home", "search", "fare", "driver", "track"] as const;

function ScreenHome() {
  return (
    <div style={{ width: "100%", height: "100%", background: "#f0f4ff", display: "flex", flexDirection: "column" }}>
      <div style={{ flex: 1, background: "linear-gradient(160deg,#dbeafe 0%,#e0e7ff 60%,#d1fae5 100%)", position: "relative", overflow: "hidden" }}>
        {[...Array(7)].map((_, i) => (
          <div key={`h${i}`} style={{ position: "absolute", left: 0, right: 0, top: `${i * 15}%`, height: 1, background: "rgba(99,102,241,0.1)" }} />
        ))}
        {[...Array(7)].map((_, i) => (
          <div key={`v${i}`} style={{ position: "absolute", top: 0, bottom: 0, left: `${i * 15}%`, width: 1, background: "rgba(99,102,241,0.1)" }} />
        ))}
        <div style={{ position: "absolute", top: "10px", left: "10px", background: "#fff", borderRadius: 10, padding: "4px 10px", boxShadow: "0 2px 8px rgba(0,0,0,0.12)", display: "flex", alignItems: "center", gap: 5 }}>
          <div style={{ width: 8, height: 8, borderRadius: "50%", background: "#1E6DE5" }} />
          <span style={{ fontSize: 10, fontWeight: 800, color: "#1E6DE5", fontFamily: "Space Grotesk,sans-serif", letterSpacing: 1 }}>JAGO</span>
        </div>
        <div style={{ position: "absolute", left: "46%", top: "44%", transform: "translate(-50%,-50%)" }}>
          <div style={{ width: 16, height: 16, borderRadius: "50%", background: "#1E6DE5", border: "3px solid #fff", boxShadow: "0 0 0 6px rgba(30,109,229,0.2)" }} />
        </div>
      </div>
      <div style={{ background: "#fff", padding: "12px 12px 10px", boxShadow: "0 -4px 16px rgba(0,0,0,0.06)" }}>
        <p style={{ fontSize: 10, color: "#64748b", margin: "0 0 6px", fontFamily: "Space Grotesk,sans-serif" }}>Welcome, Rahul 👋</p>
        <div style={{ display: "flex", alignItems: "center", gap: 6, background: "#f4f6ff", borderRadius: 10, padding: "8px 10px", marginBottom: 8 }}>
          <div style={{ width: 8, height: 8, borderRadius: "50%", background: "#1E6DE5", flexShrink: 0 }} />
          <span style={{ fontSize: 11, color: "#94a3b8", fontFamily: "Space Grotesk,sans-serif" }}>Where do you want to go?</span>
        </div>
        <div style={{ display: "flex", justifyContent: "space-around" }}>
          {[{ e: "🛵", t: "Bike" }, { e: "🛺", t: "Auto" }, { e: "🚗", t: "Car" }, { e: "📦", t: "Parcel" }].map(s => (
            <div key={s.t} style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: 3 }}>
              <div style={{ width: 32, height: 32, borderRadius: 9, background: "#eff6ff", display: "flex", alignItems: "center", justifyContent: "center", fontSize: 14 }}>{s.e}</div>
              <span style={{ fontSize: 9, color: "#475569", fontFamily: "Space Grotesk,sans-serif" }}>{s.t}</span>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}

function ScreenSearch() {
  return (
    <div style={{ width: "100%", height: "100%", background: "#fff", position: "relative" }}>
      <div style={{ background: "#1E6DE5", padding: "14px 12px 18px" }}>
        <p style={{ fontSize: 10, color: "rgba(255,255,255,0.7)", margin: "0 0 8px", fontFamily: "Space Grotesk,sans-serif" }}>Select destination</p>
        <div style={{ display: "flex", alignItems: "center", gap: 7, background: "rgba(255,255,255,0.15)", borderRadius: 8, padding: "7px 9px", marginBottom: 5 }}>
          <div style={{ width: 7, height: 7, borderRadius: "50%", background: "#4ade80" }} />
          <span style={{ fontSize: 10, color: "#fff", fontFamily: "Space Grotesk,sans-serif" }}>Current Location</span>
        </div>
        <div style={{ display: "flex", alignItems: "center", gap: 7, background: "#fff", borderRadius: 8, padding: "7px 9px" }}>
          <div style={{ width: 7, height: 7, borderRadius: "50%", background: "#ef4444" }} />
          <span style={{ fontSize: 10, color: "#1E6DE5", fontWeight: 700, fontFamily: "Space Grotesk,sans-serif" }}>Hitech City Metro</span>
        </div>
      </div>
      <div style={{ padding: "10px 12px" }}>
        <p style={{ fontSize: 9, color: "#94a3b8", margin: "0 0 7px", fontFamily: "Space Grotesk,sans-serif", textTransform: "uppercase", letterSpacing: 1.2 }}>Recent Places</p>
        {[{ e: "🏢", p: "Hitech City Metro", d: "3.2 km" }, { e: "🏥", p: "Apollo Hospital", d: "5.8 km" }, { e: "🛒", p: "Inorbit Mall", d: "2.1 km" }].map((x, i) => (
          <div key={i} style={{ display: "flex", alignItems: "center", gap: 9, padding: "8px 0", borderBottom: "1px solid #f1f5f9" }}>
            <div style={{ width: 28, height: 28, borderRadius: 8, background: "#f5f7ff", display: "flex", alignItems: "center", justifyContent: "center", fontSize: 13 }}>{x.e}</div>
            <div><p style={{ margin: 0, fontSize: 11, fontWeight: 600, color: "#1e293b", fontFamily: "Space Grotesk,sans-serif" }}>{x.p}</p><p style={{ margin: 0, fontSize: 9, color: "#94a3b8", fontFamily: "Space Grotesk,sans-serif" }}>{x.d}</p></div>
          </div>
        ))}
      </div>
      <div style={{ position: "absolute", bottom: 14, left: 12, right: 12 }}>
        <div style={{ background: "#1E6DE5", borderRadius: 12, padding: "11px", textAlign: "center" }}>
          <span style={{ fontSize: 12, fontWeight: 700, color: "#fff", fontFamily: "Space Grotesk,sans-serif" }}>Book Ride →</span>
        </div>
      </div>
    </div>
  );
}

function ScreenFare() {
  return (
    <div style={{ width: "100%", height: "100%", background: "#f8f9ff", display: "flex", flexDirection: "column" }}>
      <div style={{ flex: 1, background: "linear-gradient(140deg,#dbeafe,#e0e7ff)", position: "relative", overflow: "hidden" }}>
        <svg style={{ position: "absolute", inset: 0, width: "100%", height: "100%" }} viewBox="0 0 100 100" preserveAspectRatio="none">
          <path d="M28 75 Q50 52 72 30" stroke="#1E6DE5" strokeWidth="2.5" fill="none" strokeDasharray="5 3" opacity="0.6" />
          <circle cx="28" cy="75" r="3.5" fill="#4ade80" />
          <circle cx="72" cy="30" r="3.5" fill="#ef4444" />
        </svg>
        <div style={{ position: "absolute", right: 10, top: 10, background: "#fff", borderRadius: 7, padding: "3px 8px", boxShadow: "0 2px 8px rgba(0,0,0,0.1)" }}>
          <span style={{ fontSize: 10, fontWeight: 700, color: "#1E6DE5", fontFamily: "Space Grotesk,sans-serif" }}>3.2 km</span>
        </div>
      </div>
      <div style={{ background: "#fff", padding: "12px", boxShadow: "0 -4px 16px rgba(0,0,0,0.07)" }}>
        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 10 }}>
          <div><p style={{ margin: 0, fontSize: 10, color: "#94a3b8", fontFamily: "Space Grotesk,sans-serif" }}>Recommended</p><p style={{ margin: "2px 0 0", fontSize: 12, fontWeight: 700, color: "#1e293b", fontFamily: "Space Grotesk,sans-serif" }}>🛵 Jago Bike</p></div>
          <div style={{ textAlign: "right" }}><p style={{ margin: 0, fontSize: 10, color: "#94a3b8", fontFamily: "Space Grotesk,sans-serif" }}>Est. fare</p><p style={{ margin: "2px 0 0", fontSize: 20, fontWeight: 800, color: "#1E6DE5", fontFamily: "Space Grotesk,sans-serif" }}>₹45</p></div>
        </div>
        <div style={{ display: "flex", gap: 5, marginBottom: 10 }}>
          {[{ t: "🛵 Bike", f: "₹45", e: "2 min", a: true }, { t: "🛺 Auto", f: "₹75", e: "4 min", a: false }, { t: "🚗 Car", f: "₹130", e: "5 min", a: false }].map(o => (
            <div key={o.t} style={{ flex: 1, padding: "6px 4px", borderRadius: 8, border: `1.5px solid ${o.a ? "#1E6DE5" : "#e2e8f0"}`, background: o.a ? "#eff6ff" : "#fff", textAlign: "center" }}>
              <p style={{ margin: 0, fontSize: 10, fontFamily: "Space Grotesk,sans-serif" }}>{o.t}</p>
              <p style={{ margin: "2px 0 0", fontSize: 10, fontWeight: 700, color: o.a ? "#1E6DE5" : "#64748b", fontFamily: "Space Grotesk,sans-serif" }}>{o.f}</p>
              <p style={{ margin: 0, fontSize: 9, color: "#94a3b8", fontFamily: "Space Grotesk,sans-serif" }}>{o.e}</p>
            </div>
          ))}
        </div>
        <div style={{ background: "linear-gradient(90deg,#1E6DE5,#3b82f6)", borderRadius: 10, padding: "10px", textAlign: "center" }}>
          <span style={{ fontSize: 12, fontWeight: 700, color: "#fff", fontFamily: "Space Grotesk,sans-serif" }}>Confirm Booking</span>
        </div>
      </div>
    </div>
  );
}

function ScreenDriver() {
  return (
    <div style={{ width: "100%", height: "100%", background: "#fff", display: "flex", flexDirection: "column" }}>
      <div style={{ background: "linear-gradient(135deg,#1E6DE5,#3b82f6)", padding: "18px 12px 24px", textAlign: "center" }}>
        <div style={{ width: 40, height: 40, borderRadius: "50%", background: "rgba(255,255,255,0.2)", margin: "0 auto 6px", display: "flex", alignItems: "center", justifyContent: "center", fontSize: 20 }}>✓</div>
        <p style={{ margin: 0, fontSize: 13, fontWeight: 700, color: "#fff", fontFamily: "Space Grotesk,sans-serif" }}>Pilot on the way!</p>
        <p style={{ margin: "3px 0 0", fontSize: 10, color: "rgba(255,255,255,0.8)", fontFamily: "Space Grotesk,sans-serif" }}>Arrives in 2 min</p>
      </div>
      <div style={{ flex: 1, padding: "12px", background: "#f8f9ff" }}>
        <div style={{ background: "#fff", borderRadius: 14, padding: 12, boxShadow: "0 4px 16px rgba(0,0,0,0.07)", marginBottom: 10 }}>
          <div style={{ display: "flex", alignItems: "center", gap: 10, marginBottom: 10 }}>
            <div style={{ width: 40, height: 40, borderRadius: "50%", background: "linear-gradient(135deg,#667eea,#764ba2)", display: "flex", alignItems: "center", justifyContent: "center", fontSize: 18, color: "#fff", fontWeight: 700, fontFamily: "Space Grotesk,sans-serif" }}>R</div>
            <div style={{ flex: 1 }}>
              <p style={{ margin: 0, fontSize: 12, fontWeight: 700, color: "#1e293b", fontFamily: "Space Grotesk,sans-serif" }}>Ravi Kumar</p>
              <div style={{ display: "flex", alignItems: "center", gap: 3 }}>
                <span style={{ fontSize: 10, color: "#f59e0b" }}>★</span>
                <span style={{ fontSize: 10, color: "#475569", fontFamily: "Space Grotesk,sans-serif" }}>4.8 · 1,240 rides</span>
              </div>
            </div>
            <div style={{ width: 32, height: 32, borderRadius: "50%", background: "#dcfce7", display: "flex", alignItems: "center", justifyContent: "center", fontSize: 14 }}>📞</div>
          </div>
          <div style={{ display: "flex", justifyContent: "space-between", paddingTop: 8, borderTop: "1px solid #f1f5f9" }}>
            {[{ l: "Vehicle", v: "Activa" }, { l: "Plate", v: "TS09AB1234" }, { l: "OTP", v: "7482" }].map(x => (
              <div key={x.l} style={{ textAlign: "center" }}>
                <p style={{ margin: 0, fontSize: 8, color: "#94a3b8", fontFamily: "Space Grotesk,sans-serif" }}>{x.l}</p>
                <p style={{ margin: "2px 0 0", fontSize: 10, fontWeight: 700, color: x.l === "OTP" ? "#10b981" : "#1e293b", fontFamily: "Space Grotesk,sans-serif" }}>{x.v}</p>
              </div>
            ))}
          </div>
        </div>
        <div style={{ display: "flex", alignItems: "center", gap: 7, background: "#fffbeb", borderRadius: 9, padding: "9px 10px" }}>
          <span style={{ fontSize: 13 }}>🔔</span>
          <span style={{ fontSize: 10, color: "#92400e", fontFamily: "Space Grotesk,sans-serif" }}>Share OTP with pilot only</span>
        </div>
      </div>
    </div>
  );
}

function ScreenTrack() {
  const [eta, setEta] = useState(2);
  const [dotX, setDotX] = useState(28);
  const [dotY, setDotY] = useState(68);
  useEffect(() => {
    const t = setInterval(() => {
      setEta(e => Math.max(0, e - 1));
      setDotX(x => Math.min(x + 3, 68));
      setDotY(y => Math.max(y - 3, 30));
    }, 1200);
    return () => clearInterval(t);
  }, []);
  return (
    <div style={{ width: "100%", height: "100%", background: "#f8f9ff", display: "flex", flexDirection: "column" }}>
      <div style={{ flex: 1, background: "linear-gradient(140deg,#dbeafe,#e0e7ff)", position: "relative" }}>
        <svg style={{ position: "absolute", inset: 0, width: "100%", height: "100%" }} viewBox="0 0 100 100" preserveAspectRatio="none">
          <path d="M28 68 Q48 50 68 30" stroke="#1E6DE5" strokeWidth="2.5" fill="none" opacity="0.35" />
          <circle cx="28" cy="68" r="3" fill="#4ade80" />
          <circle cx="68" cy="30" r="3" fill="#ef4444" />
          <circle cx={dotX} cy={dotY} r="4" fill="#1E6DE5" />
          <circle cx={dotX} cy={dotY} r="7" fill="rgba(30,109,229,0.18)" />
        </svg>
        <div style={{ position: "absolute", top: 10, left: "50%", transform: "translateX(-50%)", background: "#fff", borderRadius: 18, padding: "4px 12px", boxShadow: "0 2px 10px rgba(0,0,0,0.1)", display: "flex", alignItems: "center", gap: 5, whiteSpace: "nowrap" }}>
          <div style={{ width: 7, height: 7, borderRadius: "50%", background: "#10b981", animation: "jago-badge 1.2s infinite" }} />
          <span style={{ fontSize: 9.5, fontWeight: 700, color: "#1e293b", fontFamily: "Space Grotesk,sans-serif" }}>Pilot arriving in {eta} min</span>
        </div>
      </div>
      <div style={{ background: "#fff", padding: "10px 12px", boxShadow: "0 -4px 16px rgba(0,0,0,0.06)" }}>
        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 8 }}>
          <div><p style={{ margin: 0, fontSize: 11, fontWeight: 700, color: "#1e293b", fontFamily: "Space Grotesk,sans-serif" }}>Ravi Kumar · 🛵</p><p style={{ margin: "2px 0 0", fontSize: 9, color: "#94a3b8", fontFamily: "Space Grotesk,sans-serif" }}>TS09AB1234</p></div>
          <div style={{ textAlign: "right" }}><p style={{ margin: 0, fontSize: 16, fontWeight: 800, color: "#1E6DE5", fontFamily: "Space Grotesk,sans-serif" }}>₹45</p><p style={{ margin: 0, fontSize: 8.5, color: "#10b981", fontFamily: "Space Grotesk,sans-serif" }}>Cash on delivery</p></div>
        </div>
        <div style={{ display: "flex", gap: 6 }}>
          {[{ l: "📞 Call", bg: "#eff6ff", c: "#1E6DE5" }, { l: "✕ Cancel", bg: "#fff1f2", c: "#ef4444" }, { l: "💬 Chat", bg: "#f0fdf4", c: "#10b981" }].map(a => (
            <div key={a.l} style={{ flex: 1, background: a.bg, borderRadius: 9, padding: "7px 4px", textAlign: "center" }}>
              <span style={{ fontSize: 10, fontWeight: 600, color: a.c, fontFamily: "Space Grotesk,sans-serif" }}>{a.l}</span>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}

function PhoneDemo() {
  const [screen, setScreen] = useState(0);
  const [dir, setDir] = useState<"in" | "out">("in");

  useEffect(() => {
    const t = setInterval(() => {
      setDir("out");
      setTimeout(() => {
        setScreen(s => (s + 1) % PHONE_SCREENS.length);
        setDir("in");
      }, 380);
    }, 3200);
    return () => clearInterval(t);
  }, []);

  const screens = [<ScreenHome />, <ScreenSearch />, <ScreenFare />, <ScreenDriver />, <ScreenTrack />];
  const labels = ["Open App", "Set Destination", "Confirm Fare", "Driver Found", "Live Tracking"];

  return (
    <div style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: 18 }}>
      <div style={{ position: "relative", width: 248, height: 508, animation: "jago-float 4s ease-in-out infinite" }}>
        <div style={{ position: "absolute", inset: -24, borderRadius: 64, background: "radial-gradient(ellipse, rgba(30,109,229,0.3) 0%, transparent 70%)", filter: "blur(24px)" }} />
        <div style={{ position: "absolute", inset: 0, borderRadius: 44, background: "linear-gradient(175deg,#1a1a2e 0%,#0d0d1a 100%)", boxShadow: "0 48px 96px rgba(0,0,0,0.7), inset 0 0 0 1px rgba(255,255,255,0.07), 0 0 0 2.5px #23233a", overflow: "hidden" }}>
          <div style={{ position: "absolute", left: -3, top: 100, width: 3, height: 26, background: "#23233a", borderRadius: "2px 0 0 2px" }} />
          <div style={{ position: "absolute", left: -3, top: 138, width: 3, height: 26, background: "#23233a", borderRadius: "2px 0 0 2px" }} />
          <div style={{ position: "absolute", right: -3, top: 118, width: 3, height: 36, background: "#23233a", borderRadius: "0 2px 2px 0" }} />
          <div style={{ position: "absolute", inset: "7px", borderRadius: 38, overflow: "hidden", background: "#fff" }}>
            <div style={{ height: 26, background: "linear-gradient(90deg,#1E6DE5,#2563eb)", display: "flex", alignItems: "center", justifyContent: "space-between", padding: "0 13px", flexShrink: 0 }}>
              <span style={{ fontSize: 9, fontWeight: 700, color: "#fff", fontFamily: "Space Grotesk,sans-serif" }}>9:41</span>
              <div style={{ width: 56, height: 10, borderRadius: 7, background: "#0d0d1a" }} />
              <span style={{ fontSize: 9, color: "rgba(255,255,255,0.85)", letterSpacing: -0.5 }}>●●● 🔋</span>
            </div>
            <div style={{ position: "relative", width: "100%", height: "calc(100% - 26px)", overflow: "hidden" }}>
              <div key={screen} style={{ width: "100%", height: "100%", animation: `${dir === "in" ? "jago-screen-in" : "jago-screen-out"} 0.38s ease forwards` }}>
                {screens[screen]}
              </div>
            </div>
          </div>
        </div>
      </div>
      <div style={{ display: "flex", gap: 7, alignItems: "center" }}>
        {PHONE_SCREENS.map((_, i) => (
          <button key={i} onClick={() => { setDir("out"); setTimeout(() => { setScreen(i); setDir("in"); }, 350); }}
            style={{ width: i === screen ? 22 : 7, height: 7, borderRadius: 4, background: i === screen ? "#1E6DE5" : "rgba(30,109,229,0.22)", border: "none", cursor: "pointer", transition: "all 0.3s", padding: 0 }} />
        ))}
      </div>
      <p style={{ fontSize: 11, fontWeight: 600, color: "#1E6DE5", fontFamily: "Space Grotesk,sans-serif", margin: 0, opacity: 0.75 }}>{labels[screen]}</p>
    </div>
  );
}

/* ───────────────────── Vehicle SVGs ───────────────────── */
function BikeSvg({ c = "#fff", s = 28 }: { c?: string; s?: number }) {
  return <svg width={s} height={s * 0.6} viewBox="0 0 40 24" fill="none"><circle cx="8" cy="18" r="5" stroke={c} strokeWidth="2" /><circle cx="32" cy="18" r="5" stroke={c} strokeWidth="2" /><path d="M8 18L16 8L26 8L32 18" stroke={c} strokeWidth="2" fill="none" /><path d="M20 8L22 4L28 4" stroke={c} strokeWidth="1.5" /></svg>;
}
function CarSvg({ c = "#fff", s = 36 }: { c?: string; s?: number }) {
  return <svg width={s} height={s * 0.55} viewBox="0 0 48 26" fill="none"><rect x="4" y="12" width="40" height="10" rx="3" stroke={c} strokeWidth="1.5" /><path d="M10 12L14 4L34 4L38 12" stroke={c} strokeWidth="1.5" fill="none" /><circle cx="12" cy="22" r="4" stroke={c} strokeWidth="2" /><circle cx="36" cy="22" r="4" stroke={c} strokeWidth="2" /></svg>;
}
function AutoSvg({ c = "#fff", s = 32 }: { c?: string; s?: number }) {
  return <svg width={s} height={s * 0.65} viewBox="0 0 40 26" fill="none"><circle cx="10" cy="20" r="5" stroke={c} strokeWidth="2" /><circle cx="30" cy="20" r="5" stroke={c} strokeWidth="2" /><path d="M10 20L10 10L20 6L32 10L32 20" stroke={c} strokeWidth="1.5" fill="none" /><path d="M10 10L20 10" stroke={c} strokeWidth="1.2" /></svg>;
}

/* ───────────────── Animated Road Strip ───────────────── */
function AnimatedRoad() {
  const vehicles = [
    { type: "car", lane: 25, delay: 0, dur: 6.5, color: "#60a5fa" },
    { type: "bike", lane: 40, delay: 1.4, dur: 4.2, color: "#a78bfa" },
    { type: "auto", lane: 55, delay: 0.7, dur: 5.2, color: "#34d399" },
    { type: "car",  lane: 70, delay: 2.1, dur: 7.2, color: "#f472b6" },
    { type: "bike", lane: 25, delay: 3.1, dur: 4.0, color: "#fbbf24" },
    { type: "auto", lane: 40, delay: 4.2, dur: 5.8, color: "#fb7185" },
    { type: "car",  lane: 55, delay: 0.9, dur: 8.0, color: "#38bdf8" },
    { type: "bike", lane: 70, delay: 1.8, dur: 3.4, color: "#c4b5fd" },
  ];
  return (
    <div style={{ width: "100%", height: 96, background: "#111827", overflow: "hidden", position: "relative" }}>
      {[22, 37, 52, 67, 82].map(y => <div key={y} style={{ position: "absolute", left: 0, right: 0, top: `${y}%`, height: 1, background: "rgba(255,255,255,0.05)" }} />)}
      {[35, 58].map(y => <div key={y} style={{ position: "absolute", left: 0, right: 0, top: `${y}%`, height: 2, backgroundImage: "repeating-linear-gradient(90deg,rgba(255,255,255,0.2) 0,rgba(255,255,255,0.2) 28px,transparent 28px,transparent 56px)", animation: "jago-lane-dash 1.2s linear infinite" }} />)}
      {vehicles.map((v, i) => (
        <div key={i} style={{ position: "absolute", top: `${v.lane}%`, transform: "translateY(-50%)", animation: `jago-drive ${v.dur}s ${v.delay}s linear infinite` }}>
          {v.type === "bike" && <BikeSvg c={v.color} />}
          {v.type === "car" && <CarSvg c={v.color} />}
          {v.type === "auto" && <AutoSvg c={v.color} />}
        </div>
      ))}
    </div>
  );
}

/* ─────────────── Scrolling Services Marquee ─────────────── */
const MARQUEE_ITEMS = [
  "🛵 Bike Taxi", "🛺 Auto Ride", "🚗 Cab Ride", "📦 Parcel Delivery",
  "🚛 Goods Transport", "🌆 Intercity Travel", "🤝 Car Sharing", "👮 Safety Verified",
  "💸 Fair Pricing", "⚡ 60-Second Match", "📍 Live Tracking", "🏆 Top Rated Pilots",
];

function Marquee() {
  const items = [...MARQUEE_ITEMS, ...MARQUEE_ITEMS];
  return (
    <div style={{ overflow: "hidden", background: "#0f172a", borderTop: "1px solid #1e293b", borderBottom: "1px solid #1e293b", padding: "14px 0" }}>
      <div style={{ display: "flex", gap: 40, animation: "jago-marquee 28s linear infinite", width: "max-content", alignItems: "center" }}>
        {items.map((item, i) => (
          <div key={i} style={{ display: "flex", alignItems: "center", gap: 8, whiteSpace: "nowrap" }}>
            <div style={{ width: 5, height: 5, borderRadius: "50%", background: "#1E6DE5", flexShrink: 0 }} />
            <span style={{ fontSize: 13, fontWeight: 600, color: "#94a3b8", fontFamily: "Space Grotesk,sans-serif", letterSpacing: 0.3 }}>{item}</span>
          </div>
        ))}
      </div>
    </div>
  );
}

/* ─────────────── Smart SVG Icon Components ─────────────── */
const SvcBike = () => <svg width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round"><circle cx="6" cy="16" r="3.5"/><circle cx="18" cy="16" r="3.5"/><path d="M9 16l2-6h5l2 4.5"/><path d="M6 16l3.5-8.5"/><path d="M14 10l1.5 4.5"/><path d="M11 10h4"/></svg>;
const SvcAuto = () => <svg width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round"><circle cx="7" cy="18" r="3"/><circle cx="17" cy="18" r="3"/><path d="M10 18h4"/><path d="M7 15V9l3.5-3H18l2 4v5H10"/></svg>;
const SvcCar = () => <svg width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round"><path d="M5 17H3a1 1 0 01-1-1v-3l3-5h13l3 5v3a1 1 0 01-1 1h-2"/><circle cx="7.5" cy="17.5" r="2.5"/><circle cx="16.5" cy="17.5" r="2.5"/></svg>;
const SvcCity = () => <svg width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round"><path d="M3 21h18"/><rect x="3" y="8" width="7" height="13" rx="1"/><rect x="13" y="3" width="8" height="18" rx="1"/><path d="M16 7h2m-2 4h2m-2 4h2"/><path d="M5 12h2m-2 4h2"/></svg>;
const SvcParcel = () => <svg width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round"><path d="M21 16V8a2 2 0 00-1-1.73l-7-4a2 2 0 00-2 0l-7 4A2 2 0 003 8v8a2 2 0 001 1.73l7 4a2 2 0 002 0l7-4A2 2 0 0021 16z"/><polyline points="3.27 6.96 12 12.01 20.73 6.96"/><line x1="12" y1="22.08" x2="12" y2="12"/></svg>;
const SvcTruck = () => <svg width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round"><rect x="1" y="4" width="14" height="12" rx="1"/><path d="M15 8h4l3 4v4h-7V8z"/><circle cx="5.5" cy="18.5" r="2.5"/><circle cx="18.5" cy="18.5" r="2.5"/></svg>;
const SvcPhone = () => <svg width="38" height="38" viewBox="0 0 24 24" fill="none" stroke="rgba(255,255,255,0.92)" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"><rect x="5" y="2" width="14" height="20" rx="2"/><line x1="12" y1="18" x2="12" y2="18" strokeWidth="3"/></svg>;
const SvcMoto = () => <svg width="38" height="38" viewBox="0 0 24 24" fill="none" stroke="rgba(255,255,255,0.92)" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"><circle cx="6" cy="16" r="3.5"/><circle cx="18" cy="16" r="3.5"/><path d="M9 16l2-6h5l2 4.5"/><path d="M6 16l3.5-8.5"/><path d="M14 10l1.5 4.5"/><path d="M11 10h4"/></svg>;
const FeatLightning = () => <svg width="20" height="20" viewBox="0 0 24 24"><polygon points="13 2 3 14 12 14 11 22 21 10 12 10 13 2" fill="#f59e0b"/></svg>;
const FeatShield = () => <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="#1E6DE5" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/><polyline points="9 12 11 14 15 10"/></svg>;
const FeatMoney = () => <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="#10b981" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round"><line x1="12" y1="1" x2="12" y2="23"/><path d="M17 5H9.5a3.5 3.5 0 000 7h5a3.5 3.5 0 010 7H6"/></svg>;
const FeatPin = () => <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="#818cf8" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round"><path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0118 0z"/><circle cx="12" cy="10" r="3"/></svg>;
const FeatChat = () => <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="#f472b6" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round"><path d="M21 15a2 2 0 01-2 2H7l-4 4V5a2 2 0 012-2h14a2 2 0 012 2z"/></svg>;
const FeatStar = () => <svg width="20" height="20" viewBox="0 0 24 24"><polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2" fill="#f59e0b"/></svg>;

/* ═══════════════════════════ MAIN PAGE ═══════════════════════════ */
export default function LandingPage() {
  const { theme } = useTheme();
  const isDark = theme === "dark";

  const [menuOpen, setMenuOpen] = useState(false);
  const [scrolled, setScrolled] = useState(false);

  // Stats
  const sRides = useCountUp(500000, 2200);
  const sCities = useCountUp(50, 1500);
  const sPilots = useCountUp(20000, 1900);
  const sRating = useCountUp(48, 1400); // 4.8 → shown as 4.8

  // Section reveals
  const secServices = useReveal();
  const secWhy = useReveal();
  const secApps = useReveal();
  const secStats = useReveal();
  const secCities = useReveal();
  const secDl = useReveal();

  useEffect(() => {
    const fn = () => setScrolled(window.scrollY > 18);
    window.addEventListener("scroll", fn, { passive: true });
    return () => window.removeEventListener("scroll", fn);
  }, []);

  /* Colour tokens — deep navy brand palette */
  const bg = "#06091c";
  const surface = "#090d22";
  const card = "#0e1330";
  const border = "rgba(255,255,255,0.09)";
  const text = "#eef2ff";
  const muted = "#64748b";
  const blue = "#1E6DE5";
  const blueBright = "#3b82f6";
  const green = "#10b981";
  const violet = "#818cf8";
  const amber = "#f59e0b";

  return (
    <>
      <style>{`
        @import url('https://fonts.googleapis.com/css2?family=Space+Grotesk:wght@400;500;600;700;800&family=Inter:wght@400;500;600;700&display=swap');
        *,*::before,*::after{box-sizing:border-box;margin:0;padding:0;}
        html{scroll-behavior:smooth;}
        body{font-family:'Inter',sans-serif;}

        @keyframes jago-drive {
          from { left: -90px; }
          to   { left: 110%; }
        }
        @keyframes jago-lane-dash {
          from { background-position: 0 0; }
          to   { background-position: 56px 0; }
        }
        @keyframes jago-float {
          0%,100% { transform: translateY(0); }
          50%     { transform: translateY(-14px); }
        }
        @keyframes jago-pulse {
          0%,100% { box-shadow: 0 0 0 0 rgba(30,109,229,0.5); }
          50%     { box-shadow: 0 0 0 16px rgba(30,109,229,0); }
        }
        @keyframes jago-badge {
          0%,100% { opacity:1; transform:scale(1); }
          50%     { opacity:0.45; transform:scale(0.8); }
        }
        @keyframes jago-glow {
          0%,100% { transform:scale(1) translate(0,0); opacity:0.5; }
          33%     { transform:scale(1.18) translate(22px,-18px); opacity:0.3; }
          66%     { transform:scale(0.88) translate(-16px,12px); opacity:0.6; }
        }
        @keyframes jago-screen-in {
          from { opacity:0; transform:translateX(28px) scale(0.97); }
          to   { opacity:1; transform:translateX(0) scale(1); }
        }
        @keyframes jago-screen-out {
          from { opacity:1; transform:translateX(0) scale(1); }
          to   { opacity:0; transform:translateX(-28px) scale(0.97); }
        }
        @keyframes jago-fade-up {
          from { opacity:0; transform:translateY(32px); }
          to   { opacity:1; transform:translateY(0); }
        }
        @keyframes jago-marquee {
          from { transform:translateX(0); }
          to   { transform:translateX(-50%); }
        }
        @keyframes jago-spin-slow {
          from { transform:rotate(0deg); }
          to   { transform:rotate(360deg); }
        }

        .jago-reveal { opacity:0; transform:translateY(36px); transition:opacity 0.75s ease,transform 0.75s ease; }
        .jago-reveal.vis { opacity:1; transform:translateY(0); }

        .jago-svc-card { transition:transform 0.25s,box-shadow 0.25s; cursor:pointer; }
        .jago-svc-card:hover { transform:translateY(-5px); box-shadow:0 20px 48px rgba(30,109,229,0.15)!important; }

        .jago-city-card:hover { transform:scale(1.04); }
        .jago-city-card { transition:transform 0.2s; cursor:default; }

        .jago-nav-link { color:#94a3b8; text-decoration:none; font-size:14px; font-weight:500; font-family:'Space Grotesk',sans-serif; transition:color 0.2s; }
        .jago-nav-link:hover { color:#f1f5f9; }

        .jago-dl-btn { transition:transform 0.2s,box-shadow 0.2s; }
        .jago-dl-btn:hover { transform:translateY(-3px); }

        .container { max-width:1180px; margin:0 auto; padding:0 24px; }
        .sec { padding:96px 0; }
      `}</style>

      <div style={{ background: `radial-gradient(ellipse at 25% 15%, #0d1a48 0%, #06091c 45%, #080b28 100%)`, color: text, minHeight: "100vh" }}>

        {/* ======= NAV ======= */}
        <nav style={{
          position: "fixed", top: 0, left: 0, right: 0, zIndex: 200,
          backdropFilter: "blur(16px)",
          background: scrolled ? "rgba(6,9,28,0.96)" : "rgba(6,9,28,0.72)",
          borderBottom: scrolled ? `1px solid ${border}` : "1px solid transparent",
          transition: "all 0.3s",
        }}>
          <div className="container" style={{ height: 66, display: "flex", alignItems: "center", justifyContent: "space-between" }}>
            {/* Logo */}
            <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
              <img src="/jago-logo.png" alt="JAGO" style={{ height: 38, width: "auto", objectFit: "contain" }} />
            </div>
            {/* Desktop links */}
            <div style={{ display: "flex", gap: 28, alignItems: "center" }}>
              {["#services", "#why", "#cities", "#download"].map((href, i) => (
                <a key={href} href={href} className="jago-nav-link">{["Services", "Why Jago", "Cities", "Download"][i]}</a>
              ))}
            </div>
            {/* CTA */}
            <div style={{ display: "flex", gap: 10 }}>
              <a href="#download" style={{ padding: "8px 18px", borderRadius: 10, background: `linear-gradient(135deg,${blue},${blueBright})`, color: "#fff", fontSize: 13, fontWeight: 600, textDecoration: "none", fontFamily: "Space Grotesk,sans-serif", boxShadow: `0 4px 16px rgba(30,109,229,0.4)`, animation: "jago-pulse 2.5s infinite" }}>Get App</a>
            </div>
          </div>
        </nav>

        {/* ======= HERO ======= */}
        <section style={{ minHeight: "100vh", display: "flex", alignItems: "center", position: "relative", overflow: "hidden", paddingTop: 66 }}>
          {/* Background glows */}
          <div style={{ position: "absolute", top: "8%", right: "2%", width: 600, height: 600, borderRadius: "50%", background: `radial-gradient(circle,rgba(30,109,229,0.12) 0%,transparent 70%)`, animation: "jago-glow 14s ease-in-out infinite", pointerEvents: "none" }} />
          <div style={{ position: "absolute", bottom: "5%", left: "-5%", width: 500, height: 500, borderRadius: "50%", background: `radial-gradient(circle,rgba(129,140,248,0.08) 0%,transparent 70%)`, animation: "jago-glow 18s ease-in-out infinite reverse", pointerEvents: "none" }} />
          {/* Grid overlay */}
          <div style={{ position: "absolute", inset: 0, backgroundImage: "linear-gradient(rgba(255,255,255,0.02) 1px,transparent 1px),linear-gradient(90deg,rgba(255,255,255,0.02) 1px,transparent 1px)", backgroundSize: "64px 64px", pointerEvents: "none" }} />

          <div className="container" style={{ width: "100%", display: "grid", gridTemplateColumns: "1.1fr 0.9fr", gap: 48, alignItems: "center", padding: "60px 24px 80px" }}>
            {/* LEFT */}
            <div style={{ animation: "jago-fade-up 0.9s ease forwards" }}>
              {/* JAGO Logo mark in hero */}
              <div style={{ display: "flex", alignItems: "center", gap: 12, marginBottom: 28 }}>
                <img src="/jago-logo.png" alt="JAGO" style={{ height: 52, width: "auto", objectFit: "contain" }} />
              </div>
              {/* Eyebrow badge */}
              <div style={{ display: "inline-flex", alignItems: "center", gap: 8, background: "rgba(30,109,229,0.12)", border: "1px solid rgba(30,109,229,0.3)", borderRadius: 30, padding: "6px 14px", marginBottom: 28 }}>
                <div style={{ width: 7, height: 7, borderRadius: "50%", background: green, animation: "jago-badge 1.6s infinite" }} />
                <span style={{ fontSize: 12, fontWeight: 600, color: blueBright, fontFamily: "Space Grotesk,sans-serif" }}>Live across 50+ cities in India</span>
              </div>

              <h1 style={{ fontSize: "clamp(38px,4.8vw,68px)", fontWeight: 800, lineHeight: 1.1, marginBottom: 22, fontFamily: "Space Grotesk,sans-serif", letterSpacing: -1.5 }}>
                India's Fastest<br />
                <span style={{ background: `linear-gradient(135deg,${blue},${violet})`, WebkitBackgroundClip: "text", WebkitTextFillColor: "transparent" }}>Ride Platform.</span>
              </h1>

              <p style={{ fontSize: 18, color: muted, lineHeight: 1.75, maxWidth: 480, marginBottom: 40, fontFamily: "'Inter',sans-serif" }}>
                Book a bike, auto, or cab in under 60 seconds. Connect with verified pilots for safe, affordable rides — door to door, city to city.
              </p>

              {/* App download CTAs */}
              <div style={{ display: "flex", gap: 14, flexWrap: "wrap", marginBottom: 52 }}>
                <a href="#download" className="jago-dl-btn" style={{ display: "flex", alignItems: "center", gap: 11, background: "#fff", color: "#0d0d1a", padding: "12px 22px", borderRadius: 14, textDecoration: "none", fontFamily: "Space Grotesk,sans-serif", fontWeight: 600, boxShadow: "0 4px 24px rgba(0,0,0,0.3)" }}>
                  <span style={{ fontSize: 22 }}>🍎</span>
                  <div><div style={{ fontSize: 9, opacity: 0.55, textTransform: "uppercase", letterSpacing: 1 }}>Download on</div><div style={{ fontSize: 14, lineHeight: 1.2 }}>App Store</div></div>
                </a>
                <a href="#download" className="jago-dl-btn" style={{ display: "flex", alignItems: "center", gap: 11, background: "#fff", color: "#0d0d1a", padding: "12px 22px", borderRadius: 14, textDecoration: "none", fontFamily: "Space Grotesk,sans-serif", fontWeight: 600, boxShadow: "0 4px 24px rgba(0,0,0,0.3)" }}>
                  <span style={{ fontSize: 22 }}>▶</span>
                  <div><div style={{ fontSize: 9, opacity: 0.55, textTransform: "uppercase", letterSpacing: 1 }}>Get it on</div><div style={{ fontSize: 14, lineHeight: 1.2 }}>Google Play</div></div>
                </a>
                <a href="/auth" className="jago-dl-btn" style={{ display: "flex", alignItems: "center", gap: 8, border: `1px solid ${border}`, color: text, padding: "12px 22px", borderRadius: 14, textDecoration: "none", fontFamily: "Space Grotesk,sans-serif", fontWeight: 600, background: "rgba(255,255,255,0.04)" }}>
                  <span style={{ fontSize: 16 }}>🚀</span> Become a Pilot
                </a>
              </div>

              {/* Live stats */}
              <div style={{ display: "flex", gap: 40, flexWrap: "wrap" }}>
                <div ref={sRides.ref}>
                  <p style={{ fontSize: 32, fontWeight: 800, color: text, margin: 0, fontFamily: "Space Grotesk,sans-serif", lineHeight: 1 }}>{(sRides.val / 1000).toFixed(0)}K+</p>
                  <p style={{ fontSize: 12, color: muted, margin: "4px 0 0" }}>Rides Completed</p>
                </div>
                <div ref={sCities.ref}>
                  <p style={{ fontSize: 32, fontWeight: 800, color: text, margin: 0, fontFamily: "Space Grotesk,sans-serif", lineHeight: 1 }}>{sCities.val}+</p>
                  <p style={{ fontSize: 12, color: muted, margin: "4px 0 0" }}>Cities</p>
                </div>
                <div ref={sPilots.ref}>
                  <p style={{ fontSize: 32, fontWeight: 800, color: text, margin: 0, fontFamily: "Space Grotesk,sans-serif", lineHeight: 1 }}>{(sPilots.val / 1000).toFixed(0)}K+</p>
                  <p style={{ fontSize: 12, color: muted, margin: "4px 0 0" }}>Active Pilots</p>
                </div>
              </div>
            </div>

            {/* RIGHT — PhoneDemo */}
            <div style={{ display: "flex", justifyContent: "center", alignItems: "center" }}>
              <PhoneDemo />
            </div>
          </div>
        </section>

        {/* ======= MARQUEE ======= */}
        <Marquee />

        {/* ======= SERVICES ======= */}
        <section id="services" className="sec" style={{ background: surface }}>
          <div className="container">
            <div ref={secServices.ref} className={`jago-reveal${secServices.vis ? " vis" : ""}`}>
              <div style={{ textAlign: "center", maxWidth: 560, margin: "0 auto 60px" }}>
                <div style={{ display: "inline-block", fontSize: 11, fontWeight: 700, color: blue, textTransform: "uppercase", letterSpacing: 2.5, fontFamily: "Space Grotesk,sans-serif", marginBottom: 12 }}>Our Services</div>
                <h2 style={{ fontSize: "clamp(28px,3.6vw,46px)", fontWeight: 800, fontFamily: "Space Grotesk,sans-serif", letterSpacing: -0.8, lineHeight: 1.15 }}>Every ride,<br />every need</h2>
                <p style={{ fontSize: 16, color: muted, marginTop: 14, lineHeight: 1.7 }}>From quick city hops to long-distance hauls — Jago gets you there.</p>
              </div>

              <div style={{ display: "grid", gridTemplateColumns: "repeat(3,1fr)", gap: 20 }}>
                {[
                  { icon: <SvcBike />, title: "Bike Taxi", desc: "Fastest way through city traffic. Affordable, quick 2-wheeler rides.", color: blue, g: `linear-gradient(135deg,${blue},${blueBright})` },
                  { icon: <SvcAuto />, title: "Auto Ride", desc: "Classic CNG auto rides. Comfortable and pocket-friendly.", color: violet, g: "linear-gradient(135deg,#818cf8,#a78bfa)" },
                  { icon: <SvcCar />, title: "Cab Ride", desc: "AC cab rides for family and business travel across the city.", color: green, g: "linear-gradient(135deg,#10b981,#34d399)" },
                  { icon: <SvcCity />, title: "Intercity", desc: "Outstation travel with transparent pricing and top pilots.", color: amber, g: "linear-gradient(135deg,#f59e0b,#fbbf24)" },
                  { icon: <SvcParcel />, title: "Parcel Delivery", desc: "Send packages door to door — same day, same city.", color: "#f472b6", g: "linear-gradient(135deg,#ec4899,#f472b6)" },
                  { icon: <SvcTruck />, title: "Goods Transport", desc: "Move furniture, appliances, and freight with dedicated trucks.", color: "#fb923c", g: "linear-gradient(135deg,#f97316,#fb923c)" },
                ].map(s => (
                  <div key={s.title} className="jago-svc-card" style={{ background: card, borderRadius: 20, padding: "26px 24px", border: `1px solid ${border}`, boxShadow: "0 4px 24px rgba(0,0,0,0.3)" }}>
                    <div style={{ width: 54, height: 54, borderRadius: 14, background: s.g, display: "flex", alignItems: "center", justifyContent: "center", marginBottom: 16, boxShadow: `0 8px 24px ${s.color}55` }}>{s.icon}</div>
                    <h3 style={{ fontSize: 17, fontWeight: 700, marginBottom: 8, fontFamily: "Space Grotesk,sans-serif", color: text }}>{s.title}</h3>
                    <p style={{ fontSize: 14, color: muted, lineHeight: 1.65 }}>{s.desc}</p>
                    <div style={{ marginTop: 16, fontSize: 13, fontWeight: 600, color: s.color, fontFamily: "Space Grotesk,sans-serif" }}>Book now →</div>
                  </div>
                ))}
              </div>
            </div>
          </div>
        </section>

        {/* ======= WHY JAGO ======= */}
        <section id="why" className="sec" style={{ background: bg }}>
          <div className="container">
            <div ref={secWhy.ref} className={`jago-reveal${secWhy.vis ? " vis" : ""}`}>
              <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 64, alignItems: "center" }}>
                {/* Left text */}
                <div>
                  <div style={{ fontSize: 11, fontWeight: 700, color: blue, textTransform: "uppercase", letterSpacing: 2.5, fontFamily: "Space Grotesk,sans-serif", marginBottom: 14 }}>Why Jago</div>
                  <h2 style={{ fontSize: "clamp(28px,3.6vw,46px)", fontWeight: 800, fontFamily: "Space Grotesk,sans-serif", letterSpacing: -0.8, lineHeight: 1.15, marginBottom: 20 }}>Built different,<br />built better.</h2>
                  <p style={{ fontSize: 16, color: muted, lineHeight: 1.75, marginBottom: 32 }}>We don't just move people. We built an obsession-grade experience that puts safety, affordability, and speed first — for both riders and pilots.</p>
                  <div style={{ display: "flex", gap: 14 }}>
                    <a href="#download" style={{ padding: "11px 22px", borderRadius: 12, background: `linear-gradient(135deg,${blue},${blueBright})`, color: "#fff", fontSize: 14, fontWeight: 600, textDecoration: "none", fontFamily: "Space Grotesk,sans-serif" }}>Get the App</a>
                    <a href="/auth" style={{ padding: "11px 22px", borderRadius: 12, border: `1px solid ${border}`, color: text, fontSize: 14, fontWeight: 500, textDecoration: "none", fontFamily: "Space Grotesk,sans-serif" }}>Become a Pilot</a>
                  </div>
                </div>
                {/* Right cards */}
                <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 14 }}>
                  {[
                    { icon: <FeatLightning />, title: "60-Second Match", desc: "Get a verified pilot matched in under a minute.", color: amber },
                    { icon: <FeatShield />, title: "Verified Pilots", desc: "Every pilot is background-checked and KYC verified.", color: blue },
                    { icon: <FeatMoney />, title: "No Surge", desc: "Fixed fares, no hidden charges, ever.", color: green },
                    { icon: <FeatPin />, title: "Live Tracking", desc: "Real-time GPS tracking with family share.", color: violet },
                    { icon: <FeatChat />, title: "In-app Chat", desc: "Talk to your pilot without sharing number.", color: "#f472b6" },
                    { icon: <FeatStar />, title: "Rated 4.9★", desc: "Highest rated ride app in South India.", color: amber },
                  ].map(w => (
                    <div key={w.title} style={{ background: card, border: `1px solid ${border}`, borderRadius: 16, padding: "18px" }}>
                      <div style={{ width: 44, height: 44, borderRadius: 12, background: `${w.color}22`, border: `1px solid ${w.color}44`, display: "flex", alignItems: "center", justifyContent: "center", marginBottom: 12 }}>{w.icon}</div>
                      <h4 style={{ fontSize: 14, fontWeight: 700, color: text, fontFamily: "Space Grotesk,sans-serif", marginBottom: 5 }}>{w.title}</h4>
                      <p style={{ fontSize: 12, color: muted, lineHeight: 1.5 }}>{w.desc}</p>
                    </div>
                  ))}
                </div>
              </div>
            </div>
          </div>
        </section>

        {/* ======= STATS ======= */}
        <section className="sec" style={{ background: `linear-gradient(135deg,${blue} 0%,${blueBright} 50%,${violet} 100%)`, position: "relative", overflow: "hidden" }}>
          <div style={{ position: "absolute", inset: 0, backgroundImage: "linear-gradient(rgba(255,255,255,0.04) 1px,transparent 1px),linear-gradient(90deg,rgba(255,255,255,0.04) 1px,transparent 1px)", backgroundSize: "48px 48px" }} />
          <div className="container" style={{ position: "relative" }}>
            <div ref={secStats.ref} className={`jago-reveal${secStats.vis ? " vis" : ""}`}>
              <div style={{ textAlign: "center", marginBottom: 56 }}>
                <h2 style={{ fontSize: "clamp(28px,3.6vw,46px)", fontWeight: 800, fontFamily: "Space Grotesk,sans-serif", color: "#fff", letterSpacing: -0.8 }}>Numbers that prove it</h2>
                <p style={{ color: "rgba(255,255,255,0.72)", fontSize: 16, marginTop: 12 }}>Real performance, real trust. No fluff.</p>
              </div>
              <div style={{ display: "grid", gridTemplateColumns: "repeat(4,1fr)", gap: 24 }}>
                {[
                  { ref: sRides.ref, val: `${(sRides.val / 1000).toFixed(0)}K+`, label: "Rides Completed" },
                  { ref: sCities.ref, val: `${sCities.val}+`, label: "Cities Active" },
                  { ref: sPilots.ref, val: `${(sPilots.val / 1000).toFixed(0)}K+`, label: "Verified Pilots" },
                  { ref: sRating.ref, val: `${(sRating.val / 10).toFixed(1)}★`, label: "Avg Rider Rating" },
                ].map((s, i) => (
                  <div key={i} ref={s.ref} style={{ textAlign: "center", background: "rgba(255,255,255,0.12)", backdropFilter: "blur(12px)", borderRadius: 20, padding: "32px 16px", border: "1px solid rgba(255,255,255,0.18)" }}>
                    <p style={{ fontSize: 42, fontWeight: 800, color: "#fff", margin: "0 0 8px", fontFamily: "Space Grotesk,sans-serif", lineHeight: 1 }}>{s.val}</p>
                    <p style={{ fontSize: 13, color: "rgba(255,255,255,0.75)", fontFamily: "Space Grotesk,sans-serif" }}>{s.label}</p>
                  </div>
                ))}
              </div>
            </div>
          </div>
        </section>

        {/* ======= DUO APPS ======= */}
        <section id="apps" className="sec" style={{ background: surface }}>
          <div className="container">
            <div ref={secApps.ref} className={`jago-reveal${secApps.vis ? " vis" : ""}`}>
              <div style={{ textAlign: "center", marginBottom: 52 }}>
                <div style={{ fontSize: 11, fontWeight: 700, color: blue, textTransform: "uppercase", letterSpacing: 2.5, fontFamily: "Space Grotesk,sans-serif", marginBottom: 12 }}>Two Apps, One Platform</div>
                <h2 style={{ fontSize: "clamp(28px,3.6vw,46px)", fontWeight: 800, fontFamily: "Space Grotesk,sans-serif", letterSpacing: -0.8 }}>For every journey</h2>
              </div>
              <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 24 }}>
                {[
                  { title: "Jago Customer App", sub: "For Riders", icon: <SvcPhone />, desc: "Book rides instantly, track in real-time, earn Jago coins on every trip, pay seamlessly — all in one app.", cta: "Get Customer App", bg: `linear-gradient(135deg,${blue} 0%,${violet} 100%)` },
                  { title: "Jago Pilot App", sub: "For Drivers", icon: <SvcMoto />, desc: "Accept trips, manage earnings, grow with Jago's daily pay + rewards model. Your wheels, your income.", cta: "Join as Pilot", bg: "linear-gradient(135deg,#10b981 0%,#059669 100%)" },
                ].map(d => (
                  <div key={d.title} style={{ borderRadius: 24, padding: "40px 36px", background: d.bg, position: "relative", overflow: "hidden" }}>
                    <div style={{ position: "absolute", top: -40, right: -40, width: 160, height: 160, borderRadius: "50%", background: "rgba(255,255,255,0.06)" }} />
                    <div style={{ position: "absolute", bottom: -50, left: -24, width: 180, height: 180, borderRadius: "50%", background: "rgba(255,255,255,0.04)" }} />
                    <div style={{ position: "relative", zIndex: 1 }}>
                      <div style={{ display: "inline-flex", alignItems: "center", justifyContent: "center", background: "rgba(255,255,255,0.12)", borderRadius: 16, padding: 10, marginBottom: 10 }}>{d.icon}</div>
                      <div style={{ fontSize: 10, fontWeight: 700, color: "rgba(255,255,255,0.65)", textTransform: "uppercase", letterSpacing: 2, marginBottom: 6, fontFamily: "Space Grotesk,sans-serif" }}>{d.sub}</div>
                      <h3 style={{ fontSize: 24, fontWeight: 800, color: "#fff", marginBottom: 12, fontFamily: "Space Grotesk,sans-serif" }}>{d.title}</h3>
                      <p style={{ fontSize: 15, color: "rgba(255,255,255,0.8)", lineHeight: 1.7, marginBottom: 26 }}>{d.desc}</p>
                      <a href="#download" className="jago-dl-btn" style={{ display: "inline-block", background: "rgba(255,255,255,0.18)", backdropFilter: "blur(8px)", border: "1px solid rgba(255,255,255,0.28)", color: "#fff", padding: "11px 22px", borderRadius: 12, textDecoration: "none", fontSize: 13, fontWeight: 600, fontFamily: "Space Grotesk,sans-serif" }}>{d.cta} ↓</a>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          </div>
        </section>

        {/* ======= CITIES ======= */}
        <section id="cities" className="sec" style={{ background: bg }}>
          <div className="container">
            <div ref={secCities.ref} className={`jago-reveal${secCities.vis ? " vis" : ""}`} style={{ textAlign: "center" }}>
              <div style={{ fontSize: 11, fontWeight: 700, color: blue, textTransform: "uppercase", letterSpacing: 2.5, fontFamily: "Space Grotesk,sans-serif", marginBottom: 12 }}>Service Areas</div>
              <h2 style={{ fontSize: "clamp(28px,3.6vw,46px)", fontWeight: 800, fontFamily: "Space Grotesk,sans-serif", letterSpacing: -0.8, marginBottom: 14 }}>Growing fast</h2>
              <p style={{ fontSize: 15, color: muted, marginBottom: 52, maxWidth: 420, margin: "0 auto 52px" }}>Already serving millions in these cities, expanding each month.</p>
              <div style={{ display: "grid", gridTemplateColumns: "repeat(5,1fr)", gap: 14 }}>
                {[
                  { city: "Hyderabad", f: "🏙️" }, { city: "Bangalore", f: "🌸" }, { city: "Chennai", f: "🌊" },
                  { city: "Pune", f: "💎" }, { city: "Mumbai", f: "🌃" }, { city: "Delhi", f: "🏛️" },
                  { city: "Kolkata", f: "🎨" }, { city: "Jaipur", f: "🏰" }, { city: "Ahmedabad", f: "🌺" },
                  { city: "Visakhapatnam", f: "🏖️" },
                ].map(c => (
                  <div key={c.city} className="jago-city-card" style={{ background: card, borderRadius: 14, padding: "16px 10px", border: `1px solid ${border}` }}>
                    <div style={{ fontSize: 26, marginBottom: 7 }}>{c.f}</div>
                    <p style={{ fontSize: 11, fontWeight: 600, color: text, margin: 0, fontFamily: "Space Grotesk,sans-serif" }}>{c.city}</p>
                  </div>
                ))}
              </div>
            </div>
          </div>
        </section>

        {/* ======= DOWNLOAD CTA ======= */}
        <section id="download" className="sec" style={{ background: surface }}>
          <div className="container">
            <div ref={secDl.ref} className={`jago-reveal${secDl.vis ? " vis" : ""}`}>
              <div style={{ borderRadius: 28, background: `linear-gradient(135deg,${blue} 0%,${violet} 100%)`, padding: "64px 48px", textAlign: "center", position: "relative", overflow: "hidden" }}>
                <div style={{ position: "absolute", top: -60, right: -60, width: 240, height: 240, borderRadius: "50%", background: "rgba(255,255,255,0.06)" }} />
                <div style={{ position: "absolute", bottom: -50, left: -50, width: 200, height: 200, borderRadius: "50%", background: "rgba(255,255,255,0.04)" }} />
                <div style={{ position: "relative", zIndex: 1 }}>
                  <div style={{ fontSize: 48, marginBottom: 16 }}>🚀</div>
                  <h2 style={{ fontSize: "clamp(28px,3.6vw,46px)", fontWeight: 800, color: "#fff", fontFamily: "Space Grotesk,sans-serif", marginBottom: 14, letterSpacing: -0.8 }}>Ready to ride with Jago?</h2>
                  <p style={{ fontSize: 16, color: "rgba(255,255,255,0.78)", marginBottom: 40, maxWidth: 440, marginLeft: "auto", marginRight: "auto" }}>
                    Download now and get your first ride up to <strong style={{ color: "#fff" }}>₹50 OFF</strong> with code <strong style={{ color: "#fbbf24" }}>JAGO50</strong>
                  </p>
                  <div style={{ display: "flex", gap: 14, justifyContent: "center", flexWrap: "wrap" }}>
                    {[{ label: "App Store", icon: "🍎", sub: "Download on" }, { label: "Google Play", icon: "▶", sub: "Get it on" }].map(d => (
                      <a key={d.label} href="#" className="jago-dl-btn" style={{ display: "flex", alignItems: "center", gap: 12, background: "rgba(255,255,255,0.14)", backdropFilter: "blur(8px)", border: "1px solid rgba(255,255,255,0.25)", borderRadius: 14, padding: "14px 24px", textDecoration: "none", color: "#fff", fontFamily: "Space Grotesk,sans-serif" }}>
                        <span style={{ fontSize: 28 }}>{d.icon}</span>
                        <div style={{ textAlign: "left" }}>
                          <div style={{ fontSize: 10, opacity: 0.7, textTransform: "uppercase", letterSpacing: 1 }}>{d.sub}</div>
                          <div style={{ fontSize: 16, fontWeight: 700 }}>{d.label}</div>
                        </div>
                      </a>
                    ))}
                  </div>
                </div>
              </div>
            </div>
          </div>
        </section>

        {/* ======= FOOTER ======= */}
        <footer style={{ background: "#020409", padding: "64px 24px 28px", borderTop: "1px solid rgba(255,255,255,0.05)" }}>
          <div className="container">
            <div style={{ display: "grid", gridTemplateColumns: "2fr 1fr 1fr 1fr", gap: 40, marginBottom: 56 }}>
              {/* Brand col */}
              <div>
                <div style={{ display: "flex", alignItems: "center", gap: 10, marginBottom: 18 }}>
                  <img src="/jago-logo.png" alt="JAGO" style={{ height: 36, width: "auto", objectFit: "contain" }} />
                </div>
                <p style={{ fontSize: 13, color: "#475569", lineHeight: 1.75, maxWidth: 240 }}>India's fastest-growing ride-hailing platform. Safe, fast, affordable — everywhere.</p>
                <div style={{ display: "flex", gap: 10, marginTop: 18 }}>
                  {["𝕏", "📘", "📸", "💼"].map((ic, i) => (
                    <div key={i} style={{ width: 34, height: 34, borderRadius: 8, background: "rgba(255,255,255,0.05)", border: `1px solid ${border}`, display: "flex", alignItems: "center", justifyContent: "center", fontSize: 14, cursor: "pointer" }}>{ic}</div>
                  ))}
                </div>
              </div>
              {/* Link cols */}
              {[
                { t: "Company", l: ["About Us", "Careers", "Blog", "Press"] },
                { t: "Services", l: ["Bike Taxi", "Auto Ride", "Cab Ride", "Intercity"] },
                { t: "Support", l: ["Help Center", "Safety", "Privacy Policy", "Terms"] },
              ].map(col => (
                <div key={col.t}>
                  <h4 style={{ fontSize: 12, fontWeight: 700, color: "#94a3b8", marginBottom: 16, fontFamily: "Space Grotesk,sans-serif", textTransform: "uppercase", letterSpacing: 1.5 }}>{col.t}</h4>
                  {col.l.map(link => (
                    <a key={link} href="#" style={{ display: "block", fontSize: 13, color: "#475569", textDecoration: "none", marginBottom: 11, transition: "color 0.2s" }}>{link}</a>
                  ))}
                </div>
              ))}
            </div>
            <div style={{ borderTop: `1px solid ${border}`, paddingTop: 24, display: "flex", justifyContent: "space-between", alignItems: "center", flexWrap: "wrap", gap: 10 }}>
              <p style={{ fontSize: 12, color: "#334155", fontFamily: "Space Grotesk,sans-serif" }}>© 2026 Jago Technologies Pvt. Ltd. · MindWhile IT Solutions Product · All rights reserved.</p>
              <p style={{ fontSize: 12, color: "#334155", fontFamily: "Space Grotesk,sans-serif" }}>Made with ❤️ in India</p>
            </div>
          </div>
        </footer>

      </div>
    </>
  );
}
