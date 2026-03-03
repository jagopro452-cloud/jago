import { useState, useEffect } from "react";
import AdminLayout from "./layout";

interface Service {
  key: string;
  name: string;
  description: string;
  icon: string;
  emoji: string;
  color: string;
  isActive: boolean;
}

const SERVICE_ICONS: Record<string, string> = {
  ride: "bi-car-front-fill",
  parcel: "bi-box-seam-fill",
  cargo: "bi-truck-front-fill",
  intercity: "bi-signpost-2-fill",
  carsharing: "bi-people-fill",
};

const SERVICE_COLORS: Record<string, string> = {
  ride: "#1E6DE5",
  parcel: "#F59E0B",
  cargo: "#10B981",
  intercity: "#8B5CF6",
  carsharing: "#EF4444",
};

export default function ServiceManagement() {
  const [services, setServices] = useState<Service[]>([]);
  const [loading, setLoading] = useState(true);
  const [toggling, setToggling] = useState<string | null>(null);

  useEffect(() => { fetchServices(); }, []);

  const fetchServices = async () => {
    try {
      const res = await fetch("/api/services");
      if (res.ok) { const data = await res.json(); setServices(data); }
    } catch (e) { console.error(e); }
    setLoading(false);
  };

  const toggleService = async (key: string, current: boolean) => {
    setToggling(key);
    try {
      const res = await fetch(`/api/services/${key}`, {
        method: "PATCH",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ isActive: !current }),
      });
      if (res.ok) {
        setServices(prev => prev.map(s => s.key === key ? { ...s, isActive: !current } : s));
      }
    } catch (e) { console.error(e); }
    setToggling(null);
  };

  return (
    <AdminLayout>
      <div className="p-4 p-md-6">
        <div className="d-flex align-items-center justify-content-between mb-4">
          <div>
            <h2 className="fw-bold mb-1">Service Management</h2>
            <p className="text-muted mb-0">Enable or disable business services visible to customers</p>
          </div>
          <span className="badge bg-success fs-6">
            {services.filter(s => s.isActive).length}/{services.length} Active
          </span>
        </div>

        {loading ? (
          <div className="text-center py-5"><div className="spinner-border text-primary" /></div>
        ) : (
          <>
            <div className="alert alert-info d-flex align-items-center gap-2 mb-4">
              <i className="bi bi-info-circle-fill"></i>
              <div>
                <strong>How it works:</strong> Toggling a service OFF will show it as &ldquo;Coming Soon&rdquo; in the customer app.
                Customers cannot book that service until it is re-enabled.
              </div>
            </div>

            <div className="row g-3">
              {services.map((svc) => {
                const color = SERVICE_COLORS[svc.key] || "#6366f1";
                const icon = SERVICE_ICONS[svc.key] || "bi-grid-fill";
                return (
                  <div className="col-md-6" key={svc.key}>
                    <div className={`card border-0 shadow-sm h-100 ${svc.isActive ? "" : "opacity-75"}`}
                      style={{ borderLeft: `4px solid ${color}` }}>
                      <div className="card-body d-flex align-items-center gap-3">
                        <div className="rounded-3 d-flex align-items-center justify-content-center flex-shrink-0"
                          style={{ width: 56, height: 56, background: `${color}18` }}>
                          <span style={{ fontSize: 28 }}>{svc.emoji}</span>
                        </div>
                        <div className="flex-grow-1">
                          <div className="d-flex align-items-center gap-2">
                            <h5 className="fw-bold mb-0">{svc.name}</h5>
                            <span className={`badge ${svc.isActive ? "bg-success" : "bg-secondary"}`}>
                              {svc.isActive ? "Active" : "Disabled"}
                            </span>
                          </div>
                          <p className="text-muted small mb-0 mt-1">{svc.description}</p>
                        </div>
                        <div className="form-check form-switch ms-2">
                          <input
                            className="form-check-input"
                            type="checkbox"
                            role="switch"
                            style={{ width: 48, height: 24, cursor: "pointer" }}
                            checked={svc.isActive}
                            disabled={toggling === svc.key}
                            onChange={() => toggleService(svc.key, svc.isActive)}
                          />
                        </div>
                      </div>
                      {!svc.isActive && (
                        <div className="card-footer bg-warning-subtle text-warning-emphasis small fw-semibold border-0 py-2">
                          <i className="bi bi-clock me-1"></i>
                          Customers see &ldquo;Coming Soon&rdquo; for this service
                        </div>
                      )}
                    </div>
                  </div>
                );
              })}
            </div>

            <div className="card mt-4 border-0 bg-light">
              <div className="card-body">
                <h6 className="fw-bold"><i className="bi bi-gear-fill me-2"></i>Service Types Explained</h6>
                <div className="row g-3 mt-1">
                  {[
                    { key: "ride", vehicles: "Bike, Auto, Car, SUV, Temo Auto" },
                    { key: "parcel", vehicles: "Bike Parcel, Mini Auto (parcel)" },
                    { key: "cargo", vehicles: "Cargo Truck, Mini Cargo Van, Tata Ace" },
                    { key: "intercity", vehicles: "All vehicles on long-distance routes" },
                    { key: "carsharing", vehicles: "Shared car rides between locations" },
                  ].map(item => {
                    const svc = services.find(s => s.key === item.key);
                    if (!svc) return null;
                    return (
                      <div className="col-md-6 col-lg-4" key={item.key}>
                        <div className="d-flex align-items-start gap-2">
                          <span style={{ fontSize: 20 }}>{svc.emoji}</span>
                          <div>
                            <div className="fw-semibold small">{svc.name}</div>
                            <div className="text-muted" style={{ fontSize: 11 }}>{item.vehicles}</div>
                          </div>
                        </div>
                      </div>
                    );
                  })}
                </div>
              </div>
            </div>
          </>
        )}
      </div>
    </AdminLayout>
  );
}
