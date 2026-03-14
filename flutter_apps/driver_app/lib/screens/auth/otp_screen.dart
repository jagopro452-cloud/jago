import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../../config/api_config.dart';
import '../../services/auth_service.dart';
import '../../services/firebase_otp_service.dart';
import '../home/home_screen.dart';

class OtpScreen extends StatefulWidget {
  final String phone;
  final String otp;
  final String? firebaseVerificationId;
  const OtpScreen({super.key, required this.phone, required this.otp, this.firebaseVerificationId});
  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _otpCtrl = TextEditingController();
  bool _loading = false;
  int _seconds = 30;
  Timer? _timer;
  String? _verificationId;

  @override
  void initState() {
    super.initState();
    _verificationId = widget.firebaseVerificationId;
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_seconds == 0) { t.cancel(); return; }
      if (mounted) setState(() => _seconds--);
    });
  }

  Future<void> _verify() async {
    if (_otpCtrl.text.length != 6) return;
    setState(() => _loading = true);

    if (_verificationId != null) {
      // Firebase path
      try {
        final idToken = await FirebaseOtpService.verifyOtp(
          smsCode: _otpCtrl.text,
          verificationId: _verificationId,
        );
        final res = await AuthService.verifyFirebaseToken(idToken, widget.phone, 'driver');
        setState(() => _loading = false);
        if (!mounted) return;
        if (res['success'] == true) {
          Navigator.pushAndRemoveUntil(context,
            MaterialPageRoute(builder: (_) => const HomeScreen()), (_) => false);
        } else {
          _showError(res['message'] ?? 'Verification failed. Try again.');
        }
      } catch (e) {
        setState(() => _loading = false);
        _showError(e.toString().replaceAll('Exception: ', ''));
      }
    } else {
      // Server OTP fallback
      final res = await AuthService.verifyOtp(widget.phone, _otpCtrl.text, 'driver');
      if (!mounted) return;
      setState(() => _loading = false);
      if (res['success'] == true) {
        Navigator.pushAndRemoveUntil(context,
          MaterialPageRoute(builder: (_) => const HomeScreen()), (_) => false);
      } else {
        _showError(res['message'] ?? 'Invalid OTP');
      }
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  @override
  void dispose() { _timer?.cancel(); _otpCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0B0B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B0B0B), elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.white.withValues(alpha: 0.7)),
          onPressed: () => Navigator.pop(context)),
        actions: [
          IconButton(icon: const Icon(Icons.help_outline, color: Color(0xFF2563EB)),
            onPressed: () {}),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 16),
          const Text('Verify OTP',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 8),
          Text('Sent to +91-${widget.phone}',
            style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.4))),
          if (ApiConfig.isDev && widget.otp.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('Dev OTP: ${widget.otp}',
              style: const TextStyle(fontSize: 12, color: Color(0xFF2563EB))),
          ],
          const SizedBox(height: 40),
          PinCodeTextField(
            appContext: context,
            length: 6,
            controller: _otpCtrl,
            keyboardType: TextInputType.number,
            pinTheme: PinTheme(
              shape: PinCodeFieldShape.box,
              borderRadius: BorderRadius.circular(10),
              fieldHeight: 52,
              fieldWidth: 46,
              activeFillColor: Colors.white.withValues(alpha: 0.08),
              inactiveFillColor: Colors.white.withValues(alpha: 0.05),
              selectedFillColor: Colors.white.withValues(alpha: 0.1),
              activeColor: const Color(0xFF2563EB),
              inactiveColor: Colors.white.withValues(alpha: 0.15),
              selectedColor: const Color(0xFF2563EB),
            ),
            enableActiveFill: true,
            textStyle: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            onCompleted: (_) => _verify(),
            onChanged: (_) {},
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity, height: 52,
            child: ElevatedButton(
              onPressed: _loading ? null : _verify,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
              child: _loading
                ? const SizedBox(width: 22, height: 22,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Verify', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: _seconds > 0
              ? Text('Resend in ${_seconds}s', style: TextStyle(color: Colors.white.withValues(alpha: 0.35)))
              : TextButton(
                  onPressed: () async {
                    setState(() { _seconds = 30; });
                    _startTimer();
                    // Try Firebase resend first
                    FirebaseOtpService.sendOtp(
                      phoneNumber: '+91${widget.phone}',
                      onCodeSent: (vId) => setState(() => _verificationId = vId),
                      onError: (_) async {
                        // Fallback to server OTP
                        await AuthService.sendOtp(widget.phone, 'driver');
                      },
                    );
                  },
                  child: const Text('Resend OTP',
                    style: TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.w600))),
          ),
        ]),
      ),
    );
  }
}
