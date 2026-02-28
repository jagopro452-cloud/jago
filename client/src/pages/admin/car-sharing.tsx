import { useQuery } from "@tanstack/react-query";

export default function CarSharingPage() {
  const { data, isLoading } = useQuery<any>({ queryKey: ["/api/trips"], enabled: true });
  const carShares = Array.isArray(data?.data) ? data.data.filter((t: any) => t.type === "car_sharing") : [];

  return (
    <>
    
      <div className="content-header">
        <div className="container-fluid">
          <div className="d-flex align-items-center justify-content-between gap-3 flex-wrap mb-3">
            <h2 className="h5 mb-0">Car Sharing</h2>
          </div>
        </div>
      </div>
      <div className="container-fluid">
        <div className="card">
          <div className="card-body">
            <div className="table-responsive">
              <table className="table table-borderless align-middle table-hover">
                <thead className="table-light">
                  <tr>
                    <th>#</th>
                    <th>Ref ID</th>
                    <th>Customer</th>
                    <th>Pickup</th>
                    <th>Destination</th>
                    <th>Fare</th>
                    <th>Status</th>
                  </tr>
                </thead>
                <tbody>
                  {isLoading ? (
                    <tr><td colSpan={7} className="text-center py-4"><div className="spinner-border spinner-border-sm" role="status" /></td></tr>
                  ) : carShares.length === 0 ? (
                    <tr>
                      <td colSpan={7} className="text-center py-5 text-muted">
                        <i className="bi bi-people-fill fs-2 d-block mb-2 opacity-25"></i>
                        No car sharing trips found
                      </td>
                    </tr>
                  ) : carShares.map((t: any, idx: number) => (
                    <tr key={t.id}>
                      <td>{idx + 1}</td>
                      <td className="text-primary fw-semibold">{t.refId}</td>
                      <td>{t.customerName || "—"}</td>
                      <td>{t.pickupAddress || "—"}</td>
                      <td>{t.destinationAddress || "—"}</td>
                      <td>₹{parseFloat(t.estimatedFare || 0).toFixed(2)}</td>
                      <td><span className="badge bg-info text-dark">{t.currentStatus}</span></td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        </div>
      </div>
    
    </>
  );
}
