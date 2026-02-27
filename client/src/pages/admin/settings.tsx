import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Skeleton } from "@/components/ui/skeleton";
import { useState, useEffect } from "react";
import { apiRequest } from "@/lib/queryClient";
import { useToast } from "@/hooks/use-toast";
import { Settings as SettingsIcon, Save } from "lucide-react";

type Setting = { keyName: string; value: string; settingsType: string };

const settingGroups = [
  {
    title: "Business Information",
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
    type: "business",
    fields: [
      { key: "currency", label: "Currency Code" },
      { key: "currency_symbol", label: "Currency Symbol" },
      { key: "country_code", label: "Country Code" },
    ],
  },
  {
    title: "Trip Settings",
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
    <div className="space-y-6">
      <div className="flex items-center gap-3">
        <div>
          <h1 className="text-2xl font-bold" data-testid="page-title">Business Settings</h1>
          <p className="text-sm text-muted-foreground mt-0.5">Configure your platform settings</p>
        </div>
      </div>

      <div className="space-y-6">
        {settingGroups.map(group => (
          <Card key={group.title}>
            <CardHeader className="pb-4">
              <CardTitle className="text-base">{group.title}</CardTitle>
            </CardHeader>
            <CardContent>
              {isLoading ? (
                <div className="space-y-4">
                  {group.fields.map(f => <Skeleton key={f.key} className="h-10 w-full" />)}
                </div>
              ) : (
                <div className="space-y-4">
                  <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                    {group.fields.map(f => (
                      <div key={f.key} className="space-y-2">
                        <Label htmlFor={f.key}>{f.label}</Label>
                        <Input
                          id={f.key}
                          value={values[f.key] || ""}
                          onChange={e => setValues(v => ({ ...v, [f.key]: e.target.value }))}
                          data-testid={`input-setting-${f.key}`}
                        />
                      </div>
                    ))}
                  </div>
                  <div className="flex justify-end pt-2">
                    <Button
                      onClick={() => handleSave(group)}
                      disabled={save.isPending}
                      className="gap-2"
                      data-testid={`btn-save-${group.type}`}
                    >
                      <Save className="w-4 h-4" />
                      Save {group.title}
                    </Button>
                  </div>
                </div>
              )}
            </CardContent>
          </Card>
        ))}
      </div>
    </div>
  );
}
