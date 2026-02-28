import { useState } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { apiRequest } from "@/lib/queryClient";
import { useToast } from "@/hooks/use-toast";

function Modal({ open, onClose, title, children }: any) {
  if (!open) return null;
  return (
    <div style={{ position: "fixed", inset: 0, background: "rgba(0,0,0,0.4)", zIndex: 9999, display: "flex", alignItems: "center", justifyContent: "center", padding: "1rem" }}>
      <div style={{ background: "#fff", borderRadius: "12px", width: "100%", maxWidth: "560px", padding: "1.5rem", boxShadow: "0 20px 60px rgba(0,0,0,0.2)", maxHeight: "90vh", overflowY: "auto" }}>
        <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", marginBottom: "1.25rem" }}>
          <h5 style={{ margin: 0, fontWeight: 700, color: "var(--title-color)", fontSize: "1rem" }}>{title}</h5>
          <button onClick={onClose} style={{ background: "none", border: "none", cursor: "pointer", color: "var(--bs-body-color)", fontSize: "1.2rem" }}>
            <i className="bi bi-x-lg"></i>
          </button>
        </div>
        {children}
      </div>
    </div>
  );
}

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
    <div>
      <div className="jago-page-header">
        <div>
          <h4 className="page-title" data-testid="page-title">Blog Management</h4>
          <div className="breadcrumb">
            <i className="bi bi-house-fill"></i>
            <span>Home</span>
            <i className="bi bi-chevron-right" style={{ fontSize: "0.65rem" }}></i>
            <span>Promotion Management</span>
            <i className="bi bi-chevron-right" style={{ fontSize: "0.65rem" }}></i>
            <span>Blogs</span>
          </div>
        </div>
        <button className="btn-jago-primary" onClick={openCreate} data-testid="btn-add-blog">
          <i className="bi bi-plus-circle-fill"></i> Add Article
        </button>
      </div>

      <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fill, minmax(280px, 1fr))", gap: "1rem" }}>
        {isLoading ? Array(3).fill(0).map((_, i) => (
          <div key={i} className="jago-card" style={{ padding: "1.25rem" }}>
            <div style={{ height: "120px", background: "#f1f5f9", borderRadius: "8px" }} />
          </div>
        )) : data?.length ? data.map((b: any) => (
          <div key={b.id} className="jago-card" data-testid={`blog-card-${b.id}`} style={{ padding: "1.25rem" }}>
            <div style={{ display: "flex", alignItems: "flex-start", justifyContent: "space-between", marginBottom: "0.875rem" }}>
              <div style={{ width: "40px", height: "40px", borderRadius: "8px", background: "rgba(37,99,235,0.1)", display: "grid", placeItems: "center", color: "var(--bs-primary)", fontSize: "1.1rem" }}>
                <i className="bi bi-newspaper"></i>
              </div>
              <div style={{ display: "flex", gap: "0.25rem" }}>
                <button
                  style={{ background: "none", border: "none", cursor: "pointer", color: "var(--bs-primary)", padding: "0.2rem 0.4rem", borderRadius: "4px", fontSize: "0.85rem" }}
                  onClick={() => openEdit(b)}
                  data-testid={`btn-edit-blog-${b.id}`}
                >
                  <i className="bi bi-pencil-fill"></i>
                </button>
                <button
                  style={{ background: "none", border: "none", cursor: "pointer", color: "var(--bs-danger)", padding: "0.2rem 0.4rem", borderRadius: "4px", fontSize: "0.85rem" }}
                  onClick={() => { if (confirm("Delete this blog?")) remove.mutate(b.id); }}
                  data-testid={`btn-delete-blog-${b.id}`}
                >
                  <i className="bi bi-trash-fill"></i>
                </button>
              </div>
            </div>
            <h6 style={{ fontWeight: 700, color: "var(--title-color)", marginBottom: "0.5rem", lineHeight: 1.35 }}>{b.title}</h6>
            <p style={{ fontSize: "0.8rem", color: "var(--bs-body-color)", marginBottom: "0.75rem", display: "-webkit-box", WebkitLineClamp: 2, WebkitBoxOrient: "vertical", overflow: "hidden" }}>
              {b.content}
            </p>
            <div style={{ display: "flex", alignItems: "center", gap: "0.5rem" }}>
              <span className={`jago-badge ${b.isActive ? "badge-active" : "badge-inactive"}`}>
                {b.isActive ? "Published" : "Draft"}
              </span>
              <span style={{ fontSize: "0.75rem", color: "var(--bs-body-color)" }}>
                {new Date(b.createdAt).toLocaleDateString("en-IN")}
              </span>
            </div>
          </div>
        )) : (
          <div style={{ gridColumn: "1 / -1" }}>
            <div className="jago-card">
              <div className="jago-empty">
                <i className="bi bi-newspaper"></i>
                <p>No articles yet. Create your first blog post.</p>
              </div>
            </div>
          </div>
        )}
      </div>

      <Modal open={open} onClose={() => setOpen(false)} title={editing ? "Edit Article" : "New Article"}>
        <div style={{ display: "flex", flexDirection: "column", gap: "1rem" }}>
          <div>
            <label className="jago-label">Title *</label>
            <input
              className="jago-input"
              value={form.title}
              onChange={e => setForm(f => ({ ...f, title: e.target.value, slug: makeSlug(e.target.value) }))}
              placeholder="Article title"
              data-testid="input-blog-title"
            />
          </div>
          <div>
            <label className="jago-label">Slug</label>
            <input
              className="jago-input"
              value={form.slug}
              onChange={e => setForm(f => ({ ...f, slug: e.target.value }))}
              placeholder="article-slug"
              data-testid="input-blog-slug"
            />
          </div>
          <div>
            <label className="jago-label">Content</label>
            <textarea
              className="jago-input"
              value={form.content}
              onChange={e => setForm(f => ({ ...f, content: e.target.value }))}
              placeholder="Write your article content..."
              rows={6}
              style={{ resize: "vertical" }}
              data-testid="input-blog-content"
            />
          </div>
          <div style={{ display: "flex", gap: "0.75rem", justifyContent: "flex-end", marginTop: "0.5rem" }}>
            <button className="btn-jago-outline" onClick={() => setOpen(false)}>Cancel</button>
            <button
              className="btn-jago-primary"
              onClick={() => save.mutate(form)}
              disabled={!form.title || save.isPending}
              data-testid="btn-save-blog"
            >
              {save.isPending ? "Saving..." : editing ? "Update" : "Publish"}
            </button>
          </div>
        </div>
      </Modal>
    </div>
  );
}
