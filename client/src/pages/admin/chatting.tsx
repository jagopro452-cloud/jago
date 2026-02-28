import { useQuery } from "@tanstack/react-query";
import { useState } from "react";

export default function ChattingPage() {
  const [selected, setSelected] = useState<any>(null);
  const [filter, setFilter] = useState("all");

  const { data } = useQuery<any>({ queryKey: ["/api/users", { userType: "customer" }] });
  const customers = Array.isArray(data?.data) ? data.data.slice(0, 10) : [];

  return (
    <>
    
      <div className="content-header">
        <div className="container-fluid">
          <div className="d-flex align-items-center justify-content-between gap-3 flex-wrap mb-3">
            <h2 className="h5 mb-0">Chatting</h2>
          </div>
        </div>
      </div>
      <div className="container-fluid">
        <div className="card" style={{ minHeight: "70vh" }}>
          <div className="card-body p-0">
            <div className="d-flex h-100" style={{ minHeight: "70vh" }}>
              {/* Sidebar */}
              <div className="border-end" style={{ width: 300, overflowY: "auto" }}>
                <div className="p-3 border-bottom">
                  <ul className="nav nav--tabs p-1 rounded bg-light">
                    {["all", "customer", "driver"].map(t => (
                      <li key={t} className="nav-item">
                        <button className={`nav-link text-capitalize${filter === t ? " active" : ""}`} style={{ padding: "4px 10px" }} onClick={() => setFilter(t)}>
                          {t}
                        </button>
                      </li>
                    ))}
                  </ul>
                </div>
                {customers.length === 0 ? (
                  <div className="text-center py-5 text-muted">
                    <i className="bi bi-chat-left-dots fs-2 d-block mb-2 opacity-25"></i>
                    <small>No conversations</small>
                  </div>
                ) : customers.map((c: any) => (
                  <div
                    key={c.id}
                    className={`p-3 border-bottom d-flex align-items-center gap-3 cursor-pointer ${selected?.id === c.id ? "bg-primary bg-opacity-10" : ""}`}
                    style={{ cursor: "pointer" }}
                    onClick={() => setSelected(c)}
                    data-testid={`chat-user-${c.id}`}
                  >
                    <div className="avatar rounded-circle bg-primary text-white d-flex align-items-center justify-content-center" style={{ width: 40, height: 40, flexShrink: 0 }}>
                      {(c.fullName || c.firstName || "U")[0].toUpperCase()}
                    </div>
                    <div>
                      <div className="fw-semibold">{c.fullName || `${c.firstName || ""} ${c.lastName || ""}`.trim() || "User"}</div>
                      <small className="text-muted">{c.phone || c.email || "—"}</small>
                    </div>
                  </div>
                ))}
              </div>

              {/* Chat area */}
              <div className="flex-grow-1 d-flex flex-column">
                {selected ? (
                  <>
                    <div className="p-3 border-bottom d-flex align-items-center gap-3">
                      <div className="avatar rounded-circle bg-primary text-white d-flex align-items-center justify-content-center" style={{ width: 40, height: 40 }}>
                        {(selected.fullName || selected.firstName || "U")[0].toUpperCase()}
                      </div>
                      <div>
                        <div className="fw-semibold">{selected.fullName || `${selected.firstName || ""} ${selected.lastName || ""}`.trim()}</div>
                        <small className="text-muted">{selected.phone || selected.email}</small>
                      </div>
                    </div>
                    <div className="flex-grow-1 p-4 d-flex align-items-center justify-content-center text-muted">
                      <div className="text-center">
                        <i className="bi bi-chat-dots fs-1 d-block mb-2 opacity-25"></i>
                        <p className="mb-0">No messages yet. Start a conversation.</p>
                      </div>
                    </div>
                    <div className="p-3 border-top">
                      <div className="input-group">
                        <input className="form-control" placeholder="Type a message..." data-testid="input-chat-message" />
                        <button className="btn btn-primary" data-testid="btn-send-message">
                          <i className="bi bi-send-fill"></i>
                        </button>
                      </div>
                    </div>
                  </>
                ) : (
                  <div className="flex-grow-1 d-flex align-items-center justify-content-center text-muted">
                    <div className="text-center">
                      <i className="bi bi-chat-left-dots fs-1 d-block mb-3 opacity-25"></i>
                      <h5>Select a conversation</h5>
                      <p className="mb-0">Choose a user from the list to start chatting</p>
                    </div>
                  </div>
                )}
              </div>
            </div>
          </div>
        </div>
      </div>
    
    </>
  );
}
