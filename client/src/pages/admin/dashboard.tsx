import { useQuery } from "@tanstack/react-query";

const statusBadgeClass: Record<string, string> = {
  completed: "badge-completed",
  ongoing: "badge-ongoing",
  pending: "badge-pending",
  cancelled: "badge-cancelled",
  accepted: "badge-accepted",
};

function StatCard({ label, value, icon, colorClass, sub }: {
  label: string; value: any; icon: string; colorClass: string; sub?: string;
}) {
  return (
    <div className="jago-stat-card">
      <div className={`stat-icon ${colorClass}`}>
        <i className={`bi ${icon}`}></i>
      </div>
      <div>
        <div
          className="stat-value"
          data-testid={`stat-value-${label.toLowerCase().replace(/\s+/g, "-")}`}
        >
          {value ?? <span style={{ fontSize: "1rem", color: "var(--bs-body-color)" }}>Loading...</span>}
        </div>
        <div className="stat-label">{label}</div>
        {sub && <div style={{ fontSize: "0.72rem", color: "var(--bs-body-color)", marginTop: "0.15rem" }}>{sub}</div>}
      </div>
    </div>
  );
}

export default function Dashboard() {
  const { data: stats, isLoading } = useQuery<any>({ queryKey: ["/api/dashboard/stats"] });

  return (
    <div>
      {/* Page Header */}
      <div className="jago-page-header">
        <div>
          <h4 className="page-title" data-testid="page-title">Dashboard</h4>
          <div className="breadcrumb">
            <i className="bi bi-house-fill"></i>
            <span>Home</span>
            <i className="bi bi-chevron-right" style={{ fontSize: "0.65rem" }}></i>
            <span>Dashboard</span>
          </div>
        </div>
        <div style={{ fontSize: "0.8rem", color: "var(--bs-body-color)", display: "flex", alignItems: "center", gap: "0.4rem" }}>
          <i className="bi bi-calendar3"></i>
          {new Date().toLocaleDateString("en-IN", { weekday: "long", year: "numeric", month: "long", day: "numeric" })}
        </div>
      </div>

      {/* Stats Grid */}
      <div className="jago-stats-grid" style={{ marginBottom: "1.5rem" }}>
        <StatCard
          label="Total Customers"
          value={isLoading ? "—" : stats?.totalCustomers}
          icon="bi-people-fill"
          colorClass="stat-icon-primary"
          sub="Registered users"
        />
        <StatCard
          label="Total Drivers"
          value={isLoading ? "—" : stats?.totalDrivers}
          icon="bi-person-badge-fill"
          colorClass="stat-icon-success"
          sub="Active partners"
        />
        <StatCard
          label="Total Trips"
          value={isLoading ? "—" : stats?.totalTrips}
          icon="bi-car-front-fill"
          colorClass="stat-icon-warning"
          sub="All time"
        />
        <StatCard
          label="Completed"
          value={isLoading ? "—" : stats?.completedTrips}
          icon="bi-clipboard-check-fill"
          colorClass="stat-icon-success"
          sub="Successfully done"
        />
        <StatCard
          label="Ongoing"
          value={isLoading ? "—" : stats?.ongoingTrips}
          icon="bi-activity"
          colorClass="stat-icon-info"
          sub="In progress"
        />
        <StatCard
          label="Cancelled"
          value={isLoading ? "—" : stats?.cancelledTrips}
          icon="bi-cloud-minus-fill"
          colorClass="stat-icon-danger"
          sub="All time"
        />
        <StatCard
          label="Active Zones"
          value={isLoading ? "—" : stats?.totalZones}
          icon="bi-map-fill"
          colorClass="stat-icon-purple"
          sub="Service areas"
        />
        <StatCard
          label="Total Revenue"
          value={isLoading ? "—" : `₹${(stats?.totalRevenue || 0).toLocaleString("en-IN", { minimumFractionDigits: 0, maximumFractionDigits: 0 })}`}
          icon="bi-currency-rupee"
          colorClass="stat-icon-warning"
          sub="From completed trips"
        />
      </div>

      {/* Recent Trips Card */}
      <div className="jago-card">
        <div className="jago-card-header">
          <h5 className="jago-card-title">
            <i className="bi bi-clock-history" style={{ marginRight: "0.5rem", color: "var(--bs-primary)" }}></i>
            Recent Trip Requests
          </h5>
          <span
            style={{
              background: "rgba(37,99,235,0.1)",
              color: "var(--bs-primary)",
              padding: "0.25rem 0.75rem",
              borderRadius: "20px",
              fontSize: "0.75rem",
              fontWeight: 600,
            }}
          >
            Last {stats?.recentTrips?.length || 0} records
          </span>
        </div>
        <div className="jago-table-wrapper">
          <table className="jago-table">
            <thead>
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
                      <td key={j}>
                        <div style={{ height: "16px", background: "#f1f5f9", borderRadius: "4px", width: j === 0 ? "20px" : "80%" }} />
                      </td>
                    ))}
                  </tr>
                ))
              ) : stats?.recentTrips?.length ? (
                stats.recentTrips.map((item: any, idx: number) => (
                  <tr key={item.trip.id} data-testid={`trip-row-${item.trip.id}`}>
                    <td style={{ color: "var(--bs-body-color)", fontSize: "0.8rem" }}>{idx + 1}</td>
                    <td>
                      <span style={{ fontFamily: "monospace", fontWeight: 600, color: "var(--bs-primary)", fontSize: "0.8rem" }}>
                        {item.trip.refId}
                      </span>
                    </td>
                    <td>{item.customer?.fullName || "—"}</td>
                    <td style={{ color: "var(--bs-body-color)" }}>{item.vehicleCategory?.name || "—"}</td>
                    <td style={{ fontWeight: 600 }}>
                      ₹{Number(item.trip.actualFare || item.trip.estimatedFare).toFixed(0)}
                    </td>
                    <td>
                      <span className={`jago-badge ${item.trip.paymentStatus === "paid" ? "badge-paid" : "badge-unpaid"}`}>
                        {item.trip.paymentStatus}
                      </span>
                    </td>
                    <td>
                      <span className={`jago-badge ${statusBadgeClass[item.trip.currentStatus] || "badge-primary"}`}>
                        {item.trip.currentStatus}
                      </span>
                    </td>
                    <td style={{ color: "var(--bs-body-color)", fontSize: "0.8rem", whiteSpace: "nowrap" }}>
                      {new Date(item.trip.createdAt).toLocaleDateString("en-IN")}
                    </td>
                  </tr>
                ))
              ) : (
                <tr>
                  <td colSpan={8}>
                    <div className="jago-empty">
                      <i className="bi bi-car-front"></i>
                      <p>No trips found. Trips will appear here once customers start booking.</p>
                    </div>
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}
