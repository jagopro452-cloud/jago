import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../../config/api_config.dart';
import '../../services/auth_service.dart';
import '../home/home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  bool _loading = false;
  bool _otpSent = false;
  String _serverOtp = '';
  int _seconds = 0;
  Timer? _timer;

  Future<void> _sendOtp() async {
    final phone = _phoneCtrl.text.trim();
    if (phone.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Valid 10-digit number enter చేయండి'),
          backgroundColor: Color(0xFF2563EB)));
      return;
    }
    setState(() => _loading = true);
    final res = await AuthService.sendOtp(phone, 'driver');
    setState(() => _loading = false);
    if (res['success'] == true) {
      setState(() {
        _otpSent = true;
        _serverOtp = res['otp']?.toString() ?? '';
        _seconds = 30;
      });
      _startTimer();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(res['message'] ?? 'Error'),
          backgroundColor: Colors.red));
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_seconds == 0) {
        t.cancel();
      } else {
        setState(() => _seconds--);
      }
    });
  }

  Future<void> _verify() async {
    if (_otpCtrl.text.length != 6) return;
    setState(() => _loading = true);
    final res = await AuthService.verifyOtp(
        _phoneCtrl.text.trim(), _otpCtrl.text, 'driver');
    setState(() => _loading = false);
    if (res['success'] == true) {
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (_) => false);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Invalid OTP. Try again.'),
          backgroundColor: Colors.red));
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _phoneCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF060D1E) : const Color(0xFFF8FAFF);
    final textColor = isDark ? Colors.white : const Color(0xFF111827);
    final subColor = isDark ? Colors.white38 : const Color(0xFF6B7280);
    final fieldBg = isDark
        ? Colors.white.withOpacity(0.07)
        : const Color(0xFFF0F4FF);
    final dividerColor =
        isDark ? Colors.white12 : const Color(0xFFDDE3F0);

    return Scaffold(
      backgroundColor: bg,
      body: Stack(
        children: [
          if (isDark) ...[
            Positioned(
              top: -100,
              right: -80,
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF2563EB).withOpacity(0.07),
                ),
              ),
            ),
            Positioned(
              bottom: -60,
              left: -80,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF2563EB).withOpacity(0.05),
                ),
              ),
            ),
          ],
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 36),
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D1B3E),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: const Color(0xFF2563EB).withOpacity(0.25)),
                      ),
                      child: Image.asset(
                        'assets/images/pilot_logo.png',
                        height: 24,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('JAGO',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: 2)),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                  color: const Color(0xFF2563EB),
                                  borderRadius: BorderRadius.circular(4)),
                              child: const Text('PILOT',
                                  style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      letterSpacing: 2)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 52),
                  Text(
                    'Welcome Back 👋',
                    style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        color: textColor,
                        height: 1.2),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Login అయి earning start చేయండి',
                    style: TextStyle(fontSize: 14, color: subColor),
                  ),
                  const SizedBox(height: 36),
                  Text('PHONE NUMBER',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: subColor,
                          letterSpacing: 1.2)),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: fieldBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: dividerColor),
                    ),
                    child: Row(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 19),
                        decoration: BoxDecoration(
                            border: Border(
                                right: BorderSide(color: dividerColor))),
                        child: Text('+91',
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: textColor)),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _phoneCtrl,
                          keyboardType: TextInputType.phone,
                          maxLength: 10,
                          enabled: !_otpSent,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: textColor),
                          decoration: InputDecoration(
                            hintText: '98765 43210',
                            hintStyle: TextStyle(color: subColor),
                            border: InputBorder.none,
                            counterText: '',
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 19),
                            filled: false,
                          ),
                        ),
                      ),
                      if (_otpSent)
                        TextButton(
                          onPressed: () => setState(() {
                            _otpSent = false;
                            _otpCtrl.clear();
                            _timer?.cancel();
                          }),
                          child: const Text('Edit',
                              style: TextStyle(
                                  color: Color(0xFF2563EB), fontSize: 13)),
                        ),
                    ]),
                  ),
                  if (_otpSent) ...[
                    const SizedBox(height: 28),
                    Row(children: [
                      Text('OTP',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: subColor,
                              letterSpacing: 1.2)),
                      const Spacer(),
                      if (ApiConfig.isDev && _serverOtp.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                              color: const Color(0xFF2563EB).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6)),
                          child: Text('Dev: $_serverOtp',
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF2563EB),
                                  fontWeight: FontWeight.w600)),
                        ),
                    ]),
                    const SizedBox(height: 10),
                    PinCodeTextField(
                      appContext: context,
                      length: 6,
                      controller: _otpCtrl,
                      keyboardType: TextInputType.number,
                      pinTheme: PinTheme(
                        shape: PinCodeFieldShape.box,
                        borderRadius: BorderRadius.circular(12),
                        fieldHeight: 54,
                        fieldWidth: 46,
                        activeFillColor: isDark
                            ? Colors.white.withOpacity(0.1)
                            : Colors.white,
                        inactiveFillColor: fieldBg,
                        selectedFillColor: isDark
                            ? Colors.white.withOpacity(0.12)
                            : Colors.white,
                        activeColor: const Color(0xFF2563EB),
                        inactiveColor: dividerColor,
                        selectedColor: const Color(0xFF2563EB),
                        activeTextStyle: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: textColor),
                        inactiveTextStyle: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: textColor),
                      ),
                      enableActiveFill: true,
                      onCompleted: (_) => _verify(),
                      onChanged: (_) {},
                    ),
                    const SizedBox(height: 6),
                    Center(
                      child: _seconds > 0
                          ? Text('Resend OTP in ${_seconds}s',
                              style: TextStyle(color: subColor, fontSize: 13))
                          : TextButton(
                              onPressed: _sendOtp,
                              child: const Text('Resend OTP',
                                  style: TextStyle(
                                      color: Color(0xFF2563EB),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14))),
                    ),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed:
                          _loading ? null : (_otpSent ? _verify : _sendOtp),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: _loading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : Text(
                              _otpSent
                                  ? 'Verify & Continue →'
                                  : 'Send OTP',
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Center(
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.lock_outline_rounded,
                              size: 14, color: subColor),
                          const SizedBox(width: 6),
                          Text(
                              'Your number is secure. We never share data.',
                              style: TextStyle(color: subColor, fontSize: 12)),
                        ]),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
