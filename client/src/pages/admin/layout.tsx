import { useLocation, Link } from "wouter";
import { useState, useEffect, useRef } from "react";

function useAdminBootstrap() {
  useEffect(() => {
    let link = document.getElementById("admin-bootstrap-css") as HTMLLinkElement | null;
    if (!link) {
      link = document.createElement("link");
      link.rel = "stylesheet";
      link.href = "/admin-bootstrap.min.css";
      link.id = "admin-bootstrap-css";
      document.head.appendChild(link);
    }
    return () => {
      const el = document.getElementById("admin-bootstrap-css");
      if (el) el.remove();
    };
  }, []);
}

interface NavItem {
  label: string;
  icon: string;
  href: string;
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
  useAdminBootstrap();
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
      {/* Mobile overlay */}
      <div
        className={`aside-overlay${mobileOpen ? " active" : ""}`}
        onClick={() => setMobileOpen(false)}
      />

      {/* Aside (Sidebar) - exact original JAGO structure */}
      <aside className="aside">
        {/* Aside Header */}
        <div className="aside-header">
          <a
            href="/admin/dashboard"
            className="logo"
            onClick={(e) => { e.preventDefault(); setLocation("/admin/dashboard"); }}
          >
            <img
              width="115"
              src="/jago-logo.png"
              alt="JAGO"
              className="main-logo"
            />
          </a>
          <button
            className="toggle-menu-button"
            onClick={() => setSidebarFolded(!sidebarFolded)}
            data-testid="btn-sidebar-toggle"
          >
            <i className="bi bi-chevron-left"></i>
          </button>
        </div>
        {/* End Aside Header */}

        {/* Aside Body */}
        <div className="aside-body-wrapper">
          <div className="aside-body">

            {/* User Profile */}
            <div className="user-profile">
              <div className="avatar rounded-circle">
                <i className="bi bi-person-fill"></i>
              </div>
              <div className="media-body">
                <div className="card-title fw-semibold" data-testid="sidebar-user-email">
                  {admin.email || admin.name}
                </div>
                <span className="card-text">{admin.role || "superadmin"}</span>
              </div>
            </div>
            {/* End User Profile */}

            {/* Search */}
            <div className="aside-search mb-3">
              <div className="search-form__input_group">
                <span className="search-form__icon">
                  <i className="bi bi-search"></i>
                </span>
                <input
                  type="search"
                  className="theme-input-style search-form__input"
                  placeholder="Search Here"
                  data-testid="sidebar-search"
                />
              </div>
            </div>

            {/* Nav */}
            <ul className="main-nav nav">
              {navSections.map((section) => (
                <li key={section.category}>
                  <span className="nav-category">{section.category}</span>
                  {section.items.map((item) => (
                    <li key={item.href} className={isActive(item.href) ? "active open" : ""}>
                      <Link
                        href={item.href}
                        data-testid={`nav-${item.label.toLowerCase().replace(/\s+/g, "-")}`}
                        onClick={() => setMobileOpen(false)}
                      >
                        <i className={`bi ${item.icon}`}></i>
                        <span className="link-title">{item.label}</span>
                      </Link>
                    </li>
                  ))}
                </li>
              ))}
            </ul>
            {/* End Nav */}

          </div>
        </div>
        {/* End Aside Body */}
      </aside>

      {/* Header */}
      <header className="header fixed-top">
        <div className="header-inner">
          <div className="header-left-col">
            {/* Mobile toggle */}
            <button
              className="aside-toggle-mobile border-0 bg-transparent p-0"
              onClick={() => setMobileOpen(!mobileOpen)}
              data-testid="btn-mobile-sidebar"
            >
              <i className="bi bi-list fs-3"></i>
            </button>
          </div>
          <div className="header-right-col">
            <div className="header-right">
              <ul className="nav justify-content-end align-items-center header-nav-list">
                <li>
                  <button className="header-icon-btn" data-testid="btn-notifications">
                    <i className="bi bi-bell-fill"></i>
                  </button>
                </li>
                <li>
                  {/* User Dropdown */}
                  <div className="user" ref={userMenuRef}>
                    <button
                      className="avatar avatar-sm rounded-circle header-avatar-btn"
                      onClick={() => setUserMenuOpen(!userMenuOpen)}
                      data-testid="btn-user-menu"
                    >
                      <i className="bi bi-person-fill"></i>
                    </button>
                    {userMenuOpen && (
                      <div className="dropdown-menu dropdown-menu-right show">
                        <div className="dropdown-item-text">
                          <h6 className="mb-0">{admin.name || "Admin"}</h6>
                          <span className="text-muted" style={{ fontSize: "0.8rem" }}>{admin.email}</span>
                        </div>
                        <div className="dropdown-divider"></div>
                        <Link
                          href="/admin/settings"
                          className="dropdown-item"
                          onClick={() => setUserMenuOpen(false)}
                        >
                          <i className="bi bi-gear me-2"></i>
                          Settings
                        </Link>
                        <button
                          className="dropdown-item text-danger"
                          onClick={handleLogout}
                          data-testid="menu-logout"
                        >
                          <i className="bi bi-box-arrow-right me-2"></i>
                          Sign Out
                        </button>
                      </div>
                    )}
                  </div>
                  {/* End User Dropdown */}
                </li>
              </ul>
            </div>
          </div>
        </div>
      </header>

      {/* Main Area */}
      <main className="main-area">
        <div className="main-content">
          {children}
        </div>
      </main>
    </>
  );
}
