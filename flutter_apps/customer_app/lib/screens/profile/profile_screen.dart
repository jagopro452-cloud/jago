import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';
import '../saved_places/saved_places_screen.dart';
import '../preferences/ride_preferences_screen.dart';
import '../monthly_pass/monthly_pass_screen.dart';
import '../lost_found/lost_found_screen.dart';
import '../safety/emergency_contacts_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _name = '';
  String _phone = '';
  String _email = '';
  double _rating = 5.0;
  bool _loading = true;

  @override
  void initState() { super.initState(); _loadProfile(); }

  Future<void> _loadProfile() async {
    final data = await AuthService.getProfile();
    setState(() {
      _name = data?['fullName'] ?? data?['name'] ?? 'User';
      _phone = data?['phone'] ?? '';
      _email = data?['email'] ?? '';
      _rating = (data?['rating'] ?? 5.0).toDouble();
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF1A1A2E)),
          onPressed: () => Navigator.pop(context)),
        title: const Text('Profile', style: TextStyle(color: Color(0xFF1A1A2E), fontWeight: FontWeight.bold)),
      ),
      body: _loading ? const Center(child: CircularProgressIndicator(color: Color(0xFF1E6DE5)))
        : SingleChildScrollView(
          child: Column(children: [
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.all(24),
              child: Column(children: [
                CircleAvatar(
                  radius: 40, backgroundColor: const Color(0xFF1E6DE5),
                  child: Text(_name.isNotEmpty ? _name[0].toUpperCase() : 'U',
                    style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 12),
                Text(_name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
                Text('+91-$_phone', style: TextStyle(color: Colors.grey[500], fontSize: 14)),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                  const SizedBox(width: 4),
                  Text(_rating.toStringAsFixed(1),
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
                ]),
              ]),
            ),
            const SizedBox(height: 12),
            _section([
              _tile(Icons.favorite_border, 'Saved Places', const Color(0xFF1E6DE5), () =>
                Navigator.push(context, MaterialPageRoute(builder: (_) => const SavedPlacesScreen()))),
              _tile(Icons.tune, 'Ride Preferences', const Color(0xFF1E6DE5), () =>
                Navigator.push(context, MaterialPageRoute(builder: (_) => const RidePreferencesScreen()))),
              _tile(Icons.card_membership, 'Monthly Pass', const Color(0xFF1E6DE5), () =>
                Navigator.push(context, MaterialPageRoute(builder: (_) => const MonthlyPassScreen()))),
            ]),
            const SizedBox(height: 12),
            _section([
              _tile(Icons.search, 'Lost & Found', Colors.orange, () =>
                Navigator.push(context, MaterialPageRoute(builder: (_) => const LostFoundScreen()))),
              _tile(Icons.shield_outlined, 'Emergency Contacts', Colors.red, () =>
                Navigator.push(context, MaterialPageRoute(builder: (_) => const EmergencyContactsScreen()))),
              _tile(Icons.headset_mic_outlined, 'Help & Support', Colors.teal, () {}),
            ]),
            const SizedBox(height: 12),
            _section([
              _tile(Icons.logout, 'Logout', Colors.red, () async {
                await AuthService.logout();
                if (!mounted) return;
                Navigator.pushAndRemoveUntil(context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
              }),
            ]),
            const SizedBox(height: 32),
            Text('JAGO v1.0.2 • MindWhile IT Solutions',
              style: TextStyle(color: Colors.grey[400], fontSize: 12)),
            const SizedBox(height: 24),
          ]),
        ),
    );
  }

  Widget _section(List<Widget> children) {
    return Container(
      color: Colors.white,
      child: Column(children: children),
    );
  }

  Widget _tile(IconData icon, String label, Color color, VoidCallback onTap) {
    return ListTile(
      leading: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: color, size: 20)),
      title: Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xFF1A1A2E))),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
      onTap: onTap,
    );
  }
}
