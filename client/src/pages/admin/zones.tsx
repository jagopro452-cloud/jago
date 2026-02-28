import { useState } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { apiRequest } from "@/lib/queryClient";
import { useToast } from "@/hooks/use-toast";

function Modal({ open, onClose, title, children }: any) {
  if (!open) return null;
  return (
    <div style={{ position: "fixed", inset: 0, background: "rgba(0,0,0,0.4)", zIndex: 9999, display: "flex", alignItems: "center", justifyContent: "center", padding: "1rem" }}>
      <div style={{ background: "#fff", borderRadius: "12px", width: "100%", maxWidth: "480px", padding: "1.5rem", boxShadow: "0 20px 60px rgba(0,0,0,0.2)" }}>
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

export default function Zones() {
  const { toast } = useToast();
  const qc = useQueryClient();
  const [open, setOpen] = useState(false);
  const [editing, setEditing] = useState<any>(null);
  const [form, setForm] = useState({ name: "", coordinates: "" });

  const { data, isLoading } = useQuery<any[]>({ queryKey: ["/api/zones"] });

  const save = useMutation({
    mutationFn: (data: any) => editing
      ? apiRequest("PUT", `/api/zones/${editing.id}`, data)
      : apiRequest("POST", "/api/zones", data),
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

  const openCreate = () => { setEditing(null); setForm({ name: "", coordinates: "" }); setOpen(true); };
  const openEdit = (zone: any) => { setEditing(zone); setForm({ name: zone.name, coordinates: zone.coordinates || "" }); setOpen(true); };

  return (
    <div>
      <div className="jago-page-header">
        <div>
          <h4 className="page-title" data-testid="page-title">Zone Setup</h4>
          <div className="breadcrumb">
            <i className="bi bi-house-fill"></i>
            <span>Home</span>
            <i className="bi bi-chevron-right" style={{ fontSize: "0.65rem" }}></i>
            <span>Zone Management</span>
          </div>
        </div>
        <button className="btn-jago-primary" onClick={openCreate} data-testid="btn-add-zone">
          <i className="bi bi-plus-circle-fill"></i> Add Zone
        </button>
      </div>

      <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fill, minmax(240px, 1fr))", gap: "1rem" }}>
        {isLoading ? Array(4).fill(0).map((_, i) => (
          <div key={i} className="jago-card" style={{ padding: "1.25rem" }}>
            <div style={{ height: "80px", background: "#f1f5f9", borderRadius: "8px" }} />
          </div>
        )) : data?.map((zone: any) => (
          <div key={zone.id} className="jago-card" data-testid={`zone-card-${zone.id}`} style={{ padding: "1.25rem" }}>
            <div style={{ display: "flex", alignItems: "flex-start", justifyContent: "space-between", marginBottom: "1rem" }}>
              <div style={{ width: "48px", height: "48px", borderRadius: "10px", background: "rgba(139,92,246,0.1)", display: "grid", placeItems: "center", color: "#8b5cf6", fontSize: "1.3rem" }}>
                <i className="bi bi-map-fill"></i>
              </div>
              <div style={{ display: "flex", gap: "0.25rem" }}>
                <button
                  style={{ background: "none", border: "none", cursor: "pointer", color: "var(--bs-primary)", padding: "0.25rem", borderRadius: "4px", fontSize: "0.9rem" }}
                  onClick={() => openEdit(zone)}
                  data-testid={`btn-edit-zone-${zone.id}`}
                >
                  <i className="bi bi-pencil-fill"></i>
                </button>
                <button
                  style={{ background: "none", border: "none", cursor: "pointer", color: "var(--bs-danger)", padding: "0.25rem", borderRadius: "4px", fontSize: "0.9rem" }}
                  onClick={() => { if (confirm("Delete this zone?")) remove.mutate(zone.id); }}
                  data-testid={`btn-delete-zone-${zone.id}`}
                >
                  <i className="bi bi-trash-fill"></i>
                </button>
              </div>
            </div>
            <h6 style={{ fontWeight: 700, color: "var(--title-color)", marginBottom: "0.5rem" }}>{zone.name}</h6>
            <span className={`jago-badge ${zone.isActive ? "badge-active" : "badge-inactive"}`}>
              {zone.isActive ? "Active" : "Inactive"}
            </span>
          </div>
        ))}
      </div>

      {!isLoading && !data?.length && (
        <div className="jago-card">
          <div className="jago-empty">
            <i className="bi bi-map"></i>
            <p>No zones configured yet. Add your first service zone.</p>
          </div>
        </div>
      )}

      <Modal open={open} onClose={() => setOpen(false)} title={editing ? "Edit Zone" : "Add Service Zone"}>
        <div style={{ display: "flex", flexDirection: "column", gap: "1rem" }}>
          <div>
            <label className="jago-label">Zone Name *</label>
            <input
              className="jago-input"
              value={form.name}
              onChange={e => setForm(f => ({ ...f, name: e.target.value }))}
              placeholder="e.g. Hyderabad Central"
              data-testid="input-zone-name"
            />
          </div>
          <div style={{ display: "flex", gap: "0.75rem", justifyContent: "flex-end", marginTop: "0.5rem" }}>
            <button className="btn-jago-outline" onClick={() => setOpen(false)}>Cancel</button>
            <button
              className="btn-jago-primary"
              onClick={() => save.mutate(form)}
              disabled={!form.name || save.isPending}
              data-testid="btn-save-zone"
            >
              {save.isPending ? "Saving..." : editing ? "Update Zone" : "Create Zone"}
            </button>
          </div>
        </div>
      </Modal>
    </div>
  );
}
