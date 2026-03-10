import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  late TabController _tabCtrl;

  // Password tab
  final _phonePassCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _showPassword = false;

  // OTP tab
  final _phoneOtpCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  bool _otpSent = false;
  String _serverOtp = '';
  int _seconds = 0;
  Timer? _timer;
  // Firebase OTP
  String? _firebaseVerificationId;
  bool _usingFirebaseOtp = false;

  bool _loading = false;
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  static const Color _blue = Color(0xFF1E6DE5);

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _timer?.cancel();
    _phonePassCtrl.dispose(); _passwordCtrl.dispose();
    _phoneOtpCtrl.dispose(); _otpCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  void _showSnack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
      backgroundColor: error ? const Color(0xFFE53935) : _blue,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  // ── Password Login ──────────────────────────────────────────────────────
  Future<void> _loginWithPassword() async {
    final phone = _phonePassCtrl.text.trim();
    final pass = _passwordCtrl.text;
    if (phone.length != 10) { _showSnack('Enter a valid 10-digit phone number', error: true); return; }
    if (pass.length < 6) { _showSnack('Password must be at least 6 characters', error: true); return; }
    setState(() => _loading = true);
    final res = await AuthService.loginWithPassword(phone, pass);
    setState(() => _loading = false);
    if (!mounted) return;
    if (res['success'] == true) {
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const HomeScreen()), (_) => false);
    } else {
      _showSnack(res['message'] ?? 'Login failed. Try again.', error: true);
    }
  }

  // ── OTP Login ───────────────────────────────────────────────────────────
  void _startTimer() {
    _timer?.cancel();
    _seconds = 30;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted || _seconds == 0) { t.cancel(); return; }
      setState(() => _seconds--);
    });
  }

  Future<void> _sendOtp() async {
    final phone = _phoneOtpCtrl.text.trim();
    if (phone.length != 10) { _showSnack('Enter a valid 10-digit phone number', error: true); return; }
    setState(() => _loading = true);

    // Try Firebase Phone Auth first; fall back to server OTP if unavailable
    bool firebaseSent = false;
    FirebaseOtpService.sendOtp(
      phoneNumber: '+91$phone',
      onCodeSent: (verificationId) {
        if (!mounted) return;
        setState(() {
          _firebaseVerificationId = verificationId;
          _usingFirebaseOtp = true;
          _loading = false;
          _otpSent = true;
        });
        _startTimer();
        _showSnack('OTP sent to +91$phone');
      },
      onError: (error) async {
        // Firebase failed — fall back to server OTP
        if (!mounted) return;
        final res = await AuthService.sendOtp(phone, 'customer');
        if (!mounted) return;
        setState(() { _loading = false; });
        if (res['success'] == true) {
          setState(() {
            _usingFirebaseOtp = false;
            _serverOtp = '';
            _otpSent = true;
          });
          _startTimer();
          _showSnack('OTP sent to +91$phone');
        } else {
          _showSnack(res['message'] ?? 'Failed to send OTP. Try again.', error: true);
        }
      },
      onAutoVerify: (idToken) async {
        // Firebase auto-verified (Android) → login immediately
        if (!mounted) return;
        final res = await AuthService.verifyFirebaseToken(idToken, phone, 'customer');
        if (!mounted) return;
        setState(() => _loading = false);
        if (res['success'] == true) {
          Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const HomeScreen()), (_) => false);
        }
      },
    );
    firebaseSent = true;
    if (firebaseSent) return; // wait for callbacks above
  }

  Future<void> _verifyOtp() async {
    final phone = _phoneOtpCtrl.text.trim();
    final otp = _otpCtrl.text.trim();
    if (otp.length != 6) { _showSnack('Enter the 6-digit OTP', error: true); return; }
    setState(() => _loading = true);

    if (_usingFirebaseOtp && _firebaseVerificationId != null) {
      // Firebase verification path
      try {
        final idToken = await FirebaseOtpService.verifyOtp(
          smsCode: otp,
          verificationId: _firebaseVerificationId,
        );
        final res = await AuthService.verifyFirebaseToken(idToken, phone, 'customer');
        setState(() => _loading = false);
        if (!mounted) return;
        if (res['success'] == true) {
          Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const HomeScreen()), (_) => false);
        } else {
          _showSnack(res['message'] ?? 'Verification failed. Try again.', error: true);
        }
      } catch (e) {
        setState(() => _loading = false);
        _showSnack(e.toString().replaceAll('Exception: ', ''), error: true);
      }
    } else {
      // Server OTP fallback path
      final res = await AuthService.verifyOtp(phone, otp, 'customer');
      setState(() => _loading = false);
      if (!mounted) return;
      if (res['success'] == true) {
        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const HomeScreen()), (_) => false);
      } else {
        _showSnack(res['message'] ?? 'Invalid OTP. Try again.', error: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: FadeTransition(
          opacity: _fadeAnim,
          child: SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 32),
                _buildHeader(),
                const SizedBox(height: 32),
                _buildTabBar(),
                Expanded(
                  child: TabBarView(
                    controller: _tabCtrl,
                    children: [_buildPasswordTab(), _buildOtpTab()],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(children: [
      SizedBox(
        width: 88, height: 88,
        child: Image.asset(
          'assets/images/jago_logo.png',
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Image.asset(
            'assets/images/logo.png',
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Container(
              width: 88, height: 88,
              decoration: BoxDecoration(color: _blue, borderRadius: BorderRadius.circular(20)),
              child: const Center(child: Text('J', style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900))),
            ),
          ),
        ),
      ),
      const SizedBox(height: 12),
      const Text('JAGO', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFF1E6DE5), letterSpacing: 3)),
      const SizedBox(height: 4),
      Text('Your ride, your way', style: TextStyle(fontSize: 13, color: Colors.grey[400], fontWeight: FontWeight.w500)),
    ]);
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(color: const Color(0xFFF0F4FF), borderRadius: BorderRadius.circular(14)),
      padding: const EdgeInsets.all(4),
      child: TabBar(
        controller: _tabCtrl,
        indicator: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(11), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, 2))]),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: _blue,
        unselectedLabelColor: Colors.grey[500],
        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(text: '🔑  Password'),
          Tab(text: '📱  OTP Login'),
        ],
      ),
    );
  }

  // ── Password Tab ────────────────────────────────────────────────────────
  Widget _buildPasswordTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Welcome Back!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.grey[900])),
        const SizedBox(height: 4),
        Text('Login with your phone & password', style: TextStyle(fontSize: 13, color: Colors.grey[500])),
        const SizedBox(height: 24),
        _label('Phone Number'),
        const SizedBox(height: 8),
        _phoneField(_phonePassCtrl),
        const SizedBox(height: 16),
        _label('Password'),
        const SizedBox(height: 8),
        _passwordField(),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerRight,
          child: GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ForgotPasswordScreen())),
            child: Text('Forgot Password?', style: TextStyle(color: _blue, fontWeight: FontWeight.w600, fontSize: 13)),
          ),
        ),
        const SizedBox(height: 28),
        _primaryBtn('Login', _loginWithPassword),
        const SizedBox(height: 24),
        _registerLink(),
      ]),
    );
  }

  // ── OTP Tab ─────────────────────────────────────────────────────────────
  Widget _buildOtpTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(_otpSent ? 'Enter OTP' : 'Login with OTP', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.grey[900])),
        const SizedBox(height: 4),
        Text(_otpSent ? 'OTP sent to +91${_phoneOtpCtrl.text}' : 'Quick login — no password needed!', style: TextStyle(fontSize: 13, color: Colors.grey[500])),
        const SizedBox(height: 24),
        _label('Phone Number'),
        const SizedBox(height: 8),
        _phoneField(_phoneOtpCtrl, enabled: !_otpSent),
        if (!_otpSent) ...[
          const SizedBox(height: 28),
          _primaryBtn('Send OTP', _sendOtp),
        ] else ...[
          const SizedBox(height: 20),
          _label('6-Digit OTP'),
          const SizedBox(height: 8),
          _otpField(),
          const SizedBox(height: 8),
          if (_seconds > 0)
            Center(child: Text('Resend OTP in ${_seconds}s', style: TextStyle(color: Colors.grey[400], fontSize: 13)))
          else
            Center(child: GestureDetector(onTap: _sendOtp, child: Text('Resend OTP', style: TextStyle(color: _blue, fontWeight: FontWeight.w600, fontSize: 13)))),
          const SizedBox(height: 28),
          _primaryBtn('Verify & Login', _verifyOtp),
          const SizedBox(height: 12),
          Center(child: GestureDetector(
            onTap: () => setState(() { _otpSent = false; _otpCtrl.clear(); }),
            child: Text('← Change Number', style: TextStyle(color: Colors.grey[500], fontSize: 13, fontWeight: FontWeight.w600)),
          )),
        ],
        const SizedBox(height: 24),
        _registerLink(),
      ]),
    );
  }

  // ── Shared widgets ───────────────────────────────────────────────────────
  Widget _label(String text) => Text(text, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.grey[700]));

  Widget _phoneField(TextEditingController ctrl, {bool enabled = true}) {
    return Container(
      decoration: BoxDecoration(
        color: enabled ? const Color(0xFFF5F7FA) : const Color(0xFFEEEEEE),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(children: [
        const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('+91', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E)))),
        Container(width: 1, height: 24, color: Colors.grey[300]),
        Expanded(child: TextField(
          controller: ctrl,
          enabled: enabled,
          keyboardType: TextInputType.phone,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          decoration: const InputDecoration(hintText: 'Enter 10-digit number', border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16)),
        )),
      ]),
    );
  }

  Widget _passwordField() {
    return Container(
      decoration: BoxDecoration(color: const Color(0xFFF5F7FA), borderRadius: BorderRadius.circular(14)),
      child: TextField(
        controller: _passwordCtrl,
        obscureText: !_showPassword,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          hintText: 'Enter your password',
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          prefixIcon: Icon(Icons.lock_outline_rounded, color: Colors.grey[400]),
          suffixIcon: IconButton(icon: Icon(_showPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.grey[400]), onPressed: () => setState(() => _showPassword = !_showPassword)),
        ),
      ),
    );
  }

  Widget _otpField() {
    return Container(
      decoration: BoxDecoration(color: const Color(0xFFF5F7FA), borderRadius: BorderRadius.circular(14)),
      child: TextField(
        controller: _otpCtrl,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 12, color: Color(0xFF1E6DE5)),
        decoration: InputDecoration(hintText: '• • • • • •', hintStyle: TextStyle(fontSize: 20, color: Colors.grey[300], letterSpacing: 8), border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(vertical: 16)),
      ),
    );
  }

  Widget _primaryBtn(String label, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity, height: 56,
      child: ElevatedButton(
        onPressed: _loading ? null : onTap,
        style: ElevatedButton.styleFrom(backgroundColor: _blue, foregroundColor: Colors.white, disabledBackgroundColor: _blue.withValues(alpha: 0.5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
        child: _loading
            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
            : Text(label, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
      ),
    );
  }

  Widget _registerLink() {
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      Text("Don't have an account? ", style: TextStyle(color: Colors.grey[500], fontSize: 14)),
      GestureDetector(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
        child: Text('Register Now', style: TextStyle(color: _blue, fontWeight: FontWeight.w800, fontSize: 14)),
      ),
    ]);
  }
}
