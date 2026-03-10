import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/auth_service.dart';
import '../home/home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> with SingleTickerProviderStateMixin {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _loading = false;
  bool _showPassword = false;
  bool _showConfirm = false;
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  static const Color _blue = Color(0xFF1E6DE5);

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  void _showSnack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
      backgroundColor: error ? const Color(0xFFE53935) : _blue,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  Future<void> _register() async {
    final name = _nameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    final password = _passwordCtrl.text;
    final confirm = _confirmCtrl.text;
    if (name.length < 2) { _showSnack('Please enter your full name', error: true); return; }
    if (phone.length != 10) { _showSnack('Enter a valid 10-digit phone number', error: true); return; }
    if (password.length < 6) { _showSnack('Password must be at least 6 characters', error: true); return; }
    if (password != confirm) { _showSnack('Passwords do not match', error: true); return; }
    setState(() => _loading = true);
    final res = await AuthService.registerWithPassword(phone, password, name, email: _emailCtrl.text.trim());
    setState(() => _loading = false);
    if (!mounted) return;
    if (res['success'] == true) {
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const HomeScreen()), (_) => false);
    } else {
      _showSnack(res['message'] ?? 'Registration failed. Try again.', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1A1A2E)), onPressed: () => Navigator.pop(context)),
          title: const Text('Create Account', style: TextStyle(color: Color(0xFF1A1A2E), fontWeight: FontWeight.w700, fontSize: 17)),
        ),
        body: FadeTransition(
          opacity: _fadeAnim,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Join JAGO Today', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.grey[900])),
                const SizedBox(height: 4),
                Text('Fast, safe rides at your fingertips', style: TextStyle(fontSize: 14, color: Colors.grey[500])),
                const SizedBox(height: 28),
                _buildLabel('Full Name *'),
                const SizedBox(height: 8),
                _buildInput(controller: _nameCtrl, hint: 'Enter your full name', icon: Icons.person_rounded, textCap: TextCapitalization.words),
                const SizedBox(height: 16),
                _buildLabel('Phone Number *'),
                const SizedBox(height: 8),
                _buildPhoneInput(),
                const SizedBox(height: 16),
                _buildLabel('Email (Optional)'),
                const SizedBox(height: 8),
                _buildInput(controller: _emailCtrl, hint: 'Enter your email', icon: Icons.email_outlined, keyboard: TextInputType.emailAddress),
                const SizedBox(height: 16),
                _buildLabel('Password *'),
                const SizedBox(height: 8),
                _buildPasswordInput(ctrl: _passwordCtrl, hint: 'Create a password', show: _showPassword, onToggle: () => setState(() => _showPassword = !_showPassword)),
                const SizedBox(height: 16),
                _buildLabel('Confirm Password *'),
                const SizedBox(height: 8),
                _buildPasswordInput(ctrl: _confirmCtrl, hint: 'Re-enter password', show: _showConfirm, onToggle: () => setState(() => _showConfirm = !_showConfirm)),
                const SizedBox(height: 32),
                _buildRegisterBtn(),
                const SizedBox(height: 20),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text('Already have an account? ', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Text('Login', style: TextStyle(color: _blue, fontWeight: FontWeight.w800, fontSize: 14)),
                  ),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Text(text, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.grey[700]));

  Widget _buildInput({required TextEditingController controller, required String hint, required IconData icon, TextCapitalization textCap = TextCapitalization.none, TextInputType keyboard = TextInputType.text}) {
    return Container(
      decoration: BoxDecoration(color: const Color(0xFFF5F7FA), borderRadius: BorderRadius.circular(14)),
      child: TextField(
        controller: controller,
        keyboardType: keyboard,
        textCapitalization: textCap,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          hintText: hint,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          prefixIcon: Icon(icon, color: Colors.grey[400]),
        ),
      ),
    );
  }

  Widget _buildPhoneInput() {
    return Container(
      decoration: BoxDecoration(color: const Color(0xFFF5F7FA), borderRadius: BorderRadius.circular(14)),
      child: Row(children: [
        const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('+91', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E)))),
        Container(width: 1, height: 24, color: Colors.grey[300]),
        Expanded(child: TextField(
          controller: _phoneCtrl,
          keyboardType: TextInputType.phone,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          decoration: const InputDecoration(hintText: 'Enter 10-digit number', border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16)),
        )),
      ]),
    );
  }

  Widget _buildPasswordInput({required TextEditingController ctrl, required String hint, required bool show, required VoidCallback onToggle}) {
    return Container(
      decoration: BoxDecoration(color: const Color(0xFFF5F7FA), borderRadius: BorderRadius.circular(14)),
      child: TextField(
        controller: ctrl,
        obscureText: !show,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          hintText: hint,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          prefixIcon: Icon(Icons.lock_outline_rounded, color: Colors.grey[400]),
          suffixIcon: IconButton(
            icon: Icon(show ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.grey[400]),
            onPressed: onToggle,
          ),
        ),
      ),
    );
  }

  Widget _buildRegisterBtn() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _loading ? null : _register,
        style: ElevatedButton.styleFrom(
          backgroundColor: _blue, foregroundColor: Colors.white,
          disabledBackgroundColor: _blue.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        child: _loading
            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
            : const Text('Create Account', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
      ),
    );
  }
}
