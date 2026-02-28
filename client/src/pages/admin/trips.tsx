import { useState } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { apiRequest } from "@/lib/queryClient";
import { useToast } from "@/hooks/use-toast";

const statusBadge: Record<string, string> = {
  completed: "badge-completed",
  ongoing: "badge-ongoing",
  pending: "badge-pending",
  cancelled: "badge-cancelled",
  accepted: "badge-accepted",
};

const statuses = ["all", "pending", "accepted", "ongoing", "completed", "cancelled"];

export default function Trips() {
  const [search, setSearch] = useState("");
  const [status, setStatus] = useState("all");
  const [page, setPage] = useState(1);
  const { toast } = useToast();
  const qc = useQueryClient();

  const { data, isLoading } = useQuery<any>({
    queryKey: ["/api/trips", { status, search, page }],
    queryFn: () => {
      const params = new URLSearchParams({ page: String(page), limit: "15" });
      if (status !== "all") params.set("status", status);
      if (search) params.set("search", search);
      return fetch(`/api/trips?${params}`).then(r => r.json());
    },
  });

  const updateStatus = useMutation({
    mutationFn: ({ id, newStatus }: { id: string; newStatus: string }) =>
      apiRequest("PATCH", `/api/trips/${id}/status`, { status: newStatus }),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["/api/trips"] });
      qc.invalidateQueries({ queryKey: ["/api/dashboard/stats"] });
      toast({ title: "Trip status updated successfully" });
    },
  });

  const totalPages = Math.ceil((data?.total || 0) / 15);

  return (
    <div>
      <div className="jago-page-header">
        <div>
          <h4 className="page-title" data-testid="page-title">Trip Requests</h4>
          <div className="breadcrumb">
            <i className="bi bi-house-fill"></i>
            <span>Home</span>
            <i className="bi bi-chevron-right" style={{ fontSize: "0.65rem" }}></i>
            <span>Trip Management</span>
            <i className="bi bi-chevron-right" style={{ fontSize: "0.65rem" }}></i>
            <span>All Trips</span>
          </div>
        </div>
        <div style={{ fontSize: "0.82rem", color: "var(--bs-body-color)" }}>
          Total: <strong style={{ color: "var(--title-color)" }}>{data?.total || 0}</strong> trips
        </div>
      </div>

      <div className="jago-card">
        <div className="jago-card-header">
          <h5 className="jago-card-title">
            <i className="bi bi-car-front-fill" style={{ marginRight: "0.5rem", color: "var(--bs-primary)" }}></i>
            All Trips
          </h5>
          <div style={{ display: "flex", gap: "0.625rem", alignItems: "center", flexWrap: "wrap" }}>
            {/* Search */}
            <div style={{ position: "relative" }}>
              <i className="bi bi-search" style={{ position: "absolute", left: "0.65rem", top: "50%", transform: "translateY(-50%)", color: "var(--bs-body-color)", fontSize: "0.8rem" }}></i>
              <input
                type="search"
                className="jago-input"
                style={{ paddingLeft: "2rem", width: "200px" }}
                placeholder="Search by Trip ID..."
                value={search}
                onChange={e => { setSearch(e.target.value); setPage(1); }}
                data-testid="input-search-trips"
              />
            </div>
            {/* Status Filter */}
            <select
              className="jago-input"
              style={{ width: "160px", cursor: "pointer" }}
              value={status}
              onChange={e => { setStatus(e.target.value); setPage(1); }}
              data-testid="select-trip-status"
            >
              {statuses.map(s => (
                <option key={s} value={s} data-testid={`status-option-${s}`}>
                  {s === "all" ? "All Statuses" : s.charAt(0).toUpperCase() + s.slice(1)}
                </option>
              ))}
            </select>
          </div>
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
                <th>Type</th>
                <th>Status</th>
                <th>Date</th>
                <th>Action</th>
              </tr>
            </thead>
            <tbody>
              {isLoading ? (
                Array(8).fill(0).map((_, i) => (
                  <tr key={i}>
                    {Array(9).fill(0).map((_, j) => (
                      <td key={j}><div style={{ height: "14px", background: "#f1f5f9", borderRadius: "4px" }} /></td>
                    ))}
                  </tr>
                ))
              ) : data?.data?.length ? (
                data.data.map((item: any, idx: number) => (
                  <tr key={item.trip.id} data-testid={`trip-row-${item.trip.id}`}>
                    <td style={{ color: "var(--bs-body-color)", fontSize: "0.8rem" }}>{(page - 1) * 15 + idx + 1}</td>
                    <td>
                      <span style={{ fontFamily: "monospace", fontWeight: 600, color: "var(--bs-primary)", fontSize: "0.8rem" }}>
                        {item.trip.refId}
                      </span>
                    </td>
                    <td>
                      <div style={{ fontWeight: 600, fontSize: "0.85rem" }}>{item.customer?.fullName || "Guest"}</div>
                      <div style={{ fontSize: "0.75rem", color: "var(--bs-body-color)" }}>{item.customer?.phone || ""}</div>
                    </td>
                    <td style={{ color: "var(--bs-body-color)" }}>{item.vehicleCategory?.name || "—"}</td>
                    <td style={{ fontWeight: 600 }}>
                      ₹{Number(item.trip.actualFare || item.trip.estimatedFare).toFixed(0)}
                    </td>
                    <td>
                      <span className="jago-badge badge-primary" style={{ fontSize: "0.7rem" }}>{item.trip.type}</span>
                    </td>
                    <td>
                      <span className={`jago-badge ${statusBadge[item.trip.currentStatus] || "badge-primary"}`}>
                        {item.trip.currentStatus}
                      </span>
                    </td>
                    <td style={{ color: "var(--bs-body-color)", fontSize: "0.8rem", whiteSpace: "nowrap" }}>
                      {new Date(item.trip.createdAt).toLocaleDateString("en-IN")}
                    </td>
                    <td>
                      {item.trip.currentStatus === "ongoing" && (
                        <button
                          className="btn-jago-primary btn-jago-sm"
                          onClick={() => updateStatus.mutate({ id: item.trip.id, newStatus: "completed" })}
                          data-testid={`btn-complete-trip-${item.trip.id}`}
                        >
                          <i className="bi bi-check-circle-fill"></i> Complete
                        </button>
                      )}
                      {item.trip.currentStatus === "pending" && (
                        <button
                          className="btn-jago-danger btn-jago-sm"
                          onClick={() => updateStatus.mutate({ id: item.trip.id, newStatus: "cancelled" })}
                          data-testid={`btn-cancel-trip-${item.trip.id}`}
                        >
                          <i className="bi bi-x-circle-fill"></i> Cancel
                        </button>
                      )}
                    </td>
                  </tr>
                ))
              ) : (
                <tr>
                  <td colSpan={9}>
                    <div className="jago-empty">
                      <i className="bi bi-car-front"></i>
                      <p>No trips found</p>
                    </div>
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>

        {totalPages > 1 && (
          <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", padding: "0.875rem 1rem", borderTop: "1px solid var(--bs-border-color)", fontSize: "0.82rem" }}>
            <span style={{ color: "var(--bs-body-color)" }}>Page {page} of {totalPages}</span>
            <div style={{ display: "flex", gap: "0.5rem" }}>
              <button
                className="btn-jago-outline btn-jago-sm"
                disabled={page === 1}
                onClick={() => setPage(p => p - 1)}
                data-testid="btn-prev-page"
              >
                <i className="bi bi-chevron-left"></i>
              </button>
              <button
                className="btn-jago-outline btn-jago-sm"
                disabled={page >= totalPages}
                onClick={() => setPage(p => p + 1)}
                data-testid="btn-next-page"
              >
                <i className="bi bi-chevron-right"></i>
              </button>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
