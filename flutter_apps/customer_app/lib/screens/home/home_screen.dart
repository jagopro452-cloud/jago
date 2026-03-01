import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/api_config.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';
import '../history/trips_history_screen.dart';
import '../wallet/wallet_screen.dart';
import '../coins/coins_screen.dart';
import '../monthly_pass/monthly_pass_screen.dart';
import '../profile/profile_screen.dart';
import '../booking/booking_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  GoogleMapController? _mapController;
  LatLng _center = const LatLng(12.9716, 77.5946);
  String _userName = 'there';
  String _userPhone = '';
  String _pickup = 'Current Location';
  String _destination = '';
  int _selectedRide = 0;
  Map<String, dynamic>? _homeData;
  bool _loading = true;

  final List<Map<String, dynamic>> _rideTypes = [
    {'icon': Icons.electric_bike, 'label': 'Bike', 'price': '₹EA'},
    {'icon': Icons.directions_car, 'label': 'Car', 'price': '₹ER'},
    {'icon': Icons.delivery_dining, 'label': 'Delivery', 'price': '₹55'},
  ];

  @override
  void initState() {
    super.initState();
    _loadUser();
    _getLocation();
    _fetchHome();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('user_name') ?? 'there';
      _userPhone = prefs.getString('user_phone') ?? '';
    });
  }

  Future<void> _getLocation() async {
    try {
      final perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied) return;
      final pos = await Geolocator.getCurrentPosition();
      setState(() => _center = LatLng(pos.latitude, pos.longitude));
      _mapController?.animateCamera(CameraUpdate.newLatLng(_center));
    } catch (_) {}
  }

  Future<void> _fetchHome() async {
    final token = await AuthService.getToken();
    try {
      final res = await http.get(Uri.parse(ApiConfig.customerHomeData),
        headers: {'Authorization': 'Bearer $token'});
      if (res.statusCode == 200) {
        setState(() { _homeData = jsonDecode(res.body); _loading = false; });
      }
    } catch (_) { setState(() => _loading = false); }
  }

  void _bookRide() {
    if (_destination.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter destination'), backgroundColor: Color(0xFF1E6DE5)));
      return;
    }
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => BookingScreen(pickup: _pickup, destination: _destination)));
  }

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
            _buildBottomCard(),
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
              color: Colors.white, borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: const Icon(Icons.menu, color: Color(0xFF1A1A2E), size: 22),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Row(children: [
              Expanded(
                child: Text('Hi ${_userName.split(' ').first} 👋',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Color(0xFF1A1A2E))),
              ),
              const Icon(Icons.notifications_none, color: Color(0xFF1E6DE5), size: 22),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _buildBottomCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 20, offset: const Offset(0, -4))],
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        _locationRow(Icons.location_on, const Color(0xFF1E6DE5), _pickup, 'Current Location'),
        const Padding(padding: EdgeInsets.only(left: 11), child: Divider(height: 12)),
        _locationRow(Icons.location_searching, Colors.grey, _destination, 'Where to?', onTap: _showDestinationDialog),
        const SizedBox(height: 16),
        Row(children: [
          for (int i = 0; i < _rideTypes.length; i++) ...[
            if (i > 0) const SizedBox(width: 10),
            Expanded(child: _rideTypeCard(i)),
          ],
        ]),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity, height: 50,
          child: ElevatedButton(
            onPressed: _bookRide,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E6DE5),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: const Text('Continue', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ),
      ]),
    );
  }

  Widget _locationRow(IconData icon, Color color, String value, String hint, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Row(children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(value.isEmpty ? hint : value,
            style: TextStyle(
              fontSize: 14, fontWeight: FontWeight.w500,
              color: value.isEmpty ? Colors.grey[400] : const Color(0xFF1A1A2E),
            )),
        ),
        if (value.isNotEmpty) Icon(Icons.edit_outlined, size: 16, color: Colors.grey[400]),
      ]),
    );
  }

  Widget _rideTypeCard(int i) {
    final ride = _rideTypes[i];
    final selected = _selectedRide == i;
    return GestureDetector(
      onTap: () => setState(() => _selectedRide = i),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF1E6DE5) : const Color(0xFFF5F7FA),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? const Color(0xFF1E6DE5) : Colors.transparent, width: 1.5),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(ride['icon'] as IconData,
            color: selected ? Colors.white : Colors.grey[600], size: 26),
          const SizedBox(height: 4),
          Text(ride['label'] as String,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
              color: selected ? Colors.white : Colors.grey[700])),
          Text(ride['price'] as String,
            style: TextStyle(fontSize: 11,
              color: selected ? Colors.white.withOpacity(0.85) : Colors.grey[500])),
        ]),
      ),
    );
  }

  void _showDestinationDialog() {
    final ctrl = TextEditingController(text: _destination);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          left: 24, right: 24, top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          const Text('Where to?',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
          const SizedBox(height: 16),
          TextField(
            controller: ctrl,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Enter destination',
              prefixIcon: const Icon(Icons.location_searching, color: Color(0xFF1E6DE5)),
              filled: true, fillColor: const Color(0xFFF5F7FA),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, height: 50,
            child: ElevatedButton(
              onPressed: () {
                setState(() => _destination = ctrl.text);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E6DE5), foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
              child: const Text('Confirm', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            )),
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
                  radius: 28, backgroundColor: const Color(0xFF1E6DE5),
                  child: Text(_userName.isNotEmpty ? _userName[0].toUpperCase() : 'U',
                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Hi, ${_userName.split(' ').first}!',
                    style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
                  Text('+91-$_userPhone',
                    style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13)),
                ])),
                IconButton(
                  icon: Icon(Icons.logout, color: Colors.white.withOpacity(0.5), size: 20),
                  onPressed: () => _logout(),
                ),
              ]),
            ),
            const Divider(color: Colors.white12, height: 1),
            const SizedBox(height: 8),
            _drawerItem(Icons.directions_bike, 'My Rides', () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const TripsHistoryScreen()));
            }),
            _drawerItem(Icons.account_balance_wallet, 'Payments', () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const WalletScreen()));
            }),
            _drawerItem(Icons.stars_rounded, 'JAGO Coins', () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const CoinsScreen()));
            }),
            _drawerItem(Icons.card_membership, 'Monthly Pass', () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const MonthlyPassScreen()));
            }),
            _drawerItem(Icons.person_outline, 'Profile', () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
            }),
            _drawerItem(Icons.headset_mic_outlined, 'Support', () {}),
            _drawerItem(Icons.card_giftcard_outlined, 'Refer & Earn', () {},
              badge: const Text('₹', style: TextStyle(color: Colors.white, fontSize: 11))),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text('JAGO v1.0.2\nMindWhile IT Solutions',
                style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 11)),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _drawerItem(IconData icon, String label, VoidCallback onTap, {Widget? badge}) {
    return ListTile(
      leading: Icon(icon, color: Colors.white.withOpacity(0.75), size: 22),
      title: Text(label, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500)),
      trailing: badge,
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 2),
    );
  }

  Future<void> _logout() async {
    await AuthService.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(context,
      MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
  }
}
