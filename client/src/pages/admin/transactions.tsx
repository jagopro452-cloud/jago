import { useState } from "react";
import { useQuery } from "@tanstack/react-query";

export default function Transactions() {
  const [page, setPage] = useState(1);

  const { data, isLoading } = useQuery<any>({
    queryKey: ["/api/transactions", { page }],
    queryFn: () => fetch(`/api/transactions?page=${page}&limit=15`).then(r => r.json()),
  });

  const totalPages = Math.ceil((data?.total || 0) / 15);

  return (
    <div>
      <div className="jago-page-header">
        <div>
          <h4 className="page-title" data-testid="page-title">Transactions</h4>
          <div className="breadcrumb">
            <i className="bi bi-house-fill"></i>
            <span>Home</span>
            <i className="bi bi-chevron-right" style={{ fontSize: "0.65rem" }}></i>
            <span>User Management</span>
            <i className="bi bi-chevron-right" style={{ fontSize: "0.65rem" }}></i>
            <span>Transactions</span>
          </div>
        </div>
        <div style={{ fontSize: "0.82rem", color: "var(--bs-body-color)" }}>
          Total: <strong style={{ color: "var(--title-color)" }}>{data?.total || 0}</strong> records
        </div>
      </div>

      <div className="jago-card">
        <div className="jago-card-header">
          <h5 className="jago-card-title">
            <i className="bi bi-receipt" style={{ marginRight: "0.5rem", color: "var(--bs-primary)" }}></i>
            Transaction History
          </h5>
        </div>
        <div className="jago-table-wrapper">
          <table className="jago-table">
            <thead>
              <tr>
                <th>#</th>
                <th>User</th>
                <th>Type</th>
                <th>Debit</th>
                <th>Credit</th>
                <th>Balance</th>
                <th>Date</th>
              </tr>
            </thead>
            <tbody>
              {isLoading ? Array(8).fill(0).map((_, i) => (
                <tr key={i}>
                  {Array(7).fill(0).map((_, j) => <td key={j}><div style={{ height: "14px", background: "#f1f5f9", borderRadius: "4px" }} /></td>)}
                </tr>
              )) : data?.data?.length ? data.data.map((item: any, idx: number) => (
                <tr key={item.transaction.id} data-testid={`tx-row-${item.transaction.id}`}>
                  <td style={{ color: "var(--bs-body-color)", fontSize: "0.8rem" }}>{(page - 1) * 15 + idx + 1}</td>
                  <td>
                    <div style={{ fontWeight: 600 }}>{item.user?.fullName || "—"}</div>
                    <div style={{ fontSize: "0.75rem", color: "var(--bs-body-color)" }}>{item.user?.email || ""}</div>
                  </td>
                  <td style={{ color: "var(--bs-body-color)", textTransform: "capitalize" }}>
                    {item.transaction.transactionType?.replace(/_/g, " ") || "—"}
                  </td>
                  <td style={{ color: "#ef4444", fontWeight: Number(item.transaction.debit) > 0 ? 600 : 400 }}>
                    {Number(item.transaction.debit) > 0 ? `₹${Number(item.transaction.debit).toFixed(2)}` : "—"}
                  </td>
                  <td style={{ color: "#22c55e", fontWeight: Number(item.transaction.credit) > 0 ? 600 : 400 }}>
                    {Number(item.transaction.credit) > 0 ? `₹${Number(item.transaction.credit).toFixed(2)}` : "—"}
                  </td>
                  <td style={{ fontWeight: 600 }}>₹{Number(item.transaction.balance).toFixed(2)}</td>
                  <td style={{ color: "var(--bs-body-color)", fontSize: "0.8rem", whiteSpace: "nowrap" }}>
                    {new Date(item.transaction.createdAt).toLocaleDateString("en-IN")}
                  </td>
                </tr>
              )) : (
                <tr>
                  <td colSpan={7}>
                    <div className="jago-empty">
                      <i className="bi bi-receipt"></i>
                      <p>No transactions found</p>
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
