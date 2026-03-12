import { useState, useEffect } from "react";
import { useQuery, useMutation } from "@tanstack/react-query";
import { queryClient, apiRequest } from "@/lib/queryClient";
import { useToast } from "@/hooks/use-toast";

type Model = "commission" | "subscription";

function CalcRow({ label, amount, color, bold }: { label: string; amount: string; color?: string; bold?: boolean }) {
  return (
    <div className="d-flex justify-content-between align-items-center py-1" style={{ borderBottom: "1px dashed #f1f5f9" }}>
      <span style={{ fontSize: 12.5, color: bold ? "#0f172a" : "#64748b", fontWeight: bold ? 700 : 400 }}>{label}</span>
      <span style={{ fontSize: 13, fontWeight: bold ? 800 : 600, color: color || "#0f172a" }}>{amount}</span>
    </div>
  );
}

function SectionHeader({ icon, title, bg, color, badge }: any) {
  return (
    <div className="d-flex align-items-center gap-2 mb-3">
      <div className="rounded-2 d-flex align-items-center justify-content-center flex-shrink-0"
        style={{ width: 34, height: 34, background: bg, color }}>
        <i className={`bi ${icon}`}></i>
      </div>
      <div>
        <span className="fw-semibold" style={{ fontSize: 14 }}>{title}</span>
        {badge && <span className="badge ms-2 rounded-pill" style={{ background: badge.bg, color: badge.color, fontSize: 10 }}>{badge.label}</span>}
      </div>
    </div>
  );
}

export default function RevenueModelPage() {
  const { toast } = useToast();
  const [s, setS] = useState<Record<string, string>>({});
  const [dirty, setDirty] = useState(false);
  const [exampleFare, setExampleFare] = useState("200");

  const { isLoading } = useQuery<any>({
    queryKey: ["/api/revenue-model"],
    queryFn: () => fetch("/api/revenue-model").then(r => r.ok ? r.json() : r.json().then(d => { throw new Error(d?.message || "Error") })).then(d => (d && !d.message && !d.error) ? d : {}),
    select: (data: any) => data,
  });
  const { data: settingsData } = useQuery<any>({
    queryKey: ["/api/revenue-model"],
  });
  useEffect(() => {
    if (settingsData && !dirty) setS(settingsData);
  }, [settingsData]);

  const saveMutation = useMutation({
    mutationFn: (data: any) => apiRequest("PUT", "/api/revenue-model", data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["/api/revenue-model"] });
      setDirty(false);
      toast({ title: "Saved!", description: "Revenue model settings updated successfully." });
    },
  });

  const set = (key: string, val: string) => {
    setS(prev => ({ ...prev, [key]: val }));
    setDirty(true);
  };

  const activeModel: Model = (s["active_model"] as Model) || "commission";

  const switchModel = (model: Model) => {
    set("active_model", model);
  };

  // Commission calculator
  const fare = parseFloat(exampleFare) || 0;
  const commPct = parseFloat(s["commission_pct"] || "15") / 100;
  const commGstPct = parseFloat(s["commission_gst_pct"] || "18") / 100;
  const insPerRide = parseFloat(s["commission_insurance_per_ride"] || "2");
  const commAmount = fare * commPct;
  const gstOnComm = commAmount * commGstPct;
  const driverEarnings = fare - commAmount - gstOnComm - insPerRide;
  const adminEarnings = commAmount + gstOnComm + insPerRide;

  // Subscription calculator
  const mkSubCalc = (chargeKey: string, insKey: string) => {
    const charge = parseFloat(s[chargeKey] || "0");
    const gstPct = parseFloat(s["sub_gst_pct"] || "18") / 100;
    const ins = parseFloat(s[insKey] || "0");
    const gst = charge * gstPct;
    const total = charge + gst + ins;
    return { charge, gst, ins, total };
  };

  const subDaily = mkSubCalc("sub_daily_charge", "sub_insurance_daily");
  const subWeekly = mkSubCalc("sub_weekly_charge", "sub_insurance_weekly");
  const subMonthly = mkSubCalc("sub_monthly_charge", "sub_insurance_monthly");

  const planCard = (label: string, icon: string, color: string, bg: string, data: any, chargeKey: string, insKey: string, suffix: string) => (
    <div className="col-md-4">
      <div className="card border-0 h-100" style={{ borderRadius: 14, border: `1.5px solid ${activeModel === "subscription" ? color + "33" : "#e2e8f0"}`, opacity: activeModel === "subscription" ? 1 : 0.55 }}>
        <div style={{ height: 4, background: activeModel === "subscription" ? `linear-gradient(90deg, ${color}, ${color}88)` : "#e2e8f0", borderRadius: "14px 14px 0 0" }} />
        <div className="card-body p-3">
          <div className="d-flex align-items-center gap-2 mb-3">
            <div className="rounded-3 d-flex align-items-center justify-content-center"
              style={{ width: 36, height: 36, background: bg, color, fontSize: 14 }}>
              <i className={`bi ${icon}`}></i>
            </div>
            <span className="fw-semibold" style={{ fontSize: 14 }}>{label}</span>
          </div>

          <div className="row g-2 mb-3">
            <div className="col-12">
              <label className="form-label small fw-semibold text-muted mb-1">Platform Charge</label>
              <div className="input-group input-group-sm">
                <span className="input-group-text">₹</span>
                <input type="number" className="form-control" value={s[chargeKey] || ""}
                  disabled={activeModel !== "subscription"}
                  onChange={e => set(chargeKey, e.target.value)}
                  data-testid={`input-${chargeKey}`} />
                <span className="input-group-text" style={{ fontSize: 11 }}>{suffix}</span>
              </div>
            </div>
            <div className="col-12">
              <label className="form-label small fw-semibold text-muted mb-1">Insurance</label>
              <div className="input-group input-group-sm">
                <span className="input-group-text">₹</span>
                <input type="number" className="form-control" value={s[insKey] || ""}
                  disabled={activeModel !== "subscription"}
                  onChange={e => set(insKey, e.target.value)}
                  data-testid={`input-${insKey}`} />
                <span className="input-group-text" style={{ fontSize: 11 }}>{suffix}</span>
              </div>
            </div>
          </div>

          <div className="p-2 rounded-3" style={{ background: activeModel === "subscription" ? bg : "#f8fafc" }}>
            <CalcRow label="Platform Charge" amount={`₹${data.charge.toFixed(0)}`} />
            <CalcRow label={`GST (${s["sub_gst_pct"] || 18}%)`} amount={`₹${data.gst.toFixed(1)}`} />
            <CalcRow label="Insurance" amount={`₹${data.ins.toFixed(0)}`} />
            <CalcRow label="Driver Pays Total" amount={`₹${data.total.toFixed(1)}`} color={color} bold />
          </div>
          <div className="mt-2 text-center" style={{ fontSize: 10.5, color: "#16a34a" }}>
            <i className="bi bi-check-circle-fill me-1"></i>Driver keeps 100% of ride earnings
          </div>
        </div>
      </div>
    </div>
  );

  return (
    <div className="container-fluid">
      <div className="d-flex align-items-center justify-content-between mb-4">
        <div>
          <h4 className="fw-bold mb-0" data-testid="page-title">Revenue Model</h4>
          <div className="text-muted small">Choose how your platform earns — Commission per ride OR Driver subscription</div>
        </div>
        <div className="d-flex align-items-center gap-2">
          <span className={`badge rounded-pill ${activeModel === "commission" ? "bg-warning text-dark" : "bg-success"}`}
            style={{ fontSize: 12, padding: "6px 14px" }}>
            <i className={`bi ${activeModel === "commission" ? "bi-percent" : "bi-card-checklist"} me-1`}></i>
            {activeModel === "commission" ? "Commission Model Active" : "Subscription Model Active"}
          </span>
        </div>
      </div>

      {/* MODEL SELECTOR */}
      <div className="row g-3 mb-4">
        {/* Commission Model Card */}
        <div className="col-md-6">
          <div
            className="card h-100"
            onClick={() => switchModel("commission")}
            style={{
              borderRadius: 16, cursor: "pointer",
              border: `2px solid ${activeModel === "commission" ? "#f59e0b" : "#e2e8f0"}`,
              boxShadow: activeModel === "commission" ? "0 0 0 3px #fef3c722" : "none",
              transition: "all .2s",
            }}
            data-testid="card-commission-model"
          >
            <div style={{ height: 5, background: activeModel === "commission" ? "linear-gradient(90deg,#f59e0b,#d97706)" : "#e2e8f0", borderRadius: "14px 14px 0 0" }} />
            <div className="card-body p-4">
              <div className="d-flex align-items-start justify-content-between mb-3">
                <div className="d-flex align-items-center gap-3">
                  <div className="rounded-3 d-flex align-items-center justify-content-center"
                    style={{ width: 48, height: 48, background: "#fefce8", color: "#d97706", fontSize: "1.3rem" }}>
                    <i className="bi bi-percent"></i>
                  </div>
                  <div>
                    <div className="fw-bold" style={{ fontSize: 16 }}>Commission Model</div>
                    <div className="text-muted" style={{ fontSize: 12 }}>Per-ride deduction from driver earnings</div>
                  </div>
                </div>
                <div className="rounded-circle d-flex align-items-center justify-content-center"
                  style={{ width: 24, height: 24, border: `2px solid ${activeModel === "commission" ? "#f59e0b" : "#cbd5e1"}`, background: activeModel === "commission" ? "#f59e0b" : "white" }}>
                  {activeModel === "commission" && <i className="bi bi-check-lg text-white" style={{ fontSize: 12 }}></i>}
                </div>
              </div>
              <div className="d-flex gap-3 flex-wrap" style={{ fontSize: 12.5, color: "#64748b" }}>
                <span><i className="bi bi-arrow-right-circle-fill me-1" style={{ color: "#f59e0b" }}></i>Commission % per ride</span>
                <span><i className="bi bi-arrow-right-circle-fill me-1" style={{ color: "#f59e0b" }}></i>GST on commission</span>
                <span><i className="bi bi-arrow-right-circle-fill me-1" style={{ color: "#f59e0b" }}></i>Insurance per ride</span>
              </div>
              <div className="mt-3 p-2 rounded-2" style={{ background: "#fefce8", fontSize: 12, color: "#92400e" }}>
                <i className="bi bi-info-circle me-1"></i>
                Driver earns = Fare − Commission − GST − Insurance (deducted per trip)
              </div>
            </div>
          </div>
        </div>

        {/* Subscription Model Card */}
        <div className="col-md-6">
          <div
            className="card h-100"
            onClick={() => switchModel("subscription")}
            style={{
              borderRadius: 16, cursor: "pointer",
              border: `2px solid ${activeModel === "subscription" ? "#1a73e8" : "#e2e8f0"}`,
              boxShadow: activeModel === "subscription" ? "0 0 0 3px #1a73e822" : "none",
              transition: "all .2s",
            }}
            data-testid="card-subscription-model"
          >
            <div style={{ height: 5, background: activeModel === "subscription" ? "linear-gradient(90deg,#1a73e8,#1558b0)" : "#e2e8f0", borderRadius: "14px 14px 0 0" }} />
            <div className="card-body p-4">
              <div className="d-flex align-items-start justify-content-between mb-3">
                <div className="d-flex align-items-center gap-3">
                  <div className="rounded-3 d-flex align-items-center justify-content-center"
                    style={{ width: 48, height: 48, background: "#e8f0fe", color: "#1a73e8", fontSize: "1.3rem" }}>
                    <i className="bi bi-card-checklist"></i>
                  </div>
                  <div>
                    <div className="fw-bold" style={{ fontSize: 16 }}>Subscription Model</div>
                    <div className="text-muted" style={{ fontSize: 12 }}>Driver pays daily / weekly / monthly</div>
                  </div>
                </div>
                <div className="rounded-circle d-flex align-items-center justify-content-center"
                  style={{ width: 24, height: 24, border: `2px solid ${activeModel === "subscription" ? "#1a73e8" : "#cbd5e1"}`, background: activeModel === "subscription" ? "#1a73e8" : "white" }}>
                  {activeModel === "subscription" && <i className="bi bi-check-lg text-white" style={{ fontSize: 12 }}></i>}
                </div>
              </div>
              <div className="d-flex gap-3 flex-wrap" style={{ fontSize: 12.5, color: "#64748b" }}>
                <span><i className="bi bi-arrow-right-circle-fill me-1" style={{ color: "#1a73e8" }}></i>Day / Week / Month plans</span>
                <span><i className="bi bi-arrow-right-circle-fill me-1" style={{ color: "#1a73e8" }}></i>GST on subscription</span>
                <span><i className="bi bi-arrow-right-circle-fill me-1" style={{ color: "#1a73e8" }}></i>Insurance included</span>
              </div>
              <div className="mt-3 p-2 rounded-2" style={{ background: "#e8f0fe", fontSize: 12, color: "#1558b0" }}>
                <i className="bi bi-info-circle me-1"></i>
                Driver pays fixed subscription → keeps 100% of all ride earnings
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* COMMISSION MODEL SETTINGS */}
      <div className="card border-0 shadow-sm mb-4" style={{ borderRadius: 14, opacity: activeModel === "commission" ? 1 : 0.6 }}>
        <div className="card-header bg-white py-3 px-4 d-flex align-items-center justify-content-between"
          style={{ borderBottom: "1px solid #f1f5f9", borderRadius: "14px 14px 0 0" }}>
          <SectionHeader icon="bi-percent" title="Commission Model Settings" bg="#fefce8" color="#d97706"
            badge={activeModel === "commission" ? { label: "ACTIVE", bg: "#d97706", color: "white" } : { label: "INACTIVE", bg: "#e2e8f0", color: "#94a3b8" }} />
          {activeModel !== "commission" && (
            <span style={{ fontSize: 11, color: "#94a3b8" }}>
              <i className="bi bi-lock-fill me-1"></i>Activate Commission Model to edit
            </span>
          )}
        </div>
        <div className="card-body p-4">
          <div className="row g-4">
            <div className="col-md-8">
              <div className="row g-3">
                {[
                  { key: "commission_pct", label: "Commission (%)", prefix: "%", placeholder: "15", help: "% of ride fare taken as platform commission" },
                  { key: "commission_gst_pct", label: "GST on Commission (%)", prefix: "%", placeholder: "18", help: "GST applied on the commission amount (e.g., 18%)" },
                  { key: "commission_insurance_per_ride", label: "Insurance per Ride (₹)", prefix: "₹", placeholder: "2", help: "Flat insurance amount deducted per completed ride" },
                ].map(f => (
                  <div key={f.key} className="col-md-4">
                    <label className="form-label small fw-semibold text-muted">{f.label}</label>
                    <div className="input-group input-group-sm">
                      <span className="input-group-text fw-semibold" style={{ color: "#d97706", minWidth: 36 }}>{f.prefix}</span>
                      <input type="number" step="0.5" className="form-control" placeholder={f.placeholder}
                        value={s[f.key] || ""}
                        disabled={activeModel !== "commission"}
                        onChange={e => set(f.key, e.target.value)}
                        data-testid={`input-${f.key}`} />
                    </div>
                    <div className="form-text" style={{ fontSize: 10.5 }}>{f.help}</div>
                  </div>
                ))}
              </div>
            </div>

            {/* Live Calculator */}
            <div className="col-md-4">
              <div className="p-3 rounded-3 h-100" style={{ background: activeModel === "commission" ? "#fefce8" : "#f8fafc", border: "1px dashed #fcd34d" }}>
                <div className="fw-semibold mb-2" style={{ fontSize: 13, color: "#92400e" }}>
                  <i className="bi bi-calculator me-1"></i>Earnings Calculator
                </div>
                <div className="mb-3">
                  <label className="form-label small text-muted mb-1">Example Fare (₹)</label>
                  <input type="number" className="form-control form-control-sm" value={exampleFare}
                    onChange={e => setExampleFare(e.target.value)} style={{ maxWidth: 120 }} data-testid="input-example-fare" />
                </div>
                <CalcRow label="Ride Fare" amount={`₹${fare.toFixed(0)}`} />
                <CalcRow label={`Commission (${s["commission_pct"] || 15}%)`} amount={`−₹${commAmount.toFixed(1)}`} color="#dc2626" />
                <CalcRow label={`GST on Comm. (${s["commission_gst_pct"] || 18}%)`} amount={`−₹${gstOnComm.toFixed(1)}`} color="#dc2626" />
                <CalcRow label="Insurance" amount={`−₹${insPerRide.toFixed(0)}`} color="#dc2626" />
                <div className="mt-2">
                  <CalcRow label="Driver Gets" amount={`₹${Math.max(0, driverEarnings).toFixed(1)}`} color="#16a34a" bold />
                  <CalcRow label="Admin Gets" amount={`₹${adminEarnings.toFixed(1)}`} color="#d97706" bold />
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* SUBSCRIPTION MODEL SETTINGS */}
      <div className="card border-0 shadow-sm mb-4" style={{ borderRadius: 14, opacity: activeModel === "subscription" ? 1 : 0.6 }}>
        <div className="card-header bg-white py-3 px-4 d-flex align-items-center justify-content-between"
          style={{ borderBottom: "1px solid #f1f5f9", borderRadius: "14px 14px 0 0" }}>
          <SectionHeader icon="bi-card-checklist" title="Subscription Model Settings" bg="#e8f0fe" color="#1a73e8"
            badge={activeModel === "subscription" ? { label: "ACTIVE", bg: "#1a73e8", color: "white" } : { label: "INACTIVE", bg: "#e2e8f0", color: "#94a3b8" }} />
          {activeModel !== "subscription" && (
            <span style={{ fontSize: 11, color: "#94a3b8" }}>
              <i className="bi bi-lock-fill me-1"></i>Activate Subscription Model to edit
            </span>
          )}
        </div>
        <div className="card-body p-4">
          {/* GST common */}
          <div className="row g-3 mb-4">
            <div className="col-md-3">
              <label className="form-label small fw-semibold text-muted">GST on Subscription (%)</label>
              <div className="input-group input-group-sm">
                <span className="input-group-text fw-semibold" style={{ color: "#1a73e8" }}>%</span>
                <input type="number" step="0.5" className="form-control" value={s["sub_gst_pct"] || ""}
                  disabled={activeModel !== "subscription"}
                  onChange={e => set("sub_gst_pct", e.target.value)}
                  data-testid="input-sub_gst_pct" />
              </div>
              <div className="form-text" style={{ fontSize: 10.5 }}>GST applied on platform charge (same for all plans)</div>
            </div>
          </div>

          <div className="row g-3">
            {planCard("Daily Plan", "bi-sun-fill", "#16a34a", "#f0fdf4", subDaily, "sub_daily_charge", "sub_insurance_daily", "/day")}
            {planCard("Weekly Plan", "bi-calendar-week-fill", "#7c3aed", "#f5f3ff", subWeekly, "sub_weekly_charge", "sub_insurance_weekly", "/week")}
            {planCard("Monthly Plan", "bi-calendar-month-fill", "#1a73e8", "#e8f0fe", subMonthly, "sub_monthly_charge", "sub_insurance_monthly", "/month")}
          </div>

          <div className="mt-3 p-3 rounded-3" style={{ background: "#f0fdf4", border: "1px solid #bbf7d0" }}>
            <div className="fw-semibold mb-1" style={{ fontSize: 13, color: "#15803d" }}>
              <i className="bi bi-check-circle-fill me-1"></i>How Subscription Works for Drivers
            </div>
            <div style={{ fontSize: 12, color: "#166534" }}>
              Driver subscribes to Daily / Weekly / Monthly plan → Pays (Platform Charge + GST + Insurance) → Rides all day/week/month without per-ride deductions → Keeps 100% of every ride fare.
            </div>
            <div className="mt-2 d-flex gap-4 flex-wrap" style={{ fontSize: 11.5 }}>
              <span style={{ color: "#1a73e8" }}><strong>Daily:</strong> ₹{subDaily.total.toFixed(0)} driver pays → earns 100% all day</span>
              <span style={{ color: "#7c3aed" }}><strong>Weekly:</strong> ₹{subWeekly.total.toFixed(0)} driver pays → earns 100% all week</span>
              <span style={{ color: "#16a34a" }}><strong>Monthly:</strong> ₹{subMonthly.total.toFixed(0)} driver pays → earns 100% all month</span>
            </div>
          </div>
        </div>
      </div>

      {/* PER-SERVICE MODEL OVERRIDE */}
      <div className="card border-0 shadow-sm mb-4" style={{ borderRadius: 14 }}>
        <div className="card-header bg-white py-3 px-4" style={{ borderBottom: "1px solid #f1f5f9", borderRadius: "14px 14px 0 0" }}>
          <SectionHeader icon="bi-sliders" title="Per-Service Model Settings" bg="#f0fdf4" color="#16a34a"
            badge={{ label: "Independent Control", bg: "#dcfce7", color: "#166534" }} />
        </div>
        <div className="card-body p-4">
          <div className="mb-2" style={{ fontSize: 12.5, color: "#64748b" }}>
            <i className="bi bi-info-circle me-1"></i>Override the global model for individual services. Each service can independently use Commission or Subscription.
          </div>
          <div className="row g-3 mt-1">
            {/* Rides */}
            <div className="col-md-6">
              <div className="p-3 rounded-3" style={{ border: "1.5px solid #e2e8f0", background: "#f8fafc" }}>
                <div className="d-flex align-items-center gap-2 mb-3">
                  <div className="rounded-2 d-flex align-items-center justify-content-center" style={{ width: 30, height: 30, background: "#e8f0fe", color: "#1a73e8", fontSize: 14 }}>
                    <i className="bi bi-car-front-fill"></i>
                  </div>
                  <div className="fw-semibold" style={{ fontSize: 13 }}>Rides Service</div>
                </div>
                <div className="d-flex gap-2">
                  {(["commission", "subscription"] as Model[]).map(m => (
                    <button key={m}
                      className={`btn btn-sm flex-fill ${(s["rides_model"] || activeModel) === m ? (m === "commission" ? "btn-warning" : "btn-primary") : "btn-outline-secondary"}`}
                      style={{ fontSize: 11 }}
                      onClick={() => set("rides_model", m)}
                      data-testid={`btn-rides-${m}`}>
                      <i className={`bi ${m === "commission" ? "bi-percent" : "bi-card-checklist"} me-1`}></i>
                      {m.charAt(0).toUpperCase() + m.slice(1)}
                    </button>
                  ))}
                </div>
                <div className="mt-2 text-muted" style={{ fontSize: 11 }}>
                  Currently: <strong className={(s["rides_model"] || activeModel) === "commission" ? "text-warning" : "text-primary"}>
                    {((s["rides_model"] || activeModel) === "commission" ? "Commission" : "Subscription")} Model
                  </strong>
                </div>
              </div>
            </div>
            {/* Parcels */}
            <div className="col-md-6">
              <div className="p-3 rounded-3" style={{ border: "1.5px solid #e2e8f0", background: "#f8fafc" }}>
                <div className="d-flex align-items-center gap-2 mb-3">
                  <div className="rounded-2 d-flex align-items-center justify-content-center" style={{ width: 30, height: 30, background: "#fef9c3", color: "#ca8a04", fontSize: 14 }}>
                    <i className="bi bi-box-fill"></i>
                  </div>
                  <div className="fw-semibold" style={{ fontSize: 13 }}>Parcels Service</div>
                </div>
                <div className="d-flex gap-2">
                  {(["commission", "subscription"] as Model[]).map(m => (
                    <button key={m}
                      className={`btn btn-sm flex-fill ${(s["parcels_model"] || activeModel) === m ? (m === "commission" ? "btn-warning" : "btn-primary") : "btn-outline-secondary"}`}
                      style={{ fontSize: 11 }}
                      onClick={() => set("parcels_model", m)}
                      data-testid={`btn-parcels-${m}`}>
                      <i className={`bi ${m === "commission" ? "bi-percent" : "bi-card-checklist"} me-1`}></i>
                      {m.charAt(0).toUpperCase() + m.slice(1)}
                    </button>
                  ))}
                </div>
                <div className="mt-2 text-muted" style={{ fontSize: 11 }}>
                  Currently: <strong className={(s["parcels_model"] || activeModel) === "commission" ? "text-warning" : "text-primary"}>
                    {((s["parcels_model"] || activeModel) === "commission" ? "Commission" : "Subscription")} Model
                  </strong>
                </div>
              </div>
            </div>
            {/* Cargo */}
            <div className="col-md-6">
              <div className="p-3 rounded-3" style={{ border: "1.5px solid #e2e8f0", background: "#f8fafc" }}>
                <div className="d-flex align-items-center gap-2 mb-3">
                  <div className="rounded-2 d-flex align-items-center justify-content-center" style={{ width: 30, height: 30, background: "#f0fdf4", color: "#16a34a", fontSize: 14 }}>
                    <i className="bi bi-truck"></i>
                  </div>
                  <div className="fw-semibold" style={{ fontSize: 13 }}>Cargo & Freight</div>
                </div>
                <div className="d-flex gap-2">
                  {(["commission", "subscription"] as Model[]).map(m => (
                    <button key={m}
                      className={`btn btn-sm flex-fill ${(s["cargo_model"] || activeModel) === m ? (m === "commission" ? "btn-warning" : "btn-primary") : "btn-outline-secondary"}`}
                      style={{ fontSize: 11 }}
                      onClick={() => set("cargo_model", m)}
                      data-testid={`btn-cargo-${m}`}>
                      <i className={`bi ${m === "commission" ? "bi-percent" : "bi-card-checklist"} me-1`}></i>
                      {m.charAt(0).toUpperCase() + m.slice(1)}
                    </button>
                  ))}
                </div>
                <div className="mt-2 text-muted" style={{ fontSize: 11 }}>
                  Currently: <strong className={(s["cargo_model"] || activeModel) === "commission" ? "text-warning" : "text-primary"}>
                    {((s["cargo_model"] || activeModel) === "commission" ? "Commission" : "Subscription")} Model
                  </strong>
                </div>
              </div>
            </div>
            {/* Intercity */}
            <div className="col-md-6">
              <div className="p-3 rounded-3" style={{ border: "1.5px solid #e2e8f0", background: "#f8fafc" }}>
                <div className="d-flex align-items-center gap-2 mb-3">
                  <div className="rounded-2 d-flex align-items-center justify-content-center" style={{ width: 30, height: 30, background: "#eff6ff", color: "#2563eb", fontSize: 14 }}>
                    <i className="bi bi-map"></i>
                  </div>
                  <div className="fw-semibold" style={{ fontSize: 13 }}>Intercity Rides</div>
                </div>
                <div className="d-flex gap-2">
                  {(["commission", "subscription"] as Model[]).map(m => (
                    <button key={m}
                      className={`btn btn-sm flex-fill ${(s["intercity_model"] || activeModel) === m ? (m === "commission" ? "btn-warning" : "btn-primary") : "btn-outline-secondary"}`}
                      style={{ fontSize: 11 }}
                      onClick={() => set("intercity_model", m)}
                      data-testid={`btn-intercity-${m}`}>
                      <i className={`bi ${m === "commission" ? "bi-percent" : "bi-card-checklist"} me-1`}></i>
                      {m.charAt(0).toUpperCase() + m.slice(1)}
                    </button>
                  ))}
                </div>
                <div className="mt-2 text-muted" style={{ fontSize: 11 }}>
                  Currently: <strong className={(s["intercity_model"] || activeModel) === "commission" ? "text-warning" : "text-primary"}>
                    {((s["intercity_model"] || activeModel) === "commission" ? "Commission" : "Subscription")} Model
                  </strong>
                </div>
              </div>
            </div>
          </div>

          {/* Auto-lock threshold + Launch Campaign */}
          <div className="row g-3 mt-2">
            <div className="col-md-4">
              <div className="p-3 rounded-3" style={{ border: "1.5px solid #fecaca", background: "#fff5f5" }}>
                <label className="form-label small fw-semibold mb-1" style={{ color: "#991b1b" }}>
                  <i className="bi bi-lock-fill me-1"></i>Auto-Lock Threshold (₹)
                </label>
                <div className="input-group input-group-sm">
                  <span className="input-group-text" style={{ color: "#dc2626" }}>₹</span>
                  <input type="number" className="form-control" value={s["auto_lock_threshold"] || "-100"}
                    onChange={e => set("auto_lock_threshold", e.target.value)}
                    data-testid="input-auto-lock-threshold" />
                </div>
                <div className="form-text" style={{ fontSize: 10.5, color: "#ef4444" }}>
                  Driver auto-locked when wallet balance drops below this value (typically -₹100)
                </div>
              </div>
            </div>

            {/* Launch Campaign toggle */}
            <div className="col-md-5">
              <div className="p-3 rounded-3 h-100" style={{ border: "1.5px solid #bbf7d0", background: "#f0fdf4" }}>
                <div className="d-flex align-items-center gap-2 mb-2">
                  <div className="rounded-2 d-flex align-items-center justify-content-center flex-shrink-0"
                    style={{ width: 32, height: 32, background: "#dcfce7", color: "#16a34a", fontSize: 16 }}>
                    🎉
                  </div>
                  <span className="fw-semibold" style={{ fontSize: 14, color: "#15803d" }}>Launch Campaign</span>
                  <span className={`badge rounded-pill ms-auto ${s["launch_campaign_enabled"] === "false" ? "bg-secondary" : "bg-success"}`}
                    style={{ fontSize: 10 }}>
                    {s["launch_campaign_enabled"] === "false" ? "OFF" : "ON"}
                  </span>
                </div>
                <p className="mb-2" style={{ fontSize: 11.5, color: "#166534" }}>
                  When enabled, newly approved drivers receive <strong>30 days free access</strong> — no commission, no platform fee.
                </p>
                <div className="d-flex gap-2">
                  <button
                    className={`btn btn-sm flex-fill ${s["launch_campaign_enabled"] !== "false" ? "btn-success" : "btn-outline-secondary"}`}
                    style={{ fontSize: 12 }}
                    onClick={() => set("launch_campaign_enabled", "true")}
                    data-testid="btn-launch-campaign-on">
                    <i className="bi bi-toggle-on me-1"></i>Enable
                  </button>
                  <button
                    className={`btn btn-sm flex-fill ${s["launch_campaign_enabled"] === "false" ? "btn-danger" : "btn-outline-secondary"}`}
                    style={{ fontSize: 12 }}
                    onClick={() => set("launch_campaign_enabled", "false")}
                    data-testid="btn-launch-campaign-off">
                    <i className="bi bi-toggle-off me-1"></i>Disable
                  </button>
                </div>
                <div className="form-text mt-1" style={{ fontSize: 10.5, color: "#166534" }}>
                  Disabling this immediately stops free-period benefits for all drivers.
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Save */}
      <div className="d-flex align-items-center gap-3 pb-2">
        <button className="btn btn-primary px-5"
          disabled={!dirty || saveMutation.isPending}
          onClick={() => saveMutation.mutate(s)}
          data-testid="btn-save-revenue-model">
          {saveMutation.isPending
            ? <><span className="spinner-border spinner-border-sm me-2"></span>Saving…</>
            : <><i className="bi bi-save me-2"></i>Save Revenue Model Settings</>}
        </button>
        {dirty && (
          <span className="text-warning d-flex align-items-center gap-1" style={{ fontSize: 12 }}>
            <i className="bi bi-exclamation-triangle-fill"></i>Unsaved changes
          </span>
        )}
        {!dirty && !saveMutation.isPending && (
          <span className="text-success d-flex align-items-center gap-1" style={{ fontSize: 12 }}>
            <i className="bi bi-check-circle-fill"></i>All saved
          </span>
        )}
      </div>
    </div>
  );
}
