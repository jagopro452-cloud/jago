import { useEffect, useMemo, useState } from "react";
import { Link } from "wouter";
import { apiRequest } from "@/lib/queryClient";
import { useToast } from "@/hooks/use-toast";

declare global {
  interface Window {
    io?: (url?: string, opts?: any) => any;
  }
}

type OpsSnapshot = {
  generatedAt: string;
  config: Record<string, number>;
  summary: Record<string, number>;
  rides: any[];
  alerts: any[];
};

const DEFAULT_SNAPSHOT: OpsSnapshot = {
  generatedAt: new Date(0).toISOString(),
  config: {},
  summary: {},
  rides: [],
  alerts: [],
};

function loadAdminSession() {
  try {
    return JSON.parse(localStorage.getItem("jago-admin") || "{}");
  } catch {
    return {};
  }
}

function secondsAgoLabel(value: number | null | undefined) {
  if (value == null) return "n/a";
  if (value < 60) return `${value}s ago`;
  const mins = Math.floor(value / 60);
  const secs = value % 60;
  if (mins < 60) return `${mins}m ${secs}s ago`;
  const hours = Math.floor(mins / 60);
  return `${hours}h ${mins % 60}m ago`;
}

function badgeStyles(kind: string) {
  const palette: Record<string, { bg: string; color: string; border: string }> = {
    healthy: { bg: "#ecfdf5", color: "#047857", border: "#a7f3d0" },
    reconnecting: { bg: "#eff6ff", color: "#1d4ed8", border: "#bfdbfe" },
    recovered: { bg: "#f5f3ff", color: "#6d28d9", border: "#ddd6fe" },
    stale_tracking: { bg: "#fff7ed", color: "#c2410c", border: "#fed7aa" },
    frozen_tracking: { bg: "#fef2f2", color: "#b91c1c", border: "#fecaca" },
    inactive_socket: { bg: "#111827", color: "#f9fafb", border: "#374151" },
    weak_signal: { bg: "#fefce8", color: "#a16207", border: "#fde68a" },
    reconnect_storm: { bg: "#7f1d1d", color: "#fff7ed", border: "#ef4444" },
    critical: { bg: "#7f1d1d", color: "#fff7ed", border: "#ef4444" },
    warning: { bg: "#fff7ed", color: "#9a3412", border: "#fdba74" },
  };
  return palette[kind] || { bg: "#f8fafc", color: "#334155", border: "#cbd5e1" };
}

async function ensureSocketIoScript() {
  if (window.io) return;
  await new Promise<void>((resolve, reject) => {
    const existing = document.querySelector('script[data-admin-ops-socket="true"]') as HTMLScriptElement | null;
    if (existing) {
      existing.addEventListener("load", () => resolve(), { once: true });
      existing.addEventListener("error", () => reject(new Error("Socket script failed")), { once: true });
      return;
    }
    const script = document.createElement("script");
    script.src = "/socket.io/socket.io.js";
    script.async = true;
    script.dataset.adminOpsSocket = "true";
    script.onload = () => resolve();
    script.onerror = () => reject(new Error("Socket script failed"));
    document.body.appendChild(script);
  });
}

function KpiCard({ label, value, accent, sub }: { label: string; value: string | number; accent: string; sub?: string }) {
  return (
    <div style={{
      borderRadius: 18,
      padding: "18px 20px",
      background: "#fff",
      border: "1px solid #e5e7eb",
      boxShadow: "0 10px 30px rgba(15,23,42,0.06)",
    }}>
      <div style={{ fontSize: 11, fontWeight: 800, letterSpacing: 1, textTransform: "uppercase", color: "#94a3b8" }}>{label}</div>
      <div style={{ display: "flex", alignItems: "baseline", gap: 8, marginTop: 10 }}>
        <div style={{ fontSize: 28, fontWeight: 900, color: accent, lineHeight: 1 }}>{value}</div>
        {sub ? <div style={{ fontSize: 12, color: "#64748b" }}>{sub}</div> : null}
      </div>
    </div>
  );
}

export default function RealtimeOpsPage() {
  const { toast } = useToast();
  const [snapshot, setSnapshot] = useState<OpsSnapshot>(DEFAULT_SNAPSHOT);
  const [loading, setLoading] = useState(true);
  const [socketState, setSocketState] = useState<"connecting" | "live" | "offline">("connecting");
  const [saving, setSaving] = useState(false);
  const [configDraft, setConfigDraft] = useState<Record<string, string>>({});

  useEffect(() => {
    let mounted = true;
    let socket: any = null;

    const bootstrap = async () => {
      try {
        const res = await fetch("/api/admin/realtime-ops/bootstrap");
        if (!res.ok) throw new Error("Could not load realtime operations snapshot");
        const data = await res.json();
        if (!mounted) return;
        setSnapshot(data);
        setConfigDraft(Object.fromEntries(Object.entries(data.config || {}).map(([key, value]) => [key, String(value)])));
        setLoading(false);
      } catch (error: any) {
        if (!mounted) return;
        setLoading(false);
        toast({
          title: "Realtime ops unavailable",
          description: error?.message || "Could not load admin telemetry bootstrap",
          variant: "destructive",
        });
      }
    };

    const connectSocket = async () => {
      try {
        const admin = loadAdminSession();
        if (!admin?.id || !admin?.token) {
          setSocketState("offline");
          return;
        }
        await ensureSocketIoScript();
        if (!window.io) throw new Error("Socket client unavailable");
        socket = window.io(undefined, {
          transports: ["websocket", "polling"],
          query: { userId: admin.id, userType: "admin", token: admin.token },
          autoConnect: true,
          reconnection: true,
          reconnectionAttempts: Infinity,
          reconnectionDelay: 3000,
        });
        socket.on("connect", () => setSocketState("live"));
        socket.on("disconnect", () => setSocketState("offline"));
        socket.on("connect_error", () => setSocketState("offline"));
        socket.on("admin:ops_snapshot", (data: OpsSnapshot) => {
          if (!mounted || !data) return;
          setSnapshot(data);
          setConfigDraft((prev) => Object.keys(prev).length ? prev : Object.fromEntries(Object.entries(data.config || {}).map(([key, value]) => [key, String(value)])));
        });
        socket.on("admin:ops_alert", (alert: any) => {
          if (!mounted || !alert?.message) return;
          toast({
            title: `${alert.severity === "critical" ? "Critical" : "Warning"} alert`,
            description: `${alert.tripId}: ${alert.message}`,
            variant: alert.severity === "critical" ? "destructive" : "default",
          });
        });
      } catch {
        if (mounted) setSocketState("offline");
      }
    };

    bootstrap();
    connectSocket();

    return () => {
      mounted = false;
      if (socket) socket.disconnect();
    };
  }, [toast]);

  const highlightedRides = useMemo(
    () => [...(snapshot.rides || [])].sort((a, b) => {
      const score = (ride: any) => {
        if (ride.operationalState === "inactive_socket") return 5;
        if (ride.operationalState === "frozen_tracking") return 4;
        if (ride.operationalState === "stale_tracking") return 3;
        if (ride.operationalState === "reconnecting") return 2;
        if (ride.operationalState === "recovered") return 1;
        return 0;
      };
      return score(b) - score(a);
    }),
    [snapshot.rides],
  );

  const topRecoveryEvents = useMemo(
    () => highlightedRides.flatMap((ride) => (ride.recoveryEvents || []).map((event: any) => ({ ...event, tripId: ride.tripId, refId: ride.refId }))).slice(0, 12),
    [highlightedRides],
  );

  const onChangeConfig = (key: string, value: string) => {
    setConfigDraft((prev) => ({ ...prev, [key]: value }));
  };

  const saveConfig = async () => {
    try {
      setSaving(true);
      const payload = Object.fromEntries(Object.entries(configDraft).map(([key, value]) => [key, Number(value)]));
      const res = await apiRequest("PATCH", "/api/admin/realtime-ops/config", payload);
      const data = await res.json();
      setSnapshot((prev) => ({ ...prev, config: data.config || prev.config }));
      toast({ title: "Runtime controls updated", description: "New observability thresholds are live now." });
    } catch (error: any) {
      toast({
        title: "Config update failed",
        description: error?.message || "Could not save runtime controls",
        variant: "destructive",
      });
    } finally {
      setSaving(false);
    }
  };

  const liveBadge = badgeStyles(socketState === "live" ? "healthy" : socketState === "connecting" ? "warning" : "critical");

  return (
    <div style={{ padding: "28px 32px 40px", background: "linear-gradient(180deg,#f8fbff 0%,#f8fafc 100%)", minHeight: "100%" }}>
      <div style={{ display: "flex", justifyContent: "space-between", gap: 16, flexWrap: "wrap", marginBottom: 22 }}>
        <div>
          <div style={{ fontSize: 12, color: "#2563eb", fontWeight: 800, letterSpacing: 1.2, textTransform: "uppercase" }}>Admin Live Telemetry</div>
          <h2 style={{ margin: "6px 0 8px", fontSize: 28, fontWeight: 900, color: "#0f172a" }}>Realtime Recovery Operations</h2>
          <div style={{ color: "#64748b", fontSize: 14 }}>
            Centralized ride-state observability for reconnects, stale tracking, waiting timers, socket health, and recovery audit trails.
          </div>
        </div>
        <div style={{
          minWidth: 260,
          padding: "18px 20px",
          borderRadius: 18,
          background: "linear-gradient(135deg,#0f172a,#1d4ed8)",
          color: "#fff",
          boxShadow: "0 18px 45px rgba(15,23,42,0.22)",
        }}>
          <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", gap: 10 }}>
            <div>
              <div style={{ fontSize: 11, opacity: 0.75, fontWeight: 700, textTransform: "uppercase", letterSpacing: 1 }}>Socket stream</div>
              <div style={{ fontSize: 18, fontWeight: 900, marginTop: 6 }}>{socketState === "live" ? "Live feed active" : socketState === "connecting" ? "Connecting" : "Offline"}</div>
            </div>
            <span style={{
              padding: "6px 10px",
              borderRadius: 999,
              border: `1px solid ${liveBadge.border}`,
              background: liveBadge.bg,
              color: liveBadge.color,
              fontSize: 12,
              fontWeight: 800,
            }}>
              {socketState}
            </span>
          </div>
          <div style={{ marginTop: 12, fontSize: 12, opacity: 0.82 }}>
            Last snapshot: {snapshot.generatedAt ? new Date(snapshot.generatedAt).toLocaleString("en-IN") : "n/a"}
          </div>
        </div>
      </div>

      <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(180px, 1fr))", gap: 14, marginBottom: 22 }}>
        <KpiCard label="Active rides" value={snapshot.summary.activeRideCount || 0} accent="#2563eb" />
        <KpiCard label="Reconnecting" value={snapshot.summary.reconnectingRideCount || 0} accent="#1d4ed8" />
        <KpiCard label="Recovered" value={snapshot.summary.recoveredRideCount || 0} accent="#7c3aed" />
        <KpiCard label="Stale tracking" value={snapshot.summary.staleRideCount || 0} accent="#ea580c" />
        <KpiCard label="Frozen rides" value={snapshot.summary.frozenRideCount || 0} accent="#dc2626" />
        <KpiCard label="Active alerts" value={snapshot.summary.alertCount || 0} accent="#991b1b" sub={`${snapshot.summary.unhealthyRideCount || 0} unhealthy rides`} />
      </div>

      <div style={{ display: "grid", gridTemplateColumns: "2.2fr 1fr", gap: 18, alignItems: "start" }}>
        <div style={{ borderRadius: 20, background: "#fff", border: "1px solid #e5e7eb", boxShadow: "0 12px 34px rgba(15,23,42,0.06)", overflow: "hidden" }}>
          <div style={{ padding: "18px 20px", borderBottom: "1px solid #eef2f7", display: "flex", justifyContent: "space-between", gap: 12, alignItems: "center" }}>
            <div>
              <div style={{ fontSize: 12, fontWeight: 800, letterSpacing: 1, color: "#2563eb", textTransform: "uppercase" }}>Live ride health</div>
              <div style={{ fontSize: 20, fontWeight: 900, color: "#0f172a", marginTop: 4 }}>Operational ride telemetry</div>
            </div>
            <Link href="/admin/fleet-view" className="btn btn-sm btn-outline-primary" style={{ borderRadius: 10 }}>
              Map view
            </Link>
          </div>
          <div style={{ overflowX: "auto" }}>
            <table className="table mb-0 align-middle">
              <thead>
                <tr style={{ background: "#f8fafc" }}>
                  <th style={{ minWidth: 160 }}>Ride</th>
                  <th style={{ minWidth: 120 }}>Phase</th>
                  <th style={{ minWidth: 150 }}>Health</th>
                  <th style={{ minWidth: 120 }}>Tracking</th>
                  <th style={{ minWidth: 120 }}>Heartbeat</th>
                  <th style={{ minWidth: 100 }}>Reconnects</th>
                  <th style={{ minWidth: 140 }}>Waiting</th>
                  <th style={{ minWidth: 190 }}>Recovery trail</th>
                </tr>
              </thead>
              <tbody>
                {loading ? (
                  <tr><td colSpan={8} className="text-center py-5 text-muted">Loading realtime telemetry...</td></tr>
                ) : highlightedRides.length === 0 ? (
                  <tr><td colSpan={8} className="text-center py-5 text-muted">No active or searching rides right now.</td></tr>
                ) : highlightedRides.map((ride: any) => {
                  const opBadge = badgeStyles(ride.operationalState);
                  const phaseBadge = badgeStyles(ride.phase === "in_progress" ? "healthy" : ride.phase === "heading_to_pickup" ? "reconnecting" : ride.phase);
                  return (
                    <tr key={ride.tripId}>
                      <td>
                        <div style={{ fontWeight: 800, color: "#0f172a" }}>{ride.refId || ride.tripId.slice(0, 8)}</div>
                        <div style={{ fontSize: 12, color: "#64748b" }}>{ride.driver?.name || "Unassigned"} • {ride.customer?.name || "Customer"}</div>
                        <div style={{ fontSize: 11, color: "#94a3b8", marginTop: 4 }}>{ride.vehicleName || ride.tripType}</div>
                      </td>
                      <td>
                        <span style={{
                          display: "inline-flex",
                          borderRadius: 999,
                          padding: "5px 10px",
                          fontWeight: 800,
                          fontSize: 12,
                          background: phaseBadge.bg,
                          color: phaseBadge.color,
                          border: `1px solid ${phaseBadge.border}`,
                        }}>
                          {ride.phase}
                        </span>
                      </td>
                      <td>
                        <span style={{
                          display: "inline-flex",
                          borderRadius: 999,
                          padding: "5px 10px",
                          fontWeight: 800,
                          fontSize: 12,
                          background: opBadge.bg,
                          color: opBadge.color,
                          border: `1px solid ${opBadge.border}`,
                        }}>
                          {ride.operationalState}
                        </span>
                        {ride.alerts?.length ? <div style={{ fontSize: 11, color: "#b91c1c", marginTop: 6 }}>{ride.alerts.length} alert(s)</div> : null}
                      </td>
                      <td>
                        <div style={{ fontWeight: 700, color: "#0f172a" }}>{secondsAgoLabel(ride.trackingFreshnessSec)}</div>
                        <div style={{ fontSize: 11, color: "#94a3b8" }}>{ride.driverLat != null && ride.driverLng != null ? "GPS live" : "No live fix"}</div>
                      </td>
                      <td>
                        <div style={{ fontWeight: 700, color: "#0f172a" }}>{secondsAgoLabel(ride.socketHeartbeatAgeSec)}</div>
                        <div style={{ fontSize: 11, color: "#94a3b8" }}>{ride.lastSocketHeartbeat ? new Date(ride.lastSocketHeartbeat).toLocaleTimeString("en-IN") : "No heartbeat"}</div>
                      </td>
                      <td>
                        <div style={{ fontWeight: 800, color: ride.reconnectCount > 0 ? "#1d4ed8" : "#0f172a" }}>{ride.reconnectCount}</div>
                        <div style={{ fontSize: 11, color: "#94a3b8" }}>recoveries {ride.recoveryCount || 0}</div>
                      </td>
                      <td>
                        <div style={{ fontWeight: 800, color: ride.waitingDurationSec ? "#c2410c" : "#0f172a" }}>{secondsAgoLabel(ride.waitingDurationSec)}</div>
                        <div style={{ fontSize: 11, color: "#94a3b8" }}>Charge {ride.waitingCharge ? `₹${Number(ride.waitingCharge).toFixed(2)}` : "₹0.00"}</div>
                      </td>
                      <td>
                        <div style={{ fontWeight: 700, color: "#0f172a" }}>{ride.lastRecoveryEvent || "No recent recovery"}</div>
                        <div style={{ fontSize: 11, color: "#94a3b8" }}>{ride.lastRecoveryAt ? new Date(ride.lastRecoveryAt).toLocaleString("en-IN") : "Audit trail idle"}</div>
                        <Link href={`/admin/trips`} style={{ fontSize: 11, color: "#2563eb", fontWeight: 700, textDecoration: "none" }}>
                          Open trip operations
                        </Link>
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        </div>

        <div style={{ display: "grid", gap: 18 }}>
          <div style={{ borderRadius: 20, background: "#fff", border: "1px solid #e5e7eb", boxShadow: "0 12px 34px rgba(15,23,42,0.06)", overflow: "hidden" }}>
            <div style={{ padding: "18px 20px", borderBottom: "1px solid #eef2f7" }}>
              <div style={{ fontSize: 12, fontWeight: 800, letterSpacing: 1, color: "#dc2626", textTransform: "uppercase" }}>Operational alerts</div>
              <div style={{ fontSize: 20, fontWeight: 900, color: "#0f172a", marginTop: 4 }}>Alert feed</div>
            </div>
            <div style={{ padding: 16, maxHeight: 340, overflow: "auto", display: "grid", gap: 10 }}>
              {(snapshot.alerts || []).length === 0 ? (
                <div style={{ fontSize: 13, color: "#64748b" }}>No live alerts. Active rides are currently healthy.</div>
              ) : (snapshot.alerts || []).map((alert: any) => {
                const styles = badgeStyles(alert.severity);
                return (
                  <div key={alert.id} style={{ borderRadius: 14, border: `1px solid ${styles.border}`, background: styles.bg, padding: 14 }}>
                    <div style={{ display: "flex", justifyContent: "space-between", gap: 8 }}>
                      <div style={{ fontWeight: 800, color: styles.color }}>{alert.type}</div>
                      <div style={{ fontSize: 11, color: styles.color, fontWeight: 700 }}>{alert.tripId?.slice(0, 8)}</div>
                    </div>
                    <div style={{ fontSize: 13, color: "#1f2937", marginTop: 6 }}>{alert.message}</div>
                    <div style={{ fontSize: 11, color: "#64748b", marginTop: 6 }}>
                      Heartbeat: {alert.lastSuccessfulHeartbeat ? new Date(alert.lastSuccessfulHeartbeat).toLocaleTimeString("en-IN") : "missing"} • Recovery attempts: {alert.recoveryAttempts}
                    </div>
                  </div>
                );
              })}
            </div>
          </div>

          <div style={{ borderRadius: 20, background: "#fff", border: "1px solid #e5e7eb", boxShadow: "0 12px 34px rgba(15,23,42,0.06)", overflow: "hidden" }}>
            <div style={{ padding: "18px 20px", borderBottom: "1px solid #eef2f7" }}>
              <div style={{ fontSize: 12, fontWeight: 800, letterSpacing: 1, color: "#7c3aed", textTransform: "uppercase" }}>Recovery audit</div>
              <div style={{ fontSize: 20, fontWeight: 900, color: "#0f172a", marginTop: 4 }}>Recent recovery events</div>
            </div>
            <div style={{ padding: 16, maxHeight: 280, overflow: "auto", display: "grid", gap: 10 }}>
              {topRecoveryEvents.length === 0 ? (
                <div style={{ fontSize: 13, color: "#64748b" }}>No recovery events recorded in the current active ride set.</div>
              ) : topRecoveryEvents.map((event: any, idx: number) => (
                <div key={`${event.tripId}:${event.createdAt}:${idx}`} style={{ borderLeft: "3px solid #8b5cf6", paddingLeft: 12 }}>
                  <div style={{ fontSize: 13, fontWeight: 800, color: "#0f172a" }}>{event.eventType}</div>
                  <div style={{ fontSize: 12, color: "#475569" }}>{event.refId || event.tripId.slice(0, 8)} • {event.actorType}</div>
                  <div style={{ fontSize: 11, color: "#94a3b8", marginTop: 4 }}>{new Date(event.createdAt).toLocaleString("en-IN")}</div>
                </div>
              ))}
            </div>
          </div>

          <div style={{ borderRadius: 20, background: "#fff", border: "1px solid #e5e7eb", boxShadow: "0 12px 34px rgba(15,23,42,0.06)", overflow: "hidden" }}>
            <div style={{ padding: "18px 20px", borderBottom: "1px solid #eef2f7" }}>
              <div style={{ fontSize: 12, fontWeight: 800, letterSpacing: 1, color: "#16a34a", textTransform: "uppercase" }}>Runtime controls</div>
              <div style={{ fontSize: 20, fontWeight: 900, color: "#0f172a", marginTop: 4 }}>Live observability thresholds</div>
            </div>
            <div style={{ padding: 16, display: "grid", gap: 12 }}>
              {[
                ["trackingFreshnessTimeoutSec", "Tracking freshness timeout"],
                ["frozenMovementTimeoutSec", "Frozen movement timeout"],
                ["socketHeartbeatTimeoutSec", "Socket heartbeat timeout"],
                ["reconnectStormThreshold", "Reconnect storm threshold"],
                ["recoveryCooldownSec", "Recovery cooldown"],
                ["replayLimit", "Socket replay limit"],
                ["heartbeatCadenceSec", "Heartbeat cadence"],
                ["gpsUpdateCadenceSec", "GPS update cadence"],
              ].map(([key, label]) => (
                <label key={key} style={{ display: "grid", gap: 6 }}>
                  <span style={{ fontSize: 12, fontWeight: 700, color: "#334155" }}>{label}</span>
                  <input
                    type="number"
                    className="form-control"
                    value={configDraft[key] || ""}
                    onChange={(e) => onChangeConfig(key, e.target.value)}
                  />
                </label>
              ))}
              <button className="btn btn-primary" style={{ borderRadius: 12, fontWeight: 800 }} onClick={saveConfig} disabled={saving}>
                {saving ? "Saving..." : "Apply live controls"}
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
