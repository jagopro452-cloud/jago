import { useState } from "react";

type AppTab = "driver" | "customer";

function PhoneFrame({ children, bg = "#060d1e" }: { children: React.ReactNode; bg?: string }) {
  return (
    <div style={{ display: "flex", justifyContent: "center" }}>
      <div style={{
        width: 230, minHeight: 460,
        background: bg,
        borderRadius: 42,
        border: "7px solid #1a1a2e",
        boxShadow: "0 50px 100px rgba(0,0,0,0.45), 0 0 0 1px rgba(255,255,255,0.06)",
        overflow: "hidden",
        position: "relative",
        flexShrink: 0,
      }}>
        {/* Dynamic Island */}
        <div style={{
          position: "absolute", top: 0, left: "50%", transform: "translateX(-50%)",
          width: 88, height: 24, background: "#000",
          borderRadius: "0 0 18px 18px", zIndex: 100,
          display: "flex", alignItems: "center", justifyContent: "center", gap: 5,
        }}>
          <div style={{ width: 7, height: 7, borderRadius: "50%", background: "#1e293b" }} />
          <div style={{ width: 3, height: 3, borderRadius: "50%", background: "#334155" }} />
        </div>
        <div style={{ position: "absolute", right: -8, top: 80, width: 4, height: 36, background: "#1e293b", borderRadius: "0 3px 3px 0" }} />
        <div style={{ position: "absolute", left: -8, top: 68, width: 4, height: 26, background: "#1e293b", borderRadius: "3px 0 0 3px" }} />
        <div style={{ position: "absolute", left: -8, top: 104, width: 4, height: 26, background: "#1e293b", borderRadius: "3px 0 0 3px" }} />
        <div style={{ paddingTop: 26, height: "100%" }}>{children}</div>
      </div>
    </div>
  );
}

function ScreenLabel({ title, sub }: { title: string; sub: string }) {
  return (
    <div style={{ textAlign: "center", marginTop: 14 }}>
      <div style={{ fontWeight: 700, fontSize: 12, color: "#1e293b" }}>{title}</div>
      <div style={{ fontSize: 10, color: "#94a3b8", marginTop: 2 }}>{sub}</div>
    </div>
  );
}

function CityMap({ dark = true }: { dark?: boolean }) {
  const roadColor = dark ? "rgba(255,255,255,0.04)" : "rgba(0,0,0,0.05)";
  const roadBold = dark ? "rgba(255,255,255,0.08)" : "rgba(0,0,0,0.09)";
  const bg = dark
    ? "radial-gradient(ellipse at 50% 40%, #0c2050 0%, #060d1e 80%)"
    : "linear-gradient(160deg, #dbeafe 0%, #eff6ff 100%)";
  return (
    <div style={{ position: "absolute", inset: 0, background: bg, overflow: "hidden" }}>
      <svg width="100%" height="100%" style={{ position: "absolute", inset: 0 }}>
        {[0,14,28,42,56,70,84,100].map(x => <line key={`v${x}`} x1={`${x}%`} y1="0" x2={`${x}%`} y2="100%" stroke={x % 28 === 0 ? roadBold : roadColor} strokeWidth={x % 28 === 0 ? 2 : 1}/>)}
        {[0,12,24,36,48,60,72,84,96].map(y => <line key={`h${y}`} x1="0" y1={`${y}%`} x2="100%" y2={`${y}%`} stroke={y % 24 === 0 ? roadBold : roadColor} strokeWidth={y % 24 === 0 ? 2 : 1}/>)}
        <line x1="0" y1="38%" x2="100%" y2="55%" stroke={roadBold} strokeWidth="2.5"/>
        <line x1="20%" y1="0" x2="35%" y2="100%" stroke={roadBold} strokeWidth="2"/>
        <line x1="65%" y1="0" x2="55%" y2="100%" stroke={roadBold} strokeWidth="2"/>
      </svg>
    </div>
  );
}

// ─── DRIVER APP SCREENS ────────────────────────────────────────────────────────

function DriverSplash() {
  return (
    <PhoneFrame bg="#060D1E">
      <div style={{ minHeight: 434, background: "#060D1E", display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", position: "relative", overflow: "hidden" }}>
        {/* Blue radial glow */}
        <div style={{ position: "absolute", top: -60, right: -60, width: 220, height: 220, borderRadius: "50%", background: "radial-gradient(circle, rgba(37,99,235,0.2) 0%, transparent 70%)" }} />
        <div style={{ position: "absolute", bottom: -80, left: -50, width: 180, height: 180, borderRadius: "50%", background: "radial-gradient(circle, rgba(30,58,138,0.12) 0%, transparent 70%)" }} />
        {/* Tech grid */}
        <svg style={{ position: "absolute", inset: 0, opacity: 0.04 }} width="100%" height="100%">
          {Array.from({length: 12}, (_,i) => <line key={`gv${i}`} x1={`${i*8.33}%`} y1="0" x2={`${i*8.33}%`} y2="100%" stroke="white" strokeWidth="0.5"/>)}
          {Array.from({length: 20}, (_,i) => <line key={`gh${i}`} x1="0" y1={`${i*5}%`} x2="100%" y2={`${i*5}%`} stroke="white" strokeWidth="0.5"/>)}
        </svg>

        <div style={{ flex: 2 }} />

        {/* Logo */}
        <div style={{ width: 90, height: 90, background: "#0D1B3E", borderRadius: 24, border: "1.5px solid rgba(37,99,235,0.3)", boxShadow: "0 0 40px rgba(37,99,235,0.3)", display: "flex", alignItems: "center", justifyContent: "center", flexDirection: "column" }}>
          <div style={{ fontSize: 18, fontWeight: 900, color: "white", letterSpacing: 2 }}>JAGO</div>
          <div style={{ fontSize: 8, fontWeight: 700, color: "#2563EB", letterSpacing: 5, marginTop: 1 }}>PILOT</div>
        </div>

        {/* Text */}
        <div style={{ marginTop: 24, textAlign: "center" }}>
          <div style={{ fontSize: 22, fontWeight: 900, color: "white", letterSpacing: 2 }}>JAGO <span style={{ color: "#2563EB" }}>PILOT</span></div>
          <div style={{ fontSize: 10, color: "rgba(255,255,255,0.4)", marginTop: 4, letterSpacing: 1.5 }}>Drive Smarter.</div>
        </div>

        <div style={{ flex: 3 }} />

        {/* Loader */}
        <div style={{ marginBottom: 16, textAlign: "center" }}>
          <div style={{ width: 16, height: 16, borderRadius: "50%", border: "1.5px solid rgba(37,99,235,0.4)", borderTop: "1.5px solid #2563EB", margin: "0 auto 10px", animation: "spin 1s linear infinite" }} />
          <div style={{ fontSize: 8, color: "rgba(255,255,255,0.2)" }}>MindWhile IT Solutions</div>
        </div>
      </div>
    </PhoneFrame>
  );
}

function DriverLogin() {
  return (
    <PhoneFrame bg="#060D1E">
      <div style={{ minHeight: 434, background: "#060D1E", position: "relative", overflow: "hidden" }}>
        <div style={{ position: "absolute", top: -40, right: -40, width: 200, height: 200, borderRadius: "50%", background: "radial-gradient(circle, rgba(37,99,235,0.18) 0%, transparent 70%)" }} />

        {/* Logo badge */}
        <div style={{ padding: "18px 18px 0" }}>
          <div style={{ display: "inline-flex", alignItems: "center", gap: 5, background: "rgba(37,99,235,0.15)", borderRadius: 8, border: "1px solid rgba(37,99,235,0.3)", padding: "4px 10px" }}>
            <div style={{ fontSize: 11, fontWeight: 900, color: "white" }}>JAGO</div>
            <div style={{ fontSize: 11, fontWeight: 900, color: "#2563EB" }}>PILOT</div>
          </div>
        </div>

        {/* Heading */}
        <div style={{ padding: "20px 18px 0" }}>
          <div style={{ fontSize: 22, fontWeight: 900, color: "white", lineHeight: 1.2 }}>Pilot గా<br />Login చేయండి 🏍️</div>
          <div style={{ fontSize: 10, color: "rgba(255,255,255,0.4)", marginTop: 5 }}>ప్రతి trip తో earn చేయండి</div>
        </div>

        {/* Phone input */}
        <div style={{ padding: "18px 18px 0" }}>
          <div style={{ fontSize: 9, color: "rgba(255,255,255,0.4)", marginBottom: 6, fontWeight: 700 }}>Mobile Number</div>
          <div style={{ background: "#0D1B3E", borderRadius: 14, border: "1px solid rgba(255,255,255,0.07)", display: "flex", alignItems: "center", overflow: "hidden" }}>
            <div style={{ padding: "12px 12px", borderRight: "1px solid rgba(255,255,255,0.07)", display: "flex", alignItems: "center", gap: 5 }}>
              <span style={{ fontSize: 14 }}>🇮🇳</span>
              <span style={{ fontSize: 12, fontWeight: 700, color: "white" }}>+91</span>
            </div>
            <div style={{ padding: "12px 12px", fontSize: 14, fontWeight: 700, color: "rgba(255,255,255,0.25)", letterSpacing: 2 }}>98765 43210</div>
          </div>
        </div>

        {/* Button */}
        <div style={{ padding: "14px 18px 0" }}>
          <div style={{ background: "#2563EB", borderRadius: 14, padding: "13px 0", textAlign: "center", color: "white", fontSize: 13, fontWeight: 800, boxShadow: "0 6px 20px rgba(37,99,235,0.35)" }}>Get OTP →</div>
        </div>

        {/* Privacy */}
        <div style={{ textAlign: "center", marginTop: 10, fontSize: 9, color: "rgba(255,255,255,0.2)" }}>🛡 Secure & Verified Platform</div>

        {/* Earnings banner */}
        <div style={{ margin: "14px 18px 0", background: "#0D1B3E", borderRadius: 14, border: "1px solid rgba(37,99,235,0.15)", padding: "12px 14px", display: "flex", alignItems: "center", gap: 10 }}>
          <div style={{ width: 36, height: 36, background: "rgba(37,99,235,0.15)", borderRadius: 10, display: "flex", alignItems: "center", justifyContent: "center", fontSize: 16 }}>📈</div>
          <div>
            <div style={{ fontSize: 13, fontWeight: 800, color: "white" }}>₹800–₹1500/day</div>
            <div style={{ fontSize: 8, color: "rgba(255,255,255,0.35)", marginTop: 2 }}>Average Pilot Earnings</div>
          </div>
          <div style={{ marginLeft: "auto", fontSize: 10, color: "rgba(255,255,255,0.2)" }}>›</div>
        </div>
      </div>
    </PhoneFrame>
  );
}

function DriverHome() {
  return (
    <PhoneFrame bg="#060D1E">
      <div style={{ minHeight: 434, background: "#060D1E", position: "relative", overflow: "hidden", display: "flex", flexDirection: "column" }}>
        <CityMap dark />

        {/* Driver pin */}
        <div style={{ position: "absolute", top: "40%", left: "44%", zIndex: 2 }}>
          <div style={{ width: 28, height: 28, background: "linear-gradient(135deg,#2563eb,#1d4ed8)", borderRadius: "50%", display: "flex", alignItems: "center", justifyContent: "center", boxShadow: "0 0 0 8px rgba(37,99,235,0.15),0 0 0 16px rgba(37,99,235,0.06)", fontSize: 13 }}>🏍</div>
        </div>

        {/* Top bar */}
        <div style={{ position: "relative", zIndex: 3, padding: "8px 12px" }}>
          <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
            {/* Menu btn */}
            <div style={{ width: 36, height: 36, background: "#060D1E", borderRadius: 12, boxShadow: "0 3px 10px rgba(0,0,0,0.35)", display: "flex", alignItems: "center", justifyContent: "center" }}>
              <div style={{ display: "flex", flexDirection: "column", gap: 3 }}>
                {[0,1,2].map(i => <div key={i} style={{ width: 12, height: 1.5, background: "rgba(255,255,255,0.75)", borderRadius: 1 }} />)}
              </div>
            </div>
            {/* Status pill */}
            <div style={{ flex: 1, background: "#060D1E", borderRadius: 12, padding: "10px 12px", boxShadow: "0 3px 10px rgba(0,0,0,0.35)", display: "flex", alignItems: "center", gap: 8 }}>
              <div style={{ width: 8, height: 8, borderRadius: "50%", background: "#16A34A", boxShadow: "0 0 8px rgba(22,163,74,0.6)" }} />
              <div style={{ fontSize: 11, fontWeight: 600, color: "white" }}>Online — Trips కోసం Ready</div>
            </div>
            {/* Location btn */}
            <div style={{ width: 36, height: 36, background: "#060D1E", borderRadius: 12, boxShadow: "0 3px 10px rgba(0,0,0,0.35)", display: "flex", alignItems: "center", justifyContent: "center", fontSize: 14 }}>📍</div>
          </div>
        </div>

        <div style={{ flex: 1 }} />

        {/* Bottom panel */}
        <div style={{ position: "relative", zIndex: 3, background: "#060D1E", borderRadius: "22px 22px 0 0", padding: "8px 14px 16px", boxShadow: "0 -4px 24px rgba(0,0,0,0.5)" }}>
          <div style={{ width: 30, height: 3, background: "rgba(255,255,255,0.1)", borderRadius: 2, margin: "4px auto 12px" }} />

          {/* Stats row */}
          <div style={{ display: "flex", gap: 8, marginBottom: 12 }}>
            {[
              { l: "Today Earnings", v: "₹1,240", ic: "💰", col: "#10B981" },
              { l: "Trips Today", v: "8", ic: "🛺", col: "#2563EB" },
              { l: "Wallet", v: "₹340", ic: "👛", col: "#F59E0B" },
            ].map((s, i) => (
              <div key={i} style={{ flex: 1, background: `${s.col}12`, borderRadius: 12, border: `1px solid ${s.col}22`, padding: "10px 6px", textAlign: "center" }}>
                <div style={{ width: 26, height: 26, borderRadius: "50%", background: `${s.col}20`, display: "flex", alignItems: "center", justifyContent: "center", margin: "0 auto 5px", fontSize: 12 }}>{s.ic}</div>
                <div style={{ fontSize: 12, fontWeight: 800, color: "white" }}>{s.v}</div>
                <div style={{ fontSize: 7, color: "rgba(255,255,255,0.35)", marginTop: 1 }}>{s.l}</div>
              </div>
            ))}
          </div>

          {/* Toggle button */}
          <div style={{ background: "linear-gradient(135deg,#16A34A,#15803D)", borderRadius: 14, padding: "14px 0", textAlign: "center", color: "white", fontSize: 13, fontWeight: 800, boxShadow: "0 5px 16px rgba(22,163,74,0.35)", marginBottom: 10 }}>⚡ Online — Trip కోసం Ready ✓</div>

          {/* Action chips */}
          <div style={{ display: "flex", gap: 8 }}>
            {[
              { l: "Break", ic: "☕", c: "#F59E0B" },
              { l: "Wallet", ic: "💳", c: "#10B981" },
              { l: "Trips", ic: "📋", c: "#2563EB" },
            ].map((a, i) => (
              <div key={i} style={{ flex: 1, background: `${a.c}10`, borderRadius: 10, border: `1px solid ${a.c}20`, padding: "8px 0", textAlign: "center" }}>
                <div style={{ fontSize: 14 }}>{a.ic}</div>
                <div style={{ fontSize: 9, fontWeight: 700, color: a.c, marginTop: 3 }}>{a.l}</div>
              </div>
            ))}
          </div>
        </div>
      </div>
    </PhoneFrame>
  );
}

function DriverIncomingTrip() {
  return (
    <PhoneFrame bg="#060D1E">
      <div style={{ minHeight: 434, background: "#060D1E", position: "relative", overflow: "hidden", display: "flex", flexDirection: "column" }}>
        <CityMap dark />
        <div style={{ position: "absolute", inset: 0, background: "rgba(0,0,0,0.55)", zIndex: 1 }} />

        <div style={{ flex: 1, zIndex: 2 }} />

        {/* Trip card */}
        <div style={{ position: "relative", zIndex: 3, margin: "0 10px 10px", background: "#060D1E", borderRadius: 24, border: "1px solid rgba(37,99,235,0.2)", boxShadow: "0 0 30px rgba(37,99,235,0.2)" }}>

          {/* Top banner */}
          <div style={{ background: "linear-gradient(135deg, rgba(37,99,235,0.25), rgba(37,99,235,0.1))", borderRadius: "22px 22px 0 0", padding: "14px 16px" }}>
            <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between" }}>
              <div>
                <div style={{ fontSize: 16, fontWeight: 900, color: "white" }}>New Trip Request!</div>
                <div style={{ fontSize: 9, color: "rgba(255,255,255,0.45)", marginTop: 2 }}>Accept karna cheyyi — expire avutundi!</div>
              </div>
              {/* Countdown ring */}
              <div style={{ width: 46, height: 46, borderRadius: "50%", border: "3px solid rgba(37,99,235,0.3)", display: "flex", alignItems: "center", justifyContent: "center", position: "relative" }}>
                <div style={{ position: "absolute", inset: 0, borderRadius: "50%", border: "3px solid #2563EB", borderRight: "3px solid transparent", borderBottom: "3px solid transparent", borderLeft: "3px solid transparent" }} />
                <div style={{ fontSize: 13, fontWeight: 900, color: "white" }}>22</div>
              </div>
            </div>
          </div>

          {/* Address card */}
          <div style={{ margin: "10px 14px", background: "#0D1B3E", borderRadius: 14, padding: "11px 12px" }}>
            <div style={{ display: "flex", alignItems: "center", gap: 8, marginBottom: 6 }}>
              <div style={{ width: 8, height: 8, borderRadius: "50%", background: "#2563EB" }} />
              <div style={{ fontSize: 10, fontWeight: 600, color: "white" }}>MGBS Bus Stand, Hyderabad</div>
            </div>
            <div style={{ marginLeft: 3, width: 2, height: 12, background: "rgba(255,255,255,0.1)", marginBottom: 6 }} />
            <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
              <div style={{ width: 8, height: 8, borderRadius: 2, background: "#F59E0B" }} />
              <div style={{ fontSize: 10, fontWeight: 600, color: "white" }}>Banjara Hills Road No. 12</div>
            </div>
          </div>

          {/* Stats */}
          <div style={{ display: "flex", margin: "0 14px 12px", gap: 6 }}>
            {[
              { l: "Distance", v: "7.2 km", c: "#10B981" },
              { l: "Fare", v: "₹185", c: "#F59E0B" },
              { l: "ETA", v: "~8 min", c: "#2563EB" },
            ].map((s, i) => (
              <div key={i} style={{ flex: 1, background: `${s.c}10`, borderRadius: 10, padding: "8px 4px", textAlign: "center", border: `1px solid ${s.c}20` }}>
                <div style={{ fontSize: 12, fontWeight: 800, color: s.c }}>{s.v}</div>
                <div style={{ fontSize: 7, color: "rgba(255,255,255,0.35)", marginTop: 2 }}>{s.l}</div>
              </div>
            ))}
          </div>

          {/* Buttons */}
          <div style={{ display: "flex", gap: 8, margin: "0 14px 16px" }}>
            <div style={{ flex: 1, background: "rgba(248,113,113,0.08)", borderRadius: 14, padding: "12px 0", textAlign: "center", border: "1px solid rgba(248,113,113,0.2)", fontSize: 12, fontWeight: 700, color: "#F87171" }}>✕ Reject</div>
            <div style={{ flex: 2, background: "linear-gradient(135deg,#16A34A,#15803D)", borderRadius: 14, padding: "12px 0", textAlign: "center", fontSize: 13, fontWeight: 900, color: "white", boxShadow: "0 5px 14px rgba(22,163,74,0.35)" }}>✓ Accept Trip</div>
          </div>
        </div>
      </div>
    </PhoneFrame>
  );
}

function DriverTrip() {
  return (
    <PhoneFrame bg="#060D1E">
      <div style={{ minHeight: 434, background: "#060D1E", position: "relative", overflow: "hidden", display: "flex", flexDirection: "column" }}>
        <CityMap dark />

        {/* Route */}
        <div style={{ position: "absolute", top: "25%", left: "40%", zIndex: 2 }}>
          <div style={{ width: 8, height: 8, background: "#16A34A", borderRadius: "50%", boxShadow: "0 0 10px #16A34A" }} />
          <div style={{ width: 2, height: 50, background: "linear-gradient(180deg,#16A34A,#2563EB)", marginLeft: 3 }} />
          <div style={{ width: 20, height: 20, background: "linear-gradient(135deg,#2563EB,#1d4ed8)", borderRadius: "50%", fontSize: 10, display: "flex", alignItems: "center", justifyContent: "center", boxShadow: "0 0 0 5px rgba(37,99,235,0.2)", marginLeft: -4 }}>🏍</div>
          <div style={{ width: 2, height: 35, background: "linear-gradient(180deg,#2563EB,#60A5FA)", marginLeft: 3 }} />
          <div style={{ width: 8, height: 8, background: "#EF4444", borderRadius: "50%", boxShadow: "0 0 10px #EF4444" }} />
        </div>

        <div style={{ flex: 1 }} />

        {/* Bottom panel */}
        <div style={{ position: "relative", zIndex: 3, background: "#060D1E", borderRadius: "22px 22px 0 0", padding: "8px 14px 20px", boxShadow: "0 -4px 24px rgba(0,0,0,0.5)" }}>
          <div style={{ width: 30, height: 3, background: "rgba(255,255,255,0.1)", borderRadius: 2, margin: "4px auto 12px" }} />

          {/* Status */}
          <div style={{ background: "rgba(22,163,74,0.1)", borderRadius: 14, border: "1px solid rgba(22,163,74,0.2)", padding: "10px 12px", display: "flex", alignItems: "center", gap: 10, marginBottom: 12 }}>
            <div style={{ width: 34, height: 34, background: "rgba(22,163,74,0.15)", borderRadius: 10, display: "flex", alignItems: "center", justifyContent: "center", fontSize: 16 }}>🚀</div>
            <div>
              <div style={{ fontSize: 13, fontWeight: 800, color: "#16A34A" }}>Trip Progress lo undi 🚀</div>
              <div style={{ fontSize: 9, color: "rgba(255,255,255,0.35)", marginTop: 2 }}>Banjara Hills Rd No. 12</div>
            </div>
          </div>

          {/* Customer card */}
          <div style={{ background: "#0D1B3E", borderRadius: 14, padding: "10px 12px", display: "flex", alignItems: "center", gap: 10, marginBottom: 12, border: "1px solid rgba(255,255,255,0.06)" }}>
            <div style={{ width: 36, height: 36, background: "rgba(37,99,235,0.2)", borderRadius: "50%", display: "flex", alignItems: "center", justifyContent: "center", fontSize: 14, fontWeight: 800, color: "white" }}>A</div>
            <div style={{ flex: 1 }}>
              <div style={{ fontSize: 12, fontWeight: 700, color: "white" }}>Arjun Reddy</div>
              <div style={{ display: "flex", gap: 5, marginTop: 4 }}>
                <div style={{ fontSize: 9, color: "#10B981", fontWeight: 700, background: "rgba(16,185,129,0.12)", borderRadius: 5, padding: "2px 6px" }}>₹185</div>
                <div style={{ fontSize: 9, color: "#2563EB", fontWeight: 700, background: "rgba(37,99,235,0.12)", borderRadius: 5, padding: "2px 6px" }}>7.2 km</div>
              </div>
            </div>
            <div style={{ width: 32, height: 32, background: "rgba(37,99,235,0.15)", borderRadius: 10, display: "flex", alignItems: "center", justifyContent: "center", fontSize: 14 }}>📞</div>
          </div>

          {/* Complete btn */}
          <div style={{ background: "linear-gradient(135deg,#16A34A,#15803D)", borderRadius: 14, padding: "13px 0", textAlign: "center", fontSize: 13, fontWeight: 800, color: "white", boxShadow: "0 5px 16px rgba(22,163,74,0.35)", marginBottom: 8 }}>🏁 Complete Trip ✓</div>

          {/* Secondary */}
          <div style={{ display: "flex", justifyContent: "center", gap: 10 }}>
            <div style={{ fontSize: 10, color: "#2563EB", fontWeight: 700 }}>📞 Call Customer</div>
            <div style={{ width: 1, height: 14, background: "rgba(255,255,255,0.1)" }} />
            <div style={{ fontSize: 10, color: "#F87171", fontWeight: 700 }}>✕ Cancel</div>
          </div>
        </div>
      </div>
    </PhoneFrame>
  );
}

// ─── CUSTOMER APP SCREENS ──────────────────────────────────────────────────────

function CustomerSplash() {
  return (
    <PhoneFrame bg="#1244A2">
      <div style={{ minHeight: 434, background: "linear-gradient(145deg, #0A2040, #1244A2, #1E6DE5)", display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", position: "relative", overflow: "hidden" }}>
        {/* White circle blobs */}
        <div style={{ position: "absolute", top: "-30%", right: "-25%", width: 220, height: 220, borderRadius: "50%", background: "rgba(255,255,255,0.08)" }} />
        <div style={{ position: "absolute", bottom: "-35%", left: "-25%", width: 200, height: 200, borderRadius: "50%", background: "rgba(255,255,255,0.05)" }} />

        <div style={{ flex: 2 }} />

        {/* Logo box */}
        <div style={{ width: 90, height: 90, background: "white", borderRadius: 26, boxShadow: "0 12px 40px rgba(0,0,0,0.2)", display: "flex", alignItems: "center", justifyContent: "center" }}>
          <div style={{ fontSize: 18, fontWeight: 900, color: "#1E6DE5", letterSpacing: 2 }}>JAGO</div>
        </div>

        {/* Text */}
        <div style={{ marginTop: 24, textAlign: "center" }}>
          <div style={{ fontSize: 30, fontWeight: 900, color: "white", letterSpacing: 8 }}>JAGO</div>
          <div style={{ fontSize: 10, color: "rgba(255,255,255,0.55)", marginTop: 5, letterSpacing: 2 }}>Move Smarter.</div>
        </div>

        <div style={{ flex: 3 }} />

        <div style={{ marginBottom: 18, textAlign: "center" }}>
          <div style={{ width: 16, height: 16, borderRadius: "50%", border: "1.5px solid rgba(255,255,255,0.3)", borderTop: "1.5px solid white", margin: "0 auto 10px" }} />
          <div style={{ fontSize: 8, color: "rgba(255,255,255,0.25)" }}>MindWhile IT Solutions</div>
        </div>
      </div>
    </PhoneFrame>
  );
}

function CustomerLogin() {
  return (
    <PhoneFrame bg="white">
      <div style={{ minHeight: 434, background: "white" }}>
        {/* Blue gradient header */}
        <div style={{ background: "linear-gradient(135deg, #1244A2, #1E6DE5, #4B9EFF)", padding: "16px 20px 28px", borderRadius: "0 0 28px 28px" }}>
          <div style={{ display: "inline-flex", background: "rgba(255,255,255,0.18)", borderRadius: 8, padding: "4px 10px", marginBottom: 18 }}>
            <span style={{ fontSize: 13, fontWeight: 900, color: "white", letterSpacing: 2 }}>JAGO</span>
          </div>
          <div style={{ fontSize: 22, fontWeight: 800, color: "white", lineHeight: 1.2 }}>Welcome to<br />JAGO 👋</div>
          <div style={{ fontSize: 9, color: "rgba(255,255,255,0.7)", marginTop: 6 }}>Safe, affordable rides — ఎక్కడైనా</div>
        </div>

        {/* Form */}
        <div style={{ padding: "18px 18px 0" }}>
          <div style={{ fontSize: 10, fontWeight: 700, color: "#374151", marginBottom: 7 }}>Mobile Number</div>
          <div style={{ background: "#F8FAFF", borderRadius: 14, border: "1.5px solid #DDE4F5", display: "flex", alignItems: "center", overflow: "hidden", marginBottom: 14 }}>
            <div style={{ padding: "11px 12px", borderRight: "1.5px solid #DDE4F5", display: "flex", alignItems: "center", gap: 4 }}>
              <span style={{ fontSize: 14 }}>🇮🇳</span>
              <span style={{ fontSize: 12, fontWeight: 700, color: "#111827" }}>+91</span>
            </div>
            <div style={{ padding: "11px 12px", fontSize: 14, fontWeight: 700, color: "rgba(0,0,0,0.2)", letterSpacing: 2 }}>98765 43210</div>
          </div>
          <div style={{ background: "#1E6DE5", borderRadius: 14, padding: "12px 0", textAlign: "center", color: "white", fontSize: 13, fontWeight: 800, boxShadow: "0 5px 16px rgba(30,109,229,0.3)", marginBottom: 12 }}>Get OTP →</div>
          <div style={{ textAlign: "center", fontSize: 9, color: "#9CA3AF" }}>🛡 Your data is secure & private</div>

          {/* Feature chips */}
          <div style={{ display: "flex", gap: 8, marginTop: 20 }}>
            {[
              { ic: "⚡", l: "Quick Rides" },
              { ic: "✅", l: "Verified Pilots" },
              { ic: "💳", l: "Easy Pay" },
            ].map((f, i) => (
              <div key={i} style={{ flex: 1, background: "#F8FAFF", borderRadius: 12, border: "1px solid #E8EEFF", padding: "10px 4px", textAlign: "center" }}>
                <div style={{ fontSize: 16 }}>{f.ic}</div>
                <div style={{ fontSize: 8, fontWeight: 600, color: "#374151", marginTop: 4 }}>{f.l}</div>
              </div>
            ))}
          </div>
        </div>
      </div>
    </PhoneFrame>
  );
}

function CustomerHome() {
  return (
    <PhoneFrame bg="white">
      <div style={{ minHeight: 434, background: "white", position: "relative", overflow: "hidden", display: "flex", flexDirection: "column" }}>
        <CityMap dark={false} />

        {/* Top bar */}
        <div style={{ position: "relative", zIndex: 3, padding: "8px 12px" }}>
          <div style={{ display: "flex", gap: 8, alignItems: "center" }}>
            <div style={{ width: 36, height: 36, background: "white", borderRadius: 12, boxShadow: "0 3px 10px rgba(0,0,0,0.12)", display: "flex", alignItems: "center", justifyContent: "center" }}>
              <div style={{ display: "flex", flexDirection: "column", gap: 3 }}>
                {[0,1,2].map(i => <div key={i} style={{ width: 12, height: 1.5, background: "#111827", borderRadius: 1 }} />)}
              </div>
            </div>
            <div style={{ flex: 1, background: "white", borderRadius: 12, padding: "9px 12px", boxShadow: "0 3px 10px rgba(0,0,0,0.12)", display: "flex", alignItems: "center", gap: 8 }}>
              <div style={{ width: 22, height: 22, borderRadius: "50%", background: "rgba(30,109,229,0.12)", display: "flex", alignItems: "center", justifyContent: "center", fontSize: 10, fontWeight: 800, color: "#1E6DE5" }}>A</div>
              <div style={{ fontSize: 12, fontWeight: 700, color: "#111827" }}>Hi, Arjun 👋</div>
              <div style={{ marginLeft: "auto", fontSize: 15 }}>🔔</div>
            </div>
          </div>
        </div>

        <div style={{ flex: 1 }} />

        {/* Bottom sheet */}
        <div style={{ position: "relative", zIndex: 3, background: "white", borderRadius: "26px 26px 0 0", boxShadow: "0 -4px 20px rgba(0,0,0,0.1)", padding: "8px 14px 16px" }}>
          <div style={{ width: 30, height: 3, background: "#E5E7EB", borderRadius: 2, margin: "4px auto 12px" }} />
          <div style={{ fontSize: 14, fontWeight: 800, color: "#111827", marginBottom: 12 }}>Where are you going?</div>

          {/* Location card */}
          <div style={{ background: "#F8FAFF", borderRadius: 14, border: "1px solid #E5EAFF", marginBottom: 12 }}>
            <div style={{ padding: "10px 12px", display: "flex", alignItems: "center", gap: 10 }}>
              <div style={{ width: 8, height: 8, borderRadius: "50%", border: "2px solid #1E6DE5" }} />
              <div style={{ fontSize: 10, color: "#1E6DE5", fontWeight: 600 }}>Current Location</div>
            </div>
            <div style={{ height: 1, background: "rgba(0,0,0,0.04)", marginLeft: 12 }} />
            <div style={{ padding: "10px 12px", display: "flex", alignItems: "center", gap: 10 }}>
              <div style={{ width: 8, height: 8, borderRadius: "50%", background: "#E53935" }} />
              <div style={{ fontSize: 10, color: "#9CA3AF" }}>Where to?</div>
              <div style={{ marginLeft: "auto", width: 20, height: 20, background: "rgba(30,109,229,0.08)", borderRadius: "50%", display: "flex", alignItems: "center", justifyContent: "center", fontSize: 10 }}>🔍</div>
            </div>
          </div>

          {/* Vehicle cards */}
          <div style={{ fontSize: 9, fontWeight: 700, color: "#9CA3AF", marginBottom: 8, textTransform: "uppercase", letterSpacing: 0.5 }}>Choose Vehicle</div>
          <div style={{ display: "flex", gap: 8, marginBottom: 12 }}>
            {[
              { n: "Bike", f: "₹20+", ic: "🏍", sel: true },
              { n: "Auto", f: "₹30+", ic: "🛺", sel: false },
              { n: "Parcel", f: "₹25+", ic: "📦", sel: false },
              { n: "Cargo", f: "₹200+", ic: "🚛", sel: false },
            ].map((v, i) => (
              <div key={i} style={{ flex: 1, background: v.sel ? "#1E6DE5" : "white", borderRadius: 12, border: `${v.sel ? 0 : 1.5}px solid ${v.sel ? "#1E6DE5" : "#E5E9F5"}`, padding: "10px 4px", textAlign: "center", boxShadow: v.sel ? "0 4px 12px rgba(30,109,229,0.3)" : "none" }}>
                <div style={{ fontSize: 16 }}>{v.ic}</div>
                <div style={{ fontSize: 8, fontWeight: 700, color: v.sel ? "white" : "#111827", marginTop: 4 }}>{v.n}</div>
                <div style={{ fontSize: 8, fontWeight: 800, color: v.sel ? "rgba(255,255,255,0.85)" : "#1E6DE5", marginTop: 2 }}>{v.f}</div>
              </div>
            ))}
          </div>

          {/* Book button */}
          <div style={{ background: "#1E6DE5", borderRadius: 14, padding: "13px 0", textAlign: "center", color: "white", fontSize: 13, fontWeight: 800, boxShadow: "0 5px 16px rgba(30,109,229,0.3)" }}>🗺 Find Ride</div>
        </div>
      </div>
    </PhoneFrame>
  );
}

function CustomerTracking() {
  return (
    <PhoneFrame bg="white">
      <div style={{ minHeight: 434, background: "white", position: "relative", overflow: "hidden", display: "flex", flexDirection: "column" }}>
        <CityMap dark={false} />

        <div style={{ flex: 1 }} />

        {/* Bottom sheet */}
        <div style={{ position: "relative", zIndex: 3, background: "white", borderRadius: "26px 26px 0 0", boxShadow: "0 -4px 20px rgba(0,0,0,0.1)", padding: "8px 14px 18px" }}>
          <div style={{ width: 30, height: 3, background: "#E5E7EB", borderRadius: 2, margin: "4px auto 12px" }} />

          {/* Status */}
          <div style={{ background: "rgba(30,109,229,0.07)", borderRadius: 14, border: "1px solid rgba(30,109,229,0.15)", padding: "10px 12px", display: "flex", alignItems: "center", gap: 10, marginBottom: 12 }}>
            <div style={{ width: 36, height: 36, borderRadius: "50%", background: "rgba(30,109,229,0.1)", display: "flex", alignItems: "center", justifyContent: "center", fontSize: 16 }}>🏍</div>
            <div>
              <div style={{ fontSize: 12, fontWeight: 800, color: "#1E6DE5" }}>Pilot vachestunnadu 🏍️</div>
              <div style={{ fontSize: 9, color: "#9CA3AF", marginTop: 2 }}>~4 min away</div>
            </div>
          </div>

          {/* Driver card */}
          <div style={{ background: "#F8FAFF", borderRadius: 14, border: "1px solid #E5EAFF", padding: "10px 12px", display: "flex", alignItems: "center", gap: 10, marginBottom: 12 }}>
            <div style={{ width: 36, height: 36, background: "#1E6DE5", borderRadius: "50%", display: "flex", alignItems: "center", justifyContent: "center", fontSize: 14, fontWeight: 800, color: "white" }}>A</div>
            <div style={{ flex: 1 }}>
              <div style={{ fontSize: 12, fontWeight: 800, color: "#111827" }}>Arjun Pilot</div>
              <div style={{ display: "flex", alignItems: "center", gap: 2, marginTop: 2 }}>
                <span style={{ fontSize: 10 }}>⭐</span>
                <span style={{ fontSize: 10, color: "#6B7280", fontWeight: 600 }}>4.9</span>
              </div>
            </div>
            <div style={{ width: 32, height: 32, background: "rgba(30,109,229,0.1)", borderRadius: 10, display: "flex", alignItems: "center", justifyContent: "center", fontSize: 14 }}>📞</div>
          </div>

          {/* OTP Box */}
          <div style={{ background: "#FFFBEB", borderRadius: 14, border: "1.5px solid rgba(245,158,11,0.3)", padding: "10px 12px", display: "flex", alignItems: "center", gap: 10, marginBottom: 12 }}>
            <div style={{ width: 28, height: 28, background: "rgba(245,158,11,0.12)", borderRadius: 8, display: "flex", alignItems: "center", justifyContent: "center", fontSize: 13 }}>🔒</div>
            <div>
              <div style={{ fontSize: 8, fontWeight: 700, color: "orange", marginBottom: 2 }}>Share this OTP with Pilot</div>
              <div style={{ fontSize: 22, fontWeight: 900, color: "#111827", letterSpacing: 8 }}>4829</div>
            </div>
            <div style={{ marginLeft: "auto", fontSize: 12 }}>📋</div>
          </div>

          {/* Fare chips */}
          <div style={{ display: "flex", gap: 6, marginBottom: 12 }}>
            {[
              { l: "₹85", ic: "💰", c: "#1E6DE5" },
              { l: "3.2 km", ic: "🗺", c: "#6B7280" },
              { l: "Bike", ic: "🏍", c: "#6B7280" },
            ].map((c, i) => (
              <div key={i} style={{ background: `rgba(0,0,0,0.04)`, borderRadius: 8, padding: "5px 10px", display: "flex", alignItems: "center", gap: 4 }}>
                <span style={{ fontSize: 10 }}>{c.ic}</span>
                <span style={{ fontSize: 10, fontWeight: 700, color: c.c }}>{c.l}</span>
              </div>
            ))}
          </div>

          {/* Cancel btn */}
          <div style={{ border: "1px solid rgba(239,68,68,0.3)", borderRadius: 12, padding: "10px 0", textAlign: "center", fontSize: 11, fontWeight: 700, color: "#EF4444" }}>✕ Cancel Ride</div>
        </div>
      </div>
    </PhoneFrame>
  );
}

// ─── MAIN PAGE ─────────────────────────────────────────────────────────────────

export default function AppDesignPage() {
  const [activeApp, setActiveApp] = useState<AppTab>("customer");

  const customerScreens = [
    { component: <CustomerSplash />, title: "Splash Screen", sub: "Animated Blue Gradient" },
    { component: <CustomerLogin />, title: "Login Screen", sub: "Phone + OTP" },
    { component: <CustomerHome />, title: "Home Screen", sub: "Map + Vehicle Select" },
    { component: <CustomerTracking />, title: "Tracking Screen", sub: "Live Driver Card" },
  ];

  const driverScreens = [
    { component: <DriverSplash />, title: "Splash Screen", sub: "Dark Navy + Grid" },
    { component: <DriverLogin />, title: "Login Screen", sub: "Dark + Earnings Banner" },
    { component: <DriverHome />, title: "Home Screen", sub: "Stats + Online Toggle" },
    { component: <DriverIncomingTrip />, title: "Incoming Trip", sub: "Countdown + Accept" },
    { component: <DriverTrip />, title: "On Trip Screen", sub: "Customer Card + Actions" },
  ];

  const isDriver = activeApp === "driver";
  const screens = isDriver ? driverScreens : customerScreens;
  const accent = isDriver ? "#2563EB" : "#1E6DE5";
  const palette = isDriver
    ? [{ c: "#060D1E", n: "Background" }, { c: "#0D1B3E", n: "Surface" }, { c: "#2563EB", n: "Blue" }, { c: "#16A34A", n: "Online" }, { c: "#F59E0B", n: "Amber" }, { c: "#F87171", n: "Red" }]
    : [{ c: "#1E6DE5", n: "Blue" }, { c: "#1244A2", n: "Dark Blue" }, { c: "#F8FAFF", n: "Surface" }, { c: "#111827", n: "Text" }, { c: "#E53935", n: "Dest" }, { c: "#F59E0B", n: "OTP" }];

  return (
    <div style={{ padding: 20, background: "#f1f5f9", minHeight: "100vh" }}>
      {/* Header */}
      <div style={{ background: "white", borderRadius: 18, padding: "20px 24px", boxShadow: "0 2px 12px rgba(0,0,0,0.06)", border: "1px solid #f1f5f9", marginBottom: 20 }}>
        <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", flexWrap: "wrap", gap: 12 }}>
          <div style={{ display: "flex", alignItems: "center", gap: 14 }}>
            <div style={{ width: 52, height: 52, background: `linear-gradient(135deg, ${accent}, ${isDriver ? "#1d4ed8" : "#1244A2"})`, borderRadius: 16, display: "flex", alignItems: "center", justifyContent: "center", fontSize: 24, boxShadow: `0 8px 24px ${accent}44` }}>
              {isDriver ? "🏍" : "📱"}
            </div>
            <div>
              <div style={{ fontWeight: 900, fontSize: 22, color: "#0f172a", letterSpacing: -0.5 }}>
                JAGO <span style={{ background: `linear-gradient(135deg, ${accent}, ${isDriver ? "#1d4ed8" : "#1244A2"})`, WebkitBackgroundClip: "text", WebkitTextFillColor: "transparent" }}>App Design</span>
              </div>
              <div style={{ fontSize: 12, color: "#94a3b8", marginTop: 2 }}>Latest Flutter UI — Redesigned Screens</div>
            </div>
          </div>

          {/* Toggle */}
          <div style={{ display: "flex", background: "#f1f5f9", borderRadius: 14, padding: 4, gap: 4 }}>
            {(["customer", "driver"] as AppTab[]).map(tab => (
              <button key={tab} onClick={() => setActiveApp(tab)} style={{
                padding: "8px 18px", borderRadius: 11, border: "none", cursor: "pointer", fontSize: 12, fontWeight: 700, transition: "all 0.2s",
                background: activeApp === tab ? (tab === "driver" ? "linear-gradient(135deg,#2563EB,#1d4ed8)" : "linear-gradient(135deg,#1E6DE5,#1244A2)") : "transparent",
                color: activeApp === tab ? "white" : "#64748b",
                boxShadow: activeApp === tab ? "0 4px 14px rgba(0,0,0,0.18)" : "none",
              }}>
                {tab === "driver" ? "🏍 JAGO Pilot" : "📱 JAGO Customer"}
              </button>
            ))}
          </div>
        </div>

        {/* Color palette */}
        <div style={{ marginTop: 16, display: "flex", gap: 8, flexWrap: "wrap" }}>
          {palette.map((p, i) => (
            <div key={i} style={{ display: "flex", alignItems: "center", gap: 7, background: "#f8fafc", borderRadius: 10, padding: "5px 10px", border: "1px solid #f1f5f9" }}>
              <div style={{ width: 20, height: 20, background: p.c, borderRadius: 5, border: "1px solid rgba(0,0,0,0.08)" }} />
              <div>
                <div style={{ fontSize: 9, fontWeight: 700, color: "#1e293b" }}>{p.n}</div>
                <div style={{ fontSize: 8, color: "#94a3b8" }}>{p.c}</div>
              </div>
            </div>
          ))}

          <div style={{ marginLeft: "auto", display: "flex", alignItems: "center", gap: 6, background: "#f0fdf4", borderRadius: 10, padding: "5px 12px", border: "1px solid #bbf7d0" }}>
            <div style={{ width: 7, height: 7, borderRadius: "50%", background: "#16a34a" }} />
            <span style={{ fontSize: 10, fontWeight: 700, color: "#16a34a" }}>GitHub Pushed ✓</span>
          </div>
        </div>
      </div>

      {/* App info strip */}
      <div style={{ display: "flex", gap: 10, marginBottom: 20, flexWrap: "wrap" }}>
        {[
          { l: "Framework", v: "Flutter 3.27.1" },
          { l: isDriver ? "Driver Theme" : "Customer Theme", v: isDriver ? "Dark #060D1E + Blue #2563EB" : "Blue #1E6DE5 + White" },
          { l: "Total Screens", v: isDriver ? "5 screens" : "4 screens" },
          { l: "APK Build", v: "GitHub Actions" },
        ].map((info, i) => (
          <div key={i} style={{ background: "white", borderRadius: 12, padding: "10px 16px", border: "1px solid #f1f5f9", boxShadow: "0 1px 4px rgba(0,0,0,0.04)" }}>
            <div style={{ fontSize: 9, color: "#94a3b8", fontWeight: 600 }}>{info.l}</div>
            <div style={{ fontSize: 12, fontWeight: 700, color: "#1e293b", marginTop: 2 }}>{info.v}</div>
          </div>
        ))}
      </div>

      {/* Screens scrollable row */}
      <div style={{ overflowX: "auto", paddingBottom: 12 }}>
        <div style={{ display: "flex", gap: 28, minWidth: "max-content", padding: "4px 2px 16px" }}>
          {screens.map((screen, i) => (
            <div key={i} style={{ display: "flex", flexDirection: "column", alignItems: "center" }}>
              <div style={{
                marginBottom: 12, width: 30, height: 30, borderRadius: "50%",
                background: `linear-gradient(135deg, ${accent}, ${isDriver ? "#1d4ed8" : "#1244A2"})`,
                display: "flex", alignItems: "center", justifyContent: "center",
                fontSize: 12, fontWeight: 800, color: "white",
                boxShadow: `0 4px 12px ${accent}44`,
              }}>{i + 1}</div>
              {screen.component}
              <ScreenLabel title={screen.title} sub={screen.sub} />
            </div>
          ))}
        </div>
      </div>

      {/* Design notes */}
      <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 16, marginTop: 8 }}>
        <div style={{ background: "white", borderRadius: 16, padding: "18px 20px", boxShadow: "0 2px 8px rgba(0,0,0,0.05)", border: "1px solid #f1f5f9" }}>
          <div style={{ fontSize: 11, fontWeight: 700, color: "#64748b", textTransform: "uppercase", letterSpacing: 1, marginBottom: 12 }}>🎨 Design Tokens</div>
          {[
            { k: "Border Radius", v: "12–28px" },
            { k: "Font Weight Bold", v: "700–900" },
            { k: "Animation", v: "300–500ms ease" },
            { k: "Shadow", v: "Soft + colored glow" },
            { k: "Icon style", v: "Rounded Material" },
            { k: "Input style", v: "Filled + border" },
          ].map((t, i) => (
            <div key={i} style={{ display: "flex", justifyContent: "space-between", padding: "5px 8px", background: "#f8fafc", borderRadius: 7, marginBottom: 5, border: "1px solid #f1f5f9" }}>
              <span style={{ fontSize: 10, color: "#64748b", fontWeight: 600 }}>{t.k}</span>
              <span style={{ fontSize: 10, color: "#1e293b", fontWeight: 700 }}>{t.v}</span>
            </div>
          ))}
        </div>

        <div style={{ background: "white", borderRadius: 16, padding: "18px 20px", boxShadow: "0 2px 8px rgba(0,0,0,0.05)", border: "1px solid #f1f5f9" }}>
          <div style={{ fontSize: 11, fontWeight: 700, color: "#64748b", textTransform: "uppercase", letterSpacing: 1, marginBottom: 12 }}>📦 APK Build Info</div>
          {[
            { k: "Flutter", v: "3.27.1" },
            { k: "Java", v: "17" },
            { k: "Gradle", v: "8.6" },
            { k: "compileSdk", v: "35" },
            { k: "minSdk", v: "21" },
            { k: "Customer APK", v: "~26 MB" },
            { k: "Driver APK", v: "~25.5 MB" },
          ].map((t, i) => (
            <div key={i} style={{ display: "flex", justifyContent: "space-between", padding: "5px 8px", background: "#f8fafc", borderRadius: 7, marginBottom: 5, border: "1px solid #f1f5f9" }}>
              <span style={{ fontSize: 10, color: "#64748b", fontWeight: 600 }}>{t.k}</span>
              <span style={{ fontSize: 10, color: "#1e293b", fontWeight: 700 }}>{t.v}</span>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
