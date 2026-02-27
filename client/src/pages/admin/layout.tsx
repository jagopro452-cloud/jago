import { useLocation, Link } from "wouter";
import { useState } from "react";
import { useTheme } from "@/components/theme-provider";
import {
  LayoutDashboard, Car, Users, UserCheck, MapPin, DollarSign, Tag, Star,
  Settings, FileText, Wallet, XCircle, Menu, X, LogOut, Moon, Sun,
  Package, ChevronDown, ChevronRight, Bell, User2
} from "lucide-react";
import { Button } from "@/components/ui/button";
import { ScrollArea } from "@/components/ui/scroll-area";
import {
  DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuTrigger
} from "@/components/ui/dropdown-menu";

const navItems = [
  { label: "Dashboard", icon: LayoutDashboard, href: "/admin/dashboard" },
  { label: "Trip Requests", icon: Car, href: "/admin/trips" },
  { label: "Customers", icon: Users, href: "/admin/customers" },
  { label: "Drivers", icon: UserCheck, href: "/admin/drivers" },
  { label: "Vehicle Categories", icon: Car, href: "/admin/vehicles" },
  { label: "Zones", icon: MapPin, href: "/admin/zones" },
  { label: "Fare Management", icon: DollarSign, href: "/admin/fares" },
  { label: "Transactions", icon: DollarSign, href: "/admin/transactions" },
  { label: "Coupons", icon: Tag, href: "/admin/coupons" },
  { label: "Reviews", icon: Star, href: "/admin/reviews" },
  { label: "Blogs", icon: FileText, href: "/admin/blogs" },
  { label: "Withdrawals", icon: Wallet, href: "/admin/withdrawals" },
  { label: "Cancel Reasons", icon: XCircle, href: "/admin/cancellation-reasons" },
  { label: "Settings", icon: Settings, href: "/admin/settings" },
];

export default function AdminLayout({ children }: { children: React.ReactNode }) {
  const [location, setLocation] = useLocation();
  const [sidebarOpen, setSidebarOpen] = useState(true);
  const [mobileSidebarOpen, setMobileSidebarOpen] = useState(false);
  const { theme, setTheme } = useTheme();
  const admin = JSON.parse(localStorage.getItem("jago-admin") || '{"name":"Admin","email":"admin@jago.com"}');

  const handleLogout = () => {
    localStorage.removeItem("jago-admin");
    setLocation("/admin/login");
  };

  const SidebarContent = () => (
    <div className="flex flex-col h-full">
      {/* Logo */}
      <div className="flex items-center gap-3 px-4 h-16 border-b border-sidebar-border shrink-0">
        <div className="w-8 h-8 rounded-lg bg-blue-500 flex items-center justify-center shrink-0">
          <Car className="w-4 h-4 text-white" />
        </div>
        {(sidebarOpen || mobileSidebarOpen) && (
          <div>
            <div className="text-white font-bold text-lg leading-none">JAGO</div>
            <div className="text-blue-300 text-xs">Admin Panel</div>
          </div>
        )}
      </div>

      {/* Nav */}
      <ScrollArea className="flex-1 py-3">
        <nav className="px-2 space-y-0.5">
          {navItems.map(item => {
            const active = location === item.href || location.startsWith(item.href + "/");
            return (
              <Link key={item.href} href={item.href}>
                <div
                  className={`flex items-center gap-3 px-3 py-2.5 rounded-lg cursor-pointer transition-colors text-sm font-medium ${
                    active
                      ? "bg-sidebar-accent text-sidebar-accent-foreground"
                      : "text-sidebar-foreground/80 hover:bg-sidebar-accent/60 hover:text-sidebar-accent-foreground"
                  }`}
                  data-testid={`nav-${item.label.toLowerCase().replace(/\s+/g, '-')}`}
                  onClick={() => setMobileSidebarOpen(false)}
                >
                  <item.icon className="w-4 h-4 shrink-0" />
                  {(sidebarOpen || mobileSidebarOpen) && <span className="truncate">{item.label}</span>}
                </div>
              </Link>
            );
          })}
        </nav>
      </ScrollArea>

      {/* User */}
      {(sidebarOpen || mobileSidebarOpen) && (
        <div className="p-3 border-t border-sidebar-border shrink-0">
          <div className="flex items-center gap-3 px-2 py-2 rounded-lg bg-sidebar-accent/40">
            <div className="w-8 h-8 rounded-full bg-blue-500 flex items-center justify-center shrink-0">
              <User2 className="w-4 h-4 text-white" />
            </div>
            <div className="flex-1 min-w-0">
              <div className="text-sm font-medium text-sidebar-foreground truncate">{admin.name}</div>
              <div className="text-xs text-sidebar-foreground/60 truncate">{admin.role}</div>
            </div>
            <button onClick={handleLogout} className="text-sidebar-foreground/60 hover:text-sidebar-foreground shrink-0" data-testid="btn-logout">
              <LogOut className="w-4 h-4" />
            </button>
          </div>
        </div>
      )}
    </div>
  );

  return (
    <div className="flex h-screen overflow-hidden bg-background">
      {/* Desktop Sidebar */}
      <aside
        className={`hidden md:flex flex-col bg-sidebar border-r border-sidebar-border transition-all duration-300 shrink-0 ${sidebarOpen ? "w-60" : "w-16"}`}
      >
        <SidebarContent />
      </aside>

      {/* Mobile Sidebar Overlay */}
      {mobileSidebarOpen && (
        <div className="md:hidden fixed inset-0 z-50 flex">
          <div className="fixed inset-0 bg-black/60" onClick={() => setMobileSidebarOpen(false)} />
          <div className="relative w-64 h-full bg-sidebar border-r border-sidebar-border flex flex-col z-50">
            <SidebarContent />
          </div>
        </div>
      )}

      {/* Main */}
      <div className="flex flex-col flex-1 min-w-0">
        {/* Topbar */}
        <header className="h-16 border-b bg-card flex items-center justify-between px-4 gap-4 shrink-0">
          <div className="flex items-center gap-3">
            <button
              className="hidden md:flex items-center justify-center w-8 h-8 rounded-md hover:bg-muted"
              onClick={() => setSidebarOpen(!sidebarOpen)}
              data-testid="btn-sidebar-toggle"
            >
              <Menu className="w-4 h-4" />
            </button>
            <button
              className="md:hidden flex items-center justify-center w-8 h-8 rounded-md hover:bg-muted"
              onClick={() => setMobileSidebarOpen(true)}
              data-testid="btn-mobile-sidebar"
            >
              <Menu className="w-4 h-4" />
            </button>
            <h1 className="text-sm font-semibold text-foreground hidden sm:block">
              {navItems.find(n => location === n.href || location.startsWith(n.href + "/"))?.label || "JAGO Admin"}
            </h1>
          </div>
          <div className="flex items-center gap-2">
            <Button
              size="icon"
              variant="ghost"
              onClick={() => setTheme(theme === "dark" ? "light" : "dark")}
              data-testid="btn-theme-toggle"
            >
              {theme === "dark" ? <Sun className="w-4 h-4" /> : <Moon className="w-4 h-4" />}
            </Button>
            <Button size="icon" variant="ghost" data-testid="btn-notifications">
              <Bell className="w-4 h-4" />
            </Button>
            <DropdownMenu>
              <DropdownMenuTrigger asChild>
                <Button variant="ghost" size="sm" className="gap-2" data-testid="btn-user-menu">
                  <div className="w-7 h-7 rounded-full bg-blue-600 flex items-center justify-center">
                    <User2 className="w-3.5 h-3.5 text-white" />
                  </div>
                  <span className="hidden sm:block text-sm">{admin.name}</span>
                  <ChevronDown className="w-3 h-3" />
                </Button>
              </DropdownMenuTrigger>
              <DropdownMenuContent align="end">
                <DropdownMenuItem onClick={handleLogout} data-testid="menu-logout">
                  <LogOut className="w-4 h-4 mr-2" /> Logout
                </DropdownMenuItem>
              </DropdownMenuContent>
            </DropdownMenu>
          </div>
        </header>

        {/* Page Content */}
        <main className="flex-1 overflow-auto p-4 sm:p-6">
          {children}
        </main>
      </div>
    </div>
  );
}
