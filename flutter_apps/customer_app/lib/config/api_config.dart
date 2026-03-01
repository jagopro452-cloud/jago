class ApiConfig {
  static const String prodBaseUrl = 'https://jagopro.org';
  static const String devBaseUrl = 'http://10.0.2.2:5000';

  static bool _isProd = false;
  static String get baseUrl => _isProd ? prodBaseUrl : devBaseUrl;
  static void useProduction() => _isProd = true;

  static const String googleMapsApiKey = 'YOUR_GOOGLE_MAPS_API_KEY';

  static String get sendOtp => '$baseUrl/api/app/send-otp';
  static String get verifyOtp => '$baseUrl/api/app/verify-otp';
  static String get logout => '$baseUrl/api/app/logout';
  static String get fcmToken => '$baseUrl/api/app/fcm-token';
  static String get configs => '$baseUrl/api/app/configs';
  static String get nearbyDrivers => '$baseUrl/api/app/nearby-drivers';

  static String get customerProfile => '$baseUrl/api/app/customer/profile';
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
}
