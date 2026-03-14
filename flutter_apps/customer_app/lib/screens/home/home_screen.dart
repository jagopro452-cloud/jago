import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/api_config.dart';
import '../../services/auth_service.dart';
import '../../services/socket_service.dart';
import '../history/trips_history_screen.dart';
import '../wallet/wallet_screen.dart';
import '../profile/profile_screen.dart';
import '../booking/booking_screen.dart';
import '../tracking/tracking_screen.dart';
import '../notifications/notifications_screen.dart';
import '../booking/intercity_booking_screen.dart';
import '../offers/offers_screen.dart';
import '../profile/support_chat_screen.dart';
import '../referral/referral_screen.dart';
import '../saved_places/saved_places_screen.dart';
import '../booking/parcel_booking_screen.dart';
import '../booking/voice_booking_screen.dart';
import '../../services/trip_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final SocketService _socket = SocketService();

  String _userName = 'there';
  String _userPhone = '';
  String _pickup = 'Getting location...';
  double _pickupLat = 17.3850, _pickupLng = 78.4867;
  int _unreadNotifCount = 0;
  double _walletBalance = 0;
  List<Map<String, dynamic>> _vehicleCategories = [];
  List<Map<String, dynamic>> _activeServices = [];
  List<dynamic> _savedPlaces = [];
  List<Map<String, dynamic>> _recentTrips = [];
  Map<String, dynamic>? _activeTrip;
  StreamSubscription? _driverAssignedSub;
  int _navIndex = 0;

  // Brand colors
  static const Color _primary = Color(0xFF2F80ED);
  static const Color _secondary = Color(0xFF56CCF2);
  static const Color _lightAccent = Color(0xFF86D5F5);
  static const Color _darkBg = Color(0xFF0F172A);
  static const Color _darkCard = Color(0xFF1E293B);
  static const Color _lightBg = Color(0xFFFFFFFF);
  static const Color _lightCard = Color(0xFFF5F8FF);

  @override
  void initState() {
    super.initState();
    _loadUser();
    _getLocation();
    _fetchHome();
    _fetchActiveServices();
    _fetchUnreadCount();
    _fetchWalletBalance();
    _loadSavedPlaces();
    _loadRecentTrips();
    _connectSocket();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkPendingFcmNotification());
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkActiveTrip());
  }

  Future<void> _fetchUnreadCount() async {
    try {
      final headers = await AuthService.getHeaders();
      final r = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/app/notifications?limit=1'),
        headers: headers);
      if (r.statusCode == 200 && mounted) {
        final data = jsonDecode(r.body);
        setState(() => _unreadNotifCount = (data['unreadCount'] as int?) ?? 0);
      }
    } catch (_) {}
  }

  Future<void> _fetchWalletBalance() async {
    try {
      final headers = await AuthService.getHeaders();
      final r = await http.get(Uri.parse(ApiConfig.wallet), headers: headers);
      if (r.statusCode == 200 && mounted) {
        final data = jsonDecode(r.body);
        setState(() => _walletBalance = (data['balance'] ?? 0).toDouble());
      }
    } catch (_) {}
  }

  Future<void> _loadSavedPlaces() async {
    try {
      final places = await TripService.getSavedPlaces();
      if (mounted) setState(() => _savedPlaces = places.where((p) => p['label'] == 'Home' || p['label'] == 'Work').toList());
    } catch (_) {}
  }

  Future<void> _loadRecentTrips() async {
    try {
      final headers = await AuthService.getHeaders();
      final r = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/app/customer/trips?limit=3&status=completed'),
        headers: headers);
      if (r.statusCode == 200 && mounted) {
        final data = jsonDecode(r.body);
        final trips = (data['trips'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
        setState(() => _recentTrips = trips);
      }
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
          // Verify trip is still active — prevents stale FCM from causing blank screen
          try {
            final verifyHeaders = await AuthService.getHeaders();
            final tripCheck = await http.get(Uri.parse(ApiConfig.activeTrip), headers: verifyHeaders);
            if (tripCheck.statusCode == 200) {
              final td = jsonDecode(tripCheck.body);
              final activeT = td['trip'] as Map<String, dynamic>?;
              if (activeT == null) return;
              final st = activeT['currentStatus']?.toString() ?? '';
              if (st == 'completed' || st == 'cancelled' || st.isEmpty) return;
            } else {
              return;
            }
          } catch (_) { return; }
          if (!mounted) return;
          Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => TrackingScreen(tripId: tripId)));
        }
      }
    } catch (_) {}
  }

  Future<void> _checkActiveTrip() async {
    try {
      final headers = await AuthService.getHeaders();
      final r = await http.get(Uri.parse(ApiConfig.activeTrip),
        headers: headers);
      if (r.statusCode == 200 && mounted) {
        final data = jsonDecode(r.body);
        final trip = data['trip'] as Map<String, dynamic>?;
        if (trip != null) {
          final status = trip['currentStatus']?.toString() ?? '';
          if (status != 'completed' && status != 'cancelled') {
            setState(() => _activeTrip = trip);
          }
        }
      }
    } catch (_) {}
  }

  void _connectSocket() {
    _socket.connect(ApiConfig.socketUrl).then((_) {
      // IMPORTANT: Delay subscription by 2.5 seconds to avoid stale socket
      // events from previous sessions causing immediate navigation away from home
      Future.delayed(const Duration(milliseconds: 2500), () {
        if (!mounted) return;
        _driverAssignedSub = _socket.onDriverAssigned.listen((data) {
          if (!mounted) return;
          final tripId = data['tripId']?.toString() ?? '';
          // Only navigate if the tripId matches our current active trip context
          // This prevents stale socket events from navigating incorrectly
          if (tripId.isNotEmpty) {
            final activeTripId = _activeTrip?['id']?.toString() ?? '';
            // Only navigate if we have a confirmed active trip matching this event.
            // Prevents stale socket events from causing blank-screen navigation on login.
            if (activeTripId.isNotEmpty && activeTripId == tripId) {
              Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (_) => TrackingScreen(tripId: tripId)));
            }
          }
        });
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
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
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
    try {
      final headers = await AuthService.getHeaders();
      final results = await Future.wait([
        http.get(Uri.parse(ApiConfig.customerHomeData), headers: headers),
        http.get(Uri.parse('${ApiConfig.baseUrl}/api/app/services'), headers: headers),
      ]);
      if (results[0].statusCode == 200) {
        final data = jsonDecode(results[0].body) as Map<String, dynamic>;
        final cats = (data['vehicleCategories'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
        if (mounted) setState(() {
          _vehicleCategories = cats.isNotEmpty ? cats : _defaultVehicleCategories();
        });
      } else {
        if (mounted) setState(() => _vehicleCategories = _defaultVehicleCategories());
      }
      // Service payload currently not used in UI; request kept for warm backend cache/health.
      if (results[1].statusCode == 200) {
        jsonDecode(results[1].body) as Map<String, dynamic>;
      }
    } catch (_) {
      if (mounted) setState(() {
        _vehicleCategories = _defaultVehicleCategories();
      });
    }
  }

  List<Map<String, dynamic>> _defaultVehicleCategories() => [
    {'name': 'Auto', 'type': 'ride', 'minimumFare': '30', 'baseFare': '30'},
    {'name': 'Bike', 'type': 'ride', 'minimumFare': '20', 'baseFare': '20'},
    {'name': 'Car', 'type': 'ride', 'minimumFare': '80', 'baseFare': '80'},
    {'name': 'Parcel', 'type': 'parcel', 'minimumFare': '25', 'baseFare': '25'},
  ];

  Future<void> _fetchActiveServices() async {
    try {
      final headers = await AuthService.getHeaders();
      final r = await http.get(Uri.parse(ApiConfig.activeServices), headers: headers);
      if (r.statusCode == 200 && mounted) {
        final data = jsonDecode(r.body) as Map<String, dynamic>;
        final services = (data['services'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
        setState(() => _activeServices = services);
      }
    } catch (_) {}
  }

  /// Map a service key to its default emoji and color fallback.
  Map<String, dynamic> _serviceDefaults(String key) {
    switch (key) {
      case 'bike_ride':
      case 'bike_taxi':
      case 'bike':
        return {'emoji': '🏍️', 'color': _primary};
      case 'auto_ride':
      case 'auto':
        return {'emoji': '🛺', 'color': const Color(0xFFF59E0B)};
      case 'parcel_delivery':
      case 'parcel':
        return {'emoji': '📦', 'color': const Color(0xFFF97316)};
      case 'cargo':
      case 'cargo_freight':
        return {'emoji': '🚛', 'color': const Color(0xFF10B981)};
      case 'mini_car':
      case 'car':
        return {'emoji': '🚗', 'color': const Color(0xFF8B5CF6)};
      case 'sedan':
        return {'emoji': '🚗', 'color': const Color(0xFF6366F1)};
      default:
        return {'emoji': '🚖', 'color': _primary};
    }
  }

  Color _colorFromHex(String? hex, Color fallback) {
    if (hex == null || hex.isEmpty) return fallback;
    try {
      final h = hex.replaceAll('#', '');
      return Color(int.parse('FF$h', radix: 16));
    } catch (_) { return fallback; }
  }

  void _openSearch({String? presetVehicle}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
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
      backgroundColor: Theme.of(context).cardColor,
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
      backgroundColor: Theme.of(context).cardColor,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = isDark ? _darkBg : _lightBg;
    final cardBg = isDark ? _darkCard : _lightCard;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: scaffoldBg,
      drawer: _buildDrawer(isDark),
      body: SafeArea(
        child: Column(children: [
          _buildTopBar(isDark, cardBg, textColor),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (_activeTrip != null)
                  _buildActiveTripBanner(isDark),
                _buildGreetingCard(isDark, textColor),
                _buildSearchBar(isDark, cardBg, textColor),
                _buildServiceGrid(isDark, cardBg, textColor),
                _buildExploreSection(isDark, cardBg, textColor),
                if (_recentTrips.isNotEmpty || _savedPlaces.isNotEmpty)
                  _buildRecentSection(isDark, cardBg, textColor),
                _buildEverythingSection(isDark, cardBg, textColor),
                _buildInAHurryCard(isDark),
                _buildParcelPromoBanner(isDark, cardBg, textColor),
                _buildGoPlacesBanner(isDark),
                const SizedBox(height: 20),
              ]),
            ),
          ),
          _buildBottomNav(isDark, cardBg, textColor),
        ]),
      ),
    );
  }

  // ── TOP BAR ──────────────────────────────────────────────────────────────
  Widget _buildTopBar(bool isDark, Color cardBg, Color textColor) {
    return Container(
      color: isDark ? _darkBg : _lightBg,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Row(children: [
        GestureDetector(
          onTap: () => _scaffoldKey.currentState?.openDrawer(),
          child: Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: isDark ? _darkCard : _lightCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFDCE9FF)),
            ),
            child: Icon(Icons.menu_rounded, size: 20, color: textColor),
          ),
        ),
        const SizedBox(width: 12),
        // Location indicator
        Expanded(
          child: Row(children: [
            const Icon(Icons.location_on_rounded, color: _primary, size: 14),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                _pickup == 'Getting location...' ? 'Getting location...' : _pickup.split(',').first,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: textColor.withValues(alpha: 0.75),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ]),
        ),
        // Wallet balance
        if (_walletBalance > 0) ...[
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WalletScreen())),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.account_balance_wallet_rounded, color: Color(0xFF10B981), size: 13),
                const SizedBox(width: 4),
                Text(
                  '₹${_walletBalance.toStringAsFixed(0)}',
                  style: GoogleFonts.poppins(color: const Color(0xFF10B981), fontSize: 12, fontWeight: FontWeight.w800),
                ),
              ]),
            ),
          ),
          const SizedBox(width: 8),
        ],
        // Notification bell
        GestureDetector(
          onTap: () => Navigator.push(
                  context, MaterialPageRoute(builder: (_) => const NotificationsScreen()))
              .then((_) => _fetchUnreadCount()),
          child: Stack(clipBehavior: Clip.none, children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: isDark ? _darkCard : _lightCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFDCE9FF)),
              ),
              child: Icon(Icons.notifications_outlined, color: textColor.withValues(alpha: 0.8), size: 20),
            ),
            if (_unreadNotifCount > 0)
              Positioned(
                top: -4, right: -4,
                child: Container(
                  constraints: const BoxConstraints(minWidth: 17, minHeight: 17),
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [BoxShadow(color: const Color(0xFFEF4444).withValues(alpha: 0.4), blurRadius: 4)],
                  ),
                  child: Center(child: Text(
                    _unreadNotifCount > 9 ? '9+' : _unreadNotifCount.toString(),
                    style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900),
                  )),
                ),
              ),
          ]),
        ),
      ]),
    );
  }

  // ── GREETING CARD ────────────────────────────────────────────────────────
  Widget _buildGreetingCard(bool isDark, Color textColor) {
    final hour = DateTime.now().hour;
    final timeEmoji = hour < 12 ? '☀️' : hour < 17 ? '🌤️' : hour < 20 ? '🌆' : '🌙';
    final greeting = hour < 12 ? 'Good Morning' : hour < 17 ? 'Good Afternoon' : hour < 20 ? 'Good Evening' : 'Good Night';
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        gradient: isDark
          ? LinearGradient(
              colors: [_primary.withValues(alpha: 0.12), _darkCard.withValues(alpha: 0.8)],
              begin: Alignment.topLeft, end: Alignment.bottomRight)
          : LinearGradient(
              colors: [const Color(0xFFEAF2FF), _lightCard],
              begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _primary.withValues(alpha: isDark ? 0.2 : 0.15)),
        boxShadow: [
          BoxShadow(color: _primary.withValues(alpha: 0.08), blurRadius: 16, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _primary.withValues(alpha: 0.25)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text(timeEmoji, style: const TextStyle(fontSize: 12)),
              const SizedBox(width: 5),
              Text(greeting, style: GoogleFonts.poppins(color: _primary, fontSize: 11, fontWeight: FontWeight.w700)),
            ]),
          ),
          const Spacer(),
          if (_walletBalance > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.account_balance_wallet_rounded, color: Color(0xFF10B981), size: 11),
                const SizedBox(width: 4),
                Text('₹${_walletBalance.toStringAsFixed(0)}',
                  style: GoogleFonts.poppins(color: const Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.w800)),
              ]),
            ),
        ]),
        const SizedBox(height: 10),
        Text(
          'Hello, $_userName! 👋',
          style: GoogleFonts.poppins(fontSize: 20, color: textColor, fontWeight: FontWeight.w800, letterSpacing: -0.3),
        ),
        const SizedBox(height: 2),
        RichText(
          text: TextSpan(children: [
            TextSpan(
              text: 'Where to',
              style: GoogleFonts.poppins(fontSize: 28, color: textColor, fontWeight: FontWeight.w900, letterSpacing: -0.8),
            ),
            TextSpan(
              text: '?',
              style: GoogleFonts.poppins(fontSize: 28, color: _primary, fontWeight: FontWeight.w900, letterSpacing: -0.8),
            ),
          ]),
        ),
      ]),
    );
  }

  // ── SEARCH BAR ────────────────────────────────────────────────────────────
  Widget _buildSearchBar(bool isDark, Color cardBg, Color textColor) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Column(children: [
        GestureDetector(
          onTap: _openSearch,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isDark ? _darkCard : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _primary.withValues(alpha: 0.2), width: 1.5),
              boxShadow: [
                BoxShadow(color: _primary.withValues(alpha: 0.08), blurRadius: 16, offset: const Offset(0, 4)),
                BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 3)),
              ],
            ),
            child: Row(children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_lightAccent, _primary],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: _primary.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3))],
                ),
                child: const Icon(Icons.search_rounded, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                  Text(
                    'Where do you want to go?',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textColor.withValues(alpha: 0.4),
                    ),
                  ),
                  if (_pickup.isNotEmpty && _pickup != 'Getting location...')
                    Text(
                      _pickup.split(',').first,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(fontSize: 10, color: _primary.withValues(alpha: 0.7), fontWeight: FontWeight.w600),
                    ),
                ]),
              ),
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VoiceBookingScreen())),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [_lightAccent, _primary],
                          begin: Alignment.topLeft, end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: _primary.withValues(alpha: 0.35), blurRadius: 10, offset: const Offset(0, 3))],
                      ),
                      child: const Icon(Icons.mic_rounded, color: Colors.white, size: 20),
                    ),
                    Positioned(
                      top: -4, right: -4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.white, width: 1),
                        ),
                        child: const Text('AI', style: TextStyle(color: Colors.white, fontSize: 7, fontWeight: FontWeight.w900, letterSpacing: 0.3)),
                      ),
                    ),
                  ],
                ),
              ),
            ]),
          ),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VoiceBookingScreen())),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? _darkCard : const Color(0xFFEEF6FF),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _primary.withValues(alpha: 0.2)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.mic_rounded, color: _primary, size: 14),
              const SizedBox(width: 6),
              Text(
                'Try Voice Booking — say your destination!',
                style: GoogleFonts.poppins(color: _primary, fontSize: 11, fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(color: _primary, borderRadius: BorderRadius.circular(6)),
                child: const Text('NEW', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
              ),
            ]),
          ),
        ),
      ]),
    );
  }

  // ── SERVICE GRID (dynamic from API, fallback to vehicle categories) ────────
  Widget _buildServiceGrid(bool isDark, Color cardBg, Color textColor) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header row
        Row(children: [
          Container(width: 4, height: 20, decoration: BoxDecoration(color: _primary, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 10),
          Text('Our Services', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w800, color: textColor)),
          const Spacer(),
          GestureDetector(
            onTap: _showAllServicesSheet,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: _primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _primary.withValues(alpha: 0.3)),
              ),
              child: Text('All Services', style: GoogleFonts.poppins(color: _primary, fontSize: 11, fontWeight: FontWeight.w700)),
            ),
          ),
        ]),
        const SizedBox(height: 14),

        // Empty state
        if (_activeServices.isEmpty && _vehicleCategories.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _primary.withValues(alpha: 0.15)),
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text('🚧', style: const TextStyle(fontSize: 36)),
              const SizedBox(height: 10),
              Text(
                'No services available in your area yet. Stay tuned!',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 13, color: textColor.withValues(alpha: 0.6), fontWeight: FontWeight.w500),
              ),
            ]),
          )

        // Fallback: vehicle categories as 2-column grid
        else if (_activeServices.isEmpty && _vehicleCategories.isNotEmpty)
          _buildVehicleCategoryFallbackGrid(isDark, cardBg, textColor)

        // Dynamic services from API
        else
          _buildDynamicServicesGrid(isDark, cardBg, textColor),
      ]),
    );
  }

  Widget _buildVehicleCategoryFallbackGrid(bool isDark, Color cardBg, Color textColor) {
    final items = _vehicleCategories.take(4).toList();
    final rows = <Widget>[];
    for (var i = 0; i < items.length; i += 2) {
      rows.add(Row(children: [
        Expanded(child: _buildFallbackCatCard(items[i], cardBg, textColor)),
        const SizedBox(width: 12),
        Expanded(child: i + 1 < items.length
          ? _buildFallbackCatCard(items[i + 1], cardBg, textColor)
          : const SizedBox()),
      ]));
      if (i + 2 < items.length) rows.add(const SizedBox(height: 12));
    }
    return Column(children: rows);
  }

  Widget _buildFallbackCatCard(Map<String, dynamic> cat, Color cardBg, Color textColor) {
    final key = (cat['name'] ?? '').toString().toLowerCase();
    final defaults = _serviceDefaults(key);
    final accentColor = defaults['color'] as Color;
    final emoji = defaults['emoji'] as String;
    final isParcel = cat['type'] == 'parcel';
    return GestureDetector(
      onTap: () {
        if (isParcel) {
          Navigator.push(context, MaterialPageRoute(
            builder: (_) => ParcelBookingScreen(pickupAddress: _pickup, pickupLat: _pickupLat, pickupLng: _pickupLng)));
        } else {
          _openSearch(presetVehicle: cat['name']?.toString());
        }
      },
      child: _buildGridCard(
        topLabel: isParcel ? 'Send anything' : 'Quick ride',
        boldLabel: cat['name']?.toString() ?? '',
        emoji: emoji,
        bigEmoji: true,
        cardBg: cardBg,
        textColor: textColor,
        accentColor: accentColor,
        onTap: () {
          if (isParcel) {
            Navigator.push(context, MaterialPageRoute(
              builder: (_) => ParcelBookingScreen(pickupAddress: _pickup, pickupLat: _pickupLat, pickupLng: _pickupLng)));
          } else {
            _openSearch(presetVehicle: cat['name']?.toString());
          }
        },
      ),
    );
  }

  Widget _buildDynamicServicesGrid(bool isDark, Color cardBg, Color textColor) {
    final items = _activeServices;
    final rows = <Widget>[];
    for (var i = 0; i < items.length; i += 2) {
      final a = items[i];
      final b = i + 1 < items.length ? items[i + 1] : null;
      rows.add(Row(children: [
        Expanded(child: _buildDynamicServiceCard(a, cardBg, textColor)),
        const SizedBox(width: 12),
        Expanded(child: b != null
          ? _buildDynamicServiceCard(b, cardBg, textColor)
          : const SizedBox()),
      ]));
      if (i + 2 < items.length) rows.add(const SizedBox(height: 12));
    }
    return Column(children: rows);
  }

  Widget _buildDynamicServiceCard(Map<String, dynamic> svc, Color cardBg, Color textColor) {
    final key = (svc['key'] ?? '').toString();
    final name = (svc['name'] ?? key).toString();
    final description = (svc['description'] ?? '').toString();
    final apiEmoji = (svc['icon'] ?? '').toString();
    final defaults = _serviceDefaults(key);
    final fallbackEmoji = defaults['emoji'] as String;
    final fallbackColor = defaults['color'] as Color;
    final emoji = apiEmoji.isNotEmpty ? apiEmoji : fallbackEmoji;
    final accentColor = _colorFromHex(svc['color']?.toString(), fallbackColor);

    final isParcel = key == 'parcel_delivery' || key == 'parcel' || key == 'cargo' || key == 'cargo_freight';

    return _buildGridCard(
      topLabel: description.isNotEmpty
        ? (description.length > 18 ? '${description.substring(0, 18)}…' : description)
        : (isParcel ? 'Send anything' : 'Quick ride'),
      boldLabel: name,
      emoji: emoji,
      bigEmoji: true,
      cardBg: cardBg,
      textColor: textColor,
      accentColor: accentColor,
      onTap: () {
        HapticFeedback.selectionClick();
        if (isParcel) {
          Navigator.push(context, MaterialPageRoute(
            builder: (_) => ParcelBookingScreen(pickupAddress: _pickup, pickupLat: _pickupLat, pickupLng: _pickupLng)));
        } else {
          _openSearch();
        }
      },
    );
  }

  Widget _buildGridCard({
    required String topLabel,
    required String boldLabel,
    required String emoji,
    required VoidCallback onTap,
    required Color cardBg,
    required Color textColor,
    bool bigEmoji = false,
    Color accentColor = _primary,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 116,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: accentColor.withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, 3)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [cardBg, accentColor.withValues(alpha: 0.07)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
              ),
            ),
            Positioned(
              left: 0, top: 0, bottom: 0,
              child: Container(
                width: 4,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [accentColor, accentColor.withValues(alpha: 0.3)],
                    begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 10, 12),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (topLabel.isNotEmpty) ...[
                        Text(
                          topLabel,
                          style: GoogleFonts.poppins(fontSize: 10, color: accentColor.withValues(alpha: 0.8), fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 5),
                      ],
                      Text(
                        boldLabel,
                        style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.w900, color: textColor, height: 1.15, letterSpacing: -0.3),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: 24, height: 3,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [accentColor, accentColor.withValues(alpha: 0.3)]),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                ),
                Align(
                  alignment: bigEmoji ? Alignment.bottomRight : Alignment.center,
                  child: Text(emoji, style: TextStyle(fontSize: bigEmoji ? 46 : 38)),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  // ── HORIZONTAL EXPLORE SECTION ───────────────────────────────────────────
  Widget _buildExploreSection(bool isDark, Color cardBg, Color textColor) {
    final services = [
      {'key': 'bike', 'name': 'Bike Ride', 'emoji': '🏍️', 'type': 'ride', 'color': _primary},
      {'key': 'auto', 'name': 'Auto Ride', 'emoji': '🛺', 'type': 'ride', 'color': const Color(0xFF059669)},
      {'key': 'car', 'name': 'Car Ride', 'emoji': '🚗', 'type': 'ride', 'color': const Color(0xFF2563EB)},
      {'key': 'parcel', 'name': 'Parcel', 'emoji': '📦', 'type': 'parcel', 'color': const Color(0xFFF59E0B)},
      {'key': 'cargo', 'name': 'Cargo', 'emoji': '🚛', 'type': 'cargo', 'color': const Color(0xFF7C3AED)},
      {'key': 'intercity', 'name': 'Intercity', 'emoji': '🛣️', 'type': 'intercity', 'color': const Color(0xFF0EA5E9)},
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 0, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Row(children: [
            Container(width: 4, height: 20, decoration: BoxDecoration(color: _primary, borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 10),
            Text('Book a Ride', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w800, color: textColor)),
            const Spacer(),
            GestureDetector(
              onTap: _showAllServicesSheet,
              child: Row(children: [
                Text('View All', style: GoogleFonts.poppins(fontSize: 13, color: _primary, fontWeight: FontWeight.w700)),
                const Icon(Icons.chevron_right, size: 18, color: _primary),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(children: services.map((s) => _exploreItem(s, isDark, textColor)).toList()),
        ),
        const SizedBox(height: 8),
      ]),
    );
  }

  Widget _exploreItem(Map<String, dynamic> s, bool isDark, Color textColor) {
    final isPopular = s['key'] == 'bike';
    final color = (s['color'] as Color?) ?? _primary;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        if (s['type'] == 'parcel' || s['type'] == 'cargo') {
          Navigator.push(context, MaterialPageRoute(
            builder: (_) => ParcelBookingScreen(pickupAddress: _pickup, pickupLat: _pickupLat, pickupLng: _pickupLng)));
        } else if (s['key'] == 'intercity') {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const IntercityBookingScreen()));
        } else {
          _openSearch(presetVehicle: s['key'] as String?);
        }
      },
      child: Container(
        width: 80,
        margin: const EdgeInsets.only(right: 14),
        child: Column(children: [
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              Container(
                width: 68, height: 68,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [color.withValues(alpha: isDark ? 0.25 : 0.12), color.withValues(alpha: isDark ? 0.12 : 0.05)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                  border: Border.all(color: color.withValues(alpha: isDark ? 0.5 : 0.3), width: 2),
                  boxShadow: [BoxShadow(color: color.withValues(alpha: 0.15), blurRadius: 12, offset: const Offset(0, 5))],
                ),
                child: Center(child: Text(s['emoji'] as String, style: const TextStyle(fontSize: 32))),
              ),
              if (isPopular)
                Positioned(
                  top: -6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.75)]),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 6)],
                    ),
                    child: const Text('FAST', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            s['name'] as String,
            style: GoogleFonts.poppins(
              fontSize: 11, fontWeight: FontWeight.w700,
              color: isDark ? Colors.white.withValues(alpha: 0.85) : const Color(0xFF374151),
            ),
            textAlign: TextAlign.center, maxLines: 2,
          ),
        ]),
      ),
    );
  }

  // ── ACTIVE TRIP BANNER ───────────────────────────────────────────────────
  Widget _buildActiveTripBanner(bool isDark) {
    final trip = _activeTrip!;
    final status = trip['currentStatus']?.toString() ?? 'accepted';
    final tripId = trip['id']?.toString() ?? '';
    final driverName = trip['driverName']?.toString() ?? 'your Pilot';
    final dest = trip['destinationAddress']?.toString() ?? 'destination';

    final statusLabel = {
      'accepted': 'Pilot is on the way',
      'driver_assigned': 'Pilot assigned',
      'arrived': 'Pilot has arrived!',
      'in_progress': 'Ride in progress',
    }[status] ?? 'Ride active';

    final isArrived = status == 'arrived';
    final bannerColor = isArrived ? const Color(0xFF16A34A) : _primary;

    return GestureDetector(
      onTap: () => Navigator.pushReplacement(context,
        MaterialPageRoute(builder: (_) => TrackingScreen(tripId: tripId))),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [bannerColor, bannerColor.withValues(alpha: 0.75)],
            begin: Alignment.centerLeft, end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: bannerColor.withValues(alpha: 0.35), blurRadius: 16, offset: const Offset(0, 4))],
        ),
        child: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), shape: BoxShape.circle),
            child: const Icon(Icons.navigation_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(statusLabel,
              style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14)),
            Text('$driverName → ${dest.length > 30 ? '${dest.substring(0, 28)}...' : dest}',
              style: GoogleFonts.poppins(color: Colors.white.withValues(alpha: 0.85), fontSize: 11, fontWeight: FontWeight.w500)),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text('Track →', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12)),
          ),
        ]),
      ),
    );
  }

  // ── RECENT SECTION ───────────────────────────────────────────────────────
  Widget _buildRecentSection(bool isDark, Color cardBg, Color textColor) {
    if (_recentTrips.isNotEmpty) {
      return Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(width: 4, height: 20, decoration: BoxDecoration(color: _primary, borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 10),
            Text('Recent Trips', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w800, color: textColor)),
            const Spacer(),
            GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TripsHistoryScreen())),
              child: Row(children: [
                Text('See all', style: GoogleFonts.poppins(fontSize: 13, color: _primary, fontWeight: FontWeight.w700)),
                const Icon(Icons.chevron_right, size: 16, color: _primary),
              ]),
            ),
          ]),
          const SizedBox(height: 12),
          ..._recentTrips.take(3).map((trip) {
            final pickup = trip['pickupAddress']?.toString() ?? trip['pickup_address']?.toString() ?? '';
            final dest = trip['destinationAddress']?.toString() ?? trip['destination_address']?.toString() ?? '';
            final fare = (trip['estimatedFare'] ?? trip['actual_fare'] ?? trip['estimated_fare'] ?? 0).toDouble();
            final destLat = double.tryParse(trip['destinationLat']?.toString() ?? trip['destination_lat']?.toString() ?? '0') ?? 0;
            final destLng = double.tryParse(trip['destinationLng']?.toString() ?? trip['destination_lng']?.toString() ?? '0') ?? 0;
            final vehicle = trip['vehicleName']?.toString() ?? trip['vehicle_name']?.toString() ?? '';
            final payMethod = trip['paymentMethod']?.toString() ?? trip['payment_method']?.toString() ?? 'cash';
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _primary.withValues(alpha: 0.08)),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 3))],
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Column(children: [
                      Container(width: 10, height: 10, decoration: const BoxDecoration(color: Color(0xFF16A34A), shape: BoxShape.circle)),
                      Container(width: 1, height: 20, color: isDark ? const Color(0xFF334155) : const Color(0xFFDCE9FF)),
                      const Icon(Icons.location_on_rounded, color: Color(0xFFE53935), size: 14),
                    ]),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(
                        pickup.isNotEmpty ? pickup.split(',').first : 'Pickup',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 13, color: textColor),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        dest.isNotEmpty ? dest.split(',').first : 'Destination',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 13, color: textColor),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                      ),
                    ])),
                    const SizedBox(width: 10),
                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      if (fare > 0)
                        Text(
                          '₹${fare.toStringAsFixed(0)}',
                          style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w900, color: _primary),
                        ),
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(
                            builder: (_) => BookingScreen(
                              pickup: _pickup,
                              destination: dest,
                              pickupLat: _pickupLat,
                              pickupLng: _pickupLng,
                              destLat: destLat != 0 ? destLat : 17.3850,
                              destLng: destLng != 0 ? destLng : 78.4867,
                            )));
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: _primary, width: 1.5),
                          ),
                          child: Text('Repeat →', style: GoogleFonts.poppins(color: _primary, fontSize: 11, fontWeight: FontWeight.w800)),
                        ),
                      ),
                    ]),
                  ]),
                ),
                if (vehicle.isNotEmpty || payMethod.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 4, 14, 10),
                    child: Row(children: [
                      if (vehicle.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: _primary.withValues(alpha: 0.2)),
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            const Icon(Icons.electric_bike, size: 10, color: _primary),
                            const SizedBox(width: 4),
                            Text(vehicle, style: GoogleFonts.poppins(color: _primary, fontSize: 10, fontWeight: FontWeight.w700)),
                          ]),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          payMethod == 'cash' ? '💵 Cash' : payMethod == 'wallet' ? '💳 Wallet' : '📱 UPI',
                          style: GoogleFonts.poppins(color: textColor.withValues(alpha: 0.5), fontSize: 10, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ]),
                  ),
              ]),
            );
          }).toList(),
        ]),
      );
    }
    return _buildRecentPlaces(isDark, cardBg, textColor);
  }

  Widget _buildRecentPlaces(bool isDark, Color cardBg, Color textColor) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 4, height: 20, decoration: BoxDecoration(color: _primary, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 10),
          Text('Saved Places', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w800, color: textColor)),
        ]),
        const SizedBox(height: 12),
        ..._savedPlaces.take(3).map((p) {
          final label = p['label'] ?? '';
          final address = p['address'] ?? '';
          final isHome = label == 'Home';
          return GestureDetector(
            onTap: () {
              final destLat = double.tryParse(p['lat']?.toString() ?? '0') ?? 0;
              final destLng = double.tryParse(p['lng']?.toString() ?? '0') ?? 0;
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => BookingScreen(
                  pickup: _pickup, destination: address,
                  pickupLat: _pickupLat, pickupLng: _pickupLng,
                  destLat: destLat != 0 ? destLat : 17.3850,
                  destLng: destLng != 0 ? destLng : 78.4867,
                )));
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _primary.withValues(alpha: 0.08)),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: _primary.withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: Icon(isHome ? Icons.home_rounded : Icons.work_rounded, color: _primary, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(
                    isHome ? label : address,
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 14, color: textColor),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    address,
                    style: GoogleFonts.poppins(fontSize: 12, color: textColor.withValues(alpha: 0.5)),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                ])),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _primary, width: 1.5),
                  ),
                  child: Text('Go →', style: GoogleFonts.poppins(color: _primary, fontSize: 11, fontWeight: FontWeight.w800)),
                ),
              ]),
            ),
          );
        }).toList(),
      ]),
    );
  }

  // ── EVERYTHING SECTION (extra services) ──────────────────────────────────
  Widget _buildEverythingSection(bool isDark, Color cardBg, Color textColor) {
    // This section is intentionally kept minimal in the new design
    // as the service grid above already covers main services.
    return const SizedBox.shrink();
  }

  // ── IN A HURRY CARD ───────────────────────────────────────────────────────
  Widget _buildInAHurryCard(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: GestureDetector(
        onTap: () => _openSearch(presetVehicle: 'bike'),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF56CCF2), Color(0xFF2F80ED), Color(0xFF2563EB)],
              begin: Alignment.centerLeft, end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: _primary.withValues(alpha: 0.38), blurRadius: 18, offset: const Offset(0, 6)),
              BoxShadow(color: _primary.withValues(alpha: 0.15), blurRadius: 32, offset: const Offset(0, 12)),
            ],
          ),
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('IN A HURRY?',
                    style: GoogleFonts.poppins(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)),
                ),
                const SizedBox(height: 8),
                Text(
                  'Bike ride\nin 2 min',
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, height: 1.15),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 2))],
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text('Book Now', style: GoogleFonts.poppins(color: _primary, fontWeight: FontWeight.w800, fontSize: 13)),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward_rounded, size: 14, color: _primary),
                  ]),
                ),
              ]),
            ),
            Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Text('🏍️', style: TextStyle(fontSize: 70)),
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('from ₹20', style: GoogleFonts.poppins(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
              ),
            ]),
          ]),
        ),
      ),
    );
  }

  // ── PARCEL PROMO BANNER ──────────────────────────────────────────────────
  Widget _buildParcelPromoBanner(bool isDark, Color cardBg, Color textColor) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: GestureDetector(
        onTap: () => Navigator.push(context, MaterialPageRoute(
          builder: (_) => ParcelBookingScreen(pickupAddress: _pickup, pickupLat: _pickupLat, pickupLng: _pickupLng))),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF7C2D12), Color(0xFFB45309), Color(0xFFF59E0B)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: const Color(0xFFF59E0B).withValues(alpha: 0.35), blurRadius: 20, offset: const Offset(0, 6)),
              BoxShadow(color: const Color(0xFFF59E0B).withValues(alpha: 0.15), blurRadius: 36, offset: const Offset(0, 12)),
            ],
          ),
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('JAGO DELIVERS 📦',
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
              ),
              const SizedBox(height: 8),
              Text('Send parcels,\nanywhere fast',
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, height: 1.2)),
              const SizedBox(height: 4),
              Text('Bike Parcel • Cargo Truck • Same Day',
                style: GoogleFonts.poppins(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500)),
              const SizedBox(height: 12),
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 8, offset: const Offset(0, 2))],
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text('Send Now', style: GoogleFonts.poppins(color: const Color(0xFFB45309), fontWeight: FontWeight.w900, fontSize: 13)),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward_rounded, size: 14, color: Color(0xFFB45309)),
                  ]),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                  ),
                  child: Text('from ₹25', style: GoogleFonts.poppins(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
                ),
              ]),
            ])),
            const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text('📦', style: TextStyle(fontSize: 52)),
              SizedBox(height: 6),
              Text('🏍️', style: TextStyle(fontSize: 28)),
            ]),
          ]),
        ),
      ),
    );
  }

  // ── GO PLACES BANNER ─────────────────────────────────────────────────────
  Widget _buildGoPlacesBanner(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: GestureDetector(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const IntercityBookingScreen())),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                ? [const Color(0xFF1E293B), const Color(0xFF0F2050)]
                : [const Color(0xFF1A2A5E), const Color(0xFF0F1E48)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.3), width: 1),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.18), blurRadius: 16, offset: const Offset(0, 6)),
              BoxShadow(color: const Color(0xFFFFD700).withValues(alpha: 0.08), blurRadius: 24, offset: const Offset(0, 8)),
            ],
          ),
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD700).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.3)),
                  ),
                  child: Text('INTERCITY',
                    style: GoogleFonts.poppins(color: const Color(0xFFFFD700), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                ),
                const SizedBox(height: 10),
                Text('Go anywhere,\nanytime',
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, height: 1.2)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD700).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.4)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text('Explore routes', style: GoogleFonts.poppins(color: const Color(0xFFFFD700), fontWeight: FontWeight.w700, fontSize: 12)),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward_rounded, color: Color(0xFFFFD700), size: 14),
                  ]),
                ),
              ]),
            ),
            const Text('🛣️', style: TextStyle(fontSize: 60)),
          ]),
        ),
      ),
    );
  }

  // ── BOTTOM NAV ───────────────────────────────────────────────────────────
  Widget _buildBottomNav(bool isDark, Color cardBg, Color textColor) {
    final iconColor = isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8);
    return Container(
      decoration: BoxDecoration(
        color: isDark ? _darkCard : Colors.white,
        border: Border(top: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFDCE9FF), width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _navItem(Icons.home_rounded, Icons.home_outlined, 'Home', 0, iconColor, isDark),
              _navItem(Icons.receipt_long_rounded, Icons.receipt_long_outlined, 'Trips', 1, iconColor, isDark),
              // Center voice button — blue circle
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VoiceBookingScreen())),
                child: Container(
                  width: 52, height: 52,
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_lightAccent, _primary],
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: _primary.withValues(alpha: 0.4), blurRadius: 14, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: const Icon(Icons.mic_rounded, color: Colors.white, size: 24),
                ),
              ),
              _navItem(Icons.account_balance_wallet_rounded, Icons.account_balance_wallet_outlined, 'Wallet', 2, iconColor, isDark),
              _navItem(Icons.person_rounded, Icons.person_outline_rounded, 'Profile', 3, iconColor, isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(IconData activeIcon, IconData inactiveIcon, String label, int index, Color iconColor, bool isDark) {
    final active = _navIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() => _navIndex = index);
        if (index == 1) Navigator.push(context, MaterialPageRoute(builder: (_) => const TripsHistoryScreen()));
        if (index == 2) Navigator.push(context, MaterialPageRoute(builder: (_) => const WalletScreen()));
        if (index == 3) Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
      },
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 40, height: 32,
          decoration: BoxDecoration(
            color: active ? _primary.withValues(alpha: isDark ? 0.2 : 0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(active ? activeIcon : inactiveIcon, size: 20, color: active ? _primary : iconColor),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 10,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            color: active ? _primary : iconColor,
          ),
        ),
      ]),
    );
  }

  // ── DRAWER ───────────────────────────────────────────────────────────────
  Widget _buildDrawer(bool isDark) {
    final drawerBg = isDark ? _darkBg : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    return Drawer(
      backgroundColor: drawerBg,
      child: SafeArea(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                  ? [_primary.withValues(alpha: 0.15), _darkCard.withValues(alpha: 0.8)]
                  : [const Color(0xFFEAF2FF), Colors.white],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: _primary.withValues(alpha: 0.15),
                child: Text(
                  _userName.isNotEmpty ? _userName[0].toUpperCase() : 'U',
                  style: GoogleFonts.poppins(color: _primary, fontSize: 24, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 12),
              Text(_userName, style: GoogleFonts.poppins(color: textColor, fontSize: 18, fontWeight: FontWeight.w700)),
              Text(_userPhone, style: GoogleFonts.poppins(color: textColor.withValues(alpha: 0.5), fontSize: 13)),
            ]),
          ),
          Divider(color: isDark ? const Color(0xFF334155) : const Color(0xFFDCE9FF), thickness: 1),
          _drawerItem(Icons.history_rounded, 'My Trips', textColor, () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const TripsHistoryScreen())); }),
          _drawerItem(Icons.account_balance_wallet_rounded, 'Wallet', textColor, () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const WalletScreen())); }),
          _drawerItem(Icons.local_offer_rounded, 'Offers', textColor, () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const OffersScreen())); }),
          _drawerItem(Icons.bookmark_rounded, 'Saved Places', textColor, () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const SavedPlacesScreen())); }),
          _drawerItem(Icons.people_alt_rounded, 'Refer & Earn', textColor, () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const ReferralScreen())); }),
          _drawerItem(Icons.support_agent_rounded, 'Support', textColor, () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const SupportChatScreen())); }),
          const Spacer(),
          _drawerItem(Icons.person_rounded, 'Profile', textColor, () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())); }),
          const SizedBox(height: 16),
        ]),
      ),
    );
  }

  Widget _drawerItem(IconData icon, String label, Color textColor, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: _primary, size: 22),
      title: Text(label, style: GoogleFonts.poppins(color: textColor, fontSize: 15, fontWeight: FontWeight.w500)),
      onTap: onTap,
      dense: true,
    );
  }
}

// ── PLACE SEARCH SHEET ────────────────────────────────────────────────────
class _PlaceSearchSheet extends StatefulWidget {
  final double pickupLat;
  final double pickupLng;
  final void Function(String name, double lat, double lng) onPlaceSelected;

  const _PlaceSearchSheet({
    required this.pickupLat,
    required this.pickupLng,
    required this.onPlaceSelected,
  });

  @override
  State<_PlaceSearchSheet> createState() => _PlaceSearchSheetState();
}

class _PlaceSearchSheetState extends State<_PlaceSearchSheet> {
  final TextEditingController _ctrl = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  List<Map<String, dynamic>> _nearby = [];
  bool _loading = false;
  Timer? _debounce;

  static const Color _primary = Color(0xFF2F80ED);

  @override
  void initState() {
    super.initState();
    _fetchNearby();
  }

  // Fetch actual nearby places based on real GPS coordinates
  Future<void> _fetchNearby() async {
    final lat = widget.pickupLat;
    final lng = widget.pickupLng;
    if (lat == 0.0 && lng == 0.0) return;
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=&format=json&limit=8&addressdetails=1'
        '&lat=$lat&lon=$lng&bounded=0&featuretype=settlement,suburb,city'
        '&viewbox=${lng - 0.15},${lat + 0.15},${lng + 0.15},${lat - 0.15}'
      );
      final resp = await http.get(url, headers: {'User-Agent': 'JAGOApp/1.0'});
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as List;
        if (mounted && data.isNotEmpty) {
          setState(() {
            _nearby = data.map((d) => {
              'name': d['display_name']?.toString().split(', ').take(3).join(', ') ?? '',
              'lat': double.tryParse(d['lat']?.toString() ?? '0') ?? 0.0,
              'lng': double.tryParse(d['lon']?.toString() ?? '0') ?? 0.0,
            }).where((r) => (r['name'] as String).isNotEmpty).toList().cast<Map<String, dynamic>>();
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _search(String query) async {
    if (query.length < 3) {
      setState(() { _results = []; _loading = false; });
      return;
    }
    setState(() => _loading = true);
    try {
      final lat = widget.pickupLat;
      final lng = widget.pickupLng;
      // Bias results towards user's actual location using viewbox
      final locationBias = (lat != 0.0 && lng != 0.0)
        ? '&lat=$lat&lon=$lng&bounded=0'
           '&viewbox=${lng - 0.3},${lat + 0.3},${lng + 0.3},${lat - 0.3}'
        : '';
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&limit=8&addressdetails=1$locationBias'
      );
      final resp = await http.get(url, headers: {'User-Agent': 'JAGOApp/1.0'});
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as List;
        setState(() {
          _results = data.map((d) => {
            'name': d['display_name']?.toString().split(', ').take(3).join(', ') ?? '',
            'lat': double.tryParse(d['lat']?.toString() ?? '0') ?? 0.0,
            'lng': double.tryParse(d['lon']?.toString() ?? '0') ?? 0.0,
          }).where((r) => (r['name'] as String).isNotEmpty).toList().cast<Map<String, dynamic>>();
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _ctrl.text;
    final items = query.length >= 3 ? _results : _nearby;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = isDark ? const Color(0xFF0F172A) : Colors.white;
    final inputBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFF5F8FF);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subColor = isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        color: sheetBg,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 36, height: 4,
            margin: const EdgeInsets.only(top: 10, bottom: 14),
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : const Color(0xFFDCE9FF),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _ctrl,
              autofocus: true,
              style: GoogleFonts.poppins(color: textColor, fontSize: 15),
              decoration: InputDecoration(
                hintText: 'Search destination...',
                hintStyle: GoogleFonts.poppins(color: subColor, fontSize: 15),
                prefixIcon: const Icon(Icons.search, color: _primary),
                suffixIcon: query.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, color: subColor),
                      onPressed: () => setState(() { _ctrl.clear(); _results = []; }))
                  : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                filled: true,
                fillColor: inputBg,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onChanged: (v) {
                _debounce?.cancel();
                _debounce = Timer(const Duration(milliseconds: 400), () => _search(v));
                setState(() {});
              },
            ),
          ),
          const SizedBox(height: 8),
          if (_loading) const Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator(color: _primary)),
          if (!_loading)
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.4),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: items.length + (query.length < 3 ? 1 : 0),
                itemBuilder: (_, i) {
                  if (query.length < 3 && i == 0) {
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                      child: Text(
                        _nearby.isEmpty ? 'Start typing to search...' : 'Nearby places',
                        style: GoogleFonts.poppins(fontSize: 12, color: subColor, fontWeight: FontWeight.w600),
                      ),
                    );
                  }
                  final item = items[query.length < 3 ? i - 1 : i];
                  return ListTile(
                    leading: const Icon(Icons.location_on_outlined, color: _primary),
                    title: Text(
                      item['name'] as String,
                      style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: textColor),
                      maxLines: 2,
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      widget.onPlaceSelected(
                        item['name'] as String,
                        (item['lat'] as num?)?.toDouble() ?? 0.0,
                        (item['lng'] as num?)?.toDouble() ?? 0.0,
                      );
                    },
                  );
                },
              ),
            ),
          const SizedBox(height: 16),
        ]),
      ),
    );
  }
}

// ── ALL SERVICES SHEET ────────────────────────────────────────────────────
class _AllServicesSheet extends StatelessWidget {
  final List<Map<String, dynamic>> vehicleCategories;
  final String pickup;
  final double pickupLat;
  final double pickupLng;
  final void Function(Map<String, dynamic> cat) onServiceTap;

  const _AllServicesSheet({
    required this.vehicleCategories,
    required this.pickup,
    required this.pickupLat,
    required this.pickupLng,
    required this.onServiceTap,
  });

  static const Color _primary = Color(0xFF2F80ED);

  @override
  Widget build(BuildContext context) {
    final allServices = [
      {'id': null, 'name': 'Bike Ride', 'type': 'ride', 'emoji': '🏍️', 'key': 'bike'},
      {'id': null, 'name': 'Auto Ride', 'type': 'ride', 'emoji': '🛺', 'key': 'auto'},
      {'id': null, 'name': 'Car Ride', 'type': 'ride', 'emoji': '🚗', 'key': 'car'},
      {'id': null, 'name': 'Parcel', 'type': 'parcel', 'emoji': '📦', 'key': 'parcel'},
      {'id': null, 'name': 'Intercity', 'type': 'intercity', 'emoji': '🛣️', 'key': 'intercity'},
      {'id': null, 'name': 'Car Sharing', 'type': 'carsharing', 'emoji': '🚘', 'key': 'carsharing'},
    ];

    final services = vehicleCategories.isNotEmpty
      ? vehicleCategories.map((v) => {
          'id': v['id'],
          'name': v['name'] ?? '',
          'type': v['type'] ?? 'ride',
          'emoji': _emojiForCategory(v['name']?.toString() ?? ''),
          'key': v['name']?.toString().toLowerCase().replaceAll(' ', '_') ?? '',
        }).toList()
      : allServices;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = isDark ? const Color(0xFF0F172A) : Colors.white;
    final cardBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFF5F8FF);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subColor = isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8);

    return Container(
      padding: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 24),
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 36, height: 4,
          decoration: BoxDecoration(
            color: isDark ? Colors.white24 : const Color(0xFFDCE9FF),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('All Services', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w800, color: textColor)),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: isDark ? Colors.white10 : const Color(0xFFF5F8FF),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.close, size: 18, color: subColor),
            ),
          ),
        ]),
        const SizedBox(height: 20),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3, childAspectRatio: 0.88, crossAxisSpacing: 12, mainAxisSpacing: 12,
          ),
          itemCount: services.length,
          itemBuilder: (_, i) {
            final s = services[i];
            return GestureDetector(
              onTap: () => onServiceTap(s),
              child: Container(
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFDCE9FF)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
                      blurRadius: 8, offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(s['emoji'] as String, style: const TextStyle(fontSize: 36)),
                  const SizedBox(height: 8),
                  Text(
                    s['name'] as String,
                    style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: textColor),
                    textAlign: TextAlign.center, maxLines: 2,
                  ),
                ]),
              ),
            );
          },
        ),
      ]),
    );
  }

  static String _emojiForCategory(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('bike') || lower.contains('moto')) return '🏍️';
    if (lower.contains('auto')) return '🛺';
    if (lower.contains('car') || lower.contains('cab')) return '🚗';
    if (lower.contains('parcel') || lower.contains('cargo')) return '📦';
    if (lower.contains('intercity')) return '🛣️';
    if (lower.contains('shar')) return '🚘';
    return '🚖';
  }
}
