import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import '../../services/auth_service.dart';

class RidePreferencesScreen extends StatefulWidget {
  const RidePreferencesScreen({super.key});
  @override
  State<RidePreferencesScreen> createState() => _RidePreferencesScreenState();
}

class _RidePreferencesScreenState extends State<RidePreferencesScreen> {
  bool _loading = true;
  bool _saving = false;
  bool _quietRide = false;
  bool _acPreferred = true;
  bool _musicOff = false;
  bool _wheelchairAccessible = false;
  bool _extraLuggage = false;
  String _preferredGender = 'any';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final headers = await AuthService.getHeaders();
      final res = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/app/customer/preferences'), headers: headers);
      if (res.statusCode == 200) {
        final d = jsonDecode(res.body);
        setState(() {
          _quietRide = d['quietRide'] ?? false;
          _acPreferred = d['acPreferred'] ?? true;
          _musicOff = d['musicOff'] ?? false;
          _wheelchairAccessible = d['wheelchairAccessible'] ?? false;
          _extraLuggage = d['extraLuggage'] ?? false;
          _preferredGender = d['preferredGender'] ?? 'any';
        });
      }
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final headers = await AuthService.getHeaders();
      headers['Content-Type'] = 'application/json';
      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/app/customer/preferences'),
        headers: headers,
        body: jsonEncode({
          'quietRide': _quietRide,
          'acPreferred': _acPreferred,
          'musicOff': _musicOff,
          'wheelchairAccessible': _wheelchairAccessible,
          'extraLuggage': _extraLuggage,
          'preferredGender': _preferredGender,
        }),
      );
      if (!mounted) return;
      final body = jsonDecode(res.body);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(body['message'] ?? 'Saved!'),
        backgroundColor: res.statusCode == 200 ? Colors.green : Colors.red,
      ));
    } catch (_) {}
    setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        title: const Text('Ride Preferences', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Save', style: TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF2563EB)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _banner(),
                  const SizedBox(height: 16),
                  const Text('Comfort Preferences', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  _prefCard('Quiet Ride', 'No unnecessary conversation', Icons.volume_off, _quietRide, (v) => setState(() => _quietRide = v)),
                  _prefCard('AC Preferred', 'AC on during ride', Icons.ac_unit, _acPreferred, (v) => setState(() => _acPreferred = v)),
                  _prefCard('Music Off', 'Prefer silence during ride', Icons.music_off, _musicOff, (v) => setState(() => _musicOff = v)),
                  const SizedBox(height: 16),
                  const Text('Special Requirements', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  _prefCard('Wheelchair Accessible', 'Need accessible vehicle', Icons.accessible, _wheelchairAccessible, (v) => setState(() => _wheelchairAccessible = v)),
                  _prefCard('Extra Luggage', 'Have large bags / extra luggage', Icons.luggage, _extraLuggage, (v) => setState(() => _extraLuggage = v)),
                  const SizedBox(height: 16),
                  const Text('Driver Preference', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Preferred Driver Gender', style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 12),
                        Row(children: [
                          _genderChoice('any', 'No Preference', Icons.people),
                          const SizedBox(width: 8),
                          _genderChoice('female', 'Women Driver', Icons.female),
                          const SizedBox(width: 8),
                          _genderChoice('male', 'Male Driver', Icons.male),
                        ]),
                        if (_preferredGender == 'female') ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: Colors.pink.shade50, borderRadius: BorderRadius.circular(8)),
                            child: const Row(children: [
                              Icon(Icons.shield, color: Colors.pink, size: 16),
                              SizedBox(width: 6),
                              Expanded(child: Text('Best effort to assign women driver.\nAvailability may vary.', style: TextStyle(fontSize: 12, color: Colors.pink))),
                            ]),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _saving
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Save Preferences', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _banner() => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      gradient: LinearGradient(colors: [const Color(0xFF2563EB).withValues(alpha: 0.1), const Color(0xFF7C3AED).withValues(alpha: 0.1)]),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFF2563EB).withValues(alpha: 0.2)),
    ),
    child: const Row(children: [
      Icon(Icons.tune, color: Color(0xFF2563EB)),
      SizedBox(width: 10),
      Expanded(child: Text('Your preferences are shared with the driver before every ride. We\'ll match your preferences as much as possible.',
          style: TextStyle(fontSize: 12, height: 1.4))),
    ]),
  );

  Widget _prefCard(String title, String subtitle, IconData icon, bool val, Function(bool) onChanged) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
    child: Row(children: [
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: val ? const Color(0xFF2563EB).withValues(alpha: 0.1) : Colors.grey.shade100, shape: BoxShape.circle),
        child: Icon(icon, color: val ? const Color(0xFF2563EB) : Colors.grey, size: 20),
      ),
      const SizedBox(width: 12),
      Expanded(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      )),
      Switch(value: val, onChanged: onChanged, activeThumbColor: const Color(0xFF2563EB)),
    ]),
  );

  Widget _genderChoice(String value, String label, IconData icon) => Expanded(
    child: GestureDetector(
      onTap: () => setState(() => _preferredGender = value),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: _preferredGender == value ? const Color(0xFF2563EB).withValues(alpha: 0.1) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _preferredGender == value ? const Color(0xFF2563EB) : Colors.transparent),
        ),
        child: Column(
          children: [
            Icon(icon, color: _preferredGender == value ? const Color(0xFF2563EB) : Colors.grey, size: 20),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 10, color: _preferredGender == value ? const Color(0xFF2563EB) : Colors.grey, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
          ],
        ),
      ),
    ),
  );
}
