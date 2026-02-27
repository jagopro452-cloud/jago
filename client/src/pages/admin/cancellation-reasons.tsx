import { useState } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { Card, CardContent } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Skeleton } from "@/components/ui/skeleton";
import { Plus, Trash2, XCircle } from "lucide-react";
import { apiRequest } from "@/lib/queryClient";
import { useToast } from "@/hooks/use-toast";

export default function CancellationReasonsPage() {
  const { toast } = useToast();
  const qc = useQueryClient();
  const [open, setOpen] = useState(false);
  const [form, setForm] = useState({ reason: "", userType: "customer" });

  const { data, isLoading } = useQuery<any[]>({ queryKey: ["/api/cancellation-reasons"] });

  const save = useMutation({
    mutationFn: (data: any) => apiRequest("POST", "/api/cancellation-reasons", data),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["/api/cancellation-reasons"] });
      toast({ title: "Reason added" });
      setOpen(false); setForm({ reason: "", userType: "customer" });
    },
  });

  const remove = useMutation({
    mutationFn: (id: string) => apiRequest("DELETE", `/api/cancellation-reasons/${id}`),
    onSuccess: () => { qc.invalidateQueries({ queryKey: ["/api/cancellation-reasons"] }); toast({ title: "Reason deleted" }); },
  });

  const customerReasons = data?.filter(r => r.userType === "customer") || [];
  const driverReasons = data?.filter(r => r.userType === "driver") || [];

  return (
    <div className="space-y-5">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold" data-testid="page-title">Cancellation Reasons</h1>
          <p className="text-sm text-muted-foreground mt-0.5">{data?.length || 0} reasons configured</p>
        </div>
        <Button onClick={() => setOpen(true)} data-testid="btn-add-reason"><Plus className="w-4 h-4 mr-2" />Add Reason</Button>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        {[{ title: "Customer Reasons", reasons: customerReasons, type: "customer" },
          { title: "Driver Reasons", reasons: driverReasons, type: "driver" }].map(group => (
          <Card key={group.type}>
            <CardContent className="p-0">
              <div className="p-4 border-b font-semibold text-sm">{group.title}</div>
              {isLoading ? (
                <div className="p-4 space-y-2">{Array(3).fill(0).map((_, i) => <Skeleton key={i} className="h-10" />)}</div>
              ) : group.reasons.length ? (
                <ul className="divide-y">
                  {group.reasons.map((r: any) => (
                    <li key={r.id} className="flex items-center justify-between px-4 py-3 hover:bg-muted/20" data-testid={`reason-${r.id}`}>
                      <span className="text-sm">{r.reason}</span>
                      <Button size="icon" variant="ghost" className="h-7 w-7 text-destructive" onClick={() => remove.mutate(r.id)} data-testid={`btn-delete-reason-${r.id}`}>
                        <Trash2 className="w-3.5 h-3.5" />
                      </Button>
                    </li>
                  ))}
                </ul>
              ) : (
                <div className="text-center py-8 text-muted-foreground text-sm">
                  <XCircle className="w-8 h-8 mx-auto mb-2 opacity-30" />No reasons added
                </div>
              )}
            </CardContent>
          </Card>
        ))}
      </div>

      <Dialog open={open} onOpenChange={setOpen}>
        <DialogContent>
          <DialogHeader><DialogTitle>Add Cancellation Reason</DialogTitle></DialogHeader>
          <div className="space-y-4 pt-2">
            <div className="space-y-2">
              <Label>User Type</Label>
              <Select value={form.userType} onValueChange={v => setForm(f => ({ ...f, userType: v }))}>
                <SelectTrigger><SelectValue /></SelectTrigger>
                <SelectContent>
                  <SelectItem value="customer">Customer</SelectItem>
                  <SelectItem value="driver">Driver</SelectItem>
                </SelectContent>
              </Select>
            </div>
            <div className="space-y-2">
              <Label>Reason</Label>
              <Input value={form.reason} onChange={e => setForm(f => ({ ...f, reason: e.target.value }))}
                placeholder="e.g. Driver not arriving" data-testid="input-reason" />
            </div>
            <div className="flex gap-3 justify-end">
              <Button variant="outline" onClick={() => setOpen(false)}>Cancel</Button>
              <Button onClick={() => save.mutate(form)} disabled={!form.reason || save.isPending} data-testid="btn-save-reason">
                {save.isPending ? "Saving..." : "Add Reason"}
              </Button>
            </div>
          </div>
        </DialogContent>
      </Dialog>
    </div>
  );
}
