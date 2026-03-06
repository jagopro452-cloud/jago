import { useState, useEffect } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import AdminLayout from "./layout";

interface Service {
  key: string;
  name: string;
  description: string;
  icon: string;
  emoji: string;
  color: string;
  isActive: boolean;
}

const SERVICE_META: Record<string, { icon: string; color: string; gradient: string; vehicles: string; launchFirst?: boolean; priority?: string }> = {
  ride:       { icon: "bi-car-front-fill",    color: "#1E6DE5", gradient: "linear-gradient(135deg,#1E6DE5,#3B82F6)", vehicles: "Bike Taxi, Auto, Car, SUV, Temo Auto" },
  parcel:     { icon: "bi-box-seam-fill",     color: "#FF6B35", gradient: "linear-gradient(135deg,#FF6B35,#F59E0B)", vehicles: "Bike Parcel, Mini Auto Parcel", launchFirst: true, priority: "🚀 LAUNCH #1" },
  cargo:      { icon: "bi-truck-front-fill",  color: "#10B981", gradient: "linear-gradient(135deg,#10B981,#34D399)", vehicles: "Cargo Truck, Mini Cargo Van, Tata Ace" },
  intercity:  { icon: "bi-signpost-2-fill",   color: "#8B5CF6", gradient: "linear-gradient(135deg,#8B5CF6,#A78BFA)", vehicles: "All vehicles on intercity routes" },
  carsharing: { icon: "bi-people-fill",       color: "#EF4444", gradient: "linear-gradient(135deg,#EF4444,#F87171)", vehicles: "Shared car rides between city zones" },
};

const BIKE_LAUNCH_FIRST = true;

export default function ServiceManagement() {
  const queryClient = useQueryClient();
  const [toggling, setToggling] = useState<string | null>(null);

  const { data: services = [], isLoading } = useQuery<Service[]>({
    queryKey: ["/api/services"],
  });

  const toggleMutation = useMutation({
    mutationFn: async ({ key, current }: { key: string; current: boolean }) => {
      const res = await fetch(`/api/services/${key}`, {
        method: "PATCH",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ isActive: !current }),
      });
      if (!res.ok) throw new Error("Failed to toggle");
      return res.json();
    },
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ["/api/services"] }),
  });

  const activeCount = services.filter(s => s.isActive).length;
  const totalCount  = services.length;
  const pct = totalCount > 0 ? Math.round((activeCount / totalCount) * 100) : 0;

  return (
    <AdminLayout>
      <div style={{ padding: "28px 32px", maxWidth: 1100 }}>

        {/* Header Row */}
        <div style={{ display: "flex", alignItems: "flex-start", justifyContent: "space-between", marginBottom: 28, flexWrap: "wrap", gap: 16 }}>
          <div>
            <div style={{ display: "flex", alignItems: "center", gap: 12, marginBottom: 8 }}>
              <div style={{
                width: 44, height: 44, borderRadius: 14,
                background: "linear-gradient(135deg,#FF6B35,#FF8C5A)",
                display: "flex", alignItems: "center", justifyContent: "center",
                boxShadow: "0 4px 14px rgba(255,107,53,0.35)",
              }}>
                <i className="bi bi-toggles2" style={{ color: "#fff", fontSize: 20 }} />
              </div>
              <div>
                <h4 style={{ fontWeight: 800, margin: 0, letterSpacing: -0.3 }}>Service Management</h4>
                <p style={{ margin: 0, fontSize: 13, color: "#6B7280" }}>Activate or deactivate services for the customer app</p>
              </div>
            </div>
          </div>
          {/* Launch Progress */}
          <div style={{
            background: "linear-gradient(135deg,#060D1E,#0D1B3E)",
            borderRadius: 16, padding: "14px 20px", minWidth: 220,
            border: "1px solid rgba(255,107,53,0.2)",
          }}>
            <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 8 }}>
              <span style={{ color: "rgba(255,255,255,0.7)", fontSize: 12, fontWeight: 600 }}>Launch Readiness</span>
              <span style={{ color: "#FF6B35", fontWeight: 800, fontSize: 14 }}>{activeCount}/{totalCount} Active</span>
            </div>
            <div style={{ background: "rgba(255,255,255,0.1)", borderRadius: 8, height: 8, overflow: "hidden" }}>
              <div style={{
                width: `${pct}%`, height: "100%",
                background: "linear-gradient(90deg,#FF6B35,#FFD700)",
                borderRadius: 8, transition: "width .4s ease",
              }} />
            </div>
            <div style={{ color: "rgba(255,255,255,0.45)", fontSize: 11, marginTop: 6, fontWeight: 500 }}>
              {pct}% services enabled for customers
            </div>
          </div>
        </div>

        {/* Parcel + Bike Launch Banner */}
        <div style={{
          background: "linear-gradient(135deg,rgba(255,107,53,0.12),rgba(255,215,0,0.08))",
          border: "1px solid rgba(255,107,53,0.3)",
          borderRadius: 16, padding: "16px 20px", marginBottom: 24,
          display: "flex", alignItems: "center", gap: 14,
        }}>
          <div style={{ fontSize: 32 }}>🎯</div>
          <div style={{ flex: 1 }}>
            <div style={{ fontWeight: 800, fontSize: 14, marginBottom: 4 }}>
              Strategy: Parcel &amp; Bike First Launch
            </div>
            <div style={{ fontSize: 12, color: "#6B7280", lineHeight: 1.5 }}>
              Start with <strong>Parcel</strong> and <strong>Bike Taxi</strong> to build driver supply and customer trust. Enable other services as your fleet grows.
            </div>
          </div>
          <div style={{
            padding: "6px 14px", borderRadius: 20,
            background: "linear-gradient(135deg,#FF6B35,#FFD700)",
            color: "#fff", fontWeight: 800, fontSize: 11, whiteSpace: "nowrap",
            boxShadow: "0 2px 10px rgba(255,107,53,0.35)",
          }}>
            🚀 Phase 1
          </div>
        </div>

        {isLoading ? (
          <div style={{ textAlign: "center", padding: "60px 0" }}>
            <div className="spinner-border" style={{ color: "#FF6B35" }} />
            <p style={{ marginTop: 12, color: "#6B7280" }}>Loading services...</p>
          </div>
        ) : (
          <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fill, minmax(320px, 1fr))", gap: 16 }}>
            {services.map((svc) => {
              const meta = SERVICE_META[svc.key] || { icon: "bi-grid-fill", color: "#6366f1", gradient: "linear-gradient(135deg,#6366f1,#8B5CF6)", vehicles: "" };
              const isLaunchFirst = meta.launchFirst || (svc.key === "ride" && BIKE_LAUNCH_FIRST);
              const isBike = svc.key === "ride";
              return (
                <div key={svc.key} style={{
                  background: "#fff",
                  borderRadius: 20,
                  overflow: "hidden",
                  boxShadow: svc.isActive
                    ? `0 4px 24px ${meta.color}22, 0 1px 4px rgba(0,0,0,0.06)`
                    : "0 2px 12px rgba(0,0,0,0.06)",
                  border: svc.isActive ? `1.5px solid ${meta.color}40` : "1.5px solid #F3F4F6",
                  transition: "all .25s ease",
                  position: "relative",
                }} data-testid={`service-card-${svc.key}`}>

                  {/* Top gradient bar */}
                  <div style={{ height: 5, background: svc.isActive ? meta.gradient : "#E5E7EB" }} />

                  {/* Launch first badge */}
                  {(isLaunchFirst || isBike) && (
                    <div style={{
                      position: "absolute", top: 14, right: 14,
                      background: meta.launchFirst ? "linear-gradient(135deg,#FF6B35,#F59E0B)" : "linear-gradient(135deg,#3B82F6,#1E6DE5)",
                      color: "#fff", fontSize: 9, fontWeight: 800,
                      padding: "3px 8px", borderRadius: 8, letterSpacing: 0.5,
                    }}>
                      {meta.priority || "🏍️ PHASE 1"}
                    </div>
                  )}

                  <div style={{ padding: "20px 20px 16px" }}>
                    {/* Icon + Name Row */}
                    <div style={{ display: "flex", alignItems: "center", gap: 14, marginBottom: 14 }}>
                      <div style={{
                        width: 56, height: 56, borderRadius: 16,
                        background: svc.isActive ? meta.gradient : "#F3F4F6",
                        display: "flex", alignItems: "center", justifyContent: "center",
                        boxShadow: svc.isActive ? `0 4px 14px ${meta.color}40` : "none",
                        transition: "all .25s ease",
                        flexShrink: 0,
                      }}>
                        <span style={{ fontSize: 26 }}>{svc.emoji}</span>
                      </div>
                      <div style={{ flex: 1, minWidth: 0 }}>
                        <div style={{ display: "flex", alignItems: "center", gap: 8, marginBottom: 4 }}>
                          <span style={{ fontWeight: 800, fontSize: 16 }}>{svc.name}</span>
                          <span style={{
                            padding: "2px 8px", borderRadius: 20, fontSize: 10, fontWeight: 700,
                            background: svc.isActive ? `${meta.color}18` : "#F3F4F6",
                            color: svc.isActive ? meta.color : "#9CA3AF",
                            border: `1px solid ${svc.isActive ? meta.color + "30" : "#E5E7EB"}`,
                          }}>
                            {svc.isActive ? "● Active" : "○ Disabled"}
                          </span>
                        </div>
                        <p style={{ margin: 0, fontSize: 12, color: "#6B7280", lineHeight: 1.4 }}>{svc.description}</p>
                      </div>
                    </div>

                    {/* Vehicles */}
                    <div style={{
                      background: "#F9FAFB", borderRadius: 10, padding: "8px 12px",
                      fontSize: 11, color: "#4B5563", marginBottom: 14,
                      borderLeft: `3px solid ${meta.color}`,
                    }}>
                      <span style={{ fontWeight: 600, color: meta.color, marginRight: 4 }}>
                        <i className="bi bi-ev-front-fill" /> Vehicles:
                      </span>
                      {meta.vehicles}
                    </div>

                    {/* Toggle Row */}
                    <div style={{
                      display: "flex", alignItems: "center", justifyContent: "space-between",
                      padding: "12px 14px",
                      background: svc.isActive ? `${meta.color}08` : "#F9FAFB",
                      borderRadius: 12,
                      border: `1px solid ${svc.isActive ? meta.color + "25" : "#E5E7EB"}`,
                    }}>
                      <div>
                        <div style={{ fontWeight: 700, fontSize: 13, marginBottom: 2 }}>
                          {svc.isActive ? "✓ Customers can book" : "✕ Hidden from customers"}
                        </div>
                        <div style={{ fontSize: 11, color: "#9CA3AF" }}>
                          {svc.isActive ? "Service is live in the app" : "Shows as 'Coming Soon'"}
                        </div>
                      </div>
                      <button
                        onClick={() => toggleMutation.mutate({ key: svc.key, current: svc.isActive })}
                        disabled={toggling === svc.key || toggleMutation.isPending}
                        data-testid={`toggle-service-${svc.key}`}
                        style={{
                          width: 56, height: 30, borderRadius: 15, border: "none",
                          background: svc.isActive ? meta.gradient : "#D1D5DB",
                          cursor: "pointer", position: "relative", transition: "all .25s ease",
                          boxShadow: svc.isActive ? `0 2px 8px ${meta.color}40` : "none",
                          flexShrink: 0,
                        }}
                      >
                        <div style={{
                          position: "absolute", top: 3, left: svc.isActive ? 30 : 4,
                          width: 24, height: 24, borderRadius: "50%",
                          background: "#fff", transition: "left .25s ease",
                          boxShadow: "0 2px 4px rgba(0,0,0,0.15)",
                        }} />
                        {(toggling === svc.key || toggleMutation.isPending) && (
                          <div style={{
                            position: "absolute", inset: 0, display: "flex",
                            alignItems: "center", justifyContent: "center",
                          }}>
                            <div className="spinner-border spinner-border-sm" style={{ color: "#fff", width: 14, height: 14, borderWidth: 2 }} />
                          </div>
                        )}
                      </button>
                    </div>
                  </div>
                </div>
              );
            })}
          </div>
        )}

        {/* Bottom info panel */}
        {!isLoading && services.length > 0 && (
          <div style={{
            marginTop: 28,
            background: "linear-gradient(135deg,#060D1E,#0D1B3E)",
            borderRadius: 20, padding: "20px 24px",
            border: "1px solid rgba(255,107,53,0.15)",
          }}>
            <div style={{ display: "flex", alignItems: "center", gap: 10, marginBottom: 14 }}>
              <i className="bi bi-lightbulb-fill" style={{ color: "#FFD700", fontSize: 18 }} />
              <span style={{ fontWeight: 700, color: "#fff", fontSize: 14 }}>Launch Strategy — Recommended Order</span>
            </div>
            <div style={{ display: "flex", gap: 12, flexWrap: "wrap" }}>
              {[
                { phase: "Phase 1", label: "Parcel + Bike Taxi", color: "#FF6B35", desc: "Quick deliveries & affordable rides" },
                { phase: "Phase 2", label: "Auto + Car Rides", color: "#1E6DE5", desc: "Regular commuting & airport trips" },
                { phase: "Phase 3", label: "Cargo + Intercity", color: "#10B981", desc: "B2B logistics & long-distance" },
              ].map(p => (
                <div key={p.phase} style={{
                  flex: "1 1 200px", background: "rgba(255,255,255,0.04)",
                  borderRadius: 12, padding: "12px 14px",
                  border: `1px solid ${p.color}30`,
                }}>
                  <div style={{ fontSize: 10, color: p.color, fontWeight: 800, letterSpacing: 0.5, marginBottom: 4 }}>
                    {p.phase}
                  </div>
                  <div style={{ color: "#fff", fontWeight: 700, fontSize: 13, marginBottom: 3 }}>{p.label}</div>
                  <div style={{ color: "rgba(255,255,255,0.45)", fontSize: 11 }}>{p.desc}</div>
                </div>
              ))}
            </div>
          </div>
        )}
      </div>
    </AdminLayout>
  );
}
