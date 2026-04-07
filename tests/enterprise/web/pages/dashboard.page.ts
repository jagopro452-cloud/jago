// ===========================================================================
// POM: Dashboard Page — Admin Panel
// ===========================================================================

import { type Page, type Locator, expect } from '@playwright/test';

export class DashboardPage {
  readonly page: Page;
  readonly totalTripsCard: Locator;
  readonly totalRevenueCard: Locator;
  readonly activeDriversCard: Locator;
  readonly completionRateCard: Locator;
  readonly chartContainer: Locator;
  readonly recentTripsTable: Locator;
  readonly loadingSpinner: Locator;

  constructor(page: Page) {
    this.page = page;
    this.totalTripsCard = page.locator('[data-testid="total-trips"], :text("Total Trips")').first();
    this.totalRevenueCard = page.locator('[data-testid="total-revenue"], :text("Revenue")').first();
    this.activeDriversCard = page.locator('[data-testid="active-drivers"], :text("Active Drivers"), :text("Online Drivers")').first();
    this.completionRateCard = page.locator('[data-testid="completion-rate"], :text("Completion")').first();
    this.chartContainer = page.locator('canvas, [class*="chart"], [class*="recharts"]').first();
    this.recentTripsTable = page.locator('table, [class*="trip-list"], [class*="data-table"]').first();
    this.loadingSpinner = page.locator('[class*="spinner"], [class*="loading"], [class*="skeleton"]').first();
  }

  async goto() {
    await this.page.goto('/admin/dashboard');
    await this.page.waitForLoadState('networkidle');
  }

  async waitForDataLoad(timeout = 10_000) {
    // Wait for loading to finish
    try {
      await this.loadingSpinner.waitFor({ state: 'hidden', timeout });
    } catch {
      // Spinner might not exist — that's fine
    }
  }

  async expectKPICardsVisible() {
    // At least one stat card should be visible
    const statCards = this.page.locator('[class*="card"], [class*="stat"], [class*="kpi"]');
    await expect(statCards.first()).toBeVisible();
  }

  async getKPIValues(): Promise<Record<string, string>> {
    const cards = await this.page.locator('[class*="card"], [class*="stat"]').all();
    const values: Record<string, string> = {};
    for (const card of cards) {
      const text = await card.textContent();
      if (text) values[text.trim().slice(0, 30)] = text.trim();
    }
    return values;
  }

  async expectChartRendered() {
    await expect(this.chartContainer).toBeVisible({ timeout: 10_000 });
  }
}
