import { useQuery } from "@tanstack/react-query";
import { useState, useRef, useEffect } from "react";

const avatarBg = (name: string) => {
  const c = ["#1a73e8","#16a34a","#d97706","#9333ea","#0891b2","#dc2626"];
  return c[(name || "A").charCodeAt(0) % c.length];
};
const fmtTime = (ms: number) => new Date(ms).toLocaleTimeString("en-IN", { hour: "2-digit", minute: "2-digit" });

const MOCK_MESSAGES: Record<string, any[]> = {};
const SAMPLE_MSG = [
  { from: "user", text: "Hello, I need help with my recent trip.", time: Date.now() - 3600000 },
  { from: "admin", text: "Hi! Sure, please share your trip ID.", time: Date.now() - 3500000 },
  { from: "user", text: "Trip ID is #JG-20240228-001", time: Date.now() - 3400000 },
  { from: "admin", text: "I can see your trip. What seems to be the issue?", time: Date.now() - 3300000 },
  { from: "user", text: "I was overcharged by ₹50.", time: Date.now() - 3200000 },
  { from: "admin", text: "Let me check the fare details for you. Please hold on.", time: Date.now() - 3100000 },
];

export default function ChattingPage() {
  const [selected, setSelected] = useState<any>(null);
  const [filter, setFilter] = useState("all");
  const [msgInput, setMsgInput] = useState("");
  const [messages, setMessages] = useState<Record<string, any[]>>({});
  const [search, setSearch] = useState("");
  const messagesEndRef = useRef<HTMLDivElement>(null);

  const { data: custData } = useQuery<any>({
    queryKey: ["/api/users", { userType: "customer" }],
    queryFn: () => fetch("/api/users?userType=customer&limit=20").then(r => r.json()),
  });
  const { data: driverData } = useQuery<any>({
    queryKey: ["/api/users", { userType: "driver" }],
    queryFn: () => fetch("/api/users?userType=driver&limit=20").then(r => r.json()),
  });

  const customers = Array.isArray(custData?.data) ? custData.data : [];
  const drivers = Array.isArray(driverData?.data) ? driverData.data : [];

  const allUsers = filter === "customer" ? customers : filter === "driver" ? drivers : [...customers, ...drivers];
  const filtered = search ? allUsers.filter((u: any) => {
    const name = u.fullName || `${u.firstName || ""} ${u.lastName || ""}`.trim();
    return name.toLowerCase().includes(search.toLowerCase()) || (u.phone || "").includes(search);
  }) : allUsers;

  const handleSelect = (u: any) => {
    setSelected(u);
    if (!messages[u.id]) {
      setMessages(m => ({ ...m, [u.id]: SAMPLE_MSG.slice(0, Math.floor(Math.random() * 4) + 2) }));
    }
  };

  const sendMsg = () => {
    if (!msgInput.trim() || !selected) return;
    const newMsg = { from: "admin", text: msgInput.trim(), time: Date.now() };
    setMessages(m => ({ ...m, [selected.id]: [...(m[selected.id] || []), newMsg] }));
    setMsgInput("");
    setTimeout(() => messagesEndRef.current?.scrollIntoView({ behavior: "smooth" }), 50);
    setTimeout(() => {
      const replies = ["Thank you for your help!","I understand, thanks.","Can you check again?","That's great, appreciate it!"];
      const reply = { from: "user", text: replies[Math.floor(Math.random() * replies.length)], time: Date.now() };
      setMessages(m => ({ ...m, [selected.id]: [...(m[selected.id] || []), reply] }));
      setTimeout(() => messagesEndRef.current?.scrollIntoView({ behavior: "smooth" }), 50);
    }, 2000);
  };

  const selectedName = selected ? (selected.fullName || `${selected.firstName || ""} ${selected.lastName || ""}`.trim() || "User") : "";
  const currentMsgs = selected ? (messages[selected.id] || []) : [];
  const unreadCount = (id: string) => messages[id] ? 0 : Math.floor(Math.random() * 3);

  return (
    <div className="container-fluid px-0">
      <div className="d-flex" style={{ height: "calc(100vh - 130px)", minHeight: 600 }}>

        {/* LEFT: Contacts */}
        <div className="border-end d-flex flex-column" style={{ width: 300, flexShrink: 0 }}>
          <div className="p-3 border-bottom">
            <h6 className="fw-bold mb-2">Support Chats</h6>
            <div className="input-group input-group-sm">
              <span className="input-group-text bg-light border-0"><i className="bi bi-search text-muted"></i></span>
              <input className="form-control border-0 bg-light" placeholder="Search users..." value={search} onChange={e => setSearch(e.target.value)} />
            </div>
          </div>
          <div className="px-2 py-2 border-bottom">
            <div className="btn-group btn-group-sm w-100">
              {["all","customer","driver"].map(t => (
                <button key={t} className={`btn ${filter === t ? "btn-primary" : "btn-outline-secondary"} text-capitalize`}
                  onClick={() => setFilter(t)}>{t}</button>
              ))}
            </div>
          </div>
          <div style={{ overflowY: "auto", flex: 1 }}>
            {filtered.length === 0 ? (
              <div className="text-center py-5 text-muted">
                <i className="bi bi-chat-left-dots fs-2 d-block mb-2 opacity-25"></i>
                <small>No users found</small>
              </div>
            ) : filtered.map((u: any, idx: number) => {
              const name = u.fullName || `${u.firstName || ""} ${u.lastName || ""}`.trim() || "User";
              const isSelected = selected?.id === u.id;
              const hasUnread = !messages[u.id] && idx < 3;
              return (
                <div key={u.id} onClick={() => handleSelect(u)} data-testid={`chat-user-${u.id}`}
                  className={`d-flex align-items-center gap-3 px-3 py-2 border-bottom ${isSelected ? "bg-primary bg-opacity-10" : "hover-bg"}`}
                  style={{ cursor: "pointer", background: isSelected ? undefined : undefined }}>
                  <div className="position-relative flex-shrink-0">
                    <div className="rounded-circle d-flex align-items-center justify-content-center text-white fw-bold"
                      style={{ width: 40, height: 40, fontSize: "0.9rem", background: avatarBg(name) }}>
                      {name[0]?.toUpperCase()}
                    </div>
                    <span className="position-absolute bottom-0 end-0 rounded-circle border border-white"
                      style={{ width: 10, height: 10, background: "#16a34a" }}></span>
                  </div>
                  <div className="flex-grow-1 min-w-0">
                    <div className="d-flex justify-content-between align-items-center">
                      <span className="fw-semibold text-truncate" style={{ fontSize: "0.85rem" }}>{name}</span>
                      {hasUnread && <span className="badge bg-primary rounded-pill" style={{ fontSize: "0.65rem" }}>New</span>}
                    </div>
                    <small className="text-muted text-truncate d-block">
                      {u.userType === "driver" ? "🚗 Driver" : "👤 Customer"} · {u.phone || u.email || "—"}
                    </small>
                  </div>
                </div>
              );
            })}
          </div>
        </div>

        {/* RIGHT: Chat Area */}
        <div className="flex-grow-1 d-flex flex-column">
          {selected ? (
            <>
              {/* Header */}
              <div className="p-3 border-bottom bg-white d-flex align-items-center justify-content-between">
                <div className="d-flex align-items-center gap-3">
                  <div className="rounded-circle d-flex align-items-center justify-content-center text-white fw-bold"
                    style={{ width: 42, height: 42, background: avatarBg(selectedName) }}>
                    {selectedName[0]?.toUpperCase()}
                  </div>
                  <div>
                    <div className="fw-semibold">{selectedName}</div>
                    <small className="text-success d-flex align-items-center gap-1">
                      <span style={{ width: 7, height: 7, borderRadius: "50%", background: "#16a34a", display: "inline-block" }}></span>
                      Online
                    </small>
                  </div>
                </div>
                <div className="d-flex gap-2">
                  <button className="btn btn-sm btn-outline-secondary" title="Call"><i className="bi bi-telephone-fill"></i></button>
                  <button className="btn btn-sm btn-outline-secondary" title="Profile"><i className="bi bi-person-fill"></i></button>
                </div>
              </div>

              {/* Messages */}
              <div className="flex-grow-1 p-3 overflow-auto" style={{ background: "#f8fafc" }}>
                {currentMsgs.map((msg: any, i: number) => (
                  <div key={i} className={`d-flex mb-3 ${msg.from === "admin" ? "justify-content-end" : "justify-content-start"}`}>
                    {msg.from !== "admin" && (
                      <div className="rounded-circle d-flex align-items-center justify-content-center text-white fw-bold me-2 flex-shrink-0"
                        style={{ width: 32, height: 32, fontSize: "0.75rem", background: avatarBg(selectedName), alignSelf: "flex-end" }}>
                        {selectedName[0]?.toUpperCase()}
                      </div>
                    )}
                    <div>
                      <div className="px-3 py-2 rounded-3 shadow-sm"
                        style={{ maxWidth: 340, background: msg.from === "admin" ? "#1a73e8" : "#fff", color: msg.from === "admin" ? "#fff" : "#1e293b", fontSize: "0.875rem", borderRadius: msg.from === "admin" ? "18px 18px 4px 18px" : "18px 18px 18px 4px" }}>
                        {msg.text}
                      </div>
                      <div className={`text-muted mt-1 ${msg.from === "admin" ? "text-end" : ""}`} style={{ fontSize: "0.7rem" }}>
                        {fmtTime(msg.time)}
                      </div>
                    </div>
                  </div>
                ))}
                <div ref={messagesEndRef} />
              </div>

              {/* Input */}
              <div className="p-3 border-top bg-white">
                <div className="input-group">
                  <input className="form-control border-0 bg-light rounded-start-3" placeholder="Type a message..." value={msgInput}
                    onChange={e => setMsgInput(e.target.value)} onKeyDown={e => e.key === "Enter" && sendMsg()}
                    data-testid="input-chat-message" />
                  <button className="btn btn-primary px-4" onClick={sendMsg} data-testid="btn-send-message">
                    <i className="bi bi-send-fill"></i>
                  </button>
                </div>
              </div>
            </>
          ) : (
            <div className="flex-grow-1 d-flex align-items-center justify-content-center text-muted">
              <div className="text-center">
                <i className="bi bi-chat-left-dots fs-1 d-block mb-3 opacity-25"></i>
                <h5 className="fw-semibold">Select a conversation</h5>
                <p className="mb-0 small">Choose a user from the left panel to start chatting</p>
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
