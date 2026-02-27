import { useState } from "react";
import { useQuery } from "@tanstack/react-query";
import { Card, CardContent } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Skeleton } from "@/components/ui/skeleton";
import { ChevronLeft, ChevronRight, Star } from "lucide-react";

function StarRating({ rating }: { rating: number }) {
  return (
    <div className="flex items-center gap-0.5">
      {[1, 2, 3, 4, 5].map(i => (
        <Star key={i} className={`w-3.5 h-3.5 ${i <= rating ? "text-amber-400 fill-amber-400" : "text-gray-300"}`} />
      ))}
    </div>
  );
}

export default function Reviews() {
  const [page, setPage] = useState(1);

  const { data, isLoading } = useQuery<any>({
    queryKey: ["/api/reviews", { page }],
    queryFn: () => fetch(`/api/reviews?page=${page}&limit=15`).then(r => r.json()),
  });

  const totalPages = Math.ceil((data?.total || 0) / 15);

  return (
    <div className="space-y-5">
      <div>
        <h1 className="text-2xl font-bold" data-testid="page-title">Reviews</h1>
        <p className="text-sm text-muted-foreground mt-0.5">{data?.total || 0} total reviews</p>
      </div>

      <Card>
        <CardContent className="p-0">
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b bg-muted/30">
                  <th className="text-left px-4 py-3 font-medium text-muted-foreground">Reviewer</th>
                  <th className="text-left px-4 py-3 font-medium text-muted-foreground">Rating</th>
                  <th className="text-left px-4 py-3 font-medium text-muted-foreground">Type</th>
                  <th className="text-left px-4 py-3 font-medium text-muted-foreground hidden md:table-cell">Feedback</th>
                  <th className="text-left px-4 py-3 font-medium text-muted-foreground hidden lg:table-cell">Date</th>
                </tr>
              </thead>
              <tbody>
                {isLoading ? Array(8).fill(0).map((_, i) => (
                  <tr key={i} className="border-b">
                    {Array(5).fill(0).map((_, j) => <td key={j} className="px-4 py-3"><Skeleton className="h-4 w-full" /></td>)}
                  </tr>
                )) : data?.data?.length ? data.data.map((item: any) => (
                  <tr key={item.review.id} className="border-b hover:bg-muted/20" data-testid={`review-row-${item.review.id}`}>
                    <td className="px-4 py-3 font-medium">{item.reviewer?.fullName || "Anonymous"}</td>
                    <td className="px-4 py-3"><StarRating rating={Number(item.review.rating) || 0} /></td>
                    <td className="px-4 py-3 capitalize text-muted-foreground">{item.review.reviewerType || "customer"}</td>
                    <td className="px-4 py-3 hidden md:table-cell max-w-xs">
                      <p className="truncate text-muted-foreground">{item.review.feedback || "—"}</p>
                    </td>
                    <td className="px-4 py-3 text-muted-foreground text-xs hidden lg:table-cell">
                      {new Date(item.review.createdAt).toLocaleDateString("en-IN")}
                    </td>
                  </tr>
                )) : (
                  <tr><td colSpan={5} className="text-center py-12 text-muted-foreground">
                    <Star className="w-12 h-12 mx-auto mb-3 opacity-30" />No reviews yet
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
