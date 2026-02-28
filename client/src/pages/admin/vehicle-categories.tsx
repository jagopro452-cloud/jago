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

const vehicleIcons: Record<string, string> = {
  Bike: "bi-bicycle", Auto: "bi-car-front", Car: "bi-car-front-fill", SUV: "bi-truck-front-fill", "Parcel Bike": "bi-bicycle"
};

export default function VehicleCategories() {
  const { toast } = useToast();
  const qc = useQueryClient();
  const [open, setOpen] = useState(false);
  const [editing, setEditing] = useState<any>(null);
  const [form, setForm] = useState({ name: "", type: "ride" });

  const { data, isLoading } = useQuery<any[]>({ queryKey: ["/api/vehicle-categories"] });

  const save = useMutation({
    mutationFn: (data: any) => editing
      ? apiRequest("PUT", `/api/vehicle-categories/${editing.id}`, data)
      : apiRequest("POST", "/api/vehicle-categories", data),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["/api/vehicle-categories"] });
      toast({ title: editing ? "Category updated" : "Category created" });
      setOpen(false); setEditing(null); setForm({ name: "", type: "ride" });
    },
  });

  const remove = useMutation({
    mutationFn: (id: string) => apiRequest("DELETE", `/api/vehicle-categories/${id}`),
    onSuccess: () => { qc.invalidateQueries({ queryKey: ["/api/vehicle-categories"] }); toast({ title: "Deleted" }); },
  });

  const openCreate = () => { setEditing(null); setForm({ name: "", type: "ride" }); setOpen(true); };
  const openEdit = (cat: any) => { setEditing(cat); setForm({ name: cat.name, type: cat.type || "ride" }); setOpen(true); };

  return (
    <div>
      <div className="jago-page-header">
        <div>
          <h4 className="page-title" data-testid="page-title">Vehicle Categories</h4>
          <div className="breadcrumb">
            <i className="bi bi-house-fill"></i>
            <span>Home</span>
            <i className="bi bi-chevron-right" style={{ fontSize: "0.65rem" }}></i>
            <span>Vehicle Categories</span>
          </div>
        </div>
        <button className="btn-jago-primary" onClick={openCreate} data-testid="btn-add-category">
          <i className="bi bi-plus-circle-fill"></i> Add Category
        </button>
      </div>

      <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fill, minmax(220px, 1fr))", gap: "1rem" }}>
        {isLoading ? Array(4).fill(0).map((_, i) => (
          <div key={i} className="jago-card" style={{ padding: "1.25rem" }}>
            <div style={{ height: "80px", background: "#f1f5f9", borderRadius: "8px" }} />
          </div>
        )) : data?.map((cat: any) => (
          <div key={cat.id} className="jago-card" data-testid={`category-card-${cat.id}`} style={{ padding: "1.25rem" }}>
            <div style={{ display: "flex", alignItems: "flex-start", justifyContent: "space-between", marginBottom: "1rem" }}>
              <div style={{ width: "48px", height: "48px", borderRadius: "10px", background: "rgba(37,99,235,0.1)", display: "grid", placeItems: "center", color: "var(--bs-primary)", fontSize: "1.3rem" }}>
                <i className={`bi ${vehicleIcons[cat.name] || "bi-car-front-fill"}`}></i>
              </div>
              <div style={{ display: "flex", gap: "0.25rem" }}>
                <button
                  style={{ background: "none", border: "none", cursor: "pointer", color: "var(--bs-primary)", padding: "0.25rem", borderRadius: "4px", fontSize: "0.9rem" }}
                  onClick={() => openEdit(cat)}
                  data-testid={`btn-edit-${cat.id}`}
                >
                  <i className="bi bi-pencil-fill"></i>
                </button>
                <button
                  style={{ background: "none", border: "none", cursor: "pointer", color: "var(--bs-danger)", padding: "0.25rem", borderRadius: "4px", fontSize: "0.9rem" }}
                  onClick={() => { if (confirm("Delete this category?")) remove.mutate(cat.id); }}
                  data-testid={`btn-delete-${cat.id}`}
                >
                  <i className="bi bi-trash-fill"></i>
                </button>
              </div>
            </div>
            <h6 style={{ fontWeight: 700, color: "var(--title-color)", marginBottom: "0.5rem" }}>{cat.name}</h6>
            <div style={{ display: "flex", gap: "0.5rem", flexWrap: "wrap" }}>
              <span className="jago-badge badge-primary" style={{ textTransform: "capitalize" }}>{cat.type}</span>
              <span className={`jago-badge ${cat.isActive ? "badge-active" : "badge-inactive"}`}>
                {cat.isActive ? "Active" : "Inactive"}
              </span>
            </div>
          </div>
        ))}
      </div>

      {!isLoading && !data?.length && (
        <div className="jago-card"><div className="jago-empty"><i className="bi bi-car-front"></i><p>No vehicle categories found.</p></div></div>
      )}

      <Modal open={open} onClose={() => setOpen(false)} title={editing ? "Edit Category" : "Add Vehicle Category"}>
        <div style={{ display: "flex", flexDirection: "column", gap: "1rem" }}>
          <div>
            <label className="jago-label">Category Name *</label>
            <input
              className="jago-input"
              value={form.name}
              onChange={e => setForm(f => ({ ...f, name: e.target.value }))}
              placeholder="e.g. Bike, Auto, Car"
              data-testid="input-category-name"
            />
          </div>
          <div>
            <label className="jago-label">Type *</label>
            <select
              className="jago-input"
              value={form.type}
              onChange={e => setForm(f => ({ ...f, type: e.target.value }))}
              data-testid="select-type"
            >
              <option value="ride">Ride</option>
              <option value="parcel">Parcel</option>
            </select>
          </div>
          <div style={{ display: "flex", gap: "0.75rem", justifyContent: "flex-end", marginTop: "0.5rem" }}>
            <button className="btn-jago-outline" onClick={() => setOpen(false)}>Cancel</button>
            <button
              className="btn-jago-primary"
              onClick={() => save.mutate(form)}
              disabled={!form.name || save.isPending}
              data-testid="btn-save-category"
            >
              {save.isPending ? "Saving..." : editing ? "Update" : "Create"}
            </button>
          </div>
        </div>
      </Modal>
    </div>
  );
}
