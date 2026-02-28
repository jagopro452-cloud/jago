import { useState } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { apiRequest } from "@/lib/queryClient";
import { useToast } from "@/hooks/use-toast";

const EMPTY_FORM = { zoneId: "", vehicleCategoryId: "", baseFare: "50", farePerKm: "15", farePerMin: "2", minimumFare: "30", cancellationFee: "5" };

function FareModal({ open, onClose, editing, zones, vehicleCategories, form, setForm, onSave, saving }: any) {
  if (!open) return null;
  return (
    <div className="modal-backdrop-jago">
      <div className="modal-jago" style={{ maxWidth: "620px" }}>
        <div className="modal-jago-header">
          <h5 className="modal-jago-title">{editing ? "Edit Fare" : "Add Fare"}</h5>
          <button className="modal-jago-close" onClick={onClose}><i className="bi bi-x-lg"></i></button>
        </div>
        <div className="d-flex flex-column gap-3">
          <div className="row g-3">
            <div className="col-6">
              <label className="form-label-jago">Zone <span className="text-danger">*</span></label>
              <select className="form-select" value={form.zoneId} onChange={e => setForm((f: any) => ({ ...f, zoneId: e.target.value }))} data-testid="select-zone">
                <option value="">Select Zone</option>
                {zones?.map((z: any) => <option key={z.id} value={z.id}>{z.name}</option>)}
              </select>
            </div>
            <div className="col-6">
              <label className="form-label-jago">Vehicle Category</label>
              <select className="form-select" value={form.vehicleCategoryId} onChange={e => setForm((f: any) => ({ ...f, vehicleCategoryId: e.target.value }))} data-testid="select-vehicle-category">
                <option value="">Select Category</option>
                {vehicleCategories?.map((v: any) => <option key={v.id} value={v.id}>{v.name}</option>)}
              </select>
            </div>
          </div>
          <div className="row g-3">
            <div className="col-6">
              <label className="form-label-jago">Base Fare (₹) <span className="text-danger">*</span></label>
              <input type="number" className="form-control" value={form.baseFare} min="0" onChange={e => setForm((f: any) => ({ ...f, baseFare: e.target.value }))} data-testid="input-base-fare" />
            </div>
            <div className="col-6">
              <label className="form-label-jago">Per Km Rate (₹)</label>
              <input type="number" className="form-control" value={form.farePerKm} min="0" onChange={e => setForm((f: any) => ({ ...f, farePerKm: e.target.value }))} data-testid="input-per-km" />
            </div>
          </div>
          <div className="row g-3">
            <div className="col-6">
              <label className="form-label-jago">Per Minute Rate (₹)</label>
              <input type="number" className="form-control" value={form.farePerMin} min="0" onChange={e => setForm((f: any) => ({ ...f, farePerMin: e.target.value }))} />
            </div>
            <div className="col-6">
              <label className="form-label-jago">Minimum Fare (₹)</label>
              <input type="number" className="form-control" value={form.minimumFare} min="0" onChange={e => setForm((f: any) => ({ ...f, minimumFare: e.target.value }))} />
            </div>
          </div>
          <div className="row g-3">
            <div className="col-6">
              <label className="form-label-jago">Cancellation Fee (₹)</label>
              <input type="number" className="form-control" value={form.cancellationFee} min="0" onChange={e => setForm((f: any) => ({ ...f, cancellationFee: e.target.value }))} />
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
  const [form, setForm] = useState({ ...EMPTY_FORM });

  const { data: fares, isLoading } = useQuery<any[]>({ queryKey: ["/api/fares"] });
  const { data: zones } = useQuery<any[]>({ queryKey: ["/api/zones"] });
  const { data: vehicleCategories } = useQuery<any[]>({ queryKey: ["/api/vehicle-categories"] });

  const save = useMutation({
    mutationFn: (d: any) => editing
      ? apiRequest("PUT", `/api/fares/${editing.fare.id}`, d)
      : apiRequest("POST", "/api/fares", d),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["/api/fares"] });
      toast({ title: editing ? "Fare updated" : "Fare created" });
      setOpen(false); setEditing(null); setForm({ ...EMPTY_FORM });
    },
    onError: (e: any) => toast({ title: "Error", description: e.message, variant: "destructive" }),
  });

  const remove = useMutation({
    mutationFn: (id: string) => apiRequest("DELETE", `/api/fares/${id}`),
    onSuccess: () => { qc.invalidateQueries({ queryKey: ["/api/fares"] }); toast({ title: "Fare deleted" }); },
    onError: (e: any) => toast({ title: "Error", description: e.message, variant: "destructive" }),
  });

  const openCreate = () => { setEditing(null); setForm({ ...EMPTY_FORM }); setOpen(true); };
  const openEdit = (item: any) => {
    setEditing(item);
    setForm({
      zoneId: String(item.fare.zoneId || ""),
      vehicleCategoryId: String(item.fare.vehicleCategoryId || ""),
      baseFare: String(item.fare.baseFare || "50"),
      farePerKm: String(item.fare.farePerKm || "15"),
      farePerMin: String(item.fare.farePerMin || "2"),
      minimumFare: String(item.fare.minimumFare || "30"),
      cancellationFee: String(item.fare.cancellationFee || "5"),
    });
    setOpen(true);
  };

  const filtered = fares?.filter((item: any) => {
    if (!search) return true;
    const zone = item.zone?.name || "";
    const cat = item.vehicleCategory?.name || "";
    return zone.toLowerCase().includes(search.toLowerCase()) || cat.toLowerCase().includes(search.toLowerCase());
  }) || [];

  return (
    <div className="container-fluid">
      <div className="mb-4">
        <h2 className="fs-22 mb-2 text-capitalize" data-testid="page-title">Trip Fare Setup</h2>
        <div className="fs-14 text-muted">Manage your ride sharing fares zone wise</div>
      </div>

      <div className="card">
        <div className="card-body">
          <div className="d-flex flex-wrap gap-10 justify-content-between align-items-center mb-4">
            <h5 className="text-primary text-capitalize mb-0">Operation Zone Fare List</h5>
            <div className="d-flex gap-2 align-items-center">
              <div className="input-group search-form__input_group" style={{ maxWidth: "220px" }}>
                <span className="search-form__icon"><i className="bi bi-search"></i></span>
                <input type="search" className="theme-input-style search-form__input" placeholder="Search zone or category..." value={search} onChange={e => setSearch(e.target.value)} data-testid="input-search" />
              </div>
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
                  <th>Cancel Fee</th>
                  <th className="text-center">Action</th>
                </tr>
              </thead>
              <tbody>
                {isLoading ? (
                  Array(5).fill(0).map((_, i) => (
                    <tr key={i}>{Array(9).fill(0).map((_, j) => <td key={j}><div style={{ height: "14px", background: "#f1f5f9", borderRadius: "4px" }} /></td>)}</tr>
                  ))
                ) : filtered.length ? (
                  filtered.map((item: any, idx: number) => (
                    <tr key={item.fare.id} data-testid={`fare-row-${item.fare.id}`}>
                      <td>{idx + 1}</td>
                      <td>
                        <div className="media align-items-center gap-2">
                          <span className="circle-24 title-color-bg" style={{ width: "24px", height: "24px", borderRadius: "50%", display: "inline-flex", alignItems: "center", justifyContent: "center", fontSize: "0.75rem", fontWeight: 700, background: "#1e40af", color: "#fff" }}>{idx + 1}</span>
                          <div className="media-body fw-medium">{item.zone?.name || "—"}</div>
                        </div>
                      </td>
                      <td>{item.vehicleCategory?.name || "—"}</td>
                      <td className="fw-semibold">₹{Number(item.fare.baseFare || 0).toFixed(2)}</td>
                      <td>₹{Number(item.fare.farePerKm || 0).toFixed(2)}</td>
                      <td>₹{Number(item.fare.farePerMin || 0).toFixed(2)}</td>
                      <td>₹{Number(item.fare.minimumFare || 0).toFixed(2)}</td>
                      <td>₹{Number(item.fare.cancellationFee || 0).toFixed(2)}</td>
                      <td className="text-center">
                        <div className="d-flex justify-content-center gap-2">
                          <button className="btn btn-sm btn-outline-primary" onClick={() => openEdit(item)} data-testid={`btn-edit-fare-${item.fare.id}`}><i className="bi bi-pencil-fill"></i></button>
                          <button className="btn btn-sm btn-outline-danger" onClick={() => { if (confirm("Delete this fare?")) remove.mutate(item.fare.id); }} data-testid={`btn-delete-fare-${item.fare.id}`}><i className="bi bi-trash-fill"></i></button>
                        </div>
                      </td>
                    </tr>
                  ))
                ) : (
                  <tr><td colSpan={9}>
                    <div className="d-flex flex-column justify-content-center align-items-center gap-2 py-4">
                      <i className="bi bi-cash-stack" style={{ fontSize: "2rem", color: "#94a3b8" }}></i>
                      <p className="text-muted mb-0">No fare configurations found. Click "Add Fare" to create one.</p>
                    </div>
                  </td></tr>
                )}
              </tbody>
            </table>
          </div>
        </div>
      </div>

      <FareModal
        open={open}
        onClose={() => setOpen(false)}
        editing={editing}
        zones={zones}
        vehicleCategories={vehicleCategories}
        form={form}
        setForm={setForm}
        onSave={() => save.mutate(form)}
        saving={save.isPending}
      />
    </div>
  );
}
