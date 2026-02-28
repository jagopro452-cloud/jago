import { useState } from "react";
import { useQuery } from "@tanstack/react-query";

function Stars({ rating }: { rating: number }) {
  return (
    <div style={{ display: "flex", gap: "2px" }}>
      {[1, 2, 3, 4, 5].map(i => (
        <i key={i} className={`bi ${i <= rating ? "bi-star-fill" : "bi-star"}`} style={{ fontSize: "0.75rem", color: i <= rating ? "#f59e0b" : "#d1d5db" }}></i>
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
    <div>
      <div className="jago-page-header">
        <div>
          <h4 className="page-title" data-testid="page-title">Reviews</h4>
          <div className="breadcrumb">
            <i className="bi bi-house-fill"></i>
            <span>Home</span>
            <i className="bi bi-chevron-right" style={{ fontSize: "0.65rem" }}></i>
            <span>User Management</span>
            <i className="bi bi-chevron-right" style={{ fontSize: "0.65rem" }}></i>
            <span>Reviews</span>
          </div>
        </div>
        <div style={{ fontSize: "0.82rem", color: "var(--bs-body-color)" }}>
          Total: <strong style={{ color: "var(--title-color)" }}>{data?.total || 0}</strong> reviews
        </div>
      </div>

      <div className="jago-card">
        <div className="jago-card-header">
          <h5 className="jago-card-title">
            <i className="bi bi-star-fill" style={{ marginRight: "0.5rem", color: "#f59e0b" }}></i>
            Customer Reviews
          </h5>
        </div>
        <div className="jago-table-wrapper">
          <table className="jago-table">
            <thead>
              <tr>
                <th>#</th>
                <th>Reviewer</th>
                <th>Rating</th>
                <th>Type</th>
                <th>Feedback</th>
                <th>Date</th>
              </tr>
            </thead>
            <tbody>
              {isLoading ? Array(8).fill(0).map((_, i) => (
                <tr key={i}>
                  {Array(6).fill(0).map((_, j) => <td key={j}><div style={{ height: "14px", background: "#f1f5f9", borderRadius: "4px" }} /></td>)}
                </tr>
              )) : data?.data?.length ? data.data.map((item: any, idx: number) => (
                <tr key={item.review.id} data-testid={`review-row-${item.review.id}`}>
                  <td style={{ color: "var(--bs-body-color)", fontSize: "0.8rem" }}>{(page - 1) * 15 + idx + 1}</td>
                  <td style={{ fontWeight: 600 }}>{item.reviewer?.fullName || "Anonymous"}</td>
                  <td><Stars rating={Number(item.review.rating) || 0} /></td>
                  <td style={{ textTransform: "capitalize", color: "var(--bs-body-color)" }}>{item.review.reviewerType || "customer"}</td>
                  <td style={{ color: "var(--bs-body-color)", maxWidth: "220px" }}>
                    <span style={{ display: "block", overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap" }}>
                      {item.review.feedback || "—"}
                    </span>
                  </td>
                  <td style={{ color: "var(--bs-body-color)", fontSize: "0.8rem", whiteSpace: "nowrap" }}>
                    {new Date(item.review.createdAt).toLocaleDateString("en-IN")}
                  </td>
                </tr>
              )) : (
                <tr>
                  <td colSpan={6}>
                    <div className="jago-empty">
                      <i className="bi bi-star"></i>
                      <p>No reviews found</p>
                    </div>
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
        {totalPages > 1 && (
          <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", padding: "0.875rem 1rem", borderTop: "1px solid var(--bs-border-color)", fontSize: "0.82rem" }}>
            <span style={{ color: "var(--bs-body-color)" }}>Page {page} of {totalPages}</span>
            <div style={{ display: "flex", gap: "0.5rem" }}>
              <button className="btn-jago-outline btn-jago-sm" disabled={page === 1} onClick={() => setPage(p => p - 1)}><i className="bi bi-chevron-left"></i></button>
              <button className="btn-jago-outline btn-jago-sm" disabled={page >= totalPages} onClick={() => setPage(p => p + 1)}><i className="bi bi-chevron-right"></i></button>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
