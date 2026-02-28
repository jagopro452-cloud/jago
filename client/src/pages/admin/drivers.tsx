import { useState } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { apiRequest } from "@/lib/queryClient";
import { useToast } from "@/hooks/use-toast";

export default function Drivers() {
  const [search, setSearch] = useState("");
  const [status, setStatus] = useState("all");
  const [page, setPage] = useState(1);
  const { toast } = useToast();
  const qc = useQueryClient();

  const { data, isLoading } = useQuery<any>({
    queryKey: ["/api/users", { userType: "driver", search, page, status }],
    queryFn: () => {
      const params = new URLSearchParams({ userType: "driver", page: String(page), limit: "15" });
      if (search) params.set("search", search);
      if (status !== "all") params.set("isActive", status === "active" ? "true" : "false");
      return fetch(`/api/users?${params}`).then(r => r.json());
    },
  });

  const toggleStatus = useMutation({
    mutationFn: ({ id, isActive }: { id: string; isActive: boolean }) =>
      apiRequest("PATCH", `/api/users/${id}/status`, { isActive }),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["/api/users"] });
      toast({ title: "Driver status updated" });
    },
  });

  const totalPages = Math.ceil((data?.total || 0) / 15);

  const handleSearch = (e: React.FormEvent) => {
    e.preventDefault();
    setPage(1);
  };

  return (
    <div className="container-fluid">
      <h2 className="fs-22 mb-4 text-capitalize" data-testid="page-title">Driver List</h2>

      <div className="row g-4">
        <div className="col-12">
          <div className="d-flex flex-wrap justify-content-between align-items-center my-3 gap-3">
            <ul className="nav nav--tabs p-1 rounded bg-white" role="tablist">
              {["all", "active", "inactive"].map(s => (
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
            <div className="d-flex align-items-center gap-2">
              <span className="text-muted">Total Driver:</span>
              <span className="text-primary fs-16 fw-bold" data-testid="total-count">{data?.total || 0}</span>
            </div>
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
                      placeholder="Search by Driver Name"
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
                      <th>Driver Name</th>
                      <th>Contact Info</th>
                      <th>Profile %</th>
                      <th>Level</th>
                      <th>Total Trip</th>
                      <th>Earnings</th>
                      <th>Status</th>
                      <th className="text-center">Action</th>
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
                      data.data.map((item: any, idx: number) => {
                        const user = item.user || item;
                        return (
                        <tr key={user.id} data-testid={`driver-row-${user.id}`}>
                          <td>{(page - 1) * 15 + idx + 1}</td>
                          <td>
                            <div className="media align-items-center gap-2">
                              <div className="rounded-circle d-flex align-items-center justify-content-center bg-light" style={{ width: "36px", height: "36px", flexShrink: 0 }}>
                                <i className="bi bi-person-badge-fill text-muted"></i>
                              </div>
                              <div className="media-body fw-medium title-color">
                                {user.fullName || `${user.firstName} ${user.lastName}`}
                              </div>
                            </div>
                          </td>
                          <td>
                            <div className="title-color">{user.phone || "—"}</div>
                            <div className="text-muted fs-12">{user.email || "—"}</div>
                          </td>
                          <td>
                            <div className="d-flex align-items-center gap-2">
                              <div className="progress" style={{ width: "60px", height: "6px" }}>
                                <div className="progress-bar bg-primary" style={{ width: `${user.completionPercent || 0}%` }}></div>
                              </div>
                              <span className="fs-12">{user.completionPercent || 0}%</span>
                            </div>
                          </td>
                          <td>
                            <span className="badge bg-secondary">{item.level?.name || "—"}</span>
                          </td>
                          <td className="fw-semibold">{item.tripCount || 0}</td>
                          <td className="fw-semibold text-primary">
                            ₹{Number(item.earnings || 0).toFixed(0)}
                          </td>
                          <td>
                            <label className="switcher">
                              <input
                                type="checkbox"
                                className="switcher_input"
                                checked={user.isActive}
                                onChange={() => toggleStatus.mutate({ id: user.id, isActive: !user.isActive })}
                                data-testid={`toggle-driver-${user.id}`}
                              />
                              <span className="switcher_control"></span>
                            </label>
                          </td>
                          <td className="text-center">
                            <button className="btn btn-sm btn-outline-primary" data-testid={`btn-view-driver-${user.id}`}>
                              <i className="bi bi-eye"></i>
                            </button>
                          </td>
                        </tr>
                        );
                      })
                    ) : (
                      <tr>
                        <td colSpan={9}>
                          <div className="d-flex flex-column justify-content-center align-items-center gap-2 py-4">
                            <i className="bi bi-person-badge" style={{ fontSize: "2rem", color: "#94a3b8" }}></i>
                            <p className="text-muted mb-0">No drivers found</p>
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
      </div>
    </div>
  );
}
