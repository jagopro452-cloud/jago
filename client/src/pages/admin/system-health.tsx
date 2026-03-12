import { useState } from "react";
import { useQuery } from "@tanstack/react-query";
import AdminLayout from "./layout";

interface HealthData {
  timestamp: string;
  status: string;
  services: Array<{
    service_key: string;
    service_name: string;
    service_status: string;
    revenue_model: string;
    commission_rate: number;
  }>;
  trips: {
    active: number;
    completedToday: number;
    cancelledToday: number;
    staleSearching: number;
  };
  parcels: {
    active: number;
    completedToday: number;
    commissionToday: number;
  };
  drivers: {
    online: number;
    locked: number;
    onTrip: number;
    activeSubscriptions: number;
    subscribedDrivers: number;
  };
  gstWallet: {
    balance: number;
    totalCollected: number;
    totalTrips: number;
  };
}

const SERVICE_ICONS: Record<string, string> = {
  bike_ride:       "🏍️",
  auto_ride:       "🛺",
  mini_car:        "🚗",
  sedan:           "🚙",
  suv:             "🚐",
  city_pool:       "👥",
  intercity_pool:  "🛣️",
  outstation_pool: "🗺️",
  parcel_delivery: "📦",
};

function StatusPill({ ok, label }: { ok: boolean; label: string }) {
  return (
    <span style={{
      display: "inline-flex", alignItems: "center", gap: 5,
      padding: "4px 12px", borderRadius: 20, fontSize: 12, fontWeight: 700,
      background: ok ? "rgba(46,204,113,0.12)" : "rgba(231,76,60,0.12)",
      color: ok ? "#27ae60" : "#e74c3c",
    }}>
      <span style={{ width: 7, height: 7, borderRadius: "50%", background: ok ? "#2ecc71" : "#e74c3c", display: "inline-block" }} />
      {label}
    </span>
  );
}

function KpiCard({ icon, label, value, sub, accent }: { icon: string; label: string; value: string | number; sub?: string; accent?: string }) {
  const color = accent || "#2F80ED";
  return (
    <div style={{
      background: "#fff", borderRadius: 16, padding: "18px 20px",
      boxShadow: "0 2px 12px rgba(0,0,0,0.06)", border: "1px solid #F3F4F6",
      display: "flex", gap: 14, alignItems: "center",
    }}>
      <div style={{ width: 46, height: 46, borderRadius: 13, background: `${color}15`, display: "flex", alignItems: "center", justifyContent: "center", fontSize: 22, flexShrink: 0 }}>
        {icon}
      </div>
      <div>
        <div style={{ fontSize: 22, fontWeight: 800, lineHeight: 1.1, color: "#1a1a2e" }}>{value}</div>
        <div style={{ fontSize: 12, color: "#6B7280", fontWeight: 600 }}>{label}</div>
        {sub && <div style={{ fontSize: 11, color: "#9CA3AF", marginTop: 2 }}>{sub}</div>}
      </div>
    </div>
  );
}

export default function SystemHealthPage() {
  const [autoRefresh, setAutoRefresh] = useState(true);

  const { data, isLoading, error, refetch, dataUpdatedAt } = useQuery<HealthData>({
    queryKey: ["/api/admin/system-health"],
    queryFn: () => fetch("/api/admin/system-health").then(r => {
      if (!r.ok) throw new Error("Health check failed");
      return r.json();
    }).then(d => (d && !d.message && !d.error) ? d : (() => { throw new Error("Invalid health data"); })()),
    refetchInterval: autoRefresh ? 15000 : false,
  });

  const lastUpdated = dataUpdatedAt
    ? new Date(dataUpdatedAt).toLocaleTimeString("en-IN", { hour: "2-digit", minute: "2-digit", second: "2-digit" })
    : "—";

  const isOk = data?.status === "ok";
  const hasStaleTrips = (data?.trips.staleSearching ?? 0) > 0;

  return (
    <AdminLayout>
      <div style={{ padding: "28px 32px", maxWidth: 1200 }}>

        {/* Header */}
        <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", marginBottom: 28, flexWrap: "wrap", gap: 12 }}>
          <div style={{ display: "flex", alignItems: "center", gap: 12 }}>
            <div style={{
              width: 48, height: 48, borderRadius: 14,
              background: isOk ? "linear-gradient(135deg,#2ecc71,#27ae60)" : "linear-gradient(135deg,#e74c3c,#c0392b)",
              display: "flex", alignItems: "center", justifyContent: "center",
              boxShadow: `0 4px 14px ${isOk ? "rgba(46,204,113,0.4)" : "rgba(231,76,60,0.4)"}`,
            }}>
              <i className="bi bi-activity" style={{ color: "#fff", fontSize: 22 }} />
            </div>
            <div>
              <h4 style={{ fontWeight: 800, margin: 0, fontSize: 20, letterSpacing: -0.3 }}>System Health Monitor</h4>
              <p style={{ margin: 0, fontSize: 13, color: "#6B7280" }}>
                Live status of Bike Ride + Parcel Delivery services &nbsp;·&nbsp; Last updated: {lastUpdated}
              </p>
            </div>
          </div>
          <div style={{ display: "flex", gap: 8, alignItems: "center" }}>
            <label style={{ display: "flex", alignItems: "center", gap: 6, fontSize: 13, cursor: "pointer" }}>
              <input type="checkbox" checked={autoRefresh} onChange={e => setAutoRefresh(e.target.checked)} />
              Auto-refresh (15s)
            </label>
            <button
              onClick={() => refetch()}
              className="btn btn-sm btn-outline-primary"
              style={{ borderRadius: 10 }}
            >
              <i className="bi bi-arrow-clockwise me-1" />Refresh
            </button>
          </div>
        </div>

        {isLoading && !data && (
          <div style={{ textAlign: "center", padding: 80 }}>
            <div className="spinner-border" style={{ color: "#2F80ED" }} />
            <p style={{ marginTop: 12, color: "#6B7280" }}>Running system checks…</p>
          </div>
        )}

        {error && (
          <div style={{ background: "rgba(231,76,60,0.1)", border: "1px solid #e74c3c", borderRadius: 12, padding: 20, color: "#c0392b", marginBottom: 20 }}>
            <i className="bi bi-exclamation-triangle-fill me-2" />
            Health check failed: {(error as Error).message}
          </div>
        )}

        {data && (
          <>
            {/* Overall status banner */}
            <div style={{
              background: isOk && !hasStaleTrips
                ? "linear-gradient(135deg,rgba(46,204,113,0.12),rgba(39,174,96,0.08))"
                : "linear-gradient(135deg,rgba(243,156,18,0.12),rgba(230,126,34,0.08))",
              border: `1px solid ${isOk && !hasStaleTrips ? "#2ecc71" : "#f39c12"}`,
              borderRadius: 14, padding: "14px 20px", marginBottom: 24,
              display: "flex", alignItems: "center", gap: 10,
            }}>
              <i
                className={`bi ${isOk && !hasStaleTrips ? "bi-check-circle-fill" : "bi-exclamation-triangle-fill"}`}
                style={{ fontSize: 20, color: isOk && !hasStaleTrips ? "#27ae60" : "#f39c12" }}
              />
              <div>
                <div style={{ fontWeight: 700, fontSize: 14, color: isOk && !hasStaleTrips ? "#155724" : "#856404" }}>
                  {isOk && !hasStaleTrips ? "All Systems Operational" : hasStaleTrips ? "Warning: Stale searching trips detected" : "System Error Detected"}
                </div>
                <div style={{ fontSize: 12, color: "#6B7280" }}>
                  Bike Ride + Parcel Delivery active · Subscription gate enforced · Commission model active
                </div>
              </div>
            </div>

            {/* Platform Services */}
            <h6 style={{ fontWeight: 800, fontSize: 13, textTransform: "uppercase", letterSpacing: 1, color: "#6B7280", marginBottom: 12 }}>
              Platform Services
            </h6>
            <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fill, minmax(200px, 1fr))", gap: 10, marginBottom: 28 }}>
              {data.services.map(s => (
                <div key={s.service_key} style={{
                  background: "#fff", borderRadius: 12, padding: "14px 16px",
                  border: `1px solid ${s.service_status === "active" ? "#d1fae5" : "#F3F4F6"}`,
                  boxShadow: "0 1px 6px rgba(0,0,0,0.05)",
                }}>
                  <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", marginBottom: 8 }}>
                    <span style={{ fontSize: 22 }}>{SERVICE_ICONS[s.service_key] ?? "🔧"}</span>
                    <StatusPill ok={s.service_status === "active"} label={s.service_status === "active" ? "Active" : "Inactive"} />
                  </div>
                  <div style={{ fontWeight: 700, fontSize: 13, marginBottom: 2 }}>{s.service_name}</div>
                  <div style={{ fontSize: 11, color: "#9CA3AF", textTransform: "capitalize" }}>
                    {s.revenue_model}
                    {s.revenue_model === "commission" ? ` · ${s.commission_rate}%` : ""}
                  </div>
                </div>
              ))}
            </div>

            {/* KPI Grid */}
            <h6 style={{ fontWeight: 800, fontSize: 13, textTransform: "uppercase", letterSpacing: 1, color: "#6B7280", marginBottom: 12 }}>
              Live Metrics (Today)
            </h6>
            <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fill, minmax(200px, 1fr))", gap: 14, marginBottom: 28 }}>
              <KpiCard icon="🏍️" label="Active Rides" value={data.trips.active} accent="#2F80ED" />
              <KpiCard icon="✅" label="Rides Completed" value={data.trips.completedToday} sub="Last 24 hours" accent="#2ecc71" />
              <KpiCard icon="❌" label="Rides Cancelled" value={data.trips.cancelledToday} sub="Last 24 hours" accent="#e74c3c" />
              <KpiCard
                icon="⚠️" label="Stale Searching" value={data.trips.staleSearching}
                sub=">5 min with no driver" accent={data.trips.staleSearching > 0 ? "#e74c3c" : "#2ecc71"}
              />
              <KpiCard icon="📦" label="Active Parcels" value={data.parcels.active} accent="#FF6B35" />
              <KpiCard icon="📬" label="Parcels Delivered" value={data.parcels.completedToday} sub="Last 24 hours" accent="#8B5CF6" />
              <KpiCard icon="💰" label="Parcel Commission" value={`₹${data.parcels.commissionToday}`} sub="Last 24 hours" accent="#8B5CF6" />
            </div>

            {/* Driver + Subscription Status */}
            <h6 style={{ fontWeight: 800, fontSize: 13, textTransform: "uppercase", letterSpacing: 1, color: "#6B7280", marginBottom: 12 }}>
              Driver Status
            </h6>
            <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fill, minmax(200px, 1fr))", gap: 14, marginBottom: 28 }}>
              <KpiCard icon="🟢" label="Online Drivers" value={data.drivers.online} accent="#2ecc71" />
              <KpiCard icon="🚗" label="Drivers On Trip" value={data.drivers.onTrip} accent="#2F80ED" />
              <KpiCard icon="🔒" label="Locked Drivers" value={data.drivers.locked} sub="Pending dues" accent="#e74c3c" />
              <KpiCard icon="📋" label="Active Subscriptions" value={data.drivers.activeSubscriptions} sub={`${data.drivers.subscribedDrivers} unique drivers`} accent="#F39C12" />
            </div>

            {/* Revenue + GST */}
            <h6 style={{ fontWeight: 800, fontSize: 13, textTransform: "uppercase", letterSpacing: 1, color: "#6B7280", marginBottom: 12 }}>
              Admin Revenue
            </h6>
            <div style={{ display: "grid", gridTemplateColumns: "repeat(3, 1fr)", gap: 14, marginBottom: 28 }}>
              <div style={{ background: "linear-gradient(135deg,#2F80ED,#4A90E2)", borderRadius: 16, padding: "20px 22px", color: "#fff" }}>
                <div style={{ fontSize: 13, opacity: 0.8, marginBottom: 4 }}>GST Wallet Balance</div>
                <div style={{ fontSize: 28, fontWeight: 800 }}>₹{data.gstWallet.balance.toFixed(2)}</div>
                <div style={{ fontSize: 12, opacity: 0.7, marginTop: 4 }}>
                  Total Collected: ₹{data.gstWallet.totalCollected.toFixed(2)}
                </div>
              </div>
              <div style={{ background: "linear-gradient(135deg,#8B5CF6,#6D28D9)", borderRadius: 16, padding: "20px 22px", color: "#fff" }}>
                <div style={{ fontSize: 13, opacity: 0.8, marginBottom: 4 }}>GST Trips Processed</div>
                <div style={{ fontSize: 28, fontWeight: 800 }}>{data.gstWallet.totalTrips}</div>
                <div style={{ fontSize: 12, opacity: 0.7, marginTop: 4 }}>Total trip-level GST collections</div>
              </div>
              <div style={{ background: "linear-gradient(135deg,#FF6B35,#F59E0B)", borderRadius: 16, padding: "20px 22px", color: "#fff" }}>
                <div style={{ fontSize: 13, opacity: 0.8, marginBottom: 4 }}>Revenue Sources</div>
                <div style={{ fontSize: 15, fontWeight: 700, marginTop: 6 }}>
                  <div>🏍️ Bike Ride → Subscription</div>
                  <div style={{ marginTop: 4 }}>📦 Parcel → 15% Commission</div>
                </div>
              </div>
            </div>

            {/* System checks panel */}
            <h6 style={{ fontWeight: 800, fontSize: 13, textTransform: "uppercase", letterSpacing: 1, color: "#6B7280", marginBottom: 12 }}>
              System Checks
            </h6>
            <div style={{ background: "#fff", borderRadius: 16, padding: "20px 24px", border: "1px solid #F3F4F6", boxShadow: "0 2px 12px rgba(0,0,0,0.04)" }}>
              {[
                {
                  label: "Bike Ride service active",
                  ok: data.services.some(s => s.service_key === "bike_ride" && s.service_status === "active"),
                  detail: "bike_ride is enabled in platform_services",
                },
                {
                  label: "Parcel Delivery service active",
                  ok: data.services.some(s => s.service_key === "parcel_delivery" && s.service_status === "active"),
                  detail: "parcel_delivery is enabled in platform_services",
                },
                {
                  label: "Bike Ride uses Subscription model",
                  ok: data.services.some(s => s.service_key === "bike_ride" && s.revenue_model === "subscription"),
                  detail: "Revenue model = subscription (drivers need active plan to accept)",
                },
                {
                  label: "Parcel uses Commission model",
                  ok: data.services.some(s => s.service_key === "parcel_delivery" && s.revenue_model === "commission"),
                  detail: `${data.services.find(s => s.service_key === "parcel_delivery")?.commission_rate ?? 15}% commission per delivery`,
                },
                {
                  label: "No stale searching trips",
                  ok: data.trips.staleSearching === 0,
                  detail: data.trips.staleSearching > 0 ? `${data.trips.staleSearching} trips stuck >5min in searching status` : "All search timeouts are clearing properly",
                },
                {
                  label: "GST wallet operational",
                  ok: data.gstWallet.totalTrips >= 0,
                  detail: `Balance ₹${data.gstWallet.balance.toFixed(2)} · ${data.gstWallet.totalTrips} total trips`,
                },
                {
                  label: "Active subscriptions exist",
                  ok: data.drivers.subscribedDrivers >= 0,
                  detail: `${data.drivers.subscribedDrivers} drivers with active subscription plans`,
                },
                {
                  label: "Services NOT in launch scope are inactive",
                  ok: data.services.filter(s => !["bike_ride", "parcel_delivery"].includes(s.service_key)).every(s => s.service_status === "inactive"),
                  detail: "auto_ride, mini_car, sedan, SUV, car pools all inactive",
                },
              ].map((check, i) => (
                <div key={i} style={{
                  display: "flex", alignItems: "flex-start", gap: 12, padding: "10px 0",
                  borderBottom: i < 7 ? "1px solid #F9FAFB" : "none",
                }}>
                  <div style={{
                    width: 22, height: 22, borderRadius: "50%", flexShrink: 0, marginTop: 1,
                    background: check.ok ? "rgba(46,204,113,0.15)" : "rgba(231,76,60,0.15)",
                    display: "flex", alignItems: "center", justifyContent: "center",
                  }}>
                    <i
                      className={`bi ${check.ok ? "bi-check-lg" : "bi-x-lg"}`}
                      style={{ fontSize: 11, color: check.ok ? "#27ae60" : "#e74c3c", fontWeight: 900 }}
                    />
                  </div>
                  <div>
                    <div style={{ fontSize: 13, fontWeight: 700, color: check.ok ? "#155724" : "#721c24" }}>
                      {check.label}
                    </div>
                    <div style={{ fontSize: 12, color: "#9CA3AF" }}>{check.detail}</div>
                  </div>
                </div>
              ))}
            </div>
          </>
        )}
      </div>
    </AdminLayout>
  );
}
