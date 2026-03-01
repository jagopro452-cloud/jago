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
        const SnackBar(content: Text('Enter valid 10-digit number'), backgroundColor: Color(0xFF1E6DE5)));
      return;
    }
    setState(() => _loading = true);
    final res = await AuthService.sendOtp(phone, 'customer');
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
      backgroundColor: Colors.white,
      body: Stack(children: [
        Positioned(
          bottom: 0, left: 0, right: 0,
          child: CustomPaint(size: Size(MediaQuery.of(context).size.width, 280), painter: _WavePainter()),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 60),
                const Text('Welcome!',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
                const SizedBox(height: 8),
                Text('Enter your phone number to continue',
                  style: TextStyle(fontSize: 14, color: Colors.grey[500])),
                const SizedBox(height: 32),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F7FA),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
                      decoration: const BoxDecoration(
                        border: Border(right: BorderSide(color: Color(0xFFE0E0E0))),
                      ),
                      child: const Text('+91',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Color(0xFF1A1A2E))),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _phoneCtrl,
                        keyboardType: TextInputType.phone,
                        maxLength: 10,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: const InputDecoration(
                          hintText: 'Phone Number',
                          border: InputBorder.none,
                          counterText: '',
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                          hintStyle: TextStyle(color: Colors.grey),
                        ),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ]),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _continue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E6DE5),
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
                    padding: const EdgeInsets.only(bottom: 120),
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        text: 'By continuing, you agree to our ',
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                        children: const [
                          TextSpan(text: 'Terms & Conditions',
                            style: TextStyle(color: Color(0xFF1E6DE5), fontWeight: FontWeight.w500)),
                          TextSpan(text: ' and '),
                          TextSpan(text: 'Privacy Policy',
                            style: TextStyle(color: Color(0xFF1E6DE5), fontWeight: FontWeight.w500)),
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

class _WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p1 = Paint()..color = const Color(0xFF1E6DE5).withOpacity(0.08);
    final p2 = Paint()..color = const Color(0xFF1E6DE5).withOpacity(0.05);
    final p3 = Paint()..color = const Color(0xFF1E6DE5).withOpacity(0.03);

    final path1 = Path();
    path1.moveTo(0, size.height * 0.4);
    path1.quadraticBezierTo(size.width * 0.3, 0, size.width * 0.6, size.height * 0.3);
    path1.quadraticBezierTo(size.width * 0.8, size.height * 0.5, size.width, size.height * 0.2);
    path1.lineTo(size.width, size.height);
    path1.lineTo(0, size.height);
    canvas.drawPath(path1, p1);

    final path2 = Path();
    path2.moveTo(0, size.height * 0.6);
    path2.quadraticBezierTo(size.width * 0.4, size.height * 0.2, size.width * 0.7, size.height * 0.5);
    path2.quadraticBezierTo(size.width * 0.9, size.height * 0.7, size.width, size.height * 0.4);
    path2.lineTo(size.width, size.height);
    path2.lineTo(0, size.height);
    canvas.drawPath(path2, p2);

    final path3 = Path();
    path3.moveTo(0, size.height * 0.75);
    path3.quadraticBezierTo(size.width * 0.5, size.height * 0.4, size.width, size.height * 0.6);
    path3.lineTo(size.width, size.height);
    path3.lineTo(0, size.height);
    canvas.drawPath(path3, p3);
  }

  @override
  bool shouldRepaint(_) => false;
}
