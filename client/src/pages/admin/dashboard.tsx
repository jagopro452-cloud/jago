import { useQuery } from "@tanstack/react-query";
import { Link } from "wouter";
import {
  AreaChart, Area, XAxis, YAxis, CartesianGrid, Tooltip,
  ResponsiveContainer, BarChart, Bar, Legend,
} from "recharts";

const avatarBg = (name: string) => {
  const colors = ["#1a73e8","#16a34a","#d97706","#9333ea","#0891b2","#dc2626"];
  return colors[(name || "A").charCodeAt(0) % colors.length];
};
const initials = (name: string) => (name || "?").split(" ").map(n => n[0]).join("").substring(0, 2).toUpperCase();

const STATUS_BADGE: Record<string, { cls: string; label: string }> = {
  completed: { cls: "badge bg-success", label: "Completed" },
  ongoing:   { cls: "badge bg-info", label: "Ongoing" },
  pending:   { cls: "badge bg-warning text-dark", label: "Pending" },
  cancelled: { cls: "badge bg-danger", label: "Cancelled" },
  accepted:  { cls: "badge bg-primary", label: "Accepted" },
};

export default function Dashboard() {
  const { data: stats, isLoading } = useQuery<any>({ queryKey: ["/api/dashboard/stats"] });
  const { data: chart = [] } = useQuery<any[]>({ queryKey: ["/api/dashboard/chart"] });

  const today = new Date().toLocaleDateString("en-IN", { weekday: "long", year: "numeric", month: "long", day: "numeric" });
  const adminName = (() => { try { return JSON.parse(localStorage.getItem("jago-admin") || "{}").name || "Admin"; } catch { return "Admin"; } })();
  const revenue = Number(stats?.totalRevenue || 0).toLocaleString("en-IN", { maximumFractionDigits: 0 });

  const topStats = [
    { label: "Total Customers", val: stats?.totalCustomers, icon: "bi-people-fill", color: "#1a73e8", bg: "#e8f0fe", link: "/admin/customers" },
    { label: "Total Drivers", val: stats?.totalDrivers, icon: "bi-person-badge-fill", color: "#16a34a", bg: "#f0fdf4", link: "/admin/drivers" },
    { label: "Total Revenue", val: `₹${revenue}`, icon: "bi-currency-rupee", color: "#b45309", bg: "#fefce8", link: "/admin/reports" },
    { label: "Total Trips", val: stats?.totalTrips, icon: "bi-car-front-fill", color: "#7e22ce", bg: "#f5f3ff", link: "/admin/trips" },
  ];

  const midStats = [
    { label: "Completed", val: stats?.completedTrips, icon: "bi-check-circle-fill", color: "#16a34a", bg: "rgba(22,163,74,0.1)" },
    { label: "Ongoing", val: stats?.ongoingTrips, icon: "bi-broadcast-pin", color: "#2563eb", bg: "rgba(37,99,235,0.1)" },
    { label: "Cancelled", val: stats?.cancelledTrips, icon: "bi-x-circle-fill", color: "#dc2626", bg: "rgba(220,38,38,0.1)" },
    { label: "Active Zones", val: stats?.totalZones, icon: "bi-map-fill", color: "#7c3aed", bg: "rgba(124,58,237,0.1)" },
    { label: "Vehicle Types", val: stats?.totalVehicleCategories, icon: "bi-truck", color: "#0891b2", bg: "rgba(8,145,178,0.1)" },
  ];

  return (
    <div className="container-fluid">

      {/* Welcome banner */}
      <div className="jd-banner" data-testid="dashboard-banner">
        <div className="jd-banner-inner">
          <div className="d-flex align-items-center gap-3">
            <div className="jd-avatar"><i className="bi bi-person-fill"></i></div>
            <div>
              <h3 className="mb-1">Good day, {adminName}!</h3>
              <p className="mb-0">Here's what's happening with your ride platform today.</p>
            </div>
          </div>
          <div className="jd-date-badge"><i className="bi bi-calendar3"></i><span>{today}</span></div>
        </div>
      </div>

      {/* Top 4 stat cards */}
      <div className="row g-3 mb-3">
        {topStats.map((s, i) => (
          <div key={i} className="col-xl-3 col-sm-6">
            <Link href={s.link}>
              <div className="card border-0 shadow-sm h-100" style={{ cursor: "pointer", borderRadius: 14, transition: "box-shadow 0.2s" }}
                onMouseEnter={e => (e.currentTarget.style.boxShadow = "0 6px 24px rgba(0,0,0,0.12)")}
                onMouseLeave={e => (e.currentTarget.style.boxShadow = "")}>
                <div className="card-body d-flex align-items-center gap-3">
                  <div className="rounded-3 d-flex align-items-center justify-content-center flex-shrink-0"
                    style={{ width: 54, height: 54, background: s.bg, fontSize: "1.4rem", color: s.color }}>
                    <i className={`bi ${s.icon}`}></i>
                  </div>
                  <div>
                    <div className="text-muted small fw-semibold text-uppercase" style={{ fontSize: 10, letterSpacing: ".5px" }}>{s.label}</div>
                    <div className="fw-bold mt-1" style={{ fontSize: 26, color: s.color, lineHeight: 1 }} data-testid={`stat-${i}`}>
                      {isLoading ? <span style={{ color: "#cbd5e1" }}>—</span> : (s.val ?? 0).toLocaleString()}
                    </div>
                  </div>
                </div>
              </div>
            </Link>
          </div>
        ))}
      </div>

      {/* Charts row */}
      <div className="row g-3 mb-3">
        {/* Revenue Area Chart */}
        <div className="col-lg-8">
          <div className="card border-0 shadow-sm" style={{ borderRadius: 14 }}>
            <div className="card-header bg-white py-3 px-4 d-flex align-items-center justify-content-between" style={{ borderBottom: "1px solid #f1f5f9" }}>
              <div>
                <h6 className="mb-0 fw-bold">Weekly Revenue</h6>
                <div className="text-muted small">Last 7 days performance</div>
              </div>
              <div className="d-flex gap-3 small">
                <span className="d-flex align-items-center gap-1">
                  <span style={{ width: 10, height: 10, borderRadius: 2, background: "#1a73e8", display: "inline-block" }}></span>
                  Revenue
                </span>
                <span className="d-flex align-items-center gap-1">
                  <span style={{ width: 10, height: 10, borderRadius: 2, background: "#16a34a", display: "inline-block" }}></span>
                  Trips
                </span>
              </div>
            </div>
            <div className="card-body p-3">
              <ResponsiveContainer width="100%" height={220}>
                <AreaChart data={chart} margin={{ top: 5, right: 10, bottom: 0, left: 0 }}>
                  <defs>
                    <linearGradient id="colorRev" x1="0" y1="0" x2="0" y2="1">
                      <stop offset="5%" stopColor="#1a73e8" stopOpacity={0.2} />
                      <stop offset="95%" stopColor="#1a73e8" stopOpacity={0} />
                    </linearGradient>
                    <linearGradient id="colorTrips" x1="0" y1="0" x2="0" y2="1">
                      <stop offset="5%" stopColor="#16a34a" stopOpacity={0.2} />
                      <stop offset="95%" stopColor="#16a34a" stopOpacity={0} />
                    </linearGradient>
                  </defs>
                  <CartesianGrid strokeDasharray="3 3" stroke="#f1f5f9" />
                  <XAxis dataKey="day" tick={{ fontSize: 12, fill: "#94a3b8" }} axisLine={false} tickLine={false} />
                  <YAxis tick={{ fontSize: 11, fill: "#94a3b8" }} axisLine={false} tickLine={false} width={40} />
                  <Tooltip
                    contentStyle={{ borderRadius: 10, border: "none", boxShadow: "0 4px 20px rgba(0,0,0,0.12)", fontSize: 12 }}
                    formatter={(val: any, name: string) => [name === "revenue" ? `₹${val}` : val, name === "revenue" ? "Revenue" : "Trips"]}
                  />
                  <Area type="monotone" dataKey="revenue" stroke="#1a73e8" strokeWidth={2.5} fill="url(#colorRev)" dot={false} activeDot={{ r: 5 }} />
                  <Area type="monotone" dataKey="trips" stroke="#16a34a" strokeWidth={2.5} fill="url(#colorTrips)" dot={false} activeDot={{ r: 5 }} />
                </AreaChart>
              </ResponsiveContainer>
            </div>
          </div>
        </div>

        {/* Ride vs Parcel Bar Chart */}
        <div className="col-lg-4">
          <div className="card border-0 shadow-sm h-100" style={{ borderRadius: 14 }}>
            <div className="card-header bg-white py-3 px-4" style={{ borderBottom: "1px solid #f1f5f9" }}>
              <h6 className="mb-0 fw-bold">Rides vs Parcels</h6>
              <div className="text-muted small">Weekly breakdown</div>
            </div>
            <div className="card-body p-3">
              <ResponsiveContainer width="100%" height={220}>
                <BarChart data={chart} margin={{ top: 5, right: 5, bottom: 0, left: -15 }} barSize={10}>
                  <CartesianGrid strokeDasharray="3 3" stroke="#f1f5f9" />
                  <XAxis dataKey="day" tick={{ fontSize: 11, fill: "#94a3b8" }} axisLine={false} tickLine={false} />
                  <YAxis tick={{ fontSize: 10, fill: "#94a3b8" }} axisLine={false} tickLine={false} />
                  <Tooltip contentStyle={{ borderRadius: 10, border: "none", boxShadow: "0 4px 20px rgba(0,0,0,0.12)", fontSize: 12 }} />
                  <Legend iconType="circle" iconSize={8} wrapperStyle={{ fontSize: 11 }} />
                  <Bar dataKey="rides" fill="#1a73e8" radius={[4, 4, 0, 0]} name="Rides" />
                  <Bar dataKey="parcels" fill="#16a34a" radius={[4, 4, 0, 0]} name="Parcels" />
                </BarChart>
              </ResponsiveContainer>
            </div>
          </div>
        </div>
      </div>

      {/* Mid stats strip */}
      <div className="row g-3 mb-3">
        {midStats.map((s, i) => (
          <div key={i} className="col">
            <div className="card border-0 shadow-sm" style={{ borderRadius: 12 }}>
              <div className="card-body py-3 d-flex align-items-center gap-3">
                <div className="d-flex align-items-center justify-content-center rounded-3 flex-shrink-0"
                  style={{ width: 42, height: 42, background: s.bg }}>
                  <i className={`bi ${s.icon}`} style={{ color: s.color, fontSize: "1.1rem" }}></i>
                </div>
                <div>
                  <div className="fw-bold fs-5 lh-1" style={{ color: s.color }}>
                    {isLoading ? "—" : (s.val ?? 0).toLocaleString()}
                  </div>
                  <div className="text-muted small">{s.label}</div>
                </div>
              </div>
            </div>
          </div>
        ))}
      </div>

      {/* Recent Trips */}
      <div className="card border-0 shadow-sm mb-3" style={{ borderRadius: 14 }} data-testid="recent-trips-card">
        <div className="card-header bg-white py-3 px-4 d-flex justify-content-between align-items-center" style={{ borderBottom: "1px solid #f1f5f9" }}>
          <h6 className="mb-0 fw-bold">Recent Trips</h6>
          <Link href="/admin/trips" className="text-primary small fw-semibold">View All →</Link>
        </div>
        <div className="card-body p-0">
          <div className="table-responsive">
            <table className="table table-borderless align-middle table-hover mb-0">
              <thead style={{ background: "#f8fafc" }}>
                <tr>
                  <th className="ps-4" style={{ fontSize: 11, color: "#94a3b8", fontWeight: 600, textTransform: "uppercase", letterSpacing: ".5px" }}>Trip ID</th>
                  <th style={{ fontSize: 11, color: "#94a3b8", fontWeight: 600, textTransform: "uppercase", letterSpacing: ".5px" }}>Customer</th>
                  <th style={{ fontSize: 11, color: "#94a3b8", fontWeight: 600, textTransform: "uppercase", letterSpacing: ".5px" }}>Vehicle</th>
                  <th style={{ fontSize: 11, color: "#94a3b8", fontWeight: 600, textTransform: "uppercase", letterSpacing: ".5px" }}>Type</th>
                  <th style={{ fontSize: 11, color: "#94a3b8", fontWeight: 600, textTransform: "uppercase", letterSpacing: ".5px" }}>Fare</th>
                  <th style={{ fontSize: 11, color: "#94a3b8", fontWeight: 600, textTransform: "uppercase", letterSpacing: ".5px" }}>Payment</th>
                  <th style={{ fontSize: 11, color: "#94a3b8", fontWeight: 600, textTransform: "uppercase", letterSpacing: ".5px" }}>Status</th>
                  <th style={{ fontSize: 11, color: "#94a3b8", fontWeight: 600, textTransform: "uppercase", letterSpacing: ".5px" }}>Date</th>
                </tr>
              </thead>
              <tbody>
                {isLoading ? (
                  Array(6).fill(0).map((_, i) => (
                    <tr key={i}>
                      {Array(8).fill(0).map((_, j) => (
                        <td key={j}><div style={{ height: 13, background: "#f1f5f9", borderRadius: 4 }} /></td>
                      ))}
                    </tr>
                  ))
                ) : stats?.recentTrips?.length ? (
                  stats.recentTrips.map((item: any, idx: number) => {
                    const st = item.trip.currentStatus;
                    const badge = STATUS_BADGE[st] || { cls: "badge bg-secondary", label: st };
                    const name = item.customer?.fullName || "—";
                    return (
                      <tr key={item.trip.id} data-testid={`trip-row-${item.trip.id}`}>
                        <td className="ps-4">
                          <span className="fw-semibold small" style={{ color: "#1a73e8" }}>{item.trip.refId}</span>
                        </td>
                        <td>
                          <div className="d-flex align-items-center gap-2">
                            <div className="d-flex align-items-center justify-content-center rounded-circle flex-shrink-0"
                              style={{ width: 30, height: 30, background: avatarBg(name), color: "white", fontSize: 11, fontWeight: 700 }}>
                              {initials(name)}
                            </div>
                            <span style={{ fontSize: 13 }}>{name}</span>
                          </div>
                        </td>
                        <td className="text-muted small">{item.vehicleCategory?.name || "—"}</td>
                        <td>
                          <span className="badge rounded-pill"
                            style={{ background: item.trip.type === "parcel" ? "#f0fdf4" : "#eff6ff", color: item.trip.type === "parcel" ? "#16a34a" : "#1d4ed8", fontSize: 10 }}>
                            {item.trip.type === "parcel" ? "📦 Parcel" : "🚗 Ride"}
                          </span>
                        </td>
                        <td className="fw-semibold small">₹{Number(item.trip.actualFare || item.trip.estimatedFare || 0).toFixed(0)}</td>
                        <td>
                          <span className={`badge ${item.trip.paymentStatus === "paid" ? "bg-success" : "bg-warning text-dark"}`} style={{ fontSize: 10 }}>
                            {item.trip.paymentStatus}
                          </span>
                        </td>
                        <td><span className={`${badge.cls}`} style={{ fontSize: 10 }}>{badge.label}</span></td>
                        <td className="text-muted small">{new Date(item.trip.createdAt).toLocaleDateString("en-IN")}</td>
                      </tr>
                    );
                  })
                ) : (
                  <tr><td colSpan={8}>
                    <div className="text-center py-4 text-muted">
                      <i className="bi bi-car-front fs-2 d-block mb-2"></i>No trips found
                    </div>
                  </td></tr>
                )}
              </tbody>
            </table>
          </div>
        </div>
      </div>

    </div>
  );
}
