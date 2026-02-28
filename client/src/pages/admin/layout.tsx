import { useLocation, Link } from "wouter";
import { useState, useEffect, useRef } from "react";

interface NavItem {
  label: string;
  icon: string;
  href: string;
  badge?: number;
}

interface NavSection {
  category: string;
  items: NavItem[];
}

const navSections: NavSection[] = [
  {
    category: "Dashboard",
    items: [
      { label: "Dashboard", icon: "bi-grid-fill", href: "/admin/dashboard" },
    ],
  },
  {
    category: "Zone Management",
    items: [
      { label: "Zone Setup", icon: "bi-map", href: "/admin/zones" },
    ],
  },
  {
    category: "Trip Management",
    items: [
      { label: "All Trips", icon: "bi-car-front-fill", href: "/admin/trips" },
      { label: "Fare Management", icon: "bi-cash-stack", href: "/admin/fares" },
      { label: "Cancel Reasons", icon: "bi-x-circle-fill", href: "/admin/cancellation-reasons" },
    ],
  },
  {
    category: "Promotion Management",
    items: [
      { label: "Coupon Setup", icon: "bi-ticket-fill", href: "/admin/coupons" },
      { label: "Blogs", icon: "bi-newspaper", href: "/admin/blogs" },
    ],
  },
  {
    category: "User Management",
    items: [
      { label: "Customers", icon: "bi-people-fill", href: "/admin/customers" },
      { label: "Drivers", icon: "bi-person-badge-fill", href: "/admin/drivers" },
      { label: "Vehicle Categories", icon: "bi-truck-front-fill", href: "/admin/vehicles" },
      { label: "Withdrawals", icon: "bi-cash-coin", href: "/admin/withdrawals" },
      { label: "Transactions", icon: "bi-receipt", href: "/admin/transactions" },
      { label: "Reviews", icon: "bi-star-fill", href: "/admin/reviews" },
    ],
  },
  {
    category: "System",
    items: [
      { label: "Settings", icon: "bi-gear-fill", href: "/admin/settings" },
    ],
  },
];

export default function AdminLayout({ children }: { children: React.ReactNode }) {
  const [location, setLocation] = useLocation();
  const [sidebarFolded, setSidebarFolded] = useState(false);
  const [mobileOpen, setMobileOpen] = useState(false);
  const [userMenuOpen, setUserMenuOpen] = useState(false);
  const userMenuRef = useRef<HTMLDivElement>(null);

  const admin = (() => {
    try {
      return JSON.parse(localStorage.getItem("jago-admin") || '{"name":"Admin","email":"admin@jago.com","role":"superadmin"}');
    } catch {
      return { name: "Admin", email: "admin@jago.com", role: "superadmin" };
    }
  })();

  const currentPageLabel = navSections
    .flatMap(s => s.items)
    .find(i => location === i.href || location.startsWith(i.href + "/"))?.label || "JAGO Admin";

  useEffect(() => {
    if (sidebarFolded) {
      document.body.classList.add("aside-folded");
    } else {
      document.body.classList.remove("aside-folded");
    }
  }, [sidebarFolded]);

  useEffect(() => {
    if (mobileOpen) {
      document.body.classList.add("aside-open");
    } else {
      document.body.classList.remove("aside-open");
    }
  }, [mobileOpen]);

  useEffect(() => {
    const handleClickOutside = (e: MouseEvent) => {
      if (userMenuRef.current && !userMenuRef.current.contains(e.target as Node)) {
        setUserMenuOpen(false);
      }
    };
    document.addEventListener("mousedown", handleClickOutside);
    return () => document.removeEventListener("mousedown", handleClickOutside);
  }, []);

  const handleLogout = () => {
    localStorage.removeItem("jago-admin");
    setLocation("/admin/login");
  };

  const isActive = (href: string) =>
    location === href || location.startsWith(href + "/");

  return (
    <>
      {/* Aside Overlay (mobile) */}
      <div
        className={`aside-overlay ${mobileOpen ? "active" : ""}`}
        onClick={() => setMobileOpen(false)}
      />

      {/* Sidebar */}
      <aside className="jago-aside">
        {/* Aside Header */}
        <div className="jago-aside-header">
          <a href="/admin/dashboard" className="logo" onClick={(e) => { e.preventDefault(); setLocation("/admin/dashboard"); }}>
            <div className="logo-icon">
              <i className="bi bi-car-front-fill"></i>
            </div>
            <span className="logo-text" style={{ fontWeight: 700, fontSize: "1.1rem", color: "var(--bs-primary)" }}>
              JAGO
            </span>
          </a>
          <button
            className="aside-toggle-btn"
            onClick={() => setSidebarFolded(!sidebarFolded)}
            data-testid="btn-sidebar-toggle"
          >
            <i className="bi bi-chevron-left"></i>
          </button>
        </div>

        {/* Aside Body */}
        <div className="jago-aside-body">
          {/* User Profile */}
          <div className="aside-user-profile">
            <div className="avatar">
              <i className="bi bi-person-fill"></i>
            </div>
            <div className="user-info">
              <div className="name">{admin.email || admin.name}</div>
              <div className="role">{admin.role || "superadmin"}</div>
            </div>
          </div>

          {/* Search */}
          <div className="aside-search">
            <div className="aside-search-wrapper">
              <i className="bi bi-search search-icon"></i>
              <input
                type="search"
                className="aside-search-input"
                placeholder="Search Here"
                data-testid="sidebar-search"
              />
            </div>
          </div>

          {/* Main Nav */}
          <ul className="jago-main-nav">
            {navSections.map((section) => (
              <li key={section.category}>
                <span className="nav-category">{section.category}</span>
                <ul style={{ listStyle: "none", padding: 0, margin: 0 }}>
                  {section.items.map((item) => (
                    <li key={item.href} className={isActive(item.href) ? "active" : ""}>
                      <Link href={item.href}>
                        <a
                          data-testid={`nav-${item.label.toLowerCase().replace(/\s+/g, "-")}`}
                          onClick={() => setMobileOpen(false)}
                        >
                          <i className={`bi ${item.icon}`}></i>
                          <span className="link-title">{item.label}</span>
                          {item.badge !== undefined && (
                            <span className="badge-count">{item.badge}</span>
                          )}
                        </a>
                      </Link>
                    </li>
                  ))}
                </ul>
              </li>
            ))}
          </ul>
        </div>
      </aside>

      {/* Header */}
      <header className="jago-header">
        <div className="jago-header-left">
          {/* Mobile toggle */}
          <button
            className="header-toggle-btn"
            onClick={() => setMobileOpen(!mobileOpen)}
            data-testid="btn-mobile-sidebar"
            style={{ display: "none" }}
            id="mobile-aside-btn"
          >
            <i className="bi bi-list"></i>
          </button>
          {/* Desktop toggle (shown only on desktop) */}
          <button
            className="header-toggle-btn"
            onClick={() => setSidebarFolded(!sidebarFolded)}
            data-testid="btn-desktop-sidebar"
            id="desktop-aside-btn"
          >
            <i className="bi bi-list"></i>
          </button>
          <h5 className="header-page-title">{currentPageLabel}</h5>
        </div>

        <div className="jago-header-right">
          {/* Notifications */}
          <button className="header-icon-btn" data-testid="btn-notifications">
            <i className="bi bi-bell-fill"></i>
          </button>

          {/* User Dropdown */}
          <div className="user-dropdown" ref={userMenuRef}>
            <button
              className="header-user-btn"
              onClick={() => setUserMenuOpen(!userMenuOpen)}
              data-testid="btn-user-menu"
            >
              <div className="header-avatar">
                <i className="bi bi-person-fill"></i>
              </div>
              <span style={{ fontSize: "0.82rem" }}>{admin.name || "Admin"}</span>
              <i className="bi bi-chevron-down" style={{ fontSize: "0.7rem" }}></i>
            </button>

            <div className={`user-dropdown-menu ${userMenuOpen ? "show" : ""}`}>
              <div className="user-dropdown-profile">
                <div className="avatar">
                  <i className="bi bi-person-fill"></i>
                </div>
                <div className="info">
                  <div className="name">{admin.name}</div>
                  <div className="role">{admin.email}</div>
                </div>
              </div>
              <button
                className="user-dropdown-item text-danger"
                onClick={handleLogout}
                data-testid="menu-logout"
              >
                <i className="bi bi-box-arrow-right"></i>
                Logout
              </button>
            </div>
          </div>
        </div>
      </header>

      {/* Responsive toggle: show mobile btn on small screens */}
      <style>{`
        @media (max-width: 1199px) {
          #mobile-aside-btn { display: grid !important; }
          #desktop-aside-btn { display: none !important; }
        }
        @media (min-width: 1200px) {
          #mobile-aside-btn { display: none !important; }
          #desktop-aside-btn { display: grid !important; }
        }
      `}</style>

      {/* Main Area */}
      <main className="jago-main-area">
        <div className="jago-main-content">
          {children}
        </div>
      </main>
    </>
  );
}
