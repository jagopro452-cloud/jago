import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../config/api_config.dart';
import '../auth/login_screen.dart';
import '../kyc/kyc_documents_screen.dart';
import '../performance/performance_screen.dart';
import '../break_mode/break_mode_screen.dart';
import '../fatigue/fatigue_alert_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserModel? _user;
  bool _loading = true;
  int _unread = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final results = await Future.wait([
      AuthService.getProfile(),
      _loadNotifCount(),
    ]);
    if (mounted) setState(() { _user = results[0] as UserModel?; _loading = false; });
  }

  Future<void> _loadNotifCount() async {
    try {
      final headers = await AuthService.getHeaders();
      final res = await http.get(Uri.parse(ApiConfig.notifications), headers: headers);
      if (res.statusCode == 200 && mounted) {
        setState(() => _unread = jsonDecode(res.body)['unreadCount'] ?? 0);
      }
    } catch (_) {}
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF091629),
        title: const Text('Logout', style: TextStyle(color: Colors.white)),
        content: const Text('Are you sure you want to logout?', style: TextStyle(color: Color(0xFF94A3B8))),
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
      backgroundColor: const Color(0xFF060D1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF060D1E),
        title: const Text('My Profile', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          Stack(
            children: [
              IconButton(icon: const Icon(Icons.notifications_outlined, color: Colors.white), onPressed: () {}),
              if (_unread > 0) Positioned(top: 8, right: 8, child: Container(width: 16, height: 16, decoration: const BoxDecoration(color: Color(0xFFEF4444), shape: BoxShape.circle), child: Center(child: Text('$_unread', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold))))),
            ],
          ),
          IconButton(icon: const Icon(Icons.logout, color: Color(0xFFEF4444)), onPressed: _logout),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                _buildHeader(),
                const SizedBox(height: 16),
                _buildStatsRow(),
                const SizedBox(height: 16),
                _buildLockWarning(),
                _buildMainMenu(),
                const SizedBox(height: 12),
                _buildSecondaryMenu(),
              ]),
            ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF1D4ED8), Color(0xFF2563EB)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(children: [
        Container(
          width: 72, height: 72,
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
          child: _user?.profilePhoto != null
              ? ClipRRect(borderRadius: BorderRadius.circular(20), child: Image.network(_user!.profilePhoto!, fit: BoxFit.cover))
              : const Icon(Icons.person, color: Colors.white, size: 38),
        ),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_user?.fullName ?? 'Driver', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
          Text(_user?.phone ?? '', style: const TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 6),
          Row(children: [
            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(6)), child: const Text('JAGO Pilot', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
            const SizedBox(width: 8),
            const Icon(Icons.star, color: Colors.amber, size: 14),
            Text(' ${_user?.rating.toStringAsFixed(1) ?? '5.0'}', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
          ]),
        ])),
      ]),
    );
  }

  Widget _buildStatsRow() {
    return Row(children: [
      _statCard('${_user?.stats.completedTrips ?? 0}', 'Trips', Icons.directions_car, const Color(0xFF3B82F6)),
      const SizedBox(width: 8),
      _statCard('₹${_user?.walletBalance.toStringAsFixed(0) ?? '0'}', 'Wallet', Icons.account_balance_wallet, const Color(0xFF22C55E)),
      const SizedBox(width: 8),
      _statCard(_user?.isOnline == true ? 'Online' : 'Offline', 'Status', Icons.circle, _user?.isOnline == true ? const Color(0xFF22C55E) : const Color(0xFF475569)),
    ]);
  }

  Widget _statCard(String value, String label, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: const Color(0xFF091629), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFF1E3A5F))),
        child: Column(children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
          Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 10)),
        ]),
      ),
    );
  }

  Widget _buildLockWarning() {
    if (_user?.isLocked != true) return const SizedBox();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: const Color(0xFFEF4444).withOpacity(0.1), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.5))),
      child: Row(children: [
        const Icon(Icons.lock, color: Color(0xFFEF4444), size: 20),
        const SizedBox(width: 10),
        Expanded(child: Text(_user?.lockReason ?? 'Account locked. Pay dues to go online.', style: const TextStyle(color: Color(0xFFEF4444), fontSize: 13))),
      ]),
    );
  }

  Widget _buildMainMenu() {
    return Container(
      decoration: BoxDecoration(color: const Color(0xFF091629), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF1E3A5F))),
      child: Column(children: [
        _menuItem(Icons.trending_up, 'Performance & Stats', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PerformanceScreen()))),
        _divider(),
        _menuItem(Icons.verified_user, 'KYC Documents', badge: 'Verify', badgeColor: Colors.orange, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const KycDocumentsScreen()))),
        _divider(),
        _menuItem(Icons.coffee, 'Break Mode', badge: 'New', badgeColor: Colors.amber, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BreakModeScreen()))),
        _divider(),
        _menuItem(Icons.monitor_heart, 'Fatigue Alert', badge: 'Safety', badgeColor: const Color(0xFFEF4444), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FatigueAlertScreen()))),
        _divider(),
        _menuItem(Icons.share, 'Refer & Earn', badge: '₹100/Refer', badgeColor: const Color(0xFF22C55E)),
        _divider(),
        _menuItem(Icons.receipt_long, 'Trip History'),
        _divider(),
        _menuItem(Icons.account_balance_wallet, 'Wallet & Earnings'),
      ]),
    );
  }

  Widget _buildSecondaryMenu() {
    return Container(
      decoration: BoxDecoration(color: const Color(0xFF091629), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF1E3A5F))),
      child: Column(children: [
        _menuItem(Icons.headset_mic, 'Support & Help'),
        _divider(),
        _menuItem(Icons.privacy_tip, 'Privacy Policy'),
        _divider(),
        _menuItem(Icons.description, 'Terms & Conditions'),
        _divider(),
        _menuItem(Icons.info, 'About JAGO'),
      ]),
    );
  }

  Widget _menuItem(IconData icon, String label, {VoidCallback? onTap, String? badge, Color? badgeColor}) {
    return ListTile(
      leading: Container(width: 38, height: 38, decoration: BoxDecoration(color: const Color(0xFF1E3A5F), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: const Color(0xFF3B82F6), size: 18)),
      title: Text(label, style: const TextStyle(color: Colors.white, fontSize: 14)),
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        if (badge != null) Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: (badgeColor ?? const Color(0xFF3B82F6)).withOpacity(0.15), borderRadius: BorderRadius.circular(6)), child: Text(badge, style: TextStyle(color: badgeColor ?? const Color(0xFF3B82F6), fontSize: 10, fontWeight: FontWeight.bold))),
        if (badge != null) const SizedBox(width: 6),
        const Icon(Icons.arrow_forward_ios, color: Color(0xFF334155), size: 13),
      ]),
      onTap: onTap ?? () {},
    );
  }

  Widget _divider() => const Divider(color: Color(0xFF1E3A5F), height: 1, indent: 16);
}
