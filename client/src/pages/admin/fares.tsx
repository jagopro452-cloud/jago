import { useState } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { apiRequest } from "@/lib/queryClient";
import { useToast } from "@/hooks/use-toast";

function FareModal({ open, onClose, editing, zones, form, setForm, onSave, saving }: any) {
  if (!open) return null;
  return (
    <div className="modal-backdrop-jago">
      <div className="modal-jago" style={{ maxWidth: "600px" }}>
        <div className="modal-jago-header">
          <h5 className="modal-jago-title">{editing ? "Edit Fare" : "Add Fare"}</h5>
          <button className="modal-jago-close" onClick={onClose}><i className="bi bi-x-lg"></i></button>
        </div>
        <div className="d-flex flex-column gap-3">
          <div className="row g-3">
            <div className="col-6">
              <label className="form-label-jago">Zone <span className="text-danger">*</span></label>
              <select className="form-select" value={form.zoneId} onChange={e => setForm((f: any) => ({ ...f, zoneId: e.target.value }))}>
                <option value="">Select Zone</option>
                {zones?.map((z: any) => <option key={z.id} value={z.id}>{z.name}</option>)}
              </select>
            </div>
            <div className="col-6">
              <label className="form-label-jago">Vehicle Category</label>
              <input className="form-control" value={form.vehicleCategory} onChange={e => setForm((f: any) => ({ ...f, vehicleCategory: e.target.value }))} placeholder="e.g. Economy" />
            </div>
          </div>
          <div className="row g-3">
            <div className="col-6">
              <label className="form-label-jago">Base Fare (₹)</label>
              <input type="number" className="form-control" value={form.baseFare} onChange={e => setForm((f: any) => ({ ...f, baseFare: e.target.value }))} data-testid="input-base-fare" />
            </div>
            <div className="col-6">
              <label className="form-label-jago">Per Km Rate (₹)</label>
              <input type="number" className="form-control" value={form.perKmRate} onChange={e => setForm((f: any) => ({ ...f, perKmRate: e.target.value }))} />
            </div>
          </div>
          <div className="row g-3">
            <div className="col-6">
              <label className="form-label-jago">Per Minute Rate (₹)</label>
              <input type="number" className="form-control" value={form.perMinuteRate} onChange={e => setForm((f: any) => ({ ...f, perMinuteRate: e.target.value }))} />
            </div>
            <div className="col-6">
              <label className="form-label-jago">Min Fare (₹)</label>
              <input type="number" className="form-control" value={form.minFare} onChange={e => setForm((f: any) => ({ ...f, minFare: e.target.value }))} />
            </div>
          </div>
          <div className="d-flex gap-2 justify-content-end mt-2">
            <button className="btn btn-outline-secondary" onClick={onClose}>Cancel</button>
            <button className="btn btn-primary" onClick={onSave} disabled={!form.zoneId || saving} data-testid="btn-save-fare">
              {saving ? "Saving..." : editing ? "Update" : "Create"}
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}

export default function Fares() {
  const { toast } = useToast();
  const qc = useQueryClient();
  const [open, setOpen] = useState(false);
  const [editing, setEditing] = useState<any>(null);
  const [search, setSearch] = useState("");
  const [form, setForm] = useState({ zoneId: "", vehicleCategory: "", baseFare: "50", perKmRate: "15", perMinuteRate: "2", minFare: "30" });

  const { data: fares, isLoading } = useQuery<any[]>({ queryKey: ["/api/fares"] });
  const { data: zones } = useQuery<any[]>({ queryKey: ["/api/zones"] });

  const save = useMutation({
    mutationFn: (d: any) => editing
      ? apiRequest("PUT", `/api/fares/${editing.id}`, d)
      : apiRequest("POST", "/api/fares", d),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["/api/fares"] });
      toast({ title: editing ? "Fare updated" : "Fare created" });
      setOpen(false); setEditing(null);
      setForm({ zoneId: "", vehicleCategory: "", baseFare: "50", perKmRate: "15", perMinuteRate: "2", minFare: "30" });
    },
    onError: (e: any) => toast({ title: "Error", description: e.message, variant: "destructive" }),
  });

  const remove = useMutation({
    mutationFn: (id: string) => apiRequest("DELETE", `/api/fares/${id}`),
    onSuccess: () => { qc.invalidateQueries({ queryKey: ["/api/fares"] }); toast({ title: "Fare deleted" }); },
  });

  const openCreate = () => { setEditing(null); setForm({ zoneId: "", vehicleCategory: "", baseFare: "50", perKmRate: "15", perMinuteRate: "2", minFare: "30" }); setOpen(true); };
  const openEdit = (f: any) => {
    setEditing(f);
    setForm({ zoneId: String(f.zoneId || ""), vehicleCategory: f.vehicleCategory || "", baseFare: String(f.baseFare || 50), perKmRate: String(f.perKmRate || 15), perMinuteRate: String(f.perMinuteRate || 2), minFare: String(f.minFare || 30) });
    setOpen(true);
  };

  const getZoneName = (zoneId: string | number) => zones?.find((z: any) => String(z.id) === String(zoneId))?.name || `Zone ${zoneId}`;

  const filteredFares = fares?.filter((f: any) => {
    if (!search) return true;
    const zoneName = getZoneName(f.zoneId).toLowerCase();
    return zoneName.includes(search.toLowerCase()) || (f.vehicleCategory || "").toLowerCase().includes(search.toLowerCase());
  }) || [];

  return (
    <div className="container-fluid">
      <div className="mb-4">
        <h2 className="fs-22 mb-2 text-capitalize" data-testid="page-title">Trip Fare Setup</h2>
        <div className="fs-16 text-muted">Manage your ride sharing fares zone wise</div>
      </div>

      <div className="card">
        <div className="card-body">
          <div className="d-flex flex-wrap gap-10 justify-content-between align-items-center mb-4">
            <h5 className="text-primary text-capitalize mb-0">Operation Zone Fare List</h5>
            <div className="d-flex gap-2 align-items-center">
              <form className="search-form search-form_style-two" onSubmit={e => e.preventDefault()}>
                <div className="input-group search-form__input_group">
                  <span className="search-form__icon"><i className="bi bi-search"></i></span>
                  <input type="search" className="theme-input-style search-form__input" placeholder="Search..." value={search} onChange={e => setSearch(e.target.value)} data-testid="input-search" />
                </div>
              </form>
              <button className="btn btn-primary" onClick={openCreate} data-testid="btn-add-fare">
                <i className="bi bi-plus-circle me-1"></i> Add Fare
              </button>
            </div>
          </div>

          <div className="table-responsive">
            <table className="table table-borderless align-middle table-hover">
              <thead className="table-light align-middle text-capitalize">
                <tr>
                  <th>SL</th>
                  <th>Zone</th>
                  <th>Vehicle Category</th>
                  <th>Base Fare</th>
                  <th>Per Km</th>
                  <th>Per Min</th>
                  <th>Min Fare</th>
                  <th className="text-center">Action</th>
                </tr>
              </thead>
              <tbody>
                {isLoading ? (
                  Array(5).fill(0).map((_, i) => (
                    <tr key={i}>{Array(8).fill(0).map((_, j) => <td key={j}><div style={{ height: "14px", background: "#f1f5f9", borderRadius: "4px" }} /></td>)}</tr>
                  ))
                ) : filteredFares.length ? (
                  filteredFares.map((f: any, idx: number) => (
                    <tr key={f.id} data-testid={`fare-row-${f.id}`}>
                      <td>{idx + 1}</td>
                      <td>
                        <div className="media align-items-center gap-2">
                          <span className="circle-24 title-color-bg">{idx + 1}</span>
                          <div className="media-body fw-medium">{getZoneName(f.zoneId)}</div>
                        </div>
                      </td>
                      <td>{f.vehicleCategory || "—"}</td>
                      <td className="fw-semibold">₹{Number(f.baseFare).toFixed(2)}</td>
                      <td>₹{Number(f.perKmRate).toFixed(2)}</td>
                      <td>₹{Number(f.perMinuteRate).toFixed(2)}</td>
                      <td>₹{Number(f.minFare).toFixed(2)}</td>
                      <td className="text-center">
                        <div className="d-flex justify-content-center gap-2">
                          <button className="btn btn-sm btn-outline-primary" onClick={() => openEdit(f)} data-testid={`btn-edit-fare-${f.id}`}><i className="bi bi-pencil-fill"></i></button>
                          <button className="btn btn-sm btn-outline-danger" onClick={() => { if (confirm("Delete this fare?")) remove.mutate(f.id); }} data-testid={`btn-delete-fare-${f.id}`}><i className="bi bi-trash-fill"></i></button>
                        </div>
                      </td>
                    </tr>
                  ))
                ) : (
                  <tr><td colSpan={8}>
                    <div className="d-flex flex-column justify-content-center align-items-center gap-2 py-4">
                      <i className="bi bi-cash-stack" style={{ fontSize: "2rem", color: "#94a3b8" }}></i>
                      <p className="text-muted mb-0">No fare configurations found</p>
                    </div>
                  </td></tr>
                )}
              </tbody>
            </table>
          </div>
        </div>
      </div>

      <FareModal open={open} onClose={() => setOpen(false)} editing={editing} zones={zones} form={form} setForm={setForm} onSave={() => save.mutate(form)} saving={save.isPending} />
    </div>
  );
}
