import { useQuery, useMutation } from "@tanstack/react-query";
import { queryClient, apiRequest } from "@/lib/queryClient";
import { useState } from "react";
import { useToast } from "@/hooks/use-toast";

export default function DiscountsPage() {
  const { toast } = useToast();
  const [showModal, setShowModal] = useState(false);
  const [editing, setEditing] = useState<any>(null);
  const [form, setForm] = useState({ name: "", discountAmount: "", discountType: "percentage", minOrderAmount: "", maxDiscountAmount: "", isActive: true });

  const { data, isLoading } = useQuery<any[]>({ queryKey: ["/api/discounts"] });
  const discounts = Array.isArray(data) ? data : [];

  const saveMutation = useMutation({
    mutationFn: (payload: any) =>
      editing
        ? apiRequest("PUT", `/api/discounts/${editing.id}`, payload)
        : apiRequest("POST", "/api/discounts", payload),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["/api/discounts"] });
      setShowModal(false);
      toast({ title: editing ? "Discount updated" : "Discount created" });
      setEditing(null);
    },
    onError: () => toast({ title: "Failed to save", variant: "destructive" }),
  });

  const deleteMutation = useMutation({
    mutationFn: (id: string) => apiRequest("DELETE", `/api/discounts/${id}`),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["/api/discounts"] });
      toast({ title: "Discount deleted" });
    },
  });

  const toggleMutation = useMutation({
    mutationFn: ({ id, isActive }: { id: string; isActive: boolean }) =>
      apiRequest("PATCH", `/api/discounts/${id}`, { isActive }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["/api/discounts"] });
      toast({ title: "Status updated" });
    },
    onError: () => toast({ title: "Failed to update status", variant: "destructive" }),
  });

  const openAdd = () => {
    setEditing(null);
    setForm({ name: "", discountAmount: "", discountType: "percentage", minOrderAmount: "", maxDiscountAmount: "", isActive: true });
    setShowModal(true);
  };

  const openEdit = (d: any) => {
    setEditing(d);
    setForm({ name: d.name, discountAmount: d.discountAmount, discountType: d.discountType, minOrderAmount: d.minOrderAmount || "", maxDiscountAmount: d.maxDiscountAmount || "", isActive: d.isActive });
    setShowModal(true);
  };

  return (
    <>
    
      <div className="content-header">
        <div className="container-fluid">
          <div className="d-flex align-items-center justify-content-between gap-3 flex-wrap mb-3">
            <h2 className="h5 mb-0">Discount Setup</h2>
            <button className="btn btn-primary btn-sm" onClick={openAdd} data-testid="btn-add-discount">
              <i className="bi bi-plus me-1"></i>Add Discount
            </button>
          </div>
        </div>
      </div>
      <div className="container-fluid">
        <div className="card">
          <div className="card-body">
            <div className="table-responsive">
              <table className="table table-borderless align-middle table-hover">
                <thead className="table-light">
                  <tr>
                    <th>#</th>
                    <th>Name</th>
                    <th>Discount</th>
                    <th>Type</th>
                    <th>Min Order</th>
                    <th>Status</th>
                    <th>Action</th>
                  </tr>
                </thead>
                <tbody>
                  {isLoading ? (
                    <tr><td colSpan={7} className="text-center py-4"><div className="spinner-border spinner-border-sm" role="status" /></td></tr>
                  ) : discounts.length === 0 ? (
                    <tr>
                      <td colSpan={7} className="text-center py-5 text-muted">
                        <i className="bi bi-percent fs-2 d-block mb-2 opacity-25"></i>
                        No discounts found. Click Add Discount to create one.
                      </td>
                    </tr>
                  ) : discounts.map((d: any, idx: number) => (
                    <tr key={d.id} data-testid={`row-discount-${d.id}`}>
                      <td>{idx + 1}</td>
                      <td className="fw-semibold">{d.name}</td>
                      <td>{d.discountAmount}</td>
                      <td className="text-capitalize">{d.discountType}</td>
                      <td>{d.minOrderAmount || "—"}</td>
                      <td>
                        <span className={`badge ${d.isActive ? "bg-success" : "bg-secondary"}`}>
                          {d.isActive ? "Active" : "Inactive"}
                        </span>
                      </td>
                      <td>
                        <button
                          className={`btn btn-sm me-1 ${d.isActive ? "btn-outline-warning" : "btn-outline-success"}`}
                          onClick={() => toggleMutation.mutate({ id: d.id, isActive: !d.isActive })}
                          title={d.isActive ? "Deactivate" : "Activate"}
                          data-testid={`btn-toggle-discount-${d.id}`}
                        >
                          <i className={`bi ${d.isActive ? "bi-toggle-on" : "bi-toggle-off"}`}></i>
                        </button>
                        <button className="btn btn-sm btn-outline-primary me-1" onClick={() => openEdit(d)} data-testid={`btn-edit-discount-${d.id}`}>
                          <i className="bi bi-pencil-fill"></i>
                        </button>
                        <button
                          className="btn btn-sm btn-outline-danger"
                          onClick={() => { if (confirm("Delete this discount?")) deleteMutation.mutate(d.id); }}
                          data-testid={`btn-delete-discount-${d.id}`}
                        >
                          <i className="bi bi-trash-fill"></i>
                        </button>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        </div>
      </div>

      {showModal && (
        <div className="modal fade show d-block" style={{ background: "rgba(0,0,0,0.5)" }}>
          <div className="modal-dialog">
            <div className="modal-content">
              <div className="modal-header">
                <h5 className="modal-title">{editing ? "Edit Discount" : "Add Discount"}</h5>
                <button className="btn-close" onClick={() => setShowModal(false)} />
              </div>
              <div className="modal-body">
                <div className="mb-3">
                  <label className="form-label fw-semibold">Name <span className="text-danger">*</span></label>
                  <input className="form-control" value={form.name} onChange={e => setForm({ ...form, name: e.target.value })} data-testid="input-discount-name" />
                </div>
                <div className="row g-3 mb-3">
                  <div className="col-6">
                    <label className="form-label fw-semibold">Discount Amount <span className="text-danger">*</span></label>
                    <input className="form-control" type="number" min="0" value={form.discountAmount} onChange={e => setForm({ ...form, discountAmount: e.target.value })} data-testid="input-discount-amount" />
                  </div>
                  <div className="col-6">
                    <label className="form-label fw-semibold">Type</label>
                    <select className="form-select" value={form.discountType} onChange={e => setForm({ ...form, discountType: e.target.value })} data-testid="select-discount-type">
                      <option value="percentage">Percentage (%)</option>
                      <option value="amount">Fixed Amount (₹)</option>
                    </select>
                  </div>
                </div>
                <div className="row g-3 mb-3">
                  <div className="col-6">
                    <label className="form-label fw-semibold">Min Order Amount</label>
                    <input className="form-control" type="number" min="0" value={form.minOrderAmount} onChange={e => setForm({ ...form, minOrderAmount: e.target.value })} data-testid="input-min-order" />
                  </div>
                  <div className="col-6">
                    <label className="form-label fw-semibold">Max Discount</label>
                    <input className="form-control" type="number" min="0" value={form.maxDiscountAmount} onChange={e => setForm({ ...form, maxDiscountAmount: e.target.value })} data-testid="input-max-discount" />
                  </div>
                </div>
              </div>
              <div className="modal-footer">
                <button className="btn btn-light" onClick={() => setShowModal(false)}>Cancel</button>
                <button
                  className="btn btn-primary"
                  disabled={!form.name || !form.discountAmount || saveMutation.isPending}
                  onClick={() => saveMutation.mutate(form)}
                  data-testid="btn-discount-save"
                >
                  {saveMutation.isPending ? "Saving..." : editing ? "Update" : "Create"}
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
    
    </>
  );
}
