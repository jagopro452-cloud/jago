import { useState } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Skeleton } from "@/components/ui/skeleton";
import { Plus, DollarSign } from "lucide-react";
import { apiRequest } from "@/lib/queryClient";
import { useToast } from "@/hooks/use-toast";

export default function Fares() {
  const { toast } = useToast();
  const qc = useQueryClient();
  const [open, setOpen] = useState(false);
  const [form, setForm] = useState({ zoneId: "", vehicleCategoryId: "", baseFare: "", farePerKm: "", farePerMin: "", minimumFare: "", cancellationFee: "" });

  const { data: fares, isLoading } = useQuery<any[]>({ queryKey: ["/api/fares"] });
  const { data: zones } = useQuery<any[]>({ queryKey: ["/api/zones"] });
  const { data: cats } = useQuery<any[]>({ queryKey: ["/api/vehicle-categories"] });

  const save = useMutation({
    mutationFn: (data: any) => apiRequest("POST", "/api/fares", data),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["/api/fares"] });
      toast({ title: "Fare rule saved" });
      setOpen(false);
      setForm({ zoneId: "", vehicleCategoryId: "", baseFare: "", farePerKm: "", farePerMin: "", minimumFare: "", cancellationFee: "" });
    },
  });

  return (
    <div className="space-y-5">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold" data-testid="page-title">Fare Management</h1>
          <p className="text-sm text-muted-foreground mt-0.5">Configure pricing per zone and vehicle type</p>
        </div>
        <Button onClick={() => setOpen(true)} data-testid="btn-add-fare"><Plus className="w-4 h-4 mr-2" />Add Fare Rule</Button>
      </div>

      <Card>
        <CardContent className="p-0">
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b bg-muted/30">
                  <th className="text-left px-4 py-3 font-medium text-muted-foreground">Zone</th>
                  <th className="text-left px-4 py-3 font-medium text-muted-foreground">Vehicle</th>
                  <th className="text-left px-4 py-3 font-medium text-muted-foreground">Base Fare</th>
                  <th className="text-left px-4 py-3 font-medium text-muted-foreground">Per KM</th>
                  <th className="text-left px-4 py-3 font-medium text-muted-foreground hidden md:table-cell">Per Min</th>
                  <th className="text-left px-4 py-3 font-medium text-muted-foreground hidden md:table-cell">Min Fare</th>
                  <th className="text-left px-4 py-3 font-medium text-muted-foreground hidden lg:table-cell">Cancel Fee</th>
                </tr>
              </thead>
              <tbody>
                {isLoading ? Array(4).fill(0).map((_, i) => (
                  <tr key={i} className="border-b">
                    {Array(7).fill(0).map((_, j) => <td key={j} className="px-4 py-3"><Skeleton className="h-4 w-full" /></td>)}
                  </tr>
                )) : fares?.length ? fares.map((item: any) => (
                  <tr key={item.fare.id} className="border-b hover:bg-muted/20" data-testid={`fare-row-${item.fare.id}`}>
                    <td className="px-4 py-3 font-medium">{item.zone?.name || "All Zones"}</td>
                    <td className="px-4 py-3">{item.vehicleCategory?.name || "All Vehicles"}</td>
                    <td className="px-4 py-3">₹{Number(item.fare.baseFare).toFixed(2)}</td>
                    <td className="px-4 py-3">₹{Number(item.fare.farePerKm).toFixed(2)}</td>
                    <td className="px-4 py-3 hidden md:table-cell">₹{Number(item.fare.farePerMin).toFixed(2)}</td>
                    <td className="px-4 py-3 hidden md:table-cell">₹{Number(item.fare.minimumFare).toFixed(2)}</td>
                    <td className="px-4 py-3 hidden lg:table-cell">₹{Number(item.fare.cancellationFee).toFixed(2)}</td>
                  </tr>
                )) : (
                  <tr><td colSpan={7} className="text-center py-12 text-muted-foreground">
                    <DollarSign className="w-12 h-12 mx-auto mb-3 opacity-30" />No fare rules configured
                  </td></tr>
                )}
              </tbody>
            </table>
          </div>
        </CardContent>
      </Card>

      <Dialog open={open} onOpenChange={setOpen}>
        <DialogContent>
          <DialogHeader><DialogTitle>Add Fare Rule</DialogTitle></DialogHeader>
          <div className="space-y-4 pt-2">
            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label>Zone</Label>
                <Select value={form.zoneId} onValueChange={v => setForm(f => ({ ...f, zoneId: v }))}>
                  <SelectTrigger><SelectValue placeholder="Select zone" /></SelectTrigger>
                  <SelectContent>{zones?.map(z => <SelectItem key={z.id} value={z.id}>{z.name}</SelectItem>)}</SelectContent>
                </Select>
              </div>
              <div className="space-y-2">
                <Label>Vehicle Type</Label>
                <Select value={form.vehicleCategoryId} onValueChange={v => setForm(f => ({ ...f, vehicleCategoryId: v }))}>
                  <SelectTrigger><SelectValue placeholder="Select vehicle" /></SelectTrigger>
                  <SelectContent>{cats?.map(c => <SelectItem key={c.id} value={c.id}>{c.name}</SelectItem>)}</SelectContent>
                </Select>
              </div>
            </div>
            <div className="grid grid-cols-2 gap-4">
              {[["baseFare", "Base Fare (₹)"], ["farePerKm", "Fare per KM (₹)"], ["farePerMin", "Fare per Min (₹)"], ["minimumFare", "Minimum Fare (₹)"], ["cancellationFee", "Cancellation Fee (₹)"]].map(([key, label]) => (
                <div key={key} className="space-y-2">
                  <Label>{label}</Label>
                  <Input type="number" value={(form as any)[key]} onChange={e => setForm(f => ({ ...f, [key]: e.target.value }))}
                    placeholder="0.00" data-testid={`input-${key}`} />
                </div>
              ))}
            </div>
            <div className="flex gap-3 justify-end">
              <Button variant="outline" onClick={() => setOpen(false)}>Cancel</Button>
              <Button onClick={() => save.mutate(form)} disabled={save.isPending} data-testid="btn-save-fare">
                {save.isPending ? "Saving..." : "Save Rule"}
              </Button>
            </div>
          </div>
        </DialogContent>
      </Dialog>
    </div>
  );
}
