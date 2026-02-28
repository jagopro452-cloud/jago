import { useState } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { apiRequest } from "@/lib/queryClient";
import { useToast } from "@/hooks/use-toast";

function ZoneModal({ open, onClose, editing, form, setForm, onSave, saving }: any) {
  if (!open) return null;
  return (
    <div className="modal-backdrop-jago">
      <div className="modal-jago">
        <div className="modal-jago-header">
          <h5 className="modal-jago-title">{editing ? "Edit Zone" : "Add Service Zone"}</h5>
          <button className="modal-jago-close" onClick={onClose}><i className="bi bi-x-lg"></i></button>
        </div>
        <div className="d-flex flex-column gap-3">
          <div>
            <label className="form-label-jago">Zone Name <span className="text-danger">*</span></label>
            <input
              className="form-control"
              value={form.name}
              onChange={e => setForm((f: any) => ({ ...f, name: e.target.value }))}
              placeholder="e.g. Hyderabad Central"
              data-testid="input-zone-name"
            />
          </div>
          <div className="d-flex gap-2 justify-content-end mt-2">
            <button className="btn btn-outline-secondary" onClick={onClose}>Cancel</button>
            <button
              className="btn btn-primary"
              onClick={onSave}
              disabled={!form.name || saving}
              data-testid="btn-save-zone"
            >
              {saving ? "Saving..." : editing ? "Update Zone" : "Create Zone"}
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}

export default function Zones() {
  const { toast } = useToast();
  const qc = useQueryClient();
  const [open, setOpen] = useState(false);
  const [editing, setEditing] = useState<any>(null);
  const [filterStatus, setFilterStatus] = useState("all");
  const [form, setForm] = useState({ name: "", coordinates: "" });

  const { data, isLoading } = useQuery<any[]>({ queryKey: ["/api/zones"] });

  const save = useMutation({
    mutationFn: (d: any) => editing
      ? apiRequest("PUT", `/api/zones/${editing.id}`, d)
      : apiRequest("POST", "/api/zones", d),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["/api/zones"] });
      toast({ title: editing ? "Zone updated successfully" : "Zone created successfully" });
      setOpen(false); setEditing(null); setForm({ name: "", coordinates: "" });
    },
    onError: (e: any) => toast({ title: "Error", description: e.message, variant: "destructive" }),
  });

  const remove = useMutation({
    mutationFn: (id: string) => apiRequest("DELETE", `/api/zones/${id}`),
    onSuccess: () => { qc.invalidateQueries({ queryKey: ["/api/zones"] }); toast({ title: "Zone deleted" }); },
  });

  const toggleZoneStatus = useMutation({
    mutationFn: ({ id, isActive }: { id: string; isActive: boolean }) =>
      apiRequest("PATCH", `/api/zones/${id}`, { isActive }),
    onSuccess: () => qc.invalidateQueries({ queryKey: ["/api/zones"] }),
  });

  const openCreate = () => { setEditing(null); setForm({ name: "", coordinates: "" }); setOpen(true); };
  const openEdit = (zone: any) => { setEditing(zone); setForm({ name: zone.name, coordinates: zone.coordinates || "" }); setOpen(true); };

  const filtered = data?.filter(z => {
    if (filterStatus === "active") return z.isActive;
    if (filterStatus === "inactive") return !z.isActive;
    return true;
  });

  return (
    <div className="container-fluid">
      <div className="d-flex align-items-center gap-3 justify-content-between mb-4">
        <h2 className="fs-22 text-capitalize mb-0" data-testid="page-title">Zone Setup</h2>
        <button className="btn btn-primary" onClick={openCreate} data-testid="btn-add-zone">
          <i className="bi bi-plus-circle me-1"></i> Add Zone
        </button>
      </div>

      <div className="col-12">
        <div className="d-flex flex-wrap justify-content-between align-items-center my-3 gap-3">
          <ul className="nav nav--tabs p-1 rounded bg-white" role="tablist">
            {["all", "active", "inactive"].map(s => (
              <li key={s} className="nav-item" role="presentation">
                <button
                  className={`nav-link${filterStatus === s ? " active" : ""}`}
                  onClick={() => setFilterStatus(s)}
                  data-testid={`tab-${s}`}
                >
                  {s.charAt(0).toUpperCase() + s.slice(1)}
                </button>
              </li>
            ))}
          </ul>
          <div className="d-flex align-items-center gap-2">
            <span className="text-muted text-capitalize">Total Zones:</span>
            <span className="text-primary fs-16 fw-bold" data-testid="total-count">{filtered?.length || 0}</span>
          </div>
        </div>

        <div className="card">
          <div className="card-body">
            <div className="table-responsive">
              <table className="table table-borderless align-middle table-hover">
                <thead className="table-light align-middle text-capitalize">
                  <tr>
                    <th>SL</th>
                    <th>Zone Name</th>
                    <th>Status</th>
                    <th className="text-center">Action</th>
                  </tr>
                </thead>
                <tbody>
                  {isLoading ? (
                    Array(5).fill(0).map((_, i) => (
                      <tr key={i}>
                        {Array(4).fill(0).map((_, j) => <td key={j}><div style={{ height: "14px", background: "#f1f5f9", borderRadius: "4px" }} /></td>)}
                      </tr>
                    ))
                  ) : filtered?.length ? (
                    filtered.map((zone: any, idx: number) => (
                      <tr key={zone.id} data-testid={`zone-row-${zone.id}`}>
                        <td>{idx + 1}</td>
                        <td>
                          <div className="media align-items-center gap-2">
                            <div style={{ width: "36px", height: "36px", borderRadius: "8px", background: "rgba(124,58,237,0.1)", display: "flex", alignItems: "center", justifyContent: "center" }}>
                              <i className="bi bi-map-fill" style={{ color: "#7c3aed" }}></i>
                            </div>
                            <div className="media-body fw-medium title-color">{zone.name}</div>
                          </div>
                        </td>
                        <td>
                          <label className="switcher">
                            <input
                              type="checkbox"
                              className="switcher_input"
                              checked={zone.isActive}
                              onChange={() => toggleZoneStatus.mutate({ id: zone.id, isActive: !zone.isActive })}
                              data-testid={`toggle-zone-${zone.id}`}
                            />
                            <span className="switcher_control"></span>
                          </label>
                        </td>
                        <td className="text-center">
                          <div className="d-flex justify-content-center gap-2">
                            <button
                              className="btn btn-sm btn-outline-primary"
                              onClick={() => openEdit(zone)}
                              data-testid={`btn-edit-zone-${zone.id}`}
                            >
                              <i className="bi bi-pencil-fill"></i>
                            </button>
                            <button
                              className="btn btn-sm btn-outline-danger"
                              onClick={() => { if (confirm("Delete this zone?")) remove.mutate(zone.id); }}
                              data-testid={`btn-delete-zone-${zone.id}`}
                            >
                              <i className="bi bi-trash-fill"></i>
                            </button>
                          </div>
                        </td>
                      </tr>
                    ))
                  ) : (
                    <tr>
                      <td colSpan={4}>
                        <div className="d-flex flex-column justify-content-center align-items-center gap-2 py-4">
                          <i className="bi bi-map" style={{ fontSize: "2rem", color: "#94a3b8" }}></i>
                          <p className="text-muted mb-0">No zones found</p>
                        </div>
                      </td>
                    </tr>
                  )}
                </tbody>
              </table>
            </div>
          </div>
        </div>
      </div>

      <ZoneModal
        open={open}
        onClose={() => setOpen(false)}
        editing={editing}
        form={form}
        setForm={setForm}
        onSave={() => save.mutate(form)}
        saving={save.isPending}
      />
    </div>
  );
}
