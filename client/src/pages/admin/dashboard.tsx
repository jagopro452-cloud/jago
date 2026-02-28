import { useQuery } from "@tanstack/react-query";
import { Link } from "wouter";
import { useState, useEffect } from "react";
import {
  AreaChart, Area, XAxis, YAxis, CartesianGrid, Tooltip,
  ResponsiveContainer, PieChart, Pie, Cell, Legend,
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

const NOTIF_ICONS: Record<string, { icon: string; color: string; bg: string }> = {
  trip:     { icon: "bi-car-front-fill",    color: "#1a73e8", bg: "#e8f0fe" },
  driver:   { icon: "bi-person-badge-fill", color: "#16a34a", bg: "#f0fdf4" },
  payment:  { icon: "bi-cash-stack",        color: "#d97706", bg: "#fefce8" },
  alert:    { icon: "bi-exclamation-triangle-fill", color: "#dc2626", bg: "#fef2f2" },
  user:     { icon: "bi-person-plus-fill",  color: "#7c3aed", bg: "#f5f3ff" },
  withdraw: { icon: "bi-wallet2",           color: "#0891b2", bg: "#ecfeff" },
};

function LiveClock() {
  const [time, setTime] = useState(new Date());
  useEffect(() => {
    const t = setInterval(() => setTime(new Date()), 1000);
    return () => clearInterval(t);
  }, []);
  const h = time.getHours().toString().padStart(2, "0");
  const m = time.getMinutes().toString().padStart(2, "0");
  const s = time.getSeconds().toString().padStart(2, "0");
  const ampm = time.getHours() >= 12 ? "PM" : "AM";
  const date = time.toLocaleDateString("en-IN", { weekday: "short", day: "2-digit", month: "short", year: "numeric" });

  return (
    <div style={{
      background: "linear-gradient(135deg, #1a1a2e 0%, #16213e 50%, #0f3460 100%)",
      borderRadius: 16, padding: "20px 18px", color: "white", textAlign: "center", marginBottom: 14,
    }}>
      <div style={{ fontSize: 10, letterSpacing: 3, color: "rgba(255,255,255,0.5)", textTransform: "uppercase", marginBottom: 6 }}>Live Time</div>
      <div style={{ fontSize: 34, fontWeight: 800, letterSpacing: 2, fontFamily: "monospace", lineHeight: 1 }}>
        {h}:{m}<span style={{ fontSize: 24, opacity: 0.7 }}>:{s}</span>
        <span style={{ fontSize: 14, marginLeft: 6, fontWeight: 600, color: "#60a5fa" }}>{ampm}</span>
      </div>
      <div style={{ fontSize: 11, color: "rgba(255,255,255,0.55)", marginTop: 6 }}>{date}</div>
      <div style={{ display: "flex", justifyContent: "center", gap: 4, marginTop: 10 }}>
        {[0,1,2,3,4,5,6,7].map(i => (
          <div key={i} style={{ width: 3, height: i % 3 === 0 ? 18 : i % 2 === 0 ? 12 : 8, background: `rgba(96,165,250,${0.3 + (i % 4) * 0.15})`, borderRadius: 2 }} />
        ))}
      </div>
    </div>
  );
}

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

const CUSTOM_LABEL = ({ cx, cy, midAngle, innerRadius, outerRadius, percent, name }: any) => {
  if (percent < 0.06) return null;
  const RADIAN = Math.PI / 180;
  const radius = innerRadius + (outerRadius - innerRadius) * 0.5;
  const x = cx + radius * Math.cos(-midAngle * RADIAN);
  const y = cy + radius * Math.sin(-midAngle * RADIAN);
  return (
    <text x={x} y={y} fill="white" textAnchor="middle" dominantBaseline="central" fontSize={10} fontWeight={700}>
      {`${(percent * 100).toFixed(0)}%`}
    </text>
  );
};

export default function Dashboard() {
  const { data: stats, isLoading } = useQuery<any>({ queryKey: ["/api/dashboard/stats"] });
  const { data: chart = [] } = useQuery<any[]>({ queryKey: ["/api/dashboard/chart"] });
  const { data: notifs = [] } = useQuery<any[]>({ queryKey: ["/api/notifications"] });

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

  const pieData = [
    { name: "Completed", value: stats?.completedTrips || 0, color: "#16a34a" },
    { name: "Ongoing",   value: stats?.ongoingTrips || 0,   color: "#2563eb" },
    { name: "Cancelled", value: stats?.cancelledTrips || 0, color: "#dc2626" },
    { name: "Other",     value: Math.max(0, (stats?.totalTrips || 0) - (stats?.completedTrips || 0) - (stats?.ongoingTrips || 0) - (stats?.cancelledTrips || 0)), color: "#94a3b8" },
  ].filter(d => d.value > 0);

  const quickLinks = [
    { label: "All Trips", icon: "bi-car-front", href: "/admin/trips", color: "#1a73e8" },
    { label: "Drivers", icon: "bi-person-badge", href: "/admin/drivers", color: "#16a34a" },
    { label: "Withdrawals", icon: "bi-cash-coin", href: "/admin/withdrawals", color: "#d97706" },
    { label: "Reports", icon: "bi-graph-up", href: "/admin/reports", color: "#7c3aed" },
  ];

  const recentNotifs = Array.isArray(notifs) ? notifs.slice(0, 12) : [];

  const timeAgo = (d: string) => {
    const s = Math.floor((Date.now() - new Date(d).getTime()) / 1000);
    if (s < 60) return `${s}s ago`;
    if (s < 3600) return `${Math.floor(s/60)}m ago`;
    if (s < 86400) return `${Math.floor(s/3600)}h ago`;
    return `${Math.floor(s/86400)}d ago`;
  };

  return (
    <div className="container-fluid">

      {/* ── FULL WIDTH BANNER ── */}
      <div className="jd-banner mb-3" data-testid="dashboard-banner">
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
        <div className="jd-banner-kpis">
          <div className="jd-kpi"><span className="jd-kpi-n">{stats?.ongoingTrips ?? "—"}</span><span className="jd-kpi-l">Live Trips</span></div>
          <div className="jd-kpi-sep"></div>
          <div className="jd-kpi"><span className="jd-kpi-n">{Math.round((stats?.totalDrivers ?? 0) * 0.7)}</span><span className="jd-kpi-l">Online Pilots</span></div>
          <div className="jd-kpi-sep"></div>
          <div className="jd-kpi"><span className="jd-kpi-n">₹{Number(stats?.totalRevenue ?? 0).toLocaleString("en-IN", { maximumFractionDigits: 0 })}</span><span className="jd-kpi-l">Total Revenue</span></div>
          <div className="jd-kpi-sep"></div>
          <div className="jd-kpi"><span className="jd-kpi-n">{stats?.totalZones ?? "—"}</span><span className="jd-kpi-l">Active Zones</span></div>
        </div>
      </div>

      {/* ── TWO COLUMN LAYOUT ── */}
      <div className="row g-3">

        {/* ── LEFT MAIN CONTENT ── */}
        <div className="col-xl-8 col-lg-8">

          {/* 4 Stat Cards */}
          <div className="row g-3 mb-3">
            {topStats.map((s, i) => (
              <div key={i} className="col-xl-6 col-sm-6">
                <StatCard {...s} isLoading={isLoading} />
              </div>
            ))}
          </div>

          {/* Charts Row */}
          <div className="row g-3 mb-3">
            {/* Area Chart */}
            <div className="col-lg-7">
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
                  <ResponsiveContainer width="100%" height={200}>
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

            {/* Pie Chart — Trip Status */}
            <div className="col-lg-5">
              <div className="card border-0 shadow-sm h-100" style={{ borderRadius: 16 }}>
                <div className="card-header bg-white py-3 px-4 border-0">
                  <h6 className="mb-0 fw-bold" style={{ color: "#0f172a" }}>Trip Distribution</h6>
                  <div className="text-muted small">Status breakdown</div>
                </div>
                <div className="card-body pt-0 px-3 pb-2 d-flex flex-column align-items-center">
                  {pieData.length > 0 ? (
                    <ResponsiveContainer width="100%" height={200}>
                      <PieChart>
                        <Pie
                          data={pieData}
                          cx="50%"
                          cy="45%"
                          innerRadius={50}
                          outerRadius={78}
                          paddingAngle={3}
                          dataKey="value"
                          labelLine={false}
                          label={CUSTOM_LABEL}
                        >
                          {pieData.map((entry, i) => (
                            <Cell key={i} fill={entry.color} />
                          ))}
                        </Pie>
                        <Tooltip formatter={(val: any, name: string) => [`${val} trips`, name]} contentStyle={{ borderRadius: 10, fontSize: 12 }} />
                        <Legend iconType="circle" iconSize={8} wrapperStyle={{ fontSize: 11, paddingTop: 4 }} />
                      </PieChart>
                    </ResponsiveContainer>
                  ) : (
                    <div className="d-flex flex-column align-items-center justify-content-center" style={{ height: 200, color: "#cbd5e1" }}>
                      <i className="bi bi-pie-chart fs-1 mb-2"></i>
                      <span style={{ fontSize: 12 }}>No trip data yet</span>
                    </div>
                  )}
                </div>
              </div>
            </div>
          </div>

          {/* Recent Trips Table */}
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

        {/* ── RIGHT PANEL — Notifications + Time ── */}
        <div className="col-xl-4 col-lg-4">

          {/* Live Clock */}
          <LiveClock />

          {/* Quick Stats Mini */}
          <div className="card border-0 shadow-sm mb-3" style={{ borderRadius: 16 }}>
            <div className="card-body p-3">
              <div style={{ fontSize: 10, fontWeight: 700, color: "#94a3b8", textTransform: "uppercase", letterSpacing: 1, marginBottom: 10 }}>
                Quick Stats
              </div>
              <div className="row g-2">
                {[
                  { label: "Completed", val: stats?.completedTrips ?? 0, color: "#16a34a", bg: "#f0fdf4", icon: "bi-check-circle-fill" },
                  { label: "Ongoing", val: stats?.ongoingTrips ?? 0, color: "#2563eb", bg: "#eff6ff", icon: "bi-broadcast-pin" },
                  { label: "Cancelled", val: stats?.cancelledTrips ?? 0, color: "#dc2626", bg: "#fef2f2", icon: "bi-x-circle-fill" },
                  { label: "Withdrawals", val: stats?.pendingWithdrawals ?? 0, color: "#d97706", bg: "#fefce8", icon: "bi-clock-history" },
                  { label: "Reviews", val: stats?.totalReviews ?? 0, color: "#f59e0b", bg: "#fffbeb", icon: "bi-star-fill" },
                  { label: "Zones", val: stats?.totalZones ?? 0, color: "#7c3aed", bg: "#f5f3ff", icon: "bi-map-fill" },
                ].map((s, i) => (
                  <div key={i} className="col-6">
                    <div style={{ background: s.bg, borderRadius: 10, padding: "10px 12px", display: "flex", alignItems: "center", gap: 8 }}>
                      <i className={`bi ${s.icon}`} style={{ color: s.color, fontSize: 16 }}></i>
                      <div>
                        <div style={{ fontSize: 17, fontWeight: 800, color: s.color, lineHeight: 1 }}>{isLoading ? "—" : s.val}</div>
                        <div style={{ fontSize: 10, color: "#64748b", marginTop: 1 }}>{s.label}</div>
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          </div>

          {/* Quick Links */}
          <div className="card border-0 shadow-sm mb-3" style={{ borderRadius: 16 }}>
            <div className="card-body p-3">
              <div style={{ fontSize: 10, fontWeight: 700, color: "#94a3b8", textTransform: "uppercase", letterSpacing: 1, marginBottom: 10 }}>
                Quick Actions
              </div>
              <div className="row g-2">
                {quickLinks.map((l, i) => (
                  <div key={i} className="col-6">
                    <Link href={l.href}>
                      <div style={{
                        border: `1.5px solid ${l.color}22`,
                        borderRadius: 10, padding: "10px 12px",
                        display: "flex", alignItems: "center", gap: 8,
                        cursor: "pointer", transition: "all 0.18s",
                        background: "white",
                      }}
                        onMouseEnter={e => (e.currentTarget.style.background = `${l.color}10`)}
                        onMouseLeave={e => (e.currentTarget.style.background = "white")}
                      >
                        <div style={{ width: 30, height: 30, borderRadius: 8, background: `${l.color}15`, display: "flex", alignItems: "center", justifyContent: "center", flexShrink: 0 }}>
                          <i className={`bi ${l.icon}`} style={{ color: l.color, fontSize: 14 }}></i>
                        </div>
                        <span style={{ fontSize: 12, fontWeight: 600, color: "#1e293b" }}>{l.label}</span>
                      </div>
                    </Link>
                  </div>
                ))}
              </div>
            </div>
          </div>

          {/* Notifications Feed */}
          <div className="card border-0 shadow-sm" style={{ borderRadius: 16 }}>
            <div className="card-header bg-white py-3 px-3 border-0 d-flex align-items-center justify-content-between">
              <div>
                <h6 className="mb-0 fw-bold" style={{ color: "#0f172a", fontSize: 14 }}>
                  <i className="bi bi-bell-fill me-2" style={{ color: "#1a73e8" }}></i>
                  Notifications
                </h6>
              </div>
              <Link href="/admin/notifications">
                <span style={{ fontSize: 11, color: "#1a73e8", cursor: "pointer", fontWeight: 600 }}>View all</span>
              </Link>
            </div>
            <div className="card-body p-0" style={{ maxHeight: 420, overflowY: "auto" }}>
              {recentNotifs.length === 0 ? (
                <div className="text-center py-5 text-muted">
                  <i className="bi bi-bell-slash fs-2 d-block mb-2" style={{ opacity: 0.3 }}></i>
                  <span style={{ fontSize: 12 }}>No notifications yet</span>
                </div>
              ) : (
                recentNotifs.map((n: any, i: number) => {
                  const type = n.type || "trip";
                  const style = NOTIF_ICONS[type] || NOTIF_ICONS.trip;
                  return (
                    <div key={n.id || i} style={{
                      display: "flex", alignItems: "flex-start", gap: 10,
                      padding: "12px 14px",
                      borderBottom: i < recentNotifs.length - 1 ? "1px solid #f8fafc" : "none",
                      background: n.isRead === false ? "#f8fbff" : "white",
                    }}>
                      <div style={{ width: 34, height: 34, borderRadius: 10, background: style.bg, display: "flex", alignItems: "center", justifyContent: "center", flexShrink: 0 }}>
                        <i className={`bi ${style.icon}`} style={{ color: style.color, fontSize: 14 }}></i>
                      </div>
                      <div style={{ flex: 1, minWidth: 0 }}>
                        <div style={{ fontSize: 12, fontWeight: 600, color: "#1e293b", lineHeight: 1.3, marginBottom: 2 }}>{n.title || "Notification"}</div>
                        <div style={{ fontSize: 11, color: "#64748b", lineHeight: 1.4, overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap" }}>{n.message || n.body || ""}</div>
                      </div>
                      <div style={{ fontSize: 10, color: "#94a3b8", whiteSpace: "nowrap", marginTop: 2 }}>
                        {n.createdAt ? timeAgo(n.createdAt) : ""}
                      </div>
                    </div>
                  );
                })
              )}
            </div>
          </div>

        </div>
      </div>
    </div>
  );
}
