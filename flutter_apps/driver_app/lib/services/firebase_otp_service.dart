import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';

/// Wraps Firebase Phone Authentication for driver app.
class FirebaseOtpService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static String? _verificationId;
  static int? _resendToken;

  static String _mapAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-phone-number':
        return 'Invalid phone number. Please check and try again.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait 5 minutes and try again.';
      case 'quota-exceeded':
        return 'SMS limit reached. Please try again after some time.';
      case 'operation-not-allowed':
        return 'Phone authentication is not enabled. Please contact support.';
      case 'app-not-authorized':
        return 'App is not authorized. Please update to the latest version.';
      case 'web-context-cancelled':
        return 'Verification was cancelled. Please try again.';
      case 'missing-client-identifier':
        return 'Device verification failed. Please restart the app and try again.';
      case 'session-expired':
        return 'OTP expired. Please tap "Resend OTP" to get a new code.';
      case 'invalid-verification-code':
        return 'Wrong OTP entered. Please check the code and try again.';
      case 'invalid-verification-id':
        return 'OTP session expired. Please tap "Resend OTP" to get a new code.';
      case 'network-request-failed':
        return 'No internet connection. Please check your network and try again.';
      case 'credential-already-in-use':
        return 'This phone number is already linked to another account.';
      default:
        final msg = e.message ?? '';
        if (msg.contains('blocked') || msg.contains('identitytoolkit')) {
          return 'OTP service is temporarily unavailable. Please try again in a few minutes or use password login.';
        }
        return msg.isNotEmpty ? msg : 'Something went wrong. Please try again.';
    }
  }

  static Future<void> resetVerification() async {
    _verificationId = null;
    _resendToken = null;
    try {
      await _auth.signOut();
    } catch (_) {}
  }

  static Future<void> sendOtp({
    required String phoneNumber,
    required void Function(String verificationId) onCodeSent,
    required void Function(String error) onError,
    void Function(String idToken)? onAutoVerify,
    bool forceResend = false,
  }) async {
    final completer = Completer<void>();
    Timer? watchdog;
    var callbackHandled = false;

    void finish() {
      callbackHandled = true;
      watchdog?.cancel();
      if (!completer.isCompleted) completer.complete();
    }

    try {
      if (!forceResend) {
        _verificationId = null;
      }
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        forceResendingToken: forceResend ? _resendToken : null,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-retrieval disabled — user must always enter OTP manually.
          // signInWithCredential here would consume the session and cause
          // "session expired" when user tries to verify manually.
          if (onAutoVerify == null) return;
          try {
            final userCred = await _auth.signInWithCredential(credential);
            final idToken = await userCred.user?.getIdToken(true);
            if (idToken != null) onAutoVerify.call(idToken);
          } catch (_) {}
        },
        verificationFailed: (FirebaseAuthException e) {
          _verificationId = null;
          onError(_mapAuthError(e));
          finish();
        },
        codeSent: (String verificationId, int? resendToken) {
          _verificationId = verificationId;
          _resendToken = resendToken;
          onCodeSent(verificationId);
          finish();
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
      );
      watchdog = Timer(const Duration(seconds: 55), () {
        if (callbackHandled) return;
        onError('OTP request timed out. Please tap Resend OTP to try again.');
        finish();
      });
      await completer.future;
    } catch (e) {
      onError('Failed to send OTP: ${e.toString()}');
    }
  }

  static Future<String> verifyOtp({
    required String smsCode,
    String? verificationId,
  }) async {
    final vId = verificationId ?? _verificationId;
    if (vId == null) throw Exception('OTP session expired. Please tap "Resend OTP" and try again.');

    final credential = PhoneAuthProvider.credential(
      verificationId: vId,
      smsCode: smsCode,
    );

    try {
      // Attempt sign-in with OTP credential directly (no sign-out first —
      // signing out kills the verification session on some devices)
      final userCred = await _auth.signInWithCredential(credential);
      final idToken = await userCred.user?.getIdToken(true);
      if (idToken == null) throw Exception('Could not get Firebase token. Please try again.');
      return idToken;
    } on FirebaseAuthException catch (e) {
      // If session expired, try signing out stale session and retrying once
      if (e.code == 'session-expired' || e.code == 'invalid-verification-id') {
        try {
          await _auth.signOut();
          final retryCred = await _auth.signInWithCredential(credential);
          final idToken = await retryCred.user?.getIdToken(true);
          if (idToken != null) return idToken;
        } catch (_) {}
        throw Exception('OTP session expired. Please tap "Resend OTP" to get a new code.');
      }
      throw Exception(_mapAuthError(e));
    }
  }

  static Future<void> signOut() async {
    try { await _auth.signOut(); } catch (_) {}
  }
}
