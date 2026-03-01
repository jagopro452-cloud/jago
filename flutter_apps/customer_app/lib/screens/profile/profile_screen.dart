import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';
import '../saved_places/saved_places_screen.dart';
import '../scheduled/scheduled_rides_screen.dart';
import '../safety/emergency_contacts_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _user;
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final d = await AuthService.getProfile();
    if (mounted) setState(() { _user = d?['user'] ?? d; _loading = false; });
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Logout', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Logout', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed == true) {
      await AuthService.logout();
      if (mounted) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Profile', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
        centerTitle: true,
        elevation: 0,
        surfaceTintColor: Colors.white,
        actions: [IconButton(icon: const Icon(Icons.logout, color: Color(0xFFEF4444)), onPressed: _logout)],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF2563EB)))
          : SingleChildScrollView(
              child: Column(children: [
                _buildHeader(),
                const SizedBox(height: 12),
                _buildStatsRow(),
                const SizedBox(height: 12),
                _buildMainMenu(),
                const SizedBox(height: 12),
                _buildSafetyMenu(),
                const SizedBox(height: 12),
                _buildInfoMenu(),
                const SizedBox(height: 24),
              ]),
            ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      decoration: const BoxDecoration(color: Colors.white),
      child: Column(children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              width: 88, height: 88,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF1D4ED8), Color(0xFF3B82F6)]),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(Icons.person, color: Colors.white, size: 44),
            ),
            Container(
              width: 26, height: 26,
              decoration: const BoxDecoration(color: Color(0xFF22C55E), shape: BoxShape.circle),
              child: const Icon(Icons.edit, color: Colors.white, size: 14),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(_user?['fullName'] ?? 'User', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Color(0xFF0F172A))),
        const SizedBox(height: 4),
        Text('+91 ${_user?['phone'] ?? ''}', style: const TextStyle(color: Color(0xFF64748B), fontSize: 14)),
        const SizedBox(height: 10),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _pill(Icons.star, '${double.tryParse(_user?['rating']?.toString() ?? '5')?.toStringAsFixed(1)} Rating', const Color(0xFFFACC15), const Color(0xFF78350F)),
          const SizedBox(width: 8),
          _pill(Icons.verified_user, 'JAGO Member', const Color(0xFFEFF6FF), const Color(0xFF2563EB)),
        ]),
      ]),
    );
  }

  Widget _pill(IconData icon, String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Row(children: [Icon(icon, size: 13, color: fg), const SizedBox(width: 4), Text(text, style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.bold))]),
    );
  }

  Widget _buildStatsRow() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)]),
      child: Row(children: [
        _stat('${_user?['totalTrips'] ?? 0}', 'Trips', Icons.directions_car),
        _statDivider(),
        _stat('₹${double.tryParse(_user?['walletBalance']?.toString() ?? '0')?.toStringAsFixed(0) ?? '0'}', 'Wallet', Icons.account_balance_wallet),
        _statDivider(),
        _stat('₹${double.tryParse(_user?['totalSpent']?.toString() ?? '0')?.toStringAsFixed(0) ?? '0'}', 'Spent', Icons.payments),
      ]),
    );
  }

  Widget _stat(String value, String label, IconData icon) {
    return Expanded(child: Column(children: [
      Icon(icon, color: const Color(0xFF2563EB), size: 20),
      const SizedBox(height: 4),
      Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A))),
      Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
    ]));
  }

  Widget _statDivider() => Container(width: 1, height: 40, color: const Color(0xFFE2E8F0));

  Widget _buildMainMenu() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8)]),
      child: Column(children: [
        _tile(Icons.bookmark, 'Saved Places', color: const Color(0xFF2563EB), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SavedPlacesScreen()))),
        _div(),
        _tile(Icons.schedule, 'Scheduled Rides', color: const Color(0xFF7C3AED), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ScheduledRidesScreen()))),
        _div(),
        _tile(Icons.local_offer, 'My Coupons', color: const Color(0xFF059669), badge: 'SAVE 20%'),
        _div(),
        _tile(Icons.share, 'Refer & Earn', color: const Color(0xFFF59E0B), badge: '₹50/Refer'),
      ]),
    );
  }

  Widget _buildSafetyMenu() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8)]),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0)))),
          child: const Row(children: [Icon(Icons.shield, color: Colors.red, size: 16), SizedBox(width: 6), Text('Safety', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.5))]),
        ),
        _tile(Icons.emergency, 'Emergency Contacts', color: Colors.red, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EmergencyContactsScreen()))),
        _div(),
        _tile(Icons.sos, 'SOS Settings', color: Colors.red),
        _div(),
        _tile(Icons.share_location, 'Live Trip Sharing', color: Colors.red),
      ]),
    );
  }

  Widget _buildInfoMenu() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8)]),
      child: Column(children: [
        _tile(Icons.headset_mic, 'Help & Support', color: const Color(0xFF2563EB)),
        _div(),
        _tile(Icons.privacy_tip, 'Privacy Policy', color: const Color(0xFF2563EB)),
        _div(),
        _tile(Icons.description, 'Terms & Conditions', color: const Color(0xFF2563EB)),
        _div(),
        _tile(Icons.star_outline, 'Rate the App', color: const Color(0xFFF59E0B)),
      ]),
    );
  }

  Widget _tile(IconData icon, String label, {Color color = const Color(0xFF2563EB), VoidCallback? onTap, String? badge}) {
    return ListTile(
      leading: Container(width: 38, height: 38, decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: color, size: 18)),
      title: Text(label, style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A), fontWeight: FontWeight.w500)),
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        if (badge != null) Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)), child: Text(badge, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold))),
        if (badge != null) const SizedBox(width: 6),
        const Icon(Icons.arrow_forward_ios, size: 13, color: Color(0xFFCBD5E1)),
      ]),
      onTap: onTap ?? () {},
    );
  }

  Widget _div() => const Divider(height: 1, indent: 16, color: Color(0xFFF1F5F9));
}
