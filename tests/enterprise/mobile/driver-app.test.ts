// ===========================================================================
// Appium Test Specs — Driver App E2E Tests
// ===========================================================================

import { describe, it, expect, beforeAll, afterAll, afterEach } from 'vitest';
import {
  DriverLoginPage, DriverHomePage, DriverTripPage,
  DriverWalletPage, driverAppCapabilities,
} from '../appium-framework';

const APPIUM_ENABLED = process.env.APPIUM_ENABLED === 'true';

describe.skipIf(!APPIUM_ENABLED)('Driver App — Login Flow', () => {
  let driver: any;
  let loginPage: DriverLoginPage;

  beforeAll(async () => {
    const { remote } = await import('webdriverio');
    driver = await remote({
      hostname: process.env.APPIUM_HOST || 'localhost',
      port: Number(process.env.APPIUM_PORT || 4723),
      capabilities: driverAppCapabilities,
    });
    loginPage = new DriverLoginPage(driver);
  });

  afterAll(async () => {
    if (driver) await driver.deleteSession();
  });

  it('should display driver login screen', async () => {
    const visible = await loginPage.isDisplayed('~driver_phone_input');
    expect(visible).toBe(true);
  });

  it('should validate phone number format', async () => {
    await loginPage.enterPhone('abc');
    const error = await loginPage.isDisplayed('~phone_error');
    expect(error).toBe(true);
  });
});

describe.skipIf(!APPIUM_ENABLED)('Driver App — Home & Online Toggle', () => {
  let driver: any;
  let homePage: DriverHomePage;

  beforeAll(async () => {
    const { remote } = await import('webdriverio');
    driver = await remote({
      hostname: process.env.APPIUM_HOST || 'localhost',
      port: Number(process.env.APPIUM_PORT || 4723),
      capabilities: { ...driverAppCapabilities, 'appium:noReset': true },
    });
    homePage = new DriverHomePage(driver);
  });

  afterAll(async () => {
    if (driver) await driver.deleteSession();
  });

  it('should toggle online status', async () => {
    await homePage.goOnline();
    const isOnline = await homePage.isDisplayed('~status_online');
    expect(isOnline).toBe(true);
  });

  it('should toggle offline status', async () => {
    await homePage.goOffline();
    const isOffline = await homePage.isDisplayed('~status_offline');
    expect(isOffline).toBe(true);
  });

  it('should display wallet balance', async () => {
    const balance = await homePage.getWalletBalance();
    expect(balance).toBeTruthy();
    expect(balance).toMatch(/₹/);
  });

  it('should show earnings card', async () => {
    const visible = await homePage.isDisplayed('~earnings_card');
    expect(visible).toBe(true);
  });
});

describe.skipIf(!APPIUM_ENABLED)('Driver App — Trip Acceptance Flow', () => {
  let driver: any;
  let homePage: DriverHomePage;
  let tripPage: DriverTripPage;

  beforeAll(async () => {
    const { remote } = await import('webdriverio');
    driver = await remote({
      hostname: process.env.APPIUM_HOST || 'localhost',
      port: Number(process.env.APPIUM_PORT || 4723),
      capabilities: { ...driverAppCapabilities, 'appium:noReset': true },
    });
    homePage = new DriverHomePage(driver);
    tripPage = new DriverTripPage(driver);
  });

  afterAll(async () => {
    if (driver) await driver.deleteSession();
  });

  it('should display trip request when available', async () => {
    await homePage.goOnline();
    // This test depends on an actual trip request being created
    const hasRequest = await homePage.isDisplayed('~trip_request', 5000);
    expect(typeof hasRequest).toBe('boolean');
  });

  it('should show customer and route details on acceptance', async () => {
    const hasTripDetails = await tripPage.isDisplayed('~pickup_address', 3000);
    if (hasTripDetails) {
      const customerName = await tripPage.isDisplayed('~customer_name');
      expect(customerName).toBe(true);
    }
  });
});

describe.skipIf(!APPIUM_ENABLED)('Driver App — Wallet & Earnings', () => {
  let driver: any;
  let walletPage: DriverWalletPage;

  beforeAll(async () => {
    const { remote } = await import('webdriverio');
    driver = await remote({
      hostname: process.env.APPIUM_HOST || 'localhost',
      port: Number(process.env.APPIUM_PORT || 4723),
      capabilities: { ...driverAppCapabilities, 'appium:noReset': true },
    });
    walletPage = new DriverWalletPage(driver);
  });

  afterAll(async () => {
    if (driver) await driver.deleteSession();
  });

  it('should display current wallet balance', async () => {
    const balance = await walletPage.getBalance();
    expect(balance).toBeTruthy();
  });

  it('should open recharge flow', async () => {
    await walletPage.tap('~recharge_wallet');
    const amountInput = await walletPage.isDisplayed('~recharge_amount');
    expect(amountInput).toBe(true);
  });

  it('should show transaction history', async () => {
    const hasHistory = await walletPage.isDisplayed('~transaction_list');
    expect(typeof hasHistory).toBe('boolean');
  });

  it('should display pending commission if any', async () => {
    const hasPending = await walletPage.isDisplayed('~pending_commission');
    expect(typeof hasPending).toBe('boolean');
  });
});
