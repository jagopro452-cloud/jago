import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/auth_service.dart';
import 'login_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _phoneCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _loading = false;
  bool _showNewPass = false;
  bool _showConfirm = false;
  int _step = 0;
  String _serverOtp = '';
  int _seconds = 0;
  Timer? _timer;

  static const Color _blue = Color(0xFF2563EB);
  static const Color _bg = Color(0xFF060D1E);
  static const Color _surface = Color(0xFF0D1B3E);

  @override
  void dispose() {
    _timer?.cancel();
    _phoneCtrl.dispose(); _otpCtrl.dispose();
    _newPassCtrl.dispose(); _confirmCtrl.dispose();
    super.dispose();
  }

  void _showSnack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
      backgroundColor: error ? const Color(0xFFE53935) : _blue,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
    if (phone.length != 10) { _showSnack('Enter a valid 10-digit phone number', error: true); return; }
    setState(() => _loading = true);
    final res = await AuthService.forgotPassword(phone);
    setState(() => _loading = false);
    if (!mounted) return;
    if (res['success'] == true) {
      setState(() { _step = 1; _serverOtp = res['otp']?.toString() ?? ''; });
      _startTimer();
      _showSnack('Reset OTP sent to +91$phone');
    } else {
      _showSnack(res['message'] ?? 'Failed. Try again.', error: true);
    }
  }

  Future<void> _resetPassword() async {
    final otp = _otpCtrl.text.trim();
    final newPass = _newPassCtrl.text;
    final confirm = _confirmCtrl.text;
    if (otp.length < 4) { _showSnack('Enter the OTP sent to your phone', error: true); return; }
    if (newPass.length < 6) { _showSnack('Password must be at least 6 characters', error: true); return; }
    if (newPass != confirm) { _showSnack('Passwords do not match', error: true); return; }
    setState(() => _loading = true);
    final res = await AuthService.resetPassword(_phoneCtrl.text.trim(), otp, newPass);
    setState(() => _loading = false);
    if (!mounted) return;
    if (res['success'] == true) {
      _showSnack('Password reset successfully!');
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
    } else {
      _showSnack(res['message'] ?? 'Reset failed. Try again.', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          backgroundColor: _bg, elevation: 0,
          leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white), onPressed: () => Navigator.pop(context)),
          title: const Text('Forgot Password', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: _step == 0 ? _buildStep0() : _buildStep1(),
        ),
      ),
    );
  }

  Widget _buildStep0() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Icon(Icons.lock_reset_rounded, size: 56, color: Color(0xFF2563EB)),
      const SizedBox(height: 16),
      const Text('Reset Your Password', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
      const SizedBox(height: 8),
      Text('Enter your registered phone number to receive reset OTP.', style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 14)),
      const SizedBox(height: 32),
      Text('Phone Number', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white.withOpacity(0.55))),
      const SizedBox(height: 8),
      Container(
        decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white12)),
        child: Row(children: [
          const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('+91', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white))),
          Container(width: 1, height: 24, color: Colors.white12),
          Expanded(child: TextField(
            controller: _phoneCtrl, keyboardType: TextInputType.phone,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white),
            decoration: InputDecoration(hintText: 'Enter 10-digit number', hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)), border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16)),
          )),
        ]),
      ),
      const SizedBox(height: 32),
      SizedBox(
        width: double.infinity, height: 56,
        child: ElevatedButton(
          onPressed: _loading ? null : _sendOtp,
          style: ElevatedButton.styleFrom(backgroundColor: _blue, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
          child: _loading ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)) : const Text('Send Reset OTP', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
        ),
      ),
    ]);
  }

  Widget _buildStep1() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Icon(Icons.verified_user_rounded, size: 56, color: Color(0xFF2563EB)),
      const SizedBox(height: 16),
      const Text('Enter OTP & New Password', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
      const SizedBox(height: 8),
      Text('OTP sent to +91${_phoneCtrl.text}${_serverOtp.isNotEmpty ? " (Dev: $_serverOtp)" : ""}', style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 13)),
      const SizedBox(height: 28),
      Text('6-Digit OTP', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white.withOpacity(0.55))),
      const SizedBox(height: 8),
      Container(
        decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white12)),
        child: TextField(
          controller: _otpCtrl, keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: 8, color: Colors.white),
          decoration: InputDecoration(hintText: '------', hintStyle: TextStyle(color: Colors.white.withOpacity(0.2), letterSpacing: 8), border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(vertical: 16)),
        ),
      ),
      const SizedBox(height: 8),
      if (_seconds > 0)
        Center(child: Text('Resend in ${_seconds}s', style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 13)))
      else
        Center(child: GestureDetector(onTap: _sendOtp, child: Text('Resend OTP', style: TextStyle(color: _blue, fontWeight: FontWeight.w700, fontSize: 13)))),
      const SizedBox(height: 20),
      Text('New Password', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white.withOpacity(0.55))),
      const SizedBox(height: 8),
      _buildPassField(ctrl: _newPassCtrl, hint: 'Create new password', show: _showNewPass, onToggle: () => setState(() => _showNewPass = !_showNewPass)),
      const SizedBox(height: 16),
      Text('Confirm Password', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white.withOpacity(0.55))),
      const SizedBox(height: 8),
      _buildPassField(ctrl: _confirmCtrl, hint: 'Re-enter new password', show: _showConfirm, onToggle: () => setState(() => _showConfirm = !_showConfirm)),
      const SizedBox(height: 32),
      SizedBox(
        width: double.infinity, height: 56,
        child: ElevatedButton(
          onPressed: _loading ? null : _resetPassword,
          style: ElevatedButton.styleFrom(backgroundColor: _blue, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
          child: _loading ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)) : const Text('Reset Password', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
        ),
      ),
    ]);
  }

  Widget _buildPassField({required TextEditingController ctrl, required String hint, required bool show, required VoidCallback onToggle}) {
    return Container(
      decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white12)),
      child: TextField(
        controller: ctrl, obscureText: !show,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white),
        decoration: InputDecoration(
          hintText: hint, hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)),
          border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          prefixIcon: Icon(Icons.lock_outline_rounded, color: Colors.white.withOpacity(0.3)),
          suffixIcon: IconButton(icon: Icon(show ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.white.withOpacity(0.3)), onPressed: onToggle),
        ),
      ),
    );
  }
}
