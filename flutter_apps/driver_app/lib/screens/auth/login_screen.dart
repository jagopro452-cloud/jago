import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/auth_service.dart';
import '../../services/localization_service.dart';
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

  bool _loading = false;
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  static const Color _blue = Color(0xFF2563EB);
  static const Color _bg = Color(0xFF060D1E);
  static const Color _surface = Color(0xFF0D1B3E);
  static const Color _surface2 = Color(0xFF122145);

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
      content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
      backgroundColor: error ? const Color(0xFFE53935) : _blue,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

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
    final res = await AuthService.sendOtp(phone, 'driver');
    setState(() => _loading = false);
    if (!mounted) return;
    if (res['success'] == true) {
      setState(() { _otpSent = true; _serverOtp = res['otp']?.toString() ?? ''; });
      _startTimer();
      _showSnack('OTP sent to +91$phone');
    } else {
      _showSnack(res['message'] ?? 'Failed to send OTP. Try again.', error: true);
    }
  }

  Future<void> _verifyOtp() async {
    final otp = _otpCtrl.text.trim();
    if (otp.length != 6) { _showSnack('Enter the 6-digit OTP', error: true); return; }
    setState(() => _loading = true);
    final res = await AuthService.verifyOtp(_phoneOtpCtrl.text.trim(), otp, 'driver');
    setState(() => _loading = false);
    if (!mounted) return;
    if (res['success'] == true) {
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const HomeScreen()), (_) => false);
    } else {
      _showSnack(res['message'] ?? 'Invalid OTP. Try again.', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _bg,
        body: FadeTransition(
          opacity: _fadeAnim,
          child: SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 32),
                _buildHeader(),
                const SizedBox(height: 28),
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
      Container(
        width: 64, height: 64,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF1E3A8A)], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Center(child: Text('P', style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900))),
      ),
      const SizedBox(height: 12),
      const Text('JAGO PILOT', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 3)),
      const SizedBox(height: 4),
      Text('Drive smart. Earn more.', style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.35), fontWeight: FontWeight.w500)),
    ]);
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white10)),
      padding: const EdgeInsets.all(4),
      child: TabBar(
        controller: _tabCtrl,
        indicator: BoxDecoration(color: _surface2, borderRadius: BorderRadius.circular(11), border: Border.all(color: Colors.white12)),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white38,
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

  Widget _buildPasswordTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Welcome Back, Pilot!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
        const SizedBox(height: 4),
        Text('Login with your phone & password', style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.4))),
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
        _primaryBtn('Login as Pilot', _loginWithPassword),
        const SizedBox(height: 24),
        _registerLink(),
      ]),
    );
  }

  Widget _buildOtpTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(_otpSent ? 'Enter OTP' : 'Login with OTP', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
        const SizedBox(height: 4),
        Text(_otpSent ? 'OTP sent to +91${_phoneOtpCtrl.text}${_serverOtp.isNotEmpty ? "  (Dev: $_serverOtp)" : ""}' : 'Quick login — no password needed!', style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.4))),
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
            Center(child: Text('Resend OTP in ${_seconds}s', style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 13)))
          else
            Center(child: GestureDetector(onTap: _sendOtp, child: Text('Resend OTP', style: TextStyle(color: _blue, fontWeight: FontWeight.w600, fontSize: 13)))),
          const SizedBox(height: 28),
          _primaryBtn('Verify & Login', _verifyOtp),
          const SizedBox(height: 12),
          Center(child: GestureDetector(
            onTap: () => setState(() { _otpSent = false; _otpCtrl.clear(); }),
            child: Text('← Change Number', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13, fontWeight: FontWeight.w600)),
          )),
        ],
        const SizedBox(height: 24),
        _registerLink(),
      ]),
    );
  }

  Widget _label(String text) => Text(text, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white.withOpacity(0.5)));

  Widget _phoneField(TextEditingController ctrl, {bool enabled = true}) {
    return Container(
      decoration: BoxDecoration(
        color: enabled ? _surface : _surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(children: [
        const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('+91', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white))),
        Container(width: 1, height: 24, color: Colors.white10),
        Expanded(child: TextField(
          controller: ctrl,
          enabled: enabled,
          keyboardType: TextInputType.phone,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white),
          decoration: InputDecoration(hintText: 'Enter 10-digit number', hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)), border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16)),
        )),
      ]),
    );
  }

  Widget _passwordField() {
    return Container(
      decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white10)),
      child: TextField(
        controller: _passwordCtrl,
        obscureText: !_showPassword,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Enter your password',
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          prefixIcon: Icon(Icons.lock_outline_rounded, color: Colors.white.withOpacity(0.3)),
          suffixIcon: IconButton(icon: Icon(_showPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.white.withOpacity(0.3)), onPressed: () => setState(() => _showPassword = !_showPassword)),
        ),
      ),
    );
  }

  Widget _otpField() {
    return Container(
      decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white10)),
      child: TextField(
        controller: _otpCtrl,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 12, color: _blue),
        decoration: InputDecoration(hintText: '• • • • • •', hintStyle: TextStyle(fontSize: 20, color: Colors.white.withOpacity(0.15), letterSpacing: 8), border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(vertical: 16)),
      ),
    );
  }

  Widget _primaryBtn(String label, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity, height: 56,
      child: ElevatedButton(
        onPressed: _loading ? null : onTap,
        style: ElevatedButton.styleFrom(backgroundColor: _blue, foregroundColor: Colors.white, disabledBackgroundColor: _blue.withOpacity(0.4), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
        child: _loading
            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
            : Text(label, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
      ),
    );
  }

  Widget _registerLink() {
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      Text("New here? ", style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 14)),
      GestureDetector(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
        child: Text('Register Now', style: TextStyle(color: _blue, fontWeight: FontWeight.w800, fontSize: 14)),
      ),
    ]);
  }
}
