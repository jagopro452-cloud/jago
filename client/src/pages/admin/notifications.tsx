import { useState } from "react";
import { useMutation } from "@tanstack/react-query";
import { apiRequest } from "@/lib/queryClient";
import { useToast } from "@/hooks/use-toast";

export default function NotificationsPage() {
  const { toast } = useToast();
  const [form, setForm] = useState({ title: "", message: "", target: "all", userType: "customer" });

  const sendMutation = useMutation({
    mutationFn: (payload: any) => apiRequest("POST", "/api/notifications/send", payload),
    onSuccess: () => {
      toast({ title: "Notification sent successfully" });
      setForm({ title: "", message: "", target: "all", userType: "customer" });
    },
    onError: () => toast({ title: "Failed to send notification", variant: "destructive" }),
  });

  return (
    <>
    
      <div className="content-header">
        <div className="container-fluid">
          <div className="d-flex align-items-center justify-content-between gap-3 flex-wrap mb-3">
            <h2 className="h5 mb-0">Send Notification</h2>
          </div>
        </div>
      </div>
      <div className="container-fluid">
        <div className="row">
          <div className="col-lg-6">
            <div className="card">
              <div className="card-header border-bottom py-3">
                <h5 className="card-title mb-0">Push Notification</h5>
              </div>
              <div className="card-body">
                <div className="mb-3">
                  <label className="form-label fw-semibold">Target Users</label>
                  <select className="form-select" value={form.target} onChange={e => setForm({ ...form, target: e.target.value })} data-testid="select-target">
                    <option value="all">All Users</option>
                    <option value="customer">Customers Only</option>
                    <option value="driver">Drivers Only</option>
                  </select>
                </div>
                <div className="mb-3">
                  <label className="form-label fw-semibold">Notification Title <span className="text-danger">*</span></label>
                  <input
                    className="form-control"
                    value={form.title}
                    onChange={e => setForm({ ...form, title: e.target.value })}
                    placeholder="Enter title"
                    data-testid="input-notif-title"
                  />
                </div>
                <div className="mb-3">
                  <label className="form-label fw-semibold">Message <span className="text-danger">*</span></label>
                  <textarea
                    className="form-control"
                    rows={4}
                    value={form.message}
                    onChange={e => setForm({ ...form, message: e.target.value })}
                    placeholder="Enter notification message"
                    data-testid="input-notif-message"
                  />
                </div>
                <button
                  className="btn btn-primary w-100"
                  disabled={!form.title || !form.message || sendMutation.isPending}
                  onClick={() => sendMutation.mutate(form)}
                  data-testid="btn-send-notif"
                >
                  <i className="bi bi-bell-fill me-2"></i>
                  {sendMutation.isPending ? "Sending..." : "Send Notification"}
                </button>
              </div>
            </div>
          </div>
          <div className="col-lg-6">
            <div className="card">
              <div className="card-header border-bottom py-3">
                <h5 className="card-title mb-0">Notification History</h5>
              </div>
              <div className="card-body">
                <div className="text-center py-5 text-muted">
                  <i className="bi bi-bell fs-2 d-block mb-2 opacity-25"></i>
                  <p className="mb-0">No notifications sent yet</p>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    
    </>
  );
}
