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
    type: "business",
    fields: [
      { key: "currency", label: "Currency Code" },
      { key: "currency_symbol", label: "Currency Symbol" },
      { key: "country_code", label: "Country Code" },
    ],
  },
  {
    title: "Trip Settings",
    icon: "bi-car-front-fill",
    type: "trip",
    fields: [
      { key: "ride_request_timeout", label: "Ride Request Timeout (seconds)" },
      { key: "driver_search_radius", label: "Driver Search Radius (km)" },
    ],
  },
];

export default function Settings() {
  const { toast } = useToast();
  const qc = useQueryClient();
  const [values, setValues] = useState<Record<string, string>>({});

  const { data, isLoading } = useQuery<Setting[]>({ queryKey: ["/api/settings"] });

  useEffect(() => {
    if (data) {
      const map: Record<string, string> = {};
      data.forEach(s => { map[s.keyName] = s.value; });
      setValues(map);
    }
  }, [data]);

  const save = useMutation({
    mutationFn: (payload: { keyName: string; value: string; settingsType: string }[]) =>
      Promise.all(payload.map(p => apiRequest("POST", "/api/settings", p))),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["/api/settings"] });
      toast({ title: "Settings saved successfully" });
    },
    onError: () => toast({ title: "Failed to save settings", variant: "destructive" }),
  });

  const handleSave = (group: typeof settingGroups[0]) => {
    const payload = group.fields.map(f => ({
      keyName: f.key,
      value: values[f.key] || "",
      settingsType: group.type,
    }));
    save.mutate(payload);
  };

  return (
    <div>
      <div className="jago-page-header">
        <div>
          <h4 className="page-title" data-testid="page-title">Business Settings</h4>
          <div className="breadcrumb">
            <i className="bi bi-house-fill"></i>
            <span>Home</span>
            <i className="bi bi-chevron-right" style={{ fontSize: "0.65rem" }}></i>
            <span>System</span>
            <i className="bi bi-chevron-right" style={{ fontSize: "0.65rem" }}></i>
            <span>Settings</span>
          </div>
        </div>
      </div>

      <div style={{ display: "flex", flexDirection: "column", gap: "1.25rem" }}>
        {settingGroups.map(group => (
          <div key={group.title} className="jago-card">
            <div className="jago-card-header">
              <h5 className="jago-card-title">
                <i className={`bi ${group.icon}`} style={{ marginRight: "0.5rem", color: "var(--bs-primary)" }}></i>
                {group.title}
              </h5>
            </div>
            <div style={{ padding: "1.25rem" }}>
              {isLoading ? (
                <div style={{ display: "flex", flexDirection: "column", gap: "0.75rem" }}>
                  {group.fields.map(f => <div key={f.key} style={{ height: "40px", background: "#f1f5f9", borderRadius: "8px" }} />)}
                </div>
              ) : (
                <>
                  <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fill, minmax(260px, 1fr))", gap: "1rem" }}>
                    {group.fields.map(f => (
                      <div key={f.key}>
                        <label className="jago-label">{f.label}</label>
                        <input
                          className="jago-input"
                          id={f.key}
                          value={values[f.key] || ""}
                          onChange={e => setValues(v => ({ ...v, [f.key]: e.target.value }))}
                          data-testid={`input-setting-${f.key}`}
                        />
                      </div>
                    ))}
                  </div>
                  <div style={{ display: "flex", justifyContent: "flex-end", marginTop: "1rem" }}>
                    <button
                      className="btn-jago-primary"
                      onClick={() => handleSave(group)}
                      disabled={save.isPending}
                      data-testid={`btn-save-${group.type}`}
                    >
                      <i className="bi bi-floppy-fill"></i>
                      {save.isPending ? "Saving..." : `Save ${group.title}`}
                    </button>
                  </div>
                </>
              )}
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
