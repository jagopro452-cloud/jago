import { useQuery } from "@tanstack/react-query";

const statusBadge: Record<string, { cls: string; label: string }> = {
  completed: { cls: "badge bg-success", label: "Completed" },
  ongoing: { cls: "badge bg-info", label: "Ongoing" },
  pending: { cls: "badge bg-warning text-dark", label: "Pending" },
  cancelled: { cls: "badge bg-danger", label: "Cancelled" },
  accepted: { cls: "badge bg-primary", label: "Accepted" },
};

export default function Dashboard() {
  const { data: stats, isLoading } = useQuery<any>({ queryKey: ["/api/dashboard/stats"] });

  const today = new Date().toLocaleDateString("en-IN", {
    weekday: "long", year: "numeric", month: "long", day: "numeric"
  });

  const adminName = (() => {
    try {
      return JSON.parse(localStorage.getItem("jago-admin") || "{}").name || "Admin";
    } catch { return "Admin"; }
  })();

  const revenue = Number(stats?.totalRevenue || 0).toLocaleString("en-IN", { maximumFractionDigits: 0 });

  return (
    <div className="container-fluid">

      {/* jd-banner */}
      <div className="jd-banner" data-testid="dashboard-banner">
        <div className="jd-banner-inner">
          <div className="d-flex align-items-center gap-3">
            <div className="jd-avatar">
              <i className="bi bi-person-fill"></i>
            </div>
            <div>
              <h3 className="mb-1">Good day, {adminName}!</h3>
              <p>Here&apos;s what&apos;s happening with your ride platform today.</p>
            </div>
          </div>
          <div className="jd-date-badge">
            <i className="bi bi-calendar3"></i>
            <span>{today}</span>
          </div>
        </div>
      </div>

      {/* 4 Stat Cards */}
      <div className="row g-3 mb-4">
        <div className="col-xl-3 col-sm-6">
          <div className="card jd-stat jd-stat-blue" data-testid="stat-total-customers">
            <div className="card-body">
              <div className="d-flex align-items-center gap-3 mb-3">
                <div className="jd-s-icon rounded-circle d-flex align-items-center justify-content-center" style={{ width: "48px", height: "48px", fontSize: "1.25rem" }}>
                  <i className="bi bi-people-fill"></i>
                </div>
                <div>
                  <div className="fs-12 text-muted text-uppercase fw-semibold">Total Customers</div>
                  <h3 className="mb-0 fw-bold" style={{ color: "#1e40af" }} data-testid="stat-value-total-customers">
                    {isLoading ? "—" : (stats?.totalCustomers || 0).toLocaleString()}
                  </h3>
                </div>
              </div>
              <div className="fs-12" style={{ color: "#3b82f6" }}>Registered users</div>
            </div>
          </div>
        </div>

        <div className="col-xl-3 col-sm-6">
          <div className="card jd-stat jd-stat-green" data-testid="stat-total-drivers">
            <div className="card-body">
              <div className="d-flex align-items-center gap-3 mb-3">
                <div className="jd-s-icon rounded-circle d-flex align-items-center justify-content-center" style={{ width: "48px", height: "48px", fontSize: "1.25rem" }}>
                  <i className="bi bi-person-badge-fill"></i>
                </div>
                <div>
                  <div className="fs-12 text-muted text-uppercase fw-semibold">Total Drivers</div>
                  <h3 className="mb-0 fw-bold" style={{ color: "#15803d" }} data-testid="stat-value-total-drivers">
                    {isLoading ? "—" : (stats?.totalDrivers || 0).toLocaleString()}
                  </h3>
                </div>
              </div>
              <div className="fs-12" style={{ color: "#16a34a" }}>Active partners</div>
            </div>
          </div>
        </div>

        <div className="col-xl-3 col-sm-6">
          <div className="card jd-stat jd-stat-amber" data-testid="stat-total-revenue">
            <div className="card-body">
              <div className="d-flex align-items-center gap-3 mb-3">
                <div className="jd-s-icon rounded-circle d-flex align-items-center justify-content-center" style={{ width: "48px", height: "48px", fontSize: "1.25rem" }}>
                  <i className="bi bi-currency-rupee"></i>
                </div>
                <div>
                  <div className="fs-12 text-muted text-uppercase fw-semibold">Total Earning</div>
                  <h3 className="mb-0 fw-bold" style={{ color: "#b45309" }} data-testid="stat-value-total-earning">
                    {isLoading ? "—" : `₹${revenue}`}
                  </h3>
                </div>
              </div>
              <div className="fs-12" style={{ color: "#d97706" }}>From completed trips</div>
            </div>
          </div>
        </div>

        <div className="col-xl-3 col-sm-6">
          <div className="card jd-stat jd-stat-purple" data-testid="stat-total-trips">
            <div className="card-body">
              <div className="d-flex align-items-center gap-3 mb-3">
                <div className="jd-s-icon rounded-circle d-flex align-items-center justify-content-center" style={{ width: "48px", height: "48px", fontSize: "1.25rem" }}>
                  <i className="bi bi-car-front-fill"></i>
                </div>
                <div>
                  <div className="fs-12 text-muted text-uppercase fw-semibold">Total Trips</div>
                  <h3 className="mb-0 fw-bold" style={{ color: "#7e22ce" }} data-testid="stat-value-total-trips">
                    {isLoading ? "—" : (stats?.totalTrips || 0).toLocaleString()}
                  </h3>
                </div>
              </div>
              <div className="fs-12" style={{ color: "#9333ea" }}>All time trips</div>
            </div>
          </div>
        </div>
      </div>

      {/* Ride Summary Cards */}
      <div className="row g-3 mb-4">
        <div className="col-lg-3 col-sm-6">
          <div className="card jd-ride-card jd-ride-green">
            <div className="card-body">
              <div className="d-flex align-items-center gap-3">
                <div style={{ width: "44px", height: "44px", borderRadius: "12px", background: "rgba(22,163,74,0.1)", display: "flex", alignItems: "center", justifyContent: "center", fontSize: "1.2rem", color: "#16a34a" }}>
                  <i className="bi bi-check-circle-fill"></i>
                </div>
                <div>
                  <div className="fs-12 text-muted">Completed Rides</div>
                  <div className="fw-bold fs-18" style={{ color: "#15803d" }}>
                    {isLoading ? "—" : (stats?.completedTrips || 0).toLocaleString()}
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
        <div className="col-lg-3 col-sm-6">
          <div className="card jd-ride-card jd-ride-orange">
            <div className="card-body">
              <div className="d-flex align-items-center gap-3">
                <div style={{ width: "44px", height: "44px", borderRadius: "12px", background: "rgba(234,88,12,0.1)", display: "flex", alignItems: "center", justifyContent: "center", fontSize: "1.2rem", color: "#ea580c" }}>
                  <i className="bi bi-x-circle-fill"></i>
                </div>
                <div>
                  <div className="fs-12 text-muted">Cancelled Rides</div>
                  <div className="fw-bold fs-18" style={{ color: "#c2410c" }}>
                    {isLoading ? "—" : (stats?.cancelledTrips || 0).toLocaleString()}
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
        <div className="col-lg-3 col-sm-6">
          <div className="card jd-ride-card" style={{ borderLeft: "3px solid #2563EB" }}>
            <div className="card-body">
              <div className="d-flex align-items-center gap-3">
                <div style={{ width: "44px", height: "44px", borderRadius: "12px", background: "rgba(37,99,235,0.1)", display: "flex", alignItems: "center", justifyContent: "center", fontSize: "1.2rem", color: "#2563EB" }}>
                  <i className="bi bi-activity"></i>
                </div>
                <div>
                  <div className="fs-12 text-muted">Ongoing Rides</div>
                  <div className="fw-bold fs-18" style={{ color: "#1d4ed8" }}>
                    {isLoading ? "—" : (stats?.ongoingTrips || 0).toLocaleString()}
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
        <div className="col-lg-3 col-sm-6">
          <div className="card jd-ride-card" style={{ borderLeft: "3px solid #7c3aed" }}>
            <div className="card-body">
              <div className="d-flex align-items-center gap-3">
                <div style={{ width: "44px", height: "44px", borderRadius: "12px", background: "rgba(124,58,237,0.1)", display: "flex", alignItems: "center", justifyContent: "center", fontSize: "1.2rem", color: "#7c3aed" }}>
                  <i className="bi bi-map-fill"></i>
                </div>
                <div>
                  <div className="fs-12 text-muted">Active Zones</div>
                  <div className="fw-bold fs-18" style={{ color: "#6d28d9" }}>
                    {isLoading ? "—" : (stats?.totalZones || 0).toLocaleString()}
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Recent Trips */}
      <div className="card" data-testid="recent-trips-card">
        <div className="card-header d-flex justify-content-between align-items-center">
          <h6 className="mb-0 text-capitalize fw-semibold">Recent Trips</h6>
          <a href="/admin/trips" className="text-primary fs-12">View All</a>
        </div>
        <div className="card-body">
          <div className="table-responsive">
            <table className="table table-borderless align-middle table-hover">
              <thead className="table-light align-middle text-capitalize">
                <tr>
                  <th>#</th>
                  <th>Trip ID</th>
                  <th>Customer</th>
                  <th>Vehicle</th>
                  <th>Fare</th>
                  <th>Payment</th>
                  <th>Status</th>
                  <th>Date</th>
                </tr>
              </thead>
              <tbody>
                {isLoading ? (
                  Array(5).fill(0).map((_, i) => (
                    <tr key={i}>
                      {Array(8).fill(0).map((_, j) => (
                        <td key={j}><div style={{ height: "14px", background: "#f1f5f9", borderRadius: "4px" }} /></td>
                      ))}
                    </tr>
                  ))
                ) : stats?.recentTrips?.length ? (
                  stats.recentTrips.map((item: any, idx: number) => {
                    const st = item.trip.currentStatus;
                    const badge = statusBadge[st] || { cls: "badge bg-secondary", label: st };
                    return (
                      <tr key={item.trip.id} data-testid={`trip-row-${item.trip.id}`}>
                        <td className="sl">{idx + 1}</td>
                        <td>
                          <span className="fw-semibold text-primary fs-12">{item.trip.refId}</span>
                        </td>
                        <td>
                          <div className="media align-items-center gap-2">
                            <div className="rounded-circle d-flex align-items-center justify-content-center bg-light" style={{ width: "32px", height: "32px", flexShrink: 0 }}>
                              <i className="bi bi-person-fill text-muted fs-12"></i>
                            </div>
                            <div className="media-body">{item.customer?.fullName || "—"}</div>
                          </div>
                        </td>
                        <td className="text-muted">{item.vehicleCategory?.name || "—"}</td>
                        <td className="fw-semibold">₹{Number(item.trip.actualFare || item.trip.estimatedFare || 0).toFixed(0)}</td>
                        <td>
                          <span className={`badge ${item.trip.paymentStatus === "paid" ? "bg-success" : "bg-warning text-dark"}`}>
                            {item.trip.paymentStatus}
                          </span>
                        </td>
                        <td>
                          <span className={badge.cls}>{badge.label}</span>
                        </td>
                        <td className="text-muted fs-12">{new Date(item.trip.createdAt).toLocaleDateString("en-IN")}</td>
                      </tr>
                    );
                  })
                ) : (
                  <tr>
                    <td colSpan={8}>
                      <div className="d-flex flex-column justify-content-center align-items-center gap-2 py-4">
                        <i className="bi bi-car-front" style={{ fontSize: "2rem", color: "#94a3b8" }}></i>
                        <p className="text-muted mb-0">No trips found</p>
                      </div>
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
        </div>
      </div>

    </div>
  );
}
