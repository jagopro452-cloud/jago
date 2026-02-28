import { useQuery, useMutation } from "@tanstack/react-query";
import { queryClient, apiRequest } from "@/lib/queryClient";
import { useState } from "react";
import { useToast } from "@/hooks/use-toast";

export default function SubscriptionsPage() {
  const { toast } = useToast();
  const [showModal, setShowModal] = useState(false);
  const [editing, setEditing] = useState<any>(null);
  const [form, setForm] = useState({ name: "", price: "", durationDays: "", features: "", isActive: true });

  const { data, isLoading } = useQuery<any[]>({ queryKey: ["/api/subscription-plans"] });
  const plans = Array.isArray(data) ? data : [];

  const saveMutation = useMutation({
    mutationFn: (payload: any) =>
      editing ? apiRequest("PUT", `/api/subscription-plans/${editing.id}`, payload) : apiRequest("POST", "/api/subscription-plans", payload),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["/api/subscription-plans"] });
      setShowModal(false);
      toast({ title: editing ? "Plan updated" : "Plan created" });
      setEditing(null);
    },
    onError: () => toast({ title: "Failed to save", variant: "destructive" }),
  });

  const deleteMutation = useMutation({
    mutationFn: (id: string) => apiRequest("DELETE", `/api/subscription-plans/${id}`),
    onSuccess: () => { queryClient.invalidateQueries({ queryKey: ["/api/subscription-plans"] }); toast({ title: "Deleted" }); },
  });

  const openAdd = () => { setEditing(null); setForm({ name: "", price: "", durationDays: "", features: "", isActive: true }); setShowModal(true); };
  const openEdit = (p: any) => { setEditing(p); setForm({ name: p.name, price: p.price, durationDays: p.durationDays, features: p.features || "", isActive: p.isActive }); setShowModal(true); };

  return (
    <>
    
      <div className="content-header">
        <div className="container-fluid">
          <div className="d-flex align-items-center justify-content-between gap-3 flex-wrap mb-3">
            <h2 className="h5 mb-0">Subscription Plans</h2>
            <button className="btn btn-primary btn-sm" onClick={openAdd} data-testid="btn-add-plan">
              <i className="bi bi-plus me-1"></i>Add Plan
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
                    <th>Plan Name</th>
                    <th>Price</th>
                    <th>Duration</th>
                    <th>Status</th>
                    <th>Action</th>
                  </tr>
                </thead>
                <tbody>
                  {isLoading ? (
                    <tr><td colSpan={6} className="text-center py-4"><div className="spinner-border spinner-border-sm" role="status" /></td></tr>
                  ) : plans.length === 0 ? (
                    <tr>
                      <td colSpan={6} className="text-center py-5 text-muted">
                        <i className="bi bi-card-checklist fs-2 d-block mb-2 opacity-25"></i>
                        No subscription plans found. Click Add Plan to create one.
                      </td>
                    </tr>
                  ) : plans.map((p: any, idx: number) => (
                    <tr key={p.id} data-testid={`row-plan-${p.id}`}>
                      <td>{idx + 1}</td>
                      <td className="fw-semibold">{p.name}</td>
                      <td>₹{p.price}</td>
                      <td>{p.durationDays} days</td>
                      <td><span className={`badge ${p.isActive ? "bg-success" : "bg-secondary"}`}>{p.isActive ? "Active" : "Inactive"}</span></td>
                      <td>
                        <button className="btn btn-sm btn-outline-primary me-1" onClick={() => openEdit(p)}><i className="bi bi-pencil-fill"></i></button>
                        <button className="btn btn-sm btn-outline-danger" onClick={() => { if (confirm("Delete?")) deleteMutation.mutate(p.id); }}><i className="bi bi-trash-fill"></i></button>
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
                <h5 className="modal-title">{editing ? "Edit Plan" : "Add Plan"}</h5>
                <button className="btn-close" onClick={() => setShowModal(false)} />
              </div>
              <div className="modal-body">
                <div className="mb-3">
                  <label className="form-label fw-semibold">Plan Name <span className="text-danger">*</span></label>
                  <input className="form-control" value={form.name} onChange={e => setForm({ ...form, name: e.target.value })} placeholder="e.g. Basic, Premium" data-testid="input-plan-name" />
                </div>
                <div className="row g-3 mb-3">
                  <div className="col-6">
                    <label className="form-label fw-semibold">Price (₹) <span className="text-danger">*</span></label>
                    <input className="form-control" type="number" min="0" value={form.price} onChange={e => setForm({ ...form, price: e.target.value })} data-testid="input-plan-price" />
                  </div>
                  <div className="col-6">
                    <label className="form-label fw-semibold">Duration (Days)</label>
                    <input className="form-control" type="number" min="1" value={form.durationDays} onChange={e => setForm({ ...form, durationDays: e.target.value })} data-testid="input-plan-duration" />
                  </div>
                </div>
                <div className="mb-3">
                  <label className="form-label fw-semibold">Features (one per line)</label>
                  <textarea className="form-control" rows={4} value={form.features} onChange={e => setForm({ ...form, features: e.target.value })} placeholder="Unlimited trips&#10;Priority support&#10;..." data-testid="input-plan-features" />
                </div>
              </div>
              <div className="modal-footer">
                <button className="btn btn-light" onClick={() => setShowModal(false)}>Cancel</button>
                <button className="btn btn-primary" disabled={!form.name || !form.price || saveMutation.isPending} onClick={() => saveMutation.mutate(form)} data-testid="btn-save-plan">
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
