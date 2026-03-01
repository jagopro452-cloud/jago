import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import '../../models/trip_model.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/location_service.dart';
import '../../services/trip_service.dart';
import '../../config/api_config.dart';
import '../trip/trip_screen.dart';
import '../wallet/wallet_screen.dart';
import '../history/trips_history_screen.dart';
import '../profile/profile_screen.dart';
import '../verification/face_verification_screen.dart';
import '../../widgets/incoming_trip_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  UserModel? _user;
  bool _isOnline = false;
  bool _togglingOnline = false;
  GoogleMapController? _mapCtrl;
  LatLng _currentLatLng = const LatLng(17.385044, 78.486671);
  final Set<Marker> _markers = {};
  StreamSubscription? _locationSub;
  Timer? _pollTimer;
  TripModel? _incomingTrip;
  bool _showIncoming = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _initLocation();
    _startPolling();
    _checkFaceVerificationOnStart();
  }

  Future<void> _checkFaceVerificationOnStart() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    try {
      final headers = await AuthService.getHeaders();
      final res = await http.get(Uri.parse(ApiConfig.checkVerification), headers: headers);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['needsVerification'] == true && mounted) {
          _showFaceVerification(data['reason'] ?? 'daily_check');
        }
      }
    } catch (_) {}
  }

  void _showFaceVerification(String reason) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FaceVerificationScreen(
          reason: reason,
          onVerified: () => Navigator.pop(context),
        ),
      ),
    );
  }

  Future<void> _loadProfile() async {
    final user = await AuthService.getProfile();
    if (mounted && user != null) {
      setState(() {
        _user = user;
        _isOnline = user.isOnline;
      });
    }
  }

  Future<void> _initLocation() async {
    final granted = await LocationService.requestPermission();
    if (!granted) return;
    final pos = await LocationService.getCurrentPosition();
    if (pos != null && mounted) {
      setState(() {
        _currentLatLng = LatLng(pos.latitude, pos.longitude);
        _updateDriverMarker(_currentLatLng);
      });
      _mapCtrl?.animateCamera(CameraUpdate.newLatLngZoom(_currentLatLng, 15));
    }
    _locationSub = LocationService.getLocationStream().listen((pos) {
      if (!mounted) return;
      final latlng = LatLng(pos.latitude, pos.longitude);
      setState(() {
        _currentLatLng = latlng;
        _updateDriverMarker(latlng);
      });
      if (_isOnline) {
        LocationService.updateLocation(
          lat: pos.latitude, lng: pos.longitude,
          heading: pos.heading, speed: pos.speed, isOnline: true,
        );
      }
    });
  }

  void _updateDriverMarker(LatLng pos) {
    _markers.removeWhere((m) => m.markerId.value == 'driver');
    _markers.add(Marker(
      markerId: const MarkerId('driver'),
      position: pos,
      infoWindow: const InfoWindow(title: 'You are here'),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
    ));
  }

  void _startPolling() {
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      if (!_isOnline) return;
      final data = await TripService.getIncomingTrip();
      if (!mounted) return;
      if (data['type'] == 'new_trip' || data['tripRequest'] != null) {
        final trip = TripModel.fromJson(data);
        if (!_showIncoming) {
          setState(() { _incomingTrip = trip; _showIncoming = true; });
          _showIncomingSheet(trip);
        }
      } else if (data['type'] == 'active_trip' && data['trip'] != null) {
        final trip = TripModel.fromJson(data);
        if (!mounted) return;
        _pollTimer?.cancel();
        Navigator.push(context, MaterialPageRoute(builder: (_) => TripScreen(trip: trip)));
      }
    });
  }

  void _showIncomingSheet(TripModel trip) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (_) => IncomingTripSheet(
        trip: trip,
        onAccept: () async {
          Navigator.pop(context);
          setState(() => _showIncoming = false);
          final res = await TripService.acceptTrip(trip.id);
          if (res['success'] == true && mounted) {
            _pollTimer?.cancel();
            final accepted = TripModel.fromJson(res);
            Navigator.push(context, MaterialPageRoute(builder: (_) => TripScreen(trip: accepted)));
          }
        },
        onReject: () async {
          Navigator.pop(context);
          setState(() => _showIncoming = false);
          await TripService.rejectTrip(trip.id);
        },
      ),
    ).then((_) => setState(() => _showIncoming = false));
  }

  Future<void> _toggleOnline() async {
    if (_togglingOnline) return;
    setState(() => _togglingOnline = true);
    try {
      final res = await LocationService.setOnlineStatus(!_isOnline);
      if (res['isLocked'] == true) {
        if (!mounted) return;
        _showLockedDialog(res['message'] ?? 'Account locked');
        return;
      }
      if (mounted) setState(() => _isOnline = res['isOnline'] ?? !_isOnline);
    } catch (_) {} finally {
      if (mounted) setState(() => _togglingOnline = false);
    }
  }

  void _showLockedDialog(String msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Account Locked', style: TextStyle(color: Colors.red)),
        content: Text(msg),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
      ),
    );
  }

  @override
  void dispose() {
    _locationSub?.cancel();
    _pollTimer?.cancel();
    _mapCtrl?.dispose();
    super.dispose();
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 1: return const TripsHistoryScreen();
      case 2: return const WalletScreen();
      case 3: return const ProfileScreen();
      default: return _buildHomeMap();
    }
  }

  Widget _buildHomeMap() {
    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(target: _currentLatLng, zoom: 15),
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          markers: _markers,
          mapType: MapType.normal,
          zoomControlsEnabled: false,
          onMapCreated: (ctrl) => _mapCtrl = ctrl,
        ),
        Positioned(
          top: 0, left: 0, right: 0,
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF060D1E), Colors.transparent],
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hello, ${_user?.fullName.split(' ').first ?? 'Driver'} 👋',
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        _isOnline ? '🟢 You are Online' : '🔴 You are Offline',
                        style: TextStyle(
                          color: _isOnline ? const Color(0xFF22C55E) : const Color(0xFF64748B),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: _toggleOnline,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 72,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _isOnline ? const Color(0xFF22C55E) : const Color(0xFF334155),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: _togglingOnline
                        ? const Center(child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)))
                        : AnimatedAlign(
                            duration: const Duration(milliseconds: 300),
                            alignment: _isOnline ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.all(4),
                              width: 28, height: 28,
                              decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          bottom: 100,
          left: 20, right: 20,
          child: Column(
            children: [
              _EarningsCard(user: _user),
              const SizedBox(height: 12),
              if (!_isOnline)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF060D1E).withOpacity(0.9),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF1E3A5F)),
                  ),
                  child: const Text(
                    'Go Online to start receiving trips',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildBody(),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF060D1E),
          border: Border(top: BorderSide(color: Color(0xFF1E3A5F))),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          backgroundColor: Colors.transparent,
          selectedItemColor: const Color(0xFF3B82F6),
          unselectedItemColor: const Color(0xFF475569),
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          selectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.map_outlined), activeIcon: Icon(Icons.map), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.receipt_long_outlined), activeIcon: Icon(Icons.receipt_long), label: 'Trips'),
            BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet_outlined), activeIcon: Icon(Icons.account_balance_wallet), label: 'Wallet'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}

class _EarningsCard extends StatelessWidget {
  final UserModel? user;
  const _EarningsCard({this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF060D1E).withOpacity(0.92),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E3A5F)),
      ),
      child: Row(
        children: [
          _stat('Wallet', '₹${user?.walletBalance.toStringAsFixed(2) ?? '0.00'}', Icons.account_balance_wallet),
          _divider(),
          _stat('Trips', '${user?.stats.completedTrips ?? 0}', Icons.directions_car),
          _divider(),
          _stat('Rating', '${user?.rating.toStringAsFixed(1) ?? '5.0'} ⭐', Icons.star),
        ],
      ),
    );
  }

  Widget _stat(String label, String value, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF3B82F6), size: 20),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 11)),
        ],
      ),
    );
  }

  Widget _divider() => Container(width: 1, height: 40, color: const Color(0xFF1E3A5F));
}
