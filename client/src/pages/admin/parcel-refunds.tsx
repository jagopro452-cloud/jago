import { useState } from "react";

export default function ParcelRefundsPage() {
  const [tab, setTab] = useState("pending");
  const tabs = ["pending", "approved", "denied", "refunded"];

  return (
    <>
    
      <div className="content-header">
        <div className="container-fluid">
          <div className="d-flex align-items-center justify-content-between gap-3 flex-wrap mb-3">
            <h2 className="h5 mb-0">Parcel Refund Request</h2>
          </div>
        </div>
      </div>
      <div className="container-fluid">
        <div className="card">
          <div className="card-header border-bottom py-3">
            <ul className="nav nav--tabs p-1 rounded bg-white">
              {tabs.map(t => (
                <li key={t} className="nav-item">
                  <button
                    className={`nav-link text-capitalize${tab === t ? " active" : ""}`}
                    onClick={() => setTab(t)}
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
                    <th>Ref ID</th>
                    <th>Customer</th>
                    <th>Amount</th>
                    <th>Reason</th>
                    <th>Status</th>
                    <th>Action</th>
                  </tr>
                </thead>
                <tbody>
                  <tr>
                    <td colSpan={7} className="text-center py-5 text-muted">
                      <i className="bi bi-arrow-return-left fs-2 d-block mb-2 opacity-25"></i>
                      No {tab} refund requests found
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
