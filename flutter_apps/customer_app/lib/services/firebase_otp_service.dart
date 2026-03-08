import 'package:firebase_auth/firebase_auth.dart';

/// Wraps Firebase Phone Authentication.
/// Usage:
///   1. Call [sendOtp] → user gets SMS from Firebase.
///   2. Call [verifyOtp] with the OTP user typed → returns Firebase ID token.
///   3. POST that token to your server's `/api/app/verify-firebase-token` endpoint.
class FirebaseOtpService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Set by [sendOtp], used by [verifyOtp].
  static String? _verificationId;
  static int? _resendToken;

  /// Sends OTP to [phoneNumber] (e.g. "+919876543210").
  /// [onCodeSent]   → called with verificationId when SMS is sent.
  /// [onError]      → called with error message on failure.
  /// [onAutoVerify] → called with Firebase ID token if auto-verified (Android only).
  static Future<void> sendOtp({
    required String phoneNumber,
    required void Function(String verificationId) onCodeSent,
    required void Function(String error) onError,
    void Function(String idToken)? onAutoVerify,
  }) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        forceResendingToken: _resendToken,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-retrieval / instant verification (Android only)
          try {
            final userCred = await _auth.signInWithCredential(credential);
            final idToken = await userCred.user?.getIdToken();
            if (idToken != null) onAutoVerify?.call(idToken);
          } catch (_) {}
        },
        verificationFailed: (FirebaseAuthException e) {
          String message;
          switch (e.code) {
            case 'invalid-phone-number':
              message = 'Invalid phone number format.';
              break;
            case 'too-many-requests':
              message = 'Too many attempts. Please try again later.';
              break;
            case 'quota-exceeded':
              message = 'OTP quota exceeded. Please try again tomorrow.';
              break;
            case 'app-not-authorized':
              message = 'App not authorized for Firebase Auth. Contact support.';
              break;
            default:
              message = e.message ?? 'Failed to send OTP. Please try again.';
          }
          onError(message);
        },
        codeSent: (String verificationId, int? resendToken) {
          _verificationId = verificationId;
          _resendToken = resendToken;
          onCodeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
      );
    } catch (e) {
      onError('Failed to send OTP: ${e.toString()}');
    }
  }

  /// Verifies [smsCode] entered by the user.
  /// Returns Firebase ID token on success, or throws [FirebaseAuthException].
  static Future<String> verifyOtp({
    required String smsCode,
    String? verificationId,
  }) async {
    final vId = verificationId ?? _verificationId;
    if (vId == null) throw Exception('Verification ID missing. Please resend OTP.');

    final credential = PhoneAuthProvider.credential(
      verificationId: vId,
      smsCode: smsCode,
    );
    final userCred = await _auth.signInWithCredential(credential);
    final idToken = await userCred.user?.getIdToken();
    if (idToken == null) throw Exception('Could not get Firebase token. Please try again.');
    return idToken;
  }

  /// Sign out from Firebase (call on app logout).
  static Future<void> signOut() async {
    try { await _auth.signOut(); } catch (_) {}
  }
}
