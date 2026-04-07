// ===========================================================================
// Appium Mobile Test Framework — JagoPro Customer & Driver Apps
// Page Object Model for Flutter apps
// ===========================================================================

// ── Appium Capabilities ─────────────────────────────────────────────────────

export const customerAppCapabilities = {
  platformName: 'Android',
  'appium:automationName': 'Flutter',
  'appium:app': 'flutter_apps/customer_app/build/app/outputs/flutter-apk/app-release.apk',
  'appium:deviceName': process.env.DEVICE_NAME || 'emulator-5554',
  'appium:noReset': false,
  'appium:fullReset': false,
  'appium:newCommandTimeout': 300,
  'appium:autoGrantPermissions': true,
};

export const driverAppCapabilities = {
  platformName: 'Android',
  'appium:automationName': 'Flutter',
  'appium:app': 'flutter_apps/driver_app/build/app/outputs/flutter-apk/app-release.apk',
  'appium:deviceName': process.env.DEVICE_NAME || 'emulator-5554',
  'appium:noReset': false,
  'appium:fullReset': false,
  'appium:newCommandTimeout': 300,
  'appium:autoGrantPermissions': true,
};

// ── Page Objects ────────────────────────────────────────────────────────────

export class MobileBasePage {
  constructor(protected driver: any) {}

  async waitForElement(selector: string, timeout = 10000): Promise<any> {
    const element = await this.driver.$(selector);
    await element.waitForDisplayed({ timeout });
    return element;
  }

  async tap(selector: string) {
    const element = await this.waitForElement(selector);
    await element.click();
  }

  async typeText(selector: string, text: string) {
    const element = await this.waitForElement(selector);
    await element.setValue(text);
  }

  async getText(selector: string): Promise<string> {
    const element = await this.waitForElement(selector);
    return element.getText();
  }

  async isDisplayed(selector: string, timeout = 5000): Promise<boolean> {
    try {
      const element = await this.driver.$(selector);
      await element.waitForDisplayed({ timeout });
      return true;
    } catch {
      return false;
    }
  }

  async takeScreenshot(name: string): Promise<string> {
    const screenshot = await this.driver.takeScreenshot();
    return screenshot;
  }

  async scrollDown() {
    await this.driver.touchAction([
      { action: 'press', x: 200, y: 600 },
      { action: 'moveTo', x: 200, y: 200 },
      'release',
    ]);
  }

  async goBack() {
    await this.driver.back();
  }
}

// ── Customer App Pages ──────────────────────────────────────────────────────

export class CustomerLoginPage extends MobileBasePage {
  get phoneInput() { return '~phone_input'; }
  get continueButton() { return '~continue_button'; }
  get otpInput() { return '~otp_input'; }
  get verifyButton() { return '~verify_button'; }
  get skipButton() { return '~skip_button'; }

  async enterPhone(phone: string) {
    await this.typeText(this.phoneInput, phone);
    await this.tap(this.continueButton);
  }

  async enterOtp(otp: string) {
    await this.typeText(this.otpInput, otp);
    await this.tap(this.verifyButton);
  }

  async isLoginScreenVisible(): Promise<boolean> {
    return this.isDisplayed(this.phoneInput);
  }
}

export class CustomerHomePage extends MobileBasePage {
  get pickupSearchBar() { return '~pickup_search'; }
  get dropoffSearchBar() { return '~dropoff_search'; }
  get currentLocationButton() { return '~current_location'; }
  get menuButton() { return '~menu_button'; }
  get profileButton() { return '~profile_button'; }
  get walletButton() { return '~wallet_button'; }
  get tripHistoryButton() { return '~trip_history'; }

  async searchPickup(address: string) {
    await this.tap(this.pickupSearchBar);
    await this.typeText(this.pickupSearchBar, address);
  }

  async searchDropoff(address: string) {
    await this.tap(this.dropoffSearchBar);
    await this.typeText(this.dropoffSearchBar, address);
  }

  async isHomeScreenVisible(): Promise<boolean> {
    return this.isDisplayed(this.pickupSearchBar);
  }

  async openMenu() {
    await this.tap(this.menuButton);
  }
}

export class CustomerBookingPage extends MobileBasePage {
  get vehicleList() { return '~vehicle_list'; }
  get bookNowButton() { return '~book_now'; }
  get estimatedFare() { return '~estimated_fare'; }
  get estimatedTime() { return '~estimated_time'; }
  get paymentMethod() { return '~payment_method'; }
  get cancelBooking() { return '~cancel_booking'; }

  async selectVehicle(index: number) {
    const vehicles = await this.driver.$$('~vehicle_option');
    if (vehicles[index]) {
      await vehicles[index].click();
    }
  }

  async getFareEstimate(): Promise<string> {
    return this.getText(this.estimatedFare);
  }

  async bookRide() {
    await this.tap(this.bookNowButton);
  }

  async selectPaymentMethod(method: 'cash' | 'wallet' | 'online') {
    await this.tap(this.paymentMethod);
    await this.tap(`~payment_${method}`);
  }
}

export class CustomerTrackingPage extends MobileBasePage {
  get driverName() { return '~driver_name'; }
  get driverRating() { return '~driver_rating'; }
  get vehicleNumber() { return '~vehicle_number'; }
  get eta() { return '~eta'; }
  get callDriverButton() { return '~call_driver'; }
  get chatButton() { return '~chat_button'; }
  get sosButton() { return '~sos_button'; }
  get tripStatus() { return '~trip_status'; }
  get shareTrip() { return '~share_trip'; }

  async getDriverInfo(): Promise<{ name: string; vehicle: string }> {
    const name = await this.getText(this.driverName);
    const vehicle = await this.getText(this.vehicleNumber);
    return { name, vehicle };
  }

  async callDriver() {
    await this.tap(this.callDriverButton);
  }

  async openChat() {
    await this.tap(this.chatButton);
  }

  async triggerSOS() {
    await this.tap(this.sosButton);
  }
}

// ── Driver App Pages ────────────────────────────────────────────────────────

export class DriverLoginPage extends MobileBasePage {
  get phoneInput() { return '~driver_phone_input'; }
  get continueButton() { return '~driver_continue_button'; }
  get otpInput() { return '~driver_otp_input'; }
  get verifyButton() { return '~driver_verify_button'; }

  async enterPhone(phone: string) {
    await this.typeText(this.phoneInput, phone);
    await this.tap(this.continueButton);
  }
}

export class DriverHomePage extends MobileBasePage {
  get onlineToggle() { return '~online_toggle'; }
  get earningsCard() { return '~earnings_card'; }
  get tripRequestCard() { return '~trip_request'; }
  get acceptButton() { return '~accept_trip'; }
  get rejectButton() { return '~reject_trip'; }
  get walletBalance() { return '~wallet_balance'; }
  get profileButton() { return '~driver_profile'; }

  async goOnline() {
    const isOnline = await this.isDisplayed('~status_online');
    if (!isOnline) {
      await this.tap(this.onlineToggle);
    }
  }

  async goOffline() {
    const isOnline = await this.isDisplayed('~status_online');
    if (isOnline) {
      await this.tap(this.onlineToggle);
    }
  }

  async acceptTrip() {
    await this.waitForElement(this.tripRequestCard, 60000);
    await this.tap(this.acceptButton);
  }

  async rejectTrip() {
    await this.tap(this.rejectButton);
  }

  async getWalletBalance(): Promise<string> {
    return this.getText(this.walletBalance);
  }
}

export class DriverTripPage extends MobileBasePage {
  get arrivedButton() { return '~arrived_button'; }
  get startTripButton() { return '~start_trip'; }
  get completeTripButton() { return '~complete_trip'; }
  get navigationButton() { return '~navigate'; }
  get customerName() { return '~customer_name'; }
  get pickupAddress() { return '~pickup_address'; }
  get dropoffAddress() { return '~dropoff_address'; }
  get callCustomerButton() { return '~call_customer'; }
  get otpInput() { return '~trip_otp_input'; }
  get verifyOtpButton() { return '~verify_trip_otp'; }
  get collectCashButton() { return '~collect_cash'; }
  get fareAmount() { return '~fare_amount'; }

  async markArrived() {
    await this.tap(this.arrivedButton);
  }

  async startTrip(otp?: string) {
    if (otp) {
      await this.typeText(this.otpInput, otp);
      await this.tap(this.verifyOtpButton);
    }
    await this.tap(this.startTripButton);
  }

  async completeTrip() {
    await this.tap(this.completeTripButton);
  }

  async getFare(): Promise<string> {
    return this.getText(this.fareAmount);
  }
}

export class DriverWalletPage extends MobileBasePage {
  get currentBalance() { return '~current_balance'; }
  get rechargeButton() { return '~recharge_wallet'; }
  get amountInput() { return '~recharge_amount'; }
  get payButton() { return '~pay_button'; }
  get transactionHistory() { return '~transaction_list'; }
  get pendingCommission() { return '~pending_commission'; }

  async getBalance(): Promise<string> {
    return this.getText(this.currentBalance);
  }

  async recharge(amount: number) {
    await this.tap(this.rechargeButton);
    await this.typeText(this.amountInput, String(amount));
    await this.tap(this.payButton);
  }
}

// ── Test Scenarios ──────────────────────────────────────────────────────────

export const testScenarios = {
  customerBookingFlow: {
    name: 'Customer Booking E2E',
    steps: [
      'Open customer app',
      'Login with phone + OTP',
      'Enter pickup location',
      'Enter dropoff location',
      'Select vehicle type',
      'View fare estimate',
      'Select payment method',
      'Book ride',
      'Wait for driver assignment',
      'Track driver on map',
      'Verify OTP display',
      'Complete ride',
      'Rate driver',
      'View receipt',
    ],
  },

  driverAcceptFlow: {
    name: 'Driver Trip Accept E2E',
    steps: [
      'Open driver app',
      'Login with phone + OTP',
      'Go online',
      'Wait for trip request',
      'Accept trip',
      'Navigate to pickup',
      'Mark arrived',
      'Verify OTP / Start trip',
      'Navigate to dropoff',
      'Complete trip',
      'View earnings',
      'Check wallet balance update',
    ],
  },

  walletRechargeFlow: {
    name: 'Driver Wallet Recharge',
    steps: [
      'Open wallet page',
      'Tap recharge',
      'Enter amount',
      'Complete Razorpay payment',
      'Verify balance updated',
      'Check transaction in history',
    ],
  },

  cancelTripFlow: {
    name: 'Trip Cancellation',
    steps: [
      'Customer books ride',
      'Driver assigned',
      'Customer cancels',
      'Select cancellation reason',
      'Verify cancellation fee applied',
      'Driver notified',
      'Driver goes back to online',
    ],
  },

  parcelDeliveryFlow: {
    name: 'Parcel Delivery E2E',
    steps: [
      'Customer opens parcel tab',
      'Enter sender/receiver details',
      'Select parcel category & weight',
      'Enter pickup/dropoff',
      'View fare estimate',
      'Book parcel',
      'Driver accepts parcel',
      'Driver picks up',
      'Delivery OTP verification',
      'Complete delivery',
    ],
  },
};
