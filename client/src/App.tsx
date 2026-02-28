import { Switch, Route, Redirect, useLocation } from "wouter";
import { useEffect } from "react";
import { queryClient } from "./lib/queryClient";
import { QueryClientProvider } from "@tanstack/react-query";
import { Toaster } from "@/components/ui/toaster";
import { TooltipProvider } from "@/components/ui/tooltip";
import { ThemeProvider } from "@/components/theme-provider";
import LandingPage from "@/pages/landing";
import AdminLogin from "@/pages/admin/login";
import AdminLayout from "@/pages/admin/layout";
import Dashboard from "@/pages/admin/dashboard";
import Trips from "@/pages/admin/trips";
import Customers from "@/pages/admin/customers";
import Drivers from "@/pages/admin/drivers";
import VehicleCategories from "@/pages/admin/vehicle-categories";
import Zones from "@/pages/admin/zones";
import Fares from "@/pages/admin/fares";
import Transactions from "@/pages/admin/transactions";
import Coupons from "@/pages/admin/coupons";
import Reviews from "@/pages/admin/reviews";
import Settings from "@/pages/admin/settings";
import BlogsPage from "@/pages/admin/blogs";
import Withdrawals from "@/pages/admin/withdrawals";
import CancellationReasonsPage from "@/pages/admin/cancellation-reasons";
import NotFound from "@/pages/not-found";

function AdminLogout() {
  const [, setLocation] = useLocation();
  useEffect(() => {
    localStorage.removeItem("jago-admin");
    setLocation("/admin/auth/login");
  }, []);
  return null;
}

function AdminRoutes() {
  return (
    <AdminLayout>
      <Switch>
        <Route path="/admin/dashboard" component={Dashboard} />
        <Route path="/admin/trips" component={Trips} />
        <Route path="/admin/customers" component={Customers} />
        <Route path="/admin/drivers" component={Drivers} />
        <Route path="/admin/vehicles" component={VehicleCategories} />
        <Route path="/admin/zones" component={Zones} />
        <Route path="/admin/fares" component={Fares} />
        <Route path="/admin/transactions" component={Transactions} />
        <Route path="/admin/coupons" component={Coupons} />
        <Route path="/admin/reviews" component={Reviews} />
        <Route path="/admin/settings" component={Settings} />
        <Route path="/admin/blogs" component={BlogsPage} />
        <Route path="/admin/withdrawals" component={Withdrawals} />
        <Route path="/admin/cancellation-reasons" component={CancellationReasonsPage} />
        <Route><Redirect to="/admin/dashboard" /></Route>
      </Switch>
    </AdminLayout>
  );
}

function Router() {
  return (
    <Switch>
      <Route path="/" component={LandingPage} />
      <Route path="/admin/login" component={AdminLogin} />
      <Route path="/admin/auth/login" component={AdminLogin} />
      <Route path="/admin/auth/logout" component={AdminLogout} />
      <Route path="/admin/:rest*" component={AdminRoutes} />
      <Route component={NotFound} />
    </Switch>
  );
}

export default function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <ThemeProvider>
        <TooltipProvider>
          <Toaster />
          <Router />
        </TooltipProvider>
      </ThemeProvider>
    </QueryClientProvider>
  );
}
