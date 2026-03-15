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
  final _phoneFocus = FocusNode();

  bool _otpSent = false;
  bool _showPassword = false;
  bool _usePassword = false;
  bool _loading = false;
  String? _firebaseVerificationId;
  int _seconds = 0;
  Timer? _timer;

  late AnimationController _slideCtrl;
  late Animation<Offset> _slideAnim;
  late AnimationController _heroCtrl;
  late Animation<double> _heroScale;

  static const _blue = Color(0xFF2F80ED);
  static const _navy = Color(0xFF0B0B0B);

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
    _phoneFocus.dispose();
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
    await FirebaseOtpService.sendOtp(
      phoneNumber: '+91$phone',
      onCodeSent: (vId) {
        if (!mounted) return;
        _firebaseVerificationId = vId;
        setState(() { _loading = false; _otpSent = true; });
        _startTimer();
        _showSnack('OTP sent to +91$phone');
      },
      onError: (err) {
        if (!mounted) return;
        setState(() => _loading = false);
        _showSnack(err, error: true);
      },
      onAutoVerify: (idToken) async {
        if (!mounted) return;
        final res = await AuthService.verifyFirebaseToken(idToken, phone, 'customer');
        if (!mounted) return;
        setState(() => _loading = false);
        if (res['success'] == true) {
          Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const HomeScreen()), (_) => false);
        } else {
          _showSnack(res['message'] ?? 'Auto-verify failed', error: true);
        }
      },
    );
  }

  Future<void> _verifyOtp() async {
    final phone = _phoneCtrl.text.trim();
    final otp = _otpCtrl.text.trim();
    if (otp.length != 6) { _showSnack('Enter the 6-digit OTP', error: true); return; }
    setState(() => _loading = true);
    try {
      final idToken = await FirebaseOtpService.verifyOtp(smsCode: otp, verificationId: _firebaseVerificationId);
      if (!mounted) return;
      final res = await AuthService.verifyFirebaseToken(idToken, phone, 'customer');
      setState(() => _loading = false);
      if (!mounted) return;
      if (res['success'] == true) {
        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const HomeScreen()), (_) => false);
      } else {
        _showSnack(res['message'] ?? 'Verification failed', error: true);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _showSnack(e.toString().replaceAll('Exception: ', ''), error: true);
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

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            // ── Top illustration area (40% of screen) ──
            SizedBox(
              height: size.height * 0.40,
              child: ScaleTransition(
                scale: _heroScale,
                child: _buildIllustration(size),
              ),
            ),

            // ── Bottom form card (60% of screen) ──
            Expanded(
              child: SlideTransition(
                position: _slideAnim,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 24,
                        offset: const Offset(0, -6),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(
                        _otpSent ? 'Enter OTP' : (_usePassword ? 'Welcome Back!' : 'Welcome Back'),
                        style: GoogleFonts.poppins(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: _navy,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _otpSent
                          ? 'OTP sent to +91 ${_phoneCtrl.text}'
                          : (_usePassword ? 'Login with phone & password' : 'Login to continue'),
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                      const SizedBox(height: 28),

                      if (!_otpSent) ...[
                        _buildPhoneField(),
                        const SizedBox(height: 16),

                        if (_usePassword) ...[
                          _buildPasswordField(),
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
                        _buildPrimaryButton(
                          _usePassword ? 'Login' : 'Get OTP',
                          _usePassword ? _loginWithPassword : _sendOtp,
                        ),
                        const SizedBox(height: 16),

                        Center(
                          child: GestureDetector(
                            onTap: () => setState(() { _usePassword = !_usePassword; }),
                            child: RichText(text: TextSpan(
                              style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF94A3B8)),
                              children: [
                                TextSpan(text: _usePassword ? 'Login with OTP instead  ' : 'Login with Password  '),
                                TextSpan(
                                  text: _usePassword ? 'Use OTP' : 'Use Password',
                                  style: GoogleFonts.poppins(color: _blue, fontWeight: FontWeight.w700, fontSize: 13),
                                ),
                              ],
                            )),
                          ),
                        ),
                      ] else ...[
                        _buildOtpField(),
                        const SizedBox(height: 12),
                        Center(
                          child: _seconds > 0
                            ? Text('Resend OTP in ${_seconds}s',
                                style: GoogleFonts.poppins(color: const Color(0xFF94A3B8), fontSize: 13))
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
                              style: GoogleFonts.poppins(color: const Color(0xFF94A3B8), fontWeight: FontWeight.w600, fontSize: 13)),
                          ),
                        ),
                      ],

                      const SizedBox(height: 20),
                      _buildDivider(),
                      const SizedBox(height: 16),
                      _buildRegisterLink(),
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

  // ── Hero illustration (clean, no emojis) ────────────────────────────────
  Widget _buildIllustration(Size size) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(20, 48, 20, 0),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A6FE0), Color(0xFF2F80ED), Color(0xFF56CCF2)],
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Background circles
          Positioned(
            top: -30, right: -30,
            child: Container(width: 130, height: 130,
              decoration: BoxDecoration(shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.07))),
          ),
          Positioned(
            bottom: -20, left: -20,
            child: Container(width: 100, height: 100,
              decoration: BoxDecoration(shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06))),
          ),

          // Route path — dotted line
          Positioned(
            bottom: 52, left: size.width * 0.08, right: size.width * 0.08,
            child: SizedBox(
              height: 2,
              child: CustomPaint(painter: _DashedLinePainter(), size: Size.infinite),
            ),
          ),

          // Location pin — left (pickup)
          Positioned(
            left: size.width * 0.08,
            bottom: 36,
            child: _locationPin(const Color(0xFF4ADE80), Icons.my_location_rounded),
          ),

          // Car icon — center
          Positioned(
            bottom: 30, left: 0, right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(Icons.directions_car_filled_rounded,
                  color: Color(0xFF1A6FE0), size: 32),
              ),
            ),
          ),

          // Location pin — right (drop)
          Positioned(
            right: size.width * 0.08,
            bottom: 36,
            child: _locationPin(const Color(0xFFEF4444), Icons.location_on_rounded),
          ),

          // Center top: JAGO brand
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 20),
                Text(
                  'JAGO',
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 5,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Rides  •  Delivery  •  Intercity',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _locationPin(Color color, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 8, offset: const Offset(0, 3))],
          ),
          child: Icon(icon, color: Colors.white, size: 16),
        ),
        Container(width: 2, height: 6, color: color.withValues(alpha: 0.5)),
        Container(width: 6, height: 6,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
      ],
    );
  }

  // ── Form widgets ─────────────────────────────────────────────────────────
  Widget _buildPhoneField() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          decoration: const BoxDecoration(
            border: Border(right: BorderSide(color: Color(0xFFE2E8F0), width: 1.5)),
          ),
          child: Text('+91', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: _blue)),
        ),
        Expanded(
          child: TextField(
            controller: _phoneCtrl,
            focusNode: _phoneFocus,
            keyboardType: TextInputType.phone,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
            style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: _navy),
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

  Widget _buildPasswordField() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
      ),
      child: TextField(
        controller: _passwordCtrl,
        obscureText: !_showPassword,
        style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: _navy),
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

  Widget _buildOtpField() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _blue.withValues(alpha: 0.4), width: 2),
      ),
      child: TextField(
        controller: _otpCtrl,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
        textAlign: TextAlign.center,
        autofocus: true,
        style: GoogleFonts.poppins(
          fontSize: 32, fontWeight: FontWeight.w900,
          letterSpacing: 16, color: _blue,
        ),
        decoration: InputDecoration(
          hintText: '• • • • • •',
          hintStyle: GoogleFonts.poppins(fontSize: 22, letterSpacing: 10, color: const Color(0xFFCBD5E1)),
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
            colors: [Color(0xFF56CCF2), Color(0xFF1A6FE0)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          color: _loading ? _blue.withValues(alpha: 0.4) : null,
          borderRadius: BorderRadius.circular(18),
          boxShadow: _loading ? [] : [
            BoxShadow(color: _blue.withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 8)),
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

  Widget _buildDivider() {
    return Row(children: [
      const Expanded(child: Divider(color: Color(0xFFE2E8F0))),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Text('or', style: GoogleFonts.poppins(color: const Color(0xFF94A3B8), fontSize: 13)),
      ),
      const Expanded(child: Divider(color: Color(0xFFE2E8F0))),
    ]);
  }

  Widget _buildRegisterLink() {
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      Text("New to JAGO?  ", style: GoogleFonts.poppins(color: const Color(0xFF94A3B8), fontSize: 14)),
      GestureDetector(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
        child: Text('Create Account',
          style: GoogleFonts.poppins(color: _blue, fontWeight: FontWeight.w800, fontSize: 14)),
      ),
    ]);
  }
}

class _DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    const dashWidth = 6.0;
    const dashSpace = 5.0;
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x + dashWidth, 0), paint);
      x += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
