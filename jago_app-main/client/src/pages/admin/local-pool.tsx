import { useState } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { apiRequest } from "@/lib/queryClient";
import { useToast } from "@/hooks/use-toast";

const STATUS_COLORS: Record<string, string> = {
  collecting: "#d97706",
  dispatching: "#7c3aed",
  accepted: "#2563eb",
  started: "#0891b2",
  completed: "#16a34a",
  cancelled: "#dc2626",
};

function StatusBadge({ status }: { status: string }) {
  const color = STATUS_COLORS[status] || "#64748b";
  return (
    <span style={{ background: color + "18", color, border: `1px solid ${color}44`, borderRadius: 20, padding: "2px 10px", fontSize: "0.72rem", fontWeight: 600, textTransform: "capitalize" }}>
      {status}
    </span>
  );
}

function PassengersModal({ rideId, onClose }: { rideId: string; onClose: () => void }) {
  const { data, isLoading } = useQuery<any>({
    queryKey: [`/api/admin/local-pool/rides/${rideId}/passengers`],
  });
  const passengers = data?.data || [];
  return (
    <div className="modal-backdrop-jago">
      <div className="modal-jago" style={{ maxWidth: 680 }}>
        <div className="modal-jago-header">
          <h5 className="modal-jago-title">Passengers in Pool Ride</h5>
          <button className="modal-jago-close" onClick={onClose}><i className="bi bi-x-lg"></i></button>
        </div>
        {isLoading ? (
          <div className="text-center py-4"><div className="spinner-border spinner-border-sm text-primary"></div></div>
        ) : passengers.length === 0 ? (
          <p className="text-muted text-center py-4">No passengers found.</p>
        ) : (
          <div className="table-responsive">
            <table className="table table-borderless align-middle" style={{ fontSize: "0.8rem" }}>
              <thead className="table-light">
                <tr>
                  <th>#</th>
                  <th>Customer</th>
                  <th>Pickup</th>
                  <th>Drop</th>
                  <th>Seats</th>
                  <th>Fare/Seat</th>
                  <th>Total</th>
                  <th>Status</th>
                </tr>
              </thead>
              <tbody>
                {passengers.map((p: any, i: number) => (
                  <tr key={p.id}>
                    <td>{i + 1}</td>
                    <td>
                      <div className="fw-semibold">{p.customerName || "—"}</div>
                      <div className="text-muted" style={{ fontSize: "0.72rem" }}>{p.customerPhone}</div>
                    </td>
                    <td style={{ maxWidth: 160 }}><span className="text-truncate d-block">{p.pickupAddress || `${p.pickupLat}, ${p.pickupLng}`}</span></td>
                    <td style={{ maxWidth: 160 }}><span className="text-truncate d-block">{p.dropAddress || `${p.dropLat}, ${p.dropLng}`}</span></td>
                    <td className="text-center">{p.seatsBooked}</td>
                    <td>₹{Number(p.farePerSeat || 0).toFixed(2)}</td>
                    <td className="fw-semibold">₹{Number(p.totalFare || 0).toFixed(2)}</td>
                    <td><StatusBadge status={p.status || "booked"} /></td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>
    </div>
  );
}

export default function LocalPool() {
  const { toast } = useToast();
  const qc = useQueryClient();
  const [statusFilter, setStatusFilter] = useState("all");
  const [viewPassengersRideId, setViewPassengersRideId] = useState<string | null>(null);
  const [settingsOpen, setSettingsOpen] = useState(false);
  const [settingsForm, setSettingsForm] = useState({ mode: "on", collectionSecs: "300" });

  const { data: statsData } = useQuery<any>({ queryKey: ["/api/admin/local-pool/stats"] });
  const stats = statsData || {};

  const { data: ridesData, isLoading } = useQuery<any>({
    queryKey: ["/api/admin/local-pool/rides", statusFilter],
    queryFn: () => apiRequest("GET", `/api/admin/local-pool/rides${statusFilter !== "all" ? `?status=${statusFilter}` : ""}`).then(r => r.json()),
  });
  const rides = ridesData?.data || [];

  const savSettings = useMutation({
    mutationFn: (d: any) => apiRequest("PATCH", "/api/admin/local-pool/settings", d),
    onSuccess: () => { toast({ title: "Settings saved" }); setSettingsOpen(false); qc.invalidateQueries({ queryKey: ["/api/admin/local-pool/stats"] }); },
    onError: (e: any) => toast({ title: "Error", description: e.message, variant: "destructive" }),
  });

  const statCards = [
    { label: "Total Rides", value: stats.totalRides ?? 0, icon: "bi-diagram-3-fill", color: "#2563eb" },
    { label: "Collecting", value: stats.collecting ?? 0, icon: "bi-hourglass-split", color: "#d97706" },
    { label: "Completed", value: stats.completed ?? 0, icon: "bi-check-circle-fill", color: "#16a34a" },
    { label: "Passengers", value: stats.totalPassengers ?? 0, icon: "bi-people-fill", color: "#7c3aed" },
    { label: "Revenue", value: `₹${Number(stats.totalRevenue || 0).toFixed(0)}`, icon: "bi-currency-rupee", color: "#0891b2" },
  ];

  return (
    <div className="container-fluid">
      <div className="mb-4 d-flex justify-content-between align-items-start flex-wrap gap-2">
        <div>
          <h2 className="fs-22 mb-1">Local Pool Rides</h2>
          <div className="fs-14 text-muted">On-demand city carpool — passengers share rides by direction matching</div>
        </div>
        <button className="btn btn-outline-primary btn-sm" onClick={() => setSettingsOpen(true)}>
          <i className="bi bi-gear me-1"></i> Pool Settings
        </button>
      </div>

      {/* Stats */}
      <div className="row g-3 mb-4">
        {statCards.map((s, i) => (
          <div key={i} className="col-6 col-md-4 col-lg-2-4" style={{ flex: "1 1 160px" }}>
            <div className="card h-100" style={{ border: `1.5px solid ${s.color}22` }}>
              <div className="card-body d-flex align-items-center gap-3 py-3">
                <div style={{ width: 42, height: 42, borderRadius: "50%", background: s.color + "18", display: "flex", alignItems: "center", justifyContent: "center", flexShrink: 0 }}>
                  <i className={`bi ${s.icon}`} style={{ fontSize: "1.2rem", color: s.color }}></i>
                </div>
                <div>
                  <div style={{ fontSize: "1.4rem", fontWeight: 700, lineHeight: 1 }}>{s.value}</div>
                  <div style={{ fontSize: "0.72rem", color: "#64748b" }}>{s.label}</div>
                </div>
              </div>
            </div>
          </div>
        ))}
      </div>

      <div className="card">
        <div className="card-body">
          <div className="d-flex flex-wrap gap-2 align-items-center mb-3">
            <h5 className="mb-0 text-primary me-2">Pool Rides</h5>
            {["all", "collecting", "dispatching", "accepted", "completed", "cancelled"].map(s => (
              <button key={s} className={`btn btn-sm ${statusFilter === s ? "btn-primary" : "btn-outline-secondary"}`}
                style={{ textTransform: "capitalize", padding: "3px 12px", fontSize: "0.78rem" }}
                onClick={() => setStatusFilter(s)}>
                {s}
              </button>
            ))}
            <button className="btn btn-sm btn-outline-primary ms-auto" onClick={() => qc.invalidateQueries({ queryKey: ["/api/admin/local-pool/rides"] })}>
              <i className="bi bi-arrow-clockwise"></i>
            </button>
          </div>

          <div className="table-responsive">
            <table className="table table-borderless align-middle table-hover" style={{ fontSize: "0.8rem" }}>
              <thead className="table-light" style={{ fontSize: "0.75rem" }}>
                <tr>
                  <th>#</th>
                  <th>Driver</th>
                  <th>Pickup</th>
                  <th>Destination</th>
                  <th>Seats</th>
                  <th>Fare/Seat</th>
                  <th>Passengers</th>
                  <th>Revenue</th>
                  <th>Status</th>
                  <th>Created</th>
                  <th></th>
                </tr>
              </thead>
              <tbody>
                {isLoading ? (
                  Array(5).fill(0).map((_, i) => (
                    <tr key={i}>{Array(11).fill(0).map((_, j) => <td key={j}><div style={{ height: 14, background: "#f1f5f9", borderRadius: 4 }} /></td>)}</tr>
                  ))
                ) : rides.length === 0 ? (
                  <tr><td colSpan={11}>
                    <div className="d-flex flex-column align-items-center gap-2 py-5">
                      <i className="bi bi-people" style={{ fontSize: "2.5rem", color: "#94a3b8" }}></i>
                      <p className="text-muted mb-0">No local pool rides found</p>
                    </div>
                  </td></tr>
                ) : rides.map((r: any, i: number) => (
                  <tr key={r.id}>
                    <td>{i + 1}</td>
                    <td>
                      <div className="fw-semibold">{r.driverName || <span className="text-muted">Unassigned</span>}</div>
                      <div className="text-muted" style={{ fontSize: "0.7rem" }}>{r.driverPhone}</div>
                    </td>
                    <td style={{ maxWidth: 140 }}><span className="text-truncate d-block" title={r.pickupAddress}>{r.pickupAddress || `${r.pickupLat}, ${r.pickupLng}`}</span></td>
                    <td style={{ maxWidth: 140 }}><span className="text-truncate d-block" title={r.destinationAddress}>{r.destinationAddress || `${r.destinationLat}, ${r.destinationLng}`}</span></td>
                    <td className="text-center">
                      <span style={{ fontWeight: 700 }}>{r.bookedSeats}</span>
                      <span className="text-muted">/{r.maxSeats}</span>
                    </td>
                    <td>₹{Number(r.farePerSeat || 0).toFixed(2)}</td>
                    <td className="text-center">
                      <span style={{ fontWeight: 700, color: "#7c3aed" }}>{r.passengerCount ?? 0}</span>
                    </td>
                    <td className="fw-semibold">₹{Number(r.totalRevenue || 0).toFixed(0)}</td>
                    <td><StatusBadge status={r.status || "collecting"} /></td>
                    <td style={{ color: "#64748b" }}>{r.createdAt ? new Date(r.createdAt).toLocaleString("en-IN", { day: "2-digit", month: "short", hour: "2-digit", minute: "2-digit" }) : "—"}</td>
                    <td>
                      <button className="btn btn-sm btn-outline-primary" onClick={() => setViewPassengersRideId(r.id)}>
                        <i className="bi bi-people me-1"></i>Passengers
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      </div>

      {/* Settings Modal */}
      {settingsOpen && (
        <div className="modal-backdrop-jago">
          <div className="modal-jago" style={{ maxWidth: 420 }}>
            <div className="modal-jago-header">
              <h5 className="modal-jago-title">Local Pool Settings</h5>
              <button className="modal-jago-close" onClick={() => setSettingsOpen(false)}><i className="bi bi-x-lg"></i></button>
            </div>
            <div className="d-flex flex-column gap-3">
              <div>
                <label className="form-label-jago">Pool Mode</label>
                <select className="form-select" value={settingsForm.mode} onChange={e => setSettingsForm(f => ({ ...f, mode: e.target.value }))}>
                  <option value="on">On (active)</option>
                  <option value="off">Off (disabled)</option>
                </select>
                <small className="text-muted">When off, customers cannot book local pool rides</small>
              </div>
              <div>
                <label className="form-label-jago">Collection Window (seconds)</label>
                <input type="number" className="form-control" value={settingsForm.collectionSecs} min="60" max="600" step="30"
                  onChange={e => setSettingsForm(f => ({ ...f, collectionSecs: e.target.value }))} />
                <small className="text-muted">How long a pool ride waits for passengers before dispatching (default: 300s = 5 min)</small>
              </div>
              <div className="d-flex gap-2 justify-content-end mt-2">
                <button className="btn btn-outline-secondary" onClick={() => setSettingsOpen(false)}>Cancel</button>
                <button className="btn btn-primary" onClick={() => savSettings.mutate(settingsForm)} disabled={savSettings.isPending}>
                  {savSettings.isPending ? "Saving..." : "Save Settings"}
                </button>
              </div>
            </div>
          </div>
        </div>
      )}

      {viewPassengersRideId && (
        <PassengersModal rideId={viewPassengersRideId} onClose={() => setViewPassengersRideId(null)} />
      )}
    </div>
  );
}
