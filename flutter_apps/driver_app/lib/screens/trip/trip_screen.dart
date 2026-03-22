import 'dart:async';
import 'dart:convert';
import 'dart:math' show sin, cos, asin, pi, sqrt, pow;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/api_config.dart';
import '../../config/jago_theme.dart';
import '../../services/auth_service.dart';
import '../../services/socket_service.dart';
import '../../services/call_service.dart';
import '../call/call_screen.dart';
import '../chat/trip_chat_sheet.dart';
import '../home/home_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Haversine distance in metres
double _haversineM(double lat1, double lng1, double lat2, double lng2) {
  const r = 6371000.0;
  final dLat = (lat2 - lat1) * pi / 180;
  final dLng = (lng2 - lng1) * pi / 180;
  final a = pow(sin(dLat / 2), 2) +
      cos(lat1 * pi / 180) * cos(lat2 * pi / 180) * pow(sin(dLng / 2), 2);
  return r * 2 * 2 * (asin(sqrt(a)) / 2); // same as 2*R*asin(sqrt(a))
}

// Quick polyline decoder (no extra package needed)
List<LatLng> _decodePolyline(String encoded) {
  final List<LatLng> pts = [];
  int index = 0;
  int lat = 0, lng = 0;
  while (index < encoded.length) {
    int b, shift = 0, result = 0;
    do {
      b = encoded.codeUnitAt(index++) - 63;
      result |= (b & 0x1f) << shift;
      shift += 5;
    } while (b >= 0x20);
    final dLat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
    lat += dLat;
    shift = 0; result = 0;
    do {
      b = encoded.codeUnitAt(index++) - 63;
      result |= (b & 0x1f) << shift;
      shift += 5;
    } while (b >= 0x20);
    final dLng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
    lng += dLng;
    pts.add(LatLng(lat / 1e5, lng / 1e5));
  }
  return pts;
}

// ─────────────────────────────────────────────────────────────────────────────

class TripScreen extends StatefulWidget {
  final Map<String, dynamic>? trip;
  const TripScreen({super.key, this.trip});
  @override
  State<TripScreen> createState() => _TripScreenState();
}

class _TripScreenState extends State<TripScreen> with TickerProviderStateMixin {
  final SocketService _socket = SocketService();
  GoogleMapController? _mapController;
  LatLng _center = const LatLng(17.3850, 78.4867);
  String _status = 'accepted';
  Map<String, dynamic>? _trip;
  bool _loading = false;
  bool _nearPickup = false;
  final _otpCtrl = TextEditingController();
  Timer? _locationTimer;
  Timer? _tripTimer;
  Timer? _statePollTimer; // 5s poll — server is source of truth
  List<String> _cancelReasons = [];
  StreamSubscription? _cancelSub;
  StreamSubscription? _incomingCallSub;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};

  // Live stats
  double _distanceToTargetM = 0;
  int _etaSec = 0;
  int _tripElapsedSec = 0;
  DateTime? _tripStartTime;

  // Animation for status pill
  late AnimationController _pulseCtrl;

  String _shortLocation(String v) {
    final s = v.trim();
    if (s.isEmpty) return s;
    return s.split(',').first.trim();
  }

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _socket.connect(ApiConfig.socketUrl);
    _trip = widget.trip;
    if (_trip != null) {
      _status = _trip!['currentStatus'] ?? _trip!['status'] ?? 'accepted';
      // Register active trip so socket can rejoin room on reconnect
      final tripId = _trip!['tripId'] ?? _trip!['id'];
      if (tripId != null) _socket.setActiveTrip(tripId.toString());
      final lat = double.tryParse(_trip!['pickupLat']?.toString() ?? '');
      final lng = double.tryParse(_trip!['pickupLng']?.toString() ?? '');
      if (lat != null && lng != null && lat != 0) _center = LatLng(lat, lng);
    }
    _startLocationUpdates();
    _startStatePoll();
    _loadCancelReasons();
    _listenForCancel();
    CallService().init();
    _listenForIncomingCalls();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initMapMarkers();
      _fetchRouteForCurrentStatus();
      if (_status == 'accepted' || _status == 'driver_assigned') _openNavigation();
      if (_status == 'in_progress' || _status == 'on_the_way') _startTripTimer();
      _validateActiveTrip();
    });
    print('[TRIP] Screen init — tripId=${_trip?['tripId'] ?? _trip?['id']} status=$_status');
  }

  // ── Validate trip still active on screen load ─────────────────────────────

  Future<void> _validateActiveTrip() async {
    final tripId = _trip?['tripId'] ?? _trip?['id'];
    if (tripId == null) return;
    try {
      final headers = await AuthService.getHeaders();
      final res = await http.get(Uri.parse(ApiConfig.driverActiveTrip), headers: headers);
      if (!mounted) return;
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final serverTrip = data['trip'];
        if (serverTrip == null) {
          // No active trip on server — this screen is stale
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Trip no longer active. Returning home.'), backgroundColor: Colors.orange),
          );
          Navigator.pushAndRemoveUntil(
            context, MaterialPageRoute(builder: (_) => const HomeScreen()), (_) => false);
        }
      }
    } catch (_) {
      // Network error — keep screen, socket cancel handler will catch real cancels
    }
  }

  // ── State polling — server is source of truth ────────────────────────────

  void _startStatePoll() {
    _statePollTimer?.cancel();
    _statePollTimer = Timer.periodic(const Duration(seconds: 5), (_) => _syncTripState());
  }

  void _stopStatePoll() {
    _statePollTimer?.cancel();
    _statePollTimer = null;
  }

  Future<void> _syncTripState() async {
    if (!mounted) return;
    final tripId = _trip?['tripId'] ?? _trip?['id'];
    if (tripId == null) return;
    try {
      final headers = await AuthService.getHeaders();
      final res = await http.get(Uri.parse(ApiConfig.driverActiveTrip), headers: headers)
          .timeout(const Duration(seconds: 4));
      if (!mounted) return;
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final serverTrip = data['trip'] as Map<String, dynamic>?;
        if (serverTrip == null) {
          // Trip ended on server — pop to home
          _stopStatePoll();
          if (mounted) {
            Navigator.pushAndRemoveUntil(context,
              MaterialPageRoute(builder: (_) => const HomeScreen()), (_) => false);
          }
          return;
        }
        final serverStatus = serverTrip['currentStatus']?.toString() ?? serverTrip['current_status']?.toString() ?? '';
        if (serverStatus == 'completed' || serverStatus == 'cancelled') {
          _stopStatePoll();
          if (mounted) {
            Navigator.pushAndRemoveUntil(context,
              MaterialPageRoute(builder: (_) => const HomeScreen()), (_) => false);
          }
          return;
        }
        // Sync status if server differs from local (handles race conditions)
        if (serverStatus.isNotEmpty && serverStatus != _status) {
          setState(() {
            _status = serverStatus;
            _trip = serverTrip;
          });
        }
      }
    } catch (_) {} // network error — keep polling
  }

  // ── Timers ────────────────────────────────────────────────────────────────

  void _startTripTimer() {
    _tripStartTime ??= DateTime.now();
    _tripTimer?.cancel();
    _tripTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _tripElapsedSec = DateTime.now().difference(_tripStartTime!).inSeconds;
      });
    });
  }

  void _stopTripTimer() {
    _tripTimer?.cancel();
    _tripTimer = null;
  }

  String _formatElapsed(int secs) {
    final m = (secs ~/ 60).toString().padLeft(2, '0');
    final s = (secs % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String _formatEta(int secs) {
    if (secs <= 0) return '--';
    if (secs < 60) return '< 1 min';
    final mins = (secs / 60).ceil();
    if (mins < 60) return '$mins min';
    return '${(mins / 60).floor()}h ${mins % 60}m';
  }

  String _formatDist(double m) {
    if (m <= 0) return '--';
    if (m < 1000) return '${m.round()} m';
    return '${(m / 1000).toStringAsFixed(1)} km';
  }

  // ── Socket listeners ──────────────────────────────────────────────────────

  void _listenForCancel() {
    _cancelSub = _socket.onTripCancelled.listen((data) {
      if (!mounted) return;
      _locationTimer?.cancel();
      _stopTripTimer();
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          backgroundColor: JT.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Trip Cancelled',
            style: GoogleFonts.poppins(color: JT.textPrimary, fontWeight: FontWeight.w800)),
          content: Text('Customer cancelled the trip.',
            style: GoogleFonts.poppins(color: JT.textSecondary, fontSize: 14)),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: JT.primary, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushAndRemoveUntil(context,
                  MaterialPageRoute(builder: (_) => const HomeScreen()), (_) => false);
              },
              child: const Text('OK', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );
    });
  }

  void _listenForIncomingCalls() {
    _incomingCallSub = _socket.onCallIncoming.listen((data) {
      if (!mounted) return;
      final callerName = data['callerName']?.toString() ?? 'Customer';
      final callerId = data['callerId']?.toString() ?? '';
      final tripId = data['tripId']?.toString() ?? (_trip?['id']?.toString() ?? '');
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => CallScreen(
          contactName: callerName,
          tripId: tripId,
          targetUserId: callerId,
          isIncoming: true,
          callerIdForIncoming: callerId,
        ),
      ));
    });
  }

  @override
  void dispose() {
    _otpCtrl.dispose();
    _locationTimer?.cancel();
    _stopTripTimer();
    _stopStatePoll();
    _cancelSub?.cancel();
    _incomingCallSub?.cancel();
    _pulseCtrl.dispose();
    super.dispose();
  }

  // ── Map & Route ───────────────────────────────────────────────────────────

  void _initMapMarkers() {
    if (!mounted || _trip == null) return;
    final pLat = double.tryParse(_trip!['pickupLat']?.toString() ?? _trip!['pickup_lat']?.toString() ?? '');
    final pLng = double.tryParse(_trip!['pickupLng']?.toString() ?? _trip!['pickup_lng']?.toString() ?? '');
    final dLat = double.tryParse(_trip!['destinationLat']?.toString() ?? _trip!['destination_lat']?.toString() ?? '');
    final dLng = double.tryParse(_trip!['destinationLng']?.toString() ?? _trip!['destination_lng']?.toString() ?? '');
    setState(() {
      _markers.clear();
      if (pLat != null && pLat != 0 && pLng != null) {
        _markers.add(Marker(
          markerId: const MarkerId('pickup'),
          position: LatLng(pLat, pLng),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: InfoWindow(
            title: 'Pickup',
            snippet: _shortLocation((_trip!['pickupShortName'] ?? _trip!['pickupAddress'] ?? '').toString()),
          ),
        ));
      }
      if (dLat != null && dLat != 0 && dLng != null) {
        _markers.add(Marker(
          markerId: const MarkerId('destination'),
          position: LatLng(dLat, dLng),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(
            title: 'Drop',
            snippet: _shortLocation((_trip!['destinationShortName'] ?? _trip!['destinationAddress'] ?? '').toString()),
          ),
        ));
      }
    });
  }

  void _updateSelfMarker(double lat, double lng) {
    if (!mounted) return;
    setState(() {
      _markers.removeWhere((m) => m.markerId.value == 'self');
      _markers.add(Marker(
        markerId: const MarkerId('self'),
        position: LatLng(lat, lng),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: const InfoWindow(title: 'You'),
        zIndex: 2,
      ));
    });
  }

  Future<void> _fetchRouteForCurrentStatus() async {
    final t = _trip;
    if (t == null) return;
    final myLat = _center.latitude;
    final myLng = _center.longitude;
    final toPickup = _status == 'accepted' || _status == 'driver_assigned';

    double destLat, destLng;
    if (toPickup) {
      destLat = double.tryParse(t['pickupLat']?.toString() ?? t['pickup_lat']?.toString() ?? '') ?? 0;
      destLng = double.tryParse(t['pickupLng']?.toString() ?? t['pickup_lng']?.toString() ?? '') ?? 0;
    } else {
      destLat = double.tryParse(t['destinationLat']?.toString() ?? t['destination_lat']?.toString() ?? '') ?? 0;
      destLng = double.tryParse(t['destinationLng']?.toString() ?? t['destination_lng']?.toString() ?? '') ?? 0;
    }
    if (destLat == 0 || destLng == 0) return;
    await _fetchRoute(myLat, myLng, destLat, destLng);
  }

  Future<void> _fetchRoute(double fromLat, double fromLng, double toLat, double toLng) async {
    const apiKey = 'AIzaSyAiMVYA_ppxeT344tkcoSsjeGGMaPU26eI';
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/directions/json'
        '?origin=$fromLat,$fromLng'
        '&destination=$toLat,$toLng'
        '&mode=driving'
        '&key=$apiKey',
      );
      final res = await http.get(url).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final routes = data['routes'] as List?;
        if (routes != null && routes.isNotEmpty) {
          final overviewPolyline = routes[0]['overview_polyline']?['points'] as String?;
          final legs = routes[0]['legs'] as List?;
          if (overviewPolyline != null && mounted) {
            final pts = _decodePolyline(overviewPolyline);
            int distM = 0, durSec = 0;
            if (legs != null && legs.isNotEmpty) {
              distM = (legs[0]['distance']?['value'] as int?) ?? 0;
              durSec = (legs[0]['duration']?['value'] as int?) ?? 0;
            }
            setState(() {
              _polylines.clear();
              _polylines.add(Polyline(
                polylineId: const PolylineId('route'),
                points: pts,
                color: JT.primary,
                width: 5,
                patterns: [],
              ));
              _distanceToTargetM = distM.toDouble();
              _etaSec = durSec;
            });
            print('[TRIP] Route fetched — dist=${(distM/1000).toStringAsFixed(1)}km eta=${(durSec/60).ceil()}min');
          }
        }
      }
    } catch (_) {}
  }

  // ── Location updates ──────────────────────────────────────────────────────

  void _startLocationUpdates() {
    _locationTimer = Timer.periodic(const Duration(seconds: 3), (_) => _updateLocation());
  }

  Future<void> _updateLocation() async {
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      final lat = pos.latitude;
      final lng = pos.longitude;

      if (mounted) {
        setState(() => _center = LatLng(lat, lng));
        _mapController?.animateCamera(CameraUpdate.newLatLng(_center));
        _updateSelfMarker(lat, lng);
      }

      _socket.sendLocation(lat: lat, lng: lng, speed: pos.speed);
      final locHeaders = await AuthService.getHeaders();
      http.post(Uri.parse(ApiConfig.driverLocation),
        headers: {...locHeaders, 'Content-Type': 'application/json'},
        body: jsonEncode({'lat': lat, 'lng': lng, 'isOnline': true})).catchError((_) => http.Response('', 500));

      // Live distance to target
      if (_trip != null) {
        final toPickup = _status == 'accepted' || _status == 'driver_assigned';
        final tLat = toPickup
          ? double.tryParse(_trip!['pickupLat']?.toString() ?? '') ?? 0.0
          : double.tryParse(_trip!['destinationLat']?.toString() ?? '') ?? 0.0;
        final tLng = toPickup
          ? double.tryParse(_trip!['pickupLng']?.toString() ?? '') ?? 0.0
          : double.tryParse(_trip!['destinationLng']?.toString() ?? '') ?? 0.0;
        if (tLat != 0 && tLng != 0) {
          final dm = Geolocator.distanceBetween(lat, lng, tLat, tLng);
          final etaS = dm > 0 ? (dm / 8.33).round() : 0; // ~30 km/h avg
          if (mounted) setState(() { _distanceToTargetM = dm; _etaSec = etaS; });

          // 100m arrival detection
          if (toPickup) {
            final near = dm <= 100;
            if (mounted && near != _nearPickup) {
              setState(() => _nearPickup = near);
              if (near) _showSnack('You are near the pickup location!');
            }
          }
        }
      }
    } catch (_) {}
  }

  // ── Cancel reasons ────────────────────────────────────────────────────────

  Future<void> _loadCancelReasons() async {
    try {
      final res = await http.get(Uri.parse(ApiConfig.configs));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final reasons = (data['cancellationReasons'] as List<dynamic>? ?? [])
          .where((r) => r['userType'] == 'driver' || r['user_type'] == 'driver')
          .map((r) => r['reason']?.toString() ?? '')
          .where((r) => r.isNotEmpty)
          .toList();
        if (mounted) setState(() => _cancelReasons = reasons);
      }
    } catch (_) {}
  }

  // ── Trip actions ──────────────────────────────────────────────────────────

  Future<void> _nextStep() async {
    if (_status == 'arrived') { _showOtpBottomSheet(); return; }
    setState(() => _loading = true);
    final h = await AuthService.getHeaders();
    final tripId = _trip?['id'] ?? _trip?['tripId'] ?? '';

    try {
      if (_status == 'accepted' || _status == 'driver_assigned') {
        final res = await http.post(Uri.parse(ApiConfig.driverArrived),
          headers: {...h, 'Content-Type': 'application/json'},
          body: jsonEncode({'tripId': tripId}));
        if (!mounted) return;
        if (res.statusCode == 200) {
          _socket.updateTripStatus(tripId, 'arrived');
          setState(() { _status = 'arrived'; _loading = false; });
          print('[TRIP] ✅ Arrived at pickup — tripId=$tripId');
          _showSnack('Arrived! Ask customer for OTP ');
          // Clear route polyline while waiting for OTP
          setState(() => _polylines.clear());
        } else {
          final err = jsonDecode(res.body);
          _showSnack(err['message'] ?? 'Error', error: true);
          setState(() => _loading = false);
        }
      } else if (_status == 'in_progress' || _status == 'on_the_way') {
        await _completeTrip(h);
        return;
      }
    } catch (_) {
      if (!mounted) return;
      _showSnack('Network error. Try again.', error: true);
      setState(() => _loading = false);
    }
  }

  Future<void> _completeTrip(Map<String, String> authHeaders) async {
    final tripId = _trip?['id'] ?? _trip?['tripId'] ?? '';
    final estFare = _trip?['estimatedFare'] ?? _trip?['estimated_fare'] ?? 0.0;
    final estDist = _trip?['estimatedDistance'] ?? _trip?['estimated_distance'] ?? 0.0;
    try {
      final res = await http.post(Uri.parse(ApiConfig.driverCompleteTrip),
        headers: {...authHeaders, 'Content-Type': 'application/json'},
        body: jsonEncode({'tripId': tripId, 'actualFare': estFare, 'actualDistance': estDist}));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final pricing = data['pricing'] as Map<String, dynamic>? ?? {};
        final rideFare = pricing['rideFare'] ?? data['trip']?['actualFare'] ?? data['trip']?['actual_fare'] ?? estFare;
        final driverEarnings = pricing['driverWalletCredit'] ?? rideFare;
        final commission = pricing['platformDeduction'] ?? 0;
        _socket.updateTripStatus(tripId, 'completed');
        _socket.setActiveTrip(null); // clear trip room tracking
        _locationTimer?.cancel();
        _stopTripTimer();
        print('[TRIP] ✅ Ride completed — tripId=$tripId fare=$rideFare earnings=$driverEarnings');
        if (!mounted) return;
        _showCompletionSheet(
          rideFare.toString(),
          driverEarnings: driverEarnings.toString(),
          commission: commission.toString(),
        );
      } else {
        String errMsg = 'Error completing trip';
        try { errMsg = (jsonDecode(res.body) as Map)['message'] ?? errMsg; } catch (_) {}
        if (!mounted) return;
        _showSnack(errMsg, error: true);
        setState(() => _loading = false);
      }
    } catch (e) {
      print('[TRIP] ❌ complete-trip network error: $e');
      if (!mounted) return;
      _showSnack('Network error. Please tap "Complete" again.', error: true);
      setState(() => _loading = false);
    }
  }

  Future<void> _cancelTrip(String reason) async {
    setState(() => _loading = true);
    final cancelHeaders = await AuthService.getHeaders();
    final tripId = _trip?['id'] ?? _trip?['tripId'] ?? '';
    try {
      await http.post(Uri.parse(ApiConfig.driverCancelTrip),
        headers: {...cancelHeaders, 'Content-Type': 'application/json'},
        body: jsonEncode({'tripId': tripId, 'reason': reason}));
    } catch (_) {}
    _socket.updateTripStatus(tripId, 'cancelled');
    _socket.setActiveTrip(null); // clear trip room tracking
    _locationTimer?.cancel();
    _stopTripTimer();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(context,
      MaterialPageRoute(builder: (_) => const HomeScreen()), (_) => false);
  }

  // ── OTP ───────────────────────────────────────────────────────────────────

  void _showOtpBottomSheet() {
    _otpCtrl.clear();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 44, height: 4,
              decoration: BoxDecoration(color: JT.border, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Row(children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: JT.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(16)),
                child: const Icon(Icons.lock_open_rounded, color: JT.primary, size: 28)),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Enter Customer OTP',
                  style: GoogleFonts.poppins(color: JT.textPrimary, fontWeight: FontWeight.w800, fontSize: 18)),
                Text('Ask customer for OTP shown in JAGO Pro app',
                  style: GoogleFonts.poppins(color: JT.textSecondary, fontSize: 12)),
              ])),
            ]),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                color: JT.bgSoft,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: JT.primary.withValues(alpha: 0.3), width: 1.5),
              ),
              child: TextField(
                controller: _otpCtrl,
                keyboardType: TextInputType.number,
                maxLength: 6,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                textAlign: TextAlign.center,
                autofocus: true,
                style: GoogleFonts.poppins(color: JT.textPrimary, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: 12),
                decoration: InputDecoration(
                  counterText: '',
                  hintText: '——————',
                  hintStyle: GoogleFonts.poppins(color: JT.iconInactive, letterSpacing: 8, fontSize: 24),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 18),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: JT.textSecondary,
                  side: BorderSide(color: JT.border),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: Text('Cancel', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)))),
              const SizedBox(width: 12),
              Expanded(flex: 2, child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: JT.primary, foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 16), elevation: 0),
                onPressed: () async {
                  final otp = _otpCtrl.text.trim();
                  if (otp.length < 4) return;
                  Navigator.pop(ctx);
                  await _verifyOtpAndStart(otp);
                },
                child: Text('Verify & Start Trip →',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w800, fontSize: 14)))),
            ]),
          ]),
        ),
      ),
    );
  }

  Future<void> _verifyOtpAndStart(String otp) async {
    setState(() => _loading = true);
    final h = await AuthService.getHeaders();
    final tripId = _trip?['id'] ?? _trip?['tripId'] ?? '';
    try {
      final res = await http.post(Uri.parse(ApiConfig.driverVerifyOtp),
        headers: {...h, 'Content-Type': 'application/json'},
        body: jsonEncode({'tripId': tripId, 'otp': otp}));
      if (res.statusCode == 200) {
        _socket.updateTripStatus(tripId, 'on_the_way', otp: otp);
        print('[TRIP] ✅ OTP verified — trip started — tripId=$tripId');
        if (!mounted) return;
        setState(() { _status = 'in_progress'; _loading = false; });
        _startTripTimer();
        // Navigate map to destination
        final dLat = (_trip?['destinationLat'] as num?)?.toDouble() ?? 0;
        final dLng = (_trip?['destinationLng'] as num?)?.toDouble() ?? 0;
        if (dLat != 0 && dLng != 0) {
          _mapController?.animateCamera(CameraUpdate.newLatLngZoom(LatLng(dLat, dLng), 15));
          await _fetchRoute(_center.latitude, _center.longitude, dLat, dLng);
        }
        _showSnack('Trip started! Navigate to destination');
        _showPickupPhotoPrompt(tripId);
      } else {
        final err = jsonDecode(res.body);
        if (!mounted) return;
        _showSnack(err['message'] ?? 'Wrong OTP', error: true);
        setState(() => _loading = false);
      }
    } catch (_) {
      if (!mounted) return;
      _showSnack('Network error. Try again.', error: true);
      setState(() => _loading = false);
    }
  }

  // ── Pickup photo ──────────────────────────────────────────────────────────

  void _showPickupPhotoPrompt(String tripId) {
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: JT.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4,
            decoration: BoxDecoration(color: JT.border, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: JT.surfaceAlt, borderRadius: BorderRadius.circular(16), border: Border.all(color: JT.border)),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: JT.primary.withValues(alpha: 0.10), shape: BoxShape.circle),
                child: const Icon(Icons.camera_alt_rounded, color: JT.primary, size: 26)),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Pickup Photo', style: GoogleFonts.poppins(color: JT.textPrimary, fontWeight: FontWeight.w800, fontSize: 15)),
                Text('Capture for ride security', style: GoogleFonts.poppins(color: JT.textSecondary, fontSize: 12)),
              ])),
            ]),
          ),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: JT.textSecondary,
                side: BorderSide(color: JT.border),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14)),
              onPressed: () => Navigator.pop(context),
              child: Text('Skip', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)))),
            const SizedBox(width: 12),
            Expanded(flex: 2, child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: JT.primary, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14), elevation: 0),
              icon: const Icon(Icons.camera_alt_rounded, size: 18),
              label: Text('Take Photo', style: GoogleFonts.poppins(fontWeight: FontWeight.w800)),
              onPressed: () { Navigator.pop(context); _captureAndUploadPhoto(tripId); })),
          ]),
        ]),
      ),
    );
  }

  Future<void> _captureAndUploadPhoto(String tripId) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.camera, imageQuality: 70, maxWidth: 1280);
      if (picked == null || !mounted) return;
      _showSnack('Uploading photo…');
      final ph = await AuthService.getHeaders();
      final req = http.MultipartRequest('POST', Uri.parse(ApiConfig.tripPhoto));
      req.headers.addAll(ph);
      req.fields['tripId'] = tripId;
      req.files.add(await http.MultipartFile.fromPath('photo', picked.path));
      final resp = await req.send();
      if (!mounted) return;
      _showSnack(resp.statusCode == 200 ? 'Photo saved ✓' : 'Photo upload failed', error: resp.statusCode != 200);
    } catch (_) {
      if (mounted) _showSnack('Photo upload failed', error: true);
    }
  }

  // ── Completion sheet ──────────────────────────────────────────────────────

  void _showCompletionSheet(String fare, {String driverEarnings = '0', String commission = '0'}) {
    int selectedRating = 0;
    bool ratingSubmitted = false;
    final tripId = _trip?['id'] ?? _trip?['tripId'] ?? '';
    final pm = _trip?['paymentMethod'] ?? _trip?['payment_method'] ?? 'cash';
    final isCash = pm == 'cash';
    final netEarnings = double.tryParse(driverEarnings) ?? 0.0;
    final commissionAmt = double.tryParse(commission) ?? 0.0;
    final fullFare = double.tryParse(fare) ?? 0.0;
    final elapsed = _formatElapsed(_tripElapsedSec);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 44, height: 4,
              decoration: BoxDecoration(color: JT.border, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            // Success icon
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: JT.success.withValues(alpha: 0.10),
                shape: BoxShape.circle,
                border: Border.all(color: JT.success.withValues(alpha: 0.3), width: 2)),
              child: const Icon(Icons.check_rounded, color: JT.success, size: 44)),
            const SizedBox(height: 16),
            Text('Trip Complete!',
              style: GoogleFonts.poppins(color: JT.textPrimary, fontSize: 22, fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text('Great job! Ride completed successfully.',
              style: GoogleFonts.poppins(color: JT.textSecondary, fontSize: 13)),
            const SizedBox(height: 20),
            // Earnings card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [JT.primary, JT.primary.withValues(alpha: 0.75)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(20),
                boxShadow: JT.btnShadow,
              ),
              child: Column(children: [
                Text('YOUR EARNINGS', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
                const SizedBox(height: 6),
                Text('₹${netEarnings.toStringAsFixed(0)}',
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 48, fontWeight: FontWeight.w900, height: 1.1)),
                const SizedBox(height: 12),
                Container(height: 1, color: Colors.white24),
                const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  _completionStat('Fare', '₹${fullFare.toStringAsFixed(0)}'),
                  _completionStat('Commission', '₹${commissionAmt.toStringAsFixed(0)}'),
                  _completionStat('Duration', elapsed),
                ]),
              ]),
            ),
            const SizedBox(height: 14),
            // Payment instruction
            if (isCash)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: JT.success.withValues(alpha: 0.35))),
                child: Row(children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: JT.success.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.payments_rounded, color: JT.success, size: 24)),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Collect ₹${fullFare.toStringAsFixed(0)} Cash',
                      style: GoogleFonts.poppins(color: JT.success, fontWeight: FontWeight.w800, fontSize: 15)),
                    Text('Platform fee ₹${commissionAmt.toStringAsFixed(0)} deducted from your wallet',
                      style: GoogleFonts.poppins(color: JT.textSecondary, fontSize: 11)),
                  ])),
                ]),
              )
            else
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: JT.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: JT.primary.withValues(alpha: 0.2))),
                child: Row(children: [
                  const Icon(Icons.account_balance_wallet_rounded, color: JT.primary, size: 24),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('₹${netEarnings.toStringAsFixed(0)} added to wallet',
                      style: GoogleFonts.poppins(color: JT.primary, fontWeight: FontWeight.w800, fontSize: 15)),
                    Text(pm == 'wallet' ? 'Customer wallet deducted' : 'Customer paid online',
                      style: GoogleFonts.poppins(color: JT.textSecondary, fontSize: 11)),
                  ])),
                ]),
              ),
            const SizedBox(height: 14),
            // Rating
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: JT.bgSoft, borderRadius: BorderRadius.circular(16), border: Border.all(color: JT.border)),
              child: ratingSubmitted
                ? Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.star_rounded, color: Colors.amber, size: 22),
                    const SizedBox(width: 8),
                    Text('Thank you for rating!',
                      style: GoogleFonts.poppins(color: JT.textSecondary, fontWeight: FontWeight.w600)),
                  ])
                : Column(children: [
                    Text('Rate this customer',
                      style: GoogleFonts.poppins(color: JT.textPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 10),
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      for (int i = 1; i <= 5; i++)
                        GestureDetector(
                          onTap: () async {
                            setS(() => selectedRating = i);
                            final rh = await AuthService.getHeaders();
                            try {
                              await http.post(Uri.parse(ApiConfig.driverRateCustomer),
                                headers: {...rh, 'Content-Type': 'application/json'},
                                body: jsonEncode({'tripId': tripId, 'rating': i}));
                            } catch (_) {}
                            setS(() => ratingSubmitted = true);
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Icon(
                              i <= selectedRating ? Icons.star_rounded : Icons.star_border_rounded,
                              color: Colors.amber, size: 40)),
                        ),
                    ]),
                  ]),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity, height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: JT.primary, foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0),
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pushAndRemoveUntil(context,
                    MaterialPageRoute(builder: (_) => const HomeScreen()), (_) => false);
                },
                child: Text('Back to Home →',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w800, fontSize: 16))),
            ),
          ])),
        ),
      ),
    );
  }

  Widget _completionStat(String label, String value) {
    return Column(children: [
      Text(value, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
      Text(label, style: GoogleFonts.poppins(color: Colors.white60, fontSize: 10, fontWeight: FontWeight.w600)),
    ]);
  }

  // ── Cancel dialog ─────────────────────────────────────────────────────────

  void _showCancelDialog() {
    final reasons = _cancelReasons.isNotEmpty ? _cancelReasons : [
      'Customer not at pickup location', 'Customer is not responding',
      'Vehicle breakdown', 'Customer requested to cancel', 'Other reason',
    ];
    showModalBottomSheet(
      context: context,
      backgroundColor: JT.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4,
            decoration: BoxDecoration(color: JT.border, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          Row(children: [
            Container(padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: JT.error.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.cancel_rounded, color: JT.error, size: 20)),
            const SizedBox(width: 12),
            Text('Cancel Reason', style: GoogleFonts.poppins(color: JT.textPrimary, fontSize: 17, fontWeight: FontWeight.w800)),
          ]),
          const SizedBox(height: 12),
          ...reasons.map((r) => ListTile(
            title: Text(r, style: GoogleFonts.poppins(color: JT.textPrimary, fontSize: 13)),
            leading: const Icon(Icons.chevron_right_rounded, color: JT.iconInactive, size: 18),
            contentPadding: EdgeInsets.zero, dense: true,
            onTap: () { Navigator.pop(context); _cancelTrip(r); })),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  // ── Delivery OTP ──────────────────────────────────────────────────────────

  void _showDeliveryOtpDialog() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: JT.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: JT.warning.withValues(alpha: 0.10), shape: BoxShape.circle),
              child: const Icon(Icons.local_shipping_rounded, color: JT.warning, size: 32)),
            const SizedBox(height: 16),
            Text('Delivery OTP', style: GoogleFonts.poppins(color: JT.textPrimary, fontWeight: FontWeight.w800, fontSize: 18)),
            const SizedBox(height: 4),
            Text('Ask receiver for OTP to confirm delivery',
              style: GoogleFonts.poppins(color: JT.textSecondary, fontSize: 13), textAlign: TextAlign.center),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(color: JT.bgSoft, borderRadius: BorderRadius.circular(14),
                border: Border.all(color: JT.warning.withValues(alpha: 0.3))),
              child: TextField(
                controller: ctrl, keyboardType: TextInputType.number, maxLength: 6,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(color: JT.textPrimary, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 10),
                decoration: InputDecoration(counterText: '',
                  hintText: '------', hintStyle: GoogleFonts.poppins(color: JT.iconInactive, letterSpacing: 10, fontSize: 24),
                  border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(vertical: 16)),
              )),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: TextButton(
                onPressed: () => Navigator.pop(ctx),
                style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: Text('Cancel', style: GoogleFonts.poppins(color: JT.textSecondary, fontWeight: FontWeight.w600)))),
              const SizedBox(width: 12),
              Expanded(child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: JT.warning, foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14), elevation: 0),
                onPressed: () async {
                  final otp = ctrl.text.trim();
                  if (otp.isEmpty) return;
                  Navigator.pop(ctx);
                  await _verifyDeliveryOtp(otp);
                },
                child: Text('Verify ✓', style: GoogleFonts.poppins(fontWeight: FontWeight.w800)))),
            ]),
          ]),
        ),
      ),
    ).then((_) => ctrl.dispose());
  }

  Future<void> _verifyDeliveryOtp(String otp) async {
    setState(() => _loading = true);
    final h = await AuthService.getHeaders();
    final tripId = _trip?['id'] ?? _trip?['tripId'] ?? '';
    try {
      final res = await http.post(Uri.parse(ApiConfig.verifyDeliveryOtp),
        headers: {...h, 'Content-Type': 'application/json'},
        body: jsonEncode({'tripId': tripId, 'otp': otp}));
      if (!mounted) return;
      _showSnack(res.statusCode == 200 ? 'Delivery verified! ✓' : (jsonDecode(res.body)['message'] ?? 'Wrong OTP'),
        error: res.statusCode != 200);
    } catch (_) {
      if (!mounted) return;
      _showSnack('Network error', error: true);
    }
    if (mounted) setState(() => _loading = false);
  }

  // ── Call / Navigation / SOS ───────────────────────────────────────────────

  void _startInAppCall(String contactName) {
    final customerId = _trip?['customerId']?.toString() ?? _trip?['customer_id']?.toString();
    final tripId = _trip?['id']?.toString() ?? _trip?['tripId']?.toString() ?? '';
    if (customerId == null || customerId.isEmpty) return;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => CallScreen(contactName: contactName, tripId: tripId, targetUserId: customerId)));
  }

  void _openTripChat() {
    final tripId = _trip?['id']?.toString() ?? _trip?['tripId']?.toString() ?? '';
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (_) => TripChatSheet(tripId: tripId, senderName: 'Driver'));
  }

  Future<void> _openNavigation() async {
    final toPickup = _status == 'accepted' || _status == 'driver_assigned';
    final tLat = toPickup
      ? (double.tryParse(_trip?['pickupLat']?.toString() ?? _trip?['pickup_lat']?.toString() ?? '') ?? 0.0)
      : (double.tryParse(_trip?['destinationLat']?.toString() ?? _trip?['destination_lat']?.toString() ?? '') ?? 0.0);
    final tLng = toPickup
      ? (double.tryParse(_trip?['pickupLng']?.toString() ?? _trip?['pickup_lng']?.toString() ?? '') ?? 0.0)
      : (double.tryParse(_trip?['destinationLng']?.toString() ?? _trip?['destination_lng']?.toString() ?? '') ?? 0.0);
    final label = toPickup
      ? _shortLocation(_trip?['pickupShortName']?.toString() ?? _trip?['pickupAddress']?.toString() ?? 'Pickup')
      : _shortLocation(_trip?['destinationShortName']?.toString() ?? _trip?['destinationAddress']?.toString() ?? 'Destination');

    final Uri uri;
    if (tLat != 0 && tLng != 0) {
      uri = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$tLat,$tLng&travelmode=driving');
    } else {
      uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(label)}');
    }
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      _showSnack('Cannot open navigation', error: true);
    }
  }

  Future<void> _triggerSos() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: JT.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('SOS Alert', style: GoogleFonts.poppins(color: JT.textPrimary, fontWeight: FontWeight.bold)),
        content: Text('Emergency SOS send చేయాలా? Help team contact అవుతారు.',
          style: GoogleFonts.poppins(color: JT.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.poppins(color: JT.textSecondary))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: JT.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('SOS పంపు', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
        ]));
    if (confirm != true) return;
    final h = await AuthService.getHeaders();
    final tripId = _trip?['id'] ?? _trip?['tripId'] ?? '';
    try {
      await http.post(Uri.parse(ApiConfig.sos),
        headers: {...h, 'Content-Type': 'application/json'},
        body: jsonEncode({'tripId': tripId, 'lat': _center.latitude, 'lng': _center.longitude, 'message': 'Driver SOS alert during trip'}));
      if (!mounted) return;
      _showSnack('SOS Alert sent! Help is on the way.');
    } catch (_) {
      if (!mounted) return;
      _showSnack('SOS send failed. Call 100 immediately!', error: true);
    }
  }

  void _showSnack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
      backgroundColor: error ? JT.error : JT.primary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final customerName = _trip?['customerName'] ?? _trip?['customer_name'] ?? 'Customer';
    final customerPhone = _trip?['customerPhone'] ?? _trip?['customer_phone'];
    final pickup = _shortLocation((_trip?['pickupShortName'] ?? _trip?['pickupAddress'] ?? _trip?['pickup_address'] ?? 'Pickup').toString());
    final dest = _shortLocation((_trip?['destinationShortName'] ?? _trip?['destinationAddress'] ?? _trip?['destination_address'] ?? 'Destination').toString());
    final isParcel = (_trip?['type'] ?? _trip?['tripType'] ?? '').toString().toLowerCase().contains('parcel') ||
        (_trip?['notes']?.toString().startsWith('📦') ?? false);
    final isForSomeoneElse = _trip?['isForSomeoneElse'] == true || _trip?['is_for_someone_else'] == true;
    final passengerName = _trip?['passengerName'] ?? _trip?['passenger_name'] ?? '';
    final passengerPhone = _trip?['passengerPhone'] ?? _trip?['passenger_phone'];

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: JT.bg,
        body: Stack(children: [
          // ── Full screen map ────────────────────────────────────────────────
          Positioned.fill(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(target: _center, zoom: 15),
              onMapCreated: (c) {
                _mapController = c;
                c.animateCamera(CameraUpdate.newLatLng(_center));
                _initMapMarkers();
              },
              markers: _markers,
              polylines: _polylines,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              compassEnabled: false,
              padding: const EdgeInsets.only(bottom: 260, top: 100),
            ),
          ),

          // ── Top status bar ─────────────────────────────────────────────────
          Positioned(
            top: 0, left: 0, right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: _buildTopBar(pickup, dest),
              ),
            ),
          ),

          // ── Bottom action sheet ────────────────────────────────────────────
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.10), blurRadius: 24)],
              ),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 44, height: 4,
                  margin: const EdgeInsets.only(top: 10, bottom: 4),
                  decoration: BoxDecoration(color: JT.border, borderRadius: BorderRadius.circular(2))),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    _buildCustomerCard(customerName, customerPhone),
                    if (isForSomeoneElse && passengerName.toString().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _buildPassengerCard(passengerName.toString(), passengerPhone?.toString()),
                    ],
                    if (isParcel && _trip?['notes'] != null) ...[
                      const SizedBox(height: 8),
                      _buildParcelCard(_trip!['notes'].toString()),
                    ],
                    const SizedBox(height: 10),
                    _buildLiveStats(),
                    const SizedBox(height: 8),
                    _buildPaymentBadge(),
                    if ((_status == 'in_progress' || _status == 'on_the_way') && isParcel) ...[
                      const SizedBox(height: 6),
                      _buildDeliveryOtpBtn(),
                    ],
                    _buildActionBtn(),
                    const SizedBox(height: 8),
                    _buildQuickActions(customerPhone?.toString()),
                  ]),
                ),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  // ── Top bar ───────────────────────────────────────────────────────────────

  Widget _buildTopBar(String pickup, String dest) {
    final stepInfo = _getStepInfo();
    final isOnTheWay = _status == 'in_progress' || _status == 'on_the_way';
    final isArrived = _status == 'arrived';
    final Color barColor = isOnTheWay ? JT.success : isArrived ? JT.warning : JT.primary;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.10), blurRadius: 12, offset: const Offset(0, 3))],
        border: Border.all(color: barColor.withValues(alpha: 0.2), width: 1),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: barColor.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(14)),
          child: Icon(stepInfo['icon'] as IconData, color: barColor, size: 24)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(stepInfo['label'] as String,
            style: GoogleFonts.poppins(color: barColor, fontSize: 14, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(
            isOnTheWay ? dest : pickup,
            style: GoogleFonts.poppins(color: JT.textSecondary, fontSize: 11),
            maxLines: 1, overflow: TextOverflow.ellipsis),
        ])),
        // LIVE indicator
        AnimatedBuilder(
          animation: _pulseCtrl,
          builder: (_, __) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: JT.success.withValues(alpha: 0.08 + _pulseCtrl.value * 0.06),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 7, height: 7,
                decoration: const BoxDecoration(color: JT.success, shape: BoxShape.circle)),
              const SizedBox(width: 4),
              Text('LIVE', style: GoogleFonts.poppins(color: JT.success, fontSize: 9, fontWeight: FontWeight.w800)),
            ])),
        ),
      ]),
    );
  }

  // ── Customer card ─────────────────────────────────────────────────────────

  Widget _buildCustomerCard(String name, String? phone) {
    final pm = _trip?['paymentMethod'] ?? _trip?['payment_method'] ?? 'cash';
    final pmLabel = pm == 'wallet' ? 'Wallet' : (pm == 'upi' || pm == 'online' || pm == 'razorpay') ? 'UPI' : 'Cash';
    final pmColor = pm == 'wallet' ? JT.primary : (pm == 'upi' || pm == 'online' || pm == 'razorpay') ? JT.secondary : JT.success;
    final fare = double.tryParse((_trip?['estimatedFare'] ?? _trip?['estimated_fare'] ?? 0).toString()) ?? 0;

    return Container(
      decoration: BoxDecoration(color: JT.bgSoft, borderRadius: BorderRadius.circular(18), border: Border.all(color: JT.border)),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(gradient: JT.grad, borderRadius: BorderRadius.circular(15), boxShadow: JT.btnShadow),
              child: Center(child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'C',
                style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)))),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name, style: GoogleFonts.poppins(color: JT.textPrimary, fontSize: 16, fontWeight: FontWeight.w800),
                maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 3),
              Text(pmLabel, style: GoogleFonts.poppins(color: pmColor, fontSize: 12, fontWeight: FontWeight.w700)),
            ])),
            if (phone != null)
              GestureDetector(
                onTap: () => _startInAppCall(name),
                child: Container(
                  width: 46, height: 46,
                  decoration: BoxDecoration(gradient: JT.grad, borderRadius: BorderRadius.circular(14), boxShadow: JT.btnShadow),
                  child: const Icon(Icons.phone_rounded, color: Colors.white, size: 20))),
          ]),
        ),
        Container(height: 1, color: JT.border),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(children: [
            Expanded(child: _pill('Fare', fare > 0 ? '₹${fare.toInt()}' : '₹--', JT.success)),
            const SizedBox(width: 6),
            Expanded(child: _pill('Distance',
              (double.tryParse((_trip?['estimatedDistance'] ?? 0).toString()) ?? 0) > 0
                ? '${_trip!['estimatedDistance']} km' : '--', JT.primary)),
            const SizedBox(width: 6),
            Expanded(child: _pill('Pay', pmLabel, pmColor)),
          ]),
        ),
      ]),
    );
  }

  Widget _pill(String label, String value, Color color) => Container(
    padding: const EdgeInsets.symmetric(vertical: 8),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: color.withValues(alpha: 0.15))),
    child: Column(children: [
      Text(value, style: GoogleFonts.poppins(color: color, fontSize: 13, fontWeight: FontWeight.w900)),
      const SizedBox(height: 2),
      Text(label, style: GoogleFonts.poppins(color: JT.textSecondary, fontSize: 9, fontWeight: FontWeight.w600)),
    ]));

  // ── Live stats (distance/ETA/timer) ───────────────────────────────────────

  Widget _buildLiveStats() {
    final isOnTheWay = _status == 'in_progress' || _status == 'on_the_way';
    final isNavigating = _status == 'accepted' || _status == 'driver_assigned';

    if (_status == 'arrived') {
      return Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: JT.warning.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: JT.warning.withValues(alpha: 0.3))),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.location_on_rounded, color: JT.warning, size: 18),
          const SizedBox(width: 8),
          Text('At pickup — waiting for customer',
            style: GoogleFonts.poppins(color: JT.warning, fontSize: 13, fontWeight: FontWeight.w700)),
        ]));
    }

    if (!isNavigating && !isOnTheWay) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isOnTheWay ? JT.success.withValues(alpha: 0.06) : JT.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isOnTheWay ? JT.success.withValues(alpha: 0.2) : JT.border)),
      child: Row(children: [
        Icon(isOnTheWay ? Icons.speed_rounded : Icons.navigation_rounded,
          color: isOnTheWay ? JT.success : JT.primary, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Row(children: [
          Text(
            _distanceToTargetM > 0 ? _formatDist(_distanceToTargetM) : '--',
            style: GoogleFonts.poppins(color: isOnTheWay ? JT.success : JT.primary, fontSize: 15, fontWeight: FontWeight.w900)),
          const SizedBox(width: 6),
          Text('away', style: GoogleFonts.poppins(color: JT.textSecondary, fontSize: 12)),
          const SizedBox(width: 12),
          const Icon(Icons.access_time_rounded, size: 13, color: JT.iconInactive),
          const SizedBox(width: 4),
          Text(_etaSec > 0 ? _formatEta(_etaSec) : '--',
            style: GoogleFonts.poppins(color: JT.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
        ])),
        if (isOnTheWay && _tripElapsedSec > 0) Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: JT.success.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
          child: Text(_formatElapsed(_tripElapsedSec),
            style: GoogleFonts.poppins(color: JT.success, fontSize: 12, fontWeight: FontWeight.w800))),
        if (_nearPickup && isNavigating) Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: JT.success.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20),
            border: Border.all(color: JT.success.withValues(alpha: 0.4))),
          child: Text('Near Pickup!',
            style: GoogleFonts.poppins(color: JT.success, fontSize: 11, fontWeight: FontWeight.w800))),
      ]),
    );
  }

  // ── Payment badge ─────────────────────────────────────────────────────────

  Widget _buildPaymentBadge() {
    final pm = _trip?['paymentMethod'] ?? _trip?['payment_method'] ?? 'cash';
    final isCash = pm == 'cash';
    final fare = double.tryParse((_trip?['estimatedFare'] ?? _trip?['estimated_fare'] ?? 0).toString()) ?? 0;

    if (isCash && (_status == 'in_progress' || _status == 'on_the_way')) {
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: JT.grad, borderRadius: BorderRadius.circular(14), boxShadow: JT.btnShadow),
        child: Row(children: [
          Container(width: 42, height: 42,
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(11)),
            child: const Icon(Icons.payments_rounded, color: Colors.white, size: 20)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('COLLECT ₹${fare.toInt()} CASH',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 0.5)),
            const Text('Remind customer to have exact change',
              style: TextStyle(color: Colors.white70, fontSize: 11)),
          ])),
        ]));
    }
    if (isCash) {
      return Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: JT.success.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: JT.success.withValues(alpha: 0.20))),
        child: const Row(children: [
          Icon(Icons.payments_rounded, color: JT.success, size: 14),
          SizedBox(width: 7),
          Text('Cash Payment — Collect at trip end',
            style: TextStyle(color: JT.success, fontSize: 11, fontWeight: FontWeight.w600)),
        ]));
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: JT.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: JT.border)),
      child: Row(children: [
        const Icon(Icons.account_balance_wallet_rounded, color: JT.primary, size: 14),
        const SizedBox(width: 7),
        Text(pm == 'wallet' ? 'Wallet — Auto deducted' : 'Online — Already paid',
          style: GoogleFonts.poppins(color: JT.primary, fontSize: 11, fontWeight: FontWeight.w600)),
      ]));
  }

  // ── Delivery OTP button ───────────────────────────────────────────────────

  Widget _buildDeliveryOtpBtn() => GestureDetector(
    onTap: _showDeliveryOtpDialog,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: JT.warning.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: JT.warning.withValues(alpha: 0.3))),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.lock_open_rounded, color: JT.warning, size: 17),
        const SizedBox(width: 7),
        Text('Verify Delivery OTP',
          style: GoogleFonts.poppins(color: JT.warning, fontSize: 13, fontWeight: FontWeight.w800)),
      ])));

  // ── Main action button ────────────────────────────────────────────────────

  Widget _buildActionBtn() {
    final step = _getStepInfo();
    final isOnTheWay = _status == 'in_progress' || _status == 'on_the_way';
    final showGlow = _nearPickup && (_status == 'accepted' || _status == 'driver_assigned');

    return GestureDetector(
      onTap: _loading ? null : _nextStep,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity, height: 60,
        margin: const EdgeInsets.only(top: 6),
        decoration: BoxDecoration(
          gradient: isOnTheWay
            ? const LinearGradient(
                colors: [JT.success, Color(0xFF15803D)],
                begin: Alignment.centerLeft, end: Alignment.centerRight)
            : JT.grad,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: (isOnTheWay ? JT.success : JT.primary).withValues(alpha: showGlow ? 0.55 : 0.35),
              blurRadius: showGlow ? 28 : 18, offset: const Offset(0, 6)),
          ],
          border: showGlow ? Border.all(color: JT.success, width: 2) : null,
        ),
        child: Center(
          child: _loading
            ? const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                SizedBox(width: 22, height: 22,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)),
                SizedBox(width: 12),
                Text('Please wait...', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
              ])
            : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
                  child: Icon(step['icon'] as IconData, color: Colors.white, size: 20)),
                const SizedBox(width: 12),
                Text(step['action'] as String,
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: -0.2)),
              ]),
        ),
      ),
    );
  }

  // ── Quick action row ──────────────────────────────────────────────────────

  Widget _buildQuickActions(String? phone) {
    return Wrap(alignment: WrapAlignment.center, spacing: 8, runSpacing: 8, children: [
      if (phone != null)
        _quickBtn(Icons.phone_rounded, 'Call', JT.primary, () {
          final n = (_trip?['customerName'] ?? _trip?['customer_name'] ?? 'Customer').toString();
          _startInAppCall(n);
        }),
      _quickBtn(Icons.chat_rounded, 'Chat', JT.primary, _openTripChat),
      _quickBtn(Icons.navigation_rounded, 'Navigate', JT.primary, _openNavigation),
      if (_status == 'accepted' || _status == 'driver_assigned')
        _quickBtn(Icons.cancel_outlined, 'Cancel', JT.warning, _showCancelDialog),
      _quickBtn(Icons.sos_rounded, 'SOS', JT.error, _triggerSos),
    ]);
  }

  Widget _quickBtn(IconData icon, String label, Color color, VoidCallback onTap) =>
    GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.22))),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: color, size: 15),
          const SizedBox(width: 5),
          Text(label, style: GoogleFonts.poppins(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
        ])));

  // ── Parcel card ───────────────────────────────────────────────────────────

  Widget _buildParcelCard(String notes) {
    String receiver = '', category = '', weight = '', instructions = '';
    for (final part in notes.split(' | ')) {
      if (part.startsWith('Category:')) category = part.replaceFirst('Category: ', '');
      if (part.startsWith('Weight:')) weight = part.replaceFirst('Weight: ', '');
      if (part.startsWith('Receiver:')) receiver = part.replaceFirst('Receiver: ', '');
      if (part.startsWith('Instructions:') && !part.contains('None'))
        instructions = part.replaceFirst('Instructions: ', '');
    }
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: JT.warning.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: JT.warning.withValues(alpha: 0.25))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('📦', style: TextStyle(fontSize: 15)),
          const SizedBox(width: 7),
          Text('PARCEL', style: GoogleFonts.poppins(color: JT.warning, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1)),
        ]),
        if (receiver.isNotEmpty) ...[const SizedBox(height: 6),
          Row(children: [const Icon(Icons.person_rounded, color: JT.warning, size: 14), const SizedBox(width: 5),
            Expanded(child: Text(receiver, style: GoogleFonts.poppins(color: JT.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)))]),
        ],
        if (category.isNotEmpty) ...[const SizedBox(height: 3),
          Text('$category  •  $weight', style: GoogleFonts.poppins(color: JT.textSecondary, fontSize: 11)),
        ],
        if (instructions.isNotEmpty) ...[const SizedBox(height: 3),
          Text(instructions, style: GoogleFonts.poppins(color: JT.textSecondary, fontSize: 11)),
        ],
      ]));
  }

  // ── Passenger card ────────────────────────────────────────────────────────

  Widget _buildPassengerCard(String passengerName, String? passengerPhone) =>
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: JT.surfaceAlt, borderRadius: BorderRadius.circular(12), border: Border.all(color: JT.border)),
      child: Row(children: [
        Container(padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: JT.primary.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.person_pin_rounded, color: JT.primary, size: 17)),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('PASSENGER', style: GoogleFonts.poppins(color: JT.primary, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1)),
          Text(passengerName, style: GoogleFonts.poppins(color: JT.textPrimary, fontSize: 13, fontWeight: FontWeight.w700)),
          if (passengerPhone != null && passengerPhone.isNotEmpty)
            Text(passengerPhone, style: GoogleFonts.poppins(color: JT.textSecondary, fontSize: 11)),
        ])),
      ]));

  // ── Step info ─────────────────────────────────────────────────────────────

  Map<String, dynamic> _getStepInfo() {
    switch (_status) {
      case 'driver_assigned':
      case 'accepted':
        return {'label': 'Navigating to Pickup', 'icon': Icons.navigation_rounded, 'action': 'Arrived at Pickup'};
      case 'arrived':
        return {'label': 'Arrived — Enter OTP to Start', 'icon': Icons.lock_open_rounded, 'action': 'Enter Customer OTP'};
      case 'in_progress':
      case 'on_the_way':
        return {'label': 'Trip in Progress', 'icon': Icons.speed_rounded, 'action': 'Complete Trip ✓'};
      default:
        return {'label': 'Trip Active', 'icon': Icons.electric_bike, 'action': 'Next Step'};
    }
  }
}
