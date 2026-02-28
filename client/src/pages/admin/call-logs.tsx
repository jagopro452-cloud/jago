import { useQuery } from "@tanstack/react-query";
import { useState } from "react";

export default function CallLogsPage() {
  const [filter, setFilter] = useState("all");

  const { data, isLoading } = useQuery<any[]>({ queryKey: ["/api/call-logs"] });
  const logs = Array.isArray(data) ? data : [];

  return (
    <>
    
      <div className="content-header">
        <div className="container-fluid">
          <div className="d-flex align-items-center justify-content-between gap-3 flex-wrap mb-3">
            <h2 className="h5 mb-0">Call Logs</h2>
          </div>
        </div>
      </div>
      <div className="container-fluid">
        <div className="card">
          <div className="card-header border-bottom py-3">
            <ul className="nav nav--tabs p-1 rounded bg-white">
              {["all", "answered", "missed"].map(t => (
                <li key={t} className="nav-item">
                  <button className={`nav-link text-capitalize${filter === t ? " active" : ""}`} onClick={() => setFilter(t)} data-testid={`tab-call-${t}`}>
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
                    <th>From</th>
                    <th>To</th>
                    <th>Type</th>
                    <th>Duration</th>
                    <th>Date & Time</th>
                    <th>Status</th>
                  </tr>
                </thead>
                <tbody>
                  {isLoading ? (
                    <tr><td colSpan={7} className="text-center py-4"><div className="spinner-border spinner-border-sm" role="status" /></td></tr>
                  ) : logs.length === 0 ? (
                    <tr>
                      <td colSpan={7} className="text-center py-5 text-muted">
                        <i className="bi bi-telephone-fill fs-2 d-block mb-2 opacity-25"></i>
                        No call logs found
                      </td>
                    </tr>
                  ) : logs.map((l: any, idx: number) => (
                    <tr key={l.id}>
                      <td>{idx + 1}</td>
                      <td>{l.from || "—"}</td>
                      <td>{l.to || "—"}</td>
                      <td className="text-capitalize">{l.callType || "—"}</td>
                      <td>{l.duration ? `${l.duration}s` : "—"}</td>
                      <td>{l.createdAt ? new Date(l.createdAt).toLocaleString() : "—"}</td>
                      <td>
                        <span className={`badge ${l.status === "answered" ? "bg-success" : "bg-danger"}`}>
                          {l.status || "unknown"}
                        </span>
                      </td>
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
