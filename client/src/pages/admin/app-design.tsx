import { useState } from "react";

type AppTab = "driver" | "customer";
type ThemeMode = "dark" | "light";

// ── JAGO Logo Component ──────────────────────────────────────────────────────
function JagoLogo({ size = 56, variant = "amber", showPilot = false, darkBg = true }: {
  size?: number; variant?: "amber" | "purple" | "white"; showPilot?: boolean; darkBg?: boolean;
}) {
  const src = showPilot ? "/jago-pilot-logo.png" : "/jago-logo.png";
  return (
    <div style={{
      display: "inline-flex", alignItems: "center", justifyContent: "center",
      borderRadius: size * 0.18,
      padding: darkBg ? 0 : `${size * 0.1}px ${size * 0.25}px`,
      background: darkBg ? "transparent" : "rgba(0,0,0,0.82)",
      backdropFilter: darkBg ? "none" : "blur(6px)",
    }}>
      <img
        src={src}
        alt={showPilot ? "JAGO Pilot" : "JAGO"}
        style={{ height: size, width: "auto", objectFit: "contain", maxWidth: size * 4, display: "block" }}
      />
    </div>
  );
}

// ── Phone Frame ──────────────────────────────────────────────────────────────
function PhoneFrame({ children, bg = "#060d1e" }: { children: React.ReactNode; bg?: string }) {
  return (
    <div style={{ display: "flex", justifyContent: "center" }}>
      <div style={{
        width: 230, minHeight: 456,
        background: bg,
        borderRadius: 42,
        border: "7px solid #0e2040",
        boxShadow: "0 50px 100px rgba(0,0,0,0.5), 0 0 0 1px rgba(255,255,255,0.05), inset 0 0 0 1px rgba(255,255,255,0.04)",
        overflow: "hidden",
        position: "relative",
        flexShrink: 0,
      }}>
        {/* Dynamic Island */}
        <div style={{
          position: "absolute", top: 0, left: "50%", transform: "translateX(-50%)",
          width: 90, height: 26,
          background: "#000",
          borderRadius: "0 0 20px 20px",
          zIndex: 100,
          display: "flex", alignItems: "center", justifyContent: "center", gap: 6,
        }}>
          <div style={{ width: 8, height: 8, borderRadius: "50%", background: "#1e293b", border: "1.5px solid #334155" }} />
          <div style={{ width: 4, height: 4, borderRadius: "50%", background: "#334155" }} />
        </div>
        {/* Side Buttons */}
        <div style={{ position: "absolute", right: -9, top: 80, width: 5, height: 40, background: "#1e293b", borderRadius: "0 4px 4px 0" }} />
        <div style={{ position: "absolute", left: -9, top: 70, width: 5, height: 28, background: "#1e293b", borderRadius: "4px 0 0 4px" }} />
        <div style={{ position: "absolute", left: -9, top: 108, width: 5, height: 28, background: "#1e293b", borderRadius: "4px 0 0 4px" }} />
        <div style={{ paddingTop: 28, height: "100%" }}>{children}</div>
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

function BottomNav({ active, dark = true, accent = "#3b82f6" }: { active: string; dark?: boolean; accent?: string }) {
  const bg = dark ? "#060d1e" : "white";
  const border = dark ? "rgba(255,255,255,0.06)" : "#f1f5f9";
  const inactive = dark ? "#475569" : "#9ca3af";
  const items = [
    { id: "home", svg: <svg width="16" height="16" viewBox="0 0 24 24" fill="none"><path d="M3 12L12 3L21 12V20C21 20.55 20.55 21 20 21H15V15H9V21H4C3.45 21 3 20.55 3 20V12Z" fill="currentColor"/></svg>, label: "Home" },
    { id: "trips", svg: <svg width="16" height="16" viewBox="0 0 24 24" fill="none"><circle cx="12" cy="12" r="9" stroke="currentColor" strokeWidth="2"/><path d="M12 7V12L15 15" stroke="currentColor" strokeWidth="2" strokeLinecap="round"/></svg>, label: "Trips" },
    { id: "wallet", svg: <svg width="16" height="16" viewBox="0 0 24 24" fill="none"><rect x="2" y="6" width="20" height="14" rx="3" stroke="currentColor" strokeWidth="2"/><circle cx="17" cy="13" r="2" fill="currentColor"/><path d="M2 10H22" stroke="currentColor" strokeWidth="2"/></svg>, label: "Wallet" },
    { id: "profile", svg: <svg width="16" height="16" viewBox="0 0 24 24" fill="none"><circle cx="12" cy="8" r="4" stroke="currentColor" strokeWidth="2"/><path d="M4 20C4 16.686 7.582 14 12 14C16.418 14 20 16.686 20 20" stroke="currentColor" strokeWidth="2" strokeLinecap="round"/></svg>, label: "Profile" },
  ];
  return (
    <div style={{ display: "flex", background: bg, borderTop: `1px solid ${border}`, padding: "6px 0 4px" }}>
      {items.map(it => {
        const isActive = it.id === active;
        return (
          <div key={it.id} style={{ flex: 1, display: "flex", flexDirection: "column", alignItems: "center", gap: 2, color: isActive ? accent : inactive }}>
            {it.svg}
            <div style={{ fontSize: 7, fontWeight: isActive ? 700 : 400, color: isActive ? accent : inactive }}>{it.label}</div>
            {isActive && <div style={{ width: 4, height: 4, borderRadius: "50%", background: accent }} />}
          </div>
        );
      })}
    </div>
  );
}

function CityMap({ dark = true, driverMode = false }: { dark?: boolean; driverMode?: boolean }) {
  const roadColor = dark ? "rgba(255,255,255,0.05)" : "rgba(0,0,0,0.06)";
  const roadBold = dark ? "rgba(255,255,255,0.09)" : "rgba(0,0,0,0.1)";
  const bg = dark ? (driverMode ? "radial-gradient(ellipse at 50% 40%, #0c2050 0%, #060d1e 80%)" : "radial-gradient(ellipse at 50% 40%, #0c1a2f 0%, #060d1e 80%)") : (driverMode ? "linear-gradient(160deg,#dbeafe 0%,#eff6ff 60%,#eff6ff 100%)" : "linear-gradient(160deg,#dbeafe 0%,#dbeafe 60%,#eff6ff 100%)");
  return (
    <div style={{ position: "absolute", inset: 0, background: bg, overflow: "hidden" }}>
      <svg width="100%" height="100%" style={{ position: "absolute", inset: 0 }}>
        {[0,14,28,42,56,70,84,100].map(x => <line key={`v${x}`} x1={`${x}%`} y1="0" x2={`${x}%`} y2="100%" stroke={x % 28 === 0 ? roadBold : roadColor} strokeWidth={x % 28 === 0 ? 2 : 1}/>)}
        {[0,12,24,36,48,60,72,84,96].map(y => <line key={`h${y}`} x1="0" y1={`${y}%`} x2="100%" y2={`${y}%`} stroke={y % 24 === 0 ? roadBold : roadColor} strokeWidth={y % 24 === 0 ? 2 : 1}/>)}
        <line x1="0" y1="38%" x2="100%" y2="55%" stroke={roadBold} strokeWidth="3"/>
        <line x1="20%" y1="0" x2="35%" y2="100%" stroke={roadBold} strokeWidth="2"/>
        <line x1="65%" y1="0" x2="55%" y2="100%" stroke={roadBold} strokeWidth="2"/>
        <circle cx="43%" cy="52%" r="2.5%" fill={dark ? "rgba(255,255,255,0.04)" : "rgba(0,0,0,0.04)"} stroke={roadBold} strokeWidth="1"/>
      </svg>
    </div>
  );
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// DRIVER APP SCREENS — DARK MODE
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

function DarkDriverSplash() {
  return (
    <PhoneFrame bg="#060d1e">
      <div style={{
        minHeight: 428,
        background: "linear-gradient(160deg, #060d1e 0%, #12112a 40%, #0d1f35 100%)",
        display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center",
        padding: "0 24px", gap: 0, position: "relative", overflow: "hidden",
      }}>
        {/* Glow orbs */}
        <div style={{ position: "absolute", top: "20%", left: "50%", transform: "translateX(-50%)",
          width: 160, height: 160, borderRadius: "50%",
          background: "radial-gradient(circle, rgba(59,130,246,0.12) 0%, transparent 70%)" }} />
        <div style={{ position: "absolute", bottom: "15%", right: "-20%",
          width: 140, height: 140, borderRadius: "50%",
          background: "radial-gradient(circle, rgba(59,130,246,0.08) 0%, transparent 70%)" }} />

        <JagoLogo size={90} variant="amber" showPilot={true} />

        <div style={{ marginTop: 16, fontSize: 9, color: "#475569", letterSpacing: 1 }}>Your Earnings. Your Journey.</div>

        <div style={{ marginTop: 28, width: 48, height: 4, background: "linear-gradient(90deg,#3b82f6,#1d4ed8)", borderRadius: 2 }} />

        <div style={{ marginTop: 20, fontSize: 9, color: "#334155" }}>Version 2.0.1</div>

        {/* Bottom glow line */}
        <div style={{ position: "absolute", bottom: 0, left: 0, right: 0, height: 2,
          background: "linear-gradient(90deg, transparent, #3b82f644, transparent)" }} />
      </div>
    </PhoneFrame>
  );
}

function DarkDriverLogin() {
  return (
    <PhoneFrame bg="#060d1e">
      <div style={{ minHeight: 428, background: "linear-gradient(180deg, #060d1e 0%, #091429 100%)", padding: "24px 18px 18px", position: "relative", overflow: "hidden" }}>
        <div style={{ position: "absolute", top: 0, right: 0, width: 140, height: 140,
          background: "radial-gradient(circle at top right, rgba(59,130,246,0.08) 0%, transparent 70%)" }} />

        <div style={{ display: "flex", alignItems: "center", gap: 8, marginBottom: 20 }}>
          <JagoLogo size={38} variant="amber" showPilot={true} />
        </div>

        <div style={{ color: "white", fontSize: 20, fontWeight: 800, lineHeight: 1.2 }}>Welcome<br />Back <span style={{ fontSize: 18 }}>👋</span></div>
        <div style={{ color: "#475569", fontSize: 10, marginTop: 6 }}>Login చేసి earning start చేయండి</div>

        <div style={{ marginTop: 22, display: "flex", flexDirection: "column", gap: 10 }}>
          <div>
            <div style={{ fontSize: 9, color: "#64748b", fontWeight: 600, marginBottom: 5, textTransform: "uppercase", letterSpacing: 0.5 }}>Phone Number</div>
            <div style={{
              background: "#091629", borderRadius: 14, padding: "11px 13px",
              display: "flex", alignItems: "center", gap: 8,
              border: "1.5px solid #3b82f644",
              boxShadow: "0 0 0 3px rgba(59,130,246,0.05)",
            }}>
              <div style={{ padding: "2px 6px", background: "rgba(59,130,246,0.15)", borderRadius: 6, fontSize: 10, color: "#3b82f6", fontWeight: 700 }}>+91</div>
              <div style={{ width: 1, height: 14, background: "#334155" }} />
              <span style={{ fontSize: 11, color: "#64748b" }}>98765 43210</span>
            </div>
          </div>

          <div>
            <div style={{ fontSize: 9, color: "#64748b", fontWeight: 600, marginBottom: 5, textTransform: "uppercase", letterSpacing: 0.5 }}>OTP</div>
            <div style={{ display: "flex", gap: 6 }}>
              {["5","2","•","•"].map((d, i) => (
                <div key={i} style={{
                  flex: 1, background: d !== "•" ? "rgba(59,130,246,0.08)" : "#091629",
                  border: `1.5px solid ${d !== "•" ? "#3b82f655" : "#1e293b"}`,
                  borderRadius: 12, padding: "10px 0", textAlign: "center",
                  color: d !== "•" ? "white" : "#334155", fontSize: 15, fontWeight: 800,
                  boxShadow: d === "5" ? "0 0 12px rgba(59,130,246,0.15)" : "none",
                }}>{d}</div>
              ))}
            </div>
          </div>

          <div style={{ marginTop: 4,
            background: "linear-gradient(135deg,#3b82f6,#1d4ed8)",
            borderRadius: 14, padding: "12px 0", textAlign: "center",
            color: "white", fontSize: 12, fontWeight: 700, letterSpacing: 0.5,
            boxShadow: "0 8px 24px rgba(59,130,246,0.35)",
          }}>Verify & Login →</div>

          <div style={{ textAlign: "center", fontSize: 9, color: "#334155" }}>OTP resend in <span style={{ color: "#3b82f6" }}>28s</span></div>
        </div>
      </div>
    </PhoneFrame>
  );
}

function DarkDriverHome() {
  return (
    <PhoneFrame bg="#060d1e">
      <div style={{ minHeight: 428, background: "#060d1e", position: "relative", overflow: "hidden", display: "flex", flexDirection: "column" }}>
        <CityMap dark driverMode />

        {/* Driver location pin */}
        <div style={{ position: "absolute", top: "43%", left: "44%", zIndex: 2, display: "flex", flexDirection: "column", alignItems: "center" }}>
          <div style={{ width: 32, height: 32, background: "linear-gradient(135deg,#3b82f6,#1d4ed8)", borderRadius: "50%", display: "flex", alignItems: "center", justifyContent: "center", boxShadow: "0 0 0 8px rgba(59,130,246,0.15),0 0 0 16px rgba(59,130,246,0.06)", fontSize: 14 }}>🚗</div>
        </div>

        {/* Top bar */}
        <div style={{ position: "relative", zIndex: 3, padding: "8px 14px" }}>
          <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
            <JagoLogo size={26} variant="amber" showPilot={true} />
            <div style={{ display: "flex", gap: 6, alignItems: "center" }}>
              <div style={{ position: "relative" }}>
                <div style={{ width: 30, height: 30, borderRadius: 10, background: "rgba(255,255,255,0.08)", display: "flex", alignItems: "center", justifyContent: "center" }}>
                  <svg width="14" height="14" viewBox="0 0 24 24" fill="none"><path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9M13.73 21a2 2 0 0 1-3.46 0" stroke="white" strokeWidth="2" strokeLinecap="round"/></svg>
                </div>
                <div style={{ position: "absolute", top: -2, right: -2, width: 8, height: 8, borderRadius: "50%", background: "#ef4444", border: "1.5px solid #060d1e" }} />
              </div>
              <div style={{ width: 30, height: 30, borderRadius: "50%", background: "linear-gradient(135deg,#3b82f6,#1d4ed8)", display: "flex", alignItems: "center", justifyContent: "center", fontSize: 11, fontWeight: 800, color: "white" }}>A</div>
            </div>
          </div>

          {/* Today earnings hero */}
          <div style={{ marginTop: 8, background: "rgba(0,0,0,0.55)", backdropFilter: "blur(12px)", borderRadius: 16, padding: "10px 14px", border: "1px solid rgba(59,130,246,0.2)" }}>
            <div style={{ fontSize: 7, color: "#94a3b8", textTransform: "uppercase", letterSpacing: 1 }}>Today's Earnings</div>
            <div style={{ fontSize: 24, fontWeight: 900, color: "#3b82f6", lineHeight: 1.1, marginTop: 2 }}>₹1,240</div>
            <div style={{ display: "flex", gap: 12, marginTop: 6 }}>
              {[{l:"8 Trips",c:"#60a5fa"},{l:"6.5 hrs",c:"#93c5fd"},{l:"4.9 ★",c:"#60a5fa"}].map((s,i) => (
                <div key={i} style={{ fontSize: 9, fontWeight: 600, color: s.c }}>{s.l}</div>
              ))}
            </div>
          </div>
        </div>

        <div style={{ flex: 1 }} />

        {/* Bottom sheet */}
        <div style={{ position: "relative", zIndex: 3 }}>
          <div style={{ background: "linear-gradient(180deg,transparent,rgba(6,13,30,0.95) 30%)", padding: "20px 14px 0" }}>
            <div style={{ background: "#091629", borderRadius: "20px 20px 0 0", padding: "16px 14px 12px", border: "1px solid rgba(255,255,255,0.07)", borderBottom: "none" }}>
              <div style={{ width: 36, height: 4, background: "#1e293b", borderRadius: 2, margin: "0 auto 12px" }} />
              <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 12 }}>
                <div>
                  <div style={{ fontSize: 14, fontWeight: 800, color: "white" }}>● ONLINE</div>
                  <div style={{ fontSize: 8, color: "#22c55e", marginTop: 2 }}>Searching for rides nearby...</div>
                </div>
                <div style={{ width: 52, height: 28, background: "linear-gradient(135deg,#22c55e,#16a34a)", borderRadius: 14, position: "relative", boxShadow: "0 4px 14px rgba(34,197,94,0.4)", cursor: "pointer" }}>
                  <div style={{ position: "absolute", right: 4, top: 4, width: 20, height: 20, background: "white", borderRadius: "50%", boxShadow: "0 2px 6px rgba(0,0,0,0.3)" }} />
                </div>
              </div>
              <div style={{ display: "flex", gap: 6 }}>
                {[{l:"Wallet",v:"₹240"},{l:"Bonus",v:"₹50"},{l:"Online",v:"6.5h"}].map((s,i) => (
                  <div key={i} style={{ flex: 1, background: "#1e293b", borderRadius: 10, padding: "7px 6px", textAlign: "center" }}>
                    <div style={{ fontSize: 8, color: "#475569" }}>{s.l}</div>
                    <div style={{ fontSize: 10, fontWeight: 700, color: "white", marginTop: 2 }}>{s.v}</div>
                  </div>
                ))}
              </div>
            </div>
          </div>
          <BottomNav active="home" dark accent="#3b82f6" />
        </div>
      </div>
    </PhoneFrame>
  );
}

function DarkDriverNewTrip() {
  return (
    <PhoneFrame bg="#060d1e">
      <div style={{ minHeight: 428, background: "#060d1e", position: "relative", overflow: "hidden", display: "flex", flexDirection: "column" }}>
        <CityMap dark driverMode />
        <div style={{ position: "absolute", inset: 0, background: "rgba(0,0,0,0.6)", zIndex: 1 }} />

        {/* Pulsing notification center */}
        <div style={{ position: "absolute", top: "24%", left: "50%", transform: "translate(-50%,-50%)", zIndex: 2, display: "flex", alignItems: "center", justifyContent: "center" }}>
          {[90,120,150].map((s,i) => <div key={i} style={{ position: "absolute", width: s, height: s, borderRadius: "50%", border: `1.5px solid rgba(59,130,246,${0.28-i*0.07})` }} />)}
          <div style={{ width: 64, height: 64, borderRadius: "50%", background: "linear-gradient(135deg,#3b82f6,#1d4ed8)", display: "flex", alignItems: "center", justifyContent: "center", boxShadow: "0 0 40px rgba(59,130,246,0.6)", fontSize: 26 }}>🔔</div>
        </div>

        <div style={{ flex: 1 }} />

        {/* Main trip card */}
        <div style={{ position: "relative", zIndex: 3 }}>
          <div style={{ background: "#091629", borderRadius: "24px 24px 0 0", padding: "14px 14px 0", border: "1px solid rgba(59,130,246,0.15)", borderBottom: "none" }}>
            <div style={{ width: 36, height: 4, background: "#1e293b", borderRadius: 2, margin: "0 auto 10px" }} />

            {/* Timer bar */}
            <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 8 }}>
              <div style={{ fontSize: 11, color: "#3b82f6", fontWeight: 800, textTransform: "uppercase", letterSpacing: 1 }}>New Ride Request</div>
              <div style={{ background: "rgba(59,130,246,0.15)", border: "1px solid rgba(59,130,246,0.3)", borderRadius: 8, padding: "3px 8px", fontSize: 10, fontWeight: 800, color: "#3b82f6" }}>28s</div>
            </div>
            <div style={{ height: 3, background: "#1e293b", borderRadius: 2, marginBottom: 12, overflow: "hidden" }}>
              <div style={{ width: "65%", height: "100%", background: "linear-gradient(90deg,#22c55e,#3b82f6,#1d4ed8)", borderRadius: 2 }} />
            </div>

            {/* Customer info row */}
            <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 10 }}>
              <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
                <div style={{ width: 36, height: 36, borderRadius: "50%", background: "linear-gradient(135deg,#2563eb,#1d4ed8)", display: "flex", alignItems: "center", justifyContent: "center", fontWeight: 800, color: "white", fontSize: 14 }}>A</div>
                <div>
                  <div style={{ fontSize: 12, fontWeight: 800, color: "white" }}>Arjun Reddy</div>
                  <div style={{ display: "flex", gap: 1, marginTop: 1 }}>{[...Array(5)].map((_,i) => <span key={i} style={{ fontSize: 8, color: "#3b82f6" }}>★</span>)}<span style={{ fontSize: 8, color: "#64748b", marginLeft: 3 }}>4.9</span></div>
                </div>
              </div>
              <div style={{ background: "rgba(34,197,94,0.1)", border: "1px solid rgba(34,197,94,0.3)", borderRadius: 10, padding: "5px 10px", fontSize: 14, fontWeight: 900, color: "#22c55e" }}>₹185</div>
            </div>

            {/* Route */}
            <div style={{ background: "#1e293b", borderRadius: 12, padding: "10px 12px", marginBottom: 10 }}>
              {[{dot:"#22c55e",label:"MGBS Bus Stand, Hyderabad"},{dot:"#ef4444",label:"Banjara Hills Rd No. 12"}].map((loc,i) => (
                <div key={i}>
                  {i > 0 && <div style={{ width: 1.5, height: 8, background: "#334155", marginLeft: 3, marginTop: 2, marginBottom: 2 }} />}
                  <div style={{ display: "flex", gap: 8, alignItems: "center" }}>
                    <div style={{ width: 8, height: 8, borderRadius: "50%", background: loc.dot, boxShadow: `0 0 6px ${loc.dot}`, flexShrink: 0 }} />
                    <span style={{ fontSize: 9, color: "#94a3b8" }}>{loc.label}</span>
                  </div>
                </div>
              ))}
              <div style={{ display: "flex", gap: 14, marginTop: 8, paddingTop: 8, borderTop: "1px solid #334155" }}>
                <span style={{ fontSize: 9, color: "#60a5fa", fontWeight: 600 }}>📍 2.4 km pickup</span>
                <span style={{ fontSize: 9, color: "#93c5fd", fontWeight: 600 }}>⏱ 8 min ETA</span>
                <span style={{ fontSize: 9, color: "#94a3b8", fontWeight: 600 }}>🛺 Auto</span>
              </div>
            </div>

            {/* Action buttons */}
            <div style={{ display: "flex", gap: 8, paddingBottom: 12 }}>
              <div style={{ flex: 1, background: "#1e293b", borderRadius: 14, padding: "12px 0", textAlign: "center", fontSize: 11, fontWeight: 600, color: "#64748b" }}>✕  Decline</div>
              <div style={{ flex: 2, background: "linear-gradient(135deg,#22c55e,#16a34a)", borderRadius: 14, padding: "12px 0", textAlign: "center", fontSize: 12, fontWeight: 800, color: "white", boxShadow: "0 6px 20px rgba(34,197,94,0.4)" }}>✓  Accept Ride</div>
            </div>
          </div>
        </div>
      </div>
    </PhoneFrame>
  );
}

function DarkDriverOnTrip() {
  return (
    <PhoneFrame bg="#060d1e">
      <div style={{ minHeight: 428, background: "#060d1e", position: "relative", overflow: "hidden", display: "flex", flexDirection: "column" }}>
        <CityMap dark driverMode />

        {/* Route line + markers */}
        <div style={{ position: "absolute", top: "22%", left: "38%", zIndex: 2 }}>
          <div style={{ width: 10, height: 10, background: "#22c55e", borderRadius: "50%", boxShadow: "0 0 12px #22c55e" }} />
          <div style={{ width: 2, height: 60, background: "linear-gradient(180deg,#22c55e,#3b82f6)", borderRadius: 2, marginLeft: 4 }} />
          <div style={{ width: 22, height: 22, background: "linear-gradient(135deg,#3b82f6,#1d4ed8)", borderRadius: "50%", display: "flex", alignItems: "center", justifyContent: "center", fontSize: 10, boxShadow: "0 0 0 5px rgba(59,130,246,0.2)", marginLeft: -4 }}>🚗</div>
          <div style={{ width: 2, height: 40, background: "linear-gradient(180deg,#3b82f6,#60a5fa)", borderRadius: 2, marginLeft: 4 }} />
          <div style={{ width: 10, height: 10, background: "#ef4444", borderRadius: "50%", boxShadow: "0 0 12px #ef4444" }} />
        </div>

        {/* Top nav bar */}
        <div style={{ position: "relative", zIndex: 3, background: "rgba(6,13,30,0.9)", backdropFilter: "blur(16px)", padding: "8px 14px 10px", borderBottom: "1px solid rgba(255,255,255,0.06)" }}>
          <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between" }}>
            <div>
              <div style={{ fontSize: 7, color: "#22c55e", fontWeight: 700, textTransform: "uppercase", letterSpacing: 1.5 }}>● Dropping Customer</div>
              <div style={{ fontSize: 13, fontWeight: 800, color: "white" }}>Banjara Hills Rd No. 12</div>
            </div>
            <div style={{ background: "rgba(34,197,94,0.12)", border: "1px solid rgba(34,197,94,0.3)", borderRadius: 10, padding: "5px 10px", textAlign: "center" }}>
              <div style={{ fontSize: 13, fontWeight: 900, color: "#22c55e" }}>12</div>
              <div style={{ fontSize: 7, color: "#22c55e" }}>min</div>
            </div>
          </div>
        </div>

        <div style={{ flex: 1 }} />

        {/* Bottom customer card */}
        <div style={{ position: "relative", zIndex: 3 }}>
          <div style={{ background: "linear-gradient(180deg,transparent,rgba(6,13,30,0.95) 30%)", padding: "20px 14px 0" }}>
            <div style={{ background: "#091629", borderRadius: "20px 20px 0 0", padding: "14px 14px 0", border: "1px solid rgba(255,255,255,0.07)", borderBottom: "none" }}>
              <div style={{ width: 36, height: 4, background: "#1e293b", borderRadius: 2, margin: "0 auto 12px" }} />
              <div style={{ display: "flex", alignItems: "center", gap: 10, marginBottom: 10 }}>
                <div style={{ width: 38, height: 38, borderRadius: "50%", background: "linear-gradient(135deg,#2563eb,#93c5fd)", display: "flex", alignItems: "center", justifyContent: "center", fontWeight: 800, color: "white", fontSize: 15 }}>A</div>
                <div style={{ flex: 1 }}>
                  <div style={{ fontSize: 12, fontWeight: 700, color: "white" }}>Arjun Reddy</div>
                  <div style={{ display: "flex", gap: 1 }}>{[...Array(5)].map((_,i) => <span key={i} style={{ fontSize: 8, color: "#3b82f6" }}>★</span>)}<span style={{ fontSize: 8, color: "#64748b", marginLeft: 3 }}>4.9</span></div>
                </div>
                <div style={{ display: "flex", gap: 5 }}>
                  {[{ic:<svg width="14" height="14" viewBox="0 0 24 24" fill="none"><path d="M22 16.92v3a2 2 0 0 1-2.18 2 19.79 19.79 0 0 1-8.63-3.07A19.5 19.5 0 0 1 4.69 11a19.79 19.79 0 0 1-3.07-8.67A2 2 0 0 1 3.6 0h3a2 2 0 0 1 2 1.72c.127.96.361 1.903.7 2.81a2 2 0 0 1-.45 2.11L7.91 7.91a16 16 0 0 0 6.07 6.07l.9-.9a2 2 0 0 1 2.11-.45c.907.339 1.85.573 2.81.7A2 2 0 0 1 22 16.92z" fill="white"/></svg>}, {ic:<svg width="14" height="14" viewBox="0 0 24 24" fill="none"><path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z" fill="white"/></svg>}].map((btn,i) => (
                    <div key={i} style={{ width: 32, height: 32, borderRadius: "50%", background: "#1e293b", border: "1px solid #334155", display: "flex", alignItems: "center", justifyContent: "center" }}>{btn.ic}</div>
                  ))}
                </div>
              </div>
              <div style={{ display: "flex", gap: 6, marginBottom: 12 }}>
                {[{l:"Distance",v:"7.2 km"},{l:"Fare",v:"₹185"},{l:"ETA",v:"12 min"}].map((s,i) => (
                  <div key={i} style={{ flex: 1, background: "#1e293b", borderRadius: 10, padding: "7px 0", textAlign: "center" }}>
                    <div style={{ fontSize: 7, color: "#475569" }}>{s.l}</div>
                    <div style={{ fontSize: 11, fontWeight: 700, color: "white", marginTop: 2 }}>{s.v}</div>
                  </div>
                ))}
              </div>
              <div style={{ background: "linear-gradient(135deg,#16a34a,#15803d)", borderRadius: 14, padding: "12px 0", textAlign: "center", fontSize: 12, fontWeight: 800, color: "white", boxShadow: "0 6px 18px rgba(22,163,74,0.4)", marginBottom: 12 }}>Complete Trip</div>
            </div>
          </div>
          <BottomNav active="home" dark accent="#3b82f6" />
        </div>
      </div>
    </PhoneFrame>
  );
}

function DarkDriverWallet() {
  return (
    <PhoneFrame bg="#060d1e">
      <div style={{ minHeight: 428, background: "#060d1e" }}>
        <div style={{ background: "linear-gradient(135deg,#12112a,#0d1f35)", padding: "10px 16px 20px", position: "relative", overflow: "hidden" }}>
          <div style={{ position: "absolute", top: 0, right: 0, width: 120, height: 120, background: "radial-gradient(circle at top right, rgba(59,130,246,0.1) 0%, transparent 70%)" }} />
          <div style={{ display: "flex", alignItems: "center", gap: 7, marginBottom: 14 }}>
            <JagoLogo size={22} variant="amber" showPilot={true} />
            <div style={{ fontSize: 8, color: "#64748b", textTransform: "uppercase", fontWeight: 600, letterSpacing: 1 }}>Driver Wallet</div>
          </div>
          <div style={{ textAlign: "center" }}>
            <div style={{ fontSize: 8, color: "#475569" }}>Current Balance</div>
            <div style={{ fontSize: 30, fontWeight: 900, color: "#22c55e", lineHeight: 1, marginTop: 4 }}>₹1,240</div>
            <div style={{ fontSize: 8, color: "#475569", marginTop: 3 }}>This month: ₹8,400</div>
          </div>
          <div style={{ display: "flex", gap: 8, marginTop: 14 }}>
            <div style={{ flex: 1, background: "rgba(34,197,94,0.1)", border: "1px solid rgba(34,197,94,0.25)", borderRadius: 12, padding: "9px 0", textAlign: "center", fontSize: 10, fontWeight: 700, color: "#22c55e" }}>📥 Add Cash</div>
            <div style={{ flex: 1, background: "rgba(96,165,250,0.1)", border: "1px solid rgba(96,165,250,0.25)", borderRadius: 12, padding: "9px 0", textAlign: "center", fontSize: 10, fontWeight: 700, color: "#60a5fa" }}>📤 Withdraw</div>
          </div>
        </div>

        <div style={{ padding: "12px 14px" }}>
          <div style={{ fontSize: 9, color: "#334155", textTransform: "uppercase", fontWeight: 700, letterSpacing: 1, marginBottom: 8 }}>Transactions</div>
          {[
            { icon: "🚗", label: "Trip Commission", sub: "TRP97842 · Today", amt: "-₹27.50", c: "#f87171" },
            { icon: "⭐", label: "Peak Hour Bonus", sub: "Yesterday", amt: "+₹50", c: "#86efac" },
            { icon: "🚗", label: "Trip Commission", sub: "TRP97801 · Yesterday", amt: "-₹18.20", c: "#f87171" },
            { icon: "💰", label: "Wallet Credit", sub: "Admin · 3 days ago", amt: "+₹500", c: "#86efac" },
          ].map((tx, i) => (
            <div key={i} style={{ display: "flex", alignItems: "center", gap: 9, marginBottom: 7, background: "#091429", borderRadius: 12, padding: "9px 11px", border: "1px solid rgba(255,255,255,0.04)" }}>
              <div style={{ width: 30, height: 30, borderRadius: 9, background: "#1e293b", display: "flex", alignItems: "center", justifyContent: "center", fontSize: 13 }}>{tx.icon}</div>
              <div style={{ flex: 1 }}>
                <div style={{ fontSize: 10, fontWeight: 600, color: "white" }}>{tx.label}</div>
                <div style={{ fontSize: 8, color: "#334155", marginTop: 1 }}>{tx.sub}</div>
              </div>
              <div style={{ fontSize: 11, fontWeight: 700, color: tx.c }}>{tx.amt}</div>
            </div>
          ))}
        </div>
      </div>
    </PhoneFrame>
  );
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// DRIVER APP SCREENS — LIGHT MODE
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

function LightDriverSplash() {
  return (
    <PhoneFrame bg="#eff6ff">
      <div style={{
        minHeight: 428,
        background: "linear-gradient(160deg, #eff6ff 0%, #dbeafe 40%, #eff6ff 100%)",
        display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center",
        padding: "0 24px", gap: 0, position: "relative", overflow: "hidden",
      }}>
        <div style={{ position: "absolute", top: "15%", right: "10%", width: 100, height: 100, borderRadius: "50%", background: "radial-gradient(circle, rgba(59,130,246,0.2) 0%, transparent 70%)" }} />
        <div style={{ position: "absolute", bottom: "20%", left: "5%", width: 80, height: 80, borderRadius: "50%", background: "radial-gradient(circle, rgba(239,68,68,0.1) 0%, transparent 70%)" }} />

        <div style={{ background: "rgba(6,13,30,0.85)", borderRadius: 22, padding: "14px 22px", backdropFilter: "blur(4px)", boxShadow: "0 20px 50px rgba(59,130,246,0.2)" }}>
          <img src="/jago-pilot-logo.png" alt="JAGO Pilot" style={{ height: 72, width: "auto", objectFit: "contain" }} />
        </div>

        <div style={{ marginTop: 20, fontSize: 9, color: "#1e40af", letterSpacing: 1 }}>Your Earnings. Your Journey.</div>

        <div style={{ marginTop: 20, width: 48, height: 4, background: "linear-gradient(90deg,#3b82f6,#1d4ed8)", borderRadius: 2 }} />
        <div style={{ marginTop: 20, fontSize: 9, color: "#d1d5db" }}>Version 2.0.1</div>

        <div style={{ position: "absolute", bottom: 0, left: 0, right: 0, height: 2, background: "linear-gradient(90deg, transparent, rgba(59,130,246,0.5), transparent)" }} />
      </div>
    </PhoneFrame>
  );
}

function LightDriverLogin() {
  return (
    <PhoneFrame bg="white">
      <div style={{ minHeight: 428, background: "white", padding: "24px 18px 18px", position: "relative", overflow: "hidden" }}>
        <div style={{ position: "absolute", top: 0, right: 0, width: 160, height: 160, background: "radial-gradient(circle at top right, rgba(59,130,246,0.08) 0%, transparent 70%)" }} />

        <div style={{ display: "flex", alignItems: "center", gap: 8, marginBottom: 22 }}>
          <JagoLogo size={32} variant="amber" showPilot={true} darkBg={false} />
        </div>

        <div style={{ color: "#1c1917", fontSize: 20, fontWeight: 800, lineHeight: 1.2 }}>Welcome<br />Back <span style={{ fontSize: 18 }}>👋</span></div>
        <div style={{ color: "#9ca3af", fontSize: 10, marginTop: 6 }}>Login చేసి earning start చేయండి</div>

        <div style={{ marginTop: 22, display: "flex", flexDirection: "column", gap: 10 }}>
          <div>
            <div style={{ fontSize: 9, color: "#6b7280", fontWeight: 600, marginBottom: 5, textTransform: "uppercase", letterSpacing: 0.5 }}>Phone Number</div>
            <div style={{ background: "#f0f9ff", borderRadius: 14, padding: "11px 13px", display: "flex", alignItems: "center", gap: 8, border: "1.5px solid #3b82f666", boxShadow: "0 0 0 3px rgba(59,130,246,0.08)" }}>
              <div style={{ padding: "2px 7px", background: "#dbeafe", borderRadius: 6, fontSize: 10, color: "#2563eb", fontWeight: 700 }}>+91</div>
              <div style={{ width: 1, height: 14, background: "#e5e7eb" }} />
              <span style={{ fontSize: 11, color: "#9ca3af" }}>98765 43210</span>
            </div>
          </div>

          <div>
            <div style={{ fontSize: 9, color: "#6b7280", fontWeight: 600, marginBottom: 5, textTransform: "uppercase", letterSpacing: 0.5 }}>OTP</div>
            <div style={{ display: "flex", gap: 6 }}>
              {["5","2","•","•"].map((d, i) => (
                <div key={i} style={{
                  flex: 1, background: d !== "•" ? "#eff6ff" : "#f0f9ff",
                  border: `1.5px solid ${d !== "•" ? "#3b82f6" : "#e5e7eb"}`,
                  borderRadius: 12, padding: "10px 0", textAlign: "center",
                  color: d !== "•" ? "#1c1917" : "#d1d5db", fontSize: 15, fontWeight: 800,
                }}>{d}</div>
              ))}
            </div>
          </div>

          <div style={{ marginTop: 4, background: "linear-gradient(135deg,#3b82f6,#1d4ed8)", borderRadius: 14, padding: "12px 0", textAlign: "center", color: "white", fontSize: 12, fontWeight: 700, letterSpacing: 0.5, boxShadow: "0 8px 24px rgba(59,130,246,0.35)" }}>Verify & Login →</div>
          <div style={{ textAlign: "center", fontSize: 9, color: "#9ca3af" }}>OTP resend in <span style={{ color: "#3b82f6", fontWeight: 600 }}>28s</span></div>
        </div>
      </div>
    </PhoneFrame>
  );
}

function LightDriverHome() {
  return (
    <PhoneFrame bg="#eff6ff">
      <div style={{ minHeight: 428, background: "#eff6ff", position: "relative", overflow: "hidden", display: "flex", flexDirection: "column" }}>
        <CityMap dark={false} driverMode />

        {/* Driver pin */}
        <div style={{ position: "absolute", top: "44%", left: "44%", zIndex: 2 }}>
          <div style={{ width: 32, height: 32, background: "linear-gradient(135deg,#3b82f6,#1d4ed8)", borderRadius: "50%", display: "flex", alignItems: "center", justifyContent: "center", boxShadow: "0 0 0 8px rgba(59,130,246,0.15),0 0 0 16px rgba(59,130,246,0.06)", fontSize: 14 }}>🚗</div>
        </div>

        {/* Top bar */}
        <div style={{ position: "relative", zIndex: 3, padding: "8px 14px" }}>
          <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
            <JagoLogo size={26} variant="amber" showPilot={true} darkBg={false} />
            <div style={{ display: "flex", gap: 6, alignItems: "center" }}>
              <div style={{ position: "relative" }}>
                <div style={{ width: 30, height: 30, borderRadius: 10, background: "white", boxShadow: "0 2px 8px rgba(0,0,0,0.1)", display: "flex", alignItems: "center", justifyContent: "center" }}>
                  <svg width="14" height="14" viewBox="0 0 24 24" fill="none"><path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9M13.73 21a2 2 0 0 1-3.46 0" stroke="#374151" strokeWidth="2" strokeLinecap="round"/></svg>
                </div>
                <div style={{ position: "absolute", top: -2, right: -2, width: 8, height: 8, borderRadius: "50%", background: "#ef4444", border: "1.5px solid #eff6ff" }} />
              </div>
              <div style={{ width: 30, height: 30, borderRadius: "50%", background: "linear-gradient(135deg,#3b82f6,#1d4ed8)", display: "flex", alignItems: "center", justifyContent: "center", fontSize: 11, fontWeight: 800, color: "white" }}>A</div>
            </div>
          </div>

          {/* Earnings card */}
          <div style={{ marginTop: 8, background: "white", borderRadius: 16, padding: "10px 14px", boxShadow: "0 4px 20px rgba(59,130,246,0.15)", border: "1px solid rgba(59,130,246,0.15)" }}>
            <div style={{ fontSize: 7, color: "#9ca3af", textTransform: "uppercase", letterSpacing: 1 }}>Today's Earnings</div>
            <div style={{ fontSize: 24, fontWeight: 900, color: "#2563eb", lineHeight: 1.1, marginTop: 2 }}>₹1,240</div>
            <div style={{ display: "flex", gap: 12, marginTop: 6 }}>
              {[{l:"8 Trips",c:"#3b82f6"},{l:"6.5 hrs",c:"#8b5cf6"},{l:"4.9 ★",c:"#3b82f6"}].map((s,i) => (
                <div key={i} style={{ fontSize: 9, fontWeight: 600, color: s.c }}>{s.l}</div>
              ))}
            </div>
          </div>
        </div>

        <div style={{ flex: 1 }} />

        {/* Bottom sheet */}
        <div style={{ position: "relative", zIndex: 3 }}>
          <div style={{ background: "linear-gradient(180deg,transparent,rgba(255,248,237,0.95) 30%)", padding: "20px 14px 0" }}>
            <div style={{ background: "white", borderRadius: "20px 20px 0 0", padding: "16px 14px 12px", boxShadow: "0 -4px 20px rgba(0,0,0,0.08)", border: "1px solid #f3f4f6", borderBottom: "none" }}>
              <div style={{ width: 36, height: 4, background: "#f3f4f6", borderRadius: 2, margin: "0 auto 12px" }} />
              <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 12 }}>
                <div>
                  <div style={{ fontSize: 14, fontWeight: 800, color: "#1c1917" }}>● ONLINE</div>
                  <div style={{ fontSize: 8, color: "#16a34a", marginTop: 2 }}>Searching for rides nearby...</div>
                </div>
                <div style={{ width: 52, height: 28, background: "linear-gradient(135deg,#22c55e,#16a34a)", borderRadius: 14, position: "relative", boxShadow: "0 4px 12px rgba(34,197,94,0.35)" }}>
                  <div style={{ position: "absolute", right: 4, top: 4, width: 20, height: 20, background: "white", borderRadius: "50%", boxShadow: "0 2px 4px rgba(0,0,0,0.2)" }} />
                </div>
              </div>
              <div style={{ display: "flex", gap: 6 }}>
                {[{l:"Wallet",v:"₹240"},{l:"Bonus",v:"₹50"},{l:"Online",v:"6.5h"}].map((s,i) => (
                  <div key={i} style={{ flex: 1, background: "#f0f7ff", borderRadius: 10, padding: "7px 6px", textAlign: "center", border: "1px solid #f3f4f6" }}>
                    <div style={{ fontSize: 8, color: "#9ca3af" }}>{s.l}</div>
                    <div style={{ fontSize: 10, fontWeight: 700, color: "#1c1917", marginTop: 2 }}>{s.v}</div>
                  </div>
                ))}
              </div>
            </div>
          </div>
          <BottomNav active="home" dark={false} accent="#3b82f6" />
        </div>
      </div>
    </PhoneFrame>
  );
}

function LightDriverWallet() {
  return (
    <PhoneFrame bg="white">
      <div style={{ minHeight: 428, background: "white" }}>
        <div style={{ background: "linear-gradient(135deg,#eff6ff,#eff6ff)", padding: "10px 16px 20px", position: "relative", overflow: "hidden", borderBottom: "1px solid #dbeafe" }}>
          <div style={{ display: "flex", alignItems: "center", gap: 7, marginBottom: 14 }}>
            <JagoLogo size={22} variant="amber" showPilot={true} darkBg={false} />
            <div style={{ fontSize: 8, color: "#2563eb", textTransform: "uppercase", fontWeight: 700, letterSpacing: 1 }}>Driver Wallet</div>
          </div>
          <div style={{ textAlign: "center" }}>
            <div style={{ fontSize: 8, color: "#9ca3af" }}>Current Balance</div>
            <div style={{ fontSize: 30, fontWeight: 900, color: "#16a34a", lineHeight: 1, marginTop: 4 }}>₹1,240</div>
            <div style={{ fontSize: 8, color: "#9ca3af", marginTop: 3 }}>This month: ₹8,400</div>
          </div>
          <div style={{ display: "flex", gap: 8, marginTop: 14 }}>
            <div style={{ flex: 1, background: "#dcfce7", border: "1px solid #bbf7d0", borderRadius: 12, padding: "9px 0", textAlign: "center", fontSize: 10, fontWeight: 700, color: "#16a34a" }}>📥 Add Cash</div>
            <div style={{ flex: 1, background: "#dbeafe", border: "1px solid #bfdbfe", borderRadius: 12, padding: "9px 0", textAlign: "center", fontSize: 10, fontWeight: 700, color: "#2563eb" }}>📤 Withdraw</div>
          </div>
        </div>

        <div style={{ padding: "12px 14px" }}>
          <div style={{ fontSize: 9, color: "#9ca3af", textTransform: "uppercase", fontWeight: 700, letterSpacing: 1, marginBottom: 8 }}>Transactions</div>
          {[
            { icon: "🚗", label: "Trip Commission", sub: "TRP97842 · Today", amt: "-₹27.50", c: "#ef4444" },
            { icon: "⭐", label: "Peak Hour Bonus", sub: "Yesterday", amt: "+₹50", c: "#16a34a" },
            { icon: "🚗", label: "Trip Commission", sub: "TRP97801 · Yesterday", amt: "-₹18.20", c: "#ef4444" },
            { icon: "💰", label: "Wallet Credit", sub: "Admin · 3 days ago", amt: "+₹500", c: "#16a34a" },
          ].map((tx, i) => (
            <div key={i} style={{ display: "flex", alignItems: "center", gap: 9, marginBottom: 7, background: "#f0f9ff", borderRadius: 12, padding: "9px 11px", border: "1px solid #f3f4f6" }}>
              <div style={{ width: 30, height: 30, borderRadius: 9, background: "#f3f4f6", display: "flex", alignItems: "center", justifyContent: "center", fontSize: 13 }}>{tx.icon}</div>
              <div style={{ flex: 1 }}>
                <div style={{ fontSize: 10, fontWeight: 600, color: "#1c1917" }}>{tx.label}</div>
                <div style={{ fontSize: 8, color: "#9ca3af", marginTop: 1 }}>{tx.sub}</div>
              </div>
              <div style={{ fontSize: 11, fontWeight: 700, color: tx.c }}>{tx.amt}</div>
            </div>
          ))}
        </div>
      </div>
    </PhoneFrame>
  );
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// CUSTOMER APP SCREENS — DARK MODE
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

function DarkCustomerSplash() {
  return (
    <PhoneFrame bg="#060d1e">
      <div style={{
        minHeight: 428,
        background: "linear-gradient(160deg, #060d1e 0%, #0c1a2f 45%, #091a35 100%)",
        display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center",
        padding: "0 24px", gap: 0, position: "relative", overflow: "hidden",
      }}>
        <div style={{ position: "absolute", top: "20%", left: "50%", transform: "translateX(-50%)", width: 180, height: 180, borderRadius: "50%", background: "radial-gradient(circle, rgba(37,99,235,0.15) 0%, transparent 70%)" }} />
        <div style={{ position: "absolute", bottom: "10%", right: "-10%", width: 120, height: 120, borderRadius: "50%", background: "radial-gradient(circle, rgba(79,70,229,0.1) 0%, transparent 70%)" }} />

        <JagoLogo size={90} variant="purple" />
        <div style={{ marginTop: 20, width: 48, height: 4, background: "linear-gradient(90deg,#2563eb,#1d4ed8)", borderRadius: 2 }} />
        <div style={{ marginTop: 20, fontSize: 9, color: "#334155" }}>Version 2.0.1</div>
        <div style={{ position: "absolute", bottom: 0, left: 0, right: 0, height: 2, background: "linear-gradient(90deg, transparent, #2563eb44, transparent)" }} />
      </div>
    </PhoneFrame>
  );
}

function DarkCustomerLogin() {
  return (
    <PhoneFrame bg="#060d1e">
      <div style={{ minHeight: 428, background: "linear-gradient(180deg, #060d1e 0%, #091429 100%)", padding: "24px 18px 18px", position: "relative", overflow: "hidden" }}>
        <div style={{ position: "absolute", top: 0, right: 0, width: 140, height: 140, background: "radial-gradient(circle at top right, rgba(37,99,235,0.1) 0%, transparent 70%)" }} />

        <div style={{ display: "flex", alignItems: "center", gap: 8, marginBottom: 20 }}>
          <JagoLogo size={38} variant="purple" />
        </div>

        <div style={{ color: "white", fontSize: 20, fontWeight: 800, lineHeight: 1.2 }}>Hello <span style={{ fontSize: 18 }}>👋</span><br /><span style={{ color: "#93c5fd" }}>Where to?</span></div>
        <div style={{ color: "#475569", fontSize: 10, marginTop: 6 }}>Phone number తో login చేయండి</div>

        <div style={{ marginTop: 22, display: "flex", flexDirection: "column", gap: 10 }}>
          <div>
            <div style={{ fontSize: 9, color: "#64748b", fontWeight: 600, marginBottom: 5, textTransform: "uppercase", letterSpacing: 0.5 }}>Phone Number</div>
            <div style={{ background: "#0e2040", borderRadius: 14, padding: "11px 13px", display: "flex", alignItems: "center", gap: 8, border: "1.5px solid #2563eb44", boxShadow: "0 0 0 3px rgba(37,99,235,0.05)" }}>
              <div style={{ padding: "2px 6px", background: "rgba(37,99,235,0.2)", borderRadius: 6, fontSize: 10, color: "#93c5fd", fontWeight: 700 }}>+91</div>
              <div style={{ width: 1, height: 14, background: "#334155" }} />
              <span style={{ fontSize: 11, color: "#64748b" }}>98765 43210</span>
            </div>
          </div>

          <div>
            <div style={{ fontSize: 9, color: "#64748b", fontWeight: 600, marginBottom: 5, textTransform: "uppercase", letterSpacing: 0.5 }}>OTP</div>
            <div style={{ display: "flex", gap: 6, justifyContent: "center" }}>
              {["8","4","2","•"].map((d, i) => (
                <div key={i} style={{
                  flex: 1, background: d !== "•" ? "rgba(37,99,235,0.1)" : "#0e2040",
                  border: `1.5px solid ${d !== "•" ? "#2563eb55" : "#1e293b"}`,
                  borderRadius: 12, padding: "10px 0", textAlign: "center",
                  color: d !== "•" ? "white" : "#334155", fontSize: 15, fontWeight: 800,
                }}>{d}</div>
              ))}
            </div>
          </div>

          <div style={{ marginTop: 4, background: "linear-gradient(135deg,#2563eb,#1d4ed8)", borderRadius: 14, padding: "12px 0", textAlign: "center", color: "white", fontSize: 12, fontWeight: 700, letterSpacing: 0.5, boxShadow: "0 8px 24px rgba(37,99,235,0.4)" }}>Verify & Continue →</div>

          <div style={{ textAlign: "center", padding: "10px 12px", background: "#0e2040", borderRadius: 12, display: "flex", gap: 8, alignItems: "center" }}>
            <span style={{ fontSize: 14 }}>🔒</span>
            <span style={{ fontSize: 8.5, color: "#475569" }}>Your number is secure. We never share data.</span>
          </div>
        </div>
      </div>
    </PhoneFrame>
  );
}

function DarkCustomerHome() {
  return (
    <PhoneFrame bg="#060d1e">
      <div style={{ minHeight: 428, background: "#060d1e", position: "relative", overflow: "hidden", display: "flex", flexDirection: "column" }}>
        <CityMap dark={true} driverMode={false} />

        {/* Nearby vehicles on map */}
        {[{t:"36%",l:"26%"},{t:"52%",l:"64%"},{t:"62%",l:"38%"}].map((p,i) => (
          <div key={i} style={{ position: "absolute", top: p.t, left: p.l, zIndex: 2, width: 20, height: 20, background: "rgba(37,99,235,0.2)", borderRadius: "50%", display: "flex", alignItems: "center", justifyContent: "center", fontSize: 10 }}>🚗</div>
        ))}

        {/* User location pin */}
        <div style={{ position: "absolute", top: "46%", left: "46%", zIndex: 2, display: "flex", flexDirection: "column", alignItems: "center" }}>
          <div style={{ width: 16, height: 16, background: "#2563eb", borderRadius: "50%", border: "3px solid white", boxShadow: "0 0 0 6px rgba(37,99,235,0.25)" }} />
          <div style={{ width: 2, height: 7, background: "#2563eb" }} />
        </div>

        {/* Top bar */}
        <div style={{ position: "relative", zIndex: 3, padding: "8px 14px" }}>
          <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
            <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
              <JagoLogo size={24} variant="purple" />
              <div>
                <div style={{ fontSize: 7, color: "#475569" }}>Good Morning 👋</div>
                <div style={{ fontSize: 12, fontWeight: 800, color: "white" }}>Arjun Reddy</div>
              </div>
            </div>
            <div style={{ display: "flex", gap: 6, alignItems: "center" }}>
              <div style={{ background: "rgba(37,99,235,0.15)", border: "1px solid rgba(37,99,235,0.3)", borderRadius: 20, padding: "4px 10px", fontSize: 9, fontWeight: 700, color: "#93c5fd" }}>₹250</div>
              <div style={{ position: "relative" }}>
                <div style={{ width: 30, height: 30, borderRadius: 10, background: "rgba(255,255,255,0.07)", display: "flex", alignItems: "center", justifyContent: "center" }}>
                  <svg width="14" height="14" viewBox="0 0 24 24" fill="none"><path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9M13.73 21a2 2 0 0 1-3.46 0" stroke="#93c5fd" strokeWidth="2" strokeLinecap="round"/></svg>
                </div>
                <div style={{ position: "absolute", top: -2, right: -2, width: 7, height: 7, borderRadius: "50%", background: "#ef4444", border: "1.5px solid #060d1e" }} />
              </div>
            </div>
          </div>
        </div>

        <div style={{ flex: 1 }} />

        {/* Bottom search sheet */}
        <div style={{ position: "relative", zIndex: 3 }}>
          <div style={{ background: "linear-gradient(180deg,transparent,rgba(6,13,30,0.96) 30%)", padding: "20px 14px 0" }}>
            <div style={{ background: "#0c1a2f", borderRadius: "22px 22px 0 0", padding: "14px 14px 0", border: "1px solid rgba(37,99,235,0.18)", borderBottom: "none" }}>
              <div style={{ width: 36, height: 4, background: "#0e2040", borderRadius: 2, margin: "0 auto 12px" }} />

              {/* Search bar */}
              <div style={{ background: "#0e2040", borderRadius: 14, padding: "10px 12px", display: "flex", alignItems: "center", gap: 8, marginBottom: 10, border: "1px solid rgba(37,99,235,0.2)" }}>
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none"><circle cx="11" cy="11" r="8" stroke="#2563eb" strokeWidth="2"/><path d="M21 21l-4.35-4.35" stroke="#2563eb" strokeWidth="2" strokeLinecap="round"/></svg>
                <span style={{ fontSize: 10, color: "#64748b" }}>Where do you want to go?</span>
              </div>

              {/* Recent places */}
              <div style={{ display: "flex", gap: 7, marginBottom: 12 }}>
                {[{ic:"🏠",l:"Home",sub:"Ameerpet"},{ic:"💼",l:"Office",sub:"Hi-tech City"},{ic:"⭐",l:"Saved",sub:"2 places"}].map((q,i) => (
                  <div key={i} style={{ flex: 1, background: "#0e2040", border: "1px solid rgba(37,99,235,0.15)", borderRadius: 12, padding: "8px 6px", textAlign: "center" }}>
                    <div style={{ fontSize: 13 }}>{q.ic}</div>
                    <div style={{ fontSize: 8, color: "#93c5fd", marginTop: 2, fontWeight: 700 }}>{q.l}</div>
                    <div style={{ fontSize: 7, color: "#475569", marginTop: 1 }}>{q.sub}</div>
                  </div>
                ))}
              </div>

              {/* Ride type tiles */}
              <div style={{ marginBottom: 4 }}>
                <div style={{ fontSize: 8, color: "#475569", fontWeight: 600, textTransform: "uppercase", letterSpacing: 0.8, marginBottom: 8 }}>Choose Ride</div>
                <div style={{ display: "flex", gap: 7 }}>
                  {[{ic:"🏍️",l:"Bike",p:"₹50",c:"#f97316"},{ic:"🛺",l:"Auto",p:"₹85",c:"#3b82f6",sel:true},{ic:"🚗",l:"Car",p:"₹180",c:"#2563eb"}].map((r,i) => (
                    <div key={i} style={{ flex: 1, background: r.sel ? "rgba(37,99,235,0.18)" : "#0e2040", border: `1.5px solid ${r.sel ? "#2563eb" : "rgba(37,99,235,0.1)"}`, borderRadius: 14, padding: "9px 6px", textAlign: "center", boxShadow: r.sel ? "0 0 0 2px rgba(37,99,235,0.12)" : "none" }}>
                      <div style={{ fontSize: 16 }}>{r.ic}</div>
                      <div style={{ fontSize: 9, fontWeight: 700, color: r.sel ? "#93c5fd" : "#94a3b8", marginTop: 3 }}>{r.l}</div>
                      <div style={{ fontSize: 10, fontWeight: 800, color: r.c, marginTop: 1 }}>{r.p}</div>
                    </div>
                  ))}
                </div>
              </div>
              <div style={{ height: 12 }} />
            </div>
          </div>
          <BottomNav active="home" dark accent="#2563eb" />
        </div>
      </div>
    </PhoneFrame>
  );
}

function DarkCustomerTracking() {
  return (
    <PhoneFrame bg="#060d1e">
      <div style={{ minHeight: 428, background: "#060d1e", position: "relative", overflow: "hidden", display: "flex", flexDirection: "column" }}>
        <CityMap dark driverMode={false} />

        {/* Route line on map */}
        <div style={{ position: "absolute", top: "20%", left: "38%", zIndex: 2 }}>
          <div style={{ width: 10, height: 10, background: "#2563eb", borderRadius: "50%", boxShadow: "0 0 12px #2563eb" }} />
          <div style={{ width: 2, height: 55, background: "linear-gradient(180deg,#2563eb,#60a5fa)", borderRadius: 2, marginLeft: 4 }} />
          <div style={{ width: 22, height: 22, background: "linear-gradient(135deg,#3b82f6,#1d4ed8)", borderRadius: "50%", display: "flex", alignItems: "center", justifyContent: "center", fontSize: 10, boxShadow: "0 0 0 5px rgba(59,130,246,0.2)", marginLeft: -4 }}>🚗</div>
          <div style={{ width: 2, height: 35, background: "linear-gradient(180deg,#3b82f6,#60a5fa)", borderRadius: 2, marginLeft: 4 }} />
          <div style={{ width: 10, height: 10, background: "#ef4444", borderRadius: "50%", boxShadow: "0 0 12px #ef4444" }} />
        </div>

        {/* Top status bar */}
        <div style={{ position: "relative", zIndex: 3, background: "rgba(6,13,30,0.9)", backdropFilter: "blur(16px)", padding: "8px 14px 10px", borderBottom: "1px solid rgba(37,99,235,0.15)" }}>
          <div style={{ fontSize: 7, color: "#93c5fd", fontWeight: 700, textTransform: "uppercase", letterSpacing: 1.5 }}>● Driver On The Way</div>
          <div style={{ fontSize: 13, fontWeight: 800, color: "white" }}>Arriving in 4 min</div>
        </div>

        <div style={{ flex: 1 }} />

        {/* Bottom driver card */}
        <div style={{ position: "relative", zIndex: 3 }}>
          <div style={{ background: "linear-gradient(180deg,transparent,rgba(6,13,30,0.95) 30%)", padding: "20px 14px 0" }}>
            <div style={{ background: "#0c1a2f", borderRadius: "20px 20px 0 0", padding: "14px 14px 0", border: "1px solid rgba(37,99,235,0.2)", borderBottom: "none" }}>
              <div style={{ width: 36, height: 4, background: "#0e2040", borderRadius: 2, margin: "0 auto 12px" }} />
              <div style={{ display: "flex", alignItems: "center", gap: 10, marginBottom: 10 }}>
                <div style={{ width: 38, height: 38, borderRadius: "50%", background: "linear-gradient(135deg,#3b82f6,#1d4ed8)", display: "flex", alignItems: "center", justifyContent: "center", fontWeight: 800, color: "white", fontSize: 15 }}>A</div>
                <div style={{ flex: 1 }}>
                  <div style={{ fontSize: 12, fontWeight: 700, color: "white" }}>Anil Driver</div>
                  <div style={{ display: "flex", gap: 1 }}>{[...Array(5)].map((_,i) => <span key={i} style={{ fontSize: 8, color: "#3b82f6" }}>★</span>)}<span style={{ fontSize: 8, color: "#64748b", marginLeft: 3 }}>4.9</span></div>
                </div>
                <div style={{ display: "flex", gap: 5 }}>
                  {[{ic:<svg width="14" height="14" viewBox="0 0 24 24" fill="none"><path d="M22 16.92v3a2 2 0 0 1-2.18 2 19.79 19.79 0 0 1-8.63-3.07A19.5 19.5 0 0 1 4.69 11a19.79 19.79 0 0 1-3.07-8.67A2 2 0 0 1 3.6 0h3a2 2 0 0 1 2 1.72c.127.96.361 1.903.7 2.81a2 2 0 0 1-.45 2.11L7.91 7.91a16 16 0 0 0 6.07 6.07l.9-.9a2 2 0 0 1 2.11-.45c.907.339 1.85.573 2.81.7A2 2 0 0 1 22 16.92z" fill="#93c5fd"/></svg>}, {ic:<svg width="14" height="14" viewBox="0 0 24 24" fill="none"><path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z" fill="#93c5fd"/></svg>}].map((btn,i) => (
                    <div key={i} style={{ width: 32, height: 32, borderRadius: "50%", background: "#0e2040", border: "1px solid rgba(37,99,235,0.2)", display: "flex", alignItems: "center", justifyContent: "center" }}>{btn.ic}</div>
                  ))}
                </div>
              </div>
              <div style={{ background: "#0e2040", borderRadius: 14, padding: "10px 12px", border: "1px solid rgba(37,99,235,0.15)", textAlign: "center", marginBottom: 12 }}>
                <div style={{ fontSize: 8, color: "#93c5fd", fontWeight: 600, textTransform: "uppercase", letterSpacing: 1 }}>Your OTP</div>
                <div style={{ fontSize: 26, fontWeight: 900, color: "white", letterSpacing: 8, marginTop: 4 }}>7923</div>
                <div style={{ fontSize: 7.5, color: "#475569", marginTop: 3 }}>Share with driver on arrival</div>
              </div>
            </div>
          </div>
          <BottomNav active="home" dark accent="#2563eb" />
        </div>
      </div>
    </PhoneFrame>
  );
}

function DarkCustomerWallet() {
  return (
    <PhoneFrame bg="#060d1e">
      <div style={{ minHeight: 428, background: "#060d1e" }}>
        <div style={{ background: "linear-gradient(135deg,#0c1a2f,#091a35)", padding: "10px 16px 20px", position: "relative", overflow: "hidden" }}>
          <div style={{ display: "flex", alignItems: "center", gap: 7, marginBottom: 14 }}>
            <JagoLogo size={22} variant="purple" />
            <div style={{ fontSize: 8, color: "#93c5fd", textTransform: "uppercase", fontWeight: 600, letterSpacing: 1 }}>My Wallet</div>
          </div>
          <div style={{ textAlign: "center" }}>
            <div style={{ fontSize: 8, color: "#475569" }}>Available Balance</div>
            <div style={{ fontSize: 30, fontWeight: 900, color: "#93c5fd", lineHeight: 1, marginTop: 4 }}>₹250.00</div>
            <div style={{ fontSize: 8, color: "#475569", marginTop: 3 }}>Total spent: ₹3,200 this month</div>
          </div>
          <div style={{ display: "flex", gap: 8, marginTop: 14 }}>
            <div style={{ flex: 1, background: "rgba(37,99,235,0.15)", border: "1px solid rgba(37,99,235,0.25)", borderRadius: 12, padding: "9px 0", textAlign: "center", fontSize: 10, fontWeight: 700, color: "#93c5fd" }}>💳 Add Money</div>
            <div style={{ flex: 1, background: "rgba(34,197,94,0.1)", border: "1px solid rgba(34,197,94,0.2)", borderRadius: 12, padding: "9px 0", textAlign: "center", fontSize: 10, fontWeight: 700, color: "#22c55e" }}>🎁 Rewards</div>
          </div>
        </div>

        <div style={{ padding: "12px 14px" }}>
          <div style={{ fontSize: 9, color: "#334155", textTransform: "uppercase", fontWeight: 700, letterSpacing: 1, marginBottom: 8 }}>Trip History</div>
          {[
            { icon: "🚗", label: "Auto Ride", sub: "MGBS → Banjara Hills", amt: "-₹185", c: "#f87171" },
            { icon: "🚖", label: "Car Ride", sub: "Airport → Home", amt: "-₹450", c: "#f87171" },
            { icon: "💳", label: "Wallet Recharge", sub: "UPI Payment", amt: "+₹500", c: "#86efac" },
            { icon: "🚗", label: "Bike Ride", sub: "Office → Lunch", amt: "-₹60", c: "#f87171" },
          ].map((tx, i) => (
            <div key={i} style={{ display: "flex", alignItems: "center", gap: 9, marginBottom: 7, background: "#0c1a2f", borderRadius: 12, padding: "9px 11px", border: "1px solid rgba(37,99,235,0.12)" }}>
              <div style={{ width: 30, height: 30, borderRadius: 9, background: "#0e2040", display: "flex", alignItems: "center", justifyContent: "center", fontSize: 13 }}>{tx.icon}</div>
              <div style={{ flex: 1 }}>
                <div style={{ fontSize: 10, fontWeight: 600, color: "white" }}>{tx.label}</div>
                <div style={{ fontSize: 8, color: "#334155", marginTop: 1 }}>{tx.sub}</div>
              </div>
              <div style={{ fontSize: 11, fontWeight: 700, color: tx.c }}>{tx.amt}</div>
            </div>
          ))}
        </div>
      </div>
    </PhoneFrame>
  );
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// CUSTOMER APP SCREENS — LIGHT MODE
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

function LightCustomerSplash() {
  return (
    <PhoneFrame bg="white">
      <div style={{ minHeight: 428, background: "linear-gradient(160deg, #dbeafe 0%, #bfdbfe 40%, #93c5fd 80%, #93c5fd 100%)", display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", padding: "0 24px", gap: 0, position: "relative", overflow: "hidden" }}>
        <div style={{ position: "absolute", top: "10%", right: "5%", width: 100, height: 100, borderRadius: "50%", background: "rgba(255,255,255,0.2)" }} />
        <div style={{ position: "absolute", bottom: "15%", left: "5%", width: 80, height: 80, borderRadius: "50%", background: "rgba(255,255,255,0.15)" }} />

        <div style={{ background: "rgba(0,0,0,0.55)", borderRadius: 22, padding: "14px 22px", backdropFilter: "blur(8px)", boxShadow: "0 20px 50px rgba(0,0,0,0.3)" }}>
          <img src="/jago-logo.png" alt="JAGO" style={{ height: 72, width: "auto", objectFit: "contain" }} />
        </div>
        <div style={{ marginTop: 32, width: 48, height: 4, background: "rgba(255,255,255,0.6)", borderRadius: 2 }} />
        <div style={{ marginTop: 20, fontSize: 9, color: "rgba(255,255,255,0.5)" }}>Version 2.0.1</div>
      </div>
    </PhoneFrame>
  );
}

function LightCustomerLogin() {
  return (
    <PhoneFrame bg="white">
      <div style={{ minHeight: 428, background: "white", padding: "24px 18px 18px", position: "relative", overflow: "hidden" }}>
        <div style={{ position: "absolute", top: 0, left: 0, right: 0, height: 4, background: "linear-gradient(90deg,#2563eb,#1d4ed8)" }} />
        <div style={{ position: "absolute", top: 0, right: 0, width: 140, height: 140, background: "radial-gradient(circle at top right, rgba(37,99,235,0.06) 0%, transparent 70%)" }} />

        <div style={{ display: "flex", alignItems: "center", gap: 8, marginBottom: 22 }}>
          <JagoLogo size={32} variant="purple" darkBg={false} />
        </div>

        <div style={{ color: "#1c1917", fontSize: 20, fontWeight: 800, lineHeight: 1.2 }}>Hello <span style={{ fontSize: 18 }}>👋</span><br /><span style={{ color: "#2563eb" }}>Where to?</span></div>
        <div style={{ color: "#9ca3af", fontSize: 10, marginTop: 6 }}>Phone number తో login చేయండి</div>

        <div style={{ marginTop: 22, display: "flex", flexDirection: "column", gap: 10 }}>
          <div>
            <div style={{ fontSize: 9, color: "#6b7280", fontWeight: 600, marginBottom: 5, textTransform: "uppercase", letterSpacing: 0.5 }}>Phone Number</div>
            <div style={{ background: "#f0f9ff", borderRadius: 14, padding: "11px 13px", display: "flex", alignItems: "center", gap: 8, border: "1.5px solid #2563eb66", boxShadow: "0 0 0 3px rgba(37,99,235,0.06)" }}>
              <div style={{ padding: "2px 7px", background: "#dbeafe", borderRadius: 6, fontSize: 10, color: "#2563eb", fontWeight: 700 }}>+91</div>
              <div style={{ width: 1, height: 14, background: "#e5e7eb" }} />
              <span style={{ fontSize: 11, color: "#9ca3af" }}>98765 43210</span>
            </div>
          </div>

          <div>
            <div style={{ fontSize: 9, color: "#6b7280", fontWeight: 600, marginBottom: 5, textTransform: "uppercase", letterSpacing: 0.5 }}>OTP</div>
            <div style={{ display: "flex", gap: 6, justifyContent: "center" }}>
              {["8","4","2","•"].map((d, i) => (
                <div key={i} style={{
                  flex: 1, background: d !== "•" ? "#dbeafe" : "#f0f9ff",
                  border: `1.5px solid ${d !== "•" ? "#2563eb" : "#e5e7eb"}`,
                  borderRadius: 12, padding: "10px 0", textAlign: "center",
                  color: d !== "•" ? "#2563eb" : "#d1d5db", fontSize: 15, fontWeight: 800,
                  boxShadow: d === "8" ? "0 0 0 3px rgba(37,99,235,0.1)" : "none",
                }}>{d}</div>
              ))}
            </div>
          </div>

          <div style={{ marginTop: 4, background: "linear-gradient(135deg,#2563eb,#1d4ed8)", borderRadius: 14, padding: "12px 0", textAlign: "center", color: "white", fontSize: 12, fontWeight: 700, letterSpacing: 0.5, boxShadow: "0 8px 24px rgba(37,99,235,0.35)" }}>Verify & Continue →</div>

          <div style={{ textAlign: "center", padding: "10px 12px", background: "#f0f7ff", borderRadius: 12, display: "flex", gap: 8, alignItems: "center", border: "1px solid #dbeafe" }}>
            <span style={{ fontSize: 14 }}>🔒</span>
            <span style={{ fontSize: 8.5, color: "#9ca3af" }}>Your number is secure. We never share data.</span>
          </div>
        </div>
      </div>
    </PhoneFrame>
  );
}

function LightCustomerHome() {
  return (
    <PhoneFrame bg="#eff6ff">
      <div style={{ minHeight: 428, background: "#eff6ff", position: "relative", overflow: "hidden", display: "flex", flexDirection: "column" }}>
        <CityMap dark={false} driverMode={false} />

        {/* Nearby vehicles */}
        {[{t:"36%",l:"24%"},{t:"50%",l:"65%"},{t:"60%",l:"40%"}].map((p,i) => (
          <div key={i} style={{ position: "absolute", top: p.t, left: p.l, zIndex: 2, width: 20, height: 20, background: "rgba(37,99,235,0.15)", borderRadius: "50%", border: "1px solid rgba(37,99,235,0.3)", display: "flex", alignItems: "center", justifyContent: "center", fontSize: 10 }}>🚗</div>
        ))}

        {/* User pin */}
        <div style={{ position: "absolute", top: "46%", left: "46%", zIndex: 2, display: "flex", flexDirection: "column", alignItems: "center" }}>
          <div style={{ width: 16, height: 16, background: "#2563eb", borderRadius: "50%", border: "3px solid white", boxShadow: "0 4px 14px rgba(37,99,235,0.4),0 0 0 8px rgba(37,99,235,0.1)" }} />
          <div style={{ width: 2, height: 7, background: "#2563eb" }} />
        </div>

        {/* Top bar */}
        <div style={{ position: "relative", zIndex: 3, padding: "8px 14px" }}>
          <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
            <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
              <JagoLogo size={24} variant="purple" darkBg={false} />
              <div>
                <div style={{ fontSize: 7, color: "#6b7280" }}>Good Morning 👋</div>
                <div style={{ fontSize: 12, fontWeight: 800, color: "#1c1917" }}>Arjun Reddy</div>
              </div>
            </div>
            <div style={{ display: "flex", gap: 6, alignItems: "center" }}>
              <div style={{ background: "white", border: "1px solid #dbeafe", borderRadius: 20, padding: "4px 10px", fontSize: 9, fontWeight: 700, color: "#2563eb", boxShadow: "0 2px 8px rgba(37,99,235,0.12)" }}>₹250</div>
              <div style={{ position: "relative" }}>
                <div style={{ width: 30, height: 30, borderRadius: 10, background: "white", boxShadow: "0 2px 8px rgba(0,0,0,0.1)", display: "flex", alignItems: "center", justifyContent: "center" }}>
                  <svg width="14" height="14" viewBox="0 0 24 24" fill="none"><path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9M13.73 21a2 2 0 0 1-3.46 0" stroke="#2563eb" strokeWidth="2" strokeLinecap="round"/></svg>
                </div>
                <div style={{ position: "absolute", top: -2, right: -2, width: 7, height: 7, borderRadius: "50%", background: "#ef4444", border: "1.5px solid #eff6ff" }} />
              </div>
            </div>
          </div>
        </div>

        <div style={{ flex: 1 }} />

        {/* Bottom search sheet */}
        <div style={{ position: "relative", zIndex: 3 }}>
          <div style={{ background: "linear-gradient(180deg,transparent,rgba(245,243,255,0.96) 30%)", padding: "20px 14px 0" }}>
            <div style={{ background: "white", borderRadius: "22px 22px 0 0", padding: "14px 14px 0", boxShadow: "0 -8px 30px rgba(37,99,235,0.1)", border: "1px solid #dbeafe", borderBottom: "none" }}>
              <div style={{ width: 36, height: 4, background: "#f3f4f6", borderRadius: 2, margin: "0 auto 12px" }} />

              {/* Search bar */}
              <div style={{ background: "#f0f7ff", borderRadius: 14, padding: "10px 12px", display: "flex", alignItems: "center", gap: 8, marginBottom: 10, border: "1.5px solid #dbeafe" }}>
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none"><circle cx="11" cy="11" r="8" stroke="#2563eb" strokeWidth="2"/><path d="M21 21l-4.35-4.35" stroke="#2563eb" strokeWidth="2" strokeLinecap="round"/></svg>
                <span style={{ fontSize: 10, color: "#9ca3af" }}>Where do you want to go?</span>
              </div>

              {/* Quick places */}
              <div style={{ display: "flex", gap: 7, marginBottom: 10 }}>
                {[{ic:"🏠",l:"Home",sub:"Ameerpet"},{ic:"💼",l:"Office",sub:"Hi-tech City"},{ic:"⭐",l:"Saved",sub:"2 places"}].map((q,i) => (
                  <div key={i} style={{ flex: 1, background: "#f0f7ff", border: "1px solid #dbeafe", borderRadius: 12, padding: "8px 6px", textAlign: "center" }}>
                    <div style={{ fontSize: 13 }}>{q.ic}</div>
                    <div style={{ fontSize: 8, color: "#2563eb", marginTop: 2, fontWeight: 700 }}>{q.l}</div>
                    <div style={{ fontSize: 7, color: "#9ca3af", marginTop: 1 }}>{q.sub}</div>
                  </div>
                ))}
              </div>

              {/* Ride type tiles */}
              <div style={{ marginBottom: 4 }}>
                <div style={{ fontSize: 8, color: "#9ca3af", fontWeight: 600, textTransform: "uppercase", letterSpacing: 0.8, marginBottom: 8 }}>Choose Ride</div>
                <div style={{ display: "flex", gap: 7 }}>
                  {[{ic:"🏍️",l:"Bike",p:"₹50",c:"#f97316"},{ic:"🛺",l:"Auto",p:"₹85",c:"#3b82f6",sel:true},{ic:"🚗",l:"Car",p:"₹180",c:"#2563eb"}].map((r,i) => (
                    <div key={i} style={{ flex: 1, background: r.sel ? "#dbeafe" : "#f0f7ff", border: `1.5px solid ${r.sel ? "#2563eb" : "#dbeafe"}`, borderRadius: 14, padding: "9px 6px", textAlign: "center" }}>
                      <div style={{ fontSize: 16 }}>{r.ic}</div>
                      <div style={{ fontSize: 9, fontWeight: 700, color: r.sel ? "#2563eb" : "#6b7280", marginTop: 3 }}>{r.l}</div>
                      <div style={{ fontSize: 10, fontWeight: 800, color: r.c, marginTop: 1 }}>{r.p}</div>
                    </div>
                  ))}
                </div>
              </div>
              <div style={{ height: 12 }} />
            </div>
          </div>
          <BottomNav active="home" dark={false} accent="#2563eb" />
        </div>
      </div>
    </PhoneFrame>
  );
}

function LightCustomerTracking() {
  return (
    <PhoneFrame bg="white">
      <div style={{ minHeight: 428, background: "white", position: "relative", overflow: "hidden", display: "flex", flexDirection: "column" }}>
        <CityMap dark={false} driverMode={false} />

        {/* Route on map */}
        <div style={{ position: "absolute", top: "20%", left: "38%", zIndex: 2 }}>
          <div style={{ width: 10, height: 10, background: "#2563eb", borderRadius: "50%", boxShadow: "0 0 12px rgba(37,99,235,0.5)" }} />
          <div style={{ width: 2, height: 55, background: "linear-gradient(180deg,#2563eb,#60a5fa)", borderRadius: 2, marginLeft: 4 }} />
          <div style={{ width: 22, height: 22, background: "linear-gradient(135deg,#2563eb,#1d4ed8)", borderRadius: "50%", display: "flex", alignItems: "center", justifyContent: "center", fontSize: 10, boxShadow: "0 0 0 5px rgba(37,99,235,0.15)", marginLeft: -4 }}>🚗</div>
          <div style={{ width: 2, height: 35, background: "linear-gradient(180deg,#93c5fd,#2563eb)", borderRadius: 2, marginLeft: 4 }} />
          <div style={{ width: 10, height: 10, background: "#ef4444", borderRadius: "50%", boxShadow: "0 0 10px rgba(239,68,68,0.5)" }} />
        </div>

        {/* Top status bar */}
        <div style={{ position: "relative", zIndex: 3, background: "rgba(255,255,255,0.9)", backdropFilter: "blur(16px)", padding: "8px 14px 10px", borderBottom: "1px solid rgba(37,99,235,0.1)" }}>
          <div style={{ fontSize: 7, color: "#2563eb", fontWeight: 700, textTransform: "uppercase", letterSpacing: 1.5 }}>● Driver On The Way</div>
          <div style={{ fontSize: 13, fontWeight: 800, color: "#1c1917" }}>Arriving in 4 min</div>
        </div>

        <div style={{ flex: 1 }} />

        {/* Bottom driver card */}
        <div style={{ position: "relative", zIndex: 3 }}>
          <div style={{ background: "linear-gradient(180deg,transparent,rgba(255,255,255,0.97) 30%)", padding: "20px 14px 0" }}>
            <div style={{ background: "white", borderRadius: "20px 20px 0 0", padding: "14px 14px 0", boxShadow: "0 -8px 30px rgba(37,99,235,0.1)", border: "1px solid #dbeafe", borderBottom: "none" }}>
              <div style={{ width: 36, height: 4, background: "#f3f4f6", borderRadius: 2, margin: "0 auto 12px" }} />
              <div style={{ display: "flex", alignItems: "center", gap: 10, marginBottom: 10 }}>
                <div style={{ width: 38, height: 38, borderRadius: "50%", background: "linear-gradient(135deg,#3b82f6,#1d4ed8)", display: "flex", alignItems: "center", justifyContent: "center", fontWeight: 800, color: "white", fontSize: 15 }}>A</div>
                <div style={{ flex: 1 }}>
                  <div style={{ fontSize: 12, fontWeight: 700, color: "#1c1917" }}>Anil Driver</div>
                  <div style={{ display: "flex", gap: 1 }}>{[...Array(5)].map((_,i) => <span key={i} style={{ fontSize: 8, color: "#3b82f6" }}>★</span>)}<span style={{ fontSize: 8, color: "#9ca3af", marginLeft: 3 }}>4.9</span></div>
                </div>
                <div style={{ display: "flex", gap: 5 }}>
                  {[{ic:<svg width="14" height="14" viewBox="0 0 24 24" fill="none"><path d="M22 16.92v3a2 2 0 0 1-2.18 2 19.79 19.79 0 0 1-8.63-3.07A19.5 19.5 0 0 1 4.69 11a19.79 19.79 0 0 1-3.07-8.67A2 2 0 0 1 3.6 0h3a2 2 0 0 1 2 1.72c.127.96.361 1.903.7 2.81a2 2 0 0 1-.45 2.11L7.91 7.91a16 16 0 0 0 6.07 6.07l.9-.9a2 2 0 0 1 2.11-.45c.907.339 1.85.573 2.81.7A2 2 0 0 1 22 16.92z" fill="#2563eb"/></svg>}, {ic:<svg width="14" height="14" viewBox="0 0 24 24" fill="none"><path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z" fill="#2563eb"/></svg>}].map((btn,i) => (
                    <div key={i} style={{ width: 32, height: 32, borderRadius: "50%", background: "#eff6ff", border: "1px solid #dbeafe", display: "flex", alignItems: "center", justifyContent: "center" }}>{btn.ic}</div>
                  ))}
                </div>
              </div>
              <div style={{ background: "#eff6ff", borderRadius: 14, padding: "10px 12px", border: "1px solid #dbeafe", textAlign: "center", marginBottom: 12 }}>
                <div style={{ fontSize: 8, color: "#2563eb", fontWeight: 700, textTransform: "uppercase", letterSpacing: 1 }}>Your OTP</div>
                <div style={{ fontSize: 26, fontWeight: 900, color: "#2563eb", letterSpacing: 8, marginTop: 4 }}>7923</div>
                <div style={{ fontSize: 7.5, color: "#9ca3af", marginTop: 3 }}>Share with driver on arrival</div>
              </div>
            </div>
          </div>
          <BottomNav active="home" dark={false} accent="#2563eb" />
        </div>
      </div>
    </PhoneFrame>
  );
}

function LightCustomerWallet() {
  return (
    <PhoneFrame bg="white">
      <div style={{ minHeight: 428, background: "white" }}>
        <div style={{ background: "linear-gradient(135deg,#dbeafe,#bfdbfe)", padding: "10px 16px 20px", position: "relative", overflow: "hidden" }}>
          <div style={{ display: "flex", alignItems: "center", gap: 7, marginBottom: 14 }}>
            <JagoLogo size={22} variant="purple" darkBg={false} />
            <div style={{ fontSize: 8, color: "#2563eb", textTransform: "uppercase", fontWeight: 700, letterSpacing: 1 }}>My Wallet</div>
          </div>
          <div style={{ textAlign: "center" }}>
            <div style={{ fontSize: 8, color: "#9ca3af" }}>Available Balance</div>
            <div style={{ fontSize: 30, fontWeight: 900, color: "#2563eb", lineHeight: 1, marginTop: 4 }}>₹250.00</div>
            <div style={{ fontSize: 8, color: "#9ca3af", marginTop: 3 }}>Total spent: ₹3,200 this month</div>
          </div>
          <div style={{ display: "flex", gap: 8, marginTop: 14 }}>
            <div style={{ flex: 1, background: "white", border: "1.5px solid #bfdbfe", borderRadius: 12, padding: "9px 0", textAlign: "center", fontSize: 10, fontWeight: 700, color: "#2563eb", boxShadow: "0 2px 8px rgba(37,99,235,0.1)" }}>💳 Add Money</div>
            <div style={{ flex: 1, background: "#dcfce7", border: "1.5px solid #bbf7d0", borderRadius: 12, padding: "9px 0", textAlign: "center", fontSize: 10, fontWeight: 700, color: "#16a34a" }}>🎁 Rewards</div>
          </div>
        </div>

        <div style={{ padding: "12px 14px" }}>
          <div style={{ fontSize: 9, color: "#9ca3af", textTransform: "uppercase", fontWeight: 700, letterSpacing: 1, marginBottom: 8 }}>Trip History</div>
          {[
            { icon: "🚗", label: "Auto Ride", sub: "MGBS → Banjara Hills", amt: "-₹185", c: "#ef4444" },
            { icon: "🚖", label: "Car Ride", sub: "Airport → Home", amt: "-₹450", c: "#ef4444" },
            { icon: "💳", label: "Wallet Recharge", sub: "UPI Payment", amt: "+₹500", c: "#16a34a" },
            { icon: "🚗", label: "Bike Ride", sub: "Office → Lunch", amt: "-₹60", c: "#ef4444" },
          ].map((tx, i) => (
            <div key={i} style={{ display: "flex", alignItems: "center", gap: 9, marginBottom: 7, background: "#f0f7ff", borderRadius: 12, padding: "9px 11px", border: "1px solid #dbeafe" }}>
              <div style={{ width: 30, height: 30, borderRadius: 9, background: "#dbeafe", display: "flex", alignItems: "center", justifyContent: "center", fontSize: 13 }}>{tx.icon}</div>
              <div style={{ flex: 1 }}>
                <div style={{ fontSize: 10, fontWeight: 600, color: "#1c1917" }}>{tx.label}</div>
                <div style={{ fontSize: 8, color: "#9ca3af", marginTop: 1 }}>{tx.sub}</div>
              </div>
              <div style={{ fontSize: 11, fontWeight: 700, color: tx.c }}>{tx.amt}</div>
            </div>
          ))}
        </div>
      </div>
    </PhoneFrame>
  );
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// DRIVER — LIGHT MODE NEW TRIP NOTIFICATION
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
function LightDriverNewTrip() {
  return (
    <PhoneFrame bg="#eff6ff">
      <div style={{ minHeight: 428, background: "#eff6ff", position: "relative", overflow: "hidden", display: "flex", flexDirection: "column" }}>
        <CityMap dark={false} driverMode />
        <div style={{ position: "absolute", inset: 0, background: "rgba(255,255,255,0.55)", zIndex: 1 }} />

        {/* Pulsing notification center */}
        <div style={{ position: "absolute", top: "24%", left: "50%", transform: "translate(-50%,-50%)", zIndex: 2, display: "flex", alignItems: "center", justifyContent: "center" }}>
          {[90,120,150].map((s,i) => <div key={i} style={{ position: "absolute", width: s, height: s, borderRadius: "50%", border: `1.5px solid rgba(59,130,246,${0.25-i*0.06})` }} />)}
          <div style={{ width: 64, height: 64, borderRadius: "50%", background: "linear-gradient(135deg,#3b82f6,#1d4ed8)", display: "flex", alignItems: "center", justifyContent: "center", boxShadow: "0 0 40px rgba(59,130,246,0.45)", fontSize: 26 }}>🔔</div>
        </div>

        <div style={{ flex: 1 }} />

        {/* Main trip card */}
        <div style={{ position: "relative", zIndex: 3 }}>
          <div style={{ background: "white", borderRadius: "24px 24px 0 0", padding: "14px 14px 0", boxShadow: "0 -12px 40px rgba(59,130,246,0.12)", border: "1px solid rgba(59,130,246,0.15)", borderBottom: "none" }}>
            <div style={{ width: 36, height: 4, background: "#f3f4f6", borderRadius: 2, margin: "0 auto 10px" }} />

            {/* Timer */}
            <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 8 }}>
              <div style={{ fontSize: 11, color: "#2563eb", fontWeight: 800, textTransform: "uppercase", letterSpacing: 1 }}>New Ride Request</div>
              <div style={{ background: "#dbeafe", border: "1px solid #3b82f6", borderRadius: 8, padding: "3px 8px", fontSize: 10, fontWeight: 800, color: "#2563eb" }}>28s</div>
            </div>
            <div style={{ height: 3, background: "#f3f4f6", borderRadius: 2, marginBottom: 12, overflow: "hidden" }}>
              <div style={{ width: "65%", height: "100%", background: "linear-gradient(90deg,#22c55e,#3b82f6,#1d4ed8)", borderRadius: 2 }} />
            </div>

            {/* Customer */}
            <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 10 }}>
              <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
                <div style={{ width: 36, height: 36, borderRadius: "50%", background: "linear-gradient(135deg,#2563eb,#1d4ed8)", display: "flex", alignItems: "center", justifyContent: "center", fontWeight: 800, color: "white", fontSize: 14 }}>A</div>
                <div>
                  <div style={{ fontSize: 12, fontWeight: 800, color: "#1c1917" }}>Arjun Reddy</div>
                  <div style={{ display: "flex", gap: 1 }}>{[...Array(5)].map((_,i) => <span key={i} style={{ fontSize: 8, color: "#3b82f6" }}>★</span>)}<span style={{ fontSize: 8, color: "#9ca3af", marginLeft: 3 }}>4.9</span></div>
                </div>
              </div>
              <div style={{ background: "#dbeafe", border: "1.5px solid #3b82f6", borderRadius: 10, padding: "5px 10px", fontSize: 14, fontWeight: 900, color: "#2563eb" }}>₹185</div>
            </div>

            {/* Route */}
            <div style={{ background: "#f0f9ff", borderRadius: 12, padding: "10px 12px", marginBottom: 10, border: "1px solid #f3f4f6" }}>
              {[{dot:"#22c55e",label:"MGBS Bus Stand, Hyderabad"},{dot:"#ef4444",label:"Banjara Hills Rd No. 12"}].map((loc,i) => (
                <div key={i}>
                  {i > 0 && <div style={{ width: 1.5, height: 8, background: "#e5e7eb", marginLeft: 3, marginTop: 2, marginBottom: 2 }} />}
                  <div style={{ display: "flex", gap: 8, alignItems: "center" }}>
                    <div style={{ width: 8, height: 8, borderRadius: "50%", background: loc.dot, flexShrink: 0 }} />
                    <span style={{ fontSize: 9, color: "#4b5563" }}>{loc.label}</span>
                  </div>
                </div>
              ))}
              <div style={{ display: "flex", gap: 14, marginTop: 8, paddingTop: 8, borderTop: "1px solid #f3f4f6" }}>
                <span style={{ fontSize: 9, color: "#3b82f6", fontWeight: 600 }}>📍 2.4 km pickup</span>
                <span style={{ fontSize: 9, color: "#2563eb", fontWeight: 600 }}>⏱ 8 min ETA</span>
              </div>
            </div>

            {/* Buttons */}
            <div style={{ display: "flex", gap: 8, paddingBottom: 12 }}>
              <div style={{ flex: 1, background: "#f3f4f6", borderRadius: 14, padding: "12px 0", textAlign: "center", fontSize: 11, fontWeight: 600, color: "#6b7280" }}>✕  Decline</div>
              <div style={{ flex: 2, background: "linear-gradient(135deg,#22c55e,#16a34a)", borderRadius: 14, padding: "12px 0", textAlign: "center", fontSize: 12, fontWeight: 800, color: "white", boxShadow: "0 6px 20px rgba(34,197,94,0.35)" }}>✓  Accept Ride</div>
            </div>
          </div>
        </div>
      </div>
    </PhoneFrame>
  );
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// CUSTOMER — BOOKING CONFIRMATION SCREEN
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
function DarkCustomerBooking() {
  const vehicles = [
    {ic:"🏍️",l:"Bike",p:"₹50",eta:"1 min",n:3,c:"#f97316",active:false},
    {ic:"🛺",l:"Auto",p:"₹85",eta:"2 min",n:5,c:"#3b82f6",active:true},
    {ic:"🚗",l:"Car",p:"₹180",eta:"3 min",n:2,c:"#2563eb",active:false},
    {ic:"🚙",l:"SUV",p:"₹350",eta:"5 min",n:1,c:"#3b82f6",active:false},
  ];
  return (
    <PhoneFrame bg="#060d1e">
      <div style={{ minHeight: 428, background: "#060d1e", display: "flex", flexDirection: "column" }}>
        {/* Top route bar */}
        <div style={{ background: "linear-gradient(135deg,#0c1a2f,#0e2040)", padding: "10px 14px 12px", borderBottom: "1px solid rgba(37,99,235,0.15)" }}>
          <div style={{ fontSize: 7, color: "#93c5fd", fontWeight: 700, textTransform: "uppercase", letterSpacing: 1, marginBottom: 6 }}>Choose Your Ride</div>
          <div style={{ background: "#0e2040", borderRadius: 12, padding: "9px 12px", border: "1px solid rgba(37,99,235,0.15)" }}>
            {[{dot:"#22c55e",label:"MGBS Bus Stand, Hyderabad"},{dot:"#ef4444",label:"Banjara Hills Road No. 12"}].map((loc,i) => (
              <div key={i}>
                {i > 0 && <div style={{ width: 1.5, height: 7, background: "#334155", marginLeft: 3, marginTop: 2, marginBottom: 2 }} />}
                <div style={{ display: "flex", gap: 7, alignItems: "center" }}>
                  <div style={{ width: 8, height: 8, borderRadius: "50%", background: loc.dot, boxShadow: `0 0 6px ${loc.dot}`, flexShrink: 0 }} />
                  <span style={{ fontSize: 9, color: "#94a3b8" }}>{loc.label}</span>
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* Vertical vehicle list */}
        <div style={{ flex: 1, overflowY: "auto", padding: "8px 14px" }}>
          {vehicles.map((v,i) => (
            <div key={i} style={{ display: "flex", alignItems: "center", gap: 10, padding: "10px 12px", background: v.active ? "rgba(37,99,235,0.15)" : "#0c1a2f", border: `1.5px solid ${v.active ? "#2563eb" : "rgba(37,99,235,0.08)"}`, borderRadius: 14, marginBottom: 7, position: "relative", overflow: "hidden" }}>
              {v.active && <div style={{ position: "absolute", left: 0, top: 0, bottom: 0, width: 3, background: "#2563eb", borderRadius: "3px 0 0 3px" }} />}
              <div style={{ width: 40, height: 40, background: v.active ? "rgba(37,99,235,0.2)" : "#0e2040", borderRadius: 12, display: "flex", alignItems: "center", justifyContent: "center", fontSize: 20, border: `1px solid ${v.active ? "rgba(37,99,235,0.4)" : "rgba(255,255,255,0.04)"}` }}>{v.ic}</div>
              <div style={{ flex: 1 }}>
                <div style={{ display: "flex", gap: 5, alignItems: "center" }}>
                  <span style={{ fontSize: 12, fontWeight: 700, color: v.active ? "#93c5fd" : "white" }}>{v.l}</span>
                  {v.active && <span style={{ fontSize: 7, background: "#2563eb", color: "white", borderRadius: 4, padding: "1px 5px", fontWeight: 700 }}>SELECTED</span>}
                </div>
                <div style={{ fontSize: 8, color: "#475569", marginTop: 2 }}>⏱ {v.eta} · {v.n} nearby</div>
              </div>
              <div style={{ textAlign: "right" }}>
                <div style={{ fontSize: 14, fontWeight: 900, color: v.c }}>{v.p}</div>
                <div style={{ fontSize: 7, color: "#475569", marginTop: 1 }}>per ride</div>
              </div>
            </div>
          ))}
        </div>

        {/* Book button */}
        <div style={{ padding: "10px 14px 12px", background: "#060d1e", borderTop: "1px solid rgba(37,99,235,0.1)" }}>
          <div style={{ background: "linear-gradient(135deg,#2563eb,#1d4ed8)", borderRadius: 16, padding: "13px 0", textAlign: "center", fontSize: 13, fontWeight: 800, color: "white", boxShadow: "0 8px 24px rgba(37,99,235,0.4)" }}>Book Auto Ride — ₹85</div>
        </div>
      </div>
    </PhoneFrame>
  );
}

function LightCustomerBooking() {
  const vehicles = [
    {ic:"🏍️",l:"Bike",p:"₹50",eta:"1 min",n:3,c:"#f97316",active:false},
    {ic:"🛺",l:"Auto",p:"₹85",eta:"2 min",n:5,c:"#2563eb",active:true},
    {ic:"🚗",l:"Car",p:"₹180",eta:"3 min",n:2,c:"#2563eb",active:false},
    {ic:"🚙",l:"SUV",p:"₹350",eta:"5 min",n:1,c:"#2563eb",active:false},
  ];
  return (
    <PhoneFrame bg="white">
      <div style={{ minHeight: 428, background: "white", display: "flex", flexDirection: "column" }}>
        {/* Top route bar */}
        <div style={{ background: "linear-gradient(135deg,#dbeafe,#eff6ff)", padding: "10px 14px 12px", borderBottom: "1px solid #e5e7eb" }}>
          <div style={{ fontSize: 7, color: "#2563eb", fontWeight: 700, textTransform: "uppercase", letterSpacing: 1, marginBottom: 6 }}>Choose Your Ride</div>
          <div style={{ background: "white", borderRadius: 12, padding: "9px 12px", border: "1px solid #dbeafe", boxShadow: "0 2px 8px rgba(37,99,235,0.06)" }}>
            {[{dot:"#22c55e",label:"MGBS Bus Stand, Hyderabad"},{dot:"#ef4444",label:"Banjara Hills Road No. 12"}].map((loc,i) => (
              <div key={i}>
                {i > 0 && <div style={{ width: 1.5, height: 7, background: "#e5e7eb", marginLeft: 3, marginTop: 2, marginBottom: 2 }} />}
                <div style={{ display: "flex", gap: 7, alignItems: "center" }}>
                  <div style={{ width: 8, height: 8, borderRadius: "50%", background: loc.dot, flexShrink: 0 }} />
                  <span style={{ fontSize: 9, color: "#6b7280" }}>{loc.label}</span>
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* Vertical vehicle list */}
        <div style={{ flex: 1, overflowY: "auto", padding: "8px 14px" }}>
          {vehicles.map((v,i) => (
            <div key={i} style={{ display: "flex", alignItems: "center", gap: 10, padding: "10px 12px", background: v.active ? "#faf5ff" : "#f0f7ff", border: `1.5px solid ${v.active ? "#2563eb" : "#f3f4f6"}`, borderRadius: 14, marginBottom: 7, position: "relative", overflow: "hidden", boxShadow: v.active ? "0 4px 16px rgba(37,99,235,0.1)" : "none" }}>
              {v.active && <div style={{ position: "absolute", left: 0, top: 0, bottom: 0, width: 3, background: "#2563eb", borderRadius: "3px 0 0 3px" }} />}
              <div style={{ width: 40, height: 40, background: v.active ? "#dbeafe" : "#f0f7ff", borderRadius: 12, display: "flex", alignItems: "center", justifyContent: "center", fontSize: 20, border: `1px solid ${v.active ? "#93c5fd" : "#e5e7eb"}` }}>{v.ic}</div>
              <div style={{ flex: 1 }}>
                <div style={{ display: "flex", gap: 5, alignItems: "center" }}>
                  <span style={{ fontSize: 12, fontWeight: 700, color: v.active ? "#2563eb" : "#1c1917" }}>{v.l}</span>
                  {v.active && <span style={{ fontSize: 7, background: "#2563eb", color: "white", borderRadius: 4, padding: "1px 5px", fontWeight: 700 }}>SELECTED</span>}
                </div>
                <div style={{ fontSize: 8, color: "#9ca3af", marginTop: 2 }}>⏱ {v.eta} · {v.n} nearby</div>
              </div>
              <div style={{ textAlign: "right" }}>
                <div style={{ fontSize: 14, fontWeight: 900, color: v.c }}>{v.p}</div>
                <div style={{ fontSize: 7, color: "#9ca3af", marginTop: 1 }}>per ride</div>
              </div>
            </div>
          ))}
        </div>

        {/* Book button */}
        <div style={{ padding: "10px 14px 12px", background: "white", borderTop: "1px solid #f3f4f6" }}>
          <div style={{ background: "linear-gradient(135deg,#2563eb,#1d4ed8)", borderRadius: 16, padding: "13px 0", textAlign: "center", fontSize: 13, fontWeight: 800, color: "white", boxShadow: "0 8px 24px rgba(37,99,235,0.35)" }}>Book Auto Ride — ₹85</div>
        </div>
      </div>
    </PhoneFrame>
  );
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MAIN PAGE
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

export default function AppDesign() {
  const [activeApp, setActiveApp] = useState<AppTab>("driver");
  const [themeMode, setThemeMode] = useState<ThemeMode>("dark");

  const driverScreensDark = [
    { component: <DarkDriverSplash />, title: "Splash Screen", sub: "App launch — JAGO branding" },
    { component: <DarkDriverLogin />, title: "OTP Login", sub: "Phone number verification" },
    { component: <DarkDriverHome />, title: "Home / Map", sub: "Online/offline + live stats" },
    { component: <DarkDriverNewTrip />, title: "New Ride Alert", sub: "Accept / Reject with timer" },
    { component: <DarkDriverOnTrip />, title: "On Trip", sub: "Navigation + customer info" },
    { component: <DarkDriverWallet />, title: "Wallet", sub: "Balance, earnings & history" },
  ];

  const driverScreensLight = [
    { component: <LightDriverSplash />, title: "Splash Screen", sub: "App launch — Light theme" },
    { component: <LightDriverLogin />, title: "OTP Login", sub: "Phone number verification" },
    { component: <LightDriverHome />, title: "Home / Map", sub: "Online/offline + live stats" },
    { component: <LightDriverNewTrip />, title: "New Ride Alert", sub: "Accept / Reject with timer" },
    { component: <DarkDriverOnTrip />, title: "On Trip", sub: "Navigation + customer info" },
    { component: <LightDriverWallet />, title: "Wallet", sub: "Balance, earnings & history" },
  ];

  const customerScreensDark = [
    { component: <DarkCustomerSplash />, title: "Splash Screen", sub: "App launch — JAGO branding" },
    { component: <DarkCustomerLogin />, title: "OTP Login", sub: "Phone number verification" },
    { component: <DarkCustomerHome />, title: "Home / Map", sub: "Find a ride" },
    { component: <DarkCustomerBooking />, title: "Book Ride", sub: "Vehicle selection + price" },
    { component: <DarkCustomerTracking />, title: "Live Tracking", sub: "Driver on the way + OTP" },
    { component: <DarkCustomerWallet />, title: "Wallet", sub: "Balance & trip history" },
  ];

  const customerScreensLight = [
    { component: <LightCustomerSplash />, title: "Splash Screen", sub: "App launch — Light theme" },
    { component: <LightCustomerLogin />, title: "OTP Login", sub: "Phone number verification" },
    { component: <LightCustomerHome />, title: "Home / Map", sub: "Find a ride" },
    { component: <LightCustomerBooking />, title: "Book Ride", sub: "Vehicle selection + price" },
    { component: <LightCustomerTracking />, title: "Live Tracking", sub: "Driver on the way + OTP" },
    { component: <LightCustomerWallet />, title: "Wallet", sub: "Balance & trip history" },
  ];

  const screens = activeApp === "driver"
    ? (themeMode === "dark" ? driverScreensDark : driverScreensLight)
    : (themeMode === "dark" ? customerScreensDark : customerScreensLight);

  const isDriver = activeApp === "driver";
  const accentColor = isDriver ? "#3b82f6" : "#2563eb";
  const accentGrad = isDriver
    ? "linear-gradient(135deg, #3b82f6, #ef4444)"
    : "linear-gradient(135deg, #2563eb, #1d4ed8)";

  return (
    <div className="p-4" style={{ background: "#f8fafc", minHeight: "100vh" }}>
      {/* ── Header ── */}
      <div className="mb-4" style={{ background: "white", borderRadius: 16, padding: "20px 24px", boxShadow: "0 2px 12px rgba(0,0,0,0.06)", border: "1px solid #f1f5f9" }}>
        <div className="d-flex align-items-center justify-content-between flex-wrap gap-3">
          <div className="d-flex align-items-center gap-3">
            {/* JAGO Logo */}
            <div style={{ width: 52, height: 52, background: accentGrad, borderRadius: 16, display: "flex", alignItems: "center", justifyContent: "center", boxShadow: `0 8px 24px ${accentColor}44`, fontSize: 22 }}>{isDriver ? "🚗" : "📱"}</div>
            <div>
              <div style={{ fontWeight: 900, fontSize: 22, color: "#091429", letterSpacing: -0.5 }}>JAGO <span style={{ background: accentGrad, WebkitBackgroundClip: "text", WebkitTextFillColor: "transparent" }}>App Design</span></div>
              <div style={{ fontSize: 12, color: "#94a3b8", marginTop: 1 }}>Flutter App Mockups — Driver & Customer</div>
            </div>
          </div>

          {/* Controls */}
          <div className="d-flex align-items-center gap-2 flex-wrap">
            {/* App Toggle */}
            <div style={{ display: "flex", background: "#f1f5f9", borderRadius: 12, padding: 3, gap: 2 }}>
              {(["driver","customer"] as AppTab[]).map(tab => (
                <button key={tab} onClick={() => setActiveApp(tab)} style={{
                  padding: "7px 16px", borderRadius: 10, border: "none", cursor: "pointer", fontSize: 12, fontWeight: 700, transition: "all 0.2s",
                  background: activeApp === tab ? (tab === "driver" ? "linear-gradient(135deg,#3b82f6,#1d4ed8)" : "linear-gradient(135deg,#2563eb,#1d4ed8)") : "transparent",
                  color: activeApp === tab ? "white" : "#64748b",
                  boxShadow: activeApp === tab ? "0 4px 12px rgba(0,0,0,0.15)" : "none",
                }}>
                  {tab === "driver" ? "🚗 Driver App" : "🧑‍💼 Customer App"}
                </button>
              ))}
            </div>

            {/* Theme Toggle */}
            <div style={{ display: "flex", background: "#f1f5f9", borderRadius: 12, padding: 3, gap: 2 }}>
              {(["dark","light"] as ThemeMode[]).map(mode => (
                <button key={mode} onClick={() => setThemeMode(mode)} style={{
                  padding: "7px 14px", borderRadius: 10, border: "none", cursor: "pointer", fontSize: 12, fontWeight: 700, transition: "all 0.2s",
                  background: themeMode === mode ? (mode === "dark" ? "#1e293b" : "white") : "transparent",
                  color: themeMode === mode ? (mode === "dark" ? "white" : "#1c1917") : "#64748b",
                  boxShadow: themeMode === mode ? "0 4px 12px rgba(0,0,0,0.12)" : "none",
                }}>
                  {mode === "dark" ? "🌙 Dark" : "☀️ Light"}
                </button>
              ))}
            </div>
          </div>
        </div>

        {/* App info strip */}
        <div className="mt-3 d-flex align-items-center gap-3 flex-wrap">
          <div style={{ display: "flex", gap: 8 }}>
            {[
              { label: "Platform", value: "Flutter 3.x" },
              { label: "Theme", value: isDriver ? "Amber + Dark" : "Purple + Indigo" },
              { label: "Screens", value: "6 per mode" },
              { label: "Modes", value: "Light + Dark" },
            ].map((info, i) => (
              <div key={i} style={{ background: "#f8fafc", border: "1px solid #e2e8f0", borderRadius: 8, padding: "4px 10px", fontSize: 10 }}>
                <span style={{ color: "#94a3b8" }}>{info.label}: </span>
                <span style={{ color: "#1e293b", fontWeight: 600 }}>{info.value}</span>
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* ── Color Palette ── */}
      <div className="mb-4" style={{ background: "white", borderRadius: 16, padding: "16px 20px", boxShadow: "0 2px 8px rgba(0,0,0,0.05)", border: "1px solid #f1f5f9" }}>
        <div style={{ fontSize: 11, fontWeight: 700, color: "#64748b", textTransform: "uppercase", letterSpacing: 1, marginBottom: 12 }}>
          {isDriver ? "🚗 Driver App" : "🧑‍💼 Customer App"} — Color Palette
        </div>
        <div className="d-flex gap-2 flex-wrap">
          {(isDriver ? [
            { color: "#060d1e", name: "Dark BG" },
            { color: "#091429", name: "Surface" },
            { color: "#091629", name: "Card" },
            { color: "#3b82f6", name: "Amber" },
            { color: "#ef4444", name: "Red" },
            { color: "#22c55e", name: "Green" },
            { color: "#ffffff", name: "White" },
            { color: "#eff6ff", name: "Light BG" },
          ] : [
            { color: "#060d1e", name: "Dark BG" },
            { color: "#0c1a2f", name: "Surface" },
            { color: "#0e2040", name: "Card" },
            { color: "#2563eb", name: "Purple" },
            { color: "#1d4ed8", name: "Indigo" },
            { color: "#93c5fd", name: "Violet" },
            { color: "#dbeafe", name: "Light BG" },
            { color: "#ffffff", name: "White" },
          ]).map((c, i) => (
            <div key={i} style={{ display: "flex", alignItems: "center", gap: 7, background: "#f8fafc", borderRadius: 10, padding: "6px 10px", border: "1px solid #f1f5f9" }}>
              <div style={{ width: 22, height: 22, background: c.color, borderRadius: 6, border: "1px solid rgba(0,0,0,0.08)", flexShrink: 0 }} />
              <div>
                <div style={{ fontSize: 9, fontWeight: 700, color: "#1e293b" }}>{c.name}</div>
                <div style={{ fontSize: 8, color: "#94a3b8" }}>{c.color}</div>
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* ── Screens Grid ── */}
      <div style={{ overflowX: "auto", paddingBottom: 8 }}>
        <div style={{ display: "flex", gap: 24, minWidth: "max-content", padding: "4px 2px 12px" }}>
          {screens.map((screen, i) => (
            <div key={i} style={{ display: "flex", flexDirection: "column", alignItems: "center" }}>
              {/* Screen number badge */}
              <div style={{
                marginBottom: 10, width: 28, height: 28, borderRadius: "50%",
                background: accentGrad,
                display: "flex", alignItems: "center", justifyContent: "center",
                fontSize: 11, fontWeight: 800, color: "white",
                boxShadow: `0 4px 12px ${accentColor}44`,
              }}>{i + 1}</div>

              {screen.component}
              <ScreenLabel title={screen.title} sub={screen.sub} />
            </div>
          ))}
        </div>
      </div>

      {/* ── Flutter Specs ── */}
      <div className="mt-4 row g-3">
        <div className="col-md-6">
          <div style={{ background: "white", borderRadius: 16, padding: "18px 20px", boxShadow: "0 2px 8px rgba(0,0,0,0.05)", border: "1px solid #f1f5f9", height: "100%" }}>
            <div style={{ fontSize: 11, fontWeight: 700, color: "#64748b", textTransform: "uppercase", letterSpacing: 1, marginBottom: 12 }}>📱 Flutter Dependencies</div>
            <div style={{ background: "#091429", borderRadius: 12, padding: "14px 16px", fontFamily: "monospace", fontSize: 10.5, lineHeight: 1.8, color: "#94a3b8" }}>
              <div><span style={{ color: "#3b82f6" }}>dependencies:</span></div>
              <div>&nbsp;&nbsp;<span style={{ color: "#60a5fa" }}>flutter_map:</span> <span style={{ color: "#86efac" }}>^6.0.0</span></div>
              <div>&nbsp;&nbsp;<span style={{ color: "#60a5fa" }}>dio:</span> <span style={{ color: "#86efac" }}>^5.0.0</span></div>
              <div>&nbsp;&nbsp;<span style={{ color: "#60a5fa" }}>get:</span> <span style={{ color: "#86efac" }}>^4.6.6</span></div>
              <div>&nbsp;&nbsp;<span style={{ color: "#60a5fa" }}>geolocator:</span> <span style={{ color: "#86efac" }}>^11.0.0</span></div>
              <div>&nbsp;&nbsp;<span style={{ color: "#60a5fa" }}>firebase_messaging:</span> <span style={{ color: "#86efac" }}>^14.7.0</span></div>
              <div>&nbsp;&nbsp;<span style={{ color: "#60a5fa" }}>shared_preferences:</span> <span style={{ color: "#86efac" }}>^2.2.0</span></div>
              <div>&nbsp;&nbsp;<span style={{ color: "#60a5fa" }}>socket_io_client:</span> <span style={{ color: "#86efac" }}>^2.0.0</span></div>
              <div>&nbsp;&nbsp;<span style={{ color: "#60a5fa" }}>google_fonts:</span> <span style={{ color: "#86efac" }}>^6.1.0</span></div>
            </div>
          </div>
        </div>

        <div className="col-md-6">
          <div style={{ background: "white", borderRadius: 16, padding: "18px 20px", boxShadow: "0 2px 8px rgba(0,0,0,0.05)", border: "1px solid #f1f5f9", height: "100%" }}>
            <div style={{ fontSize: 11, fontWeight: 700, color: "#64748b", textTransform: "uppercase", letterSpacing: 1, marginBottom: 12 }}>🎨 Design Tokens</div>
            <div style={{ display: "flex", flexDirection: "column", gap: 8 }}>
              {[
                { token: "Font Family", value: "Google Fonts — Poppins / Inter" },
                { token: "Border Radius", value: "12–28px (pill buttons: 50px)" },
                { token: "Spacing Unit", value: "8px grid system" },
                { token: "Icon Library", value: "Lucide Icons / Material Symbols" },
                { token: "Animation", value: "300ms ease cubic-bezier" },
                { token: "Driver Theme", value: "Amber #3b82f6 + Dark #060d1e" },
                { token: "Customer Theme", value: "Purple #2563eb + Indigo #1d4ed8" },
                { token: "Light Mode BG", value: "Driver: #eff6ff · Customer: #dbeafe" },
              ].map((t, i) => (
                <div key={i} style={{ display: "flex", justifyContent: "space-between", alignItems: "center", padding: "6px 10px", background: "#f8fafc", borderRadius: 8, border: "1px solid #f1f5f9" }}>
                  <span style={{ fontSize: 10, color: "#64748b", fontWeight: 600 }}>{t.token}</span>
                  <span style={{ fontSize: 10, color: "#1e293b", fontWeight: 700 }}>{t.value}</span>
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>

      {/* ── API Connection ── */}
      <div className="mt-3" style={{ background: "white", borderRadius: 16, padding: "18px 20px", boxShadow: "0 2px 8px rgba(0,0,0,0.05)", border: "1px solid #f1f5f9" }}>
        <div style={{ fontSize: 11, fontWeight: 700, color: "#64748b", textTransform: "uppercase", letterSpacing: 1, marginBottom: 12 }}>🔗 API Base URL Configuration</div>
        <div style={{ display: "flex", gap: 12, flexWrap: "wrap" }}>
          {[
            { env: "Development", url: "http://localhost:5000", badge: "#22c55e", badgeBg: "#dcfce7" },
            { env: "Staging", url: "https://staging.jagopro.org", badge: "#3b82f6", badgeBg: "#dbeafe" },
            { env: "Production", url: "https://jagopro.org", badge: "#6d28d9", badgeBg: "#dbeafe" },
          ].map((e, i) => (
            <div key={i} style={{ flex: 1, minWidth: 180, background: "#f8fafc", borderRadius: 12, padding: "12px 14px", border: "1px solid #f1f5f9" }}>
              <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 6 }}>
                <div style={{ fontSize: 11, fontWeight: 700, color: "#1e293b" }}>{e.env}</div>
                <div style={{ fontSize: 9, fontWeight: 700, color: e.badge, background: e.badgeBg, padding: "2px 7px", borderRadius: 6 }}>Active</div>
              </div>
              <div style={{ fontFamily: "monospace", fontSize: 10, color: "#64748b", background: "white", padding: "5px 8px", borderRadius: 7, border: "1px solid #e2e8f0" }}>{e.url}</div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
