import { useEffect, useRef, useState, useCallback } from "react";
import { useQuery } from "@tanstack/react-query";
import { queryClient } from "@/lib/queryClient";

declare global {
  interface Window { L: any; }
}

function loadScript(src: string): Promise<void> {
  return new Promise((res, rej) => {
    if (document.querySelector(`script[src="${src}"]`)) { res(); return; }
    const s = document.createElement("script");
    s.src = src; s.onload = () => res(); s.onerror = rej;
    document.head.appendChild(s);
  });
}
function loadLeafletCss() {
  if (document.querySelector('link[href*="leaflet.css"]')) return;
  const l = document.createElement("link");
  l.rel = "stylesheet"; l.href = "https://unpkg.com/leaflet@1.9.4/dist/leaflet.css";
  document.head.appendChild(l);
}

// Vehicle type → color & icon
const VEHICLE_CONFIG: Record<string, { color: string; emoji: string; label: string }> = {
  "Car":         { color: "#1a73e8", emoji: "🚗", label: "Car" },
  "Bike":        { color: "#f97316", emoji: "🏍️", label: "Bike" },
  "SUV":         { color: "#8b5cf6", emoji: "🚙", label: "SUV" },
  "Auto":        { color: "#eab308", emoji: "🛺", label: "Auto" },
  "Parcel Bike": { color: "#22c55e", emoji: "📦", label: "Parcel" },
  "default":     { color: "#64748b", emoji: "🚐", label: "Vehicle" },
};

function getVehicleConfig(type: string) {
  return VEHICLE_CONFIG[type] || VEHICLE_CONFIG["default"];
}

function createVehicleIcon(L: any, type: string, heading: number = 0) {
  const cfg = getVehicleConfig(type);
  const svg = `<div style="
    width:42px;height:42px;
    background:${cfg.color};
    border:3px solid white;
    border-radius:50%;
    display:flex;align-items:center;justify-content:center;
    font-size:18px;
    box-shadow:0 2px 8px rgba(0,0,0,0.35);
    transform:rotate(${heading}deg);
    transition:transform 0.4s ease;
  ">${cfg.emoji}</div>`;
  return L.divIcon({ html: svg, className: "", iconSize: [42, 42], iconAnchor: [21, 21], popupAnchor: [0, -22] });
}

function createEndpointIcon(L: any, type: "pickup" | "dest") {
  const color = type === "pickup" ? "#22c55e" : "#ef4444";
  const icon = type === "pickup" ? "P" : "D";
  const svg = `<div style="
    width:26px;height:26px;background:${color};border:2px solid white;
    border-radius:50%;display:flex;align-items:center;justify-content:center;
    color:white;font-weight:700;font-size:11px;
    box-shadow:0 2px 6px rgba(0,0,0,0.3);">${icon}</div>`;
  return L.divIcon({ html: svg, className: "", iconSize: [26, 26], iconAnchor: [13, 13] });
}

export default function FleetViewPage() {
  const mapRef = useRef<HTMLDivElement>(null);
  const mapInstance = useRef<any>(null);
  const vehicleLayersRef = useRef<Map<string, any>>(new Map());
  const [mapReady, setMapReady] = useState(false);
  const [selected, setSelected] = useState<any>(null);
  const [filter, setFilter] = useState<"all" | "ride" | "parcel">("all");

  const { data: trips = [], isLoading } = useQuery<any[]>({
    queryKey: ["/api/live-tracking"],
    refetchInterval: 5000, // re-fetch every 5s
  });

  // Also grab all trips for stats
  const { data: allTripsData } = useQuery<any>({ queryKey: ["/api/trips"] });

  const filteredTrips = filter === "all" ? trips : trips.filter(t => t.type === filter);

  // Init map
  useEffect(() => {
    loadLeafletCss();
    async function init() {
      await loadScript("https://unpkg.com/leaflet@1.9.4/dist/leaflet.js");
      setMapReady(true);
    }
    init();
    return () => { if (mapInstance.current) { mapInstance.current.remove(); mapInstance.current = null; } };
  }, []);

  useEffect(() => {
    if (!mapReady || !mapRef.current || mapInstance.current) return;
    const L = window.L;
    const map = L.map(mapRef.current, { center: [17.43, 78.49], zoom: 11 });
    L.tileLayer("https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png", {
      attribution: '&copy; <a href="https://www.openstreetmap.org/">OpenStreetMap</a>',
      maxZoom: 19,
    }).addTo(map);
    mapInstance.current = map;
  }, [mapReady]);

  // Update vehicle markers whenever trips change
  useEffect(() => {
    if (!mapReady || !mapInstance.current) return;
    const L = window.L;
    const map = mapInstance.current;
    const currentIds = new Set(filteredTrips.map(t => t.id));

    // Remove stale layers
    vehicleLayersRef.current.forEach((layers, id) => {
      if (!currentIds.has(id)) {
        if (layers.all) layers.all.forEach((l: any) => { try { map.removeLayer(l); } catch {} });
        vehicleLayersRef.current.delete(id);
      }
    });

    filteredTrips.forEach((trip: any) => {
      const cfg = getVehicleConfig(trip.vehicleType);
      const existingLayers = vehicleLayersRef.current.get(trip.id);

      // Calculate heading angle from previous to current position
      const heading = 45; // simplified — always NE direction

      if (existingLayers) {
        // Update existing vehicle marker position smoothly
        existingLayers.vehicle.setLatLng([trip.currentLat, trip.currentLng]);
        existingLayers.vehicle.setIcon(createVehicleIcon(L, trip.vehicleType, heading));

        // Update traveled path
        existingLayers.traveledPath.setLatLngs([
          [trip.pickupLat, trip.pickupLng],
          [trip.currentLat, trip.currentLng],
        ]);
      } else {
        // Create new layers for this trip
        const layers: any[] = [];

        // Full route dashed line
        const routeLine = L.polyline(
          [[trip.pickupLat, trip.pickupLng], [trip.destinationLat, trip.destinationLng]],
          { color: cfg.color, weight: 2, dashArray: "6 6", opacity: 0.5 }
        ).addTo(map);
        layers.push(routeLine);

        // Traveled path (solid)
        const traveledPath = L.polyline(
          [[trip.pickupLat, trip.pickupLng], [trip.currentLat, trip.currentLng]],
          { color: cfg.color, weight: 4, opacity: 0.9 }
        ).addTo(map);
        layers.push(traveledPath);

        // Pickup marker
        const pickupMarker = L.marker([trip.pickupLat, trip.pickupLng], {
          icon: createEndpointIcon(L, "pickup"),
        }).addTo(map)
          .bindTooltip(`📍 ${trip.pickupAddress}`, { direction: "top", className: "leaflet-tooltip-custom" });
        layers.push(pickupMarker);

        // Destination marker
        const destMarker = L.marker([trip.destinationLat, trip.destinationLng], {
          icon: createEndpointIcon(L, "dest"),
        }).addTo(map)
          .bindTooltip(`🏁 ${trip.destinationAddress}`, { direction: "top", className: "leaflet-tooltip-custom" });
        layers.push(destMarker);

        // Vehicle marker
        const vehicleMarker = L.marker([trip.currentLat, trip.currentLng], {
          icon: createVehicleIcon(L, trip.vehicleType, heading),
          zIndexOffset: 1000,
        }).addTo(map)
          .bindPopup(`
            <div style="min-width:200px;font-family:sans-serif">
              <div style="display:flex;align-items:center;gap:8px;margin-bottom:8px">
                <span style="font-size:22px">${cfg.emoji}</span>
                <div>
                  <div style="font-weight:700;font-size:14px">${cfg.label} · ${trip.vehicleType}</div>
                  <div style="font-size:11px;color:#64748b">${trip.refId}</div>
                </div>
              </div>
              <div style="font-size:12px;margin-bottom:4px"><b>Customer:</b> ${trip.customerName}</div>
              <div style="font-size:12px;margin-bottom:4px"><b>From:</b> ${trip.pickupAddress}</div>
              <div style="font-size:12px;margin-bottom:8px"><b>To:</b> ${trip.destinationAddress}</div>
              <div style="background:#f1f5f9;border-radius:6px;padding:6px">
                <div style="display:flex;justify-content:space-between;font-size:12px">
                  <span>Progress</span><span><b>${trip.progress}%</b></span>
                </div>
                <div style="height:5px;background:#e2e8f0;border-radius:3px;margin-top:4px">
                  <div style="height:5px;background:${cfg.color};border-radius:3px;width:${trip.progress}%"></div>
                </div>
              </div>
            </div>
          `);

        vehicleMarker.on("click", () => setSelected(trip));
        layers.push(vehicleMarker);

        vehicleLayersRef.current.set(trip.id, {
          vehicle: vehicleMarker,
          traveledPath,
          all: layers,
        });
      }
    });
  }, [mapReady, filteredTrips]);

  const focusTrip = useCallback((trip: any) => {
    setSelected(trip);
    if (mapInstance.current) {
      mapInstance.current.setView([trip.currentLat, trip.currentLng], 14, { animate: true });
      const layers = vehicleLayersRef.current.get(trip.id);
      if (layers?.vehicle) layers.vehicle.openPopup();
    }
  }, []);

  const totalOngoing = trips.length;
  const rideCount = trips.filter(t => t.type === "ride").length;
  const parcelCount = trips.filter(t => t.type === "parcel").length;
  const allTotal = allTripsData?.total || 0;

  return (
    <>
      <div className="content-header">
        <div className="container-fluid">
          <div className="d-flex align-items-center justify-content-between gap-3 flex-wrap mb-3">
            <h2 className="h5 mb-0">
              Live Vehicle Tracking
              <span className="badge bg-danger ms-2 fs-6" style={{ fontSize: "10px !important", animation: "pulse 1.5s infinite" }}>
                <i className="bi bi-broadcast me-1"></i>LIVE
              </span>
            </h2>
            <div className="d-flex align-items-center gap-2">
              <span className="text-muted small">Auto-refreshes every 5s</span>
              <button
                className="btn btn-sm btn-outline-primary"
                onClick={() => queryClient.invalidateQueries({ queryKey: ["/api/live-tracking"] })}
                data-testid="button-refresh-tracking"
              >
                <i className="bi bi-arrow-clockwise me-1"></i>Refresh
              </button>
            </div>
          </div>
        </div>
      </div>

      <div className="container-fluid">
        {/* Stats row */}
        <div className="row g-3 mb-3">
          {[
            { label: "Live Trips", val: totalOngoing, icon: "bi-broadcast", color: "#ef4444", bg: "rgba(239,68,68,0.1)" },
            { label: "Ride Trips", val: rideCount, icon: "bi-car-front-fill", color: "#1a73e8", bg: "rgba(26,115,232,0.1)" },
            { label: "Parcel Trips", val: parcelCount, icon: "bi-box-seam-fill", color: "#22c55e", bg: "rgba(34,197,94,0.1)" },
            { label: "All Trips Today", val: allTotal, icon: "bi-graph-up", color: "#8b5cf6", bg: "rgba(139,92,246,0.1)" },
          ].map((s, i) => (
            <div key={i} className="col-sm-6 col-xl-3">
              <div className="card border-0 shadow-sm">
                <div className="card-body d-flex align-items-center gap-3">
                  <div className="rounded p-2" style={{ background: s.bg }}>
                    <i className={`bi ${s.icon} fs-4`} style={{ color: s.color }}></i>
                  </div>
                  <div>
                    <div className="fw-bold fs-5" data-testid={`stat-${s.label.toLowerCase().replace(/ /g,"-")}`}>{s.val}</div>
                    <div className="text-muted small">{s.label}</div>
                  </div>
                </div>
              </div>
            </div>
          ))}
        </div>

        <div className="row g-3">
          {/* Map */}
          <div className="col-lg-8">
            <div className="card border-0 shadow-sm">
              <div className="card-header bg-white py-2 d-flex align-items-center justify-content-between">
                <h6 className="mb-0 fw-semibold">
                  <i className="bi bi-map me-2 text-primary"></i>Live Map
                </h6>
                {/* Legend */}
                <div className="d-flex gap-3 flex-wrap" style={{ fontSize: 11 }}>
                  {Object.entries(VEHICLE_CONFIG).filter(([k]) => k !== "default").map(([k, v]) => (
                    <span key={k} className="d-flex align-items-center gap-1">
                      <span style={{ fontSize: 14 }}>{v.emoji}</span>
                      <span className="text-muted">{v.label}</span>
                    </span>
                  ))}
                  <span className="d-flex align-items-center gap-1">
                    <span style={{ display: "inline-block", width: 16, height: 3, background: "#1a73e8", borderRadius: 2 }}></span>
                    <span className="text-muted">Traveled</span>
                  </span>
                  <span className="d-flex align-items-center gap-1">
                    <span style={{ display: "inline-block", width: 16, height: 2, background: "#94a3b8", borderRadius: 2, borderTop: "2px dashed #94a3b8" }}></span>
                    <span className="text-muted">Remaining</span>
                  </span>
                </div>
              </div>
              <div className="card-body p-0" style={{ position: "relative" }}>
                {isLoading && (
                  <div className="position-absolute top-0 start-0 w-100 h-100 d-flex align-items-center justify-content-center"
                    style={{ background: "rgba(255,255,255,0.7)", zIndex: 1000 }}>
                    <div className="spinner-border text-primary" role="status" />
                  </div>
                )}
                <div ref={mapRef} data-testid="div-tracking-map"
                  style={{ height: "62vh", width: "100%", borderRadius: "0 0 0 0.5rem" }} />
              </div>
            </div>
          </div>

          {/* Trip list */}
          <div className="col-lg-4">
            <div className="card border-0 shadow-sm" style={{ height: "100%" }}>
              <div className="card-header bg-white py-2">
                <ul className="nav nav--tabs p-1 rounded bg-white" style={{ gap: 4 }}>
                  {(["all", "ride", "parcel"] as const).map(f => (
                    <li className="nav-item" key={f}>
                      <button
                        className={`btn btn-sm ${filter === f ? "btn-primary" : "btn-outline-secondary"}`}
                        style={{ fontSize: 12, padding: "3px 10px" }}
                        onClick={() => setFilter(f)}
                        data-testid={`tab-${f}`}
                      >
                        {f === "all" ? `All (${trips.length})` : f === "ride" ? `Rides (${rideCount})` : `Parcels (${parcelCount})`}
                      </button>
                    </li>
                  ))}
                </ul>
              </div>
              <div className="card-body p-0" style={{ overflowY: "auto", maxHeight: "58vh" }}>
                {filteredTrips.length === 0 && (
                  <div className="text-center text-muted py-5">
                    <i className="bi bi-broadcast fs-2 d-block mb-2 text-success"></i>
                    <div className="fw-semibold">No active trips</div>
                    <div className="small">Ongoing trips will appear here</div>
                  </div>
                )}
                {filteredTrips.map((trip: any) => {
                  const cfg = getVehicleConfig(trip.vehicleType);
                  const isSelected = selected?.id === trip.id;
                  return (
                    <div
                      key={trip.id}
                      className={`p-3 border-bottom cursor-pointer ${isSelected ? "bg-light" : ""}`}
                      style={{ cursor: "pointer", borderLeft: `4px solid ${isSelected ? cfg.color : "transparent"}`, transition: "all 0.2s" }}
                      onClick={() => focusTrip(trip)}
                      data-testid={`card-trip-${trip.id}`}
                    >
                      <div className="d-flex align-items-start gap-2">
                        <span style={{ fontSize: 22, lineHeight: 1 }}>{cfg.emoji}</span>
                        <div className="flex-grow-1 min-width-0">
                          <div className="d-flex justify-content-between align-items-center">
                            <span className="fw-semibold small">{trip.refId}</span>
                            <span className="badge rounded-pill" style={{ fontSize: 10, background: cfg.color + "20", color: cfg.color }}>
                              {trip.vehicleType}
                            </span>
                          </div>
                          <div className="text-muted" style={{ fontSize: 11, marginTop: 2 }}>
                            👤 {trip.customerName}
                          </div>
                          <div className="text-muted text-truncate" style={{ fontSize: 11 }}>
                            📍 {trip.pickupAddress}
                          </div>
                          <div className="text-muted text-truncate" style={{ fontSize: 11 }}>
                            🏁 {trip.destinationAddress}
                          </div>
                          {/* Progress bar */}
                          <div className="mt-2">
                            <div className="d-flex justify-content-between" style={{ fontSize: 10, color: "#64748b" }}>
                              <span>Journey Progress</span>
                              <span className="fw-bold" style={{ color: cfg.color }}>{trip.progress}%</span>
                            </div>
                            <div className="progress mt-1" style={{ height: 5, borderRadius: 3 }}>
                              <div
                                className="progress-bar"
                                style={{ width: `${trip.progress}%`, background: cfg.color, transition: "width 1s ease" }}
                              />
                            </div>
                          </div>
                          <div className="d-flex gap-3 mt-2" style={{ fontSize: 11, color: "#64748b" }}>
                            <span>💰 ₹{parseFloat(trip.estimatedFare).toFixed(0)}</span>
                            <span>📏 {parseFloat(trip.estimatedDistance).toFixed(1)} km</span>
                            <span className="ms-auto">
                              <span className="badge rounded-pill bg-warning text-dark" style={{ fontSize: 9 }}>
                                {trip.type}
                              </span>
                            </span>
                          </div>
                        </div>
                      </div>
                    </div>
                  );
                })}
              </div>
            </div>
          </div>
        </div>
      </div>
    </>
  );
}
