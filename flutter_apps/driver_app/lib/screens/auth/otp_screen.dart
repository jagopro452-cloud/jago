import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../../config/api_config.dart';
import '../../services/auth_service.dart';
import '../home/home_screen.dart';

class OtpScreen extends StatefulWidget {
  final String phone;
  final String otp;
  const OtpScreen({super.key, required this.phone, required this.otp});
  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _otpCtrl = TextEditingController();
  bool _loading = false;
  int _seconds = 30;
  Timer? _timer;

  @override
  void initState() { super.initState(); _startTimer(); }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_seconds == 0) t.cancel();
      else setState(() => _seconds--);
    });
  }

  Future<void> _verify() async {
    if (_otpCtrl.text.length != 6) return;
    setState(() => _loading = true);
    final res = await AuthService.verifyOtp(widget.phone, _otpCtrl.text, 'driver');
    setState(() => _loading = false);
    if (res['success'] == true) {
      Navigator.pushAndRemoveUntil(context,
        MaterialPageRoute(builder: (_) => const HomeScreen()), (_) => false);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid OTP'), backgroundColor: Colors.red));
    }
  }

  @override
  void dispose() { _timer?.cancel(); _otpCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060D1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF060D1E), elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.white.withOpacity(0.7)),
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
            style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.4))),
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
              activeFillColor: Colors.white.withOpacity(0.08),
              inactiveFillColor: Colors.white.withOpacity(0.05),
              selectedFillColor: Colors.white.withOpacity(0.1),
              activeColor: const Color(0xFF2563EB),
              inactiveColor: Colors.white.withOpacity(0.15),
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
              ? Text('Resend in ${_seconds}s', style: TextStyle(color: Colors.white.withOpacity(0.35)))
              : TextButton(
                  onPressed: () { setState(() => _seconds = 30); _startTimer(); },
                  child: const Text('Resend OTP',
                    style: TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.w600))),
          ),
        ]),
      ),
    );
  }
}
