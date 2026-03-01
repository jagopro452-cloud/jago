class ApiConfig {
  static const String prodBaseUrl = 'https://jagopro.org';
  static const String devBaseUrl = 'http://10.0.2.2:5000';

  static bool _isProd = true;
  static String get baseUrl => _isProd ? prodBaseUrl : devBaseUrl;
  static bool get isDev => !_isProd;
  static void useProduction() => _isProd = true;
  static void useDevelopment() => _isProd = false;

  static const String googleMapsApiKey = 'YOUR_GOOGLE_MAPS_API_KEY';

  static String get sendOtp => '$baseUrl/api/app/send-otp';
  static String get verifyOtp => '$baseUrl/api/app/verify-otp';
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
  static String get savedPlaces => '$baseUrl/api/app/customer/saved-places';
  static String get applyCoupon => '$baseUrl/api/app/customer/apply-coupon';
  static String get updateProfile => '$baseUrl/api/app/customer/profile';
  static String get scheduleRide => '$baseUrl/api/app/customer/schedule-ride';
  static String get scheduledRides => '$baseUrl/api/app/customer/scheduled-rides';
  static String get sos => '$baseUrl/api/app/sos';

  // ── Unique Features ─────────────────────────────────────────────────
  static String get coins => '$baseUrl/api/app/customer/coins';
  static String get redeemCoins => '$baseUrl/api/app/customer/redeem-coins';
  static String get monthlyPass => '$baseUrl/api/app/customer/monthly-pass';
  static String get buyMonthlyPass => '$baseUrl/api/app/customer/monthly-pass/buy';
  static String get preferences => '$baseUrl/api/app/customer/preferences';
  static String get customerLostFound => '$baseUrl/api/app/customer/lost-found';
  static String get lostFound => '$baseUrl/api/app/lost-found';
  static String get tipDriver => '$baseUrl/api/app/tip-driver';
  static String get surgeAlert => '$baseUrl/api/app/customer/surge-alert';
  static String get fcmToken => '$baseUrl/api/app/fcm-token';
  static String get referral => '$baseUrl/api/app/referral';
}
