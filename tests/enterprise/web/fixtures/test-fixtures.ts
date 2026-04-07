// ===========================================================================
// Playwright Fixtures — Shared auth state, page objects
// ===========================================================================

import { test as base, expect } from '@playwright/test';
import { LoginPage, DashboardPage, SidebarNav, DriversPage, TripsPage } from '../pages';

type JagoFixtures = {
  loginPage: LoginPage;
  dashboardPage: DashboardPage;
  sidebar: SidebarNav;
  driversPage: DriversPage;
  tripsPage: TripsPage;
  authenticatedPage: DashboardPage;
};

export const test = base.extend<JagoFixtures>({
  loginPage: async ({ page }, use) => {
    await use(new LoginPage(page));
  },

  dashboardPage: async ({ page }, use) => {
    await use(new DashboardPage(page));
  },

  sidebar: async ({ page }, use) => {
    await use(new SidebarNav(page));
  },

  driversPage: async ({ page }, use) => {
    await use(new DriversPage(page));
  },

  tripsPage: async ({ page }, use) => {
    await use(new TripsPage(page));
  },

  // Provides a page that's already logged in
  authenticatedPage: async ({ page }, use) => {
    const login = new LoginPage(page);
    await login.goto();

    const adminEmail = process.env.TEST_ADMIN_EMAIL || 'kiranatmakuri518@gmail.com';
    const adminPassword = process.env.TEST_ADMIN_PASSWORD || 'admin123';

    await login.loginAndWaitForDashboard(adminEmail, adminPassword);
    const dashboard = new DashboardPage(page);
    await use(dashboard);
  },
});

export { expect };
