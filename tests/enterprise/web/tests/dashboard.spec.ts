// ===========================================================================
// E2E: Dashboard Tests
// ===========================================================================

import { test, expect } from '../fixtures/test-fixtures';

test.describe('Admin Dashboard', () => {
  test.beforeEach(async ({ page }) => {
    // Login first
    const { LoginPage } = await import('../pages');
    const lp = new LoginPage(page);
    await lp.goto();
    await lp.loginAndWaitForDashboard(
      process.env.TEST_ADMIN_EMAIL || 'kiranatmakuri518@gmail.com',
      process.env.TEST_ADMIN_PASSWORD || 'admin123'
    );
  });

  test('should load dashboard with KPI cards', async ({ page, dashboardPage }) => {
    await dashboardPage.goto();
    await dashboardPage.waitForDataLoad();
    await dashboardPage.expectKPICardsVisible();
  });

  test('should display revenue chart', async ({ dashboardPage }) => {
    await dashboardPage.goto();
    await dashboardPage.waitForDataLoad();
    await dashboardPage.expectChartRendered();
  });

  test('should load within 3 seconds', async ({ page }) => {
    const start = Date.now();
    await page.goto('/admin/dashboard');
    await page.waitForLoadState('networkidle');
    const duration = Date.now() - start;
    expect(duration).toBeLessThan(3000);
  });

  test('should display correct KPI data types (numbers, not NaN)', async ({ dashboardPage }) => {
    await dashboardPage.goto();
    await dashboardPage.waitForDataLoad();
    const bodyText = await dashboardPage.page.textContent('body');
    expect(bodyText).not.toContain('NaN');
    expect(bodyText).not.toContain('undefined');
  });

  test('should be responsive on mobile viewport', async ({ page }) => {
    await page.setViewportSize({ width: 375, height: 812 });
    await page.goto('/admin/dashboard');
    await page.waitForLoadState('networkidle');
    // Content should be readable — no horizontal scrollbar
    const bodyWidth = await page.evaluate(() => document.body.scrollWidth);
    const viewportWidth = 375;
    expect(bodyWidth).toBeLessThanOrEqual(viewportWidth + 50); // small tolerance
  });
});

test.describe('Dashboard Navigation', () => {
  test.beforeEach(async ({ page }) => {
    const { LoginPage } = await import('../pages');
    const lp = new LoginPage(page);
    await lp.goto();
    await lp.loginAndWaitForDashboard(
      process.env.TEST_ADMIN_EMAIL || 'kiranatmakuri518@gmail.com',
      process.env.TEST_ADMIN_PASSWORD || 'admin123'
    );
  });

  test('sidebar should be visible and navigable', async ({ page, sidebar }) => {
    await sidebar.expectSidebarVisible();
    const links = await sidebar.getAllMenuLinks();
    expect(links.length).toBeGreaterThan(5);
  });

  test('should navigate to drivers page', async ({ page, sidebar }) => {
    await sidebar.navigateTo(sidebar.drivers);
    await expect(page).toHaveURL(/driver/);
  });

  test('should navigate to trips page', async ({ page, sidebar }) => {
    await sidebar.navigateTo(sidebar.trips);
    await expect(page).toHaveURL(/trip/);
  });

  test('should navigate to all admin pages without errors', async ({ page, sidebar }) => {
    const adminPages = [
      '/admin/dashboard',
      '/admin/drivers',
      '/admin/customers',
      '/admin/trips',
      '/admin/vehicle-categories',
      '/admin/fares',
      '/admin/coupons',
      '/admin/transactions',
      '/admin/reports',
      '/admin/settings',
      '/admin/fleet-view',
      '/admin/complaints',
      '/admin/notifications',
    ];

    const errors: string[] = [];
    page.on('pageerror', e => errors.push(`${page.url()}: ${e.message}`));

    for (const path of adminPages) {
      await page.goto(path);
      await page.waitForLoadState('networkidle');
      await page.waitForTimeout(500);
    }

    if (errors.length) {
      console.warn('Page errors found:', errors);
    }
    // Critical: no uncaught exceptions
    const criticalErrors = errors.filter(e =>
      !e.includes('ResizeObserver') && !e.includes('Script error')
    );
    expect(criticalErrors).toHaveLength(0);
  });
});
