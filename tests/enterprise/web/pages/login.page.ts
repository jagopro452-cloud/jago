// ===========================================================================
// POM: Login Page — Admin Panel
// ===========================================================================

import { type Page, type Locator, expect } from '@playwright/test';

export class LoginPage {
  readonly page: Page;
  readonly emailInput: Locator;
  readonly passwordInput: Locator;
  readonly loginButton: Locator;
  readonly errorMessage: Locator;
  readonly otpInput: Locator;
  readonly verifyOtpButton: Locator;
  readonly forgotPasswordLink: Locator;

  constructor(page: Page) {
    this.page = page;
    this.emailInput = page.locator('input[type="email"], input[name="email"], input[placeholder*="email" i]');
    this.passwordInput = page.locator('input[type="password"]');
    this.loginButton = page.locator('button[type="submit"], button:has-text("Login"), button:has-text("Sign In")');
    this.errorMessage = page.locator('[class*="error"], [class*="alert-danger"], [role="alert"]');
    this.otpInput = page.locator('input[placeholder*="OTP" i], input[name="otp"]');
    this.verifyOtpButton = page.locator('button:has-text("Verify")');
    this.forgotPasswordLink = page.locator('a:has-text("Forgot"), button:has-text("Forgot")');
  }

  async goto() {
    await this.page.goto('/admin/login');
    await this.page.waitForLoadState('networkidle');
  }

  async login(email: string, password: string) {
    await this.emailInput.fill(email);
    await this.passwordInput.fill(password);
    await this.loginButton.click();
    await this.page.waitForLoadState('networkidle');
  }

  async loginAndWaitForDashboard(email: string, password: string) {
    await this.login(email, password);
    // Wait for redirect to dashboard
    await this.page.waitForURL(/\/(admin|dashboard)/, { timeout: 15_000 });
  }

  async expectError(text?: string) {
    await expect(this.errorMessage).toBeVisible();
    if (text) {
      await expect(this.errorMessage).toContainText(text);
    }
  }

  async expectLoggedIn() {
    await expect(this.page).toHaveURL(/\/(admin|dashboard)/);
  }

  async verifyOtp(otp: string) {
    await this.otpInput.fill(otp);
    await this.verifyOtpButton.click();
    await this.page.waitForLoadState('networkidle');
  }
}
