import { useState } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { apiRequest } from "@/lib/queryClient";
import { useToast } from "@/hooks/use-toast";

const SERVICE_TYPES = [
  { value: "both", label: "Ride & Parcel", icon: "bi-grid-fill", color: "#7c3aed" },
  { value: "ride", label: "Ride Only", icon: "bi-car-front-fill", color: "#1a73e8" },
  { value: "parcel", label: "Parcel Only", icon: "bi-box-seam-fill", color: "#16a34a" },
];

function ZoneModal({ open, onClose, editing, form, setForm, onSave, saving }: any) {
  if (!open) return null;
  return (
    <div className="modal-backdrop-jago">
      <div className="modal-jago" style={{ maxWidth: 540 }}>
        <div className="modal-jago-header">
          <h5 className="modal-jago-title">
            <i className={`bi ${editing ? "bi-pencil-fill" : "bi-plus-circle-fill"} me-2 text-primary`}></i>
            {editing ? "Edit Service Zone" : "Add Service Zone"}
          </h5>
          <button className="modal-jago-close" onClick={onClose}><i className="bi bi-x-lg"></i></button>
        </div>
        <div className="d-flex flex-column gap-3">
          <div>
            <label className="form-label-jago">Zone Name <span className="text-danger">*</span></label>
            <input className="admin-form-control" value={form.name}
              onChange={e => setForm((f: any) => ({ ...f, name: e.target.value }))}
              placeholder="e.g. Hyderabad Central" data-testid="input-zone-name" />
          </div>

          <div>
            <label className="form-label-jago">Service Type <span className="text-danger">*</span></label>
            <div className="d-flex gap-2 flex-wrap">
              {SERVICE_TYPES.map(st => (
                <button key={st.value} type="button"
                  onClick={() => setForm((f: any) => ({ ...f, serviceType: st.value }))}
                  data-testid={`btn-service-${st.value}`}
                  style={{
                    background: form.serviceType === st.value ? st.color : "#f8fafc",
                    color: form.serviceType === st.value ? "#fff" : "#64748b",
                    border: `1.5px solid ${form.serviceType === st.value ? st.color : "#e2e8f0"}`,
                    borderRadius: 10, padding: "6px 14px", fontWeight: 600, fontSize: 12,
                    cursor: "pointer", transition: "all 0.15s",
                  }}>
                  <i className={`bi ${st.icon} me-1`}></i>{st.label}
                </button>
              ))}
            </div>
          </div>

          <div>
            <label className="form-label-jago">Surge Factor</label>
            <div className="d-flex align-items-center gap-2">
              <input type="number" step="0.1" min="1" max="5" className="admin-form-control"
                style={{ maxWidth: 130 }} value={form.surgeFactor}
                onChange={e => setForm((f: any) => ({ ...f, surgeFactor: parseFloat(e.target.value) || 1.0 }))}
                placeholder="1.0" data-testid="input-surge-factor" />
              <span className="text-muted small">× base fare (1.0 = normal, 2.0 = 2× surge)</span>
            </div>
          </div>

          <div>
            <label className="form-label-jago">Zone Coordinates <span className="text-muted fw-normal">(optional)</span></label>
            <textarea className="admin-form-control" rows={3} value={form.coordinates}
              onChange={e => setForm((f: any) => ({ ...f, coordinates: e.target.value }))}
              placeholder='{"type":"Polygon","coordinates":[[[78.4,17.3],[78.5,17.3],[78.5,17.4],[78.4,17.3]]]}'
              data-testid="input-zone-coordinates"
              style={{ fontFamily: "monospace", fontSize: 11 }} />
            <div className="text-muted" style={{ fontSize: 10.5, marginTop: 4 }}>GeoJSON Polygon format. Used for map overlay display.</div>
          </div>

          <div className="d-flex align-items-center gap-2">
            <label className="form-label-jago mb-0">Status</label>
            <label className="switcher ms-2">
              <input type="checkbox" className="switcher_input" checked={form.isActive}
                onChange={e => setForm((f: any) => ({ ...f, isActive: e.target.checked }))} />
              <span className="switcher_control"></span>
            </label>
            <span className="small" style={{ color: form.isActive ? "#16a34a" : "#94a3b8", fontWeight: 600 }}>
              {form.isActive ? "Active" : "Inactive"}
            </span>
          </div>

          <div className="d-flex gap-2 justify-content-end mt-1 pt-2 border-top">
            <button className="btn btn-outline-secondary" onClick={onClose}>Cancel</button>
            <button className="btn btn-primary" onClick={onSave} disabled={!form.name || saving}
              data-testid="btn-save-zone">
              {saving ? <><span className="spinner-border spinner-border-sm me-2"></span>Saving…</> : editing ? "Update Zone" : "Create Zone"}
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
  const [search, setSearch] = useState("");
  const defaultForm = { name: "", coordinates: "", serviceType: "both", surgeFactor: 1.0, isActive: true };
  const [form, setForm] = useState(defaultForm);

  const { data = [], isLoading } = useQuery<any[]>({ queryKey: ["/api/zones"] });

  const save = useMutation({
    mutationFn: (d: any) => editing
      ? apiRequest("PUT", `/api/zones/${editing.id}`, d)
      : apiRequest("POST", "/api/zones", d),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["/api/zones"] });
      toast({ title: editing ? "Zone updated" : "Zone created successfully" });
      setOpen(false); setEditing(null); setForm(defaultForm);
    },
    onError: (e: any) => toast({ title: "Error", description: e.message, variant: "destructive" }),
  });

  const remove = useMutation({
    mutationFn: (id: string) => apiRequest("DELETE", `/api/zones/${id}`),
    onSuccess: () => { qc.invalidateQueries({ queryKey: ["/api/zones"] }); toast({ title: "Zone deleted" }); },
  });

  const toggle = useMutation({
    mutationFn: ({ id, isActive }: { id: string; isActive: boolean }) =>
      apiRequest("PATCH", `/api/zones/${id}`, { isActive }),
    onSuccess: () => qc.invalidateQueries({ queryKey: ["/api/zones"] }),
  });

  const openEdit = (zone: any) => {
    setEditing(zone);
    setForm({ name: zone.name, coordinates: zone.coordinates || "", serviceType: zone.serviceType || "both", surgeFactor: Number(zone.surgeFactor) || 1.0, isActive: zone.isActive });
    setOpen(true);
  };

  const filtered = (data as any[]).filter(z => {
    const ok1 = filterStatus === "all" || (filterStatus === "active" ? z.isActive : !z.isActive);
    const ok2 = !search || z.name.toLowerCase().includes(search.toLowerCase());
    return ok1 && ok2;
  });

  const zones = data as any[];
  const activeCount = zones.filter(z => z.isActive).length;
  const getServiceConfig = (type: string) => SERVICE_TYPES.find(s => s.value === type) || SERVICE_TYPES[0];

  return (
    <div className="container-fluid">
      <div className="d-flex align-items-center justify-content-between mb-4">
        <div>
          <h4 className="fw-bold mb-0" data-testid="page-title">Zone Setup</h4>
          <div className="text-muted small">Configure service zones, service types and surge pricing</div>
        </div>
        <button className="btn btn-primary" onClick={() => { setEditing(null); setForm(defaultForm); setOpen(true); }}
          data-testid="btn-add-zone">
          <i className="bi bi-plus-circle me-1"></i> Add Zone
        </button>
      </div>

      {/* Summary strip */}
      <div className="row g-3 mb-3">
        {[
          { label: "Total Zones", val: zones.length, icon: "bi-map-fill", color: "#7c3aed", bg: "#f5f3ff" },
          { label: "Active", val: activeCount, icon: "bi-check-circle-fill", color: "#16a34a", bg: "#f0fdf4" },
          { label: "Inactive", val: zones.length - activeCount, icon: "bi-pause-circle-fill", color: "#64748b", bg: "#f8fafc" },
          { label: "With Surge", val: zones.filter((z: any) => (z.surgeFactor || 1) > 1).length, icon: "bi-lightning-fill", color: "#d97706", bg: "#fefce8" },
        ].map((s, i) => (
          <div key={i} className="col-6 col-xl-3">
            <div className="card border-0 shadow-sm" style={{ borderRadius: 14 }}>
              <div className="card-body d-flex align-items-center gap-3 py-3">
                <div className="rounded-3 d-flex align-items-center justify-content-center flex-shrink-0"
                  style={{ width: 44, height: 44, background: s.bg, color: s.color, fontSize: "1.1rem" }}>
                  <i className={`bi ${s.icon}`}></i>
                </div>
                <div>
                  <div className="fw-bold lh-1 mb-1" style={{ fontSize: 22, color: s.color }}>
                    {isLoading ? "—" : s.val}
                  </div>
                  <div className="text-muted small">{s.label}</div>
                </div>
              </div>
            </div>
          </div>
        ))}
      </div>

      <div className="card border-0 shadow-sm" style={{ borderRadius: 14 }}>
        <div className="card-header bg-white py-3 px-4 d-flex align-items-center justify-content-between flex-wrap gap-2"
          style={{ borderBottom: "1px solid #f1f5f9" }}>
          <ul className="nav nav--tabs p-1 rounded bg-light">
            {[["all","All"],["active","Active"],["inactive","Inactive"]].map(([val, label]) => (
              <li key={val} className="nav-item">
                <button className={`nav-link${filterStatus === val ? " active" : ""}`}
                  onClick={() => setFilterStatus(val)} data-testid={`tab-${val}`}>{label}</button>
              </li>
            ))}
          </ul>
          <div style={{ display: "flex", alignItems: "center", gap: 6, background: "#f8fafc", border: "1.5px solid #e2e8f0", borderRadius: 10, padding: "6px 12px" }}>
            <i className="bi bi-search" style={{ fontSize: 12, color: "#94a3b8" }}></i>
            <input style={{ border: "none", background: "transparent", outline: "none", fontSize: 13, width: 180 }}
              placeholder="Search zones…" value={search} onChange={e => setSearch(e.target.value)}
              data-testid="input-search" />
          </div>
        </div>

        <div className="card-body p-0">
          <div className="table-responsive">
            <table className="table table-borderless align-middle table-hover mb-0">
              <thead style={{ background: "#f8fafc" }}>
                <tr>
                  {["#","Zone Name","Service Type","Surge","Status","Active","Actions"].map((h, i) => (
                    <th key={i} className={i === 0 ? "ps-4" : i === 6 ? "text-center pe-4" : ""}
                      style={{ fontSize: 11, color: "#94a3b8", fontWeight: 700, textTransform: "uppercase", letterSpacing: ".5px", paddingTop: 12, paddingBottom: 12 }}>
                      {h}
                    </th>
                  ))}
                </tr>
              </thead>
              <tbody>
                {isLoading ? (
                  Array(3).fill(0).map((_, i) => (
                    <tr key={i}>{Array(7).fill(0).map((_, j) => <td key={j}><div style={{ height: 14, background: "#f1f5f9", borderRadius: 4 }} /></td>)}</tr>
                  ))
                ) : filtered.length ? (
                  filtered.map((zone: any, idx: number) => {
                    const sc = getServiceConfig(zone.serviceType || "both");
                    const surge = Number(zone.surgeFactor) || 1;
                    return (
                      <tr key={zone.id} data-testid={`zone-row-${zone.id}`}>
                        <td className="ps-4 text-muted small">{idx + 1}</td>
                        <td>
                          <div className="d-flex align-items-center gap-2">
                            <div className="rounded-circle d-flex align-items-center justify-content-center flex-shrink-0"
                              style={{ width: 36, height: 36, background: "#f5f3ff", color: "#7c3aed", fontSize: 14 }}>
                              <i className="bi bi-map-fill"></i>
                            </div>
                            <div>
                              <div className="fw-semibold" style={{ fontSize: 13 }}>{zone.name}</div>
                              <div className="text-muted" style={{ fontSize: 10.5 }}>
                                {zone.coordinates ? "📍 Coordinates set" : "No coordinates"}
                              </div>
                            </div>
                          </div>
                        </td>
                        <td>
                          <span className="badge rounded-pill"
                            style={{ background: sc.color + "18", color: sc.color, fontSize: 11, padding: "4px 10px", fontWeight: 600 }}>
                            <i className={`bi ${sc.icon} me-1`}></i>{sc.label}
                          </span>
                        </td>
                        <td>
                          <span className={`badge ${surge > 1 ? "bg-warning text-dark" : "bg-secondary"}`} style={{ fontSize: 11 }}>
                            {surge.toFixed(1)}×{surge > 1 && <i className="bi bi-lightning-fill ms-1"></i>}
                          </span>
                        </td>
                        <td>
                          <span className={`badge ${zone.isActive ? "bg-success" : "bg-secondary"}`} style={{ fontSize: 10 }}>
                            {zone.isActive ? "Active" : "Inactive"}
                          </span>
                        </td>
                        <td>
                          <label className="switcher">
                            <input type="checkbox" className="switcher_input" checked={zone.isActive}
                              onChange={() => toggle.mutate({ id: zone.id, isActive: !zone.isActive })}
                              data-testid={`toggle-zone-${zone.id}`} />
                            <span className="switcher_control"></span>
                          </label>
                        </td>
                        <td className="text-center pe-4">
                          <div className="d-flex justify-content-center gap-1">
                            <button className="btn btn-sm btn-outline-primary" style={{ borderRadius: 8 }}
                              onClick={() => openEdit(zone)} data-testid={`btn-edit-zone-${zone.id}`}>
                              <i className="bi bi-pencil-fill"></i>
                            </button>
                            <button className="btn btn-sm btn-outline-danger" style={{ borderRadius: 8 }}
                              onClick={() => { if (confirm(`Delete zone "${zone.name}"?`)) remove.mutate(zone.id); }}
                              data-testid={`btn-delete-zone-${zone.id}`}>
                              <i className="bi bi-trash-fill"></i>
                            </button>
                          </div>
                        </td>
                      </tr>
                    );
                  })
                ) : (
                  <tr><td colSpan={7}>
                    <div className="text-center py-5 text-muted">
                      <i className="bi bi-map fs-1 d-block mb-2" style={{ opacity: 0.25 }}></i>
                      <p className="fw-semibold mb-1">No zones found</p>
                      <p className="small">Create your first zone to get started</p>
                    </div>
                  </td></tr>
                )}
              </tbody>
            </table>
          </div>
        </div>
      </div>

      <ZoneModal open={open} onClose={() => { setOpen(false); setEditing(null); }}
        editing={editing} form={form} setForm={setForm}
        onSave={() => save.mutate(form)} saving={save.isPending} />
    </div>
  );
}
