import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';
import '../saved_places/saved_places_screen.dart';

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
        title: const Text('Logout'),
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
      backgroundColor: Colors.white,
      appBar: AppBar(backgroundColor: Colors.white, title: const Text('Profile', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A))), centerTitle: true, actions: [
        IconButton(icon: const Icon(Icons.logout, color: Color(0xFFEF4444)), onPressed: _logout),
      ]),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF2563EB)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildHeader(),
                  const SizedBox(height: 20),
                  _buildInfo(),
                  const SizedBox(height: 20),
                  _buildMenu(),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF1D4ED8), Color(0xFF3B82F6)]),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(children: [
        Container(
          width: 70, height: 70,
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
          child: const Icon(Icons.person, color: Colors.white, size: 36),
        ),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_user?['fullName'] ?? 'User', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
          Text(_user?['phone'] ?? '', style: const TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
            child: Text('JAGO Member', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ])),
      ]),
    );
  }

  Widget _buildInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(children: [
        _row(Icons.email_outlined, 'Email', _user?['email'] ?? 'Not set'),
        const Divider(color: Color(0xFFE2E8F0)),
        _row(Icons.account_balance_wallet_outlined, 'Wallet Balance', '₹${double.tryParse(_user?['walletBalance']?.toString() ?? '0')?.toStringAsFixed(2) ?? '0.00'}'),
        const Divider(color: Color(0xFFE2E8F0)),
        _row(Icons.star_outlined, 'Rating', '${double.tryParse(_user?['rating']?.toString() ?? '5')?.toStringAsFixed(1)} ⭐'),
      ]),
    );
  }

  Widget _row(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(children: [
        Icon(icon, color: const Color(0xFF2563EB), size: 18),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
        const Spacer(),
        Text(value, style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13, fontWeight: FontWeight.w500)),
      ]),
    );
  }

  Widget _buildMenu() {
    final items = [
      {'icon': Icons.bookmark_outline, 'label': 'Saved Places', 'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SavedPlacesScreen()))},
      {'icon': Icons.share_outlined, 'label': 'Refer & Earn', 'onTap': () {}},
      {'icon': Icons.local_offer_outlined, 'label': 'My Coupons', 'onTap': () {}},
      {'icon': Icons.headset_mic_outlined, 'label': 'Support', 'onTap': () {}},
      {'icon': Icons.privacy_tip_outlined, 'label': 'Privacy Policy', 'onTap': () {}},
      {'icon': Icons.description_outlined, 'label': 'Terms & Conditions', 'onTap': () {}},
    ];
    return Container(
      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(children: items.asMap().entries.map((e) => Column(children: [
        ListTile(
          leading: Icon(e.value['icon'] as IconData, color: const Color(0xFF2563EB), size: 20),
          title: Text(e.value['label'] as String, style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14)),
          trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFFCBD5E1)),
          onTap: e.value['onTap'] as VoidCallback?,
        ),
        if (e.key < items.length - 1) const Divider(color: Color(0xFFE2E8F0), height: 1, indent: 16),
      ])).toList()),
    );
  }
}
