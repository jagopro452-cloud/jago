import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserModel? _user;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = await AuthService.getProfile();
    if (mounted) setState(() { _user = user; _loading = false; });
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
      if (mounted) {
        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060D1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF060D1E),
        title: const Text('Profile', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.logout, color: Color(0xFFEF4444)), onPressed: _logout),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  _buildStatsRow(),
                  const SizedBox(height: 24),
                  _buildInfoSection(),
                  const SizedBox(height: 24),
                  _buildMenuSection(),
                ],
              ),
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
      child: Row(
        children: [
          Container(
            width: 70, height: 70,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 36),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_user?.fullName ?? 'Driver', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
                Text(_user?.phone ?? '', style: const TextStyle(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.star, color: Colors.amber, size: 14),
                    Text(' ${_user?.rating.toStringAsFixed(1) ?? '5.0'}', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                  ]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        _statCard('${_user?.stats.completedTrips ?? 0}', 'Trips', Icons.directions_car),
        const SizedBox(width: 12),
        _statCard('₹${_user?.stats.totalEarned.toStringAsFixed(0) ?? '0'}', 'Earned', Icons.payments),
        const SizedBox(width: 12),
        _statCard('₹${_user?.walletBalance.toStringAsFixed(0) ?? '0'}', 'Wallet', Icons.account_balance_wallet),
      ],
    );
  }

  Widget _statCard(String value, String label, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: const Color(0xFF091629), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFF1E3A5F))),
        child: Column(children: [
          Icon(icon, color: const Color(0xFF3B82F6), size: 20),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 11)),
        ]),
      ),
    );
  }

  Widget _buildInfoSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF091629), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF1E3A5F))),
      child: Column(
        children: [
          _infoRow(Icons.email, 'Email', _user?.email ?? 'Not set'),
          _divider(),
          _infoRow(Icons.lock, 'Account Status', _user?.isLocked == true ? '🔒 Locked' : '✅ Active'),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF3B82F6), size: 18),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
          const Spacer(),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _divider() => const Divider(color: Color(0xFF1E3A5F), height: 1);

  Widget _buildMenuSection() {
    final items = [
      {'icon': Icons.history, 'label': 'Trip History'},
      {'icon': Icons.share, 'label': 'Refer & Earn'},
      {'icon': Icons.headset_mic, 'label': 'Support'},
      {'icon': Icons.privacy_tip, 'label': 'Privacy Policy'},
      {'icon': Icons.description, 'label': 'Terms & Conditions'},
    ];
    return Container(
      decoration: BoxDecoration(color: const Color(0xFF091629), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF1E3A5F))),
      child: Column(
        children: items.asMap().entries.map((e) {
          final item = e.value;
          return Column(
            children: [
              ListTile(
                leading: Icon(item['icon'] as IconData, color: const Color(0xFF3B82F6), size: 20),
                title: Text(item['label'] as String, style: const TextStyle(color: Colors.white, fontSize: 14)),
                trailing: const Icon(Icons.arrow_forward_ios, color: Color(0xFF334155), size: 14),
                onTap: () {},
              ),
              if (e.key < items.length - 1) const Divider(color: Color(0xFF1E3A5F), height: 1, indent: 16),
            ],
          );
        }).toList(),
      ),
    );
  }
}
