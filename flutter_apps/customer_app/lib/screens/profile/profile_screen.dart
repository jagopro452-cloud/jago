import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../main.dart' show saveThemePreference;
import '../auth/login_screen.dart';
import '../saved_places/saved_places_screen.dart';
import '../preferences/ride_preferences_screen.dart';
import '../monthly_pass/monthly_pass_screen.dart';
import '../lost_found/lost_found_screen.dart';
import '../safety/emergency_contacts_screen.dart';
import '../referral/referral_screen.dart';
import './support_chat_screen.dart';

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
  double _walletBalance = 0;
  int _loyaltyPoints = 0;
  int _completedTrips = 0;
  double _totalSpent = 0;
  bool _loading = true;
  bool _editing = false;
  bool _saving = false;
  late TextEditingController _nameCtrl;
  late TextEditingController _emailCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _emailCtrl = TextEditingController();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final data = await AuthService.getProfile();
    setState(() {
      _name = data?['fullName'] ?? data?['name'] ?? 'User';
      _phone = data?['phone'] ?? '';
      _email = data?['email'] ?? '';
      _rating = (data?['rating'] ?? 5.0).toDouble();
      _walletBalance = (data?['walletBalance'] ?? 0).toDouble();
      _loyaltyPoints = (data?['loyaltyPoints'] ?? 0).toInt();
      final stats = data?['stats'] as Map<String, dynamic>? ?? {};
      _completedTrips = (stats['completedTrips'] ?? 0).toInt();
      _totalSpent = (stats['totalSpent'] ?? 0).toDouble();
      _nameCtrl.text = _name;
      _emailCtrl.text = _email;
      _loading = false;
    });
  }

  Future<void> _saveProfile() async {
    setState(() => _saving = true);
    final res = await AuthService.updateProfile(
      fullName: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
    );
    setState(() => _saving = false);
    if (res['success'] == true) {
      setState(() {
        _name = _nameCtrl.text.trim();
        _email = _emailCtrl.text.trim();
        _editing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Profile updated successfully'),
          backgroundColor: Color(0xFF1E6DE5)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(res['message'] ?? 'Update failed'),
          backgroundColor: Colors.red));
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg =
        isDark ? const Color(0xFF0A0F1E) : const Color(0xFFF3F6FB);
    final cardBg = isDark ? const Color(0xFF141B2D) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF111827);
    final subColor = isDark ? Colors.white54 : const Color(0xFF6B7280);
    final divColor = isDark ? Colors.white10 : const Color(0xFFEEEEEE);

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: cardBg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor, size: 20),
          onPressed: () => Navigator.pop(context)),
        title: Text('My Profile',
            style: TextStyle(
                color: textColor, fontWeight: FontWeight.w700, fontSize: 17)),
        actions: [
          if (!_editing)
            TextButton.icon(
              onPressed: () => setState(() => _editing = true),
              icon: const Icon(Icons.edit_outlined,
                  color: Color(0xFF1E6DE5), size: 18),
              label: const Text('Edit',
                  style: TextStyle(
                      color: Color(0xFF1E6DE5), fontWeight: FontWeight.w600)),
            )
          else ...[
            TextButton(
              onPressed: () =>
                  setState(() {
                    _editing = false;
                    _nameCtrl.text = _name;
                    _emailCtrl.text = _email;
                  }),
              child: Text('Cancel', style: TextStyle(color: subColor)),
            ),
            TextButton(
              onPressed: _saving ? null : _saveProfile,
              child: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Color(0xFF1E6DE5)))
                  : const Text('Save',
                      style: TextStyle(
                          color: Color(0xFF1E6DE5),
                          fontWeight: FontWeight.w700)),
            ),
          ],
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF1E6DE5)))
          : SingleChildScrollView(
              child: Column(children: [
                Container(
                  width: double.infinity,
                  color: cardBg,
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
                  child: Column(children: [
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 44,
                          backgroundColor:
                              const Color(0xFF1E6DE5).withOpacity(0.15),
                          child: Text(
                            _name.isNotEmpty
                                ? _name[0].toUpperCase()
                                : 'U',
                            style: const TextStyle(
                                color: Color(0xFF1E6DE5),
                                fontSize: 36,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        if (_editing)
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                                color: const Color(0xFF1E6DE5),
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: cardBg, width: 2)),
                            child: const Icon(Icons.camera_alt_outlined,
                                color: Colors.white, size: 14),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    if (_editing) ...[
                      _editField('Full Name', _nameCtrl, textColor, isDark),
                      const SizedBox(height: 10),
                      _editField('Email Address', _emailCtrl, textColor,
                          isDark,
                          keyboard: TextInputType.emailAddress),
                    ] else ...[
                      Text(_name,
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: textColor)),
                      const SizedBox(height: 4),
                      Text('+91 $_phone',
                          style: TextStyle(color: subColor, fontSize: 14)),
                      if (_email.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(_email,
                            style:
                                TextStyle(color: subColor, fontSize: 13)),
                      ],
                      const SizedBox(height: 10),
                      Row(mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                        const Icon(Icons.star_rounded,
                            color: Colors.amber, size: 20),
                        const SizedBox(width: 4),
                        Text(_rating.toStringAsFixed(1),
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: textColor,
                                fontSize: 15)),
                        Text(' rating',
                            style:
                                TextStyle(color: subColor, fontSize: 13)),
                      ]),
                    ],
                  ]),
                ),
                const SizedBox(height: 12),
                Container(
                  color: cardBg,
                  padding: const EdgeInsets.all(16),
                  child: Row(children: [
                    _statCard('Wallet', '₹${_walletBalance.toStringAsFixed(0)}',
                        Icons.account_balance_wallet_outlined,
                        const Color(0xFF1E6DE5), isDark),
                    _statCard('Loyalty Points', '$_loyaltyPoints pts',
                        Icons.stars_rounded, Colors.amber, isDark),
                    _statCard('Trips', '$_completedTrips',
                        Icons.directions_car_rounded,
                        Colors.green, isDark),
                    _statCard('Spent', '₹${_totalSpent.toStringAsFixed(0)}',
                        Icons.receipt_long_outlined, Colors.purple, isDark),
                  ]),
                ),
                const SizedBox(height: 12),
                _section([
                  _tile(Icons.favorite_border_rounded, 'Saved Places',
                      const Color(0xFF1E6DE5), cardBg, textColor, divColor,
                      () => Navigator.push(context, MaterialPageRoute(
                          builder: (_) => const SavedPlacesScreen()))),
                  _tile(Icons.tune_rounded, 'Ride Preferences',
                      const Color(0xFF1E6DE5), cardBg, textColor, divColor,
                      () => Navigator.push(context, MaterialPageRoute(
                          builder: (_) => const RidePreferencesScreen()))),
                  _tile(Icons.card_membership_rounded, 'Monthly Pass',
                      const Color(0xFF1E6DE5), cardBg, textColor, divColor,
                      () => Navigator.push(context, MaterialPageRoute(
                          builder: (_) => const MonthlyPassScreen()))),
                  _tile(Icons.card_giftcard_rounded, 'Refer & Earn',
                      Colors.amber.shade700, cardBg, textColor, divColor,
                      () => Navigator.push(context, MaterialPageRoute(
                          builder: (_) => const ReferralScreen()))),
                ], cardBg),
                const SizedBox(height: 12),
                _section([
                  _tile(Icons.search_rounded, 'Lost & Found', Colors.orange,
                      cardBg, textColor, divColor,
                      () => Navigator.push(context, MaterialPageRoute(
                          builder: (_) => const LostFoundScreen()))),
                  _tile(Icons.shield_outlined, 'Emergency Contacts', Colors.red,
                      cardBg, textColor, divColor,
                      () => Navigator.push(context, MaterialPageRoute(
                          builder: (_) => const EmergencyContactsScreen()))),
                  _tile(Icons.headset_mic_outlined, 'Help & Support',
                      Colors.teal, cardBg, textColor, divColor, () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const SupportChatScreen()));
                      }),
                ], cardBg),
                const SizedBox(height: 12),
                _section([
                  ListTile(
                    leading: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withOpacity(0.08)
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8)),
                      child: Icon(
                          isDark
                              ? Icons.light_mode_outlined
                              : Icons.dark_mode_outlined,
                          color: isDark ? Colors.amber : Colors.indigo,
                          size: 20),
                    ),
                    title: Text(
                        isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: textColor)),
                    trailing: Icon(Icons.chevron_right,
                        color: subColor, size: 20),
                    onTap: () async {
                      await saveThemePreference(
                          isDark ? ThemeMode.light : ThemeMode.dark);
                    },
                  ),
                ], cardBg),
                const SizedBox(height: 12),
                _section([
                  _tile(Icons.logout_rounded, 'Logout', Colors.red, cardBg,
                      textColor, divColor, () async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        backgroundColor: cardBg,
                        title: Text('Logout?',
                            style: TextStyle(color: textColor)),
                        content: Text('Are you sure you want to logout?',
                            style: TextStyle(color: subColor)),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: Text('Cancel',
                                  style: TextStyle(color: subColor))),
                          TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Logout',
                                  style: TextStyle(color: Colors.red))),
                        ],
                      ),
                    );
                    if (ok == true) {
                      await AuthService.logout();
                      if (!mounted) return;
                      Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const LoginScreen()),
                          (_) => false);
                    }
                  }),
                ], cardBg),
                const SizedBox(height: 32),
                Text('v2.01 • MindWhile IT Solutions',
                    style: TextStyle(color: subColor, fontSize: 11)),
                const SizedBox(height: 24),
              ]),
            ),
    );
  }

  Widget _editField(String label, TextEditingController ctrl, Color textColor,
      bool isDark,
      {TextInputType keyboard = TextInputType.text}) {
    final fieldBg =
        isDark ? const Color(0xFF1E293B) : const Color(0xFFF5F7FA);
    final borderColor =
        isDark ? Colors.white12 : const Color(0xFFE5E9F0);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: textColor.withOpacity(0.5),
              letterSpacing: 0.8)),
      const SizedBox(height: 4),
      Container(
        decoration: BoxDecoration(
            color: fieldBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor)),
        child: TextField(
          controller: ctrl,
          keyboardType: keyboard,
          style: TextStyle(color: textColor, fontSize: 15),
          decoration: InputDecoration(
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ),
    ]);
  }

  Widget _statCard(String label, String value, IconData icon, Color color,
      bool isDark) {
    return Expanded(
      child: Column(children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
              color: color.withOpacity(isDark ? 0.15 : 0.1),
              borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(height: 6),
        Text(value,
            style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 13,
                color: isDark ? Colors.white : const Color(0xFF111827))),
        Text(label,
            style: TextStyle(
                fontSize: 10,
                color: isDark ? Colors.white38 : Colors.grey.shade500)),
      ]),
    );
  }

  Widget _section(List<Widget> children, Color cardBg) {
    return Container(
      color: cardBg,
      child: Column(children: children),
    );
  }

  Widget _tile(IconData icon, String label, Color color, Color cardBg,
      Color textColor, Color divColor, VoidCallback onTap) {
    return Column(children: [
      ListTile(
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(label,
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: textColor)),
        trailing: Icon(Icons.chevron_right_rounded,
            color: textColor.withOpacity(0.3), size: 20),
        onTap: onTap,
      ),
      Divider(height: 1, color: divColor, indent: 68),
    ]);
  }
}
