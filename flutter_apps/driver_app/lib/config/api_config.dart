class ApiConfig {
  // Override at compile time:  --dart-define=API_BASE_URL=https://yourdomain.com
  static const String compileTimeBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: '');

  // Production server URL (update when custom domain jagopro.org is configured)
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

  static const String googleMapsApiKey = 'AIzaSyBJIuefXlqcKNsIssYHQP6lpIWQ3ih4_Z8';

  // Socket.IO base URL (same server, no path)
  static String get socketUrl => baseUrl;

  static String get sendOtp => '$baseUrl/api/app/send-otp';
  static String get verifyOtp => '$baseUrl/api/app/verify-otp';
  static String get verifyFirebaseToken => '$baseUrl/api/app/verify-firebase-token';
  static String get loginPassword => '$baseUrl/api/app/login-password';
  static String get registerAccount => '$baseUrl/api/app/register';
  static String get forgotPassword => '$baseUrl/api/app/forgot-password';
  static String get resetPassword => '$baseUrl/api/app/reset-password';
  static String get logout => '$baseUrl/api/app/logout';
  static String get fcmToken => '$baseUrl/api/app/fcm-token';
  static String get configs => '$baseUrl/api/app/configs';
  static String get sos => '$baseUrl/api/app/sos';
  static String get notifications => '$baseUrl/api/app/notifications';
  static String get notificationsReadAll => '$baseUrl/api/app/notifications/read-all';
  static String get emergencyContacts => '$baseUrl/api/app/emergency-contacts';
  static String get tripShare => '$baseUrl/api/app/trip-share';

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

  static String get checkVerification => '$baseUrl/api/app/driver/check-verification';
  static String get faceVerify => '$baseUrl/api/app/driver/face-verify';
  static String get uploadDocument => '$baseUrl/api/app/driver/upload-document';
  static String get driverDocuments => '$baseUrl/api/app/driver/documents';
  static String get driverDashboard => '$baseUrl/api/app/driver/dashboard';
  static String get performance => '$baseUrl/api/app/driver/performance';
  static String get weeklyEarnings => '$baseUrl/api/app/driver/weekly-earnings';

  // ── Support Chat ─────────────────────────────────────────────────────
  static String get supportChat => '$baseUrl/api/app/driver/support-chat';
  static String get supportChatSend => '$baseUrl/api/app/driver/support-chat/send';

  // ── Unique Features ─────────────────────────────────────────────────
  static String get breakMode => '$baseUrl/api/app/driver/break';
  static String get fatigueStatus => '$baseUrl/api/app/driver/fatigue-status';
  static String get tipDriver => '$baseUrl/api/app/tip-driver';
  static String get lostFound => '$baseUrl/api/app/lost-found';
  static String get driverWithdrawRequest => '$baseUrl/api/app/driver/withdraw-request';
  static String get deleteAccount => '$baseUrl/api/app/driver/account';
  static String get verifyDeliveryOtp => '$baseUrl/api/app/driver/verify-delivery-otp';
  static String get tripPhoto => '$baseUrl/api/app/driver/trip-photo';
}
