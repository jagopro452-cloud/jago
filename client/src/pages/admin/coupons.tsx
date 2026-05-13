import { useState } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { apiRequest } from "@/lib/queryClient";
import { useToast } from "@/hooks/use-toast";

const EMPTY_FORM = {
  name: "", code: "", discountType: "amount", discountAmount: "50",
  minTripAmount: "0", maxDiscountAmount: "", limitPerUser: "1",
  totalUsageLimit: "", endDate: "",
};

function CouponModal({ open, onClose, editing, form, setForm, onSave, saving }: any) {
  if (!open) return null;
  const f = (key: string, val: string) => setForm((p: any) => ({ ...p, [key]: val }));
  return (
    <div className="modal-backdrop-jago">
      <div className="modal-jago" style={{ maxWidth: "600px" }}>
        <div className="modal-jago-header">
          <h5 className="modal-jago-title">{editing ? "Edit Coupon" : "Add Coupon"}</h5>
          <button className="modal-jago-close" onClick={onClose}><i className="bi bi-x-lg"></i></button>
        </div>
        <div className="d-flex flex-column gap-3">
          {/* Row 1: name + code */}
          <div className="row g-3">
            <div className="col-6">
              <label className="form-label-jago">Coupon Name <span className="text-danger">*</span></label>
              <input className="form-control" value={form.name} onChange={e => f("name", e.target.value)} placeholder="e.g. Welcome Offer" data-testid="input-coupon-name" />
            </div>
            <div className="col-6">
              <label className="form-label-jago">Coupon Code <span className="text-danger">*</span></label>
              <input className="form-control" value={form.code} onChange={e => f("code", e.target.value.toUpperCase())} placeholder="e.g. WELCOME50" data-testid="input-coupon-code" />
            </div>
          </div>
          {/* Row 2: discount type + value */}
          <div className="row g-3">
            <div className="col-6">
              <label className="form-label-jago">Discount Type</label>
              <select className="form-select" value={form.discountType} onChange={e => f("discountType", e.target.value)}>
                <option value="amount">Fixed Amount (₹)</option>
                <option value="percentage">Percentage (%)</option>
              </select>
            </div>
            <div className="col-6">
              <label className="form-label-jago">Discount {form.discountType === "percentage" ? "%" : "₹"} <span className="text-danger">*</span></label>
              <input type="number" min="0" className="form-control" value={form.discountAmount} onChange={e => f("discountAmount", e.target.value)} data-testid="input-discount-amount" />
            </div>
          </div>
          {/* Row 3: max discount cap + min trip */}
          <div className="row g-3">
            <div className="col-6">
              <label className="form-label-jago">
                Max Discount (₹)
                <small className="text-muted ms-1">{form.discountType === "percentage" ? "— caps % discount" : "— optional"}</small>
              </label>
              <input type="number" min="0" className="form-control" value={form.maxDiscountAmount} onChange={e => f("maxDiscountAmount", e.target.value)} placeholder="No cap" />
            </div>
            <div className="col-6">
              <label className="form-label-jago">Min Trip Amount (₹)</label>
              <input type="number" min="0" className="form-control" value={form.minTripAmount} onChange={e => f("minTripAmount", e.target.value)} />
            </div>
          </div>
          {/* Row 4: per-user limit + total usage + expiry */}
          <div className="row g-3">
            <div className="col-4">
              <label className="form-label-jago">Limit Per User</label>
              <input type="number" min="1" className="form-control" value={form.limitPerUser} onChange={e => f("limitPerUser", e.target.value)} />
            </div>
            <div className="col-4">
              <label className="form-label-jago">Total Usage Limit</label>
              <input type="number" min="0" className="form-control" value={form.totalUsageLimit} onChange={e => f("totalUsageLimit", e.target.value)} placeholder="Unlimited" />
            </div>
            <div className="col-4">
              <label className="form-label-jago">Expiry Date</label>
              <input type="date" className="form-control" value={form.endDate} onChange={e => f("endDate", e.target.value)} />
            </div>
          </div>
          <div className="d-flex gap-2 justify-content-end mt-2">
            <button className="btn btn-outline-secondary" onClick={onClose}>Cancel</button>
            <button className="btn btn-primary" onClick={onSave} disabled={!form.name || !form.code || saving} data-testid="btn-save-coupon">
              {saving ? "Saving..." : editing ? "Update" : "Create"}
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}

export default function Coupons() {
  const { toast } = useToast();
  const qc = useQueryClient();
  const [open, setOpen] = useState(false);
  const [editing, setEditing] = useState<any>(null);
  const [page, setPage] = useState(1);
  const [form, setForm] = useState({ ...EMPTY_FORM });

  const { data, isLoading } = useQuery<any>({
    queryKey: ["/api/coupons", { page }],
    queryFn: () => fetch(`/api/coupons?page=${page}&limit=15`)
      .then(r => r.ok ? r.json() : r.json().then(d => { throw new Error(d?.message || "Error"); }))
      .then(d => d?.data ? d : { data: Array.isArray(d) ? d : [], total: 0 }),
  });

  const resetForm = () => setForm({ ...EMPTY_FORM });

  const save = useMutation({
    mutationFn: (d: any) => editing
      ? apiRequest("PUT", `/api/coupons/${editing.id}`, d)
      : apiRequest("POST", "/api/coupons", d),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["/api/coupons"] });
      toast({ title: editing ? "Coupon updated" : "Coupon created" });
      setOpen(false); setEditing(null); resetForm();
    },
    onError: (e: any) => toast({ title: "Error", description: e.message, variant: "destructive" }),
  });

  const remove = useMutation({
    mutationFn: (id: string) => apiRequest("DELETE", `/api/coupons/${id}`),
    onSuccess: () => { qc.invalidateQueries({ queryKey: ["/api/coupons"] }); toast({ title: "Coupon deleted" }); },
  });

  const toggleStatus = useMutation({
    mutationFn: ({ id, isActive }: { id: string; isActive: boolean }) =>
      apiRequest("PATCH", `/api/coupons/${id}`, { isActive }),
    onSuccess: () => qc.invalidateQueries({ queryKey: ["/api/coupons"] }),
  });

  const openCreate = () => { setEditing(null); resetForm(); setOpen(true); };
  const openEdit = (c: any) => {
    setEditing(c);
    // Normalize date for input[type=date] (ISO → YYYY-MM-DD)
    const endDate = c.endDate ? c.endDate.substring(0, 10) : "";
    setForm({
      name: c.name || "",
      code: c.code || "",
      discountType: c.discountType || "amount",
      discountAmount: String(c.discountAmount || 50),
      minTripAmount: String(c.minTripAmount || 0),
      maxDiscountAmount: c.maxDiscountAmount ? String(c.maxDiscountAmount) : "",
      limitPerUser: String(c.limitPerUser || 1),
      totalUsageLimit: c.totalUsageLimit ? String(c.totalUsageLimit) : "",
      endDate,
    });
    setOpen(true);
  };

  const formatDiscount = (c: any) => {
    const isPercent = c.discountType === "percentage" || c.discountType === "percent";
    const label = isPercent ? `${c.discountAmount}%` : `₹${c.discountAmount}`;
    const cap = c.maxDiscountAmount ? ` (max ₹${c.maxDiscountAmount})` : "";
    return label + cap;
  };

  const formatExpiry = (c: any) => {
    if (!c.endDate) return "—";
    try {
      const dt = new Date(c.endDate);
      return dt.toLocaleDateString("en-IN", { day: "2-digit", month: "short", year: "numeric" });
    } catch { return c.endDate; }
  };

  const totalPages = Math.ceil((data?.total || 0) / 15);
  const coupons: any[] = data?.data || (Array.isArray(data) ? data : []);

  return (
    <div className="container-fluid">
      <div className="d-flex align-items-center justify-content-between mb-4">
        <h2 className="fs-22 text-capitalize mb-0" data-testid="page-title">Coupon Setup</h2>
        <button className="btn btn-primary" onClick={openCreate} data-testid="btn-add-coupon">
          <i className="bi bi-plus-circle me-1"></i> Add Coupon
        </button>
      </div>

      <div className="card">
        <div className="card-body">
          <div className="table-responsive">
            <table className="table table-borderless align-middle table-hover">
              <thead className="table-light align-middle text-capitalize">
                <tr>
                  <th>SL</th>
                  <th>Coupon Name</th>
                  <th>Code</th>
                  <th>Discount</th>
                  <th>Min Amount</th>
                  <th>Limit/User</th>
                  <th>Total Uses</th>
                  <th>Expiry</th>
                  <th>Status</th>
                  <th className="text-center">Action</th>
                </tr>
              </thead>
              <tbody>
                {isLoading ? (
                  Array(5).fill(0).map((_, i) => (
                    <tr key={i}>{Array(10).fill(0).map((_, j) => <td key={j}><div style={{ height: "14px", background: "#f1f5f9", borderRadius: "4px" }} /></td>)}</tr>
                  ))
                ) : coupons.length ? (
                  coupons.map((c: any, idx: number) => (
                    <tr key={c.id} data-testid={`coupon-row-${c.id}`}>
                      <td>{(page - 1) * 15 + idx + 1}</td>
                      <td className="fw-medium title-color">{c.name}</td>
                      <td><span className="badge bg-primary" style={{ letterSpacing: "1px" }}>{c.code}</span></td>
                      <td><span className="badge bg-success-subtle text-success">{formatDiscount(c)}</span></td>
                      <td>{c.minTripAmount > 0 ? `₹${c.minTripAmount}` : "—"}</td>
                      <td>{c.limitPerUser || 1}x</td>
                      <td>{c.totalUsageLimit || <span className="text-muted">∞</span>}</td>
                      <td className={c.endDate && new Date(c.endDate) < new Date() ? "text-danger" : ""}>{formatExpiry(c)}</td>
                      <td>
                        <label className="switcher">
                          <input type="checkbox" className="switcher_input" checked={!!c.isActive} onChange={() => toggleStatus.mutate({ id: c.id, isActive: !c.isActive })} data-testid={`toggle-coupon-${c.id}`} />
                          <span className="switcher_control"></span>
                        </label>
                      </td>
                      <td className="text-center">
                        <div className="d-flex justify-content-center gap-2">
                          <button className="btn btn-sm btn-outline-primary" onClick={() => openEdit(c)} data-testid={`btn-edit-coupon-${c.id}`}><i className="bi bi-pencil-fill"></i></button>
                          <button className="btn btn-sm btn-outline-danger" onClick={() => { if (confirm("Delete this coupon?")) remove.mutate(c.id); }} data-testid={`btn-delete-coupon-${c.id}`}><i className="bi bi-trash-fill"></i></button>
                        </div>
                      </td>
                    </tr>
                  ))
                ) : (
                  <tr><td colSpan={10}>
                    <div className="d-flex flex-column justify-content-center align-items-center gap-2 py-4">
                      <i className="bi bi-ticket" style={{ fontSize: "2rem", color: "#94a3b8" }}></i>
                      <p className="text-muted mb-0">No coupons found</p>
                    </div>
                  </td></tr>
                )}
              </tbody>
            </table>
          </div>
          {totalPages > 1 && (
            <div className="d-flex flex-wrap align-items-center justify-content-end gap-2 mt-3">
              <button className="btn btn-sm btn-outline-secondary" onClick={() => setPage(p => Math.max(1, p - 1))} disabled={page === 1}><i className="bi bi-chevron-left"></i></button>
              {Array.from({ length: Math.min(5, totalPages) }, (_, i) => i + 1).map(p => (
                <button key={p} className={`btn btn-sm ${p === page ? "btn-primary" : "btn-outline-secondary"}`} onClick={() => setPage(p)}>{p}</button>
              ))}
              <button className="btn btn-sm btn-outline-secondary" onClick={() => setPage(p => Math.min(totalPages, p + 1))} disabled={page === totalPages}><i className="bi bi-chevron-right"></i></button>
            </div>
          )}
        </div>
      </div>

      <CouponModal open={open} onClose={() => setOpen(false)} editing={editing} form={form} setForm={setForm} onSave={() => save.mutate(form)} saving={save.isPending} />
    </div>
  );
}
