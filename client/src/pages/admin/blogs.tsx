import { useState } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { Card, CardContent } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { Skeleton } from "@/components/ui/skeleton";
import { Plus, Pencil, Trash2, FileText } from "lucide-react";
import { apiRequest } from "@/lib/queryClient";
import { useToast } from "@/hooks/use-toast";

export default function BlogsPage() {
  const { toast } = useToast();
  const qc = useQueryClient();
  const [open, setOpen] = useState(false);
  const [editing, setEditing] = useState<any>(null);
  const [form, setForm] = useState({ title: "", slug: "", content: "" });

  const { data, isLoading } = useQuery<any[]>({ queryKey: ["/api/blogs"] });

  const save = useMutation({
    mutationFn: (data: any) => editing
      ? apiRequest("PUT", `/api/blogs/${editing.id}`, data)
      : apiRequest("POST", "/api/blogs", data),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["/api/blogs"] });
      toast({ title: editing ? "Blog updated" : "Blog created" });
      setOpen(false); setEditing(null); setForm({ title: "", slug: "", content: "" });
    },
  });

  const remove = useMutation({
    mutationFn: (id: string) => apiRequest("DELETE", `/api/blogs/${id}`),
    onSuccess: () => { qc.invalidateQueries({ queryKey: ["/api/blogs"] }); toast({ title: "Blog deleted" }); },
  });

  const openCreate = () => { setEditing(null); setForm({ title: "", slug: "", content: "" }); setOpen(true); };
  const openEdit = (b: any) => { setEditing(b); setForm({ title: b.title, slug: b.slug || "", content: b.content || "" }); setOpen(true); };

  const makeSlug = (title: string) => title.toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-+|-+$/g, "");

  return (
    <div className="space-y-5">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold" data-testid="page-title">Blog Management</h1>
          <p className="text-sm text-muted-foreground mt-0.5">{data?.length || 0} articles</p>
        </div>
        <Button onClick={openCreate} data-testid="btn-add-blog"><Plus className="w-4 h-4 mr-2" />Add Article</Button>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        {isLoading ? Array(3).fill(0).map((_, i) => <Card key={i}><CardContent className="p-5"><Skeleton className="h-32" /></CardContent></Card>)
          : data?.length ? data.map((b: any) => (
            <Card key={b.id} data-testid={`blog-card-${b.id}`}>
              <CardContent className="p-5">
                <div className="flex items-start justify-between mb-3">
                  <div className="w-10 h-10 rounded-lg bg-blue-50 dark:bg-blue-900/20 flex items-center justify-center">
                    <FileText className="w-5 h-5 text-blue-600" />
                  </div>
                  <div className="flex gap-1">
                    <Button size="icon" variant="ghost" className="h-7 w-7" onClick={() => openEdit(b)} data-testid={`btn-edit-blog-${b.id}`}><Pencil className="w-3.5 h-3.5" /></Button>
                    <Button size="icon" variant="ghost" className="h-7 w-7 text-destructive" onClick={() => remove.mutate(b.id)} data-testid={`btn-delete-blog-${b.id}`}><Trash2 className="w-3.5 h-3.5" /></Button>
                  </div>
                </div>
                <h3 className="font-semibold text-foreground leading-snug mb-2">{b.title}</h3>
                <p className="text-xs text-muted-foreground line-clamp-2">{b.content}</p>
                <div className="flex items-center gap-2 mt-3">
                  <span className={`text-xs px-2 py-0.5 rounded-full ${b.isActive ? "bg-green-100 text-green-700" : "bg-red-100 text-red-700"}`}>
                    {b.isActive ? "Published" : "Draft"}
                  </span>
                  <span className="text-xs text-muted-foreground">{new Date(b.createdAt).toLocaleDateString("en-IN")}</span>
                </div>
              </CardContent>
            </Card>
          )) : (
            <div className="col-span-3 text-center py-16 text-muted-foreground">
              <FileText className="w-12 h-12 mx-auto mb-3 opacity-30" />No articles yet
            </div>
          )}
      </div>

      <Dialog open={open} onOpenChange={setOpen}>
        <DialogContent className="max-w-lg">
          <DialogHeader><DialogTitle>{editing ? "Edit Article" : "New Article"}</DialogTitle></DialogHeader>
          <div className="space-y-4 pt-2">
            <div className="space-y-2">
              <Label>Title</Label>
              <Input value={form.title} onChange={e => setForm(f => ({ ...f, title: e.target.value, slug: makeSlug(e.target.value) }))} placeholder="Article title" data-testid="input-blog-title" />
            </div>
            <div className="space-y-2">
              <Label>Slug</Label>
              <Input value={form.slug} onChange={e => setForm(f => ({ ...f, slug: e.target.value }))} placeholder="article-slug" data-testid="input-blog-slug" />
            </div>
            <div className="space-y-2">
              <Label>Content</Label>
              <Textarea value={form.content} onChange={e => setForm(f => ({ ...f, content: e.target.value }))}
                placeholder="Write your article content..." rows={6} data-testid="input-blog-content" />
            </div>
            <div className="flex gap-3 justify-end">
              <Button variant="outline" onClick={() => setOpen(false)}>Cancel</Button>
              <Button onClick={() => save.mutate(form)} disabled={!form.title || save.isPending} data-testid="btn-save-blog">
                {save.isPending ? "Saving..." : editing ? "Update" : "Publish"}
              </Button>
            </div>
          </div>
        </DialogContent>
      </Dialog>
    </div>
  );
}
