import { useQuery, useMutation } from "@tanstack/react-query";
import { queryClient, apiRequest } from "@/lib/queryClient";
import { useState } from "react";
import { useToast } from "@/hooks/use-toast";

export default function EmployeesPage() {
  const { toast } = useToast();
  const [showModal, setShowModal] = useState(false);
  const [editing, setEditing] = useState<any>(null);
  const [form, setForm] = useState({ name: "", email: "", phone: "", role: "employee", isActive: true });

  const { data, isLoading } = useQuery<any[]>({ queryKey: ["/api/employees"] });
  const employees = Array.isArray(data) ? data : [];

  const saveMutation = useMutation({
    mutationFn: (payload: any) =>
      editing ? apiRequest("PUT", `/api/employees/${editing.id}`, payload) : apiRequest("POST", "/api/employees", payload),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["/api/employees"] });
      setShowModal(false);
      toast({ title: editing ? "Employee updated" : "Employee created" });
      setEditing(null);
    },
    onError: () => toast({ title: "Failed to save", variant: "destructive" }),
  });

  const deleteMutation = useMutation({
    mutationFn: (id: string) => apiRequest("DELETE", `/api/employees/${id}`),
    onSuccess: () => { queryClient.invalidateQueries({ queryKey: ["/api/employees"] }); toast({ title: "Deleted" }); },
  });

  const toggleMutation = useMutation({
    mutationFn: ({ id, isActive }: any) => apiRequest("PUT", `/api/employees/${id}`, { isActive }),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ["/api/employees"] }),
  });

  const openAdd = () => { setEditing(null); setForm({ name: "", email: "", phone: "", role: "employee", isActive: true }); setShowModal(true); };
  const openEdit = (e: any) => { setEditing(e); setForm({ name: e.name, email: e.email, phone: e.phone || "", role: e.role, isActive: e.isActive }); setShowModal(true); };

  return (
    <>
    
      <div className="content-header">
        <div className="container-fluid">
          <div className="d-flex align-items-center justify-content-between gap-3 flex-wrap mb-3">
            <h2 className="h5 mb-0">Employee Setup</h2>
            <button className="btn btn-primary btn-sm" onClick={openAdd} data-testid="btn-add-employee">
              <i className="bi bi-plus me-1"></i>Add Employee
            </button>
          </div>
        </div>
      </div>
      <div className="container-fluid">
        <div className="card">
          <div className="card-body">
            <div className="table-responsive">
              <table className="table table-borderless align-middle table-hover">
                <thead className="table-light">
                  <tr>
                    <th>#</th>
                    <th>Name</th>
                    <th>Email</th>
                    <th>Phone</th>
                    <th>Role</th>
                    <th>Status</th>
                    <th>Action</th>
                  </tr>
                </thead>
                <tbody>
                  {isLoading ? (
                    <tr><td colSpan={7} className="text-center py-4"><div className="spinner-border spinner-border-sm" role="status" /></td></tr>
                  ) : employees.length === 0 ? (
                    <tr>
                      <td colSpan={7} className="text-center py-5 text-muted">
                        <i className="bi bi-person-square fs-2 d-block mb-2 opacity-25"></i>
                        No employees found. Click Add Employee to create one.
                      </td>
                    </tr>
                  ) : employees.map((e: any, idx: number) => (
                    <tr key={e.id} data-testid={`row-employee-${e.id}`}>
                      <td>{idx + 1}</td>
                      <td className="fw-semibold">{e.name}</td>
                      <td>{e.email}</td>
                      <td>{e.phone || "—"}</td>
                      <td className="text-capitalize">{e.role}</td>
                      <td>
                        <label className="switcher">
                          <input className="switcher_input" type="checkbox" checked={e.isActive} onChange={ev => toggleMutation.mutate({ id: e.id, isActive: ev.target.checked })} />
                          <span className="switcher_control"></span>
                        </label>
                      </td>
                      <td>
                        <button className="btn btn-sm btn-outline-primary me-1" onClick={() => openEdit(e)}><i className="bi bi-pencil-fill"></i></button>
                        <button className="btn btn-sm btn-outline-danger" onClick={() => { if (confirm("Delete?")) deleteMutation.mutate(e.id); }}><i className="bi bi-trash-fill"></i></button>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        </div>
      </div>

      {showModal && (
        <div className="modal fade show d-block" style={{ background: "rgba(0,0,0,0.5)" }}>
          <div className="modal-dialog">
            <div className="modal-content">
              <div className="modal-header">
                <h5 className="modal-title">{editing ? "Edit Employee" : "Add Employee"}</h5>
                <button className="btn-close" onClick={() => setShowModal(false)} />
              </div>
              <div className="modal-body">
                <div className="mb-3">
                  <label className="form-label fw-semibold">Full Name <span className="text-danger">*</span></label>
                  <input className="form-control" value={form.name} onChange={e => setForm({ ...form, name: e.target.value })} data-testid="input-employee-name" />
                </div>
                <div className="mb-3">
                  <label className="form-label fw-semibold">Email <span className="text-danger">*</span></label>
                  <input className="form-control" type="email" value={form.email} onChange={e => setForm({ ...form, email: e.target.value })} data-testid="input-employee-email" />
                </div>
                <div className="mb-3">
                  <label className="form-label fw-semibold">Phone</label>
                  <input className="form-control" value={form.phone} onChange={e => setForm({ ...form, phone: e.target.value })} data-testid="input-employee-phone" />
                </div>
                <div className="mb-3">
                  <label className="form-label fw-semibold">Role</label>
                  <select className="form-select" value={form.role} onChange={e => setForm({ ...form, role: e.target.value })} data-testid="select-employee-role">
                    <option value="employee">Employee</option>
                    <option value="manager">Manager</option>
                    <option value="admin">Admin</option>
                  </select>
                </div>
              </div>
              <div className="modal-footer">
                <button className="btn btn-light" onClick={() => setShowModal(false)}>Cancel</button>
                <button className="btn btn-primary" disabled={!form.name || !form.email || saveMutation.isPending} onClick={() => saveMutation.mutate(form)} data-testid="btn-save-employee">
                  {saveMutation.isPending ? "Saving..." : editing ? "Update" : "Create"}
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
    
    </>
  );
}
