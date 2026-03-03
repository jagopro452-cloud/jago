import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
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
import '../notifications/notifications_screen.dart';
import '../booking/intercity_booking_screen.dart';
import '../coins/spin_wheel_screen.dart';
import '../scheduled/scheduled_rides_screen.dart';
import '../lost_found/lost_found_screen.dart';
import '../offers/offers_screen.dart';
import '../profile/support_chat_screen.dart';
import '../referral/referral_screen.dart';
import '../saved_places/saved_places_screen.dart';
import '../booking/parcel_booking_screen.dart';
import '../car_sharing/car_sharing_screen.dart';
import '../../services/trip_service.dart';
import '../../services/localization_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final SocketService _socket = SocketService();

  String _userName = 'there';
  String _userPhone = '';
  String _pickup = 'Getting location...';
  double _pickupLat = 17.3850, _pickupLng = 78.4867;
  bool _loading = true;
  int _unreadNotifCount = 0;
  List<Map<String, dynamic>> _vehicleCategories = [];
  List<Map<String, dynamic>> _services = [];
  List<dynamic> _banners = [];
  List<dynamic> _savedPlaces = [];
  StreamSubscription? _driverAssignedSub;
  int _navIndex = 0;

  static const Color _yellow = Color(0xFFFBBC04);
  static const Color _dark = Color(0xFF1A1A1A);
  static const Color _gray = Color(0xFF6B7280);
  static const Color _lightBg = Color(0xFFF5F5F5);
  static const Color _cardBg = Color(0xFFF0F0F0);
  static const Color _jagoBrand = Color(0xFF1B4DCC);

  @override
  void initState() {
    super.initState();
    _loadUser();
    _getLocation();
    _fetchHome();
    _fetchUnreadCount();
    _loadSavedPlaces();
    _connectSocket();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkPendingFcmNotification());
  }

  Future<void> _fetchUnreadCount() async {
    try {
      final token = await AuthService.getToken();
      final r = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/app/notifications?limit=1'),
        headers: {'Authorization': 'Bearer $token'});
      if (r.statusCode == 200 && mounted) {
        final data = jsonDecode(r.body);
        setState(() => _unreadNotifCount = (data['unreadCount'] as int?) ?? 0);
      }
    } catch (_) {}
  }

  Future<void> _loadSavedPlaces() async {
    try {
      final places = await TripService.getSavedPlaces();
      if (mounted) setState(() => _savedPlaces = places.where((p) => p['label'] == 'Home' || p['label'] == 'Work').toList());
    } catch (_) {}
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
        _pickupLat = pos.latitude;
        _pickupLng = pos.longitude;
      });
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
        if (results != null && results.isNotEmpty && mounted) {
          setState(() => _pickup = results[0]['formatted_address'] ?? 'Current Location');
        }
      }
    } catch (_) {}
  }

  Future<void> _fetchHome() async {
    final token = await AuthService.getToken();
    try {
      final results = await Future.wait([
        http.get(Uri.parse(ApiConfig.customerHomeData), headers: {'Authorization': 'Bearer $token'}),
        http.get(Uri.parse('${ApiConfig.baseUrl}/api/app/services'), headers: {'Authorization': 'Bearer $token'}),
      ]);
      if (results[0].statusCode == 200) {
        final data = jsonDecode(results[0].body) as Map<String, dynamic>;
        final cats = (data['vehicleCategories'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
        if (mounted) setState(() {
          _vehicleCategories = cats.isNotEmpty ? cats : _defaultVehicleCategories();
          _banners = (data['banners'] as List<dynamic>?) ?? [];
        });
      } else {
        if (mounted) setState(() => _vehicleCategories = _defaultVehicleCategories());
      }
      if (results[1].statusCode == 200) {
        final sData = jsonDecode(results[1].body) as Map<String, dynamic>;
        final svcList = (sData['services'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
        if (mounted) setState(() => _services = svcList.isNotEmpty ? svcList : _defaultServices());
      } else {
        if (mounted) setState(() => _services = _defaultServices());
      }
    } catch (_) {
      if (mounted) setState(() {
        _vehicleCategories = _defaultVehicleCategories();
        _services = _defaultServices();
      });
    }
    if (mounted) setState(() => _loading = false);
  }

  List<Map<String, dynamic>> _defaultServices() => [
    {'key': 'ride', 'name': 'Normal Ride', 'description': 'Bike, Auto, Car, SUV', 'emoji': '🚕', 'color': '#1E6DE5', 'isActive': true},
    {'key': 'parcel', 'name': 'Parcel', 'description': 'Send packages fast', 'emoji': '📦', 'color': '#F59E0B', 'isActive': true},
    {'key': 'cargo', 'name': 'Cargo', 'description': 'Truck & van delivery', 'emoji': '🚛', 'color': '#10B981', 'isActive': true},
    {'key': 'intercity', 'name': 'Intercity', 'description': 'City to city travel', 'emoji': '🛣️', 'color': '#8B5CF6', 'isActive': true},
    {'key': 'carsharing', 'name': 'Car Sharing', 'description': 'Share rides & costs', 'emoji': '🚘', 'color': '#EF4444', 'isActive': true},
  ];

  List<Map<String, dynamic>> _defaultVehicleCategories() => [
    {'name': 'Auto', 'type': 'ride', 'minimumFare': '30', 'baseFare': '30'},
    {'name': 'Bike', 'type': 'ride', 'minimumFare': '20', 'baseFare': '20'},
    {'name': 'Car', 'type': 'ride', 'minimumFare': '80', 'baseFare': '80'},
    {'name': 'Parcel', 'type': 'parcel', 'minimumFare': '25', 'baseFare': '25'},
  ];

  void _openSearch({String? presetVehicle}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _PlaceSearchSheet(
        pickupLat: _pickupLat,
        pickupLng: _pickupLng,
        onPlaceSelected: (name, lat, lng) {
          final cat = presetVehicle != null
            ? _vehicleCategories.firstWhere(
                (c) => c['name'].toString().toLowerCase().contains(presetVehicle.toLowerCase()),
                orElse: () => _vehicleCategories.isNotEmpty ? _vehicleCategories[0] : {},
              )
            : (_vehicleCategories.isNotEmpty ? _vehicleCategories[0] : null);
          Navigator.push(context, MaterialPageRoute(
            builder: (_) => BookingScreen(
              pickup: _pickup,
              destination: name,
              pickupLat: _pickupLat,
              pickupLng: _pickupLng,
              destLat: lat != 0 ? lat : 17.3850,
              destLng: lng != 0 ? lng : 78.4867,
              vehicleCategoryId: cat?['id']?.toString(),
              vehicleCategoryName: cat?['name']?.toString(),
            ),
          ));
        },
      ),
    );
  }

  void _showAllServicesSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _AllServicesSheet(
        vehicleCategories: _vehicleCategories,
        pickup: _pickup,
        pickupLat: _pickupLat,
        pickupLng: _pickupLng,
        onServiceTap: (cat) {
          Navigator.pop(ctx);
          if (cat['type'] == 'parcel') {
            Navigator.push(context, MaterialPageRoute(
              builder: (_) => ParcelBookingScreen(
                pickupAddress: _pickup, pickupLat: _pickupLat, pickupLng: _pickupLng)));
          } else {
            _openSearchWithCategory(cat);
          }
        },
      ),
    );
  }

  void _openSearchWithCategory(Map<String, dynamic> cat) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _PlaceSearchSheet(
        pickupLat: _pickupLat,
        pickupLng: _pickupLng,
        onPlaceSelected: (name, lat, lng) {
          Navigator.push(context, MaterialPageRoute(
            builder: (_) => BookingScreen(
              pickup: _pickup,
              destination: name,
              pickupLat: _pickupLat,
              pickupLng: _pickupLng,
              destLat: lat != 0 ? lat : 17.3850,
              destLng: lng != 0 ? lng : 78.4867,
              vehicleCategoryId: cat['id']?.toString(),
              vehicleCategoryName: cat['name']?.toString(),
            ),
          ));
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: Colors.white,
        drawer: _buildDrawer(),
        body: SafeArea(
          child: Column(children: [
            _buildTopSearchBar(),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  if (_savedPlaces.isNotEmpty) _buildRecentPlaces(),
                  _buildEverythingSection(),
                  _buildExploreSection(),
                  _buildInAHurryCard(),
                  _buildGoPlacesBanner(),
                  const SizedBox(height: 20),
                ]),
              ),
            ),
            _buildBottomNav(),
          ]),
        ),
      ),
    );
  }

  // ── Top Search Bar (JAGO branded) ──────────────────────────────────────────
  Widget _buildTopSearchBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          GestureDetector(
            onTap: () => _scaffoldKey.currentState?.openDrawer(),
            child: const Icon(Icons.menu_rounded, size: 26, color: _dark),
          ),
          const SizedBox(width: 10),
          // JAGO Logo
          RichText(text: const TextSpan(
            children: [
              TextSpan(text: 'JA', style: TextStyle(
                fontSize: 22, fontWeight: FontWeight.w900, color: _jagoBrand, letterSpacing: -0.5)),
              TextSpan(text: 'GO', style: TextStyle(
                fontSize: 22, fontWeight: FontWeight.w900, color: _yellow, letterSpacing: -0.5)),
            ],
          )),
          const Spacer(),
          if (_pickup.isNotEmpty && _pickup != 'Getting location...')
            Flexible(
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.location_on, size: 14, color: _jagoBrand),
                const SizedBox(width: 3),
                Flexible(child: Text(
                  _pickup.split(',').first,
                  style: TextStyle(fontSize: 12, color: Colors.grey[700], fontWeight: FontWeight.w500),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                )),
              ]),
            ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => const NotificationsScreen()))
              .then((_) => _fetchUnreadCount()),
            child: Stack(children: [
              const Icon(Icons.notifications_outlined, color: _dark, size: 26),
              if (_unreadNotifCount > 0)
                Positioned(top: 0, right: 0,
                  child: Container(
                    width: 9, height: 9,
                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                  )),
            ]),
          ),
        ]),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: _openSearch,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: _lightBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey[200]!, width: 1),
            ),
            child: Row(children: [
              const Icon(Icons.search, color: _dark, size: 22),
              const SizedBox(width: 12),
              Text('Where are you going?',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.grey[500])),
            ]),
          ),
        ),
      ]),
    );
  }

  // ── Recent Places ──────────────────────────────────────────────────────────
  Widget _buildRecentPlaces() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Column(
        children: _savedPlaces.take(3).map((p) {
          final label = p['label'] ?? '';
          final address = p['address'] ?? '';
          final isHome = label == 'Home';
          return GestureDetector(
            onTap: () {
              final destLat = double.tryParse(p['lat']?.toString() ?? '0') ?? 0;
              final destLng = double.tryParse(p['lng']?.toString() ?? '0') ?? 0;
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => BookingScreen(
                  pickup: _pickup,
                  destination: address,
                  pickupLat: _pickupLat, pickupLng: _pickupLng,
                  destLat: destLat != 0 ? destLat : 17.3850,
                  destLng: destLng != 0 ? destLng : 78.4867,
                ),
              ));
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey[100]!, width: 1)),
              ),
              child: Row(children: [
                Icon(Icons.history, color: Colors.grey[500], size: 20),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(isHome ? label : address,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: _dark),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                  if (isHome)
                    Text(address,
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ])),
                Icon(Icons.favorite_border, color: Colors.grey[400], size: 20),
              ]),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Everything In Minutes — Rapido-style 2×2 Grid ──────────────────────────
  Widget _buildEverythingSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Everything In Minutes',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _dark)),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: _buildGridCard(
            topLabel: 'Send anything',
            boldLabel: 'Parcel',
            emoji: '📦',
            onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => ParcelBookingScreen(
                pickupAddress: _pickup, pickupLat: _pickupLat, pickupLng: _pickupLng))),
          )),
          const SizedBox(width: 12),
          Expanded(child: _buildGridCard(
            topLabel: 'Beat the traffic',
            boldLabel: 'Bike Taxi',
            emoji: '🏍️',
            bigEmoji: true,
            onTap: () => _openSearch(presetVehicle: 'bike'),
          )),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _buildGridCard(
            topLabel: 'Your everyday rides',
            boldLabel: 'Book now',
            emoji: '🛺',
            bigEmoji: true,
            onTap: () => _openSearch(presetVehicle: 'auto'),
          )),
          const SizedBox(width: 12),
          Expanded(child: _buildGridCard(
            topLabel: '',
            boldLabel: 'All\nServices',
            emoji: '📋',
            onTap: _showAllServicesSheet,
          )),
        ]),
      ]),
    );
  }

  Widget _buildGridCard({
    required String topLabel,
    required String boldLabel,
    required String emoji,
    required VoidCallback onTap,
    bool bigEmoji = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 112,
        padding: const EdgeInsets.fromLTRB(14, 14, 8, 10),
        decoration: BoxDecoration(
          color: _lightBg,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
              if (topLabel.isNotEmpty) ...[
                Text(topLabel,
                  style: TextStyle(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.w400)),
                const SizedBox(height: 5),
              ],
              Text(boldLabel,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: _dark, height: 1.2)),
            ]),
          ),
          Align(
            alignment: bigEmoji ? Alignment.bottomRight : Alignment.center,
            child: Text(emoji,
              style: TextStyle(fontSize: bigEmoji ? 44 : 36)),
          ),
        ]),
      ),
    );
  }

  void _handleServiceTap(String key) {
    switch (key) {
      case 'ride':
        _openSearch();
        break;
      case 'parcel':
      case 'cargo':
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => ParcelBookingScreen(
            pickupAddress: _pickup, pickupLat: _pickupLat, pickupLng: _pickupLng)));
        break;
      case 'intercity':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const IntercityBookingScreen()));
        break;
      case 'carsharing':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const CarSharingScreen()));
        break;
      default:
        _openSearch();
    }
  }

  // ── Explore Section — horizontal vehicle icons (Rapido style) ────────────
  Widget _buildExploreSection() {
    final allVehicles = _vehicleCategories.isNotEmpty
      ? _vehicleCategories.take(4).toList()
      : [
          {'name': 'Shared Auto', 'type': 'ride', 'minimumFare': '20'},
          {'name': 'Bike', 'type': 'ride', 'minimumFare': '18'},
          {'name': 'Auto', 'type': 'ride', 'minimumFare': '25'},
          {'name': 'Parcel', 'type': 'parcel', 'minimumFare': '30'},
        ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 26, 16, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Explore', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _dark)),
          GestureDetector(
            onTap: _showAllServicesSheet,
            child: Row(children: [
              Text('View All', style: TextStyle(fontSize: 13, color: Colors.grey[700], fontWeight: FontWeight.w600)),
              Icon(Icons.chevron_right, size: 18, color: Colors.grey[600]),
            ]),
          ),
        ]),
        const SizedBox(height: 16),
        Row(
          children: allVehicles.map((cat) {
            final name = cat['name']?.toString() ?? '';
            final isParcel = cat['type'] == 'parcel' || name.toLowerCase().contains('parcel');
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  if (isParcel) {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (_) => ParcelBookingScreen(
                        pickupAddress: _pickup, pickupLat: _pickupLat, pickupLng: _pickupLng)));
                  } else {
                    _openSearchWithCategory(cat);
                  }
                },
                child: Column(children: [
                  Container(
                    width: 68, height: 68,
                    decoration: BoxDecoration(
                      color: _lightBg,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Center(
                      child: Text(_emojiForVehicle(name),
                        style: const TextStyle(fontSize: 32))),
                  ),
                  const SizedBox(height: 8),
                  Text(name,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _dark),
                    textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
                ]),
              ),
            );
          }).toList(),
        ),
      ]),
    );
  }

  // ── In a Hurry? Card (Rapido style) ───────────────────────────────────────
  Widget _buildInAHurryCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 28, 16, 0),
      child: GestureDetector(
        onTap: () => _openSearch(presetVehicle: 'auto'),
        child: Container(
          height: 100,
          decoration: BoxDecoration(
            color: _lightBg,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(children: [
            const SizedBox(width: 18),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                const Text('In a hurry?',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _dark)),
                const SizedBox(height: 4),
                Text('An auto will arrive in 5 mins.',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                const SizedBox(height: 10),
                Text('Book Now',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                    color: _jagoBrand, decoration: TextDecoration.underline,
                    decorationColor: _jagoBrand)),
              ]),
            ),
            // Right side: auto emoji + yellow badge
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(right: Radius.circular(16)),
              child: Container(
                width: 130,
                color: _yellow.withOpacity(0.12),
                child: Stack(children: [
                  const Center(child: Text('🛺', style: TextStyle(fontSize: 52))),
                  Positioned(
                    top: 10, right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                      decoration: BoxDecoration(
                        color: _yellow,
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [BoxShadow(color: _yellow.withOpacity(0.4), blurRadius: 6)],
                      ),
                      child: const Column(mainAxisSize: MainAxisSize.min, children: [
                        Text('5 MIN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.black)),
                        Text('AUTO', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: Colors.black54)),
                      ]),
                    ),
                  ),
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  // ── Go Places Banner (#goJAGO — Rapido style) ─────────────────────────────
  Widget _buildGoPlacesBanner() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (_banners.isNotEmpty) Padding(
        padding: const EdgeInsets.fromLTRB(16, 28, 16, 0),
        child: _buildBannerCard(),
      ),
      const SizedBox(height: 28),
      // #goJAGO watermark section
      Stack(children: [
        // Faded background illustration
        Positioned.fill(
          child: Opacity(
            opacity: 0.04,
            child: Icon(Icons.directions_car_filled, size: 200, color: _dark),
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Column(children: [
            Text('#goJAGO',
              style: TextStyle(
                fontSize: 32, fontWeight: FontWeight.w900,
                color: Colors.grey[300], letterSpacing: 2,
                fontStyle: FontStyle.italic,
              )),
            const SizedBox(height: 16),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Text('🇮🇳', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Text('Made for India', style: TextStyle(fontSize: 13, color: Colors.grey[500], fontWeight: FontWeight.w500)),
            ]),
            const SizedBox(height: 6),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Text('❤️', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
              Text('MindWhile IT Solutions', style: TextStyle(fontSize: 13, color: Colors.grey[500], fontWeight: FontWeight.w500)),
            ]),
          ]),
        ),
      ]),
    ]);
  }

  Widget _buildBannerCard() {
    final banner = _banners[0] as Map<String, dynamic>;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(banner['title']?.toString() ?? 'Special Offer',
              style: const TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            if (banner['description'] != null)
              Text(banner['description'].toString(),
                style: const TextStyle(fontSize: 12, color: Color(0xFFFBBC04), fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('Book Now ➤',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ]),
        ),
        const SizedBox(width: 12),
        const Text('🚗', style: TextStyle(fontSize: 50)),
      ]),
    );
  }

  // ── Bottom Navigation (Rapido style: Ride | All Services | Travel | Profile)
  Widget _buildBottomNav() {
    final items = [
      {'icon': Icons.home_filled, 'label': 'Ride'},
      {'icon': Icons.grid_view_rounded, 'label': 'All Services'},
      {'icon': Icons.beach_access_rounded, 'label': 'Travel'},
      {'icon': Icons.person_outline_rounded, 'label': 'Profile'},
    ];
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[200]!, width: 1)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, -2))],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: List.generate(items.length, (i) {
            final isSelected = _navIndex == i;
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() => _navIndex = i);
                  if (i == 0) {
                    // Ride - stay on home
                  } else if (i == 1) {
                    // All Services - show bottom sheet
                    _showAllServicesSheet();
                    Future.delayed(const Duration(milliseconds: 50), () {
                      if (mounted) setState(() => _navIndex = 0);
                    });
                  } else if (i == 2) {
                    // Travel - intercity
                    Navigator.push(context, MaterialPageRoute(
                      builder: (_) => const IntercityBookingScreen()))
                      .then((_) => setState(() => _navIndex = 0));
                  } else if (i == 3) {
                    // Profile
                    Navigator.push(context, MaterialPageRoute(
                      builder: (_) => const ProfileScreen()))
                      .then((_) => setState(() => _navIndex = 0));
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  color: Colors.transparent,
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(items[i]['icon'] as IconData,
                      color: isSelected ? _jagoBrand : Colors.grey[400],
                      size: 24),
                    const SizedBox(height: 3),
                    Text(items[i]['label'] as String,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                        color: isSelected ? _jagoBrand : Colors.grey[400],
                      )),
                  ]),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  // ── Emoji helper ────────────────────────────────────────────────────────────
  String _emojiForVehicle(String name) {
    final n = name.toLowerCase();
    if (n.contains('parcel') || n.contains('delivery')) return '📦';
    if (n.contains('bike')) return '🏍️';
    if (n.contains('auto') || n.contains('rickshaw') || n.contains('temo')) return '🛺';
    if (n.contains('suv') || n.contains('premium')) return '🚙';
    if (n.contains('car') || n.contains('cab')) return '🚗';
    if (n.contains('truck') || n.contains('cargo')) return '🚛';
    if (n.contains('share') || n.contains('pool')) return '🚐';
    return '🚗';
  }

  // ── Drawer ──────────────────────────────────────────────────────────────────
  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: const Color(0xFF0A0F1E),
      child: SafeArea(
        child: ListView(children: [
          // JAGO Header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_jagoBrand.withOpacity(0.9), const Color(0xFF0A0F1E)],
                begin: Alignment.topLeft, end: Alignment.bottomRight),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // JAGO logo
              RichText(text: const TextSpan(children: [
                TextSpan(text: 'JA', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                TextSpan(text: 'GO', style: TextStyle(color: Color(0xFFFBBC04), fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
              ])),
              const SizedBox(height: 20),
              Row(children: [
                Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
                  ),
                  child: Center(
                    child: Text((_userName.isNotEmpty ? _userName[0] : 'U').toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(_userName,
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 3),
                  Text(_userPhone,
                    style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13)),
                ])),
              ]),
            ]),
          ),
          _drawerItem(Icons.person_outline_rounded, 'Profile', () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
          }),
          _drawerItem(Icons.account_balance_wallet_rounded, 'Wallet', () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (_) => const WalletScreen()));
          }),
          _drawerItem(Icons.history_rounded, 'My Trips', () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (_) => const TripsHistoryScreen()));
          }),
          _drawerItem(Icons.stars_rounded, 'JAGO Coins', () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (_) => const CoinsScreen()));
          }),
          _drawerItem(Icons.calendar_month_rounded, 'Monthly Pass', () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (_) => const MonthlyPassScreen()));
          }),
          _drawerItem(Icons.local_offer_rounded, 'Offers & Coupons', () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (_) => const OffersScreen()));
          }),
          _drawerItem(Icons.casino_rounded, 'Daily Spin', () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (_) => const SpinWheelScreen()));
          }),
          _drawerItem(Icons.share_rounded, 'Refer & Earn', () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (_) => const ReferralScreen()));
          }),
          _drawerItem(Icons.place_rounded, 'Saved Places', () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (_) => const SavedPlacesScreen()));
          }),
          _drawerItem(Icons.headset_mic_rounded, 'Support Chat', () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (_) => const SupportChatScreen()));
          }),
          _drawerItem(Icons.find_in_page_rounded, 'Lost & Found', () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (_) => const LostFoundScreen()));
          }),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: GestureDetector(
              onTap: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    backgroundColor: const Color(0xFF1E293B),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    title: const Text('Logout', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                    content: const Text('Are you sure you want to logout?',
                      style: TextStyle(color: Colors.white70)),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context, false),
                        child: Text('Cancel', style: TextStyle(color: Colors.white.withOpacity(0.5)))),
                      TextButton(onPressed: () => Navigator.pop(context, true),
                        child: const Text('Logout', style: TextStyle(color: Color(0xFFF87171), fontWeight: FontWeight.w700))),
                    ],
                  ),
                );
                if (confirmed == true && mounted) {
                  await AuthService.logout();
                  if (mounted) Navigator.pushAndRemoveUntil(context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.red.withOpacity(0.3), width: 1),
                  borderRadius: BorderRadius.circular(12),
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
            padding: const EdgeInsets.only(bottom: 16, top: 8),
            child: Center(child: Text('v1.0.0 • MindWhile IT Solutions',
              style: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 10))),
          ),
        ]),
      ),
    );
  }

  Widget _drawerItem(IconData icon, String label, VoidCallback onTap) {
    return ListTile(
      leading: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Colors.white.withOpacity(0.7), size: 18),
      ),
      title: Text(label, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
      trailing: Icon(Icons.chevron_right, color: Colors.white.withOpacity(0.15), size: 18),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
    );
  }
}

// ── All Services Bottom Sheet ─────────────────────────────────────────────────
class _AllServicesSheet extends StatelessWidget {
  final List<Map<String, dynamic>> vehicleCategories;
  final String pickup;
  final double pickupLat, pickupLng;
  final Function(Map<String, dynamic>) onServiceTap;

  const _AllServicesSheet({
    required this.vehicleCategories,
    required this.pickup,
    required this.pickupLat,
    required this.pickupLng,
    required this.onServiceTap,
  });

  String _emoji(String name) {
    final n = name.toLowerCase();
    if (n.contains('parcel') || n.contains('delivery')) return '📦';
    if (n.contains('bike lite')) return '🛵';
    if (n.contains('bike')) return '🏍️';
    if (n.contains('shared') || n.contains('share')) return '🚐';
    if (n.contains('temo') || n.contains('mini auto')) return '🛺';
    if (n.contains('auto') || n.contains('rickshaw')) return '🛺';
    if (n.contains('premium')) return '⭐';
    if (n.contains('suv')) return '🚙';
    if (n.contains('car') || n.contains('cab')) return '🚗';
    if (n.contains('truck') || n.contains('cargo')) return '🚛';
    if (n.contains('travel')) return '🌴';
    return '🚗';
  }

  @override
  Widget build(BuildContext context) {
    final cats = vehicleCategories.isNotEmpty
      ? vehicleCategories
      : [
          {'name': 'Auto', 'type': 'ride'},
          {'name': 'Bike', 'type': 'ride'},
          {'name': 'Car', 'type': 'ride'},
          {'name': 'Parcel', 'type': 'parcel'},
        ];

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Drag handle
        Container(
          width: 40, height: 4,
          margin: const EdgeInsets.only(top: 12, bottom: 4),
          decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(2)),
        ),
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 16, 0),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('All services',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A))),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 18, color: Color(0xFF1A1A1A)),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 20,
              crossAxisSpacing: 8,
              childAspectRatio: 0.85,
            ),
            itemCount: cats.length,
            itemBuilder: (_, i) {
              final cat = cats[i];
              final name = cat['name']?.toString() ?? '';
              return GestureDetector(
                onTap: () => onServiceTap(cat),
                child: Column(children: [
                  Container(
                    width: 62, height: 62,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F0F0),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(_emoji(name), style: const TextStyle(fontSize: 28)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(name,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A)),
                    textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
                ]),
              );
            },
          ),
        ),
      ]),
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
        Container(
          width: 40, height: 4,
          margin: const EdgeInsets.only(top: 10, bottom: 16),
          decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(2))),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Where to?',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A))),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _ctrl,
                autofocus: true,
                onChanged: _onChanged,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xFF1A1A1A)),
                decoration: InputDecoration(
                  hintText: 'Search destination...',
                  hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontWeight: FontWeight.w400),
                  prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF6B7280), size: 22),
                  suffixIcon: _searching
                    ? const Padding(padding: EdgeInsets.all(14),
                        child: SizedBox(width: 18, height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2)))
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
                  Icon(Icons.location_on_outlined, color: Colors.grey[300], size: 48),
                  const SizedBox(height: 12),
                  Text('Start typing to search',
                    textAlign: TextAlign.center,
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
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.location_on_rounded, color: Color(0xFF6B7280), size: 18)),
                    title: Text(p['mainText'] ?? '',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF1A1A1A))),
                    subtitle: (p['secondaryText'] ?? '') != ''
                      ? Text(p['secondaryText'],
                          style: TextStyle(color: Colors.grey[500], fontSize: 12),
                          maxLines: 1, overflow: TextOverflow.ellipsis)
                      : null,
                    onTap: () => _selectPlace(p),
                  );
                }),
        ),
      ]),
    );
  }
}
