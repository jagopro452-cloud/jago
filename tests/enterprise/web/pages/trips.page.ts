// ===========================================================================
// POM: Trips Management Page
// ===========================================================================

import { type Page, type Locator, expect } from '@playwright/test';

export class TripsPage {
  readonly page: Page;
  readonly searchInput: Locator;
  readonly tripTable: Locator;
  readonly tripRows: Locator;
  readonly statusFilter: Locator;
  readonly dateFromInput: Locator;
  readonly dateToInput: Locator;
  readonly activeTab: Locator;
  readonly historyTab: Locator;
  readonly cancelledTab: Locator;
  readonly refreshButton: Locator;
  readonly tripDetailModal: Locator;

  constructor(page: Page) {
    this.page = page;
    this.searchInput = page.locator('input[placeholder*="search" i], input[type="search"]').first();
    this.tripTable = page.locator('table').first();
    this.tripRows = page.locator('table tbody tr');
    this.statusFilter = page.locator('select:near(:text("Status"))').first();
    this.dateFromInput = page.locator('input[type="date"]').first();
    this.dateToInput = page.locator('input[type="date"]').nth(1);
    this.activeTab = page.locator('button:has-text("Active"), [role="tab"]:has-text("Active")').first();
    this.historyTab = page.locator('button:has-text("History"), [role="tab"]:has-text("History"), a:has-text("History")').first();
    this.cancelledTab = page.locator('button:has-text("Cancelled"), [role="tab"]:has-text("Cancelled")').first();
    this.refreshButton = page.locator('button:has-text("Refresh"), button[class*="refresh"]').first();
    this.tripDetailModal = page.locator('[class*="modal"], [role="dialog"]').first();
  }

  async goto() {
    await this.page.goto('/admin/trips');
    await this.page.waitForLoadState('networkidle');
  }

  async gotoActive() {
    await this.page.goto('/admin/rides/active');
    await this.page.waitForLoadState('networkidle');
  }

  async gotoHistory() {
    await this.page.goto('/admin/rides/history');
    await this.page.waitForLoadState('networkidle');
  }

  async search(query: string) {
    await this.searchInput.fill(query);
    await this.page.waitForTimeout(500);
    await this.page.waitForLoadState('networkidle');
  }

  async getTripCount(): Promise<number> {
    return this.tripRows.count();
  }

  async clickTrip(index: number) {
    await this.tripRows.nth(index).click();
    await this.page.waitForTimeout(500);
  }

  async expectTripsLoaded() {
    await expect(this.tripTable).toBeVisible({ timeout: 10_000 });
  }

  async forceCancel(tripIndex: number) {
    await this.tripRows.nth(tripIndex).click();
    const cancelBtn = this.page.locator('button:has-text("Force Cancel"), button:has-text("Cancel Trip")').first();
    if (await cancelBtn.isVisible()) {
      await cancelBtn.click();
      // Confirm dialog
      const confirmBtn = this.page.locator('[role="dialog"] button:has-text("Confirm"), [role="dialog"] button:has-text("Yes")').first();
      if (await confirmBtn.isVisible()) {
        await confirmBtn.click();
      }
    }
  }
}
