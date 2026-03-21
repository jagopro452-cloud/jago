import 'dart:async';
import 'dart:convert';
import 'dart:math' show cos, pi, sqrt;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/heatmap_service.dart';
import '../../config/api_config.dart';
import '../../config/jago_theme.dart';
import '../../services/auth_service.dart';
import '../../services/socket_service.dart';
import '../../services/alarm_service.dart';
import '../../widgets/incoming_trip_sheet.dart';
import '../../widgets/incoming_parcel_sheet.dart';
import '../../services/fcm_service.dart';
import '../auth/login_screen.dart';
import '../auth/pending_verification_screen.dart';
import '../verification/face_verification_screen.dart';
import '../wallet/wallet_screen.dart';
import '../history/trips_history_screen.dart';
import '../profile/profile_screen.dart';
import '../break_mode/break_mode_screen.dart';
import '../fatigue/fatigue_screen.dart';
import '../trip/trip_screen.dart';
import '../notifications/notifications_screen.dart';
import '../referral/referral_screen.dart';
import '../profile/support_chat_screen.dart';
import '../onboarding/model_selection_screen.dart';
import '../onboarding/subscription_plans_screen.dart';
import '../earnings/earnings_screen.dart';
import '../kyc/kyc_documents_screen.dart';
import '../parcel/parcel_delivery_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final SocketService _socket = SocketService();
  GoogleMapController? _mapController;
  LatLng _center = const LatLng(16.5062, 80.6480);
  bool _isOnline = false;
  bool _toggling = false;
  bool _socketConnected = false;
  String _userName = 'Pilot';
  String _userPhone = '';
  double _walletBalance = 0;
  int _tripsToday = 0;
  double _earningsToday = 0;
  double _driverRating = 5.0;
  int _unreadNotifCount = 0;
  Map<String, dynamic>? _incomingTrip;
  Map<String, dynamic>? _incomingParcel;
  String _vehicleCategory = '';
  String _vehicleNumber = '';
  String _vehicleModel = '';
  String _zone = '';
  Timer? _locationTimer;
  late AnimationController _pulseCtrl;
  final List<StreamSubscription> _subs = [];
  int _navIndex = 0;
  bool _inFreePeriod = false;
  int _freeDaysRemaining = 0;

  // ── Heatmap ────────────────────────────────────────────────────────────
  final HeatmapService _heatmap = HeatmapService();
  Set<Circle> _heatmapCircles = {};
  bool _showHeatmap = true;
  HeatmapZone? _nearestHighZone;
  HeatmapSuggestion? _heatmapSuggestion;
  Timer? _idleTimer;
  int _idleSeconds = 0;
  bool _idleSuggestionShown = false;

  // ── Eligible Services ──────────────────────────────────────────────────
  List<Map<String, dynamic>> _eligibleServices = [];

  String _getTimeGreeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning';
    if (h < 17) return 'Good Afternoon';
    if (h < 20) return 'Good Evening';
    return 'Good Night';
  }

  String _ordinal(int day) {
    if (day >= 11 && day <= 13) return '${day}th';
    switch (day % 10) {
      case 1: return '${day}st';
      case 2: return '${day}nd';
      case 3: return '${day}rd';
      default: return '${day}th';
    }
  }

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _checkVerificationStatus();
    _loadUser();
    _getLocation();
    _fetchDashboard();
    _fetchLaunchBenefit();
    _fetchEligibleServices();
    _connectSocket();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _recoverActiveTrip();   // Fix 7: state recovery — must run before FCM check
      await _checkPendingFcmTrip();
    });
  }

  Future<void> _checkVerificationStatus() async {
    try {
      final headers = await AuthService.getHeaders();
      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/app/driver/verification-status'),
        headers: headers,
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['verificationStatus'] != 'approved') {
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const PendingVerificationScreen()),
          );
        } else if (data['modelSelectedAt'] == null) {
          final inFreePeriod = data['launchFreeActive'] == true &&
              data['freePeriodEnd'] != null &&
              DateTime.tryParse(data['freePeriodEnd'].toString())?.isAfter(DateTime.now()) == true;
          if (!inFreePeriod) {
            if (!mounted) return;
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const ModelSelectionScreen()),
            );
          }
        }
      }
    } catch (_) {}
  }

  // ── App state recovery: if driver has an active trip, go to TripScreen directly ──
  Future<void> _recoverActiveTrip() async {
    try {
      final headers = await AuthService.getHeaders();
      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/app/driver/active-trip'),
        headers: headers,
      );
      if (res.statusCode != 200) return;
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final trip = data['trip'];
      if (trip == null) return;
      final status = trip['currentStatus'] ?? trip['current_status'] ?? '';
      if (!['accepted', 'arrived', 'on_the_way', 'driver_assigned'].contains(status)) return;
      if (!mounted) return;
      // Navigate directly to trip screen — driver was mid-trip when app crashed
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => TripScreen(trip: trip),
        ),
      );
    } catch (_) {}
  }

  Future<void> _checkPendingFcmTrip() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // ── Pending ride ──────────────────────────────────────────────────────
      final pendingTripStr = prefs.getString('pending_trip_data');
      if (pendingTripStr != null && pendingTripStr.isNotEmpty) {
        await prefs.remove('pending_trip_data');
        final tripData = jsonDecode(pendingTripStr) as Map<String, dynamic>;
        if (mounted && _incomingTrip == null) {
          await Future.delayed(const Duration(milliseconds: 300));
          if (!mounted) return;
          setState(() => _incomingTrip = tripData);
          _showIncomingTrip();
          return; // Show trip first; parcel can wait
        }
      }

      // ── Pending parcel ────────────────────────────────────────────────────
      final pendingParcelStr = prefs.getString('pending_parcel_data');
      if (pendingParcelStr != null && pendingParcelStr.isNotEmpty) {
        await prefs.remove('pending_parcel_data');
        final parcelData = jsonDecode(pendingParcelStr) as Map<String, dynamic>;
        if (mounted && _incomingParcel == null && _incomingTrip == null) {
          await Future.delayed(const Duration(milliseconds: 300));
          if (!mounted) return;
          setState(() => _incomingParcel = parcelData);
          _showIncomingParcel();
        }
      }
    } catch (_) {}
  }

  Future<void> _connectSocket() async {
    await _socket.connect(ApiConfig.socketUrl);

    _subs.add(_socket.onConnectionChanged.listen((connected) {
      if (mounted) setState(() => _socketConnected = connected);
    }));

    _subs.add(_socket.onNewTrip.listen((trip) {
      if (!mounted) return;
      if (_incomingTrip == null) {
        setState(() => _incomingTrip = trip);
        _showIncomingTrip();
      }
    }));

    _subs.add(_socket.onTripCancelled.listen((data) {
      if (!mounted) return;
      setState(() => _incomingTrip = null);
      Navigator.of(context).popUntil((r) => r.isFirst);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Customer cancelled the trip', style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: JT.error,
        behavior: SnackBarBehavior.floating,
      ));
    }));

    _subs.add(_socket.onTripTaken.listen((data) {
      if (!mounted) return;
      if (_incomingTrip == null) return;
      final takenTripId = (data['tripId'] ?? data['id'] ?? '').toString();
      final currentTripId = (_incomingTrip?['tripId'] ?? _incomingTrip?['id'] ?? '').toString();
      if (currentTripId.isEmpty || takenTripId.isEmpty || takenTripId == currentTripId) {
        setState(() => _incomingTrip = null);
        Navigator.of(context).popUntil((r) => r.isFirst);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Another driver accepted this trip', style: TextStyle(fontWeight: FontWeight.w600)),
          backgroundColor: JT.textSecondary,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ));
      }
    }));

    _subs.add(_socket.onTripTimeout.listen((data) {
      if (!mounted) return;
      if (_incomingTrip == null) return;
      final timeoutTripId = (data['tripId'] ?? data['id'] ?? '').toString();
      final currentTripId = (_incomingTrip?['tripId'] ?? _incomingTrip?['id'] ?? '').toString();
      if (currentTripId.isEmpty || timeoutTripId.isEmpty || timeoutTripId == currentTripId) {
        setState(() => _incomingTrip = null);
        Navigator.of(context).popUntil((r) => r.isFirst);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Trip request timed out', style: TextStyle(fontWeight: FontWeight.w600)),
          backgroundColor: JT.warning,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 3),
        ));
      }
    }));

    _subs.add(_socket.onNoDrivers.listen((_) {
      AlarmService().stopAlarm();
    }));

    _subs.add(_socket.onNewParcel.listen((parcel) {
      if (!mounted) return;
      if (!_isOnline) return;
      if (_incomingTrip != null || _incomingParcel != null) return;
      setState(() => _incomingParcel = parcel);
      _showIncomingParcel();
    }));

    _subs.add(_socket.onWalletRecharged.listen((data) {
      if (!mounted) return;
      final newBalance = (data['newBalance'] ?? data['balance'] ?? 0).toDouble();
      setState(() => _walletBalance = newBalance);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Wallet recharged! Balance: ₹${newBalance.toStringAsFixed(0)}',
            style: const TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: JT.success,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ));
    }));

    // ── FCM foreground stream: app is open, direct-show IncomingTripSheet ─
    // Fires when FCM arrives while app is in foreground (no notification shown).
    // Also fires after notification tap when app is in background/terminated.
    _subs.add(FcmService().onForegroundAlert.listen((data) {
      if (!mounted || !_isOnline) return;
      final type = data['type'] ?? '';
      if (type == 'new_trip' && _incomingTrip == null && _incomingParcel == null) {
        setState(() => _incomingTrip = data);
        _showIncomingTrip();
      } else if (type == 'new_parcel' && _incomingParcel == null && _incomingTrip == null) {
        setState(() => _incomingParcel = data);
        _showIncomingParcel();
      }
    }));
  }

  @override
  void dispose() {
    for (final s in _subs) s.cancel();
    _locationTimer?.cancel();
    _idleTimer?.cancel();
    _heatmap.stopRefresh();
    _pulseCtrl.dispose();
    _socket.disconnect();
    super.dispose();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _userName = prefs.getString('user_name') ?? 'Pilot';
      _userPhone = prefs.getString('user_phone') ?? '';
    });
  }

  Future<void> _getLocation() async {
    try {
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
      final pos = await Geolocator.getCurrentPosition();
      if (!mounted) return;
      setState(() => _center = LatLng(pos.latitude, pos.longitude));
      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(_center, 15));
    } catch (_) {}
  }

  void _handleSessionExpired() {
    AuthService.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Session expired. Please login again.', style: TextStyle(fontWeight: FontWeight.w700)),
      backgroundColor: JT.error,
      behavior: SnackBarBehavior.floating,
    ));
  }

  Future<void> _fetchDashboard() async {
    final token = await AuthService.getToken();
    if (token == null || token.isEmpty) {
      _handleSessionExpired();
      return;
    }
    try {
      final headers = await AuthService.getHeaders();
      final res = await http.get(Uri.parse(ApiConfig.driverDashboard), headers: headers);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (!mounted) return;
        setState(() {
          _isOnline = data['isOnline'] ?? false;
          _walletBalance = (data['walletBalance'] ?? 0).toDouble();
          _tripsToday = data['tripsToday'] ?? 0;
          _earningsToday = (data['earningsToday'] ?? 0).toDouble();
          _vehicleCategory = data['vehicleCategory'] ?? '';
          _vehicleNumber = data['vehicleNumber'] ?? '';
          _vehicleModel = data['vehicleModel'] ?? '';
          _zone = data['zone'] ?? '';
          _driverRating = double.tryParse(data['rating']?.toString() ?? '') ?? _driverRating;
        });
        if (_isOnline) {
          _startLocationStreaming();
          // Re-announce online status via socket — restores driver_locations.is_online=true
          // after app restart/crash where socket disconnect handler had set it false.
          // Without this, dispatch won't find driver until first GPS update arrives (3s delay).
          _socket.setOnlineStatus(
            isOnline: true,
            lat: _center.latitude,
            lng: _center.longitude,
          );
        }
      } else if (res.statusCode == 401) {
        _handleSessionExpired();
        return;
      }
    } catch (_) {}
  }

  Future<void> _fetchLaunchBenefit() async {
    try {
      final headers = await AuthService.getHeaders();
      final res = await http.get(Uri.parse(ApiConfig.launchBenefit), headers: headers);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (mounted) {
          setState(() {
            _inFreePeriod = data['active'] == true;
            _freeDaysRemaining = data['freeDaysRemaining'] ?? 0;
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _fetchEligibleServices() async {
    try {
      final headers = await AuthService.getHeaders();
      final res = await http.get(Uri.parse(ApiConfig.eligibleServices), headers: headers);
      if (res.statusCode == 200 && mounted) {
        final data = jsonDecode(res.body);
        final list = (data['services'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
        setState(() => _eligibleServices = list);
      }
    } catch (_) {}
  }

  Future<void> _fetchUnreadCount() async {
    try {
      final headers = await AuthService.getHeaders();
      final res = await http.get(Uri.parse(ApiConfig.notifications), headers: headers);
      if (res.statusCode == 200 && mounted) {
        final data = jsonDecode(res.body);
        setState(() => _unreadNotifCount = (data['unreadCount'] ?? 0).toInt());
      }
    } catch (_) {}
  }

  void _startLocationStreaming() {
    _locationTimer?.cancel();
    _locationTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      try {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
        );
        final lat = pos.latitude;
        final lng = pos.longitude;
        if (!mounted) return;
        setState(() => _center = LatLng(lat, lng));

        final reqHeaders = await AuthService.getHeaders();
        _socket.sendLocation(lat: lat, lng: lng, speed: pos.speed);
        // Send isOnline=true so the server doesn't reset is_online to false on each update
        http.post(
          Uri.parse(ApiConfig.driverLocation),
          headers: reqHeaders,
          body: jsonEncode({'lat': lat, 'lng': lng, 'isOnline': true}),
        ).catchError((_) => http.Response('', 500));

        if (_isOnline && _incomingTrip == null) {
          try {
            final resp = await http.get(
              Uri.parse(ApiConfig.driverIncomingTrip),
              headers: reqHeaders,
            ).timeout(const Duration(seconds: 4));
            if (resp.statusCode == 200 && mounted) {
              final data = jsonDecode(resp.body) as Map<String, dynamic>;
              final trip = data['trip'];
              final stage = (data['stage'] ?? '').toString();
              if (trip != null && stage == 'new_request' && _incomingTrip == null) {
                final tripMap = Map<String, dynamic>.from(trip as Map);
                tripMap['tripId'] = tripMap['tripId'] ?? tripMap['id'];
                setState(() => _incomingTrip = tripMap);
                _showIncomingTrip();
              }
            }
          } catch (_) {}
        }
      } catch (_) {}
    });
  }

  void _stopLocationStreaming() {
    _locationTimer?.cancel();
    _locationTimer = null;
  }

  // ── Heatmap methods ────────────────────────────────────────────────────

  void _startHeatmapRefresh() {
    _idleSuggestionShown = false;
    _heatmap.startRefresh(
      _center.latitude, _center.longitude,
      onUpdate: () {
        if (!mounted) return;
        setState(() {
          _heatmapCircles = _showHeatmap ? _heatmap.buildCircles() : {};
          _nearestHighZone = _heatmap.nearestHighDemand(
            _center.latitude, _center.longitude);
        });
      },
    );
  }

  void _stopHeatmap() {
    _idleTimer?.cancel();
    _idleTimer = null;
    _idleSeconds = 0;
    _idleSuggestionShown = false;
    _heatmap.stopRefresh();
    if (mounted) setState(() { _heatmapCircles = {}; _nearestHighZone = null; _heatmapSuggestion = null; });
  }

  void _toggleHeatmap() {
    setState(() {
      _showHeatmap = !_showHeatmap;
      _heatmapCircles = _showHeatmap ? _heatmap.buildCircles() : {};
    });
  }

  void _startIdleTimer() {
    _idleTimer?.cancel();
    _idleSeconds = 0;
    _idleSuggestionShown = false;
    final timeoutSecs = _heatmap.idleTimeoutMinutes * 60;
    _idleTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_isOnline || _incomingTrip != null || !mounted) {
        _idleSeconds = 0;
        _idleSuggestionShown = false;
        return;
      }
      _idleSeconds++;
      if (_idleSeconds >= timeoutSecs && !_idleSuggestionShown) {
        _idleSuggestionShown = true;
        _triggerIdleSuggestion();
      }
    });
  }

  Future<void> _triggerIdleSuggestion() async {
    final sugg = await _heatmap.fetchSuggestion(_center.latitude, _center.longitude);
    if (sugg == null || !mounted) return;
    setState(() => _heatmapSuggestion = sugg);
    _showIdleSuggestionDialog(sugg);
  }

  void _showIdleSuggestionDialog(HeatmapSuggestion sugg) {
    showDialog(
      context: context,
      barrierColor: Colors.black38,
      builder: (_) => AlertDialog(
        backgroundColor: JT.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: JT.border, width: 1),
        ),
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: sugg.demandLevel == 'high'
                  ? JT.error.withValues(alpha: 0.10)
                  : JT.warning.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.local_fire_department_rounded,
              color: sugg.demandLevel == 'high' ? JT.error : JT.warning,
              size: 22),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text('Demand Zone Nearby',
              style: GoogleFonts.poppins(color: JT.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(sugg.message, style: GoogleFonts.poppins(color: JT.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(sugg.detail, style: GoogleFonts.poppins(color: JT.textSecondary, fontSize: 12)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: JT.success.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: JT.success.withValues(alpha: 0.25)),
            ),
            child: Row(children: [
              const Icon(Icons.currency_rupee_rounded, color: JT.success, size: 18),
              const SizedBox(width: 6),
              Text('₹${sugg.earningMin}–₹${sugg.earningMax} in 30 min',
                style: GoogleFonts.poppins(color: JT.success, fontWeight: FontWeight.bold, fontSize: 14)),
            ]),
          ),
        ]),
        actions: [
          TextButton(
            onPressed: () { Navigator.pop(context); _idleSuggestionShown = false; },
            child: Text('Stay Here', style: GoogleFonts.poppins(color: JT.textSecondary)),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _mapController?.animateCamera(CameraUpdate.newLatLngZoom(
                LatLng(sugg.lat, sugg.lng), 14));
            },
            icon: const Icon(Icons.navigation_rounded, size: 16),
            label: const Text('Go There'),
            style: ElevatedButton.styleFrom(
              backgroundColor: JT.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  void _showIncomingTrip() {
    if (_incomingTrip == null) return;
    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: true,
        fullscreenDialog: false,
        barrierDismissible: false,
        transitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (_, __, ___) => IncomingTripSheet(
          trip: _incomingTrip!,
          onAccept: () async {
            final trip = Map<String, dynamic>.from(_incomingTrip!);
            Navigator.pop(context);
            setState(() => _incomingTrip = null);
            FcmService().dismissTripNotification();

            final tripId = trip['tripId'] ?? trip['id'] ?? '';
            bool accepted = false;
            if (_socketConnected) {
              accepted = await _socket.acceptTrip(tripId);
            }
            if (!accepted) {
              try {
                final hdrs = await AuthService.getHeaders();
                final res = await http.post(
                  Uri.parse(ApiConfig.driverAcceptTrip),
                  headers: {...hdrs, 'Content-Type': 'application/json'},
                  body: jsonEncode({'tripId': tripId}),
                );
                if (res.statusCode == 200) accepted = true;
              } catch (_) {}
            }
            if (!mounted) return;
            if (!accepted) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Network issue — proceeding. Contact support if trip is missing.',
                  style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
                backgroundColor: JT.warning,
                behavior: SnackBarBehavior.floating,
                duration: Duration(seconds: 4),
              ));
            }
            // Fetch full trip data from server (includes destinationLat/Lng, customerId, customerPhone)
            Map<String, dynamic> fullTrip = trip;
            try {
              final hdrs = await AuthService.getHeaders();
              final res = await http.get(Uri.parse(ApiConfig.driverIncomingTrip), headers: hdrs)
                .timeout(const Duration(seconds: 6));
              if (res.statusCode == 200) {
                final data = jsonDecode(res.body) as Map<String, dynamic>;
                if (data['trip'] != null) {
                  fullTrip = Map<String, dynamic>.from(trip)
                    ..addAll(Map<String, dynamic>.from(data['trip'] as Map));
                }
              }
            } catch (_) {}
            if (!mounted) return;
            Navigator.push(context, MaterialPageRoute(builder: (_) => TripScreen(trip: fullTrip)));
          },
          onReject: () async {
            final trip = Map<String, dynamic>.from(_incomingTrip!);
            Navigator.pop(context);
            setState(() => _incomingTrip = null);
            FcmService().dismissTripNotification();
            try {
              final hdrs = await AuthService.getHeaders();
              await http.post(
                Uri.parse(ApiConfig.driverRejectTrip),
                headers: hdrs,
                body: jsonEncode({'tripId': trip['tripId'] ?? trip['id'] ?? ''}),
              );
            } catch (_) {}
          },
        ),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  void _showIncomingParcel() {
    final parcel = _incomingParcel;
    if (parcel == null) return;
    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: true,
        barrierDismissible: false,
        transitionDuration: const Duration(milliseconds: 280),
        pageBuilder: (_, __, ___) => IncomingParcelSheet(
          parcel: parcel,
          onAccept: () async {
            setState(() => _incomingParcel = null);
            final orderId = parcel['orderId']?.toString() ?? parcel['id']?.toString() ?? '';
            if (orderId.isEmpty) return;
            try {
              final hdrs = await AuthService.getHeaders();
              final r = await http.post(Uri.parse(ApiConfig.driverParcelAccept(orderId)), headers: hdrs);
              if (!mounted) return;
              if (r.statusCode == 200) {
                final data = jsonDecode(r.body);
                final order = data['order'] as Map<String, dynamic>? ?? {};
                Navigator.push(context, MaterialPageRoute(builder: (_) => ParcelDeliveryScreen(order: order)));
              } else {
                _showSnack('Already taken by another driver', error: true);
              }
            } catch (_) {
              if (mounted) _showSnack('Network error, try again', error: true);
            }
          },
          onSkip: () {
            if (mounted) setState(() => _incomingParcel = null);
          },
        ),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
      ),
    ).whenComplete(() {
      if (mounted) setState(() => _incomingParcel = null);
    });
  }

  void _showSnack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: Colors.white)),
      backgroundColor: error ? JT.error : JT.success,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 4),
    ));
  }

  void _showWalletLockedDialog(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        backgroundColor: JT.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: JT.error.withValues(alpha: 0.3), width: 1),
        ),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 70, height: 70,
            decoration: BoxDecoration(
              color: JT.error.withValues(alpha: 0.08),
              shape: BoxShape.circle,
              border: Border.all(color: JT.error.withValues(alpha: 0.25)),
            ),
            child: const Icon(Icons.account_balance_wallet_rounded, color: JT.error, size: 34),
          ),
          const SizedBox(height: 16),
          Text(
            'Wallet Balance Low',
            style: GoogleFonts.poppins(
              color: JT.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: GoogleFonts.poppins(color: JT.textSecondary, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: JT.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.add_circle_outline, color: Colors.white, size: 20),
              label: Text(
                'Recharge Wallet Now',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const WalletScreen()));
              },
            ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Later', style: GoogleFonts.poppins(color: JT.textSecondary)),
          ),
        ]),
      ),
    );
  }

  Future<bool> _checkFaceVerificationAndProceed() async {
    try {
      final headers = await AuthService.getHeaders();
      final res = await http.get(
        Uri.parse(ApiConfig.checkVerification),
        headers: headers,
      ).timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['needsVerification'] == true && mounted) {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => FaceVerificationScreen(
                reason: data['reason']?.toString() ?? 'daily_check',
                onVerified: () => Navigator.pop(context),
              ),
            ),
          );
          if (mounted) _toggleOnline();
          return true;
        }
      }
    } catch (_) {}
    return false;
  }

  Future<void> _toggleOnline() async {
    HapticFeedback.mediumImpact();
    if (!_isOnline) {
      final redirected = await _checkFaceVerificationAndProceed();
      if (redirected) return;
    }
    setState(() => _toggling = true);
    final newStatus = !_isOnline;
    try {
      _socket.setOnlineStatus(
        isOnline: newStatus,
        lat: _center.latitude,
        lng: _center.longitude,
      );

      final headers = await AuthService.getHeaders();
      final res = await http.patch(
        Uri.parse(ApiConfig.driverOnlineStatus),
        headers: headers,
        body: jsonEncode({
          'isOnline': newStatus,
          'lat': _center.latitude,
          'lng': _center.longitude,
        }),
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        setState(() => _isOnline = newStatus);
        if (_isOnline) {
          _startLocationStreaming();
          _startHeatmapRefresh();
          _startIdleTimer();
          _showSnack('Online అయ్యారు! Trips కోసం ready ✓');
        } else {
          _stopLocationStreaming();
          _stopHeatmap();
          _showSnack('Offline అయ్యారు');
        }
      } else if (res.statusCode == 401) {
        _socket.setOnlineStatus(isOnline: false, lat: _center.latitude, lng: _center.longitude);
        setState(() => _toggling = false);
        _handleSessionExpired();
        return;
      } else {
        Map<String, dynamic> errBody = {};
        try { errBody = jsonDecode(res.body); } catch (_) {}

        if (errBody['notVerified'] == true) {
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const PendingVerificationScreen()),
          );
          return;
        }

        if (errBody['needsModelSelection'] == true || errBody['needsModelSelection'] == 'true') {
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const ModelSelectionScreen()),
          );
          return;
        }

        if (errBody['subscriptionExpired'] == true || errBody['subscriptionExpired'] == 'true'
            || errBody['requiresSubscription'] == true || errBody['requiresSubscription'] == 'true') {
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const SubscriptionPlansScreen()),
          );
          return;
        }

        if (errBody['isLocked'] == true || errBody['isLocked'] == 'true') {
          if (!mounted) return;
          setState(() => _toggling = false);
          _socket.setOnlineStatus(isOnline: false, lat: _center.latitude, lng: _center.longitude);
          _showWalletLockedDialog(errBody['message']?.toString() ?? 'Wallet balance too low.');
          return;
        }

        if (errBody['documentExpired'] == true || errBody['documentExpired'] == 'true') {
          if (!mounted) return;
          setState(() => _toggling = false);
          _socket.setOnlineStatus(isOnline: false, lat: _center.latitude, lng: _center.longitude);
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              backgroundColor: JT.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: JT.warning.withValues(alpha: 0.4), width: 1),
              ),
              title: Row(children: [
                const Icon(Icons.warning_amber_rounded, color: JT.warning, size: 28),
                const SizedBox(width: 10),
                Text(
                  'Document Expired',
                  style: GoogleFonts.poppins(
                    color: JT.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ]),
              content: Text(
                errBody['message']?.toString() ?? 'A document has expired. Please upload an updated document.',
                style: GoogleFonts.poppins(color: JT.textSecondary, fontSize: 14),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const KycDocumentsScreen()));
                  },
                  child: Text(
                    'Update Documents',
                    style: GoogleFonts.poppins(color: JT.primary, fontWeight: FontWeight.bold),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Later',
                    style: GoogleFonts.poppins(color: JT.textSecondary),
                  ),
                ),
              ],
            ),
          );
          return;
        }

        final msg = errBody['message']?.toString() ?? 'Server error. Try again.';
        _showSnack(msg, error: true);
        _socket.setOnlineStatus(isOnline: _isOnline, lat: _center.latitude, lng: _center.longitude);
      }
    } on Exception catch (_) {
      _showSnack('Connection error. Please check your internet.', error: true);
      _socket.setOnlineStatus(isOnline: _isOnline, lat: _center.latitude, lng: _center.longitude);
    }
    setState(() => _toggling = false);
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: JT.bg,
        drawer: _buildDrawer(),
        bottomNavigationBar: _buildDriverBottomNav(),
        body: Stack(children: [
          // Full-screen map
          GoogleMap(
            initialCameraPosition: CameraPosition(target: _center, zoom: 14),
            onMapCreated: (c) { _mapController = c; },
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            circles: _heatmapCircles,
          ),
          // Subtle white gradient overlay at top for readability
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              height: 180,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: 0.92),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(children: [
              _buildTopBar(),
              const SizedBox(height: 10),
              const Spacer(),
              // Heatmap banner
              if (_isOnline && _nearestHighZone != null && _showHeatmap)
                _buildHeatmapBanner(_nearestHighZone!),
              _buildBottomPanel(),
            ]),
          ),
          // Heatmap toggle button
          if (_isOnline)
            Positioned(
              right: 14,
              bottom: 100,
              child: _buildHeatmapToggle(),
            ),
        ]),
      ),
    );
  }

  Widget _buildHeatmapBanner(HeatmapZone zone) {
    final color = zone.color;
    final icon = zone.demandLevel == 'high' ? Icons.local_fire_department_rounded : Icons.trending_up_rounded;

    return GestureDetector(
      onTap: () => _mapController?.animateCamera(CameraUpdate.newLatLngZoom(LatLng(zone.lat, zone.lng), 15)),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: JT.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.15), blurRadius: 14, offset: const Offset(0, 4))],
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              zone.demandLevel == 'high' ? '🔴 High demand zone ${_calcDist(zone)} away' : '🟡 Medium demand zone ${_calcDist(zone)} away',
              style: GoogleFonts.poppins(color: JT.textPrimary, fontSize: 12, fontWeight: FontWeight.w700),
            ),
            if (zone.earningMin > 0)
              Text(
                'Est. ₹${zone.earningMin}–₹${zone.earningMax} in 30 min',
                style: GoogleFonts.poppins(color: color, fontSize: 11, fontWeight: FontWeight.w600),
              ),
          ])),
          Icon(Icons.arrow_forward_ios_rounded, color: JT.iconInactive, size: 14),
        ]),
      ),
    );
  }

  String _calcDist(HeatmapZone zone) {
    final dLat = (zone.lat - _center.latitude) * 111.32;
    final dLng = (zone.lng - _center.longitude) * 111.32 * cos(_center.latitude * pi / 180);
    final d = sqrt(dLat * dLat + dLng * dLng);
    if (d < 1.0) return '${(d * 1000).toStringAsFixed(0)} m';
    return '${d.toStringAsFixed(1)} km';
  }

  Widget _buildHeatmapToggle() {
    return GestureDetector(
      onTap: _toggleHeatmap,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: _showHeatmap ? JT.primary : JT.surface,
          shape: BoxShape.circle,
          border: Border.all(
            color: _showHeatmap ? JT.primary : JT.border,
            width: 1.5),
          boxShadow: JT.cardShadow,
        ),
        child: Icon(
          Icons.layers_rounded,
          color: _showHeatmap ? Colors.white : JT.iconInactive,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(children: [
        _iconBtn(Icons.menu_rounded, () => _scaffoldKey.currentState?.openDrawer()),
        const SizedBox(width: 10),
        // Pilot logo + greeting
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: JT.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: JT.border),
              boxShadow: JT.cardShadow,
            ),
            child: Row(children: [
              // Pilot logo with socket indicator
              Stack(clipBehavior: Clip.none, children: [
                JT.logoPilot(height: 28),
                Positioned(
                  top: -2, right: -4,
                  child: Container(
                    width: 8, height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _socketConnected ? JT.success : JT.warning,
                      border: Border.all(color: JT.surface, width: 1.5),
                    ),
                  ),
                ),
              ]),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                  Text(
                    '${_getTimeGreeting()}, ${_userName.split(' ').first}!',
                    style: GoogleFonts.poppins(
                      color: JT.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (_isOnline)
                    Row(children: [
                      AnimatedBuilder(
                        animation: _pulseCtrl,
                        builder: (_, __) => Container(
                          width: 6, height: 6,
                          margin: const EdgeInsets.only(right: 4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: JT.success,
                            boxShadow: [BoxShadow(
                              color: JT.success.withValues(alpha: 0.4 + _pulseCtrl.value * 0.4),
                              blurRadius: 3 + _pulseCtrl.value * 4,
                            )],
                          ),
                        ),
                      ),
                      Text(
                        'Online — trips enabled',
                        style: GoogleFonts.poppins(
                          color: JT.success,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ])
                  else
                    Row(children: [
                      Container(
                        width: 6, height: 6,
                        margin: const EdgeInsets.only(right: 4),
                        decoration: BoxDecoration(shape: BoxShape.circle, color: JT.error.withValues(alpha: 0.6)),
                      ),
                      Text(
                        'Offline — tap to go online',
                        style: GoogleFonts.poppins(
                          color: JT.textSecondary,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ]),
                ]),
              ),
            ]),
          ),
        ),
        const SizedBox(width: 8),
        // Notifications bell
        GestureDetector(
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()))
              .then((_) => _fetchUnreadCount());
          },
          child: Stack(children: [
            Container(
              width: 46, height: 46,
              decoration: BoxDecoration(
                color: JT.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: JT.border),
                boxShadow: JT.cardShadow,
              ),
              child: Icon(Icons.notifications_rounded, color: JT.textSecondary, size: 22),
            ),
            if (_unreadNotifCount > 0)
              Positioned(
                top: 5, right: 5,
                child: Container(
                  width: 17, height: 17,
                  decoration: BoxDecoration(
                    color: JT.error,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      _unreadNotifCount > 9 ? '9+' : _unreadNotifCount.toString(),
                      style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
              ),
          ]),
        ),
        const SizedBox(width: 8),
        _iconBtn(Icons.my_location_rounded, _getLocation),
      ]),
    );
  }

  Widget _iconBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 46, height: 46,
        decoration: BoxDecoration(
          color: JT.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: JT.border),
          boxShadow: JT.cardShadow,
        ),
        child: Icon(icon, color: JT.textSecondary, size: 20),
      ),
    );
  }

  Widget _buildBottomPanel() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      decoration: BoxDecoration(
        color: JT.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: JT.border, width: 1),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 28, offset: const Offset(0, -4)),
        ],
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Drag handle
        Container(
          width: 44, height: 4,
          margin: const EdgeInsets.only(top: 12, bottom: 12),
          decoration: BoxDecoration(
            color: JT.border,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        // Hero earnings banner
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: JT.bgSoft,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: JT.border),
            ),
            child: Row(children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                  "Today's Total",
                  style: GoogleFonts.poppins(
                    color: JT.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Row(children: [
                  Text(
                    '₹${_earningsToday.toStringAsFixed(0)}',
                    style: GoogleFonts.poppins(
                      color: JT.primary,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: JT.success.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: JT.success.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      '$_tripsToday trips',
                      style: GoogleFonts.poppins(
                        color: JT.success,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ]),
              ]),
              const Spacer(),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(
                  'Wallet',
                  style: GoogleFonts.poppins(
                    color: JT.textSecondary,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '₹${_walletBalance.toStringAsFixed(0)}',
                  style: GoogleFonts.poppins(
                    color: JT.warning,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ]),
            ]),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          child: Column(children: [
            // Avatar + greeting + toggle row
            Row(children: [
              Container(
                width: 50, height: 50,
                decoration: BoxDecoration(
                  gradient: JT.grad,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: JT.btnShadow,
                ),
                child: Center(
                  child: Text(
                    _userName.isNotEmpty ? _userName[0].toUpperCase() : 'P',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(
                    _getTimeGreeting(),
                    style: GoogleFonts.poppins(
                      color: JT.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _userName.split(' ').first.isNotEmpty ? _userName.split(' ').first : 'Pilot',
                    style: GoogleFonts.poppins(
                      color: JT.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  if (!_isOnline)
                    Text(
                      'Tap GO ONLINE to start earning',
                      style: GoogleFonts.poppins(
                        color: JT.warning,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ]),
              ),
              // Inline toggle button
              GestureDetector(
                onTap: _toggling ? null : _toggleOnline,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    gradient: _isOnline
                        ? JT.grad
                        : null,
                    color: _isOnline ? null : JT.surfaceAlt,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: _isOnline ? JT.btnShadow : [],
                    border: _isOnline ? null : Border.all(color: JT.border),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    AnimatedBuilder(
                      animation: _pulseCtrl,
                      builder: (_, __) => Container(
                        width: 8, height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isOnline ? Colors.white : JT.textSecondary,
                          boxShadow: _isOnline ? [BoxShadow(
                            color: Colors.white.withValues(alpha: 0.5 + _pulseCtrl.value * 0.3),
                            blurRadius: 3 + _pulseCtrl.value * 4,
                          )] : [],
                        ),
                      ),
                    ),
                    const SizedBox(width: 7),
                    Text(
                      _isOnline ? 'GO OFFLINE' : 'GO ONLINE',
                      style: GoogleFonts.poppins(
                        color: _isOnline ? Colors.white : JT.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ]),
                ),
              ),
            ]),
            if (_isOnline) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: JT.success.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: JT.success.withValues(alpha: 0.2), width: 1),
                ),
                child: Row(children: [
                  AnimatedBuilder(
                    animation: _pulseCtrl,
                    builder: (_, __) => Container(
                      width: 8, height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: JT.success,
                        boxShadow: [BoxShadow(
                          color: JT.success.withValues(alpha: 0.4 + _pulseCtrl.value * 0.4),
                          blurRadius: 4 + _pulseCtrl.value * 6,
                        )],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'LIVE — Incoming trips enabled',
                    style: GoogleFonts.poppins(
                      color: JT.success,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '₹${_earningsToday.toStringAsFixed(0)} earned',
                    style: GoogleFonts.poppins(
                      color: JT.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ]),
              ),
            ],
            const SizedBox(height: 14),
            if (_inFreePeriod) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: JT.success.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: JT.success.withValues(alpha: 0.25)),
                ),
                child: Row(children: [
                  const Text('🎉', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 10),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Free Period Active',
                        style: GoogleFonts.poppins(color: JT.textPrimary, fontWeight: FontWeight.w700, fontSize: 13)),
                      Text('No subscription & no commission for $_freeDaysRemaining more day${_freeDaysRemaining == 1 ? '' : 's'}',
                        style: GoogleFonts.poppins(color: JT.success, fontSize: 11)),
                    ],
                  )),
                ]),
              ),
            ],
            _buildStatsRow(),
            if (_vehicleCategory.isNotEmpty || _vehicleNumber.isNotEmpty) ...[
              const SizedBox(height: 10),
              _buildVehicleCard(),
            ],
            if (_eligibleServices.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: JT.primary.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: JT.primary.withValues(alpha: 0.15)),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Your Eligible Services',
                    style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700, color: JT.textPrimary)),
                  const SizedBox(height: 8),
                  Wrap(spacing: 8, runSpacing: 6, children: _eligibleServices.map((svc) {
                    final name = svc['service_name']?.toString() ?? svc['key']?.toString() ?? '';
                    return Chip(
                      avatar: const Icon(Icons.directions_car_filled_rounded, size: 14, color: JT.primary),
                      label: Text(name, style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600)),
                      backgroundColor: JT.primary.withValues(alpha: 0.08),
                      side: BorderSide(color: JT.primary.withValues(alpha: 0.2)),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    );
                  }).toList()),
                ]),
              ),
            ],
            if (_isOnline && (
              _vehicleCategory.toLowerCase().contains('parcel') ||
              _vehicleCategory.toLowerCase().contains('cargo') ||
              _vehicleCategory.toLowerCase().contains('bike')
            )) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  color: JT.warning.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: JT.warning.withValues(alpha: 0.25), width: 1),
                ),
                child: Row(children: [
                  const Icon(Icons.inventory_2_rounded, size: 18, color: Color(0xFFF59E0B)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Parcel deliveries active — stay ready!',
                      style: GoogleFonts.poppins(
                        color: JT.warning,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: JT.warning.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'EARN MORE',
                      style: GoogleFonts.poppins(
                        color: JT.warning,
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ]),
              ),
            ],
            const SizedBox(height: 16),
            _buildToggleBtn(),
            const SizedBox(height: 14),
            if (!_isOnline) _buildOfflineTip(),
            if (!_isOnline) const SizedBox(height: 12),
            _buildActionRow(),
            const SizedBox(height: 20),
          ]),
        ),
      ]),
    );
  }

  Widget _buildVehicleCard() {
    final IconData vIcon = _vehicleCategory.toLowerCase().contains('bike')
      ? Icons.electric_bike_rounded
      : _vehicleCategory.toLowerCase().contains('auto')
        ? Icons.electric_rickshaw_rounded
        : _vehicleCategory.toLowerCase().contains('suv')
          ? Icons.directions_car_filled_rounded
          : Icons.directions_car_rounded;

    return Container(
      decoration: BoxDecoration(
        color: JT.bgSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border(
          left: const BorderSide(color: JT.primary, width: 3),
          right: BorderSide(color: JT.border),
          top: BorderSide(color: JT.border),
          bottom: BorderSide(color: JT.border),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              gradient: JT.grad,
              borderRadius: BorderRadius.circular(12),
              boxShadow: JT.btnShadow,
            ),
            child: Icon(vIcon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                _vehicleCategory.isNotEmpty ? _vehicleCategory : 'My Vehicle',
                style: GoogleFonts.poppins(
                  color: JT.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
              if (_vehicleNumber.isNotEmpty || _vehicleModel.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  [
                    if (_vehicleNumber.isNotEmpty) _vehicleNumber.toUpperCase(),
                    if (_vehicleModel.isNotEmpty) _vehicleModel,
                  ].join('  ·  '),
                  style: GoogleFonts.poppins(
                    color: JT.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ]),
          ),
          if (_zone.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: JT.success.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: JT.success.withValues(alpha: 0.25)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.location_on_rounded, color: JT.success, size: 10),
                const SizedBox(width: 3),
                Text(
                  _zone,
                  style: GoogleFonts.poppins(
                    color: JT.success,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ]),
            ),
        ]),
      ),
    );
  }

  Widget _buildToggleBtn() {
    final isOn = _isOnline;
    return GestureDetector(
      onTap: _toggling ? null : _toggleOnline,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
        width: double.infinity,
        height: 76,
        decoration: BoxDecoration(
          gradient: isOn
              ? const LinearGradient(colors: [Color(0xFF16A34A), Color(0xFF15803D)], begin: Alignment.topLeft, end: Alignment.bottomRight)
              : const LinearGradient(colors: [Color(0xFF2F6BFF), Color(0xFF1A4DC8)], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: (isOn ? const Color(0xFF16A34A) : const Color(0xFF2F6BFF)).withValues(alpha: 0.40),
              blurRadius: 20, offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Center(
          child: _toggling
            ? const SizedBox(width: 28, height: 28, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.8))
            : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                AnimatedBuilder(
                  animation: _pulseCtrl,
                  builder: (_, __) => Container(
                    width: 12, height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [BoxShadow(
                        color: Colors.white.withValues(alpha: 0.4 + _pulseCtrl.value * 0.4),
                        blurRadius: 4 + _pulseCtrl.value * 8,
                      )],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(
                    isOn ? 'GO OFFLINE' : 'GO ONLINE',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                    ),
                  ),
                  Text(
                    isOn ? 'Tap to stop accepting trips' : 'Tap to start earning',
                    style: GoogleFonts.poppins(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ]),
                const SizedBox(width: 16),
                Icon(
                  isOn ? Icons.stop_circle_outlined : Icons.play_circle_outline_rounded,
                  color: Colors.white.withValues(alpha: 0.85),
                  size: 28,
                ),
              ]),
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(children: [
          Container(
            width: 4, height: 16,
            decoration: BoxDecoration(
              gradient: JT.grad,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            "Today's Performance",
            style: GoogleFonts.poppins(
              color: JT.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: JT.surfaceAlt,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: JT.border),
            ),
            child: Text(
              _ordinal(DateTime.now().day),
              style: GoogleFonts.poppins(
                color: JT.primary,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ]),
      ),
      Row(children: [
        Expanded(child: _statCard(
          icon: Icons.currency_rupee_rounded,
          iconColor: JT.primary,
          label: 'Earned',
          value: '₹${_earningsToday.toStringAsFixed(0)}',
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EarningsScreen())),
        )),
        const SizedBox(width: 8),
        Expanded(child: _statCard(
          icon: Icons.directions_car_rounded,
          iconColor: JT.success,
          label: 'Trips',
          value: '$_tripsToday',
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TripsHistoryScreen())),
        )),
        const SizedBox(width: 8),
        Expanded(child: _statCard(
          icon: Icons.star_rounded,
          iconColor: const Color(0xFFF59E0B),
          label: 'Rating',
          value: _driverRating.toStringAsFixed(1),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TripsHistoryScreen())),
        )),
        const SizedBox(width: 8),
        Expanded(child: _statCard(
          icon: Icons.account_balance_wallet_rounded,
          iconColor: const Color(0xFF8B5CF6),
          label: 'Wallet',
          value: '₹${_walletBalance.toStringAsFixed(0)}',
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WalletScreen())),
        )),
      ]),
    ]);
  }

  Widget _statCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 14, 10, 12),
        decoration: BoxDecoration(
          color: JT.bgSoft,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: JT.border, width: 1),
          boxShadow: JT.cardShadow,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 3, width: 32,
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [iconColor, iconColor.withValues(alpha: 0.2)]),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.10),
                shape: BoxShape.circle,
                border: Border.all(color: iconColor.withValues(alpha: 0.2)),
              ),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: GoogleFonts.poppins(
                color: JT.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: GoogleFonts.poppins(
                color: JT.textSecondary,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOfflineTip() {
    final tips = [
      'Go Online to start receiving ride requests',
      'Pilots who start early earn more today',
      'Tap Go Online — trips are waiting near you',
      'Stay consistent — daily earnings add up!',
    ];
    final tip = tips[DateTime.now().minute % tips.length];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: JT.bgSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: JT.border),
      ),
      child: Row(children: [
        Container(
          width: 38, height: 38,
          decoration: BoxDecoration(
            color: JT.surfaceAlt,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.lightbulb_outline_rounded, color: JT.primary, size: 19),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            tip,
            style: GoogleFonts.poppins(
              color: JT.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildActionRow() {
    return Row(children: [
      Expanded(child: _actionChip(Icons.coffee_rounded, 'Break', JT.warning, () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const BreakModeScreen()));
      })),
      const SizedBox(width: 10),
      Expanded(child: _actionChip(Icons.account_balance_wallet_rounded, 'Wallet', JT.success, () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const WalletScreen()));
      })),
      const SizedBox(width: 10),
      Expanded(child: _actionChip(Icons.history_rounded, 'Trips', JT.primary, () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const TripsHistoryScreen()));
      })),
    ]);
  }

  Widget _actionChip(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: JT.bgSoft,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: JT.border, width: 1),
          boxShadow: JT.cardShadow,
        ),
        child: Column(children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.2)),
            ),
            child: Icon(icon, color: color, size: 19),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: GoogleFonts.poppins(color: color, fontSize: 11, fontWeight: FontWeight.w700),
          ),
        ]),
      ),
    );
  }

  Widget _buildDriverBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: JT.surface,
        border: const Border(top: BorderSide(color: JT.border, width: 1)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 24, offset: const Offset(0, -4))],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _driverNavItem(Icons.map_rounded, 'Home', 0),
              _driverNavItem(Icons.currency_rupee_rounded, 'Earnings', 1),
              _driverNavItem(Icons.account_balance_wallet_rounded, 'Wallet', 2),
              _driverNavItem(Icons.person_rounded, 'Profile', 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _driverNavItem(IconData icon, String label, int index) {
    final active = _navIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() => _navIndex = index);
        if (index == 0) return;
        if (index == 1) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const EarningsScreen()))
              .then((_) => setState(() => _navIndex = 0));
        } else if (index == 2) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const WalletScreen()))
              .then((_) => setState(() => _navIndex = 0));
        } else if (index == 3) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()))
              .then((_) => setState(() => _navIndex = 0));
        }
      },
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          width: 44, height: 34,
          decoration: BoxDecoration(
            color: active ? JT.surfaceAlt : Colors.transparent,
            borderRadius: BorderRadius.circular(22),
            border: active ? Border.all(color: JT.border, width: 1) : null,
          ),
          child: Icon(icon, size: 20, color: active ? JT.primary : JT.iconInactive),
        ),
        const SizedBox(height: 3),
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

  Widget _buildDrawer() {
    return Drawer(
      child: Container(
        color: JT.bg,
        child: SafeArea(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: JT.grad,
                borderRadius: BorderRadius.circular(20),
                boxShadow: JT.btnShadow,
              ),
              child: Row(children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  child: Text(
                    _userName.isNotEmpty ? _userName[0].toUpperCase() : 'P',
                    style: GoogleFonts.poppins(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(
                      _userName,
                      style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '+91 $_userPhone',
                      style: GoogleFonts.poppins(color: Colors.white.withValues(alpha: 0.75), fontSize: 12),
                    ),
                    const SizedBox(height: 6),
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.verified_rounded, color: Colors.white, size: 12),
                          const SizedBox(width: 4),
                          JT.logoPilot(height: 14),
                        ]),
                      ),
                    ]),
                  ]),
                ),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Divider(color: JT.border, height: 1),
            ),
            const SizedBox(height: 8),
            _drawerItem(Icons.dashboard_rounded, 'Dashboard', null, () {}),
            _drawerItem(Icons.currency_rupee_rounded, 'Earnings', '₹${_earningsToday.toStringAsFixed(0)}', () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const EarningsScreen()));
            }),
            _drawerItem(Icons.route_rounded, 'My Trips', null, () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const TripsHistoryScreen()));
            }),
            _drawerItem(Icons.account_balance_wallet_rounded, 'Wallet', '₹${_walletBalance.toStringAsFixed(0)}', () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const WalletScreen()));
            }),
            _drawerItem(Icons.person_rounded, 'Profile', null, () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
            }),
            _drawerItem(Icons.health_and_safety_rounded, 'Safety & Fatigue', null, () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const FatigueScreen()));
            }),
            _drawerItem(Icons.headset_mic_rounded, 'Support', null, () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const DriverSupportChatScreen()));
            }),
            _drawerItem(Icons.card_giftcard_rounded, 'Refer & Earn', null, () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ReferralScreen()));
            }),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: GestureDetector(
                onTap: () async {
                  _socket.disconnect();
                  await AuthService.logout();
                  if (!mounted) return;
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (_) => false,
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: JT.error.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: JT.error.withValues(alpha: 0.2), width: 1),
                  ),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.logout_rounded, color: JT.error, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Logout',
                      style: GoogleFonts.poppins(
                        color: JT.error,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ]),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Center(
                child: Text(
                  'v1.0.29 • MindWheel IT Solutions',
                  style: GoogleFonts.poppins(color: JT.iconInactive, fontSize: 10),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _drawerItem(IconData icon, String label, String? badge, VoidCallback onTap) {
    return ListTile(
      leading: Container(
        width: 38, height: 38,
        decoration: BoxDecoration(
          color: JT.surfaceAlt,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: JT.border),
        ),
        child: Icon(icon, color: JT.primary, size: 18),
      ),
      title: Text(
        label,
        style: GoogleFonts.poppins(color: JT.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
      ),
      trailing: badge != null
        ? Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: JT.success.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: JT.success.withValues(alpha: 0.25)),
            ),
            child: Text(
              badge,
              style: GoogleFonts.poppins(
                color: JT.success,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          )
        : Icon(Icons.chevron_right_rounded, color: JT.iconInactive, size: 18),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
    );
  }
}
