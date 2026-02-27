import { useState } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Skeleton } from "@/components/ui/skeleton";
import { Plus, Pencil, Trash2, Tag } from "lucide-react";
import { apiRequest } from "@/lib/queryClient";
import { useToast } from "@/hooks/use-toast";

export default function Coupons() {
  const { toast } = useToast();
  const qc = useQueryClient();
  const [open, setOpen] = useState(false);
  const [editing, setEditing] = useState<any>(null);
  const [form, setForm] = useState({ name: "", code: "", discountAmount: "", discountType: "amount", minTripAmount: "", limitPerUser: "1" });

  const { data, isLoading } = useQuery<any[]>({ queryKey: ["/api/coupons"] });

  const save = useMutation({
    mutationFn: (data: any) => editing
      ? apiRequest("PUT", `/api/coupons/${editing.id}`, data)
      : apiRequest("POST", "/api/coupons", data),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["/api/coupons"] });
      toast({ title: editing ? "Coupon updated" : "Coupon created" });
      setOpen(false); setEditing(null);
      setForm({ name: "", code: "", discountAmount: "", discountType: "amount", minTripAmount: "", limitPerUser: "1" });
    },
    onError: (e: any) => toast({ title: "Error", description: e.message, variant: "destructive" }),
  });

  const remove = useMutation({
    mutationFn: (id: string) => apiRequest("DELETE", `/api/coupons/${id}`),
    onSuccess: () => { qc.invalidateQueries({ queryKey: ["/api/coupons"] }); toast({ title: "Coupon deleted" }); },
  });

  const openCreate = () => { setEditing(null); setForm({ name: "", code: "", discountAmount: "", discountType: "amount", minTripAmount: "", limitPerUser: "1" }); setOpen(true); };
  const openEdit = (c: any) => {
    setEditing(c);
    setForm({ name: c.name, code: c.code, discountAmount: String(c.discountAmount || ""), discountType: c.discountType || "amount", minTripAmount: String(c.minTripAmount || ""), limitPerUser: String(c.limitPerUser || "1") });
    setOpen(true);
  };

  return (
    <div className="space-y-5">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold" data-testid="page-title">Coupons</h1>
          <p className="text-sm text-muted-foreground mt-0.5">{data?.length || 0} coupon codes</p>
        </div>
        <Button onClick={openCreate} data-testid="btn-add-coupon"><Plus className="w-4 h-4 mr-2" />Add Coupon</Button>
      </div>

      <Card>
        <CardContent className="p-0">
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b bg-muted/30">
                  <th className="text-left px-4 py-3 font-medium text-muted-foreground">Name</th>
                  <th className="text-left px-4 py-3 font-medium text-muted-foreground">Code</th>
                  <th className="text-left px-4 py-3 font-medium text-muted-foreground">Discount</th>
                  <th className="text-left px-4 py-3 font-medium text-muted-foreground hidden md:table-cell">Min Fare</th>
                  <th className="text-left px-4 py-3 font-medium text-muted-foreground hidden lg:table-cell">Limit/User</th>
                  <th className="text-left px-4 py-3 font-medium text-muted-foreground">Status</th>
                  <th className="text-left px-4 py-3 font-medium text-muted-foreground">Actions</th>
                </tr>
              </thead>
              <tbody>
                {isLoading ? Array(4).fill(0).map((_, i) => (
                  <tr key={i} className="border-b">
                    {Array(7).fill(0).map((_, j) => <td key={j} className="px-4 py-3"><Skeleton className="h-4 w-full" /></td>)}
                  </tr>
                )) : data?.length ? data.map((c: any) => (
                  <tr key={c.id} className="border-b hover:bg-muted/20" data-testid={`coupon-row-${c.id}`}>
                    <td className="px-4 py-3 font-medium">{c.name}</td>
                    <td className="px-4 py-3"><span className="font-mono bg-muted px-2 py-0.5 rounded text-xs">{c.code}</span></td>
                    <td className="px-4 py-3">{c.discountType === "percentage" ? `${c.discountAmount}%` : `₹${c.discountAmount}`}</td>
                    <td className="px-4 py-3 hidden md:table-cell">₹{c.minTripAmount}</td>
                    <td className="px-4 py-3 hidden lg:table-cell">{c.limitPerUser}</td>
                    <td className="px-4 py-3">
                      <span className={`text-xs px-2 py-0.5 rounded-full ${c.isActive ? "bg-green-100 text-green-700" : "bg-red-100 text-red-700"}`}>
                        {c.isActive ? "Active" : "Inactive"}
                      </span>
                    </td>
                    <td className="px-4 py-3">
                      <div className="flex gap-1">
                        <Button size="icon" variant="ghost" className="h-7 w-7" onClick={() => openEdit(c)} data-testid={`btn-edit-coupon-${c.id}`}><Pencil className="w-3.5 h-3.5" /></Button>
                        <Button size="icon" variant="ghost" className="h-7 w-7 text-destructive" onClick={() => remove.mutate(c.id)} data-testid={`btn-delete-coupon-${c.id}`}><Trash2 className="w-3.5 h-3.5" /></Button>
                      </div>
                    </td>
                  </tr>
                )) : (
                  <tr><td colSpan={7} className="text-center py-12 text-muted-foreground">
                    <Tag className="w-12 h-12 mx-auto mb-3 opacity-30" />No coupons created
                  </td></tr>
                )}
              </tbody>
            </table>
          </div>
        </CardContent>
      </Card>

      <Dialog open={open} onOpenChange={setOpen}>
        <DialogContent>
          <DialogHeader><DialogTitle>{editing ? "Edit Coupon" : "Add Coupon"}</DialogTitle></DialogHeader>
          <div className="space-y-4 pt-2">
            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label>Coupon Name</Label>
                <Input value={form.name} onChange={e => setForm(f => ({ ...f, name: e.target.value }))} placeholder="e.g. Welcome Offer" data-testid="input-coupon-name" />
              </div>
              <div className="space-y-2">
                <Label>Coupon Code</Label>
                <Input value={form.code} onChange={e => setForm(f => ({ ...f, code: e.target.value.toUpperCase() }))} placeholder="e.g. WELCOME50" data-testid="input-coupon-code" />
              </div>
            </div>
            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label>Discount Type</Label>
                <Select value={form.discountType} onValueChange={v => setForm(f => ({ ...f, discountType: v }))}>
                  <SelectTrigger><SelectValue /></SelectTrigger>
                  <SelectContent>
                    <SelectItem value="amount">Fixed Amount</SelectItem>
                    <SelectItem value="percentage">Percentage</SelectItem>
                  </SelectContent>
                </Select>
              </div>
              <div className="space-y-2">
                <Label>Discount {form.discountType === "percentage" ? "%" : "₹"}</Label>
                <Input type="number" value={form.discountAmount} onChange={e => setForm(f => ({ ...f, discountAmount: e.target.value }))} data-testid="input-discount-amount" />
              </div>
            </div>
            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label>Min Trip Amount (₹)</Label>
                <Input type="number" value={form.minTripAmount} onChange={e => setForm(f => ({ ...f, minTripAmount: e.target.value }))} />
              </div>
              <div className="space-y-2">
                <Label>Limit Per User</Label>
                <Input type="number" value={form.limitPerUser} onChange={e => setForm(f => ({ ...f, limitPerUser: e.target.value }))} />
              </div>
            </div>
            <div className="flex gap-3 justify-end">
              <Button variant="outline" onClick={() => setOpen(false)}>Cancel</Button>
              <Button onClick={() => save.mutate(form)} disabled={!form.name || !form.code || save.isPending} data-testid="btn-save-coupon">
                {save.isPending ? "Saving..." : editing ? "Update" : "Create"}
              </Button>
            </div>
          </div>
        </DialogContent>
      </Dialog>
    </div>
  );
}
