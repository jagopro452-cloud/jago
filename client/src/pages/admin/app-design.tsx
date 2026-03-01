import { useState } from "react";
import jagoLogoWhite from "@assets/JAGO_LOGO_WightPNG_1772377612337.png";
import jagoLogoBlue  from "@assets/JAGO_LOGOPNG_(1)_1772377612339.png";
import pilotLogo     from "@assets/PILOT_LOGOPNG_1772377649091.png";

type AppTab = "customer" | "driver";

// ── Phone Frame ────────────────────────────────────────────────────────────────
function Phone({ children, bg = "#fff", h = 490 }: { children: React.ReactNode; bg?: string; h?: number }) {
  return (
    <div style={{ display: "flex", justifyContent: "center" }}>
      <div style={{
        width: 235, height: h, background: bg,
        borderRadius: 46,
        border: "9px solid #1c1c28",
        boxShadow: "0 60px 120px rgba(0,0,0,0.55), 0 0 0 1px rgba(255,255,255,0.05), inset 0 0 0 1px rgba(255,255,255,0.04)",
        overflow: "hidden", position: "relative", flexShrink: 0,
      }}>
        {/* Dynamic Island */}
        <div style={{
          position: "absolute", top: 0, left: "50%", transform: "translateX(-50%)",
          width: 94, height: 28, background: "#000",
          borderRadius: "0 0 20px 20px", zIndex: 100,
          display: "flex", alignItems: "center", justifyContent: "center", gap: 6,
        }}>
          <div style={{ width: 8, height: 8, borderRadius: "50%", background: "#1e293b", border: "1px solid #334155" }} />
          <div style={{ width: 3, height: 3, borderRadius: "50%", background: "#475569" }} />
        </div>
        {/* Right power btn */}
        <div style={{ position: "absolute", right: -10, top: 90, width: 5, height: 42, background: "#222", borderRadius: "0 4px 4px 0" }} />
        {/* Left volume btns */}
        <div style={{ position: "absolute", left: -10, top: 76, width: 5, height: 28, background: "#222", borderRadius: "4px 0 0 4px" }} />
        <div style={{ position: "absolute", left: -10, top: 116, width: 5, height: 28, background: "#222", borderRadius: "4px 0 0 4px" }} />
        <div style={{ paddingTop: 30, height: "100%", overflow: "hidden" }}>{children}</div>
      </div>
    </div>
  );
}

function Label({ title, sub }: { title: string; sub: string }) {
  return (
    <div style={{ textAlign: "center", marginTop: 16 }}>
      <div style={{ fontWeight: 700, fontSize: 13, color: "#0f172a" }}>{title}</div>
      <div style={{ fontSize: 10, color: "#94a3b8", marginTop: 3 }}>{sub}</div>
    </div>
  );
}

function Map({ dark = false }: { dark?: boolean }) {
  const bg = dark
    ? "radial-gradient(ellipse at 45% 38%, #0c2050 0%, #060d1e 80%)"
    : "linear-gradient(145deg,#dbeafe 0%,#eff6ff 55%,#f0f7ff 100%)";
  const r = dark ? "rgba(255,255,255,0.055)" : "rgba(0,0,0,0.055)";
  const rb = dark ? "rgba(255,255,255,0.1)" : "rgba(0,0,0,0.09)";
  return (
    <div style={{ position: "absolute", inset: 0, background: bg }}>
      <svg width="100%" height="100%" style={{ position: "absolute", inset: 0 }}>
        {[0,10,20,30,40,50,60,70,80,90,100].map(x=><line key={`v${x}`} x1={`${x}%`} y1="0" x2={`${x}%`} y2="100%" stroke={x%30===0?rb:r} strokeWidth={x%30===0?1.5:.5}/>)}
        {[0,8,16,24,32,40,48,56,64,72,80,88,96].map(y=><line key={`h${y}`} x1="0" y1={`${y}%`} x2="100%" y2={`${y}%`} stroke={y%24===0?rb:r} strokeWidth={y%24===0?1.5:.5}/>)}
        <line x1="5%" y1="42%" x2="100%" y2="58%" stroke={rb} strokeWidth="2"/>
        <line x1="22%" y1="0" x2="36%" y2="100%" stroke={rb} strokeWidth="1.5"/>
        <line x1="68%" y1="0" x2="56%" y2="100%" stroke={rb} strokeWidth="1.5"/>
        <circle cx="44%" cy="51%" r="3%" fill="none" stroke={rb} strokeWidth="1"/>
      </svg>
    </div>
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
// CUSTOMER APP SCREENS
// ═══════════════════════════════════════════════════════════════════════════════

function CustSplash() {
  return (
    <Phone bg="#1244A2">
      <div style={{ height: "100%", background: "linear-gradient(145deg,#0A2040 0%,#1244A2 45%,#1E6DE5 100%)", display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", position: "relative", overflow: "hidden" }}>
        {/* Blobs */}
        <div style={{ position: "absolute", top: "-22%", right: "-22%", width: "90%", height: "90%", borderRadius: "50%", background: "rgba(255,255,255,0.08)" }} />
        <div style={{ position: "absolute", bottom: "-28%", left: "-18%", width: "80%", height: "80%", borderRadius: "50%", background: "rgba(255,255,255,0.05)" }} />
        {/* Diagonal lines */}
        <svg style={{ position: "absolute", inset: 0, opacity: 0.06 }} width="100%" height="100%">
          {[-4,-2,0,2,4,6,8,10,12].map((i,idx)=><line key={idx} x1={`${i*12}%`} y1="0" x2={`${i*12+60}%`} y2="100%" stroke="white" strokeWidth="1"/>)}
        </svg>

        <div style={{ flex: 2 }} />
        {/* Logo card */}
        <div style={{ width: 112, height: 112, background: "white", borderRadius: 32, display: "flex", alignItems: "center", justifyContent: "center", boxShadow: "0 20px 60px rgba(0,0,0,0.25), 0 8px 20px rgba(30,109,229,0.3)", position: "relative" }}>
          {/* Inner glow */}
          <div style={{ position: "absolute", inset: 0, borderRadius: 32, boxShadow: "inset 0 0 0 1px rgba(30,109,229,0.1)" }} />
          <img src={jagoLogoBlue} style={{ width: 80, height: 80, objectFit: "contain" }} alt="JAGO" />
        </div>
        {/* Text */}
        <div style={{ marginTop: 32, textAlign: "center" }}>
          <div style={{ fontSize: 46, fontWeight: 900, color: "white", letterSpacing: 10, textShadow: "0 4px 12px rgba(0,0,0,0.2)" }}>JAGO</div>
          <div style={{ marginTop: 10, display: "inline-block", background: "rgba(255,255,255,0.12)", borderRadius: 20, border: "1px solid rgba(255,255,255,0.18)", padding: "5px 18px", fontSize: 12, color: "rgba(255,255,255,0.85)", letterSpacing: 2.5, fontWeight: 500 }}>Move Smarter.</div>
        </div>
        <div style={{ flex: 3 }} />
        {/* Loader */}
        <div style={{ marginBottom: 44, textAlign: "center" }}>
          <div style={{ width: 20, height: 20, borderRadius: "50%", border: "2px solid rgba(255,255,255,0.2)", borderTop: "2px solid rgba(255,255,255,0.6)", margin: "0 auto 16px" }} />
          <div style={{ fontSize: 10, color: "rgba(255,255,255,0.3)", letterSpacing: 0.3 }}>MindWhile IT Solutions</div>
        </div>
      </div>
    </Phone>
  );
}

function CustLogin() {
  return (
    <Phone bg="white">
      <div style={{ height: "100%", background: "white", overflow: "hidden" }}>
        {/* Header gradient */}
        <div style={{ background: "linear-gradient(135deg,#1244A2,#1E6DE5,#4B9EFF)", padding: "18px 22px 36px", position: "relative", overflow: "hidden" }}>
          <div style={{ position: "absolute", top: -20, right: -20, width: 100, height: 100, borderRadius: "50%", background: "rgba(255,255,255,0.1)" }} />
          <div style={{ position: "absolute", bottom: -30, left: -15, width: 80, height: 80, borderRadius: "50%", background: "rgba(255,255,255,0.06)" }} />
          {/* Logo badge */}
          <div style={{ display: "inline-flex", alignItems: "center", background: "rgba(255,255,255,0.18)", backdropFilter: "blur(8px)", borderRadius: 10, border: "1px solid rgba(255,255,255,0.25)", padding: "6px 14px", marginBottom: 22, position: "relative" }}>
            <img src={jagoLogoWhite} style={{ height: 24, objectFit: "contain" }} alt="JAGO" />
          </div>
          <div style={{ fontSize: 26, fontWeight: 800, color: "white", lineHeight: 1.25, position: "relative" }}>Welcome to<br />JAGO 👋</div>
          <div style={{ fontSize: 12, color: "rgba(255,255,255,0.75)", marginTop: 7, position: "relative" }}>Safe, affordable rides — ఎక్కడైనా</div>
        </div>

        {/* Form */}
        <div style={{ padding: "22px 20px 0" }}>
          <div style={{ fontSize: 11, fontWeight: 700, color: "#374151", marginBottom: 8, letterSpacing: 0.2 }}>Mobile Number</div>
          <div style={{ background: "#F8FAFF", borderRadius: 16, border: "1.5px solid #DDE4F5", display: "flex", alignItems: "center", overflow: "hidden", marginBottom: 18 }}>
            <div style={{ padding: "14px 14px", borderRight: "1.5px solid #DDE4F5", display: "flex", alignItems: "center", gap: 5 }}>
              <span style={{ fontSize: 16 }}>🇮🇳</span>
              <span style={{ fontSize: 14, fontWeight: 800, color: "#111827" }}>+91</span>
            </div>
            <div style={{ padding: "14px 14px", fontSize: 16, fontWeight: 700, color: "rgba(0,0,0,0.18)", letterSpacing: 2.5 }}>00000 00000</div>
          </div>
          {/* Button */}
          <div style={{ background: "linear-gradient(135deg,#1E6DE5,#1244A2)", borderRadius: 16, padding: "14px 0", textAlign: "center", color: "white", fontSize: 15, fontWeight: 800, boxShadow: "0 8px 24px rgba(30,109,229,0.35)", marginBottom: 14, letterSpacing: 0.3 }}>Get OTP →</div>
          <div style={{ display: "flex", justifyContent: "center", alignItems: "center", gap: 5, marginBottom: 22 }}>
            <div style={{ fontSize: 13, opacity: 0.5 }}>🛡</div>
            <span style={{ fontSize: 11, color: "#9CA3AF" }}>Your data is secure & private</span>
          </div>
          {/* Feature chips */}
          <div style={{ display: "flex", gap: 8 }}>
            {[{ic:"⚡",l:"Quick Rides"},{ic:"✅",l:"Verified Pilots"},{ic:"💳",l:"Easy Pay"}].map((f,i)=>(
              <div key={i} style={{ flex: 1, background: "#F8FAFF", borderRadius: 14, border: "1px solid #E8EEFF", padding: "12px 6px", textAlign: "center" }}>
                <div style={{ fontSize: 18, marginBottom: 5 }}>{f.ic}</div>
                <div style={{ fontSize: 9, fontWeight: 700, color: "#374151" }}>{f.l}</div>
              </div>
            ))}
          </div>
        </div>
      </div>
    </Phone>
  );
}

function CustHome() {
  return (
    <Phone bg="#EFF6FF">
      <div style={{ height: "100%", position: "relative", display: "flex", flexDirection: "column" }}>
        <Map dark={false} />
        {/* Location pin */}
        <div style={{ position: "absolute", top: "37%", left: "42%", zIndex: 2 }}>
          <div style={{ width: 28, height: 28, borderRadius: "50%", background: "linear-gradient(135deg,#1E6DE5,#1244A2)", display: "flex", alignItems: "center", justifyContent: "center", boxShadow: "0 0 0 7px rgba(30,109,229,0.12),0 0 0 14px rgba(30,109,229,0.06)", fontSize: 13 }}>📍</div>
        </div>
        {/* Top bar */}
        <div style={{ position: "relative", zIndex: 3, padding: "8px 12px" }}>
          <div style={{ display: "flex", gap: 8 }}>
            <div style={{ width: 36, height: 36, background: "white", borderRadius: 12, boxShadow: "0 3px 12px rgba(0,0,0,0.12)", display: "flex", alignItems: "center", justifyContent: "center" }}>
              <div style={{ display: "flex", flexDirection: "column", gap: 3 }}>
                {[0,1,2].map(i=><div key={i} style={{ width: 12, height: 2, background: "#111827", borderRadius: 1 }}/>)}
              </div>
            </div>
            <div style={{ flex: 1, background: "white", borderRadius: 12, padding: "9px 12px", boxShadow: "0 3px 12px rgba(0,0,0,0.12)", display: "flex", alignItems: "center", gap: 8 }}>
              <div style={{ width: 22, height: 22, borderRadius: "50%", background: "#1E6DE5", display: "flex", alignItems: "center", justifyContent: "center", fontSize: 10, fontWeight: 900, color: "white" }}>A</div>
              <div style={{ fontSize: 12, fontWeight: 700, color: "#111827" }}>Hi Arjun! 👋</div>
              <div style={{ marginLeft: "auto", fontSize: 16 }}>🔔</div>
            </div>
            <div style={{ width: 36, height: 36, background: "white", borderRadius: 12, boxShadow: "0 3px 12px rgba(0,0,0,0.12)", display: "flex", alignItems: "center", justifyContent: "center", fontSize: 16 }}>📍</div>
          </div>
        </div>
        <div style={{ flex: 1 }} />
        {/* Bottom sheet */}
        <div style={{ position: "relative", zIndex: 3, background: "white", borderRadius: "28px 28px 0 0", boxShadow: "0 -6px 30px rgba(0,0,0,0.1)", padding: "6px 16px 18px" }}>
          <div style={{ width: 36, height: 4, background: "#E5E7EB", borderRadius: 2, margin: "8px auto 14px" }} />
          <div style={{ fontSize: 15, fontWeight: 800, color: "#111827", marginBottom: 12 }}>Where are you going?</div>
          {/* Location inputs */}
          <div style={{ background: "#F8FAFF", borderRadius: 16, border: "1px solid #E5EAFF", marginBottom: 14, overflow: "hidden" }}>
            {[{dot:"#1E6DE5",lbl:"Current Location",sub:false},{dot:"#E53935",lbl:"Where to?",sub:true}].map((l,i)=>(
              <div key={i}>
                {i>0&&<div style={{ height: 1, background: "rgba(0,0,0,0.04)", marginLeft: 30 }}/>}
                <div style={{ padding: "10px 14px", display: "flex", alignItems: "center", gap: 10 }}>
                  <div style={{ width: 9, height: 9, borderRadius: l.sub?"2px":"50%", background: l.dot, flexShrink: 0 }}/>
                  <div style={{ fontSize: 11, color: l.sub?"#9CA3AF":"#1E6DE5", fontWeight: l.sub?400:600 }}>{l.lbl}</div>
                  {l.sub&&<div style={{ marginLeft: "auto", width: 22, height: 22, background: "rgba(30,109,229,0.08)", borderRadius: "50%", display: "flex", alignItems: "center", justifyContent: "center", fontSize: 12 }}>🔍</div>}
                </div>
              </div>
            ))}
          </div>
          {/* Vehicle cards */}
          <div style={{ fontSize: 10, fontWeight: 700, color: "#9CA3AF", marginBottom: 8, textTransform: "uppercase", letterSpacing: 0.5 }}>Select Vehicle</div>
          <div style={{ display: "flex", gap: 7, marginBottom: 14 }}>
            {[{n:"Bike",f:"₹20+",ic:"🏍",s:true},{n:"Auto",f:"₹30+",ic:"🛺",s:false},{n:"Parcel",f:"₹25+",ic:"📦",s:false},{n:"Cargo",f:"₹200+",ic:"🚛",s:false}].map((v,i)=>(
              <div key={i} style={{ flex: 1, background: v.s?"#1E6DE5":"white", borderRadius: 14, border: `${v.s?0:1.5}px solid ${v.s?"#1E6DE5":"#E5E9F5"}`, padding: "10px 4px", textAlign: "center", boxShadow: v.s?"0 6px 16px rgba(30,109,229,0.3)":"none" }}>
                <div style={{ fontSize: 18, marginBottom: 4 }}>{v.ic}</div>
                <div style={{ fontSize: 9, fontWeight: 700, color: v.s?"white":"#374151" }}>{v.n}</div>
                <div style={{ fontSize: 9, fontWeight: 800, color: v.s?"rgba(255,255,255,0.8)":"#1E6DE5", marginTop: 2 }}>{v.f}</div>
              </div>
            ))}
          </div>
          <div style={{ background: "linear-gradient(135deg,#1E6DE5,#1244A2)", borderRadius: 16, padding: "14px 0", textAlign: "center", color: "white", fontSize: 14, fontWeight: 800, boxShadow: "0 6px 18px rgba(30,109,229,0.35)", letterSpacing: 0.3 }}>🗺 Find Ride</div>
        </div>
      </div>
    </Phone>
  );
}

function CustTracking() {
  return (
    <Phone bg="#EFF6FF">
      <div style={{ height: "100%", position: "relative", display: "flex", flexDirection: "column" }}>
        <Map dark={false} />
        {/* Route line */}
        <div style={{ position: "absolute", top: "28%", left: "42%", zIndex: 2 }}>
          <div style={{ width: 9, height: 9, borderRadius: "50%", background: "#1E6DE5", boxShadow: "0 0 10px rgba(30,109,229,0.6)" }} />
          <div style={{ width: 2, height: 42, background: "linear-gradient(180deg,#1E6DE5,#E53935)", marginLeft: 3 }} />
          <div style={{ width: 22, height: 22, borderRadius: "50%", background: "#1E6DE5", display: "flex", alignItems: "center", justifyContent: "center", fontSize: 11, boxShadow: "0 0 0 5px rgba(30,109,229,0.15)", marginLeft: -4 }}>🏍</div>
          <div style={{ width: 2, height: 30, background: "linear-gradient(180deg,#1E6DE5,#E53935)", marginLeft: 3 }} />
          <div style={{ width: 9, height: 9, borderRadius: "50%", background: "#E53935", boxShadow: "0 0 10px rgba(229,57,53,0.6)" }} />
        </div>
        <div style={{ flex: 1 }} />
        {/* Bottom sheet */}
        <div style={{ position: "relative", zIndex: 3, background: "white", borderRadius: "28px 28px 0 0", boxShadow: "0 -6px 30px rgba(0,0,0,0.1)", padding: "6px 16px 20px" }}>
          <div style={{ width: 36, height: 4, background: "#E5E7EB", borderRadius: 2, margin: "8px auto 14px" }} />
          {/* Status banner */}
          <div style={{ background: "linear-gradient(135deg,rgba(30,109,229,0.08),rgba(30,109,229,0.04))", borderRadius: 16, border: "1px solid rgba(30,109,229,0.15)", padding: "12px 14px", display: "flex", alignItems: "center", gap: 10, marginBottom: 12 }}>
            <div style={{ fontSize: 22 }}>🏍</div>
            <div>
              <div style={{ fontSize: 13, fontWeight: 800, color: "#1E6DE5" }}>Pilot వస్తున్నాడు!</div>
              <div style={{ fontSize: 10, color: "#9CA3AF", marginTop: 2 }}>~4 min away · Tracking live</div>
            </div>
          </div>
          {/* Driver card */}
          <div style={{ background: "#F8FAFF", borderRadius: 16, border: "1px solid #E5EAFF", padding: "12px 14px", display: "flex", alignItems: "center", gap: 10, marginBottom: 12 }}>
            <div style={{ width: 42, height: 42, background: "linear-gradient(135deg,#1E6DE5,#1244A2)", borderRadius: "50%", display: "flex", alignItems: "center", justifyContent: "center", fontSize: 16, fontWeight: 900, color: "white" }}>A</div>
            <div style={{ flex: 1 }}>
              <div style={{ fontSize: 13, fontWeight: 800, color: "#111827" }}>Arjun Pilot</div>
              <div style={{ fontSize: 10, color: "#6B7280", marginTop: 2 }}>⭐ 4.9 · Bike · TG09AB1234</div>
            </div>
            <div style={{ width: 36, height: 36, background: "rgba(30,109,229,0.1)", borderRadius: 12, display: "flex", alignItems: "center", justifyContent: "center", fontSize: 16 }}>📞</div>
          </div>
          {/* OTP Box */}
          <div style={{ background: "#FFFBEB", borderRadius: 16, border: "1.5px solid rgba(245,158,11,0.3)", padding: "12px 14px", display: "flex", alignItems: "center", gap: 12, marginBottom: 12 }}>
            <div style={{ width: 36, height: 36, background: "rgba(245,158,11,0.12)", borderRadius: 10, display: "flex", alignItems: "center", justifyContent: "center", fontSize: 16 }}>🔐</div>
            <div style={{ flex: 1 }}>
              <div style={{ fontSize: 9, fontWeight: 700, color: "#D97706", marginBottom: 4, textTransform: "uppercase", letterSpacing: 0.5 }}>Share with Pilot</div>
              <div style={{ fontSize: 28, fontWeight: 900, color: "#111827", letterSpacing: 10 }}>4829</div>
            </div>
            <div style={{ fontSize: 18 }}>📋</div>
          </div>
          {/* Fare info */}
          <div style={{ display: "flex", gap: 7, marginBottom: 12 }}>
            {[{ic:"💰",v:"₹85",l:"Fare"},{ic:"📍",v:"3.2km",l:"Distance"},{ic:"🏍",v:"Bike",l:"Vehicle"}].map((c,i)=>(
              <div key={i} style={{ flex: 1, background: "#F8FAFF", borderRadius: 10, border: "1px solid #E5EAFF", padding: "8px 4px", textAlign: "center" }}>
                <div style={{ fontSize: 13, marginBottom: 2 }}>{c.ic}</div>
                <div style={{ fontSize: 11, fontWeight: 800, color: "#1E6DE5" }}>{c.v}</div>
                <div style={{ fontSize: 8, color: "#9CA3AF", marginTop: 1 }}>{c.l}</div>
              </div>
            ))}
          </div>
          <div style={{ border: "1.5px solid rgba(229,57,53,0.25)", borderRadius: 14, padding: "12px 0", textAlign: "center", fontSize: 12, fontWeight: 700, color: "#E53935" }}>✕  Cancel Ride</div>
        </div>
      </div>
    </Phone>
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
// DRIVER APP SCREENS
// ═══════════════════════════════════════════════════════════════════════════════

function PilotSplash() {
  return (
    <Phone bg="#060D1E">
      <div style={{ height: "100%", background: "#060D1E", display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", position: "relative", overflow: "hidden" }}>
        {/* Glow */}
        <div style={{ position: "absolute", top: "-15%", right: "-15%", width: "75%", height: "75%", borderRadius: "50%", background: "radial-gradient(circle,rgba(37,99,235,0.28) 0%,transparent 70%)" }} />
        <div style={{ position: "absolute", bottom: "-20%", left: "-15%", width: "65%", height: "65%", borderRadius: "50%", background: "radial-gradient(circle,rgba(30,58,138,0.18) 0%,transparent 70%)" }} />
        {/* Grid */}
        <svg style={{ position: "absolute", inset: 0, opacity: 0.038 }} width="100%" height="100%">
          {Array.from({length:12},(_,i)=><line key={`gv${i}`} x1={`${i*8.33}%`} y1="0" x2={`${i*8.33}%`} y2="100%" stroke="white" strokeWidth=".5"/>)}
          {Array.from({length:20},(_,i)=><line key={`gh${i}`} x1="0" y1={`${i*5}%`} x2="100%" y2={`${i*5}%`} stroke="white" strokeWidth=".5"/>)}
        </svg>
        {/* Animated ring */}
        <div style={{ position: "absolute", width: 220, height: 220, borderRadius: "50%", border: "1px solid rgba(37,99,235,0.15)" }} />
        <div style={{ position: "absolute", width: 170, height: 170, borderRadius: "50%", border: "1px solid rgba(37,99,235,0.1)" }} />

        <div style={{ flex: 2 }} />
        {/* Logo */}
        <div style={{ width: 130, height: 130, background: "#0D1B3E", borderRadius: 36, border: "1.5px solid rgba(37,99,235,0.35)", boxShadow: "0 0 60px rgba(37,99,235,0.35), 0 20px 40px rgba(0,0,0,0.4)", display: "flex", alignItems: "center", justifyContent: "center", position: "relative" }}>
          <div style={{ position: "absolute", inset: 0, borderRadius: 36, background: "linear-gradient(135deg,rgba(37,99,235,0.08),transparent)" }} />
          <img src={pilotLogo} style={{ width: 92, height: 92, objectFit: "contain", position: "relative" }} alt="JAGO Pilot" />
        </div>
        {/* Text */}
        <div style={{ marginTop: 32, textAlign: "center" }}>
          <div style={{ marginTop: 10, display: "inline-block", background: "rgba(37,99,235,0.1)", borderRadius: 20, border: "1px solid rgba(37,99,235,0.2)", padding: "5px 18px", fontSize: 12, color: "rgba(255,255,255,0.6)", letterSpacing: 2.5 }}>Drive Smarter.</div>
        </div>
        <div style={{ flex: 3 }} />
        <div style={{ marginBottom: 44, textAlign: "center" }}>
          <div style={{ width: 20, height: 20, borderRadius: "50%", border: "2px solid rgba(37,99,235,0.2)", borderTop: "2px solid rgba(37,99,235,0.7)", margin: "0 auto 16px" }} />
          <div style={{ fontSize: 10, color: "rgba(255,255,255,0.2)", letterSpacing: 0.3 }}>MindWhile IT Solutions</div>
        </div>
      </div>
    </Phone>
  );
}

function PilotLogin() {
  return (
    <Phone bg="#060D1E">
      <div style={{ height: "100%", background: "#060D1E", position: "relative", overflow: "hidden" }}>
        {/* Glow top-right */}
        <div style={{ position: "absolute", top: -60, right: -60, width: 260, height: 260, borderRadius: "50%", background: "radial-gradient(circle,rgba(37,99,235,0.18) 0%,transparent 70%)" }} />
        <div style={{ padding: "20px 22px 0" }}>
          {/* Logo badge */}
          <div style={{ display: "inline-flex", alignItems: "center", background: "rgba(37,99,235,0.12)", borderRadius: 10, border: "1px solid rgba(37,99,235,0.25)", padding: "7px 14px", marginBottom: 28 }}>
            <img src={pilotLogo} style={{ height: 28, objectFit: "contain" }} alt="JAGO Pilot" />
          </div>
          <div style={{ fontSize: 28, fontWeight: 900, color: "white", lineHeight: 1.2, letterSpacing: -0.5, marginBottom: 8 }}>Pilot గా<br />Login చేయండి 🏍️</div>
          <div style={{ fontSize: 12, color: "rgba(255,255,255,0.4)", marginBottom: 26 }}>ప్రతి trip తో earn చేయండి</div>
          {/* Phone input */}
          <div style={{ fontSize: 11, fontWeight: 700, color: "rgba(255,255,255,0.45)", marginBottom: 8, textTransform: "uppercase", letterSpacing: 0.3 }}>Mobile Number</div>
          <div style={{ background: "#0D1B3E", borderRadius: 16, border: "1px solid rgba(255,255,255,0.07)", display: "flex", alignItems: "center", overflow: "hidden", marginBottom: 18 }}>
            <div style={{ padding: "14px 14px", borderRight: "1px solid rgba(255,255,255,0.07)", display: "flex", alignItems: "center", gap: 5 }}>
              <span style={{ fontSize: 16 }}>🇮🇳</span>
              <span style={{ fontSize: 14, fontWeight: 800, color: "white" }}>+91</span>
            </div>
            <div style={{ padding: "14px 14px", fontSize: 16, fontWeight: 700, color: "rgba(255,255,255,0.18)", letterSpacing: 2.5 }}>00000 00000</div>
          </div>
          {/* Button */}
          <div style={{ background: "linear-gradient(135deg,#2563EB,#1d4ed8)", borderRadius: 16, padding: "14px 0", textAlign: "center", color: "white", fontSize: 15, fontWeight: 800, boxShadow: "0 8px 28px rgba(37,99,235,0.4)", marginBottom: 14, letterSpacing: 0.3 }}>Get OTP →</div>
          <div style={{ display: "flex", justifyContent: "center", alignItems: "center", gap: 5, marginBottom: 24 }}>
            <span style={{ fontSize: 11, opacity: 0.4 }}>🛡</span>
            <span style={{ fontSize: 11, color: "rgba(255,255,255,0.3)" }}>Secure & Verified Platform</span>
          </div>
          {/* Earnings banner */}
          <div style={{ background: "#0D1B3E", borderRadius: 16, border: "1px solid rgba(37,99,235,0.15)", padding: "14px 16px", display: "flex", alignItems: "center", gap: 14 }}>
            <div style={{ width: 46, height: 46, background: "rgba(37,99,235,0.12)", borderRadius: 12, display: "flex", alignItems: "center", justifyContent: "center", fontSize: 20 }}>📈</div>
            <div style={{ flex: 1 }}>
              <div style={{ fontSize: 16, fontWeight: 900, color: "white" }}>₹800–₹1500/day</div>
              <div style={{ fontSize: 10, color: "rgba(255,255,255,0.35)", marginTop: 3 }}>Average Pilot Earnings</div>
            </div>
            <div style={{ fontSize: 16, color: "rgba(255,255,255,0.2)" }}>›</div>
          </div>
        </div>
      </div>
    </Phone>
  );
}

function PilotHome() {
  return (
    <Phone bg="#060D1E">
      <div style={{ height: "100%", background: "#060D1E", position: "relative", display: "flex", flexDirection: "column" }}>
        <Map dark />
        {/* Driver pin */}
        <div style={{ position: "absolute", top: "38%", left: "43%", zIndex: 2 }}>
          <div style={{ width: 30, height: 30, borderRadius: "50%", background: "linear-gradient(135deg,#2563EB,#1d4ed8)", display: "flex", alignItems: "center", justifyContent: "center", boxShadow: "0 0 0 8px rgba(37,99,235,0.14),0 0 0 16px rgba(37,99,235,0.06)", fontSize: 14 }}>🏍</div>
        </div>
        {/* Top bar */}
        <div style={{ position: "relative", zIndex: 3, padding: "8px 12px" }}>
          <div style={{ display: "flex", gap: 8, alignItems: "center" }}>
            <div style={{ width: 36, height: 36, background: "rgba(6,13,30,0.85)", borderRadius: 12, backdropFilter: "blur(8px)", boxShadow: "0 3px 12px rgba(0,0,0,0.4)", border: "1px solid rgba(255,255,255,0.06)", display: "flex", alignItems: "center", justifyContent: "center" }}>
              <div style={{ display: "flex", flexDirection: "column", gap: 3 }}>
                {[0,1,2].map(i=><div key={i} style={{ width: 12, height: 2, background: "rgba(255,255,255,0.7)", borderRadius: 1 }}/>)}
              </div>
            </div>
            <div style={{ flex: 1, background: "rgba(6,13,30,0.85)", borderRadius: 12, backdropFilter: "blur(8px)", padding: "10px 12px", boxShadow: "0 3px 12px rgba(0,0,0,0.4)", border: "1px solid rgba(255,255,255,0.06)", display: "flex", alignItems: "center", gap: 8 }}>
              <div style={{ width: 8, height: 8, borderRadius: "50%", background: "#16A34A", boxShadow: "0 0 8px rgba(22,163,74,0.7)" }} />
              <div style={{ fontSize: 12, fontWeight: 700, color: "white" }}>Online — Ready</div>
              <div style={{ marginLeft: "auto", fontSize: 11, color: "rgba(255,255,255,0.3)" }}>✓</div>
            </div>
            <div style={{ width: 36, height: 36, background: "rgba(6,13,30,0.85)", borderRadius: 12, backdropFilter: "blur(8px)", boxShadow: "0 3px 12px rgba(0,0,0,0.4)", border: "1px solid rgba(255,255,255,0.06)", display: "flex", alignItems: "center", justifyContent: "center", fontSize: 15 }}>📍</div>
          </div>
        </div>
        <div style={{ flex: 1 }} />
        {/* Bottom panel */}
        <div style={{ position: "relative", zIndex: 3, background: "#060D1E", borderRadius: "24px 24px 0 0", padding: "6px 14px 18px", boxShadow: "0 -6px 30px rgba(0,0,0,0.55)", border: "1px solid rgba(255,255,255,0.05)", borderBottom: "none" }}>
          <div style={{ width: 32, height: 4, background: "rgba(255,255,255,0.08)", borderRadius: 2, margin: "8px auto 14px" }} />
          {/* Stat tiles */}
          <div style={{ display: "flex", gap: 8, marginBottom: 14 }}>
            {[
              { l:"Today Earnings", v:"₹1,240", ic:"💰", c:"#10B981", bg:"rgba(16,185,129,0.1)", br:"rgba(16,185,129,0.18)" },
              { l:"Trips Today",    v:"8",      ic:"🛺", c:"#2563EB", bg:"rgba(37,99,235,0.1)",  br:"rgba(37,99,235,0.18)" },
              { l:"Wallet",        v:"₹340",   ic:"👛", c:"#F59E0B", bg:"rgba(245,158,11,0.1)", br:"rgba(245,158,11,0.18)" },
            ].map((s,i)=>(
              <div key={i} style={{ flex: 1, background: s.bg, borderRadius: 14, border: `1px solid ${s.br}`, padding: "12px 6px", textAlign: "center" }}>
                <div style={{ width: 28, height: 28, borderRadius: "50%", background: s.bg, display: "flex", alignItems: "center", justifyContent: "center", margin: "0 auto 6px", fontSize: 14, border: `1px solid ${s.br}` }}>{s.ic}</div>
                <div style={{ fontSize: 14, fontWeight: 900, color: "white" }}>{s.v}</div>
                <div style={{ fontSize: 7, color: "rgba(255,255,255,0.3)", marginTop: 2 }}>{s.l}</div>
              </div>
            ))}
          </div>
          {/* Toggle */}
          <div style={{ background: "linear-gradient(135deg,#16A34A,#15803D)", borderRadius: 16, padding: "14px 0", textAlign: "center", color: "white", fontSize: 14, fontWeight: 900, boxShadow: "0 6px 20px rgba(22,163,74,0.4)", marginBottom: 12, letterSpacing: 0.3 }}>⚡ Online — Trip కోసం Ready ✓</div>
          {/* Chips */}
          <div style={{ display: "flex", gap: 8 }}>
            {[{l:"Break",ic:"☕",c:"#F59E0B",bg:"rgba(245,158,11,0.08)",br:"rgba(245,158,11,0.18)"},{l:"Wallet",ic:"💳",c:"#10B981",bg:"rgba(16,185,129,0.08)",br:"rgba(16,185,129,0.18)"},{l:"Trips",ic:"📋",c:"#2563EB",bg:"rgba(37,99,235,0.08)",br:"rgba(37,99,235,0.18)"}].map((a,i)=>(
              <div key={i} style={{ flex: 1, background: a.bg, borderRadius: 12, border: `1px solid ${a.br}`, padding: "10px 0", textAlign: "center" }}>
                <div style={{ fontSize: 16, marginBottom: 4 }}>{a.ic}</div>
                <div style={{ fontSize: 9, fontWeight: 700, color: a.c }}>{a.l}</div>
              </div>
            ))}
          </div>
        </div>
      </div>
    </Phone>
  );
}

function PilotIncoming() {
  return (
    <Phone bg="#060D1E">
      <div style={{ height: "100%", background: "#060D1E", position: "relative", display: "flex", flexDirection: "column" }}>
        <Map dark />
        <div style={{ position: "absolute", inset: 0, background: "rgba(0,0,0,0.55)", zIndex: 1 }} />
        {/* Pulse rings */}
        <div style={{ position: "absolute", top: "22%", left: "50%", transform: "translate(-50%,-50%)", zIndex: 2 }}>
          {[130,100,70].map((s,i)=>(
            <div key={i} style={{ position: "absolute", width: s, height: s, borderRadius: "50%", border: `1px solid rgba(37,99,235,${0.25-i*0.06})`, top: -(s-34)/2, left: -(s-34)/2 }} />
          ))}
          <div style={{ width: 64, height: 64, borderRadius: "50%", background: "linear-gradient(135deg,#2563EB,#1d4ed8)", display: "flex", alignItems: "center", justifyContent: "center", fontSize: 28, boxShadow: "0 0 40px rgba(37,99,235,0.6)" }}>🔔</div>
        </div>
        <div style={{ flex: 1, zIndex: 2 }} />
        {/* Trip card */}
        <div style={{ position: "relative", zIndex: 3, margin: "0 10px 10px", background: "#060D1E", borderRadius: 26, border: "1px solid rgba(37,99,235,0.2)", boxShadow: "0 0 40px rgba(37,99,235,0.2), 0 30px 60px rgba(0,0,0,0.5)" }}>
          {/* Header */}
          <div style={{ background: "linear-gradient(135deg,rgba(37,99,235,0.2),rgba(37,99,235,0.08))", borderRadius: "24px 24px 0 0", padding: "14px 18px" }}>
            <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between" }}>
              <div>
                <div style={{ fontSize: 17, fontWeight: 900, color: "white" }}>New Trip! 🔔</div>
                <div style={{ fontSize: 10, color: "rgba(255,255,255,0.4)", marginTop: 3 }}>Accept — expire అవుతుంది!</div>
              </div>
              {/* Countdown */}
              <div style={{ width: 52, height: 52, borderRadius: "50%", border: "2.5px solid rgba(37,99,235,0.25)", display: "flex", alignItems: "center", justifyContent: "center", position: "relative" }}>
                <div style={{ position: "absolute", inset: -1, borderRadius: "50%", background: "conic-gradient(#2563EB 60%, transparent 60%)", mask: "radial-gradient(transparent 17px, black 17px)" }} />
                <div style={{ fontSize: 16, fontWeight: 900, color: "white" }}>22</div>
              </div>
            </div>
          </div>
          {/* Route */}
          <div style={{ margin: "12px 16px", background: "#0D1B3E", borderRadius: 16, padding: "12px 14px" }}>
            {[{dot:"#2563EB",lbl:"MGBS Bus Stand, Hyderabad",r:false},{dot:"#F59E0B",lbl:"Banjara Hills Road No. 12",r:true}].map((l,i)=>(
              <div key={i}>
                {i>0&&<div style={{ width: 2, height: 12, background: "rgba(255,255,255,0.08)", marginLeft: 3, marginBottom: 4, marginTop: 2 }}/>}
                <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
                  <div style={{ width: 9, height: 9, borderRadius: l.r?"2px":"50%", background: l.dot, flexShrink: 0, boxShadow: `0 0 6px ${l.dot}` }}/>
                  <div style={{ fontSize: 11, color: "rgba(255,255,255,0.75)", fontWeight: 600 }}>{l.lbl}</div>
                </div>
              </div>
            ))}
          </div>
          {/* Stats */}
          <div style={{ display: "flex", margin: "0 16px 14px", gap: 7 }}>
            {[{l:"Distance",v:"7.2 km",c:"#10B981"},{l:"Fare",v:"₹185",c:"#F59E0B"},{l:"ETA",v:"~8 min",c:"#2563EB"}].map((s,i)=>(
              <div key={i} style={{ flex: 1, background: `${s.c}0d`, borderRadius: 12, padding: "9px 5px", textAlign: "center", border: `1px solid ${s.c}25` }}>
                <div style={{ fontSize: 14, fontWeight: 900, color: s.c }}>{s.v}</div>
                <div style={{ fontSize: 8, color: "rgba(255,255,255,0.3)", marginTop: 2 }}>{s.l}</div>
              </div>
            ))}
          </div>
          {/* Buttons */}
          <div style={{ display: "flex", gap: 10, margin: "0 16px 18px" }}>
            <div style={{ flex: 1, background: "rgba(248,113,113,0.07)", borderRadius: 16, padding: "13px 0", textAlign: "center", border: "1px solid rgba(248,113,113,0.2)", fontSize: 12, fontWeight: 700, color: "#F87171" }}>✕ Reject</div>
            <div style={{ flex: 2, background: "linear-gradient(135deg,#16A34A,#15803D)", borderRadius: 16, padding: "13px 0", textAlign: "center", fontSize: 14, fontWeight: 900, color: "white", boxShadow: "0 6px 20px rgba(22,163,74,0.4)", letterSpacing: 0.3 }}>✓ Accept Trip</div>
          </div>
        </div>
      </div>
    </Phone>
  );
}

function PilotTrip() {
  return (
    <Phone bg="#060D1E">
      <div style={{ height: "100%", background: "#060D1E", position: "relative", display: "flex", flexDirection: "column" }}>
        <Map dark />
        {/* Route */}
        <div style={{ position: "absolute", top: "24%", left: "40%", zIndex: 2 }}>
          <div style={{ width: 9, height: 9, borderRadius: "50%", background: "#16A34A", boxShadow: "0 0 10px rgba(22,163,74,0.7)" }} />
          <div style={{ width: 2, height: 52, background: "linear-gradient(180deg,#16A34A,#2563EB)", marginLeft: 3 }} />
          <div style={{ width: 24, height: 24, borderRadius: "50%", background: "linear-gradient(135deg,#2563EB,#1d4ed8)", display: "flex", alignItems: "center", justifyContent: "center", fontSize: 12, boxShadow: "0 0 0 5px rgba(37,99,235,0.18)", marginLeft: -5 }}>🏍</div>
          <div style={{ width: 2, height: 36, background: "linear-gradient(180deg,#2563EB,#EF4444)", marginLeft: 3 }} />
          <div style={{ width: 9, height: 9, borderRadius: "50%", background: "#EF4444", boxShadow: "0 0 10px rgba(239,68,68,0.7)" }} />
        </div>
        <div style={{ flex: 1 }} />
        {/* Panel */}
        <div style={{ position: "relative", zIndex: 3, background: "#060D1E", borderRadius: "24px 24px 0 0", padding: "6px 16px 20px", boxShadow: "0 -6px 30px rgba(0,0,0,0.55)", border: "1px solid rgba(255,255,255,0.05)", borderBottom: "none" }}>
          <div style={{ width: 32, height: 4, background: "rgba(255,255,255,0.08)", borderRadius: 2, margin: "8px auto 14px" }} />
          {/* Status */}
          <div style={{ background: "rgba(22,163,74,0.08)", borderRadius: 16, border: "1px solid rgba(22,163,74,0.18)", padding: "12px 14px", display: "flex", alignItems: "center", gap: 10, marginBottom: 12 }}>
            <div style={{ width: 36, height: 36, background: "rgba(22,163,74,0.12)", borderRadius: 10, display: "flex", alignItems: "center", justifyContent: "center", fontSize: 18 }}>🚀</div>
            <div>
              <div style={{ fontSize: 14, fontWeight: 800, color: "#16A34A" }}>Trip Progress — ON RIDE</div>
              <div style={{ fontSize: 10, color: "rgba(255,255,255,0.3)", marginTop: 2 }}>Banjara Hills Rd No. 12</div>
            </div>
          </div>
          {/* Customer */}
          <div style={{ background: "#0D1B3E", borderRadius: 16, border: "1px solid rgba(255,255,255,0.06)", padding: "12px 14px", display: "flex", alignItems: "center", gap: 10, marginBottom: 14 }}>
            <div style={{ width: 42, height: 42, background: "rgba(37,99,235,0.18)", borderRadius: "50%", display: "flex", alignItems: "center", justifyContent: "center", fontSize: 16, fontWeight: 900, color: "white" }}>A</div>
            <div style={{ flex: 1 }}>
              <div style={{ fontSize: 13, fontWeight: 800, color: "white" }}>Arjun Reddy</div>
              <div style={{ display: "flex", gap: 6, marginTop: 5 }}>
                <div style={{ fontSize: 9, fontWeight: 700, color: "#10B981", background: "rgba(16,185,129,0.1)", borderRadius: 6, padding: "2px 7px" }}>₹185</div>
                <div style={{ fontSize: 9, fontWeight: 700, color: "#2563EB", background: "rgba(37,99,235,0.1)", borderRadius: 6, padding: "2px 7px" }}>7.2 km</div>
              </div>
            </div>
            <div style={{ width: 36, height: 36, background: "rgba(37,99,235,0.12)", borderRadius: 12, display: "flex", alignItems: "center", justifyContent: "center", fontSize: 16, border: "1px solid rgba(37,99,235,0.2)" }}>📞</div>
          </div>
          {/* Complete */}
          <div style={{ background: "linear-gradient(135deg,#16A34A,#15803D)", borderRadius: 16, padding: "14px 0", textAlign: "center", fontSize: 14, fontWeight: 900, color: "white", boxShadow: "0 6px 20px rgba(22,163,74,0.4)", marginBottom: 10, letterSpacing: 0.3 }}>🏁 Complete Trip ✓</div>
          {/* Secondary */}
          <div style={{ display: "flex", justifyContent: "center", gap: 14, alignItems: "center" }}>
            <div style={{ fontSize: 11, color: "#2563EB", fontWeight: 700 }}>📞 Call Customer</div>
            <div style={{ width: 1, height: 14, background: "rgba(255,255,255,0.1)" }} />
            <div style={{ fontSize: 11, color: "#F87171", fontWeight: 700 }}>✕ Cancel</div>
          </div>
        </div>
      </div>
    </Phone>
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
// MAIN PAGE
// ═══════════════════════════════════════════════════════════════════════════════

export default function AppDesignPage() {
  const [tab, setTab] = useState<AppTab>("customer");

  const custScreens = [
    { c: <CustSplash />,    title: "Splash",   sub: "Blue gradient + animated logo" },
    { c: <CustLogin />,     title: "Login",    sub: "Gradient header + OTP + chips" },
    { c: <CustHome />,      title: "Home",     sub: "Map + vehicle select + bottom sheet" },
    { c: <CustTracking />,  title: "Tracking", sub: "Live pilot card + OTP box" },
  ];
  const pilotScreens = [
    { c: <PilotSplash />,   title: "Splash",        sub: "Dark navy + glow + grid" },
    { c: <PilotLogin />,    title: "Login",          sub: "Dark + earnings banner" },
    { c: <PilotHome />,     title: "Home",           sub: "Stats tiles + online toggle" },
    { c: <PilotIncoming />, title: "Incoming Trip",  sub: "Countdown ring + accept" },
    { c: <PilotTrip />,     title: "On Trip",        sub: "Route map + complete" },
  ];

  const isDriver = tab === "driver";
  const screens = isDriver ? pilotScreens : custScreens;
  const accent = isDriver ? "#2563EB" : "#1E6DE5";
  const grad = isDriver ? "linear-gradient(135deg,#2563EB,#1d4ed8)" : "linear-gradient(135deg,#1E6DE5,#1244A2)";

  const custPalette = [
    { c:"#0A2040", n:"Deep Blue" }, { c:"#1244A2", n:"Dark Blue" }, { c:"#1E6DE5", n:"Primary Blue" },
    { c:"#4B9EFF", n:"Light Blue" }, { c:"#F8FAFF", n:"Surface" }, { c:"#E53935", n:"Destination" },
    { c:"#F59E0B", n:"OTP/Warn" }, { c:"#111827", n:"Text" },
  ];
  const pilotPalette = [
    { c:"#060D1E", n:"Background" }, { c:"#0D1B3E", n:"Surface" }, { c:"#2563EB", n:"Blue" },
    { c:"#16A34A", n:"Online" }, { c:"#10B981", n:"Earn" }, { c:"#F59E0B", n:"Wallet" },
    { c:"#F87171", n:"Reject" }, { c:"#EF4444", n:"Dest" },
  ];
  const palette = isDriver ? pilotPalette : custPalette;

  return (
    <div style={{ padding: 24, background: "#f1f5f9", minHeight: "100vh" }}>

      {/* ── Header ── */}
      <div style={{ background: "white", borderRadius: 20, padding: "22px 28px 18px", boxShadow: "0 2px 16px rgba(0,0,0,0.06)", border: "1px solid #f1f5f9", marginBottom: 20 }}>
        <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", flexWrap: "wrap", gap: 14 }}>
          <div style={{ display: "flex", alignItems: "center", gap: 16 }}>
            <div style={{ width: 56, height: 56, background: grad, borderRadius: 18, display: "flex", alignItems: "center", justifyContent: "center", fontSize: 26, boxShadow: `0 8px 28px ${accent}44` }}>
              {isDriver ? "🏍" : "📱"}
            </div>
            <div>
              <div style={{ fontWeight: 900, fontSize: 24, color: "#0f172a", letterSpacing: -0.5 }}>
                JAGO&nbsp;<span style={{ background: grad, WebkitBackgroundClip: "text", WebkitTextFillColor: "transparent" }}>App Design</span>
              </div>
              <div style={{ fontSize: 12, color: "#94a3b8", marginTop: 2 }}>
                {isDriver ? "JAGO Pilot (Driver) — Dark Navy Theme" : "JAGO Customer — Blue & White Theme"} · Flutter 3.27.1
              </div>
            </div>
          </div>
          {/* App toggle */}
          <div style={{ display: "flex", background: "#f1f5f9", borderRadius: 16, padding: 4, gap: 4 }}>
            {(["customer","driver"] as AppTab[]).map(t => (
              <button key={t} onClick={() => setTab(t)} style={{
                padding: "9px 20px", borderRadius: 13, border: "none", cursor: "pointer",
                fontSize: 13, fontWeight: 700, transition: "all 0.2s",
                background: tab === t ? (t === "driver" ? "linear-gradient(135deg,#2563EB,#1d4ed8)" : "linear-gradient(135deg,#1E6DE5,#1244A2)") : "transparent",
                color: tab === t ? "white" : "#64748b",
                boxShadow: tab === t ? "0 4px 16px rgba(0,0,0,0.18)" : "none",
              }}>
                {t === "driver" ? "🏍  JAGO Pilot" : "📱  JAGO Customer"}
              </button>
            ))}
          </div>
        </div>

        {/* Color palette */}
        <div style={{ marginTop: 18, display: "flex", gap: 8, flexWrap: "wrap", alignItems: "center" }}>
          <span style={{ fontSize: 10, fontWeight: 700, color: "#94a3b8", textTransform: "uppercase", letterSpacing: 1, marginRight: 4 }}>Palette</span>
          {palette.map((p, i) => (
            <div key={i} style={{ display: "flex", alignItems: "center", gap: 7, background: "#f8fafc", borderRadius: 10, padding: "5px 10px", border: "1px solid #f1f5f9" }}>
              <div style={{ width: 18, height: 18, background: p.c, borderRadius: 5, border: "1px solid rgba(0,0,0,0.1)" }} />
              <div>
                <div style={{ fontSize: 9, fontWeight: 700, color: "#1e293b" }}>{p.n}</div>
                <div style={{ fontSize: 8, color: "#94a3b8" }}>{p.c}</div>
              </div>
            </div>
          ))}
          <div style={{ marginLeft: "auto", display: "flex", alignItems: "center", gap: 6, background: "#f0fdf4", borderRadius: 10, padding: "6px 14px", border: "1px solid #bbf7d0" }}>
            <div style={{ width: 7, height: 7, borderRadius: "50%", background: "#16a34a" }} />
            <span style={{ fontSize: 10, fontWeight: 700, color: "#16a34a" }}>GitHub Pushed ✓</span>
          </div>
        </div>
      </div>

      {/* ── Info strip ── */}
      <div style={{ display: "flex", gap: 10, marginBottom: 24, flexWrap: "wrap" }}>
        {[
          { l: "Framework",  v: "Flutter 3.27.1" },
          { l: "Build",      v: isDriver ? "Android APK (~25.5 MB)" : "Android + iOS (~26 MB)" },
          { l: isDriver ? "Pilot Theme" : "Customer Theme", v: isDriver ? "Dark #060D1E + Blue #2563EB" : "Blue #1E6DE5 + White" },
          { l: "Screens",    v: isDriver ? "5 screens" : "4 screens" },
          { l: "Animations", v: "ElasticOut + FadeIn + SlideUp" },
        ].map((info, i) => (
          <div key={i} style={{ background: "white", borderRadius: 14, padding: "10px 18px", border: "1px solid #f1f5f9", boxShadow: "0 1px 4px rgba(0,0,0,0.04)" }}>
            <div style={{ fontSize: 9, color: "#94a3b8", fontWeight: 600, textTransform: "uppercase", letterSpacing: 0.5 }}>{info.l}</div>
            <div style={{ fontSize: 12, fontWeight: 700, color: "#1e293b", marginTop: 2 }}>{info.v}</div>
          </div>
        ))}
      </div>

      {/* ── Screen Grid ── */}
      <div style={{ overflowX: "auto", paddingBottom: 16 }}>
        <div style={{ display: "flex", gap: 32, minWidth: "max-content", padding: "4px 2px 20px" }}>
          {screens.map((s, i) => (
            <div key={i} style={{ display: "flex", flexDirection: "column", alignItems: "center" }}>
              <div style={{ marginBottom: 14, display: "flex", alignItems: "center", gap: 6 }}>
                <div style={{ width: 30, height: 30, borderRadius: "50%", background: grad, display: "flex", alignItems: "center", justifyContent: "center", fontSize: 12, fontWeight: 900, color: "white", boxShadow: `0 4px 14px ${accent}44` }}>{i + 1}</div>
              </div>
              {s.c}
              <Label title={s.title} sub={s.sub} />
            </div>
          ))}
        </div>
      </div>

      {/* ── Bottom specs ── */}
      <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 16 }}>
        <div style={{ background: "white", borderRadius: 18, padding: "20px 22px", boxShadow: "0 2px 8px rgba(0,0,0,0.05)", border: "1px solid #f1f5f9" }}>
          <div style={{ fontSize: 11, fontWeight: 700, color: "#64748b", textTransform: "uppercase", letterSpacing: 1, marginBottom: 14 }}>📱 Flutter Dependencies</div>
          <div style={{ background: "#060D1E", borderRadius: 14, padding: "14px 18px", fontFamily: "monospace", fontSize: 11, lineHeight: 2, color: "#94a3b8" }}>
            <div><span style={{ color: "#60a5fa" }}>google_maps_flutter:</span> <span style={{ color: "#86efac" }}>^2.5.0</span></div>
            <div><span style={{ color: "#60a5fa" }}>dio:</span> <span style={{ color: "#86efac" }}>^5.0.0</span></div>
            <div><span style={{ color: "#60a5fa" }}>get:</span> <span style={{ color: "#86efac" }}>^4.6.6</span></div>
            <div><span style={{ color: "#60a5fa" }}>geolocator:</span> <span style={{ color: "#86efac" }}>^11.0.0</span></div>
            <div><span style={{ color: "#60a5fa" }}>firebase_messaging:</span> <span style={{ color: "#86efac" }}>^14.7.0</span></div>
            <div><span style={{ color: "#60a5fa" }}>pin_code_fields:</span> <span style={{ color: "#86efac" }}>^8.0.1</span></div>
            <div><span style={{ color: "#60a5fa" }}>socket_io_client:</span> <span style={{ color: "#86efac" }}>^2.0.0</span></div>
            <div><span style={{ color: "#60a5fa" }}>shared_preferences:</span> <span style={{ color: "#86efac" }}>^2.2.0</span></div>
          </div>
        </div>
        <div style={{ background: "white", borderRadius: 18, padding: "20px 22px", boxShadow: "0 2px 8px rgba(0,0,0,0.05)", border: "1px solid #f1f5f9" }}>
          <div style={{ fontSize: 11, fontWeight: 700, color: "#64748b", textTransform: "uppercase", letterSpacing: 1, marginBottom: 14 }}>🔗 API Configuration</div>
          {[
            { env: "Production", url: "https://jagopro.org", c: "#8b5cf6", bg: "#f5f3ff" },
            { env: "Staging",    url: "https://staging.jagopro.org", c: "#2563eb", bg: "#eff6ff" },
            { env: "Dev",        url: "http://localhost:5000", c: "#16a34a", bg: "#f0fdf4" },
          ].map((e,i) => (
            <div key={i} style={{ background: "#f8fafc", borderRadius: 12, padding: "12px 14px", marginBottom: 8, border: "1px solid #f1f5f9" }}>
              <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 5 }}>
                <div style={{ fontSize: 12, fontWeight: 700, color: "#1e293b" }}>{e.env}</div>
                <div style={{ fontSize: 9, fontWeight: 700, color: e.c, background: e.bg, padding: "2px 8px", borderRadius: 6 }}>{i === 0 ? "✓ Active" : "Staging"}</div>
              </div>
              <div style={{ fontFamily: "monospace", fontSize: 10, color: "#64748b", background: "white", padding: "5px 10px", borderRadius: 8, border: "1px solid #e2e8f0" }}>{e.url}</div>
            </div>
          ))}
          <div style={{ marginTop: 12, background: "#f8fafc", borderRadius: 12, padding: "10px 14px", border: "1px solid #f1f5f9" }}>
            <div style={{ fontSize: 10, fontWeight: 700, color: "#64748b", marginBottom: 4 }}>Google Maps Key</div>
            <div style={{ fontFamily: "monospace", fontSize: 9, color: "#64748b", background: "white", padding: "4px 8px", borderRadius: 6, border: "1px solid #e2e8f0", wordBreak: "break-all" }}>AIzaSyB_yncy2ojljQ_dehITVkPQrPDtoCQbuhw</div>
          </div>
        </div>
      </div>
    </div>
  );
}
