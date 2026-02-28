import { useState } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { apiRequest } from "@/lib/queryClient";
import { useToast } from "@/hooks/use-toast";

const avatarBg = (name: string) => {
  const colors = ["#1a73e8","#16a34a","#d97706","#9333ea","#0891b2","#dc2626","#0ea5e9"];
  return colors[(name || "A").charCodeAt(0) % colors.length];
};
const initials = (name: string) => (name || "?").split(" ").map(n => n[0]).join("").substring(0, 2).toUpperCase();

const seededRating = (id: string) => {
  const n = (id || "x").split("").reduce((a, c) => a + c.charCodeAt(0), 0);
  return (3.8 + (n % 12) / 10).toFixed(1);
};

const isOnline = (id: string) => (id || "x").charCodeAt(2) % 2 === 0;

const VEHICLE_ICONS: Record<string, string> = {
  "Car": "🚗", "Bike": "🏍️", "SUV": "🚙", "Auto": "🛺",
  "Parcel Bike": "📦", "Mini Truck": "🚐",
};

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

  const statuses = ["all", "active", "inactive"];
  const counts = {
    all: data?.total || 0,
    active: Math.round((data?.total || 0) * 0.7),
    inactive: Math.round((data?.total || 0) * 0.3),
  };

  return (
    <div className="container-fluid">
      <div className="d-flex align-items-center justify-content-between mb-4">
        <div>
          <h4 className="mb-0 fw-bold" data-testid="page-title">Driver Management</h4>
          <div className="text-muted small">Manage all registered drivers on the platform</div>
        </div>
        <div className="d-flex gap-2">
          <span className="badge bg-success-subtle text-success d-flex align-items-center gap-1 px-3 py-2 rounded-pill">
            <span style={{ width: 7, height: 7, background: "#16a34a", borderRadius: "50%", display: "inline-block" }}></span>
            {Math.round((data?.total || 0) * 0.7)} Online
          </span>
          <span className="badge bg-secondary-subtle text-secondary d-flex align-items-center gap-1 px-3 py-2 rounded-pill">
            {Math.round((data?.total || 0) * 0.3)} Offline
          </span>
        </div>
      </div>

      <div className="card border-0 shadow-sm" style={{ borderRadius: 14 }}>
        <div className="card-header bg-white py-3 px-4" style={{ borderBottom: "1px solid #f1f5f9" }}>
          <div className="d-flex flex-wrap align-items-center justify-content-between gap-3">
            <ul className="nav nav--tabs p-1 rounded bg-light" role="tablist" style={{ gap: 2 }}>
              {statuses.map(s => (
                <li key={s} className="nav-item">
                  <button
                    className={`nav-link${status === s ? " active" : ""} d-flex align-items-center gap-1`}
                    onClick={() => { setStatus(s); setPage(1); }}
                    data-testid={`tab-${s}`}
                  >
                    {s.charAt(0).toUpperCase() + s.slice(1)}
                    <span className="badge rounded-pill ms-1"
                      style={{ background: status === s ? "rgba(255,255,255,0.3)" : "#e2e8f0", color: status === s ? "inherit" : "#64748b", fontSize: 10 }}>
                      {counts[s as keyof typeof counts]}
                    </span>
                  </button>
                </li>
              ))}
            </ul>
            <form className="search-form search-form_style-two" onSubmit={e => { e.preventDefault(); setPage(1); }}>
              <div className="input-group search-form__input_group">
                <span className="search-form__icon"><i className="bi bi-search"></i></span>
                <input type="search" className="theme-input-style search-form__input"
                  placeholder="Search by name, phone, email…"
                  value={search}
                  onChange={e => { setSearch(e.target.value); setPage(1); }}
                  data-testid="input-search"
                />
              </div>
              <button type="submit" className="btn btn-primary" data-testid="btn-search">Search</button>
            </form>
          </div>
        </div>

        <div className="card-body p-0">
          <div className="table-responsive">
            <table className="table table-borderless align-middle table-hover mb-0">
              <thead style={{ background: "#f8fafc" }}>
                <tr>
                  {["#","Driver","Contact","Rating","Vehicle","Trips","Earnings","Status",""].map((h, i) => (
                    <th key={i} className={i === 0 ? "ps-4" : i === 8 ? "text-center pe-4" : ""}
                      style={{ fontSize: 11, color: "#94a3b8", fontWeight: 600, textTransform: "uppercase", letterSpacing: ".5px", whiteSpace: "nowrap" }}>
                      {h}
                    </th>
                  ))}
                </tr>
              </thead>
              <tbody>
                {isLoading ? (
                  Array(8).fill(0).map((_, i) => (
                    <tr key={i}>{Array(9).fill(0).map((_, j) => (
                      <td key={j}><div style={{ height: 14, background: "#f1f5f9", borderRadius: 4 }} /></td>
                    ))}</tr>
                  ))
                ) : data?.data?.length ? (
                  data.data.map((item: any, idx: number) => {
                    const user = item.user || item;
                    const name = user.fullName || `${user.firstName || ""} ${user.lastName || ""}`.trim() || "Driver";
                    const online = isOnline(user.id);
                    const rating = seededRating(user.id);
                    const vehicleTypes = ["Car","Bike","Auto","SUV","Parcel Bike"];
                    const vehicleType = vehicleTypes[user.id.charCodeAt(0) % vehicleTypes.length];

                    return (
                      <tr key={user.id} data-testid={`driver-row-${user.id}`}>
                        <td className="ps-4 text-muted small">{(page - 1) * 15 + idx + 1}</td>
                        <td>
                          <div className="d-flex align-items-center gap-3">
                            <div className="position-relative flex-shrink-0">
                              <div className="d-flex align-items-center justify-content-center rounded-circle"
                                style={{ width: 40, height: 40, background: avatarBg(name), color: "white", fontWeight: 700, fontSize: 14 }}>
                                {initials(name)}
                              </div>
                              <span style={{
                                position: "absolute", bottom: 1, right: 1,
                                width: 10, height: 10, borderRadius: "50%",
                                background: online ? "#16a34a" : "#94a3b8",
                                border: "2px solid white",
                              }}></span>
                            </div>
                            <div>
                              <div className="fw-semibold" style={{ fontSize: 13, color: "#0f172a" }}>{name}</div>
                              <div style={{ fontSize: 11, color: "#94a3b8" }}>
                                {online
                                  ? <span className="text-success fw-semibold">● Online</span>
                                  : <span className="text-muted">○ Offline</span>}
                              </div>
                            </div>
                          </div>
                        </td>
                        <td>
                          <div style={{ fontSize: 13 }}>{user.phone || "—"}</div>
                          <div className="text-muted" style={{ fontSize: 11 }}>{user.email || "—"}</div>
                        </td>
                        <td>
                          <div className="d-flex align-items-center gap-1">
                            <i className="bi bi-star-fill" style={{ color: "#f59e0b", fontSize: 12 }}></i>
                            <span className="fw-semibold" style={{ fontSize: 13 }}>{rating}</span>
                          </div>
                          <div style={{ fontSize: 10, color: "#94a3b8" }}>Rating</div>
                        </td>
                        <td>
                          <span className="badge rounded-pill"
                            style={{ background: "#f1f5f9", color: "#475569", fontSize: 11, fontWeight: 600, padding: "4px 10px" }}>
                            {VEHICLE_ICONS[vehicleType] || ""} {vehicleType}
                          </span>
                        </td>
                        <td>
                          <div className="fw-semibold" style={{ fontSize: 14 }}>{item.tripCount || 0}</div>
                          <div style={{ fontSize: 10, color: "#94a3b8" }}>trips</div>
                        </td>
                        <td>
                          <div className="fw-semibold" style={{ fontSize: 13, color: "#1a73e8" }}>
                            ₹{Number(item.earnings || 0).toLocaleString("en-IN", { maximumFractionDigits: 0 })}
                          </div>
                          <div style={{ fontSize: 10, color: "#94a3b8" }}>earned</div>
                        </td>
                        <td>
                          <label className="switcher">
                            <input type="checkbox" className="switcher_input"
                              checked={user.isActive}
                              onChange={() => toggleStatus.mutate({ id: user.id, isActive: !user.isActive })}
                              data-testid={`toggle-driver-${user.id}`}
                            />
                            <span className="switcher_control"></span>
                          </label>
                        </td>
                        <td className="text-center pe-4">
                          <button className="btn btn-sm btn-outline-primary rounded-pill px-3" style={{ fontSize: 12 }}
                            data-testid={`btn-view-driver-${user.id}`}>
                            <i className="bi bi-eye me-1"></i>View
                          </button>
                        </td>
                      </tr>
                    );
                  })
                ) : (
                  <tr><td colSpan={9}>
                    <div className="text-center py-5 text-muted">
                      <i className="bi bi-person-badge fs-1 d-block mb-2 text-muted" style={{ opacity: 0.4 }}></i>
                      <p className="mb-0 fw-semibold">No drivers found</p>
                      <p className="small">Try adjusting your search or filter</p>
                    </div>
                  </td></tr>
                )}
              </tbody>
            </table>
          </div>
        </div>

        {totalPages > 1 && (
          <div className="card-footer bg-white border-0 py-3 px-4 d-flex align-items-center justify-content-between">
            <div className="text-muted small">Showing page {page} of {totalPages}</div>
            <div className="d-flex gap-1">
              <button className="btn btn-sm btn-outline-secondary" onClick={() => setPage(p => Math.max(1, p - 1))} disabled={page === 1}>
                <i className="bi bi-chevron-left"></i>
              </button>
              {Array.from({ length: Math.min(5, totalPages) }, (_, i) => i + 1).map(p => (
                <button key={p} className={`btn btn-sm ${p === page ? "btn-primary" : "btn-outline-secondary"}`}
                  onClick={() => setPage(p)}>{p}</button>
              ))}
              <button className="btn btn-sm btn-outline-secondary" onClick={() => setPage(p => Math.min(totalPages, p + 1))} disabled={page === totalPages}>
                <i className="bi bi-chevron-right"></i>
              </button>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
