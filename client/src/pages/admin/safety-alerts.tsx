import { useState } from "react";

export default function SafetyAlertsPage() {
  const [filter, setFilter] = useState("customer");

  return (
    <>
    
      <div className="content-header">
        <div className="container-fluid">
          <div className="d-flex align-items-center justify-content-between gap-3 flex-wrap mb-3">
            <h2 className="h5 mb-0">Solved Alert List</h2>
          </div>
        </div>
      </div>
      <div className="container-fluid">
        <div className="card">
          <div className="card-header border-bottom py-3">
            <ul className="nav nav--tabs p-1 rounded bg-white">
              {["customer", "driver"].map(t => (
                <li key={t} className="nav-item">
                  <button
                    className={`nav-link text-capitalize${filter === t ? " active" : ""}`}
                    onClick={() => setFilter(t)}
                    data-testid={`tab-${t}`}
                  >
                    {t}
                  </button>
                </li>
              ))}
            </ul>
          </div>
          <div className="card-body">
            <div className="table-responsive">
              <table className="table table-borderless align-middle table-hover">
                <thead className="table-light">
                  <tr>
                    <th>#</th>
                    <th>User</th>
                    <th>Trip Ref</th>
                    <th>Alert Type</th>
                    <th>Resolved At</th>
                    <th>Status</th>
                  </tr>
                </thead>
                <tbody>
                  <tr>
                    <td colSpan={6} className="text-center py-5 text-muted">
                      <i className="bi bi-shield-fill-check fs-2 d-block mb-2 opacity-25"></i>
                      No solved alerts found
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>
          </div>
        </div>
      </div>
    
    </>
  );
}
