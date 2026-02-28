import { useState } from "react";
import { Link } from "wouter";

export default function PagesMediaPage() {
  const [activeSection, setActiveSection] = useState("business-pages");

  const sections = [
    { id: "business-pages", label: "Business Pages" },
    { id: "landing-page", label: "Landing Page Setup" },
    { id: "social-media", label: "Social Media Links" },
  ];

  const tabs = [
    { label: "Business Info", href: "/admin/business-setup" },
    { label: "Pages & Media", href: "/admin/pages-media" },
    { label: "Configurations", href: "/admin/configurations" },
    { label: "System Settings", href: "/admin/settings" },
  ];

  return (
    <>
    
      <div className="content-header">
        <div className="container-fluid">
          <div className="d-flex align-items-center justify-content-between gap-3 flex-wrap mb-3">
            <h2 className="h5 mb-0">Pages & Media</h2>
          </div>
        </div>
      </div>
      <div className="container-fluid">
        <div className="card">
          <div className="card-header border-bottom py-3">
            <ul className="nav nav--tabs p-1 rounded bg-white">
              {tabs.map(t => (
                <li key={t.href} className="nav-item">
                  <Link href={t.href} className={`nav-link${t.href === "/admin/pages-media" ? " active" : ""}`}>
                    {t.label}
                  </Link>
                </li>
              ))}
            </ul>
          </div>
          <div className="card-body">
            <div className="row g-0">
              <div className="col-md-3 border-end">
                <ul className="nav flex-column p-2">
                  {sections.map(s => (
                    <li key={s.id} className="nav-item">
                      <button
                        className={`nav-link w-100 text-start${activeSection === s.id ? " active text-primary fw-semibold" : " text-dark"}`}
                        onClick={() => setActiveSection(s.id)}
                        data-testid={`nav-section-${s.id}`}
                      >
                        {s.label}
                      </button>
                    </li>
                  ))}
                </ul>
              </div>
              <div className="col-md-9 p-4">
                {activeSection === "business-pages" && (
                  <div>
                    <h6 className="fw-bold mb-4">Business Pages</h6>
                    {["Terms & Conditions", "Privacy Policy", "About Us", "Refund Policy"].map(page => (
                      <div key={page} className="card mb-3">
                        <div className="card-body">
                          <div className="d-flex justify-content-between align-items-center mb-2">
                            <h6 className="mb-0">{page}</h6>
                            <button className="btn btn-sm btn-outline-primary">Edit</button>
                          </div>
                          <textarea className="form-control" rows={4} placeholder={`Enter ${page} content here...`} />
                        </div>
                      </div>
                    ))}
                  </div>
                )}
                {activeSection === "landing-page" && (
                  <div>
                    <h6 className="fw-bold mb-4">Landing Page Setup</h6>
                    <div className="mb-3">
                      <label className="form-label fw-semibold">Hero Title</label>
                      <input className="form-control" placeholder="Your ride, your way" />
                    </div>
                    <div className="mb-3">
                      <label className="form-label fw-semibold">Hero Subtitle</label>
                      <textarea className="form-control" rows={2} placeholder="The smarter way to get around" />
                    </div>
                    <div className="mb-3">
                      <label className="form-label fw-semibold">App Store Link</label>
                      <input className="form-control" placeholder="https://apps.apple.com/..." />
                    </div>
                    <div className="mb-3">
                      <label className="form-label fw-semibold">Play Store Link</label>
                      <input className="form-control" placeholder="https://play.google.com/..." />
                    </div>
                    <button className="btn btn-primary">Save Landing Page</button>
                  </div>
                )}
                {activeSection === "social-media" && (
                  <div>
                    <h6 className="fw-bold mb-4">Social Media Links</h6>
                    {[
                      { label: "Facebook", icon: "bi-facebook", placeholder: "https://facebook.com/..." },
                      { label: "Instagram", icon: "bi-instagram", placeholder: "https://instagram.com/..." },
                      { label: "Twitter/X", icon: "bi-twitter-x", placeholder: "https://twitter.com/..." },
                      { label: "YouTube", icon: "bi-youtube", placeholder: "https://youtube.com/..." },
                      { label: "LinkedIn", icon: "bi-linkedin", placeholder: "https://linkedin.com/..." },
                    ].map(s => (
                      <div key={s.label} className="mb-3">
                        <label className="form-label fw-semibold">
                          <i className={`bi ${s.icon} me-2`}></i>{s.label}
                        </label>
                        <input className="form-control" placeholder={s.placeholder} data-testid={`input-social-${s.label.toLowerCase()}`} />
                      </div>
                    ))}
                    <button className="btn btn-primary">Save Social Links</button>
                  </div>
                )}
              </div>
            </div>
          </div>
        </div>
      </div>
    
    </>
  );
}
