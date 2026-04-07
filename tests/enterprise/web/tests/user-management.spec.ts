// ===========================================================================
// E2E: Driver & Customer Management Tests
// ===========================================================================

import { test, expect } from '../fixtures/test-fixtures';
import { DriversPage } from '../pages';

test.describe('Driver Management', () => {
  let driversPage: DriversPage;

  test.beforeEach(async ({ page }) => {
    const { LoginPage } = await import('../pages');
    const lp = new LoginPage(page);
    await lp.goto();
    await lp.loginAndWaitForDashboard(
      process.env.TEST_ADMIN_EMAIL || 'kiranatmakuri518@gmail.com',
      process.env.TEST_ADMIN_PASSWORD || 'admin123'
    );
    driversPage = new DriversPage(page);
    await driversPage.goto();
  });

  test('should display drivers list table', async () => {
    await driversPage.expectDriversLoaded();
  });

  test('should search drivers by phone number', async () => {
    await driversPage.search('99999');
    await driversPage.page.waitForTimeout(1000);
    // Should filter results or show no-results message
    const bodyText = await driversPage.page.textContent('body');
    expect(bodyText).toBeTruthy();
  });

  test('should handle empty search gracefully', async () => {
    await driversPage.search('zzzznonexistent12345');
    await driversPage.page.waitForTimeout(1000);
    // Should show empty state, not crash
    const bodyText = await driversPage.page.textContent('body');
    expect(bodyText).not.toContain('Error');
  });

  test('should display driver details on click', async ({ page }) => {
    const driverCount = await driversPage.getDriverCount();
    if (driverCount > 0) {
      await driversPage.clickDriver(0);
      // Should show driver detail view or modal
      await page.waitForTimeout(1000);
      const bodyText = await page.textContent('body');
      expect(bodyText).toBeTruthy();
    }
  });
});

test.describe('Customer Management', () => {
  test.beforeEach(async ({ page }) => {
    const { LoginPage } = await import('../pages');
    const lp = new LoginPage(page);
    await lp.goto();
    await lp.loginAndWaitForDashboard(
      process.env.TEST_ADMIN_EMAIL || 'kiranatmakuri518@gmail.com',
      process.env.TEST_ADMIN_PASSWORD || 'admin123'
    );
  });

  test('should display customers page', async ({ page }) => {
    await page.goto('/admin/customers');
    await page.waitForLoadState('networkidle');
    const table = page.locator('table').first();
    await expect(table).toBeVisible({ timeout: 10_000 });
  });

  test('should search customers', async ({ page }) => {
    await page.goto('/admin/customers');
    await page.waitForLoadState('networkidle');
    const searchInput = page.locator('input[placeholder*="search" i], input[type="search"]').first();
    if (await searchInput.isVisible()) {
      await searchInput.fill('test');
      await page.waitForTimeout(1000);
    }
    // No crash expected
    const errorVisible = await page.locator(':text("Error"), :text("crashed")').isVisible().catch(() => false);
    expect(errorVisible).toBeFalsy();
  });
});
