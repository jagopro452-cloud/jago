import { useState } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { apiRequest } from "@/lib/queryClient";
import { useToast } from "@/hooks/use-toast";

const statuses = ["all", "pending", "accepted", "ongoing", "completed", "cancelled"];

const badgeClass: Record<string, string> = {
  completed: "badge bg-success",
  ongoing: "badge bg-info",
  pending: "badge bg-warning text-dark",
  cancelled: "badge bg-danger",
  accepted: "badge bg-primary",
};

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

  const handleSearch = (e: React.FormEvent) => {
    e.preventDefault();
    setPage(1);
  };

  return (
    <div className="container-fluid">
      <h4 className="text-capitalize mb-4" data-testid="page-title">Trip List</h4>

      <div className="d-flex flex-wrap justify-content-between align-items-center mb-3">
        <h4 className="text-capitalize">All Trips</h4>
        <div className="d-flex align-items-center gap-2 text-capitalize">
          <span className="text-muted">Total Trips:</span>
          <h4 className="" data-testid="total-count">{data?.total || 0}</h4>
        </div>
      </div>

      <div className="mb-3">
        <ul className="nav nav--tabs p-1 rounded bg-white" role="tablist">
          {statuses.map(s => (
            <li key={s} className="nav-item" role="presentation">
              <button
                className={`nav-link${status === s ? " active" : ""}`}
                onClick={() => { setStatus(s); setPage(1); }}
                data-testid={`tab-${s}`}
              >
                {s.charAt(0).toUpperCase() + s.slice(1)}
              </button>
            </li>
          ))}
        </ul>
      </div>

      <div className="card">
        <div className="card-body">
          <div className="table-top d-flex flex-wrap gap-10 justify-content-between">
            <form className="search-form search-form_style-two" onSubmit={handleSearch}>
              <div className="input-group search-form__input_group">
                <span className="search-form__icon">
                  <i className="bi bi-search"></i>
                </span>
                <input
                  type="search"
                  className="theme-input-style search-form__input"
                  placeholder="Search here by Trip ID"
                  value={search}
                  onChange={e => { setSearch(e.target.value); setPage(1); }}
                  data-testid="input-search"
                />
              </div>
              <button type="submit" className="btn btn-primary" data-testid="btn-search">Search</button>
            </form>
          </div>

          <div className="table-responsive mt-3">
            <table className="table table-borderless align-middle table-hover">
              <thead className="table-light align-middle text-capitalize">
                <tr>
                  <th>SL</th>
                  <th>Trip ID</th>
                  <th>Customer</th>
                  <th>Driver</th>
                  <th>Vehicle</th>
                  <th>Fare</th>
                  <th>Payment</th>
                  <th>Status</th>
                  <th>Date</th>
                  <th className="text-center">Action</th>
                </tr>
              </thead>
              <tbody>
                {isLoading ? (
                  Array(8).fill(0).map((_, i) => (
                    <tr key={i}>
                      {Array(10).fill(0).map((_, j) => (
                        <td key={j}><div style={{ height: "14px", background: "#f1f5f9", borderRadius: "4px" }} /></td>
                      ))}
                    </tr>
                  ))
                ) : data?.data?.length ? (
                  data.data.map((item: any, idx: number) => {
                    const st = item.trip.currentStatus;
                    return (
                      <tr key={item.trip.id} data-testid={`trip-row-${item.trip.id}`}>
                        <td>{(page - 1) * 15 + idx + 1}</td>
                        <td>
                          <span className="fw-semibold text-primary fs-12">{item.trip.refId}</span>
                        </td>
                        <td>{item.customer?.fullName || "—"}</td>
                        <td>{item.driver?.fullName || "—"}</td>
                        <td className="text-muted">{item.vehicleCategory?.name || "—"}</td>
                        <td className="fw-semibold">₹{Number(item.trip.actualFare || item.trip.estimatedFare || 0).toFixed(0)}</td>
                        <td>
                          <span className={`badge ${item.trip.paymentStatus === "paid" ? "bg-success" : "bg-warning text-dark"}`}>
                            {item.trip.paymentStatus}
                          </span>
                        </td>
                        <td>
                          <span className={badgeClass[st] || "badge bg-secondary"}>
                            {st.charAt(0).toUpperCase() + st.slice(1)}
                          </span>
                        </td>
                        <td className="text-muted fs-12">{new Date(item.trip.createdAt).toLocaleDateString("en-IN")}</td>
                        <td className="text-center">
                          {(st === "pending" || st === "accepted") && (
                            <button
                              className="btn btn-sm btn-outline-danger"
                              onClick={() => updateStatus.mutate({ id: item.trip.id, newStatus: "cancelled" })}
                              data-testid={`btn-cancel-${item.trip.id}`}
                            >
                              <i className="bi bi-x-circle"></i>
                            </button>
                          )}
                        </td>
                      </tr>
                    );
                  })
                ) : (
                  <tr>
                    <td colSpan={10}>
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

          {totalPages > 1 && (
            <div className="d-flex flex-wrap align-items-center justify-content-end gap-2 mt-3">
              <button className="btn btn-sm btn-outline-secondary" onClick={() => setPage(p => Math.max(1, p - 1))} disabled={page === 1}>
                <i className="bi bi-chevron-left"></i>
              </button>
              {Array.from({ length: Math.min(5, totalPages) }, (_, i) => i + 1).map(p => (
                <button
                  key={p}
                  className={`btn btn-sm ${p === page ? "btn-primary" : "btn-outline-secondary"}`}
                  onClick={() => setPage(p)}
                >{p}</button>
              ))}
              <button className="btn btn-sm btn-outline-secondary" onClick={() => setPage(p => Math.min(totalPages, p + 1))} disabled={page === totalPages}>
                <i className="bi bi-chevron-right"></i>
              </button>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
