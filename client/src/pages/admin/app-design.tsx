import { useState } from "react";
import jagoLogoBlue  from "@assets/JAGO_LOGOPNG_(1)_1772377612339.png";
import jagoLogoWhite from "@assets/JAGO_LOGO_WightPNG_1772377612337.png";
import pilotLogo     from "@assets/PILOT_LOGOPNG_1772377649091.png";

type AppTab = "customer" | "driver";

// ─── Phone Frame ──────────────────────────────────────────────────────────────
function Phone({ children, bg = "#fff", dark = false }: {
  children: React.ReactNode; bg?: string; dark?: boolean;
}) {
  return (
    <div style={{ position: "relative" }}>
      <div style={{
        width: 248, height: 520,
        background: bg,
        borderRadius: 48,
        border: dark ? "8px solid #1a1f36" : "8px solid #1a1f36",
        boxShadow: "0 70px 120px rgba(0,0,0,0.5), 0 30px 60px rgba(0,0,0,0.25), 0 0 0 1px rgba(255,255,255,0.05)",
        overflow: "hidden", position: "relative", flexShrink: 0,
      }}>
        {/* Status bar */}
        <div style={{
          position: "absolute", top: 0, left: 0, right: 0, height: 48, zIndex: 200,
          display: "flex", alignItems: "center", justifyContent: "space-between",
          padding: "0 20px",
        }}>
          <span style={{ fontSize: 11, fontWeight: 700, color: dark ? "white" : "white", opacity: 0.9 }}>9:41</span>
          {/* Dynamic island */}
          <div style={{
            position: "absolute", top: 0, left: "50%", transform: "translateX(-50%)",
            width: 100, height: 32, background: "#000",
            borderRadius: "0 0 22px 22px",
          }} />
          <div style={{ display: "flex", gap: 4, alignItems: "center" }}>
            <svg width="15" height="11" viewBox="0 0 15 11" fill="none">
              <rect x="0" y="4" width="3" height="7" rx="1" fill={dark?"white":"white"} opacity="0.9"/>
              <rect x="4" y="2.5" width="3" height="8.5" rx="1" fill={dark?"white":"white"} opacity="0.9"/>
              <rect x="8" y="1" width="3" height="10" rx="1" fill={dark?"white":"white"} opacity="0.9"/>
              <rect x="12" y="0" width="3" height="11" rx="1" fill={dark?"white":"white"} opacity="0.9"/>
            </svg>
            <svg width="16" height="11" viewBox="0 0 16 11" fill="none">
              <path d="M8 2.5C10.2 2.5 12.2 3.4 13.6 4.9L15 3.4C13.2 1.4 10.7 0.2 8 0.2C5.3 0.2 2.8 1.4 1 3.4L2.4 4.9C3.8 3.4 5.8 2.5 8 2.5Z" fill={dark?"white":"white"} opacity="0.9"/>
              <path d="M8 5.5C9.6 5.5 11 6.1 12.1 7.1L13.5 5.6C12 4.2 10.1 3.3 8 3.3C5.9 3.3 4 4.2 2.5 5.6L3.9 7.1C5 6.1 6.4 5.5 8 5.5Z" fill={dark?"white":"white"} opacity="0.7"/>
              <circle cx="8" cy="10" r="1.2" fill={dark?"white":"white"} opacity="0.9"/>
            </svg>
            <div style={{ display: "flex", alignItems: "center", gap: 1 }}>
              <div style={{ width: 22, height: 11, border: `1.5px solid ${dark?"rgba(255,255,255,0.8)":"rgba(255,255,255,0.8)"}`, borderRadius: 3, display: "flex", alignItems: "center", padding: "1.5px" }}>
                <div style={{ width: "75%", height: "100%", background: dark?"#34D399":"#34D399", borderRadius: 1.5 }} />
              </div>
              <div style={{ width: 1.5, height: 5, background: dark?"rgba(255,255,255,0.6)":"rgba(255,255,255,0.6)", borderRadius: 1, marginLeft: 1 }} />
            </div>
          </div>
        </div>
        {/* Side buttons */}
        <div style={{ position: "absolute", right: -9, top: 100, width: 4, height: 44, background: "#111827", borderRadius: "0 3px 3px 0" }} />
        <div style={{ position: "absolute", left: -9, top: 88, width: 4, height: 28, background: "#111827", borderRadius: "3px 0 0 3px" }} />
        <div style={{ position: "absolute", left: -9, top: 128, width: 4, height: 28, background: "#111827", borderRadius: "3px 0 0 3px" }} />
        {/* Home indicator */}
        <div style={{ position: "absolute", bottom: 6, left: "50%", transform: "translateX(-50%)", width: 100, height: 4, background: dark?"rgba(255,255,255,0.35)":"rgba(0,0,0,0.2)", borderRadius: 3, zIndex: 200 }} />
        <div style={{ paddingTop: 48, height: "calc(100% - 18px)", overflow: "hidden" }}>{children}</div>
      </div>
    </div>
  );
}

function ScreenLabel({ n, title, sub }: { n: number; title: string; sub: string }) {
  return (
    <div style={{ textAlign: "center", marginTop: 18 }}>
      <div style={{ fontWeight: 800, fontSize: 14, color: "#0f172a" }}>{title}</div>
      <div style={{ fontSize: 11, color: "#94a3b8", marginTop: 4 }}>{sub}</div>
    </div>
  );
}

// ─── Map SVG ─────────────────────────────────────────────────────────────────
function MapBg({ dark = false }: { dark?: boolean }) {
  const bg   = dark ? "#0f172a" : "#e8f0fe";
  const road = dark ? "rgba(255,255,255,0.06)" : "rgba(255,255,255,0.9)";
  const main = dark ? "rgba(255,255,255,0.1)"  : "white";
  return (
    <div style={{ position: "absolute", inset: 0, background: bg, overflow: "hidden" }}>
      <svg width="100%" height="100%" style={{ position: "absolute" }}>
        {/* City blocks */}
        {[0,1,2,3,4,5].map(row=>
          [0,1,2,3].map(col=>(
            <rect key={`b${row}${col}`} x={col*62+2} y={row*54+2} width={56} height={48}
              fill={dark?"rgba(30,41,59,0.8)":"rgba(219,234,254,0.6)"} rx="3"/>
          ))
        )}
        {/* Roads H */}
        {[0,54,108,162,216,270,324].map((y,i)=><rect key={`rh${i}`} x="0" y={y} width="248" height="4" fill={road}/>)}
        {/* Roads V */}
        {[0,62,124,186,248].map((x,i)=><rect key={`rv${i}`} x={x} y="0" width="4" height="400" fill={road}/>)}
        {/* Main road diagonal */}
        <path d="M0,180 Q100,140 248,200" stroke={main} strokeWidth="7" fill="none"/>
        <path d="M0,300 Q150,240 248,280" stroke={main} strokeWidth="5" fill="none"/>
        {/* Trees */}
        {[[30,90],[150,50],[200,160],[80,200]].map(([x,y],i)=>(
          <circle key={`t${i}`} cx={x} cy={y} r="4" fill={dark?"rgba(34,197,94,0.3)":"rgba(34,197,94,0.5)"}/>
        ))}
      </svg>
    </div>
  );
}

// ══════════════════════════════════════════════════════════════════════════════
// CUSTOMER APP SCREENS
// ══════════════════════════════════════════════════════════════════════════════

function C1_Splash() {
  return (
    <Phone bg="#1E6DE5" dark>
      <div style={{
        height: "100%",
        background: "linear-gradient(160deg, #0D47A1 0%, #1565C0 35%, #1976D2 65%, #1E88E5 100%)",
        display: "flex", flexDirection: "column", alignItems: "center",
        position: "relative", overflow: "hidden",
      }}>
        {/* Concentric circles background */}
        {[340,270,200,140].map((s,i)=>(
          <div key={i} style={{
            position: "absolute", top: "50%", left: "50%",
            transform: "translate(-50%,-50%)",
            width: s, height: s, borderRadius: "50%",
            border: "1px solid rgba(255,255,255,0.07)",
          }}/>
        ))}
        {/* Top highlight */}
        <div style={{ position: "absolute", top: -60, left: "50%", transform: "translateX(-50%)", width: 280, height: 200, borderRadius: "50%", background: "rgba(255,255,255,0.06)" }}/>

        <div style={{ flex: 1.5 }}/>

        {/* Logo card */}
        <div style={{
          width: 116, height: 116,
          background: "white",
          borderRadius: 30,
          display: "flex", alignItems: "center", justifyContent: "center",
          boxShadow: "0 24px 60px rgba(0,0,0,0.25), 0 8px 24px rgba(0,0,0,0.15)",
        }}>
          <img src={jagoLogoBlue} style={{ width: 82, objectFit: "contain" }} alt="JAGO"/>
        </div>

        {/* Brand */}
        <div style={{ marginTop: 28, textAlign: "center" }}>
          <div style={{ fontSize: 44, fontWeight: 900, color: "white", letterSpacing: 8, lineHeight: 1 }}>JAGO</div>
          <div style={{ marginTop: 10, fontSize: 13, color: "rgba(255,255,255,0.6)", letterSpacing: 2, fontWeight: 400 }}>Move Smarter.</div>
        </div>

        <div style={{ flex: 2 }}/>

        {/* Loading dots */}
        <div style={{ marginBottom: 40, display: "flex", flexDirection: "column", alignItems: "center", gap: 10 }}>
          <div style={{ display: "flex", gap: 6 }}>
            {[1,0.4,0.4].map((o,i)=>(
              <div key={i} style={{ width: 6, height: 6, borderRadius: "50%", background: `rgba(255,255,255,${o})` }}/>
            ))}
          </div>
          <div style={{ fontSize: 10, color: "rgba(255,255,255,0.3)", letterSpacing: 0.5 }}>MindWhile IT Solutions</div>
        </div>
      </div>
    </Phone>
  );
}

function C2_Login() {
  return (
    <Phone bg="#F8FAFF">
      <div style={{ height: "100%", background: "#F8FAFF", display: "flex", flexDirection: "column", overflow: "hidden" }}>
        {/* Blue top section */}
        <div style={{
          background: "linear-gradient(145deg, #0D47A1, #1565C0, #1976D2)",
          padding: "14px 24px 36px",
          borderRadius: "0 0 32px 32px",
          position: "relative", overflow: "hidden",
          flexShrink: 0,
        }}>
          <div style={{ position: "absolute", top: -40, right: -40, width: 150, height: 150, borderRadius: "50%", background: "rgba(255,255,255,0.07)" }}/>
          <div style={{ position: "absolute", bottom: -20, left: -20, width: 100, height: 100, borderRadius: "50%", background: "rgba(255,255,255,0.05)" }}/>
          {/* Logo */}
          <div style={{ marginBottom: 20, position: "relative" }}>
            <img src={jagoLogoWhite} style={{ height: 26, objectFit: "contain" }} alt="JAGO"/>
          </div>
          <div style={{ fontSize: 27, fontWeight: 800, color: "white", lineHeight: 1.2, position: "relative" }}>
            Welcome to<br/>JAGO 👋
          </div>
          <div style={{ fontSize: 12, color: "rgba(255,255,255,0.7)", marginTop: 6, position: "relative" }}>
            Safe, affordable rides — ఎక్కడైనా
          </div>
        </div>

        {/* Form section */}
        <div style={{ padding: "24px 22px 0", flex: 1 }}>
          <div style={{ fontSize: 12, fontWeight: 600, color: "#6B7280", marginBottom: 8 }}>Mobile Number</div>
          {/* Phone input */}
          <div style={{
            background: "white",
            borderRadius: 14,
            border: "1.5px solid #E5E7EB",
            display: "flex", alignItems: "center",
            boxShadow: "0 2px 8px rgba(0,0,0,0.06)",
            marginBottom: 16, overflow: "hidden",
          }}>
            <div style={{ padding: "0 14px", borderRight: "1.5px solid #E5E7EB", height: 52, display: "flex", alignItems: "center", gap: 6, flexShrink: 0 }}>
              <span style={{ fontSize: 18 }}>🇮🇳</span>
              <span style={{ fontSize: 15, fontWeight: 700, color: "#111827" }}>+91</span>
            </div>
            <div style={{ padding: "0 16px", fontSize: 15, color: "#9CA3AF", letterSpacing: 1.5, fontWeight: 500 }}>00000 00000</div>
          </div>
          {/* Continue button */}
          <div style={{
            background: "linear-gradient(135deg, #1976D2, #0D47A1)",
            borderRadius: 14, height: 52,
            display: "flex", alignItems: "center", justifyContent: "center",
            color: "white", fontSize: 15, fontWeight: 700,
            boxShadow: "0 8px 24px rgba(21,101,192,0.4)",
            letterSpacing: 0.3, marginBottom: 16,
          }}>Continue →</div>
          {/* Divider */}
          <div style={{ display: "flex", alignItems: "center", gap: 10, marginBottom: 14 }}>
            <div style={{ flex: 1, height: 1, background: "#E5E7EB" }}/>
            <span style={{ fontSize: 11, color: "#9CA3AF" }}>or</span>
            <div style={{ flex: 1, height: 1, background: "#E5E7EB" }}/>
          </div>
          {/* Google login */}
          <div style={{
            background: "white", borderRadius: 14, height: 48,
            display: "flex", alignItems: "center", justifyContent: "center", gap: 8,
            border: "1.5px solid #E5E7EB", boxShadow: "0 2px 6px rgba(0,0,0,0.05)",
            marginBottom: 18,
          }}>
            <svg width="18" height="18" viewBox="0 0 24 24"><path d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z" fill="#4285F4"/><path d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z" fill="#34A853"/><path d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z" fill="#FBBC05"/><path d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z" fill="#EA4335"/></svg>
            <span style={{ fontSize: 13, fontWeight: 600, color: "#374151" }}>Continue with Google</span>
          </div>
          <div style={{ fontSize: 10, color: "#9CA3AF", textAlign: "center" }}>By continuing you agree to our Terms & Privacy Policy</div>
        </div>
      </div>
    </Phone>
  );
}

function C3_Home() {
  return (
    <Phone bg="#EFF6FF">
      <div style={{ height: "100%", position: "relative", display: "flex", flexDirection: "column" }}>
        <MapBg dark={false}/>

        {/* Floating top bar */}
        <div style={{ position: "relative", zIndex: 10, padding: "8px 14px 0" }}>
          <div style={{
            background: "white", borderRadius: 16,
            padding: "10px 14px",
            display: "flex", alignItems: "center", gap: 10,
            boxShadow: "0 4px 16px rgba(0,0,0,0.1)",
          }}>
            <div style={{ width: 34, height: 34, borderRadius: 10, background: "#EFF6FF", display: "flex", alignItems: "center", justifyContent: "center" }}>
              <svg width="16" height="12" viewBox="0 0 16 12" fill="none">
                <rect width="16" height="2" rx="1" fill="#374151"/>
                <rect y="5" width="12" height="2" rx="1" fill="#374151"/>
                <rect y="10" width="8" height="2" rx="1" fill="#374151"/>
              </svg>
            </div>
            <img src={jagoLogoBlue} style={{ height: 18, objectFit: "contain" }} alt="JAGO"/>
            <div style={{ flex: 1 }}/>
            <div style={{ width: 34, height: 34, borderRadius: "50%", background: "linear-gradient(135deg,#1976D2,#0D47A1)", display: "flex", alignItems: "center", justifyContent: "center", fontSize: 13, fontWeight: 800, color: "white" }}>A</div>
          </div>
        </div>

        {/* Location pin on map */}
        <div style={{ position: "absolute", top: "34%", left: "44%", zIndex: 5 }}>
          <div style={{ width: 10, height: 10, borderRadius: "50%", background: "#1976D2", border: "2px solid white", boxShadow: "0 0 0 6px rgba(25,118,210,0.15)" }}/>
        </div>

        <div style={{ flex: 1 }}/>

        {/* Bottom sheet */}
        <div style={{
          position: "relative", zIndex: 10,
          background: "white",
          borderRadius: "28px 28px 0 0",
          boxShadow: "0 -8px 40px rgba(0,0,0,0.12)",
          padding: "8px 18px 12px",
        }}>
          <div style={{ width: 40, height: 4, background: "#E5E7EB", borderRadius: 2, margin: "6px auto 16px" }}/>

          <div style={{ fontSize: 18, fontWeight: 800, color: "#111827", marginBottom: 14, letterSpacing: -0.3 }}>
            Where are you going?
          </div>

          {/* Search bar */}
          <div style={{
            background: "#F9FAFB", borderRadius: 16,
            border: "1.5px solid #E5E7EB",
            marginBottom: 16, overflow: "hidden",
          }}>
            <div style={{ display: "flex", alignItems: "center", gap: 10, padding: "11px 14px", borderBottom: "1px solid #F3F4F6" }}>
              <div style={{ width: 9, height: 9, borderRadius: "50%", border: "2.5px solid #1976D2", flexShrink: 0 }}/>
              <span style={{ fontSize: 13, color: "#1976D2", fontWeight: 600 }}>Current Location</span>
            </div>
            <div style={{ display: "flex", alignItems: "center", gap: 10, padding: "11px 14px" }}>
              <div style={{ width: 9, height: 9, borderRadius: "2px", background: "#EF4444", flexShrink: 0 }}/>
              <span style={{ fontSize: 13, color: "#9CA3AF" }}>Where to?</span>
              <div style={{ marginLeft: "auto", width: 24, height: 24, background: "#EFF6FF", borderRadius: "50%", display: "flex", alignItems: "center", justifyContent: "center" }}>
                <svg width="12" height="12" viewBox="0 0 24 24" fill="none"><circle cx="11" cy="11" r="8" stroke="#1976D2" strokeWidth="2"/><path d="M21 21L16.65 16.65" stroke="#1976D2" strokeWidth="2" strokeLinecap="round"/></svg>
              </div>
            </div>
          </div>

          {/* Vehicles */}
          <div style={{ fontSize: 11, fontWeight: 600, color: "#9CA3AF", textTransform: "uppercase", letterSpacing: 1, marginBottom: 10 }}>Select Vehicle</div>
          <div style={{ display: "flex", gap: 8, marginBottom: 14 }}>
            {[
              { ic:"🏍", n:"Bike", f:"₹20+", sel:true },
              { ic:"🛺", n:"Auto", f:"₹35+", sel:false },
              { ic:"📦", n:"Parcel", f:"₹25+", sel:false },
              { ic:"🚛", n:"Cargo", f:"₹200+", sel:false },
            ].map((v,i)=>(
              <div key={i} style={{
                flex: 1,
                background: v.sel ? "linear-gradient(135deg,#1976D2,#1565C0)" : "white",
                borderRadius: 14,
                border: `1.5px solid ${v.sel?"#1976D2":"#E5E7EB"}`,
                padding: "10px 4px", textAlign: "center",
                boxShadow: v.sel?"0 6px 20px rgba(25,118,210,0.35)":"0 2px 6px rgba(0,0,0,0.05)",
              }}>
                <div style={{ fontSize: 20, marginBottom: 3 }}>{v.ic}</div>
                <div style={{ fontSize: 10, fontWeight: 700, color: v.sel?"white":"#374151" }}>{v.n}</div>
                <div style={{ fontSize: 9, fontWeight: 600, color: v.sel?"rgba(255,255,255,0.8)":"#1976D2", marginTop: 1 }}>{v.f}</div>
              </div>
            ))}
          </div>

          <div style={{
            background: "linear-gradient(135deg, #1976D2, #0D47A1)",
            borderRadius: 16, height: 50,
            display: "flex", alignItems: "center", justifyContent: "center",
            color: "white", fontSize: 15, fontWeight: 700,
            boxShadow: "0 8px 24px rgba(21,101,192,0.4)",
          }}>Find Ride →</div>
        </div>
      </div>
    </Phone>
  );
}

function C4_Tracking() {
  return (
    <Phone bg="#F8FAFF">
      <div style={{ height: "100%", position: "relative", display: "flex", flexDirection: "column" }}>
        <MapBg dark={false}/>

        {/* Route on map */}
        <div style={{ position: "absolute", top: "20%", left: "38%", zIndex: 5 }}>
          <div style={{ width: 10, height: 10, borderRadius: "50%", background: "#1976D2", border: "2px solid white", boxShadow: "0 0 0 4px rgba(25,118,210,0.2)" }}/>
          <svg width="20" height="60" viewBox="0 0 20 60" style={{ marginLeft: -5 }}>
            <path d="M10,0 C10,20 10,40 10,60" stroke="#1976D2" strokeWidth="2.5" fill="none" strokeDasharray="4,3"/>
          </svg>
          <div style={{ width: 20, height: 20, borderRadius: "50%", background: "white", border: "2.5px solid #1976D2", display: "flex", alignItems: "center", justifyContent: "center", marginLeft: -4, fontSize: 10 }}>🏍</div>
          <svg width="20" height="40" viewBox="0 0 20 40" style={{ marginLeft: -5 }}>
            <path d="M10,0 C10,13 10,27 10,40" stroke="#EF4444" strokeWidth="2.5" fill="none" strokeDasharray="4,3"/>
          </svg>
          <div style={{ width: 10, height: 10, borderRadius: "50%", background: "#EF4444", border: "2px solid white", boxShadow: "0 0 0 4px rgba(239,68,68,0.2)" }}/>
        </div>

        <div style={{ flex: 1 }}/>

        {/* Bottom sheet */}
        <div style={{ position: "relative", zIndex: 10, background: "white", borderRadius: "28px 28px 0 0", boxShadow: "0 -8px 40px rgba(0,0,0,0.12)", padding: "8px 18px 14px" }}>
          <div style={{ width: 40, height: 4, background: "#E5E7EB", borderRadius: 2, margin: "6px auto 14px" }}/>

          {/* Status banner */}
          <div style={{
            background: "linear-gradient(135deg, #EFF6FF, #DBEAFE)",
            borderRadius: 16, padding: "12px 14px",
            display: "flex", alignItems: "center", gap: 12,
            border: "1px solid #BFDBFE", marginBottom: 14,
          }}>
            <div style={{ width: 40, height: 40, borderRadius: "50%", background: "#DBEAFE", display: "flex", alignItems: "center", justifyContent: "center", fontSize: 20 }}>🏍</div>
            <div>
              <div style={{ fontSize: 14, fontWeight: 800, color: "#1D4ED8" }}>Pilot వస్తున్నాడు!</div>
              <div style={{ fontSize: 11, color: "#60A5FA", marginTop: 2 }}>~4 min away · Tracking live</div>
            </div>
          </div>

          {/* Driver card */}
          <div style={{ background: "#F9FAFB", borderRadius: 16, padding: "12px 14px", display: "flex", alignItems: "center", gap: 12, border: "1px solid #F3F4F6", marginBottom: 12 }}>
            <div style={{ width: 46, height: 46, borderRadius: "50%", background: "linear-gradient(135deg,#1976D2,#0D47A1)", display: "flex", alignItems: "center", justifyContent: "center", fontWeight: 900, fontSize: 18, color: "white", flexShrink: 0 }}>A</div>
            <div style={{ flex: 1 }}>
              <div style={{ fontSize: 14, fontWeight: 800, color: "#111827" }}>Arjun Pilot</div>
              <div style={{ fontSize: 11, color: "#9CA3AF", marginTop: 2 }}>⭐ 4.9 · Bike · TG09AB1234</div>
            </div>
            <div style={{ width: 40, height: 40, borderRadius: 12, background: "#EFF6FF", display: "flex", alignItems: "center", justifyContent: "center", border: "1px solid #BFDBFE" }}>
              <svg width="18" height="18" viewBox="0 0 24 24" fill="none"><path d="M6.62 10.79c1.44 2.83 3.76 5.14 6.59 6.59l2.2-2.2c.27-.27.67-.36 1.02-.24 1.12.37 2.33.57 3.57.57.55 0 1 .45 1 1V20c0 .55-.45 1-1 1-9.39 0-17-7.61-17-17 0-.55.45-1 1-1h3.5c.55 0 1 .45 1 1 0 1.25.2 2.45.57 3.57.11.35.03.74-.25 1.02l-2.2 2.2z" fill="#1976D2"/></svg>
            </div>
          </div>

          {/* OTP */}
          <div style={{
            background: "#FFFBEB", borderRadius: 16,
            padding: "12px 16px",
            display: "flex", alignItems: "center", gap: 14,
            border: "1.5px solid #FDE68A", marginBottom: 12,
          }}>
            <div style={{ width: 38, height: 38, borderRadius: 10, background: "#FEF3C7", display: "flex", alignItems: "center", justifyContent: "center", fontSize: 18, flexShrink: 0 }}>🔐</div>
            <div style={{ flex: 1 }}>
              <div style={{ fontSize: 10, fontWeight: 700, color: "#D97706", textTransform: "uppercase", letterSpacing: 1, marginBottom: 3 }}>Share with Pilot</div>
              <div style={{ fontSize: 32, fontWeight: 900, color: "#111827", letterSpacing: 12, lineHeight: 1 }}>4829</div>
            </div>
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" style={{ flexShrink: 0 }}><rect x="9" y="9" width="13" height="13" rx="2" stroke="#D97706" strokeWidth="2"/><path d="M5 15H4a2 2 0 01-2-2V4a2 2 0 012-2h9a2 2 0 012 2v1" stroke="#D97706" strokeWidth="2"/></svg>
          </div>

          {/* Cancel */}
          <div style={{ border: "1.5px solid #FECACA", borderRadius: 14, height: 44, display: "flex", alignItems: "center", justifyContent: "center", fontSize: 13, fontWeight: 600, color: "#EF4444" }}>
            Cancel Ride
          </div>
        </div>
      </div>
    </Phone>
  );
}

// ══════════════════════════════════════════════════════════════════════════════
// DRIVER APP (JAGO PILOT) SCREENS
// ══════════════════════════════════════════════════════════════════════════════

function D1_Splash() {
  return (
    <Phone bg="#060D1E" dark>
      <div style={{
        height: "100%", background: "#060D1E",
        display: "flex", flexDirection: "column", alignItems: "center",
        position: "relative", overflow: "hidden",
      }}>
        {/* Radial glow */}
        <div style={{ position: "absolute", top: "30%", left: "50%", transform: "translate(-50%,-50%)", width: 300, height: 300, borderRadius: "50%", background: "radial-gradient(circle, rgba(37,99,235,0.22) 0%, transparent 70%)" }}/>
        {/* Grid lines */}
        <svg style={{ position: "absolute", inset: 0, opacity: 0.04 }} width="100%" height="100%">
          {Array.from({length:14},(_,i)=><line key={`v${i}`} x1={i*18} y1="0" x2={i*18} y2="520" stroke="white" strokeWidth=".5"/>)}
          {Array.from({length:30},(_,i)=><line key={`h${i}`} x1="0" y1={i*18} x2="248" y2={i*18} stroke="white" strokeWidth=".5"/>)}
        </svg>
        {/* Rings */}
        {[200,160,120].map((s,i)=>(
          <div key={i} style={{ position: "absolute", top: "36%", left: "50%", transform: "translate(-50%,-50%)", width: s, height: s, borderRadius: "50%", border: `1px solid rgba(37,99,235,${0.12-i*0.03})` }}/>
        ))}

        <div style={{ flex: 1.8 }}/>

        {/* Pilot logo card */}
        <div style={{
          width: 128, height: 128,
          background: "#0D1B3E",
          borderRadius: 34,
          border: "1.5px solid rgba(37,99,235,0.3)",
          boxShadow: "0 0 60px rgba(37,99,235,0.3), 0 24px 48px rgba(0,0,0,0.5)",
          display: "flex", alignItems: "center", justifyContent: "center",
          position: "relative",
        }}>
          <div style={{ position: "absolute", inset: 0, borderRadius: 34, background: "linear-gradient(135deg, rgba(37,99,235,0.1) 0%, transparent 60%)" }}/>
          <img src={pilotLogo} style={{ width: 90, objectFit: "contain", position: "relative" }} alt="JAGO Pilot"/>
        </div>

        <div style={{ marginTop: 30, textAlign: "center" }}>
          <div style={{ display: "inline-block", background: "rgba(37,99,235,0.12)", border: "1px solid rgba(37,99,235,0.2)", borderRadius: 20, padding: "5px 20px", fontSize: 12, color: "rgba(255,255,255,0.55)", letterSpacing: 2 }}>Drive Smarter.</div>
        </div>

        <div style={{ flex: 2.2 }}/>

        <div style={{ marginBottom: 40, display: "flex", flexDirection: "column", alignItems: "center", gap: 10 }}>
          <div style={{ width: 22, height: 22, borderRadius: "50%", border: "2px solid rgba(37,99,235,0.15)", borderTop: "2px solid rgba(37,99,235,0.6)" }}/>
          <div style={{ fontSize: 10, color: "rgba(255,255,255,0.2)" }}>MindWhile IT Solutions</div>
        </div>
      </div>
    </Phone>
  );
}

function D2_Login() {
  return (
    <Phone bg="#060D1E" dark>
      <div style={{ height: "100%", background: "#060D1E", position: "relative", overflow: "hidden" }}>
        <div style={{ position: "absolute", top: -80, right: -80, width: 280, height: 280, borderRadius: "50%", background: "radial-gradient(circle, rgba(37,99,235,0.18) 0%, transparent 70%)" }}/>

        <div style={{ padding: "16px 22px 0", position: "relative" }}>
          {/* Pilot logo */}
          <div style={{ marginBottom: 32 }}>
            <img src={pilotLogo} style={{ height: 32, objectFit: "contain" }} alt="JAGO Pilot"/>
          </div>

          <div style={{ fontSize: 30, fontWeight: 900, color: "white", lineHeight: 1.2, letterSpacing: -0.5, marginBottom: 8 }}>
            Pilot గా<br/>Login చేయండి 🏍️
          </div>
          <div style={{ fontSize: 13, color: "rgba(255,255,255,0.4)", marginBottom: 28 }}>
            ప్రతి trip తో earn చేయండి
          </div>

          {/* Phone input */}
          <div style={{ fontSize: 12, fontWeight: 600, color: "rgba(255,255,255,0.4)", marginBottom: 8, textTransform: "uppercase", letterSpacing: 0.5 }}>Mobile Number</div>
          <div style={{ background: "#0D1B3E", borderRadius: 16, border: "1px solid rgba(255,255,255,0.08)", display: "flex", alignItems: "center", overflow: "hidden", marginBottom: 20 }}>
            <div style={{ padding: "0 16px", height: 54, borderRight: "1px solid rgba(255,255,255,0.06)", display: "flex", alignItems: "center", gap: 6, flexShrink: 0 }}>
              <span style={{ fontSize: 18 }}>🇮🇳</span>
              <span style={{ fontSize: 15, fontWeight: 700, color: "white" }}>+91</span>
            </div>
            <div style={{ padding: "0 16px", fontSize: 15, color: "rgba(255,255,255,0.2)", letterSpacing: 1.5 }}>00000 00000</div>
          </div>

          {/* Button */}
          <div style={{
            background: "linear-gradient(135deg, #2563EB, #1D4ED8)",
            borderRadius: 16, height: 54,
            display: "flex", alignItems: "center", justifyContent: "center",
            color: "white", fontSize: 15, fontWeight: 700,
            boxShadow: "0 10px 30px rgba(37,99,235,0.4)",
            marginBottom: 14,
          }}>Get OTP →</div>

          <div style={{ display: "flex", justifyContent: "center", alignItems: "center", gap: 5, marginBottom: 26 }}>
            <svg width="12" height="12" viewBox="0 0 24 24" fill="none"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z" stroke="rgba(255,255,255,0.3)" strokeWidth="2"/></svg>
            <span style={{ fontSize: 11, color: "rgba(255,255,255,0.3)" }}>Secure & Verified Platform</span>
          </div>

          {/* Earnings banner */}
          <div style={{ background: "#0D1B3E", borderRadius: 18, border: "1px solid rgba(37,99,235,0.15)", padding: "14px 16px", display: "flex", alignItems: "center", gap: 14 }}>
            <div style={{ width: 46, height: 46, background: "rgba(37,99,235,0.15)", borderRadius: 13, display: "flex", alignItems: "center", justifyContent: "center" }}>
              <svg width="22" height="22" viewBox="0 0 24 24" fill="none"><path d="M23 6l-9.5 9.5-5-5L1 18" stroke="#2563EB" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"/><path d="M17 6h6v6" stroke="#2563EB" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"/></svg>
            </div>
            <div style={{ flex: 1 }}>
              <div style={{ fontSize: 18, fontWeight: 900, color: "white" }}>₹800 – ₹1500<span style={{ fontSize: 12, fontWeight: 500 }}>/day</span></div>
              <div style={{ fontSize: 11, color: "rgba(255,255,255,0.35)", marginTop: 2 }}>Average Pilot Earnings</div>
            </div>
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none"><path d="M9 18l6-6-6-6" stroke="rgba(255,255,255,0.2)" strokeWidth="2" strokeLinecap="round"/></svg>
          </div>
        </div>
      </div>
    </Phone>
  );
}

function D3_Home() {
  return (
    <Phone bg="#060D1E" dark>
      <div style={{ height: "100%", background: "#060D1E", position: "relative", display: "flex", flexDirection: "column" }}>
        <MapBg dark/>

        {/* Driver dot */}
        <div style={{ position: "absolute", top: "36%", left: "44%", zIndex: 5 }}>
          <div style={{ width: 12, height: 12, borderRadius: "50%", background: "#2563EB", border: "2px solid white", boxShadow: "0 0 0 8px rgba(37,99,235,0.15), 0 0 0 16px rgba(37,99,235,0.07)" }}/>
        </div>

        {/* Floating top bar */}
        <div style={{ position: "relative", zIndex: 10, padding: "8px 14px 0" }}>
          <div style={{ background: "rgba(13,27,62,0.92)", borderRadius: 16, padding: "10px 14px", backdropFilter: "blur(12px)", border: "1px solid rgba(255,255,255,0.06)", display: "flex", alignItems: "center", gap: 10, boxShadow: "0 4px 16px rgba(0,0,0,0.4)" }}>
            <div style={{ width: 8, height: 8, borderRadius: "50%", background: "#22C55E", boxShadow: "0 0 8px rgba(34,197,94,0.7)" }}/>
            <span style={{ fontSize: 13, fontWeight: 700, color: "white" }}>Online — Ready for trips</span>
            <div style={{ flex: 1 }}/>
            <div style={{ width: 34, height: 34, borderRadius: "50%", background: "linear-gradient(135deg,#2563EB,#1D4ED8)", display: "flex", alignItems: "center", justifyContent: "center", fontSize: 13, fontWeight: 900, color: "white" }}>A</div>
          </div>
        </div>

        <div style={{ flex: 1 }}/>

        {/* Bottom panel */}
        <div style={{ position: "relative", zIndex: 10, background: "#060D1E", borderRadius: "28px 28px 0 0", padding: "6px 16px 14px", boxShadow: "0 -6px 40px rgba(0,0,0,0.6)", border: "1px solid rgba(255,255,255,0.05)", borderBottom: "none" }}>
          <div style={{ width: 36, height: 4, background: "rgba(255,255,255,0.08)", borderRadius: 2, margin: "8px auto 16px" }}/>

          {/* Stats */}
          <div style={{ display: "flex", gap: 8, marginBottom: 14 }}>
            {[
              { ic:"💰", l:"Earnings", v:"₹1,240", c:"#22C55E", bg:"rgba(34,197,94,0.1)", br:"rgba(34,197,94,0.2)" },
              { ic:"🛺", l:"Trips",    v:"8",      c:"#3B82F6", bg:"rgba(59,130,246,0.1)", br:"rgba(59,130,246,0.2)" },
              { ic:"👛", l:"Wallet",   v:"₹340",   c:"#F59E0B", bg:"rgba(245,158,11,0.1)", br:"rgba(245,158,11,0.2)" },
            ].map((s,i)=>(
              <div key={i} style={{ flex: 1, background: s.bg, border: `1px solid ${s.br}`, borderRadius: 16, padding: "12px 6px", textAlign: "center" }}>
                <div style={{ fontSize: 20, marginBottom: 4 }}>{s.ic}</div>
                <div style={{ fontSize: 15, fontWeight: 900, color: "white" }}>{s.v}</div>
                <div style={{ fontSize: 9, color: "rgba(255,255,255,0.35)", marginTop: 2 }}>{s.l}</div>
              </div>
            ))}
          </div>

          {/* Toggle button */}
          <div style={{
            background: "linear-gradient(135deg, #16A34A, #15803D)",
            borderRadius: 16, height: 52,
            display: "flex", alignItems: "center", justifyContent: "center",
            gap: 8, color: "white", fontSize: 15, fontWeight: 800,
            boxShadow: "0 8px 24px rgba(22,163,74,0.4)",
            marginBottom: 12,
          }}>
            <div style={{ width: 8, height: 8, borderRadius: "50%", background: "rgba(255,255,255,0.6)" }}/>
            Online — Trip కోసం Ready ✓
          </div>

          {/* Quick actions */}
          <div style={{ display: "flex", gap: 8 }}>
            {[
              { ic:"☕", l:"Break",  c:"#F59E0B", bg:"rgba(245,158,11,0.1)", br:"rgba(245,158,11,0.2)" },
              { ic:"💳", l:"Wallet", c:"#22C55E", bg:"rgba(34,197,94,0.1)",  br:"rgba(34,197,94,0.2)" },
              { ic:"📋", l:"Trips",  c:"#3B82F6", bg:"rgba(59,130,246,0.1)", br:"rgba(59,130,246,0.2)" },
            ].map((a,i)=>(
              <div key={i} style={{ flex: 1, background: a.bg, border: `1px solid ${a.br}`, borderRadius: 14, padding: "10px 0", textAlign: "center" }}>
                <div style={{ fontSize: 18, marginBottom: 4 }}>{a.ic}</div>
                <div style={{ fontSize: 10, fontWeight: 700, color: a.c }}>{a.l}</div>
              </div>
            ))}
          </div>
        </div>
      </div>
    </Phone>
  );
}

function D4_Incoming() {
  return (
    <Phone bg="#060D1E" dark>
      <div style={{ height: "100%", background: "#060D1E", position: "relative", display: "flex", flexDirection: "column" }}>
        <MapBg dark/>
        <div style={{ position: "absolute", inset: 0, background: "rgba(0,0,0,0.6)", zIndex: 2 }}/>

        {/* Pulse rings */}
        <div style={{ position: "absolute", top: "22%", left: "50%", transform: "translate(-50%,-50%)", zIndex: 3 }}>
          {[150,115,80].map((s,i)=>(
            <div key={i} style={{ position: "absolute", width: s, height: s, borderRadius: "50%", border: `1px solid rgba(37,99,235,${0.2-i*0.05})`, top: -(s-56)/2, left: -(s-56)/2 }}/>
          ))}
          <div style={{ width: 56, height: 56, borderRadius: "50%", background: "linear-gradient(135deg,#2563EB,#1D4ED8)", display: "flex", alignItems: "center", justifyContent: "center", boxShadow: "0 0 40px rgba(37,99,235,0.6)" }}>
            <svg width="26" height="26" viewBox="0 0 24 24" fill="none"><path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9M13.73 21a2 2 0 0 1-3.46 0" stroke="white" strokeWidth="2" strokeLinecap="round"/></svg>
          </div>
        </div>

        <div style={{ flex: 1, zIndex: 3 }}/>

        {/* Trip card */}
        <div style={{ position: "relative", zIndex: 4, margin: "0 10px 10px", background: "#0D1B3E", borderRadius: 28, border: "1px solid rgba(37,99,235,0.2)", boxShadow: "0 0 50px rgba(37,99,235,0.2), 0 40px 80px rgba(0,0,0,0.6)" }}>
          {/* Header */}
          <div style={{ padding: "16px 18px", borderBottom: "1px solid rgba(255,255,255,0.06)", display: "flex", alignItems: "center", justifyContent: "space-between" }}>
            <div>
              <div style={{ fontSize: 11, fontWeight: 700, color: "#2563EB", textTransform: "uppercase", letterSpacing: 1, marginBottom: 3 }}>New Trip Request</div>
              <div style={{ fontSize: 18, fontWeight: 900, color: "white" }}>Accept చేయండి! 🔔</div>
            </div>
            {/* Countdown */}
            <div style={{ width: 54, height: 54, borderRadius: "50%", position: "relative", display: "flex", alignItems: "center", justifyContent: "center" }}>
              <svg width="54" height="54" viewBox="0 0 54 54" style={{ position: "absolute", transform: "rotate(-90deg)" }}>
                <circle cx="27" cy="27" r="23" fill="none" stroke="rgba(37,99,235,0.15)" strokeWidth="3"/>
                <circle cx="27" cy="27" r="23" fill="none" stroke="#2563EB" strokeWidth="3" strokeDasharray={`${144*0.6} ${144}`} strokeLinecap="round"/>
              </svg>
              <span style={{ fontSize: 16, fontWeight: 900, color: "white" }}>22</span>
            </div>
          </div>

          {/* Route */}
          <div style={{ margin: "14px 16px", background: "#060D1E", borderRadius: 16, padding: "12px 14px" }}>
            <div style={{ display: "flex", alignItems: "flex-start", gap: 12 }}>
              <div style={{ display: "flex", flexDirection: "column", alignItems: "center", paddingTop: 3 }}>
                <div style={{ width: 10, height: 10, borderRadius: "50%", background: "#2563EB", boxShadow: "0 0 8px rgba(37,99,235,0.6)" }}/>
                <div style={{ width: 1.5, height: 22, background: "rgba(255,255,255,0.12)", margin: "3px 0" }}/>
                <div style={{ width: 10, height: 10, borderRadius: "2px", background: "#F59E0B", boxShadow: "0 0 8px rgba(245,158,11,0.5)" }}/>
              </div>
              <div style={{ flex: 1 }}>
                <div style={{ fontSize: 12, fontWeight: 700, color: "white", marginBottom: 20 }}>MGBS Bus Stand, Hyderabad</div>
                <div style={{ fontSize: 12, fontWeight: 700, color: "rgba(255,255,255,0.7)" }}>Banjara Hills Rd No. 12</div>
              </div>
            </div>
            {/* Trip stats */}
            <div style={{ display: "flex", gap: 10, marginTop: 12, paddingTop: 12, borderTop: "1px solid rgba(255,255,255,0.06)" }}>
              {[{l:"7.2 km",c:"#3B82F6"},{l:"~8 min",c:"#22C55E"},{l:"₹185",c:"#F59E0B"}].map((s,i)=>(
                <div key={i} style={{ flex: 1, textAlign: "center", fontSize: 13, fontWeight: 800, color: s.c }}>{s.l}</div>
              ))}
            </div>
          </div>

          {/* Buttons */}
          <div style={{ display: "flex", gap: 10, margin: "0 16px 18px" }}>
            <div style={{ flex: 1, background: "rgba(239,68,68,0.08)", borderRadius: 16, height: 52, display: "flex", alignItems: "center", justifyContent: "center", border: "1px solid rgba(239,68,68,0.2)", fontSize: 13, fontWeight: 700, color: "#F87171" }}>Reject</div>
            <div style={{ flex: 2, background: "linear-gradient(135deg,#16A34A,#15803D)", borderRadius: 16, height: 52, display: "flex", alignItems: "center", justifyContent: "center", fontSize: 15, fontWeight: 800, color: "white", boxShadow: "0 8px 24px rgba(22,163,74,0.45)", gap: 6 }}>
              <svg width="18" height="18" viewBox="0 0 24 24" fill="none"><path d="M20 6L9 17l-5-5" stroke="white" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"/></svg>
              Accept Trip
            </div>
          </div>
        </div>
      </div>
    </Phone>
  );
}

function D5_OnTrip() {
  return (
    <Phone bg="#060D1E" dark>
      <div style={{ height: "100%", background: "#060D1E", position: "relative", display: "flex", flexDirection: "column" }}>
        <MapBg dark/>

        {/* Route */}
        <div style={{ position: "absolute", top: "22%", left: "40%", zIndex: 5 }}>
          <div style={{ width: 10, height: 10, borderRadius: "50%", background: "#22C55E", border: "2px solid white", boxShadow: "0 0 10px rgba(34,197,94,0.6)" }}/>
          <svg width="20" height="55" viewBox="0 0 20 55" style={{ marginLeft: -5 }}><path d="M10,0 L10,55" stroke="url(#gr)" strokeWidth="2.5" strokeDasharray="4,3" fill="none"/><defs><linearGradient id="gr" x1="0" y1="0" x2="0" y2="1"><stop offset="0%" stopColor="#22C55E"/><stop offset="100%" stopColor="#2563EB"/></linearGradient></defs></svg>
          <div style={{ width: 22, height: 22, borderRadius: "50%", background: "linear-gradient(135deg,#2563EB,#1D4ED8)", display: "flex", alignItems: "center", justifyContent: "center", fontSize: 11, boxShadow: "0 0 0 5px rgba(37,99,235,0.2)", marginLeft: -5 }}>🏍</div>
          <svg width="20" height="40" viewBox="0 0 20 40" style={{ marginLeft: -5 }}><path d="M10,0 L10,40" stroke="url(#gr2)" strokeWidth="2.5" strokeDasharray="4,3" fill="none"/><defs><linearGradient id="gr2" x1="0" y1="0" x2="0" y2="1"><stop offset="0%" stopColor="#2563EB"/><stop offset="100%" stopColor="#EF4444"/></linearGradient></defs></svg>
          <div style={{ width: 10, height: 10, borderRadius: "50%", background: "#EF4444", border: "2px solid white", boxShadow: "0 0 10px rgba(239,68,68,0.6)" }}/>
        </div>

        <div style={{ flex: 1 }}/>

        {/* Bottom panel */}
        <div style={{ position: "relative", zIndex: 10, background: "#060D1E", borderRadius: "28px 28px 0 0", padding: "6px 16px 14px", boxShadow: "0 -6px 40px rgba(0,0,0,0.6)", border: "1px solid rgba(255,255,255,0.05)", borderBottom: "none" }}>
          <div style={{ width: 36, height: 4, background: "rgba(255,255,255,0.08)", borderRadius: 2, margin: "8px auto 14px" }}/>

          {/* Status */}
          <div style={{ background: "rgba(22,163,74,0.08)", border: "1px solid rgba(22,163,74,0.18)", borderRadius: 16, padding: "12px 14px", display: "flex", alignItems: "center", gap: 12, marginBottom: 12 }}>
            <div style={{ width: 38, height: 38, background: "rgba(22,163,74,0.15)", borderRadius: 10, display: "flex", alignItems: "center", justifyContent: "center" }}>
              <svg width="20" height="20" viewBox="0 0 24 24" fill="none"><path d="M12 2L2 7l10 5 10-5-10-5z" stroke="#22C55E" strokeWidth="2" strokeLinejoin="round"/><path d="M2 17l10 5 10-5" stroke="#22C55E" strokeWidth="2" strokeLinejoin="round"/><path d="M2 12l10 5 10-5" stroke="#22C55E" strokeWidth="2" strokeLinejoin="round"/></svg>
            </div>
            <div>
              <div style={{ fontSize: 14, fontWeight: 800, color: "#22C55E" }}>Trip Progress — ON RIDE</div>
              <div style={{ fontSize: 11, color: "rgba(255,255,255,0.35)", marginTop: 2 }}>Banjara Hills Rd No. 12 · 12 min</div>
            </div>
          </div>

          {/* Customer card */}
          <div style={{ background: "#0D1B3E", borderRadius: 16, border: "1px solid rgba(255,255,255,0.06)", padding: "12px 14px", display: "flex", alignItems: "center", gap: 12, marginBottom: 14 }}>
            <div style={{ width: 44, height: 44, borderRadius: "50%", background: "linear-gradient(135deg,#2563EB,#1D4ED8)", display: "flex", alignItems: "center", justifyContent: "center", fontWeight: 900, fontSize: 16, color: "white", flexShrink: 0 }}>A</div>
            <div style={{ flex: 1 }}>
              <div style={{ fontSize: 14, fontWeight: 800, color: "white" }}>Arjun Reddy</div>
              <div style={{ display: "flex", gap: 6, marginTop: 5 }}>
                <span style={{ fontSize: 10, fontWeight: 700, color: "#22C55E", background: "rgba(34,197,94,0.12)", borderRadius: 6, padding: "2px 8px" }}>₹185</span>
                <span style={{ fontSize: 10, fontWeight: 700, color: "#3B82F6", background: "rgba(59,130,246,0.12)", borderRadius: 6, padding: "2px 8px" }}>7.2 km</span>
              </div>
            </div>
            <div style={{ width: 40, height: 40, borderRadius: 12, background: "rgba(37,99,235,0.12)", border: "1px solid rgba(37,99,235,0.2)", display: "flex", alignItems: "center", justifyContent: "center" }}>
              <svg width="18" height="18" viewBox="0 0 24 24" fill="none"><path d="M6.62 10.79c1.44 2.83 3.76 5.14 6.59 6.59l2.2-2.2c.27-.27.67-.36 1.02-.24 1.12.37 2.33.57 3.57.57.55 0 1 .45 1 1V20c0 .55-.45 1-1 1-9.39 0-17-7.61-17-17 0-.55.45-1 1-1h3.5c.55 0 1 .45 1 1 0 1.25.2 2.45.57 3.57.11.35.03.74-.25 1.02l-2.2 2.2z" fill="#2563EB"/></svg>
            </div>
          </div>

          {/* Complete button */}
          <div style={{ background: "linear-gradient(135deg,#16A34A,#15803D)", borderRadius: 16, height: 54, display: "flex", alignItems: "center", justifyContent: "center", gap: 8, color: "white", fontSize: 15, fontWeight: 800, boxShadow: "0 8px 24px rgba(22,163,74,0.45)", marginBottom: 10 }}>
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none"><path d="M20 6L9 17l-5-5" stroke="white" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"/></svg>
            Complete Trip
          </div>

          <div style={{ display: "flex", justifyContent: "center", gap: 16 }}>
            <span style={{ fontSize: 12, fontWeight: 600, color: "#2563EB" }}>📞 Call Customer</span>
            <span style={{ color: "rgba(255,255,255,0.1)" }}>|</span>
            <span style={{ fontSize: 12, fontWeight: 600, color: "#F87171" }}>Cancel</span>
          </div>
        </div>
      </div>
    </Phone>
  );
}

// ══════════════════════════════════════════════════════════════════════════════
// MAIN PAGE
// ══════════════════════════════════════════════════════════════════════════════
export default function AppDesignPage() {
  const [tab, setTab] = useState<AppTab>("customer");
  const isDriver = tab === "driver";

  const customerScreens = [
    { c: <C1_Splash/>, title: "Splash Screen", sub: "Animated blue gradient entry" },
    { c: <C2_Login/>,  title: "Login Screen",  sub: "Phone OTP + Google sign-in" },
    { c: <C3_Home/>,   title: "Home Screen",   sub: "Map + vehicle select" },
    { c: <C4_Tracking/>, title: "Tracking",    sub: "Live tracking + OTP card" },
  ];
  const driverScreens = [
    { c: <D1_Splash/>,   title: "Splash Screen",    sub: "Dark navy + animated glow" },
    { c: <D2_Login/>,    title: "Login Screen",      sub: "Earnings banner + OTP" },
    { c: <D3_Home/>,     title: "Home Screen",       sub: "Live stats + online toggle" },
    { c: <D4_Incoming/>, title: "Incoming Trip",     sub: "Countdown ring + accept" },
    { c: <D5_OnTrip/>,   title: "On Trip Screen",    sub: "Route map + complete" },
  ];

  const screens = isDriver ? driverScreens : customerScreens;
  const accent = isDriver ? "#2563EB" : "#1976D2";
  const grad = isDriver
    ? "linear-gradient(135deg,#2563EB,#1D4ED8)"
    : "linear-gradient(135deg,#1976D2,#0D47A1)";

  return (
    <div style={{ padding: 24, background: "#F1F5F9", minHeight: "100vh" }}>

      {/* Header */}
      <div style={{ background: "white", borderRadius: 22, padding: "22px 28px 20px", boxShadow: "0 2px 20px rgba(0,0,0,0.06)", border: "1px solid #F1F5F9", marginBottom: 20 }}>
        <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", flexWrap: "wrap", gap: 14 }}>
          <div style={{ display: "flex", alignItems: "center", gap: 16 }}>
            <div style={{ width: 58, height: 58, background: grad, borderRadius: 18, display: "flex", alignItems: "center", justifyContent: "center", boxShadow: `0 10px 30px ${accent}44` }}>
              <img src={isDriver ? pilotLogo : jagoLogoWhite} style={{ width: isDriver ? 36 : 40, objectFit: "contain" }} alt=""/>
            </div>
            <div>
              <div style={{ fontWeight: 900, fontSize: 24, color: "#0F172A", letterSpacing: -0.5 }}>
                {isDriver ? "JAGO Pilot" : "JAGO"}&nbsp;
                <span style={{ background: grad, WebkitBackgroundClip: "text", WebkitTextFillColor: "transparent" }}>App Design</span>
              </div>
              <div style={{ fontSize: 13, color: "#94A3B8", marginTop: 3 }}>
                {isDriver
                  ? "Driver App — Dark Navy · Flutter 3.27.1 · Android APK"
                  : "Customer App — Blue & White · Flutter 3.27.1 · Android + iOS"}
              </div>
            </div>
          </div>

          {/* Toggle */}
          <div style={{ display: "flex", background: "#F1F5F9", borderRadius: 16, padding: 4, gap: 3 }}>
            {(["customer","driver"] as AppTab[]).map(t=>(
              <button key={t} onClick={()=>setTab(t)} style={{
                padding: "9px 22px", borderRadius: 13, border: "none", cursor: "pointer",
                fontSize: 13, fontWeight: 700, transition: "all 0.2s",
                background: tab===t ? (t==="driver" ? "linear-gradient(135deg,#2563EB,#1D4ED8)" : "linear-gradient(135deg,#1976D2,#0D47A1)") : "transparent",
                color: tab===t ? "white" : "#64748B",
                boxShadow: tab===t ? "0 4px 18px rgba(0,0,0,0.2)" : "none",
              }}>
                {t==="driver" ? "🏍  JAGO Pilot" : "📱  JAGO Customer"}
              </button>
            ))}
          </div>
        </div>

        {/* Color palette */}
        <div style={{ marginTop: 18, display: "flex", gap: 7, flexWrap: "wrap", alignItems: "center" }}>
          <span style={{ fontSize: 10, fontWeight: 700, color: "#94A3B8", textTransform: "uppercase", letterSpacing: 1, marginRight: 2 }}>Color System</span>
          {(isDriver
            ? [{c:"#060D1E",n:"Background"},{c:"#0D1B3E",n:"Surface"},{c:"#2563EB",n:"Primary"},{c:"#22C55E",n:"Online"},{c:"#F59E0B",n:"Wallet"},{c:"#F87171",n:"Reject"}]
            : [{c:"#0D47A1",n:"Deep Blue"},{c:"#1976D2",n:"Primary"},{c:"#42A5F5",n:"Light"},{c:"#F8FAFF",n:"Surface"},{c:"#EF4444",n:"Dest"},{c:"#F59E0B",n:"OTP"}]
          ).map((p,i)=>(
            <div key={i} style={{ display:"flex", alignItems:"center", gap:6, background:"#F8FAFC", borderRadius:9, padding:"4px 10px", border:"1px solid #F1F5F9" }}>
              <div style={{ width:16, height:16, background:p.c, borderRadius:4, border:"1px solid rgba(0,0,0,0.1)" }}/>
              <div>
                <div style={{ fontSize:9, fontWeight:700, color:"#1E293B" }}>{p.n}</div>
                <div style={{ fontSize:8, color:"#94A3B8" }}>{p.c}</div>
              </div>
            </div>
          ))}
          <div style={{ marginLeft:"auto", display:"flex", alignItems:"center", gap:6, background:"#F0FDF4", borderRadius:10, padding:"6px 14px", border:"1px solid #BBF7D0" }}>
            <div style={{ width:7, height:7, borderRadius:"50%", background:"#16A34A" }}/>
            <span style={{ fontSize:10, fontWeight:700, color:"#16A34A" }}>GitHub Pushed ✓</span>
          </div>
        </div>
      </div>

      {/* Info strip */}
      <div style={{ display:"flex", gap:10, marginBottom:24, flexWrap:"wrap" }}>
        {[
          { l:"Framework",   v:"Flutter 3.27.1" },
          { l:"Build Tool",  v:"GitHub Actions CI" },
          { l:"Theme",       v: isDriver ? "Dark Navy #060D1E" : "Blue #1976D2" },
          { l:"Screens",     v: isDriver ? "5 screens" : "4 screens" },
          { l:"APK Size",    v: isDriver ? "~25.5 MB" : "~26 MB" },
        ].map((info,i)=>(
          <div key={i} style={{ background:"white", borderRadius:14, padding:"10px 18px", border:"1px solid #F1F5F9", boxShadow:"0 1px 4px rgba(0,0,0,0.04)" }}>
            <div style={{ fontSize:9, color:"#94A3B8", fontWeight:600, textTransform:"uppercase", letterSpacing:0.5 }}>{info.l}</div>
            <div style={{ fontSize:13, fontWeight:700, color:"#1E293B", marginTop:2 }}>{info.v}</div>
          </div>
        ))}
      </div>

      {/* Screens */}
      <div style={{ overflowX:"auto", paddingBottom:16 }}>
        <div style={{ display:"flex", gap:36, minWidth:"max-content", padding:"4px 2px 24px" }}>
          {screens.map((s,i)=>(
            <div key={i} style={{ display:"flex", flexDirection:"column", alignItems:"center" }}>
              <div style={{ marginBottom:16, display:"flex", alignItems:"center", gap:8 }}>
                <div style={{ width:32, height:32, borderRadius:"50%", background:grad, display:"flex", alignItems:"center", justifyContent:"center", fontSize:13, fontWeight:900, color:"white", boxShadow:`0 4px 16px ${accent}44` }}>{i+1}</div>
              </div>
              {s.c}
              <ScreenLabel n={i+1} title={s.title} sub={s.sub}/>
            </div>
          ))}
        </div>
      </div>

      {/* Bottom info */}
      <div style={{ display:"grid", gridTemplateColumns:"1fr 1fr", gap:16 }}>
        <div style={{ background:"white", borderRadius:20, padding:"20px 22px", boxShadow:"0 2px 10px rgba(0,0,0,0.05)", border:"1px solid #F1F5F9" }}>
          <div style={{ fontSize:11, fontWeight:700, color:"#64748B", textTransform:"uppercase", letterSpacing:1, marginBottom:14 }}>📱 Key Dependencies</div>
          <div style={{ background:"#0F172A", borderRadius:14, padding:"16px 18px", fontFamily:"monospace", fontSize:11, lineHeight:2 }}>
            {[
              ["google_maps_flutter","^2.5.0"],["dio","^5.0.0"],["get","^4.6.6"],
              ["geolocator","^11.0.0"],["firebase_messaging","^14.7.0"],
              ["pin_code_fields","^8.0.1"],["socket_io_client","^2.0.0"],
            ].map(([k,v],i)=>(
              <div key={i}><span style={{color:"#60A5FA"}}>{k}:</span> <span style={{color:"#86EFAC"}}>{v}</span></div>
            ))}
          </div>
        </div>
        <div style={{ background:"white", borderRadius:20, padding:"20px 22px", boxShadow:"0 2px 10px rgba(0,0,0,0.05)", border:"1px solid #F1F5F9" }}>
          <div style={{ fontSize:11, fontWeight:700, color:"#64748B", textTransform:"uppercase", letterSpacing:1, marginBottom:14 }}>🔗 API Endpoints</div>
          {[
            { env:"Production", url:"https://jagopro.org",           c:"#7C3AED", bg:"#F5F3FF" },
            { env:"Staging",    url:"https://staging.jagopro.org",   c:"#2563EB", bg:"#EFF6FF" },
            { env:"Local Dev",  url:"http://localhost:5000",         c:"#16A34A", bg:"#F0FDF4" },
          ].map((e,i)=>(
            <div key={i} style={{ background:"#F8FAFC", borderRadius:13, padding:"12px 14px", marginBottom:8, border:"1px solid #F1F5F9" }}>
              <div style={{ display:"flex", justifyContent:"space-between", alignItems:"center", marginBottom:5 }}>
                <div style={{ fontSize:13, fontWeight:700, color:"#1E293B" }}>{e.env}</div>
                <div style={{ fontSize:9, fontWeight:700, color:e.c, background:e.bg, padding:"2px 8px", borderRadius:6 }}>{i===0?"✓ Active":"Standby"}</div>
              </div>
              <div style={{ fontFamily:"monospace", fontSize:10, color:"#64748B", background:"white", padding:"5px 10px", borderRadius:8, border:"1px solid #E2E8F0" }}>{e.url}</div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
