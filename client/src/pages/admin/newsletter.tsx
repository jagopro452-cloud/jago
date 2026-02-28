import { useQuery } from "@tanstack/react-query";

export default function NewsletterPage() {
  const { data, isLoading } = useQuery<any[]>({ queryKey: ["/api/newsletter"] });
  const subscribers = Array.isArray(data) ? data : [];

  return (
    <>
    
      <div className="content-header">
        <div className="container-fluid">
          <div className="d-flex align-items-center justify-content-between gap-3 flex-wrap mb-3">
            <h2 className="h5 mb-0">Newsletter Subscribers</h2>
            <span className="badge bg-primary fs-6">{subscribers.length} Subscribers</span>
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
                    <th>Email</th>
                    <th>Subscribed At</th>
                    <th>Status</th>
                  </tr>
                </thead>
                <tbody>
                  {isLoading ? (
                    <tr><td colSpan={4} className="text-center py-4"><div className="spinner-border spinner-border-sm" role="status" /></td></tr>
                  ) : subscribers.length === 0 ? (
                    <tr>
                      <td colSpan={4} className="text-center py-5 text-muted">
                        <i className="bi bi-envelope-fill fs-2 d-block mb-2 opacity-25"></i>
                        No newsletter subscribers yet
                      </td>
                    </tr>
                  ) : subscribers.map((s: any, idx: number) => (
                    <tr key={s.id}>
                      <td>{idx + 1}</td>
                      <td>{s.email}</td>
                      <td>{s.createdAt ? new Date(s.createdAt).toLocaleDateString() : "—"}</td>
                      <td><span className="badge bg-success">Active</span></td>
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
