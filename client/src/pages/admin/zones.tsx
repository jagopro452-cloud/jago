import { useState } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { Card, CardContent } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { Skeleton } from "@/components/ui/skeleton";
import { Plus, Pencil, Trash2, MapPin } from "lucide-react";
import { apiRequest } from "@/lib/queryClient";
import { useToast } from "@/hooks/use-toast";

export default function Zones() {
  const { toast } = useToast();
  const qc = useQueryClient();
  const [open, setOpen] = useState(false);
  const [editing, setEditing] = useState<any>(null);
  const [form, setForm] = useState({ name: "", coordinates: "" });

  const { data, isLoading } = useQuery<any[]>({ queryKey: ["/api/zones"] });

  const save = useMutation({
    mutationFn: (data: any) => editing
      ? apiRequest("PUT", `/api/zones/${editing.id}`, data)
      : apiRequest("POST", "/api/zones", data),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["/api/zones"] });
      toast({ title: editing ? "Zone updated" : "Zone created" });
      setOpen(false); setEditing(null); setForm({ name: "", coordinates: "" });
    },
    onError: (e: any) => toast({ title: "Error", description: e.message, variant: "destructive" }),
  });

  const remove = useMutation({
    mutationFn: (id: string) => apiRequest("DELETE", `/api/zones/${id}`),
    onSuccess: () => { qc.invalidateQueries({ queryKey: ["/api/zones"] }); toast({ title: "Zone deleted" }); },
  });

  const openCreate = () => { setEditing(null); setForm({ name: "", coordinates: "" }); setOpen(true); };
  const openEdit = (zone: any) => { setEditing(zone); setForm({ name: zone.name, coordinates: zone.coordinates || "" }); setOpen(true); };

  return (
    <div className="space-y-5">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold" data-testid="page-title">Service Zones</h1>
          <p className="text-sm text-muted-foreground mt-0.5">{data?.length || 0} zones configured</p>
        </div>
        <Button onClick={openCreate} data-testid="btn-add-zone"><Plus className="w-4 h-4 mr-2" />Add Zone</Button>
      </div>

      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
        {isLoading ? Array(4).fill(0).map((_, i) => <Card key={i}><CardContent className="p-5"><Skeleton className="h-20" /></CardContent></Card>)
          : data?.map((zone: any) => (
            <Card key={zone.id} data-testid={`zone-card-${zone.id}`}>
              <CardContent className="p-5">
                <div className="flex items-start justify-between mb-3">
                  <div className="w-12 h-12 rounded-xl bg-purple-50 dark:bg-purple-900/20 flex items-center justify-center">
                    <MapPin className="w-6 h-6 text-purple-600" />
                  </div>
                  <div className="flex gap-1">
                    <Button size="icon" variant="ghost" className="h-7 w-7" onClick={() => openEdit(zone)} data-testid={`btn-edit-zone-${zone.id}`}>
                      <Pencil className="w-3.5 h-3.5" />
                    </Button>
                    <Button size="icon" variant="ghost" className="h-7 w-7 text-destructive" onClick={() => remove.mutate(zone.id)} data-testid={`btn-delete-zone-${zone.id}`}>
                      <Trash2 className="w-3.5 h-3.5" />
                    </Button>
                  </div>
                </div>
                <h3 className="font-semibold text-foreground">{zone.name}</h3>
                <span className={`text-xs px-2 py-0.5 rounded-full mt-2 inline-block ${zone.isActive ? "bg-green-100 text-green-700" : "bg-red-100 text-red-700"}`}>
                  {zone.isActive ? "Active" : "Inactive"}
                </span>
              </CardContent>
            </Card>
          ))}
      </div>

      <Dialog open={open} onOpenChange={setOpen}>
        <DialogContent>
          <DialogHeader><DialogTitle>{editing ? "Edit Zone" : "Add Service Zone"}</DialogTitle></DialogHeader>
          <div className="space-y-4 pt-2">
            <div className="space-y-2">
              <Label>Zone Name</Label>
              <Input value={form.name} onChange={e => setForm(f => ({ ...f, name: e.target.value }))}
                placeholder="e.g. Hyderabad Central" data-testid="input-zone-name" />
            </div>
            <div className="flex gap-3 justify-end">
              <Button variant="outline" onClick={() => setOpen(false)}>Cancel</Button>
              <Button onClick={() => save.mutate(form)} disabled={!form.name || save.isPending} data-testid="btn-save-zone">
                {save.isPending ? "Saving..." : editing ? "Update" : "Create"}
              </Button>
            </div>
          </div>
        </DialogContent>
      </Dialog>
    </div>
  );
}
