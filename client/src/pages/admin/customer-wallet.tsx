import { useQuery } from "@tanstack/react-query";
import { useState } from "react";

export default function CustomerWalletPage() {
  const [search, setSearch] = useState("");
  const { data, isLoading } = useQuery<any>({ queryKey: ["/api/users", { userType: "customer" }] });
  const customers = Array.isArray(data?.data) ? data.data : [];
  const filtered = customers.filter((c: any) =>
    !search || (c.fullName || c.firstName || "").toLowerCase().includes(search.toLowerCase()) || (c.phone || "").includes(search)
  );

  return (
    <>
    
      <div className="content-header">
        <div className="container-fluid">
          <div className="d-flex align-items-center justify-content-between gap-3 flex-wrap mb-3">
            <h2 className="h5 mb-0">Customer Wallet</h2>
          </div>
        </div>
      </div>
      <div className="container-fluid">
        <div className="card">
          <div className="card-header border-bottom py-3">
            <div className="row g-3">
              <div className="col-md-4">
                <div className="input-group">
                  <span className="input-group-text"><i className="bi bi-search"></i></span>
                  <input className="form-control" placeholder="Search customer..." value={search} onChange={e => setSearch(e.target.value)} data-testid="input-wallet-search" />
                </div>
              </div>
            </div>
          </div>
          <div className="card-body">
            <div className="table-responsive">
              <table className="table table-borderless align-middle table-hover">
                <thead className="table-light">
                  <tr>
                    <th>#</th>
                    <th>Customer</th>
                    <th>Phone</th>
                    <th>Email</th>
                    <th>Wallet Balance</th>
                    <th>Loyalty Points</th>
                    <th>Status</th>
                  </tr>
                </thead>
                <tbody>
                  {isLoading ? (
                    <tr><td colSpan={7} className="text-center py-4"><div className="spinner-border spinner-border-sm" role="status" /></td></tr>
                  ) : filtered.length === 0 ? (
                    <tr>
                      <td colSpan={7} className="text-center py-5 text-muted">
                        <i className="bi bi-wallet-fill fs-2 d-block mb-2 opacity-25"></i>
                        No customers found
                      </td>
                    </tr>
                  ) : filtered.map((c: any, idx: number) => (
                    <tr key={c.id} data-testid={`row-wallet-${c.id}`}>
                      <td>{idx + 1}</td>
                      <td>
                        <div className="d-flex align-items-center gap-2">
                          <div className="avatar avatar-sm rounded-circle bg-primary text-white d-flex align-items-center justify-content-center" style={{ width: 32, height: 32, fontSize: 14 }}>
                            {(c.fullName || c.firstName || "U")[0].toUpperCase()}
                          </div>
                          <span className="fw-semibold">{c.fullName || `${c.firstName || ""} ${c.lastName || ""}`.trim() || "—"}</span>
                        </div>
                      </td>
                      <td>{c.phone || "—"}</td>
                      <td>{c.email || "—"}</td>
                      <td className="fw-semibold text-success">₹0.00</td>
                      <td>{c.loyaltyPoints || 0}</td>
                      <td>
                        <span className={`badge ${c.isActive ? "bg-success" : "bg-danger"}`}>
                          {c.isActive ? "Active" : "Inactive"}
                        </span>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        </div>
      </div>
    
    </>
  );
}
