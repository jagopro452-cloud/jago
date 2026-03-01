import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../../services/auth_service.dart';

class OtpScreen extends StatefulWidget {
  final String phone;
  final String? devOtp;
  const OtpScreen({super.key, required this.phone, this.devOtp});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  String _otp = '';
  bool _loading = false;
  String? _error;
  int _countdown = 60;
  Timer? _timer;

  @override
  void initState() { super.initState(); _startTimer(); }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_countdown == 0) t.cancel();
      else if (mounted) setState(() => _countdown--);
    });
  }

  Future<void> _verify() async {
    if (_otp.length < 6) { setState(() => _error = 'Enter 6-digit OTP'); return; }
    setState(() { _loading = true; _error = null; });
    try {
      final res = await AuthService.verifyOtp(widget.phone, _otp);
      if (!mounted) return;
      if (res['success'] == true) {
        Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
      } else {
        setState(() => _error = res['message'] ?? 'Invalid OTP');
      }
    } catch (_) {
      setState(() => _error = 'Network error.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() { _timer?.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(backgroundColor: Colors.white, leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF0F172A)), onPressed: () => Navigator.pop(context))),
      body: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Verify OTP', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            const SizedBox(height: 8),
            Text('Sent to +91 ${widget.phone}', style: const TextStyle(fontSize: 14, color: Color(0xFF64748B))),
            if (widget.devOtp != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(8)),
                child: Text('Dev OTP: ${widget.devOtp}', style: const TextStyle(color: Color(0xFF2563EB), fontSize: 13, fontWeight: FontWeight.bold)),
              ),
            ],
            const SizedBox(height: 40),
            PinCodeTextField(
              appContext: context,
              length: 6,
              onChanged: (v) => setState(() => _otp = v),
              onCompleted: (_) => _verify(),
              keyboardType: TextInputType.number,
              pinTheme: PinTheme(
                shape: PinCodeFieldShape.box,
                borderRadius: BorderRadius.circular(12),
                fieldHeight: 56, fieldWidth: 48,
                activeFillColor: const Color(0xFFEFF6FF),
                inactiveFillColor: const Color(0xFFF8FAFC),
                selectedFillColor: const Color(0xFFDBEAFE),
                activeColor: const Color(0xFF2563EB),
                inactiveColor: const Color(0xFFE2E8F0),
                selectedColor: const Color(0xFF1D4ED8),
              ),
              enableActiveFill: true,
              textStyle: const TextStyle(color: Color(0xFF0F172A), fontSize: 22, fontWeight: FontWeight.bold),
            ),
            if (_error != null) Text(_error!, style: const TextStyle(color: Color(0xFFEF4444), fontSize: 13)),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity, height: 56,
              child: ElevatedButton(
                onPressed: _loading ? null : _verify,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0),
                child: _loading
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                    : const Text('Verify & Login', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: _countdown > 0
                  ? Text('Resend in ${_countdown}s', style: const TextStyle(color: Color(0xFF94A3B8)))
                  : TextButton(onPressed: () { setState(() => _countdown = 60); _startTimer(); AuthService.sendOtp(widget.phone); }, child: const Text('Resend OTP', style: TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold))),
            ),
          ],
        ),
      ),
    );
  }
}
