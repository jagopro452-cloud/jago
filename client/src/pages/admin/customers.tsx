import { useState } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { apiRequest } from "@/lib/queryClient";
import { useToast } from "@/hooks/use-toast";

export default function Customers() {
  const [search, setSearch] = useState("");
  const [page, setPage] = useState(1);
  const { toast } = useToast();
  const qc = useQueryClient();

  const { data, isLoading } = useQuery<any>({
    queryKey: ["/api/users", { userType: "customer", search, page }],
    queryFn: () => {
      const params = new URLSearchParams({ userType: "customer", page: String(page), limit: "15" });
      if (search) params.set("search", search);
      return fetch(`/api/users?${params}`).then(r => r.json());
    },
  });

  const toggleStatus = useMutation({
    mutationFn: ({ id, isActive }: { id: string; isActive: boolean }) =>
      apiRequest("PATCH", `/api/users/${id}/status`, { isActive }),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["/api/users"] });
      toast({ title: "Customer status updated" });
    },
  });

  const totalPages = Math.ceil((data?.total || 0) / 15);

  return (
    <div>
      <div className="jago-page-header">
        <div>
          <h4 className="page-title" data-testid="page-title">Customers</h4>
          <div className="breadcrumb">
            <i className="bi bi-house-fill"></i>
            <span>Home</span>
            <i className="bi bi-chevron-right" style={{ fontSize: "0.65rem" }}></i>
            <span>User Management</span>
            <i className="bi bi-chevron-right" style={{ fontSize: "0.65rem" }}></i>
            <span>Customers</span>
          </div>
        </div>
        <div style={{ fontSize: "0.82rem", color: "var(--bs-body-color)" }}>
          Total: <strong style={{ color: "var(--title-color)" }}>{data?.total || 0}</strong> customers
        </div>
      </div>

      <div className="jago-card">
        <div className="jago-card-header">
          <h5 className="jago-card-title">
            <i className="bi bi-people-fill" style={{ marginRight: "0.5rem", color: "var(--bs-primary)" }}></i>
            Customer List
          </h5>
          <div style={{ position: "relative" }}>
            <i className="bi bi-search" style={{ position: "absolute", left: "0.65rem", top: "50%", transform: "translateY(-50%)", color: "var(--bs-body-color)", fontSize: "0.8rem" }}></i>
            <input
              type="search"
              className="jago-input"
              style={{ paddingLeft: "2rem", width: "220px" }}
              placeholder="Search customers..."
              value={search}
              onChange={e => { setSearch(e.target.value); setPage(1); }}
              data-testid="input-search"
            />
          </div>
        </div>

        <div className="jago-table-wrapper">
          <table className="jago-table">
            <thead>
              <tr>
                <th>#</th>
                <th>Name</th>
                <th>Email</th>
                <th>Phone</th>
                <th>Loyalty Points</th>
                <th>Status</th>
                <th>Joined</th>
                <th>Action</th>
              </tr>
            </thead>
            <tbody>
              {isLoading ? (
                Array(8).fill(0).map((_, i) => (
                  <tr key={i}>
                    {Array(8).fill(0).map((_, j) => (
                      <td key={j}><div style={{ height: "14px", background: "#f1f5f9", borderRadius: "4px" }} /></td>
                    ))}
                  </tr>
                ))
              ) : data?.data?.length ? (
                data.data.map((u: any, idx: number) => (
                  <tr key={u.id} data-testid={`customer-row-${u.id}`}>
                    <td style={{ color: "var(--bs-body-color)", fontSize: "0.8rem" }}>{(page - 1) * 15 + idx + 1}</td>
                    <td>
                      <div style={{ display: "flex", alignItems: "center", gap: "0.625rem" }}>
                        <div style={{ width: "32px", height: "32px", borderRadius: "50%", background: "rgba(37,99,235,0.1)", display: "grid", placeItems: "center", color: "var(--bs-primary)", fontSize: "0.9rem", flexShrink: 0 }}>
                          <i className="bi bi-person-fill"></i>
                        </div>
                        <span style={{ fontWeight: 600 }}>{u.fullName || `${u.firstName || ""} ${u.lastName || ""}`.trim() || "—"}</span>
                      </div>
                    </td>
                    <td style={{ color: "var(--bs-body-color)" }}>{u.email || "—"}</td>
                    <td style={{ color: "var(--bs-body-color)" }}>{u.phone || "—"}</td>
                    <td style={{ textAlign: "center" }}>
                      <span className="jago-badge badge-primary">{u.loyaltyPoints || 0}</span>
                    </td>
                    <td>
                      <span className={`jago-badge ${u.isActive ? "badge-active" : "badge-inactive"}`}>
                        {u.isActive ? "Active" : "Blocked"}
                      </span>
                    </td>
                    <td style={{ color: "var(--bs-body-color)", fontSize: "0.8rem" }}>
                      {u.createdAt ? new Date(u.createdAt).toLocaleDateString("en-IN") : "—"}
                    </td>
                    <td>
                      <button
                        className={u.isActive ? "btn-jago-danger btn-jago-sm" : "btn-jago-primary btn-jago-sm"}
                        onClick={() => toggleStatus.mutate({ id: u.id, isActive: !u.isActive })}
                        data-testid={`btn-toggle-customer-${u.id}`}
                      >
                        {u.isActive ? (
                          <><i className="bi bi-person-x-fill"></i> Block</>
                        ) : (
                          <><i className="bi bi-person-check-fill"></i> Unblock</>
                        )}
                      </button>
                    </td>
                  </tr>
                ))
              ) : (
                <tr>
                  <td colSpan={8}>
                    <div className="jago-empty">
                      <i className="bi bi-people"></i>
                      <p>No customers found</p>
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
              <button className="btn-jago-outline btn-jago-sm" disabled={page === 1} onClick={() => setPage(p => p - 1)}><i className="bi bi-chevron-left"></i></button>
              <button className="btn-jago-outline btn-jago-sm" disabled={page >= totalPages} onClick={() => setPage(p => p + 1)}><i className="bi bi-chevron-right"></i></button>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
