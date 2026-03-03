import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { useState, useEffect } from "react";
import { apiRequest } from "@/lib/queryClient";
import { useToast } from "@/hooks/use-toast";

type Setting = { keyName: string; value: string; settingsType: string };

const settingGroups = [
  {
    title: "Business Information",
    icon: "bi-building-fill",
    type: "business",
    fields: [
      { key: "business_name", label: "Business Name" },
      { key: "business_email", label: "Business Email" },
      { key: "business_phone", label: "Business Phone" },
      { key: "business_address", label: "Business Address" },
    ],
  },
  {
    title: "Currency & Region",
    icon: "bi-currency-rupee",
    type: "currency",
    fields: [
      { key: "currency_code", label: "Currency Code" },
      { key: "currency_symbol", label: "Currency Symbol" },
      { key: "country_code", label: "Country Code" },
    ],
  },
  {
    title: "Trip Settings",
    icon: "bi-car-front-fill",
    type: "trip",
    fields: [
      { key: "max_search_radius", label: "Max Search Radius (km)" },
      { key: "driver_cancel_limit", label: "Driver Cancel Limit" },
      { key: "customer_cancel_limit", label: "Customer Cancel Limit" },
    ],
  },
  {
    title: "Payment Gateway",
    icon: "bi-credit-card-2-front-fill",
    type: "payment",
    fields: [
      { key: "razorpay_key_id", label: "Razorpay Key ID" },
      { key: "razorpay_key_secret", label: "Razorpay Key Secret" },
      { key: "payment_gateway_mode", label: "Mode (test / live)" },
      { key: "fast2sms_api_key", label: "Fast2SMS API Key (OTP)" },
    ],
  },
  {
    title: "App Configuration",
    icon: "bi-phone-fill",
    type: "app",
    fields: [
      { key: "customer_app_version", label: "Customer App Version" },
      { key: "driver_app_version", label: "Driver App Version" },
      { key: "force_update", label: "Force Update (true / false)" },
      { key: "maintenance_mode", label: "Maintenance Mode (true / false)" },
    ],
  },
  {
    title: "Referral & Wallet",
    icon: "bi-wallet2",
    type: "referral",
    fields: [
      { key: "referral_bonus_driver", label: "Driver Referral Bonus (₹)" },
      { key: "referral_bonus_customer", label: "Customer Referral Bonus (₹)" },
      { key: "min_wallet_withdrawal", label: "Min Withdrawal Amount (₹)" },
      { key: "max_wallet_recharge", label: "Max Recharge Amount (₹)" },
    ],
  },
];

export default function Settings() {
  const { toast } = useToast();
  const qc = useQueryClient();
  const [formData, setFormData] = useState<Record<string, string>>({});
  const [activeGroup, setActiveGroup] = useState("business");

  const { data: settings, isLoading } = useQuery<Setting[]>({
    queryKey: ["/api/settings"],
    queryFn: () => fetch("/api/settings").then(r => r.json()),
  });

  useEffect(() => {
    if (settings) {
      const obj: Record<string, string> = {};
      settings.forEach(s => { obj[s.keyName] = s.value; });
      setFormData(obj);
    }
  }, [settings]);

  const save = useMutation({
    mutationFn: (data: Record<string, string>) => apiRequest("POST", "/api/settings", { settings: data }),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["/api/settings"] });
      toast({ title: "Settings saved successfully" });
    },
    onError: () => toast({ title: "Error saving settings", variant: "destructive" }),
  });

  const activeGroupData = settingGroups.find(g => g.type === activeGroup);

  return (
    <div className="container-fluid">
      <h2 className="fs-22 mb-4 text-capitalize" data-testid="page-title">System Settings</h2>

      <div className="row g-4">
        <div className="col-lg-3">
          <div className="card">
            <div className="card-body p-2">
              <ul className="nav flex-column">
                {settingGroups.map(g => (
                  <li key={g.type} className="nav-item">
                    <button
                      className={`nav-link w-100 text-start d-flex align-items-center gap-2 ${activeGroup === g.type ? "active bg-primary text-white rounded" : "text-muted"}`}
                      style={{ border: "none", background: "none", padding: "0.625rem 0.75rem" }}
                      onClick={() => setActiveGroup(g.type)}
                      data-testid={`settings-tab-${g.type}`}
                    >
                      <i className={`bi ${g.icon}`}></i>
                      <span>{g.title}</span>
                    </button>
                  </li>
                ))}
              </ul>
            </div>
          </div>
        </div>

        <div className="col-lg-9">
          {activeGroupData && (
            <div className="card">
              <div className="card-header d-flex align-items-center gap-2">
                <i className={`bi ${activeGroupData.icon} text-primary`}></i>
                <h6 className="mb-0">{activeGroupData.title}</h6>
              </div>
              <div className="card-body">
                {isLoading ? (
                  <div className="d-flex justify-content-center py-4">
                    <div className="spinner-border text-primary" role="status"></div>
                  </div>
                ) : (
                  <div className="row g-3">
                    {activeGroupData.fields.map(field => (
                      <div key={field.key} className="col-md-6">
                        <label className="form-label fw-semibold fs-14">{field.label}</label>
                        <input
                          type="text"
                          className="form-control"
                          value={formData[field.key] || ""}
                          onChange={e => setFormData(prev => ({ ...prev, [field.key]: e.target.value }))}
                          data-testid={`setting-${field.key}`}
                        />
                      </div>
                    ))}
                    <div className="col-12 mt-3">
                      <button
                        className="btn btn-primary"
                        onClick={() => save.mutate(formData)}
                        disabled={save.isPending}
                        data-testid="btn-save-settings"
                      >
                        {save.isPending ? (
                          <><span className="spinner-border spinner-border-sm me-2"></span>Saving...</>
                        ) : (
                          <><i className="bi bi-floppy-fill me-2"></i>Save Changes</>
                        )}
                      </button>
                    </div>
                  </div>
                )}
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
