
export default function HeatMapPage() {
  return (
    <>
    
      <div className="content-header">
        <div className="container-fluid">
          <div className="d-flex align-items-center justify-content-between gap-3 flex-wrap mb-3">
            <h2 className="h5 mb-0">Heat Map</h2>
          </div>
        </div>
      </div>
      <div className="container-fluid">
        <div className="card">
          <div className="card-body p-0" style={{ height: "70vh", position: "relative" }}>
            <div
              className="d-flex flex-column align-items-center justify-content-center h-100 text-muted"
              style={{ minHeight: 400 }}
            >
              <i className="bi bi-pin-map-fill" style={{ fontSize: 64, color: "#2563EB", opacity: 0.4 }}></i>
              <h5 className="mt-3">Live Heat Map</h5>
              <p className="mb-0 text-center" style={{ maxWidth: 400 }}>
                This module displays real-time driver and trip density across zones. Connect your map provider API in Business Configurations to enable this feature.
              </p>
            </div>
          </div>
        </div>
      </div>
    
    </>
  );
}
