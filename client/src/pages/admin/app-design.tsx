import { useState } from "react";

type AppTab = "driver" | "customer";

function PhoneFrame({ children, dark = false }: { children: React.ReactNode; dark?: boolean }) {
  return (
    <div className="d-flex justify-content-center">
      <div style={{
        width: 220,
        minHeight: 440,
        background: dark ? "#0f0f1a" : "#f8fafc",
        borderRadius: 36,
        border: "6px solid #1e293b",
        boxShadow: "0 40px 80px rgba(0,0,0,0.45), inset 0 0 0 1px rgba(255,255,255,0.06)",
        overflow: "hidden",
        position: "relative",
        flexShrink: 0,
      }}>
        {/* Notch */}
        <div style={{
          position: "absolute", top: 0, left: "50%", transform: "translateX(-50%)",
          width: 80, height: 22, background: "#0f0f1a",
          borderRadius: "0 0 16px 16px", zIndex: 10,
        }} />
        <div style={{ paddingTop: 24, height: "100%" }}>{children}</div>
      </div>
    </div>
  );
}

function ScreenLabel({ title, sub }: { title: string; sub: string }) {
  return (
    <div className="text-center mt-3">
      <div className="fw-semibold" style={{ fontSize: 12.5, color: "#1e293b" }}>{title}</div>
      <div style={{ fontSize: 10.5, color: "#94a3b8" }}>{sub}</div>
    </div>
  );
}

// ── DRIVER APP SCREENS ────────────────────────────────────────────────────────

function DriverSplash() {
  return (
    <PhoneFrame dark>
      <div style={{
        height: "100%", minHeight: 416,
        background: "linear-gradient(160deg, #0f0f1a 0%, #1a1040 50%, #0d2137 100%)",
        display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center",
        padding: "0 20px", gap: 12,
      }}>
        <div style={{
          width: 70, height: 70,
          background: "linear-gradient(135deg, #f59e0b, #ef4444)",
          borderRadius: 20,
          display: "flex", alignItems: "center", justifyContent: "center",
          boxShadow: "0 10px 30px rgba(245,158,11,0.4)",
          fontSize: 30,
        }}>🚗</div>
        <div style={{ fontWeight: 800, fontSize: 22, color: "white", letterSpacing: -0.5 }}>JAGO</div>
        <div style={{ fontSize: 10, color: "#64748b", textTransform: "uppercase", letterSpacing: 2 }}>Driver Partner</div>
        <div style={{ marginTop: 30, width: 40, height: 3, background: "linear-gradient(90deg,#f59e0b,#ef4444)", borderRadius: 2 }} />
      </div>
    </PhoneFrame>
  );
}

function DriverOtp() {
  return (
    <PhoneFrame dark>
      <div style={{
        minHeight: 416, background: "linear-gradient(180deg, #0f0f1a 0%, #111827 100%)",
        padding: "30px 18px 18px",
      }}>
        <div style={{ color: "#f59e0b", fontSize: 11, fontWeight: 700, letterSpacing: 1, textTransform: "uppercase" }}>JAGO DRIVER</div>
        <div style={{ color: "white", fontSize: 18, fontWeight: 800, marginTop: 8, lineHeight: 1.2 }}>Welcome<br />Back 👋</div>
        <div style={{ color: "#64748b", fontSize: 10, marginTop: 6 }}>Login తో ride earning start చేయండి</div>

        <div style={{ marginTop: 24 }}>
          <div style={{ fontSize: 9, color: "#94a3b8", textTransform: "uppercase", fontWeight: 600, marginBottom: 4 }}>Phone Number</div>
          <div style={{
            background: "#1e293b", borderRadius: 12, padding: "10px 12px",
            display: "flex", alignItems: "center", gap: 8,
            border: "1.5px solid #f59e0b33",
          }}>
            <span style={{ fontSize: 10, color: "#f59e0b", fontWeight: 700 }}>+91</span>
            <span style={{ fontSize: 11, color: "#64748b" }}>9876543210</span>
          </div>

          <div style={{ marginTop: 12 }}>
            <div style={{ fontSize: 9, color: "#94a3b8", textTransform: "uppercase", fontWeight: 600, marginBottom: 4 }}>Enter OTP</div>
            <div style={{ display: "flex", gap: 6 }}>
              {["5","•","•","•"].map((d, i) => (
                <div key={i} style={{
                  flex: 1, background: d === "5" ? "#1a1040" : "#1e293b",
                  border: `1.5px solid ${d === "5" ? "#f59e0b" : "#334155"}`,
                  borderRadius: 10, padding: "8px 0", textAlign: "center",
                  color: "white", fontSize: 14, fontWeight: 700,
                }}>{d}</div>
              ))}
            </div>
          </div>

          <div style={{
            marginTop: 20, background: "linear-gradient(135deg,#f59e0b,#ef4444)",
            borderRadius: 12, padding: "11px 0", textAlign: "center",
            color: "white", fontSize: 12, fontWeight: 700,
            boxShadow: "0 8px 20px rgba(245,158,11,0.35)",
          }}>Verify & Login →</div>

          <div style={{ textAlign: "center", marginTop: 10, fontSize: 9, color: "#475569" }}>OTP resend in 28s</div>
        </div>
      </div>
    </PhoneFrame>
  );
}

function DriverHome() {
  return (
    <PhoneFrame dark>
      <div style={{ minHeight: 416, background: "#0f0f1a", position: "relative", overflow: "hidden" }}>
        {/* Map background */}
        <div style={{
          position: "absolute", inset: 0,
          background: "radial-gradient(ellipse at 50% 60%, #0d2137 0%, #0f0f1a 70%)",
        }}>
          {/* Fake map grid */}
          {[...Array(8)].map((_, i) => (
            <div key={i} style={{
              position: "absolute", left: 0, right: 0, top: `${12 * i}%`,
              height: 1, background: "rgba(255,255,255,0.04)",
            }} />
          ))}
          {[...Array(6)].map((_, i) => (
            <div key={i} style={{
              position: "absolute", top: 0, bottom: 0, left: `${16 * i}%`,
              width: 1, background: "rgba(255,255,255,0.04)",
            }} />
          ))}
          {/* Road */}
          <div style={{ position: "absolute", left: "30%", top: "25%", width: "40%", height: "50%",
            border: "2px solid rgba(245,158,11,0.15)", borderRadius: 4 }} />
          {/* Car marker */}
          <div style={{ position: "absolute", top: "48%", left: "44%",
            width: 20, height: 20, background: "#f59e0b", borderRadius: "50%",
            display: "flex", alignItems: "center", justifyContent: "center",
            boxShadow: "0 0 0 6px rgba(245,158,11,0.2)", fontSize: 10,
          }}>🚗</div>
        </div>

        {/* Top bar */}
        <div style={{ position: "relative", zIndex: 2, padding: "8px 14px 0" }}>
          <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
            <div>
              <div style={{ fontSize: 8, color: "#64748b" }}>Good Morning</div>
              <div style={{ fontSize: 13, fontWeight: 800, color: "white" }}>Anil Driver 👋</div>
            </div>
            <div style={{ width: 30, height: 30, borderRadius: "50%", background: "linear-gradient(135deg,#f59e0b,#ef4444)", display: "flex", alignItems: "center", justifyContent: "center", fontSize: 12 }}>A</div>
          </div>

          {/* Stats row */}
          <div style={{ display: "flex", gap: 6, marginTop: 10 }}>
            {[{l:"Today",v:"₹1,240",c:"#86efac"},{l:"Trips",v:"8",c:"#60a5fa"},{l:"Rating",v:"4.9★",c:"#f59e0b"}].map((s,i) => (
              <div key={i} style={{ flex: 1, background: "rgba(255,255,255,0.06)", borderRadius: 10, padding: "6px 8px", backdropFilter: "blur(10px)" }}>
                <div style={{ fontSize: 7.5, color: "#64748b" }}>{s.l}</div>
                <div style={{ fontSize: 11, fontWeight: 700, color: s.c }}>{s.v}</div>
              </div>
            ))}
          </div>
        </div>

        {/* Bottom card */}
        <div style={{
          position: "absolute", bottom: 0, left: 0, right: 0,
          background: "linear-gradient(180deg, rgba(15,15,26,0) 0%, #0f0f1a 30%)",
          padding: "30px 14px 14px",
        }}>
          {/* Online toggle */}
          <div style={{
            background: "#111827", borderRadius: 16, padding: "14px 16px",
            border: "1px solid rgba(255,255,255,0.08)",
            backdropFilter: "blur(20px)",
          }}>
            <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
              <div>
                <div style={{ fontSize: 12, fontWeight: 700, color: "white" }}>You're ONLINE</div>
                <div style={{ fontSize: 9, color: "#22c55e", marginTop: 2 }}>● Looking for rides...</div>
              </div>
              <div style={{
                width: 44, height: 24, background: "linear-gradient(135deg,#22c55e,#16a34a)",
                borderRadius: 12, position: "relative", boxShadow: "0 4px 12px rgba(34,197,94,0.4)",
              }}>
                <div style={{ position: "absolute", right: 3, top: 3, width: 18, height: 18, background: "white", borderRadius: "50%" }} />
              </div>
            </div>
            <div style={{ height: 1, background: "rgba(255,255,255,0.06)", margin: "10px 0" }} />
            <div style={{ display: "flex", gap: 8 }}>
              {["Wallet: ₹240","History","Settings"].map((btn,i) => (
                <div key={i} style={{
                  flex: 1, background: "rgba(255,255,255,0.05)", borderRadius: 8,
                  padding: "5px 0", textAlign: "center", fontSize: 8, color: "#94a3b8",
                }}>{btn}</div>
              ))}
            </div>
          </div>
        </div>
      </div>
    </PhoneFrame>
  );
}

function DriverNewTrip() {
  return (
    <PhoneFrame dark>
      <div style={{ minHeight: 416, background: "#0f0f1a", position: "relative", overflow: "hidden" }}>
        {/* Dim map background */}
        <div style={{ position: "absolute", inset: 0, background: "rgba(0,0,0,0.6)", zIndex: 1 }} />

        {/* Pulsing alert ring */}
        <div style={{
          position: "absolute", top: "22%", left: "50%", transform: "translate(-50%,-50%)",
          width: 80, height: 80, borderRadius: "50%",
          border: "2px solid rgba(245,158,11,0.3)",
          animation: "pulse 1.5s infinite", zIndex: 2,
        }} />
        <div style={{
          position: "absolute", top: "22%", left: "50%", transform: "translate(-50%,-50%)",
          width: 56, height: 56, borderRadius: "50%",
          background: "linear-gradient(135deg,#f59e0b,#ef4444)",
          display: "flex", alignItems: "center", justifyContent: "center",
          boxShadow: "0 0 30px rgba(245,158,11,0.6)", zIndex: 3, fontSize: 22,
        }}>🔔</div>

        {/* Trip alert sheet */}
        <div style={{
          position: "absolute", bottom: 0, left: 0, right: 0, zIndex: 4,
          background: "#111827",
          borderRadius: "24px 24px 0 0",
          padding: "16px 16px 14px",
          border: "1px solid rgba(245,158,11,0.2)",
          boxShadow: "0 -20px 60px rgba(245,158,11,0.15)",
        }}>
          <div style={{ textAlign: "center", marginBottom: 12 }}>
            <div style={{ fontSize: 10, color: "#f59e0b", fontWeight: 700, textTransform: "uppercase", letterSpacing: 1 }}>🔔 New Ride Request!</div>
            <div style={{ fontSize: 8, color: "#475569", marginTop: 2 }}>Auto-reject in 28s</div>
            {/* Timer bar */}
            <div style={{ height: 3, background: "#1e293b", borderRadius: 2, marginTop: 6, overflow: "hidden" }}>
              <div style={{ width: "70%", height: "100%", background: "linear-gradient(90deg,#22c55e,#f59e0b)", borderRadius: 2 }} />
            </div>
          </div>

          <div style={{ background: "#0f0f1a", borderRadius: 12, padding: "10px 12px", marginBottom: 10 }}>
            <div style={{ display: "flex", justifyContent: "space-between", marginBottom: 8 }}>
              <div style={{ fontSize: 13, fontWeight: 800, color: "white" }}>Arjun Reddy</div>
              <div style={{ background: "rgba(245,158,11,0.15)", borderRadius: 8, padding: "2px 8px", fontSize: 12, color: "#f59e0b", fontWeight: 700 }}>₹185</div>
            </div>
            {[
              { icon: "🟢", label: "MGBS Bus Stand, Hyderabad", color: "#22c55e" },
              { icon: "🔴", label: "Banjara Hills Road No.12", color: "#ef4444" },
            ].map((loc, i) => (
              <div key={i} style={{ display: "flex", gap: 6, alignItems: "flex-start", marginTop: i === 0 ? 0 : 6 }}>
                <span style={{ fontSize: 8, marginTop: 2 }}>{loc.icon}</span>
                <span style={{ fontSize: 9, color: "#94a3b8" }}>{loc.label}</span>
              </div>
            ))}
            <div style={{ display: "flex", gap: 10, marginTop: 8 }}>
              <span style={{ fontSize: 8.5, color: "#60a5fa" }}>📍 2.4 km away</span>
              <span style={{ fontSize: 8.5, color: "#a78bfa" }}>⏱ ~8 min to pickup</span>
            </div>
          </div>

          <div style={{ display: "flex", gap: 8 }}>
            <div style={{
              flex: 1, background: "#1e293b", borderRadius: 12,
              padding: "10px 0", textAlign: "center",
              fontSize: 11, fontWeight: 600, color: "#64748b",
            }}>Reject</div>
            <div style={{
              flex: 2, background: "linear-gradient(135deg,#22c55e,#16a34a)",
              borderRadius: 12, padding: "10px 0", textAlign: "center",
              fontSize: 11, fontWeight: 700, color: "white",
              boxShadow: "0 6px 16px rgba(34,197,94,0.4)",
            }}>✓ Accept Ride</div>
          </div>
        </div>
      </div>
    </PhoneFrame>
  );
}

function DriverOnTrip() {
  return (
    <PhoneFrame dark>
      <div style={{ minHeight: 416, background: "#0f0f1a", position: "relative", overflow: "hidden" }}>
        {/* Map */}
        <div style={{ position: "absolute", inset: 0, background: "radial-gradient(ellipse at 50% 40%, #0d2137 0%, #0f0f1a 80%)" }}>
          {/* Route line */}
          <div style={{ position: "absolute", left: "35%", top: "20%", width: 2, height: "60%",
            background: "linear-gradient(180deg,#22c55e,#f59e0b)", borderRadius: 2 }} />
          <div style={{ position: "absolute", top: "20%", left: "33%", width: 8, height: 8,
            background: "#22c55e", borderRadius: "50%", boxShadow: "0 0 12px #22c55e" }} />
          <div style={{ position: "absolute", top: "55%", left: "33%",
            width: 22, height: 22, background: "#f59e0b", borderRadius: "50%",
            display: "flex", alignItems: "center", justifyContent: "center",
            boxShadow: "0 0 0 5px rgba(245,158,11,0.2)", fontSize: 11,
          }}>🚗</div>
          <div style={{ position: "absolute", top: "80%", left: "33%", width: 8, height: 8,
            background: "#ef4444", borderRadius: "50%", boxShadow: "0 0 12px #ef4444" }} />
        </div>

        {/* Top nav bar */}
        <div style={{ position: "relative", zIndex: 2, background: "rgba(17,24,39,0.95)", padding: "8px 14px", backdropFilter: "blur(10px)" }}>
          <div style={{ fontSize: 8, color: "#64748b" }}>ON THE WAY TO DESTINATION</div>
          <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginTop: 2 }}>
            <div style={{ fontSize: 12, fontWeight: 700, color: "white" }}>Banjara Hills Rd 12</div>
            <div style={{ fontSize: 11, color: "#22c55e", fontWeight: 700 }}>12 min</div>
          </div>
        </div>

        {/* Bottom sheet */}
        <div style={{
          position: "absolute", bottom: 0, left: 0, right: 0, zIndex: 3,
          background: "#111827", borderRadius: "20px 20px 0 0",
          padding: "12px 14px 14px",
          border: "1px solid rgba(255,255,255,0.06)",
        }}>
          <div style={{ display: "flex", gap: 10, alignItems: "center", marginBottom: 10 }}>
            <div style={{ width: 36, height: 36, borderRadius: "50%",
              background: "linear-gradient(135deg,#7c3aed,#a78bfa)",
              display: "flex", alignItems: "center", justifyContent: "center",
              fontSize: 16, fontWeight: 700, color: "white",
            }}>A</div>
            <div>
              <div style={{ fontSize: 12, fontWeight: 700, color: "white" }}>Arjun Reddy</div>
              <div style={{ display: "flex", gap: 4 }}>
                {[...Array(5)].map((_,i) => <span key={i} style={{ fontSize: 8, color: "#f59e0b" }}>★</span>)}
                <span style={{ fontSize: 8, color: "#64748b" }}>4.9</span>
              </div>
            </div>
            <div style={{ marginLeft: "auto", display: "flex", gap: 6 }}>
              <div style={{ width: 30, height: 30, borderRadius: "50%", background: "#1e293b",
                display: "flex", alignItems: "center", justifyContent: "center", fontSize: 12 }}>📞</div>
              <div style={{ width: 30, height: 30, borderRadius: "50%", background: "#1e293b",
                display: "flex", alignItems: "center", justifyContent: "center", fontSize: 12 }}>💬</div>
            </div>
          </div>

          <div style={{ display: "flex", gap: 6, marginBottom: 10 }}>
            {[{l:"Distance",v:"7.2 km"},{l:"Duration",v:"12 min"},{l:"Fare",v:"₹185"}].map((s,i) => (
              <div key={i} style={{ flex: 1, background: "#0f0f1a", borderRadius: 8, padding: "6px 0", textAlign: "center" }}>
                <div style={{ fontSize: 7.5, color: "#475569" }}>{s.l}</div>
                <div style={{ fontSize: 10.5, fontWeight: 700, color: "white" }}>{s.v}</div>
              </div>
            ))}
          </div>

          <div style={{
            background: "linear-gradient(135deg,#16a34a,#15803d)",
            borderRadius: 12, padding: "10px 0", textAlign: "center",
            fontSize: 11, fontWeight: 700, color: "white",
            boxShadow: "0 6px 16px rgba(22,163,74,0.4)",
          }}>🏁 Complete Trip</div>
        </div>
      </div>
    </PhoneFrame>
  );
}

function DriverWallet() {
  return (
    <PhoneFrame dark>
      <div style={{ minHeight: 416, background: "#0f0f1a" }}>
        {/* Header */}
        <div style={{ background: "linear-gradient(135deg,#1a1040,#0d2137)", padding: "10px 16px 20px" }}>
          <div style={{ fontSize: 9, color: "#64748b", textTransform: "uppercase", fontWeight: 600 }}>Driver Wallet</div>
          <div style={{ marginTop: 12, textAlign: "center" }}>
            <div style={{ fontSize: 8, color: "#64748b" }}>Current Balance</div>
            <div style={{ fontSize: 28, fontWeight: 900, color: "#22c55e", lineHeight: 1, marginTop: 4 }}>₹1,240</div>
            <div style={{ fontSize: 8, color: "#64748b", marginTop: 2 }}>This month earning: ₹8,400</div>
          </div>
          <div style={{ display: "flex", gap: 8, marginTop: 14 }}>
            <div style={{
              flex: 1, background: "rgba(34,197,94,0.15)", border: "1px solid rgba(34,197,94,0.3)",
              borderRadius: 10, padding: "8px 0", textAlign: "center",
              fontSize: 10, fontWeight: 700, color: "#22c55e",
            }}>📥 Cash In</div>
            <div style={{
              flex: 1, background: "rgba(96,165,250,0.15)", border: "1px solid rgba(96,165,250,0.3)",
              borderRadius: 10, padding: "8px 0", textAlign: "center",
              fontSize: 10, fontWeight: 700, color: "#60a5fa",
            }}>📤 Withdraw</div>
          </div>
        </div>

        {/* Transactions */}
        <div style={{ padding: "12px 14px" }}>
          <div style={{ fontSize: 9, color: "#64748b", textTransform: "uppercase", fontWeight: 600, marginBottom: 8 }}>Recent</div>
          {[
            { icon: "🚗", label: "Trip Commission", sub: "TRP97842 • Today", amt: "-₹27.50", c: "#f87171" },
            { icon: "⭐", label: "Bonus Earned", sub: "Peak hour • Yesterday", amt: "+₹50", c: "#86efac" },
            { icon: "🚗", label: "Trip Commission", sub: "TRP97801 • Yesterday", amt: "-₹18.20", c: "#f87171" },
            { icon: "💰", label: "Wallet Credit", sub: "Admin • 3 days ago", amt: "+₹500", c: "#86efac" },
          ].map((tx, i) => (
            <div key={i} style={{
              display: "flex", alignItems: "center", gap: 8, marginBottom: 8,
              background: "#111827", borderRadius: 10, padding: "8px 10px",
            }}>
              <div style={{ width: 28, height: 28, borderRadius: 8, background: "#1e293b",
                display: "flex", alignItems: "center", justifyContent: "center", fontSize: 12,
              }}>{tx.icon}</div>
              <div style={{ flex: 1 }}>
                <div style={{ fontSize: 10, fontWeight: 600, color: "white" }}>{tx.label}</div>
                <div style={{ fontSize: 8, color: "#475569" }}>{tx.sub}</div>
              </div>
              <div style={{ fontSize: 11, fontWeight: 700, color: tx.c }}>{tx.amt}</div>
            </div>
          ))}
        </div>
      </div>
    </PhoneFrame>
  );
}

// ── CUSTOMER APP SCREENS ──────────────────────────────────────────────────────

function CustomerSplash() {
  return (
    <PhoneFrame>
      <div style={{
        minHeight: 416, background: "linear-gradient(160deg, #6d28d9 0%, #4f46e5 50%, #1a73e8 100%)",
        display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center",
        padding: "0 20px", gap: 12,
      }}>
        <div style={{
          width: 70, height: 70,
          background: "white",
          borderRadius: 20,
          display: "flex", alignItems: "center", justifyContent: "center",
          boxShadow: "0 20px 40px rgba(0,0,0,0.2)",
          fontSize: 30,
        }}>🚖</div>
        <div style={{ fontWeight: 800, fontSize: 22, color: "white", letterSpacing: -0.5 }}>JAGO</div>
        <div style={{ fontSize: 10, color: "rgba(255,255,255,0.6)", textTransform: "uppercase", letterSpacing: 2 }}>Ride Anywhere</div>
        <div style={{ marginTop: 30, width: 40, height: 3, background: "rgba(255,255,255,0.4)", borderRadius: 2 }} />
      </div>
    </PhoneFrame>
  );
}

function CustomerOtp() {
  return (
    <PhoneFrame>
      <div style={{ minHeight: 416, background: "white", padding: "30px 18px 18px" }}>
        {/* Top gradient strip */}
        <div style={{ height: 3, background: "linear-gradient(90deg,#6d28d9,#1a73e8)", borderRadius: 2, marginBottom: 20 }} />

        <div style={{ fontSize: 9, color: "#6d28d9", fontWeight: 700, letterSpacing: 1, textTransform: "uppercase" }}>JAGO CUSTOMER</div>
        <div style={{ fontSize: 18, fontWeight: 800, color: "#0f172a", marginTop: 6, lineHeight: 1.2 }}>Enter OTP 📱</div>
        <div style={{ fontSize: 10, color: "#94a3b8", marginTop: 4 }}>Sent to +91 9876543210</div>

        <div style={{ marginTop: 24 }}>
          {/* OTP boxes */}
          <div style={{ display: "flex", gap: 8, justifyContent: "center", marginBottom: 20 }}>
            {["8","4","2","3"].map((d, i) => (
              <div key={i} style={{
                width: 40, height: 46,
                background: i === 3 ? "white" : "#f8fafc",
                border: `2px solid ${i === 3 ? "#6d28d9" : i < 3 ? "#e2e8f0" : "#e2e8f0"}`,
                borderRadius: 12,
                display: "flex", alignItems: "center", justifyContent: "center",
                fontSize: 18, fontWeight: 800,
                color: i < 3 ? "#0f172a" : "#6d28d9",
                boxShadow: i === 3 ? "0 0 0 3px rgba(109,40,217,0.15)" : "none",
              }}>{d}</div>
            ))}
          </div>

          <div style={{
            background: "linear-gradient(135deg,#6d28d9,#4f46e5)",
            borderRadius: 14, padding: "12px 0", textAlign: "center",
            color: "white", fontSize: 12, fontWeight: 700,
            boxShadow: "0 8px 20px rgba(109,40,217,0.35)",
          }}>Verify & Continue →</div>

          <div style={{ textAlign: "center", marginTop: 12, fontSize: 9, color: "#94a3b8" }}>
            Didn't receive? <span style={{ color: "#6d28d9", fontWeight: 600 }}>Resend OTP</span>
          </div>

          <div style={{ marginTop: 20, padding: "10px 12px", background: "#f8fafc", borderRadius: 10, display: "flex", gap: 8, alignItems: "center" }}>
            <span style={{ fontSize: 14 }}>🔒</span>
            <span style={{ fontSize: 8.5, color: "#64748b" }}>Your number is secure. We never share data.</span>
          </div>
        </div>
      </div>
    </PhoneFrame>
  );
}

function CustomerHome() {
  return (
    <PhoneFrame>
      <div style={{ minHeight: 416, background: "#f1f5f9", position: "relative", overflow: "hidden" }}>
        {/* Map */}
        <div style={{
          position: "absolute", inset: 0,
          background: "linear-gradient(160deg, #dbeafe 0%, #e0e7ff 60%, #f1f5f9 100%)",
        }}>
          {[...Array(8)].map((_, i) => (
            <div key={i} style={{
              position: "absolute", left: 0, right: 0, top: `${12 * i}%`,
              height: 1, background: "rgba(100,116,139,0.1)",
            }} />
          ))}
          {[...Array(6)].map((_, i) => (
            <div key={i} style={{
              position: "absolute", top: 0, bottom: 0, left: `${16 * i}%`,
              width: 1, background: "rgba(100,116,139,0.1)",
            }} />
          ))}
          {/* Nearby car icons */}
          {[{t:"35%",l:"25%"},{t:"45%",l:"60%"},{t:"60%",l:"40%"}].map((p,i) => (
            <div key={i} style={{ position: "absolute", top: p.t, left: p.l,
              fontSize: 14, filter: "drop-shadow(0 2px 4px rgba(0,0,0,0.2))" }}>🚗</div>
          ))}
          {/* Location pin */}
          <div style={{ position: "absolute", top: "48%", left: "48%",
            display: "flex", flexDirection: "column", alignItems: "center" }}>
            <div style={{ width: 14, height: 14, background: "#6d28d9", borderRadius: "50%",
              border: "3px solid white", boxShadow: "0 4px 12px rgba(109,40,217,0.4)" }} />
            <div style={{ width: 2, height: 6, background: "#6d28d9" }} />
          </div>
        </div>

        {/* Top */}
        <div style={{ position: "relative", zIndex: 2, padding: "8px 14px" }}>
          <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
            <div>
              <div style={{ fontSize: 8, color: "#64748b" }}>Hello,</div>
              <div style={{ fontSize: 13, fontWeight: 800, color: "#0f172a" }}>Arjun Reddy 🙌</div>
            </div>
            <div style={{
              padding: "4px 8px", background: "rgba(255,255,255,0.9)",
              borderRadius: 20, fontSize: 9, fontWeight: 600, color: "#6d28d9",
              boxShadow: "0 2px 8px rgba(0,0,0,0.1)",
            }}>💰 ₹250</div>
          </div>
        </div>

        {/* Bottom booking card */}
        <div style={{
          position: "absolute", bottom: 0, left: 0, right: 0, zIndex: 3,
          background: "white", borderRadius: "24px 24px 0 0",
          padding: "16px 14px 14px",
          boxShadow: "0 -8px 40px rgba(0,0,0,0.12)",
        }}>
          {/* Search bar */}
          <div style={{
            background: "#f8fafc", borderRadius: 12, padding: "10px 12px",
            display: "flex", alignItems: "center", gap: 8, marginBottom: 12,
            border: "1.5px solid #e2e8f0",
          }}>
            <span style={{ fontSize: 12 }}>🔍</span>
            <span style={{ fontSize: 10, color: "#94a3b8" }}>Where do you want to go?</span>
          </div>

          {/* Quick destinations */}
          <div style={{ fontSize: 8.5, color: "#64748b", fontWeight: 600, marginBottom: 8 }}>RECENT PLACES</div>
          {[
            { icon: "🏠", label: "Home", sub: "Jubilee Hills, Hyd" },
            { icon: "💼", label: "Office", sub: "Hitech City, Hyd" },
          ].map((p,i) => (
            <div key={i} style={{
              display: "flex", gap: 10, alignItems: "center", marginBottom: 8,
              padding: "8px 10px", background: "#f8fafc", borderRadius: 10,
            }}>
              <div style={{ width: 28, height: 28, borderRadius: 8, background: "white",
                display: "flex", alignItems: "center", justifyContent: "center", fontSize: 13,
                boxShadow: "0 2px 6px rgba(0,0,0,0.08)",
              }}>{p.icon}</div>
              <div>
                <div style={{ fontSize: 10.5, fontWeight: 600, color: "#0f172a" }}>{p.label}</div>
                <div style={{ fontSize: 8.5, color: "#94a3b8" }}>{p.sub}</div>
              </div>
              <span style={{ marginLeft: "auto", fontSize: 10, color: "#cbd5e1" }}>›</span>
            </div>
          ))}
        </div>
      </div>
    </PhoneFrame>
  );
}

function CustomerFareSelect() {
  return (
    <PhoneFrame>
      <div style={{ minHeight: 416, background: "#f8fafc" }}>
        {/* Top */}
        <div style={{ background: "white", padding: "10px 14px 14px", boxShadow: "0 2px 12px rgba(0,0,0,0.06)" }}>
          <div style={{ fontSize: 9, color: "#6d28d9", fontWeight: 700, textTransform: "uppercase", letterSpacing: 1 }}>Select Ride</div>
          <div style={{ fontSize: 11, fontWeight: 600, color: "#0f172a", marginTop: 2 }}>MGBS → Banjara Hills</div>
          <div style={{ display: "flex", gap: 8, marginTop: 6 }}>
            <span style={{ fontSize: 8.5, color: "#64748b" }}>📍 7.2 km</span>
            <span style={{ fontSize: 8.5, color: "#64748b" }}>⏱ ~18 min</span>
          </div>
        </div>

        <div style={{ padding: "10px 14px" }}>
          {[
            { icon: "🚗", name: "Car", cap: "1-4 passengers", fare: "₹165", time: "3 min", sel: false },
            { icon: "🛺", name: "Auto", cap: "1-3 passengers", fare: "₹95", time: "2 min", sel: true },
            { icon: "🏍", name: "Bike", cap: "1 passenger", fare: "₹65", time: "1 min", sel: false },
          ].map((v,i) => (
            <div key={i} style={{
              display: "flex", alignItems: "center", gap: 10, marginBottom: 8,
              background: "white",
              border: `2px solid ${v.sel ? "#6d28d9" : "#f1f5f9"}`,
              borderRadius: 14, padding: "10px 12px",
              boxShadow: v.sel ? "0 4px 16px rgba(109,40,217,0.15)" : "0 1px 4px rgba(0,0,0,0.04)",
            }}>
              <div style={{ fontSize: 22 }}>{v.icon}</div>
              <div style={{ flex: 1 }}>
                <div style={{ fontSize: 11, fontWeight: 700, color: "#0f172a" }}>{v.name}</div>
                <div style={{ fontSize: 8.5, color: "#94a3b8" }}>{v.cap}</div>
              </div>
              <div style={{ textAlign: "right" }}>
                <div style={{ fontSize: 12, fontWeight: 800, color: v.sel ? "#6d28d9" : "#0f172a" }}>{v.fare}</div>
                <div style={{ fontSize: 8, color: "#94a3b8" }}>{v.time} away</div>
              </div>
            </div>
          ))}

          {/* Payment */}
          <div style={{
            background: "white", borderRadius: 12, padding: "8px 12px",
            display: "flex", alignItems: "center", gap: 8, marginBottom: 12,
            border: "1px solid #f1f5f9",
          }}>
            <span style={{ fontSize: 12 }}>💵</span>
            <span style={{ fontSize: 10, color: "#0f172a", fontWeight: 600 }}>Cash</span>
            <span style={{ marginLeft: "auto", fontSize: 9, color: "#6d28d9", fontWeight: 600 }}>Change ›</span>
          </div>

          <div style={{
            background: "linear-gradient(135deg,#6d28d9,#4f46e5)",
            borderRadius: 14, padding: "12px 0", textAlign: "center",
            color: "white", fontSize: 12, fontWeight: 700,
            boxShadow: "0 8px 20px rgba(109,40,217,0.35)",
          }}>Book Auto — ₹95 →</div>
        </div>
      </div>
    </PhoneFrame>
  );
}

function CustomerTracking() {
  return (
    <PhoneFrame>
      <div style={{ minHeight: 416, background: "#f1f5f9", position: "relative", overflow: "hidden" }}>
        {/* Map */}
        <div style={{
          position: "absolute", inset: 0,
          background: "linear-gradient(160deg,#dbeafe 0%,#e0e7ff 70%,#f1f5f9 100%)",
        }}>
          {/* Route */}
          <div style={{ position: "absolute", left: "42%", top: "18%", width: 3, height: "55%",
            background: "linear-gradient(180deg,#6d28d9,#f59e0b)", borderRadius: 2 }} />
          <div style={{ position: "absolute", top: "18%", left: "40%", width: 10, height: 10,
            background: "#6d28d9", borderRadius: "50%", boxShadow: "0 0 12px #6d28d9" }} />
          <div style={{ position: "absolute", top: "47%", left: "38%",
            width: 26, height: 26, background: "#f59e0b", borderRadius: "50%",
            display: "flex", alignItems: "center", justifyContent: "center",
            boxShadow: "0 0 0 6px rgba(245,158,11,0.2)", fontSize: 13,
          }}>🛺</div>
          <div style={{ position: "absolute", top: "73%", left: "40%", width: 10, height: 10,
            background: "#ef4444", borderRadius: "50%", boxShadow: "0 0 12px #ef4444" }} />
        </div>

        {/* Top pill */}
        <div style={{ position: "relative", zIndex: 2, padding: "8px 14px" }}>
          <div style={{
            background: "rgba(255,255,255,0.95)", borderRadius: 20, padding: "6px 14px",
            display: "inline-flex", alignItems: "center", gap: 6,
            boxShadow: "0 4px 16px rgba(0,0,0,0.1)",
          }}>
            <div style={{ width: 8, height: 8, background: "#f59e0b", borderRadius: "50%",
              boxShadow: "0 0 0 3px rgba(245,158,11,0.3)" }} />
            <span style={{ fontSize: 9, fontWeight: 700, color: "#0f172a" }}>Driver is on the way</span>
          </div>
        </div>

        {/* Bottom driver card */}
        <div style={{
          position: "absolute", bottom: 0, left: 0, right: 0, zIndex: 3,
          background: "white", borderRadius: "24px 24px 0 0",
          padding: "14px 14px 14px",
          boxShadow: "0 -8px 40px rgba(0,0,0,0.12)",
        }}>
          <div style={{ display: "flex", alignItems: "center", gap: 10, marginBottom: 10 }}>
            <div style={{ width: 42, height: 42, borderRadius: "50%",
              background: "linear-gradient(135deg,#f59e0b,#ef4444)",
              display: "flex", alignItems: "center", justifyContent: "center",
              fontSize: 18, fontWeight: 700, color: "white",
            }}>A</div>
            <div style={{ flex: 1 }}>
              <div style={{ fontSize: 12, fontWeight: 700, color: "#0f172a" }}>Anil Kumar</div>
              <div style={{ fontSize: 8.5, color: "#64748b" }}>KA 05 MN 2847 • Auto 🛺</div>
              <div style={{ display: "flex", gap: 2 }}>
                {[...Array(5)].map((_,i) => <span key={i} style={{ fontSize: 8, color: "#f59e0b" }}>★</span>)}
                <span style={{ fontSize: 8, color: "#94a3b8" }}>4.8</span>
              </div>
            </div>
            <div style={{ display: "flex", gap: 6 }}>
              <div style={{ width: 32, height: 32, borderRadius: "50%", background: "#f0fdf4",
                display: "flex", alignItems: "center", justifyContent: "center", fontSize: 14 }}>📞</div>
              <div style={{ width: 32, height: 32, borderRadius: "50%", background: "#f0f4ff",
                display: "flex", alignItems: "center", justifyContent: "center", fontSize: 14 }}>💬</div>
            </div>
          </div>

          {/* ETA bar */}
          <div style={{
            background: "linear-gradient(135deg,#6d28d9,#4f46e5)",
            borderRadius: 10, padding: "8px 12px",
            display: "flex", justifyContent: "space-between", alignItems: "center",
          }}>
            <div style={{ fontSize: 9, color: "rgba(255,255,255,0.7)" }}>Arriving in</div>
            <div style={{ fontSize: 16, fontWeight: 900, color: "white" }}>4 min</div>
            <div style={{ fontSize: 9, color: "rgba(255,255,255,0.7)" }}>0.8 km away</div>
          </div>

          <div style={{
            marginTop: 8, background: "#fef9f0", border: "1px solid #fde68a",
            borderRadius: 10, padding: "6px 10px", textAlign: "center",
            fontSize: 9, color: "#92400e",
          }}>⚠️ Cancel trip only before driver arrives</div>
        </div>
      </div>
    </PhoneFrame>
  );
}

function CustomerRating() {
  const [rating, setRating] = useState(5);
  return (
    <PhoneFrame>
      <div style={{ minHeight: 416, background: "white" }}>
        {/* Top gradient */}
        <div style={{
          height: 120, background: "linear-gradient(135deg,#6d28d9,#4f46e5)",
          display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "flex-end",
          padding: "0 20px 16px",
        }}>
          <div style={{ width: 56, height: 56, borderRadius: "50%",
            background: "linear-gradient(135deg,#f59e0b,#ef4444)",
            display: "flex", alignItems: "center", justifyContent: "center",
            fontSize: 24, fontWeight: 700, color: "white",
            border: "3px solid white",
            boxShadow: "0 8px 20px rgba(0,0,0,0.2)",
            marginBottom: -28,
          }}>A</div>
        </div>

        <div style={{ paddingTop: 36, padding: "36px 18px 16px", textAlign: "center" }}>
          <div style={{ fontSize: 13, fontWeight: 800, color: "#0f172a" }}>Trip Completed! 🎉</div>
          <div style={{ fontSize: 9, color: "#94a3b8", marginTop: 2 }}>Rate your experience with Anil Kumar</div>

          {/* Fare summary */}
          <div style={{ background: "#f8fafc", borderRadius: 12, padding: "10px 14px", margin: "12px 0", textAlign: "left" }}>
            <div style={{ display: "flex", justifyContent: "space-between" }}>
              <span style={{ fontSize: 9, color: "#64748b" }}>Total Fare</span>
              <span style={{ fontSize: 14, fontWeight: 900, color: "#0f172a" }}>₹95</span>
            </div>
            <div style={{ height: 1, background: "#f1f5f9", margin: "6px 0" }} />
            {[["Distance","7.2 km"],["Duration","22 min"],["Payment","Cash"]].map(([k,v],i) => (
              <div key={i} style={{ display: "flex", justifyContent: "space-between", marginBottom: 2 }}>
                <span style={{ fontSize: 8.5, color: "#94a3b8" }}>{k}</span>
                <span style={{ fontSize: 8.5, fontWeight: 600, color: "#475569" }}>{v}</span>
              </div>
            ))}
          </div>

          {/* Stars */}
          <div style={{ fontSize: 9, color: "#64748b", marginBottom: 8 }}>How was your ride?</div>
          <div style={{ display: "flex", gap: 8, justifyContent: "center", marginBottom: 14 }}>
            {[1,2,3,4,5].map(s => (
              <div key={s} onClick={() => setRating(s)}
                style={{ fontSize: 26, cursor: "pointer", filter: s <= rating ? "none" : "grayscale(1) opacity(0.3)" }}>⭐</div>
            ))}
          </div>

          <div style={{
            background: "linear-gradient(135deg,#6d28d9,#4f46e5)",
            borderRadius: 14, padding: "11px 0", textAlign: "center",
            color: "white", fontSize: 11, fontWeight: 700,
            boxShadow: "0 6px 16px rgba(109,40,217,0.35)",
          }}>Submit Rating & Done ✓</div>
        </div>
      </div>
    </PhoneFrame>
  );
}

// ── SCREEN DATA ───────────────────────────────────────────────────────────────

const DRIVER_SCREENS = [
  { title: "Splash Screen", sub: "Brand + launch", component: <DriverSplash /> },
  { title: "OTP Login", sub: "Dark + amber theme", component: <DriverOtp /> },
  { title: "Home — Online", sub: "Map + toggle + stats", component: <DriverHome /> },
  { title: "New Ride Alert 🔔", sub: "Sound alert popup", component: <DriverNewTrip /> },
  { title: "Trip In Progress", sub: "Live nav + customer info", component: <DriverOnTrip /> },
  { title: "Wallet", sub: "Balance + transactions", component: <DriverWallet /> },
];

const CUSTOMER_SCREENS = [
  { title: "Splash Screen", sub: "Purple gradient", component: <CustomerSplash /> },
  { title: "OTP Login", sub: "Clean white + purple", component: <CustomerOtp /> },
  { title: "Home — Map", sub: "Nearby cars + search", component: <CustomerHome /> },
  { title: "Fare Selection", sub: "Compare vehicle types", component: <CustomerFareSelect /> },
  { title: "Tracking Screen", sub: "Live driver position", component: <CustomerTracking /> },
  { title: "Trip Complete + Rating", sub: "Fare summary + stars", component: <CustomerRating /> },
];

// ── DESIGN TOKENS ──────────────────────────────────────────────────────────────

const COLOR_PALETTES = [
  {
    name: "Driver App",
    colors: [
      { hex: "#0f0f1a", label: "Background" },
      { hex: "#111827", label: "Card" },
      { hex: "#1e293b", label: "Surface" },
      { hex: "#f59e0b", label: "Primary" },
      { hex: "#ef4444", label: "Accent" },
      { hex: "#22c55e", label: "Success" },
      { hex: "#60a5fa", label: "Info" },
    ],
  },
  {
    name: "Customer App",
    colors: [
      { hex: "#ffffff", label: "Background" },
      { hex: "#f8fafc", label: "Surface" },
      { hex: "#e2e8f0", label: "Border" },
      { hex: "#6d28d9", label: "Primary" },
      { hex: "#4f46e5", label: "Secondary" },
      { hex: "#f59e0b", label: "Accent" },
      { hex: "#22c55e", label: "Success" },
    ],
  },
];

// ── MAIN PAGE ─────────────────────────────────────────────────────────────────

export default function AppDesignPage() {
  const [activeTab, setActiveTab] = useState<AppTab>("driver");
  const screens = activeTab === "driver" ? DRIVER_SCREENS : CUSTOMER_SCREENS;
  const palette = COLOR_PALETTES[activeTab === "driver" ? 0 : 1];

  return (
    <div className="container-fluid">
      {/* Header */}
      <div className="d-flex align-items-center justify-content-between mb-4">
        <div>
          <h4 className="fw-bold mb-0" data-testid="page-title">
            <i className="bi bi-phone-fill me-2 text-primary"></i>Flutter App UI Design
          </h4>
          <div className="text-muted small">Driver App + Customer App — Screen mockups & color system</div>
        </div>
        <div className="d-flex gap-2 align-items-center">
          <span className="badge rounded-pill" style={{ background: "#f0fdf4", color: "#16a34a", fontSize: 11 }}>
            <i className="bi bi-check-circle-fill me-1"></i>Production Ready Design
          </span>
        </div>
      </div>

      {/* App switcher */}
      <div className="d-flex gap-0 mb-4 rounded-3 overflow-hidden" style={{ background: "#f1f5f9", padding: 4, width: "fit-content" }}>
        {(["driver", "customer"] as AppTab[]).map(tab => (
          <button key={tab} onClick={() => setActiveTab(tab)}
            className="btn btn-sm fw-semibold"
            style={{
              borderRadius: 10, padding: "8px 20px", fontSize: 12, border: "none",
              background: activeTab === tab ? (tab === "driver" ? "linear-gradient(135deg,#0f0f1a,#1a1040)" : "linear-gradient(135deg,#6d28d9,#4f46e5)") : "transparent",
              color: activeTab === tab ? "white" : "#64748b",
              boxShadow: activeTab === tab ? "0 4px 12px rgba(0,0,0,0.2)" : "none",
              transition: "all 0.2s",
            }}
            data-testid={`tab-${tab}`}>
            {tab === "driver" ? "🚗 Driver App" : "👤 Customer App"}
          </button>
        ))}
      </div>

      {/* Color Palette */}
      <div className="card border-0 shadow-sm mb-4" style={{ borderRadius: 14 }}>
        <div className="card-header bg-white py-3 px-4" style={{ borderBottom: "1px solid #f1f5f9" }}>
          <span className="fw-semibold" style={{ fontSize: 13 }}>
            <i className="bi bi-palette-fill me-2" style={{ color: activeTab === "driver" ? "#f59e0b" : "#6d28d9" }}></i>
            {palette.name} — Color System
          </span>
        </div>
        <div className="card-body px-4 py-3">
          <div className="d-flex gap-3 flex-wrap">
            {palette.colors.map((c, i) => (
              <div key={i} className="text-center">
                <div style={{
                  width: 44, height: 44, borderRadius: 12, background: c.hex,
                  border: c.hex === "#ffffff" ? "1.5px solid #e2e8f0" : "none",
                  boxShadow: "0 4px 12px rgba(0,0,0,0.12)",
                  marginBottom: 4,
                }} />
                <div style={{ fontSize: 9, color: "#64748b" }}>{c.label}</div>
                <code style={{ fontSize: 8, color: "#94a3b8" }}>{c.hex}</code>
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* Screens grid */}
      <div className="row g-4">
        {screens.map((screen, i) => (
          <div key={i} className="col-6 col-md-4 col-xl-2">
            {screen.component}
            <ScreenLabel title={screen.title} sub={screen.sub} />
          </div>
        ))}
      </div>

      {/* Typography & spacing guide */}
      <div className="row g-3 mt-2">
        <div className="col-md-6">
          <div className="card border-0 shadow-sm" style={{ borderRadius: 14 }}>
            <div className="card-header bg-white py-3 px-4" style={{ borderBottom: "1px solid #f1f5f9" }}>
              <span className="fw-semibold" style={{ fontSize: 13 }}>
                <i className="bi bi-type me-2 text-primary"></i>Typography
              </span>
            </div>
            <div className="card-body px-4">
              {[
                { name: "Headline", size: "22–28px", weight: 900, sample: "₹1,240" },
                { name: "Title", size: "16–18px", weight: 800, sample: "New Ride Request!" },
                { name: "Body", size: "12–14px", weight: 600, sample: "Anil Kumar • Driver" },
                { name: "Caption", size: "9–11px", weight: 500, sample: "2.4 km away • 8 min" },
                { name: "Label", size: "8–9px", weight: 700, sample: "ONLINE STATUS" },
              ].map((t, i) => (
                <div key={i} className="d-flex align-items-center gap-3 mb-3">
                  <div style={{ width: 60, fontSize: 9.5, color: "#64748b" }}>
                    <div style={{ fontWeight: 600 }}>{t.name}</div>
                    <div>{t.size}</div>
                  </div>
                  <div style={{ fontSize: t.name === "Headline" ? 20 : t.name === "Title" ? 15 : t.name === "Body" ? 12 : t.name === "Caption" ? 10 : 8.5, fontWeight: t.weight, color: "#0f172a" }}>
                    {t.sample}
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>

        <div className="col-md-6">
          <div className="card border-0 shadow-sm h-100" style={{ borderRadius: 14 }}>
            <div className="card-header bg-white py-3 px-4" style={{ borderBottom: "1px solid #f1f5f9" }}>
              <span className="fw-semibold" style={{ fontSize: 13 }}>
                <i className="bi bi-grid-fill me-2" style={{ color: activeTab === "driver" ? "#f59e0b" : "#6d28d9" }}></i>
                Flutter pubspec.yaml
              </span>
            </div>
            <div className="card-body p-0">
              <pre style={{
                background: "#0f172a", color: "#e2e8f0", margin: 0,
                padding: "16px 18px", fontSize: 10.5, lineHeight: 1.8,
                borderRadius: "0 0 14px 14px", overflowX: "auto",
              }}>{`dependencies:
  flutter:
    sdk: flutter

  # HTTP & Storage
  http: ^1.2.0
  shared_preferences: ^2.2.3

  # Maps
  google_maps_flutter: ^2.5.0
  geolocator: ^11.0.0

  # Firebase (Push Notifications)
  firebase_core: ^2.27.0
  firebase_messaging: ^14.9.0

  # Local Notifications + Sound
  flutter_local_notifications: ^17.0.0
  audioplayers: ^6.0.0

  # State Management
  provider: ^6.1.2

  # UI
  shimmer: ^3.0.0
  lottie: ^3.0.0`}</pre>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
