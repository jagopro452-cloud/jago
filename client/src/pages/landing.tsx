import { useState, useEffect, useRef } from "react";

/* --- Hooks --- */
function useReveal() {
  const ref = useRef<HTMLDivElement>(null);
  const [vis, setVis] = useState(false);
  useEffect(() => {
    const el = ref.current; if (!el) return;
    const io = new IntersectionObserver(([e]) => { if (e.isIntersecting) { setVis(true); io.disconnect(); } }, { threshold: 0.1 });
    io.observe(el); return () => io.disconnect();
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
        setVal(Math.round((1 - Math.pow(1 - p, 3)) * target));
        if (p < 1) requestAnimationFrame(tick);
      };
      requestAnimationFrame(tick);
    }, { threshold: 0.5 });
    io.observe(el); return () => io.disconnect();
  }, [target, duration]);
  return { ref, val };
}

/* --- Phone Demo Screens --- */
const SCREENS = ["home", "route", "fare", "pilot", "track"] as const;
type ScreenType = typeof SCREENS[number];

function PhoneScreen({ screen }: { screen: ScreenType }) {
  const [eta, setEta] = useState(3);
  useEffect(() => {
    if (screen !== "track") return;
    const t = setInterval(() => setEta(e => Math.max(0, e - 1)), 1400);
    return () => clearInterval(t);
  }, [screen]);

  const StatusBar = () => (
    <div style={{ height: 28, background: "#0A0F2E", display: "flex", alignItems: "center", justifyContent: "space-between", padding: "0 14px", flexShrink: 0 }}>
      <span style={{ fontSize: 9, fontWeight: 700, color: "rgba(255,255,255,0.8)", fontFamily: "Space Grotesk,sans-serif" }}>9:41</span>
      <div style={{ width: 52, height: 8, borderRadius: 4, background: "#000" }} />
      <span style={{ fontSize: 9, color: "rgba(255,255,255,0.7)" }}>??? ?</span>
    </div>
  );

  if (screen === "home") return (
    <div style={{ width: "100%", height: "100%", display: "flex", flexDirection: "column", background: "#f0f4ff" }}>
      <StatusBar />
      <div style={{ flex: 1, position: "relative", background: "linear-gradient(160deg,#dbeafe,#e0e7ff)", overflow: "hidden" }}>
        {[...Array(6)].map((_, i) => <div key={i} style={{ position: "absolute", left: 0, right: 0, top: `${i * 18}%`, height: 1, background: "rgba(30,109,229,0.08)" }} />)}
        {[...Array(6)].map((_, i) => <div key={i} style={{ position: "absolute", top: 0, bottom: 0, left: `${i * 18}%`, width: 1, background: "rgba(30,109,229,0.08)" }} />)}
        <div style={{ position: "absolute", top: 10, left: 10, background: "rgba(255,255,255,0.95)", borderRadius: 8, padding: "3px 9px", boxShadow: "0 2px 8px rgba(0,0,0,0.1)", display: "flex", alignItems: "center", gap: 5 }}>
          <div style={{ width: 6, height: 6, borderRadius: "50%", background: "#1558C4" }} />
          <span style={{ fontSize: 9, fontWeight: 800, color: "#1558C4", fontFamily: "Space Grotesk,sans-serif", letterSpacing: 1 }}>JAGO</span>
        </div>
        <div style={{ position: "absolute", left: "48%", top: "45%", transform: "translate(-50%,-50%)" }}>
          <div style={{ width: 14, height: 14, borderRadius: "50%", background: "#1558C4", border: "3px solid #fff", boxShadow: "0 0 0 7px rgba(21,88,196,0.18)" }} />
        </div>
      </div>
      <div style={{ background: "#fff", padding: "12px 12px 10px", boxShadow: "0 -4px 20px rgba(0,0,0,0.07)" }}>
        <p style={{ fontSize: 10, color: "#64748b", margin: "0 0 7px", fontFamily: "Space Grotesk,sans-serif" }}>Good morning, Rahul ??</p>
        <div style={{ display: "flex", alignItems: "center", gap: 6, background: "#f0f5ff", borderRadius: 10, padding: "8px 10px", marginBottom: 9, border: "1px solid rgba(21,88,196,0.1)" }}>
          <div style={{ width: 6, height: 6, borderRadius: "50%", background: "#1558C4", flexShrink: 0 }} />
          <span style={{ fontSize: 10, color: "#94a3b8", fontFamily: "Space Grotesk,sans-serif" }}>Where do you want to go?</span>
        </div>
        <div style={{ display: "flex", justifyContent: "space-around" }}>
          {["Bike","Auto","Car","Parcel"].map((s, si) => (
            <div key={s} style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: 4 }}>
              <div style={{ width: 34, height: 34, borderRadius: 10, background: "#f0f5ff", border: "1px solid rgba(21,88,196,0.12)", display: "flex", alignItems: "center", justifyContent: "center" }}>
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#1558C4" strokeWidth="2.2" strokeLinecap="round">
                  {si === 0 && <><circle cx="6" cy="16" r="3"/><circle cx="18" cy="16" r="3"/><path d="M9 16l2-6h5l2 4.5"/><path d="M6 16l3.5-8.5"/></>}
                  {si === 1 && <><circle cx="7" cy="18" r="3"/><circle cx="17" cy="18" r="3"/><path d="M10 18h4M7 15V9l3.5-3H18l2 4v5H10"/></>}
                  {si === 2 && <><path d="M5 17H3a1 1 0 01-1-1v-3l3-5h13l3 5v3a1 1 0 01-1 1h-2"/><circle cx="7.5" cy="17.5" r="2.5"/><circle cx="16.5" cy="17.5" r="2.5"/></>}
                  {si === 3 && <><path d="M21 16V8a2 2 0 00-1-1.73l-7-4a2 2 0 00-2 0l-7 4A2 2 0 003 8v8a2 2 0 001 1.73l7 4a2 2 0 002 0l7-4A2 2 0 0021 16z"/><polyline points="3.27 6.96 12 12.01 20.73 6.96"/><line x1="12" y1="22.08" x2="12" y2="12"/></>}
                </svg>
              </div>
              <span style={{ fontSize: 8.5, color: "#475569", fontFamily: "Space Grotesk,sans-serif", fontWeight: 600 }}>{s}</span>
            </div>
          ))}
        </div>
      </div>
    </div>
  );

  if (screen === "route") return (
    <div style={{ width: "100%", height: "100%", display: "flex", flexDirection: "column", background: "#fff" }}>
      <StatusBar />
      <div style={{ background: "#1558C4", padding: "14px 12px 18px" }}>
        <p style={{ fontSize: 9, color: "rgba(255,255,255,0.65)", margin: "0 0 8px", fontFamily: "Space Grotesk,sans-serif", textTransform: "uppercase", letterSpacing: 1 }}>Set destination</p>
        <div style={{ display: "flex", alignItems: "center", gap: 7, background: "rgba(255,255,255,0.12)", borderRadius: 8, padding: "7px 9px", marginBottom: 5 }}>
          <div style={{ width: 6, height: 6, borderRadius: "50%", background: "rgba(255,255,255,0.9)" }} />
          <span style={{ fontSize: 10, color: "rgba(255,255,255,0.85)", fontFamily: "Space Grotesk,sans-serif" }}>Current Location</span>
        </div>
        <div style={{ display: "flex", alignItems: "center", gap: 7, background: "#fff", borderRadius: 8, padding: "7px 9px" }}>
          <div style={{ width: 6, height: 6, borderRadius: "50%", background: "#1558C4" }} />
          <span style={{ fontSize: 10, color: "#1558C4", fontWeight: 700, fontFamily: "Space Grotesk,sans-serif" }}>Hitech City Metro</span>
        </div>
      </div>
      <div style={{ padding: "10px 12px" }}>
        <p style={{ fontSize: 8.5, color: "#94a3b8", margin: "0 0 7px", fontFamily: "Space Grotesk,sans-serif", textTransform: "uppercase", letterSpacing: 1.2 }}>Nearby</p>
        {[{ p: "Hitech City Metro", d: "3.2 km" }, { p: "Apollo Hospital", d: "5.8 km" }, { p: "Inorbit Mall", d: "2.1 km" }].map((x, i) => (
          <div key={i} style={{ display: "flex", alignItems: "center", gap: 9, padding: "8px 0", borderBottom: "1px solid #f1f5f9" }}>
            <div style={{ width: 28, height: 28, borderRadius: 7, background: "#f0f5ff", display: "flex", alignItems: "center", justifyContent: "center" }}>
              <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="#1558C4" strokeWidth="2.2"><path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0118 0z"/><circle cx="12" cy="10" r="3"/></svg>
            </div>
            <div>
              <p style={{ margin: 0, fontSize: 10.5, fontWeight: 600, color: "#1e293b", fontFamily: "Space Grotesk,sans-serif" }}>{x.p}</p>
              <p style={{ margin: 0, fontSize: 8.5, color: "#94a3b8", fontFamily: "Space Grotesk,sans-serif" }}>{x.d}</p>
            </div>
          </div>
        ))}
      </div>
      <div style={{ position: "absolute", bottom: 14, left: 12, right: 12 }}>
        <div style={{ background: "#1558C4", borderRadius: 12, padding: "11px", textAlign: "center" }}>
          <span style={{ fontSize: 11.5, fontWeight: 700, color: "#fff", fontFamily: "Space Grotesk,sans-serif" }}>Confirm Route ?</span>
        </div>
      </div>
    </div>
  );

  if (screen === "fare") return (
    <div style={{ width: "100%", height: "100%", display: "flex", flexDirection: "column", background: "#f8f9ff" }}>
      <StatusBar />
      <div style={{ flex: 1, background: "linear-gradient(140deg,#dbeafe,#e0e7ff)", position: "relative", overflow: "hidden" }}>
        <svg style={{ position: "absolute", inset: "0" as any, width: "100%", height: "100%" }} viewBox="0 0 100 100" preserveAspectRatio="none">
          <path d="M28 75 Q50 52 72 30" stroke="#1558C4" strokeWidth="2.5" fill="none" strokeDasharray="5 3" opacity="0.6" />
          <circle cx="28" cy="75" r="3.5" fill="#fff" stroke="#1558C4" strokeWidth="1.5" />
          <circle cx="72" cy="30" r="3.5" fill="#1558C4" />
        </svg>
        <div style={{ position: "absolute", right: 10, top: 10, background: "#fff", borderRadius: 7, padding: "3px 8px", boxShadow: "0 2px 8px rgba(0,0,0,0.1)" }}>
          <span style={{ fontSize: 9.5, fontWeight: 700, color: "#1558C4", fontFamily: "Space Grotesk,sans-serif" }}>3.2 km</span>
        </div>
      </div>
      <div style={{ background: "#fff", padding: "12px", boxShadow: "0 -4px 16px rgba(0,0,0,0.07)" }}>
        <div style={{ display: "flex", gap: 5, marginBottom: 10 }}>
          {[{ t: "Bike", f: "?45", e: "2m", a: true }, { t: "Auto", f: "?75", e: "4m", a: false }, { t: "Car", f: "?130", e: "5m", a: false }].map(o => (
            <div key={o.t} style={{ flex: 1, padding: "7px 4px", borderRadius: 9, border: `1.5px solid ${o.a ? "#1558C4" : "#e2e8f0"}`, background: o.a ? "#f0f5ff" : "#fff", textAlign: "center" }}>
              <p style={{ margin: 0, fontSize: 9.5, fontWeight: 700, fontFamily: "Space Grotesk,sans-serif", color: o.a ? "#1558C4" : "#334155" }}>{o.t}</p>
              <p style={{ margin: "2px 0 0", fontSize: 12, fontWeight: 800, color: o.a ? "#1558C4" : "#64748b", fontFamily: "Space Grotesk,sans-serif" }}>{o.f}</p>
              <p style={{ margin: 0, fontSize: 8, color: "#94a3b8", fontFamily: "Space Grotesk,sans-serif" }}>{o.e}</p>
            </div>
          ))}
        </div>
        <div style={{ background: "linear-gradient(90deg,#1558C4,#2563eb)", borderRadius: 10, padding: "11px", textAlign: "center" }}>
          <span style={{ fontSize: 11.5, fontWeight: 700, color: "#fff", fontFamily: "Space Grotesk,sans-serif" }}>Confirm Booking</span>
        </div>
      </div>
    </div>
  );

  if (screen === "pilot") return (
    <div style={{ width: "100%", height: "100%", display: "flex", flexDirection: "column", background: "#fff" }}>
      <StatusBar />
      <div style={{ background: "linear-gradient(135deg,#0A0F2E,#1558C4)", padding: "20px 12px 26px", textAlign: "center" }}>
        <div style={{ width: 38, height: 38, borderRadius: "50%", background: "rgba(255,255,255,0.15)", margin: "0 auto 8px", display: "flex", alignItems: "center", justifyContent: "center" }}>
          <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#fff" strokeWidth="2.5"><polyline points="20 6 9 17 4 12"/></svg>
        </div>
        <p style={{ margin: 0, fontSize: 13, fontWeight: 700, color: "#fff", fontFamily: "Space Grotesk,sans-serif" }}>Pilot on the way!</p>
        <p style={{ margin: "3px 0 0", fontSize: 9.5, color: "rgba(255,255,255,0.75)", fontFamily: "Space Grotesk,sans-serif" }}>Arrives in 2 min</p>
      </div>
      <div style={{ flex: 1, padding: "12px", background: "#f8f9ff" }}>
        <div style={{ background: "#fff", borderRadius: 14, padding: 12, boxShadow: "0 4px 16px rgba(0,0,0,0.07)", marginBottom: 10 }}>
          <div style={{ display: "flex", alignItems: "center", gap: 10, marginBottom: 10 }}>
            <div style={{ width: 40, height: 40, borderRadius: "50%", background: "linear-gradient(135deg,#0A0F2E,#1558C4)", display: "flex", alignItems: "center", justifyContent: "center", fontSize: 16, color: "#fff", fontWeight: 700, fontFamily: "Space Grotesk,sans-serif" }}>R</div>
            <div style={{ flex: 1 }}>
              <p style={{ margin: 0, fontSize: 11.5, fontWeight: 700, color: "#1e293b", fontFamily: "Space Grotesk,sans-serif" }}>Ravi Kumar</p>
              <div style={{ display: "flex", alignItems: "center", gap: 3 }}>
                <span style={{ fontSize: 10, color: "#1558C4" }}>?</span>
                <span style={{ fontSize: 9.5, color: "#475569", fontFamily: "Space Grotesk,sans-serif" }}>4.8 � 1,240 rides</span>
              </div>
            </div>
            <div style={{ width: 30, height: 30, borderRadius: "50%", background: "#f0f5ff", border: "1px solid rgba(21,88,196,0.15)", display: "flex", alignItems: "center", justifyContent: "center" }}>
              <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="#1558C4" strokeWidth="2.2"><path d="M22 16.92v3a2 2 0 01-2.18 2 19.79 19.79 0 01-8.63-3.07A19.5 19.5 0 013.07 9.8 19.79 19.79 0 01.08 1.2 2 2 0 012.07 0h3a2 2 0 012 1.72 12.84 12.84 0 00.7 2.81 2 2 0 01-.45 2.11L6.09 7.91a16 16 0 006 6l1.27-1.27a2 2 0 012.11-.45 12.84 12.84 0 002.81.7A2 2 0 0122 14.92z"/></svg>
            </div>
          </div>
          <div style={{ display: "flex", justifyContent: "space-between", paddingTop: 8, borderTop: "1px solid #f1f5f9" }}>
            {[{ l: "Vehicle", v: "Activa" }, { l: "Plate", v: "TS09AB1234" }, { l: "OTP", v: "7482" }].map(x => (
              <div key={x.l} style={{ textAlign: "center" }}>
                <p style={{ margin: 0, fontSize: 7.5, color: "#94a3b8", fontFamily: "Space Grotesk,sans-serif" }}>{x.l}</p>
                <p style={{ margin: "2px 0 0", fontSize: 10, fontWeight: 700, color: x.l === "OTP" ? "#1558C4" : "#1e293b", fontFamily: "Space Grotesk,sans-serif" }}>{x.v}</p>
              </div>
            ))}
          </div>
        </div>
        <div style={{ display: "flex", alignItems: "center", gap: 7, background: "#f0f5ff", borderRadius: 9, padding: "9px 10px", border: "1px solid rgba(21,88,196,0.12)" }}>
          <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="#1558C4" strokeWidth="2.5"><path d="M18 8A6 6 0 006 8c0 7-3 9-3 9h18s-3-2-3-9"/><path d="M13.73 21a2 2 0 01-3.46 0"/></svg>
          <span style={{ fontSize: 9.5, color: "#1558C4", fontFamily: "Space Grotesk,sans-serif", fontWeight: 600 }}>Share OTP with pilot only</span>
        </div>
      </div>
    </div>
  );

  // track
  return (
    <div style={{ width: "100%", height: "100%", display: "flex", flexDirection: "column", background: "#f8f9ff" }}>
      <StatusBar />
      <div style={{ flex: 1, background: "linear-gradient(140deg,#dbeafe,#e0e7ff)", position: "relative" }}>
        <svg style={{ position: "absolute", inset: "0" as any, width: "100%", height: "100%" }} viewBox="0 0 100 100" preserveAspectRatio="none">
          <path d="M28 68 Q48 50 68 30" stroke="#1558C4" strokeWidth="2.5" fill="none" opacity="0.3" />
          <circle cx="28" cy="68" r="3" fill="#fff" stroke="#1558C4" strokeWidth="1.5" />
          <circle cx="68" cy="30" r="3" fill="#1558C4" />
          <circle cx="45" cy="52" r="4.5" fill="#1558C4" />
          <circle cx="45" cy="52" r="8" fill="rgba(21,88,196,0.15)" />
        </svg>
        <div style={{ position: "absolute", top: 10, left: "50%", transform: "translateX(-50%)", background: "#fff", borderRadius: 18, padding: "5px 13px", boxShadow: "0 2px 12px rgba(0,0,0,0.1)", display: "flex", alignItems: "center", gap: 6, whiteSpace: "nowrap" }}>
          <div style={{ width: 6, height: 6, borderRadius: "50%", background: "#1558C4" }} />
          <span style={{ fontSize: 9.5, fontWeight: 700, color: "#1e293b", fontFamily: "Space Grotesk,sans-serif" }}>Pilot arriving in {eta} min</span>
        </div>
      </div>
      <div style={{ background: "#fff", padding: "10px 12px", boxShadow: "0 -4px 16px rgba(0,0,0,0.06)" }}>
        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 9 }}>
          <div>
            <p style={{ margin: 0, fontSize: 11, fontWeight: 700, color: "#1e293b", fontFamily: "Space Grotesk,sans-serif" }}>Ravi Kumar � Bike</p>
            <p style={{ margin: "2px 0 0", fontSize: 8.5, color: "#94a3b8", fontFamily: "Space Grotesk,sans-serif" }}>TS09AB1234</p>
          </div>
          <div style={{ textAlign: "right" }}>
            <p style={{ margin: 0, fontSize: 17, fontWeight: 800, color: "#1558C4", fontFamily: "Space Grotesk,sans-serif" }}>?45</p>
            <p style={{ margin: 0, fontSize: 8.5, color: "#64748b", fontFamily: "Space Grotesk,sans-serif" }}>Cash</p>
          </div>
        </div>
        <div style={{ display: "flex", gap: 6 }}>
          {[{ l: "Call" }, { l: "Cancel" }, { l: "Chat" }].map((a, ai) => (
            <div key={a.l} style={{ flex: 1, background: ai === 1 ? "#fff1f2" : "#f0f5ff", borderRadius: 9, padding: "7px 4px", textAlign: "center", border: `1px solid ${ai === 1 ? "#fecdd3" : "rgba(21,88,196,0.12)"}` }}>
              <span style={{ fontSize: 9.5, fontWeight: 600, color: ai === 1 ? "#e11d48" : "#1558C4", fontFamily: "Space Grotesk,sans-serif" }}>{a.l}</span>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}

function PhoneDemo() {
  const [screen, setScreen] = useState(0);
  const [animKey, setAnimKey] = useState(0);
  useEffect(() => {
    const t = setInterval(() => { setAnimKey(k => k + 1); setScreen(s => (s + 1) % SCREENS.length); }, 3400);
    return () => clearInterval(t);
  }, []);
  const labels = ["Open App", "Set Destination", "Choose Ride", "Pilot Found", "Live Track"];
  return (
    <div style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: 20 }}>
      <div style={{ position: "relative", width: 240, height: 494, animation: "jago-float 4s ease-in-out infinite" }}>
        <div style={{ position: "absolute", inset: -28, borderRadius: 60, background: "radial-gradient(ellipse, rgba(21,88,196,0.35) 0%, transparent 70%)", filter: "blur(28px)" }} />
        <div style={{ position: "absolute", inset: 0, borderRadius: 42, background: "#0A0F2E", boxShadow: "0 48px 96px rgba(0,0,0,0.6), inset 0 0 0 1px rgba(255,255,255,0.06), 0 0 0 2px #161C3D", overflow: "hidden" }}>
          <div style={{ position: "absolute", left: -3, top: 96, width: 3, height: 24, background: "#161C3D", borderRadius: "2px 0 0 2px" }} />
          <div style={{ position: "absolute", left: -3, top: 132, width: 3, height: 24, background: "#161C3D", borderRadius: "2px 0 0 2px" }} />
          <div style={{ position: "absolute", right: -3, top: 114, width: 3, height: 34, background: "#161C3D", borderRadius: "0 2px 2px 0" }} />
          <div style={{ position: "absolute", inset: 6, borderRadius: 36, overflow: "hidden", background: "#fff" }}>
            <div key={animKey} style={{ width: "100%", height: "100%", animation: "jago-screen-in 0.36s ease forwards" }}>
              <PhoneScreen screen={SCREENS[screen]} />
            </div>
          </div>
        </div>
      </div>
      <div style={{ display: "flex", gap: 8, alignItems: "center" }}>
        {SCREENS.map((_, i) => (
          <button key={i} onClick={() => { setScreen(i); setAnimKey(k => k + 1); }}
            style={{ width: i === screen ? 24 : 7, height: 7, borderRadius: 4, background: i === screen ? "#fff" : "rgba(255,255,255,0.25)", border: "none", cursor: "pointer", transition: "all 0.3s", padding: 0 }} />
        ))}
      </div>
      <p style={{ fontSize: 11, fontWeight: 600, color: "rgba(255,255,255,0.5)", fontFamily: "Space Grotesk,sans-serif", margin: 0, letterSpacing: 1 }}>{labels[screen].toUpperCase()}</p>
    </div>
  );
}

/* --- Scroll Marquee --- */
const MARQUEE_ITEMS = ["Bike Taxi","Auto Ride","Cab Ride","Parcel Delivery","Goods Transport","Intercity Travel","Car Sharing","Safety Verified","Fair Pricing","60-Second Match","Live Tracking","Top Rated Pilots"];

function Marquee() {
  const items = [...MARQUEE_ITEMS, ...MARQUEE_ITEMS];
  return (
    <div style={{ overflow: "hidden", background: "rgba(255,255,255,0.04)", borderTop: "1px solid rgba(255,255,255,0.06)", borderBottom: "1px solid rgba(255,255,255,0.06)", padding: "14px 0" }}>
      <div style={{ display: "flex", gap: 40, animation: "jago-marquee 28s linear infinite", width: "max-content" }}>
        {items.map((item, i) => (
          <div key={i} style={{ display: "flex", alignItems: "center", gap: 8, whiteSpace: "nowrap" }}>
            <div style={{ width: 4, height: 4, borderRadius: "50%", background: "#1558C4" }} />
            <span style={{ fontSize: 12, fontWeight: 600, color: "rgba(255,255,255,0.45)", fontFamily: "Space Grotesk,sans-serif", letterSpacing: 0.5 }}>{item}</span>
          </div>
        ))}
      </div>
    </div>
  );
}

/* ---------------------------- MAIN PAGE ---------------------------- */
export default function LandingPage() {
  const [scrolled, setScrolled] = useState(false);

  const sRides  = useCountUp(500000, 2200);
  const sCities = useCountUp(50, 1500);
  const sPilots = useCountUp(20000, 1900);
  const sRating = useCountUp(49, 1400);

  const secSvc    = useReveal();
  const secHow    = useReveal();
  const secWhy    = useReveal();
  const secApps   = useReveal();
  const secStats  = useReveal();
  const secCities = useReveal();
  const secDl     = useReveal();
  const secJoin   = useReveal();

  useEffect(() => {
    const fn = () => setScrolled(window.scrollY > 24);
    window.addEventListener("scroll", fn, { passive: true });
    return () => window.removeEventListener("scroll", fn);
  }, []);

  /* -- Palette: Deep Navy + White -- */
  const N900 = "#06091A";
  const N800 = "#0A0F2E";
  const N700 = "#0D1340";
  const N600 = "#111A52";
  const N500 = "#1558C4";
  const W    = "#FFFFFF";
  const W70  = "rgba(255,255,255,0.70)";
  const W40  = "rgba(255,255,255,0.40)";
  const W10  = "rgba(255,255,255,0.10)";
  const W06  = "rgba(255,255,255,0.06)";
  const BORDER = "rgba(255,255,255,0.09)";

  const AppleIcon = () => <svg width="22" height="22" viewBox="0 0 24 24" fill={N800}><path d="M17.05 20.28c-.98.95-2.05.8-3.08.35-1.09-.46-2.09-.48-3.24 0-1.44.62-2.2.44-3.06-.35C2.79 15.25 3.51 7.7 9.05 7.42c1.42.07 2.4.78 3.22.83 1.23-.24 2.4-1 3.72-.87 1.58.17 2.86.77 3.62 2.06-3.27 1.98-2.53 6.2.72 7.43-.6 1.65-1.36 3.26-3.28 5.41zM12.03 7.25c-.15-2.23 1.66-4.07 3.74-4.25.29 2.58-2.34 4.5-3.74 4.25z"/></svg>;
  const PlayIcon = () => <svg width="22" height="22" viewBox="0 0 24 24" fill={N800}><path d="M3 18.5v-13A1.5 1.5 0 015.12 4.1l13 6.5a1.5 1.5 0 010 2.8l-13 6.5A1.5 1.5 0 013 18.5z"/></svg>;
  const ArrowR = () => <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round"><path d="M5 12h14M12 5l7 7-7 7"/></svg>;

  return (
    <>
      <style>{`
        @import url('https://fonts.googleapis.com/css2?family=Space+Grotesk:wght@400;500;600;700;800&family=Inter:wght@400;500;600;700&display=swap');
        *,*::before,*::after{box-sizing:border-box;margin:0;padding:0}
        html{scroll-behavior:smooth}
        body{font-family:'Inter',sans-serif;background:${N800}}

        @keyframes jago-float{0%,100%{transform:translateY(0)}50%{transform:translateY(-14px)}}
        @keyframes jago-badge{0%,100%{opacity:1;transform:scale(1)}50%{opacity:.45;transform:scale(.8)}}
        @keyframes jago-glow{0%,100%{transform:scale(1) translate(0,0);opacity:.5}40%{transform:scale(1.2) translate(20px,-20px);opacity:.3}70%{transform:scale(.85) translate(-18px,14px);opacity:.6}}
        @keyframes jago-fade-up{from{opacity:0;transform:translateY(32px)}to{opacity:1;transform:translateY(0)}}
        @keyframes jago-marquee{from{transform:translateX(0)}to{transform:translateX(-50%)}}
        @keyframes jago-screen-in{from{opacity:0;transform:translateX(24px) scale(.97)}to{opacity:1;transform:translateX(0) scale(1)}}
        @keyframes jago-pulse{0%,100%{box-shadow:0 0 0 0 rgba(21,88,196,.55)}50%{box-shadow:0 0 0 14px rgba(21,88,196,0)}}

        .reveal{opacity:0;transform:translateY(36px);transition:opacity .8s ease,transform .8s ease}
        .reveal.vis{opacity:1;transform:translateY(0)}
        .svc-card{transition:transform .25s,box-shadow .25s,background .25s;cursor:pointer}
        .svc-card:hover{transform:translateY(-6px);background:${N600} !important;box-shadow:0 24px 60px rgba(21,88,196,.22)!important}
        .feat-card{transition:background .2s}
        .feat-card:hover{background:${N600} !important}
        .city-card{transition:transform .2s}
        .city-card:hover{transform:scale(1.04)}
        .dl-btn{transition:transform .2s,box-shadow .2s}
        .dl-btn:hover{transform:translateY(-3px)}
        .nav-link{color:${W40};text-decoration:none;font-size:14px;font-weight:500;font-family:'Space Grotesk',sans-serif;transition:color .2s}
        .nav-link:hover{color:${W}}
        .container{max-width:1160px;margin:0 auto;padding:0 24px}
        .sec{padding:100px 0}

        @media(max-width:768px){
          .hero-grid{grid-template-columns:1fr !important}
          .svc-grid{grid-template-columns:1fr 1fr !important}
          .feat-grid{grid-template-columns:1fr 1fr !important}
          .apps-grid{grid-template-columns:1fr !important}
          .stats-grid{grid-template-columns:1fr 1fr !important}
          .city-grid{grid-template-columns:repeat(3,1fr) !important}
          .footer-grid{grid-template-columns:1fr 1fr !important}
          .hero-btns{flex-direction:column}
          .hide-mobile{display:none !important}
        }
      `}</style>

      <div style={{ background: N800, color: W, minHeight: "100vh" }}>

        {/* NAV */}
        <nav style={{ position: "fixed", top: 0, left: 0, right: 0, zIndex: 200, backdropFilter: "blur(20px)", background: scrolled ? "rgba(6,9,26,0.96)" : "rgba(10,15,46,.7)", borderBottom: `1px solid ${scrolled ? BORDER : "transparent"}`, transition: "all .3s" }}>
          <div className="container" style={{ height: 64, display: "flex", alignItems: "center", justifyContent: "space-between" }}>
            <a href="/"><img src="/jago-logo.png" alt="JAGO" style={{ height: 36, width: "auto", objectFit: "contain" }} /></a>
            <div className="hide-mobile" style={{ display: "flex", gap: 32, alignItems: "center" }}>
              {[["#services","Services"],["#how","How It Works"],["#why","Why Jago"],["#cities","Cities"],["#download","Download"]].map(([href, label]) => (
                <a key={href} href={href} className="nav-link">{label}</a>
              ))}
            </div>
            <a href="#download" className="dl-btn" style={{ padding: "9px 20px", borderRadius: 10, background: N500, color: W, fontSize: 13, fontWeight: 700, textDecoration: "none", fontFamily: "Space Grotesk,sans-serif" }}>Get App</a>
          </div>
        </nav>

        {/* HERO */}
        <section style={{ minHeight: "100vh", display: "flex", alignItems: "center", position: "relative", overflow: "hidden", paddingTop: 64 }}>
          <div style={{ position: "absolute", top: "5%", right: "-5%", width: 700, height: 700, borderRadius: "50%", background: "radial-gradient(circle,rgba(21,88,196,0.14) 0%,transparent 70%)", animation: "jago-glow 16s ease-in-out infinite", pointerEvents: "none" }} />
          <div style={{ position: "absolute", bottom: "5%", left: "-8%", width: 500, height: 500, borderRadius: "50%", background: "radial-gradient(circle,rgba(21,88,196,0.09) 0%,transparent 70%)", animation: "jago-glow 20s ease-in-out infinite reverse", pointerEvents: "none" }} />
          <div style={{ position: "absolute", inset: 0, backgroundImage: `linear-gradient(${BORDER} 1px,transparent 1px),linear-gradient(90deg,${BORDER} 1px,transparent 1px)`, backgroundSize: "72px 72px", pointerEvents: "none" }} />

          <div className="container hero-grid" style={{ width: "100%", display: "grid", gridTemplateColumns: "1.15fr 0.85fr", gap: 56, alignItems: "center", padding: "72px 24px 96px" }}>
            {/* LEFT */}
            <div style={{ animation: "jago-fade-up .9s ease forwards" }}>
              <div style={{ marginBottom: 32 }}>
                <img src="/jago-logo.png" alt="JAGO" style={{ height: 56, width: "auto", objectFit: "contain" }} />
              </div>
              <div style={{ display: "inline-flex", alignItems: "center", gap: 8, background: W06, border: `1px solid ${BORDER}`, borderRadius: 30, padding: "6px 14px", marginBottom: 30 }}>
                <div style={{ width: 7, height: 7, borderRadius: "50%", background: "#4ade80", animation: "jago-badge 1.6s infinite" }} />
                <span style={{ fontSize: 12, fontWeight: 600, color: W70, fontFamily: "Space Grotesk,sans-serif" }}>Live across 50+ cities in India</span>
              </div>
              <h1 style={{ fontSize: "clamp(40px,5vw,72px)", fontWeight: 800, lineHeight: 1.08, marginBottom: 24, fontFamily: "Space Grotesk,sans-serif", letterSpacing: -2 }}>
                Move Smarter,<br />
                <span style={{ color: N500 }}>Ride Anywhere.</span>
              </h1>
              <p style={{ fontSize: 18, color: W70, lineHeight: 1.8, maxWidth: 480, marginBottom: 44 }}>
                Book a bike, auto, or cab in under 60 seconds. Smart rides with verified pilots — door to door, city to city.
              </p>
              <div className="hero-btns" style={{ display: "flex", gap: 14, flexWrap: "wrap", marginBottom: 56 }}>
                <a href="#download" className="dl-btn" style={{ display: "flex", alignItems: "center", gap: 11, background: W, color: N800, padding: "13px 22px", borderRadius: 14, textDecoration: "none", fontFamily: "Space Grotesk,sans-serif", fontWeight: 700, boxShadow: "0 4px 28px rgba(0,0,0,.4)" }}>
                  <AppleIcon />
                  <div><div style={{ fontSize: 9, opacity: .5, textTransform: "uppercase", letterSpacing: 1 }}>Download on</div><div style={{ fontSize: 14, lineHeight: 1.2 }}>App Store</div></div>
                </a>
                <a href="#download" className="dl-btn" style={{ display: "flex", alignItems: "center", gap: 11, background: W, color: N800, padding: "13px 22px", borderRadius: 14, textDecoration: "none", fontFamily: "Space Grotesk,sans-serif", fontWeight: 700, boxShadow: "0 4px 28px rgba(0,0,0,.4)" }}>
                  <PlayIcon />
                  <div><div style={{ fontSize: 9, opacity: .5, textTransform: "uppercase", letterSpacing: 1 }}>Get it on</div><div style={{ fontSize: 14, lineHeight: 1.2 }}>Google Play</div></div>
                </a>
                <a href="/auth" className="dl-btn" style={{ display: "flex", alignItems: "center", gap: 8, border: `1px solid ${BORDER}`, color: W70, padding: "13px 22px", borderRadius: 14, textDecoration: "none", fontFamily: "Space Grotesk,sans-serif", fontWeight: 600 }}>
                  <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round"><circle cx="6" cy="16" r="3"/><circle cx="18" cy="16" r="3"/><path d="M9 16l2-6h5l2 4.5"/><path d="M6 16l3.5-8.5"/></svg>
                  <span style={{ marginLeft: 4 }}>Become a Pilot</span>
                </a>
              </div>
              <div style={{ display: "flex", gap: 44, flexWrap: "wrap" }}>
                {[
                  { refObj: sRides.ref,  val: `${(sRides.val/1000).toFixed(0)}K+`, label: "Rides" },
                  { refObj: sCities.ref, val: `${sCities.val}+`, label: "Cities" },
                  { refObj: sPilots.ref, val: `${(sPilots.val/1000).toFixed(0)}K+`, label: "Pilots" },
                ].map((s, i) => (
                  <div key={i} ref={s.refObj}>
                    <p style={{ fontSize: 34, fontWeight: 800, color: W, margin: 0, fontFamily: "Space Grotesk,sans-serif", lineHeight: 1 }}>{s.val}</p>
                    <p style={{ fontSize: 12, color: W40, margin: "5px 0 0", fontFamily: "Space Grotesk,sans-serif", letterSpacing: .5 }}>{s.label}</p>
                  </div>
                ))}
              </div>
            </div>
            {/* RIGHT */}
            <div style={{ display: "flex", justifyContent: "center" }}><PhoneDemo /></div>
          </div>
          <div style={{ position: "absolute", bottom: 0, left: 0, right: 0, height: 120, background: `linear-gradient(transparent,${N800})`, pointerEvents: "none" }} />
        </section>

        {/* MARQUEE */}
        <Marquee />

        {/* SERVICES */}
        <section id="services" className="sec" style={{ background: N900 }}>
          <div className="container">
            <div ref={secSvc.ref} className={`reveal${secSvc.vis ? " vis" : ""}`}>
              <div style={{ textAlign: "center", maxWidth: 540, margin: "0 auto 64px" }}>
                <div style={{ fontSize: 11, fontWeight: 700, color: N500, textTransform: "uppercase", letterSpacing: 3, fontFamily: "Space Grotesk,sans-serif", marginBottom: 14 }}>Our Services</div>
                <h2 style={{ fontSize: "clamp(28px,3.5vw,48px)", fontWeight: 800, fontFamily: "Space Grotesk,sans-serif", letterSpacing: -1, lineHeight: 1.12 }}>Every ride,<br />every need.</h2>
                <p style={{ fontSize: 15, color: W40, marginTop: 14, lineHeight: 1.75 }}>From quick city hops to long-distance hauls � Jago gets you there.</p>
              </div>
              <div className="svc-grid" style={{ display: "grid", gridTemplateColumns: "repeat(3,1fr)", gap: 16 }}>
                {[
                  { icon: <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round"><circle cx="6" cy="16" r="3"/><circle cx="18" cy="16" r="3"/><path d="M9 16l2-6h5l2 4.5"/><path d="M6 16l3.5-8.5"/></svg>, title: "Bike Taxi", desc: "Fastest way through city traffic. Affordable 2-wheeler rides." },
                  { icon: <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round"><circle cx="7" cy="18" r="3"/><circle cx="17" cy="18" r="3"/><path d="M10 18h4M7 15V9l3.5-3H18l2 4v5H10"/></svg>, title: "Auto Ride", desc: "Classic CNG auto rides. Comfortable and pocket-friendly." },
                  { icon: <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round"><path d="M5 17H3a1 1 0 01-1-1v-3l3-5h13l3 5v3a1 1 0 01-1 1h-2"/><circle cx="7.5" cy="17.5" r="2.5"/><circle cx="16.5" cy="17.5" r="2.5"/></svg>, title: "Cab Ride", desc: "AC cab rides for family and business travel across the city." },
                  { icon: <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round"><path d="M3 21h18"/><rect x="3" y="8" width="7" height="13" rx="1"/><rect x="13" y="3" width="8" height="18" rx="1"/></svg>, title: "Intercity", desc: "Outstation travel with transparent pricing and top pilots." },
                  { icon: <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round"><path d="M21 16V8a2 2 0 00-1-1.73l-7-4a2 2 0 00-2 0l-7 4A2 2 0 003 8v8a2 2 0 001 1.73l7 4a2 2 0 002 0l7-4A2 2 0 0021 16z"/><polyline points="3.27 6.96 12 12.01 20.73 6.96"/><line x1="12" y1="22.08" x2="12" y2="12"/></svg>, title: "Parcel Delivery", desc: "Send packages door to door � same day, same city." },
                  { icon: <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round"><rect x="1" y="4" width="14" height="12" rx="1"/><path d="M15 8h4l3 4v4h-7V8z"/><circle cx="5.5" cy="18.5" r="2.5"/><circle cx="18.5" cy="18.5" r="2.5"/></svg>, title: "Goods Transport", desc: "Move furniture, appliances, and freight with trucks." },
                ].map((s, i) => (
                  <div key={i} className="svc-card" style={{ background: N700, borderRadius: 20, padding: "28px 24px", border: `1px solid ${BORDER}` }}>
                    <div style={{ width: 52, height: 52, borderRadius: 14, background: `linear-gradient(135deg,${N500},#0e2fa8)`, display: "flex", alignItems: "center", justifyContent: "center", marginBottom: 18, boxShadow: "0 8px 24px rgba(21,88,196,0.4)" }}>
                      {s.icon}
                    </div>
                    <h3 style={{ fontSize: 16.5, fontWeight: 700, marginBottom: 9, fontFamily: "Space Grotesk,sans-serif", color: W }}>{s.title}</h3>
                    <p style={{ fontSize: 13.5, color: W40, lineHeight: 1.7, marginBottom: 16 }}>{s.desc}</p>
                    <div style={{ display: "flex", alignItems: "center", gap: 5, fontSize: 12.5, fontWeight: 600, color: N500, fontFamily: "Space Grotesk,sans-serif" }}>
                      Book now <ArrowR />
                    </div>
                  </div>
                ))}
              </div>
            </div>
          </div>
        </section>

        {/* HOW IT WORKS */}
        <section id="how" className="sec" style={{ background: N800 }}>
          <div className="container">
            <div ref={secHow.ref} className={`reveal${secHow.vis ? " vis" : ""}`}>
              <div style={{ textAlign: "center", maxWidth: 560, margin: "0 auto 64px" }}>
                <div style={{ fontSize: 11, fontWeight: 700, color: N500, textTransform: "uppercase", letterSpacing: 3, fontFamily: "Space Grotesk,sans-serif", marginBottom: 14 }}>How It Works</div>
                <h2 style={{ fontSize: "clamp(28px,3.5vw,48px)", fontWeight: 800, fontFamily: "Space Grotesk,sans-serif", letterSpacing: -1, lineHeight: 1.12 }}>Ride in 3 simple steps.</h2>
                <p style={{ fontSize: 15, color: W40, marginTop: 14, lineHeight: 1.75 }}>From booking to destination — the whole experience is designed to be fast and effortless.</p>
              </div>
              <div style={{ display: "grid", gridTemplateColumns: "repeat(3,1fr)", gap: 24 }} className="svc-grid">
                {[
                  {
                    step: "01",
                    icon: <svg width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="2" strokeLinecap="round"><path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0118 0z"/><circle cx="12" cy="10" r="3"/></svg>,
                    title: "Set your destination",
                    desc: "Open the app and enter where you want to go. Jago instantly shows you available ride options and upfront fares — no surprises.",
                  },
                  {
                    step: "02",
                    icon: <svg width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><circle cx="6" cy="16" r="3"/><circle cx="18" cy="16" r="3"/><path d="M9 16l2-6h5l2 4.5"/><path d="M6 16l3.5-8.5"/></svg>,
                    title: "Get matched instantly",
                    desc: "A verified pilot near you accepts your trip in under 60 seconds. Track their live location as they head your way.",
                  },
                  {
                    step: "03",
                    icon: <svg width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="2" strokeLinecap="round"><polygon points="13 2 3 14 12 14 11 22 21 10 12 10 13 2"/></svg>,
                    title: "Ride & pay seamlessly",
                    desc: "Confirm OTP, hop in, and your route is navigated automatically. Pay with UPI, card, or Jago Wallet — earn coins with every trip.",
                  },
                ].map((s, i) => (
                  <div key={i} style={{ background: N700, borderRadius: 24, padding: "36px 28px", border: `1px solid ${BORDER}`, position: "relative", overflow: "hidden" }}>
                    <div style={{ position: "absolute", top: 20, right: 22, fontSize: 56, fontWeight: 800, color: "rgba(21,88,196,0.08)", fontFamily: "Space Grotesk,sans-serif", lineHeight: 1, pointerEvents: "none" }}>{s.step}</div>
                    <div style={{ width: 56, height: 56, borderRadius: 16, background: `linear-gradient(135deg,${N500},#0e2fa8)`, display: "flex", alignItems: "center", justifyContent: "center", marginBottom: 22, boxShadow: "0 8px 24px rgba(21,88,196,0.4)" }}>
                      {s.icon}
                    </div>
                    <h3 style={{ fontSize: 17, fontWeight: 700, color: W, marginBottom: 12, fontFamily: "Space Grotesk,sans-serif" }}>{s.title}</h3>
                    <p style={{ fontSize: 13.5, color: W40, lineHeight: 1.75 }}>{s.desc}</p>
                  </div>
                ))}
              </div>
            </div>
          </div>
        </section>

        {/* WHY JAGO */}
        <section id="why" className="sec" style={{ background: N800 }}>
          <div className="container">
            <div ref={secWhy.ref} className={`reveal${secWhy.vis ? " vis" : ""}`}>
              <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 72, alignItems: "center" }} className="hero-grid">
                <div>
                  <div style={{ fontSize: 11, fontWeight: 700, color: N500, textTransform: "uppercase", letterSpacing: 3, fontFamily: "Space Grotesk,sans-serif", marginBottom: 14 }}>Why Jago</div>
                  <h2 style={{ fontSize: "clamp(28px,3.5vw,48px)", fontWeight: 800, fontFamily: "Space Grotesk,sans-serif", letterSpacing: -1, lineHeight: 1.12, marginBottom: 20 }}>Built different,<br />built better.</h2>
                  <p style={{ fontSize: 15.5, color: W70, lineHeight: 1.8, marginBottom: 36, maxWidth: 440 }}>We built an obsession-grade experience that puts safety, affordability, and speed first � for both riders and pilots.</p>
                  <div style={{ display: "flex", gap: 14, flexWrap: "wrap" }}>
                    <a href="#download" style={{ padding: "12px 22px", borderRadius: 12, background: N500, color: W, fontSize: 14, fontWeight: 700, textDecoration: "none", fontFamily: "Space Grotesk,sans-serif" }}>Get the App</a>
                    <a href="/auth" style={{ padding: "12px 22px", borderRadius: 12, border: `1px solid ${BORDER}`, color: W70, fontSize: 14, fontWeight: 500, textDecoration: "none", fontFamily: "Space Grotesk,sans-serif" }}>Become a Pilot</a>
                  </div>
                </div>
                <div className="feat-grid" style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 12 }}>
                  {[
                    { icon: <svg width="19" height="19" viewBox="0 0 24 24" fill="white"><polygon points="13 2 3 14 12 14 11 22 21 10 12 10 13 2"/></svg>, title: "60-Second Match", desc: "Get a verified pilot matched in under a minute." },
                    { icon: <svg width="19" height="19" viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="2.2" strokeLinecap="round"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/><polyline points="9 12 11 14 15 10"/></svg>, title: "Verified Pilots", desc: "Every pilot is background-checked and KYC verified." },
                    { icon: <svg width="19" height="19" viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="2.2" strokeLinecap="round"><circle cx="8" cy="8" r="6"/><path d="M18.09 10.37A6 6 0 1110.34 18"/><path d="M7 6h1v4"/><path d="M16.71 13.88l.7.71-2.82 2.82"/></svg>, title: "No Surge Pricing", desc: "Fixed fares, no hidden charges, ever." },
                    { icon: <svg width="19" height="19" viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="2.2" strokeLinecap="round"><path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0118 0z"/><circle cx="12" cy="10" r="3"/></svg>, title: "Live GPS Tracking", desc: "Real-time tracking with family share link." },
                    { icon: <svg width="19" height="19" viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="2.2" strokeLinecap="round"><path d="M21 15a2 2 0 01-2 2H7l-4 4V5a2 2 0 012-2h14a2 2 0 012 2z"/></svg>, title: "In-App Chat", desc: "Talk to your pilot without sharing your number." },
                    { icon: <svg width="19" height="19" viewBox="0 0 24 24" fill="white"><polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"/></svg>, title: "Rated 4.9?", desc: "Highest rated ride app in South India." },
                  ].map((w, i) => (
                    <div key={i} className="feat-card" style={{ background: N700, border: `1px solid ${BORDER}`, borderRadius: 16, padding: "18px" }}>
                      <div style={{ width: 40, height: 40, borderRadius: 10, background: `linear-gradient(135deg,${N500},#0e2fa8)`, display: "flex", alignItems: "center", justifyContent: "center", marginBottom: 12 }}>{w.icon}</div>
                      <h4 style={{ fontSize: 13.5, fontWeight: 700, color: W, fontFamily: "Space Grotesk,sans-serif", marginBottom: 5 }}>{w.title}</h4>
                      <p style={{ fontSize: 12, color: W40, lineHeight: 1.55 }}>{w.desc}</p>
                    </div>
                  ))}
                </div>
              </div>
            </div>
          </div>
        </section>

        {/* STATS */}
        <section className="sec" style={{ background: `linear-gradient(135deg,${N900} 0%,${N800} 50%,#091040 100%)`, position: "relative", overflow: "hidden" }}>
          <div style={{ position: "absolute", inset: 0, backgroundImage: `linear-gradient(${W06} 1px,transparent 1px),linear-gradient(90deg,${W06} 1px,transparent 1px)`, backgroundSize: "56px 56px", pointerEvents: "none" }} />
          <div className="container" style={{ position: "relative" }}>
            <div ref={secStats.ref} className={`reveal${secStats.vis ? " vis" : ""}`}>
              <div style={{ textAlign: "center", marginBottom: 60 }}>
                <h2 style={{ fontSize: "clamp(28px,3.5vw,48px)", fontWeight: 800, fontFamily: "Space Grotesk,sans-serif", color: W, letterSpacing: -1 }}>Numbers that prove it</h2>
                <p style={{ color: W40, fontSize: 15, marginTop: 12 }}>Real performance. Real trust.</p>
              </div>
              <div className="stats-grid" style={{ display: "grid", gridTemplateColumns: "repeat(4,1fr)", gap: 20 }}>
                {[
                  { refObj: sRides.ref,  val: `${(sRides.val/1000).toFixed(0)}K+`, label: "Rides Completed" },
                  { refObj: sCities.ref, val: `${sCities.val}+`, label: "Cities Active" },
                  { refObj: sPilots.ref, val: `${(sPilots.val/1000).toFixed(0)}K+`, label: "Verified Pilots" },
                  { refObj: sRating.ref, val: `${(sRating.val/10).toFixed(1)}?`, label: "Avg Rider Rating" },
                ].map((s, i) => (
                  <div key={i} ref={s.refObj} style={{ textAlign: "center", background: W06, backdropFilter: "blur(12px)", borderRadius: 20, padding: "36px 16px", border: `1px solid ${W10}` }}>
                    <p style={{ fontSize: 44, fontWeight: 800, color: W, margin: "0 0 10px", fontFamily: "Space Grotesk,sans-serif", lineHeight: 1 }}>{s.val}</p>
                    <p style={{ fontSize: 13, color: W40, fontFamily: "Space Grotesk,sans-serif" }}>{s.label}</p>
                  </div>
                ))}
              </div>
            </div>
          </div>
        </section>

        {/* TWO APPS */}
        <section id="apps" className="sec" style={{ background: N900 }}>
          <div className="container">
            <div ref={secApps.ref} className={`reveal${secApps.vis ? " vis" : ""}`}>
              <div style={{ textAlign: "center", marginBottom: 56 }}>
                <div style={{ fontSize: 11, fontWeight: 700, color: N500, textTransform: "uppercase", letterSpacing: 3, fontFamily: "Space Grotesk,sans-serif", marginBottom: 14 }}>Two Apps, One Platform</div>
                <h2 style={{ fontSize: "clamp(28px,3.5vw,48px)", fontWeight: 800, fontFamily: "Space Grotesk,sans-serif", letterSpacing: -1 }}>For every journey</h2>
              </div>
              <div className="apps-grid" style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 20 }}>
                {[
                  { title: "Jago Customer App", sub: "For Riders",  desc: "Book rides instantly, track in real-time, earn Jago coins on every trip, pay seamlessly � all in one app.", cta: "Get Customer App", shade: "#1035A8" },
                  { title: "Jago Pilot App",    sub: "For Drivers", desc: "Accept trips, manage earnings, grow with Jago's daily pay + rewards model. Your wheels, your income.", cta: "Join as Pilot", shade: "#0A0F2E" },
                ].map((d, i) => (
                  <div key={i} style={{ borderRadius: 24, padding: "44px 40px", background: `linear-gradient(135deg,${N500} 0%,${d.shade} 100%)`, position: "relative", overflow: "hidden" }}>
                    <div style={{ position: "absolute", top: -44, right: -44, width: 160, height: 160, borderRadius: "50%", background: "rgba(255,255,255,0.05)" }} />
                    <div style={{ position: "absolute", bottom: -50, left: -24, width: 180, height: 180, borderRadius: "50%", background: "rgba(255,255,255,0.03)" }} />
                    <div style={{ position: "relative", zIndex: 1 }}>
                      <div style={{ width: 56, height: 56, borderRadius: 16, background: "rgba(255,255,255,0.13)", border: "1px solid rgba(255,255,255,0.2)", display: "flex", alignItems: "center", justifyContent: "center", marginBottom: 14 }}>
                        {i === 0
                          ? <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="1.8" strokeLinecap="round"><rect x="5" y="2" width="14" height="20" rx="2"/><line x1="12" y1="18" x2="12" y2="18" strokeWidth="3"/></svg>
                          : <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"><circle cx="6" cy="16" r="3"/><circle cx="18" cy="16" r="3"/><path d="M9 16l2-6h5l2 4.5"/><path d="M6 16l3.5-8.5"/></svg>
                        }
                      </div>
                      <div style={{ fontSize: 10, fontWeight: 700, color: "rgba(255,255,255,0.6)", textTransform: "uppercase", letterSpacing: 2, marginBottom: 8, fontFamily: "Space Grotesk,sans-serif" }}>{d.sub}</div>
                      <h3 style={{ fontSize: 24, fontWeight: 800, color: W, marginBottom: 14, fontFamily: "Space Grotesk,sans-serif" }}>{d.title}</h3>
                      <p style={{ fontSize: 15, color: "rgba(255,255,255,0.78)", lineHeight: 1.7, marginBottom: 28 }}>{d.desc}</p>
                      <a href="#download" className="dl-btn" style={{ display: "inline-flex", alignItems: "center", gap: 8, background: "rgba(255,255,255,0.15)", backdropFilter: "blur(8px)", border: "1px solid rgba(255,255,255,0.25)", color: W, padding: "11px 22px", borderRadius: 12, textDecoration: "none", fontSize: 13, fontWeight: 700, fontFamily: "Space Grotesk,sans-serif" }}>
                        {d.cta} <ArrowR />
                      </a>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          </div>
        </section>

        {/* DRIVER EARNINGS */}
        <section id="earnings" className="sec" style={{ background: N900, position: "relative", overflow: "hidden" }}>
          <div style={{ position: "absolute", inset: 0, backgroundImage: `radial-gradient(circle at 70% 50%, rgba(21,88,196,0.12) 0%, transparent 60%)`, pointerEvents: "none" }} />
          <div className="container" style={{ position: "relative" }}>
            <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 64, alignItems: "center" }} className="hero-grid">
              <div>
                <div style={{ fontSize: 11, fontWeight: 700, color: N500, textTransform: "uppercase", letterSpacing: 3, fontFamily: "Space Grotesk,sans-serif", marginBottom: 14 }}>Pilot Earnings</div>
                <h2 style={{ fontSize: "clamp(28px,3.5vw,48px)", fontWeight: 800, fontFamily: "Space Grotesk,sans-serif", letterSpacing: -1, lineHeight: 1.12, marginBottom: 20 }}>Drive more.<br />Earn more.</h2>
                <p style={{ fontSize: 15.5, color: W70, lineHeight: 1.8, marginBottom: 36, maxWidth: 420 }}>Jago pilots earn industry-leading pay with daily payouts, surge bonuses, and zero commission cuts for the first 3 months.</p>
                <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 16, marginBottom: 36 }}>
                  {[
                    { val: "₹2,500+", label: "Avg. daily earnings" },
                    { val: "0%", label: "Commission — first 90 days" },
                    { val: "₹500", label: "Weekly performance bonus" },
                    { val: "24h", label: "Daily payout cycle" },
                  ].map((e, i) => (
                    <div key={i} style={{ background: `rgba(21,88,196,0.08)`, borderRadius: 16, padding: "20px 18px", border: `1px solid rgba(21,88,196,0.2)` }}>
                      <p style={{ fontSize: 26, fontWeight: 800, color: N500, fontFamily: "Space Grotesk,sans-serif", margin: "0 0 4px", lineHeight: 1.1 }}>{e.val}</p>
                      <p style={{ fontSize: 12, color: W40, margin: 0, lineHeight: 1.5 }}>{e.label}</p>
                    </div>
                  ))}
                </div>
                <a href="/auth" style={{ display: "inline-flex", alignItems: "center", gap: 8, padding: "13px 26px", borderRadius: 12, background: N500, color: W, textDecoration: "none", fontSize: 14, fontWeight: 700, fontFamily: "Space Grotesk,sans-serif", boxShadow: "0 4px 20px rgba(21,88,196,0.35)" }}>
                  Become a Pilot <ArrowR />
                </a>
              </div>
              <div style={{ display: "flex", flexDirection: "column", gap: 14 }}>
                {[
                  { icon: "💳", title: "Daily Pay", desc: "Request your earnings any day — no weekly lock-in. Money hits your bank within 2 hours." },
                  { icon: "🏆", title: "Reward Tiers", desc: "Bronze → Silver → Gold → Platinum. Higher tiers unlock better trip rates and priority dispatch." },
                  { icon: "⛽", title: "Fuel Savings", desc: "Partner pump discounts up to ₹8/litre at 200+ stations across service cities." },
                  { icon: "🛡️", title: "100% Insured", desc: "Every trip covered under Jago Shield — accident, vehicle damage, and third-party liability." },
                ].map((b, i) => (
                  <div key={i} style={{ display: "flex", gap: 18, background: N800, borderRadius: 16, padding: "20px 22px", border: `1px solid ${BORDER}`, alignItems: "flex-start" }}>
                    <span style={{ fontSize: 26, flexShrink: 0, lineHeight: 1 }}>{b.icon}</span>
                    <div>
                      <h4 style={{ fontSize: 14, fontWeight: 700, color: W, fontFamily: "Space Grotesk,sans-serif", margin: "0 0 5px" }}>{b.title}</h4>
                      <p style={{ fontSize: 13, color: W40, margin: 0, lineHeight: 1.65 }}>{b.desc}</p>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          </div>
        </section>

        {/* CITIES */}
        <section id="cities" className="sec" style={{ background: N800 }}>
          <div className="container">
            <div ref={secCities.ref} className={`reveal${secCities.vis ? " vis" : ""}`} style={{ textAlign: "center" }}>
              <div style={{ fontSize: 11, fontWeight: 700, color: N500, textTransform: "uppercase", letterSpacing: 3, fontFamily: "Space Grotesk,sans-serif", marginBottom: 14 }}>Service Areas</div>
              <h2 style={{ fontSize: "clamp(28px,3.5vw,48px)", fontWeight: 800, fontFamily: "Space Grotesk,sans-serif", letterSpacing: -1, marginBottom: 14 }}>Growing fast</h2>
              <p style={{ fontSize: 15, color: W40, maxWidth: 400, margin: "0 auto 56px", lineHeight: 1.7 }}>Serving millions across India, expanding every month.</p>
              <div className="city-grid" style={{ display: "grid", gridTemplateColumns: "repeat(5,1fr)", gap: 12 }}>
                {["Hyderabad","Bangalore","Chennai","Pune","Mumbai","Delhi","Kolkata","Jaipur","Ahmedabad","Visakhapatnam"].map((city, i) => (
                  <div key={i} className="city-card" style={{ background: N700, borderRadius: 14, padding: "18px 10px", border: `1px solid ${BORDER}` }}>
                    <div style={{ width: 36, height: 36, borderRadius: 10, background: `linear-gradient(135deg,${N500},#0e2fa8)`, display: "flex", alignItems: "center", justifyContent: "center", margin: "0 auto 10px" }}>
                      <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="2.2"><path d="M3 21h18"/><rect x="3" y="8" width="7" height="13" rx="1"/><rect x="13" y="3" width="8" height="18" rx="1"/></svg>
                    </div>
                    <p style={{ fontSize: 11, fontWeight: 600, color: W70, margin: 0, fontFamily: "Space Grotesk,sans-serif" }}>{city}</p>
                  </div>
                ))}
              </div>
            </div>
          </div>
        </section>

        {/* JOIN AS PILOT CTA */}
        <section className="sec" style={{ background: N800, position: "relative", overflow: "hidden" }}>
          <div style={{ position: "absolute", inset: 0, backgroundImage: `radial-gradient(circle at 30% 50%, rgba(21,88,196,0.14) 0%, transparent 55%), radial-gradient(circle at 75% 20%, rgba(14,47,168,0.1) 0%, transparent 50%)`, pointerEvents: "none" }} />
          <div className="container" style={{ position: "relative" }}>
            <div ref={secJoin.ref} className={`reveal${secJoin.vis ? " vis" : ""}`}>
              <div style={{ borderRadius: 28, background: `linear-gradient(135deg,#0D1340 0%,#111A52 60%,#0e2fa8 100%)`, padding: "64px 56px", border: `1px solid rgba(21,88,196,0.3)`, position: "relative", overflow: "hidden" }}>
                <div style={{ position: "absolute", top: -80, right: -80, width: 320, height: 320, borderRadius: "50%", background: "rgba(21,88,196,0.1)" }} />
                <div style={{ position: "absolute", bottom: -60, left: "30%", width: 250, height: 250, borderRadius: "50%", background: "rgba(21,88,196,0.07)" }} />
                <div style={{ position: "relative", zIndex: 1, display: "grid", gridTemplateColumns: "1.2fr 0.8fr", gap: 56, alignItems: "center" }} className="hero-grid">
                  <div>
                    <div style={{ display: "inline-flex", alignItems: "center", gap: 8, background: "rgba(21,88,196,0.25)", border: "1px solid rgba(21,88,196,0.4)", borderRadius: 30, padding: "6px 14px", marginBottom: 22 }}>
                      <div style={{ width: 7, height: 7, borderRadius: "50%", background: "#4ade80", animation: "jago-badge 1.6s infinite" }} />
                      <span style={{ fontSize: 12, fontWeight: 600, color: "rgba(255,255,255,0.75)", fontFamily: "Space Grotesk,sans-serif" }}>Now accepting pilots in 50+ cities</span>
                    </div>
                    <h2 style={{ fontSize: "clamp(28px,3.5vw,52px)", fontWeight: 800, fontFamily: "Space Grotesk,sans-serif", letterSpacing: -1, lineHeight: 1.1, marginBottom: 18, color: W }}>
                      Your vehicle.<br />Your schedule.<br /><span style={{ color: "#60a5fa" }}>Your income.</span>
                    </h2>
                    <p style={{ fontSize: 16, color: W70, lineHeight: 1.8, maxWidth: 440, marginBottom: 36 }}>
                      Join thousands of pilots earning ₹2,500+ daily with Jago. Zero commission for 90 days, daily payouts, and full insurance on every trip.
                    </p>
                    <div style={{ display: "flex", gap: 14, flexWrap: "wrap" }}>
                      <a href="/auth" style={{ display: "inline-flex", alignItems: "center", gap: 8, padding: "14px 28px", borderRadius: 14, background: W, color: N800, textDecoration: "none", fontSize: 15, fontWeight: 700, fontFamily: "Space Grotesk,sans-serif", boxShadow: "0 4px 24px rgba(0,0,0,0.3)" }}>
                        Start Earning Today <ArrowR />
                      </a>
                      <a href="#download" style={{ display: "inline-flex", alignItems: "center", gap: 8, padding: "14px 24px", borderRadius: 14, border: `1px solid rgba(255,255,255,0.2)`, color: W70, textDecoration: "none", fontSize: 14, fontWeight: 600, fontFamily: "Space Grotesk,sans-serif" }}>
                        Get Pilot App
                      </a>
                    </div>
                  </div>
                  <div style={{ display: "flex", flexDirection: "column", gap: 14 }}>
                    {[
                      { icon: "₹", label: "₹2,500+", sub: "Average daily earnings" },
                      { icon: "0", label: "0% commission", sub: "For your first 90 days" },
                      { icon: "⚡", label: "Daily payouts", sub: "Withdraw anytime, same day" },
                      { icon: "🛡️", label: "Full insurance", sub: "Covered on every single trip" },
                    ].map((p, i) => (
                      <div key={i} style={{ display: "flex", alignItems: "center", gap: 16, background: "rgba(255,255,255,0.05)", borderRadius: 14, padding: "16px 20px", border: "1px solid rgba(255,255,255,0.08)" }}>
                        <div style={{ width: 42, height: 42, borderRadius: 12, background: `linear-gradient(135deg,${N500},#0e2fa8)`, display: "flex", alignItems: "center", justifyContent: "center", flexShrink: 0 }}>
                          <span style={{ fontSize: i === 0 ? 18 : 20, fontWeight: i === 0 ? 800 : 400, color: W, fontFamily: "Space Grotesk,sans-serif" }}>{p.icon}</span>
                        </div>
                        <div>
                          <p style={{ fontSize: 15, fontWeight: 700, color: W, margin: 0, fontFamily: "Space Grotesk,sans-serif" }}>{p.label}</p>
                          <p style={{ fontSize: 12, color: W40, margin: 0, marginTop: 2 }}>{p.sub}</p>
                        </div>
                      </div>
                    ))}
                  </div>
                </div>
              </div>
            </div>
          </div>
        </section>

        {/* DOWNLOAD CTA */}
        <section id="download" className="sec" style={{ background: N900 }}>
          <div className="container">
            <div ref={secDl.ref} className={`reveal${secDl.vis ? " vis" : ""}`}>
              <div style={{ borderRadius: 28, background: `linear-gradient(135deg,${N500} 0%,#0e2fa8 100%)`, padding: "72px 48px", textAlign: "center", position: "relative", overflow: "hidden" }}>
                <div style={{ position: "absolute", top: -60, right: -60, width: 260, height: 260, borderRadius: "50%", background: "rgba(255,255,255,0.05)" }} />
                <div style={{ position: "absolute", bottom: -50, left: -50, width: 220, height: 220, borderRadius: "50%", background: "rgba(255,255,255,0.03)" }} />
                <div style={{ position: "relative", zIndex: 1 }}>
                  <div style={{ width: 64, height: 64, borderRadius: 18, background: "rgba(255,255,255,0.15)", display: "flex", alignItems: "center", justifyContent: "center", margin: "0 auto 20px" }}>
                    <img src="/jago-logo.png" alt="JAGO" style={{ height: 42, width: "auto", objectFit: "contain" }} />
                  </div>
                  <h2 style={{ fontSize: "clamp(26px,3.5vw,46px)", fontWeight: 800, color: W, fontFamily: "Space Grotesk,sans-serif", marginBottom: 14, letterSpacing: -1 }}>Ready to ride with Jago?</h2>
                  <p style={{ fontSize: 16, color: "rgba(255,255,255,0.75)", marginBottom: 44, maxWidth: 440, margin: "0 auto 44px" }}>
                    Download now and get your first ride up to <strong style={{ color: W }}>?50 OFF</strong> with code{" "}
                    <strong style={{ background: "rgba(255,255,255,0.15)", padding: "2px 8px", borderRadius: 6 }}>JAGO50</strong>
                  </p>
                  <div style={{ display: "flex", gap: 14, justifyContent: "center", flexWrap: "wrap" }}>
                    {[{ label: "App Store", sub: "Download on", isApple: true }, { label: "Google Play", sub: "Get it on", isApple: false }].map(d => (
                      <a key={d.label} href="#" className="dl-btn" style={{ display: "flex", alignItems: "center", gap: 12, background: W, color: N800, borderRadius: 14, padding: "14px 26px", textDecoration: "none", fontFamily: "Space Grotesk,sans-serif" }}>
                        {d.isApple ? <AppleIcon /> : <PlayIcon />}
                        <div style={{ textAlign: "left" }}>
                          <div style={{ fontSize: 9.5, opacity: .5, textTransform: "uppercase", letterSpacing: 1 }}>{d.sub}</div>
                          <div style={{ fontSize: 16, fontWeight: 800, lineHeight: 1.2 }}>{d.label}</div>
                        </div>
                      </a>
                    ))}
                  </div>
                </div>
              </div>
            </div>
          </div>
        </section>

        {/* FOOTER */}
        <footer style={{ background: N900, padding: "64px 24px 28px", borderTop: `1px solid ${BORDER}` }}>
          <div className="container">
            <div className="footer-grid" style={{ display: "grid", gridTemplateColumns: "2fr 1fr 1fr 1fr", gap: 40, marginBottom: 52 }}>
              <div>
                <img src="/jago-logo.png" alt="JAGO" style={{ height: 36, width: "auto", objectFit: "contain", marginBottom: 18 }} />
                <p style={{ fontSize: 13, color: W40, lineHeight: 1.75, maxWidth: 240 }}>India's fastest-growing ride-hailing platform. Safe, fast, affordable � everywhere.</p>
              </div>
              {[
                { t: "Company", l: [{ label: "About Us", href: "/about-us" }, { label: "Contact Us", href: "/contact-us" }, { label: "Become a Pilot", href: "/auth" }, { label: "Careers", href: "#" }] },
                { t: "Services", l: [{ label: "Bike Taxi", href: "/#services" }, { label: "Auto Ride", href: "/#services" }, { label: "Cab Ride", href: "/#services" }, { label: "Parcel Delivery", href: "/#services" }] },
                { t: "Legal", l: [{ label: "Privacy Policy", href: "/privacy" }, { label: "Terms of Service", href: "/terms" }, { label: "Refund Policy", href: "/refund-policy" }, { label: "Cookie Policy", href: "/cookie-policy" }] },
              ].map(col => (
                <div key={col.t}>
                  <h4 style={{ fontSize: 11, fontWeight: 700, color: W40, marginBottom: 18, fontFamily: "Space Grotesk,sans-serif", textTransform: "uppercase", letterSpacing: 1.8 }}>{col.t}</h4>
                  {col.l.map(link => (
                    <a key={link.label} href={link.href} style={{ display: "block", fontSize: 13.5, color: W70, textDecoration: "none", marginBottom: 12, transition: "color .2s" }}
                      onMouseEnter={e => (e.currentTarget.style.color = W)}
                      onMouseLeave={e => (e.currentTarget.style.color = W70)}>
                      {link.label}
                    </a>
                  ))}
                </div>
              ))}
            </div>
            <div style={{ borderTop: `1px solid ${BORDER}`, paddingTop: 24, display: "flex", justifyContent: "space-between", alignItems: "center", flexWrap: "wrap", gap: 10 }}>
              <p style={{ fontSize: 12, color: W40, fontFamily: "Space Grotesk,sans-serif" }}>� 2026 Jago Technologies Pvt. Ltd. � MindWhile IT Solutions Product � All rights reserved.</p>
              <p style={{ fontSize: 12, color: W40, fontFamily: "Space Grotesk,sans-serif" }}>Made with ? in India</p>
            </div>
          </div>
        </footer>

      </div>
    </>
  );
}
