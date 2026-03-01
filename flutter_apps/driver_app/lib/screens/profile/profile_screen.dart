import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';
import '../performance/performance_screen.dart';
import '../kyc/kyc_documents_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _name = '';
  String _phone = '';
  double _rating = 5.0;
  int _totalTrips = 0;
  bool _loading = true;

  @override
  void initState() { super.initState(); _loadProfile(); }

  Future<void> _loadProfile() async {
    final data = await AuthService.getProfile();
    setState(() {
      _name = data?['fullName'] ?? 'Driver';
      _phone = data?['phone'] ?? '';
      _rating = (data?['rating'] ?? 5.0).toDouble();
      _totalTrips = data?['stats']?['completedTrips'] ?? 0;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060D1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF060D1E), elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.white.withOpacity(0.7)),
          onPressed: () => Navigator.pop(context)),
        title: const Text('Profile', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: _loading ? const Center(child: CircularProgressIndicator(color: Color(0xFF2563EB)))
        : SingleChildScrollView(
          child: Column(children: [
            Container(
              color: const Color(0xFF0D1B4B),
              padding: const EdgeInsets.all(24),
              child: Column(children: [
                CircleAvatar(
                  radius: 42, backgroundColor: const Color(0xFF2563EB),
                  child: Text(_name.isNotEmpty ? _name[0].toUpperCase() : 'P',
                    style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 12),
                Text(_name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                Text('+91-$_phone', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14)),
                const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  _badge(Icons.star_rounded, Colors.amber, _rating.toStringAsFixed(1)),
                  const SizedBox(width: 16),
                  _badge(Icons.route, const Color(0xFF2563EB), '$_totalTrips trips'),
                ]),
              ]),
            ),
            const SizedBox(height: 2),
            _section([
              _tile(Icons.bar_chart, 'Performance', const Color(0xFF2563EB), () =>
                Navigator.push(context, MaterialPageRoute(builder: (_) => const PerformanceScreen()))),
              _tile(Icons.description_outlined, 'KYC Documents', const Color(0xFF2563EB), () =>
                Navigator.push(context, MaterialPageRoute(builder: (_) => const KycDocumentsScreen()))),
            ]),
            const SizedBox(height: 2),
            _section([
              _tile(Icons.headset_mic_outlined, 'Support', Colors.teal, () {}),
              _tile(Icons.logout, 'Logout', Colors.redAccent, () async {
                await AuthService.logout();
                if (!mounted) return;
                Navigator.pushAndRemoveUntil(context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
              }),
            ]),
            const SizedBox(height: 32),
            Text('JAGO Pilot v1.0.2 • MindWhile IT Solutions',
              style: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 12)),
            const SizedBox(height: 24),
          ]),
        ),
    );
  }

  Widget _badge(IconData icon, Color color, String label) {
    return Row(children: [
      Icon(icon, color: color, size: 16),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
    ]);
  }

  Widget _section(List<Widget> tiles) {
    return Container(color: const Color(0xFF0D1B4B), child: Column(children: tiles));
  }

  Widget _tile(IconData icon, String label, Color color, VoidCallback onTap) {
    return ListTile(
      leading: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: color, size: 20)),
      title: Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.white)),
      trailing: Icon(Icons.chevron_right, color: Colors.white.withOpacity(0.3), size: 20),
      onTap: onTap,
    );
  }
}
