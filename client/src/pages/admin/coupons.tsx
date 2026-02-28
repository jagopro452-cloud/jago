import { useState } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { apiRequest } from "@/lib/queryClient";
import { useToast } from "@/hooks/use-toast";

function Modal({ open, onClose, title, children }: any) {
  if (!open) return null;
  return (
    <div style={{ position: "fixed", inset: 0, background: "rgba(0,0,0,0.4)", zIndex: 9999, display: "flex", alignItems: "center", justifyContent: "center", padding: "1rem" }}>
      <div style={{ background: "#fff", borderRadius: "12px", width: "100%", maxWidth: "560px", padding: "1.5rem", boxShadow: "0 20px 60px rgba(0,0,0,0.2)" }}>
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

export default function Coupons() {
  const { toast } = useToast();
  const qc = useQueryClient();
  const [open, setOpen] = useState(false);
  const [editing, setEditing] = useState<any>(null);
  const [form, setForm] = useState({ name: "", code: "", discountAmount: "", discountType: "amount", minTripAmount: "", limitPerUser: "1" });

  const { data, isLoading } = useQuery<any[]>({ queryKey: ["/api/coupons"] });

  const save = useMutation({
    mutationFn: (data: any) => editing
      ? apiRequest("PUT", `/api/coupons/${editing.id}`, data)
      : apiRequest("POST", "/api/coupons", data),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["/api/coupons"] });
      toast({ title: editing ? "Coupon updated" : "Coupon created" });
      setOpen(false); setEditing(null);
      setForm({ name: "", code: "", discountAmount: "", discountType: "amount", minTripAmount: "", limitPerUser: "1" });
    },
    onError: (e: any) => toast({ title: "Error", description: e.message, variant: "destructive" }),
  });

  const remove = useMutation({
    mutationFn: (id: string) => apiRequest("DELETE", `/api/coupons/${id}`),
    onSuccess: () => { qc.invalidateQueries({ queryKey: ["/api/coupons"] }); toast({ title: "Coupon deleted" }); },
  });

  const openCreate = () => { setEditing(null); setForm({ name: "", code: "", discountAmount: "", discountType: "amount", minTripAmount: "", limitPerUser: "1" }); setOpen(true); };
  const openEdit = (c: any) => {
    setEditing(c);
    setForm({ name: c.name, code: c.code, discountAmount: String(c.discountAmount || ""), discountType: c.discountType || "amount", minTripAmount: String(c.minTripAmount || ""), limitPerUser: String(c.limitPerUser || "1") });
    setOpen(true);
  };

  return (
    <div>
      <div className="jago-page-header">
        <div>
          <h4 className="page-title" data-testid="page-title">Coupon Setup</h4>
          <div className="breadcrumb">
            <i className="bi bi-house-fill"></i>
            <span>Home</span>
            <i className="bi bi-chevron-right" style={{ fontSize: "0.65rem" }}></i>
            <span>Promotion Management</span>
            <i className="bi bi-chevron-right" style={{ fontSize: "0.65rem" }}></i>
            <span>Coupons</span>
          </div>
        </div>
        <button className="btn-jago-primary" onClick={openCreate} data-testid="btn-add-coupon">
          <i className="bi bi-plus-circle-fill"></i> Add Coupon
        </button>
      </div>

      <div className="jago-card">
        <div className="jago-card-header">
          <h5 className="jago-card-title">
            <i className="bi bi-ticket-fill" style={{ marginRight: "0.5rem", color: "var(--bs-primary)" }}></i>
            Coupon Codes
          </h5>
        </div>
        <div className="jago-table-wrapper">
          <table className="jago-table">
            <thead>
              <tr>
                <th>#</th>
                <th>Name</th>
                <th>Code</th>
                <th>Discount</th>
                <th>Min Fare</th>
                <th>Limit/User</th>
                <th>Status</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              {isLoading ? Array(4).fill(0).map((_, i) => (
                <tr key={i}>
                  {Array(8).fill(0).map((_, j) => <td key={j}><div style={{ height: "14px", background: "#f1f5f9", borderRadius: "4px" }} /></td>)}
                </tr>
              )) : data?.length ? data.map((c: any, idx: number) => (
                <tr key={c.id} data-testid={`coupon-row-${c.id}`}>
                  <td style={{ color: "var(--bs-body-color)", fontSize: "0.8rem" }}>{idx + 1}</td>
                  <td style={{ fontWeight: 600 }}>{c.name}</td>
                  <td>
                    <span style={{ fontFamily: "monospace", background: "#f1f5f9", padding: "0.2rem 0.5rem", borderRadius: "4px", fontWeight: 600, fontSize: "0.8rem", color: "var(--bs-primary)" }}>{c.code}</span>
                  </td>
                  <td style={{ fontWeight: 600 }}>
                    {c.discountType === "percentage" ? `${c.discountAmount}%` : `₹${c.discountAmount}`}
                  </td>
                  <td>₹{c.minTripAmount}</td>
                  <td style={{ textAlign: "center" }}>{c.limitPerUser}</td>
                  <td>
                    <span className={`jago-badge ${c.isActive ? "badge-active" : "badge-inactive"}`}>
                      {c.isActive ? "Active" : "Inactive"}
                    </span>
                  </td>
                  <td>
                    <div style={{ display: "flex", gap: "0.375rem" }}>
                      <button
                        style={{ background: "none", border: "none", cursor: "pointer", color: "var(--bs-primary)", padding: "0.2rem 0.4rem", borderRadius: "4px", fontSize: "0.85rem" }}
                        onClick={() => openEdit(c)}
                        data-testid={`btn-edit-coupon-${c.id}`}
                      >
                        <i className="bi bi-pencil-fill"></i>
                      </button>
                      <button
                        style={{ background: "none", border: "none", cursor: "pointer", color: "var(--bs-danger)", padding: "0.2rem 0.4rem", borderRadius: "4px", fontSize: "0.85rem" }}
                        onClick={() => { if (confirm("Delete this coupon?")) remove.mutate(c.id); }}
                        data-testid={`btn-delete-coupon-${c.id}`}
                      >
                        <i className="bi bi-trash-fill"></i>
                      </button>
                    </div>
                  </td>
                </tr>
              )) : (
                <tr>
                  <td colSpan={8}>
                    <div className="jago-empty">
                      <i className="bi bi-ticket"></i>
                      <p>No coupons created yet</p>
                    </div>
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </div>

      <Modal open={open} onClose={() => setOpen(false)} title={editing ? "Edit Coupon" : "Add Coupon"}>
        <div style={{ display: "flex", flexDirection: "column", gap: "1rem" }}>
          <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: "1rem" }}>
            <div>
              <label className="jago-label">Coupon Name *</label>
              <input className="jago-input" value={form.name} onChange={e => setForm(f => ({ ...f, name: e.target.value }))} placeholder="e.g. Welcome Offer" data-testid="input-coupon-name" />
            </div>
            <div>
              <label className="jago-label">Coupon Code *</label>
              <input className="jago-input" value={form.code} onChange={e => setForm(f => ({ ...f, code: e.target.value.toUpperCase() }))} placeholder="e.g. WELCOME50" data-testid="input-coupon-code" />
            </div>
          </div>
          <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: "1rem" }}>
            <div>
              <label className="jago-label">Discount Type</label>
              <select className="jago-input" value={form.discountType} onChange={e => setForm(f => ({ ...f, discountType: e.target.value }))}>
                <option value="amount">Fixed Amount (₹)</option>
                <option value="percentage">Percentage (%)</option>
              </select>
            </div>
            <div>
              <label className="jago-label">Discount {form.discountType === "percentage" ? "%" : "₹"}</label>
              <input type="number" className="jago-input" value={form.discountAmount} onChange={e => setForm(f => ({ ...f, discountAmount: e.target.value }))} data-testid="input-discount-amount" />
            </div>
          </div>
          <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: "1rem" }}>
            <div>
              <label className="jago-label">Min Trip Amount (₹)</label>
              <input type="number" className="jago-input" value={form.minTripAmount} onChange={e => setForm(f => ({ ...f, minTripAmount: e.target.value }))} />
            </div>
            <div>
              <label className="jago-label">Limit Per User</label>
              <input type="number" className="jago-input" value={form.limitPerUser} onChange={e => setForm(f => ({ ...f, limitPerUser: e.target.value }))} />
            </div>
          </div>
          <div style={{ display: "flex", gap: "0.75rem", justifyContent: "flex-end", marginTop: "0.5rem" }}>
            <button className="btn-jago-outline" onClick={() => setOpen(false)}>Cancel</button>
            <button
              className="btn-jago-primary"
              onClick={() => save.mutate(form)}
              disabled={!form.name || !form.code || save.isPending}
              data-testid="btn-save-coupon"
            >
              {save.isPending ? "Saving..." : editing ? "Update" : "Create"}
            </button>
          </div>
        </div>
      </Modal>
    </div>
  );
}
