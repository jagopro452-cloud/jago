import { useState } from "react";
import { Link } from "wouter";
import { useMutation } from "@tanstack/react-query";
import { queryClient, apiRequest } from "@/lib/queryClient";
import { useToast } from "@/hooks/use-toast";

export default function ConfigurationsPage() {
  const { toast } = useToast();
  const [activeSection, setActiveSection] = useState("notification");

  const sections = [
    { id: "notification", label: "Notification" },
    { id: "third-party", label: "3rd Party" },
    { id: "payment", label: "Payment Methods" },
    { id: "ai-setup", label: "AI Setup" },
  ];

  const tabs = [
    { label: "Business Info", href: "/admin/business-setup" },
    { label: "Pages & Media", href: "/admin/pages-media" },
    { label: "Configurations", href: "/admin/configurations" },
    { label: "System Settings", href: "/admin/settings" },
  ];

  const saveMutation = useMutation({
    mutationFn: (d: any) => apiRequest("POST", "/api/business-settings", d),
    onSuccess: () => { queryClient.invalidateQueries({ queryKey: ["/api/business-settings"] }); toast({ title: "Settings saved" }); },
    onError: () => toast({ title: "Failed to save", variant: "destructive" }),
  });

  return (
    <>
    
      <div className="content-header">
        <div className="container-fluid">
          <div className="d-flex align-items-center justify-content-between gap-3 flex-wrap mb-3">
            <h2 className="h5 mb-0">Configurations</h2>
          </div>
        </div>
      </div>
      <div className="container-fluid">
        <div className="card">
          <div className="card-header border-bottom py-3">
            <ul className="nav nav--tabs p-1 rounded bg-white">
              {tabs.map(t => (
                <li key={t.href} className="nav-item">
                  <Link href={t.href} className={`nav-link${t.href === "/admin/configurations" ? " active" : ""}`}>
                    {t.label}
                  </Link>
                </li>
              ))}
            </ul>
          </div>
          <div className="card-body">
            <div className="row g-0">
              <div className="col-md-3 border-end">
                <ul className="nav flex-column p-2">
                  {sections.map(s => (
                    <li key={s.id} className="nav-item">
                      <button
                        className={`nav-link w-100 text-start${activeSection === s.id ? " active text-primary fw-semibold" : " text-dark"}`}
                        onClick={() => setActiveSection(s.id)}
                        data-testid={`nav-config-${s.id}`}
                      >
                        {s.label}
                      </button>
                    </li>
                  ))}
                </ul>
              </div>
              <div className="col-md-9 p-4">
                {activeSection === "notification" && (
                  <div>
                    <h6 className="fw-bold mb-4">Notification Configuration</h6>
                    <div className="mb-3">
                      <label className="form-label fw-semibold">Firebase Server Key</label>
                      <input className="form-control" type="password" placeholder="Enter Firebase server key" data-testid="input-firebase-key" />
                    </div>
                    <div className="mb-3">
                      <label className="form-label fw-semibold">Firebase Project ID</label>
                      <input className="form-control" placeholder="Enter Firebase project ID" data-testid="input-firebase-project" />
                    </div>
                    <button className="btn btn-primary">Save</button>
                  </div>
                )}
                {activeSection === "third-party" && (
                  <div>
                    <h6 className="fw-bold mb-4">3rd Party API Configuration</h6>
                    <div className="mb-4">
                      <h6 className="text-muted mb-3">Google Maps</h6>
                      <div className="mb-3">
                        <label className="form-label fw-semibold">Google Maps API Key</label>
                        <input className="form-control" type="password" placeholder="Enter Google Maps API key" data-testid="input-maps-key" />
                      </div>
                    </div>
                    <div className="mb-4">
                      <h6 className="text-muted mb-3">SMS Gateway</h6>
                      <div className="mb-3">
                        <label className="form-label fw-semibold">Provider</label>
                        <select className="form-select" data-testid="select-sms-provider">
                          <option value="">Select provider</option>
                          <option value="twilio">Twilio</option>
                          <option value="nexmo">Nexmo</option>
                          <option value="msg91">MSG91</option>
                        </select>
                      </div>
                      <div className="mb-3">
                        <label className="form-label fw-semibold">API Key</label>
                        <input className="form-control" type="password" placeholder="Enter SMS API key" data-testid="input-sms-key" />
                      </div>
                    </div>
                    <button className="btn btn-primary">Save</button>
                  </div>
                )}
                {activeSection === "payment" && (
                  <div>
                    <h6 className="fw-bold mb-4">Payment Methods</h6>
                    {["Cash", "Razorpay", "Stripe", "PayU"].map(method => (
                      <div key={method} className="card mb-3">
                        <div className="card-body">
                          <div className="d-flex justify-content-between align-items-center mb-3">
                            <h6 className="mb-0">{method}</h6>
                            <label className="switcher">
                              <input className="switcher_input" type="checkbox" defaultChecked={method === "Cash"} />
                              <span className="switcher_control"></span>
                            </label>
                          </div>
                          {method !== "Cash" && (
                            <div className="row g-2">
                              <div className="col-6">
                                <input className="form-control form-control-sm" placeholder={`${method} API Key`} type="password" />
                              </div>
                              <div className="col-6">
                                <input className="form-control form-control-sm" placeholder={`${method} Secret Key`} type="password" />
                              </div>
                            </div>
                          )}
                        </div>
                      </div>
                    ))}
                    <button className="btn btn-primary">Save Payment Settings</button>
                  </div>
                )}
                {activeSection === "ai-setup" && (
                  <div>
                    <h6 className="fw-bold mb-4">AI Setup</h6>
                    <div className="mb-3">
                      <label className="form-label fw-semibold">AI Provider</label>
                      <select className="form-select" data-testid="select-ai-provider">
                        <option value="">Select AI provider</option>
                        <option value="openai">OpenAI</option>
                        <option value="gemini">Google Gemini</option>
                      </select>
                    </div>
                    <div className="mb-3">
                      <label className="form-label fw-semibold">API Key</label>
                      <input className="form-control" type="password" placeholder="Enter AI API key" data-testid="input-ai-key" />
                    </div>
                    <button className="btn btn-primary">Save AI Settings</button>
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
