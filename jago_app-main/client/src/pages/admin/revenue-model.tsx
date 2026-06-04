import { useState } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { apiRequest } from "@/lib/queryClient";
import { useToast } from "@/hooks/use-toast";

const MODULE_META: Record<string, { label: string; icon: string; color: string; bg: string }> = {
  ride:       { label: "Ride",       icon: "bi-car-front-fill",  color: "#1a73e8", bg: "#EBF4FF" },
  parcel:     { label: "Parcel",     icon: "bi-box-seam-fill",   color: "#16a34a", bg: "#f0fdf4" },
  carpool:    { label: "Carpool",    icon: "bi-people-fill",     color: "#7c3aed", bg: "#f5f3ff" },
  outstation: { label: "Outstation", icon: "bi-signpost-2-fill", color: "#d97706", bg: "#fefce8" },
  b2b:        { label: "B2B",        icon: "bi-building-fill",   color: "#0891b2", bg: "#ecfeff" },
};

type ModuleConfig = {
  moduleName: string;
  revenueModel: "commission" | "subscription" | "free";
  commissionType: "percentage" | "flat";
  commissionPercentage: number;
  commissionFlatAmount: number;
  commissionGstPercentage: number;
  subscriptionRequired: boolean;
  isActive: boolean;
  notes: string;
};

function calcPreview(form: ModuleConfig, exFare: number) {
  if (form.revenueModel !== "commission") return { comm: 0, gst: 0, driver: exFare };
  const comm = form.commissionType === "flat"
    ? form.commissionFlatAmount
    : exFare * (form.commissionPercentage / 100);
  const gst = comm * (form.commissionGstPercentage / 100);
  return { comm, gst, driver: exFare - comm - gst };
}

function ModuleRow({ mod, onSaved }: { mod: ModuleConfig; onSaved: () => void }) {
  const { toast } = useToast();
  const [editing, setEditing] = useState(false);
  const [form, setForm] = useState<ModuleConfig>(mod);
  const [exFare, setExFare] = useState(200);
  const meta = MODULE_META[mod.moduleName] || { label: mod.moduleName, icon: "bi-gear", color: "#64748b", bg: "#f1f5f9" };

  const saveMut = useMutation({
    mutationFn: (data: any) => apiRequest("PUT", `/api/admin/module-revenue/${mod.moduleName}`, data),
    onSuccess: () => { toast({ title: `${meta.label} saved` }); setEditing(false); onSaved(); },
    onError: (e: any) => toast({ title: "Save failed", description: e.message, variant: "destructive" }),
  });

  const set = (key: keyof ModuleConfig, val: any) => setForm(f => ({ ...f, [key]: val }));
  const { comm, gst, driver } = calcPreview(form, exFare);

  // Display badge for current config
  const configBadge = () => {
    if (mod.revenueModel === "commission") {
      return mod.commissionType === "flat"
        ? `₹${mod.commissionFlatAmount}/ride`
        : `${mod.commissionPercentage}%`;
    }
    return mod.revenueModel;
  };

  return (
    <tr style={{ verticalAlign: "middle" }}>
      {/* Service */}
      <td className="ps-3 py-3">
        <div className="d-flex align-items-center gap-2">
          <div className="rounded-2 d-flex align-items-center justify-content-center flex-shrink-0"
            style={{ width: 34, height: 34, background: meta.bg, color: meta.color }}>
            <i className={`bi ${meta.icon}`} style={{ fontSize: 15 }}></i>
          </div>
          <div>
            <div className="fw-semibold" style={{ fontSize: 13 }}>{meta.label}</div>
            {mod.notes && <div className="text-muted" style={{ fontSize: 11 }}>{mod.notes}</div>}
          </div>
        </div>
      </td>

      {/* Config summary */}
      <td>
        {editing ? (
          <select className="form-select form-select-sm" value={form.revenueModel}
            onChange={e => set("revenueModel", e.target.value as any)} style={{ width: 140 }}>
            <option value="commission">Commission</option>
            <option value="subscription">Subscription</option>
            <option value="free">Free</option>
          </select>
        ) : (
          <span className={`badge rounded-pill ${mod.revenueModel === "commission" ? "bg-primary" : mod.revenueModel === "subscription" ? "bg-success" : "bg-secondary"}`}
            style={{ fontSize: 11 }}>
            {mod.revenueModel.charAt(0).toUpperCase() + mod.revenueModel.slice(1)}
          </span>
        )}
      </td>

      {/* Commission type + value */}
      <td>
        {editing && form.revenueModel === "commission" ? (
          <div style={{ minWidth: 220 }}>
            {/* Toggle: % or ₹ */}
            <div className="btn-group btn-group-sm mb-2" role="group">
              <button type="button"
                className={`btn ${form.commissionType === "percentage" ? "btn-primary" : "btn-outline-secondary"}`}
                onClick={() => set("commissionType", "percentage")}>
                % Percentage
              </button>
              <button type="button"
                className={`btn ${form.commissionType === "flat" ? "btn-primary" : "btn-outline-secondary"}`}
                onClick={() => set("commissionType", "flat")}>
                ₹ Fixed Amount
              </button>
            </div>
            {form.commissionType === "percentage" ? (
              <div className="d-flex align-items-center gap-1">
                <input type="number" className="form-control form-control-sm" value={form.commissionPercentage}
                  onChange={e => set("commissionPercentage", parseFloat(e.target.value) || 0)}
                  style={{ width: 80 }} min={0} max={100} step={0.5} />
                <span className="text-muted fw-semibold">%</span>
                <span className="text-muted" style={{ fontSize: 11 }}>of fare</span>
              </div>
            ) : (
              <div className="d-flex align-items-center gap-1">
                <span className="text-muted fw-semibold">₹</span>
                <input type="number" className="form-control form-control-sm" value={form.commissionFlatAmount}
                  onChange={e => set("commissionFlatAmount", parseFloat(e.target.value) || 0)}
                  style={{ width: 80 }} min={0} step={0.5} />
                <span className="text-muted" style={{ fontSize: 11 }}>per ride</span>
              </div>
            )}
          </div>
        ) : (
          <span className="fw-bold" style={{ color: meta.color, fontSize: 14 }}>{configBadge()}</span>
        )}
      </td>

      {/* GST % */}
      <td>
        {editing ? (
          <div className="d-flex align-items-center gap-1">
            <input type="number" className="form-control form-control-sm" value={form.commissionGstPercentage}
              onChange={e => set("commissionGstPercentage", parseFloat(e.target.value) || 0)}
              style={{ width: 70 }} min={0} max={30} step={0.5} />
            <span className="text-muted" style={{ fontSize: 13 }}>%</span>
          </div>
        ) : (
          <span style={{ fontSize: 13 }}>{mod.commissionGstPercentage}%</span>
        )}
      </td>

      {/* Active */}
      <td>
        <div className="form-check form-switch mb-0">
          <input className="form-check-input" type="checkbox" checked={form.isActive}
            onChange={e => {
              const v = e.target.checked;
              set("isActive", v);
              if (!editing) saveMut.mutate({ ...form, isActive: v });
            }} />
        </div>
      </td>

      {/* Live preview */}
      <td>
        <div style={{ fontSize: 11, lineHeight: 1.6, minWidth: 200 }}>
          {editing ? (
            <>
              <div className="d-flex align-items-center gap-1 mb-1">
                <span className="text-muted">Test fare ₹</span>
                <input type="number" className="form-control form-control-sm py-0" value={exFare}
                  onChange={e => setExFare(parseFloat(e.target.value) || 200)}
                  style={{ width: 70, height: 22, fontSize: 11 }} min={10} />
              </div>
              <div>Platform: <strong style={{ color: "#1a73e8" }}>₹{comm.toFixed(2)}</strong> + GST <strong>₹{gst.toFixed(2)}</strong></div>
              <div>Driver gets: <strong style={{ color: "#16a34a" }}>₹{driver.toFixed(2)}</strong></div>
            </>
          ) : (
            <>
              <div>₹200 fare → driver: <strong style={{ color: "#16a34a" }}>₹{calcPreview(mod, 200).driver.toFixed(0)}</strong></div>
              <div className="text-muted">Platform: ₹{calcPreview(mod, 200).comm.toFixed(0)} + GST ₹{calcPreview(mod, 200).gst.toFixed(0)}</div>
            </>
          )}
        </div>
      </td>

      {/* Actions */}
      <td className="pe-3">
        {editing ? (
          <div className="d-flex gap-1">
            <button className="btn btn-sm btn-primary px-3" style={{ fontSize: 11 }}
              disabled={saveMut.isPending}
              onClick={() => saveMut.mutate(form)}>
              {saveMut.isPending ? "Saving..." : "Save"}
            </button>
            <button className="btn btn-sm btn-outline-secondary" style={{ fontSize: 11 }}
              onClick={() => { setForm(mod); setEditing(false); }}>Cancel</button>
          </div>
        ) : (
          <button className="btn btn-sm btn-outline-primary" style={{ fontSize: 11 }}
            onClick={() => setEditing(true)}>
            <i className="bi bi-pencil me-1"></i>Edit
          </button>
        )}
      </td>
    </tr>
  );
}

export default function RevenueModelPage() {
  const qc = useQueryClient();

  const { data, isLoading } = useQuery<any>({
    queryKey: ["/api/admin/module-revenue"],
  });

  const modules: ModuleConfig[] = (data?.modules || []).map((m: any) => ({
    moduleName: m.moduleName,
    revenueModel: m.revenueModel || "commission",
    commissionType: m.commissionType || "percentage",
    commissionPercentage: parseFloat(m.commissionPercentage) || 0,
    commissionFlatAmount: parseFloat(m.commissionFlatAmount) || 0,
    commissionGstPercentage: parseFloat(m.commissionGstPercentage) || 18,
    subscriptionRequired: !!m.subscriptionRequired,
    isActive: m.isActive !== false,
    notes: m.notes || "",
  }));

  return (
    <div className="p-4">
      {/* Header */}
      <div className="d-flex align-items-center gap-3 mb-4">
        <div className="rounded-3 d-flex align-items-center justify-content-center"
          style={{ width: 44, height: 44, background: "#EBF4FF", color: "#1a73e8" }}>
          <i className="bi bi-diagram-3-fill" style={{ fontSize: 20 }}></i>
        </div>
        <div>
          <h4 className="mb-0 fw-bold" style={{ fontSize: 20 }}>Revenue Model</h4>
          <p className="mb-0 text-muted" style={{ fontSize: 13 }}>
            Per service: set % commission or fixed ₹ amount per ride — your choice
          </p>
        </div>
      </div>

      {/* Info banner */}
      <div className="alert border-0 mb-4 d-flex gap-3 align-items-start" style={{ background: "#f0f9ff", borderRadius: 12 }}>
        <i className="bi bi-info-circle-fill mt-1" style={{ color: "#1a73e8", fontSize: 16, flexShrink: 0 }}></i>
        <div style={{ fontSize: 13 }}>
          <strong>Two commission types available:</strong>
          <span className="ms-2"><strong>% Percentage</strong> — e.g. 15% of fare (higher fare = more platform revenue)</span>
          <span className="ms-3"><strong>₹ Fixed Amount</strong> — e.g. ₹1 per ride regardless of fare (predictable for driver)</span>
          <br />GST is calculated on top of commission amount in both cases.
        </div>
      </div>

      {/* Summary cards */}
      <div className="row g-3 mb-4">
        {[
          { label: "Active Services", value: modules.filter(m => m.isActive).length, icon: "bi-check-circle-fill", color: "#16a34a", bg: "#f0fdf4" },
          { label: "% Based", value: modules.filter(m => m.revenueModel === "commission" && m.commissionType === "percentage").length, icon: "bi-percent", color: "#1a73e8", bg: "#EBF4FF" },
          { label: "Fixed ₹ Amount", value: modules.filter(m => m.revenueModel === "commission" && m.commissionType === "flat").length, icon: "bi-currency-rupee", color: "#d97706", bg: "#fefce8" },
          { label: "Subscription", value: modules.filter(m => m.revenueModel === "subscription").length, icon: "bi-card-checklist", color: "#7c3aed", bg: "#f5f3ff" },
        ].map((s, i) => (
          <div className="col-6 col-md-3" key={i}>
            <div className="card border-0 h-100" style={{ borderRadius: 14, boxShadow: "0 1px 4px rgba(0,0,0,0.06)" }}>
              <div className="card-body d-flex align-items-center gap-3 p-3">
                <div className="rounded-3 d-flex align-items-center justify-content-center flex-shrink-0"
                  style={{ width: 44, height: 44, background: s.bg, color: s.color }}>
                  <i className={`bi ${s.icon}`} style={{ fontSize: 18 }}></i>
                </div>
                <div>
                  <div className="fw-bold" style={{ fontSize: 22 }}>{s.value}</div>
                  <div className="text-muted" style={{ fontSize: 12 }}>{s.label}</div>
                </div>
              </div>
            </div>
          </div>
        ))}
      </div>

      {/* Table */}
      <div className="card border-0" style={{ borderRadius: 16, boxShadow: "0 1px 8px rgba(0,0,0,0.07)" }}>
        <div className="card-body p-0">
          <div className="px-4 py-3" style={{ borderBottom: "1px solid #f1f5f9" }}>
            <h6 className="mb-0 fw-semibold">Service Revenue Configuration</h6>
            <p className="mb-0 text-muted" style={{ fontSize: 12 }}>Click Edit on any row — choose % or ₹ and enter your value</p>
          </div>
          {isLoading ? (
            <div className="text-center py-5">
              <div className="spinner-border text-primary spinner-border-sm"></div>
            </div>
          ) : (
            <div className="table-responsive">
              <table className="table table-borderless table-hover align-middle mb-0">
                <thead style={{ background: "#f8fafc" }}>
                  <tr>
                    <th className="ps-3 py-3" style={{ fontSize: 12, color: "#64748b", fontWeight: 600 }}>SERVICE</th>
                    <th style={{ fontSize: 12, color: "#64748b", fontWeight: 600 }}>MODEL</th>
                    <th style={{ fontSize: 12, color: "#64748b", fontWeight: 600 }}>COMMISSION (% or ₹)</th>
                    <th style={{ fontSize: 12, color: "#64748b", fontWeight: 600 }}>GST ON COMMISSION</th>
                    <th style={{ fontSize: 12, color: "#64748b", fontWeight: 600 }}>ACTIVE</th>
                    <th style={{ fontSize: 12, color: "#64748b", fontWeight: 600 }}>LIVE PREVIEW</th>
                    <th className="pe-3" style={{ fontSize: 12, color: "#64748b", fontWeight: 600 }}>ACTIONS</th>
                  </tr>
                </thead>
                <tbody>
                  {modules.length === 0 ? (
                    <tr><td colSpan={7}>
                      <div className="text-center py-5 text-muted">
                        <i className="bi bi-diagram-3 fs-1 d-block mb-2" style={{ opacity: 0.3 }}></i>
                        <p className="mb-0">No modules configured yet</p>
                      </div>
                    </td></tr>
                  ) : (
                    modules.map(mod => (
                      <ModuleRow key={mod.moduleName} mod={mod}
                        onSaved={() => qc.invalidateQueries({ queryKey: ["/api/admin/module-revenue"] })} />
                    ))
                  )}
                </tbody>
              </table>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
