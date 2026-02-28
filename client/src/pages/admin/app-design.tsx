import { useState } from "react";

type AppTab = "driver" | "customer";
type ThemeMode = "dark" | "light";

// ── JAGO Logo Component ──────────────────────────────────────────────────────
function JagoLogo({ size = 56, variant = "amber", showPilot = false }: { size?: number; variant?: "amber" | "purple" | "white"; showPilot?: boolean }) {
  const src = showPilot ? "/jago-pilot-logo.png" : "/jago-logo.png";
  const isLight = variant === "white";
  return (
    <div style={{ display: "flex", alignItems: "center", justifyContent: "center" }}>
      <img
        src={src}
        alt={showPilot ? "JAGO Pilot" : "JAGO"}
        style={{
          height: size,
          width: "auto",
          objectFit: "contain",
          filter: isLight ? "brightness(10)" : "none",
          mixBlendMode: "screen",
          maxWidth: size * 3,
        }}
      />
    </div>
  );
}

// ── Phone Frame ──────────────────────────────────────────────────────────────
function PhoneFrame({ children, bg = "#0f0f1a" }: { children: React.ReactNode; bg?: string }) {
  return (
    <div style={{ display: "flex", justifyContent: "center" }}>
      <div style={{
        width: 230, minHeight: 456,
        background: bg,
        borderRadius: 42,
        border: "7px solid #1e293b",
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

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// DRIVER APP SCREENS — DARK MODE
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

function DarkDriverSplash() {
  return (
    <PhoneFrame bg="#0a0a14">
      <div style={{
        minHeight: 428,
        background: "linear-gradient(160deg, #0a0a14 0%, #12112a 40%, #0d1f35 100%)",
        display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center",
        padding: "0 24px", gap: 0, position: "relative", overflow: "hidden",
      }}>
        {/* Glow orbs */}
        <div style={{ position: "absolute", top: "20%", left: "50%", transform: "translateX(-50%)",
          width: 160, height: 160, borderRadius: "50%",
          background: "radial-gradient(circle, rgba(245,158,11,0.12) 0%, transparent 70%)" }} />
        <div style={{ position: "absolute", bottom: "15%", right: "-20%",
          width: 140, height: 140, borderRadius: "50%",
          background: "radial-gradient(circle, rgba(239,68,68,0.08) 0%, transparent 70%)" }} />

        <JagoLogo size={90} variant="amber" showPilot={true} />

        <div style={{ marginTop: 16, fontSize: 9, color: "#475569", letterSpacing: 1 }}>Your Earnings. Your Journey.</div>

        <div style={{ marginTop: 28, width: 48, height: 4, background: "linear-gradient(90deg,#f59e0b,#ef4444)", borderRadius: 2 }} />

        <div style={{ marginTop: 20, fontSize: 9, color: "#334155" }}>Version 2.0.1</div>

        {/* Bottom glow line */}
        <div style={{ position: "absolute", bottom: 0, left: 0, right: 0, height: 2,
          background: "linear-gradient(90deg, transparent, #f59e0b44, transparent)" }} />
      </div>
    </PhoneFrame>
  );
}

function DarkDriverLogin() {
  return (
    <PhoneFrame bg="#0a0a14">
      <div style={{ minHeight: 428, background: "linear-gradient(180deg, #0a0a14 0%, #0f172a 100%)", padding: "24px 18px 18px", position: "relative", overflow: "hidden" }}>
        <div style={{ position: "absolute", top: 0, right: 0, width: 140, height: 140,
          background: "radial-gradient(circle at top right, rgba(245,158,11,0.08) 0%, transparent 70%)" }} />

        <div style={{ display: "flex", alignItems: "center", gap: 8, marginBottom: 20 }}>
          <JagoLogo size={32} variant="amber" />
          <div style={{ fontSize: 13, fontWeight: 800, color: "white", letterSpacing: 1 }}>JAGO</div>
          <div style={{ fontSize: 8, color: "#f59e0b", background: "rgba(245,158,11,0.15)", padding: "2px 7px", borderRadius: 6, marginLeft: 2, fontWeight: 800, letterSpacing: 0.5, border: "1px solid rgba(245,158,11,0.3)" }}>PILOT</div>
        </div>

        <div style={{ color: "white", fontSize: 20, fontWeight: 800, lineHeight: 1.2 }}>Welcome<br />Back <span style={{ fontSize: 18 }}>👋</span></div>
        <div style={{ color: "#475569", fontSize: 10, marginTop: 6 }}>Login చేసి earning start చేయండి</div>

        <div style={{ marginTop: 22, display: "flex", flexDirection: "column", gap: 10 }}>
          <div>
            <div style={{ fontSize: 9, color: "#64748b", fontWeight: 600, marginBottom: 5, textTransform: "uppercase", letterSpacing: 0.5 }}>Phone Number</div>
            <div style={{
              background: "#111827", borderRadius: 14, padding: "11px 13px",
              display: "flex", alignItems: "center", gap: 8,
              border: "1.5px solid #f59e0b44",
              boxShadow: "0 0 0 3px rgba(245,158,11,0.05)",
            }}>
              <div style={{ padding: "2px 6px", background: "rgba(245,158,11,0.15)", borderRadius: 6, fontSize: 10, color: "#f59e0b", fontWeight: 700 }}>+91</div>
              <div style={{ width: 1, height: 14, background: "#334155" }} />
              <span style={{ fontSize: 11, color: "#64748b" }}>98765 43210</span>
            </div>
          </div>

          <div>
            <div style={{ fontSize: 9, color: "#64748b", fontWeight: 600, marginBottom: 5, textTransform: "uppercase", letterSpacing: 0.5 }}>OTP</div>
            <div style={{ display: "flex", gap: 6 }}>
              {["5","2","•","•"].map((d, i) => (
                <div key={i} style={{
                  flex: 1, background: d !== "•" ? "rgba(245,158,11,0.08)" : "#111827",
                  border: `1.5px solid ${d !== "•" ? "#f59e0b55" : "#1e293b"}`,
                  borderRadius: 12, padding: "10px 0", textAlign: "center",
                  color: d !== "•" ? "white" : "#334155", fontSize: 15, fontWeight: 800,
                  boxShadow: d === "5" ? "0 0 12px rgba(245,158,11,0.15)" : "none",
                }}>{d}</div>
              ))}
            </div>
          </div>

          <div style={{ marginTop: 4,
            background: "linear-gradient(135deg,#f59e0b,#ef4444)",
            borderRadius: 14, padding: "12px 0", textAlign: "center",
            color: "white", fontSize: 12, fontWeight: 700, letterSpacing: 0.5,
            boxShadow: "0 8px 24px rgba(245,158,11,0.35)",
          }}>Verify & Login →</div>

          <div style={{ textAlign: "center", fontSize: 9, color: "#334155" }}>OTP resend in <span style={{ color: "#f59e0b" }}>28s</span></div>
        </div>
      </div>
    </PhoneFrame>
  );
}

function DarkDriverHome() {
  return (
    <PhoneFrame bg="#0a0a14">
      <div style={{ minHeight: 428, background: "#0a0a14", position: "relative", overflow: "hidden" }}>
        {/* Map bg */}
        <div style={{ position: "absolute", inset: 0, background: "radial-gradient(ellipse at 50% 55%, #0d1f35 0%, #0a0a14 75%)" }}>
          {[...Array(9)].map((_, i) => <div key={i} style={{ position: "absolute", left: 0, right: 0, top: `${11 * i}%`, height: 1, background: "rgba(255,255,255,0.025)" }} />)}
          {[...Array(7)].map((_, i) => <div key={i} style={{ position: "absolute", top: 0, bottom: 0, left: `${14 * i}%`, width: 1, background: "rgba(255,255,255,0.025)" }} />)}
          <div style={{ position: "absolute", left: "28%", right: "28%", top: "30%", bottom: "20%", border: "1px solid rgba(245,158,11,0.12)", borderRadius: 4 }} />
          <div style={{ position: "absolute", top: "50%", left: "46%",
            width: 24, height: 24, background: "linear-gradient(135deg,#f59e0b,#ef4444)", borderRadius: "50%",
            display: "flex", alignItems: "center", justifyContent: "center",
            boxShadow: "0 0 0 8px rgba(245,158,11,0.12), 0 0 0 16px rgba(245,158,11,0.05)", fontSize: 11,
          }}>🚗</div>
        </div>

        {/* Top Bar */}
        <div style={{ position: "relative", zIndex: 2, padding: "8px 14px 0" }}>
          <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
            <div style={{ display: "flex", alignItems: "center", gap: 7 }}>
              <JagoLogo size={24} variant="amber" />
              <div>
                <div style={{ fontSize: 7, color: "#475569" }}>Good Morning</div>
                <div style={{ fontSize: 12, fontWeight: 800, color: "white" }}>Anil Driver 👋</div>
              </div>
            </div>
            <div style={{ display: "flex", gap: 5 }}>
              <div style={{ width: 28, height: 28, borderRadius: 9, background: "#111827", border: "1px solid #1e293b", display: "flex", alignItems: "center", justifyContent: "center", fontSize: 12 }}>🔔</div>
              <div style={{ width: 28, height: 28, borderRadius: "50%", background: "linear-gradient(135deg,#f59e0b,#ef4444)", display: "flex", alignItems: "center", justifyContent: "center", fontSize: 11, fontWeight: 800, color: "white" }}>A</div>
            </div>
          </div>

          <div style={{ display: "flex", gap: 6, marginTop: 10 }}>
            {[{l:"Today",v:"₹1,240",c:"#22c55e",ic:"💰"},{l:"Trips",v:"8",c:"#60a5fa",ic:"🚗"},{l:"Rating",v:"4.9★",c:"#f59e0b",ic:"⭐"}].map((s,i) => (
              <div key={i} style={{ flex: 1, background: "rgba(255,255,255,0.04)", borderRadius: 12, padding: "7px 8px", backdropFilter: "blur(10px)", border: "1px solid rgba(255,255,255,0.06)" }}>
                <div style={{ fontSize: 11 }}>{s.ic}</div>
                <div style={{ fontSize: 7, color: "#475569", marginTop: 2 }}>{s.l}</div>
                <div style={{ fontSize: 11, fontWeight: 800, color: s.c }}>{s.v}</div>
              </div>
            ))}
          </div>
        </div>

        {/* Bottom Sheet */}
        <div style={{ position: "absolute", bottom: 0, left: 0, right: 0,
          background: "linear-gradient(180deg, rgba(10,10,20,0) 0%, #0a0a14 25%)",
          padding: "30px 14px 14px",
        }}>
          <div style={{ background: "#0f172a", borderRadius: 20, padding: "14px 15px", border: "1px solid rgba(255,255,255,0.07)", backdropFilter: "blur(20px)" }}>
            <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
              <div>
                <div style={{ fontSize: 13, fontWeight: 800, color: "white" }}>You're ONLINE</div>
                <div style={{ fontSize: 9, color: "#22c55e", marginTop: 2 }}>● Searching for rides...</div>
              </div>
              <div style={{ width: 48, height: 26, background: "linear-gradient(135deg,#22c55e,#16a34a)", borderRadius: 13, position: "relative", boxShadow: "0 4px 14px rgba(34,197,94,0.4)" }}>
                <div style={{ position: "absolute", right: 3, top: 3, width: 20, height: 20, background: "white", borderRadius: "50%", boxShadow: "0 2px 6px rgba(0,0,0,0.3)" }} />
              </div>
            </div>
            <div style={{ height: 1, background: "rgba(255,255,255,0.05)", margin: "10px 0" }} />
            <div style={{ display: "flex", gap: 7 }}>
              {["💰 Wallet: ₹240","📋 History","⚙️ Settings"].map((btn,i) => (
                <div key={i} style={{ flex: 1, background: "rgba(255,255,255,0.04)", borderRadius: 10, padding: "6px 0", textAlign: "center", fontSize: 7.5, color: "#64748b" }}>{btn}</div>
              ))}
            </div>
          </div>
        </div>
      </div>
    </PhoneFrame>
  );
}

function DarkDriverNewTrip() {
  return (
    <PhoneFrame bg="#0a0a14">
      <div style={{ minHeight: 428, background: "#0a0a14", position: "relative", overflow: "hidden" }}>
        <div style={{ position: "absolute", inset: 0, background: "rgba(0,0,0,0.65)", zIndex: 1 }} />
        {/* Glow rings */}
        {[80, 110, 140].map((s,i) => (
          <div key={i} style={{
            position: "absolute", top: "22%", left: "50%", transform: "translate(-50%,-50%)",
            width: s, height: s, borderRadius: "50%",
            border: `1.5px solid rgba(245,158,11,${0.3 - i * 0.08})`,
            zIndex: 2,
          }} />
        ))}
        <div style={{
          position: "absolute", top: "22%", left: "50%", transform: "translate(-50%,-50%)",
          width: 60, height: 60, borderRadius: "50%",
          background: "linear-gradient(135deg,#f59e0b,#ef4444)",
          display: "flex", alignItems: "center", justifyContent: "center",
          boxShadow: "0 0 40px rgba(245,158,11,0.7)", zIndex: 3, fontSize: 24,
        }}>🔔</div>

        <div style={{
          position: "absolute", bottom: 0, left: 0, right: 0, zIndex: 4,
          background: "linear-gradient(180deg, #0d1525 0%, #0a0f1a 100%)",
          borderRadius: "26px 26px 0 0",
          padding: "16px 16px 14px",
          border: "1px solid rgba(245,158,11,0.2)",
          boxShadow: "0 -20px 60px rgba(245,158,11,0.12)",
        }}>
          <div style={{ textAlign: "center", marginBottom: 12 }}>
            <div style={{ fontSize: 11, color: "#f59e0b", fontWeight: 800, textTransform: "uppercase", letterSpacing: 1.5 }}>🔔 New Ride Request!</div>
            <div style={{ fontSize: 8, color: "#475569", marginTop: 3 }}>Auto-cancel in 28 seconds</div>
            <div style={{ height: 4, background: "#1e293b", borderRadius: 2, marginTop: 8, overflow: "hidden" }}>
              <div style={{ width: "65%", height: "100%", background: "linear-gradient(90deg,#22c55e,#f59e0b,#ef4444)", borderRadius: 2 }} />
            </div>
          </div>

          <div style={{ background: "#111827", borderRadius: 14, padding: "11px 13px", marginBottom: 10, border: "1px solid rgba(255,255,255,0.06)" }}>
            <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 9 }}>
              <div style={{ display: "flex", alignItems: "center", gap: 7 }}>
                <div style={{ width: 32, height: 32, borderRadius: "50%", background: "linear-gradient(135deg,#7c3aed,#4f46e5)", display: "flex", alignItems: "center", justifyContent: "center", fontSize: 13, fontWeight: 700, color: "white" }}>A</div>
                <div>
                  <div style={{ fontSize: 12, fontWeight: 800, color: "white" }}>Arjun Reddy</div>
                  <div style={{ display: "flex", gap: 2 }}>{[...Array(5)].map((_,i) => <span key={i} style={{ fontSize: 7, color: "#f59e0b" }}>★</span>)}<span style={{ fontSize: 7, color: "#64748b" }}>4.9</span></div>
                </div>
              </div>
              <div style={{ background: "rgba(245,158,11,0.15)", border: "1px solid rgba(245,158,11,0.3)", borderRadius: 10, padding: "4px 10px", fontSize: 13, color: "#f59e0b", fontWeight: 800 }}>₹185</div>
            </div>
            {[
              { dot: "#22c55e", label: "MGBS Bus Stand, Hyderabad" },
              { dot: "#ef4444", label: "Banjara Hills Road No. 12" },
            ].map((loc, i) => (
              <div key={i} style={{ display: "flex", gap: 7, alignItems: "center", marginTop: i === 0 ? 0 : 5 }}>
                <div style={{ width: 8, height: 8, borderRadius: "50%", background: loc.dot, flexShrink: 0, boxShadow: `0 0 6px ${loc.dot}` }} />
                <span style={{ fontSize: 9, color: "#94a3b8" }}>{loc.label}</span>
              </div>
            ))}
            <div style={{ display: "flex", gap: 12, marginTop: 8 }}>
              <span style={{ fontSize: 8.5, color: "#60a5fa" }}>📍 2.4 km away</span>
              <span style={{ fontSize: 8.5, color: "#a78bfa" }}>⏱ 8 min pickup</span>
            </div>
          </div>

          <div style={{ display: "flex", gap: 8 }}>
            <div style={{ flex: 1, background: "#1e293b", borderRadius: 12, padding: "11px 0", textAlign: "center", fontSize: 11, fontWeight: 600, color: "#64748b" }}>✕ Reject</div>
            <div style={{ flex: 2, background: "linear-gradient(135deg,#22c55e,#16a34a)", borderRadius: 12, padding: "11px 0", textAlign: "center", fontSize: 11, fontWeight: 700, color: "white", boxShadow: "0 6px 20px rgba(34,197,94,0.4)" }}>✓ Accept Ride</div>
          </div>
        </div>
      </div>
    </PhoneFrame>
  );
}

function DarkDriverOnTrip() {
  return (
    <PhoneFrame bg="#0a0a14">
      <div style={{ minHeight: 428, background: "#0a0a14", position: "relative", overflow: "hidden" }}>
        <div style={{ position: "absolute", inset: 0, background: "radial-gradient(ellipse at 45% 40%, #0d2137 0%, #0a0a14 80%)" }}>
          <div style={{ position: "absolute", left: "38%", top: "22%", width: 2.5, height: "55%", background: "linear-gradient(180deg,#22c55e,#f59e0b50)", borderRadius: 2 }} />
          <div style={{ position: "absolute", top: "22%", left: "36%", width: 10, height: 10, background: "#22c55e", borderRadius: "50%", boxShadow: "0 0 14px #22c55e" }} />
          <div style={{ position: "absolute", top: "53%", left: "34%", width: 26, height: 26, background: "linear-gradient(135deg,#f59e0b,#ef4444)", borderRadius: "50%",
            display: "flex", alignItems: "center", justifyContent: "center",
            boxShadow: "0 0 0 6px rgba(245,158,11,0.15)", fontSize: 12,
          }}>🚗</div>
          <div style={{ position: "absolute", top: "77%", left: "36%", width: 10, height: 10, background: "#ef4444", borderRadius: "50%", boxShadow: "0 0 14px #ef4444" }} />
        </div>

        <div style={{ position: "relative", zIndex: 2, background: "rgba(10,10,20,0.92)", padding: "8px 14px 10px", backdropFilter: "blur(16px)", borderBottom: "1px solid rgba(255,255,255,0.05)" }}>
          <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
            <div>
              <div style={{ fontSize: 7.5, color: "#22c55e", fontWeight: 700, textTransform: "uppercase", letterSpacing: 1 }}>● On The Way</div>
              <div style={{ fontSize: 12, fontWeight: 700, color: "white", marginTop: 1 }}>Banjara Hills Rd 12</div>
            </div>
            <div style={{ background: "rgba(34,197,94,0.1)", border: "1px solid rgba(34,197,94,0.25)", borderRadius: 10, padding: "4px 10px" }}>
              <span style={{ fontSize: 12, fontWeight: 800, color: "#22c55e" }}>12 min</span>
            </div>
          </div>
        </div>

        <div style={{ position: "absolute", bottom: 0, left: 0, right: 0, zIndex: 3,
          background: "linear-gradient(180deg, rgba(10,10,20,0) 0%, #0a0f1a 25%)",
          padding: "30px 14px 14px",
        }}>
          <div style={{ background: "#0f172a", borderRadius: 20, padding: "13px 14px", border: "1px solid rgba(255,255,255,0.07)" }}>
            <div style={{ display: "flex", gap: 10, alignItems: "center", marginBottom: 10 }}>
              <div style={{ width: 38, height: 38, borderRadius: "50%", background: "linear-gradient(135deg,#7c3aed,#a78bfa)", display: "flex", alignItems: "center", justifyContent: "center", fontSize: 16, fontWeight: 800, color: "white" }}>A</div>
              <div style={{ flex: 1 }}>
                <div style={{ fontSize: 12, fontWeight: 700, color: "white" }}>Arjun Reddy</div>
                <div style={{ display: "flex", gap: 3 }}>{[...Array(5)].map((_,i) => <span key={i} style={{ fontSize: 8, color: "#f59e0b" }}>★</span>)}<span style={{ fontSize: 8, color: "#64748b", marginLeft: 2 }}>4.9</span></div>
              </div>
              <div style={{ display: "flex", gap: 6 }}>
                {["📞","💬"].map((ic,i) => <div key={i} style={{ width: 32, height: 32, borderRadius: "50%", background: "#1e293b", display: "flex", alignItems: "center", justifyContent: "center", fontSize: 13 }}>{ic}</div>)}
              </div>
            </div>

            <div style={{ display: "flex", gap: 6, marginBottom: 10 }}>
              {[{l:"Distance",v:"7.2 km"},{l:"Duration",v:"12 min"},{l:"Fare",v:"₹185"}].map((s,i) => (
                <div key={i} style={{ flex: 1, background: "#111827", borderRadius: 10, padding: "7px 0", textAlign: "center", border: "1px solid rgba(255,255,255,0.04)" }}>
                  <div style={{ fontSize: 7.5, color: "#475569" }}>{s.l}</div>
                  <div style={{ fontSize: 11, fontWeight: 700, color: "white", marginTop: 2 }}>{s.v}</div>
                </div>
              ))}
            </div>

            <div style={{ background: "linear-gradient(135deg,#16a34a,#15803d)", borderRadius: 13, padding: "11px 0", textAlign: "center", fontSize: 11, fontWeight: 700, color: "white", boxShadow: "0 6px 18px rgba(22,163,74,0.4)" }}>🏁 Complete Trip</div>
          </div>
        </div>
      </div>
    </PhoneFrame>
  );
}

function DarkDriverWallet() {
  return (
    <PhoneFrame bg="#0a0a14">
      <div style={{ minHeight: 428, background: "#0a0a14" }}>
        <div style={{ background: "linear-gradient(135deg,#12112a,#0d1f35)", padding: "10px 16px 20px", position: "relative", overflow: "hidden" }}>
          <div style={{ position: "absolute", top: 0, right: 0, width: 120, height: 120, background: "radial-gradient(circle at top right, rgba(245,158,11,0.1) 0%, transparent 70%)" }} />
          <div style={{ display: "flex", alignItems: "center", gap: 7, marginBottom: 14 }}>
            <JagoLogo size={22} variant="amber" />
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
            <div key={i} style={{ display: "flex", alignItems: "center", gap: 9, marginBottom: 7, background: "#0f172a", borderRadius: 12, padding: "9px 11px", border: "1px solid rgba(255,255,255,0.04)" }}>
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
    <PhoneFrame bg="#fff8ed">
      <div style={{
        minHeight: 428,
        background: "linear-gradient(160deg, #fff8ed 0%, #fef3c7 40%, #fffbf5 100%)",
        display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center",
        padding: "0 24px", gap: 0, position: "relative", overflow: "hidden",
      }}>
        <div style={{ position: "absolute", top: "15%", right: "10%", width: 100, height: 100, borderRadius: "50%", background: "radial-gradient(circle, rgba(245,158,11,0.2) 0%, transparent 70%)" }} />
        <div style={{ position: "absolute", bottom: "20%", left: "5%", width: 80, height: 80, borderRadius: "50%", background: "radial-gradient(circle, rgba(239,68,68,0.1) 0%, transparent 70%)" }} />

        <div style={{ background: "rgba(10,10,20,0.85)", borderRadius: 22, padding: "14px 22px", backdropFilter: "blur(4px)", boxShadow: "0 20px 50px rgba(245,158,11,0.2)" }}>
          <img src="/jago-pilot-logo.png" alt="JAGO Pilot" style={{ height: 72, width: "auto", objectFit: "contain" }} />
        </div>

        <div style={{ marginTop: 20, fontSize: 9, color: "#92400e", letterSpacing: 1 }}>Your Earnings. Your Journey.</div>

        <div style={{ marginTop: 20, width: 48, height: 4, background: "linear-gradient(90deg,#f59e0b,#ef4444)", borderRadius: 2 }} />
        <div style={{ marginTop: 20, fontSize: 9, color: "#d1d5db" }}>Version 2.0.1</div>

        <div style={{ position: "absolute", bottom: 0, left: 0, right: 0, height: 2, background: "linear-gradient(90deg, transparent, rgba(245,158,11,0.5), transparent)" }} />
      </div>
    </PhoneFrame>
  );
}

function LightDriverLogin() {
  return (
    <PhoneFrame bg="white">
      <div style={{ minHeight: 428, background: "white", padding: "24px 18px 18px", position: "relative", overflow: "hidden" }}>
        <div style={{ position: "absolute", top: 0, right: 0, width: 160, height: 160, background: "radial-gradient(circle at top right, rgba(245,158,11,0.08) 0%, transparent 70%)" }} />

        <div style={{ display: "flex", alignItems: "center", gap: 8, marginBottom: 22 }}>
          <JagoLogo size={32} variant="amber" />
          <div style={{ fontSize: 13, fontWeight: 800, color: "#1c1917", letterSpacing: 1 }}>JAGO</div>
          <div style={{ fontSize: 8, color: "#d97706", background: "#fef3c7", padding: "2px 7px", borderRadius: 6, marginLeft: 2, fontWeight: 800, letterSpacing: 0.5, border: "1px solid #fde68a" }}>PILOT</div>
        </div>

        <div style={{ color: "#1c1917", fontSize: 20, fontWeight: 800, lineHeight: 1.2 }}>Welcome<br />Back <span style={{ fontSize: 18 }}>👋</span></div>
        <div style={{ color: "#9ca3af", fontSize: 10, marginTop: 6 }}>Login చేసి earning start చేయండి</div>

        <div style={{ marginTop: 22, display: "flex", flexDirection: "column", gap: 10 }}>
          <div>
            <div style={{ fontSize: 9, color: "#6b7280", fontWeight: 600, marginBottom: 5, textTransform: "uppercase", letterSpacing: 0.5 }}>Phone Number</div>
            <div style={{ background: "#fafafa", borderRadius: 14, padding: "11px 13px", display: "flex", alignItems: "center", gap: 8, border: "1.5px solid #f59e0b66", boxShadow: "0 0 0 3px rgba(245,158,11,0.08)" }}>
              <div style={{ padding: "2px 7px", background: "#fef3c7", borderRadius: 6, fontSize: 10, color: "#d97706", fontWeight: 700 }}>+91</div>
              <div style={{ width: 1, height: 14, background: "#e5e7eb" }} />
              <span style={{ fontSize: 11, color: "#9ca3af" }}>98765 43210</span>
            </div>
          </div>

          <div>
            <div style={{ fontSize: 9, color: "#6b7280", fontWeight: 600, marginBottom: 5, textTransform: "uppercase", letterSpacing: 0.5 }}>OTP</div>
            <div style={{ display: "flex", gap: 6 }}>
              {["5","2","•","•"].map((d, i) => (
                <div key={i} style={{
                  flex: 1, background: d !== "•" ? "#fff8ed" : "#fafafa",
                  border: `1.5px solid ${d !== "•" ? "#f59e0b" : "#e5e7eb"}`,
                  borderRadius: 12, padding: "10px 0", textAlign: "center",
                  color: d !== "•" ? "#1c1917" : "#d1d5db", fontSize: 15, fontWeight: 800,
                }}>{d}</div>
              ))}
            </div>
          </div>

          <div style={{ marginTop: 4, background: "linear-gradient(135deg,#f59e0b,#ef4444)", borderRadius: 14, padding: "12px 0", textAlign: "center", color: "white", fontSize: 12, fontWeight: 700, letterSpacing: 0.5, boxShadow: "0 8px 24px rgba(245,158,11,0.35)" }}>Verify & Login →</div>
          <div style={{ textAlign: "center", fontSize: 9, color: "#9ca3af" }}>OTP resend in <span style={{ color: "#f59e0b", fontWeight: 600 }}>28s</span></div>
        </div>
      </div>
    </PhoneFrame>
  );
}

function LightDriverHome() {
  return (
    <PhoneFrame bg="#f8fafc">
      <div style={{ minHeight: 428, background: "#f8fafc", position: "relative", overflow: "hidden" }}>
        <div style={{ position: "absolute", inset: 0, background: "linear-gradient(160deg, #fef3c7 0%, #e0f2fe 60%, #f8fafc 100%)" }}>
          {[...Array(8)].map((_, i) => <div key={i} style={{ position: "absolute", left: 0, right: 0, top: `${12 * i}%`, height: 1, background: "rgba(0,0,0,0.04)" }} />)}
          {[...Array(6)].map((_, i) => <div key={i} style={{ position: "absolute", top: 0, bottom: 0, left: `${16 * i}%`, width: 1, background: "rgba(0,0,0,0.04)" }} />)}
          <div style={{ position: "absolute", top: "50%", left: "46%", width: 24, height: 24, background: "linear-gradient(135deg,#f59e0b,#ef4444)", borderRadius: "50%", display: "flex", alignItems: "center", justifyContent: "center", boxShadow: "0 0 0 8px rgba(245,158,11,0.15)", fontSize: 11 }}>🚗</div>
        </div>

        <div style={{ position: "relative", zIndex: 2, padding: "8px 14px 0" }}>
          <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
            <div style={{ display: "flex", alignItems: "center", gap: 7 }}>
              <JagoLogo size={24} variant="amber" />
              <div>
                <div style={{ fontSize: 7, color: "#6b7280" }}>Good Morning</div>
                <div style={{ fontSize: 12, fontWeight: 800, color: "#1c1917" }}>Anil Driver 👋</div>
              </div>
            </div>
            <div style={{ width: 28, height: 28, borderRadius: "50%", background: "linear-gradient(135deg,#f59e0b,#ef4444)", display: "flex", alignItems: "center", justifyContent: "center", fontSize: 11, fontWeight: 800, color: "white" }}>A</div>
          </div>
          <div style={{ display: "flex", gap: 6, marginTop: 10 }}>
            {[{l:"Today",v:"₹1,240",c:"#16a34a",bg:"#dcfce7",ic:"💰"},{l:"Trips",v:"8",c:"#2563eb",bg:"#dbeafe",ic:"🚗"},{l:"Rating",v:"4.9★",c:"#d97706",bg:"#fef3c7",ic:"⭐"}].map((s,i) => (
              <div key={i} style={{ flex: 1, background: "white", borderRadius: 12, padding: "7px 8px", boxShadow: "0 2px 8px rgba(0,0,0,0.06)", border: "1px solid rgba(0,0,0,0.04)" }}>
                <div style={{ fontSize: 11 }}>{s.ic}</div>
                <div style={{ fontSize: 7, color: "#9ca3af", marginTop: 2 }}>{s.l}</div>
                <div style={{ fontSize: 11, fontWeight: 800, color: s.c }}>{s.v}</div>
              </div>
            ))}
          </div>
        </div>

        <div style={{ position: "absolute", bottom: 0, left: 0, right: 0, background: "linear-gradient(180deg, rgba(248,250,252,0) 0%, #f8fafc 30%)", padding: "30px 14px 14px" }}>
          <div style={{ background: "white", borderRadius: 20, padding: "14px 15px", boxShadow: "0 8px 30px rgba(0,0,0,0.1)", border: "1px solid rgba(0,0,0,0.06)" }}>
            <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
              <div>
                <div style={{ fontSize: 13, fontWeight: 800, color: "#1c1917" }}>You're ONLINE</div>
                <div style={{ fontSize: 9, color: "#16a34a", marginTop: 2 }}>● Looking for rides...</div>
              </div>
              <div style={{ width: 48, height: 26, background: "linear-gradient(135deg,#22c55e,#16a34a)", borderRadius: 13, position: "relative", boxShadow: "0 4px 12px rgba(34,197,94,0.35)" }}>
                <div style={{ position: "absolute", right: 3, top: 3, width: 20, height: 20, background: "white", borderRadius: "50%" }} />
              </div>
            </div>
            <div style={{ height: 1, background: "#f3f4f6", margin: "10px 0" }} />
            <div style={{ display: "flex", gap: 7 }}>
              {["💰 ₹240","📋 History","⚙️ Settings"].map((btn,i) => (
                <div key={i} style={{ flex: 1, background: "#f9fafb", borderRadius: 10, padding: "6px 0", textAlign: "center", fontSize: 7.5, color: "#6b7280", border: "1px solid #f3f4f6" }}>{btn}</div>
              ))}
            </div>
          </div>
        </div>
      </div>
    </PhoneFrame>
  );
}

function LightDriverWallet() {
  return (
    <PhoneFrame bg="white">
      <div style={{ minHeight: 428, background: "white" }}>
        <div style={{ background: "linear-gradient(135deg,#fffbeb,#fff7ed)", padding: "10px 16px 20px", position: "relative", overflow: "hidden", borderBottom: "1px solid #fef3c7" }}>
          <div style={{ display: "flex", alignItems: "center", gap: 7, marginBottom: 14 }}>
            <JagoLogo size={22} variant="amber" />
            <div style={{ fontSize: 8, color: "#d97706", textTransform: "uppercase", fontWeight: 700, letterSpacing: 1 }}>Driver Wallet</div>
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
            <div key={i} style={{ display: "flex", alignItems: "center", gap: 9, marginBottom: 7, background: "#fafafa", borderRadius: 12, padding: "9px 11px", border: "1px solid #f3f4f6" }}>
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
    <PhoneFrame bg="#0d0b1a">
      <div style={{
        minHeight: 428,
        background: "linear-gradient(160deg, #0d0b1a 0%, #13103a 45%, #0b1733 100%)",
        display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center",
        padding: "0 24px", gap: 0, position: "relative", overflow: "hidden",
      }}>
        <div style={{ position: "absolute", top: "20%", left: "50%", transform: "translateX(-50%)", width: 180, height: 180, borderRadius: "50%", background: "radial-gradient(circle, rgba(124,58,237,0.15) 0%, transparent 70%)" }} />
        <div style={{ position: "absolute", bottom: "10%", right: "-10%", width: 120, height: 120, borderRadius: "50%", background: "radial-gradient(circle, rgba(79,70,229,0.1) 0%, transparent 70%)" }} />

        <JagoLogo size={90} variant="purple" />
        <div style={{ marginTop: 20, width: 48, height: 4, background: "linear-gradient(90deg,#7c3aed,#4f46e5)", borderRadius: 2 }} />
        <div style={{ marginTop: 20, fontSize: 9, color: "#334155" }}>Version 2.0.1</div>
        <div style={{ position: "absolute", bottom: 0, left: 0, right: 0, height: 2, background: "linear-gradient(90deg, transparent, #7c3aed44, transparent)" }} />
      </div>
    </PhoneFrame>
  );
}

function DarkCustomerLogin() {
  return (
    <PhoneFrame bg="#0d0b1a">
      <div style={{ minHeight: 428, background: "linear-gradient(180deg, #0d0b1a 0%, #0f172a 100%)", padding: "24px 18px 18px", position: "relative", overflow: "hidden" }}>
        <div style={{ position: "absolute", top: 0, right: 0, width: 140, height: 140, background: "radial-gradient(circle at top right, rgba(124,58,237,0.1) 0%, transparent 70%)" }} />

        <div style={{ display: "flex", alignItems: "center", gap: 8, marginBottom: 20 }}>
          <JagoLogo size={32} variant="purple" />
          <div style={{ fontSize: 13, fontWeight: 800, color: "white", letterSpacing: 1 }}>JAGO</div>
          <div style={{ fontSize: 8, color: "#a78bfa", background: "rgba(124,58,237,0.1)", padding: "2px 6px", borderRadius: 6, marginLeft: 4 }}>CUSTOMER</div>
        </div>

        <div style={{ color: "white", fontSize: 20, fontWeight: 800, lineHeight: 1.2 }}>Hello <span style={{ fontSize: 18 }}>👋</span><br /><span style={{ color: "#a78bfa" }}>Where to?</span></div>
        <div style={{ color: "#475569", fontSize: 10, marginTop: 6 }}>Phone number తో login చేయండి</div>

        <div style={{ marginTop: 22, display: "flex", flexDirection: "column", gap: 10 }}>
          <div>
            <div style={{ fontSize: 9, color: "#64748b", fontWeight: 600, marginBottom: 5, textTransform: "uppercase", letterSpacing: 0.5 }}>Phone Number</div>
            <div style={{ background: "#1e1a3a", borderRadius: 14, padding: "11px 13px", display: "flex", alignItems: "center", gap: 8, border: "1.5px solid #7c3aed44", boxShadow: "0 0 0 3px rgba(124,58,237,0.05)" }}>
              <div style={{ padding: "2px 6px", background: "rgba(124,58,237,0.2)", borderRadius: 6, fontSize: 10, color: "#a78bfa", fontWeight: 700 }}>+91</div>
              <div style={{ width: 1, height: 14, background: "#334155" }} />
              <span style={{ fontSize: 11, color: "#64748b" }}>98765 43210</span>
            </div>
          </div>

          <div>
            <div style={{ fontSize: 9, color: "#64748b", fontWeight: 600, marginBottom: 5, textTransform: "uppercase", letterSpacing: 0.5 }}>OTP</div>
            <div style={{ display: "flex", gap: 6, justifyContent: "center" }}>
              {["8","4","2","•"].map((d, i) => (
                <div key={i} style={{
                  flex: 1, background: d !== "•" ? "rgba(124,58,237,0.1)" : "#1e1a3a",
                  border: `1.5px solid ${d !== "•" ? "#7c3aed55" : "#1e293b"}`,
                  borderRadius: 12, padding: "10px 0", textAlign: "center",
                  color: d !== "•" ? "white" : "#334155", fontSize: 15, fontWeight: 800,
                }}>{d}</div>
              ))}
            </div>
          </div>

          <div style={{ marginTop: 4, background: "linear-gradient(135deg,#7c3aed,#4f46e5)", borderRadius: 14, padding: "12px 0", textAlign: "center", color: "white", fontSize: 12, fontWeight: 700, letterSpacing: 0.5, boxShadow: "0 8px 24px rgba(124,58,237,0.4)" }}>Verify & Continue →</div>

          <div style={{ textAlign: "center", padding: "10px 12px", background: "#1e1a3a", borderRadius: 12, display: "flex", gap: 8, alignItems: "center" }}>
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
    <PhoneFrame bg="#0d0b1a">
      <div style={{ minHeight: 428, background: "#0d0b1a", position: "relative", overflow: "hidden" }}>
        <div style={{ position: "absolute", inset: 0, background: "radial-gradient(ellipse at 50% 55%, #13103a 0%, #0d0b1a 75%)" }}>
          {[...Array(8)].map((_, i) => <div key={i} style={{ position: "absolute", left: 0, right: 0, top: `${12 * i}%`, height: 1, background: "rgba(255,255,255,0.02)" }} />)}
          {[...Array(6)].map((_, i) => <div key={i} style={{ position: "absolute", top: 0, bottom: 0, left: `${16 * i}%`, width: 1, background: "rgba(255,255,255,0.02)" }} />)}
          {[{t:"38%",l:"26%"},{t:"55%",l:"62%"},{t:"65%",l:"42%"}].map((p,i) => (
            <div key={i} style={{ position: "absolute", top: p.t, left: p.l, fontSize: 14 }}>🚗</div>
          ))}
          <div style={{ position: "absolute", top: "50%", left: "48%", display: "flex", flexDirection: "column", alignItems: "center" }}>
            <div style={{ width: 14, height: 14, background: "#7c3aed", borderRadius: "50%", border: "3px solid rgba(255,255,255,0.2)", boxShadow: "0 0 0 6px rgba(124,58,237,0.2)" }} />
            <div style={{ width: 2, height: 6, background: "#7c3aed" }} />
          </div>
        </div>

        <div style={{ position: "relative", zIndex: 2, padding: "8px 14px" }}>
          <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
            <div style={{ display: "flex", alignItems: "center", gap: 7 }}>
              <JagoLogo size={24} variant="purple" />
              <div>
                <div style={{ fontSize: 7, color: "#475569" }}>Hello,</div>
                <div style={{ fontSize: 12, fontWeight: 800, color: "white" }}>Arjun Reddy 🙌</div>
              </div>
            </div>
            <div style={{ padding: "4px 10px", background: "rgba(124,58,237,0.15)", border: "1px solid rgba(124,58,237,0.25)", borderRadius: 20, fontSize: 9, fontWeight: 700, color: "#a78bfa" }}>💰 ₹250</div>
          </div>
        </div>

        <div style={{ position: "absolute", bottom: 0, left: 0, right: 0, zIndex: 3, background: "linear-gradient(180deg, rgba(13,11,26,0) 0%, #0d0b1a 25%)", padding: "30px 14px 14px" }}>
          <div style={{ background: "#13103a", borderRadius: 20, padding: "14px", border: "1px solid rgba(124,58,237,0.2)", boxShadow: "0 -8px 30px rgba(124,58,237,0.1)" }}>
            <div style={{ background: "#1e1a3a", borderRadius: 13, padding: "10px 12px", display: "flex", alignItems: "center", gap: 8, marginBottom: 12, border: "1px solid rgba(124,58,237,0.15)" }}>
              <span style={{ fontSize: 12 }}>🔍</span>
              <span style={{ fontSize: 10, color: "#475569" }}>Where do you want to go?</span>
            </div>
            <div style={{ display: "flex", gap: 7 }}>
              {[{ic:"🏠",l:"Home"},{ic:"💼",l:"Office"},{ic:"⭐",l:"Saved"}].map((q,i) => (
                <div key={i} style={{ flex: 1, background: "rgba(124,58,237,0.1)", border: "1px solid rgba(124,58,237,0.15)", borderRadius: 11, padding: "8px 0", textAlign: "center" }}>
                  <div style={{ fontSize: 12 }}>{q.ic}</div>
                  <div style={{ fontSize: 8, color: "#a78bfa", marginTop: 2, fontWeight: 600 }}>{q.l}</div>
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>
    </PhoneFrame>
  );
}

function DarkCustomerTracking() {
  return (
    <PhoneFrame bg="#0d0b1a">
      <div style={{ minHeight: 428, background: "#0d0b1a", position: "relative", overflow: "hidden" }}>
        <div style={{ position: "absolute", inset: 0, background: "radial-gradient(ellipse at 45% 35%, #13103a 0%, #0d0b1a 80%)" }}>
          <div style={{ position: "absolute", left: "38%", top: "20%", width: 2, height: "50%", background: "linear-gradient(180deg,#7c3aed,#4f46e560)", borderRadius: 2 }} />
          <div style={{ position: "absolute", top: "20%", left: "36%", width: 10, height: 10, background: "#7c3aed", borderRadius: "50%", boxShadow: "0 0 14px #7c3aed" }} />
          <div style={{ position: "absolute", top: "53%", left: "34%", width: 24, height: 24, background: "linear-gradient(135deg,#7c3aed,#4f46e5)", borderRadius: "50%", display: "flex", alignItems: "center", justifyContent: "center", boxShadow: "0 0 0 6px rgba(124,58,237,0.2)", fontSize: 12 }}>🚗</div>
          <div style={{ position: "absolute", top: "70%", left: "36%", width: 10, height: 10, background: "#ef4444", borderRadius: "50%", boxShadow: "0 0 12px #ef4444" }} />
        </div>

        <div style={{ position: "relative", zIndex: 2, background: "rgba(13,11,26,0.9)", padding: "8px 14px 10px", backdropFilter: "blur(16px)", borderBottom: "1px solid rgba(124,58,237,0.15)" }}>
          <div style={{ fontSize: 7.5, color: "#a78bfa", fontWeight: 700, textTransform: "uppercase", letterSpacing: 1 }}>● Driver On The Way</div>
          <div style={{ fontSize: 12, fontWeight: 700, color: "white", marginTop: 1 }}>Arriving in 4 min</div>
        </div>

        <div style={{ position: "absolute", bottom: 0, left: 0, right: 0, zIndex: 3, background: "linear-gradient(180deg, rgba(13,11,26,0) 0%, #0d0b1a 25%)", padding: "30px 14px 14px" }}>
          <div style={{ background: "#13103a", borderRadius: 20, padding: "13px 14px", border: "1px solid rgba(124,58,237,0.2)" }}>
            <div style={{ display: "flex", gap: 10, alignItems: "center", marginBottom: 10 }}>
              <div style={{ width: 38, height: 38, borderRadius: "50%", background: "linear-gradient(135deg,#f59e0b,#ef4444)", display: "flex", alignItems: "center", justifyContent: "center", fontSize: 16, fontWeight: 800, color: "white" }}>A</div>
              <div style={{ flex: 1 }}>
                <div style={{ fontSize: 12, fontWeight: 700, color: "white" }}>Anil Driver</div>
                <div style={{ display: "flex", gap: 3 }}>{[...Array(5)].map((_,i) => <span key={i} style={{ fontSize: 8, color: "#f59e0b" }}>★</span>)}<span style={{ fontSize: 8, color: "#64748b", marginLeft: 2 }}>4.9</span></div>
              </div>
              <div style={{ display: "flex", gap: 6 }}>
                {["📞","💬"].map((ic,i) => <div key={i} style={{ width: 32, height: 32, borderRadius: "50%", background: "#1e1a3a", border: "1px solid rgba(124,58,237,0.2)", display: "flex", alignItems: "center", justifyContent: "center", fontSize: 13 }}>{ic}</div>)}
              </div>
            </div>

            <div style={{ background: "#1e1a3a", borderRadius: 13, padding: "10px 12px", border: "1px solid rgba(124,58,237,0.15)", textAlign: "center" }}>
              <div style={{ fontSize: 8, color: "#a78bfa", fontWeight: 600, textTransform: "uppercase", letterSpacing: 1 }}>🔐 Your OTP</div>
              <div style={{ fontSize: 28, fontWeight: 900, color: "white", letterSpacing: 6, marginTop: 4 }}>7 9 2 3</div>
              <div style={{ fontSize: 7.5, color: "#64748b", marginTop: 3 }}>Share this with driver when they arrive</div>
            </div>
          </div>
        </div>
      </div>
    </PhoneFrame>
  );
}

function DarkCustomerWallet() {
  return (
    <PhoneFrame bg="#0d0b1a">
      <div style={{ minHeight: 428, background: "#0d0b1a" }}>
        <div style={{ background: "linear-gradient(135deg,#13103a,#0b1733)", padding: "10px 16px 20px", position: "relative", overflow: "hidden" }}>
          <div style={{ display: "flex", alignItems: "center", gap: 7, marginBottom: 14 }}>
            <JagoLogo size={22} variant="purple" />
            <div style={{ fontSize: 8, color: "#a78bfa", textTransform: "uppercase", fontWeight: 600, letterSpacing: 1 }}>My Wallet</div>
          </div>
          <div style={{ textAlign: "center" }}>
            <div style={{ fontSize: 8, color: "#475569" }}>Available Balance</div>
            <div style={{ fontSize: 30, fontWeight: 900, color: "#a78bfa", lineHeight: 1, marginTop: 4 }}>₹250.00</div>
            <div style={{ fontSize: 8, color: "#475569", marginTop: 3 }}>Total spent: ₹3,200 this month</div>
          </div>
          <div style={{ display: "flex", gap: 8, marginTop: 14 }}>
            <div style={{ flex: 1, background: "rgba(124,58,237,0.15)", border: "1px solid rgba(124,58,237,0.25)", borderRadius: 12, padding: "9px 0", textAlign: "center", fontSize: 10, fontWeight: 700, color: "#a78bfa" }}>💳 Add Money</div>
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
            <div key={i} style={{ display: "flex", alignItems: "center", gap: 9, marginBottom: 7, background: "#13103a", borderRadius: 12, padding: "9px 11px", border: "1px solid rgba(124,58,237,0.12)" }}>
              <div style={{ width: 30, height: 30, borderRadius: 9, background: "#1e1a3a", display: "flex", alignItems: "center", justifyContent: "center", fontSize: 13 }}>{tx.icon}</div>
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
      <div style={{ minHeight: 428, background: "linear-gradient(160deg, #ede9fe 0%, #ddd6fe 40%, #c4b5fd 80%, #a78bfa 100%)", display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", padding: "0 24px", gap: 0, position: "relative", overflow: "hidden" }}>
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
        <div style={{ position: "absolute", top: 0, left: 0, right: 0, height: 4, background: "linear-gradient(90deg,#7c3aed,#4f46e5)" }} />
        <div style={{ position: "absolute", top: 0, right: 0, width: 140, height: 140, background: "radial-gradient(circle at top right, rgba(124,58,237,0.06) 0%, transparent 70%)" }} />

        <div style={{ display: "flex", alignItems: "center", gap: 8, marginBottom: 22 }}>
          <JagoLogo size={32} variant="purple" />
          <div style={{ fontSize: 13, fontWeight: 800, color: "#1c1917", letterSpacing: 1 }}>JAGO</div>
          <div style={{ fontSize: 8, color: "#7c3aed", background: "#ede9fe", padding: "2px 7px", borderRadius: 6, marginLeft: 4, fontWeight: 700 }}>CUSTOMER</div>
        </div>

        <div style={{ color: "#1c1917", fontSize: 20, fontWeight: 800, lineHeight: 1.2 }}>Hello <span style={{ fontSize: 18 }}>👋</span><br /><span style={{ color: "#7c3aed" }}>Where to?</span></div>
        <div style={{ color: "#9ca3af", fontSize: 10, marginTop: 6 }}>Phone number తో login చేయండి</div>

        <div style={{ marginTop: 22, display: "flex", flexDirection: "column", gap: 10 }}>
          <div>
            <div style={{ fontSize: 9, color: "#6b7280", fontWeight: 600, marginBottom: 5, textTransform: "uppercase", letterSpacing: 0.5 }}>Phone Number</div>
            <div style={{ background: "#fafafa", borderRadius: 14, padding: "11px 13px", display: "flex", alignItems: "center", gap: 8, border: "1.5px solid #7c3aed66", boxShadow: "0 0 0 3px rgba(124,58,237,0.06)" }}>
              <div style={{ padding: "2px 7px", background: "#ede9fe", borderRadius: 6, fontSize: 10, color: "#7c3aed", fontWeight: 700 }}>+91</div>
              <div style={{ width: 1, height: 14, background: "#e5e7eb" }} />
              <span style={{ fontSize: 11, color: "#9ca3af" }}>98765 43210</span>
            </div>
          </div>

          <div>
            <div style={{ fontSize: 9, color: "#6b7280", fontWeight: 600, marginBottom: 5, textTransform: "uppercase", letterSpacing: 0.5 }}>OTP</div>
            <div style={{ display: "flex", gap: 6, justifyContent: "center" }}>
              {["8","4","2","•"].map((d, i) => (
                <div key={i} style={{
                  flex: 1, background: d !== "•" ? "#ede9fe" : "#fafafa",
                  border: `1.5px solid ${d !== "•" ? "#7c3aed" : "#e5e7eb"}`,
                  borderRadius: 12, padding: "10px 0", textAlign: "center",
                  color: d !== "•" ? "#7c3aed" : "#d1d5db", fontSize: 15, fontWeight: 800,
                  boxShadow: d === "8" ? "0 0 0 3px rgba(124,58,237,0.1)" : "none",
                }}>{d}</div>
              ))}
            </div>
          </div>

          <div style={{ marginTop: 4, background: "linear-gradient(135deg,#7c3aed,#4f46e5)", borderRadius: 14, padding: "12px 0", textAlign: "center", color: "white", fontSize: 12, fontWeight: 700, letterSpacing: 0.5, boxShadow: "0 8px 24px rgba(124,58,237,0.35)" }}>Verify & Continue →</div>

          <div style={{ textAlign: "center", padding: "10px 12px", background: "#f9f7ff", borderRadius: 12, display: "flex", gap: 8, alignItems: "center", border: "1px solid #ede9fe" }}>
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
    <PhoneFrame bg="#f5f3ff">
      <div style={{ minHeight: 428, background: "#f5f3ff", position: "relative", overflow: "hidden" }}>
        <div style={{ position: "absolute", inset: 0, background: "linear-gradient(160deg, #ddd6fe 0%, #e0e7ff 50%, #f5f3ff 100%)" }}>
          {[...Array(8)].map((_, i) => <div key={i} style={{ position: "absolute", left: 0, right: 0, top: `${12 * i}%`, height: 1, background: "rgba(124,58,237,0.05)" }} />)}
          {[...Array(6)].map((_, i) => <div key={i} style={{ position: "absolute", top: 0, bottom: 0, left: `${16 * i}%`, width: 1, background: "rgba(124,58,237,0.05)" }} />)}
          {[{t:"35%",l:"25%"},{t:"52%",l:"62%"},{t:"62%",l:"40%"}].map((p,i) => (
            <div key={i} style={{ position: "absolute", top: p.t, left: p.l, fontSize: 14 }}>🚗</div>
          ))}
          <div style={{ position: "absolute", top: "48%", left: "48%", display: "flex", flexDirection: "column", alignItems: "center" }}>
            <div style={{ width: 14, height: 14, background: "#7c3aed", borderRadius: "50%", border: "3px solid white", boxShadow: "0 4px 14px rgba(124,58,237,0.4)" }} />
            <div style={{ width: 2, height: 6, background: "#7c3aed" }} />
          </div>
        </div>

        <div style={{ position: "relative", zIndex: 2, padding: "8px 14px" }}>
          <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
            <div style={{ display: "flex", alignItems: "center", gap: 7 }}>
              <JagoLogo size={24} variant="purple" />
              <div>
                <div style={{ fontSize: 7, color: "#6b7280" }}>Hello,</div>
                <div style={{ fontSize: 12, fontWeight: 800, color: "#1c1917" }}>Arjun Reddy 🙌</div>
              </div>
            </div>
            <div style={{ padding: "4px 10px", background: "white", borderRadius: 20, fontSize: 9, fontWeight: 700, color: "#7c3aed", boxShadow: "0 2px 8px rgba(124,58,237,0.15)", border: "1px solid #ede9fe" }}>💰 ₹250</div>
          </div>
        </div>

        <div style={{ position: "absolute", bottom: 0, left: 0, right: 0, zIndex: 3, background: "linear-gradient(180deg, rgba(245,243,255,0) 0%, #f5f3ff 30%)", padding: "30px 14px 14px" }}>
          <div style={{ background: "white", borderRadius: 20, padding: "14px", boxShadow: "0 8px 30px rgba(124,58,237,0.12)", border: "1px solid #ede9fe" }}>
            <div style={{ background: "#faf9ff", borderRadius: 13, padding: "10px 12px", display: "flex", alignItems: "center", gap: 8, marginBottom: 12, border: "1.5px solid #ede9fe" }}>
              <span style={{ fontSize: 12 }}>🔍</span>
              <span style={{ fontSize: 10, color: "#9ca3af" }}>Where do you want to go?</span>
            </div>
            <div style={{ display: "flex", gap: 7 }}>
              {[{ic:"🏠",l:"Home"},{ic:"💼",l:"Office"},{ic:"⭐",l:"Saved"}].map((q,i) => (
                <div key={i} style={{ flex: 1, background: "#faf9ff", border: "1px solid #ede9fe", borderRadius: 11, padding: "8px 0", textAlign: "center" }}>
                  <div style={{ fontSize: 12 }}>{q.ic}</div>
                  <div style={{ fontSize: 8, color: "#7c3aed", marginTop: 2, fontWeight: 600 }}>{q.l}</div>
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>
    </PhoneFrame>
  );
}

function LightCustomerTracking() {
  return (
    <PhoneFrame bg="white">
      <div style={{ minHeight: 428, background: "white", position: "relative", overflow: "hidden" }}>
        <div style={{ position: "absolute", inset: 0, background: "linear-gradient(160deg, #ddd6fe 0%, #e0e7ff 50%, #f1f5f9 100%)" }}>
          <div style={{ position: "absolute", left: "38%", top: "20%", width: 2, height: "50%", background: "linear-gradient(180deg,#7c3aed,#7c3aed40)", borderRadius: 2 }} />
          <div style={{ position: "absolute", top: "20%", left: "36%", width: 10, height: 10, background: "#7c3aed", borderRadius: "50%", boxShadow: "0 0 12px rgba(124,58,237,0.5)" }} />
          <div style={{ position: "absolute", top: "53%", left: "34%", width: 24, height: 24, background: "linear-gradient(135deg,#7c3aed,#4f46e5)", borderRadius: "50%", display: "flex", alignItems: "center", justifyContent: "center", boxShadow: "0 0 0 6px rgba(124,58,237,0.15)", fontSize: 12 }}>🚗</div>
          <div style={{ position: "absolute", top: "70%", left: "36%", width: 10, height: 10, background: "#ef4444", borderRadius: "50%", boxShadow: "0 0 12px rgba(239,68,68,0.5)" }} />
        </div>

        <div style={{ position: "relative", zIndex: 2, background: "rgba(255,255,255,0.9)", padding: "8px 14px 10px", backdropFilter: "blur(16px)", borderBottom: "1px solid rgba(124,58,237,0.1)" }}>
          <div style={{ fontSize: 7.5, color: "#7c3aed", fontWeight: 700, textTransform: "uppercase", letterSpacing: 1 }}>● Driver On The Way</div>
          <div style={{ fontSize: 12, fontWeight: 700, color: "#1c1917", marginTop: 1 }}>Arriving in 4 min</div>
        </div>

        <div style={{ position: "absolute", bottom: 0, left: 0, right: 0, zIndex: 3, background: "linear-gradient(180deg, rgba(255,255,255,0) 0%, white 25%)", padding: "30px 14px 14px" }}>
          <div style={{ background: "white", borderRadius: 20, padding: "13px 14px", boxShadow: "0 8px 30px rgba(124,58,237,0.12)", border: "1px solid #ede9fe" }}>
            <div style={{ display: "flex", gap: 10, alignItems: "center", marginBottom: 10 }}>
              <div style={{ width: 38, height: 38, borderRadius: "50%", background: "linear-gradient(135deg,#f59e0b,#ef4444)", display: "flex", alignItems: "center", justifyContent: "center", fontSize: 16, fontWeight: 800, color: "white" }}>A</div>
              <div style={{ flex: 1 }}>
                <div style={{ fontSize: 12, fontWeight: 700, color: "#1c1917" }}>Anil Driver</div>
                <div style={{ display: "flex", gap: 3 }}>{[...Array(5)].map((_,i) => <span key={i} style={{ fontSize: 8, color: "#f59e0b" }}>★</span>)}<span style={{ fontSize: 8, color: "#9ca3af", marginLeft: 2 }}>4.9</span></div>
              </div>
              <div style={{ display: "flex", gap: 6 }}>
                {["📞","💬"].map((ic,i) => <div key={i} style={{ width: 32, height: 32, borderRadius: "50%", background: "#f5f3ff", border: "1px solid #ede9fe", display: "flex", alignItems: "center", justifyContent: "center", fontSize: 13 }}>{ic}</div>)}
              </div>
            </div>

            <div style={{ background: "#f5f3ff", borderRadius: 13, padding: "10px 12px", border: "1px solid #ede9fe", textAlign: "center" }}>
              <div style={{ fontSize: 8, color: "#7c3aed", fontWeight: 700, textTransform: "uppercase", letterSpacing: 1 }}>🔐 Your OTP</div>
              <div style={{ fontSize: 28, fontWeight: 900, color: "#7c3aed", letterSpacing: 6, marginTop: 4 }}>7 9 2 3</div>
              <div style={{ fontSize: 7.5, color: "#9ca3af", marginTop: 3 }}>Share this with driver when they arrive</div>
            </div>
          </div>
        </div>
      </div>
    </PhoneFrame>
  );
}

function LightCustomerWallet() {
  return (
    <PhoneFrame bg="white">
      <div style={{ minHeight: 428, background: "white" }}>
        <div style={{ background: "linear-gradient(135deg,#ede9fe,#ddd6fe)", padding: "10px 16px 20px", position: "relative", overflow: "hidden" }}>
          <div style={{ display: "flex", alignItems: "center", gap: 7, marginBottom: 14 }}>
            <JagoLogo size={22} variant="purple" />
            <div style={{ fontSize: 8, color: "#7c3aed", textTransform: "uppercase", fontWeight: 700, letterSpacing: 1 }}>My Wallet</div>
          </div>
          <div style={{ textAlign: "center" }}>
            <div style={{ fontSize: 8, color: "#9ca3af" }}>Available Balance</div>
            <div style={{ fontSize: 30, fontWeight: 900, color: "#7c3aed", lineHeight: 1, marginTop: 4 }}>₹250.00</div>
            <div style={{ fontSize: 8, color: "#9ca3af", marginTop: 3 }}>Total spent: ₹3,200 this month</div>
          </div>
          <div style={{ display: "flex", gap: 8, marginTop: 14 }}>
            <div style={{ flex: 1, background: "white", border: "1.5px solid #ddd6fe", borderRadius: 12, padding: "9px 0", textAlign: "center", fontSize: 10, fontWeight: 700, color: "#7c3aed", boxShadow: "0 2px 8px rgba(124,58,237,0.1)" }}>💳 Add Money</div>
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
            <div key={i} style={{ display: "flex", alignItems: "center", gap: 9, marginBottom: 7, background: "#faf9ff", borderRadius: 12, padding: "9px 11px", border: "1px solid #ede9fe" }}>
              <div style={{ width: 30, height: 30, borderRadius: 9, background: "#ede9fe", display: "flex", alignItems: "center", justifyContent: "center", fontSize: 13 }}>{tx.icon}</div>
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
    { component: <DarkDriverNewTrip />, title: "New Ride Alert", sub: "Accept / Reject with timer" },
    { component: <DarkDriverOnTrip />, title: "On Trip", sub: "Navigation + customer info" },
    { component: <LightDriverWallet />, title: "Wallet", sub: "Balance, earnings & history" },
  ];

  const customerScreensDark = [
    { component: <DarkCustomerSplash />, title: "Splash Screen", sub: "App launch — JAGO branding" },
    { component: <DarkCustomerLogin />, title: "OTP Login", sub: "Phone number verification" },
    { component: <DarkCustomerHome />, title: "Home / Map", sub: "Book a ride" },
    { component: <DarkCustomerTracking />, title: "Live Tracking", sub: "Driver on the way + OTP" },
    { component: <DarkCustomerWallet />, title: "Wallet", sub: "Balance & trip history" },
    { component: <LightCustomerHome />, title: "Light Preview", sub: "Alternate theme" },
  ];

  const customerScreensLight = [
    { component: <LightCustomerSplash />, title: "Splash Screen", sub: "App launch — Light theme" },
    { component: <LightCustomerLogin />, title: "OTP Login", sub: "Phone number verification" },
    { component: <LightCustomerHome />, title: "Home / Map", sub: "Book a ride" },
    { component: <LightCustomerTracking />, title: "Live Tracking", sub: "Driver on the way + OTP" },
    { component: <LightCustomerWallet />, title: "Wallet", sub: "Balance & trip history" },
    { component: <DarkCustomerSplash />, title: "Dark Preview", sub: "Dark theme variant" },
  ];

  const screens = activeApp === "driver"
    ? (themeMode === "dark" ? driverScreensDark : driverScreensLight)
    : (themeMode === "dark" ? customerScreensDark : customerScreensLight);

  const isDriver = activeApp === "driver";
  const accentColor = isDriver ? "#f59e0b" : "#7c3aed";
  const accentGrad = isDriver
    ? "linear-gradient(135deg, #f59e0b, #ef4444)"
    : "linear-gradient(135deg, #7c3aed, #4f46e5)";

  return (
    <div className="p-4" style={{ background: "#f8fafc", minHeight: "100vh" }}>
      {/* ── Header ── */}
      <div className="mb-4" style={{ background: "white", borderRadius: 16, padding: "20px 24px", boxShadow: "0 2px 12px rgba(0,0,0,0.06)", border: "1px solid #f1f5f9" }}>
        <div className="d-flex align-items-center justify-content-between flex-wrap gap-3">
          <div className="d-flex align-items-center gap-3">
            {/* JAGO Logo */}
            <div style={{ width: 52, height: 52, background: accentGrad, borderRadius: 16, display: "flex", alignItems: "center", justifyContent: "center", boxShadow: `0 8px 24px ${accentColor}44`, fontSize: 22 }}>🚗</div>
            <div>
              <div style={{ fontWeight: 900, fontSize: 22, color: "#0f172a", letterSpacing: -0.5 }}>JAGO <span style={{ background: accentGrad, WebkitBackgroundClip: "text", WebkitTextFillColor: "transparent" }}>App Design</span></div>
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
                  background: activeApp === tab ? (tab === "driver" ? "linear-gradient(135deg,#f59e0b,#ef4444)" : "linear-gradient(135deg,#7c3aed,#4f46e5)") : "transparent",
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
            { color: "#0a0a14", name: "Dark BG" },
            { color: "#0f172a", name: "Surface" },
            { color: "#111827", name: "Card" },
            { color: "#f59e0b", name: "Amber" },
            { color: "#ef4444", name: "Red" },
            { color: "#22c55e", name: "Green" },
            { color: "#ffffff", name: "White" },
            { color: "#fff8ed", name: "Light BG" },
          ] : [
            { color: "#0d0b1a", name: "Dark BG" },
            { color: "#13103a", name: "Surface" },
            { color: "#1e1a3a", name: "Card" },
            { color: "#7c3aed", name: "Purple" },
            { color: "#4f46e5", name: "Indigo" },
            { color: "#a78bfa", name: "Violet" },
            { color: "#ede9fe", name: "Light BG" },
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
            <div style={{ background: "#0f172a", borderRadius: 12, padding: "14px 16px", fontFamily: "monospace", fontSize: 10.5, lineHeight: 1.8, color: "#94a3b8" }}>
              <div><span style={{ color: "#f59e0b" }}>dependencies:</span></div>
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
                { token: "Driver Theme", value: "Amber #f59e0b + Dark #0a0a14" },
                { token: "Customer Theme", value: "Purple #7c3aed + Indigo #4f46e5" },
                { token: "Light Mode BG", value: "Driver: #fff8ed · Customer: #ede9fe" },
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
            { env: "Staging", url: "https://staging.jagopro.org", badge: "#f59e0b", badgeBg: "#fef3c7" },
            { env: "Production", url: "https://jagopro.org", badge: "#6d28d9", badgeBg: "#ede9fe" },
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
