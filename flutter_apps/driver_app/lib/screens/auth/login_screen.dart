import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
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
  String _serverOtp = '';
  bool _usingFirebaseOtp = false;
  String? _firebaseVerificationId;
  int _seconds = 0;
  Timer? _timer;

  late AnimationController _slideCtrl;
  late Animation<Offset> _slideAnim;
  late AnimationController _heroCtrl;
  late Animation<double> _heroScale;

  static const _blue = Color(0xFF2F80ED);
  static const _navy = Color(0xFF0F172A);

  @override
  void initState() {
    super.initState();
    _slideCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _slideAnim = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOutCubic));
    _heroCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _heroScale = Tween<double>(begin: 0.8, end: 1.0)
        .animate(CurvedAnimation(parent: _heroCtrl, curve: Curves.easeOutBack));
    _slideCtrl.forward();
    _heroCtrl.forward();
  }

  @override
  void dispose() {
    _slideCtrl.dispose();
    _heroCtrl.dispose();
    _timer?.cancel();
    _phoneCtrl.dispose();
    _otpCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _showSnack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.white, fontSize: 13)),
      backgroundColor: error ? const Color(0xFFEF4444) : _blue,
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
    if (phone.length != 10) { _showSnack('Enter a valid 10-digit number', error: true); return; }
    setState(() => _loading = true);

    // Step 1: Ask server which OTP provider to use (server reads otp_settings from DB)
    Map<String, dynamic> serverRes;
    try {
      serverRes = await AuthService.sendOtp(phone, 'driver');
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      _showSnack('Network error. Check your connection and try again.', error: true);
      return;
    }
    if (!mounted) return;

    final provider = serverRes['provider']?.toString() ?? 'sms';
    final devOtp = serverRes['otp']?.toString() ?? '';

    if (provider == 'firebase') {
      // Step 2a: Server wants Firebase OTP — trigger on-device Firebase Phone Auth
      final switchMsg = serverRes['message']?.toString() ?? '';
      if (switchMsg.contains('failed') || switchMsg.contains('Switching')) {
        _showSnack('SMS OTP failed. Switching to secure verification.', error: false);
      }
      await FirebaseOtpService.sendOtp(
        phoneNumber: '+91$phone',
        onCodeSent: (vId) {
          if (!mounted) return;
          _firebaseVerificationId = vId;
          _usingFirebaseOtp = true;
          setState(() { _loading = false; _otpSent = true; });
          _startTimer();
          _showSnack('OTP sent to +91$phone');
        },
        onError: (err) {
          if (!mounted) return;
          setState(() => _loading = false);
          _showSnack('Verification unavailable. Please try again later.', error: true);
        },
        onAutoVerify: (idToken) async {
          if (!mounted) return;
          final res = await AuthService.verifyFirebaseToken(idToken, phone, 'driver');
          if (!mounted) return;
          setState(() => _loading = false);
          if (res['success'] == true) {
            Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const HomeScreen()), (_) => false);
          } else {
            _showSnack(res['message'] ?? 'Auto-verify failed', error: true);
          }
        },
      );
    } else {
      // Step 2b: Server sent SMS OTP successfully
      _usingFirebaseOtp = false;
      _serverOtp = devOtp;
      setState(() {
        _loading = false;
        _otpSent = true;
        if (devOtp.isNotEmpty) _otpCtrl.text = devOtp;
      });
      _startTimer();
      _showSnack(devOtp.isNotEmpty ? 'OTP: $devOtp (auto-filled)' : 'OTP sent to +91$phone');
    }
  }

  Future<void> _verifyOtp() async {
    final phone = _phoneCtrl.text.trim();
    final otp = _otpCtrl.text.trim();
    if (otp.length != 6) { _showSnack('Enter the 6-digit OTP', error: true); return; }
    setState(() => _loading = true);
    if (_usingFirebaseOtp) {
      try {
        final idToken = await FirebaseOtpService.verifyOtp(smsCode: otp, verificationId: _firebaseVerificationId);
        if (!mounted) return;
        final res = await AuthService.verifyFirebaseToken(idToken, phone, 'driver');
        setState(() => _loading = false);
        if (!mounted) return;
        if (res['success'] == true) {
          Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const HomeScreen()), (_) => false);
        } else {
          _showSnack(res['message'] ?? 'Verification failed', error: true);
        }
      } catch (e) {
        setState(() => _loading = false);
        _showSnack(e.toString().replaceAll('Exception: ', ''), error: true);
      }
    } else {
      final res = await AuthService.verifyOtp(phone, otp, 'driver');
      setState(() => _loading = false);
      if (!mounted) return;
      if (res['success'] == true) {
        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const HomeScreen()), (_) => false);
      } else {
        _showSnack(res['message'] ?? 'Invalid OTP', error: true);
      }
    }
  }

  Future<void> _loginWithPassword() async {
    final phone = _phoneCtrl.text.trim();
    final pass = _passwordCtrl.text;
    if (phone.length != 10) { _showSnack('Enter a valid 10-digit number', error: true); return; }
    if (pass.length < 6) { _showSnack('Password must be at least 6 characters', error: true); return; }
    setState(() => _loading = true);
    final res = await AuthService.loginWithPassword(phone, pass);
    setState(() => _loading = false);
    if (!mounted) return;
    if (res['success'] == true) {
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const HomeScreen()), (_) => false);
    } else {
      _showSnack(res['message'] ?? 'Login failed', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textPrimary = isDark ? Colors.white : _navy;
    final textSub = isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFF1A6FE0),
        body: Stack(
          children: [
            // ── Hero background ──
            Positioned(
              top: 0, left: 0, right: 0,
              height: size.height * 0.48,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1A6FE0), Color(0xFF0D3F8F)],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(top: -50, right: -50,
                      child: Container(width: 200, height: 200,
                        decoration: BoxDecoration(shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.06)))),
                    Positioned(bottom: 10, left: -40,
                      child: Container(width: 150, height: 150,
                        decoration: BoxDecoration(shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.04)))),
                    Center(
                      child: ScaleTransition(
                        scale: _heroScale,
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          SizedBox(
                            height: size.height * 0.14,
                            child: Image.asset(
                              'assets/images/pilot_logo.png',
                              fit: BoxFit.contain,
                              color: Colors.white,
                              errorBuilder: (_, __, ___) => Image.asset(
                                'assets/images/jago_logo_white.png',
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 100, height: 100,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  child: const Center(child: Text('P',
                                    style: TextStyle(color: Colors.white, fontSize: 52, fontWeight: FontWeight.w900))),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text('Earn. Drive. Grow.',
                            style: GoogleFonts.poppins(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.5,
                            )),
                        ]),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Slide-up card ──
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: SlideTransition(
                position: _slideAnim,
                child: Container(
                  constraints: BoxConstraints(maxHeight: size.height * 0.64),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 32, offset: const Offset(0, -8))],
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Center(child: Container(
                        margin: const EdgeInsets.only(top: 12, bottom: 24),
                        width: 40, height: 4,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(2)),
                      )),

                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: _blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.directions_bike_rounded, color: _blue, size: 14),
                          const SizedBox(width: 6),
                          Text('Pilot App', style: GoogleFonts.poppins(color: _blue, fontWeight: FontWeight.w700, fontSize: 12)),
                        ]),
                      ),
                      const SizedBox(height: 14),

                      Text(
                        _otpSent ? 'Enter OTP' : (_usePassword ? 'Welcome Back!' : 'Enter your number'),
                        style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w800, color: textPrimary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _otpSent
                          ? 'OTP sent to +91 ${_phoneCtrl.text}'
                          : (_usePassword ? 'Login with phone & password' : 'We\'ll send a verification code'),
                        style: GoogleFonts.poppins(fontSize: 13, color: textSub),
                      ),
                      const SizedBox(height: 28),

                      if (!_otpSent) ...[
                        _buildPhoneField(isDark, textPrimary),
                        const SizedBox(height: 16),
                        if (_usePassword) ...[
                          _buildPasswordField(isDark, textPrimary),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: GestureDetector(
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ForgotPasswordScreen())),
                              child: Text('Forgot Password?',
                                style: GoogleFonts.poppins(color: _blue, fontWeight: FontWeight.w600, fontSize: 13)),
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        _buildPrimaryButton(_usePassword ? 'Login' : 'Get OTP',
                          _usePassword ? _loginWithPassword : _sendOtp),
                        const SizedBox(height: 16),
                        Center(
                          child: GestureDetector(
                            onTap: () => setState(() { _usePassword = !_usePassword; }),
                            child: Text(
                              _usePassword ? 'Use OTP Login instead' : 'Use Password instead',
                              style: GoogleFonts.poppins(color: _blue, fontWeight: FontWeight.w700, fontSize: 13),
                            ),
                          ),
                        ),
                      ] else ...[
                        _buildOtpField(isDark),
                        const SizedBox(height: 12),
                        Center(
                          child: _seconds > 0
                            ? Text('Resend OTP in ${_seconds}s', style: GoogleFonts.poppins(color: textSub, fontSize: 13))
                            : GestureDetector(
                                onTap: () { setState(() { _otpSent = false; _otpCtrl.clear(); }); _sendOtp(); },
                                child: Text('Resend OTP',
                                  style: GoogleFonts.poppins(color: _blue, fontWeight: FontWeight.w700, fontSize: 13)),
                              ),
                        ),
                        const SizedBox(height: 28),
                        _buildPrimaryButton('Verify & Continue', _verifyOtp),
                        const SizedBox(height: 12),
                        Center(
                          child: GestureDetector(
                            onTap: () => setState(() { _otpSent = false; _otpCtrl.clear(); }),
                            child: Text('← Change Number',
                              style: GoogleFonts.poppins(color: textSub, fontWeight: FontWeight.w600, fontSize: 13)),
                          ),
                        ),
                      ],

                      const SizedBox(height: 20),
                      Row(children: [
                        Expanded(child: Divider(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))),
                        Padding(padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text('or', style: GoogleFonts.poppins(color: const Color(0xFF94A3B8), fontSize: 13))),
                        Expanded(child: Divider(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))),
                      ]),
                      const SizedBox(height: 16),
                      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Text("New pilot?  ", style: GoogleFonts.poppins(color: textSub, fontSize: 14)),
                        GestureDetector(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                          child: Text('Register Now',
                            style: GoogleFonts.poppins(color: _blue, fontWeight: FontWeight.w800, fontSize: 14)),
                        ),
                      ]),
                    ]),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhoneField(bool isDark, Color textColor) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0), width: 1.5),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          decoration: BoxDecoration(
            border: Border(right: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0), width: 1.5)),
          ),
          child: Text('+91', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: _blue)),
        ),
        Expanded(
          child: TextField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
            style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: textColor),
            decoration: InputDecoration(
              hintText: '10-digit mobile number',
              hintStyle: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF94A3B8)),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildPasswordField(bool isDark, Color textColor) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0), width: 1.5),
      ),
      child: TextField(
        controller: _passwordCtrl,
        obscureText: !_showPassword,
        style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: textColor),
        decoration: InputDecoration(
          hintText: 'Enter your password',
          hintStyle: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF94A3B8)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          prefixIcon: const Icon(Icons.lock_outline_rounded, color: Color(0xFF94A3B8), size: 20),
          suffixIcon: IconButton(
            icon: Icon(_showPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              color: const Color(0xFF94A3B8), size: 20),
            onPressed: () => setState(() => _showPassword = !_showPassword),
          ),
        ),
      ),
    );
  }

  Widget _buildOtpField(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _blue.withValues(alpha: 0.4), width: 2),
      ),
      child: TextField(
        controller: _otpCtrl,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
        textAlign: TextAlign.center,
        autofocus: true,
        style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: 16, color: _blue),
        decoration: InputDecoration(
          hintText: '• • • • • •',
          hintStyle: GoogleFonts.poppins(fontSize: 22, letterSpacing: 10,
            color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 20),
        ),
      ),
    );
  }

  Widget _buildPrimaryButton(String label, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: _loading ? null : const LinearGradient(
            colors: [Color(0xFF2F80ED), Color(0xFF0D3F8F)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          color: _loading ? _blue.withValues(alpha: 0.4) : null,
          borderRadius: BorderRadius.circular(18),
          boxShadow: _loading ? [] : [
            BoxShadow(color: _blue.withValues(alpha: 0.45), blurRadius: 20, offset: const Offset(0, 8)),
          ],
        ),
        child: ElevatedButton(
          onPressed: _loading ? null : onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            elevation: 0,
          ),
          child: _loading
            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
            : Text(label, style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.3)),
        ),
      ),
    );
  }
}
