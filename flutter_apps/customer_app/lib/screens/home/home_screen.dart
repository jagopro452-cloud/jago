import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/api_config.dart';
import '../../services/auth_service.dart';
import '../../services/socket_service.dart';
import '../auth/login_screen.dart';
import '../history/trips_history_screen.dart';
import '../wallet/wallet_screen.dart';
import '../coins/coins_screen.dart';
import '../monthly_pass/monthly_pass_screen.dart';
import '../profile/profile_screen.dart';
import '../booking/booking_screen.dart';
import '../tracking/tracking_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final SocketService _socket = SocketService();
  GoogleMapController? _mapController;
  LatLng _center = const LatLng(17.3850, 78.4867);
  String _userName = 'there';
  String _userPhone = '';
  String _pickup = 'Getting location...';
  String _destination = '';
  double _pickupLat = 17.3850, _pickupLng = 78.4867;
  double _destLat = 0, _destLng = 0;
  int _selectedRide = 0;
  bool _loading = true;
  List<Map<String, dynamic>> _vehicleCategories = [];
  StreamSubscription? _driverAssignedSub;

  static const Color _blue = Color(0xFF1E6DE5);
  static const Color _dark = Color(0xFF111827);
  static const Color _gray = Color(0xFF6B7280);

  static IconData _iconForVehicle(String name, {String? type}) {
    final n = name.toLowerCase();
    if (n.contains('bike parcel') || n.contains('parcel bike')) return Icons.delivery_dining;
    if (n.contains('bike')) return Icons.electric_bike;
    if (n.contains('mini auto') || n.contains('temo auto')) return Icons.electric_rickshaw;
    if (n.contains('auto')) return Icons.electric_rickshaw;
    if (n.contains('suv')) return Icons.directions_car;
    if (n.contains('tata ace') || n.contains('mini cargo')) return Icons.local_shipping;
    if (n.contains('cargo truck')) return Icons.fire_truck;
    if (n.contains('cargo')) return Icons.local_shipping;
    if (n.contains('parcel')) return Icons.delivery_dining;
    if (n.contains('car')) return Icons.directions_car_filled;
    if (type == 'cargo') return Icons.local_shipping;
    if (type == 'parcel') return Icons.delivery_dining;
    return Icons.directions_car;
  }

  @override
  void initState() {
    super.initState();
    _loadUser();
    _getLocation();
    _fetchHome();
    _connectSocket();
    // Check for pending FCM notification (app opened from push while terminated)
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkPendingFcmNotification());
  }

  Future<void> _checkPendingFcmNotification() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pendingStr = prefs.getString('pending_notification');
      if (pendingStr != null && pendingStr.isNotEmpty) {
        await prefs.remove('pending_notification');
        final data = jsonDecode(pendingStr) as Map<String, dynamic>;
        final type = data['type']?.toString() ?? '';
        final tripId = data['tripId']?.toString() ?? '';
        if (!mounted || tripId.isEmpty) return;
        if (type == 'trip_accepted' || type == 'driver_arrived') {
          await Future.delayed(const Duration(milliseconds: 600));
          if (!mounted) return;
          Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => TrackingScreen(tripId: tripId)));
        }
      }
    } catch (_) {}
  }

  void _connectSocket() {
    _socket.connect(ApiConfig.socketUrl).then((_) {
      // If driver assigned while on home screen (unlikely but possible)
      _driverAssignedSub = _socket.onDriverAssigned.listen((data) {
        if (!mounted) return;
        final tripId = data['tripId']?.toString() ?? '';
        if (tripId.isNotEmpty) {
          Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => TrackingScreen(tripId: tripId)));
        }
      });
    });
  }

  @override
  void dispose() {
    _driverAssignedSub?.cancel();
    super.dispose();
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
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) { setState(() => _pickup = 'Current Location'); return; }
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
        if (perm == LocationPermission.denied) { setState(() => _pickup = 'Current Location'); return; }
      }
      if (perm == LocationPermission.deniedForever) { setState(() => _pickup = 'Current Location'); return; }
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _center = LatLng(pos.latitude, pos.longitude);
        _pickupLat = pos.latitude;
        _pickupLng = pos.longitude;
      });
      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(_center, 15));
      _reverseGeocode(pos.latitude, pos.longitude);
    } catch (_) { setState(() => _pickup = 'Current Location'); }
  }

  Future<void> _reverseGeocode(double lat, double lng) async {
    try {
      final url = 'https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lng&key=${ApiConfig.googleMapsApiKey}';
      final res = await http.get(Uri.parse(url));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final results = data['results'] as List<dynamic>?;
        if (results != null && results.isNotEmpty) {
          setState(() => _pickup = results[0]['formatted_address'] ?? 'Current Location');
        }
      }
    } catch (_) {}
  }

  Future<void> _fetchHome() async {
    final token = await AuthService.getToken();
    try {
      final res = await http.get(Uri.parse(ApiConfig.customerHomeData),
        headers: {'Authorization': 'Bearer $token'});
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final cats = (data['vehicleCategories'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
        setState(() {
          _vehicleCategories = cats.isNotEmpty ? cats : _defaultVehicleCategories();
          _loading = false;
        });
      } else {
        setState(() { _vehicleCategories = _defaultVehicleCategories(); _loading = false; });
      }
    } catch (_) { setState(() { _vehicleCategories = _defaultVehicleCategories(); _loading = false; }); }
  }

  List<Map<String, dynamic>> _defaultVehicleCategories() => [
    {'name': 'Bike', 'type': 'ride', 'minimumFare': '20', 'baseFare': '20'},
    {'name': 'Mini Auto', 'type': 'ride', 'minimumFare': '30', 'baseFare': '30'},
    {'name': 'Bike Parcel', 'type': 'parcel', 'minimumFare': '25', 'baseFare': '25'},
    {'name': 'Tata Ace', 'type': 'cargo', 'minimumFare': '200', 'baseFare': '200'},
  ];

  void _bookRide() {
    if (_destination.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Destination enter cheyyandi', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: _blue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
      return;
    }
    final cat = _vehicleCategories.isNotEmpty ? _vehicleCategories[_selectedRide] : null;
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => BookingScreen(
        pickup: _pickup,
        destination: _destination,
        pickupLat: _pickupLat,
        pickupLng: _pickupLng,
        destLat: _destLat,
        destLng: _destLng,
        vehicleCategoryId: cat?['id']?.toString(),
        vehicleCategoryName: cat?['name']?.toString(),
      )));
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
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
              _buildBottomSheet(),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(children: [
        GestureDetector(
          onTap: () => _scaffoldKey.currentState?.openDrawer(),
          child: Container(
            width: 50, height: 50,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.13), blurRadius: 16, offset: const Offset(0, 4))],
            ),
            child: const Icon(Icons.menu_rounded, color: Color(0xFF111827), size: 22),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.13), blurRadius: 16, offset: const Offset(0, 4))],
            ),
            child: Row(children: [
              Image.asset('assets/images/jago_logo.png', height: 22, fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Text('JAGO',
                  style: TextStyle(color: Color(0xFF1E6DE5), fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 2))),
              const SizedBox(width: 12),
              Container(width: 1, height: 20, color: const Color(0xFFE5E7EB)),
              const SizedBox(width: 12),
              Expanded(
                child: Text('Hi, ${_userName.split(' ').first} 👋',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF111827))),
              ),
              Stack(children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.notifications_rounded, color: Color(0xFF1E6DE5), size: 20),
                ),
                Positioned(top: 7, right: 7,
                  child: Container(width: 7, height: 7,
                    decoration: const BoxDecoration(color: Color(0xFFEF4444), shape: BoxShape.circle))),
              ]),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _buildBottomSheet() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
        boxShadow: [BoxShadow(color: Color(0x1A000000), blurRadius: 32, spreadRadius: 2, offset: Offset(0, -6))],
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 44, height: 5,
          margin: const EdgeInsets.only(top: 12, bottom: 18),
          decoration: BoxDecoration(color: const Color(0xFFE5E7EB), borderRadius: BorderRadius.circular(3)),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Where are you going?',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), letterSpacing: -0.3)),
                  const SizedBox(height: 3),
                  Text('Hyderabad & Andhra Pradesh',
                    style: TextStyle(fontSize: 12, color: Colors.grey[400], fontWeight: FontWeight.w500)),
                ]),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFBFDBFE), width: 1),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.schedule_rounded, size: 13, color: Color(0xFF1E6DE5)),
                  const SizedBox(width: 4),
                  const Text('Now', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF1E6DE5))),
                  const SizedBox(width: 3),
                  Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: const Color(0xFF1E6DE5)),
                ]),
              ),
            ]),
            const SizedBox(height: 16),
            _buildLocationCard(),
            const SizedBox(height: 18),
            _buildVehicleSection(),
            const SizedBox(height: 18),
            _buildBookBtn(),
          ]),
        ),
      ]),
    );
  }

  Widget _buildLocationCard() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5EAFF), width: 1),
      ),
      child: Column(children: [
        _locationRow(
          color: _blue,
          icon: Icons.radio_button_checked_rounded,
          label: _pickup,
          hint: 'Current Location',
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(children: [
            Container(width: 1, height: 16, color: Colors.grey.withOpacity(0.25),
              margin: const EdgeInsets.only(left: 7)),
          ]),
        ),
        _locationRow(
          color: const Color(0xFFE53935),
          icon: Icons.location_on_rounded,
          label: _destination,
          hint: 'Where to?',
          onTap: _showDestinationSearch,
          isEditable: true,
        ),
      ]),
    );
  }

  Widget _locationRow({
    required Color color,
    required IconData icon,
    required String label,
    required String hint,
    VoidCallback? onTap,
    bool isEditable = false,
  }) {
    final isEmpty = label.isEmpty;
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isEmpty ? hint : label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isEmpty ? FontWeight.w400 : FontWeight.w600,
                color: isEmpty ? Colors.grey[400] : _dark,
              ),
            ),
          ),
          if (isEditable)
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: _blue.withOpacity(0.08), shape: BoxShape.circle),
              child: Icon(Icons.search_rounded, color: _blue, size: 14),
            ),
        ]),
      ),
    );
  }

  Widget _buildVehicleSection() {
    if (_loading) {
      return const Center(child: SizedBox(height: 80, child: Center(
        child: CircularProgressIndicator(color: Color(0xFF1E6DE5), strokeWidth: 2))));
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Choose Vehicle', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
          color: Colors.grey[500], letterSpacing: 0.5)),
      const SizedBox(height: 10),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(_vehicleCategories.length, (i) {
            return Padding(
              padding: EdgeInsets.only(right: i < _vehicleCategories.length - 1 ? 10 : 0),
              child: _vehicleCard(i, _vehicleCategories[i]),
            );
          }),
        ),
      ),
    ]);
  }

  Widget _vehicleCard(int i, Map<String, dynamic> cat) {
    final selected = _selectedRide == i;
    final name = cat['name']?.toString() ?? '';
    final type = cat['type']?.toString();
    final minFare = double.tryParse(cat['minimumFare']?.toString() ?? '0') ?? 0;
    final fareLabel = minFare > 0 ? '₹${minFare.toInt()}+' : '—';
    return GestureDetector(
      onTap: () => setState(() => _selectedRide = i),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        width: 88,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: selected ? _blue : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? _blue : const Color(0xFFE5E9F5),
            width: selected ? 0 : 1.5,
          ),
          boxShadow: selected ? [BoxShadow(
            color: _blue.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))] : [],
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(_iconForVehicle(name, type: type),
            color: selected ? Colors.white : Colors.grey[600], size: 28),
          const SizedBox(height: 6),
          Text(name,
            textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
              color: selected ? Colors.white : _dark, height: 1.3)),
          const SizedBox(height: 3),
          Text(fareLabel,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800,
              color: selected ? Colors.white.withOpacity(0.9) : _blue)),
        ]),
      ),
    );
  }

  Widget _buildBookBtn() {
    final selected = _selectedRide < _vehicleCategories.length ? _vehicleCategories[_selectedRide] : null;
    final hasDestination = _destination.isNotEmpty;
    return GestureDetector(
      onTap: _bookRide,
      child: Container(
        width: double.infinity,
        height: 58,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: hasDestination
              ? [const Color(0xFF1565C0), const Color(0xFF1E6DE5), const Color(0xFF1565C0)]
              : [const Color(0xFF94A3B8), const Color(0xFF64748B)],
            begin: Alignment.centerLeft, end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: hasDestination ? [BoxShadow(
            color: const Color(0xFF1E6DE5).withOpacity(0.45),
            blurRadius: 20, offset: const Offset(0, 6),
          )] : [],
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), shape: BoxShape.circle),
            child: const Icon(Icons.search_rounded, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Find Ride', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 0.3)),
            if (selected != null)
              Text('${selected['name'] ?? ''} · ${selected['minimumFare'] != null ? '₹${selected['minimumFare']}+' : '--'}',
                style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11, fontWeight: FontWeight.w500)),
          ]),
          const SizedBox(width: 12),
          const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
        ]),
      ),
    );
  }

  void _showDestinationSearch() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _PlaceSearchSheet(
        pickupLat: _pickupLat,
        pickupLng: _pickupLng,
        onPlaceSelected: (name, lat, lng) {
          setState(() {
            _destination = name;
            _destLat = lat;
            _destLng = lng;
          });
        },
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Container(
        color: const Color(0xFF111827),
        child: SafeArea(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1E6DE5), Color(0xFF1244A2)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  child: Text(_userName.isNotEmpty ? _userName[0].toUpperCase() : 'U',
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(_userName,
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text('+91 $_userPhone',
                    style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6)),
                    child: const Text('JAGO Customer',
                      style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
                  ),
                ])),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Divider(color: Colors.white.withOpacity(0.08), height: 1),
            ),
            const SizedBox(height: 8),
            _drawerItem(Icons.directions_bike_rounded, 'My Rides', () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const TripsHistoryScreen()));
            }),
            _drawerItem(Icons.account_balance_wallet_rounded, 'Payments & Wallet', () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const WalletScreen()));
            }),
            _drawerItem(Icons.stars_rounded, 'JAGO Coins', () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const CoinsScreen()));
            }),
            _drawerItem(Icons.card_membership_rounded, 'Monthly Pass', () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const MonthlyPassScreen()));
            }),
            _drawerItem(Icons.person_rounded, 'Profile', () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
            }),
            _drawerItem(Icons.headset_mic_rounded, 'Support', () {}),
            _drawerItem(Icons.card_giftcard_rounded, 'Refer & Earn', () {}),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: GestureDetector(
                onTap: () async {
                  await AuthService.logout();
                  if (!mounted) return;
                  Navigator.pushAndRemoveUntil(context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.withOpacity(0.2), width: 1),
                  ),
                  child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.logout_rounded, color: Color(0xFFF87171), size: 18),
                    SizedBox(width: 8),
                    Text('Logout', style: TextStyle(color: Color(0xFFF87171), fontWeight: FontWeight.w700, fontSize: 14)),
                  ]),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Center(child: Text('v1.0.0 • MindWhile IT Solutions',
                style: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 10))),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _drawerItem(IconData icon, String label, VoidCallback onTap) {
    return ListTile(
      leading: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: _blue.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: _blue, size: 18),
      ),
      title: Text(label, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
      trailing: Icon(Icons.chevron_right, color: Colors.white.withOpacity(0.2), size: 18),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
    );
  }
}

// ── Google Places Search Sheet ──────────────────────────────────────────────
class _PlaceSearchSheet extends StatefulWidget {
  final double pickupLat, pickupLng;
  final Function(String name, double lat, double lng) onPlaceSelected;
  const _PlaceSearchSheet({required this.pickupLat, required this.pickupLng, required this.onPlaceSelected});
  @override
  State<_PlaceSearchSheet> createState() => _PlaceSearchSheetState();
}

class _PlaceSearchSheetState extends State<_PlaceSearchSheet> {
  final _ctrl = TextEditingController();
  List<Map<String, dynamic>> _predictions = [];
  bool _searching = false;
  Timer? _debounce;

  static const Color _blue = Color(0xFF1E6DE5);

  @override
  void dispose() { _ctrl.dispose(); _debounce?.cancel(); super.dispose(); }

  void _onChanged(String q) {
    _debounce?.cancel();
    if (q.length < 2) { setState(() => _predictions = []); return; }
    _debounce = Timer(const Duration(milliseconds: 400), () => _search(q));
  }

  Future<void> _search(String q) async {
    setState(() => _searching = true);
    try {
      final url = 'https://maps.googleapis.com/maps/api/place/autocomplete/json'
        '?input=${Uri.encodeComponent(q)}'
        '&location=${widget.pickupLat},${widget.pickupLng}'
        '&radius=50000&components=country:in'
        '&key=${ApiConfig.googleMapsApiKey}';
      final res = await http.get(Uri.parse(url));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final preds = (data['predictions'] as List<dynamic>? ?? [])
          .map((p) => {
            'placeId': p['place_id'],
            'description': p['description'],
            'mainText': p['structured_formatting']?['main_text'] ?? p['description'],
            'secondaryText': p['structured_formatting']?['secondary_text'] ?? '',
          }).toList();
        if (mounted) setState(() => _predictions = preds.cast<Map<String, dynamic>>());
      }
    } catch (_) {}
    if (mounted) setState(() => _searching = false);
  }

  Future<void> _selectPlace(Map<String, dynamic> place) async {
    try {
      final placeId = place['placeId'];
      final url = 'https://maps.googleapis.com/maps/api/geocode/json?place_id=$placeId&key=${ApiConfig.googleMapsApiKey}';
      final res = await http.get(Uri.parse(url));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final results = data['results'] as List<dynamic>?;
        if (results != null && results.isNotEmpty) {
          final loc = results[0]['geometry']['location'];
          if (mounted) Navigator.pop(context);
          widget.onPlaceSelected(place['description'],
            (loc['lat'] as num).toDouble(), (loc['lng'] as num).toDouble());
          return;
        }
      }
    } catch (_) {}
    if (mounted) {
      Navigator.pop(context);
      widget.onPlaceSelected(place['description'], 0, 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 40, height: 4,
          margin: const EdgeInsets.only(top: 10, bottom: 16),
          decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(2))),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Where to?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF111827))),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF5F7FA),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE5EAFF), width: 1),
              ),
              child: TextField(
                controller: _ctrl,
                autofocus: true,
                onChanged: _onChanged,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF111827)),
                decoration: InputDecoration(
                  hintText: 'Search destination...',
                  hintStyle: TextStyle(color: Colors.grey[400], fontWeight: FontWeight.w400),
                  prefixIcon: Icon(Icons.search_rounded, color: _blue, size: 22),
                  suffixIcon: _searching
                    ? const Padding(padding: EdgeInsets.all(14),
                        child: SizedBox(width: 18, height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1E6DE5))))
                    : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 8),
        ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.5),
          child: _predictions.isEmpty
            ? Padding(
                padding: const EdgeInsets.all(40),
                child: Column(children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _blue.withOpacity(0.06),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.location_on_outlined, color: _blue.withOpacity(0.4), size: 40),
                  ),
                  const SizedBox(height: 16),
                  Text('Start typing to search', textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[400], fontSize: 14, fontWeight: FontWeight.w500)),
                ]))
            : ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                itemCount: _predictions.length,
                separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey[100]),
                itemBuilder: (_, i) {
                  final p = _predictions[i];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                    leading: Container(
                      width: 38, height: 38,
                      decoration: BoxDecoration(
                        color: _blue.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.location_on_rounded, color: Color(0xFF1E6DE5), size: 18)),
                    title: Text(p['mainText'] ?? '',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF111827))),
                    subtitle: (p['secondaryText'] ?? '') != ''
                      ? Text(p['secondaryText'],
                          style: TextStyle(color: Colors.grey[500], fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis)
                      : null,
                    onTap: () => _selectPlace(p),
                  );
                }),
        ),
      ]),
    );
  }
}
