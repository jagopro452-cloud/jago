import { useState } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { apiRequest } from "@/lib/queryClient";
import { useToast } from "@/hooks/use-toast";

function CouponModal({ open, onClose, editing, form, setForm, onSave, saving }: any) {
  if (!open) return null;
  return (
    <div className="modal-backdrop-jago">
      <div className="modal-jago" style={{ maxWidth: "560px" }}>
        <div className="modal-jago-header">
          <h5 className="modal-jago-title">{editing ? "Edit Coupon" : "Add Coupon"}</h5>
          <button className="modal-jago-close" onClick={onClose}><i className="bi bi-x-lg"></i></button>
        </div>
        <div className="d-flex flex-column gap-3">
          <div className="row g-3">
            <div className="col-6">
              <label className="form-label-jago">Coupon Name <span className="text-danger">*</span></label>
              <input className="form-control" value={form.name} onChange={e => setForm((f: any) => ({ ...f, name: e.target.value }))} placeholder="e.g. Welcome Offer" data-testid="input-coupon-name" />
            </div>
            <div className="col-6">
              <label className="form-label-jago">Coupon Code <span className="text-danger">*</span></label>
              <input className="form-control" value={form.code} onChange={e => setForm((f: any) => ({ ...f, code: e.target.value.toUpperCase() }))} placeholder="e.g. WELCOME50" data-testid="input-coupon-code" />
            </div>
          </div>
          <div className="row g-3">
            <div className="col-6">
              <label className="form-label-jago">Discount Type</label>
              <select className="form-select" value={form.discountType} onChange={e => setForm((f: any) => ({ ...f, discountType: e.target.value }))}>
                <option value="amount">Fixed Amount (₹)</option>
                <option value="percentage">Percentage (%)</option>
              </select>
            </div>
            <div className="col-6">
              <label className="form-label-jago">Discount {form.discountType === "percentage" ? "%" : "₹"}</label>
              <input type="number" className="form-control" value={form.discountAmount} onChange={e => setForm((f: any) => ({ ...f, discountAmount: e.target.value }))} data-testid="input-discount-amount" />
            </div>
          </div>
          <div className="row g-3">
            <div className="col-6">
              <label className="form-label-jago">Min Trip Amount (₹)</label>
              <input type="number" className="form-control" value={form.minTripAmount} onChange={e => setForm((f: any) => ({ ...f, minTripAmount: e.target.value }))} />
            </div>
            <div className="col-6">
              <label className="form-label-jago">Limit Per User</label>
              <input type="number" className="form-control" value={form.limitPerUser} onChange={e => setForm((f: any) => ({ ...f, limitPerUser: e.target.value }))} />
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
  const [form, setForm] = useState({ name: "", code: "", discountType: "amount", discountAmount: "50", minTripAmount: "0", limitPerUser: "1" });

  const { data, isLoading } = useQuery<any>({
    queryKey: ["/api/coupons", { page }],
    queryFn: () => fetch(`/api/coupons?page=${page}&limit=15`).then(r => r.json()),
  });

  const save = useMutation({
    mutationFn: (d: any) => editing
      ? apiRequest("PUT", `/api/coupons/${editing.id}`, d)
      : apiRequest("POST", "/api/coupons", d),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["/api/coupons"] });
      toast({ title: editing ? "Coupon updated" : "Coupon created" });
      setOpen(false); setEditing(null);
      setForm({ name: "", code: "", discountType: "amount", discountAmount: "50", minTripAmount: "0", limitPerUser: "1" });
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

  const openCreate = () => { setEditing(null); setForm({ name: "", code: "", discountType: "amount", discountAmount: "50", minTripAmount: "0", limitPerUser: "1" }); setOpen(true); };
  const openEdit = (c: any) => {
    setEditing(c);
    setForm({ name: c.name, code: c.code, discountType: c.discountType || "amount", discountAmount: String(c.discountAmount || 50), minTripAmount: String(c.minTripAmount || 0), limitPerUser: String(c.limitPerUser || 1) });
    setOpen(true);
  };

  const totalPages = Math.ceil((data?.total || 0) / 15);
  const coupons = data?.data || data || [];

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
                  <th>Status</th>
                  <th className="text-center">Action</th>
                </tr>
              </thead>
              <tbody>
                {isLoading ? (
                  Array(5).fill(0).map((_, i) => (
                    <tr key={i}>{Array(8).fill(0).map((_, j) => <td key={j}><div style={{ height: "14px", background: "#f1f5f9", borderRadius: "4px" }} /></td>)}</tr>
                  ))
                ) : coupons.length ? (
                  coupons.map((c: any, idx: number) => (
                    <tr key={c.id} data-testid={`coupon-row-${c.id}`}>
                      <td>{(page - 1) * 15 + idx + 1}</td>
                      <td className="fw-medium title-color">{c.name}</td>
                      <td><span className="badge bg-primary">{c.code}</span></td>
                      <td>
                        {c.discountType === "percentage"
                          ? `${c.discountAmount}%`
                          : `₹${c.discountAmount}`}
                      </td>
                      <td>₹{c.minTripAmount || 0}</td>
                      <td>{c.limitPerUser || 1}x</td>
                      <td>
                        <label className="switcher">
                          <input type="checkbox" className="switcher_input" checked={c.isActive} onChange={() => toggleStatus.mutate({ id: c.id, isActive: !c.isActive })} data-testid={`toggle-coupon-${c.id}`} />
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
                  <tr><td colSpan={8}>
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
