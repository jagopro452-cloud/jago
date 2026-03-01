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

  Future<void> _continue() async {
    final phone = _phoneCtrl.text.trim();
    if (phone.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter valid 10-digit number'), backgroundColor: Color(0xFF2563EB)));
      return;
    }
    setState(() => _loading = true);
    final res = await AuthService.sendOtp(phone, 'driver');
    setState(() => _loading = false);
    if (res['success'] == true) {
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => OtpScreen(phone: phone, otp: res['otp']?.toString() ?? '')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message'] ?? 'Error'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060D1E),
      body: Stack(children: [
        Positioned(
          top: -80, right: -80,
          child: Container(width: 250, height: 250,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF2563EB).withOpacity(0.08))),
        ),
        Positioned(
          bottom: -40, left: -60,
          child: Container(width: 200, height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF2563EB).withOpacity(0.06))),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 48),
                const Text('JAGO',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900,
                    color: Color(0xFF2563EB), letterSpacing: 3)),
                const Text('PILOT',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                    color: Colors.white, letterSpacing: 6)),
                const SizedBox(height: 52),
                const Text('Welcome!',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 8),
                Text('Enter your phone number to start driving',
                  style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.45))),
                const SizedBox(height: 32),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
                      decoration: BoxDecoration(
                        border: Border(right: BorderSide(color: Colors.white.withOpacity(0.1)))),
                      child: Text('+91',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15,
                          color: Colors.white.withOpacity(0.85))),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _phoneCtrl,
                        keyboardType: TextInputType.phone,
                        maxLength: 10,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                        decoration: InputDecoration(
                          hintText: 'Phone Number',
                          hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                          border: InputBorder.none,
                          counterText: '',
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                        ),
                      ),
                    ),
                  ]),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity, height: 52,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _continue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: _loading
                      ? const SizedBox(width: 22, height: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Continue',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
                const Spacer(),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 40),
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        text: 'By continuing, you agree to our ',
                        style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 12),
                        children: const [
                          TextSpan(text: 'Terms & Conditions',
                            style: TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.w500)),
                          TextSpan(text: ' and '),
                          TextSpan(text: 'Privacy Policy',
                            style: TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ]),
    );
  }
}
