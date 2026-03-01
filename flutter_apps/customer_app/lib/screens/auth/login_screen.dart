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
  late AnimationController _slideCtrl;
  late Animation<Offset> _slideAnim;

  static const Color _blue = Color(0xFF1E6DE5);
  static const Color _dark = Color(0xFF111827);

  @override
  void initState() {
    super.initState();
    _slideCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOut));
    _slideCtrl.forward();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _phoneCtrl.dispose();
    _otpCtrl.dispose();
    _slideCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final phone = _phoneCtrl.text.trim();
    if (phone.length != 10) {
      _showSnack('Valid 10-digit number enter చేయండి');
      return;
    }
    setState(() => _loading = true);
    final res = await AuthService.sendOtp(phone, 'customer');
    setState(() => _loading = false);
    if (res['success'] == true) {
      setState(() {
        _otpSent = true;
        _serverOtp = res['otp']?.toString() ?? '';
        _seconds = 30;
      });
      _startTimer();
      _slideCtrl.reset();
      _slideCtrl.forward();
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
    final res = await AuthService.verifyOtp(_phoneCtrl.text.trim(), _otpCtrl.text, 'customer');
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
      content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
      backgroundColor: error ? const Color(0xFFE53935) : _blue,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SlideTransition(
                position: _slideAnim,
                child: FadeTransition(
                  opacity: _slideCtrl,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                    child: _otpSent ? _buildOtpPanel() : _buildPhonePanel(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1244A2), Color(0xFF1E6DE5), Color(0xFF4B9EFF)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 20, 28, 36),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Image.asset('assets/images/jago_logo.png',
                    height: 22, fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Text('JAGO',
                      style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w900, letterSpacing: 3))),
                ),
              ]),
              const SizedBox(height: 24),
              Text(
                _otpSent ? 'OTP Enter\nచేయండి 📱' : 'Welcome to\nJAGO 👋',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  height: 1.25,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _otpSent
                    ? '+91 ${_phoneCtrl.text.trim()} కి OTP పంపించాం'
                    : 'Safe, affordable rides — ఎక్కడైనా',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.78),
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhonePanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 28),
        const Text('Mobile Number',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
              color: Color(0xFF374151), letterSpacing: 0.3)),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFF),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFDDE4F5), width: 1.5),
          ),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
              decoration: const BoxDecoration(
                border: Border(right: BorderSide(color: Color(0xFFDDE4F5), width: 1.5)),
              ),
              child: const Row(children: [
                Text('🇮🇳', style: TextStyle(fontSize: 18)),
                SizedBox(width: 6),
                Text('+91', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
              ]),
            ),
            Expanded(
              child: TextField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF111827), letterSpacing: 2),
                decoration: const InputDecoration(
                  counterText: '',
                  hintText: '00000 00000',
                  hintStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: Color(0xFFB0BAD0), letterSpacing: 1),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 32),
        _buildBtn('Get OTP →', _sendOtp),
        const SizedBox(height: 20),
        _buildPrivacyNote(),
        const SizedBox(height: 32),
        _buildFeatureRow(),
      ],
    );
  }

  Widget _buildOtpPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 28),
        const Text('Enter 6-Digit OTP',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
              color: Color(0xFF374151), letterSpacing: 0.3)),
        const SizedBox(height: 10),
        PinCodeTextField(
          appContext: context,
          length: 6,
          controller: _otpCtrl,
          keyboardType: TextInputType.number,
          textStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF111827)),
          pinTheme: PinTheme(
            shape: PinCodeFieldShape.box,
            borderRadius: BorderRadius.circular(14),
            fieldHeight: 56,
            fieldWidth: 46,
            activeFillColor: const Color(0xFFEEF4FF),
            inactiveFillColor: const Color(0xFFF8FAFF),
            selectedFillColor: const Color(0xFFDEEBFF),
            activeColor: _blue,
            inactiveColor: const Color(0xFFDDE4F5),
            selectedColor: _blue,
          ),
          enableActiveFill: true,
          onCompleted: (_) => _verify(),
          onChanged: (_) {},
        ),
        const SizedBox(height: 8),
        if (_serverOtp.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _blue.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('Dev OTP: $_serverOtp',
              style: const TextStyle(fontSize: 12, color: _blue, fontWeight: FontWeight.w700)),
          ),
        const SizedBox(height: 6),
        Row(children: [
          Text(
            _seconds > 0 ? 'Resend OTP in ${_seconds}s' : '',
            style: TextStyle(color: Colors.grey[500], fontSize: 13),
          ),
          if (_seconds == 0)
            TextButton(
              onPressed: () { _otpCtrl.clear(); setState(() => _otpSent = false); },
              child: const Text('← Back to Phone', style: TextStyle(color: _blue, fontWeight: FontWeight.w700)),
            ),
        ]),
        const SizedBox(height: 24),
        _buildBtn('Verify & Continue →', _verify),
        const SizedBox(height: 16),
        _buildPrivacyNote(),
      ],
    );
  }

  Widget _buildBtn(String label, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _loading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: _blue,
          foregroundColor: Colors.white,
          disabledBackgroundColor: _blue.withOpacity(0.5),
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

  Widget _buildPrivacyNote() {
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.shield_outlined, size: 14, color: Colors.grey[400]),
      const SizedBox(width: 6),
      Text('Your data is secure & private',
        style: TextStyle(color: Colors.grey[400], fontSize: 12, fontWeight: FontWeight.w500)),
    ]);
  }

  Widget _buildFeatureRow() {
    return Row(children: [
      _featureChip(Icons.electric_bike, 'Quick Rides'),
      const SizedBox(width: 10),
      _featureChip(Icons.verified_outlined, 'Verified Pilots'),
      const SizedBox(width: 10),
      _featureChip(Icons.payments_outlined, 'Easy Pay'),
    ]);
  }

  Widget _featureChip(IconData icon, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE8EEFF), width: 1),
        ),
        child: Column(children: [
          Icon(icon, color: _blue, size: 22),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF374151)),
            textAlign: TextAlign.center),
        ]),
      ),
    );
  }
}
