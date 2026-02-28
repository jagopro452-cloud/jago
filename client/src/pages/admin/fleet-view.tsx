import { useEffect, useRef, useState } from "react";
import { useQuery } from "@tanstack/react-query";

declare global {
  interface Window {
    L: any;
  }
}

function loadScript(src: string): Promise<void> {
  return new Promise((resolve, reject) => {
    if (document.querySelector(`script[src="${src}"]`)) { resolve(); return; }
    const s = document.createElement("script");
    s.src = src;
    s.onload = () => resolve();
    s.onerror = reject;
    document.head.appendChild(s);
  });
}

function loadLeafletCss() {
  if (document.querySelector('link[href*="leaflet.css"]')) return;
  const link = document.createElement("link");
  link.rel = "stylesheet";
  link.href = "https://unpkg.com/leaflet@1.9.4/dist/leaflet.css";
  document.head.appendChild(link);
}

function createDriverIcon(L: any, status: string) {
  const color = status === "active" ? "#22c55e" : "#94a3b8";
  const svg = `<svg xmlns="http://www.w3.org/2000/svg" width="36" height="44" viewBox="0 0 36 44">
    <circle cx="18" cy="16" r="14" fill="${color}" stroke="white" stroke-width="3"/>
    <path d="M18 32 L10 44 L18 40 L26 44 Z" fill="${color}"/>
    <text x="18" y="21" text-anchor="middle" fill="white" font-size="14" font-family="Arial">🚗</text>
  </svg>`;
  return L.divIcon({
    html: `<div style="width:36px;height:44px">${svg}</div>`,
    className: "",
    iconSize: [36, 44],
    iconAnchor: [18, 44],
    popupAnchor: [0, -44],
  });
}

export default function FleetViewPage() {
  const mapRef = useRef<HTMLDivElement>(null);
  const mapInstance = useRef<any>(null);
  const markersRef = useRef<any[]>([]);
  const [mapReady, setMapReady] = useState(false);
  const [selectedDriver, setSelectedDriver] = useState<any>(null);
  const [statusFilter, setStatusFilter] = useState<"all" | "active" | "inactive">("all");

  const { data: drivers = [], isLoading } = useQuery<any[]>({
    queryKey: ["/api/fleet-drivers"],
    refetchInterval: 30000,
  });

  useEffect(() => {
    loadLeafletCss();
    async function init() {
      await loadScript("https://unpkg.com/leaflet@1.9.4/dist/leaflet.js");
      setMapReady(true);
    }
    init();
    return () => {
      if (mapInstance.current) {
        mapInstance.current.remove();
        mapInstance.current = null;
      }
    };
  }, []);

  useEffect(() => {
    if (!mapReady || !mapRef.current || mapInstance.current) return;
    const L = window.L;
    const map = L.map(mapRef.current, { center: [17.385, 78.486], zoom: 11 });
    L.tileLayer("https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png", {
      attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>',
      maxZoom: 19,
    }).addTo(map);
    mapInstance.current = map;
  }, [mapReady]);

  useEffect(() => {
    if (!mapReady || !mapInstance.current || !drivers.length) return;
    const L = window.L;
    markersRef.current.forEach(m => mapInstance.current.removeLayer(m));
    markersRef.current = [];

    const filtered = statusFilter === "all" ? drivers : drivers.filter(d => d.status === statusFilter);

    filtered.forEach((driver: any) => {
      const marker = L.marker([driver.lat, driver.lng], { icon: createDriverIcon(L, driver.status) })
        .addTo(mapInstance.current)
        .bindPopup(`
          <div style="min-width:160px;font-family:sans-serif">
            <div style="font-weight:600;margin-bottom:4px">${driver.name}</div>
            <div style="font-size:12px;color:#64748b">${driver.phone || "N/A"}</div>
            <div style="margin-top:6px">
              <span style="background:${driver.status === "active" ? "#dcfce7" : "#f1f5f9"};color:${driver.status === "active" ? "#16a34a" : "#475569"};padding:2px 8px;border-radius:99px;font-size:11px;font-weight:600">${driver.status}</span>
            </div>
          </div>
        `);
      marker.on("click", () => setSelectedDriver(driver));
      markersRef.current.push(marker);
    });
  }, [mapReady, drivers, statusFilter]);

  const filtered = statusFilter === "all" ? drivers : drivers.filter(d => d.status === statusFilter);
  const activeCount = drivers.filter(d => d.status === "active").length;
  const inactiveCount = drivers.filter(d => d.status === "inactive").length;

  return (
    <>
      <div className="content-header">
        <div className="container-fluid">
          <div className="d-flex align-items-center justify-content-between gap-3 flex-wrap mb-3">
            <h2 className="h5 mb-0">Fleet View</h2>
            <div className="d-flex gap-2">
              <select
                className="form-select form-select-sm"
                style={{ width: "auto" }}
                value={statusFilter}
                onChange={e => setStatusFilter(e.target.value as any)}
                data-testid="select-fleet-filter"
              >
                <option value="all">All Drivers ({drivers.length})</option>
                <option value="active">Active ({activeCount})</option>
                <option value="inactive">Inactive ({inactiveCount})</option>
              </select>
            </div>
          </div>
        </div>
      </div>

      <div className="container-fluid">
        <div className="row g-3 mb-3">
          <div className="col-sm-4">
            <div className="card border-0 shadow-sm">
              <div className="card-body d-flex align-items-center gap-3">
                <div className="rounded p-2" style={{ background: "rgba(34,197,94,0.12)" }}>
                  <i className="bi bi-person-check-fill fs-4" style={{ color: "#22c55e" }}></i>
                </div>
                <div>
                  <div className="fw-semibold" data-testid="text-active-drivers">{activeCount}</div>
                  <div className="text-muted small">Active Drivers</div>
                </div>
              </div>
            </div>
          </div>
          <div className="col-sm-4">
            <div className="card border-0 shadow-sm">
              <div className="card-body d-flex align-items-center gap-3">
                <div className="rounded p-2" style={{ background: "rgba(148,163,184,0.15)" }}>
                  <i className="bi bi-person-dash-fill fs-4" style={{ color: "#94a3b8" }}></i>
                </div>
                <div>
                  <div className="fw-semibold" data-testid="text-inactive-drivers">{inactiveCount}</div>
                  <div className="text-muted small">Inactive Drivers</div>
                </div>
              </div>
            </div>
          </div>
          <div className="col-sm-4">
            <div className="card border-0 shadow-sm">
              <div className="card-body d-flex align-items-center gap-3">
                <div className="rounded p-2" style={{ background: "rgba(26,115,232,0.12)" }}>
                  <i className="bi bi-car-front-fill fs-4" style={{ color: "#1a73e8" }}></i>
                </div>
                <div>
                  <div className="fw-semibold" data-testid="text-total-drivers">{drivers.length}</div>
                  <div className="text-muted small">Total Fleet</div>
                </div>
              </div>
            </div>
          </div>
        </div>

        <div className="row g-3">
          <div className="col-lg-8">
            <div className="card border-0 shadow-sm h-100">
              <div className="card-header bg-white py-3">
                <h6 className="mb-0 fw-semibold">
                  <i className="bi bi-map me-2 text-primary"></i>Live Fleet Map
                  <span className="badge bg-success ms-2" style={{ fontSize: 10 }}>LIVE</span>
                </h6>
              </div>
              <div className="card-body p-0" style={{ position: "relative" }}>
                {isLoading && (
                  <div className="position-absolute top-0 start-0 w-100 h-100 d-flex align-items-center justify-content-center"
                    style={{ background: "rgba(255,255,255,0.8)", zIndex: 1000 }}>
                    <div className="spinner-border text-primary" role="status" />
                  </div>
                )}
                <div
                  ref={mapRef}
                  data-testid="div-fleetmap"
                  style={{ height: "60vh", width: "100%", borderRadius: "0 0 0.5rem 0" }}
                />
              </div>
            </div>
          </div>

          <div className="col-lg-4">
            <div className="card border-0 shadow-sm h-100">
              <div className="card-header bg-white py-3 d-flex align-items-center justify-content-between">
                <h6 className="mb-0 fw-semibold">Driver List</h6>
                <span className="badge bg-primary rounded-pill">{filtered.length}</span>
              </div>
              <div className="card-body p-0" style={{ overflowY: "auto", maxHeight: "60vh" }}>
                {filtered.length === 0 && (
                  <div className="text-center text-muted py-5">
                    <i className="bi bi-people fs-2 d-block mb-2"></i>No drivers found
                  </div>
                )}
                {filtered.map((driver: any) => (
                  <div
                    key={driver.id}
                    className={`d-flex align-items-center gap-3 px-3 py-2 border-bottom cursor-pointer ${selectedDriver?.id === driver.id ? "bg-light" : ""}`}
                    style={{ cursor: "pointer" }}
                    data-testid={`row-driver-${driver.id}`}
                    onClick={() => {
                      setSelectedDriver(driver);
                      if (mapInstance.current) {
                        mapInstance.current.setView([driver.lat, driver.lng], 14);
                      }
                    }}
                  >
                    <div
                      className="rounded-circle d-flex align-items-center justify-content-center flex-shrink-0 text-white fw-semibold"
                      style={{ width: 38, height: 38, background: driver.status === "active" ? "#22c55e" : "#94a3b8", fontSize: 14 }}
                    >
                      {driver.name?.charAt(0) || "D"}
                    </div>
                    <div className="flex-grow-1 min-width-0">
                      <div className="fw-semibold text-truncate small">{driver.name}</div>
                      <div className="text-muted" style={{ fontSize: 11 }}>{driver.phone || "N/A"}</div>
                    </div>
                    <span
                      className="badge rounded-pill"
                      style={{
                        fontSize: 10,
                        background: driver.status === "active" ? "#dcfce7" : "#f1f5f9",
                        color: driver.status === "active" ? "#16a34a" : "#475569",
                      }}
                    >
                      {driver.status}
                    </span>
                  </div>
                ))}
              </div>
            </div>
          </div>
        </div>
      </div>
    </>
  );
}
