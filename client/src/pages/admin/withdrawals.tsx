import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { apiRequest } from "@/lib/queryClient";
import { useToast } from "@/hooks/use-toast";

export default function Withdrawals() {
  const { toast } = useToast();
  const qc = useQueryClient();

  const { data, isLoading } = useQuery<any[]>({
    queryKey: ["/api/withdrawals"],
    queryFn: () => fetch("/api/withdrawals").then(r => r.json()),
  });

  const update = useMutation({
    mutationFn: ({ id, status }: { id: string; status: string }) =>
      apiRequest("PATCH", `/api/withdrawals/${id}/status`, { status }),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["/api/withdrawals"] });
      toast({ title: "Withdrawal status updated" });
    },
  });

  return (
    <div>
      <div className="jago-page-header">
        <div>
          <h4 className="page-title" data-testid="page-title">Withdrawal Requests</h4>
          <div className="breadcrumb">
            <i className="bi bi-house-fill"></i>
            <span>Home</span>
            <i className="bi bi-chevron-right" style={{ fontSize: "0.65rem" }}></i>
            <span>User Management</span>
            <i className="bi bi-chevron-right" style={{ fontSize: "0.65rem" }}></i>
            <span>Withdrawals</span>
          </div>
        </div>
        <div style={{ fontSize: "0.82rem", color: "var(--bs-body-color)" }}>
          Total: <strong style={{ color: "var(--title-color)" }}>{data?.length || 0}</strong> requests
        </div>
      </div>

      <div className="jago-card">
        <div className="jago-card-header">
          <h5 className="jago-card-title">
            <i className="bi bi-cash-coin" style={{ marginRight: "0.5rem", color: "var(--bs-primary)" }}></i>
            Withdrawal Requests
          </h5>
        </div>
        <div className="jago-table-wrapper">
          <table className="jago-table">
            <thead>
              <tr>
                <th>#</th>
                <th>Driver</th>
                <th>Amount</th>
                <th>Note</th>
                <th>Status</th>
                <th>Date</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              {isLoading ? Array(5).fill(0).map((_, i) => (
                <tr key={i}>
                  {Array(7).fill(0).map((_, j) => <td key={j}><div style={{ height: "14px", background: "#f1f5f9", borderRadius: "4px" }} /></td>)}
                </tr>
              )) : data?.length ? data.map((item: any, idx: number) => (
                <tr key={item.withdraw.id} data-testid={`withdrawal-row-${item.withdraw.id}`}>
                  <td style={{ color: "var(--bs-body-color)", fontSize: "0.8rem" }}>{idx + 1}</td>
                  <td>
                    <div style={{ fontWeight: 600 }}>{item.user?.fullName || "—"}</div>
                    <div style={{ fontSize: "0.75rem", color: "var(--bs-body-color)" }}>{item.user?.phone || ""}</div>
                  </td>
                  <td style={{ fontWeight: 700, color: "var(--bs-primary)" }}>₹{Number(item.withdraw.amount).toFixed(2)}</td>
                  <td style={{ color: "var(--bs-body-color)", maxWidth: "180px" }}>
                    <span style={{ display: "block", overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap" }}>
                      {item.withdraw.note || "—"}
                    </span>
                  </td>
                  <td>
                    <span className={`jago-badge ${
                      item.withdraw.status === "approved" ? "badge-completed" :
                      item.withdraw.status === "rejected" ? "badge-cancelled" :
                      "badge-pending"
                    }`}>
                      {item.withdraw.status}
                    </span>
                  </td>
                  <td style={{ color: "var(--bs-body-color)", fontSize: "0.8rem", whiteSpace: "nowrap" }}>
                    {new Date(item.withdraw.createdAt).toLocaleDateString("en-IN")}
                  </td>
                  <td>
                    {item.withdraw.status === "pending" && (
                      <div style={{ display: "flex", gap: "0.375rem" }}>
                        <button
                          className="btn-jago-primary btn-jago-sm"
                          style={{ background: "#22c55e", borderColor: "#22c55e" }}
                          onClick={() => update.mutate({ id: item.withdraw.id, status: "approved" })}
                          data-testid={`btn-approve-${item.withdraw.id}`}
                        >
                          <i className="bi bi-check-circle-fill"></i> Approve
                        </button>
                        <button
                          className="btn-jago-danger btn-jago-sm"
                          onClick={() => update.mutate({ id: item.withdraw.id, status: "rejected" })}
                          data-testid={`btn-reject-${item.withdraw.id}`}
                        >
                          <i className="bi bi-x-circle-fill"></i> Reject
                        </button>
                      </div>
                    )}
                  </td>
                </tr>
              )) : (
                <tr>
                  <td colSpan={7}>
                    <div className="jago-empty">
                      <i className="bi bi-cash-coin"></i>
                      <p>No withdrawal requests found</p>
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
