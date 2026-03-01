import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../services/auth_service.dart';
import '../../services/trip_service.dart';
import '../booking/booking_screen.dart';
import '../tracking/tracking_screen.dart';
import '../wallet/wallet_screen.dart';
import '../history/trips_history_screen.dart';
import '../profile/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _idx = 0;
  Map<String, dynamic>? _user;
  GoogleMapController? _mapCtrl;
  LatLng _currentLatLng = const LatLng(17.385044, 78.486671);
  final Set<Marker> _markers = {};
  Timer? _activeTripTimer;
  bool _checkingActive = false;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _initLocation();
    _checkActiveTrip();
    _activeTripTimer = Timer.periodic(const Duration(seconds: 10), (_) => _checkActiveTrip());
  }

  Future<void> _loadUser() async {
    final u = await AuthService.getProfile();
    if (mounted && u != null) setState(() => _user = u['user'] ?? u);
  }

  Future<void> _initLocation() async {
    bool srv = await Geolocator.isLocationServiceEnabled();
    if (!srv) return;
    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
    if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) return;
    final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    if (mounted) {
      setState(() {
        _currentLatLng = LatLng(pos.latitude, pos.longitude);
        _markers.add(Marker(markerId: const MarkerId('me'), position: _currentLatLng, infoWindow: const InfoWindow(title: 'You')));
      });
      _mapCtrl?.animateCamera(CameraUpdate.newLatLngZoom(_currentLatLng, 15));
    }
  }

  Future<void> _checkActiveTrip() async {
    if (_checkingActive) return;
    _checkingActive = true;
    try {
      final data = await TripService.getActiveTrip();
      if (data['activeTrip'] != null && mounted) {
        _activeTripTimer?.cancel();
        Navigator.push(context, MaterialPageRoute(builder: (_) => TrackingScreen(tripData: data['activeTrip']))).then((_) {
          _activeTripTimer = Timer.periodic(const Duration(seconds: 10), (_) => _checkActiveTrip());
        });
      }
    } catch (_) {}
    _checkingActive = false;
  }

  @override
  void dispose() { _activeTripTimer?.cancel(); _mapCtrl?.dispose(); super.dispose(); }

  Widget _buildBody() {
    switch (_idx) {
      case 1: return const TripsHistoryScreen();
      case 2: return const WalletScreen();
      case 3: return const ProfileScreen();
      default: return _buildHomeTab();
    }
  }

  Widget _buildHomeTab() {
    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(target: _currentLatLng, zoom: 15),
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          markers: _markers,
          onMapCreated: (c) => _mapCtrl = c,
        ),
        Positioned(
          top: 0, left: 0, right: 0,
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 52, 20, 16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
                colors: [Colors.white, Color(0xF0FFFFFF), Colors.transparent],
              ),
            ),
            child: Column(
              children: [
                Row(children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Good day! 👋', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                        Text(_user?['fullName']?.toString().split(' ').first ?? 'Rider', style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 18)),
                      ],
                    ),
                  ),
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFBFDBFE))),
                    child: const Icon(Icons.notifications_outlined, color: Color(0xFF2563EB), size: 20),
                  ),
                ]),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: _openBooking,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4))],
                    ),
                    child: const Row(children: [
                      Icon(Icons.search, color: Color(0xFF2563EB), size: 22),
                      SizedBox(width: 10),
                      Text('Where are you going?', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 15)),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          bottom: 100, left: 20, right: 20,
          child: Column(
            children: [
              Row(children: [
                _quickAction(Icons.home, 'Home', _openBooking),
                const SizedBox(width: 10),
                _quickAction(Icons.work, 'Work', _openBooking),
                const SizedBox(width: 10),
                _quickAction(Icons.favorite, 'Saved', _openBooking),
              ]),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _openBooking,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF1D4ED8), Color(0xFF3B82F6)]),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [BoxShadow(color: const Color(0xFF2563EB).withOpacity(0.3), blurRadius: 16)],
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.directions_car, color: Colors.white),
                      SizedBox(width: 8),
                      Text('Book a Ride', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          right: 20, bottom: 180,
          child: Column(children: [
            _mapBtn(Icons.my_location, _initLocation),
            const SizedBox(height: 8),
            _mapBtn(Icons.add, () => _mapCtrl?.animateCamera(CameraUpdate.zoomIn())),
            const SizedBox(height: 8),
            _mapBtn(Icons.remove, () => _mapCtrl?.animateCamera(CameraUpdate.zoomOut())),
          ]),
        ),
      ],
    );
  }

  Widget _quickAction(IconData icon, String label, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8)]),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, color: const Color(0xFF2563EB), size: 18),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13, fontWeight: FontWeight.w600)),
          ]),
        ),
      ),
    );
  }

  Widget _mapBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8)]),
        child: Icon(icon, color: const Color(0xFF2563EB), size: 20),
      ),
    );
  }

  void _openBooking() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => BookingScreen(currentLatLng: _currentLatLng))).then((_) => _checkActiveTrip());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildBody(),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Color(0xFFE2E8F0)))),
        child: BottomNavigationBar(
          currentIndex: _idx,
          onTap: (i) => setState(() => _idx = i),
          backgroundColor: Colors.transparent,
          selectedItemColor: const Color(0xFF2563EB),
          unselectedItemColor: const Color(0xFF94A3B8),
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          selectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.receipt_long_outlined), activeIcon: Icon(Icons.receipt_long), label: 'Trips'),
            BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet_outlined), activeIcon: Icon(Icons.account_balance_wallet), label: 'Wallet'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}
