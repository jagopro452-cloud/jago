import 'package:firebase_auth/firebase_auth.dart';

/// Wraps Firebase Phone Authentication for driver app.
class FirebaseOtpService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static String? _verificationId;
  static int? _resendToken;

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

  static Future<void> signOut() async {
    try { await _auth.signOut(); } catch (_) {}
  }
}
