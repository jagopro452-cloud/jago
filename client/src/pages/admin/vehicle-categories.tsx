import { useState } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Skeleton } from "@/components/ui/skeleton";
import { Plus, Pencil, Trash2, Car } from "lucide-react";
import { apiRequest } from "@/lib/queryClient";
import { useToast } from "@/hooks/use-toast";

export default function VehicleCategories() {
  const { toast } = useToast();
  const qc = useQueryClient();
  const [open, setOpen] = useState(false);
  const [editing, setEditing] = useState<any>(null);
  const [form, setForm] = useState({ name: "", type: "ride" });

  const { data, isLoading } = useQuery<any[]>({ queryKey: ["/api/vehicle-categories"] });

  const save = useMutation({
    mutationFn: (data: any) => editing
      ? apiRequest("PUT", `/api/vehicle-categories/${editing.id}`, data)
      : apiRequest("POST", "/api/vehicle-categories", data),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["/api/vehicle-categories"] });
      toast({ title: editing ? "Category updated" : "Category created" });
      setOpen(false); setEditing(null); setForm({ name: "", type: "ride" });
    },
    onError: (e: any) => toast({ title: "Error", description: e.message, variant: "destructive" }),
  });

  const remove = useMutation({
    mutationFn: (id: string) => apiRequest("DELETE", `/api/vehicle-categories/${id}`),
    onSuccess: () => { qc.invalidateQueries({ queryKey: ["/api/vehicle-categories"] }); toast({ title: "Deleted" }); },
  });

  const openCreate = () => { setEditing(null); setForm({ name: "", type: "ride" }); setOpen(true); };
  const openEdit = (cat: any) => { setEditing(cat); setForm({ name: cat.name, type: cat.type || "ride" }); setOpen(true); };

  return (
    <div className="space-y-5">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold" data-testid="page-title">Vehicle Categories</h1>
          <p className="text-sm text-muted-foreground mt-0.5">{data?.length || 0} categories</p>
        </div>
        <Button onClick={openCreate} data-testid="btn-add-category"><Plus className="w-4 h-4 mr-2" />Add Category</Button>
      </div>

      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4">
        {isLoading ? Array(4).fill(0).map((_, i) => <Card key={i}><CardContent className="p-5"><Skeleton className="h-20" /></CardContent></Card>)
          : data?.map((cat: any) => (
            <Card key={cat.id} data-testid={`category-card-${cat.id}`}>
              <CardContent className="p-5">
                <div className="flex items-start justify-between mb-3">
                  <div className="w-12 h-12 rounded-xl bg-blue-50 dark:bg-blue-900/20 flex items-center justify-center">
                    <Car className="w-6 h-6 text-blue-600" />
                  </div>
                  <div className="flex gap-1">
                    <Button size="icon" variant="ghost" className="h-7 w-7" onClick={() => openEdit(cat)} data-testid={`btn-edit-${cat.id}`}>
                      <Pencil className="w-3.5 h-3.5" />
                    </Button>
                    <Button size="icon" variant="ghost" className="h-7 w-7 text-destructive" onClick={() => remove.mutate(cat.id)} data-testid={`btn-delete-${cat.id}`}>
                      <Trash2 className="w-3.5 h-3.5" />
                    </Button>
                  </div>
                </div>
                <h3 className="font-semibold text-foreground">{cat.name}</h3>
                <div className="flex items-center gap-2 mt-2">
                  <span className="text-xs bg-muted text-muted-foreground px-2 py-0.5 rounded-full capitalize">{cat.type}</span>
                  <span className={`text-xs px-2 py-0.5 rounded-full ${cat.isActive ? "bg-green-100 text-green-700" : "bg-red-100 text-red-700"}`}>
                    {cat.isActive ? "Active" : "Inactive"}
                  </span>
                </div>
              </CardContent>
            </Card>
          ))}
      </div>

      <Dialog open={open} onOpenChange={setOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>{editing ? "Edit Category" : "Add Vehicle Category"}</DialogTitle>
          </DialogHeader>
          <div className="space-y-4 pt-2">
            <div className="space-y-2">
              <Label>Category Name</Label>
              <Input value={form.name} onChange={e => setForm(f => ({ ...f, name: e.target.value }))}
                placeholder="e.g. Bike, Auto, Car" data-testid="input-category-name" />
            </div>
            <div className="space-y-2">
              <Label>Type</Label>
              <Select value={form.type} onValueChange={v => setForm(f => ({ ...f, type: v }))}>
                <SelectTrigger data-testid="select-type">
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="ride">Ride</SelectItem>
                  <SelectItem value="parcel">Parcel</SelectItem>
                </SelectContent>
              </Select>
            </div>
            <div className="flex gap-3 justify-end">
              <Button variant="outline" onClick={() => setOpen(false)}>Cancel</Button>
              <Button onClick={() => save.mutate(form)} disabled={!form.name || save.isPending} data-testid="btn-save-category">
                {save.isPending ? "Saving..." : editing ? "Update" : "Create"}
              </Button>
            </div>
          </div>
        </DialogContent>
      </Dialog>
    </div>
  );
}
