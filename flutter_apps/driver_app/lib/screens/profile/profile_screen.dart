import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../../services/auth_service.dart';
import '../../config/api_config.dart';
import '../../main.dart' show themeNotifier, saveThemePreference;
import '../../services/localization_service.dart';
import '../auth/login_screen.dart';
import '../onboarding/language_select_screen.dart';
import '../performance/performance_screen.dart';
import '../kyc/kyc_documents_screen.dart';
import '../referral/referral_screen.dart';
import '../history/trips_history_screen.dart';
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
  String _vehicleNumber = '';
  String _vehicleModel = '';
  String _vehicleCategory = '';
  String _driverStatus = '';
  String _referralCode = '';
  double _rating = 5.0;
  int _totalTrips = 0;
  int _cancelledTrips = 0;
  double _weeklyEarnings = 0;
  bool _loading = true;
  bool _savingName = false;

  static const Color _bg = Color(0xFF060D1E);
  static const Color _surface = Color(0xFF1C1C1E);
  static const Color _blue = Color(0xFF2563EB);

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final data = await AuthService.getProfile();
    if (data != null) {
      setState(() {
        _name = data.fullName;
        _phone = data.phone;
        _email = data.email ?? '';
        _vehicleNumber = data.vehicleNumber ?? '';
        _vehicleModel = data.vehicleModel ?? '';
        _vehicleCategory = data.vehicleCategory ?? '';
        _driverStatus = data.status ?? 'pending';
        _referralCode = data.referralCode ?? '';
        _rating = data.rating;
        _totalTrips = data.stats.completedTrips;
        _cancelledTrips = data.stats.cancelledTrips;
        _weeklyEarnings = data.stats.weeklyEarnings;
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
    }
  }

  Future<String> _getSupportPhone() async {
    try {
      final r = await http.get(Uri.parse(ApiConfig.configs));
      if (r.statusCode == 200) {
        final data = jsonDecode(r.body);
        return data['configs']?['support_phone'] ?? '+916303000000';
      }
    } catch (_) {}
    return '+916303000000';
  }

  void _showEditNameSheet() {
    final ctrl = TextEditingController(text: _name);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1C1C1E),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 24),
            const Text('Edit Display Name',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 20),
            TextField(
              controller: ctrl,
              autofocus: true,
              style: const TextStyle(color: Colors.white, fontSize: 15),
              decoration: InputDecoration(
                hintText: 'Your full name',
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: _blue)),
                prefixIcon: Icon(Icons.person_rounded, color: Colors.white.withValues(alpha: 0.4)),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _blue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () async {
                  final newName = ctrl.text.trim();
                  if (newName.isEmpty || newName == _name) {
                    Navigator.pop(context);
                    return;
                  }
                  Navigator.pop(context);
                  setState(() => _savingName = true);
                  try {
                    final token = await AuthService.getToken();
                    final res = await http.put(
                      Uri.parse(ApiConfig.updateProfile),
                      headers: {
                        'Authorization': 'Bearer $token',
                        'Content-Type': 'application/json',
                      },
                      body: jsonEncode({'fullName': newName}),
                    );
                    if (res.statusCode == 200 && mounted) {
                      setState(() { _name = newName; });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Row(children: [
                            Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                            SizedBox(width: 10),
                            Text('Name updated successfully'),
                          ]),
                          backgroundColor: const Color(0xFF16A34A),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      );
                    }
                  } catch (_) {}
                  if (mounted) setState(() => _savingName = false);
                },
                child: const Text('Save Changes',
                  style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Future<void> _deleteDriverAccount(bool permanent) async {
    final token = await AuthService.getToken();
    try {
      final res = await http.delete(
        Uri.parse(ApiConfig.deleteAccount),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: jsonEncode({'permanent': permanent}),
      );
      if (res.statusCode == 200 && mounted) {
        await AuthService.logout();
        Navigator.pushAndRemoveUntil(context,
          MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
      } else if (mounted) {
        final data = jsonDecode(res.body);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(data['message'] ?? 'Delete failed'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Network error. Please try again.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  void _showDeleteAccountSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1C1C1E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 20),
          const Row(children: [
            Icon(Icons.warning_rounded, color: Colors.red, size: 22),
            SizedBox(width: 10),
            Text('Delete Account', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
          ]),
          const SizedBox(height: 6),
          Text('Choose how you want to remove your account.',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 13)),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  backgroundColor: _surface,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  title: const Text('Deactivate Account?',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                  content: Text('Your account will be deactivated. Your data is kept. Contact support to reactivate.',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13)),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: TextStyle(color: Colors.white.withValues(alpha: 0.5)))),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.orange,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                      onPressed: () { Navigator.pop(context); _deleteDriverAccount(false); },
                      child: const Text('Deactivate', style: TextStyle(color: Colors.white))),
                  ],
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: const Row(children: [
                Icon(Icons.pause_circle_outline, color: Colors.orange, size: 22),
                SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Deactivate Account', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w700, fontSize: 14)),
                  SizedBox(height: 2),
                  Text('Recoverable - contact support to reactivate', style: TextStyle(color: Colors.orange, fontSize: 11, fontWeight: FontWeight.w400)),
                ])),
              ]),
            ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  backgroundColor: _surface,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  title: const Text('Delete Permanently?',
                    style: TextStyle(color: Colors.red, fontWeight: FontWeight.w800)),
                  content: Text('This will permanently delete all your data including earnings history, KYC documents, and personal information. This cannot be undone.',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13)),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: TextStyle(color: Colors.white.withValues(alpha: 0.5)))),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                      onPressed: () { Navigator.pop(context); _deleteDriverAccount(true); },
                      child: const Text('Delete Forever', style: TextStyle(color: Colors.white))),
                  ],
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
              ),
              child: const Row(children: [
                Icon(Icons.delete_forever, color: Colors.red, size: 22),
                SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Delete Account Permanently', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700, fontSize: 14)),
                  SizedBox(height: 2),
                  Text('All data deleted forever - cannot be undone', style: TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.w400)),
                ])),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  void _showSupportSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1C1C1E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 20),
          const Row(children: [
            Icon(Icons.headset_mic_rounded, color: Colors.teal, size: 22),
            SizedBox(width: 10),
            Text('Support', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
          ]),
          const SizedBox(height: 6),
          Text('JAGO Pilot support team always ready!',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 13)),
          const SizedBox(height: 20),
          _supportOption(
            icon: Icons.chat_bubble_rounded, color: _blue,
            title: 'Chat with Support', subtitle: 'Average response: 2 minutes',
            onTap: () {
              Navigator.pop(ctx);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const DriverSupportChatScreen()));
            },
          ),
          const SizedBox(height: 10),
          _supportOption(
            icon: Icons.phone_rounded, color: Colors.teal,
            title: 'Call Support', subtitle: 'Available 24/7',
            onTap: () async {
              final phone = await _getSupportPhone();
              Navigator.pop(ctx);
              final uri = Uri(scheme: 'tel', path: phone);
              if (await canLaunchUrl(uri)) await launchUrl(uri);
            },
          ),
        ]),
      ),
    );
  }

  Widget _supportOption({
    required IconData icon, required Color color, required String title,
    required String subtitle, required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.12)),
        ),
        child: Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
            const SizedBox(height: 2),
            Text(subtitle, style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12)),
          ]),
          const Spacer(),
          Icon(Icons.chevron_right_rounded, color: Colors.white.withValues(alpha: 0.3)),
        ]),
      ),
    );
  }

  Color _statusColor() {
    switch (_driverStatus) {
      case 'approved': return Colors.green;
      case 'pending': return Colors.orange;
      case 'rejected': return Colors.red;
      default: return Colors.grey;
    }
  }

  String _statusLabel() {
    switch (_driverStatus) {
      case 'approved': return 'Verified Pilot';
      case 'pending': return 'Verification Pending';
      case 'rejected': return 'Verification Rejected';
      default: return _driverStatus;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: _bg,
        body: const Center(child: CircularProgressIndicator(color: _blue)),
      );
    }

    return Scaffold(
      backgroundColor: _bg,
      body: CustomScrollView(
        slivers: [
          // Hero profile header
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: _bg,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_rounded, color: Colors.white.withValues(alpha: 0.7)),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                onPressed: () {
                  final isDark = themeNotifier.value == ThemeMode.dark;
                  saveThemePreference(isDark ? ThemeMode.light : ThemeMode.dark);
                  // Persist to server
                  AuthService.getToken().then((token) {
                    http.patch(
                      Uri.parse('${ApiConfig.baseUrl}/api/app/driver/theme'),
                      headers: {
                        'Content-Type': 'application/json',
                        'Authorization': 'Bearer $token',
                      },
                      body: jsonEncode({'theme': isDark ? 'light' : 'dark'}),
                    ).catchError((_) => http.Response('', 500));
                  });
                },
                icon: ValueListenableBuilder<ThemeMode>(
                  valueListenable: themeNotifier,
                  builder: (_, mode, __) => Icon(
                    mode == ThemeMode.dark ? Icons.light_mode : Icons.dark_mode,
                    color: Colors.white,
                  ),
                ),
              ),
              IconButton(
                onPressed: _showEditNameSheet,
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.edit_rounded, color: Colors.white, size: 18),
                ),
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF112240), _bg],
                    begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 46,
                            backgroundColor: _blue,
                            child: Text(
                              _name.isNotEmpty ? _name[0].toUpperCase() : 'P',
                              style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900),
                            ),
                          ),
                          Positioned(
                            bottom: 0, right: 0,
                            child: GestureDetector(
                              onTap: _showEditNameSheet,
                              child: Container(
                                width: 28, height: 28,
                                decoration: BoxDecoration(
                                  color: _blue, shape: BoxShape.circle,
                                  border: Border.all(color: _bg, width: 2),
                                ),
                                child: const Icon(Icons.edit_rounded, color: Colors.white, size: 14),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_savingName)
                        const SizedBox(
                          height: 20, width: 20,
                          child: CircularProgressIndicator(color: _blue, strokeWidth: 2))
                      else
                        Text(_name,
                          style: const TextStyle(
                            color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900,
                            letterSpacing: -0.3)),
                      const SizedBox(height: 4),
                      Text('+91-$_phone',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 13)),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: _statusColor().withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _statusColor().withValues(alpha: 0.3)),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(
                            _driverStatus == 'approved' ? Icons.verified_rounded : Icons.pending_rounded,
                            size: 13, color: _statusColor()),
                          const SizedBox(width: 5),
                          Text(_statusLabel(),
                            style: TextStyle(color: _statusColor(), fontSize: 12, fontWeight: FontWeight.w700)),
                        ]),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Stats row
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Row(children: [
                    _statCard('Rating', '${_rating.toStringAsFixed(1)} ⭐', _blue),
                    const SizedBox(width: 10),
                    _statCard('Trips Done', '$_totalTrips', Colors.green),
                    const SizedBox(width: 10),
                    _statCard('This Week', '₹${_weeklyEarnings.toStringAsFixed(0)}', Colors.amber.shade600),
                  ]),
                ),

                const SizedBox(height: 20),

                // Vehicle info card
                if (_vehicleNumber.isNotEmpty || _vehicleModel.isNotEmpty)
                  _sectionCard(
                    title: 'Vehicle Info',
                    icon: Icons.two_wheeler_rounded,
                    iconColor: _blue,
                    children: [
                      if (_vehicleNumber.isNotEmpty)
                        _infoRow(Icons.badge_rounded, 'Vehicle Number', _vehicleNumber.toUpperCase()),
                      if (_vehicleModel.isNotEmpty)
                        _infoRow(Icons.directions_car_rounded, 'Model', _vehicleModel),
                      if (_vehicleCategory.isNotEmpty)
                        _infoRow(Icons.category_rounded, 'Category', _vehicleCategory),
                    ],
                  ),

                if (_vehicleNumber.isNotEmpty || _vehicleModel.isNotEmpty)
                  const SizedBox(height: 12),

                // Account info card
                _sectionCard(
                  title: 'Account',
                  icon: Icons.person_rounded,
                  iconColor: Colors.teal,
                  children: [
                    if (_email.isNotEmpty)
                      _infoRow(Icons.email_rounded, 'Email', _email),
                    if (_referralCode.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: _referralCode));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Row(children: [
                                Icon(Icons.copy_rounded, color: Colors.white, size: 16),
                                SizedBox(width: 8),
                                Text('Referral code copied!'),
                              ]),
                              backgroundColor: _blue,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                        child: _infoRow(
                          Icons.card_giftcard_rounded, 'Referral Code',
                          _referralCode,
                          trailing: const Icon(Icons.copy_rounded, size: 14, color: Colors.blue),
                        ),
                      ),
                    _infoRow(Icons.cancel_outlined, 'Cancellations', '$_cancelledTrips trips cancelled'),
                  ],
                ),

                const SizedBox(height: 12),

                // Menu items
                _menuCard(children: [
                  _menuTile(Icons.bar_chart_rounded, 'Performance & Ratings', const Color(0xFF8B5CF6), () =>
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const PerformanceScreen()))),
                  _divider(),
                  _menuTile(Icons.receipt_long_rounded, 'Trip History', Colors.teal, () =>
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const TripsHistoryScreen()))),
                  _divider(),
                  _menuTile(Icons.description_outlined, 'KYC Documents', _blue, () =>
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const KycDocumentsScreen()))),
                  _divider(),
                  _menuTile(Icons.card_giftcard_rounded, 'Refer & Earn', Colors.amber.shade600, () =>
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ReferralScreen()))),
                ]),

                const SizedBox(height: 12),

                _menuCard(children: [
                  _buildDriverLanguageTile(),
                  _divider(),
                  ValueListenableBuilder<ThemeMode>(
                    valueListenable: themeNotifier,
                    builder: (_, mode, __) {
                      final isDark = mode == ThemeMode.dark;
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        leading: Container(
                          width: 38, height: 38,
                          decoration: BoxDecoration(
                            color: Colors.deepPurple.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                              color: Colors.deepPurple, size: 20),
                        ),
                        title: Text(isDark ? 'Dark Mode' : 'Light Mode',
                          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                        subtitle: Text(isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12)),
                        trailing: Switch(
                          value: isDark,
                          onChanged: (val) => saveThemePreference(val ? ThemeMode.dark : ThemeMode.light),
                          activeThumbColor: _blue,
                          trackColor: WidgetStateProperty.all(Colors.white.withValues(alpha: 0.12)),
                        ),
                      );
                    },
                  ),
                  _divider(),
                  _menuTile(Icons.headset_mic_rounded, 'Help & Support', Colors.teal, _showSupportSheet),
                  _divider(),
                  _menuTile(Icons.privacy_tip_rounded, 'Privacy Policy', Colors.grey.shade400, () async {
                    const url = 'https://jagopro.org/privacy';
                    if (await canLaunchUrl(Uri.parse(url))) await launchUrl(Uri.parse(url));
                  }),
                  _divider(),
                  _menuTile(Icons.delete_forever_rounded, 'Delete Account', Colors.red, _showDeleteAccountSheet),
                  _divider(),
                  _menuTile(Icons.logout_rounded, 'Logout', Colors.redAccent, () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        backgroundColor: _surface,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        title: const Text('Logout', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                        content: Text('Are you sure you want to logout?',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.6))),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: Text('Cancel', style: TextStyle(color: Colors.white.withValues(alpha: 0.5)))),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Logout', style: TextStyle(color: Colors.white))),
                        ],
                      ),
                    );
                    if (confirm == true && mounted) {
                      await AuthService.logout();
                      Navigator.pushAndRemoveUntil(context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
                    }
                  }),
                ]),

                const SizedBox(height: 32),
                Center(
                  child: Text('JAGO Pilot v1.0.2 · MindWhile IT Solutions Pvt Ltd',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.15), fontSize: 11)),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Column(children: [
          Text(value, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 10),
            textAlign: TextAlign.center),
        ]),
      ),
    );
  }

  Widget _sectionCard({
    required String title, required IconData icon, required Color iconColor,
    required List<Widget> children,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(children: [
              Icon(icon, color: iconColor, size: 16),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(
                color: Colors.white60, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
            ]),
          ),
          ...children,
          const SizedBox(height: 4),
        ]),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value, {Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      child: Row(children: [
        Icon(icon, size: 16, color: Colors.white.withValues(alpha: 0.3)),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 10)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
        ]),
        if (trailing != null) ...[const Spacer(), trailing],
      ]),
    );
  }

  Widget _buildDriverLanguageTile() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF111827);
    final subtextColor = isDark ? Colors.white54 : Colors.grey.shade500;
    final currentLang = L.supportedLanguages.firstWhere(
      (l) => l['code'] == L.lang,
      orElse: () => L.supportedLanguages.first,
    );
    return ListTile(
      onTap: () => Navigator.push(context,
        MaterialPageRoute(builder: (_) => const LanguageSelectScreen(fromProfile: true))),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Container(
        width: 38, height: 38,
        decoration: BoxDecoration(
          color: const Color(0xFFFF6200).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10)),
        child: const Icon(Icons.translate_rounded, color: Color(0xFFFF6200), size: 20),
      ),
      title: Text('Language / భాష', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textColor)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('${currentLang['flag']} ${currentLang['nativeName']}',
            style: TextStyle(fontSize: 11, color: subtextColor)),
          const SizedBox(width: 4),
          Icon(Icons.chevron_right_rounded, color: subtextColor, size: 20),
        ],
      ),
    );
  }

  Widget _menuCard({required List<Widget> children}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Column(children: children),
      ),
    );
  }

  Widget _menuTile(IconData icon, String label, Color color, VoidCallback onTap) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Container(
        width: 38, height: 38,
        decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
      trailing: Icon(Icons.chevron_right_rounded, color: Colors.white.withValues(alpha: 0.2), size: 20),
    );
  }

  Widget _divider() => Divider(
    height: 1, color: Colors.white.withValues(alpha: 0.04),
    indent: 64, endIndent: 16,
  );
}
