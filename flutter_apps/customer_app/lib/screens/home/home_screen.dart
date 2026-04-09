import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:shimmer/shimmer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/api_config.dart';
import '../../config/jago_theme.dart';
import '../../config/safe_parse.dart';
import '../../services/auth_service.dart';
import '../../services/socket_service.dart';
import '../history/trips_history_screen.dart';
import '../wallet/wallet_screen.dart';
import '../profile/profile_screen.dart';
import '../booking/booking_screen.dart';
import '../booking/map_location_picker.dart';
import '../tracking/tracking_screen.dart';
import '../notifications/notifications_screen.dart';
import '../booking/intercity_booking_screen.dart';
import '../offers/offers_screen.dart';
import '../profile/support_chat_screen.dart';
import '../referral/referral_screen.dart';
import '../saved_places/saved_places_screen.dart';
import '../booking/parcel_booking_screen.dart';
import '../booking/voice_booking_screen.dart';
import '../booking/location_screen.dart';
import '../../services/trip_service.dart';
import '../auth/login_screen.dart';
import '../b2b/b2b_login_screen.dart';
import '../outstation_pool/outstation_pool_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final SocketService _socket = SocketService();

  String _userName = 'there';
  String _userPhone = '';
  String _pickup = 'Getting location...';
  double _pickupLat = 0.0, _pickupLng = 0.0;
  bool _locationReady = false;
  int _unreadNotifCount = 0;
  double _walletBalance = 0;
  List<Map<String, dynamic>> _vehicleCategories = [];
  List<Map<String, dynamic>> _activeServices = [];
  List<dynamic> _savedPlaces = [];
  List<Map<String, dynamic>> _recentTrips = [];
  Map<String, dynamic>? _activeTrip;
  StreamSubscription? _driverAssignedSub;
  StreamSubscription? _tripCancelledSub;
  StreamSubscription? _tripStatusSub;
  Timer? _searchingTimer; // auto-cancel if no pilot found within 5 min
  Timer?
      _statePollTimer; // 5s poll during searching — server is source of truth
  int _navIndex = 0;
  bool _homeLoading = true;
  Timer? _loadingTimeout;

  // New state: banners + feature flags + popular locations
  List<Map<String, dynamic>> _banners = [];
  int _bannerIndex = 0;
  Timer? _bannerTimer;
  final PageController _bannerPageCtrl = PageController();
  List<Map<String, dynamic>> _popularLocations = [];

  // ── Live Map state ────────────────────────────────────────────────────────
  GoogleMapController? _mapController;
  Set<Marker> _mapMarkers = {};
  Timer? _nearbyDriversTimer;
  final Map<String, BitmapDescriptor> _markerIconCache = {};
  bool _mapReady = false;

  // Brand colors — mapped to JT design system
  static const Color _primary = JT.primary;
  static const Color _darkBg = JT.textPrimary;
  static const Color _darkCard = JT.surface;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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
    _fetchPopularLocations();
    _connectSocket();
    // Safety fallback: never show loading more than 6 seconds
    _loadingTimeout = Timer(const Duration(seconds: 6), () {
      if (mounted && _homeLoading) setState(() => _homeLoading = false);
    });
    // Auto-scroll banner every 4 seconds
    _bannerTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || _banners.isEmpty) return;
      final next = (_bannerIndex + 1) % _banners.length;
      _bannerPageCtrl.animateToPage(next,
          duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    });
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _checkPendingFcmNotification());
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkActiveTrip());
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowTutorial());
    // Start nearby drivers polling (10s — battery-optimised, still smooth enough)
    _nearbyDriversTimer = Timer.periodic(
        const Duration(seconds: 10), (_) => _fetchNearbyDrivers());
    _fetchNearbyDrivers(); // fetch immediately
  }

  Future<void> _fetchUnreadCount() async {
    try {
      final headers = await AuthService.getHeaders();
      final r = await http
          .get(Uri.parse('${ApiConfig.baseUrl}/api/app/notifications?limit=1'),
              headers: headers)
          .timeout(const Duration(seconds: 8));
      if (r.statusCode == 200 && mounted) {
        final data = jsonDecode(r.body);
        setState(() => _unreadNotifCount = (data['unreadCount'] as int?) ?? 0);
      }
    } catch (_) {}
  }

  Future<void> _fetchWalletBalance() async {
    try {
      final headers = await AuthService.getHeaders();
      final r = await http
          .get(Uri.parse(ApiConfig.wallet), headers: headers)
          .timeout(const Duration(seconds: 8));
      if (r.statusCode == 200 && mounted) {
        final data = jsonDecode(r.body);
        setState(() => _walletBalance =
            double.tryParse(data['balance']?.toString() ?? '0') ?? 0.0);
      }
    } catch (_) {}
  }

  Future<void> _loadSavedPlaces() async {
    try {
      final places = await TripService.getSavedPlaces();
      if (mounted)
        setState(() => _savedPlaces = places
            .where((p) => p['label'] == 'Home' || p['label'] == 'Work')
            .toList());
    } catch (_) {}
  }

  Future<void> _loadRecentTrips() async {
    try {
      final headers = await AuthService.getHeaders();
      final r = await http.get(
          Uri.parse(
              '${ApiConfig.baseUrl}/api/app/customer/trips?limit=3&status=completed'),
          headers: headers);
      if (r.statusCode == 200 && mounted) {
        final data = jsonDecode(r.body);
        final trips =
            (data['trips'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ??
                [];
        setState(() => _recentTrips = trips);
      }
    } catch (_) {}
  }

  Future<void> _fetchBanners() async {
    try {
      final headers = await AuthService.getHeaders();
      final r = await http
          .get(Uri.parse('${ApiConfig.baseUrl}/api/app/banners'),
              headers: headers)
          .timeout(const Duration(seconds: 6));
      if (r.statusCode == 200 && mounted) {
        final data = jsonDecode(r.body) as Map<String, dynamic>;
        final list =
            (data['banners'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ??
                [];
        setState(() => _banners = list);
      }
    } catch (_) {}
  }

  Future<void> _fetchPopularLocations() async {
    try {
      final headers = await AuthService.getHeaders();
      final params = <String, String>{};
      if (_pickupLat != 0.0 && _pickupLng != 0.0) {
        params['lat'] = _pickupLat.toString();
        params['lng'] = _pickupLng.toString();
      }
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/app/popular-locations')
          .replace(queryParameters: params.isNotEmpty ? params : null);
      final r = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 6));
      if (r.statusCode == 200 && mounted) {
        final data = jsonDecode(r.body) as Map<String, dynamic>;
        final list = (data['locations'] as List<dynamic>?)
                ?.cast<Map<String, dynamic>>() ??
            [];
        if (list.isNotEmpty) {
          setState(() => _popularLocations = list);
        }
      }
    } catch (_) {}
  }

  IconData _iconForPlace(String name) {
    final n = name.toLowerCase();
    if (n.contains('airport') || n.contains('gannavaram')) return Icons.flight_takeoff_rounded;
    if (n.contains('railway') || n.contains('station') || n.contains('junction')) return Icons.train_rounded;
    if (n.contains('bus') || n.contains('stand')) return Icons.directions_bus_rounded;
    if (n.contains('temple') || n.contains('durga') || n.contains('mandir')) return Icons.temple_hindu_rounded;
    if (n.contains('hospital')) return Icons.local_hospital_rounded;
    if (n.contains('mall') || n.contains('market')) return Icons.shopping_bag_rounded;
    if (n.contains('college') || n.contains('university')) return Icons.school_rounded;
    return Icons.location_city_rounded;
  }

  Color _colorForPlace(String name) {
    final n = name.toLowerCase();
    if (n.contains('airport')) return const Color(0xFF1E88E5);
    if (n.contains('railway') || n.contains('station')) return const Color(0xFFE53935);
    if (n.contains('bus')) return const Color(0xFF5E35B1);
    if (n.contains('temple')) return const Color(0xFFFF8F00);
    if (n.contains('hospital')) return const Color(0xFFD32F2F);
    return const Color(0xFF43A047);
  }

  Future<void> _fetchFeatureFlags() async {
    try {
      final r = await http
          .get(Uri.parse('${ApiConfig.baseUrl}/api/app/feature-flags'))
          .timeout(const Duration(seconds: 6));
      if (r.statusCode == 200 && mounted) {
        // feature flags loaded (unused by current UI)
      }
    } catch (_) {}
  }

  // ── LIVE MAP: Nearby Drivers ─────────────────────────────────────────────

  Future<BitmapDescriptor> _getVehicleMarkerIcon(String vehicleType) async {
    if (_markerIconCache.containsKey(vehicleType))
      return _markerIconCache[vehicleType]!;
    final descriptor = await _drawVehicleMarker(vehicleType);
    _markerIconCache[vehicleType] = descriptor;
    return descriptor;
  }

  Future<BitmapDescriptor> _drawVehicleMarker(String vehicleType) async {
    const size = 72.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, size, size));

    // Pick color + emoji by vehicle type
    Color bg;
    String emoji;
    if (vehicleType.contains('bike') || vehicleType.contains('moto')) {
      bg = const Color(0xFF2F7BFF);
      emoji = '🏍️';
    } else if (vehicleType.contains('auto')) {
      bg = const Color(0xFF5B9DFF);
      emoji = '🛺';
    } else if (vehicleType.contains('parcel') ||
        vehicleType.contains('cargo')) {
      bg = const Color(0xFF1A6FDB);
      emoji = '📦';
    } else {
      bg = const Color(0xFF2563EB);
      emoji = '🚗';
    }

    // Shadow
    final shadowPaint = Paint()
      ..color = bg.withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(
        const Offset(size / 2, size / 2 + 2), size / 2 - 6, shadowPaint);

    // Circle background
    canvas.drawCircle(
        const Offset(size / 2, size / 2), size / 2 - 8, Paint()..color = bg);

    // White border
    canvas.drawCircle(
      const Offset(size / 2, size / 2),
      size / 2 - 8,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    // Emoji
    final tp = TextPainter(
      text: TextSpan(text: emoji, style: const TextStyle(fontSize: 26)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset((size - tp.width) / 2, (size - tp.height) / 2 - 1));

    final picture = recorder.endRecording();
    final img = await picture.toImage(size.toInt(), size.toInt());
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(data!.buffer.asUint8List());
  }

  Future<void> _fetchNearbyDrivers() async {
    if (!mounted || !_locationReady) return;
    try {
      final headers = await AuthService.getHeaders();
      final uri = Uri.parse(ApiConfig.nearbyDrivers).replace(queryParameters: {
        'lat': _pickupLat.toString(),
        'lng': _pickupLng.toString(),
        'radius': '5',
      });
      final r = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 5));
      if (!mounted || r.statusCode != 200) return;

      final data = jsonDecode(r.body) as Map<String, dynamic>;
      final drivers =
          (data['drivers'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ??
              [];

      final Set<Marker> newMarkers = {};
      for (final d in drivers) {
        final lat = double.tryParse(d['lat']?.toString() ?? '');
        final lng = double.tryParse(d['lng']?.toString() ?? '');
        if (lat == null || lng == null) continue;

        final id = d['id']?.toString() ?? '';
        final vehicleType =
            (d['vehicleCategoryName'] ?? d['vehicleName'] ?? 'car')
                .toString()
                .toLowerCase();
        final heading = double.tryParse(d['heading']?.toString() ?? '0') ?? 0;
        final rating = double.tryParse(d['rating']?.toString() ?? '0') ?? 0;

        final icon = await _getVehicleMarkerIcon(vehicleType);

        newMarkers.add(Marker(
          markerId: MarkerId('driver_$id'),
          position: LatLng(lat, lng),
          icon: icon,
          rotation: heading,
          anchor: const Offset(0.5, 0.5),
          flat: true, // rotates with map
          infoWindow: InfoWindow(
            title: d['fullName']?.toString() ?? 'Driver',
            snippet: rating > 0 ? '⭐ ${rating.toStringAsFixed(1)}' : null,
          ),
        ));
      }

      if (mounted) setState(() => _mapMarkers = newMarkers);
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
        if (type == 'trip_accepted' ||
            type == 'driver_assigned' ||
            type == 'driver_arrived') {
          // Verify trip is still active — prevents stale FCM from causing blank screen
          try {
            final verifyHeaders = await AuthService.getHeaders();
            final tripCheck = await http.get(Uri.parse(ApiConfig.activeTrip),
                headers: verifyHeaders);
            if (tripCheck.statusCode == 200) {
              final td = jsonDecode(tripCheck.body);
              final activeT = td['trip'] as Map<String, dynamic>?;
              if (activeT == null) return;
              final st = activeT['currentStatus']?.toString() ?? '';
              if (st == 'completed' || st == 'cancelled' || st.isEmpty) return;
            } else {
              return;
            }
          } catch (_) {
            return;
          }
          if (!mounted) return;
          Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (_) => TrackingScreen(tripId: tripId)));
        }
      }
    } catch (_) {}
  }

  Future<void> _checkActiveTrip() async {
    try {
      final headers = await AuthService.getHeaders();
      final r =
          await http.get(Uri.parse(ApiConfig.activeTrip), headers: headers);
      if (!mounted) return;
      if (r.statusCode == 401) {
        _handleUnauthorized();
        return;
      }
      if (r.statusCode == 200) {
        final data = jsonDecode(r.body);
        final trip = data['trip'] as Map<String, dynamic>?;
        if (trip != null) {
          final status = trip['currentStatus']?.toString() ?? '';
          if (status != 'completed' && status != 'cancelled') {
            setState(() => _activeTrip = trip);
            // Start auto-cancel timer if searching and no pilot found yet
            if (status == 'searching') {
              _startSearchingTimer(trip['id']?.toString() ?? '');
            }
            // Fix 7: if driver already assigned/in-progress, go straight to TrackingScreen
            if (['accepted', 'arrived', 'on_the_way', 'driver_assigned']
                .contains(status)) {
              final tripId = trip['id']?.toString() ?? '';
              if (tripId.isNotEmpty && mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TrackingScreen(tripId: tripId),
                  ),
                );
              }
            }
          }
        }
      }
    } catch (_) {}
  }

  void _startSearchingTimer(String tripId) {
    _searchingTimer?.cancel();
    // Auto-cancel after 5 minutes if still searching
    _searchingTimer =
        Timer(const Duration(minutes: 5), () => _autoCancelSearching(tripId));
    // Poll server every 5s while searching — catches driver acceptance when socket is down
    _statePollTimer?.cancel();
    _statePollTimer =
        Timer.periodic(const Duration(seconds: 5), (_) => _pollTripState());
  }

  Future<void> _pollTripState() async {
    if (!mounted || _activeTrip == null) {
      _statePollTimer?.cancel();
      return;
    }
    try {
      final headers = await AuthService.getHeaders();
      final r = await http
          .get(Uri.parse(ApiConfig.activeTrip), headers: headers)
          .timeout(const Duration(seconds: 4));
      if (!mounted) return;
      if (r.statusCode == 200) {
        final data = jsonDecode(r.body);
        final trip = data['trip'] as Map<String, dynamic>?;
        if (trip == null) {
          // Trip gone — cancelled or completed
          _statePollTimer?.cancel();
          _searchingTimer?.cancel();
          setState(() => _activeTrip = null);
          return;
        }
        final status = trip['currentStatus']?.toString() ?? '';
        if (status == 'completed' || status == 'cancelled') {
          _statePollTimer?.cancel();
          _searchingTimer?.cancel();
          setState(() => _activeTrip = null);
          return;
        }
        setState(() => _activeTrip = trip);
        // Driver accepted while socket was down → navigate to tracking
        if (['accepted', 'arrived', 'on_the_way', 'driver_assigned']
            .contains(status)) {
          _statePollTimer?.cancel();
          _searchingTimer?.cancel();
          final tripId = trip['id']?.toString() ?? '';
          if (tripId.isNotEmpty && mounted) {
            Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (_) => TrackingScreen(tripId: tripId)));
          }
        }
      }
    } catch (_) {} // network error — keep polling
  }

  Future<void> _autoCancelSearching(String tripId) async {
    if (!mounted || _activeTrip == null) return;
    final status = _activeTrip!['currentStatus']?.toString() ?? '';
    if (status != 'searching') return;
    try {
      final h = await AuthService.getHeaders();
      await http.post(Uri.parse(ApiConfig.cancelTrip),
          headers: {...h, 'Content-Type': 'application/json'},
          body: jsonEncode({
            'tripId': tripId,
            'reason': 'Auto-cancelled: no pilot available nearby'
          }));
    } catch (_) {}
    if (!mounted) return;
    setState(() => _activeTrip = null);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('No pilot found nearby. Ride auto-cancelled.',
          style: GoogleFonts.poppins(
              color: Colors.white, fontWeight: FontWeight.w400, fontSize: 13)),
      backgroundColor: JT.primaryDark,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 5),
    ));
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
                  color: JT.primary,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Row(
                  children: [
                    const Text('👋', style: TextStyle(fontSize: 28)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Welcome!',
                                style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w400,
                                    fontSize: 18)),
                            Text('Here\'s a quick guide to get you started',
                                style: GoogleFonts.poppins(
                                    color: Colors.white.withValues(alpha: 0.85),
                                    fontSize: 12)),
                          ]),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _TutorialTip(
                        icon: '🔍',
                        title: 'Search Destination',
                        desc:
                            'Tap "Where do you want to go?" to search for your destination and see instant fare estimates.'),
                    const SizedBox(height: 14),
                    _TutorialTip(
                        icon: '🚗',
                        title: 'Choose a Service',
                        desc:
                            'Select from Auto, Bike, Car, Ride Pool, Parcel, and more based on your need.'),
                    const SizedBox(height: 14),
                    _TutorialTip(
                        icon: '💳',
                        title: 'Wallet & Payments',
                        desc:
                            'Recharge your wallet for cashless rides. Tap the wallet icon in the top right.'),
                    const SizedBox(height: 14),
                    _TutorialTip(
                        icon: '🔔',
                        title: 'Stay Updated',
                        desc:
                            'Enable notifications to get real-time alerts for your rides, offers, and more.'),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: JT.gradientButton(
                          label: "Got it, Let's Go!",
                          onTap: () => Navigator.pop(ctx)),
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
              Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (_) => TrackingScreen(tripId: tripId)));
            }
          }
        });

        // Clear active trip state when trip is cancelled or completed
        _tripCancelledSub = _socket.onTripCancelled.listen((data) {
          if (!mounted) return;
          _searchingTimer?.cancel();
          _statePollTimer?.cancel();
          setState(() => _activeTrip = null);
        });
        _tripStatusSub = _socket.onTripStatus.listen((data) {
          if (!mounted) return;
          final status = data['status']?.toString() ?? '';
          if (status == 'completed' || status == 'cancelled') {
            _searchingTimer?.cancel();
            _statePollTimer?.cancel();
            setState(() => _activeTrip = null);
          }
        });
      });
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _loadingTimeout?.cancel();
    _bannerTimer?.cancel();
    _searchingTimer?.cancel();
    _statePollTimer?.cancel();
    _bannerPageCtrl.dispose();
    _driverAssignedSub?.cancel();
    _tripCancelledSub?.cancel();
    _tripStatusSub?.cancel();
    _nearbyDriversTimer?.cancel();
    _mapController?.dispose();
    // Don't disconnect socket — it's a shared singleton used by other screens
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      // App went to background — pause the nearby-drivers poll to save battery
      _nearbyDriversTimer?.cancel();
      _nearbyDriversTimer = null;
    } else if (state == AppLifecycleState.resumed) {
      // App came back to foreground — refresh pickup location and restart polling
      _getLocation();
      if (_nearbyDriversTimer == null) {
        _nearbyDriversTimer = Timer.periodic(
            const Duration(seconds: 10), (_) => _fetchNearbyDrivers());
        _fetchNearbyDrivers(); // refresh immediately on resume
      }
    }
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _userName = prefs.getString('user_name') ?? 'there';
      _userPhone = prefs.getString('user_phone') ?? '';
    });
  }

  Future<void> _showLocationPrompt({
    required String title,
    required String message,
    required Future<bool> Function() openSettings,
  }) async {
    if (!mounted) return;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await openSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  Future<void> _getLocation() async {
    // Step 1: Instant fallback — no GPS wait
    Position? fallback;
    try { fallback = await Geolocator.getLastKnownPosition(); } catch (_) {}

    // Step 2: Check GPS services
    bool serviceOn = false;
    try { serviceOn = await Geolocator.isLocationServiceEnabled(); } catch (_) {}

    if (!serviceOn) {
      if (fallback != null && mounted) {
        _applyPosition(fallback, label: 'Current Location');
      } else if (mounted) {
        setState(() { _pickup = 'Turn on location to detect pickup'; _locationReady = false; });
        await _showLocationPrompt(
          title: 'Location Services Off',
          message: 'Turn on device location so we can detect your live pickup point accurately.',
          openSettings: Geolocator.openLocationSettings,
        );
        // Re-check after user returns from settings
        try { serviceOn = await Geolocator.isLocationServiceEnabled(); } catch (_) {}
        if (!serviceOn) return;
      } else {
        return;
      }
    }

    // Step 3: Check permission
    LocationPermission perm = LocationPermission.denied;
    try {
      perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
    } catch (_) {}

    if (perm == LocationPermission.deniedForever) {
      if (fallback != null && mounted) {
        _applyPosition(fallback, label: 'Current Location');
      }
      if (!mounted) return;
      setState(() { _pickup = 'Location blocked. Tap to open settings.'; _locationReady = fallback != null; });
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
    if (perm == LocationPermission.denied) {
      if (fallback != null && mounted) _applyPosition(fallback, label: 'Current Location');
      if (mounted && fallback == null) {
        setState(() { _pickup = 'Location permission needed'; _locationReady = false; });
      }
      return;
    }

    // Step 4: Permission granted — get accurate position
    // Show fallback immediately for fast UI response
    if (fallback != null && !_locationReady) {
      _applyPosition(fallback, label: 'Current Location');
    }

    Position? pos;
    try {
      pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 12),
        ),
      );
    } catch (_) {
      pos = fallback;
    }

    if (pos != null && mounted) {
      _applyPosition(pos);
    } else if (mounted && !_locationReady) {
      setState(() { _pickup = 'Tap to detect your location'; _locationReady = false; });
    }
  }

  void _applyPosition(Position pos, {String? label}) {
    if (!mounted) return;
    setState(() {
      _pickupLat = pos.latitude;
      _pickupLng = pos.longitude;
      _locationReady = true;
      _pickup = label ?? 'Current Location';
    });
    _reverseGeocode(pos.latitude, pos.longitude);
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(LatLng(pos.latitude, pos.longitude), 15),
    );
    _fetchNearbyDrivers();
  }

  Future<void> _reverseGeocode(double lat, double lng) async {
    // Try server proxy first
    try {
      final headers = await AuthService.getHeaders();
      final res = await http.get(
        Uri.parse('${ApiConfig.reverseGeocode}?lat=$lat&lng=$lng'),
        headers: headers,
      ).timeout(const Duration(seconds: 6));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        // Try structured fields first, then formattedAddress
        final parts = <String>[];
        for (final k in ['area', 'city', 'state']) {
          final v = data[k]?.toString() ?? '';
          if (v.isNotEmpty && !parts.contains(v)) parts.add(v);
        }
        if (parts.isNotEmpty && mounted) {
          setState(() => _pickup = parts.take(3).join(', '));
          return;
        }
        final addr = data['formattedAddress']?.toString() ?? '';
        if (mounted && addr.isNotEmpty) {
          setState(() => _pickup = addr.split(',').take(3).join(',').trim());
          return;
        }
      }
    } catch (_) {}
    // Nominatim fallback — no key required
    try {
      final res = await http.get(
        Uri.parse(
            'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lng'),
        headers: const {'User-Agent': 'JagoPro/1.0'},
      ).timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final addr = data['display_name']?.toString() ?? '';
        if (mounted && addr.isNotEmpty) {
          final short = addr.split(',').take(3).join(',').trim();
          setState(() => _pickup = short.isNotEmpty ? short : 'Current Location');
          return;
        }
      }
    } catch (_) {}
    // Final fallback — always show something meaningful
    if (mounted) {
      setState(() => _pickup = 'Current Location');
    }
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
      final r = await http
          .get(Uri.parse(ApiConfig.customerHomeData), headers: headers)
          .timeout(const Duration(seconds: 6));
      if (r.statusCode == 401) {
        if (mounted) setState(() => _homeLoading = false);
        _handleUnauthorized();
        return;
      }
      if (r.statusCode == 200 && mounted) {
        final data = jsonDecode(r.body) as Map<String, dynamic>;
        final cats = (data['vehicleCategories'] as List<dynamic>?)
                ?.cast<Map<String, dynamic>>() ??
            [];
        setState(() => _vehicleCategories = cats);
      }
    } catch (_) {}
    if (mounted) setState(() => _homeLoading = false);
  }

  Future<void> _fetchActiveServices() async {
    try {
      final headers = await AuthService.getHeaders();
      // Use location-based endpoint for city-filtered services
      final uri =
          Uri.parse(ApiConfig.servicesForLocation).replace(queryParameters: {
        if (_locationReady) 'lat': _pickupLat.toString(),
        if (_locationReady) 'lng': _pickupLng.toString(),
      });
      final r = await http.get(uri, headers: headers);
      if (r.statusCode == 200 && mounted) {
        final data = jsonDecode(r.body) as Map<String, dynamic>;
        final services = (data['services'] as List<dynamic>?)
                ?.cast<Map<String, dynamic>>() ??
            [];
        setState(() => _activeServices = services);
      }
    } catch (_) {
      // Fallback to non-location endpoint
      try {
        final headers = await AuthService.getHeaders();
        final r = await http.get(Uri.parse(ApiConfig.activeServices),
            headers: headers);
        if (r.statusCode == 200 && mounted) {
          final data = jsonDecode(r.body) as Map<String, dynamic>;
          final services = (data['services'] as List<dynamic>?)
                  ?.cast<Map<String, dynamic>>() ??
              [];
          setState(() => _activeServices = services);
        }
      } catch (_) {}
    }
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
        return {'emoji': '🛺', 'color': const Color(0xFF5B9DFF)};
      case 'parcel_delivery':
      case 'parcel':
        return {'emoji': '📦', 'color': const Color(0xFF1A6FDB)};
      case 'cargo':
      case 'cargo_freight':
        return {'emoji': '🚛', 'color': const Color(0xFF2563EB)};
      case 'mini_car':
      case 'car':
        return {'emoji': '🚗', 'color': const Color(0xFF2563EB)};
      case 'sedan':
        return {'emoji': '🚗', 'color': const Color(0xFF1A6FDB)};
      default:
        return {'emoji': '🚖', 'color': _primary};
    }
  }

  Color _colorFromHex(String? hex, Color fallback) {
    if (hex == null || hex.isEmpty) return fallback;
    try {
      final h = hex.replaceAll('#', '');
      return Color(int.parse('FF$h', radix: 16));
    } catch (_) {
      return fallback;
    }
  }

  Map<String, dynamic> _vehicleStyle(String name) {
    final n = name.toLowerCase();
    if (n.contains('bike parcel') || n.contains('parcel bike'))
      return {
        'icon': Icons.inventory_2_rounded,
        'color': const Color(0xFF1A6FDB),
        'gradient': [const Color(0xFF1A6FDB), const Color(0xFF1A6FDB)],
      };
    if (n.contains('bike'))
      return {
        'icon': Icons.electric_bike_rounded,
        'color': JT.primary,
        'gradient': [JT.primary, JT.primary],
      };
    if (n.contains('auto'))
      return {
        'icon': Icons.electric_rickshaw_rounded,
        'color': const Color(0xFF5B9DFF),
        'gradient': [const Color(0xFF5B9DFF), const Color(0xFF5B9DFF)],
      };
    if (n.contains('truck') ||
        n.contains('cargo') ||
        n.contains('tata') ||
        n.contains('pickup'))
      return {
        'icon': Icons.local_shipping_rounded,
        'color': const Color(0xFF2563EB),
        'gradient': [const Color(0xFF2563EB), const Color(0xFF2563EB)],
      };
    if (n.contains('parcel') || n.contains('delivery'))
      return {
        'icon': Icons.inventory_2_rounded,
        'color': const Color(0xFF1A6FDB),
        'gradient': [const Color(0xFF1A6FDB), const Color(0xFF1A6FDB)],
      };
    if (n.contains('suv') || n.contains('car') || n.contains('cab'))
      return {
        'icon': Icons.directions_car_filled_rounded,
        'color': const Color(0xFF2563EB),
        'gradient': [const Color(0xFF2563EB), const Color(0xFF2563EB)],
      };
    if (n.contains('pool') ||
        n.contains('share') ||
        n.contains('all') ||
        n.contains('service'))
      return {
        'icon': Icons.grid_view_rounded,
        'color': JT.primary,
        'gradient': [JT.primary, JT.primary],
      };
    return {
      'icon': Icons.directions_car_filled_rounded,
      'color': JT.primary,
      'gradient': [JT.primary, JT.primary],
    };
  }

  static String _normalizeServiceKey(String value) {
    return value
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
  }

  String _serviceDisplayName(Map<String, dynamic> item) {
    final raw = (item['name'] ?? item['service_name'] ?? item['vehicleCategoryName'] ?? item['key'] ?? '').toString().trim();
    return raw;
  }

  bool _serviceMatchesType(Map<String, dynamic> item, String type) {
    final rawType = (item['type'] ?? item['category'] ?? item['serviceType'] ?? item['kind'] ?? '').toString().toLowerCase();
    final rawName = _serviceDisplayName(item).toLowerCase();
    if (type == 'ride') {
      return rawType == 'ride' ||
          rawName.contains('bike') ||
          rawName.contains('auto') ||
          rawName.contains('car');
    }
    if (type == 'parcel') {
      return rawType == 'parcel' ||
          rawType == 'cargo' ||
          rawName.contains('parcel') ||
          rawName.contains('truck') ||
          rawName.contains('van') ||
          rawName.contains('cargo');
    }
    if (type == 'pool') {
      return rawType == 'pool' ||
          rawName.contains('pool') ||
          rawName.contains('share');
    }
    return rawType == type || rawName.contains(type);
  }

  List<String> _serviceNamesForType(String type) {
    final names = <String>{};
    for (final item in [..._vehicleCategories, ..._activeServices]) {
      if (!_serviceMatchesType(item, type)) continue;
      final display = _serviceDisplayName(item);
      if (display.isNotEmpty) names.add(display);
      final key = _normalizeServiceKey((item['key'] ?? item['service_key'] ?? item['slug'] ?? display).toString());
      if (key.isNotEmpty) names.add(key.replaceAll('_', ' '));
    }
    return names.toList();
  }

  String _serviceSummaryForType(String type, String fallback) {
    final names = _serviceNamesForType(type);
    if (names.isEmpty) return fallback;
    return names.take(3).join(' · ');
  }

  String _serviceStatusForType(String type) {
    final names = _serviceNamesForType(type);
    if (names.isEmpty) return 'LIVE';
    return '${names.length} active';
  }

  void _openSearch({String? presetVehicle}) {
    // Rule: ALL ride entry points go Home → LocationScreen → BookingScreen
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => LocationScreen(
            serviceType: 'ride',
            pickupAddress: _pickup.isNotEmpty ? _pickup : null,
            pickupLat: _pickupLat,
            pickupLng: _pickupLng,
          ),
        ));
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
        activeServices: _activeServices,
        pickup: _pickup,
        pickupLat: _pickupLat,
        pickupLng: _pickupLng,
        onServiceTap: (cat) {
          Navigator.pop(ctx);
          if (cat['type'] == 'parcel' ||
              (cat['key']?.toString().contains('parcel') ?? false)) {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => ParcelBookingScreen(
                        pickupAddress: _pickup,
                        pickupLat: _pickupLat,
                        pickupLng: _pickupLng)));
          } else {
            _openSearchWithCategory(cat);
          }
        },
      ),
    );
  }

  void _openSearchWithCategory(Map<String, dynamic> cat) {
    final isParcel = cat['type'] == 'parcel' ||
        (cat['key']?.toString().contains('parcel') ?? false);
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => LocationScreen(
            serviceType: isParcel ? 'parcel' : 'ride',
            pickupAddress: _pickup.isNotEmpty ? _pickup : null,
            pickupLat: _pickupLat,
            pickupLng: _pickupLng,
            vehicleCategoryId: cat['id']?.toString(),
            vehicleCategoryName: cat['name']?.toString(),
          ),
        ));
  }

  @override
  Widget build(BuildContext context) {
    const isDark = false;
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      drawer: _buildDrawer(isDark),
      body: SafeArea(
        child: Column(
          children: [
            // ── Active trip banner ──
            if (_activeTrip != null) _buildActiveTripBanner(isDark),
            // ── Scrollable home content ──
            Expanded(
              child: _homeLoading
                  ? _buildSkeletonLoader(isDark, JT.bgSoft)
                  : SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Search bar
                          _buildSearchBar(isDark, JT.bgSoft, JT.textPrimary),
                          // Recent places
                          _buildRecentPlacesSection(),
                          // "Everything In Minutes" service cards
                          _buildEverythingInMinutes(isDark),
                          // "Explore" vehicle types
                          _buildExploreSection(isDark),
                          // "Go Places with Jago" horizontal cards
                          _buildGoPlacesSection(),
                          // Brand banner
                          _buildJagoBrandBanner(),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
            ),
            // ── Bottom navigation ──
            _buildBottomNav(isDark, JT.bg, JT.textPrimary),
          ],
        ),
      ),
    );
  }

  Widget _buildRecenterButton() {
    return const SizedBox.shrink(); // Not used in new layout
  }

  Widget _buildSkeletonLoader(bool isDark, Color cardBg) {
    final baseColor =
        isDark ? const Color(0xFF2A3A50) : const Color(0xFFE5E7EB);
    final highlightColor =
        isDark ? const Color(0xFF3A4E66) : const Color(0xFFF3F4F6);
    Widget box(double w, double h, {double r = 10}) => Container(
          width: w,
          height: h,
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(r)),
        );
    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Search bar skeleton
          box(double.infinity, 52, r: 14),
          const SizedBox(height: 20),
          // Service icons skeleton label
          box(120, 18, r: 8),
          const SizedBox(height: 12),
          Row(
              children: List.generate(
                  4,
                  (_) => Expanded(
                          child: Padding(
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
      ),
    );
  }

  // ── TOP BAR — not used in new layout (search bar is the first element) ──
  Widget _buildTopBar(bool isDark, Color cardBg, Color textColor) {
    return const SizedBox.shrink(); // Replaced by scrollable layout
  }

  // ── SEARCH BAR — Rapido-style clean "Where are you going?" ────────────────
  Widget _buildSearchBar(bool isDark, Color cardBg, Color textColor) {
    final nearbyCount = _mapMarkers.length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Location + Nearby count row
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(children: [
            GestureDetector(
              onTap: () => _scaffoldKey.currentState?.openDrawer(),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.menu_rounded, color: JT.textPrimary, size: 20),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GestureDetector(
                onTap: () async {
                  final result = await Navigator.push<PickedLocation>(context,
                    MaterialPageRoute(builder: (_) => MapLocationPicker(
                      title: 'Select Pickup Location',
                      initialLat: _pickupLat, initialLng: _pickupLng,
                    )));
                  if (result != null && mounted) {
                    setState(() {
                      _pickupLat = result.lat; _pickupLng = result.lng;
                      _pickup = result.address; _locationReady = true;
                    });
                  }
                },
                child: Row(children: [
                  Icon(Icons.location_on_rounded, color: JT.primary, size: 16),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      _pickup == 'Getting location...' ? 'Getting location...' : _pickup.split(',').first,
                      style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: JT.textPrimary),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(Icons.keyboard_arrow_down_rounded, color: JT.textSecondary, size: 18),
                ]),
              ),
            ),
            const SizedBox(width: 8),
            // Notification bell
            GestureDetector(
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const NotificationsScreen()))
                  .then((_) => _fetchUnreadCount()),
              child: Stack(clipBehavior: Clip.none, children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.notifications_outlined, color: JT.textPrimary, size: 20),
                ),
                if (_unreadNotifCount > 0)
                  Positioned(top: -2, right: -2,
                    child: Container(
                      width: 16, height: 16,
                      decoration: BoxDecoration(color: JT.error, shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5)),
                      child: Center(child: Text(
                        _unreadNotifCount > 9 ? '9+' : _unreadNotifCount.toString(),
                        style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w600),
                      )),
                    ),
                  ),
              ]),
            ),
          ]),
        ),
        // Search bar
        GestureDetector(
          onTap: (_pickup.contains('retry') || _pickup.contains('Tap'))
              ? _getLocation
              : _openSearch,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Row(children: [
              Icon(Icons.search_rounded, color: JT.textSecondary, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Where are you going?',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: JT.textSecondary,
                  ),
                ),
              ),
            ]),
          ),
        ),
        // Live nearby driver count
        if (nearbyCount > 0)
          Padding(
            padding: const EdgeInsets.only(top: 10, left: 4),
            child: Row(children: [
              Container(
                width: 8, height: 8,
                decoration: const BoxDecoration(color: Color(0xFF22C55E), shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(
                '$nearbyCount ${nearbyCount == 1 ? 'driver' : 'drivers'} nearby',
                style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF22C55E), fontWeight: FontWeight.w500),
              ),
            ]),
          ),
      ]),
    );
  }

  // ── RECENT PLACES — history with heart icon ──────────────────────────────
  Widget _buildRecentPlacesSection() {
    // Combine saved places + recent trips
    final List<Map<String, dynamic>> recentItems = [];
    for (final place in _savedPlaces) {
      recentItems.add({
        'name': place['label']?.toString() ?? '',
        'address': place['address']?.toString() ?? '',
        'lat': double.tryParse(place['lat']?.toString() ?? '0') ?? 0.0,
        'lng': double.tryParse(place['lng']?.toString() ?? '0') ?? 0.0,
        'isSaved': true,
      });
    }
    for (final trip in _recentTrips.take(3)) {
      final dest = trip['destinationAddress']?.toString() ??
          trip['destination_address']?.toString() ?? '';
      if (dest.isNotEmpty) {
        recentItems.add({
          'name': dest.split(',').first.trim(),
          'address': dest,
          'lat': double.tryParse(trip['destLat']?.toString() ?? '0') ?? 0.0,
          'lng': double.tryParse(trip['destLng']?.toString() ?? '0') ?? 0.0,
          'isSaved': false,
        });
      }
    }
    if (recentItems.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F6FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDBE8F5), width: 1),
      ),
      child: Column(
        children: recentItems.take(3).map((item) {
          final name = item['name'] as String;
          final address = item['address'] as String;
          final isSaved = item['isSaved'] as bool;
          return InkWell(
            onTap: () {
              final lat = item['lat'] as double;
              final lng = item['lng'] as double;
              if (lat != 0.0 && lng != 0.0) {
                Navigator.push(context,
                    MaterialPageRoute(
                        builder: (_) => BookingScreen(
                              pickup: _pickup,
                              destination: address,
                              pickupLat: _pickupLat,
                              pickupLng: _pickupLng,
                              destLat: lat,
                              destLng: lng,
                            )));
              } else {
                _openSearch();
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: const Color(0xFFDBE8F5),
                    width: 1,
                    style: BorderStyle.solid,
                  ),
                ),
              ),
              child: Row(children: [
                Icon(
                  Icons.access_time_rounded,
                  color: JT.textSecondary,
                  size: 20,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: JT.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (address.isNotEmpty && address != name)
                        Text(
                          address,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: JT.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                Icon(
                  isSaved ? Icons.favorite_border_rounded : Icons.favorite_border_rounded,
                  color: JT.textTertiary,
                  size: 20,
                ),
              ]),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── "EVERYTHING IN MINUTES" — Rapido-style 2×2 service cards ──────────────
  Widget _buildEverythingInMinutes(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Everything In Minutes',
            style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: JT.textPrimary)),
        const SizedBox(height: 14),
        Row(children: [
          // Send anything — Parcel
          Expanded(
            child: _serviceCard(
              subtitle: 'Send anything',
              title: 'Parcel',
              bgColor: const Color(0xFFFFF8F0),
              icon: Icons.inventory_2_rounded,
              iconColor: const Color(0xFFE8943A),
              onTap: () {
                HapticFeedback.selectionClick();
                Navigator.push(context,
                    MaterialPageRoute(
                        builder: (_) => LocationScreen(
                              serviceType: 'parcel',
                              pickupAddress: _pickup.isNotEmpty ? _pickup : null,
                              pickupLat: _pickupLat,
                              pickupLng: _pickupLng,
                            )));
              },
            ),
          ),
          const SizedBox(width: 12),
          // Beat the traffic — Bike Taxi
          Expanded(
            child: _serviceCard(
              subtitle: 'Beat the traffic',
              title: 'Bike Taxi',
              bgColor: const Color(0xFFF5F5F5),
              icon: Icons.electric_bike_rounded,
              iconColor: JT.textPrimary,
              onTap: () {
                HapticFeedback.selectionClick();
                _openSearch();
              },
            ),
          ),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          // Your everyday rides — Book now
          Expanded(
            child: _serviceCard(
              subtitle: 'Your everyday rides',
              title: 'Book now',
              bgColor: const Color(0xFFF0FFF0),
              icon: Icons.electric_rickshaw_rounded,
              iconColor: const Color(0xFF3CB371),
              onTap: () {
                HapticFeedback.selectionClick();
                _openSearch();
              },
            ),
          ),
          const SizedBox(width: 12),
          // All Services
          Expanded(
            child: _serviceCard(
              subtitle: '',
              title: 'All\nServices',
              bgColor: const Color(0xFFF5F5F5),
              icon: Icons.grid_view_rounded,
              iconColor: JT.textSecondary,
              onTap: () {
                HapticFeedback.selectionClick();
                _showAllServicesSheet();
              },
            ),
          ),
        ]),
      ]),
    );
  }

  Widget _serviceCard({
    required String subtitle,
    required String title,
    required Color bgColor,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 110,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Stack(children: [
          // Background icon
          Positioned(
            right: -8,
            bottom: -8,
            child: Icon(icon, size: 64, color: iconColor.withValues(alpha: 0.12)),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (subtitle.isNotEmpty) ...[
                Text(subtitle,
                    style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: JT.textSecondary,
                        fontWeight: FontWeight.w400)),
                const SizedBox(height: 2),
              ],
              Text(title,
                  style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: JT.textPrimary,
                      height: 1.2)),
            ],
          ),
        ]),
      ),
    );
  }

  // ── LEGACY FEATURED GRID (kept for compatibility) ──────────────────────
  Widget _buildFeaturedGrid(bool isDark) {
    final rideNames = _serviceNamesForType('ride');
    final parcelNames = _serviceNamesForType('parcel');
    final hasRide = rideNames.isNotEmpty;
    final hasParcel = parcelNames.isNotEmpty;

    if (!hasRide && !hasParcel) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Our Services',
              style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: JT.textPrimary)),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: JT.border),
              boxShadow: JT.cardShadow,
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: JT.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Icon(Icons.wifi_tethering_error_rounded,
                    color: JT.primary, size: 34),
              ),
              const SizedBox(height: 14),
              Text('Could not load services',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: JT.textPrimary)),
              const SizedBox(height: 6),
              Text('Check your connection and tap retry',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                      fontSize: 12, color: JT.textSecondary, height: 1.4)),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: () async {
                  setState(() => _homeLoading = true);
                  await Future.wait([_fetchHome(), _fetchActiveServices()]);
                },
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: Text('Retry',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w400)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: JT.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(140, 50),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ]),
          ),
        ]),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Our Services',
            style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: JT.textPrimary)),
        const SizedBox(height: 14),
        Row(children: [
          // ── Ride card — only if admin has active ride vehicles ──
          if (hasRide)
            Expanded(
                child: _buildServiceCard(
              imageUrl: ApiConfig.vehicleAsset('auto.png'),
              fallbackIcon: Icons.electric_rickshaw_rounded,
              title: 'Ride',
              subtitle: _serviceSummaryForType('ride', 'Bike · Auto · Car'),
              metaLabel: _serviceStatusForType('ride'),
              accent: const Color(0xFF2563EB),
              onTap: () {
                HapticFeedback.selectionClick();
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => LocationScreen(
                              serviceType: 'ride',
                              pickupAddress:
                                  _pickup.isNotEmpty ? _pickup : null,
                              pickupLat: _pickupLat,
                              pickupLng: _pickupLng,
                            )));
              },
            )),
          if (hasRide && hasParcel) const SizedBox(width: 14),
          // ── Parcel card — only if admin has active parcel vehicles ──
          if (hasParcel)
            Expanded(
                child: _buildServiceCard(
              imageUrl: ApiConfig.vehicleAsset('parcel_bike.png'),
              fallbackIcon: Icons.local_shipping_rounded,
              title: 'Parcel',
              subtitle: _serviceSummaryForType('parcel', 'Bike · Truck · Van'),
              metaLabel: _serviceStatusForType('parcel'),
              accent: const Color(0xFF059669),
              onTap: () {
                HapticFeedback.selectionClick();
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => LocationScreen(
                              serviceType: 'parcel',
                              pickupAddress:
                                  _pickup.isNotEmpty ? _pickup : null,
                              pickupLat: _pickupLat,
                              pickupLng: _pickupLng,
                            )));
              },
            )),
        ]),
      ]),
    );
  }

  Widget _buildServiceCard({
    required String imageUrl,
    required IconData fallbackIcon,
    required String title,
    required String subtitle,
    required String metaLabel,
    required Color accent,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 158,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: accent.withValues(alpha: 0.12), width: 1),
          boxShadow: [
            BoxShadow(color: accent.withValues(alpha: 0.10), blurRadius: 20, offset: const Offset(0, 8)),
            BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(children: [
            // Subtle tinted background
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.white, accent.withValues(alpha: 0.04)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 14,
              right: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: accent.withValues(alpha: 0.16)),
                ),
                child: Text(
                  metaLabel.toUpperCase(),
                  style: GoogleFonts.poppins(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w500,
                    color: accent,
                    letterSpacing: 0.7,
                  ),
                ),
              ),
            ),
            // Vehicle icon — right side, bottom-anchored
            Positioned(
              right: -6,
              bottom: -4,
              child: SizedBox(
                width: 118,
                height: 118,
                child: Icon(
                  fallbackIcon,
                  size: 88,
                  color: accent.withValues(alpha: 0.15),
                ),
              ),
            ),
            // Content — left side
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w400,
                        color: accent,
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Title
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 26,
                      fontWeight: FontWeight.w500,
                      color: JT.textPrimary,
                      letterSpacing: -0.5,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // CTA button
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [accent, accent.withValues(alpha: 0.80)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Text('Book Now',
                          style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w400)),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 12),
                    ]),
                  ),
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }

  void _onServiceTap(String serviceKey) {
    if (serviceKey.contains('parcel')) {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => LocationScreen(
                    serviceType: 'parcel',
                    pickupAddress: _pickup.isNotEmpty ? _pickup : null,
                    pickupLat: _pickupLat,
                    pickupLng: _pickupLng,
                  )));
    } else if (serviceKey.contains('pool') ||
        serviceKey.contains('intercity')) {
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => const IntercityBookingScreen()));
    } else {
      _openSearch();
    }
  }

  Widget _dynamicServiceCard({
    required String title,
    required String emoji,
    required String subtitle,
    required VoidCallback onTap,
    String imageUrl = '',
  }) {
    final style = _vehicleStyle(title);
    final iconData = style['icon'] as IconData;
    final gradColors = style['gradient'] as List<Color>;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 14, 10, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFDCE7F5)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 16,
                offset: const Offset(0, 5))
          ],
        ),
        child: Stack(children: [
          Positioned(
            right: -8,
            top: -8,
            child: Icon(iconData,
                size: 72, color: gradColors.first.withValues(alpha: 0.08)),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: gradColors.first.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(iconData, size: 19, color: gradColors.first),
            ),
            const Spacer(),
            if (subtitle.isNotEmpty) ...[
              Text(subtitle,
                  style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: JT.textSecondary,
                      fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
            ],
            Text(title,
                style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: JT.textPrimary),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
          ]),
        ]),
      ),
    );
  }

  Widget _featuredCard({
    required String subtitle,
    required String title,
    required String emoji,
    required VoidCallback onTap,
    bool tall = false,
    IconData icon = Icons.directions_car_filled_rounded,
    List<Color> gradient = const [JT.primary, Color(0xFF4FA9FF)],
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: tall ? 172 : 148,
        padding: const EdgeInsets.fromLTRB(16, 16, 12, 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFDCE7F5)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 18,
                offset: const Offset(0, 6))
          ],
        ),
        child: Stack(children: [
          Positioned(
              right: -10,
              top: -10,
              child: Icon(icon,
                  size: 90, color: gradient.first.withValues(alpha: 0.08))),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: gradient.first.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, size: 20, color: gradient.first),
            ),
            const Spacer(),
            if (subtitle.isNotEmpty) ...[
              Text(subtitle,
                  style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: JT.textSecondary,
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 3),
            ],
            Text(title,
                style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: JT.textPrimary),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
          ]),
        ]),
      ),
    );
  }

  // ── EXPLORE — Rapido-style round vehicle icons with "View All" ────────────
  Widget _buildExploreSection(bool isDark) {
    final vehicles = <Map<String, dynamic>>[
      {'name': 'Shared\nAuto', 'icon': Icons.electric_rickshaw_rounded, 'color': const Color(0xFF2E7D32), 'type': 'ride'},
      {'name': 'Bike', 'icon': Icons.electric_bike_rounded, 'color': JT.textPrimary, 'type': 'ride'},
      {'name': 'Auto', 'icon': Icons.electric_rickshaw_rounded, 'color': const Color(0xFF2E7D32), 'type': 'ride'},
      {'name': 'Parcel', 'icon': Icons.inventory_2_rounded, 'color': const Color(0xFFE8943A), 'type': 'parcel'},
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('Explore',
              style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: JT.textPrimary)),
          const Spacer(),
          GestureDetector(
            onTap: _showAllServicesSheet,
            child: Row(children: [
              Text('View All',
                  style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: JT.textSecondary)),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded, color: JT.textSecondary, size: 18),
            ]),
          ),
        ]),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: vehicles.map((v) {
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                if (v['type'] == 'parcel') {
                  Navigator.push(context,
                      MaterialPageRoute(
                          builder: (_) => LocationScreen(
                                serviceType: 'parcel',
                                pickupAddress: _pickup.isNotEmpty ? _pickup : null,
                                pickupLat: _pickupLat,
                                pickupLng: _pickupLng,
                              )));
                } else {
                  _openSearch();
                }
              },
              child: Column(children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(v['icon'] as IconData,
                      color: v['color'] as Color, size: 30),
                ),
                const SizedBox(height: 8),
                Text(
                  v['name'] as String,
                  style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: JT.textPrimary),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                ),
              ]),
            );
          }).toList(),
        ),
      ]),
    );
  }

  // ── "GO PLACES WITH JAGO" — Horizontal destination cards (LIVE from API) ──
  Widget _buildGoPlacesSection() {
    // Use _popularLocations fetched from server, with fallback
    final destinations = _popularLocations.isNotEmpty
        ? _popularLocations.take(8).map((p) {
            final name = p['name']?.toString() ?? '';
            return {
              'name': name,
              'icon': _iconForPlace(name),
              'color': _colorForPlace(name),
              'lat': (p['lat'] as num?)?.toDouble() ?? 0.0,
              'lng': (p['lng'] as num?)?.toDouble() ?? 0.0,
            };
          }).toList()
        : <Map<String, dynamic>>[];

    if (destinations.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text('Go Places with Jago',
              style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: JT.textPrimary)),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 160,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: destinations.length,
            itemBuilder: (_, i) {
              final d = destinations[i];
              return GestureDetector(
                onTap: () {
                  final lat = (d['lat'] as num?)?.toDouble() ?? 0.0;
                  final lng = (d['lng'] as num?)?.toDouble() ?? 0.0;
                  final name = d['name'] as String;
                  if (lat != 0.0 && lng != 0.0) {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (_) => BookingScreen(
                          pickup: _pickup,
                          destination: name,
                          pickupLat: _pickupLat, pickupLng: _pickupLng,
                          destLat: lat, destLng: lng,
                        )));
                  } else {
                    _openSearch();
                  }
                },
                child: Container(
                  width: 140,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE8E8E8)),
                  ),
                  child: Column(children: [
                    // Illustration area with yellow wave background
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              const Color(0xFFFFC107).withValues(alpha: 0.25),
                              const Color(0xFFFFF8E1),
                            ],
                          ),
                        ),
                        child: Icon(
                          d['icon'] as IconData,
                          size: 48,
                          color: d['color'] as Color,
                        ),
                      ),
                    ),
                    // Label
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      child: Text(
                        (d['name'] as String).replaceAll('\n', ' '),
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: JT.textPrimary,
                        ),
                        maxLines: 2,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ]),
                ),
              );
            },
          ),
        ),
        // Page indicator dots
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(width: 20, height: 6, decoration: BoxDecoration(
              color: JT.textPrimary, borderRadius: BorderRadius.circular(3))),
            const SizedBox(width: 4),
            Container(width: 20, height: 6, decoration: BoxDecoration(
              color: const Color(0xFFD9D9D9), borderRadius: BorderRadius.circular(3))),
          ],
        ),
      ]),
    );
  }

  // ── BRAND BANNER — "#goJago" style like Rapido ──────────────────────────
  Widget _buildJagoBrandBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Brand tagline
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Color(0xFF2A4CB7), Color(0xFF3A9EEC)],
            ).createShader(bounds),
            child: Text(
              '#goJago',
              style: GoogleFonts.poppins(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                fontStyle: FontStyle.italic,
                color: Colors.white,
                height: 1.1,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Text('Made for India', style: GoogleFonts.poppins(
              fontSize: 13, color: JT.textSecondary, fontWeight: FontWeight.w400)),
          ]),
          const SizedBox(height: 4),
          Row(children: [
            Text('Safe, Fast & Affordable', style: GoogleFonts.poppins(
              fontSize: 13, color: JT.textSecondary, fontWeight: FontWeight.w400)),
          ]),
        ],
      ),
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
                        color: Colors.white,
                        border: Border.all(color: const Color(0xFFDCE7F5)),
                        boxShadow: JT.cardShadow,
                      ),
                      child: imgUrl.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.network(imgUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      _bannerPlaceholder(b)))
                          : _bannerPlaceholder(b),
                    );
                  },
                ),
              ),
              if (_banners.length > 1) ...[
                const SizedBox(height: 8),
                Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                        _banners.length,
                        (i) => Container(
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              width: _bannerIndex == i ? 16 : 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: _bannerIndex == i
                                    ? JT.primary
                                    : JT.primary.withValues(alpha: 0.3),
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
        color: JT.primary,
      ),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(b['title']?.toString() ?? 'Special Offer',
                style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w400)),
            const SizedBox(height: 4),
            Text('Tap to learn more',
                style:
                    GoogleFonts.poppins(color: Colors.white70, fontSize: 12)),
          ]),
    );
  }

  Widget _buildStaticPromoBanner(bool isDark) {
    return Container(
      height: 130,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        border: Border.all(color: const Color(0xFFDCE7F5)),
        boxShadow: JT.cardShadow,
      ),
      padding: const EdgeInsets.all(20),
      child: Row(children: [
        Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
              JT.logoBlue(height: 28),
              const SizedBox(height: 8),
              Text('Safe, fast and affordable rides',
                  style: GoogleFonts.poppins(
                      color: JT.textSecondary, fontSize: 12)),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: _openSearch,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                      color: JT.primary,
                      borderRadius: BorderRadius.circular(20)),
                  child: Text('Book Now',
                      style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w400)),
                ),
              ),
            ])),
        Icon(Icons.directions_car_filled_rounded,
            size: 72, color: JT.primary.withValues(alpha: 0.12)),
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
        Row(
            children: _savedPlaces.take(2).map((place) {
          final label = place['label']?.toString() ?? '';
          final address = place['address']?.toString() ?? '';
          final icon =
              label == 'Home' ? Icons.home_rounded : Icons.work_rounded;
          final isFirst = _savedPlaces.indexOf(place) == 0;
          return Expanded(
              child: GestureDetector(
            onTap: () {
              final lat =
                  double.tryParse(place['lat']?.toString() ?? '0') ?? 0.0;
              final lng =
                  double.tryParse(place['lng']?.toString() ?? '0') ?? 0.0;
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => BookingScreen(
                            pickup: _pickup,
                            destination: address,
                            pickupLat: _pickupLat,
                            pickupLng: _pickupLng,
                            destLat: lat != 0 ? lat : 17.385,
                            destLng: lng != 0 ? lng : 78.4867,
                          )));
            },
            child: Container(
              margin: EdgeInsets.only(right: isFirst ? 8 : 0),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? JT.surface : JT.surface,
                borderRadius: BorderRadius.circular(14),
                boxShadow: JT.cardShadow,
              ),
              child: Row(children: [
                Icon(icon, color: JT.primary, size: 18),
                const SizedBox(width: 8),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(label,
                          style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: JT.textPrimary)),
                      Text(address,
                          style: GoogleFonts.poppins(
                              fontSize: 10,
                              color:
                                  isDark ? Colors.white54 : JT.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
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
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const TripsHistoryScreen())),
            child: Text('See all',
                style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: JT.primary,
                    fontWeight: FontWeight.w400)),
          ),
        ]),
        const SizedBox(height: 10),
        ..._recentTrips.take(3).map((trip) {
          final dest = trip['destinationAddress']?.toString() ??
              trip['destination_address']?.toString() ??
              'Unknown';
          final fare = trip['actualFare']?.toString() ??
              trip['actual_fare']?.toString() ??
              '';
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
                Expanded(
                    child: Text(dest.split(',').first,
                        style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: JT.textPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis)),
                if (fare.isNotEmpty)
                  Text('₹$fare',
                      style: GoogleFonts.poppins(
                          fontSize: 12, color: JT.textSecondary)),
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
    final isSearching = status == 'searching';

    final statusLabel = {
          'searching': 'Finding a Pilot...',
          'accepted': 'Pilot is on the way',
          'driver_assigned': 'Pilot assigned',
          'arrived': 'Pilot has arrived!',
          'in_progress': 'Ride in progress',
        }[status] ??
        'Ride active';

    final isArrived = status == 'arrived';
    final bannerColor = isSearching
        ? JT.primaryDark
        : isArrived
            ? const Color(0xFF1A6FDB)
            : JT.primary;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: bannerColor.withValues(alpha: 0.20)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 16,
              offset: const Offset(0, 4))
        ],
      ),
      child: Row(children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
              color: bannerColor.withValues(alpha: 0.10),
              shape: BoxShape.circle),
          child: Icon(
              isSearching ? Icons.search_rounded : Icons.navigation_rounded,
              color: bannerColor,
              size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(statusLabel,
              style: GoogleFonts.poppins(
                  color: JT.textPrimary,
                  fontWeight: FontWeight.w500,
                  fontSize: 14)),
          Text(
              isSearching
                  ? 'Looking for nearby pilots...'
                  : '$driverName → ${dest.length > 28 ? '${dest.substring(0, 26)}...' : dest}',
              style: GoogleFonts.poppins(
                  color: JT.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w500)),
        ])),
        if (isSearching)
          // Cancel button for stuck searching trips
          GestureDetector(
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: JT.surface,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  title: Text('Cancel Ride?',
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w400,
                          color: JT.textPrimary,
                          fontSize: 16)),
                  content: Text(
                      'No pilot found yet. Do you want to cancel this request?',
                      style: GoogleFonts.poppins(
                          color: JT.textSecondary, fontSize: 13)),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: Text('Wait',
                            style:
                                GoogleFonts.poppins(color: JT.textSecondary))),
                    ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: JT.primaryDark,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10))),
                        onPressed: () => Navigator.pop(ctx, true),
                        child: Text('Cancel Ride',
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w500))),
                  ],
                ),
              );
              if (confirm == true && mounted) {
                try {
                  final h = await AuthService.getHeaders();
                  await http.post(Uri.parse(ApiConfig.cancelTrip),
                      headers: h,
                      body: jsonEncode(
                          {'tripId': tripId, 'reason': 'No pilot found'}));
                } catch (_) {}
                if (mounted) setState(() => _activeTrip = null);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: JT.primaryDark.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('Cancel',
                  style: GoogleFonts.poppins(
                      color: JT.primaryDark,
                      fontWeight: FontWeight.w400,
                      fontSize: 12)),
            ),
          )
        else
          GestureDetector(
            onTap: () {
              if (tripId.isEmpty) return;
              Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (_) => TrackingScreen(tripId: tripId)));
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: JT.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('Track →',
                  style: GoogleFonts.poppins(
                      color: JT.primary,
                      fontWeight: FontWeight.w400,
                      fontSize: 12)),
            ),
          ),
      ]),
    );
  }

  // ── BOTTOM NAV — Rapido-style (Ride, All Services, Travel, Profile) ──────
  Widget _buildBottomNav(bool isDark, Color cardBg, Color textColor) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF3C3C3C),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SizedBox(
        height: 64,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _navItem(Icons.home_rounded, Icons.home_outlined, 'Ride', 0, isDark),
            _navItem(Icons.near_me_rounded, Icons.near_me_outlined, 'All Services', 1, isDark),
            _navItem(Icons.sailing_rounded, Icons.sailing_outlined, 'Travel', 2, isDark),
            _navItem(Icons.person_rounded, Icons.person_outline_rounded, 'Profile', 3, isDark),
          ],
        ),
      ),
    );
  }

  Widget _navItem(IconData activeIcon, IconData inactiveIcon, String label,
      int index, bool isDark) {
    final active = _navIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() => _navIndex = index);
        if (index == 1)
          _showAllServicesSheet();
        if (index == 2)
          Navigator.push(
              context, MaterialPageRoute(builder: (_) => const WalletScreen()));
        if (index == 3)
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()));
      },
      child: SizedBox(
        width: 80,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(active ? activeIcon : inactiveIcon,
              size: 22, color: active ? Colors.white : Colors.white54),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: active ? FontWeight.w600 : FontWeight.w400,
              color: active ? Colors.white : Colors.white54,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ]),
      ),
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
              color: JT.bgSoft,
              border: const Border(bottom: BorderSide(color: JT.border)),
            ),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: JT.surfaceAlt,
                child: Text(
                  _userName.isNotEmpty ? _userName[0].toUpperCase() : 'U',
                  style: GoogleFonts.poppins(
                      color: JT.primary,
                      fontSize: 24,
                      fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(height: 12),
              Text(_userName, style: JT.h2),
              Text(_userPhone, style: JT.body),
            ]),
          ),
          Divider(
              color: isDark ? const Color(0xFF334155) : JT.border,
              thickness: 1),
          _drawerItem(Icons.history_rounded, 'My Trips', textColor, () {
            Navigator.pop(context);
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const TripsHistoryScreen()));
          }),
          _drawerItem(Icons.account_balance_wallet_rounded, 'Wallet', textColor,
              () {
            Navigator.pop(context);
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const WalletScreen()));
          }),
          _drawerItem(Icons.local_offer_rounded, 'Offers', textColor, () {
            Navigator.pop(context);
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const OffersScreen()));
          }),
          _drawerItem(Icons.bookmark_rounded, 'Saved Places', textColor, () {
            Navigator.pop(context);
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const SavedPlacesScreen()));
          }),
          _drawerItem(Icons.people_alt_rounded, 'Refer & Earn', textColor, () {
            Navigator.pop(context);
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ReferralScreen()));
          }),
          _drawerItem(
              Icons.directions_car_outlined, 'Intercity Pool', textColor, () {
            Navigator.pop(context);
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const OutstationPoolScreen()));
          }),
          _drawerItem(Icons.business_center_rounded, 'B2B Business', textColor,
              () {
            Navigator.pop(context);
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const B2BLoginScreen()));
          }),
          _drawerItem(Icons.support_agent_rounded, 'Support', textColor, () {
            Navigator.pop(context);
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const SupportChatScreen()));
          }),
          const Spacer(),
          _drawerItem(Icons.person_rounded, 'Profile', textColor, () {
            Navigator.pop(context);
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()));
          }),
          const SizedBox(height: 16),
        ]),
      ),
    );
  }

  Widget _drawerItem(
      IconData icon, String label, Color textColor, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: JT.primary, size: 22),
      title: Text(label,
          style: GoogleFonts.poppins(
              color: textColor, fontSize: 15, fontWeight: FontWeight.w500)),
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
  List<Map<String, dynamic>> _popular = [];
  bool _loading = false;
  Timer? _debounce;

  static const Color _primary = JT.primary;

  @override
  void initState() {
    super.initState();
    _fetchPopularLocations();
    _fetchNearby();
  }

  void _openMapPicker() async {
    Navigator.pop(context);
    final result = await Navigator.push<PickedLocation>(
      context,
      MaterialPageRoute(
          builder: (_) => MapLocationPicker(
                title: 'Select Destination',
                initialLat: widget.pickupLat,
                initialLng: widget.pickupLng,
              )),
    );
    if (result != null) {
      widget.onPlaceSelected(result.address, result.lat, result.lng);
    }
  }

  Future<void> _fetchPopularLocations() async {
    try {
      final headers = await AuthService.getHeaders();
      final r = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/app/popular-locations?lat=${widget.pickupLat}&lng=${widget.pickupLng}'),
        headers: headers,
      );
      if (r.statusCode == 200) {
        final data = jsonDecode(r.body) as Map<String, dynamic>;
        final list = (data['locations'] as List<dynamic>? ?? [])
            .map((x) => Map<String, dynamic>.from(x as Map))
            .map((x) => {
                  'name': (x['name'] ?? '').toString(),
                  'lat': double.tryParse(
                          (x['lat'] ?? x['latitude'] ?? 0).toString()) ??
                      0.0,
                  'lng': double.tryParse(
                          (x['lng'] ?? x['longitude'] ?? 0).toString()) ??
                      0.0,
                })
            .where((x) => (x['name'] as String).isNotEmpty)
            .toList();
        if (mounted && list.isNotEmpty) {
          setState(() => _popular = list);
          return;
        }
      }
    } catch (_) {}
    // No hardcoded fallback — popular locations come from the API only
  }

  // Fetch actual nearby places based on real GPS coordinates
  Future<void> _fetchNearby() async {
    final lat = widget.pickupLat;
    final lng = widget.pickupLng;
    if (lat == 0.0 && lng == 0.0) return;
    try {
      final headers = await AuthService.getHeaders();
      final res = await http.get(
        Uri.parse('${ApiConfig.placesNearby}?lat=$lat&lng=$lng&radius=3000'),
        headers: headers,
      ).timeout(const Duration(seconds: 6));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final places = (data['places'] as List<dynamic>?) ?? [];
        if (mounted && places.isNotEmpty) {
          setState(() {
            _nearby = places
                .map((p) => <String, dynamic>{
                      'name': p['name']?.toString() ?? '',
                      'lat': (p['lat'] as num?)?.toDouble() ?? 0.0,
                      'lng': (p['lng'] as num?)?.toDouble() ?? 0.0,
                    })
                .where((r) => (r['name'] as String).isNotEmpty)
                .toList();
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _search(String query) async {
    if (query.length < 3) {
      setState(() {
        _results = [];
        _loading = false;
      });
      return;
    }
    setState(() => _loading = true);
    try {
      final headers = await AuthService.getHeaders();
      final lat = widget.pickupLat;
      final lng = widget.pickupLng;
      final qp = StringBuffer('?query=${Uri.encodeComponent(query)}');
      if (lat != 0.0 && lng != 0.0) qp.write('&lat=$lat&lng=$lng');
      final r = await http.get(
        Uri.parse('${ApiConfig.placesAutocomplete}$qp'),
        headers: headers,
      ).timeout(const Duration(seconds: 6));
      if (r.statusCode == 200) {
        final data = jsonDecode(r.body) as Map<String, dynamic>;
        final preds = (data['predictions'] as List<dynamic>?) ?? [];
        setState(() {
          _results = preds
              .map((p) => <String, dynamic>{
                    'name': p['fullDescription']?.toString() ??
                        p['mainText']?.toString() ?? '',
                    'placeId': p['placeId']?.toString() ?? '',
                    'lat': (p['lat'] as num?)?.toDouble() ?? 0.0,
                    'lng': (p['lng'] as num?)?.toDouble() ?? 0.0,
                  })
              .where((r) => (r['name'] as String).isNotEmpty)
              .toList();
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _resolveAndSelect(Map<String, dynamic> p) async {
    var name = p['name']?.toString() ?? '';
    var lat = (p['lat'] as num?)?.toDouble() ?? 0.0;
    var lng = (p['lng'] as num?)?.toDouble() ?? 0.0;
    final placeId = p['placeId']?.toString() ?? '';
    if ((lat == 0.0 || lng == 0.0) &&
        placeId.isNotEmpty &&
        !placeId.startsWith('local:')) {
      try {
        final headers = await AuthService.getHeaders();
        final r = await http
            .get(
              Uri.parse(
                  '${ApiConfig.placeDetails}?placeId=${Uri.encodeComponent(placeId)}'),
              headers: headers,
            )
            .timeout(const Duration(seconds: 6));
        if (r.statusCode == 200) {
          final d = jsonDecode(r.body) as Map<String, dynamic>;
          lat = (d['lat'] as num?)?.toDouble() ?? 0.0;
          lng = (d['lng'] as num?)?.toDouble() ?? 0.0;
          name = d['address']?.toString() ?? name;
        }
      } catch (_) {}
    }
    if (lat != 0.0 && lng != 0.0) {
      Navigator.pop(context);
      widget.onPlaceSelected(name, lat, lng);
    }
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

    const sheetBg = Colors.white;
    const inputBg = Color(0xFFF5F8FF);
    const textColor = JT.textPrimary;
    const subColor = Color(0xFF94A3B8);
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        color: sheetBg,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(top: 10, bottom: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFDCE9FF),
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
                        onPressed: () => setState(() {
                              _ctrl.clear();
                              _results = [];
                            }))
                    : null,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none),
                filled: true,
                fillColor: inputBg,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onChanged: (v) {
                _debounce?.cancel();
                _debounce =
                    Timer(const Duration(milliseconds: 400), () => _search(v));
                setState(() {});
              },
            ),
          ),
          // Pick on Map option
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: GestureDetector(
              onTap: _openMapPicker,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F7FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFDCE9FF)),
                ),
                child: Row(children: [
                  const Icon(Icons.map_rounded, color: _primary, size: 20),
                  const SizedBox(width: 10),
                  Text('Pick on Map',
                      style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: _primary)),
                  const Spacer(),
                  const Icon(Icons.chevron_right_rounded,
                      color: _primary, size: 20),
                ]),
              ),
            ),
          ),
          const SizedBox(height: 8),
          if (_popular.isNotEmpty && query.length < 3)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 2, 16, 10),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Popular Locations',
                      style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: subColor,
                          fontWeight: FontWeight.w400),
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _popular.map((p) {
                          return GestureDetector(
                            onTap: () {
                              Navigator.pop(context);
                              widget.onPlaceSelected(
                                p['name'] as String,
                                (p['lat'] as num?)?.toDouble() ?? 0.0,
                                (p['lng'] as num?)?.toDouble() ?? 0.0,
                              );
                            },
                            child: Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0F7FF),
                                borderRadius: BorderRadius.circular(20),
                                border:
                                    Border.all(color: const Color(0xFFDCE9FF)),
                              ),
                              child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.place_rounded,
                                        color: _primary, size: 14),
                                    const SizedBox(width: 6),
                                    Text(
                                      p['name'] as String,
                                      style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w400,
                                          color: textColor),
                                    ),
                                  ]),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ]),
            ),
          if (_loading)
            const Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(color: _primary)),
          if (!_loading)
            ConstrainedBox(
              constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.4),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: items.length + (query.length < 3 ? 1 : 0),
                itemBuilder: (_, i) {
                  if (query.length < 3 && i == 0) {
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                      child: Text(
                        _nearby.isEmpty
                            ? 'Start typing to search...'
                            : 'Nearby places',
                        style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: subColor,
                            fontWeight: FontWeight.w400),
                      ),
                    );
                  }
                  final item = items[query.length < 3 ? i - 1 : i];
                  return ListTile(
                    leading:
                        const Icon(Icons.location_on_outlined, color: _primary),
                    title: Text(
                      item['name'] as String,
                      style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: textColor),
                      maxLines: 2,
                    ),
                    onTap: () => _resolveAndSelect(item),
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
  final List<Map<String, dynamic>> activeServices;
  final String pickup;
  final double pickupLat;
  final double pickupLng;
  final void Function(Map<String, dynamic> cat) onServiceTap;

  const _AllServicesSheet({
    required this.vehicleCategories,
    required this.activeServices,
    required this.pickup,
    required this.pickupLat,
    required this.pickupLng,
    required this.onServiceTap,
  });


  @override
  Widget build(BuildContext context) {
    // Build services list from active vehicle categories (filtered by admin)
    List<Map<String, dynamic>> services = [];

    if (vehicleCategories.isNotEmpty) {
      services = vehicleCategories
          .map((v) => {
                'id': v['id'],
                'name': v['name'] ?? '',
                'type': v['type'] ?? 'ride',
                'emoji': _emojiForCategory(v['name']?.toString() ?? ''),
                'key':
                    v['name']?.toString().toLowerCase().replaceAll(' ', '_') ??
                        '',
              })
          .toList();
    }

    // Add active platform services that aren't already covered by vehicle categories
    if (activeServices.isNotEmpty) {
      final existingKeys =
          services.map((s) => s['key']?.toString() ?? '').toSet();
      for (final svc in activeServices) {
        final key = svc['key']?.toString() ?? '';
        if (key.isNotEmpty &&
            !existingKeys.any((k) => key.contains(k) || k.contains(key))) {
          services.add({
            'id': null,
            'name': svc['name']?.toString() ?? key,
            'type': svc['category']?.toString() ?? 'ride',
            'emoji': svc['icon']?.toString() ?? '🚗',
            'key': key,
          });
        }
      }
    }

    // If nothing available at all, show empty state
    if (services.isEmpty) {
      services = [
        {
          'id': null,
          'name': 'No services available',
          'type': 'none',
          'emoji': '🔒',
          'key': ''
        }
      ];
    }

    // Group services by category
    final rideServices = services.where((s) {
      final t = s['type']?.toString() ?? '';
      return t == 'ride' &&
          !(s['name']?.toString().toLowerCase().contains('pool') ?? false);
    }).toList();
    final parcelServices = services.where((s) {
      final t = s['type']?.toString() ?? '';
      return t == 'parcel' || t == 'cargo';
    }).toList();
    final poolServices = services.where((s) {
      final t = s['type']?.toString() ?? '';
      final name = s['name']?.toString().toLowerCase() ?? '';
      return name.contains('pool') || name.contains('share') || t == 'pool';
    }).toList();

    return Container(
      padding: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFDCE9FF),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('All Services',
                style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w400,
                    color: JT.textPrimary)),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: Color(0xFFF5F8FF),
                  shape: BoxShape.circle,
                ),
                child:
                    const Icon(Icons.close, size: 18, color: Color(0xFF94A3B8)),
              ),
            ),
          ]),
          const SizedBox(height: 20),
          if (rideServices.isNotEmpty) ...[
            _sectionHeader('🚗 Ride'),
            const SizedBox(height: 10),
            _serviceGrid(rideServices),
            const SizedBox(height: 20),
          ],
          if (parcelServices.isNotEmpty) ...[
            _sectionHeader('📦 Parcel & Logistics'),
            const SizedBox(height: 10),
            _serviceGrid(parcelServices),
            const SizedBox(height: 20),
          ],
          if (poolServices.isNotEmpty) ...[
            _sectionHeader('🚐 Car Pool'),
            const SizedBox(height: 10),
            _serviceGrid(poolServices),
          ],
        ]),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(title,
          style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: JT.textPrimary)),
    );
  }

  Widget _serviceGrid(List<Map<String, dynamic>> items) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.88,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final s = items[i];
        return GestureDetector(
          onTap: () => onServiceTap(s),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF5F8FF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFDCE9FF)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(s['emoji'] as String, style: const TextStyle(fontSize: 36)),
              const SizedBox(height: 8),
              Text(
                s['name'] as String,
                style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: JT.textPrimary),
                textAlign: TextAlign.center,
                maxLines: 2,
              ),
            ]),
          ),
        );
      },
    );
  }

  static String _emojiForCategory(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('bike') && lower.contains('parcel')) return '📦';
    if (lower.contains('bike') || lower.contains('moto')) return '🏍️';
    if (lower.contains('auto') && lower.contains('parcel')) return '📦';
    if (lower.contains('auto')) return '🛺';
    if (lower.contains('cargo') ||
        lower.contains('truck') ||
        lower.contains('bolero')) return '🚛';
    if (lower.contains('parcel')) return '📦';
    if (lower.contains('pool') || lower.contains('shar')) return '🚐';
    if (lower.contains('car') || lower.contains('cab')) return '🚗';
    if (lower.contains('suv')) return '🚙';
    if (lower.contains('intercity')) return '🛣️';
    return '🚖';
  }
}

// Tutorial tip row widget used in the first-visit tutorial overlay
class _TutorialTip extends StatelessWidget {
  final String icon;
  final String title;
  final String desc;
  const _TutorialTip(
      {required this.icon, required this.title, required this.desc});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(12),
          ),
          child:
              Center(child: Text(icon, style: const TextStyle(fontSize: 20))),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                      color: JT.textPrimary)),
              const SizedBox(height: 2),
              Text(desc,
                  style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: const Color(0xFF64748B),
                      height: 1.4)),
            ],
          ),
        ),
      ],
    );
  }
}
