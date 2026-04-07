// ===========================================================================
// POM: Drivers Management Page
// ===========================================================================

import { type Page, type Locator, expect } from '@playwright/test';

export class DriversPage {
  readonly page: Page;
  readonly searchInput: Locator;
  readonly driverTable: Locator;
  readonly driverRows: Locator;
  readonly statusFilter: Locator;
  readonly verificationFilter: Locator;
  readonly exportButton: Locator;
  readonly addDriverButton: Locator;
  readonly paginationNext: Locator;
  readonly paginationPrev: Locator;
  readonly totalCount: Locator;

  constructor(page: Page) {
    this.page = page;
    this.searchInput = page.locator('input[placeholder*="search" i], input[type="search"]').first();
    this.driverTable = page.locator('table').first();
    this.driverRows = page.locator('table tbody tr');
    this.statusFilter = page.locator('select:near(:text("Status")), [class*="filter"]').first();
    this.verificationFilter = page.locator('select:near(:text("Verification")), select:near(:text("Verified"))').first();
    this.exportButton = page.locator('button:has-text("Export"), button:has-text("Download")').first();
    this.addDriverButton = page.locator('button:has-text("Add"), button:has-text("New Driver")').first();
    this.paginationNext = page.locator('button:has-text("Next"), [aria-label="Next"]').first();
    this.paginationPrev = page.locator('button:has-text("Previous"), [aria-label="Previous"]').first();
    this.totalCount = page.locator(':text("total"), :text("showing"), :text("of")').first();
  }

  async goto() {
    await this.page.goto('/admin/drivers');
    await this.page.waitForLoadState('networkidle');
  }

  async search(query: string) {
    await this.searchInput.fill(query);
    await this.page.waitForTimeout(500); // debounce
    await this.page.waitForLoadState('networkidle');
  }

  async getDriverCount(): Promise<number> {
    return this.driverRows.count();
  }

  async clickDriver(index: number) {
    await this.driverRows.nth(index).click();
    await this.page.waitForLoadState('networkidle');
  }

  async expectDriversLoaded() {
    await expect(this.driverTable).toBeVisible({ timeout: 10_000 });
  }

  async expectNoResults() {
    const count = await this.driverRows.count();
    expect(count).toBe(0);
  }
}
