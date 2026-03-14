import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/api_config.dart';
import '../../services/auth_service.dart';
import 'pending_verification_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  bool _loading = false;

  // Step 1: Basic Info
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  DateTime? _dob;
  final _cityCtrl = TextEditingController();

  // Step 2: Password
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _showPassword = false;

  // Step 3: Driving License
  final _licenseNumCtrl = TextEditingController();
  DateTime? _licenseExpiry;
  File? _dlFront;
  File? _dlBack;

  // Step 4: Vehicle Details
  final _vehicleBrandCtrl = TextEditingController();
  final _vehicleModelCtrl = TextEditingController();
  final _vehicleColorCtrl = TextEditingController();
  final _vehicleYearCtrl = TextEditingController();
  final _vehicleNumCtrl = TextEditingController();
  String _vehicleType = 'bike';

  // Step 5: Vehicle Documents
  File? _rcPhoto;
  File? _insurancePhoto;
  File? _vehicleFrontPhoto;

  // Step 6: Selfie
  File? _selfiePhoto;

  final _picker = ImagePicker();
  static const Color _primary = Color(0xFF2F80ED);
  static const Color _bg = Color(0xFF0F172A);
  static const Color _surface = Color(0xFF1E293B);

  @override
  void initState() {
    super.initState();
    _prefillPhone();
  }

  Future<void> _prefillPhone() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _phoneCtrl.text = prefs.getString('user_phone') ?? '';
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameCtrl.dispose(); _phoneCtrl.dispose(); _cityCtrl.dispose();
    _passwordCtrl.dispose(); _confirmCtrl.dispose();
    _licenseNumCtrl.dispose(); _vehicleBrandCtrl.dispose();
    _vehicleModelCtrl.dispose(); _vehicleColorCtrl.dispose();
    _vehicleYearCtrl.dispose(); _vehicleNumCtrl.dispose();
    super.dispose();
  }

  void _showSnack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? Colors.red : _primary,
      behavior: SnackBarBehavior.floating,
    ));
  }

  Future<void> _pickImage(String type) async {
    final picked = await _picker.pickImage(
      source: type == 'selfie' ? ImageSource.camera : ImageSource.gallery,
      preferredCameraDevice: type == 'selfie' ? CameraDevice.front : CameraDevice.rear,
      imageQuality: 70,
    );
    if (picked != null) {
      setState(() {
        if (type == 'dl_front') _dlFront = File(picked.path);
        if (type == 'dl_back') _dlBack = File(picked.path);
        if (type == 'rc') _rcPhoto = File(picked.path);
        if (type == 'insurance') _insurancePhoto = File(picked.path);
        if (type == 'vehicle') _vehicleFrontPhoto = File(picked.path);
        if (type == 'selfie') _selfiePhoto = File(picked.path);
      });
    }
  }

  Future<String?> _fileToBase64(File? file) async {
    if (file == null) return null;
    return base64Encode(await file.readAsBytes());
  }

  Future<void> _submit() async {
    setState(() => _loading = true);
    try {
      // Ensure driver has an account and token. If not logged in, register first.
      String? token = await AuthService.getToken();
      if (token == null || token.isEmpty) {
        final phone = _phoneCtrl.text.trim();
        final password = _passwordCtrl.text;
        final name = _nameCtrl.text.trim();
        if (phone.length != 10) throw Exception('Enter a valid 10-digit phone number');
        if (password.length < 6) throw Exception('Password must be at least 6 characters');
        if (name.length < 2) throw Exception('Please enter your full name');
        final regRes = await AuthService.registerWithPassword(phone, password, name);
        if (regRes['success'] != true) {
          throw Exception(regRes['message'] ?? 'Registration failed. Try again.');
        }
        token = await AuthService.getToken();
      }

      final authHeaders = await AuthService.getHeaders();
      final headers = {...authHeaders, 'Content-Type': 'application/json'};

      // 1. Update Profile Fields
      final profileRes = await http.patch(
        Uri.parse('${ApiConfig.baseUrl}/api/app/driver/update-registration'),
        headers: headers,
        body: jsonEncode({
          'name': _nameCtrl.text.trim(),
          'dob': _dob?.toIso8601String(),
          'city': _cityCtrl.text.trim(),
          'password': _passwordCtrl.text,
          'licenseNumber': _licenseNumCtrl.text.trim(),
          'licenseExpiry': _licenseExpiry?.toIso8601String(),
          'vehicleBrand': _vehicleBrandCtrl.text.trim(),
          'vehicleModel': _vehicleModelCtrl.text.trim(),
          'vehicleColor': _vehicleColorCtrl.text.trim(),
          'vehicleYear': int.tryParse(_vehicleYearCtrl.text.trim()),
          'vehicleNumber': _vehicleNumCtrl.text.trim().toUpperCase(),
          'vehicleType': _vehicleType,
        }),
      );

      if (profileRes.statusCode != 200) {
        String msg = 'Failed to update profile';
        try {
          if ((profileRes.headers['content-type'] ?? '').contains('application/json')) {
            final decoded = jsonDecode(profileRes.body);
            msg = decoded['message'] ?? msg;
          }
        } catch (_) {}
        throw Exception(msg);
      }

      // 2. Upload Documents
      final docs = {
        'dl_front': _dlFront,
        'dl_back': _dlBack,
        'rc': _rcPhoto,
        'insurance': _insurancePhoto,
        'vehicle_photo': _vehicleFrontPhoto,
        'selfie': _selfiePhoto,
      };

      for (var entry in docs.entries) {
        if (entry.value != null) {
          final b64 = await _fileToBase64(entry.value);
          await http.post(
            Uri.parse('${ApiConfig.baseUrl}/api/app/driver/upload-document-base64'),
            headers: headers,
            body: jsonEncode({'docType': entry.key, 'imageData': b64}),
          );
        }
      }

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const PendingVerificationScreen()), (_) => false);
    } catch (e) {
      _showSnack(e.toString(), error: true);
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg, elevation: 0,
        title: Text('Step ${_currentStep + 1} of 6', style: const TextStyle(fontSize: 16)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(value: (_currentStep + 1) / 6, backgroundColor: Colors.white12, valueColor: const AlwaysStoppedAnimation(_primary)),
        ),
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _buildStep1(), _buildStep2(), _buildStep3(),
          _buildStep4(), _buildStep5(), _buildStep6(),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                  setState(() => _currentStep--);
                },
                style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white24), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: const Text('Back', style: TextStyle(color: Colors.white)),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _loading ? null : () {
                if (_currentStep == 0) {
                  if (_nameCtrl.text.trim().length < 2) { _showSnack('Enter your full name', error: true); return; }
                  if (_phoneCtrl.text.trim().length != 10) { _showSnack('Enter a valid 10-digit phone number', error: true); return; }
                }
                if (_currentStep == 1) {
                  if (_passwordCtrl.text.length < 6) { _showSnack('Password must be at least 6 characters', error: true); return; }
                  if (_passwordCtrl.text != _confirmCtrl.text) { _showSnack('Passwords do not match', error: true); return; }
                }
                if (_currentStep == 2) {
                  if (_licenseNumCtrl.text.trim().isEmpty) { _showSnack('Enter your license number', error: true); return; }
                  if (_licenseExpiry == null) { _showSnack('Select license expiry date', error: true); return; }
                  if (_dlFront == null) { _showSnack('Upload DL Front photo', error: true); return; }
                  if (_dlBack == null) { _showSnack('Upload DL Back photo', error: true); return; }
                }
                if (_currentStep == 3) {
                  if (_vehicleBrandCtrl.text.trim().isEmpty) { _showSnack('Enter vehicle brand', error: true); return; }
                  if (_vehicleModelCtrl.text.trim().isEmpty) { _showSnack('Enter vehicle model', error: true); return; }
                  if (_vehicleColorCtrl.text.trim().isEmpty) { _showSnack('Enter vehicle color', error: true); return; }
                  if (_vehicleYearCtrl.text.trim().isEmpty) { _showSnack('Enter vehicle year', error: true); return; }
                  if (_vehicleNumCtrl.text.trim().isEmpty) { _showSnack('Enter vehicle number', error: true); return; }
                }
                if (_currentStep == 4) {
                  if (_rcPhoto == null) { _showSnack('Upload RC photo', error: true); return; }
                  if (_insurancePhoto == null) { _showSnack('Upload Insurance photo', error: true); return; }
                  if (_vehicleFrontPhoto == null) { _showSnack('Upload Vehicle Front photo', error: true); return; }
                }
                if (_currentStep == 5) {
                  if (_selfiePhoto == null) { _showSnack('Take a selfie photo', error: true); return; }
                  _submit();
                  return;
                }
                _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                setState(() => _currentStep++);
              },
              style: ElevatedButton.styleFrom(backgroundColor: _primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: _loading ? const CircularProgressIndicator(color: Colors.white) : Text(_currentStep == 5 ? 'Submit Application' : 'Next'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep1() {
    return _stepContainer('Basic Information', 'Tell us about yourself', [
      _input('Full Name', _nameCtrl, Icons.person),
      const SizedBox(height: 16),
      _phoneInput(),
      const SizedBox(height: 16),
      _datePicker('Date of Birth', _dob, (d) => setState(() => _dob = d)),
      const SizedBox(height: 16),
      _input('City', _cityCtrl, Icons.location_city),
    ]);
  }

  Widget _buildStep2() {
    return _stepContainer('Security', 'Set a strong password', [
      _input('Password', _passwordCtrl, Icons.lock, obscure: !_showPassword, suffix: IconButton(icon: Icon(_showPassword ? Icons.visibility : Icons.visibility_off), onPressed: () => setState(() => _showPassword = !_showPassword))),
      const SizedBox(height: 16),
      _input('Confirm Password', _confirmCtrl, Icons.lock, obscure: true),
    ]);
  }

  Widget _buildStep3() {
    return _stepContainer('Driving License', 'Verify your driving credentials', [
      _input('License Number', _licenseNumCtrl, Icons.badge),
      const SizedBox(height: 16),
      _datePicker('Expiry Date', _licenseExpiry, (d) => setState(() => _licenseExpiry = d)),
      const SizedBox(height: 24),
      _imageTile('DL Front Photo', _dlFront, () => _pickImage('dl_front')),
      const SizedBox(height: 12),
      _imageTile('DL Back Photo', _dlBack, () => _pickImage('dl_back')),
    ]);
  }

  Widget _buildStep4() {
    return _stepContainer('Vehicle Details', 'Tell us about your ride', [
      _input('Brand', _vehicleBrandCtrl, Icons.directions_car),
      const SizedBox(height: 16),
      _input('Model', _vehicleModelCtrl, Icons.model_training),
      const SizedBox(height: 16),
      Row(children: [
        Expanded(child: _input('Color', _vehicleColorCtrl, Icons.color_lens)),
        const SizedBox(width: 16),
        Expanded(child: _input('Year', _vehicleYearCtrl, Icons.calendar_today, keyboard: TextInputType.number)),
      ]),
      const SizedBox(height: 16),
      _input('Vehicle Number', _vehicleNumCtrl, Icons.numbers),
      const SizedBox(height: 16),
      _dropdown('Vehicle Type', _vehicleType, ['bike', 'auto', 'car', 'mini', 'sedan', 'suv', 'xl'], (v) => setState(() => _vehicleType = v!)),
    ]);
  }

  Widget _buildStep5() {
    return _stepContainer('Vehicle Documents', 'Upload RC and Insurance', [
      _imageTile('RC Photo', _rcPhoto, () => _pickImage('rc')),
      const SizedBox(height: 12),
      _imageTile('Insurance Photo', _insurancePhoto, () => _pickImage('insurance')),
      const SizedBox(height: 12),
      _imageTile('Vehicle Front Photo', _vehicleFrontPhoto, () => _pickImage('vehicle')),
    ]);
  }

  Widget _buildStep6() {
    return _stepContainer('Final Step', 'Take a clear selfie', [
      const SizedBox(height: 40),
      Center(
        child: GestureDetector(
          onTap: () => _pickImage('selfie'),
          child: Container(
            width: 200, height: 200,
            decoration: BoxDecoration(color: _surface, shape: BoxShape.circle, border: Border.all(color: _primary, width: 2), image: _selfiePhoto != null ? DecorationImage(image: FileImage(_selfiePhoto!), fit: BoxFit.cover) : null),
            child: _selfiePhoto == null ? const Icon(Icons.camera_alt, size: 50, color: Colors.white24) : null,
          ),
        ),
      ),
      const SizedBox(height: 24),
      const Text('Make sure your face is clearly visible without glasses or hats.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white54)),
    ]);
  }

  Widget _stepContainer(String title, String subtitle, List<Widget> children) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 4),
          Text(subtitle, style: TextStyle(color: Colors.white.withValues(alpha: 0.5))),
          const SizedBox(height: 32),
          ...children,
        ],
      ),
    );
  }

  Widget _phoneInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _phoneCtrl,
          readOnly: false,
          enabled: true,
          keyboardType: TextInputType.phone,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Phone Number',
            labelStyle: const TextStyle(color: Colors.white54),
            prefixIcon: const Icon(Icons.phone, color: _primary),
            filled: true, fillColor: _surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        if (_phoneCtrl.text.isNotEmpty && _phoneCtrl.text.length < 10)
          const Padding(
            padding: EdgeInsets.only(top: 4, left: 12),
            child: Text('Enter a valid 10-digit phone number', style: TextStyle(color: Colors.redAccent, fontSize: 12)),
          ),
      ],
    );
  }

  Widget _input(String label, TextEditingController ctrl, IconData icon, {bool readOnly = false, bool obscure = false, Widget? suffix, TextInputType keyboard = TextInputType.text}) {
    return TextField(
      controller: ctrl, readOnly: readOnly, obscureText: obscure, keyboardType: keyboard,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label, labelStyle: const TextStyle(color: Colors.white54),
        prefixIcon: Icon(icon, color: _primary),
        suffixIcon: suffix,
        filled: true, fillColor: _surface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _datePicker(String label, DateTime? value, Function(DateTime) onPick) {
    return ListTile(
      tileColor: _surface, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      leading: const Icon(Icons.calendar_month, color: _primary),
      title: Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
      subtitle: Text(value == null ? 'Select Date' : DateFormat('dd MMM yyyy').format(value), style: const TextStyle(color: Colors.white, fontSize: 16)),
      onTap: () async {
        final d = await showDatePicker(context: context, initialDate: DateTime.now().subtract(const Duration(days: 6570)), firstDate: DateTime(1950), lastDate: DateTime.now());
        if (d != null) onPick(d);
      },
    );
  }

  Widget _imageTile(String label, File? file, VoidCallback onTap) {
    return ListTile(
      tileColor: _surface, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      leading: const Icon(Icons.image, color: _primary),
      title: Text(label, style: const TextStyle(color: Colors.white, fontSize: 14)),
      trailing: file != null ? const Icon(Icons.check_circle, color: Colors.green) : const Text('Upload', style: TextStyle(color: _primary)),
      onTap: onTap,
    );
  }

  Widget _dropdown(String label, String value, List<String> options, Function(String?) onChange) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(12)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value, isExpanded: true, dropdownColor: _surface,
          items: options.map((s) => DropdownMenuItem(value: s, child: Text(s.toUpperCase(), style: const TextStyle(color: Colors.white)))).toList(),
          onChanged: onChange,
        ),
      ),
    );
  }
}

