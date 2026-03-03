import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
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
  final _vehicleNumCtrl = TextEditingController();
  final _vehicleModelCtrl = TextEditingController();
  String _gender = 'male';
  String? _selectedVehicleCatId;
  String? _selectedVehicleCatName;
  List<Map<String, dynamic>> _vehicleCategories = [];
  bool _loading = false;
  bool _loadingCats = true;
  bool _showPassword = false;
  bool _showConfirm = false;
  int _step = 0;
  late AnimationController _animCtrl;

  static const Color _blue = Color(0xFF2563EB);
  static const Color _bg = Color(0xFF060D1E);
  static const Color _surface = Color(0xFF0D1B3E);

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _animCtrl.forward();
    _loadVehicleCategories();
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _phoneCtrl.dispose(); _emailCtrl.dispose();
    _passwordCtrl.dispose(); _confirmCtrl.dispose();
    _vehicleNumCtrl.dispose(); _vehicleModelCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadVehicleCategories() async {
    try {
      final res = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/vehicle-categories'));
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        setState(() {
          _vehicleCategories = data.where((v) => v['type'] == 'ride')
              .map((v) => {'id': v['id'].toString(), 'name': v['name'].toString(), 'icon': v['icon']?.toString() ?? '🚗'})
              .toList();
          _loadingCats = false;
          if (_vehicleCategories.isNotEmpty) {
            _selectedVehicleCatId = _vehicleCategories[0]['id'];
            _selectedVehicleCatName = _vehicleCategories[0]['name'];
          }
        });
      } else { setState(() => _loadingCats = false); }
    } catch (_) { setState(() => _loadingCats = false); }
  }

  void _showSnack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
      backgroundColor: error ? const Color(0xFFE53935) : _blue,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  Future<void> _goToStep1() async {
    if (_nameCtrl.text.trim().length < 2) { _showSnack('Enter your full name', error: true); return; }
    if (_phoneCtrl.text.trim().length != 10) { _showSnack('Enter valid 10-digit phone number', error: true); return; }
    if (_passwordCtrl.text.length < 6) { _showSnack('Password must be at least 6 characters', error: true); return; }
    if (_passwordCtrl.text != _confirmCtrl.text) { _showSnack('Passwords do not match', error: true); return; }
    setState(() { _step = 1; });
    _animCtrl.reset();
    _animCtrl.forward();
  }

  Future<void> _register() async {
    if (_vehicleNumCtrl.text.trim().isEmpty) { _showSnack('Enter your vehicle number', error: true); return; }
    setState(() => _loading = true);
    final res = await AuthService.registerWithPassword(
      _phoneCtrl.text.trim(), _passwordCtrl.text, _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim().isNotEmpty ? _emailCtrl.text.trim() : null,
    );
    if (res['success'] == true && res['token'] != null) {
      try {
        final headers = await AuthService.getHeaders();
        await http.patch(Uri.parse(ApiConfig.updateProfile), headers: headers, body: jsonEncode({
          'gender': _gender,
          'vehicleNumber': _vehicleNumCtrl.text.trim().toUpperCase(),
          'vehicleModel': _vehicleModelCtrl.text.trim(),
          if (_selectedVehicleCatId != null) 'vehicleCategoryId': _selectedVehicleCatId,
        }));
      } catch (_) {}
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const HomeScreen()), (_) => false);
    } else {
      setState(() => _loading = false);
      if (!mounted) return;
      _showSnack(res['message'] ?? 'Registration failed. Try again.', error: true);
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
          leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white), onPressed: () {
            if (_step == 1) { setState(() => _step = 0); } else { Navigator.pop(context); }
          }),
          title: Text(_step == 0 ? 'Create Pilot Account' : 'Vehicle Details', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 17)),
        ),
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _step == 0 ? _buildStep0() : _buildStep1(),
        ),
      ),
    );
  }

  Widget _buildStep0() {
    return SingleChildScrollView(
      key: const ValueKey(0),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Join as JAGO Pilot', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white)),
        const SizedBox(height: 4),
        Text('Earn money on your own schedule', style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.45))),
        const SizedBox(height: 28),
        _label('Full Name *'),
        const SizedBox(height: 8),
        _buildInput(ctrl: _nameCtrl, hint: 'Enter your full name', icon: Icons.person_rounded, textCap: TextCapitalization.words),
        const SizedBox(height: 16),
        _label('Phone Number *'),
        const SizedBox(height: 8),
        _buildPhoneInput(),
        const SizedBox(height: 16),
        _label('Email (Optional)'),
        const SizedBox(height: 8),
        _buildInput(ctrl: _emailCtrl, hint: 'Enter your email', icon: Icons.email_outlined, keyboard: TextInputType.emailAddress),
        const SizedBox(height: 16),
        _label('Password *'),
        const SizedBox(height: 8),
        _buildPassInput(ctrl: _passwordCtrl, hint: 'Create a password', show: _showPassword, onToggle: () => setState(() => _showPassword = !_showPassword)),
        const SizedBox(height: 16),
        _label('Confirm Password *'),
        const SizedBox(height: 8),
        _buildPassInput(ctrl: _confirmCtrl, hint: 'Re-enter password', show: _showConfirm, onToggle: () => setState(() => _showConfirm = !_showConfirm)),
        const SizedBox(height: 32),
        _buildBtn('Next → Vehicle Details', _goToStep1),
        const SizedBox(height: 20),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('Already a Pilot? ', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 14)),
          GestureDetector(onTap: () => Navigator.pop(context), child: Text('Login', style: TextStyle(color: _blue, fontWeight: FontWeight.w800, fontSize: 14))),
        ]),
      ]),
    );
  }

  Widget _buildStep1() {
    return SingleChildScrollView(
      key: const ValueKey(1),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Vehicle Information', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
        const SizedBox(height: 4),
        Text('Tell us about your vehicle', style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.45))),
        const SizedBox(height: 28),
        _label('Vehicle Category'),
        const SizedBox(height: 12),
        if (_loadingCats)
          const Center(child: CircularProgressIndicator(color: Color(0xFF2563EB)))
        else
          Wrap(
            spacing: 10, runSpacing: 10,
            children: _vehicleCategories.map((cat) {
              final selected = _selectedVehicleCatId == cat['id'];
              return GestureDetector(
                onTap: () => setState(() { _selectedVehicleCatId = cat['id']; _selectedVehicleCatName = cat['name']; }),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: selected ? _blue : _surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: selected ? _blue : Colors.white12),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text(cat['icon'] ?? '🚗', style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Text(cat['name'], style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                  ]),
                ),
              );
            }).toList(),
          ),
        const SizedBox(height: 20),
        _label('Vehicle Number *'),
        const SizedBox(height: 8),
        _buildInput(ctrl: _vehicleNumCtrl, hint: 'e.g. TS09AB1234', icon: Icons.directions_car_rounded, textCap: TextCapitalization.characters),
        const SizedBox(height: 16),
        _label('Vehicle Model'),
        const SizedBox(height: 8),
        _buildInput(ctrl: _vehicleModelCtrl, hint: 'e.g. Honda Activa 6G', icon: Icons.two_wheeler_rounded),
        const SizedBox(height: 32),
        _buildBtn(_loading ? 'Registering...' : 'Complete Registration', _loading ? () {} : _register),
      ]),
    );
  }

  Widget _label(String text) => Text(text, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white.withOpacity(0.55)));

  Widget _buildInput({required TextEditingController ctrl, required String hint, required IconData icon, TextCapitalization textCap = TextCapitalization.none, TextInputType keyboard = TextInputType.text}) {
    return Container(
      decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white12)),
      child: TextField(
        controller: ctrl, keyboardType: keyboard, textCapitalization: textCap,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white),
        decoration: InputDecoration(
          hintText: hint, hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)),
          border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.3)),
        ),
      ),
    );
  }

  Widget _buildPhoneInput() {
    return Container(
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
    );
  }

  Widget _buildPassInput({required TextEditingController ctrl, required String hint, required bool show, required VoidCallback onToggle}) {
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

  Widget _buildBtn(String label, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity, height: 56,
      child: ElevatedButton(
        onPressed: _loading ? null : onTap,
        style: ElevatedButton.styleFrom(backgroundColor: _blue, foregroundColor: Colors.white, disabledBackgroundColor: _blue.withOpacity(0.4), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
        child: _loading ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)) : Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
      ),
    );
  }
}
