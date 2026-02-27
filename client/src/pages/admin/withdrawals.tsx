import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { Card, CardContent } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Skeleton } from "@/components/ui/skeleton";
import { Wallet, CheckCircle, XCircle } from "lucide-react";
import { apiRequest } from "@/lib/queryClient";
import { useToast } from "@/hooks/use-toast";

export default function Withdrawals() {
  const { toast } = useToast();
  const qc = useQueryClient();

  const { data, isLoading } = useQuery<any[]>({
    queryKey: ["/api/withdrawals"],
    queryFn: () => fetch("/api/withdrawals").then(r => r.json()),
  });

  const update = useMutation({
    mutationFn: ({ id, status }: { id: string; status: string }) =>
      apiRequest("PATCH", `/api/withdrawals/${id}/status`, { status }),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["/api/withdrawals"] });
      toast({ title: "Withdrawal status updated" });
    },
  });

  return (
    <div className="space-y-5">
      <div>
        <h1 className="text-2xl font-bold" data-testid="page-title">Withdrawal Requests</h1>
        <p className="text-sm text-muted-foreground mt-0.5">{data?.length || 0} withdrawal requests</p>
      </div>

      <Card>
        <CardContent className="p-0">
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b bg-muted/30">
                  <th className="text-left px-4 py-3 font-medium text-muted-foreground">Driver</th>
                  <th className="text-left px-4 py-3 font-medium text-muted-foreground">Amount</th>
                  <th className="text-left px-4 py-3 font-medium text-muted-foreground hidden md:table-cell">Note</th>
                  <th className="text-left px-4 py-3 font-medium text-muted-foreground">Status</th>
                  <th className="text-left px-4 py-3 font-medium text-muted-foreground hidden lg:table-cell">Date</th>
                  <th className="text-left px-4 py-3 font-medium text-muted-foreground">Actions</th>
                </tr>
              </thead>
              <tbody>
                {isLoading ? Array(5).fill(0).map((_, i) => (
                  <tr key={i} className="border-b">
                    {Array(6).fill(0).map((_, j) => <td key={j} className="px-4 py-3"><Skeleton className="h-4 w-full" /></td>)}
                  </tr>
                )) : data?.length ? data.map((item: any) => (
                  <tr key={item.withdraw.id} className="border-b hover:bg-muted/20" data-testid={`withdrawal-row-${item.withdraw.id}`}>
                    <td className="px-4 py-3">
                      <div className="font-medium">{item.user?.fullName || "—"}</div>
                      <div className="text-xs text-muted-foreground">{item.user?.phone || ""}</div>
                    </td>
                    <td className="px-4 py-3 font-semibold">₹{Number(item.withdraw.amount).toFixed(2)}</td>
                    <td className="px-4 py-3 text-muted-foreground hidden md:table-cell max-w-xs">
                      <p className="truncate">{item.withdraw.note || "—"}</p>
                    </td>
                    <td className="px-4 py-3">
                      <span className={`text-xs px-2 py-0.5 rounded-full font-medium ${
                        item.withdraw.status === "approved" ? "bg-green-100 text-green-700" :
                        item.withdraw.status === "rejected" ? "bg-red-100 text-red-700" :
                        "bg-amber-100 text-amber-700"
                      }`}>{item.withdraw.status}</span>
                    </td>
                    <td className="px-4 py-3 text-muted-foreground text-xs hidden lg:table-cell">
                      {new Date(item.withdraw.createdAt).toLocaleDateString("en-IN")}
                    </td>
                    <td className="px-4 py-3">
                      {item.withdraw.status === "pending" && (
                        <div className="flex gap-1">
                          <Button size="sm" variant="outline" className="text-xs h-7 text-green-600 border-green-200"
                            onClick={() => update.mutate({ id: item.withdraw.id, status: "approved" })} data-testid={`btn-approve-${item.withdraw.id}`}>
                            <CheckCircle className="w-3 h-3 mr-1" />Approve
                          </Button>
                          <Button size="sm" variant="outline" className="text-xs h-7 text-red-600 border-red-200"
                            onClick={() => update.mutate({ id: item.withdraw.id, status: "rejected" })} data-testid={`btn-reject-${item.withdraw.id}`}>
                            <XCircle className="w-3 h-3 mr-1" />Reject
                          </Button>
                        </div>
                      )}
                    </td>
                  </tr>
                )) : (
                  <tr><td colSpan={6} className="text-center py-12 text-muted-foreground">
                    <Wallet className="w-12 h-12 mx-auto mb-3 opacity-30" />No withdrawal requests
                  </td></tr>
                )}
              </tbody>
            </table>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
