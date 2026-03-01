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
  static String get sos => '$baseUrl/api/app/sos';

  static String get driverProfile => '$baseUrl/api/app/driver/profile';
  static String get driverLocation => '$baseUrl/api/app/driver/location';
  static String get driverOnlineStatus => '$baseUrl/api/app/driver/online-status';
  static String get driverIncomingTrip => '$baseUrl/api/app/driver/incoming-trip';
  static String get driverAcceptTrip => '$baseUrl/api/app/driver/accept-trip';
  static String get driverRejectTrip => '$baseUrl/api/app/driver/reject-trip';
  static String get driverArrived => '$baseUrl/api/app/driver/arrived';
  static String get driverVerifyOtp => '$baseUrl/api/app/driver/verify-pickup-otp';
  static String get driverCompleteTrip => '$baseUrl/api/app/driver/complete-trip';
  static String get driverCancelTrip => '$baseUrl/api/app/driver/cancel-trip';
  static String get driverTrips => '$baseUrl/api/app/driver/trips';
  static String get driverWallet => '$baseUrl/api/app/driver/wallet';
  static String get driverEarnings => '$baseUrl/api/app/driver/earnings';
  static String get driverRateCustomer => '$baseUrl/api/app/driver/rate-customer';
  static String get updateProfile => '$baseUrl/api/app/driver/profile';
  static String get changePassword => '$baseUrl/api/app/change-password';
  static String get referral => '$baseUrl/api/app/referral';
}
