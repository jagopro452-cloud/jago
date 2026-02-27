import { useState } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { Card, CardContent, CardHeader } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Skeleton } from "@/components/ui/skeleton";
import { Search, Users, ChevronLeft, ChevronRight, UserCheck, UserX } from "lucide-react";
import { apiRequest } from "@/lib/queryClient";
import { useToast } from "@/hooks/use-toast";

export default function Customers() {
  const [search, setSearch] = useState("");
  const [page, setPage] = useState(1);
  const { toast } = useToast();
  const qc = useQueryClient();

  const { data, isLoading } = useQuery<any>({
    queryKey: ["/api/users", { userType: "customer", search, page }],
    queryFn: () => {
      const params = new URLSearchParams({ userType: "customer", page: String(page), limit: "15" });
      if (search) params.set("search", search);
      return fetch(`/api/users?${params}`).then(r => r.json());
    },
  });

  const toggleStatus = useMutation({
    mutationFn: ({ id, isActive }: { id: string; isActive: boolean }) =>
      apiRequest("PATCH", `/api/users/${id}/status`, { isActive }),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["/api/users"] });
      toast({ title: "Customer status updated" });
    },
  });

  const totalPages = Math.ceil((data?.total || 0) / 15);

  return (
    <div className="space-y-5">
      <div>
        <h1 className="text-2xl font-bold" data-testid="page-title">Customers</h1>
        <p className="text-sm text-muted-foreground mt-0.5">{data?.total || 0} registered customers</p>
      </div>

      <Card>
        <CardHeader className="pb-4">
          <div className="relative max-w-xs">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground" />
            <Input placeholder="Search customers..." className="pl-9" value={search}
              onChange={e => { setSearch(e.target.value); setPage(1); }} data-testid="input-search" />
          </div>
        </CardHeader>
        <CardContent className="p-0">
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b bg-muted/30">
                  <th className="text-left px-4 py-3 font-medium text-muted-foreground">Name</th>
                  <th className="text-left px-4 py-3 font-medium text-muted-foreground hidden sm:table-cell">Email</th>
                  <th className="text-left px-4 py-3 font-medium text-muted-foreground hidden md:table-cell">Phone</th>
                  <th className="text-left px-4 py-3 font-medium text-muted-foreground hidden lg:table-cell">Points</th>
                  <th className="text-left px-4 py-3 font-medium text-muted-foreground">Status</th>
                  <th className="text-left px-4 py-3 font-medium text-muted-foreground hidden xl:table-cell">Joined</th>
                  <th className="text-left px-4 py-3 font-medium text-muted-foreground">Action</th>
                </tr>
              </thead>
              <tbody>
                {isLoading ? (
                  Array(8).fill(0).map((_, i) => (
                    <tr key={i} className="border-b">
                      {Array(7).fill(0).map((_, j) => <td key={j} className="px-4 py-3"><Skeleton className="h-4 w-full" /></td>)}
                    </tr>
                  ))
                ) : data?.data?.length ? (
                  data.data.map((u: any) => (
                    <tr key={u.id} className="border-b hover:bg-muted/20 transition-colors" data-testid={`customer-row-${u.id}`}>
                      <td className="px-4 py-3 font-medium">{u.fullName || `${u.firstName || ""} ${u.lastName || ""}`.trim() || "—"}</td>
                      <td className="px-4 py-3 text-muted-foreground hidden sm:table-cell">{u.email || "—"}</td>
                      <td className="px-4 py-3 text-muted-foreground hidden md:table-cell">{u.phone || "—"}</td>
                      <td className="px-4 py-3 hidden lg:table-cell">{u.loyaltyPoints}</td>
                      <td className="px-4 py-3">
                        <span className={`inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium ${u.isActive ? "bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-400" : "bg-red-100 text-red-700 dark:bg-red-900/30 dark:text-red-400"}`}>
                          {u.isActive ? "Active" : "Blocked"}
                        </span>
                      </td>
                      <td className="px-4 py-3 text-muted-foreground text-xs hidden xl:table-cell">
                        {u.createdAt ? new Date(u.createdAt).toLocaleDateString("en-IN") : "—"}
                      </td>
                      <td className="px-4 py-3">
                        <Button size="sm" variant="outline" className="text-xs h-7"
                          onClick={() => toggleStatus.mutate({ id: u.id, isActive: !u.isActive })}
                          data-testid={`btn-toggle-status-${u.id}`}>
                          {u.isActive ? <><UserX className="w-3 h-3 mr-1" />Block</> : <><UserCheck className="w-3 h-3 mr-1" />Unblock</>}
                        </Button>
                      </td>
                    </tr>
                  ))
                ) : (
                  <tr><td colSpan={7} className="text-center py-12 text-muted-foreground"><Users className="w-12 h-12 mx-auto mb-3 opacity-30" />No customers found</td></tr>
                )}
              </tbody>
            </table>
          </div>
          {totalPages > 1 && (
            <div className="flex items-center justify-between px-4 py-3 border-t">
              <p className="text-sm text-muted-foreground">Page {page} of {totalPages}</p>
              <div className="flex gap-2">
                <Button size="sm" variant="outline" disabled={page === 1} onClick={() => setPage(p => p - 1)} data-testid="btn-prev"><ChevronLeft className="w-4 h-4" /></Button>
                <Button size="sm" variant="outline" disabled={page >= totalPages} onClick={() => setPage(p => p + 1)} data-testid="btn-next"><ChevronRight className="w-4 h-4" /></Button>
              </div>
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  );
}
