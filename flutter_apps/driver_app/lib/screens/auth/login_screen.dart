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

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final _phoneCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  bool _loading = false;
  bool _otpSent = false;
  String _serverOtp = '';
  int _seconds = 0;
  Timer? _timer;
  late AnimationController _animCtrl;

  static const Color _blue = Color(0xFF2563EB);
  static const Color _bg = Color(0xFF060D1E);
  static const Color _surface = Color(0xFF0D1B3E);

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _phoneCtrl.dispose();
    _otpCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final phone = _phoneCtrl.text.trim();
    if (phone.length != 10) {
      _showSnack('Valid 10-digit number enter చేయండి');
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
      _animCtrl.reset();
      _animCtrl.forward();
    } else {
      _showSnack(res['message'] ?? 'Error occurred', error: true);
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_seconds == 0) { t.cancel(); } else { setState(() => _seconds--); }
    });
  }

  Future<void> _verify() async {
    if (_otpCtrl.text.length != 6) return;
    setState(() => _loading = true);
    final res = await AuthService.verifyOtp(_phoneCtrl.text.trim(), _otpCtrl.text, 'driver');
    setState(() => _loading = false);
    if (res['success'] == true) {
      Navigator.pushAndRemoveUntil(context,
          MaterialPageRoute(builder: (_) => const HomeScreen()), (_) => false);
    } else {
      _showSnack('Invalid OTP. Try again.', error: true);
    }
  }

  void _showSnack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
      backgroundColor: error ? const Color(0xFFDC2626) : _blue,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _bg,
        body: Stack(
          children: [
            _buildBackground(),
            SafeArea(
              child: FadeTransition(
                opacity: _animCtrl,
                child: Column(
                  children: [
                    _buildTop(),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                        child: _otpSent ? _buildOtpPanel() : _buildPhonePanel(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackground() {
    return Positioned(
      top: -60,
      right: -60,
      child: Container(
        width: 260,
        height: 260,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [_blue.withOpacity(0.18), Colors.transparent],
          ),
        ),
      ),
    );
  }

  Widget _buildTop() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _blue.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _blue.withOpacity(0.3), width: 1),
              ),
              child: Image.asset('assets/images/pilot_logo.png',
                height: 20, fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Row(mainAxisSize: MainAxisSize.min, children: [
                  Text('JAGO ', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900)),
                  Text('PILOT', style: TextStyle(color: Color(0xFF2563EB), fontSize: 14, fontWeight: FontWeight.w900)),
                ])),
            ),
          ]),
          const SizedBox(height: 28),
          Text(
            _otpSent ? 'OTP Verify\nచేయండి 🔐' : 'Pilot గా\nLogin చేయండి 🏍️',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w900,
              height: 1.2,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _otpSent
                ? '+91 ${_phoneCtrl.text.trim()} కి OTP పంపించాం'
                : 'ప్రతి trip తో earn చేయండి',
            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildPhonePanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Mobile Number'),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
          ),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
              decoration: BoxDecoration(
                border: Border(right: BorderSide(color: Colors.white.withOpacity(0.08), width: 1)),
              ),
              child: const Row(children: [
                Text('🇮🇳', style: TextStyle(fontSize: 18)),
                SizedBox(width: 6),
                Text('+91', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
              ]),
            ),
            Expanded(
              child: TextField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 2),
                decoration: InputDecoration(
                  counterText: '',
                  hintText: '00000 00000',
                  hintStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: Colors.white.withOpacity(0.2), letterSpacing: 1),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 32),
        _buildBtn('Get OTP →', _sendOtp),
        const SizedBox(height: 24),
        _buildPrivacyNote(),
        const SizedBox(height: 36),
        _buildEarningsBanner(),
      ],
    );
  }

  Widget _buildOtpPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Enter 6-Digit OTP'),
        const SizedBox(height: 10),
        PinCodeTextField(
          appContext: context,
          length: 6,
          controller: _otpCtrl,
          keyboardType: TextInputType.number,
          textStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white),
          pinTheme: PinTheme(
            shape: PinCodeFieldShape.box,
            borderRadius: BorderRadius.circular(14),
            fieldHeight: 56,
            fieldWidth: 46,
            activeFillColor: _blue.withOpacity(0.2),
            inactiveFillColor: _surface,
            selectedFillColor: _blue.withOpacity(0.3),
            activeColor: _blue,
            inactiveColor: Colors.white.withOpacity(0.12),
            selectedColor: _blue,
          ),
          enableActiveFill: true,
          onCompleted: (_) => _verify(),
          onChanged: (_) {},
        ),
        if (_serverOtp.isNotEmpty) ...[
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _blue.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _blue.withOpacity(0.2)),
            ),
            child: Text('Dev OTP: $_serverOtp',
              style: const TextStyle(fontSize: 12, color: _blue, fontWeight: FontWeight.w700)),
          ),
        ],
        const SizedBox(height: 8),
        Row(children: [
          Text(
            _seconds > 0 ? 'Resend in ${_seconds}s' : '',
            style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13),
          ),
          if (_seconds == 0)
            TextButton(
              onPressed: () { _otpCtrl.clear(); setState(() => _otpSent = false); },
              child: const Text('← Change Number',
                style: TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.w700)),
            ),
        ]),
        const SizedBox(height: 24),
        _buildBtn('Verify & Start Earning →', _verify),
        const SizedBox(height: 16),
        _buildPrivacyNote(),
      ],
    );
  }

  Widget _buildBtn(String label, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: ElevatedButton(
        onPressed: _loading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: _blue,
          foregroundColor: Colors.white,
          disabledBackgroundColor: _blue.withOpacity(0.4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        child: _loading
            ? const SizedBox(width: 22, height: 22,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
            : Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 0.2)),
      ),
    );
  }

  Widget _label(String text) {
    return Text(text,
      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
          color: Colors.white.withOpacity(0.55), letterSpacing: 0.3));
  }

  Widget _buildPrivacyNote() {
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.shield_outlined, size: 14, color: Colors.white.withOpacity(0.3)),
      const SizedBox(width: 6),
      Text('Secure & Verified Platform',
        style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 12, fontWeight: FontWeight.w500)),
    ]);
  }

  Widget _buildEarningsBanner() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _blue.withOpacity(0.15), width: 1),
      ),
      child: Row(children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: _blue.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.trending_up_rounded, color: Color(0xFF2563EB), size: 24),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('₹800–₹1500/day', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 3),
          Text('Average Pilot Earnings', style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 12)),
        ])),
        Icon(Icons.arrow_forward_ios, color: Colors.white.withOpacity(0.2), size: 14),
      ]),
    );
  }
}
