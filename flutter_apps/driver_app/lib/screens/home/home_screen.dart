import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/api_config.dart';
import '../../services/auth_service.dart';
import '../../services/trip_service.dart';
import '../../widgets/incoming_trip_sheet.dart';
import '../auth/login_screen.dart';
import '../wallet/wallet_screen.dart';
import '../history/trips_history_screen.dart';
import '../profile/profile_screen.dart';
import '../break_mode/break_mode_screen.dart';
import '../trip/trip_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  GoogleMapController? _mapController;
  LatLng _center = const LatLng(12.9716, 77.5946);
  bool _isOnline = false;
  bool _loading = false;
  bool _toggling = false;
  String _userName = 'Pilot';
  String _userPhone = '';
  double _walletBalance = 0;
  int _tripsToday = 0;
  double _earningsToday = 0;
  Map<String, dynamic>? _incomingTrip;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _getLocation();
    _fetchDashboard();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('user_name') ?? 'Pilot';
      _userPhone = prefs.getString('user_phone') ?? '';
    });
  }

  Future<void> _getLocation() async {
    try {
      await Geolocator.requestPermission();
      final pos = await Geolocator.getCurrentPosition();
      setState(() => _center = LatLng(pos.latitude, pos.longitude));
      _mapController?.animateCamera(CameraUpdate.newLatLng(_center));
    } catch (_) {}
  }

  Future<void> _fetchDashboard() async {
    final token = await AuthService.getToken();
    try {
      final res = await http.get(Uri.parse(ApiConfig.driverDashboard),
        headers: {'Authorization': 'Bearer $token'});
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          _isOnline = data['isOnline'] ?? false;
          _walletBalance = (data['walletBalance'] ?? 0).toDouble();
          _tripsToday = data['tripsToday'] ?? 0;
          _earningsToday = (data['earningsToday'] ?? 0).toDouble();
        });
        if (_isOnline) _startPolling();
      }
    } catch (_) {}
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 8), (_) => _checkIncomingTrip());
  }

  Future<void> _checkIncomingTrip() async {
    final token = await AuthService.getToken();
    try {
      final res = await http.get(Uri.parse(ApiConfig.driverIncomingTrip),
        headers: {'Authorization': 'Bearer $token'});
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['trip'] != null && _incomingTrip == null) {
          setState(() => _incomingTrip = data['trip']);
          _showIncomingTrip();
        }
      }
    } catch (_) {}
  }

  void _showIncomingTrip() {
    if (_incomingTrip == null) return;
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (_) => IncomingTripSheet(
        trip: _incomingTrip!,
        onAccept: () {
          Navigator.pop(context);
          setState(() => _incomingTrip = null);
          Navigator.push(context, MaterialPageRoute(builder: (_) => const TripScreen()));
        },
        onReject: () {
          Navigator.pop(context);
          setState(() => _incomingTrip = null);
        },
      ),
    );
  }

  Future<void> _toggleOnline() async {
    setState(() => _toggling = true);
    final token = await AuthService.getToken();
    try {
      final res = await http.post(Uri.parse(ApiConfig.driverOnlineStatus),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: jsonEncode({'isOnline': !_isOnline, 'lat': _center.latitude, 'lng': _center.longitude}));
      if (res.statusCode == 200) {
        setState(() => _isOnline = !_isOnline);
        if (_isOnline) _startPolling();
        else _pollTimer?.cancel();
      }
    } catch (_) {}
    setState(() => _toggling = false);
  }

  @override
  void dispose() { _pollTimer?.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildDrawer(),
      body: Stack(children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(target: _center, zoom: 14),
          onMapCreated: (c) => _mapController = c,
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
        ),
        SafeArea(
          child: Column(children: [
            _buildTopBar(),
            const Spacer(),
            _buildBottomPanel(),
          ]),
        ),
      ]),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(children: [
        GestureDetector(
          onTap: () => _scaffoldKey.currentState?.openDrawer(),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF060D1E), borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 8)],
            ),
            child: const Icon(Icons.menu, color: Colors.white, size: 22),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF060D1E), borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 8)],
            ),
            child: Row(children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isOnline ? Colors.green : Colors.grey)),
              const SizedBox(width: 8),
              Text(_isOnline ? 'Online — Ready for trips' : 'Offline',
                style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13, fontWeight: FontWeight.w500)),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _buildBottomPanel() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF060D1E), borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 20)],
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Row(children: [
          _statCard('Today', '₹${_earningsToday.toStringAsFixed(0)}', Icons.account_balance_wallet_outlined),
          const SizedBox(width: 12),
          _statCard('Trips', '$_tripsToday', Icons.route_outlined),
          const SizedBox(width: 12),
          _statCard('Wallet', '₹${_walletBalance.toStringAsFixed(0)}', Icons.savings_outlined),
        ]),
        const SizedBox(height: 20),
        GestureDetector(
          onTap: _toggling ? null : _toggleOnline,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: double.infinity, height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _isOnline
                  ? [const Color(0xFF16A34A), const Color(0xFF15803D)]
                  : [const Color(0xFF2563EB), const Color(0xFF1D4ED8)],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(
                color: (_isOnline ? const Color(0xFF16A34A) : const Color(0xFF2563EB)).withOpacity(0.3),
                blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: Center(
              child: _toggling
                ? const SizedBox(width: 22, height: 22,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(_isOnline ? Icons.stop_circle_outlined : Icons.play_circle_outline,
                      color: Colors.white, size: 22),
                    const SizedBox(width: 10),
                    Text(_isOnline ? 'Go Offline' : 'Go Online',
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                  ]),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _actionBtn(Icons.coffee_outlined, 'Break', () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const BreakModeScreen()));
          })),
          const SizedBox(width: 12),
          Expanded(child: _actionBtn(Icons.location_on_outlined, 'My Location', _getLocation)),
        ]),
      ]),
    );
  }

  Widget _statCard(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06), borderRadius: BorderRadius.circular(12)),
        child: Column(children: [
          Icon(icon, color: const Color(0xFF2563EB), size: 20),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          Text(label, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11)),
        ]),
      ),
    );
  }

  Widget _actionBtn(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06), borderRadius: BorderRadius.circular(12)),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: Colors.white.withOpacity(0.7), size: 18),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13, fontWeight: FontWeight.w500)),
        ]),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Container(
        color: const Color(0xFF0D1B4B),
        child: SafeArea(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(children: [
                CircleAvatar(
                  radius: 28, backgroundColor: const Color(0xFF2563EB),
                  child: Text(_userName.isNotEmpty ? _userName[0].toUpperCase() : 'P',
                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Hi, ${_userName.split(' ').first}!',
                    style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
                  Text('+91-$_userPhone',
                    style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6)),
                    child: const Text('Driver',
                      style: TextStyle(color: Color(0xFF2563EB), fontSize: 10, fontWeight: FontWeight.w700)),
                  ),
                ])),
              ]),
            ),
            const Divider(color: Colors.white12, height: 1),
            const SizedBox(height: 8),
            _drawerItem(Icons.route_outlined, 'My Trips', () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const TripsHistoryScreen()));
            }),
            _drawerItem(Icons.account_balance_wallet_outlined, 'Wallet', () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const WalletScreen()));
            }),
            _drawerItem(Icons.person_outline, 'Profile', () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
            }),
            _drawerItem(Icons.headset_mic_outlined, 'Support', () {}),
            _drawerItem(Icons.card_giftcard_outlined, 'Refer & Earn', () {}),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity, height: 46,
                child: OutlinedButton.icon(
                  onPressed: () async { await AuthService.logout(); if (!mounted) return;
                    Navigator.pushAndRemoveUntil(context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false); },
                  icon: const Icon(Icons.logout, size: 18, color: Colors.redAccent),
                  label: const Text('Logout', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.redAccent, width: 1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text('v1.0.2 • MindWhile IT Solutions',
                style: TextStyle(color: Colors.white.withOpacity(0.25), fontSize: 11)),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _drawerItem(IconData icon, String label, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.white.withOpacity(0.7), size: 22),
      title: Text(label, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500)),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 2),
    );
  }
}
