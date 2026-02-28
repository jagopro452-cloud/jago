import { useQuery, useMutation } from "@tanstack/react-query";
import { queryClient, apiRequest } from "@/lib/queryClient";
import { useState } from "react";
import { useToast } from "@/hooks/use-toast";

const STATUS_BADGE: Record<string, string> = {
  active: "bg-success", suspended: "bg-danger", pending: "bg-warning text-dark",
};

const ROLE_COLORS: Record<string, string> = {
  active: "#16a34a", suspended: "#dc2626", pending: "#d97706",
};

function CompanyModal({ open, onClose, editing, onSave, saving }: any) {
  const [form, setForm] = useState(() => editing ? {
    companyName: editing.companyName || "",
    contactPerson: editing.contactPerson || "",
    phone: editing.phone || "",
    email: editing.email || "",
    gstNumber: editing.gstNumber || "",
    address: editing.address || "",
    city: editing.city || "",
    status: editing.status || "active",
    commissionPct: editing.commissionPct || "10",
  } : {
    companyName: "", contactPerson: "", phone: "", email: "",
    gstNumber: "", address: "", city: "Hyderabad",
    status: "active", commissionPct: "10",
  });

  if (!open) return null;
  const f = (k: string, v: any) => setForm((p: any) => ({ ...p, [k]: v }));

  return (
    <div className="modal-backdrop-jago" onClick={onClose}>
      <div className="modal-jago" style={{ maxWidth: 560 }} onClick={e => e.stopPropagation()}>
        <div className="modal-jago-header">
          <h5 className="modal-jago-title">
            <i className={`bi ${editing ? "bi-pencil-fill" : "bi-building-add"} me-2 text-primary`}></i>
            {editing ? "Edit B2B Company" : "Add B2B Company"}
          </h5>
          <button className="modal-jago-close" onClick={onClose}><i className="bi bi-x-lg"></i></button>
        </div>

        <div className="row g-3">
          <div className="col-12">
            <label className="form-label-jago">Company Name <span className="text-danger">*</span></label>
            <input className="admin-form-control" value={form.companyName}
              onChange={e => f("companyName", e.target.value)}
              placeholder="e.g. Swiggy Instamart" data-testid="input-b2b-name" />
          </div>
          <div className="col-6">
            <label className="form-label-jago">Contact Person</label>
            <input className="admin-form-control" value={form.contactPerson}
              onChange={e => f("contactPerson", e.target.value)} placeholder="Contact name" />
          </div>
          <div className="col-6">
            <label className="form-label-jago">Phone</label>
            <input className="admin-form-control" value={form.phone}
              onChange={e => f("phone", e.target.value)} placeholder="+91 9876543210" />
          </div>
          <div className="col-6">
            <label className="form-label-jago">Email</label>
            <input type="email" className="admin-form-control" value={form.email}
              onChange={e => f("email", e.target.value)} placeholder="admin@company.com" />
          </div>
          <div className="col-6">
            <label className="form-label-jago">GST Number</label>
            <input className="admin-form-control" value={form.gstNumber}
              onChange={e => f("gstNumber", e.target.value)} placeholder="36AABCD5678Q2Z6" />
          </div>
          <div className="col-6">
            <label className="form-label-jago">City</label>
            <input className="admin-form-control" value={form.city}
              onChange={e => f("city", e.target.value)} placeholder="Hyderabad" />
          </div>
          <div className="col-6">
            <label className="form-label-jago">Commission %</label>
            <div className="input-group">
              <input type="number" min="0" max="100" step="0.5" className="admin-form-control"
                value={form.commissionPct} onChange={e => f("commissionPct", e.target.value)} />
              <span className="input-group-text">%</span>
            </div>
          </div>
          <div className="col-12">
            <label className="form-label-jago">Address</label>
            <textarea className="admin-form-control" rows={2} value={form.address}
              onChange={e => f("address", e.target.value)} placeholder="Full business address" />
          </div>
          <div className="col-6">
            <label className="form-label-jago">Status</label>
            <select className="admin-form-control" value={form.status} onChange={e => f("status", e.target.value)}>
              <option value="active">Active</option>
              <option value="pending">Pending</option>
              <option value="suspended">Suspended</option>
            </select>
          </div>
        </div>

        <div className="d-flex gap-2 justify-content-end pt-3 border-top mt-3">
          <button className="btn btn-outline-secondary" onClick={onClose}>Cancel</button>
          <button className="btn btn-primary" disabled={!form.companyName || saving}
            onClick={() => onSave(form)} data-testid="btn-save-b2b">
            {saving ? <><span className="spinner-border spinner-border-sm me-2"></span>Saving…</> : editing ? "Update" : "Register"}
          </button>
        </div>
      </div>
    </div>
  );
}

function WalletModal({ company, open, onClose, onSave, saving }: any) {
  const [amount, setAmount] = useState("");
  const [type, setType] = useState<"add" | "deduct">("add");

  if (!open) return null;

  return (
    <div className="modal-backdrop-jago" onClick={onClose}>
      <div className="modal-jago" style={{ maxWidth: 380 }} onClick={e => e.stopPropagation()}>
        <div className="modal-jago-header">
          <h5 className="modal-jago-title">
            <i className="bi bi-wallet2 me-2 text-primary"></i>Wallet — {company?.companyName}
          </h5>
          <button className="modal-jago-close" onClick={onClose}><i className="bi bi-x-lg"></i></button>
        </div>
        <div style={{ background: "#f0fdf4", borderRadius: 10, padding: "12px 16px", marginBottom: 14, display: "flex", alignItems: "center", gap: 10 }}>
          <i className="bi bi-wallet-fill text-success" style={{ fontSize: 20 }}></i>
          <div>
            <div style={{ fontSize: 11, color: "#64748b" }}>Current Balance</div>
            <div style={{ fontSize: 20, fontWeight: 700, color: "#16a34a" }}>
              ₹{Number(company?.walletBalance || 0).toLocaleString("en-IN")}
            </div>
          </div>
        </div>
        <div className="d-flex gap-2 mb-3">
          {(["add", "deduct"] as const).map(t => (
            <button key={t} className={`btn btn-sm flex-1 ${type === t ? (t === "add" ? "btn-success" : "btn-danger") : "btn-outline-secondary"}`}
              onClick={() => setType(t)} style={{ flex: 1 }}>
              {t === "add" ? "➕ Add" : "➖ Deduct"}
            </button>
          ))}
        </div>
        <div>
          <label className="form-label-jago">Amount (₹)</label>
          <div className="input-group">
            <span className="input-group-text fw-bold">₹</span>
            <input type="number" min="1" className="admin-form-control"
              value={amount} onChange={e => setAmount(e.target.value)} placeholder="0.00"
              data-testid="input-wallet-amount" />
          </div>
        </div>
        <div className="d-flex gap-2 justify-content-end pt-3 border-top mt-3">
          <button className="btn btn-outline-secondary" onClick={onClose}>Cancel</button>
          <button className={`btn ${type === "add" ? "btn-success" : "btn-danger"}`}
            disabled={!amount || saving} onClick={() => onSave({ amount: Number(amount), type })}
            data-testid="btn-confirm-wallet">
            {saving ? "…" : type === "add" ? "Add Funds" : "Deduct Funds"}
          </button>
        </div>
      </div>
    </div>
  );
}

export default function B2BCompaniesPage() {
  const { toast } = useToast();
  const [tab, setTab] = useState("all");
  const [open, setOpen] = useState(false);
  const [editing, setEditing] = useState<any>(null);
  const [walletTarget, setWalletTarget] = useState<any>(null);

  const { data = [], isLoading } = useQuery<any[]>({
    queryKey: ["/api/b2b-companies"],
    queryFn: () => fetch("/api/b2b-companies").then(r => r.json()),
  });

  const companies = Array.isArray(data) ? data : [];

  const save = useMutation({
    mutationFn: (d: any) => editing
      ? apiRequest("PUT", `/api/b2b-companies/${editing.id}`, d)
      : apiRequest("POST", "/api/b2b-companies", d),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["/api/b2b-companies"] });
      toast({ title: editing ? "Company updated" : "Company registered" });
      setOpen(false); setEditing(null);
    },
    onError: (e: any) => toast({ title: "Error", description: e.message, variant: "destructive" }),
  });

  const wallet = useMutation({
    mutationFn: ({ id, data }: any) => apiRequest("PATCH", `/api/b2b-companies/${id}/wallet`, data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["/api/b2b-companies"] });
      toast({ title: "Wallet updated" });
      setWalletTarget(null);
    },
  });

  const remove = useMutation({
    mutationFn: (id: string) => apiRequest("DELETE", `/api/b2b-companies/${id}`),
    onSuccess: () => { queryClient.invalidateQueries({ queryKey: ["/api/b2b-companies"] }); toast({ title: "Deleted" }); },
  });

  const filtered = tab === "all" ? companies : companies.filter(c => c.status === tab);
  const activeCount = companies.filter(c => c.status === "active").length;
  const suspendedCount = companies.filter(c => c.status === "suspended").length;
  const totalBalance = companies.reduce((s, c) => s + Number(c.walletBalance || 0), 0);
  const totalTrips = companies.reduce((s, c) => s + Number(c.totalTrips || 0), 0);

  return (
    <div className="container-fluid">
      <div className="d-flex align-items-center justify-content-between mb-4">
        <div>
          <h4 className="fw-bold mb-0" data-testid="page-title">B2B / Porter Companies</h4>
          <div className="text-muted small">Manage business accounts for bulk delivery and ride partners</div>
        </div>
        <button className="btn btn-primary" onClick={() => { setEditing(null); setOpen(true); }}
          data-testid="btn-add-b2b">
          <i className="bi bi-building-add me-1"></i>Register Company
        </button>
      </div>

      {/* Summary cards */}
      <div className="row g-3 mb-3">
        {[
          { label: "Total Companies", val: companies.length, icon: "bi-building-fill", color: "#1a73e8", bg: "#e8f0fe" },
          { label: "Active", val: activeCount, icon: "bi-check-circle-fill", color: "#16a34a", bg: "#f0fdf4" },
          { label: "Suspended", val: suspendedCount, icon: "bi-x-circle-fill", color: "#dc2626", bg: "#fff5f5" },
          { label: "Total Wallet", val: `₹${totalBalance.toLocaleString("en-IN")}`, icon: "bi-wallet-fill", color: "#7c3aed", bg: "#f5f3ff" },
          { label: "Total Trips", val: totalTrips, icon: "bi-truck-front-fill", color: "#d97706", bg: "#fefce8" },
        ].map((s, i) => (
          <div key={i} className="col-6 col-xl">
            <div className="card border-0 shadow-sm" style={{ borderRadius: 14 }}>
              <div className="card-body d-flex align-items-center gap-3 py-3">
                <div className="rounded-3 d-flex align-items-center justify-content-center flex-shrink-0"
                  style={{ width: 42, height: 42, background: s.bg, color: s.color, fontSize: "1.1rem" }}>
                  <i className={`bi ${s.icon}`}></i>
                </div>
                <div>
                  <div className="fw-bold lh-1 mb-1" style={{ fontSize: 18, color: s.color }}>{isLoading ? "—" : s.val}</div>
                  <div className="text-muted" style={{ fontSize: 11 }}>{s.label}</div>
                </div>
              </div>
            </div>
          </div>
        ))}
      </div>

      <div className="card border-0 shadow-sm" style={{ borderRadius: 14 }}>
        <div className="card-header bg-white py-3 px-4 d-flex align-items-center gap-3"
          style={{ borderBottom: "1px solid #f1f5f9" }}>
          <ul className="nav nav--tabs p-1 rounded bg-light">
            {[
              ["all", "All", companies.length],
              ["active", "Active", activeCount],
              ["pending", "Pending", companies.filter(c => c.status === "pending").length],
              ["suspended", "Suspended", suspendedCount],
            ].map(([val, label, cnt]) => (
              <li key={val as string} className="nav-item">
                <button className={`nav-link${tab === val ? " active" : ""}`}
                  onClick={() => setTab(val as string)} data-testid={`tab-b2b-${val}`}>
                  {label}
                  {(cnt as number) > 0 && <span className="ms-1 badge rounded-pill"
                    style={{ background: tab === val ? "rgba(255,255,255,0.3)" : "#e2e8f0", color: tab === val ? "white" : "#475569", fontSize: 9 }}>
                    {cnt}
                  </span>}
                </button>
              </li>
            ))}
          </ul>
        </div>

        <div className="card-body p-0">
          <div className="table-responsive">
            <table className="table table-borderless align-middle table-hover mb-0">
              <thead style={{ background: "#f8fafc" }}>
                <tr>
                  {["#", "Company", "Contact", "GST / City", "Commission", "Wallet", "Trips", "Status", "Actions"].map((h, i) => (
                    <th key={i} className={i === 0 ? "ps-4" : i === 8 ? "text-center pe-4" : ""}
                      style={{ fontSize: 11, color: "#94a3b8", fontWeight: 700, textTransform: "uppercase", letterSpacing: ".5px", paddingTop: 12, paddingBottom: 12 }}>
                      {h}
                    </th>
                  ))}
                </tr>
              </thead>
              <tbody>
                {isLoading ? Array(3).fill(0).map((_, i) => (
                  <tr key={i}>{Array(9).fill(0).map((_, j) => <td key={j}><div style={{ height: 14, background: "#f1f5f9", borderRadius: 4 }} /></td>)}</tr>
                )) : filtered.length === 0 ? (
                  <tr><td colSpan={9}>
                    <div className="text-center py-5 text-muted">
                      <i className="bi bi-building fs-1 d-block mb-2" style={{ opacity: 0.25 }}></i>
                      <p className="fw-semibold mb-1">No companies found</p>
                      <button className="btn btn-sm btn-outline-primary mt-1" onClick={() => { setEditing(null); setOpen(true); }}>
                        <i className="bi bi-building-add me-1"></i>Register First Company
                      </button>
                    </div>
                  </td></tr>
                ) : filtered.map((co: any, idx: number) => (
                  <tr key={co.id} data-testid={`row-b2b-${co.id}`}>
                    <td className="ps-4 text-muted small">{idx + 1}</td>
                    <td>
                      <div className="d-flex align-items-center gap-2">
                        <div className="rounded-3 d-flex align-items-center justify-content-center flex-shrink-0"
                          style={{ width: 38, height: 38, background: "#e8f0fe", color: "#1a73e8", fontSize: 16 }}>
                          <i className="bi bi-building-fill"></i>
                        </div>
                        <div>
                          <div className="fw-semibold" style={{ fontSize: 13 }}>{co.companyName}</div>
                          <div style={{ fontSize: 10.5, color: "#94a3b8" }}>{co.email || "—"}</div>
                        </div>
                      </div>
                    </td>
                    <td>
                      <div style={{ fontSize: 12 }}>{co.contactPerson || "—"}</div>
                      <div style={{ fontSize: 10.5, color: "#94a3b8" }}>{co.phone || "—"}</div>
                    </td>
                    <td>
                      <div style={{ fontSize: 11, fontFamily: "monospace", color: "#64748b" }}>{co.gstNumber || "—"}</div>
                      <div style={{ fontSize: 10.5, color: "#94a3b8" }}>{co.city || "—"}</div>
                    </td>
                    <td>
                      <span className="fw-semibold" style={{ color: "#7c3aed", fontSize: 13 }}>
                        {co.commissionPct}%
                      </span>
                    </td>
                    <td>
                      <div className="fw-semibold" style={{ fontSize: 13, color: "#16a34a" }}>
                        ₹{Number(co.walletBalance || 0).toLocaleString("en-IN")}
                      </div>
                    </td>
                    <td style={{ fontSize: 13, color: "#d97706", fontWeight: 600 }}>
                      {co.totalTrips || 0}
                    </td>
                    <td>
                      <span className={`badge ${STATUS_BADGE[co.status] || "bg-secondary"}`} style={{ fontSize: 10 }}>
                        {co.status}
                      </span>
                    </td>
                    <td className="text-center pe-4">
                      <div className="d-flex justify-content-center gap-1">
                        <button className="btn btn-sm" style={{ borderRadius: 8, background: "#f0fdf4", color: "#16a34a", border: "1px solid #bbf7d0" }}
                          onClick={() => setWalletTarget(co)} data-testid={`btn-wallet-${co.id}`} title="Manage Wallet">
                          <i className="bi bi-wallet2"></i>
                        </button>
                        <button className="btn btn-sm btn-outline-primary" style={{ borderRadius: 8 }}
                          onClick={() => { setEditing(co); setOpen(true); }} data-testid={`btn-edit-b2b-${co.id}`}>
                          <i className="bi bi-pencil-fill"></i>
                        </button>
                        <button className="btn btn-sm btn-outline-danger" style={{ borderRadius: 8 }}
                          onClick={() => { if (confirm(`Delete ${co.companyName}?`)) remove.mutate(co.id); }}
                          data-testid={`btn-delete-b2b-${co.id}`}>
                          <i className="bi bi-trash-fill"></i>
                        </button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      </div>

      <CompanyModal key={editing?.id || "new"} open={open} onClose={() => { setOpen(false); setEditing(null); }}
        editing={editing} onSave={(d: any) => save.mutate(d)} saving={save.isPending} />

      {walletTarget && (
        <WalletModal company={walletTarget} open={!!walletTarget}
          onClose={() => setWalletTarget(null)}
          onSave={(d: any) => wallet.mutate({ id: walletTarget.id, data: d })}
          saving={wallet.isPending} />
      )}
    </div>
  );
}
