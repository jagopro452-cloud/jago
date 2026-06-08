import { useQuery, useMutation } from "@tanstack/react-query";
import { queryClient, apiRequest } from "@/lib/queryClient";
import { useState } from "react";
import { useToast } from "@/hooks/use-toast";

const avatarBg = (name: string) => {
  const colors = ["#1a73e8", "#16a34a", "#d97706", "#9333ea", "#0891b2", "#dc2626"];
  return colors[(name || "A").charCodeAt(0) % colors.length];
};

const initials = (name: string) =>
  (name || "?")
    .split(" ")
    .map((n) => n[0])
    .join("")
    .substring(0, 2)
    .toUpperCase();

const fmt = (n: any) =>
  Number(n || 0).toLocaleString("en-IN", { maximumFractionDigits: 0 });

function commissionPreview(fr: any, fare = 200) {
  if (fr.commission_type === "flat") return Number(fr.commission_flat || 0);
  return (fare * Number(fr.commission_percent || 0)) / 100;
}

type FormState = {
  name: string;
  ownerName: string;
  email: string;
  password: string;
  phone: string;
  zoneId: string;
  commissionType: "percentage" | "flat";
  commissionPercent: string;
  commissionFlat: string;
  isActive: boolean;
};

const emptyForm: FormState = {
  name: "",
  ownerName: "",
  email: "",
  password: "",
  phone: "",
  zoneId: "",
  commissionType: "percentage",
  commissionPercent: "",
  commissionFlat: "",
  isActive: true,
};

export default function FranchiseesPage() {
  const { toast } = useToast();
  const [showModal, setShowModal] = useState(false);
  const [editing, setEditing] = useState<any>(null);
  const [viewingStats, setViewingStats] = useState<any>(null);
  const [form, setForm] = useState<FormState>(emptyForm);
  const f = (k: keyof FormState, v: any) => setForm((p) => ({ ...p, [k]: v }));

  const { data = [], isLoading } = useQuery<any[]>({
    queryKey: ["/api/admin/franchisees"],
    queryFn: () =>
      fetch("/api/admin/franchisees")
        .then((r) =>
          r.ok ? r.json() : r.json().then((d) => { throw new Error(d?.message || "Error"); }),
        )
        .then((d) => (Array.isArray(d) ? d : [])),
  });

  const { data: zones = [] } = useQuery<any[]>({
    queryKey: ["/api/zones"],
    queryFn: () =>
      fetch("/api/zones")
        .then((r) =>
          r.ok ? r.json() : r.json().then((d) => { throw new Error(d?.message || "Error"); }),
        )
        .then((d) => (Array.isArray(d) ? d : d?.data && Array.isArray(d.data) ? d.data : [])),
  });

  const { data: stats } = useQuery<any>({
    queryKey: ["/api/admin/franchisees", viewingStats?.id, "stats"],
    queryFn: () =>
      fetch(`/api/admin/franchisees/${viewingStats.id}/stats`).then((r) =>
        r.ok ? r.json() : r.json().then((d) => { throw new Error(d?.message || "Error"); }),
      ),
    enabled: !!viewingStats?.id,
  });

  const saveMutation = useMutation({
    mutationFn: (payload: any) =>
      editing
        ? apiRequest("PUT", `/api/admin/franchisees/${editing.id}`, payload)
        : apiRequest("POST", "/api/admin/franchisees", payload),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["/api/admin/franchisees"] });
      toast({ title: editing ? "Franchise updated" : "Franchise created" });
      setShowModal(false);
      setEditing(null);
      setForm(emptyForm);
    },
    onError: (e: any) =>
      toast({ title: "Error", description: e.message, variant: "destructive" }),
  });

  const deleteMutation = useMutation({
    mutationFn: (id: string) => apiRequest("DELETE", `/api/admin/franchisees/${id}`),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["/api/admin/franchisees"] });
      toast({ title: "Deleted" });
    },
  });

  const toggleMutation = useMutation({
    mutationFn: ({ id, isActive }: any) =>
      apiRequest("PUT", `/api/admin/franchisees/${id}`, { isActive }),
    onSuccess: () =>
      queryClient.invalidateQueries({ queryKey: ["/api/admin/franchisees"] }),
  });

  const openCreate = () => {
    setEditing(null);
    setForm(emptyForm);
    setShowModal(true);
  };

  const openEdit = (fr: any) => {
    setEditing(fr);
    setForm({
      name: fr.name,
      ownerName: fr.owner_name,
      email: fr.email,
      password: "",
      phone: fr.phone || "",
      zoneId: fr.zone_id || "",
      commissionType: fr.commission_type === "flat" ? "flat" : "percentage",
      commissionPercent: String(fr.commission_percent || ""),
      commissionFlat: String(fr.commission_flat || ""),
      isActive: fr.is_active,
    });
    setShowModal(true);
  };

  const handleSave = () => {
    saveMutation.mutate({
      name: form.name,
      ownerName: form.ownerName,
      email: form.email,
      password: form.password || undefined,
      phone: form.phone,
      zoneId: form.zoneId || undefined,
      commissionType: form.commissionType,
      commissionPercent:
        form.commissionType === "percentage" ? parseFloat(form.commissionPercent) || 0 : 0,
      commissionFlat:
        form.commissionType === "flat" ? parseFloat(form.commissionFlat) || 0 : 0,
      isActive: form.isActive,
    });
  };

  const franchisees = Array.isArray(data) ? data : [];
  const zonesArr = Array.isArray(zones) ? zones : [];
  const totalEarnings = franchisees.reduce((s, x) => s + Number(x.total_earnings || 0), 0);
  const previewFare = 200;
  const previewComm =
    form.commissionType === "flat"
      ? parseFloat(form.commissionFlat) || 0
      : (previewFare * (parseFloat(form.commissionPercent) || 0)) / 100;

  return (
    <div className="p-4">
      <div className="d-flex justify-content-between align-items-center mb-4">
        <div>
          <h4 className="mb-0 fw-bold" style={{ color: "#1a1a2e" }}>
            <i className="bi bi-building me-2" style={{ color: "#7c3aed" }}></i>
            Franchise Management
          </h4>
          <small className="text-muted">
            Zone-wise franchise partners - admin sets commission, franchisee earns it
          </small>
        </div>
        <button
          className="btn btn-sm px-3 py-2 fw-semibold text-white"
          style={{ background: "#7c3aed", borderRadius: 8 }}
          onClick={openCreate}
        >
          <i className="bi bi-plus-lg me-1"></i> Add Franchise
        </button>
      </div>

      <div className="row g-3 mb-4">
        {[
          { label: "Total Franchises", val: franchisees.length, icon: "bi-building", color: "#7c3aed" },
          { label: "Active", val: franchisees.filter((fr) => fr.is_active).length, icon: "bi-check-circle-fill", color: "#16a34a" },
          { label: "Total Trips", val: fmt(franchisees.reduce((s, x) => s + Number(x.total_trips || 0), 0)), icon: "bi-car-front-fill", color: "#1a73e8" },
          { label: "Total Franchise Earnings", val: `₹${fmt(totalEarnings)}`, icon: "bi-currency-rupee", color: "#d97706" },
        ].map((card) => (
          <div className="col-6 col-md-3" key={card.label}>
            <div className="card border-0 shadow-sm h-100" style={{ borderRadius: 12 }}>
              <div className="card-body d-flex align-items-center gap-3 p-3">
                <div
                  className="rounded-circle d-flex align-items-center justify-content-center flex-shrink-0"
                  style={{ width: 44, height: 44, background: `${card.color}18` }}
                >
                  <i className={`${card.icon} fs-5`} style={{ color: card.color }}></i>
                </div>
                <div>
                  <div className="fw-bold fs-5">{card.val}</div>
                  <div className="text-muted small">{card.label}</div>
                </div>
              </div>
            </div>
          </div>
        ))}
      </div>

      <div className="card border-0 shadow-sm" style={{ borderRadius: 12 }}>
        <div className="card-body p-0">
          {isLoading ? (
            <div className="text-center py-5">
              <div className="spinner-border" style={{ color: "#7c3aed" }}></div>
            </div>
          ) : franchisees.length === 0 ? (
            <div className="text-center py-5 text-muted">
              <i className="bi bi-building fs-1 d-block mb-2"></i>
              No franchises yet.
            </div>
          ) : (
            <div className="table-responsive">
              <table className="table table-hover mb-0 align-middle">
                <thead style={{ background: "#f8f9fb" }}>
                  <tr>
                    <th className="border-0 ps-4 py-3">Franchise</th>
                    <th className="border-0 py-3">Zone</th>
                    <th className="border-0 py-3">Commission (Admin Set)</th>
                    <th className="border-0 py-3">Trips</th>
                    <th className="border-0 py-3">Earned</th>
                    <th className="border-0 py-3">Status</th>
                    <th className="border-0 py-3">Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {franchisees.map((fr) => (
                    <tr key={fr.id}>
                      <td className="ps-4">
                        <div className="d-flex align-items-center gap-2">
                          <div
                            className="rounded-circle d-flex align-items-center justify-content-center text-white fw-bold flex-shrink-0"
                            style={{ width: 36, height: 36, fontSize: 13, background: avatarBg(fr.name) }}
                          >
                            {initials(fr.name)}
                          </div>
                          <div>
                            <div className="fw-semibold" style={{ fontSize: 14 }}>{fr.name}</div>
                            <div className="text-muted" style={{ fontSize: 12 }}>
                              {fr.owner_name} · {fr.phone || fr.email}
                            </div>
                          </div>
                        </div>
                      </td>
                      <td>
                        {fr.zone_name ? (
                          <span className="badge rounded-pill" style={{ background: "#7c3aed18", color: "#7c3aed" }}>
                            <i className="bi bi-map me-1"></i>
                            {fr.zone_name}
                          </span>
                        ) : (
                          <span className="text-muted small">No zone</span>
                        )}
                      </td>
                      <td>
                        <div className="d-flex align-items-center gap-2">
                          <span
                            className="badge rounded-pill fw-semibold"
                            style={{
                              background: fr.commission_type === "flat" ? "#d9770618" : "#1a73e818",
                              color: fr.commission_type === "flat" ? "#d97706" : "#1a73e8",
                              fontSize: 13,
                              padding: "4px 10px",
                            }}
                          >
                            {fr.commission_type === "flat" ? (
                              <>
                                <i className="bi bi-currency-rupee me-1"></i>
                                ₹{Number(fr.commission_flat || 0).toFixed(0)} / ride
                              </>
                            ) : (
                              <>
                                <i className="bi bi-percent me-1"></i>
                                {Number(fr.commission_percent || 0).toFixed(1)}% of fare
                              </>
                            )}
                          </span>
                        </div>
                        <div className="text-muted mt-1" style={{ fontSize: 11 }}>
                          On ₹200 ride →{" "}
                          <strong style={{ color: "#16a34a" }}>
                            ₹{commissionPreview(fr, 200).toFixed(0)}
                          </strong>{" "}
                          to franchise
                        </div>
                      </td>
                      <td><span className="fw-semibold">{fmt(fr.total_trips)}</span></td>
                      <td><span className="fw-bold" style={{ color: "#16a34a", fontSize: 15 }}>₹{fmt(fr.total_earnings)}</span></td>
                      <td>
                        <div className="form-check form-switch mb-0">
                          <input
                            className="form-check-input"
                            type="checkbox"
                            checked={fr.is_active}
                            onChange={(e) => toggleMutation.mutate({ id: fr.id, isActive: e.target.checked })}
                          />
                        </div>
                      </td>
                      <td>
                        <div className="d-flex gap-1">
                          <button className="btn btn-sm btn-light px-2" title="View Stats" onClick={() => setViewingStats(fr)}>
                            <i className="bi bi-bar-chart-fill" style={{ color: "#1a73e8" }}></i>
                          </button>
                          <button className="btn btn-sm btn-light px-2" title="Edit" onClick={() => openEdit(fr)}>
                            <i className="bi bi-pencil-fill" style={{ color: "#7c3aed" }}></i>
                          </button>
                          <button
                            className="btn btn-sm btn-light px-2"
                            title="Delete"
                            onClick={() => {
                              if (confirm(`Delete "${fr.name}"?`)) deleteMutation.mutate(fr.id);
                            }}
                          >
                            <i className="bi bi-trash-fill" style={{ color: "#dc2626" }}></i>
                          </button>
                        </div>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </div>
      </div>

      {showModal && (
        <div className="modal show d-block" style={{ background: "rgba(0,0,0,0.5)" }}>
          <div className="modal-dialog modal-dialog-centered modal-lg">
            <div className="modal-content border-0 shadow-lg" style={{ borderRadius: 16 }}>
              <div className="modal-header border-0 pb-0 px-4 pt-4">
                <h5 className="modal-title fw-bold">{editing ? "Edit Franchise" : "Add Franchise"}</h5>
                <button className="btn-close" onClick={() => setShowModal(false)}></button>
              </div>
              <div className="modal-body px-4 py-3">
                <div className="row g-3">
                  <div className="col-12">
                    <label className="form-label small fw-semibold">Franchise Name *</label>
                    <input className="form-control" placeholder="e.g. Hyderabad North Franchise" value={form.name} onChange={(e) => f("name", e.target.value)} />
                  </div>
                  <div className="col-md-6">
                    <label className="form-label small fw-semibold">Owner Name *</label>
                    <input className="form-control" placeholder="Full name" value={form.ownerName} onChange={(e) => f("ownerName", e.target.value)} />
                  </div>
                  <div className="col-md-6">
                    <label className="form-label small fw-semibold">Phone</label>
                    <input className="form-control" placeholder="10-digit" value={form.phone} onChange={(e) => f("phone", e.target.value)} />
                  </div>
                  <div className="col-md-6">
                    <label className="form-label small fw-semibold">Email *</label>
                    <input className="form-control" type="email" value={form.email} onChange={(e) => f("email", e.target.value)} />
                  </div>
                  <div className="col-md-6">
                    <label className="form-label small fw-semibold">
                      {editing ? "New Password (leave blank to keep)" : "Password *"}
                    </label>
                    <input className="form-control" type="password" placeholder="••••••••" value={form.password} onChange={(e) => f("password", e.target.value)} />
                  </div>
                  <div className="col-12">
                    <label className="form-label small fw-semibold">Assign Zone</label>
                    <select className="form-select" value={form.zoneId} onChange={(e) => f("zoneId", e.target.value)}>
                      <option value="">— No zone —</option>
                      {zonesArr.map((zone: any) => (
                        <option key={zone.id} value={zone.id}>{zone.name}</option>
                      ))}
                    </select>
                  </div>
                  <div className="col-12">
                    <div className="rounded-3 p-3" style={{ background: "#f8f9fb", border: "1px solid #e9ecef" }}>
                      <div className="fw-semibold mb-1" style={{ fontSize: 14 }}>
                        <i className="bi bi-cash-coin me-2" style={{ color: "#d97706" }}></i>
                        Commission - Admin Sets This
                      </div>
                      <div className="text-muted mb-3" style={{ fontSize: 12 }}>
                        This amount goes to the franchise partner per completed ride. Choose % or fixed ₹.
                      </div>
                      <div className="d-flex gap-2 mb-3">
                        <button
                          type="button"
                          className={`btn fw-semibold px-4 ${form.commissionType === "percentage" ? "text-white" : "btn-outline-secondary"}`}
                          style={form.commissionType === "percentage" ? { background: "#1a73e8", border: "none" } : {}}
                          onClick={() => f("commissionType", "percentage")}
                        >
                          <i className="bi bi-percent me-2"></i>Percentage %
                        </button>
                        <button
                          type="button"
                          className={`btn fw-semibold px-4 ${form.commissionType === "flat" ? "text-white" : "btn-outline-secondary"}`}
                          style={form.commissionType === "flat" ? { background: "#d97706", border: "none" } : {}}
                          onClick={() => f("commissionType", "flat")}
                        >
                          <i className="bi bi-currency-rupee me-2"></i>Fixed ₹ Amount
                        </button>
                      </div>
                      {form.commissionType === "percentage" ? (
                        <div className="d-flex align-items-center gap-2">
                          <div className="input-group" style={{ width: 180 }}>
                            <input
                              type="number"
                              className="form-control fw-semibold"
                              placeholder="0"
                              value={form.commissionPercent}
                              onChange={(e) => f("commissionPercent", e.target.value)}
                              min={0}
                              max={100}
                              step={0.5}
                              style={{ fontSize: 18 }}
                            />
                            <span className="input-group-text fw-bold" style={{ color: "#1a73e8" }}>%</span>
                          </div>
                          <span className="text-muted" style={{ fontSize: 13 }}>of ride fare</span>
                        </div>
                      ) : (
                        <div className="d-flex align-items-center gap-2">
                          <div className="input-group" style={{ width: 180 }}>
                            <span className="input-group-text fw-bold" style={{ color: "#d97706" }}>₹</span>
                            <input
                              type="number"
                              className="form-control fw-semibold"
                              placeholder="0"
                              value={form.commissionFlat}
                              onChange={(e) => f("commissionFlat", e.target.value)}
                              min={0}
                              step={0.5}
                              style={{ fontSize: 18 }}
                            />
                          </div>
                          <span className="text-muted" style={{ fontSize: 13 }}>per completed ride</span>
                        </div>
                      )}
                      {previewComm > 0 && (
                        <div className="mt-3 rounded-2 p-2 d-flex align-items-center gap-2" style={{ background: "#16a34a10", border: "1px solid #16a34a30" }}>
                          <i className="bi bi-calculator" style={{ color: "#16a34a" }}></i>
                          <span style={{ fontSize: 13 }}>
                            On a <strong>₹{previewFare}</strong> ride → franchise earns{" "}
                            <strong style={{ color: "#16a34a", fontSize: 15 }}>₹{previewComm.toFixed(2)}</strong>
                            {form.commissionType === "percentage" && (
                              <span className="text-muted"> ({form.commissionPercent}% of fare)</span>
                            )}
                            {form.commissionType === "flat" && (
                              <span className="text-muted"> (fixed amount)</span>
                            )}
                          </span>
                        </div>
                      )}
                    </div>
                  </div>
                </div>
              </div>
              <div className="modal-footer border-0 px-4 pb-4 pt-0">
                <button className="btn btn-light px-4" onClick={() => setShowModal(false)}>Cancel</button>
                <button
                  className="btn text-white px-4 fw-semibold"
                  style={{ background: "#7c3aed", borderRadius: 8 }}
                  disabled={saveMutation.isPending}
                  onClick={handleSave}
                >
                  {saveMutation.isPending ? <span className="spinner-border spinner-border-sm me-1"></span> : null}
                  {editing ? "Update" : "Create Franchise"}
                </button>
              </div>
            </div>
          </div>
        </div>
      )}

      {viewingStats && (
        <div className="modal show d-block" style={{ background: "rgba(0,0,0,0.5)" }}>
          <div className="modal-dialog modal-dialog-centered modal-lg">
            <div className="modal-content border-0 shadow-lg" style={{ borderRadius: 16 }}>
              <div className="modal-header border-0 px-4 pt-4 pb-0">
                <div>
                  <h5 className="modal-title fw-bold">{viewingStats.name}</h5>
                  <div className="d-flex align-items-center gap-2 mt-1">
                    {viewingStats.zone_name && (
                      <span className="badge rounded-pill" style={{ background: "#7c3aed18", color: "#7c3aed" }}>
                        <i className="bi bi-map me-1"></i>
                        {viewingStats.zone_name}
                      </span>
                    )}
                    <span
                      className="badge rounded-pill fw-semibold"
                      style={{
                        background: viewingStats.commission_type === "flat" ? "#d9770618" : "#1a73e818",
                        color: viewingStats.commission_type === "flat" ? "#d97706" : "#1a73e8",
                      }}
                    >
                      {viewingStats.commission_type === "flat"
                        ? `₹${Number(viewingStats.commission_flat || 0).toFixed(0)}/ride`
                        : `${Number(viewingStats.commission_percent || 0).toFixed(1)}% commission`}
                    </span>
                  </div>
                </div>
                <button className="btn-close" onClick={() => setViewingStats(null)}></button>
              </div>
              <div className="modal-body px-4 py-3">
                {!stats ? (
                  <div className="text-center py-4">
                    <div className="spinner-border" style={{ color: "#7c3aed" }}></div>
                  </div>
                ) : (
                  <>
                    <div className="row g-3 mb-4">
                      {[
                        { label: "Completed Trips", val: fmt(stats.summary?.completed_trips), color: "#16a34a" },
                        { label: "Cancelled", val: fmt(stats.summary?.cancelled_trips), color: "#dc2626" },
                        { label: "Total Ride Revenue", val: `₹${fmt(stats.summary?.total_revenue)}`, color: "#1a73e8" },
                        { label: "Franchise Earned", val: `₹${fmt(stats.summary?.franchise_earnings)}`, color: "#d97706" },
                        { label: "Drivers in Zone", val: fmt(stats.summary?.active_drivers), color: "#7c3aed" },
                        { label: "Customers", val: fmt(stats.summary?.active_customers), color: "#0891b2" },
                      ].map((card) => (
                        <div className="col-6 col-md-4" key={card.label}>
                          <div className="border rounded-3 p-3 text-center">
                            <div className="fw-bold fs-5" style={{ color: card.color }}>{card.val}</div>
                            <div className="text-muted small">{card.label}</div>
                          </div>
                        </div>
                      ))}
                    </div>
                    <h6 className="fw-bold mb-2">Recent Trips</h6>
                    <div className="table-responsive" style={{ maxHeight: 250, overflowY: "auto" }}>
                      <table className="table table-sm table-hover mb-0">
                        <thead style={{ background: "#f8f9fb", position: "sticky", top: 0 }}>
                          <tr>
                            <th>Ref</th>
                            <th>Customer</th>
                            <th>Fare</th>
                            <th>Franchise Earned</th>
                            <th>Status</th>
                          </tr>
                        </thead>
                        <tbody>
                          {(stats.recentTrips || []).map((trip: any) => (
                            <tr key={trip.ref_id}>
                              <td className="small fw-semibold">{trip.ref_id}</td>
                              <td className="small">{trip.customer_name || "—"}</td>
                              <td className="small">₹{fmt(trip.total_fare)}</td>
                              <td className="small fw-semibold" style={{ color: "#16a34a" }}>
                                ₹{commissionPreview(viewingStats, Number(trip.total_fare || 0)).toFixed(0)}
                              </td>
                              <td>
                                <span
                                  className={`badge rounded-pill ${trip.current_status === "completed" ? "bg-success" : trip.current_status === "cancelled" ? "bg-danger" : "bg-secondary"}`}
                                  style={{ fontSize: 10 }}
                                >
                                  {trip.current_status}
                                </span>
                              </td>
                            </tr>
                          ))}
                          {!(stats.recentTrips || []).length && (
                            <tr>
                              <td colSpan={5} className="text-center text-muted py-3">No trips yet</td>
                            </tr>
                          )}
                        </tbody>
                      </table>
                    </div>
                  </>
                )}
              </div>
              <div className="modal-footer border-0 px-4 pb-4 pt-0">
                <button className="btn btn-light px-4" onClick={() => setViewingStats(null)}>Close</button>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
