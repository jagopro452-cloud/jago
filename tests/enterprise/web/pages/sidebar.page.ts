// ===========================================================================
// POM: Sidebar Navigation — Admin Panel
// ===========================================================================

import { type Page, type Locator, expect } from '@playwright/test';

export class SidebarNav {
  readonly page: Page;
  readonly sidebar: Locator;
  readonly menuItems: Locator;

  // Navigation links
  readonly dashboard: Locator;
  readonly trips: Locator;
  readonly drivers: Locator;
  readonly customers: Locator;
  readonly vehicles: Locator;
  readonly fares: Locator;
  readonly parcels: Locator;
  readonly payments: Locator;
  readonly coupons: Locator;
  readonly reports: Locator;
  readonly settings: Locator;
  readonly fleetView: Locator;
  readonly heatMap: Locator;

  constructor(page: Page) {
    this.page = page;
    this.sidebar = page.locator('nav, [class*="sidebar"], [class*="side-nav"], aside').first();
    this.menuItems = page.locator('nav a, [class*="sidebar"] a, [class*="nav-link"]');

    this.dashboard = page.locator('a[href*="dashboard"], a:has-text("Dashboard")').first();
    this.trips = page.locator('a[href*="trips"], a:has-text("Trips")').first();
    this.drivers = page.locator('a[href*="drivers"]:not([href*="driver-"]), a:has-text("Drivers")').first();
    this.customers = page.locator('a[href*="customers"], a:has-text("Customers")').first();
    this.vehicles = page.locator('a[href*="vehicle"], a:has-text("Vehicles")').first();
    this.fares = page.locator('a[href*="fares"], a:has-text("Fares")').first();
    this.parcels = page.locator('a[href*="parcel"], a:has-text("Parcels")').first();
    this.payments = page.locator('a[href*="transaction"], a:has-text("Payments"), a:has-text("Transactions")').first();
    this.coupons = page.locator('a[href*="coupon"], a:has-text("Coupons")').first();
    this.reports = page.locator('a[href*="report"], a:has-text("Reports")').first();
    this.settings = page.locator('a[href*="setting"], a:has-text("Settings")').first();
    this.fleetView = page.locator('a[href*="fleet"], a:has-text("Fleet")').first();
    this.heatMap = page.locator('a[href*="heat"], a:has-text("Heatmap")').first();
  }

  async navigateTo(linkLocator: Locator) {
    await linkLocator.click();
    await this.page.waitForLoadState('networkidle');
  }

  async expectSidebarVisible() {
    await expect(this.sidebar).toBeVisible();
  }

  async getAllMenuLinks(): Promise<string[]> {
    const links = await this.menuItems.all();
    const hrefs: string[] = [];
    for (const link of links) {
      const href = await link.getAttribute('href');
      if (href) hrefs.push(href);
    }
    return hrefs;
  }

  async navigateAndVerify(linkLocator: Locator, expectedUrlPattern: RegExp) {
    await this.navigateTo(linkLocator);
    await expect(this.page).toHaveURL(expectedUrlPattern);
  }
}
