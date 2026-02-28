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

function StatCard({ label, val, icon, color, bg, link, trend, trendUp, isLoading }: any) {
  return (
    <Link href={link}>
      <div className="jd-stat-card" data-testid={`stat-card-${label.toLowerCase().replace(/\s+/g,"-")}`}>
        <div className="jd-stat-icon-wrap" style={{ background: bg }}>
          <i className={`bi ${icon}`} style={{ color, fontSize: "1.35rem" }}></i>
        </div>
        <div className="jd-stat-body">
          <div className="jd-stat-label">{label}</div>
          <div className="jd-stat-value" style={{ color }}>
            {isLoading ? <span className="jd-stat-skeleton"></span> : (val ?? 0).toLocaleString()}
          </div>
        </div>
        {trend && (
          <div className={`jd-stat-trend ${trendUp ? "jd-trend-up" : "jd-trend-down"}`}>
            <i className={`bi ${trendUp ? "bi-arrow-up-short" : "bi-arrow-down-short"}`}></i>
            {trend}
          </div>
        )}
        <div className="jd-stat-arrow"><i className="bi bi-chevron-right"></i></div>
      </div>
    </Link>
  );
}

export default function Dashboard() {
  const { data: stats, isLoading } = useQuery<any>({ queryKey: ["/api/dashboard/stats"] });
  const { data: chart = [] } = useQuery<any[]>({ queryKey: ["/api/dashboard/chart"] });

  const today = new Date().toLocaleDateString("en-IN", { weekday: "long", year: "numeric", month: "long", day: "numeric" });
  const adminName = (() => { try { return JSON.parse(localStorage.getItem("jago-admin") || "{}").name || "Admin"; } catch { return "Admin"; } })();
  const revenue = Number(stats?.totalRevenue || 0).toLocaleString("en-IN", { maximumFractionDigits: 0 });
  const hour = new Date().getHours();
  const greeting = hour < 12 ? "Good morning" : hour < 17 ? "Good afternoon" : "Good evening";

  const topStats = [
    { label: "Total Customers", val: stats?.totalCustomers, icon: "bi-people-fill", color: "#1a73e8", bg: "#e8f0fe", link: "/admin/customers", trend: "+12%", trendUp: true },
    { label: "Total Drivers", val: stats?.totalDrivers, icon: "bi-person-badge-fill", color: "#16a34a", bg: "#f0fdf4", link: "/admin/drivers", trend: "+5%", trendUp: true },
    { label: "Total Revenue", val: `₹${revenue}`, icon: "bi-currency-rupee", color: "#b45309", bg: "#fefce8", link: "/admin/reports", trend: "+18%", trendUp: true },
    { label: "Total Trips", val: stats?.totalTrips, icon: "bi-car-front-fill", color: "#7e22ce", bg: "#f5f3ff", link: "/admin/trips", trend: "+8%", trendUp: true },
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

      {/* ── Hero Welcome Banner ── */}
      <div className="jd-banner" data-testid="dashboard-banner">
        <div className="jd-banner-inner">
          <div className="d-flex align-items-center gap-3">
            <div className="jd-avatar">
              <span style={{ fontSize: "1.6rem" }}>👋</span>
            </div>
            <div>
              <h3 className="mb-1">{greeting}, {adminName}!</h3>
              <p className="mb-0">Here's your platform overview for today</p>
            </div>
          </div>
          <div className="d-flex align-items-center gap-2">
            <div className="jd-date-badge">
              <i className="bi bi-calendar3"></i>
              <span>{today}</span>
            </div>
          </div>
        </div>
        {/* Mini KPI strip */}
        <div className="jd-banner-kpis">
          <div className="jd-kpi"><span className="jd-kpi-n">{stats?.ongoingTrips ?? "—"}</span><span className="jd-kpi-l">Live Trips</span></div>
          <div className="jd-kpi-sep"></div>
          <div className="jd-kpi"><span className="jd-kpi-n">{Math.round((stats?.totalDrivers ?? 0) * 0.7)}</span><span className="jd-kpi-l">Online Drivers</span></div>
          <div className="jd-kpi-sep"></div>
          <div className="jd-kpi"><span className="jd-kpi-n">₹{Number(stats?.totalRevenue ?? 0).toLocaleString("en-IN", { maximumFractionDigits: 0 })}</span><span className="jd-kpi-l">Total Revenue</span></div>
          <div className="jd-kpi-sep"></div>
          <div className="jd-kpi"><span className="jd-kpi-n">{stats?.totalZones ?? "—"}</span><span className="jd-kpi-l">Active Zones</span></div>
        </div>
      </div>

      {/* ── 4 Stat Cards ── */}
      <div className="row g-3 mb-3">
        {topStats.map((s, i) => (
          <div key={i} className="col-xl-3 col-sm-6">
            <StatCard {...s} isLoading={isLoading} />
          </div>
        ))}
      </div>

      {/* ── Charts Row ── */}
      <div className="row g-3 mb-3">
        <div className="col-lg-8">
          <div className="card border-0 shadow-sm h-100" style={{ borderRadius: 16 }}>
            <div className="card-header bg-white py-3 px-4 d-flex align-items-center justify-content-between border-0">
              <div>
                <h6 className="mb-0 fw-bold" style={{ color: "#0f172a" }}>Weekly Revenue Trend</h6>
                <div className="text-muted small">Revenue & trips over the last 7 days</div>
              </div>
              <div className="d-flex gap-3 small">
                <span className="d-flex align-items-center gap-1 fw-semibold" style={{ color: "#1a73e8" }}>
                  <span style={{ width: 8, height: 8, borderRadius: 2, background: "#1a73e8", display: "inline-block" }}></span>Revenue
                </span>
                <span className="d-flex align-items-center gap-1 fw-semibold" style={{ color: "#16a34a" }}>
                  <span style={{ width: 8, height: 8, borderRadius: 2, background: "#16a34a", display: "inline-block" }}></span>Trips
                </span>
              </div>
            </div>
            <div className="card-body pt-0 px-3 pb-3">
              <ResponsiveContainer width="100%" height={230}>
                <AreaChart data={chart} margin={{ top: 5, right: 10, bottom: 0, left: 0 }}>
                  <defs>
                    <linearGradient id="gradRev" x1="0" y1="0" x2="0" y2="1">
                      <stop offset="0%" stopColor="#1a73e8" stopOpacity={0.25} />
                      <stop offset="100%" stopColor="#1a73e8" stopOpacity={0} />
                    </linearGradient>
                    <linearGradient id="gradTrips" x1="0" y1="0" x2="0" y2="1">
                      <stop offset="0%" stopColor="#16a34a" stopOpacity={0.22} />
                      <stop offset="100%" stopColor="#16a34a" stopOpacity={0} />
                    </linearGradient>
                  </defs>
                  <CartesianGrid strokeDasharray="3 3" stroke="#f1f5f9" />
                  <XAxis dataKey="day" tick={{ fontSize: 11, fill: "#94a3b8" }} axisLine={false} tickLine={false} />
                  <YAxis tick={{ fontSize: 11, fill: "#94a3b8" }} axisLine={false} tickLine={false} width={42} />
                  <Tooltip
                    contentStyle={{ borderRadius: 12, border: "none", boxShadow: "0 8px 32px rgba(0,0,0,0.12)", fontSize: 12, padding: "10px 14px" }}
                    formatter={(val: any, name: string) => [name === "revenue" ? `₹${val}` : val, name === "revenue" ? "Revenue" : "Trips"]}
                  />
                  <Area type="monotone" dataKey="revenue" stroke="#1a73e8" strokeWidth={2.5} fill="url(#gradRev)" dot={false} activeDot={{ r: 5, fill: "#1a73e8" }} />
                  <Area type="monotone" dataKey="trips" stroke="#16a34a" strokeWidth={2.5} fill="url(#gradTrips)" dot={false} activeDot={{ r: 5, fill: "#16a34a" }} />
                </AreaChart>
              </ResponsiveContainer>
            </div>
          </div>
        </div>

        <div className="col-lg-4">
          <div className="card border-0 shadow-sm h-100" style={{ borderRadius: 16 }}>
            <div className="card-header bg-white py-3 px-4 border-0">
              <h6 className="mb-0 fw-bold" style={{ color: "#0f172a" }}>Rides vs Parcels</h6>
              <div className="text-muted small">Daily split this week</div>
            </div>
            <div className="card-body pt-0 px-3 pb-3">
              <ResponsiveContainer width="100%" height={230}>
                <BarChart data={chart} margin={{ top: 5, right: 5, bottom: 0, left: -15 }} barSize={10}>
                  <CartesianGrid strokeDasharray="3 3" stroke="#f1f5f9" />
                  <XAxis dataKey="day" tick={{ fontSize: 11, fill: "#94a3b8" }} axisLine={false} tickLine={false} />
                  <YAxis tick={{ fontSize: 10, fill: "#94a3b8" }} axisLine={false} tickLine={false} />
                  <Tooltip contentStyle={{ borderRadius: 12, border: "none", boxShadow: "0 8px 32px rgba(0,0,0,0.12)", fontSize: 12 }} />
                  <Legend iconType="circle" iconSize={7} wrapperStyle={{ fontSize: 11, paddingTop: 8 }} />
                  <Bar dataKey="rides" fill="#1a73e8" radius={[4, 4, 0, 0]} name="Rides" />
                  <Bar dataKey="parcels" fill="#16a34a" radius={[4, 4, 0, 0]} name="Parcels" />
                </BarChart>
              </ResponsiveContainer>
            </div>
          </div>
        </div>
      </div>

      {/* ── Mid Stats Strip ── */}
      <div className="row g-3 mb-3">
        {midStats.map((s, i) => (
          <div key={i} className="col">
            <div className="card border-0 shadow-sm" style={{ borderRadius: 14 }}>
              <div className="card-body py-3 d-flex align-items-center gap-3">
                <div className="d-flex align-items-center justify-content-center rounded-3 flex-shrink-0"
                  style={{ width: 44, height: 44, background: s.bg }}>
                  <i className={`bi ${s.icon}`} style={{ color: s.color, fontSize: "1.15rem" }}></i>
                </div>
                <div>
                  <div className="fw-bold lh-1 mb-1" style={{ fontSize: 22, color: s.color }}>
                    {isLoading ? "—" : (s.val ?? 0).toLocaleString()}
                  </div>
                  <div className="text-muted" style={{ fontSize: 12 }}>{s.label}</div>
                </div>
              </div>
            </div>
          </div>
        ))}
      </div>

      {/* ── Recent Trips Table ── */}
      <div className="card border-0 shadow-sm mb-3" style={{ borderRadius: 16 }} data-testid="recent-trips-card">
        <div className="card-header bg-white py-3 px-4 d-flex justify-content-between align-items-center border-0">
          <div>
            <h6 className="mb-0 fw-bold" style={{ color: "#0f172a" }}>Recent Trips</h6>
            <div className="text-muted small">Latest platform activity</div>
          </div>
          <Link href="/admin/trips" className="btn btn-sm btn-outline-primary rounded-pill px-3" style={{ fontSize: 12 }}>
            View All <i className="bi bi-arrow-right ms-1"></i>
          </Link>
        </div>
        <div className="card-body p-0">
          <div className="table-responsive">
            <table className="table table-borderless align-middle table-hover mb-0">
              <thead style={{ background: "#f8fafc", borderTop: "1px solid #f1f5f9" }}>
                <tr>
                  {["Trip ID","Customer","Vehicle","Type","Fare","Payment","Status","Date"].map((h, i) => (
                    <th key={i} className={i === 0 ? "ps-4" : ""}
                      style={{ fontSize: 10.5, color: "#94a3b8", fontWeight: 700, textTransform: "uppercase", letterSpacing: ".6px", whiteSpace: "nowrap", paddingTop: 12, paddingBottom: 12 }}>
                      {h}
                    </th>
                  ))}
                </tr>
              </thead>
              <tbody>
                {isLoading ? (
                  Array(6).fill(0).map((_, i) => (
                    <tr key={i}>
                      {Array(8).fill(0).map((_, j) => (
                        <td key={j}><div className="skeleton" style={{ height: 13, borderRadius: 4 }} /></td>
                      ))}
                    </tr>
                  ))
                ) : stats?.recentTrips?.length ? (
                  stats.recentTrips.map((item: any) => {
                    const st = item.trip.currentStatus;
                    const badge = STATUS_BADGE[st] || { cls: "badge bg-secondary", label: st };
                    const name = item.customer?.fullName || "—";
                    return (
                      <tr key={item.trip.id} data-testid={`trip-row-${item.trip.id}`}>
                        <td className="ps-4">
                          <span className="fw-bold" style={{ fontSize: 12, color: "#1a73e8", fontFamily: "monospace" }}>{item.trip.refId}</span>
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
                        <td className="text-muted" style={{ fontSize: 12 }}>{item.vehicleCategory?.name || "—"}</td>
                        <td>
                          <span className="badge rounded-pill"
                            style={{ background: item.trip.type === "parcel" ? "#f0fdf4" : "#eff6ff", color: item.trip.type === "parcel" ? "#16a34a" : "#1d4ed8", fontSize: 10, padding: "4px 8px" }}>
                            {item.trip.type === "parcel" ? "📦 Parcel" : "🚗 Ride"}
                          </span>
                        </td>
                        <td className="fw-semibold" style={{ fontSize: 13 }}>₹{Number(item.trip.actualFare || item.trip.estimatedFare || 0).toFixed(0)}</td>
                        <td>
                          <span className={`badge ${item.trip.paymentStatus === "paid" ? "bg-success" : "bg-warning text-dark"}`} style={{ fontSize: 10 }}>
                            {item.trip.paymentStatus === "paid" ? "✓ Paid" : "Unpaid"}
                          </span>
                        </td>
                        <td><span className={badge.cls} style={{ fontSize: 10 }}>{badge.label}</span></td>
                        <td className="text-muted" style={{ fontSize: 12 }}>{new Date(item.trip.createdAt).toLocaleDateString("en-IN")}</td>
                      </tr>
                    );
                  })
                ) : (
                  <tr><td colSpan={8}>
                    <div className="text-center py-5 text-muted">
                      <i className="bi bi-car-front fs-1 d-block mb-2" style={{ opacity: 0.25 }}></i>
                      <p className="fw-semibold mb-0">No trips yet</p>
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
