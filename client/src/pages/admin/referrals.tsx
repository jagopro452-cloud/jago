import { useState } from "react";
import { useQuery, useMutation } from "@tanstack/react-query";
import { queryClient, apiRequest } from "@/lib/queryClient";
import { useToast } from "@/hooks/use-toast";

const STATUS_STYLES: any = {
  paid: { bg: "#d1fae5", color: "#065f46", label: "Paid" },
  pending: { bg: "#fef3c7", color: "#92400e", label: "Pending" },
  expired: { bg: "#f1f5f9", color: "#64748b", label: "Expired" },
};

function timeAgo(dateStr: string) {
  const diff = Date.now() - new Date(dateStr).getTime();
  const days = Math.floor(diff / 86400000);
  if (days === 0) return "Today";
  if (days === 1) return "Yesterday";
  return `${days} days ago`;
}

export default function ReferralsPage() {
  const { toast } = useToast();
  const [statusFilter, setStatusFilter] = useState("all");
  const [typeFilter, setTypeFilter] = useState("all");

  const { data: stats } = useQuery<any>({ queryKey: ["/api/referrals/stats"] });
  const { data: referrals = [], isLoading } = useQuery<any[]>({
    queryKey: ["/api/referrals", { status: statusFilter, referralType: typeFilter }],
    queryFn: () => fetch(`/api/referrals?status=${statusFilter}&referralType=${typeFilter}`).then(r => r.json()),
  });

  const payMutation = useMutation({
    mutationFn: (id: string) => apiRequest("PATCH", `/api/referrals/${id}/pay`, {}),
    onSuccess: () => {
      toast({ title: "✅ Referral marked as paid" });
      queryClient.invalidateQueries({ queryKey: ["/api/referrals"] });
      queryClient.invalidateQueries({ queryKey: ["/api/referrals/stats"] });
    },
    onError: () => toast({ title: "Failed to update", variant: "destructive" }),
  });

  const expireMutation = useMutation({
    mutationFn: (id: string) => apiRequest("PATCH", `/api/referrals/${id}/expire`, {}),
    onSuccess: () => {
      toast({ title: "Referral marked as expired" });
      queryClient.invalidateQueries({ queryKey: ["/api/referrals"] });
      queryClient.invalidateQueries({ queryKey: ["/api/referrals/stats"] });
    },
  });

  const statCards = [
    { label: "Total Referrals", val: stats?.total || 0, icon: "bi-share-fill", color: "#4f46e5", bg: "linear-gradient(135deg,#4f46e515,#818cf815)" },
    { label: "Paid Out", val: stats?.paid || 0, icon: "bi-check-circle-fill", color: "#059669", bg: "linear-gradient(135deg,#05966915,#34d39915)" },
    { label: "Pending Payment", val: stats?.pending || 0, icon: "bi-clock-fill", color: "#d97706", bg: "linear-gradient(135deg,#d9770615,#fbbf2415)" },
    { label: "Total Rewarded", val: `₹${Number(stats?.totalRewarded || 0).toFixed(0)}`, icon: "bi-gift-fill", color: "#0284c7", bg: "linear-gradient(135deg,#0284c715,#38bdf815)" },
  ];

  return (
    <>
      <div className="content-header">
        <div className="container-fluid">
          <h2 className="h5 mb-3">Referral Management</h2>
        </div>
      </div>
      <div className="container-fluid">
        <div className="row g-3 mb-4">
          {statCards.map((s, i) => (
            <div key={i} className="col-6 col-md-3">
              <div className="card border-0" style={{ background: s.bg }}>
                <div className="card-body d-flex align-items-center gap-3 p-3">
                  <div style={{ width: 44, height: 44, borderRadius: 10, background: s.color + "22", display: "flex", alignItems: "center", justifyContent: "center" }}>
                    <i className={`bi ${s.icon}`} style={{ color: s.color, fontSize: "1.1rem" }} />
                  </div>
                  <div>
                    <div style={{ fontSize: "1.4rem", fontWeight: 700, color: s.color, lineHeight: 1 }}>{s.val}</div>
                    <div style={{ fontSize: "0.72rem", color: "#64748b", marginTop: 2 }}>{s.label}</div>
                  </div>
                </div>
              </div>
            </div>
          ))}
        </div>

        <div className="row g-3 mb-4">
          <div className="col-md-6">
            <div className="card" style={{ border: "1px solid #e2e8f0" }}>
              <div className="card-body p-3">
                <div className="fw-semibold mb-1" style={{ fontSize: "0.78rem", color: "#64748b" }}>CUSTOMER REFERRALS</div>
                <div className="d-flex gap-4">
                  <div><span style={{ fontSize: "1.5rem", fontWeight: 700, color: "#4f46e5" }}>{stats?.customerReferrals || 0}</span><div style={{ fontSize: "0.7rem", color: "#64748b" }}>Total</div></div>
                  <div><span style={{ fontSize: "1.5rem", fontWeight: 700, color: "#d97706" }}>₹{Number(stats?.pendingAmount || 0).toFixed(0)}</span><div style={{ fontSize: "0.7rem", color: "#64748b" }}>Pending ₹</div></div>
                </div>
              </div>
            </div>
          </div>
          <div className="col-md-6">
            <div className="card" style={{ border: "1px solid #e2e8f0" }}>
              <div className="card-body p-3">
                <div className="fw-semibold mb-1" style={{ fontSize: "0.78rem", color: "#64748b" }}>DRIVER REFERRALS</div>
                <div className="d-flex gap-4">
                  <div><span style={{ fontSize: "1.5rem", fontWeight: 700, color: "#059669" }}>{stats?.driverReferrals || 0}</span><div style={{ fontSize: "0.7rem", color: "#64748b" }}>Total</div></div>
                  <div><span style={{ fontSize: "1.5rem", fontWeight: 700, color: "#059669" }}>₹{Number(stats?.totalRewarded || 0).toFixed(0)}</span><div style={{ fontSize: "0.7rem", color: "#64748b" }}>Rewarded</div></div>
                </div>
              </div>
            </div>
          </div>
        </div>

        <div className="card">
          <div className="card-body">
            <div className="d-flex flex-wrap gap-2 align-items-center justify-content-between mb-4">
              <h5 className="text-primary mb-0">Referral List</h5>
              <div className="d-flex gap-2 flex-wrap">
                <div className="d-flex gap-1 flex-wrap">
                  {["all", "pending", "paid", "expired"].map(s => (
                    <button
                      key={s}
                      className={`btn btn-sm ${statusFilter === s ? "btn-primary" : "btn-outline-secondary"}`}
                      onClick={() => setStatusFilter(s)}
                      data-testid={`filter-status-${s}`}
                      style={{ fontSize: "0.75rem" }}
                    >
                      {s === "all" ? "All" : s.charAt(0).toUpperCase() + s.slice(1)}
                    </button>
                  ))}
                </div>
                <div className="d-flex gap-1">
                  {["all", "customer", "driver"].map(t => (
                    <button
                      key={t}
                      className={`btn btn-sm ${typeFilter === t ? "btn-info text-white" : "btn-outline-secondary"}`}
                      onClick={() => setTypeFilter(t)}
                      data-testid={`filter-type-${t}`}
                      style={{ fontSize: "0.75rem" }}
                    >
                      {t === "all" ? "All Types" : t.charAt(0).toUpperCase() + t.slice(1)}
                    </button>
                  ))}
                </div>
              </div>
            </div>

            <div className="table-responsive">
              <table className="table table-borderless align-middle table-hover">
                <thead className="table-light" style={{ fontSize: "0.78rem" }}>
                  <tr>
                    <th>#</th>
                    <th>Referrer</th>
                    <th>Referred User</th>
                    <th>Code</th>
                    <th>Type</th>
                    <th className="text-end">Reward</th>
                    <th>Date</th>
                    <th className="text-center">Status</th>
                    <th className="text-center">Action</th>
                  </tr>
                </thead>
                <tbody style={{ fontSize: "0.8rem" }}>
                  {isLoading ? Array(5).fill(0).map((_, i) => (
                    <tr key={i}>{Array(9).fill(0).map((_, j) => <td key={j}><div style={{ height: 14, background: "#f1f5f9", borderRadius: 4 }} /></td>)}</tr>
                  )) : (referrals as any[]).length === 0 ? (
                    <tr>
                      <td colSpan={9} className="text-center py-4 text-muted">
                        <i className="bi bi-share fs-2 d-block mb-2 opacity-25"></i>
                        No referrals found
                      </td>
                    </tr>
                  ) : (referrals as any[]).map((r: any, i: number) => {
                    const ss = STATUS_STYLES[r.status] || STATUS_STYLES.pending;
                    return (
                      <tr key={r.id} data-testid={`referral-row-${r.id}`}>
                        <td>{i + 1}</td>
                        <td>
                          <div className="fw-semibold">{r.referrerName || "—"}</div>
                          <div style={{ fontSize: "0.7rem", color: "#64748b" }}>{r.referrerPhone}</div>
                          <span className={`badge ${r.referrerType === "driver" ? "bg-success" : "bg-info"} bg-opacity-10 text-${r.referrerType === "driver" ? "success" : "info"}`} style={{ fontSize: "0.65rem" }}>
                            {r.referrerType}
                          </span>
                        </td>
                        <td>
                          {r.referredName ? (
                            <>
                              <div className="fw-semibold">{r.referredName}</div>
                              <div style={{ fontSize: "0.7rem", color: "#64748b" }}>{r.referredPhone}</div>
                            </>
                          ) : (
                            <span className="text-muted" style={{ fontSize: "0.75rem" }}>Not yet registered</span>
                          )}
                        </td>
                        <td>
                          <code style={{ background: "#f1f5f9", padding: "2px 6px", borderRadius: 4, fontSize: "0.78rem" }}>
                            {r.referralCode}
                          </code>
                        </td>
                        <td>
                          <span className={`badge ${r.referralType === "driver" ? "bg-success" : "bg-primary"} bg-opacity-10 text-${r.referralType === "driver" ? "success" : "primary"}`} style={{ fontSize: "0.7rem" }}>
                            {r.referralType}
                          </span>
                        </td>
                        <td className="text-end fw-semibold">₹{Number(r.rewardAmount || 0).toFixed(0)}</td>
                        <td style={{ fontSize: "0.75rem", color: "#64748b" }}>{timeAgo(r.createdAt)}</td>
                        <td className="text-center">
                          <span style={{ background: ss.bg, color: ss.color, padding: "2px 10px", borderRadius: 12, fontSize: "0.7rem", fontWeight: 600 }}>
                            {ss.label}
                          </span>
                        </td>
                        <td className="text-center">
                          <div className="d-flex gap-1 justify-content-center">
                            {r.status === "pending" && (
                              <>
                                <button
                                  className="btn btn-sm btn-success"
                                  style={{ fontSize: "0.72rem", padding: "2px 8px" }}
                                  disabled={payMutation.isPending}
                                  onClick={() => { if (confirm(`Pay ₹${r.rewardAmount} to ${r.referrerName}?`)) payMutation.mutate(r.id); }}
                                  data-testid={`btn-pay-${r.id}`}
                                >
                                  <i className="bi bi-check-circle me-1"></i>Pay
                                </button>
                                <button
                                  className="btn btn-sm btn-outline-secondary"
                                  style={{ fontSize: "0.72rem", padding: "2px 8px" }}
                                  disabled={expireMutation.isPending}
                                  onClick={() => expireMutation.mutate(r.id)}
                                  data-testid={`btn-expire-${r.id}`}
                                >
                                  Expire
                                </button>
                              </>
                            )}
                            {r.status !== "pending" && (
                              <span style={{ fontSize: "0.72rem", color: "#94a3b8" }}>—</span>
                            )}
                          </div>
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>
          </div>
        </div>
      </div>
    </>
  );
}
