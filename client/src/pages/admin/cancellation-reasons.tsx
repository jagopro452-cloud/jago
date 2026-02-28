import { useState } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { apiRequest } from "@/lib/queryClient";
import { useToast } from "@/hooks/use-toast";

function Modal({ open, onClose, title, children }: any) {
  if (!open) return null;
  return (
    <div style={{ position: "fixed", inset: 0, background: "rgba(0,0,0,0.4)", zIndex: 9999, display: "flex", alignItems: "center", justifyContent: "center", padding: "1rem" }}>
      <div style={{ background: "#fff", borderRadius: "12px", width: "100%", maxWidth: "480px", padding: "1.5rem", boxShadow: "0 20px 60px rgba(0,0,0,0.2)" }}>
        <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", marginBottom: "1.25rem" }}>
          <h5 style={{ margin: 0, fontWeight: 700, color: "var(--title-color)", fontSize: "1rem" }}>{title}</h5>
          <button onClick={onClose} style={{ background: "none", border: "none", cursor: "pointer", color: "var(--bs-body-color)", fontSize: "1.2rem" }}>
            <i className="bi bi-x-lg"></i>
          </button>
        </div>
        {children}
      </div>
    </div>
  );
}

export default function CancellationReasonsPage() {
  const { toast } = useToast();
  const qc = useQueryClient();
  const [open, setOpen] = useState(false);
  const [form, setForm] = useState({ reason: "", userType: "customer" });

  const { data, isLoading } = useQuery<any[]>({ queryKey: ["/api/cancellation-reasons"] });

  const save = useMutation({
    mutationFn: (data: any) => apiRequest("POST", "/api/cancellation-reasons", data),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["/api/cancellation-reasons"] });
      toast({ title: "Reason added" });
      setOpen(false); setForm({ reason: "", userType: "customer" });
    },
  });

  const remove = useMutation({
    mutationFn: (id: string) => apiRequest("DELETE", `/api/cancellation-reasons/${id}`),
    onSuccess: () => { qc.invalidateQueries({ queryKey: ["/api/cancellation-reasons"] }); toast({ title: "Reason deleted" }); },
  });

  const customerReasons = data?.filter(r => r.userType === "customer") || [];
  const driverReasons = data?.filter(r => r.userType === "driver") || [];

  return (
    <div>
      <div className="jago-page-header">
        <div>
          <h4 className="page-title" data-testid="page-title">Cancellation Reasons</h4>
          <div className="breadcrumb">
            <i className="bi bi-house-fill"></i>
            <span>Home</span>
            <i className="bi bi-chevron-right" style={{ fontSize: "0.65rem" }}></i>
            <span>Trip Management</span>
            <i className="bi bi-chevron-right" style={{ fontSize: "0.65rem" }}></i>
            <span>Cancel Reasons</span>
          </div>
        </div>
        <button className="btn-jago-primary" onClick={() => setOpen(true)} data-testid="btn-add-reason">
          <i className="bi bi-plus-circle-fill"></i> Add Reason
        </button>
      </div>

      <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: "1.25rem" }}>
        {[
          { title: "Customer Reasons", reasons: customerReasons, type: "customer", icon: "bi-people-fill" },
          { title: "Driver Reasons", reasons: driverReasons, type: "driver", icon: "bi-person-badge-fill" },
        ].map(group => (
          <div key={group.type} className="jago-card">
            <div className="jago-card-header">
              <h5 className="jago-card-title">
                <i className={`bi ${group.icon}`} style={{ marginRight: "0.5rem", color: "var(--bs-primary)" }}></i>
                {group.title}
              </h5>
              <span className="jago-badge badge-primary">{group.reasons.length}</span>
            </div>
            {isLoading ? (
              <div style={{ padding: "1rem", display: "flex", flexDirection: "column", gap: "0.625rem" }}>
                {Array(3).fill(0).map((_, i) => <div key={i} style={{ height: "40px", background: "#f1f5f9", borderRadius: "6px" }} />)}
              </div>
            ) : group.reasons.length ? (
              <ul style={{ listStyle: "none", padding: 0, margin: 0 }}>
                {group.reasons.map((r: any, idx: number) => (
                  <li
                    key={r.id}
                    style={{
                      display: "flex",
                      alignItems: "center",
                      justifyContent: "space-between",
                      padding: "0.75rem 1rem",
                      borderTop: idx === 0 ? "1px solid var(--bs-border-color)" : "none",
                      borderBottom: "1px solid var(--bs-border-color)",
                    }}
                    data-testid={`reason-${r.id}`}
                  >
                    <div style={{ display: "flex", alignItems: "center", gap: "0.5rem" }}>
                      <i className="bi bi-dash-circle" style={{ color: "var(--bs-danger)", fontSize: "0.75rem" }}></i>
                      <span style={{ fontSize: "0.85rem" }}>{r.reason}</span>
                    </div>
                    <button
                      style={{ background: "none", border: "none", cursor: "pointer", color: "var(--bs-danger)", padding: "0.2rem 0.4rem", borderRadius: "4px", fontSize: "0.85rem" }}
                      onClick={() => remove.mutate(r.id)}
                      data-testid={`btn-delete-reason-${r.id}`}
                    >
                      <i className="bi bi-trash-fill"></i>
                    </button>
                  </li>
                ))}
              </ul>
            ) : (
              <div className="jago-empty">
                <i className="bi bi-x-circle"></i>
                <p>No reasons added</p>
              </div>
            )}
          </div>
        ))}
      </div>

      <Modal open={open} onClose={() => setOpen(false)} title="Add Cancellation Reason">
        <div style={{ display: "flex", flexDirection: "column", gap: "1rem" }}>
          <div>
            <label className="jago-label">User Type</label>
            <select
              className="jago-input"
              value={form.userType}
              onChange={e => setForm(f => ({ ...f, userType: e.target.value }))}
            >
              <option value="customer">Customer</option>
              <option value="driver">Driver</option>
            </select>
          </div>
          <div>
            <label className="jago-label">Reason *</label>
            <input
              className="jago-input"
              value={form.reason}
              onChange={e => setForm(f => ({ ...f, reason: e.target.value }))}
              placeholder="e.g. Driver not arriving"
              data-testid="input-reason"
            />
          </div>
          <div style={{ display: "flex", gap: "0.75rem", justifyContent: "flex-end", marginTop: "0.5rem" }}>
            <button className="btn-jago-outline" onClick={() => setOpen(false)}>Cancel</button>
            <button
              className="btn-jago-primary"
              onClick={() => save.mutate(form)}
              disabled={!form.reason || save.isPending}
              data-testid="btn-save-reason"
            >
              {save.isPending ? "Saving..." : "Add Reason"}
            </button>
          </div>
        </div>
      </Modal>
    </div>
  );
}
