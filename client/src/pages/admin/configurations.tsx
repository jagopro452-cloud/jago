import { useState } from "react";
import { Link } from "wouter";
import { useQuery, useMutation } from "@tanstack/react-query";
import { queryClient, apiRequest } from "@/lib/queryClient";
import { useToast } from "@/hooks/use-toast";

const PAGE_TABS = [
  { label: "Business Info", href: "/admin/business-setup" },
  { label: "Pages & Media", href: "/admin/pages-media" },
  { label: "Configurations", href: "/admin/configurations" },
  { label: "System Settings", href: "/admin/settings" },
];

const CONFIG_TABS = [
  { id: "otp", label: "OTP Setup", icon: "bi-shield-lock-fill", color: "#dc2626", bg: "#fee2e2" },
  { id: "payment", label: "Payment Gateway", icon: "bi-credit-card-fill", color: "#1a73e8", bg: "#e8f0fe" },
  { id: "commission", label: "Commission", icon: "bi-percent", color: "#d97706", bg: "#fef9c3" },
  { id: "features", label: "Features", icon: "bi-toggles", color: "#16a34a", bg: "#f0fdf4" },
  { id: "firebase", label: "Firebase & SMS", icon: "bi-bell-fill", color: "#f97316", bg: "#fff7ed" },
  { id: "maps", label: "Google Maps", icon: "bi-map-fill", color: "#7c3aed", bg: "#f5f3ff" },
];

function Toggle({ label, desc, value, onChange, id }: any) {
  return (
    <div className="d-flex align-items-center justify-content-between"
      style={{ padding: "14px 0", borderBottom: "1px solid #f1f5f9" }}>
      <div style={{ flex: 1, paddingRight: 24 }}>
        <div style={{ fontSize: 13.5, fontWeight: 600, color: "#0f172a" }}>{label}</div>
        {desc && <div style={{ fontSize: 12, color: "#94a3b8", marginTop: 2 }}>{desc}</div>}
      </div>
      <label className="switcher mb-0">
        <input type="checkbox" className="switcher_input"
          checked={value === "true" || value === true}
          onChange={e => onChange(e.target.checked ? "true" : "false")}
          data-testid={`toggle-${id}`} />
        <span className="switcher_control"></span>
      </label>
    </div>
  );
}

function Field({ label, desc, value, onChange, type = "text", placeholder, suffix, id }: any) {
  return (
    <div style={{ padding: "14px 0", borderBottom: "1px solid #f1f5f9" }}>
      <div style={{ fontSize: 13, fontWeight: 600, color: "#0f172a", marginBottom: 6 }}>{label}</div>
      {desc && <div style={{ fontSize: 11.5, color: "#94a3b8", marginBottom: 8 }}>{desc}</div>}
      <div className="input-group">
        <input type={type} className="admin-form-control"
          value={value || ""} onChange={e => onChange(e.target.value)}
          placeholder={placeholder || ""} data-testid={`input-${id}`}
          style={{ fontSize: 13 }} />
        {suffix && <span className="input-group-text" style={{ fontSize: 12 }}>{suffix}</span>}
      </div>
    </div>
  );
}

function NumberField({ label, desc, value, onChange, min, max, suffix, id }: any) {
  return (
    <div className="d-flex align-items-center justify-content-between"
      style={{ padding: "14px 0", borderBottom: "1px solid #f1f5f9" }}>
      <div style={{ flex: 1, paddingRight: 24 }}>
        <div style={{ fontSize: 13.5, fontWeight: 600, color: "#0f172a" }}>{label}</div>
        {desc && <div style={{ fontSize: 12, color: "#94a3b8", marginTop: 2 }}>{desc}</div>}
      </div>
      <div className="input-group" style={{ width: 130 }}>
        <input type="number" min={min} max={max} className="admin-form-control text-center"
          value={value || ""} onChange={e => onChange(e.target.value)}
          style={{ fontSize: 15, fontWeight: 700, padding: "6px 10px" }}
          data-testid={`input-${id}`} />
        {suffix && <span className="input-group-text fw-semibold">{suffix}</span>}
      </div>
    </div>
  );
}

export default function ConfigurationsPage() {
  const { toast } = useToast();
  const [tab, setTab] = useState("otp");
  const [local, setLocal] = useState<Record<string, string>>({});

  const { data: settingsData = [] } = useQuery<any[]>({
    queryKey: ["/api/business-settings"],
    queryFn: () => fetch("/api/business-settings").then(r => r.json()),
  });

  const arr = Array.isArray(settingsData) ? settingsData : [];
  const dbMap: Record<string, string> = {};
  arr.forEach((s: any) => { dbMap[s.keyName] = s.value; });

  const get = (key: string) => local[key] !== undefined ? local[key] : (dbMap[key] ?? "");
  const set = (key: string) => (val: string) => setLocal(p => ({ ...p, [key]: val }));

  const hasChanges = Object.keys(local).length > 0;

  const save = useMutation({
    mutationFn: () => apiRequest("PUT", "/api/business-settings", local),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["/api/business-settings"] });
      setLocal({});
      toast({ title: "Settings saved successfully" });
    },
    onError: () => toast({ title: "Failed to save settings", variant: "destructive" }),
  });

  const curTab = CONFIG_TABS.find(t => t.id === tab)!;

  return (
    <div className="container-fluid">
      {/* Header */}
      <div className="d-flex align-items-center justify-content-between mb-4">
        <div>
          <h4 className="fw-bold mb-0">Configurations</h4>
          <div className="text-muted small">OTP setup, payment gateway, commission rates and feature toggles</div>
        </div>
        {hasChanges && (
          <button className="btn btn-primary" onClick={() => save.mutate()} disabled={save.isPending}
            data-testid="btn-save-settings">
            {save.isPending
              ? <><span className="spinner-border spinner-border-sm me-2"></span>Saving…</>
              : <><i className="bi bi-save-fill me-1"></i>Save Changes ({Object.keys(local).length})</>}
          </button>
        )}
      </div>

      {/* Page-level tabs */}
      <div className="card border-0 shadow-sm mb-4" style={{ borderRadius: 14 }}>
        <div className="card-header bg-white py-3 px-4" style={{ borderBottom: "1px solid #f1f5f9" }}>
          <ul className="nav nav--tabs p-1 rounded bg-light">
            {PAGE_TABS.map(t => (
              <li key={t.href} className="nav-item">
                <Link href={t.href} className={`nav-link${t.href === "/admin/configurations" ? " active" : ""}`}>
                  {t.label}
                </Link>
              </li>
            ))}
          </ul>
        </div>
      </div>

      {/* Config section tabs — horizontal, icon-based */}
      <div className="row g-2 mb-4">
        {CONFIG_TABS.map(ct => (
          <div key={ct.id} className="col-6 col-md-4 col-xl-2">
            <button
              onClick={() => setTab(ct.id)}
              className="w-100 text-start border-0"
              style={{
                background: tab === ct.id ? ct.color : "#fff",
                color: tab === ct.id ? "#fff" : "#475569",
                borderRadius: 12,
                padding: "12px 14px",
                cursor: "pointer",
                boxShadow: tab === ct.id ? `0 4px 14px ${ct.color}44` : "0 1px 4px rgba(0,0,0,0.07)",
                transition: "all .15s",
                border: `1.5px solid ${tab === ct.id ? ct.color : "#e2e8f0"}`,
              }}
              data-testid={`tab-config-${ct.id}`}>
              <div className="d-flex align-items-center gap-2 mb-1">
                <div style={{
                  width: 28, height: 28, borderRadius: 8,
                  background: tab === ct.id ? "rgba(255,255,255,0.2)" : ct.bg,
                  color: tab === ct.id ? "#fff" : ct.color,
                  display: "flex", alignItems: "center", justifyContent: "center",
                  fontSize: 13, flexShrink: 0,
                }}>
                  <i className={`bi ${ct.icon}`}></i>
                </div>
                <span style={{ fontSize: 12, fontWeight: 700, lineHeight: 1.2 }}>{ct.label}</span>
              </div>
            </button>
          </div>
        ))}
      </div>

      {/* Section header */}
      <div className="d-flex align-items-center gap-3 mb-3">
        <div style={{
          width: 42, height: 42, borderRadius: 12,
          background: curTab.bg, color: curTab.color,
          display: "flex", alignItems: "center", justifyContent: "center", fontSize: 18,
        }}>
          <i className={`bi ${curTab.icon}`}></i>
        </div>
        <div>
          <h5 className="fw-bold mb-0">{curTab.label}</h5>
          <div style={{ fontSize: 12, color: "#94a3b8" }}>
            {tab === "otp" && "Configure OTP verification for rides and parcels"}
            {tab === "payment" && "Setup Razorpay, Cash and Wallet payment methods"}
            {tab === "commission" && "Platform fees for B2C rides and B2B deliveries"}
            {tab === "features" && "Enable or disable platform features instantly"}
            {tab === "firebase" && "Push notifications and SMS gateway settings"}
            {tab === "maps" && "Google Maps API for location and routing"}
          </div>
        </div>
      </div>

      <div className="card border-0 shadow-sm" style={{ borderRadius: 14 }}>
        <div className="card-body p-4">

          {/* ===== OTP SETUP ===== */}
          {tab === "otp" && (
            <div>
              <div className="d-flex gap-2 mb-4 p-3 rounded-3" style={{ background: "#fef9c3", border: "1px solid #fde047" }}>
                <i className="bi bi-info-circle-fill text-warning mt-1" style={{ fontSize: 13, flexShrink: 0 }}></i>
                <div style={{ fontSize: 12.5, color: "#713f12" }}>
                  OTP verification ensures the right passenger gets into the right vehicle. Enable both pickup and drop OTP for maximum security.
                </div>
              </div>

              <Toggle label="Pickup OTP Verification" id="otp_pickup"
                desc="Driver asks customer to share OTP when reaching pickup location"
                value={get("otp_pickup_enabled")} onChange={set("otp_pickup_enabled")} />

              <Toggle label="Drop-off OTP Verification" id="otp_drop"
                desc="Customer enters OTP at destination before trip ends"
                value={get("otp_drop_enabled")} onChange={set("otp_drop_enabled")} />

              <NumberField label="OTP Length (digits)" id="otp_length"
                desc="Number of digits in OTP code — 4 digits recommended"
                value={get("otp_length")} onChange={set("otp_length")} min={4} max={8} suffix="digits" />

              <div className="row g-3 mt-2">
                {[
                  { key: "otp_pickup_enabled", label: "Pickup OTP", icon: "bi-geo-alt-fill", desc: "When driver arrives" },
                  { key: "otp_drop_enabled", label: "Drop OTP", icon: "bi-flag-fill", desc: "When trip ends" },
                ].map(card => {
                  const isOn = get(card.key) === "true";
                  return (
                    <div key={card.key} className="col-6">
                      <div className="card border-0" style={{
                        borderRadius: 12, padding: 16,
                        background: isOn ? "#f0fdf4" : "#f8fafc",
                        border: `1.5px solid ${isOn ? "#86efac" : "#e2e8f0"}`,
                      }}>
                        <div className="d-flex align-items-center gap-2 mb-1">
                          <i className={`bi ${card.icon}`} style={{ color: isOn ? "#16a34a" : "#94a3b8", fontSize: 16 }}></i>
                          <div style={{ fontSize: 13, fontWeight: 700, color: isOn ? "#166534" : "#475569" }}>{card.label}</div>
                        </div>
                        <div style={{ fontSize: 11.5, color: isOn ? "#16a34a" : "#94a3b8" }}>{card.desc}</div>
                        <div className="mt-2">
                          <span className="badge" style={{
                            background: isOn ? "#16a34a" : "#e2e8f0",
                            color: isOn ? "#fff" : "#475569",
                            fontSize: 10, padding: "3px 8px",
                          }}>
                            {isOn ? "ENABLED" : "DISABLED"}
                          </span>
                        </div>
                      </div>
                    </div>
                  );
                })}
              </div>
            </div>
          )}

          {/* ===== PAYMENT GATEWAY ===== */}
          {tab === "payment" && (
            <div>
              {/* Cash & Wallet */}
              <div className="mb-4">
                <div style={{ fontSize: 13, fontWeight: 700, color: "#64748b", textTransform: "uppercase", letterSpacing: ".5px", marginBottom: 8 }}>
                  Basic Payment Methods
                </div>
                <Toggle label="Cash Payment" id="cash_enabled"
                  desc="Allow customers to pay in cash after the trip"
                  value={get("cash_enabled")} onChange={set("cash_enabled")} />
                <Toggle label="Wallet Payment" id="wallet_enabled"
                  desc="Allow customers to pay from JAGO in-app wallet"
                  value={get("wallet_enabled")} onChange={set("wallet_enabled")} />
              </div>

              {/* Razorpay */}
              <div style={{ border: "1.5px solid #e2e8f0", borderRadius: 14, padding: 20, marginBottom: 16 }}>
                <div className="d-flex align-items-center justify-content-between mb-3">
                  <div className="d-flex align-items-center gap-3">
                    <div style={{ width: 42, height: 42, borderRadius: 10, background: "#1a73e808", border: "1.5px solid #e2e8f0", display: "flex", alignItems: "center", justifyContent: "center" }}>
                      <span style={{ fontWeight: 900, fontSize: 15, color: "#1a73e8" }}>R</span>
                    </div>
                    <div>
                      <div style={{ fontSize: 14, fontWeight: 700, color: "#0f172a" }}>Razorpay</div>
                      <div style={{ fontSize: 11.5, color: "#94a3b8" }}>India's leading payment gateway</div>
                    </div>
                  </div>
                  <label className="switcher mb-0">
                    <input type="checkbox" className="switcher_input"
                      checked={get("razorpay_enabled") === "true"}
                      onChange={e => set("razorpay_enabled")(e.target.checked ? "true" : "false")}
                      data-testid="toggle-razorpay" />
                    <span className="switcher_control"></span>
                  </label>
                </div>

                {/* Mode toggle */}
                <div className="d-flex gap-2 mb-3">
                  {["test", "live"].map(mode => (
                    <button key={mode}
                      onClick={() => set("razorpay_mode")(mode)}
                      className="btn btn-sm"
                      style={{
                        borderRadius: 8, fontSize: 12, fontWeight: 700,
                        background: get("razorpay_mode") === mode ? (mode === "live" ? "#16a34a" : "#d97706") : "#f8fafc",
                        color: get("razorpay_mode") === mode ? "#fff" : "#64748b",
                        border: `1.5px solid ${get("razorpay_mode") === mode ? (mode === "live" ? "#16a34a" : "#d97706") : "#e2e8f0"}`,
                        padding: "5px 16px",
                      }}
                      data-testid={`btn-razorpay-${mode}`}>
                      {mode === "test" ? "Test Mode" : "Live Mode"}
                    </button>
                  ))}
                  {get("razorpay_mode") === "test" && (
                    <span className="badge align-self-center" style={{ background: "#fef9c3", color: "#713f12", fontSize: 10 }}>
                      Payments will not be charged in Test mode
                    </span>
                  )}
                  {get("razorpay_mode") === "live" && (
                    <span className="badge align-self-center" style={{ background: "#f0fdf4", color: "#166534", fontSize: 10 }}>
                      Real payments will be charged
                    </span>
                  )}
                </div>

                <div className="row g-3">
                  <div className="col-12 col-md-6">
                    <label style={{ fontSize: 12, fontWeight: 700, color: "#475569", marginBottom: 6, display: "block" }}>
                      Key ID <span className="text-danger">*</span>
                      <span style={{ fontWeight: 400, color: "#94a3b8", marginLeft: 6 }}>
                        (rzp_{get("razorpay_mode") === "live" ? "live" : "test"}_XXXX)
                      </span>
                    </label>
                    <input className="admin-form-control"
                      value={get("razorpay_key_id")} onChange={e => set("razorpay_key_id")(e.target.value)}
                      placeholder={`rzp_${get("razorpay_mode") === "live" ? "live" : "test"}_xxxxxxxxxxxxxxxx`}
                      data-testid="input-razorpay-key-id" style={{ fontSize: 12, fontFamily: "monospace" }} />
                  </div>
                  <div className="col-12 col-md-6">
                    <label style={{ fontSize: 12, fontWeight: 700, color: "#475569", marginBottom: 6, display: "block" }}>
                      Key Secret <span className="text-danger">*</span>
                    </label>
                    <input type="password" className="admin-form-control"
                      value={get("razorpay_key_secret")} onChange={e => set("razorpay_key_secret")(e.target.value)}
                      placeholder="Enter secret key"
                      data-testid="input-razorpay-secret" style={{ fontSize: 12 }} />
                  </div>
                </div>

                <div className="mt-3 p-3 rounded-3" style={{ background: "#f8fafc", border: "1px solid #e2e8f0" }}>
                  <div style={{ fontSize: 12, fontWeight: 700, color: "#475569", marginBottom: 6 }}>
                    <i className="bi bi-info-circle me-1"></i>How to get Razorpay keys:
                  </div>
                  <ol style={{ fontSize: 11.5, color: "#64748b", margin: 0, paddingLeft: 16 }}>
                    <li>Login to <strong>dashboard.razorpay.com</strong></li>
                    <li>Go to Settings → API Keys</li>
                    <li>Click <strong>Generate Test/Live Key</strong></li>
                    <li>Copy Key ID and Secret, paste here</li>
                  </ol>
                </div>
              </div>

              {get("razorpay_enabled") !== "true" && (
                <div className="d-flex gap-2 p-3 rounded-3" style={{ background: "#f0f9ff", border: "1px solid #bae6fd" }}>
                  <i className="bi bi-lightbulb-fill text-info mt-1" style={{ fontSize: 13, flexShrink: 0 }}></i>
                  <div style={{ fontSize: 12, color: "#0c4a6e" }}>
                    Enable Razorpay toggle above to accept UPI, Cards, Net Banking, and EMI payments. Currently only Cash and Wallet payments are active.
                  </div>
                </div>
              )}
            </div>
          )}

          {/* ===== COMMISSION ===== */}
          {tab === "commission" && (
            <div>
              <div className="row g-3 mb-4">
                {[
                  { key: "platform_commission_b2c", label: "B2C Commission", desc: "Customer rides (Bike, Auto, Car, SUV)", color: "#1a73e8", bg: "#e8f0fe" },
                  { key: "platform_commission_b2b", label: "B2B Commission", desc: "Porter and business deliveries", color: "#7c3aed", bg: "#f5f3ff" },
                  { key: "driver_payout_pct", label: "Driver Payout", desc: "Driver gets this % of fare", color: "#16a34a", bg: "#f0fdf4" },
                ].map(card => (
                  <div key={card.key} className="col-12 col-md-4">
                    <div style={{ borderRadius: 14, background: card.bg, border: `1.5px solid ${card.color}22`, padding: 20, textAlign: "center" }}>
                      <div style={{ fontSize: 12, color: "#64748b", marginBottom: 8, fontWeight: 600 }}>{card.label}</div>
                      <div style={{ display: "flex", alignItems: "center", justifyContent: "center", gap: 4 }}>
                        <input type="number" min="0" max="100" step="0.5"
                          className="admin-form-control text-center"
                          style={{ width: 80, fontSize: 28, fontWeight: 900, color: card.color, border: "none", background: "transparent", padding: "4px 0" }}
                          value={get(card.key)} onChange={e => set(card.key)(e.target.value)}
                          data-testid={`input-${card.key}`} />
                        <span style={{ fontSize: 24, fontWeight: 900, color: card.color }}>%</span>
                      </div>
                      <div style={{ fontSize: 11, color: "#94a3b8", marginTop: 6 }}>{card.desc}</div>
                    </div>
                  </div>
                ))}
              </div>

              <NumberField label="Driver Search Radius (km)" id="driver_search_radius"
                desc="How far to search for available drivers from pickup location"
                value={get("driver_search_radius")} onChange={set("driver_search_radius")}
                min={1} max={50} suffix="km" />

              <NumberField label="Ride Request Timeout (sec)" id="ride_request_timeout"
                desc="Seconds before ride request expires if no driver accepts"
                value={get("ride_request_timeout")} onChange={set("ride_request_timeout")}
                min={10} max={120} suffix="sec" />

              <NumberField label="Surge Multiplier Cap" id="surge_max_multiplier"
                desc="Maximum allowed surge pricing multiplier (e.g. 3 = 3× normal fare)"
                value={get("surge_max_multiplier") || "3"} onChange={set("surge_max_multiplier")}
                min={1} max={10} suffix="×" />
            </div>
          )}

          {/* ===== FEATURES ===== */}
          {tab === "features" && (
            <div>
              <div className="row g-3 mb-4">
                {[
                  { key: "intercity_enabled", label: "Intercity Car Sharing", icon: "bi-signpost-2-fill", color: "#1a73e8" },
                  { key: "car_sharing_enabled", label: "City Car Sharing", icon: "bi-people-fill", color: "#7c3aed" },
                  { key: "parcel_subscription_enabled", label: "Parcel Subscriptions", icon: "bi-box-seam-fill", color: "#16a34a" },
                  { key: "ride_subscription_enabled", label: "Ride Subscriptions", icon: "bi-car-front-fill", color: "#d97706" },
                  { key: "surge_pricing_enabled", label: "Surge Pricing", icon: "bi-lightning-charge-fill", color: "#dc2626" },
                  { key: "otp_pickup_enabled", label: "Pickup OTP", icon: "bi-shield-check-fill", color: "#0891b2" },
                  { key: "otp_drop_enabled", label: "Drop OTP", icon: "bi-shield-fill", color: "#0891b2" },
                  { key: "cash_enabled", label: "Cash Payments", icon: "bi-cash-coin", color: "#16a34a" },
                  { key: "wallet_enabled", label: "Wallet Payments", icon: "bi-wallet-fill", color: "#7c3aed" },
                ].map(item => {
                  const isOn = get(item.key) === "true";
                  return (
                    <div key={item.key} className="col-6 col-md-4">
                      <div style={{
                        borderRadius: 12, padding: "12px 14px",
                        background: isOn ? item.color + "10" : "#f8fafc",
                        border: `1.5px solid ${isOn ? item.color + "33" : "#e2e8f0"}`,
                      }}>
                        <div className="d-flex align-items-center justify-content-between mb-1">
                          <div className="d-flex align-items-center gap-2">
                            <i className={`bi ${item.icon}`} style={{ fontSize: 14, color: isOn ? item.color : "#94a3b8" }}></i>
                            <span style={{ fontSize: 12, fontWeight: 600, color: isOn ? "#0f172a" : "#64748b" }}>{item.label}</span>
                          </div>
                        </div>
                        <label className="switcher">
                          <input type="checkbox" className="switcher_input"
                            checked={isOn}
                            onChange={e => set(item.key)(e.target.checked ? "true" : "false")}
                            data-testid={`toggle-feature-${item.key}`} />
                          <span className="switcher_control"></span>
                        </label>
                      </div>
                    </div>
                  );
                })}
              </div>
            </div>
          )}

          {/* ===== FIREBASE & SMS ===== */}
          {tab === "firebase" && (
            <div>
              <div style={{ fontSize: 13, fontWeight: 700, color: "#64748b", textTransform: "uppercase", letterSpacing: ".5px", marginBottom: 12 }}>
                Firebase Push Notifications
              </div>

              <Field label="Firebase Server Key" id="firebase_server_key"
                desc="Found in Firebase Console → Project Settings → Cloud Messaging → Server key"
                value={get("firebase_server_key")} onChange={set("firebase_server_key")}
                type="password" placeholder="AAAAxxxxxxxx:APA91b..." />

              <Field label="Firebase Project ID" id="firebase_project_id"
                desc="Found in Firebase Console → Project Settings → General → Project ID"
                value={get("firebase_project_id")} onChange={set("firebase_project_id")}
                placeholder="jago-app-xxxxx" />

              <div style={{ height: 24 }} />
              <div style={{ fontSize: 13, fontWeight: 700, color: "#64748b", textTransform: "uppercase", letterSpacing: ".5px", marginBottom: 12 }}>
                SMS Gateway
              </div>

              <div style={{ padding: "14px 0", borderBottom: "1px solid #f1f5f9" }}>
                <div style={{ fontSize: 13.5, fontWeight: 600, color: "#0f172a", marginBottom: 8 }}>SMS Provider</div>
                <div className="d-flex gap-2">
                  {["msg91", "twilio", "nexmo"].map(p => (
                    <button key={p}
                      onClick={() => set("sms_provider")(p)}
                      style={{
                        borderRadius: 8, fontSize: 12, fontWeight: 700,
                        background: get("sms_provider") === p ? "#1a73e8" : "#f8fafc",
                        color: get("sms_provider") === p ? "#fff" : "#64748b",
                        border: `1.5px solid ${get("sms_provider") === p ? "#1a73e8" : "#e2e8f0"}`,
                        padding: "7px 18px", cursor: "pointer",
                      }}
                      data-testid={`btn-sms-${p}`}>
                      {p.toUpperCase()}
                    </button>
                  ))}
                </div>
              </div>

              <Field label="SMS API Key" id="sms_api_key"
                desc={`API key for ${(get("sms_provider") || "MSG91").toUpperCase()} SMS gateway`}
                value={get("sms_api_key")} onChange={set("sms_api_key")}
                type="password" placeholder="Enter SMS API key" />

              <div className="mt-3 p-3 rounded-3" style={{ background: "#f0f9ff", border: "1px solid #bae6fd" }}>
                <div style={{ fontSize: 12, fontWeight: 700, color: "#0369a1", marginBottom: 4 }}>
                  <i className="bi bi-phone-fill me-1"></i>SMS is used for OTP delivery
                </div>
                <div style={{ fontSize: 11.5, color: "#0c4a6e" }}>
                  Make sure SMS gateway is configured before enabling OTP verification. Without it, customers won't receive OTP codes.
                </div>
              </div>
            </div>
          )}

          {/* ===== GOOGLE MAPS ===== */}
          {tab === "maps" && (
            <div>
              <div className="d-flex gap-3 mb-4 p-3 rounded-3" style={{ background: "#f5f3ff", border: "1px solid #c4b5fd" }}>
                <i className="bi bi-map-fill text-purple mt-1" style={{ fontSize: 18, color: "#7c3aed", flexShrink: 0 }}></i>
                <div>
                  <div style={{ fontSize: 13, fontWeight: 700, color: "#4c1d95" }}>Google Maps API</div>
                  <div style={{ fontSize: 12, color: "#6d28d9" }}>Used for pickup/drop location selection, distance calculation, and routing in the Flutter app.</div>
                </div>
              </div>

              <Field label="Google Maps API Key" id="google_maps_key"
                desc="Enable Maps SDK for Android, iOS and Places API in Google Cloud Console"
                value={get("google_maps_key")} onChange={set("google_maps_key")}
                type="password" placeholder="AIzaSy..." />

              <div className="mt-3 p-3 rounded-3" style={{ background: "#f8fafc", border: "1px solid #e2e8f0" }}>
                <div style={{ fontSize: 12, fontWeight: 700, color: "#475569", marginBottom: 6 }}>
                  <i className="bi bi-info-circle me-1"></i>Required APIs to enable in Google Cloud:
                </div>
                <div className="row g-2">
                  {["Maps SDK for Android", "Maps SDK for iOS", "Places API", "Directions API", "Distance Matrix API", "Geocoding API"].map(api => (
                    <div key={api} className="col-6 col-md-4">
                      <div style={{ fontSize: 11.5, color: "#64748b", display: "flex", alignItems: "center", gap: 6 }}>
                        <i className="bi bi-check-circle-fill text-success" style={{ fontSize: 10 }}></i>
                        {api}
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            </div>
          )}

        </div>
      </div>

      {/* Bottom save bar */}
      {hasChanges && (
        <div style={{
          position: "fixed", bottom: 24, right: 24, left: "auto", zIndex: 999,
          background: "#0f172a", borderRadius: 14, padding: "14px 20px",
          display: "flex", alignItems: "center", gap: 12,
          boxShadow: "0 8px 32px rgba(0,0,0,0.3)",
        }}>
          <div style={{ fontSize: 13, color: "#94a3b8" }}>
            <span style={{ color: "#fff", fontWeight: 700 }}>{Object.keys(local).length}</span> unsaved changes
          </div>
          <button className="btn btn-sm" style={{ background: "#475569", color: "#fff", borderRadius: 8, fontSize: 12, border: "none" }}
            onClick={() => setLocal({})}>Discard</button>
          <button className="btn btn-sm btn-primary" style={{ borderRadius: 8, fontSize: 12 }}
            onClick={() => save.mutate()} disabled={save.isPending}
            data-testid="btn-save-float">
            {save.isPending ? "Saving…" : "Save Changes"}
          </button>
        </div>
      )}
    </div>
  );
}
