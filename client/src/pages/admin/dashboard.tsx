import { useQuery } from "@tanstack/react-query";
import { Link } from "wouter";
import { useState, useEffect } from "react";
import {
  AreaChart, Area, XAxis, YAxis, CartesianGrid, Tooltip,
  ResponsiveContainer, PieChart, Pie, Cell, Legend,
} from "recharts";

const avatarBg = (name: string) => {
  const colors = ["#2F80ED","#16a34a","#d97706","#9333ea","#0891b2","#dc2626"];
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
  trip:     { icon: "bi-car-front-fill",    color: "#2F80ED", bg: "#EBF4FF" },
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
      background: "linear-gradient(135deg, #1a3d7c 0%, #1a5abf 50%, #2F80ED 100%)",
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
  const { data: svcData } = useQuery<any>({ queryKey: ["/api/admin/dashboard"], staleTime: 30_000 });
  const { data: chart = [] } = useQuery<any[]>({ queryKey: ["/api/dashboard/chart"] });
  const { data: notifs = [] } = useQuery<any[]>({ queryKey: ["/api/notifications"] });

  const today = new Date().toLocaleDateString("en-IN", { weekday: "long", year: "numeric", month: "long", day: "numeric" });
  const adminName = (() => { try { return JSON.parse(localStorage.getItem("jago-admin") || "{}").name || "Admin"; } catch { return "Admin"; } })();
  const revenue = Number(stats?.totalRevenue || 0).toLocaleString("en-IN", { maximumFractionDigits: 0 });
  const hour = new Date().getHours();
  const greeting = hour < 12 ? "Good morning" : hour < 17 ? "Good afternoon" : "Good evening";

  const topStats = [
    { label: "Total Customers", val: stats?.totalCustomers, icon: "bi-people-fill", color: "#2F80ED", bg: "#EBF4FF", link: "/admin/customers", trend: "+12%", trendUp: true },
    { label: "Total Drivers", val: stats?.totalDrivers, icon: "bi-person-badge-fill", color: "#16a34a", bg: "#f0fdf4", link: "/admin/drivers", trend: "+5%", trendUp: true },
    { label: "Total Revenue", val: `₹${revenue}`, icon: "bi-currency-rupee", color: "#b45309", bg: "#fefce8", link: "/admin/reports", trend: "+18%", trendUp: true },
    { label: "Total Trips", val: stats?.totalTrips, icon: "bi-car-front-fill", color: "#7e22ce", bg: "#f5f3ff", link: "/admin/trips", trend: "+8%", trendUp: true },
  ];

  const pieData = [
    { name: "Completed", value: stats?.completedTrips || 0, color: "#2ECC71" },
    { name: "Ongoing",   value: stats?.ongoingTrips || 0,   color: "#2F80ED" },
    { name: "Cancelled", value: stats?.cancelledTrips || 0, color: "#E74C3C" },
    { name: "Other",     value: Math.max(0, (stats?.totalTrips || 0) - (stats?.completedTrips || 0) - (stats?.ongoingTrips || 0) - (stats?.cancelledTrips || 0)), color: "#94a3b8" },
  ].filter(d => d.value > 0);

  const quickLinks = [
    { label: "All Trips", icon: "bi-car-front", href: "/admin/trips", color: "#2F80ED" },
    { label: "Drivers", icon: "bi-person-badge", href: "/admin/drivers", color: "#16a34a" },
    { label: "Withdrawals", icon: "bi-cash-coin", href: "/admin/withdrawals", color: "#d97706" },
    { label: "Reports", icon: "bi-graph-up", href: "/admin/reports", color: "#7c3aed" },
    { label: "Customer APK", icon: "bi-android2", href: "/apks/jago-customer-v1.0.30.apk", color: "#16a34a", external: true },
    { label: "Driver APK", icon: "bi-android2", href: "/apks/jago-driver-v1.0.30.apk", color: "#0891b2", external: true },
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
    <div className="container-fluid admin-dashboard-page">

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

          {/* Services Overview */}
          {(() => {
            const svc = svcData?.services;
            const drv = svcData?.drivers;
            const services = [
              {
                label: "City Rides", icon: "bi-car-front-fill", color: "#2F80ED", bg: "#eff6ff",
                trips: svc?.rides?.trips ?? 0,
                revenue: svc?.rides?.revenue ?? 0,
                model: svc?.rides?.model ?? "subscription",
                href: "/admin/trips",
              },
              {
                label: "Parcels", icon: "bi-box-seam-fill", color: "#16a34a", bg: "#f0fdf4",
                trips: svc?.parcels?.trips ?? 0,
                revenue: svc?.parcels?.revenue ?? 0,
                model: svc?.parcels?.model ?? "commission",
                href: "/admin/parcel-trips",
              },
              {
                label: "Intercity Carpool", icon: "bi-people-fill", color: "#7c3aed", bg: "#f5f3ff",
                trips: svc?.carpool?.trips ?? 0,
                revenue: svc?.carpool?.revenue ?? 0,
                model: svc?.carpool?.model ?? "commission",
                href: "/admin/intercity-carsharing",
              },
              {
                label: "Outstation Pool", icon: "bi-signpost-2-fill", color: "#d97706", bg: "#fefce8",
                trips: svc?.outstationPool?.bookings ?? 0,
                revenue: svc?.outstationPool?.revenue ?? 0,
                model: svc?.outstationPool?.mode === "on" ? "active" : "inactive",
                modelColor: svc?.outstationPool?.mode === "on" ? "#16a34a" : "#94a3b8",
                href: "/admin/outstation-pool",
              },
            ];
            const pendingComm = drv?.totalPendingCommission ?? 0;
            return (
              <>
                <div className="mb-2 mt-1" style={{ display: "flex", alignItems: "center", justifyContent: "space-between" }}>
                  <span style={{ fontSize: 11, fontWeight: 700, color: "#94a3b8", textTransform: "uppercase", letterSpacing: 1 }}>Services Overview</span>
                  {pendingComm > 0 && (
                    <span style={{ fontSize: 11, background: "#fef2f2", color: "#dc2626", border: "1px solid #fecaca", borderRadius: 8, padding: "3px 10px", fontWeight: 700 }}>
                      ₹{pendingComm.toLocaleString("en-IN", { maximumFractionDigits: 0 })} pending commission
                    </span>
                  )}
                </div>
                <div className="row g-3 mb-3">
                  {services.map((s, i) => (
                    <div key={i} className="col-xl-3 col-sm-6">
                      <Link href={s.href}>
                        <div style={{
                          background: "white", borderRadius: 14, padding: "14px 16px",
                          boxShadow: "0 1px 4px rgba(0,0,0,0.07)",
                          border: `1.5px solid ${s.color}18`,
                          cursor: "pointer", transition: "box-shadow 0.18s",
                        }}
                          onMouseEnter={e => (e.currentTarget.style.boxShadow = `0 4px 16px ${s.color}22`)}
                          onMouseLeave={e => (e.currentTarget.style.boxShadow = "0 1px 4px rgba(0,0,0,0.07)")}
                        >
                          <div style={{ display: "flex", alignItems: "center", gap: 10, marginBottom: 10 }}>
                            <div style={{ width: 36, height: 36, borderRadius: 10, background: s.bg, display: "flex", alignItems: "center", justifyContent: "center" }}>
                              <i className={`bi ${s.icon}`} style={{ color: s.color, fontSize: 16 }}></i>
                            </div>
                            <div style={{ flex: 1 }}>
                              <div style={{ fontSize: 12, fontWeight: 700, color: "#1e293b" }}>{s.label}</div>
                              <div style={{ fontSize: 10, color: (s as any).modelColor ?? s.color, fontWeight: 600, textTransform: "capitalize" }}>{s.model}</div>
                            </div>
                          </div>
                          <div style={{ display: "flex", justifyContent: "space-between" }}>
                            <div>
                              <div style={{ fontSize: 18, fontWeight: 800, color: s.color, lineHeight: 1 }}>{svcData ? s.trips.toLocaleString() : "—"}</div>
                              <div style={{ fontSize: 10, color: "#94a3b8", marginTop: 2 }}>trips</div>
                            </div>
                            <div style={{ textAlign: "right" }}>
                              <div style={{ fontSize: 14, fontWeight: 700, color: "#0f172a", lineHeight: 1 }}>₹{svcData ? s.revenue.toLocaleString("en-IN", { maximumFractionDigits: 0 }) : "—"}</div>
                              <div style={{ fontSize: 10, color: "#94a3b8", marginTop: 2 }}>revenue</div>
                            </div>
                          </div>
                        </div>
                      </Link>
                    </div>
                  ))}
                </div>
              </>
            );
          })()}

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
                    <span className="d-flex align-items-center gap-1 fw-semibold" style={{ color: "#2F80ED" }}>
                      <span style={{ width: 8, height: 8, borderRadius: 2, background: "#2F80ED", display: "inline-block" }}></span>Revenue
                    </span>
                    <span className="d-flex align-items-center gap-1 fw-semibold" style={{ color: "#16a34a" }}>
                      <span style={{ width: 8, height: 8, borderRadius: 2, background: "#16a34a", display: "inline-block" }}></span>Trips
                    </span>
                  </div>
                </div>
                <div className="card-body pt-0 px-3 pb-3">
                  {chart.length > 0 ? (
                    <ResponsiveContainer width="100%" height={200}>
                      <AreaChart data={chart} margin={{ top: 5, right: 10, bottom: 0, left: 0 }}>
                        <defs>
                          <linearGradient id="gradRev" x1="0" y1="0" x2="0" y2="1">
                            <stop offset="0%" stopColor="#2F80ED" stopOpacity={0.25} />
                            <stop offset="100%" stopColor="#2F80ED" stopOpacity={0} />
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
                        <Area type="monotone" dataKey="revenue" stroke="#2F80ED" strokeWidth={2.5} fill="url(#gradRev)" dot={false} activeDot={{ r: 5, fill: "#2F80ED" }} />
                        <Area type="monotone" dataKey="trips" stroke="#16a34a" strokeWidth={2.5} fill="url(#gradTrips)" dot={false} activeDot={{ r: 5, fill: "#16a34a" }} />
                      </AreaChart>
                    </ResponsiveContainer>
                  ) : (
                    <div style={{ height: 200, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 12 }}>
                      {/* SVG empty state illustration */}
                      <svg width="120" height="70" viewBox="0 0 120 70" fill="none" style={{ opacity: 0.18 }}>
                        <path d="M8 60 Q20 20 35 35 Q50 50 65 20 Q80 -10 95 30 Q105 55 112 40" stroke="#2F80ED" strokeWidth="2.5" strokeLinecap="round" fill="none"/>
                        <path d="M8 62 Q20 22 35 37 Q50 52 65 22 Q80 -8 95 32 Q105 57 112 42 L112 65 L8 65Z" fill="#2F80ED" fillOpacity="0.12"/>
                        <path d="M8 60 Q25 50 40 55 Q55 60 70 45 Q85 30 112 55" stroke="#16a34a" strokeWidth="2" strokeLinecap="round" strokeDasharray="4 3" fill="none"/>
                        {[15,40,65,90].map((x,i) => (
                          <line key={i} x1={x} y1="10" x2={x} y2="62" stroke="#e2e8f0" strokeWidth="1"/>
                        ))}
                        {[20,40,60].map((y,i) => (
                          <line key={i} x1="8" y1={y} x2="112" y2={y} stroke="#e2e8f0" strokeWidth="1"/>
                        ))}
                      </svg>
                      <div style={{ textAlign: "center" }}>
                        <div style={{ fontSize: 13, fontWeight: 700, color: "#64748B", marginBottom: 4 }}>No analytics yet</div>
                        <div style={{ fontSize: 11, color: "#94a3b8", maxWidth: 220, lineHeight: 1.5 }}>Data will appear here once trips are completed on the platform</div>
                      </div>
                      <div style={{ display: "flex", gap: 12 }}>
                        <div style={{ display: "flex", alignItems: "center", gap: 6, background: "#eff6ff", borderRadius: 8, padding: "6px 12px" }}>
                          <div style={{ width: 8, height: 8, borderRadius: 2, background: "#2F80ED" }}></div>
                          <span style={{ fontSize: 11, fontWeight: 600, color: "#2F80ED" }}>Revenue</span>
                        </div>
                        <div style={{ display: "flex", alignItems: "center", gap: 6, background: "#f0fdf4", borderRadius: 8, padding: "6px 12px" }}>
                          <div style={{ width: 8, height: 8, borderRadius: 2, background: "#16a34a" }}></div>
                          <span style={{ fontSize: 11, fontWeight: 600, color: "#16a34a" }}>Trips</span>
                        </div>
                      </div>
                    </div>
                  )}
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
                              <span className="fw-bold" style={{ fontSize: 12, color: "#2F80ED", fontFamily: "monospace" }}>{item.trip.refId}</span>
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
                        <div className="d-flex flex-column align-items-center justify-content-center py-5">
                          <div style={{ width: 72, height: 72, borderRadius: "50%", background: "linear-gradient(135deg,#eff6ff,#dbeafe)", display: "flex", alignItems: "center", justifyContent: "center", marginBottom: 16 }}>
                            <i className="bi bi-car-front" style={{ fontSize: 32, color: "#93c5fd" }}></i>
                          </div>
                          <h6 className="fw-bold mb-1" style={{ color: "#0f172a" }}>No Trips Yet</h6>
                          <p className="text-muted mb-3" style={{ fontSize: 13, maxWidth: 260, textAlign: "center", lineHeight: 1.5 }}>
                            Trips will appear here once customers book rides through the JAGO app
                          </p>
                          <div style={{ display: "flex", gap: 8 }}>
                            <span style={{ background: "#f0fdf4", border: "1px solid #bbf7d0", color: "#16a34a", borderRadius: 8, padding: "4px 12px", fontSize: 11, fontWeight: 700 }}>
                              ✓ Platform Ready
                            </span>
                            <span style={{ background: "#eff6ff", border: "1px solid #bfdbfe", color: "#1d4ed8", borderRadius: 8, padding: "4px 12px", fontSize: 11, fontWeight: 700 }}>
                              Waiting for First Trip
                            </span>
                          </div>
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
                  { label: "Completed", val: stats?.completedTrips ?? 0, color: "#2ECC71", bg: "#f0fdf4", icon: "bi-check-circle-fill" },
                  { label: "Ongoing", val: stats?.ongoingTrips ?? 0, color: "#2F80ED", bg: "#eff6ff", icon: "bi-broadcast-pin" },
                  { label: "Cancelled", val: stats?.cancelledTrips ?? 0, color: "#E74C3C", bg: "#fef2f2", icon: "bi-x-circle-fill" },
                  { label: "Withdrawals", val: stats?.pendingWithdrawals ?? 0, color: "#F39C12", bg: "#fefce8", icon: "bi-clock-history" },
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
                    {l.external ? (
                      <a href={l.href} download style={{ textDecoration: "none" }}>
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
                      </a>
                    ) : (
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
                    )}
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
                  <i className="bi bi-bell-fill me-2" style={{ color: "#2F80ED" }}></i>
                  Notifications
                </h6>
              </div>
              <Link href="/admin/notifications">
                <span style={{ fontSize: 11, color: "#2F80ED", cursor: "pointer", fontWeight: 600 }}>View all</span>
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
