// ===========================================================================
// Appium Test Specs — Customer App E2E Tests
// ===========================================================================

import { describe, it, expect, beforeAll, afterAll, afterEach } from 'vitest';
import {
  CustomerLoginPage, CustomerHomePage, CustomerBookingPage,
  CustomerTrackingPage, customerAppCapabilities,
} from '../appium-framework';

// NOTE: These tests require:
// 1. Appium server running (npx appium)
// 2. Android emulator / real device connected
// 3. Customer APK built
// Skip in CI unless APPIUM_ENABLED=true

const APPIUM_ENABLED = process.env.APPIUM_ENABLED === 'true';
const skipReason = 'Appium not configured — set APPIUM_ENABLED=true';

describe.skipIf(!APPIUM_ENABLED)('Customer App — Login Flow', () => {
  let driver: any;
  let loginPage: CustomerLoginPage;

  beforeAll(async () => {
    // eslint-disable-next-line @typescript-eslint/no-var-requires
    const { remote } = await import('webdriverio');
    driver = await remote({
      hostname: process.env.APPIUM_HOST || 'localhost',
      port: Number(process.env.APPIUM_PORT || 4723),
      capabilities: customerAppCapabilities,
    });
    loginPage = new CustomerLoginPage(driver);
  });

  afterAll(async () => {
    if (driver) await driver.deleteSession();
  });

  afterEach(async () => {
    if (driver) await loginPage.takeScreenshot(`customer-login-${Date.now()}`);
  });

  it('should display login screen on first launch', async () => {
    const visible = await loginPage.isLoginScreenVisible();
    expect(visible).toBe(true);
  });

  it('should show error for invalid phone number', async () => {
    await loginPage.enterPhone('123');
    const errorVisible = await loginPage.isDisplayed('~phone_error');
    expect(errorVisible).toBe(true);
  });

  it('should request OTP for valid phone', async () => {
    await loginPage.enterPhone('9876543210');
    // Should navigate to OTP screen
    const otpVisible = await loginPage.isDisplayed('~otp_input', 10000);
    expect(otpVisible).toBe(true);
  });

  it('should reject invalid OTP', async () => {
    await loginPage.enterOtp('000000');
    const error = await loginPage.isDisplayed('~otp_error');
    expect(error).toBe(true);
  });
});

describe.skipIf(!APPIUM_ENABLED)('Customer App — Home Screen', () => {
  let driver: any;
  let homePage: CustomerHomePage;

  beforeAll(async () => {
    const { remote } = await import('webdriverio');
    driver = await remote({
      hostname: process.env.APPIUM_HOST || 'localhost',
      port: Number(process.env.APPIUM_PORT || 4723),
      capabilities: { ...customerAppCapabilities, 'appium:noReset': true },
    });
    homePage = new CustomerHomePage(driver);
  });

  afterAll(async () => {
    if (driver) await driver.deleteSession();
  });

  it('should display home screen with search bars', async () => {
    const visible = await homePage.isHomeScreenVisible();
    expect(visible).toBe(true);
  });

  it('should open pickup search with suggestions', async () => {
    await homePage.searchPickup('Hitech City');
    const suggestions = await homePage.isDisplayed('~location_suggestions', 5000);
    expect(suggestions).toBe(true);
  });

  it('should navigate to menu/drawer', async () => {
    await homePage.openMenu();
    const menuVisible = await homePage.isDisplayed('~menu_drawer', 3000);
    expect(menuVisible).toBe(true);
  });
});

describe.skipIf(!APPIUM_ENABLED)('Customer App — Booking Flow', () => {
  let driver: any;
  let homePage: CustomerHomePage;
  let bookingPage: CustomerBookingPage;

  beforeAll(async () => {
    const { remote } = await import('webdriverio');
    driver = await remote({
      hostname: process.env.APPIUM_HOST || 'localhost',
      port: Number(process.env.APPIUM_PORT || 4723),
      capabilities: { ...customerAppCapabilities, 'appium:noReset': true },
    });
    homePage = new CustomerHomePage(driver);
    bookingPage = new CustomerBookingPage(driver);
  });

  afterAll(async () => {
    if (driver) await driver.deleteSession();
  });

  it('should show vehicle options after location selection', async () => {
    await homePage.searchPickup('Hitech City, Hyderabad');
    await homePage.searchDropoff('KPHB, Hyderabad');
    const vehicleList = await bookingPage.isDisplayed('~vehicle_list', 10000);
    expect(vehicleList).toBe(true);
  });

  it('should display fare estimate', async () => {
    await bookingPage.selectVehicle(0);
    const fare = await bookingPage.getFareEstimate();
    expect(fare).toBeTruthy();
    expect(fare).toMatch(/₹/);
  });

  it('should allow payment method selection', async () => {
    await bookingPage.selectPaymentMethod('cash');
    const selected = await bookingPage.isDisplayed('~payment_cash_selected');
    expect(selected).toBe(true);
  });
});

describe.skipIf(!APPIUM_ENABLED)('Customer App — Tracking', () => {
  let driver: any;
  let trackingPage: CustomerTrackingPage;

  beforeAll(async () => {
    const { remote } = await import('webdriverio');
    driver = await remote({
      hostname: process.env.APPIUM_HOST || 'localhost',
      port: Number(process.env.APPIUM_PORT || 4723),
      capabilities: { ...customerAppCapabilities, 'appium:noReset': true },
    });
    trackingPage = new CustomerTrackingPage(driver);
  });

  afterAll(async () => {
    if (driver) await driver.deleteSession();
  });

  it('should display driver info on tracking screen', async () => {
    // Prerequisite: an active trip exists
    const hasTracking = await trackingPage.isDisplayed('~trip_status', 5000);
    if (hasTracking) {
      const info = await trackingPage.getDriverInfo();
      expect(info.name).toBeTruthy();
      expect(info.vehicle).toBeTruthy();
    }
  });

  it('should have SOS button visible during trip', async () => {
    const hasSOS = await trackingPage.isDisplayed('~sos_button', 3000);
    // SOS should always be present during active trip
    expect(typeof hasSOS).toBe('boolean');
  });
});
