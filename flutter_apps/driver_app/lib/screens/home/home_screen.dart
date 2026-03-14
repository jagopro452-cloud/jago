import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/api_config.dart';
import '../../services/auth_service.dart';
import '../../services/socket_service.dart';
import '../../services/alarm_service.dart';
import '../../widgets/incoming_trip_sheet.dart';
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

  static const Color _primary = Color(0xFF2F80ED);
  static const Color _bg = Color(0xFF0F172A);
  static const Color _surface = Color(0xFF1E293B);
  static const Color _green = Color(0xFF16A34A);

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
    _connectSocket();
    // Check for pending FCM trip (app opened from notification while terminated)
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkPendingFcmTrip());
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
          // Check if driver is in 30-day free period — skip model selection if so
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

  Future<void> _checkPendingFcmTrip() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pendingStr = prefs.getString('pending_trip_data');
      if (pendingStr != null && pendingStr.isNotEmpty) {
        await prefs.remove('pending_trip_data');
        final tripData = jsonDecode(pendingStr) as Map<String, dynamic>;
        if (!mounted) return;
        if (_incomingTrip == null) {
          await Future.delayed(const Duration(milliseconds: 800));
          setState(() => _incomingTrip = tripData);
          _showIncomingTrip();
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
        backgroundColor: Color(0xFFEF4444),
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
          backgroundColor: Color(0xFF6B7280),
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
          backgroundColor: Color(0xFFF59E0B),
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
      AlarmService().startAlarm();
      _showIncomingParcel();
    }));
  }

  @override
  void dispose() {
    for (final s in _subs) s.cancel();
    _locationTimer?.cancel();
    _pulseCtrl.dispose();
    super.dispose();
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
      backgroundColor: Color(0xFFEF4444),
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
        setState(() {
          _isOnline = data['isOnline'] ?? false;
          _walletBalance = (data['walletBalance'] ?? 0).toDouble();
          _tripsToday = data['tripsToday'] ?? 0;
          _earningsToday = (data['earningsToday'] ?? 0).toDouble();
          _vehicleCategory = data['vehicleCategory'] ?? '';
          _vehicleNumber = data['vehicleNumber'] ?? '';
          _vehicleModel = data['vehicleModel'] ?? '';
          _zone = data['zone'] ?? '';
        });
        if (_isOnline) _startLocationStreaming();
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

  Future<void> _fetchUnreadCount() async {
    try {
      final headers = await AuthService.getHeaders();
      final res = await http.get(Uri.parse(ApiConfig.notifications), headers: headers);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() => _unreadNotifCount = (data['unreadCount'] ?? 0).toInt());
      }
    } catch (_) {}
  }

  void _startLocationStreaming() {
    _locationTimer?.cancel();
    _locationTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
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
        http.post(
          Uri.parse(ApiConfig.driverLocation),
          headers: reqHeaders,
          body: jsonEncode({'lat': lat, 'lng': lng}),
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
                await http.post(
                  Uri.parse(ApiConfig.driverAcceptTrip),
                  headers: hdrs,
                  body: jsonEncode({'tripId': tripId}),
                );
              } catch (_) {}
            }
            if (!mounted) return;
            Navigator.push(context, MaterialPageRoute(builder: (_) => TripScreen(trip: trip)));
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1E293B),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFF334155),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('📦', style: TextStyle(fontSize: 28)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                  'New Parcel Request',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${parcel['dropCount'] ?? 1} stop${(parcel['dropCount'] ?? 1) > 1 ? 's' : ''}',
                  style: GoogleFonts.poppins(color: const Color(0xFFF59E0B), fontSize: 13),
                ),
              ]),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _primary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '₹${parcel['totalFare'] ?? 0}',
                style: GoogleFonts.poppins(
                  color: const Color(0xFF60A5FA),
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ]),
          const SizedBox(height: 14),
          if ((parcel['pickupAddress'] ?? '').toString().isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(children: [
                const Icon(Icons.location_on, color: Color(0xFF22C55E), size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    parcel['pickupAddress'] ?? '',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                    maxLines: 2,
                  ),
                ),
              ]),
            ),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  AlarmService().stopAlarm();
                  setState(() => _incomingParcel = null);
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(
                  'Pass',
                  style: GoogleFonts.poppins(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: () async {
                  final orderId = parcel['orderId']?.toString() ?? '';
                  if (orderId.isEmpty) return;
                  Navigator.pop(context);
                  AlarmService().stopAlarm();
                  setState(() => _incomingParcel = null);
                  try {
                    final hdrs = await AuthService.getHeaders();
                    final r = await http.post(
                      Uri.parse(ApiConfig.driverParcelAccept(orderId)),
                      headers: hdrs,
                    );
                    if (r.statusCode == 200) {
                      _showSnack('Parcel order accepted! Check pending orders.');
                    } else {
                      _showSnack('Already taken by another driver', error: true);
                    }
                  } catch (_) {
                    _showSnack('Network error, try again', error: true);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF59E0B),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(
                  'Accept Delivery',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ),
          ]),
        ]),
      ),
    ).whenComplete(() {
      AlarmService().stopAlarm();
      if (mounted) setState(() => _incomingParcel = null);
    });
  }

  void _showSnack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
      backgroundColor: error ? Colors.red.shade700 : _green,
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
        backgroundColor: _surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.red, size: 32),
          ),
          const SizedBox(height: 16),
          Text(
            'Wallet Balance Low',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
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
            child: Text('Later', style: GoogleFonts.poppins(color: Colors.white38)),
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
          _showSnack('Online అయ్యారు! Trips కోసం ready ✓');
        } else {
          _stopLocationStreaming();
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
              backgroundColor: _surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
                const SizedBox(width: 10),
                Text(
                  'Document Expired',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ]),
              content: Text(
                errBody['message']?.toString() ?? 'A document has expired. Please upload an updated document.',
                style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const KycDocumentsScreen()));
                  },
                  child: Text(
                    'Update Documents',
                    style: GoogleFonts.poppins(color: _primary, fontWeight: FontWeight.bold),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Later',
                    style: GoogleFonts.poppins(color: Colors.white.withOpacity(0.5)),
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
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        key: _scaffoldKey,
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
          ),
          // Top dark gradient overlay
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              height: 200,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.75),
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
              _buildBottomPanel(),
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
        _iconBtn(Icons.menu_rounded, () => _scaffoldKey.currentState?.openDrawer()),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: _surface.withOpacity(0.95),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withOpacity(0.07), width: 1),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.45), blurRadius: 18, offset: const Offset(0, 4))],
            ),
            child: Row(children: [
              // Brand pill with socket indicator
              Stack(clipBehavior: Clip.none, children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_primary.withOpacity(0.18), _primary.withOpacity(0.06)],
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _primary.withOpacity(0.35), width: 1),
                  ),
                  child: Text(
                    'JAGO Pilot',
                    style: GoogleFonts.poppins(
                      color: _primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
                Positioned(
                  top: -3, right: -3,
                  child: Container(
                    width: 9, height: 9,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _socketConnected ? const Color(0xFF34D399) : const Color(0xFFF59E0B),
                      border: Border.all(color: _surface, width: 1.5),
                      boxShadow: [BoxShadow(
                        color: (_socketConnected ? const Color(0xFF34D399) : const Color(0xFFF59E0B)).withOpacity(0.55),
                        blurRadius: 5,
                      )],
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
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
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
                            color: const Color(0xFF34D399),
                            boxShadow: [BoxShadow(
                              color: const Color(0xFF34D399).withOpacity(0.4 + _pulseCtrl.value * 0.4),
                              blurRadius: 3 + _pulseCtrl.value * 4,
                            )],
                          ),
                        ),
                      ),
                      Text(
                        'Online — trips enabled',
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF34D399).withOpacity(0.85),
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
                        decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFEF4444)),
                      ),
                      Text(
                        'Offline — tap to go online',
                        style: GoogleFonts.poppins(
                          color: Colors.white.withOpacity(0.4),
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
                color: _surface.withOpacity(0.95),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withOpacity(0.07)),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.35), blurRadius: 10, offset: const Offset(0, 3))],
              ),
              child: const Icon(Icons.notifications_rounded, color: Colors.white, size: 22),
            ),
            if (_unreadNotifCount > 0)
              Positioned(
                top: 5, right: 5,
                child: Container(
                  width: 17, height: 17,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFFEF4444), Color(0xFFDC2626)]),
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: const Color(0xFFEF4444).withOpacity(0.4), blurRadius: 4)],
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
          color: _surface.withOpacity(0.95),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.35), blurRadius: 10, offset: const Offset(0, 3))],
        ),
        child: Icon(icon, color: Colors.white.withOpacity(0.85), size: 20),
      ),
    );
  }

  Widget _buildBottomPanel() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF1E293B), width: 1),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 24, offset: const Offset(0, -4))],
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Drag handle
        Container(
          width: 40, height: 4,
          margin: const EdgeInsets.only(top: 10, bottom: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [_primary.withOpacity(0.4), Colors.white.withOpacity(0.12)]),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        // Hero earnings banner
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_primary.withOpacity(0.18), _primary.withOpacity(0.06), Colors.transparent],
                begin: Alignment.centerLeft, end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _primary.withOpacity(0.2)),
            ),
            child: Row(children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                  "Today's Total",
                  style: GoogleFonts.poppins(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Row(children: [
                  Text(
                    '₹${_earningsToday.toStringAsFixed(0)}',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF34D399).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF34D399).withOpacity(0.4)),
                    ),
                    child: Text(
                      '$_tripsToday trips',
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF34D399),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
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
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '₹${_walletBalance.toStringAsFixed(0)}',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFFFFD700),
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
            // Avatar + greeting + online toggle row
            Row(children: [
              Container(
                width: 50, height: 50,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2F80ED), Color(0xFF86D5F5)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: _primary.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4))],
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
                      color: Colors.white.withOpacity(0.65),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _userName.split(' ').first.isNotEmpty ? _userName.split(' ').first : 'Pilot',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  if (!_isOnline)
                    Text(
                      'Tap Go Online to start earning',
                      style: GoogleFonts.poppins(
                        color: const Color(0xFFFFD700),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ]),
              ),
              // Inline online/offline toggle button
              GestureDetector(
                onTap: _toggling ? null : _toggleOnline,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _isOnline
                        ? [const Color(0xFF065F46), const Color(0xFF10B981)]
                        : [const Color(0xFF1E3A5F), _primary],
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(
                      color: (_isOnline ? _green : _primary).withOpacity(0.35),
                      blurRadius: 10, offset: const Offset(0, 3),
                    )],
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    AnimatedBuilder(
                      animation: _pulseCtrl,
                      builder: (_, __) => Container(
                        width: 8, height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: _isOnline ? [BoxShadow(
                            color: Colors.white.withOpacity(0.5 + _pulseCtrl.value * 0.3),
                            blurRadius: 3 + _pulseCtrl.value * 4,
                          )] : [],
                        ),
                      ),
                    ),
                    const SizedBox(width: 7),
                    Text(
                      _isOnline ? 'ONLINE' : 'OFFLINE',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
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
                  gradient: LinearGradient(
                    colors: [const Color(0xFF065F46).withOpacity(0.6), const Color(0xFF10B981).withOpacity(0.15)],
                    begin: Alignment.centerLeft, end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _green.withOpacity(0.3), width: 1),
                ),
                child: Row(children: [
                  AnimatedBuilder(
                    animation: _pulseCtrl,
                    builder: (_, __) => Container(
                      width: 8, height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF4ADE80),
                        boxShadow: [BoxShadow(
                          color: const Color(0xFF4ADE80).withOpacity(0.4 + _pulseCtrl.value * 0.4),
                          blurRadius: 4 + _pulseCtrl.value * 6,
                        )],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'LIVE — Incoming trips enabled',
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF4ADE80),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '₹${_earningsToday.toStringAsFixed(0)} earned',
                    style: GoogleFonts.poppins(
                      color: Colors.white.withOpacity(0.55),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
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
                  gradient: const LinearGradient(
                    colors: [Color(0xFF065F46), Color(0xFF047857)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF34D399).withValues(alpha: 0.4)),
                ),
                child: Row(children: [
                  const Text('🎉', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 10),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Free Period Active', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
                      Text('No subscription & no commission for $_freeDaysRemaining more day${_freeDaysRemaining == 1 ? '' : 's'}',
                        style: const TextStyle(color: Color(0xFF6EE7B7), fontSize: 11)),
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
            if (_isOnline && (
              _vehicleCategory.toLowerCase().contains('parcel') ||
              _vehicleCategory.toLowerCase().contains('cargo') ||
              _vehicleCategory.toLowerCase().contains('bike')
            )) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [const Color(0xFF7C2D12).withOpacity(0.5), const Color(0xFFF59E0B).withOpacity(0.15)],
                    begin: Alignment.centerLeft, end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.35), width: 1),
                ),
                child: Row(children: [
                  const Text('📦', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Parcel deliveries active — stay ready!',
                      style: GoogleFonts.poppins(
                        color: const Color(0xFFF59E0B),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'EARN MORE',
                      style: GoogleFonts.poppins(
                        color: const Color(0xFFF59E0B),
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
        gradient: LinearGradient(
          colors: [_primary.withOpacity(0.12), _primary.withOpacity(0.04)],
          begin: Alignment.centerLeft, end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: _primary, width: 3)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2F80ED), Color(0xFF86D5F5)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: _primary.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 3))],
            ),
            child: Icon(vIcon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                _vehicleCategory.isNotEmpty ? _vehicleCategory : 'My Vehicle',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
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
                    color: Colors.white.withOpacity(0.45),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ]),
          ),
          if (_zone.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  const Color(0xFF10B981).withOpacity(0.15),
                  const Color(0xFF059669).withOpacity(0.1),
                ]),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.location_on_rounded, color: Color(0xFF10B981), size: 10),
                const SizedBox(width: 3),
                Text(
                  _zone,
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF10B981),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
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
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (isOn) ...[
            AnimatedBuilder(
              animation: _pulseCtrl,
              builder: (_, __) => Container(
                width: 140 + (_pulseCtrl.value * 16),
                height: 56 + (_pulseCtrl.value * 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28 + _pulseCtrl.value * 4),
                  border: Border.all(
                    color: const Color(0xFF10B981).withOpacity(0.5 - _pulseCtrl.value * 0.5),
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ],
          AnimatedContainer(
            duration: const Duration(milliseconds: 450),
            curve: Curves.easeInOutCubic,
            width: 140,
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isOn
                  ? [const Color(0xFF34D399), const Color(0xFF10B981)]
                  : [const Color(0xFF1E3A5F), _primary],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [BoxShadow(
                color: (isOn ? const Color(0xFF10B981) : _primary).withOpacity(0.4),
                blurRadius: 12, offset: const Offset(0, 4),
              )],
            ),
            child: Center(
              child: _toggling
                ? const SizedBox(
                    width: 24, height: 24,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                  )
                : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(
                      isOn ? Icons.power_settings_new_rounded : Icons.play_circle_fill_rounded,
                      color: Colors.white, size: 22,
                    ),
                    const SizedBox(width: 7),
                    Text(
                      isOn ? 'ONLINE' : 'GO ONLINE',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                      ),
                    ),
                    if (!isOn) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 16),
                    ],
                  ]),
            ),
          ),
        ],
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
              gradient: const LinearGradient(
                colors: [Color(0xFF2F80ED), Color(0xFF86D5F5)],
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            "Today's Performance",
            style: GoogleFonts.poppins(
              color: Colors.white.withOpacity(0.8),
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: _primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _primary.withOpacity(0.25)),
            ),
            child: Text(
              _ordinal(DateTime.now().day),
              style: GoogleFonts.poppins(
                color: _primary,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ]),
      ),
      Row(children: [
        Expanded(child: _statCard(
          icon: Icons.currency_rupee_rounded,
          iconColor: _primary,
          label: 'Earned',
          value: '₹${_earningsToday.toStringAsFixed(0)}',
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EarningsScreen())),
        )),
        const SizedBox(width: 8),
        Expanded(child: _statCard(
          icon: Icons.directions_car_rounded,
          iconColor: const Color(0xFF34D399),
          label: 'Trips',
          value: '$_tripsToday',
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TripsHistoryScreen())),
        )),
        const SizedBox(width: 8),
        Expanded(child: _statCard(
          icon: Icons.account_balance_wallet_rounded,
          iconColor: const Color(0xFFFFD700),
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
          gradient: LinearGradient(
            colors: [_surface, const Color(0xFF1A2744)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: iconColor.withOpacity(0.15)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.22), blurRadius: 10, offset: const Offset(0, 3))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 3, width: 36,
              margin: const EdgeInsets.only(bottom: 9),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [iconColor, iconColor.withOpacity(0.3)]),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [iconColor.withOpacity(0.22), iconColor.withOpacity(0.08)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: iconColor.withOpacity(0.25), blurRadius: 6, offset: const Offset(0, 2))],
              ),
              child: Icon(icon, size: 17, color: iconColor),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: GoogleFonts.poppins(
                color: Colors.white.withOpacity(0.5),
                fontSize: 10,
                fontWeight: FontWeight.w700,
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
        gradient: LinearGradient(
          colors: [_primary.withOpacity(0.14), const Color(0xFF0F172A)],
          begin: Alignment.centerLeft, end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _primary.withOpacity(0.22)),
      ),
      child: Row(children: [
        Container(
          width: 38, height: 38,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [_primary.withOpacity(0.2), _primary.withOpacity(0.08)]),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.lightbulb_outline_rounded, color: _primary, size: 19),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            tip,
            style: GoogleFonts.poppins(
              color: Colors.white.withOpacity(0.78),
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
      Expanded(child: _actionChip(Icons.coffee_rounded, 'Break', const Color(0xFFF59E0B), () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const BreakModeScreen()));
      })),
      const SizedBox(width: 10),
      Expanded(child: _actionChip(Icons.account_balance_wallet_rounded, 'Wallet', const Color(0xFF10B981), () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const WalletScreen()));
      })),
      const SizedBox(width: 10),
      Expanded(child: _actionChip(Icons.history_rounded, 'Trips', _primary, () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const TripsHistoryScreen()));
      })),
    ]);
  }

  Widget _actionChip(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.18), color.withOpacity(0.08)],
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.22), width: 1),
          boxShadow: [BoxShadow(color: color.withOpacity(0.12), blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: Column(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 19),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: GoogleFonts.poppins(color: color, fontSize: 11, fontWeight: FontWeight.w800),
          ),
        ]),
      ),
    );
  }

  Widget _buildDriverBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: _bg,
        border: Border(top: BorderSide(color: const Color(0xFF1E293B), width: 1)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20, offset: const Offset(0, -4))],
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
          duration: const Duration(milliseconds: 200),
          width: 40, height: 32,
          decoration: BoxDecoration(
            color: active ? _primary.withOpacity(0.18) : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(icon, size: 20, color: active ? _primary : Colors.white38),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 10,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            color: active ? _primary : Colors.white38,
          ),
        ),
      ]),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Container(
        color: _surface,
        child: SafeArea(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                  colors: [_primary.withOpacity(0.28), _primary.withOpacity(0.1)],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _primary.withOpacity(0.25), width: 1),
              ),
              child: Row(children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: _primary,
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
                      style: GoogleFonts.poppins(color: Colors.white.withOpacity(0.5), fontSize: 12),
                    ),
                    const SizedBox(height: 6),
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _primary.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.verified_rounded, color: Colors.white, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            'JAGO PILOT',
                            style: GoogleFonts.poppins(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800),
                          ),
                        ]),
                      ),
                    ]),
                  ]),
                ),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Divider(color: Colors.white.withOpacity(0.08), height: 1),
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
                    color: Colors.red.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.withOpacity(0.2), width: 1),
                  ),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.logout_rounded, color: Color(0xFFF87171), size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Logout',
                      style: GoogleFonts.poppins(
                        color: const Color(0xFFF87171),
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
                  style: GoogleFonts.poppins(color: Colors.white.withOpacity(0.2), fontSize: 10),
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
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: _primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: _primary, size: 18),
      ),
      title: Text(
        label,
        style: GoogleFonts.poppins(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
      ),
      trailing: badge != null
        ? Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              badge,
              style: GoogleFonts.poppins(
                color: const Color(0xFF10B981),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          )
        : Icon(Icons.chevron_right, color: Colors.white.withOpacity(0.2), size: 18),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
    );
  }
}
