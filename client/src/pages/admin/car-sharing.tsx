import { useState } from "react";
import { useQuery, useMutation } from "@tanstack/react-query";
import { queryClient, apiRequest } from "@/lib/queryClient";
import { useToast } from "@/hooks/use-toast";

const STATUS_COLORS: Record<string, string> = {
  completed: "bg-success", cancelled: "bg-danger",
  ongoing: "bg-warning text-dark", pending: "bg-info text-dark",
};

export default function CarSharingPage() {
  const { toast } = useToast();
  const [statusFilter, setStatusFilter] = useState("all");
  const [search, setSearch] = useState("");

  const { data, isLoading } = useQuery<any>({
    queryKey: ["/api/car-sharing-trips"],
    queryFn: () => fetch("/api/car-sharing-trips").then(r => r.json()),
  });

  const allTrips: any[] = Array.isArray(data?.data) ? data.data : [];

  const filtered = allTrips.filter(t => {
    if (statusFilter !== "all" && t.currentStatus !== statusFilter) return false;
    if (search && !(t.refId?.toLowerCase().includes(search.toLowerCase()) ||
      t.customerName?.toLowerCase().includes(search.toLowerCase()))) return false;
    return true;
  });

  const statusMutation = useMutation({
    mutationFn: ({ id, status }: any) => apiRequest("PATCH", `/api/trips/${id}/status`, { status }),
    onSuccess: () => { queryClient.invalidateQueries({ queryKey: ["/api/car-sharing-trips"] }); toast({ title: "Status updated" }); },
  });

  const completedCount = allTrips.filter(t => t.currentStatus === "completed").length;
  const ongoingCount = allTrips.filter(t => t.currentStatus === "ongoing").length;
  const cancelledCount = allTrips.filter(t => t.currentStatus === "cancelled").length;
  const revenue = allTrips.filter(t => t.currentStatus === "completed").reduce((s, t) => s + Number(t.actualFare || t.estimatedFare || 0), 0);

  return (
    <div className="container-fluid">
      <div className="d-flex align-items-center justify-content-between mb-4">
        <div>
          <h4 className="fw-bold mb-0" data-testid="page-title">Car Sharing</h4>
          <div className="text-muted small">Shared rides, carpooling, and on-demand car sharing trips</div>
        </div>
      </div>

      {/* Summary cards */}
      <div className="row g-3 mb-3">
        {[
          { label: "Total Car Shares", val: allTrips.length, icon: "bi-people-fill", color: "#1a73e8", bg: "#e8f0fe" },
          { label: "Ongoing", val: ongoingCount, icon: "bi-arrow-clockwise", color: "#d97706", bg: "#fefce8" },
          { label: "Completed", val: completedCount, icon: "bi-check-circle-fill", color: "#16a34a", bg: "#f0fdf4" },
          { label: "Cancelled", val: cancelledCount, icon: "bi-x-circle-fill", color: "#dc2626", bg: "#fff5f5" },
          { label: "Total Revenue", val: `₹${revenue.toFixed(0)}`, icon: "bi-currency-rupee", color: "#7c3aed", bg: "#f5f3ff" },
        ].map((s, i) => (
          <div key={i} className="col-6 col-xl">
            <div className="card border-0 shadow-sm" style={{ borderRadius: 14 }}>
              <div className="card-body d-flex align-items-center gap-3 py-3">
                <div className="rounded-3 d-flex align-items-center justify-content-center flex-shrink-0"
                  style={{ width: 42, height: 42, background: s.bg, color: s.color, fontSize: "1.1rem" }}>
                  <i className={`bi ${s.icon}`}></i>
                </div>
                <div>
                  <div className="fw-bold lh-1 mb-1" style={{ fontSize: 18, color: s.color }}>
                    {isLoading ? "—" : s.val}
                  </div>
                  <div className="text-muted" style={{ fontSize: 11 }}>{s.label}</div>
                </div>
              </div>
            </div>
          </div>
        ))}
      </div>

      <div className="card border-0 shadow-sm" style={{ borderRadius: 14 }}>
        <div className="card-header bg-white py-3 px-4 d-flex align-items-center justify-content-between flex-wrap gap-2"
          style={{ borderBottom: "1px solid #f1f5f9" }}>
          <ul className="nav nav--tabs p-1 rounded bg-light">
            {(["all", "ongoing", "completed", "cancelled", "pending"] as const).map(s => (
              <li key={s} className="nav-item">
                <button className={`nav-link text-capitalize${statusFilter === s ? " active" : ""}`}
                  onClick={() => setStatusFilter(s)} data-testid={`tab-cs-${s}`}>
                  {s}
                  {s !== "all" && <span className="ms-1 badge rounded-pill"
                    style={{ background: statusFilter === s ? "rgba(255,255,255,0.3)" : "#e2e8f0", color: statusFilter === s ? "white" : "#475569", fontSize: 9 }}>
                    {allTrips.filter(t => t.currentStatus === s).length}
                  </span>}
                </button>
              </li>
            ))}
          </ul>
          <div style={{ display: "flex", alignItems: "center", gap: 6, background: "#f8fafc", border: "1.5px solid #e2e8f0", borderRadius: 10, padding: "6px 12px" }}>
            <i className="bi bi-search" style={{ fontSize: 12, color: "#94a3b8" }}></i>
            <input style={{ border: "none", background: "transparent", outline: "none", fontSize: 13, width: 180 }}
              placeholder="Search trips…" value={search} onChange={e => setSearch(e.target.value)}
              data-testid="input-cs-search" />
          </div>
        </div>

        <div className="card-body p-0">
          <div className="table-responsive">
            <table className="table table-borderless align-middle table-hover mb-0">
              <thead style={{ background: "#f8fafc" }}>
                <tr>
                  {["#", "Ref ID", "Customer", "Driver", "Pickup → Drop", "Vehicle", "Distance", "Fare", "Status", "Date"].map((h, i) => (
                    <th key={i} className={i === 0 ? "ps-4" : ""}
                      style={{ fontSize: 11, color: "#94a3b8", fontWeight: 700, textTransform: "uppercase", letterSpacing: ".5px", paddingTop: 12, paddingBottom: 12 }}>
                      {h}
                    </th>
                  ))}
                </tr>
              </thead>
              <tbody>
                {isLoading ? Array(3).fill(0).map((_, i) => (
                  <tr key={i}>{Array(10).fill(0).map((_, j) => <td key={j}><div style={{ height: 14, background: "#f1f5f9", borderRadius: 4 }} /></td>)}</tr>
                )) : filtered.length === 0 ? (
                  <tr><td colSpan={10}>
                    <div className="text-center py-5 text-muted">
                      <i className="bi bi-people-fill fs-1 d-block mb-2" style={{ opacity: 0.25 }}></i>
                      <p className="fw-semibold mb-1">No car sharing trips found</p>
                      <p className="small">Car sharing trips will appear here once customers book shared rides</p>
                    </div>
                  </td></tr>
                ) : filtered.map((t: any, idx: number) => (
                  <tr key={t.id} data-testid={`row-cs-${t.id}`}>
                    <td className="ps-4 text-muted small">{idx + 1}</td>
                    <td>
                      <span className="fw-semibold" style={{ fontSize: 12, color: "#1a73e8", fontFamily: "monospace" }}>
                        {t.refId}
                      </span>
                    </td>
                    <td>
                      <div style={{ fontSize: 12 }}>{t.customerName || "—"}</div>
                      <div style={{ fontSize: 10.5, color: "#94a3b8" }}>{t.customerPhone || ""}</div>
                    </td>
                    <td>
                      <div style={{ fontSize: 12 }}>{t.driverName || "—"}</div>
                      <div style={{ fontSize: 10.5, color: "#94a3b8" }}>{t.driverPhone || ""}</div>
                    </td>
                    <td style={{ maxWidth: 220 }}>
                      <div style={{ fontSize: 11, color: "#374151" }}>
                        <i className="bi bi-geo-alt-fill text-success me-1" style={{ fontSize: 9 }}></i>
                        {t.pickupAddress || "—"}
                      </div>
                      <div style={{ fontSize: 11, color: "#94a3b8", marginTop: 2 }}>
                        <i className="bi bi-geo-alt-fill text-danger me-1" style={{ fontSize: 9 }}></i>
                        {t.destinationAddress || "—"}
                      </div>
                    </td>
                    <td style={{ fontSize: 12, color: "#64748b" }}>{t.vehicleName || "—"}</td>
                    <td style={{ fontSize: 12 }}>
                      {t.estimatedDistance ? `${parseFloat(t.estimatedDistance).toFixed(1)} km` : "—"}
                    </td>
                    <td>
                      <span className="fw-semibold" style={{ fontSize: 13, color: "#16a34a" }}>
                        ₹{parseFloat(t.actualFare || t.estimatedFare || 0).toFixed(0)}
                      </span>
                    </td>
                    <td>
                      <span className={`badge ${STATUS_COLORS[t.currentStatus] || "bg-secondary"}`} style={{ fontSize: 10 }}>
                        {t.currentStatus}
                      </span>
                    </td>
                    <td style={{ fontSize: 11, color: "#94a3b8", whiteSpace: "nowrap" }}>
                      {t.createdAt ? new Date(t.createdAt).toLocaleDateString("en-IN") : "—"}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </div>
  );
}
