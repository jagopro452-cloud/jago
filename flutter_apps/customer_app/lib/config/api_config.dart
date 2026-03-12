class ApiConfig {
  // Override at compile time:  --dart-define=API_BASE_URL=https://yourdomain.com
  static const String compileTimeBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: '');

  // Production server URL
  static const String _prodUrl = 'https://jagopro.org';

  // LAN IP for local testing only
  static const String _lanDevUrl = 'http://192.168.1.11:5000';

  static bool _isProd = true; // PRODUCTION BUILD

  static String get baseUrl {
    if (compileTimeBaseUrl.isNotEmpty) {
      final u = compileTimeBaseUrl;
      return u.endsWith('/') ? u.substring(0, u.length - 1) : u;
    }
    return _isProd ? _prodUrl : _lanDevUrl;
  }
  static bool get isDev => !_isProd;
  static void useProduction() => _isProd = true;
  static void useDevelopment() => _isProd = false;

  static const String googleMapsApiKey = 'AIzaSyBk3Lj0EIppvldBZue9Cmhff_oi9NeBlL0';

  // Socket.IO base URL (same server, no path)
  static String get socketUrl => baseUrl;

  static String get sendOtp => '$baseUrl/api/app/send-otp';
  static String get verifyOtp => '$baseUrl/api/app/verify-otp';
  static String get verifyFirebaseToken => '$baseUrl/api/app/verify-firebase-token';
  static String get loginPassword => '$baseUrl/api/app/login-password';
  static String get registerAccount => '$baseUrl/api/app/register';
  static String get forgotPassword => '$baseUrl/api/app/forgot-password';
  static String get resetPassword => '$baseUrl/api/app/reset-password';
  static String get changePassword => '$baseUrl/api/app/change-password';
  static String get logout => '$baseUrl/api/app/logout';
  static String get configs => '$baseUrl/api/app/configs';
  static String get nearbyDrivers => '$baseUrl/api/app/nearby-drivers';
  static String get notifications => '$baseUrl/api/app/notifications';
  static String get notificationsReadAll => '$baseUrl/api/app/notifications/read-all';
  static String get emergencyContacts => '$baseUrl/api/app/emergency-contacts';
  static String get tripShare => '$baseUrl/api/app/trip-share';
  static String get trackPrefix => '$baseUrl/api/app/track';

  static String get customerProfile => '$baseUrl/api/app/customer/profile';
  static String get customerHomeData => '$baseUrl/api/app/customer/home-data';
  static String get estimateFare => '$baseUrl/api/app/customer/estimate-fare';
  static String get bookRide => '$baseUrl/api/app/customer/book-ride';
  static String get activeTrip => '$baseUrl/api/app/customer/active-trip';
  static String get trackTrip => '$baseUrl/api/app/customer/track-trip';
  static String get cancelTrip => '$baseUrl/api/app/customer/cancel-trip';
  static String get rateDriver => '$baseUrl/api/app/customer/rate-driver';
  static String get trips => '$baseUrl/api/app/customer/trips';
  static String get wallet => '$baseUrl/api/app/customer/wallet';
  static String get walletRecharge => '$baseUrl/api/app/customer/wallet/recharge';
  static String get walletCreateOrder => '$baseUrl/api/app/customer/wallet/create-order';
  static String get walletVerifyPayment => '$baseUrl/api/app/customer/wallet/verify-payment';
  static String get savedPlaces => '$baseUrl/api/app/customer/saved-places';
  static String get applyCoupon => '$baseUrl/api/app/customer/apply-coupon';
  static String get rideCreateOrder => '$baseUrl/api/app/customer/ride/create-order';
  static String get rideVerifyPayment => '$baseUrl/api/app/customer/ride/verify-payment';
  static String get customerOffers => '$baseUrl/api/app/customer/offers';
  static String get updateProfile => '$baseUrl/api/app/customer/profile';
  static String get scheduleRide => '$baseUrl/api/app/customer/schedule-ride';
  static String get scheduledRides => '$baseUrl/api/app/customer/scheduled-rides';
  static String get sos => '$baseUrl/api/app/sos';

  // ── Intercity ────────────────────────────────────────────────────────
  static String get intercityRoutes => '$baseUrl/api/intercity-routes';
  static String get intercityBook => '$baseUrl/api/app/customer/intercity-book';

  // ── Support Chat ─────────────────────────────────────────────────────
  static String get supportChat => '$baseUrl/api/app/customer/support-chat';
  static String get supportChatSend => '$baseUrl/api/app/customer/support-chat/send';

  // ── Unique Features ─────────────────────────────────────────────────
  static String get coins => '$baseUrl/api/app/customer/coins';
  static String get redeemCoins => '$baseUrl/api/app/customer/redeem-coins';
  static String get spinWheel => '$baseUrl/api/app/customer/spin-wheel';
  static String get spinWheelPlay => '$baseUrl/api/app/customer/spin-wheel/play';
  static String get monthlyPass => '$baseUrl/api/app/customer/monthly-pass';
  static String get buyMonthlyPass => '$baseUrl/api/app/customer/monthly-pass/buy';
  static String get preferences => '$baseUrl/api/app/customer/preferences';
  static String get customerLostFound => '$baseUrl/api/app/customer/lost-found';
  static String get lostFound => '$baseUrl/api/app/lost-found';
  static String get tipDriver => '$baseUrl/api/app/tip-driver';
  static String get surgeAlert => '$baseUrl/api/app/customer/surge-alert';
  static String get fcmToken => '$baseUrl/api/app/fcm-token';
  static String get referral => '$baseUrl/api/app/referral';
  static String get deleteAccount => '$baseUrl/api/app/customer/account';

  // ── Trip Receipt ─────────────────────────────────────────────────────
  static String tripReceipt(String tripId) => '$baseUrl/api/app/customer/trip-receipt/$tripId';

  // ── Parcel ───────────────────────────────────────────────────────────
  static String get parcelBook => '$baseUrl/api/app/parcel/book';
  static String get parcelOrders => '$baseUrl/api/app/parcel/orders';
  static String get parcelOptimizeRoute => '$baseUrl/api/app/parcel/optimize-route';
  static String parcelTrack(String id) => '$baseUrl/api/app/parcel/$id/track';
  static String parcelReceipt(String id) => '$baseUrl/api/app/parcel/$id/receipt';
  static String parcelCancel(String id) => '$baseUrl/api/app/parcel/$id/cancel';

  // ── B2B ──────────────────────────────────────────────────────────────
  static String get b2bRegister => '$baseUrl/api/app/b2b/register';
  static String get b2bDashboard => '$baseUrl/api/app/b2b/dashboard';

  // ── Voice Booking ────────────────────────────────────────────────────
  static String get voiceBookingParse => '$baseUrl/api/app/voice-booking/parse';
}
