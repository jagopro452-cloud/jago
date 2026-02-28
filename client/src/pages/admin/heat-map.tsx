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

export default function HeatMapPage() {
  const mapRef = useRef<HTMLDivElement>(null);
  const mapInstance = useRef<any>(null);
  const heatLayer = useRef<any>(null);
  const [mapReady, setMapReady] = useState(false);
  const [filter, setFilter] = useState<"all" | "pickup" | "destination">("all");

  const { data: points = [], isLoading } = useQuery<any[]>({
    queryKey: ["/api/heatmap-points"],
  });

  useEffect(() => {
    loadLeafletCss();
    async function init() {
      await loadScript("https://unpkg.com/leaflet@1.9.4/dist/leaflet.js");
      await loadScript("https://unpkg.com/leaflet.heat@0.2.0/dist/leaflet-heat.js");
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
    const map = L.map(mapRef.current, {
      center: [17.385, 78.486],
      zoom: 11,
    });
    L.tileLayer("https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png", {
      attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>',
      maxZoom: 19,
    }).addTo(map);
    mapInstance.current = map;
  }, [mapReady]);

  useEffect(() => {
    if (!mapReady || !mapInstance.current || !points.length) return;
    const L = window.L;
    if (heatLayer.current) {
      mapInstance.current.removeLayer(heatLayer.current);
    }
    const latlngs = points
      .filter((p: any) => p.lat && p.lng)
      .map((p: any) => [parseFloat(p.lat), parseFloat(p.lng), parseFloat(p.intensity) || 1]);
    heatLayer.current = L.heatLayer(latlngs, {
      radius: 35,
      blur: 25,
      maxZoom: 13,
      gradient: { 0.2: "#1a73e8", 0.4: "#34a853", 0.6: "#fbbc04", 0.8: "#ea4335", 1.0: "#c62828" },
    }).addTo(mapInstance.current);
  }, [mapReady, points]);

  return (
    <>
      <div className="content-header">
        <div className="container-fluid">
          <div className="d-flex align-items-center justify-content-between gap-3 flex-wrap mb-3">
            <h2 className="h5 mb-0">Heat Map</h2>
            <div className="d-flex gap-2 align-items-center">
              <span className="text-muted small">
                <i className="bi bi-geo-alt-fill text-danger me-1"></i>
                {points.length} data points
              </span>
              <select
                className="form-select form-select-sm"
                style={{ width: "auto" }}
                value={filter}
                onChange={(e) => setFilter(e.target.value as any)}
                data-testid="select-heatmap-filter"
              >
                <option value="all">All Points</option>
                <option value="pickup">Pickup Only</option>
                <option value="destination">Destination Only</option>
              </select>
            </div>
          </div>
        </div>
      </div>

      <div className="container-fluid">
        <div className="row g-3 mb-3">
          <div className="col-sm-6 col-xl-3">
            <div className="card border-0 shadow-sm">
              <div className="card-body d-flex align-items-center gap-3">
                <div className="rounded p-2" style={{ background: "rgba(234,67,53,0.12)" }}>
                  <i className="bi bi-fire fs-4" style={{ color: "#ea4335" }}></i>
                </div>
                <div>
                  <div className="fw-semibold">{points.length}</div>
                  <div className="text-muted small">Total Points</div>
                </div>
              </div>
            </div>
          </div>
          <div className="col-sm-6 col-xl-3">
            <div className="card border-0 shadow-sm">
              <div className="card-body d-flex align-items-center gap-3">
                <div className="rounded p-2" style={{ background: "rgba(26,115,232,0.12)" }}>
                  <i className="bi bi-geo-alt-fill fs-4" style={{ color: "#1a73e8" }}></i>
                </div>
                <div>
                  <div className="fw-semibold">{Math.floor(points.length / 2)}</div>
                  <div className="text-muted small">Pickup Points</div>
                </div>
              </div>
            </div>
          </div>
          <div className="col-sm-6 col-xl-3">
            <div className="card border-0 shadow-sm">
              <div className="card-body d-flex align-items-center gap-3">
                <div className="rounded p-2" style={{ background: "rgba(52,168,83,0.12)" }}>
                  <i className="bi bi-flag-fill fs-4" style={{ color: "#34a853" }}></i>
                </div>
                <div>
                  <div className="fw-semibold">{points.length - Math.floor(points.length / 2)}</div>
                  <div className="text-muted small">Drop Points</div>
                </div>
              </div>
            </div>
          </div>
          <div className="col-sm-6 col-xl-3">
            <div className="card border-0 shadow-sm">
              <div className="card-body d-flex align-items-center gap-3">
                <div className="rounded p-2" style={{ background: "rgba(251,188,4,0.15)" }}>
                  <i className="bi bi-activity fs-4" style={{ color: "#fbbc04" }}></i>
                </div>
                <div>
                  <div className="fw-semibold">Live</div>
                  <div className="text-muted small">Map Status</div>
                </div>
              </div>
            </div>
          </div>
        </div>

        <div className="card border-0 shadow-sm">
          <div className="card-header bg-white d-flex align-items-center justify-content-between py-3">
            <h6 className="mb-0 fw-semibold">
              <i className="bi bi-map me-2 text-primary"></i>Trip Density Heat Map
            </h6>
            <div className="d-flex align-items-center gap-3 small text-muted">
              <span><span className="d-inline-block rounded-circle me-1" style={{ width: 10, height: 10, background: "#1a73e8" }}></span>Low</span>
              <span><span className="d-inline-block rounded-circle me-1" style={{ width: 10, height: 10, background: "#34a853" }}></span>Medium</span>
              <span><span className="d-inline-block rounded-circle me-1" style={{ width: 10, height: 10, background: "#fbbc04" }}></span>High</span>
              <span><span className="d-inline-block rounded-circle me-1" style={{ width: 10, height: 10, background: "#ea4335" }}></span>Very High</span>
            </div>
          </div>
          <div className="card-body p-0" style={{ position: "relative" }}>
            {isLoading && (
              <div className="position-absolute top-0 start-0 w-100 h-100 d-flex align-items-center justify-content-center"
                style={{ background: "rgba(255,255,255,0.7)", zIndex: 1000 }}>
                <div className="spinner-border text-primary" role="status">
                  <span className="visually-hidden">Loading...</span>
                </div>
              </div>
            )}
            <div
              ref={mapRef}
              data-testid="div-heatmap"
              style={{ height: "65vh", width: "100%", borderRadius: "0 0 0.5rem 0.5rem" }}
            />
          </div>
        </div>
      </div>
    </>
  );
}
