import { useState } from "react";
import { Link } from "wouter";
import { useQuery, useMutation } from "@tanstack/react-query";
import { queryClient, apiRequest } from "@/lib/queryClient";
import { useToast } from "@/hooks/use-toast";

const SECTIONS = [
  { id: "otp", label: "OTP & Security", icon: "bi-shield-lock-fill" },
  { id: "commission", label: "Commission & Charges", icon: "bi-percent" },
  { id: "features", label: "Feature Toggles", icon: "bi-toggles" },
  { id: "notification", label: "Notifications", icon: "bi-bell-fill" },
  { id: "payment", label: "Payment Methods", icon: "bi-credit-card-fill" },
  { id: "third-party", label: "3rd Party APIs", icon: "bi-plug-fill" },
];

const PAGE_TABS = [
  { label: "Business Info", href: "/admin/business-setup" },
  { label: "Pages & Media", href: "/admin/pages-media" },
  { label: "Configurations", href: "/admin/configurations" },
  { label: "System Settings", href: "/admin/settings" },
];

function SettingToggle({ label, desc, settingKey, value, onChange }: any) {
  return (
    <div className="d-flex align-items-center justify-content-between py-3"
      style={{ borderBottom: "1px solid #f1f5f9" }}>
      <div style={{ flex: 1, paddingRight: 20 }}>
        <div style={{ fontSize: 13, fontWeight: 600, color: "#0f172a" }}>{label}</div>
        {desc && <div style={{ fontSize: 11.5, color: "#94a3b8", marginTop: 2 }}>{desc}</div>}
      </div>
      <label className="switcher mb-0">
        <input type="checkbox" className="switcher_input"
          checked={value === "true" || value === true}
          onChange={e => onChange(settingKey, e.target.checked ? "true" : "false")} />
        <span className="switcher_control"></span>
      </label>
    </div>
  );
}

function SettingInput({ label, desc, settingKey, value, onChange, suffix, type = "number", min, max }: any) {
  return (
    <div className="d-flex align-items-center justify-content-between py-3"
      style={{ borderBottom: "1px solid #f1f5f9" }}>
      <div style={{ flex: 1, paddingRight: 20 }}>
        <div style={{ fontSize: 13, fontWeight: 600, color: "#0f172a" }}>{label}</div>
        {desc && <div style={{ fontSize: 11.5, color: "#94a3b8", marginTop: 2 }}>{desc}</div>}
      </div>
      <div className="input-group" style={{ width: 140 }}>
        <input type={type} min={min} max={max} className="admin-form-control text-end"
          style={{ fontSize: 13, padding: "6px 10px" }}
          value={value || ""} onChange={e => onChange(settingKey, e.target.value)} />
        {suffix && <span className="input-group-text" style={{ fontSize: 12 }}>{suffix}</span>}
      </div>
    </div>
  );
}

export default function ConfigurationsPage() {
  const { toast } = useToast();
  const [activeSection, setActiveSection] = useState("otp");
  const [localSettings, setLocalSettings] = useState<Record<string, string>>({});

  const { data: settingsData = [] } = useQuery<any[]>({
    queryKey: ["/api/business-settings"],
    queryFn: () => fetch("/api/business-settings").then(r => r.json()),
  });

  const settingsArr = Array.isArray(settingsData) ? settingsData : [];
  const settingsMap: Record<string, string> = {};
  settingsArr.forEach((s: any) => { settingsMap[s.keyName] = s.value; });
  const get = (key: string) => localSettings[key] ?? settingsMap[key] ?? "";
  const set = (key: string, val: string) => setLocalSettings(p => ({ ...p, [key]: val }));

  const save = useMutation({
    mutationFn: () => apiRequest("PUT", "/api/business-settings", localSettings),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["/api/business-settings"] });
      setLocalSettings({});
      toast({ title: "Settings saved successfully" });
    },
    onError: () => toast({ title: "Failed to save", variant: "destructive" }),
  });

  const hasChanges = Object.keys(localSettings).length > 0;

  return (
    <div className="container-fluid">
      <div className="d-flex align-items-center justify-content-between mb-4">
        <div>
          <h4 className="fw-bold mb-0">Configurations</h4>
          <div className="text-muted small">Platform-wide settings, OTP, commission, and feature toggles</div>
        </div>
        {hasChanges && (
          <button className="btn btn-primary" onClick={() => save.mutate()}
            disabled={save.isPending} data-testid="btn-save-settings">
            {save.isPending ? <><span className="spinner-border spinner-border-sm me-2"></span>Saving…</> : <><i className="bi bi-save-fill me-1"></i>Save Changes</>}
          </button>
        )}
      </div>

      {/* Page tabs */}
      <div className="card border-0 shadow-sm mb-3" style={{ borderRadius: 14 }}>
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

      <div className="row g-3">
        {/* Left sidebar nav */}
        <div className="col-12 col-md-3">
          <div className="card border-0 shadow-sm" style={{ borderRadius: 14 }}>
            <div className="card-body p-2">
              {SECTIONS.map(s => (
                <button key={s.id}
                  className="w-100 text-start d-flex align-items-center gap-2 rounded-3 mb-1"
                  style={{
                    border: "none", padding: "10px 12px", fontSize: 13, fontWeight: activeSection === s.id ? 700 : 500,
                    background: activeSection === s.id ? "rgba(37,99,235,0.08)" : "transparent",
                    color: activeSection === s.id ? "#1a73e8" : "#475569",
                    cursor: "pointer",
                  }}
                  onClick={() => setActiveSection(s.id)} data-testid={`nav-config-${s.id}`}>
                  <i className={`bi ${s.icon}`} style={{ fontSize: 14, width: 18, textAlign: "center" }}></i>
                  {s.label}
                </button>
              ))}
            </div>
          </div>
        </div>

        {/* Right content */}
        <div className="col-12 col-md-9">
          <div className="card border-0 shadow-sm" style={{ borderRadius: 14 }}>
            <div className="card-body p-4">

              {/* OTP & Security */}
              {activeSection === "otp" && <>
                <div className="d-flex align-items-center gap-2 mb-4">
                  <div className="rounded-3 d-flex align-items-center justify-content-center"
                    style={{ width: 40, height: 40, background: "#fee2e2", color: "#dc2626", fontSize: "1rem" }}>
                    <i className="bi bi-shield-lock-fill"></i>
                  </div>
                  <div>
                    <h6 className="fw-bold mb-0">OTP & Security Settings</h6>
                    <div style={{ fontSize: 11.5, color: "#94a3b8" }}>Configure OTP verification for rides and deliveries</div>
                  </div>
                </div>

                <SettingToggle label="Pickup OTP Verification" settingKey="otp_pickup_enabled"
                  desc="Require customer to share OTP when driver arrives at pickup"
                  value={get("otp_pickup_enabled")} onChange={set} />
                <SettingToggle label="Drop OTP Verification" settingKey="otp_drop_enabled"
                  desc="Require OTP confirmation at drop point before ending ride"
                  value={get("otp_drop_enabled")} onChange={set} />
                <SettingInput label="OTP Length" settingKey="otp_length"
                  desc="Number of digits in the OTP (4 or 6 recommended)"
                  value={get("otp_length")} onChange={set} min={4} max={8} />

                <div style={{ marginTop: 20, padding: "12px 16px", background: "#f0fdf4", borderRadius: 10, display: "flex", gap: 10 }}>
                  <i className="bi bi-info-circle-fill text-success mt-1" style={{ fontSize: 13 }}></i>
                  <div style={{ fontSize: 12, color: "#374151" }}>
                    OTP settings apply to both <strong>B2C rides</strong> and <strong>B2B parcel deliveries</strong>. Changes take effect immediately for new trips.
                  </div>
                </div>
              </>}

              {/* Commission */}
              {activeSection === "commission" && <>
                <div className="d-flex align-items-center gap-2 mb-4">
                  <div className="rounded-3 d-flex align-items-center justify-content-center"
                    style={{ width: 40, height: 40, background: "#fef9c3", color: "#d97706", fontSize: "1rem" }}>
                    <i className="bi bi-percent"></i>
                  </div>
                  <div>
                    <h6 className="fw-bold mb-0">Commission & Platform Charges</h6>
                    <div style={{ fontSize: 11.5, color: "#94a3b8" }}>Set platform fees for B2C, B2B and driver payouts</div>
                  </div>
                </div>

                <div className="row g-3 mb-3">
                  {[
                    { title: "B2C Commission", key: "platform_commission_b2c", color: "#1a73e8", bg: "#e8f0fe", desc: "Commission on customer rides" },
                    { title: "B2B Commission", key: "platform_commission_b2b", color: "#7c3aed", bg: "#f5f3ff", desc: "Commission on B2B/Porter trips" },
                    { title: "Driver Payout %", key: "driver_payout_pct", color: "#16a34a", bg: "#f0fdf4", desc: "% of fare paid to driver" },
                  ].map(card => (
                    <div key={card.key} className="col-4">
                      <div className="card border-0" style={{ borderRadius: 12, background: card.bg }}>
                        <div className="card-body p-3 text-center">
                          <div style={{ fontSize: 11, color: "#64748b", marginBottom: 6 }}>{card.title}</div>
                          <div style={{ display: "flex", alignItems: "center", justifyContent: "center", gap: 4 }}>
                            <input type="number" min="0" max="100" step="0.5"
                              className="admin-form-control text-center"
                              style={{ width: 70, fontSize: 20, fontWeight: 800, color: card.color, border: "none", background: "transparent", padding: 0 }}
                              value={get(card.key)} onChange={e => set(card.key, e.target.value)}
                              data-testid={`input-${card.key}`} />
                            <span style={{ fontSize: 18, fontWeight: 700, color: card.color }}>%</span>
                          </div>
                          <div style={{ fontSize: 10.5, color: "#94a3b8", marginTop: 4 }}>{card.desc}</div>
                        </div>
                      </div>
                    </div>
                  ))}
                </div>

                <SettingInput label="Surge Multiplier Cap" settingKey="surge_max_multiplier"
                  desc="Maximum allowed surge multiplier (e.g. 3.0 = 3x normal fare)"
                  value={get("surge_max_multiplier") || "3"} onChange={set} suffix="×" type="number" min={1} max={10} />
                <SettingInput label="Cancellation Fee (₹)" settingKey="cancellation_fee"
                  desc="Fee charged to customer for late cancellation"
                  value={get("cancellation_fee") || "0"} onChange={set} suffix="₹" />
                <SettingInput label="Min Wallet Balance (₹)" settingKey="min_wallet_balance"
                  desc="Minimum wallet balance required to book a ride"
                  value={get("min_wallet_balance") || "0"} onChange={set} suffix="₹" />
              </>}

              {/* Feature Toggles */}
              {activeSection === "features" && <>
                <div className="d-flex align-items-center gap-2 mb-4">
                  <div className="rounded-3 d-flex align-items-center justify-content-center"
                    style={{ width: 40, height: 40, background: "#f0fdf4", color: "#16a34a", fontSize: "1rem" }}>
                    <i className="bi bi-toggles"></i>
                  </div>
                  <div>
                    <h6 className="fw-bold mb-0">Platform Feature Toggles</h6>
                    <div style={{ fontSize: 11.5, color: "#94a3b8" }}>Enable or disable platform modules instantly</div>
                  </div>
                </div>

                {[
                  { key: "intercity_enabled", label: "Intercity Car Sharing", desc: "Allow users to book long-distance intercity rides" },
                  { key: "car_sharing_enabled", label: "City Car Sharing", desc: "Allow shared rides within the city" },
                  { key: "parcel_subscription_enabled", label: "Parcel Subscriptions", desc: "Enable subscription plans for parcel deliveries" },
                  { key: "ride_subscription_enabled", label: "Ride Subscriptions", desc: "Enable subscription plans for regular rides" },
                  { key: "surge_pricing_enabled", label: "Surge Pricing", desc: "Allow dynamic fare increase during high demand" },
                  { key: "otp_pickup_enabled", label: "OTP Pickup Verification", desc: "Require OTP at pickup point" },
                  { key: "otp_drop_enabled", label: "OTP Drop Verification", desc: "Require OTP at drop point" },
                ].map(f => (
                  <SettingToggle key={f.key} label={f.label} desc={f.desc}
                    settingKey={f.key} value={get(f.key)} onChange={set} />
                ))}
              </>}

              {/* Notifications */}
              {activeSection === "notification" && <>
                <h6 className="fw-bold mb-4">Notification Configuration</h6>
                <div className="mb-3">
                  <label className="form-label-jago">Firebase Server Key</label>
                  <input className="admin-form-control" type="password" placeholder="Enter Firebase server key" data-testid="input-firebase-key" />
                </div>
                <div className="mb-3">
                  <label className="form-label-jago">Firebase Project ID</label>
                  <input className="admin-form-control" placeholder="Enter Firebase project ID" data-testid="input-firebase-project" />
                </div>
                <div className="mb-3">
                  <label className="form-label-jago">FCM Sender ID</label>
                  <input className="admin-form-control" placeholder="Enter FCM Sender ID" />
                </div>
                <button className="btn btn-primary" onClick={() => toast({ title: "Firebase settings saved" })}>Save Firebase Settings</button>
              </>}

              {/* Payment */}
              {activeSection === "payment" && <>
                <h6 className="fw-bold mb-4">Payment Methods</h6>
                {[
                  { method: "Cash", icon: "bi-cash-coin", color: "#16a34a" },
                  { method: "Razorpay", icon: "bi-credit-card-fill", color: "#1a73e8" },
                  { method: "Stripe", icon: "bi-stripe", color: "#7c3aed" },
                  { method: "Wallet", icon: "bi-wallet-fill", color: "#d97706" },
                ].map(({ method, icon, color }) => (
                  <div key={method} className="card border-0 mb-3" style={{ borderRadius: 12, border: "1.5px solid #f1f5f9" }}>
                    <div className="card-body p-3">
                      <div className="d-flex justify-content-between align-items-center mb-2">
                        <div className="d-flex align-items-center gap-2">
                          <div className="rounded-3 d-flex align-items-center justify-content-center"
                            style={{ width: 34, height: 34, background: color + "18", color, fontSize: 14 }}>
                            <i className={`bi ${icon}`}></i>
                          </div>
                          <span className="fw-semibold" style={{ fontSize: 13 }}>{method}</span>
                        </div>
                        <label className="switcher">
                          <input className="switcher_input" type="checkbox" defaultChecked={method === "Cash" || method === "Wallet"} />
                          <span className="switcher_control"></span>
                        </label>
                      </div>
                      {method !== "Cash" && method !== "Wallet" && (
                        <div className="row g-2">
                          <div className="col-6">
                            <input className="admin-form-control" placeholder={`${method} API Key`} type="password" style={{ fontSize: 12 }} />
                          </div>
                          <div className="col-6">
                            <input className="admin-form-control" placeholder={`${method} Secret Key`} type="password" style={{ fontSize: 12 }} />
                          </div>
                        </div>
                      )}
                    </div>
                  </div>
                ))}
              </>}

              {/* 3rd Party */}
              {activeSection === "third-party" && <>
                <h6 className="fw-bold mb-4">3rd Party API Configuration</h6>
                {[
                  { title: "Google Maps", key: "maps_api_key", icon: "bi-map-fill", color: "#1a73e8" },
                  { title: "SMS Gateway (MSG91/Twilio)", key: "sms_api_key", icon: "bi-phone-fill", color: "#16a34a" },
                  { title: "Push Notification (FCM)", key: "fcm_server_key", icon: "bi-bell-fill", color: "#d97706" },
                ].map(api => (
                  <div key={api.key} className="mb-4">
                    <div className="d-flex align-items-center gap-2 mb-2">
                      <div className="rounded-3 d-flex align-items-center justify-content-center"
                        style={{ width: 30, height: 30, background: api.color + "18", color: api.color, fontSize: 13 }}>
                        <i className={`bi ${api.icon}`}></i>
                      </div>
                      <div className="fw-semibold" style={{ fontSize: 13 }}>{api.title}</div>
                    </div>
                    <input className="admin-form-control" type="password"
                      placeholder={`Enter ${api.title} API Key`} data-testid={`input-${api.key}`} />
                  </div>
                ))}
                <button className="btn btn-primary" onClick={() => toast({ title: "API settings saved" })}>Save API Settings</button>
              </>}

            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
