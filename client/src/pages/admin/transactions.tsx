import { useState } from "react";
import { useQuery } from "@tanstack/react-query";
import { Card, CardContent, CardHeader } from "@/components/ui/card";
import { Skeleton } from "@/components/ui/skeleton";
import { Button } from "@/components/ui/button";
import { ChevronLeft, ChevronRight, DollarSign } from "lucide-react";

export default function Transactions() {
  const [page, setPage] = useState(1);

  const { data, isLoading } = useQuery<any>({
    queryKey: ["/api/transactions", { page }],
    queryFn: () => fetch(`/api/transactions?page=${page}&limit=15`).then(r => r.json()),
  });

  const totalPages = Math.ceil((data?.total || 0) / 15);

  return (
    <div className="space-y-5">
      <div>
        <h1 className="text-2xl font-bold" data-testid="page-title">Transactions</h1>
        <p className="text-sm text-muted-foreground mt-0.5">{data?.total || 0} total transactions</p>
      </div>

      <Card>
        <CardContent className="p-0">
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b bg-muted/30">
                  <th className="text-left px-4 py-3 font-medium text-muted-foreground">User</th>
                  <th className="text-left px-4 py-3 font-medium text-muted-foreground">Type</th>
                  <th className="text-left px-4 py-3 font-medium text-muted-foreground">Debit</th>
                  <th className="text-left px-4 py-3 font-medium text-muted-foreground">Credit</th>
                  <th className="text-left px-4 py-3 font-medium text-muted-foreground hidden md:table-cell">Balance</th>
                  <th className="text-left px-4 py-3 font-medium text-muted-foreground hidden lg:table-cell">Date</th>
                </tr>
              </thead>
              <tbody>
                {isLoading ? Array(8).fill(0).map((_, i) => (
                  <tr key={i} className="border-b">
                    {Array(6).fill(0).map((_, j) => <td key={j} className="px-4 py-3"><Skeleton className="h-4 w-full" /></td>)}
                  </tr>
                )) : data?.data?.length ? data.data.map((item: any) => (
                  <tr key={item.transaction.id} className="border-b hover:bg-muted/20" data-testid={`tx-row-${item.transaction.id}`}>
                    <td className="px-4 py-3">
                      <div className="font-medium">{item.user?.fullName || "—"}</div>
                      <div className="text-xs text-muted-foreground">{item.user?.email || ""}</div>
                    </td>
                    <td className="px-4 py-3 text-muted-foreground capitalize">{item.transaction.transactionType?.replace(/_/g, " ") || "—"}</td>
                    <td className="px-4 py-3 text-red-600">
                      {Number(item.transaction.debit) > 0 ? `₹${Number(item.transaction.debit).toFixed(2)}` : "—"}
                    </td>
                    <td className="px-4 py-3 text-green-600">
                      {Number(item.transaction.credit) > 0 ? `₹${Number(item.transaction.credit).toFixed(2)}` : "—"}
                    </td>
                    <td className="px-4 py-3 hidden md:table-cell">₹{Number(item.transaction.balance).toFixed(2)}</td>
                    <td className="px-4 py-3 text-muted-foreground text-xs hidden lg:table-cell">
                      {new Date(item.transaction.createdAt).toLocaleDateString("en-IN")}
                    </td>
                  </tr>
                )) : (
                  <tr><td colSpan={6} className="text-center py-12 text-muted-foreground">
                    <DollarSign className="w-12 h-12 mx-auto mb-3 opacity-30" />No transactions yet
                  </td></tr>
                )}
              </tbody>
            </table>
          </div>
          {totalPages > 1 && (
            <div className="flex items-center justify-between px-4 py-3 border-t">
              <p className="text-sm text-muted-foreground">Page {page} of {totalPages}</p>
              <div className="flex gap-2">
                <Button size="sm" variant="outline" disabled={page === 1} onClick={() => setPage(p => p - 1)}><ChevronLeft className="w-4 h-4" /></Button>
                <Button size="sm" variant="outline" disabled={page >= totalPages} onClick={() => setPage(p => p + 1)}><ChevronRight className="w-4 h-4" /></Button>
              </div>
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  );
}
