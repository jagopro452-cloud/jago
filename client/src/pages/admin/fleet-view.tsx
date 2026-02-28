
export default function FleetViewPage() {
  return (
    <>
    
      <div className="content-header">
        <div className="container-fluid">
          <div className="d-flex align-items-center justify-content-between gap-3 flex-wrap mb-3">
            <h2 className="h5 mb-0">Fleet View</h2>
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
              <i className="bi bi-map-fill" style={{ fontSize: 64, color: "#2563EB", opacity: 0.4 }}></i>
              <h5 className="mt-3">Live Fleet View</h5>
              <p className="mb-0 text-center" style={{ maxWidth: 400 }}>
                Track all drivers on the map in real-time. Connect your map provider API in Business Configurations to enable live fleet tracking.
              </p>
            </div>
          </div>
        </div>
      </div>
    
    </>
  );
}
