import { useEffect, useRef, useState } from "react";
import { useQuery } from "@tanstack/react-query";

declare global { interface Window { L: any; } }

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

const TILES: Record<string, { url: string; label: string }> = {
  dark:    { url: "https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png",    label: "🌙 Dark" },
  voyager: { url: "https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png", label: "🗺️ Voyager" },
  light:   { url: "https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png",   label: "☀️ Light" },
};

const HEAT_PRESETS: Record<string, { radius: number; blur: number; gradient: Record<string, string>; label: string }> = {
  hot:    { radius: 35, blur: 25, gradient: { 0.2: "#3b82f6", 0.4: "#06b6d4", 0.6: "#22c55e", 0.8: "#f59e0b", 1.0: "#ef4444" }, label: "🔥 Hot Zones" },
  cool:   { radius: 30, blur: 20, gradient: { 0.2: "#06b6d4", 0.5: "#3b82f6", 0.8: "#8b5cf6", 1.0: "#ec4899" }, label: "❄️ Cool Blue" },
  dense:  { radius: 45, blur: 35, gradient: { 0.1: "#fef08a", 0.4: "#fbbf24", 0.7: "#f97316", 1.0: "#b91c1c" }, label: "🌋 Dense" },
};

export default function HeatMapPage() {
  const mapRef = useRef<HTMLDivElement>(null);
  const mapInstance = useRef<any>(null);
  const heatRef = useRef<any>(null);
  const tileRef = useRef<any>(null);
  const [mapReady, setMapReady] = useState(false);
  const [tileStyle, setTileStyle] = useState<keyof typeof TILES>("dark");
  const [heatPreset, setHeatPreset] = useState<keyof typeof HEAT_PRESETS>("hot");
  const [zoom, setZoom] = useState(11);

  const { data: points = [], isLoading } = useQuery<any[]>({
    queryKey: ["/api/heatmap-points"],
    refetchInterval: 30000,
  });

  useEffect(() => {
    loadLeafletCss();
    async function init() {
      await loadScript("https://unpkg.com/leaflet@1.9.4/dist/leaflet.js");
      await loadScript("https://unpkg.com/leaflet.heat@0.2.0/dist/leaflet-heat.js");
      setMapReady(true);
    }
    init();
    return () => { if (mapInstance.current) { mapInstance.current.remove(); mapInstance.current = null; } };
  }, []);

  useEffect(() => {
    if (!mapReady || !mapRef.current || mapInstance.current) return;
    const L = window.L;
    const map = L.map(mapRef.current, { center: [17.43, 78.49], zoom: 11, zoomControl: false });
    L.control.zoom({ position: "bottomright" }).addTo(map);
    const t = TILES[tileStyle];
    tileRef.current = L.tileLayer(t.url, { attribution: '&copy; CARTO', maxZoom: 19, subdomains: "abcd" }).addTo(map);
    map.on("zoomend", () => setZoom(map.getZoom()));
    mapInstance.current = map;
  }, [mapReady]);

  // Rebuild heat layer when points or preset changes
  useEffect(() => {
    if (!mapReady || !mapInstance.current || !points.length) return;
    const L = window.L;
    if (heatRef.current) { mapInstance.current.removeLayer(heatRef.current); }
    const preset = HEAT_PRESETS[heatPreset];
    const latlngs = points
      .filter((p: any) => p.lat && p.lng)
      .map((p: any) => [parseFloat(p.lat), parseFloat(p.lng), parseFloat(p.intensity) || 1]);
    heatRef.current = L.heatLayer(latlngs, {
      radius: preset.radius,
      blur: preset.blur,
      maxZoom: zoom,
      gradient: preset.gradient,
    }).addTo(mapInstance.current);
  }, [mapReady, points, heatPreset, zoom]);

  // Switch tile layer
  const switchTile = (style: keyof typeof TILES) => {
    setTileStyle(style);
    if (mapInstance.current && tileRef.current) {
      mapInstance.current.removeLayer(tileRef.current);
      const L = window.L;
      tileRef.current = L.tileLayer(TILES[style].url, {
        attribution: '&copy; CARTO', maxZoom: 19, subdomains: "abcd"
      }).addTo(mapInstance.current);
    }
  };

  const pickupCount = Math.floor(points.length / 2);
  const dropCount = points.length - pickupCount;

  const legendColors = Object.entries(HEAT_PRESETS[heatPreset].gradient);

  return (
    <>
      <div className="content-header">
        <div className="container-fluid">
          <div className="d-flex align-items-center justify-content-between gap-3 flex-wrap mb-3">
            <h2 className="h5 mb-0 fw-bold">
              <i className="bi bi-fire text-danger me-2"></i>Trip Heat Map
            </h2>
            <div className="d-flex gap-2 align-items-center flex-wrap">
              {/* Heat style */}
              <div className="btn-group btn-group-sm">
                {Object.entries(HEAT_PRESETS).map(([k, v]) => (
                  <button key={k}
                    className={`btn ${heatPreset === k ? "btn-danger" : "btn-outline-secondary"}`}
                    style={{ fontSize: 11 }}
                    onClick={() => setHeatPreset(k as keyof typeof HEAT_PRESETS)}
                    data-testid={`btn-preset-${k}`}
                  >{v.label}</button>
                ))}
              </div>
              {/* Tile style */}
              <div className="btn-group btn-group-sm">
                {Object.entries(TILES).map(([k, v]) => (
                  <button key={k}
                    className={`btn ${tileStyle === k ? "btn-dark" : "btn-outline-secondary"}`}
                    style={{ fontSize: 11 }}
                    onClick={() => switchTile(k as keyof typeof TILES)}
                    data-testid={`btn-tile-${k}`}
                  >{v.label}</button>
                ))}
              </div>
            </div>
          </div>
        </div>
      </div>

      <div className="container-fluid">
        {/* Stats */}
        <div className="row g-3 mb-3">
          {[
            { label: "Total Data Points", val: points.length, icon: "bi-geo-alt-fill", color: "#ef4444", gradient: "linear-gradient(135deg,#ef444412,#fca5a512)" },
            { label: "Pickup Locations", val: pickupCount, icon: "bi-box-arrow-in-down-right", color: "#3b82f6", gradient: "linear-gradient(135deg,#3b82f612,#93c5fd12)" },
            { label: "Drop Locations", val: dropCount, icon: "bi-box-arrow-up-right", color: "#22c55e", gradient: "linear-gradient(135deg,#22c55e12,#86efac12)" },
            { label: "Map Zoom", val: `${zoom}x`, icon: "bi-zoom-in", color: "#8b5cf6", gradient: "linear-gradient(135deg,#8b5cf612,#c4b5fd12)" },
          ].map((s, i) => (
            <div key={i} className="col-sm-6 col-xl-3">
              <div className="card border-0 shadow-sm" style={{ borderRadius: 12 }}>
                <div className="card-body d-flex align-items-center gap-3 py-3">
                  <div className="rounded-3 d-flex align-items-center justify-content-center flex-shrink-0"
                    style={{ width: 46, height: 46, background: s.gradient }}>
                    <i className={`bi ${s.icon} fs-5`} style={{ color: s.color }}></i>
                  </div>
                  <div>
                    <div className="fw-bold fs-4 lh-1" style={{ color: s.color }}>{s.val}</div>
                    <div className="text-muted small mt-1">{s.label}</div>
                  </div>
                </div>
              </div>
            </div>
          ))}
        </div>

        <div className="card border-0 shadow-sm" style={{ borderRadius: 16, overflow: "hidden" }}>
          <div className="card-header bg-white py-2 px-3 d-flex align-items-center justify-content-between"
            style={{ borderBottom: "1px solid #f1f5f9" }}>
            <h6 className="mb-0 fw-semibold">
              <i className="bi bi-map me-2 text-primary"></i>Trip Density Heatmap
            </h6>
            {/* Gradient legend */}
            <div className="d-flex align-items-center gap-2" style={{ fontSize: 11 }}>
              <span className="text-muted">Low</span>
              <div style={{
                width: 120, height: 8, borderRadius: 4,
                background: `linear-gradient(to right, ${legendColors.map(([, c]) => c).join(", ")})`,
                boxShadow: "0 1px 4px rgba(0,0,0,0.1)"
              }} />
              <span className="text-muted">High</span>
            </div>
          </div>

          <div style={{ position: "relative" }}>
            {isLoading && (
              <div className="position-absolute top-0 start-0 w-100 h-100 d-flex flex-column align-items-center justify-content-center"
                style={{ background: "rgba(10,15,30,0.7)", zIndex: 1000, backdropFilter: "blur(4px)" }}>
                <div className="spinner-border text-danger mb-2" role="status" />
                <div style={{ color: "white", fontSize: 13 }}>Loading heat data…</div>
              </div>
            )}
            <div ref={mapRef} data-testid="div-heatmap"
              style={{ height: "66vh", width: "100%" }} />

            {/* Floating info overlay */}
            {!isLoading && points.length > 0 && (
              <div style={{
                position: "absolute", bottom: 40, left: 16, zIndex: 500,
                background: "rgba(15,23,42,0.85)", backdropFilter: "blur(8px)",
                borderRadius: 12, padding: "10px 16px", color: "white",
                boxShadow: "0 4px 20px rgba(0,0,0,0.3)", border: "1px solid rgba(255,255,255,0.1)"
              }}>
                <div style={{ fontSize: 13, fontWeight: 700, marginBottom: 4 }}>📊 Density Summary</div>
                <div style={{ fontSize: 11, color: "#94a3b8" }}>{points.length} data points plotted</div>
                <div style={{ fontSize: 11, color: "#94a3b8" }}>Hyderabad region</div>
              </div>
            )}
          </div>
        </div>
      </div>
    </>
  );
}
