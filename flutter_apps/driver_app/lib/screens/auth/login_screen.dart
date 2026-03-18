import 'dart:async';
import 'package:flutter/material.dart';
import '../../config/jago_theme.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sms_autofill/sms_autofill.dart';
import '../../services/auth_service.dart';
import '../../services/firebase_otp_service.dart';
import '../home/home_screen.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final _phoneCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _otpSent = false;
  bool _showPassword = false;
  bool _usePassword = false;
  bool _loading = false;
  int _seconds = 0;
  Timer? _timer;
  String? _firebaseVerificationId;

  late AnimationController _cardCtrl;
  late Animation<Offset> _cardSlide;
  late AnimationController _logoCtrl;
  late Animation<double> _logoFade;

  static const _blue = JT.primary;
  static const _dark = Color(0xFF080F1E);

  @override
  void initState() {
    super.initState();
    _cardCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _cardSlide = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _cardCtrl, curve: Curves.easeOutCubic));

    _logoCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _logoFade = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _logoCtrl, curve: Curves.easeOut));

    _logoCtrl.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _cardCtrl.forward();
    });
  }

  @override
  void dispose() {
    _cardCtrl.dispose();
    _logoCtrl.dispose();
    _timer?.cancel();
    _phoneCtrl.dispose();
    _otpCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.white, fontSize: 13)),
      backgroundColor: error ? const Color(0xFFEF4444) : const Color(0xFF10B981),
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 3),
    ));
  }

  void _startTimer() {
    _timer?.cancel();
    _seconds = 30;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted || _seconds == 0) { t.cancel(); return; }
      setState(() => _seconds--);
    });
  }

  Future<void> _sendOtp() async {
    final phone = _phoneCtrl.text.trim();
    if (phone.length != 10) { _snack('Enter a valid 10-digit number', error: true); return; }
    setState(() => _loading = true);
    // Server rate-limit check first
    final res = await AuthService.sendOtp(phone, 'driver');
    if (!mounted) return;
    if (res['success'] != true) {
      setState(() => _loading = false);
      _snack(res['message'] ?? 'Failed to send OTP', error: true);
      return;
    }
    // Now actually send OTP via Firebase Phone Auth
    try {
      await FirebaseOtpService.sendOtp(
        phoneNumber: '+91$phone',
        onCodeSent: (verificationId) {
          if (!mounted) return;
          _firebaseVerificationId = verificationId;
          setState(() { _otpSent = true; _loading = false; });
          _startTimer();
          _snack('OTP sent to +91$phone');
          SmsAutoFill().listenForCode();
        },
        onError: (error) {
          if (!mounted) return;
          setState(() => _loading = false);
          _snack(error, error: true);
        },
        onAutoVerify: (idToken) async {
          if (!mounted) return;
          setState(() => _loading = true);
          final verifyRes = await AuthService.verifyFirebaseToken(idToken, phone, 'driver');
          if (!mounted) return;
          setState(() => _loading = false);
          if (verifyRes['success'] == true) {
            Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const HomeScreen()), (_) => false);
          } else {
            setState(() => _otpSent = true);
            _startTimer();
            _snack('Enter the OTP sent to your phone');
          }
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _snack('Failed to send OTP. Please try again.', error: true);
    }
  }

  Future<void> _verifyOtp() async {
    final phone = _phoneCtrl.text.trim();
    final otp = _otpCtrl.text.trim();
    if (otp.length != 6) { _snack('Enter the 6-digit OTP', error: true); return; }
    if (_loading) return;
    setState(() => _loading = true);
    try {
      final idToken = await FirebaseOtpService.verifyOtp(
        smsCode: otp,
        verificationId: _firebaseVerificationId,
      );
      if (!mounted) return;
      final res = await AuthService.verifyFirebaseToken(idToken, phone, 'driver');
      if (!mounted) return;
      setState(() => _loading = false);
      if (res['success'] == true) {
        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const HomeScreen()), (_) => false);
      } else {
        _snack(res['message'] ?? 'Verification failed. Try again.', error: true);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      String msg = e.toString().replaceAll('Exception: ', '');
      if (msg.contains('missing') || msg.contains('null')) {
        msg = 'Session expired. Please resend OTP.';
        setState(() { _otpSent = false; _otpCtrl.clear(); });
      } else if (msg.contains('invalid-verification-code') || msg.contains('invalid-verification-id')) {
        msg = 'Wrong OTP. Please check and try again.';
      }
      _snack(msg, error: true);
    }
  }

  Future<void> _loginWithPassword() async {
    final phone = _phoneCtrl.text.trim();
    final pass = _passwordCtrl.text;
    if (phone.length != 10) { _snack('Enter a valid 10-digit number', error: true); return; }
    if (pass.length < 6) { _snack('Password must be at least 6 characters', error: true); return; }
    setState(() => _loading = true);
    final res = await AuthService.loginWithPassword(phone, pass);
    if (!mounted) return;
    setState(() => _loading = false);
    if (res['success'] == true) {
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const HomeScreen()), (_) => false);
    } else {
      _snack(res['message'] ?? 'Login failed', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(statusBarColor: Colors.transparent, statusBarIconBrightness: Brightness.dark),
      child: Scaffold(
        backgroundColor: _blue,
        resizeToAvoidBottomInset: true,
        body: Theme(
          data: ThemeData.light().copyWith(
            textTheme: GoogleFonts.poppinsTextTheme(),
          ),
          child: Stack(
          children: [
            // Blue background
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [_blue, const Color(0xFF1565D8), Colors.white],
                    stops: const [0.0, 0.42, 0.42],
                  ),
                ),
              ),
            ),

            // Top brand
            Positioned(
              top: 0, left: 0, right: 0,
              height: size.height * 0.42,
              child: FadeTransition(
                opacity: _logoFade,
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 76, height: 76,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: Colors.white.withValues(alpha: 0.2),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.asset(
                            'assets/images/pilot_logo.png',
                            fit: BoxFit.contain,
                            color: Colors.white,
                            colorBlendMode: BlendMode.srcIn,
                            errorBuilder: (_, __, ___) => Center(
                              child: Text('P', style: GoogleFonts.poppins(
                                fontSize: 40, fontWeight: FontWeight.w900, color: Colors.white, height: 1,
                              )),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text('PILOT', style: GoogleFonts.poppins(
                        fontSize: 22, fontWeight: FontWeight.w900,
                        color: Colors.white, letterSpacing: 4,
                      )),
                      const SizedBox(height: 4),
                      Text('Earn. Drive. Grow.', style: GoogleFonts.poppins(
                        fontSize: 12, fontWeight: FontWeight.w400,
                        color: Colors.white.withValues(alpha: 0.75),
                        letterSpacing: 0.5,
                      )),
                    ],
                  ),
                ),
              ),
            ),

            // White bottom card
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: SlideTransition(
                position: _cardSlide,
                child: Container(
                  constraints: BoxConstraints(maxHeight: size.height * 0.64),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                  ),
                  child: SingleChildScrollView(
                    padding: EdgeInsets.only(
                      left: 28, right: 28, top: 8,
                      bottom: MediaQuery.of(context).viewInsets.bottom + 32,
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Center(child: Container(
                        margin: const EdgeInsets.only(top: 12, bottom: 24),
                        width: 36, height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      )),

                      Text(
                        _otpSent ? 'Enter OTP' : (_usePassword ? 'Welcome Back' : 'Sign In'),
                        style: GoogleFonts.poppins(fontSize: 26, fontWeight: FontWeight.w800, color: _dark),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _otpSent
                          ? 'Sent to +91 ${_phoneCtrl.text}'
                          : (_usePassword ? 'Login with your password' : 'Enter your mobile number'),
                        style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF94A3B8)),
                      ),
                      const SizedBox(height: 28),

                      if (!_otpSent) ...[
                        _buildPhoneField(),
                        const SizedBox(height: 14),
                        if (_usePassword) ...[
                          _buildPasswordField(),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: GestureDetector(
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ForgotPasswordScreen())),
                              child: Text('Forgot Password?', style: GoogleFonts.poppins(color: _blue, fontWeight: FontWeight.w600, fontSize: 13)),
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        _buildButton(_usePassword ? 'Login' : 'Get OTP', _usePassword ? _loginWithPassword : _sendOtp),
                        const SizedBox(height: 16),
                        Center(
                          child: GestureDetector(
                            onTap: () => setState(() { _usePassword = !_usePassword; }),
                            child: Text(
                              _usePassword ? 'Use OTP instead' : 'Use Password instead',
                              style: GoogleFonts.poppins(color: _blue, fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                          ),
                        ),
                      ] else ...[
                        _buildOtpField(),
                        const SizedBox(height: 12),
                        Center(
                          child: _seconds > 0
                            ? Text('Resend in ${_seconds}s', style: GoogleFonts.poppins(color: const Color(0xFF94A3B8), fontSize: 13))
                            : GestureDetector(
                                onTap: () { setState(() { _otpSent = false; _otpCtrl.clear(); }); _sendOtp(); },
                                child: Text('Resend OTP', style: GoogleFonts.poppins(color: _blue, fontWeight: FontWeight.w700, fontSize: 13)),
                              ),
                        ),
                        const SizedBox(height: 28),
                        _buildButton('Verify & Login', _verifyOtp),
                        const SizedBox(height: 12),
                        Center(
                          child: GestureDetector(
                            onTap: () => setState(() { _otpSent = false; _otpCtrl.clear(); }),
                            child: Text('← Change Number', style: GoogleFonts.poppins(
                              color: const Color(0xFF94A3B8), fontWeight: FontWeight.w500, fontSize: 13)),
                          ),
                        ),
                      ],

                      const SizedBox(height: 28),
                      Row(children: [
                        const Expanded(child: Divider(color: Color(0xFFF1F5F9), thickness: 1.5)),
                        Padding(padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Text('or', style: GoogleFonts.poppins(color: const Color(0xFFCBD5E1), fontSize: 13))),
                        const Expanded(child: Divider(color: Color(0xFFF1F5F9), thickness: 1.5)),
                      ]),
                      const SizedBox(height: 20),
                      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Text("New pilot?  ", style: GoogleFonts.poppins(color: const Color(0xFF94A3B8), fontSize: 14)),
                        GestureDetector(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                          child: Text('Register Now', style: GoogleFonts.poppins(color: _blue, fontWeight: FontWeight.w800, fontSize: 14)),
                        ),
                      ]),
                    ]),
                  ),
                ),
              ),
            ),
          ],
        ),
        ),  // Theme
      ),
    );
  }

  Widget _buildPhoneField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _blue.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: _blue.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          decoration: BoxDecoration(
            color: _blue.withValues(alpha: 0.08),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(14),
              bottomLeft: Radius.circular(14),
            ),
            border: Border(right: BorderSide(color: _blue.withValues(alpha: 0.2), width: 1.5)),
          ),
          child: Text('+91', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w800, color: _blue)),
        ),
        Expanded(
          child: TextField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
            style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: _dark),
            decoration: InputDecoration(
              hintText: 'Mobile number',
              hintStyle: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFFCBD5E1)),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildPasswordField() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
      ),
      child: TextField(
        controller: _passwordCtrl,
        obscureText: !_showPassword,
        style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: _dark),
        decoration: InputDecoration(
          hintText: 'Password',
          hintStyle: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFFCBD5E1)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          prefixIcon: const Icon(Icons.lock_outline_rounded, color: Color(0xFFCBD5E1), size: 20),
          suffixIcon: IconButton(
            icon: Icon(_showPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              color: const Color(0xFFCBD5E1), size: 20),
            onPressed: () => setState(() => _showPassword = !_showPassword),
          ),
        ),
      ),
    );
  }

  Widget _buildOtpField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _blue.withValues(alpha: 0.4), width: 2),
      ),
      child: PinFieldAutoFill(
        controller: _otpCtrl,
        codeLength: 6,
        keyboardType: TextInputType.number,
        decoration: UnderlineDecoration(
          textStyle: GoogleFonts.poppins(
            fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 4, color: _dark,
          ),
          colorBuilder: FixedColorBuilder(Colors.transparent),
        ),
        onCodeSubmitted: (code) { if (code.length == 6) _verifyOtp(); },
        onCodeChanged: (code) {
          _otpCtrl.text = code ?? '';
          if ((code?.length ?? 0) == 6) _verifyOtp();
        },
      ),
    );
  }

  Widget _buildButton(String label, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: ElevatedButton(
        onPressed: _loading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: _loading ? _blue.withValues(alpha: 0.4) : _blue,
          foregroundColor: Colors.white,
          elevation: _loading ? 0 : 6,
          shadowColor: _blue.withValues(alpha: 0.4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
        child: _loading
          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
          : Text(label, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.3)),
      ),
    );
  }
}
