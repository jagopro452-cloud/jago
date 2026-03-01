import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/auth_service.dart';
import 'otp_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _sendOtp() async {
    final phone = _phoneCtrl.text.trim();
    if (phone.length < 10) { setState(() => _error = 'Enter valid 10-digit number'); return; }
    setState(() { _loading = true; _error = null; });
    try {
      final res = await AuthService.sendOtp(phone);
      if (!mounted) return;
      if (res['success'] == true) {
        Navigator.push(context, MaterialPageRoute(builder: (_) => OtpScreen(phone: phone, devOtp: res['otp'])));
      } else {
        setState(() => _error = res['message'] ?? 'Failed');
      }
    } catch (_) {
      setState(() => _error = 'Network error. Check your connection.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60),
              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF1D4ED8), Color(0xFF3B82F6)]),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Center(child: Text('J', style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.white))),
              ),
              const SizedBox(height: 32),
              const Text('Welcome to JAGO', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
              const SizedBox(height: 6),
              const Text('India\'s Smart Ride Sharing Platform', style: TextStyle(fontSize: 14, color: Color(0xFF64748B))),
              const SizedBox(height: 48),
              const Text('Mobile Number', style: TextStyle(fontSize: 13, color: Color(0xFF475569), fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                      decoration: const BoxDecoration(border: Border(right: BorderSide(color: Color(0xFFE2E8F0)))),
                      child: const Text('+91', style: TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _phoneCtrl,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
                        style: const TextStyle(fontSize: 18, color: Color(0xFF0F172A), letterSpacing: 2),
                        decoration: const InputDecoration(
                          hintText: '9876543210',
                          hintStyle: TextStyle(color: Color(0xFFCBD5E1), fontSize: 16, letterSpacing: 1),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(_error!, style: const TextStyle(color: Color(0xFFEF4444), fontSize: 13)),
              ],
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity, height: 56,
                child: ElevatedButton(
                  onPressed: _loading ? null : _sendOtp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: _loading
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                      : const Text('Send OTP', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 48),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(12)),
                child: Column(
                  children: [
                    _featureRow(Icons.security, 'Verified drivers with background checks'),
                    const SizedBox(height: 10),
                    _featureRow(Icons.my_location, 'Real-time GPS tracking'),
                    const SizedBox(height: 10),
                    _featureRow(Icons.payment, 'Cash, UPI & Wallet payments'),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              const Center(child: Text('By continuing, you agree to our Terms & Privacy Policy', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)))),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _featureRow(IconData icon, String text) {
    return Row(children: [
      Icon(icon, color: const Color(0xFF2563EB), size: 18),
      const SizedBox(width: 10),
      Text(text, style: const TextStyle(fontSize: 13, color: Color(0xFF475569))),
    ]);
  }
}
