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
import HeatMap from "@/pages/admin/heat-map";
import FleetView from "@/pages/admin/fleet-view";
import CarSharing from "@/pages/admin/car-sharing";
import IntercityCarSharing from "@/pages/admin/intercity-carsharing";
import ParcelRefunds from "@/pages/admin/parcel-refunds";
import SafetyAlerts from "@/pages/admin/safety-alerts";
import Banners from "@/pages/admin/banners";
import Discounts from "@/pages/admin/discounts";
import SpinWheel from "@/pages/admin/spin-wheel";
import Notifications from "@/pages/admin/notifications";
import DriverLevels from "@/pages/admin/driver-levels";
import CustomerLevels from "@/pages/admin/customer-levels";
import CustomerWallet from "@/pages/admin/customer-wallet";
import WalletBonus from "@/pages/admin/wallet-bonus";
import Employees from "@/pages/admin/employees";
import Newsletter from "@/pages/admin/newsletter";
import Subscriptions from "@/pages/admin/subscriptions";
import RevenueModel from "@/pages/admin/revenue-model";
import DriverWalletPage from "@/pages/admin/driver-wallet";
import RefundRequestsPage from "@/pages/admin/refund-requests";
import ApiDocsPage from "@/pages/admin/api-docs";
import AppDesignPage from "@/pages/admin/app-design";
import ParcelAttributes from "@/pages/admin/parcel-attributes";
import VehicleAttributes from "@/pages/admin/vehicle-attributes";
import VehicleRequests from "@/pages/admin/vehicle-requests";
import ParcelFares from "@/pages/admin/parcel-fares";
import SurgePricing from "@/pages/admin/surge-pricing";
import Reports from "@/pages/admin/reports";
import Chatting from "@/pages/admin/chatting";
import CallLogs from "@/pages/admin/call-logs";
import BusinessSetup from "@/pages/admin/business-setup";
import PagesMedia from "@/pages/admin/pages-media";
import Configurations from "@/pages/admin/configurations";
import B2BCompanies from "@/pages/admin/b2b-companies";
import IntercityRoutes from "@/pages/admin/intercity-routes";
import Insurance from "@/pages/admin/insurance";
import DriverEarnings from "@/pages/admin/driver-earnings";
import Referrals from "@/pages/admin/referrals";
import { PrivacyPage, TermsPage, AboutPage, ContactPage } from "@/pages/policy-pages";
import NotFound from "@/pages/not-found";

function AdminLogout() {
  const [, setLocation] = useLocation();
  useEffect(() => {
    localStorage.removeItem("jago-admin");
    setLocation("/admin/login");
  }, []);
  return null;
}

function AdminRoutes() {
  return (
    <AdminLayout>
      <Switch>
        {/* Dashboard */}
        <Route path="/admin/dashboard" component={Dashboard} />
        <Route path="/admin/heat-map" component={HeatMap} />
        <Route path="/admin/fleet-view" component={FleetView} />
        {/* Zone Management */}
        <Route path="/admin/zones" component={Zones} />
        {/* Trip Management */}
        <Route path="/admin/trips" component={Trips} />
        <Route path="/admin/car-sharing" component={CarSharing} />
        <Route path="/admin/intercity-carsharing" component={IntercityCarSharing} />
        <Route path="/admin/parcel-refunds" component={ParcelRefunds} />
        <Route path="/admin/safety-alerts" component={SafetyAlerts} />
        {/* Promotion Management */}
        <Route path="/admin/banners" component={Banners} />
        <Route path="/admin/coupons" component={Coupons} />
        <Route path="/admin/discounts" component={Discounts} />
        <Route path="/admin/spin-wheel" component={SpinWheel} />
        <Route path="/admin/notifications" component={Notifications} />
        {/* User Management */}
        <Route path="/admin/driver-levels" component={DriverLevels} />
        <Route path="/admin/drivers" component={Drivers} />
        <Route path="/admin/withdrawals" component={Withdrawals} />
        <Route path="/admin/customer-levels" component={CustomerLevels} />
        <Route path="/admin/customers" component={Customers} />
        <Route path="/admin/customer-wallet" component={CustomerWallet} />
        <Route path="/admin/wallet-bonus" component={WalletBonus} />
        <Route path="/admin/employees" component={Employees} />
        <Route path="/admin/newsletter" component={Newsletter} />
        <Route path="/admin/subscriptions" component={Subscriptions} />
        <Route path="/admin/revenue-model" component={RevenueModel} />
        {/* Parcel Management */}
        <Route path="/admin/parcel-attributes" component={ParcelAttributes} />
        {/* Vehicle Management */}
        <Route path="/admin/vehicle-attributes" component={VehicleAttributes} />
        <Route path="/admin/vehicles" component={VehicleCategories} />
        <Route path="/admin/vehicle-requests" component={VehicleRequests} />
        {/* Fare Management */}
        <Route path="/admin/fares" component={Fares} />
        <Route path="/admin/cancellation-reasons" component={CancellationReasonsPage} />
        <Route path="/admin/parcel-fares" component={ParcelFares} />
        <Route path="/admin/surge-pricing" component={SurgePricing} />
        {/* Transactions & Reports */}
        <Route path="/admin/transactions" component={Transactions} />
        <Route path="/admin/reports" component={Reports} />
        {/* Help & Support */}
        <Route path="/admin/chatting" component={Chatting} />
        <Route path="/admin/call-logs" component={CallLogs} />
        {/* Blog Management */}
        <Route path="/admin/blogs" component={BlogsPage} />
        {/* Reviews */}
        <Route path="/admin/reviews" component={Reviews} />
        {/* Business Management */}
        <Route path="/admin/business-setup" component={BusinessSetup} />
        <Route path="/admin/pages-media" component={PagesMedia} />
        <Route path="/admin/configurations" component={Configurations} />
        <Route path="/admin/settings" component={Settings} />
        {/* B2B / Porter */}
        <Route path="/admin/b2b-companies" component={B2BCompanies} />
        {/* Intercity Routes */}
        <Route path="/admin/intercity-routes" component={IntercityRoutes} />
        {/* Insurance */}
        <Route path="/admin/insurance" component={Insurance} />
        {/* Driver Earnings */}
        <Route path="/admin/driver-earnings" component={DriverEarnings} />
        <Route path="/admin/driver-wallet" component={DriverWalletPage} />
        <Route path="/admin/refund-requests" component={RefundRequestsPage} />
        <Route path="/admin/api-docs" component={ApiDocsPage} />
        <Route path="/admin/app-design" component={AppDesignPage} />
        {/* Referrals */}
        <Route path="/admin/referrals" component={Referrals} />
        <Route><Redirect to="/admin/dashboard" /></Route>
      </Switch>
    </AdminLayout>
  );
}

function Router() {
  return (
    <Switch>
      <Route path="/" component={LandingPage} />
      <Route path="/about-us" component={AboutPage} />
      <Route path="/privacy" component={PrivacyPage} />
      <Route path="/terms" component={TermsPage} />
      <Route path="/contact-us" component={ContactPage} />
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
