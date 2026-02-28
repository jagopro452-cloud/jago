import { useQuery } from "@tanstack/react-query";
import { useState } from "react";

export default function ReportsPage() {
  const [tab, setTab] = useState("earning");
  const { data: stats } = useQuery<any>({ queryKey: ["/api/dashboard/stats"] });

  const earningStats = [
    { label: "Total Earnings", value: `₹${(parseFloat(stats?.totalRevenue || 0)).toFixed(2)}`, icon: "bi-cash-stack", color: "jd-stat-blue" },
    { label: "Driver Earnings", value: `₹${(parseFloat(stats?.totalRevenue || 0) * 0.8).toFixed(2)}`, icon: "bi-cash-coin", color: "jd-stat-green" },
    { label: "Admin Commission", value: `₹${(parseFloat(stats?.totalRevenue || 0) * 0.2).toFixed(2)}`, icon: "bi-currency-rupee", color: "jd-stat-purple" },
    { label: "Total Trips", value: stats?.totalTrips || 0, icon: "bi-car-front-fill", color: "jd-stat-amber" },
  ];

  return (
    <>
    
      <div className="content-header">
        <div className="container-fluid">
          <div className="d-flex align-items-center justify-content-between gap-3 flex-wrap mb-3">
            <h2 className="h5 mb-0">Reports</h2>
          </div>
        </div>
      </div>
      <div className="container-fluid">
        <div className="card mb-4">
          <div className="card-header border-bottom py-3">
            <ul className="nav nav--tabs p-1 rounded bg-white">
              {["earning", "trip", "driver", "customer"].map(t => (
                <li key={t} className="nav-item">
                  <button className={`nav-link text-capitalize${tab === t ? " active" : ""}`} onClick={() => setTab(t)} data-testid={`tab-report-${t}`}>
                    {t.charAt(0).toUpperCase() + t.slice(1)} Report
                  </button>
                </li>
              ))}
            </ul>
          </div>
          <div className="card-body">
            {tab === "earning" && (
              <>
                <div className="row g-3 mb-4">
                  {earningStats.map((s, i) => (
                    <div key={i} className="col-md-3 col-sm-6">
                      <div className={`jd-stat ${s.color}`}>
                        <div className="jd-s-icon">
                          <i className={`bi ${s.icon}`}></i>
                        </div>
                        <div>
                          <div className="jd-stat-value">{s.value}</div>
                          <div className="jd-stat-label">{s.label}</div>
                        </div>
                      </div>
                    </div>
                  ))}
                </div>
                <div className="table-responsive">
                  <table className="table table-borderless align-middle table-hover">
                    <thead className="table-light">
                      <tr>
                        <th>Date</th>
                        <th>Total Trips</th>
                        <th>Revenue</th>
                        <th>Driver Earnings</th>
                        <th>Commission</th>
                      </tr>
                    </thead>
                    <tbody>
                      <tr>
                        <td colSpan={5} className="text-center py-5 text-muted">
                          <i className="bi bi-bar-chart-line-fill fs-2 d-block mb-2 opacity-25"></i>
                          Detailed earnings report will appear here
                        </td>
                      </tr>
                    </tbody>
                  </table>
                </div>
              </>
            )}
            {tab === "trip" && (
              <div className="table-responsive">
                <table className="table table-borderless align-middle table-hover">
                  <thead className="table-light">
                    <tr>
                      <th>Period</th>
                      <th>Total</th>
                      <th>Completed</th>
                      <th>Cancelled</th>
                      <th>Completion Rate</th>
                    </tr>
                  </thead>
                  <tbody>
                    <tr>
                      <td colSpan={5} className="text-center py-5 text-muted">
                        <i className="bi bi-car-front-fill fs-2 d-block mb-2 opacity-25"></i>
                        Trip report data will appear here
                      </td>
                    </tr>
                  </tbody>
                </table>
              </div>
            )}
            {tab === "driver" && (
              <div className="table-responsive">
                <table className="table table-borderless align-middle table-hover">
                  <thead className="table-light">
                    <tr>
                      <th>Driver</th>
                      <th>Total Trips</th>
                      <th>Earnings</th>
                      <th>Rating</th>
                      <th>Active Days</th>
                    </tr>
                  </thead>
                  <tbody>
                    <tr>
                      <td colSpan={5} className="text-center py-5 text-muted">
                        <i className="bi bi-person-badge-fill fs-2 d-block mb-2 opacity-25"></i>
                        Driver report data will appear here
                      </td>
                    </tr>
                  </tbody>
                </table>
              </div>
            )}
            {tab === "customer" && (
              <div className="table-responsive">
                <table className="table table-borderless align-middle table-hover">
                  <thead className="table-light">
                    <tr>
                      <th>Customer</th>
                      <th>Total Trips</th>
                      <th>Total Spent</th>
                      <th>Coupons Used</th>
                      <th>Joined</th>
                    </tr>
                  </thead>
                  <tbody>
                    <tr>
                      <td colSpan={5} className="text-center py-5 text-muted">
                        <i className="bi bi-people-fill fs-2 d-block mb-2 opacity-25"></i>
                        Customer report data will appear here
                      </td>
                    </tr>
                  </tbody>
                </table>
              </div>
            )}
          </div>
        </div>
      </div>
    
    </>
  );
}
