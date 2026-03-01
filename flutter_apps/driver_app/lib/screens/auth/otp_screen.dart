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
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_countdown == 0) {
        t.cancel();
      } else {
        if (mounted) setState(() => _countdown--);
      }
    });
  }

  Future<void> _verify() async {
    if (_otp.length < 6) {
      setState(() => _error = 'Enter 6-digit OTP');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final res = await AuthService.verifyOtp(widget.phone, _otp);
      if (!mounted) return;
      if (res['success'] == true && res['token'] != null) {
        Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
      } else {
        setState(() => _error = res['message'] ?? 'Invalid OTP');
      }
    } catch (e) {
      setState(() => _error = 'Network error. Try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resend() async {
    setState(() { _countdown = 60; _error = null; });
    _startTimer();
    await AuthService.sendOtp(widget.phone);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF060D1E), Color(0xFF0C1A2F)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(height: 32),
                const Text('Verify OTP', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 8),
                Text(
                  'Enter the 6-digit code sent to +91 ${widget.phone}',
                  style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                ),
                if (widget.devOtp != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E3A5F),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('Dev OTP: ${widget.devOtp}', style: const TextStyle(color: Color(0xFF3B82F6), fontSize: 13, fontWeight: FontWeight.bold)),
                    ),
                  ),
                const SizedBox(height: 48),
                PinCodeTextField(
                  appContext: context,
                  length: 6,
                  onChanged: (v) => setState(() => _otp = v),
                  onCompleted: (_) => _verify(),
                  keyboardType: TextInputType.number,
                  pinTheme: PinTheme(
                    shape: PinCodeFieldShape.box,
                    borderRadius: BorderRadius.circular(12),
                    fieldHeight: 56,
                    fieldWidth: 48,
                    activeFillColor: const Color(0xFF091629),
                    inactiveFillColor: const Color(0xFF060D1E),
                    selectedFillColor: const Color(0xFF0C2050),
                    activeColor: const Color(0xFF3B82F6),
                    inactiveColor: const Color(0xFF1E3A5F),
                    selectedColor: const Color(0xFF2563EB),
                  ),
                  enableActiveFill: true,
                  textStyle: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(_error!, style: const TextStyle(color: Color(0xFFEF4444), fontSize: 13)),
                ],
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _verify,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: _loading
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                        : const Text('Verify & Login', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 24),
                Center(
                  child: _countdown > 0
                      ? Text('Resend OTP in ${_countdown}s', style: const TextStyle(color: Color(0xFF64748B), fontSize: 14))
                      : TextButton(
                          onPressed: _resend,
                          child: const Text('Resend OTP', style: TextStyle(color: Color(0xFF3B82F6), fontSize: 14, fontWeight: FontWeight.bold)),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
