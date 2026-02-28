import { useQuery, useMutation } from "@tanstack/react-query";
import { queryClient, apiRequest } from "@/lib/queryClient";
import { useState } from "react";
import { useToast } from "@/hooks/use-toast";

export default function ParcelAttributesPage() {
  const { toast } = useToast();
  const [tab, setTab] = useState<"categories" | "weights">("categories");

  const [showModal, setShowModal] = useState(false);
  const [editing, setEditing] = useState<any>(null);
  const [catForm, setCatForm] = useState({ name: "", isActive: true });
  const [wtForm, setWtForm] = useState({ label: "", minWeight: "", maxWeight: "", isActive: true });

  const { data: cats, isLoading: catsLoading } = useQuery<any[]>({ queryKey: ["/api/parcel-categories"] });
  const { data: weights, isLoading: weightsLoading } = useQuery<any[]>({ queryKey: ["/api/parcel-weights"] });
  const categories = Array.isArray(cats) ? cats : [];
  const weightList = Array.isArray(weights) ? weights : [];

  const catSave = useMutation({
    mutationFn: (d: any) => editing ? apiRequest("PUT", `/api/parcel-categories/${editing.id}`, d) : apiRequest("POST", "/api/parcel-categories", d),
    onSuccess: () => { queryClient.invalidateQueries({ queryKey: ["/api/parcel-categories"] }); setShowModal(false); toast({ title: editing ? "Updated" : "Created" }); setEditing(null); },
    onError: () => toast({ title: "Failed", variant: "destructive" }),
  });

  const catDelete = useMutation({
    mutationFn: (id: string) => apiRequest("DELETE", `/api/parcel-categories/${id}`),
    onSuccess: () => { queryClient.invalidateQueries({ queryKey: ["/api/parcel-categories"] }); toast({ title: "Deleted" }); },
  });

  const wtSave = useMutation({
    mutationFn: (d: any) => editing ? apiRequest("PUT", `/api/parcel-weights/${editing.id}`, d) : apiRequest("POST", "/api/parcel-weights", d),
    onSuccess: () => { queryClient.invalidateQueries({ queryKey: ["/api/parcel-weights"] }); setShowModal(false); toast({ title: editing ? "Updated" : "Created" }); setEditing(null); },
    onError: () => toast({ title: "Failed", variant: "destructive" }),
  });

  const wtDelete = useMutation({
    mutationFn: (id: string) => apiRequest("DELETE", `/api/parcel-weights/${id}`),
    onSuccess: () => { queryClient.invalidateQueries({ queryKey: ["/api/parcel-weights"] }); toast({ title: "Deleted" }); },
  });

  const openAddCat = () => { setEditing(null); setCatForm({ name: "", isActive: true }); setShowModal(true); };
  const openEditCat = (c: any) => { setEditing(c); setCatForm({ name: c.name, isActive: c.isActive }); setShowModal(true); };
  const openAddWt = () => { setEditing(null); setWtForm({ label: "", minWeight: "", maxWeight: "", isActive: true }); setShowModal(true); };
  const openEditWt = (w: any) => { setEditing(w); setWtForm({ label: w.label, minWeight: w.minWeight, maxWeight: w.maxWeight, isActive: w.isActive }); setShowModal(true); };

  return (
    <>
    
      <div className="content-header">
        <div className="container-fluid">
          <div className="d-flex align-items-center justify-content-between gap-3 flex-wrap mb-3">
            <h2 className="h5 mb-0">Parcel Attributes</h2>
            <button className="btn btn-primary btn-sm" onClick={tab === "categories" ? openAddCat : openAddWt} data-testid="btn-add-parcel-attr">
              <i className="bi bi-plus me-1"></i>Add {tab === "categories" ? "Category" : "Weight"}
            </button>
          </div>
        </div>
      </div>
      <div className="container-fluid">
        <div className="card">
          <div className="card-header border-bottom py-3">
            <ul className="nav nav--tabs p-1 rounded bg-white">
              <li className="nav-item">
                <button className={`nav-link${tab === "categories" ? " active" : ""}`} onClick={() => setTab("categories")} data-testid="tab-parcel-categories">Parcel Categories</button>
              </li>
              <li className="nav-item">
                <button className={`nav-link${tab === "weights" ? " active" : ""}`} onClick={() => setTab("weights")} data-testid="tab-parcel-weights">Parcel Weights</button>
              </li>
            </ul>
          </div>
          <div className="card-body">
            {tab === "categories" ? (
              <div className="table-responsive">
                <table className="table table-borderless align-middle table-hover">
                  <thead className="table-light">
                    <tr><th>#</th><th>Category Name</th><th>Status</th><th>Action</th></tr>
                  </thead>
                  <tbody>
                    {catsLoading ? (
                      <tr><td colSpan={4} className="text-center py-4"><div className="spinner-border spinner-border-sm" role="status" /></td></tr>
                    ) : categories.length === 0 ? (
                      <tr>
                        <td colSpan={4} className="text-center py-5 text-muted">
                          <i className="bi bi-patch-plus fs-2 d-block mb-2 opacity-25"></i>
                          No parcel categories found.
                        </td>
                      </tr>
                    ) : categories.map((c: any, idx: number) => (
                      <tr key={c.id} data-testid={`row-parcel-cat-${c.id}`}>
                        <td>{idx + 1}</td>
                        <td className="fw-semibold">{c.name}</td>
                        <td><span className={`badge ${c.isActive ? "bg-success" : "bg-secondary"}`}>{c.isActive ? "Active" : "Inactive"}</span></td>
                        <td>
                          <button className="btn btn-sm btn-outline-primary me-1" onClick={() => openEditCat(c)}><i className="bi bi-pencil-fill"></i></button>
                          <button className="btn btn-sm btn-outline-danger" onClick={() => { if (confirm("Delete?")) catDelete.mutate(c.id); }}><i className="bi bi-trash-fill"></i></button>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            ) : (
              <div className="table-responsive">
                <table className="table table-borderless align-middle table-hover">
                  <thead className="table-light">
                    <tr><th>#</th><th>Label</th><th>Min (kg)</th><th>Max (kg)</th><th>Status</th><th>Action</th></tr>
                  </thead>
                  <tbody>
                    {weightsLoading ? (
                      <tr><td colSpan={6} className="text-center py-4"><div className="spinner-border spinner-border-sm" role="status" /></td></tr>
                    ) : weightList.length === 0 ? (
                      <tr>
                        <td colSpan={6} className="text-center py-5 text-muted">
                          <i className="bi bi-patch-plus fs-2 d-block mb-2 opacity-25"></i>
                          No parcel weights found.
                        </td>
                      </tr>
                    ) : weightList.map((w: any, idx: number) => (
                      <tr key={w.id} data-testid={`row-parcel-wt-${w.id}`}>
                        <td>{idx + 1}</td>
                        <td className="fw-semibold">{w.label}</td>
                        <td>{w.minWeight}</td>
                        <td>{w.maxWeight}</td>
                        <td><span className={`badge ${w.isActive ? "bg-success" : "bg-secondary"}`}>{w.isActive ? "Active" : "Inactive"}</span></td>
                        <td>
                          <button className="btn btn-sm btn-outline-primary me-1" onClick={() => openEditWt(w)}><i className="bi bi-pencil-fill"></i></button>
                          <button className="btn btn-sm btn-outline-danger" onClick={() => { if (confirm("Delete?")) wtDelete.mutate(w.id); }}><i className="bi bi-trash-fill"></i></button>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            )}
          </div>
        </div>
      </div>

      {showModal && tab === "categories" && (
        <div className="modal fade show d-block" style={{ background: "rgba(0,0,0,0.5)" }}>
          <div className="modal-dialog">
            <div className="modal-content">
              <div className="modal-header">
                <h5 className="modal-title">{editing ? "Edit Parcel Category" : "Add Parcel Category"}</h5>
                <button className="btn-close" onClick={() => setShowModal(false)} />
              </div>
              <div className="modal-body">
                <div className="mb-3">
                  <label className="form-label fw-semibold">Category Name <span className="text-danger">*</span></label>
                  <input className="form-control" value={catForm.name} onChange={e => setCatForm({ ...catForm, name: e.target.value })} data-testid="input-parcel-cat-name" />
                </div>
              </div>
              <div className="modal-footer">
                <button className="btn btn-light" onClick={() => setShowModal(false)}>Cancel</button>
                <button className="btn btn-primary" disabled={!catForm.name || catSave.isPending} onClick={() => catSave.mutate(catForm)} data-testid="btn-save-parcel-cat">
                  {catSave.isPending ? "Saving..." : editing ? "Update" : "Create"}
                </button>
              </div>
            </div>
          </div>
        </div>
      )}

      {showModal && tab === "weights" && (
        <div className="modal fade show d-block" style={{ background: "rgba(0,0,0,0.5)" }}>
          <div className="modal-dialog">
            <div className="modal-content">
              <div className="modal-header">
                <h5 className="modal-title">{editing ? "Edit Parcel Weight" : "Add Parcel Weight"}</h5>
                <button className="btn-close" onClick={() => setShowModal(false)} />
              </div>
              <div className="modal-body">
                <div className="mb-3">
                  <label className="form-label fw-semibold">Label <span className="text-danger">*</span></label>
                  <input className="form-control" value={wtForm.label} onChange={e => setWtForm({ ...wtForm, label: e.target.value })} placeholder="e.g. Light, Medium, Heavy" data-testid="input-parcel-wt-label" />
                </div>
                <div className="row g-3 mb-3">
                  <div className="col-6">
                    <label className="form-label fw-semibold">Min Weight (kg)</label>
                    <input className="form-control" type="number" min="0" value={wtForm.minWeight} onChange={e => setWtForm({ ...wtForm, minWeight: e.target.value })} data-testid="input-parcel-min-wt" />
                  </div>
                  <div className="col-6">
                    <label className="form-label fw-semibold">Max Weight (kg)</label>
                    <input className="form-control" type="number" min="0" value={wtForm.maxWeight} onChange={e => setWtForm({ ...wtForm, maxWeight: e.target.value })} data-testid="input-parcel-max-wt" />
                  </div>
                </div>
              </div>
              <div className="modal-footer">
                <button className="btn btn-light" onClick={() => setShowModal(false)}>Cancel</button>
                <button className="btn btn-primary" disabled={!wtForm.label || wtSave.isPending} onClick={() => wtSave.mutate(wtForm)} data-testid="btn-save-parcel-wt">
                  {wtSave.isPending ? "Saving..." : editing ? "Update" : "Create"}
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
    
    </>
  );
}
