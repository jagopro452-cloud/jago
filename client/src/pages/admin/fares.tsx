import { useState } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { apiRequest } from "@/lib/queryClient";
import { useToast } from "@/hooks/use-toast";

function Modal({ open, onClose, title, children }: any) {
  if (!open) return null;
  return (
    <div style={{ position: "fixed", inset: 0, background: "rgba(0,0,0,0.4)", zIndex: 9999, display: "flex", alignItems: "center", justifyContent: "center", padding: "1rem" }}>
      <div style={{ background: "#fff", borderRadius: "12px", width: "100%", maxWidth: "560px", padding: "1.5rem", boxShadow: "0 20px 60px rgba(0,0,0,0.2)" }}>
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

export default function Fares() {
  const { toast } = useToast();
  const qc = useQueryClient();
  const [open, setOpen] = useState(false);
  const [form, setForm] = useState({ zoneId: "", vehicleCategoryId: "", baseFare: "", farePerKm: "", farePerMin: "", minimumFare: "", cancellationFee: "" });

  const { data: fares, isLoading } = useQuery<any[]>({ queryKey: ["/api/fares"] });
  const { data: zones } = useQuery<any[]>({ queryKey: ["/api/zones"] });
  const { data: cats } = useQuery<any[]>({ queryKey: ["/api/vehicle-categories"] });

  const save = useMutation({
    mutationFn: (data: any) => apiRequest("POST", "/api/fares", data),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["/api/fares"] });
      toast({ title: "Fare rule saved successfully" });
      setOpen(false);
      setForm({ zoneId: "", vehicleCategoryId: "", baseFare: "", farePerKm: "", farePerMin: "", minimumFare: "", cancellationFee: "" });
    },
  });

  return (
    <div>
      <div className="jago-page-header">
        <div>
          <h4 className="page-title" data-testid="page-title">Fare Management</h4>
          <div className="breadcrumb">
            <i className="bi bi-house-fill"></i>
            <span>Home</span>
            <i className="bi bi-chevron-right" style={{ fontSize: "0.65rem" }}></i>
            <span>Trip Management</span>
            <i className="bi bi-chevron-right" style={{ fontSize: "0.65rem" }}></i>
            <span>Fare Management</span>
          </div>
        </div>
        <button className="btn-jago-primary" onClick={() => setOpen(true)} data-testid="btn-add-fare">
          <i className="bi bi-plus-circle-fill"></i> Add Fare Rule
        </button>
      </div>

      <div className="jago-card">
        <div className="jago-card-header">
          <h5 className="jago-card-title">
            <i className="bi bi-cash-stack" style={{ marginRight: "0.5rem", color: "var(--bs-primary)" }}></i>
            Fare Rules
          </h5>
        </div>
        <div className="jago-table-wrapper">
          <table className="jago-table">
            <thead>
              <tr>
                <th>#</th>
                <th>Zone</th>
                <th>Vehicle</th>
                <th>Base Fare</th>
                <th>Per KM</th>
                <th>Per Min</th>
                <th>Min Fare</th>
                <th>Cancel Fee</th>
              </tr>
            </thead>
            <tbody>
              {isLoading ? Array(4).fill(0).map((_, i) => (
                <tr key={i}>
                  {Array(8).fill(0).map((_, j) => <td key={j}><div style={{ height: "14px", background: "#f1f5f9", borderRadius: "4px" }} /></td>)}
                </tr>
              )) : fares?.length ? fares.map((item: any, idx: number) => (
                <tr key={item.fare.id} data-testid={`fare-row-${item.fare.id}`}>
                  <td style={{ color: "var(--bs-body-color)", fontSize: "0.8rem" }}>{idx + 1}</td>
                  <td style={{ fontWeight: 600 }}>{item.zone?.name || "All Zones"}</td>
                  <td>{item.vehicleCategory?.name || "All Vehicles"}</td>
                  <td style={{ fontWeight: 600, color: "var(--bs-primary)" }}>₹{Number(item.fare.baseFare).toFixed(2)}</td>
                  <td>₹{Number(item.fare.farePerKm).toFixed(2)}</td>
                  <td>₹{Number(item.fare.farePerMin).toFixed(2)}</td>
                  <td>₹{Number(item.fare.minimumFare).toFixed(2)}</td>
                  <td>₹{Number(item.fare.cancellationFee).toFixed(2)}</td>
                </tr>
              )) : (
                <tr>
                  <td colSpan={8}>
                    <div className="jago-empty">
                      <i className="bi bi-cash-stack"></i>
                      <p>No fare rules configured. Add your first fare rule.</p>
                    </div>
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </div>

      <Modal open={open} onClose={() => setOpen(false)} title="Add Fare Rule">
        <div style={{ display: "flex", flexDirection: "column", gap: "1rem" }}>
          <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: "1rem" }}>
            <div>
              <label className="jago-label">Zone</label>
              <select className="jago-input" value={form.zoneId} onChange={e => setForm(f => ({ ...f, zoneId: e.target.value }))}>
                <option value="">Select Zone</option>
                {zones?.map(z => <option key={z.id} value={z.id}>{z.name}</option>)}
              </select>
            </div>
            <div>
              <label className="jago-label">Vehicle Type</label>
              <select className="jago-input" value={form.vehicleCategoryId} onChange={e => setForm(f => ({ ...f, vehicleCategoryId: e.target.value }))}>
                <option value="">Select Vehicle</option>
                {cats?.map(c => <option key={c.id} value={c.id}>{c.name}</option>)}
              </select>
            </div>
          </div>
          <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: "1rem" }}>
            {[
              ["baseFare", "Base Fare (₹)"],
              ["farePerKm", "Fare per KM (₹)"],
              ["farePerMin", "Fare per Min (₹)"],
              ["minimumFare", "Minimum Fare (₹)"],
              ["cancellationFee", "Cancellation Fee (₹)"],
            ].map(([key, label]) => (
              <div key={key}>
                <label className="jago-label">{label}</label>
                <input
                  type="number"
                  className="jago-input"
                  value={(form as any)[key]}
                  onChange={e => setForm(f => ({ ...f, [key]: e.target.value }))}
                  placeholder="0.00"
                  data-testid={`input-${key}`}
                />
              </div>
            ))}
          </div>
          <div style={{ display: "flex", gap: "0.75rem", justifyContent: "flex-end", marginTop: "0.5rem" }}>
            <button className="btn-jago-outline" onClick={() => setOpen(false)}>Cancel</button>
            <button
              className="btn-jago-primary"
              onClick={() => save.mutate(form)}
              disabled={save.isPending}
              data-testid="btn-save-fare"
            >
              {save.isPending ? "Saving..." : "Save Rule"}
            </button>
          </div>
        </div>
      </Modal>
    </div>
  );
}
