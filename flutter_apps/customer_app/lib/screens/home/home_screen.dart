import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/api_config.dart';
import '../../config/jago_theme.dart';
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
import '../auth/login_screen.dart';

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
  bool _homeLoading = true;
  Timer? _loadingTimeout;

  // New state: banners + feature flags
  List<Map<String, dynamic>> _banners = [];
  Map<String, bool> _featureFlags = {};
  int _bannerIndex = 0;
  Timer? _bannerTimer;
  final PageController _bannerPageCtrl = PageController();

  // Brand colors — mapped to JT design system
  static const Color _primary = Color(0xFF2F7BFF);
  static const Color _secondary = JT.secondary;
  static const Color _lightAccent = JT.secondary;
  static const Color _darkBg = JT.textPrimary;
  static const Color _darkCard = JT.surface;
  static const Color _lightBg = JT.bg;
  static const Color _lightCard = JT.surfaceAlt;

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
    _fetchBanners();
    _fetchFeatureFlags();
    _connectSocket();
    // Safety fallback: never show loading more than 6 seconds
    _loadingTimeout = Timer(const Duration(seconds: 6), () {
      if (mounted && _homeLoading) {
        setState(() {
          _homeLoading = false;
          if (_vehicleCategories.isEmpty) _vehicleCategories = _defaultVehicleCategories();
        });
      }
    });
    // Auto-scroll banner every 4 seconds
    _bannerTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || _banners.isEmpty) return;
      final next = (_bannerIndex + 1) % _banners.length;
      _bannerPageCtrl.animateToPage(next,
        duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkPendingFcmNotification());
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkActiveTrip());
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowTutorial());
  }

  Future<void> _fetchUnreadCount() async {
    try {
      final headers = await AuthService.getHeaders();
      final r = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/app/notifications?limit=1'),
        headers: headers).timeout(const Duration(seconds: 8));
      if (r.statusCode == 200 && mounted) {
        final data = jsonDecode(r.body);
        setState(() => _unreadNotifCount = (data['unreadCount'] as int?) ?? 0);
      }
    } catch (_) {}
  }

  Future<void> _fetchWalletBalance() async {
    try {
      final headers = await AuthService.getHeaders();
      final r = await http.get(Uri.parse(ApiConfig.wallet), headers: headers)
          .timeout(const Duration(seconds: 8));
      if (r.statusCode == 200 && mounted) {
        final data = jsonDecode(r.body);
        setState(() => _walletBalance = double.tryParse(data['balance']?.toString() ?? '0') ?? 0.0);
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

  Future<void> _fetchBanners() async {
    try {
      final headers = await AuthService.getHeaders();
      final r = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/app/banners'), headers: headers)
        .timeout(const Duration(seconds: 6));
      if (r.statusCode == 200 && mounted) {
        final data = jsonDecode(r.body) as Map<String, dynamic>;
        final list = (data['banners'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
        setState(() => _banners = list);
      }
    } catch (_) {}
  }

  Future<void> _fetchFeatureFlags() async {
    try {
      final r = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/app/feature-flags'))
        .timeout(const Duration(seconds: 6));
      if (r.statusCode == 200 && mounted) {
        final data = jsonDecode(r.body) as Map<String, dynamic>;
        final flags = (data['flags'] as Map<String, dynamic>?) ?? {};
        setState(() => _featureFlags = flags.map((k, v) => MapEntry(k, v == true)));
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

  Future<void> _maybeShowTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool('home_tutorial_seen') ?? false;
    if (seen || !mounted) return;
    await prefs.setBool('home_tutorial_seen', true);
    // Small delay so the home screen finishes building first
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  gradient: JT.grad,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Row(
                  children: [
                    const Text('👋', style: TextStyle(fontSize: 28)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Welcome!', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
                        Text('Here\'s a quick guide to get you started', style: GoogleFonts.poppins(color: Colors.white.withOpacity(0.85), fontSize: 12)),
                      ]),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _TutorialTip(icon: '🔍', title: 'Search Destination', desc: 'Tap "Where do you want to go?" to search for your destination and see instant fare estimates.'),
                    const SizedBox(height: 14),
                    _TutorialTip(icon: '🚗', title: 'Choose a Service', desc: 'Select from Auto, Bike, Car, Ride Pool, Parcel, and more based on your need.'),
                    const SizedBox(height: 14),
                    _TutorialTip(icon: '💳', title: 'Wallet & Payments', desc: 'Recharge your wallet for cashless rides. Tap the wallet icon in the top right.'),
                    const SizedBox(height: 14),
                    _TutorialTip(icon: '🔔', title: 'Stay Updated', desc: 'Enable notifications to get real-time alerts for your rides, offers, and more.'),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: JT.gradientButton(label: "Got it, Let's Go!", onTap: () => Navigator.pop(ctx)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
    _loadingTimeout?.cancel();
    _bannerTimer?.cancel();
    _bannerPageCtrl.dispose();
    _driverAssignedSub?.cancel();
    _socket.disconnect();
    super.dispose();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
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
      }
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
        if (!mounted) return;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            title: const Text('Location Required'),
            content: const Text('Location access is required to request rides. Please enable it in your device settings.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () { Navigator.pop(context); Geolocator.openAppSettings(); },
                child: const Text('Open Settings'),
              ),
            ],
          ),
        );
        return;
      }
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

  void _handleUnauthorized() {
    AuthService.logout().then((_) {
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(context,
        MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
    });
  }

  Future<void> _fetchHome() async {
    try {
      final headers = await AuthService.getHeaders();
      final results = await Future.wait([
        http.get(Uri.parse(ApiConfig.customerHomeData), headers: headers)
            .timeout(const Duration(seconds: 6)),
        http.get(Uri.parse('${ApiConfig.baseUrl}/api/app/services'), headers: headers)
            .timeout(const Duration(seconds: 6)),
      ]);
      // 401 = token expired — logout and go to login
      if (results[0].statusCode == 401) {
        if (mounted) setState(() => _homeLoading = false);
        _handleUnauthorized();
        return;
      }
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
    if (mounted) setState(() => _homeLoading = false);
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
    const isDark = false; // light-only theme
    final scaffoldBg = JT.bg;

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: scaffoldBg,
      drawer: _buildDrawer(isDark),
      body: SafeArea(
        child: Column(children: [
          _buildTopBar(isDark, JT.bgSoft, JT.textPrimary),
          Expanded(
            child: _homeLoading
              ? _buildSkeletonLoader(isDark, JT.bgSoft)
              : RefreshIndicator(
                  color: JT.primary,
                  onRefresh: () async {
                    await Future.wait([_fetchHome(), _fetchActiveServices(), _fetchBanners(), _fetchWalletBalance()]);
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      if (_activeTrip != null) _buildActiveTripBanner(isDark),
                      _buildSearchBar(isDark, JT.bgSoft, JT.textPrimary),
                      _buildServiceIcons(isDark),
                      _buildBannerCarousel(isDark),
                      _buildSavedPlaces(isDark),
                      _buildRecentTrips(isDark),
                      const SizedBox(height: 24),
                    ]),
                  ),
                ),
          ),
          _buildBottomNav(isDark, JT.bg, JT.textPrimary),
        ]),
      ),
    );
  }

  Widget _buildSkeletonLoader(bool isDark, Color cardBg) {
    final shimmer = isDark ? const Color(0xFF2A3A50) : JT.border;
    Widget box(double w, double h, {double r = 10}) => Container(
      width: w, height: h,
      decoration: BoxDecoration(color: shimmer, borderRadius: BorderRadius.circular(r)),
    );
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Search bar skeleton
        box(double.infinity, 52, r: 14),
        const SizedBox(height: 20),
        // Service icons skeleton
        box(120, 18, r: 8),
        const SizedBox(height: 12),
        Row(children: List.generate(4, (_) => Expanded(child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Column(children: [
            box(double.infinity, 56, r: 14),
            const SizedBox(height: 6),
            box(50, 12, r: 6),
          ]),
        )))),
        const SizedBox(height: 20),
        // Banner skeleton
        box(double.infinity, 130, r: 16),
        const SizedBox(height: 20),
        box(double.infinity, 80, r: 12),
        const SizedBox(height: 12),
        box(double.infinity, 80, r: 12),
      ]),
    );
  }

  // ── TOP BAR ──────────────────────────────────────────────────────────────
  Widget _buildTopBar(bool isDark, Color cardBg, Color textColor) {
    return Container(
      color: isDark ? _darkBg : JT.bg,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Row(children: [
        // Logo
        GestureDetector(
          onTap: () => _scaffoldKey.currentState?.openDrawer(),
          child: isDark ? JT.logoWhite(height: 32) : JT.logoBlue(height: 32),
        ),
        const SizedBox(width: 8),
        // Location indicator
        Expanded(
          child: GestureDetector(
            onTap: () => _scaffoldKey.currentState?.openDrawer(),
            child: Row(children: [
              Icon(Icons.location_on_rounded, color: JT.primary, size: 13),
              const SizedBox(width: 3),
              Flexible(
                child: Text(
                  _pickup == 'Getting location...' ? 'Getting location...' : _pickup.split(',').first,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white70 : JT.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ]),
          ),
        ),
        // Wallet balance chip
        if (_walletBalance > 0) ...[
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WalletScreen())),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: JT.surfaceAlt,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: JT.border),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.account_balance_wallet_rounded, color: JT.primary, size: 13),
                const SizedBox(width: 4),
                Text(
                  '₹${_walletBalance.toStringAsFixed(0)}',
                  style: GoogleFonts.poppins(color: JT.primary, fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ]),
            ),
          ),
          const SizedBox(width: 8),
        ],
        // Notification bell — outline icon in JT.primary
        GestureDetector(
          onTap: () => Navigator.push(
                  context, MaterialPageRoute(builder: (_) => const NotificationsScreen()))
              .then((_) => _fetchUnreadCount()),
          child: Stack(clipBehavior: Clip.none, children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: isDark ? _darkCard : JT.surfaceAlt,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? const Color(0xFF334155) : JT.border),
              ),
              child: Icon(Icons.notifications_outlined, color: JT.primary, size: 20),
            ),
            if (_unreadNotifCount > 0)
              Positioned(
                top: -4, right: -4,
                child: Container(
                  constraints: const BoxConstraints(minWidth: 17, minHeight: 17),
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: JT.error,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [BoxShadow(color: JT.error.withOpacity(0.4), blurRadius: 4)],
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

  // ── SEARCH BAR ────────────────────────────────────────────────────────────
  Widget _buildSearchBar(bool isDark, Color cardBg, Color textColor) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: GestureDetector(
        onTap: _openSearch,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isDark ? _darkCard : JT.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: JT.border, width: 1.5),
            boxShadow: JT.cardShadow,
          ),
          child: Row(children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: JT.surfaceAlt,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.location_on_rounded, color: JT.primary, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                Text(
                  'Where to go?',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white54 : JT.textSecondary,
                  ),
                ),
                if (_pickup.isNotEmpty && _pickup != 'Getting location...')
                  Text(
                    _pickup.split(',').first,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(fontSize: 10, color: JT.primary, fontWeight: FontWeight.w600),
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
                      gradient: JT.grad,
                      shape: BoxShape.circle,
                      boxShadow: JT.btnShadow,
                    ),
                    child: const Icon(Icons.mic_rounded, color: Colors.white, size: 20),
                  ),
                  Positioned(
                    top: -4, right: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: JT.success,
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
    );
  }

  // ── SERVICE ICONS (dynamic from vehicle categories) ───────────────────────
  Widget _buildServiceIcons(bool isDark) {
    final items = _vehicleCategories.take(6).toList();
    if (items.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Services', style: JT.h3),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: items.map((cat) => _buildServiceIcon(cat, isDark)).toList(),
        ),
      ]),
    );
  }

  Widget _buildServiceIcon(Map<String, dynamic> cat, bool isDark) {
    final name = cat['name']?.toString() ?? '';
    final type = cat['type']?.toString() ?? 'ride';
    IconData icon = Icons.directions_bike_rounded;
    if (name.toLowerCase().contains('auto')) icon = Icons.electric_rickshaw_rounded;
    else if (name.toLowerCase().contains('car') || name.toLowerCase().contains('cab')) icon = Icons.directions_car_rounded;
    else if (name.toLowerCase().contains('parcel')) icon = Icons.inventory_2_rounded;
    else if (name.toLowerCase().contains('travel') || name.toLowerCase().contains('intercity')) icon = Icons.directions_bus_rounded;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        if (type == 'parcel') {
          Navigator.push(context, MaterialPageRoute(builder: (_) => ParcelBookingScreen(
            pickupAddress: _pickup, pickupLat: _pickupLat, pickupLng: _pickupLng)));
        } else {
          _openSearchWithCategory(cat);
        }
      },
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 56, height: 56,
          decoration: BoxDecoration(
            gradient: JT.grad,
            borderRadius: BorderRadius.circular(16),
            boxShadow: JT.btnShadow,
          ),
          child: Icon(icon, color: Colors.white, size: 26),
        ),
        const SizedBox(height: 6),
        Text(name, style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : JT.textPrimary), maxLines: 1),
      ]),
    );
  }

  // ── BANNER CAROUSEL ───────────────────────────────────────────────────────
  Widget _buildBannerCarousel(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: _banners.isEmpty
        ? _buildStaticPromoBanner(isDark)
        : Column(children: [
            SizedBox(
              height: 140,
              child: PageView.builder(
                controller: _bannerPageCtrl,
                onPageChanged: (i) => setState(() => _bannerIndex = i),
                itemCount: _banners.length,
                itemBuilder: (_, i) {
                  final b = _banners[i];
                  final imgUrl = b['image_url']?.toString() ?? '';
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: JT.grad,
                      boxShadow: JT.cardShadow,
                    ),
                    child: imgUrl.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(imgUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _bannerPlaceholder(b)))
                      : _bannerPlaceholder(b),
                  );
                },
              ),
            ),
            if (_banners.length > 1) ...[
              const SizedBox(height: 8),
              Row(mainAxisAlignment: MainAxisAlignment.center, children:
                List.generate(_banners.length, (i) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: _bannerIndex == i ? 16 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: _bannerIndex == i ? JT.primary : JT.primary.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ))),
            ],
          ]),
    );
  }

  Widget _bannerPlaceholder(Map<String, dynamic> b) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: JT.grad,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(b['title']?.toString() ?? 'Special Offer', style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text('Tap to learn more', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12)),
      ]),
    );
  }

  Widget _buildStaticPromoBanner(bool isDark) {
    return Container(
      height: 130,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: JT.grad,
        boxShadow: JT.cardShadow,
      ),
      padding: const EdgeInsets.all(20),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
          JT.logoWhite(height: 28),
          const SizedBox(height: 8),
          Text('Safe, fast and affordable rides', style: GoogleFonts.poppins(color: Colors.white.withOpacity(0.85), fontSize: 12)),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: _openSearch,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
              child: Text('Book Now', style: GoogleFonts.poppins(color: JT.primary, fontSize: 12, fontWeight: FontWeight.w800)),
            ),
          ),
        ])),
        const Text('🚗', style: TextStyle(fontSize: 64)),
      ]),
    );
  }

  // ── SAVED PLACES ──────────────────────────────────────────────────────────
  Widget _buildSavedPlaces(bool isDark) {
    if (_savedPlaces.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Quick Access', style: JT.h3),
        const SizedBox(height: 10),
        Row(children: _savedPlaces.take(2).map((place) {
          final label = place['label']?.toString() ?? '';
          final address = place['address']?.toString() ?? '';
          final icon = label == 'Home' ? Icons.home_rounded : Icons.work_rounded;
          final isFirst = _savedPlaces.indexOf(place) == 0;
          return Expanded(child: GestureDetector(
            onTap: () {
              final lat = double.tryParse(place['lat']?.toString() ?? '0') ?? 0.0;
              final lng = double.tryParse(place['lng']?.toString() ?? '0') ?? 0.0;
              Navigator.push(context, MaterialPageRoute(builder: (_) => BookingScreen(
                pickup: _pickup, destination: address,
                pickupLat: _pickupLat, pickupLng: _pickupLng,
                destLat: lat != 0 ? lat : 17.385, destLng: lng != 0 ? lng : 78.4867,
              )));
            },
            child: Container(
              margin: EdgeInsets.only(right: isFirst ? 8 : 0),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? JT.surface : JT.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: JT.border),
                boxShadow: JT.cardShadow,
              ),
              child: Row(children: [
                Icon(icon, color: JT.primary, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(label, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700, color: JT.textPrimary)),
                  Text(address, style: GoogleFonts.poppins(fontSize: 10, color: isDark ? Colors.white54 : JT.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                ])),
              ]),
            ),
          ));
        }).toList()),
      ]),
    );
  }

  // ── RECENT TRIPS ──────────────────────────────────────────────────────────
  Widget _buildRecentTrips(bool isDark) {
    if (_recentTrips.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('Recent', style: JT.h3),
          const Spacer(),
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TripsHistoryScreen())),
            child: Text('See all', style: GoogleFonts.poppins(fontSize: 12, color: JT.primary, fontWeight: FontWeight.w600)),
          ),
        ]),
        const SizedBox(height: 10),
        ..._recentTrips.take(3).map((trip) {
          final dest = trip['destinationAddress']?.toString() ?? trip['destination_address']?.toString() ?? 'Unknown';
          final fare = trip['actualFare']?.toString() ?? trip['actual_fare']?.toString() ?? '';
          return GestureDetector(
            onTap: _openSearch,
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? JT.surface : JT.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? Colors.white12 : JT.border),
                boxShadow: isDark ? null : JT.cardShadow,
              ),
              child: Row(children: [
                Icon(Icons.history_rounded, color: JT.primary, size: 18),
                const SizedBox(width: 12),
                Expanded(child: Text(dest.split(',').first, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: JT.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis)),
                if (fare.isNotEmpty) Text('₹$fare', style: GoogleFonts.poppins(fontSize: 12, color: JT.textSecondary)),
              ]),
            ),
          );
        }),
      ]),
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
    final bannerColor = isArrived ? JT.success : JT.primary;

    return GestureDetector(
      onTap: () {
        if (tripId.isEmpty) return;
        Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => TrackingScreen(tripId: tripId)));
      },
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

  // ── BOTTOM NAV ───────────────────────────────────────────────────────────
  Widget _buildBottomNav(bool isDark, Color cardBg, Color textColor) {
    final iconColor = isDark ? JT.iconInactive : JT.iconInactive;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? _darkCard : JT.bg,
        border: Border(top: BorderSide(color: isDark ? const Color(0xFF334155) : JT.border, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
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
              // Center voice button — gradient circle
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VoiceBookingScreen())),
                child: Container(
                  width: 52, height: 52,
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    gradient: JT.grad,
                    shape: BoxShape.circle,
                    boxShadow: JT.btnShadow,
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
            color: active ? JT.primary.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(active ? activeIcon : inactiveIcon, size: 20, color: active ? JT.primary : JT.iconInactive),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 10,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            color: active ? JT.primary : JT.iconInactive,
          ),
        ),
      ]),
    );
  }

  // ── DRAWER ───────────────────────────────────────────────────────────────
  Widget _buildDrawer(bool isDark) {
    final drawerBg = isDark ? _darkBg : JT.bg;
    final textColor = JT.textPrimary;
    return Drawer(
      backgroundColor: drawerBg,
      child: SafeArea(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            decoration: BoxDecoration(
              gradient: isDark
                ? LinearGradient(colors: [JT.primary.withOpacity(0.15), _darkCard.withOpacity(0.8)], begin: Alignment.topLeft, end: Alignment.bottomRight)
                : const LinearGradient(colors: [JT.bgSoft, JT.bg], begin: Alignment.topLeft, end: Alignment.bottomRight),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: JT.surfaceAlt,
                child: Text(
                  _userName.isNotEmpty ? _userName[0].toUpperCase() : 'U',
                  style: GoogleFonts.poppins(color: JT.primary, fontSize: 24, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 12),
              Text(_userName, style: JT.h2),
              Text(_userPhone, style: JT.body),
            ]),
          ),
          Divider(color: isDark ? const Color(0xFF334155) : JT.border, thickness: 1),
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
      leading: Icon(icon, color: JT.primary, size: 22),
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

  static const Color _primary = Color(0xFF2F7BFF);

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
    const isDark = false;
    final query = _ctrl.text;
    final items = query.length >= 3 ? _results : _nearby;

    final sheetBg = isDark ? JT.textPrimary : Colors.white;
    final inputBg = isDark ? JT.surface : const Color(0xFFF5F8FF);
    final textColor = isDark ? Colors.white : JT.textPrimary;
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

  static const Color _primary = Color(0xFF2F7BFF);

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

    const isDark = false;
    final sheetBg = isDark ? JT.textPrimary : Colors.white;
    final cardBg = isDark ? JT.surface : const Color(0xFFF5F8FF);
    final textColor = isDark ? Colors.white : JT.textPrimary;
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

// Tutorial tip row widget used in the first-visit tutorial overlay
class _TutorialTip extends StatelessWidget {
  final String icon;
  final String title;
  final String desc;
  const _TutorialTip({required this.icon, required this.title, required this.desc});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42, height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(child: Text(icon, style: const TextStyle(fontSize: 20))),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 13, color: JT.textPrimary)),
              const SizedBox(height: 2),
              Text(desc, style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF64748B), height: 1.4)),
            ],
          ),
        ),
      ],
    );
  }
}
