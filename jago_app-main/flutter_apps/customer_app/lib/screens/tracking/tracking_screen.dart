import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../../config/api_config.dart';
import '../../config/jago_theme.dart';
import '../../services/auth_service.dart';
import '../../services/socket_service.dart';
import '../../services/alarm_service.dart';
import '../../services/call_service.dart';
import '../call/call_screen.dart';
import '../chat/trip_chat_sheet.dart';
import '../home/home_screen.dart';
import '../booking/booking_screen.dart';
import '../tip/tip_driver_screen.dart';

class TrackingScreen extends StatefulWidget {
  final String tripId;
  const TrackingScreen({super.key, required this.tripId});
  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen>
    with TickerProviderStateMixin {
  final SocketService _socket = SocketService();
  GoogleMapController? _mapController;
  LatLng _center = const LatLng(20.5937, 78.9629);
  LatLng? _driverLatLng;
  String _status = 'searching';
  Map<String, dynamic>? _trip;
  Timer? _pollTimer;
  int _rated = 0;
  double _walletPendingAmount =
      0; // amount customer still owes after wallet deduction
  List<String> _cancelReasons = [];
  late AnimationController _pulseCtrl;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  bool _routeFetched = false;
  final List<StreamSubscription> _subs = [];
  final FlutterTts _tts = FlutterTts();
  String _lastAnnouncedStatus = '';
  StreamSubscription? _incomingCallSub;

  // Booking timeout warning (Feature 1) & Boost Fare (Feature 2)
  Timer? _searchTimeoutTimer;
  bool _boostLoading = false;

  static const Color _blue = Color(0xFF2F7BFF);
  static const Color _green = JT.primaryDark;

  @override
  void initState() {
    super.initState();
    _initTts();
    _pulseCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat(reverse: true);
    _connectSocket();
    _pollStatus();
    _loadCancelReasons();
    CallService().init();
    _listenForIncomingCalls();
    // HTTP polling as fallback (every 3s — socket handles real-time)
    _pollTimer =
        Timer.periodic(const Duration(seconds: 5), (_) => _pollStatus());
    // Start 90-second timeout warning for searching state
    _startSearchTimeoutTimer();
  }

  void _connectSocket() {
    _socket.connect(ApiConfig.socketUrl).then((_) {
      // Join this trip's tracking room
      _socket.trackTrip(widget.tripId);

      // Real-time driver GPS location
      _subs.add(_socket.onDriverLocation.listen((data) {
        if (!mounted) return;
        final lat = double.tryParse(data['lat']?.toString() ?? '');
        final lng = double.tryParse(data['lng']?.toString() ?? '');
        if (lat != null && lng != null) {
          setState(() {
            _driverLatLng = LatLng(lat, lng);
            _updateDriverMarker(_driverLatLng!);
          });
        }
      }));

      // Real-time trip status changes
      _subs.add(_socket.onTripStatus.listen((data) {
        if (!mounted) return;
        final rawStatus = data['status']?.toString() ?? _status;
        // payment_pending = driver completed but payment not yet confirmed — treat as completed for customer
        final newStatus =
            rawStatus == 'payment_pending' ? 'completed' : rawStatus;
        final otp = data['otp']?.toString();
        setState(() {
          _status = newStatus;
          if (otp != null && _trip != null) {
            _trip!['pickupOtp'] = otp;
          }
          // Capture wallet pending amount when trip completes
          if (newStatus == 'completed') {
            _walletPendingAmount = double.tryParse(
                  data['walletPendingAmount']?.toString() ??
                      data['pendingPaymentAmount']?.toString() ??
                      '0',
                ) ??
                0.0;
            // Merge completion data into _trip so completed card shows fare immediately
            if (_trip != null) {
              if (data['fare'] != null) _trip!['actualFare'] = data['fare'];
              if (data['userDiscount'] != null) _trip!['userDiscount'] = data['userDiscount'];
              if (data['userPayable'] != null) _trip!['userPayable'] = data['userPayable'];
              if (data['actualDistance'] != null) _trip!['actualDistance'] = data['actualDistance'];
              if (data['paymentMethod'] != null) _trip!['paymentMethod'] = data['paymentMethod'];
              if (data['gstAmount'] != null) _trip!['gstAmount'] = data['gstAmount'];
            }
          }
        });
        _announceStatus(newStatus);
        if (newStatus == 'arrived') {
          AlarmService().playChime();
          HapticFeedback.heavyImpact();
          _showArrivalBanner();
        }
        if (newStatus == 'in_progress' || newStatus == 'on_the_way') {
          AlarmService().playChime();
          HapticFeedback.mediumImpact();
          // Trip started — re-fetch route from driver to destination
          _routeFetched = false;
          _fetchRoutePolyline();
        }
        if (newStatus == 'completed') AlarmService().playChime();
        if (newStatus == 'completed' || newStatus == 'cancelled') {
          _pollTimer?.cancel();
          _pollStatus(); // fetch final state
        }
      }));

      // Driver assigned (from searching state) — extract driver info from socket event immediately
      _subs.add(_socket.onDriverAssigned.listen((data) {
        if (!mounted) return;
        // Cancel the search timeout warning — driver found
        _searchTimeoutTimer?.cancel();
        // Extract driver details from socket event so UI updates instantly (no wait for HTTP poll)
        final driverData = data['driver'];
        final driverMap = driverData is Map ? Map<String, dynamic>.from(driverData as Map) : null;
        final pickupOtp = data['pickupOtp']?.toString();
        setState(() {
          _status = 'driver_assigned';
          if (driverMap != null) {
            // Seed _trip with driver info so _buildDriverCard renders immediately
            _trip = {
              ...(_trip ?? {}),
              if (pickupOtp != null && pickupOtp.isNotEmpty) 'pickupOtp': pickupOtp,
              'driverName': driverMap['fullName'] ?? driverMap['full_name'] ?? '',
              'driverPhone': driverMap['phone'] ?? '',
              'driverRating': driverMap['rating'],
              'driverPhoto': driverMap['photo'] ?? driverMap['profilePhoto'] ?? '',
              'driverVehicleNumber': driverMap['vehicleNumber'] ?? driverMap['vehicle_number'] ?? '',
              'driverVehicleModel': driverMap['vehicleModel'] ?? driverMap['vehicle_model'] ?? '',
              'vehicleName': driverMap['vehicleCategory'] ?? driverMap['vehicle_category'] ?? (_trip?['vehicleName'] ?? ''),
            };
            // Update driver location on map immediately
            final dLat = double.tryParse(driverMap['lat']?.toString() ?? '');
            final dLng = double.tryParse(driverMap['lng']?.toString() ?? '');
            if (dLat != null && dLng != null && dLat != 0) {
              _driverLatLng = LatLng(dLat, dLng);
              _updateDriverMarker(_driverLatLng!);
            }
          } else if (pickupOtp != null && pickupOtp.isNotEmpty && _trip != null) {
            _trip!['pickupOtp'] = pickupOtp;
          }
        });
        AlarmService().playChime();
        HapticFeedback.heavyImpact();
        _announceStatus('driver_assigned');
        _pollStatus(); // refresh full trip data (OTP, fare, full driver details from DB)
        _showPilotFoundBanner();
      }));

      // Trip cancelled by driver
      _subs.add(_socket.onTripCancelled.listen((data) {
        if (!mounted) return;
        final reason = data['reason']?.toString() ?? '';
        setState(() => _status = 'cancelled');
        _announceStatus('cancelled');
        _pollTimer?.cancel();
        if (reason == 'no_drivers' || reason == 'timeout') {
          _showNoDriversDialog();
        }
      }));

      // Re-searching for driver (after rejection)
      _subs.add(_socket.onTripSearching.listen((data) {
        if (!mounted) return;
        setState(() => _status = 'searching');
        // Restart the 90s timeout warning since we're back to searching
        _startSearchTimeoutTimer();
      }));

      // No drivers available — trip auto-cancelled
      _subs.add(_socket.onNoDrivers.listen((data) {
        if (!mounted) return;
        setState(() => _status = 'cancelled');
        _pollTimer?.cancel();
        _showNoDriversDialog();
      }));
    });
  }

  // No drivers available → set cancelled state (UI handled by _buildCancelledCard)
  void _showNoDriversDialog() {
    if (!mounted) return;
    // Update state to show inline cancelled UI with retry option
    setState(() => _status = 'cancelled');
    // Light snackbar notification
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.search_off_rounded, color: Colors.white, size: 18),
        const SizedBox(width: 10),
        Expanded(
            child: Text('No pilots nearby. Try again!',
                style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w400,
                    fontSize: 13))),
      ]),
      backgroundColor: const Color(0xFFDC2626),
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 4),
    ));
  }

  // Retry booking using the same trip's original params
  void _retryBooking() {
    final t = _trip;
    if (t == null) {
      Navigator.pushAndRemoveUntil(context,
          MaterialPageRoute(builder: (_) => const HomeScreen()), (_) => false);
      return;
    }
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => BookingScreen(
          pickup: t['pickupAddress']?.toString() ??
              t['pickup_address']?.toString() ??
              'Pickup',
          destination: t['destinationAddress']?.toString() ??
              t['destination_address']?.toString() ??
              'Destination',
          pickupLat: double.tryParse(t['pickupLat']?.toString() ?? '') ?? 0.0,
          pickupLng: double.tryParse(t['pickupLng']?.toString() ?? '') ?? 0.0,
          destLat:
              double.tryParse(t['destinationLat']?.toString() ?? '') ?? 0.0,
          destLng:
              double.tryParse(t['destinationLng']?.toString() ?? '') ?? 0.0,
          vehicleCategoryId: t['vehicleCategoryId']?.toString(),
          vehicleCategoryName: t['vehicleName']?.toString(),
          category: (t['tripType']?.toString() == 'parcel' ||
                  t['trip_type']?.toString() == 'parcel')
              ? 'parcel'
              : 'ride',
        ),
      ),
      (_) => false,
    );
  }

  BitmapDescriptor _vehicleMarkerIcon() {
    final vehicle = (_trip?['vehicleName'] ?? _trip?['vehicle_name'] ?? '')
        .toString()
        .toLowerCase();
    if (vehicle.contains('bike') ||
        vehicle.contains('moto') ||
        vehicle.contains('two')) {
      return BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueOrange); // Bike → Orange
    } else if (vehicle.contains('auto') || vehicle.contains('rick')) {
      return BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueGreen); // Auto → Green
    } else if (vehicle.contains('suv') || vehicle.contains('innova')) {
      return BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueViolet); // SUV → Violet
    } else if (vehicle.contains('parcel') ||
        vehicle.contains('truck') ||
        vehicle.contains('tata')) {
      return BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueMagenta); // Parcel → Magenta
    } else if (vehicle.contains('car') ||
        vehicle.contains('sedan') ||
        vehicle.contains('mini')) {
      return BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueAzure); // Car → Azure
    }
    return BitmapDescriptor.defaultMarkerWithHue(
        BitmapDescriptor.hueBlue); // Default → Blue
  }

  void _updateDriverMarker(LatLng pos) {
    _markers.removeWhere((m) => m.markerId.value == 'driver');
    final vehicleName =
        (_trip?['vehicleName'] ?? _trip?['vehicle_name'] ?? 'Pilot').toString();
    _markers.add(Marker(
      markerId: const MarkerId('driver'),
      position: pos,
      icon: _vehicleMarkerIcon(),
      infoWindow: InfoWindow(
          title: vehicleName.isNotEmpty ? vehicleName : 'Your Pilot'),
    ));
    // Keep camera on driver when trip is in progress (driver arriving or started)
    if (_status == 'driver_assigned' ||
        _status == 'accepted' ||
        _status == 'arrived' ||
        _status == 'in_progress' ||
        _status == 'on_the_way') {
      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(pos, 16));
    }
  }

  /// Decode a Google Maps encoded polyline string into LatLng points.
  List<LatLng> _decodePolyline(String encoded) {
    final points = <LatLng>[];
    int index = 0;
    int lat = 0, lng = 0;
    while (index < encoded.length) {
      int shift = 0, result = 0;
      int b;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      lat += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      lng += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);

      points.add(LatLng(lat / 1e5, lng / 1e5));
    }
    return points;
  }

  /// Fetch route polyline from server and draw it on the map.
  /// When trip is in_progress, uses driver's live position as origin.
  Future<void> _fetchRoutePolyline() async {
    if (_routeFetched) return;
    final trip = _trip;
    if (trip == null) return;

    final pLat = double.tryParse(trip['pickupLat']?.toString() ?? trip['pickup_lat']?.toString() ?? '');
    final pLng = double.tryParse(trip['pickupLng']?.toString() ?? trip['pickup_lng']?.toString() ?? '');
    final dLat = double.tryParse(trip['destinationLat']?.toString() ?? trip['destination_lat']?.toString() ?? '');
    final dLng = double.tryParse(trip['destinationLng']?.toString() ?? trip['destination_lng']?.toString() ?? '');

    if (pLat == null || pLng == null || dLat == null || dLng == null) return;
    if (pLat == 0 || dLat == 0) return;

    // When trip is in progress, use driver's live position as route origin
    final bool tripStarted = _status == 'in_progress' || _status == 'on_the_way';
    final originLat = (tripStarted && _driverLatLng != null) ? _driverLatLng!.latitude : pLat;
    final originLng = (tripStarted && _driverLatLng != null) ? _driverLatLng!.longitude : pLng;

    _routeFetched = true; // prevent duplicate fetches

    try {
      final headers = await AuthService.getHeaders();
      final res = await http.post(
        Uri.parse(ApiConfig.routeMultiWaypoint),
        headers: {...headers, 'Content-Type': 'application/json'},
        body: jsonEncode({
          'origin': {'lat': originLat, 'lng': originLng},
          'destination': {'lat': dLat, 'lng': dLng},
        }),
      );
      if (res.statusCode == 200 && mounted) {
        final data = jsonDecode(res.body);
        final encodedPolyline = data['overviewPolyline']?.toString() ?? '';
        if (encodedPolyline.isNotEmpty) {
          final points = _decodePolyline(encodedPolyline);
          if (points.isNotEmpty) {
            setState(() {
              _polylines.clear();
              _polylines.add(Polyline(
                polylineId: const PolylineId('route'),
                points: points,
                color: _blue,
                width: 5,
                patterns: [],
              ));
              // Add pickup marker
              _markers.removeWhere((m) => m.markerId.value == 'pickup');
              _markers.add(Marker(
                markerId: const MarkerId('pickup'),
                position: LatLng(pLat, pLng),
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
                infoWindow: InfoWindow(title: trip['pickupAddress']?.toString() ?? trip['pickup_address']?.toString() ?? 'Pickup'),
              ));
              // Add destination marker
              _markers.removeWhere((m) => m.markerId.value == 'destination');
              _markers.add(Marker(
                markerId: const MarkerId('destination'),
                position: LatLng(dLat, dLng),
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                infoWindow: InfoWindow(title: trip['destinationAddress']?.toString() ?? trip['destination_address']?.toString() ?? 'Destination'),
              ));
            });
            // Fit camera to show the entire route
            _fitMapToRoute(LatLng(pLat, pLng), LatLng(dLat, dLng));
          }
        }
      }
    } catch (_) {
      // Fallback: draw a straight dashed line between pickup and destination
      if (mounted) {
        setState(() {
          _polylines.clear();
          _polylines.add(Polyline(
            polylineId: const PolylineId('route'),
            points: [LatLng(pLat, pLng), LatLng(dLat, dLng)],
            color: _blue.withValues(alpha: 0.5),
            width: 3,
            patterns: [PatternItem.dash(15), PatternItem.gap(10)],
          ));
        });
      }
    }
  }

  void _fitMapToRoute(LatLng pickup, LatLng destination) {
    if (_mapController == null) return;
    final bounds = LatLngBounds(
      southwest: LatLng(
        math.min(pickup.latitude, destination.latitude),
        math.min(pickup.longitude, destination.longitude),
      ),
      northeast: LatLng(
        math.max(pickup.latitude, destination.latitude),
        math.max(pickup.longitude, destination.longitude),
      ),
    );
    _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 80));
  }

  @override
  void dispose() {
    for (final s in _subs) s.cancel();
    _incomingCallSub?.cancel();
    _pollTimer?.cancel();
    _searchTimeoutTimer?.cancel();
    _pulseCtrl.dispose();
    _tts.stop();
    // Don't disconnect socket — it's a shared singleton
    super.dispose();
  }

  void _listenForIncomingCalls() {
    _incomingCallSub = _socket.onCallIncoming.listen((data) {
      if (!mounted) return;
      final callerName = data['callerName']?.toString() ?? 'Driver';
      final callerId = data['callerId']?.toString() ?? '';
      final tripId = data['tripId']?.toString() ?? widget.tripId;
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

  void _startInAppCall(String driverName) {
    final driverId =
        _trip?['driverId']?.toString() ?? _trip?['driver_id']?.toString();
    if (driverId == null || driverId.isEmpty) return;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => CallScreen(
        contactName: driverName,
        tripId: widget.tripId,
        targetUserId: driverId,
      ),
    ));
  }

  void _openTripChat() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TripChatSheet(
        tripId: widget.tripId,
        senderName: 'Customer',
      ),
    );
  }

  Future<void> _initTts() async {
    try {
      await _tts.setLanguage('en-IN');
      await _tts.setSpeechRate(0.44);
      await _tts.setPitch(1.0);
      await _tts.setVolume(1.0);
    } catch (_) {}
  }

  Future<void> _announceStatus(String status) async {
    if (status == _lastAnnouncedStatus) return;
    _lastAnnouncedStatus = status;
    String? message;
    switch (status) {
      case 'driver_assigned':
      case 'accepted':
        message = 'Pilot assigned and on the way.';
        break;
      case 'arrived':
        message = 'Your pilot has arrived at pickup.';
        break;
      case 'in_progress':
      case 'on_the_way':
        message = 'Trip started. You are now on the way.';
        break;
      case 'completed':
        message = 'Trip completed successfully.';
        break;
      case 'cancelled':
        message = 'Trip has been cancelled.';
        break;
    }
    if (message == null) return;
    try {
      await _tts.stop();
      await _tts.speak(message);
    } catch (_) {}
  }

  // ── Feature 1: Booking Timeout Warning ────────────────────────────────────
  void _startSearchTimeoutTimer() {
    _searchTimeoutTimer?.cancel();
    _searchTimeoutTimer = Timer(const Duration(seconds: 90), () {
      if (!mounted || _status != 'searching') return;
      _showBookingTimeoutWarning();
    });
  }

  void _showBookingTimeoutWarning() {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        title: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.timer_outlined, color: Color(0xFFF59E0B), size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text('Search is taking long',
              style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w500, color: JT.textPrimary)),
          ),
        ]),
        content: Text(
          'We haven\'t found a pilot yet. You can boost your fare to attract more drivers, or cancel the trip.',
          style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF6B7280), height: 1.5),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _showCancelDialog();
            },
            child: Text('Cancel Trip',
              style: GoogleFonts.poppins(color: const Color(0xFFDC2626), fontWeight: FontWeight.w400, fontSize: 13)),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              _showBoostFareSheet();
            },
            icon: const Icon(Icons.bolt_rounded, size: 16),
            label: Text('Boost Fare', style: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 13)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2F7BFF),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }

  // ── Feature 2: Boost Fare ──────────────────────────────────────────────────
  Future<void> _boostFare(int amount) async {
    if (_boostLoading) return;
    setState(() => _boostLoading = true);
    try {
      final headers = await AuthService.getHeaders();
      final tripId = _trip?['id']?.toString() ?? widget.tripId;
      final res = await http.post(
        Uri.parse(ApiConfig.boostFare(tripId)),
        headers: headers,
        body: jsonEncode({'boostAmount': amount}),
      );
      if (!mounted) return;
      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Row(children: [
            const Icon(Icons.bolt_rounded, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Text('Fare boosted by ₹$amount! Searching for pilots...',
              style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w400, fontSize: 13)),
          ]),
          backgroundColor: const Color(0xFF2F7BFF),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 4),
        ));
        // Restart the 90s timer after boost
        _startSearchTimeoutTimer();
      } else {
        final err = jsonDecode(res.body);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(err['message']?.toString() ?? 'Boost failed. Try again.',
            style: GoogleFonts.poppins(color: Colors.white, fontSize: 13)),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Network error. Try again.',
            style: GoogleFonts.poppins(color: Colors.white, fontSize: 13)),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    }
    if (mounted) setState(() => _boostLoading = false);
  }

  void _showBoostFareSheet() {
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 30)],
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 44, height: 4,
            decoration: BoxDecoration(color: const Color(0xFFE5E7EB), borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 20),
          Row(children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF2F7BFF).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.bolt_rounded, color: Color(0xFF2F7BFF), size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Boost Your Fare',
                style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.w500, color: JT.textPrimary)),
              Text('Add extra to attract more pilots',
                style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF6B7280))),
            ])),
          ]),
          const SizedBox(height: 22),
          Row(children: [
            _buildBoostOption(10),
            const SizedBox(width: 10),
            _buildBoostOption(20),
            const SizedBox(width: 10),
            _buildBoostOption(50),
          ]),
          const SizedBox(height: 10),
          Text('Boost amount will be added to the trip fare',
            style: GoogleFonts.poppins(color: const Color(0xFF9CA3AF), fontSize: 11),
            textAlign: TextAlign.center),
        ]),
      ),
    );
  }

  Widget _buildBoostOption(int amount) {
    return Expanded(
      child: GestureDetector(
        onTap: _boostLoading ? null : () {
          Navigator.pop(context);
          _boostFare(amount);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [const Color(0xFF2F7BFF), const Color(0xFF1A5FCC)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: const Color(0xFF2F7BFF).withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.bolt_rounded, color: Colors.white, size: 20),
            const SizedBox(height: 4),
            Text('₹$amount',
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500)),
            Text('Boost', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 10)),
          ]),
        ),
      ),
    );
  }

  Future<void> _loadCancelReasons() async {
    try {
      final res = await http.get(Uri.parse(ApiConfig.configs));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final reasons = (data['cancellationReasons'] as List<dynamic>? ?? [])
            .where((r) =>
                r['userType'] == 'customer' || r['user_type'] == 'customer')
            .map((r) => r['reason']?.toString() ?? '')
            .where((r) => r.isNotEmpty)
            .toList();
        if (mounted) setState(() => _cancelReasons = reasons);
      }
    } catch (_) {}
  }

  Future<void> _pollStatus() async {
    try {
      final headers = await AuthService.getHeaders();
      final res = await http.get(
        Uri.parse('${ApiConfig.trackTrip}/${widget.tripId}'),
        headers: headers,
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final trip = data['trip'];
        if (trip != null && mounted) {
          final dLat = double.tryParse(trip['driverLat']?.toString() ?? '');
          final dLng = double.tryParse(trip['driverLng']?.toString() ?? '');
          final rawStatus = trip['currentStatus'] ?? _status;
          // payment_pending = driver completed but payment not yet confirmed — show as completed on user side
          final resolvedStatus =
              rawStatus == 'payment_pending' ? 'completed' : rawStatus;
          setState(() {
            _trip = trip;
            _status = resolvedStatus;
            if (resolvedStatus == 'completed') {
              _walletPendingAmount = double.tryParse(
                    trip['walletPendingAmount']?.toString() ??
                        trip['pendingPaymentAmount']?.toString() ??
                        '0',
                  ) ??
                  _walletPendingAmount;
            }
            if (dLat != null && dLng != null && dLat != 0) {
              _driverLatLng = LatLng(dLat, dLng);
              _updateDriverMarker(_driverLatLng!);
            }
            // Update map to pickup position
            final pLat = double.tryParse(trip['pickupLat']?.toString() ?? '');
            final pLng = double.tryParse(trip['pickupLng']?.toString() ?? '');
            if (pLat != null && pLng != null && pLat != 0) {
              _center = LatLng(pLat, pLng);
              // Animate camera only when driver is not yet assigned (searching state)
              if (_status == 'searching') {
                _mapController?.animateCamera(CameraUpdate.newLatLng(_center));
              }
            }
          });
          // Fetch route polyline once trip data has pickup+destination
          _fetchRoutePolyline();
          if (_status == 'completed' || _status == 'cancelled')
            _pollTimer?.cancel();
        }
      } else if (res.statusCode == 404 &&
          mounted &&
          (_status == 'completed' || _status == 'cancelled')) {
        _pollTimer?.cancel();
      }
    } catch (_) {}
  }

  Future<void> _cancelTrip(String reason) async {
    setState(() => _boostLoading = true);
    double? walletRefund;
    try {
      final headers = await AuthService.getHeaders();
      final res = await http.post(Uri.parse(ApiConfig.cancelTrip),
          headers: {...headers, 'Content-Type': 'application/json'},
          body: jsonEncode(
              {'tripId': _trip?['id'] ?? widget.tripId, 'reason': reason}));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        walletRefund =
            double.tryParse(data['walletRefund']?.toString() ?? '');
        _socket.cancelTrip(_trip?['id']?.toString() ?? widget.tripId);
      } else {
        String message = 'Unable to cancel this trip right now.';
        try {
          message =
              (jsonDecode(res.body) as Map<String, dynamic>)['message']
                      ?.toString() ??
                  message;
        } catch (_) {}
        if (!mounted) return;
        setState(() => _boostLoading = false);
        _showInlineSnack(message, error: true);
        return;
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _boostLoading = false);
      _showInlineSnack('Network error while cancelling. Please try again.', error: true);
      return;
    }
    if (!mounted) return;
    setState(() => _boostLoading = false);
    if (walletRefund != null && walletRefund > 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          '₹${walletRefund.toStringAsFixed(0)} refunded to your wallet',
          style:
              const TextStyle(fontWeight: FontWeight.w500, color: Colors.white),
        ),
        backgroundColor: JT.primary,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 4),
      ));
      await Future.delayed(const Duration(seconds: 2));
    }
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(context,
        MaterialPageRoute(builder: (_) => const HomeScreen()), (_) => false);
  }

  Future<void> _rateDriver(int stars) async {
    setState(() => _rated = stars);
    try {
      final headers = await AuthService.getHeaders();
      await http.post(Uri.parse(ApiConfig.rateDriver),
          headers: headers,
          body: jsonEncode({
            'tripId': _trip?['id'] ?? widget.tripId,
            'driverId': _trip?['driverId'],
            'rating': stars,
          }));
    } catch (_) {}
  }

  void _showCancelDialog() {
    final reasons = _cancelReasons.isNotEmpty
        ? _cancelReasons
        : [
            'Driver is taking too long',
            'I booked by mistake',
            'Changed travel plans',
            'Other reason',
          ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: JT.border, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          Row(children: [
            Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: JT.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.cancel_rounded,
                    color: JT.primaryDark, size: 20)),
            const SizedBox(width: 12),
            Text('Cancel Reason',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: JT.textPrimary)),
          ]),
          const SizedBox(height: 16),
          ...reasons.map((r) => ListTile(
                title: Text(r,
                    style: TextStyle(
                        fontSize: 14,
                        color: JT.textSecondary,
                        fontWeight: FontWeight.w500)),
                leading: Icon(Icons.chevron_right_rounded,
                    color: Colors.grey[400], size: 18),
                contentPadding: EdgeInsets.zero,
                dense: true,
                onTap: () {
                  Navigator.pop(context);
                  _cancelTrip(r);
                },
              )),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const isDark = false;
    const isDarkSheet = false;
    final statusInfo = _getStatusInfo(_status);
    final trip = _trip;
    final otp =
        trip?['pickupOtp']?.toString() ?? trip?['pickup_otp']?.toString();
    final driverName =
        trip?['driverName']?.toString() ?? trip?['driver_name']?.toString();
    final driverPhone =
        trip?['driverPhone']?.toString() ?? trip?['driver_phone']?.toString();
    final driverRating = trip?['driverRating'] ?? trip?['driver_rating'];
    final driverPhoto =
        trip?['driverPhoto']?.toString() ?? trip?['driver_photo']?.toString();
    final actualFare = trip?['actualFare'] ?? trip?['actual_fare'];
    final estimatedFare = trip?['estimatedFare'] ?? trip?['estimated_fare'];

    final panelBg = JT.surface;

    return PopScope(
      canPop: _status == 'completed' || _status == 'cancelled',
      child: Scaffold(
        backgroundColor: JT.bg,
        body: Stack(children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: _center, zoom: 15),
            onMapCreated: (c) {
              _mapController = c;
              if (_driverLatLng != null) _updateDriverMarker(_driverLatLng!);
              // Fetch route polyline once map is ready
              _fetchRoutePolyline();
            },
            markers: _markers,
            polylines: _polylines,
            myLocationEnabled: true,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.62),
              decoration: BoxDecoration(
                color: panelBg,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: const [
                  BoxShadow(color: Color(0x22000000), blurRadius: 24)
                ],
              ),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(top: 10, bottom: 4),
                    decoration: BoxDecoration(
                        color: JT.border,
                        borderRadius: BorderRadius.circular(2))),
                Flexible(
                    child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildStatusHeader(statusInfo),
                          if (driverName != null && _status != 'searching') ...[
                            const SizedBox(height: 14),
                            _buildDriverCard(driverName, driverPhone,
                                driverRating, driverPhoto),
                          ],
                          if (otp != null &&
                              otp.isNotEmpty &&
                              (_status == 'driver_assigned' ||
                                  _status == 'accepted' ||
                                  _status == 'arrived')) ...[
                            const SizedBox(height: 12),
                            _buildOtpBox(otp),
                          ],
                          if (trip != null) ...[
                            const SizedBox(height: 12),
                            _buildFareRow(trip, actualFare, estimatedFare),
                          ],
                          if (_status == 'completed' && trip != null) ...[
                            const SizedBox(height: 16),
                            _buildCompletedCard(actualFare,
                                walletPendingAmount: _walletPendingAmount),
                          ] else if (_status == 'cancelled') ...[
                            const SizedBox(height: 16),
                            _buildCancelledCard(),
                          ] else ...[
                            const SizedBox(height: 16),
                            Row(children: [
                              if (_status == 'searching' ||
                                  _status == 'driver_assigned' ||
                                  _status == 'accepted' ||
                                  _status == 'arrived') ...[
                                Expanded(
                                    child: GestureDetector(
                                  onTap: _boostLoading ? null : _showCancelDialog,
                                  child: Container(
                                    height: 52,
                                    decoration: BoxDecoration(
                                      color:
                                          JT.primaryDark.withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                          color: JT.primaryDark
                                              .withValues(alpha: 0.20)),
                                      boxShadow: JT.shadowXs,
                                    ),
                                    child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Icon(Icons.cancel_rounded,
                                              size: 16, color: JT.primaryDark),
                                          const SizedBox(width: 6),
                                          Text(
                                              _boostLoading
                                                  ? 'Cancelling...'
                                                  : 'Cancel',
                                              style: const TextStyle(
                                                  color: JT.primaryDark,
                                                  fontWeight: FontWeight.w400,
                                                  fontSize: 13)),
                                        ]),
                                  ),
                                )),
                                const SizedBox(width: 10),
                              ],
                              Expanded(
                                  child: GestureDetector(
                                onTap: () async {
                                  final phone = await _getSupportPhone();
                                  final uri = Uri(scheme: 'tel', path: phone);
                                  if (await canLaunchUrl(uri))
                                    await launchUrl(uri);
                                },
                                child: Container(
                                  height: 52,
                                  decoration: BoxDecoration(
                                    color: JT.primary.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                        color:
                                            JT.primary.withValues(alpha: 0.20)),
                                    boxShadow: JT.shadowXs,
                                  ),
                                  child: const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.phone_in_talk_rounded,
                                            size: 16, color: JT.primary),
                                        SizedBox(width: 6),
                                        Text('Support',
                                            style: TextStyle(
                                                color: JT.primary,
                                                fontWeight: FontWeight.w400,
                                                fontSize: 13)),
                                      ]),
                                ),
                              )),
                            ]),
                          ],
                        ]),
                  ),
                )),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  Future<String> _getSupportPhone() async {
    try {
      final r = await http.get(Uri.parse(ApiConfig.configs));
      if (r.statusCode == 200) {
        final data = jsonDecode(r.body);
        return data['configs']?['support_phone'] ?? '+916303000000';
      }
    } catch (_) {}
    return '+916303000000';
  }

  String? _resolveNetworkImage(String? rawUrl) {
    final value = rawUrl?.trim();
    if (value == null || value.isEmpty) return null;
    if (value.startsWith('http://') || value.startsWith('https://')) return value;
    final base = ApiConfig.assetBaseUrl;
    return value.startsWith('/') ? '$base$value' : '$base/$value';
  }

  void _showInlineSnack(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message,
          style: GoogleFonts.poppins(
              color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
      backgroundColor: error ? const Color(0xFFDC2626) : JT.primary,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  Widget _buildStatusHeader(Map<String, dynamic> info) {
    final color = info['color'] as Color;

    if (_status == 'searching') {
      return AnimatedBuilder(
        animation: _pulseCtrl,
        builder: (_, __) {
          final pulse = _pulseCtrl.value;
          return Column(children: [
            const SizedBox(height: 4),
            SizedBox(
              width: 120,
              height: 120,
              child: Stack(alignment: Alignment.center, children: [
                // Outer pulse ring
                Opacity(
                  opacity: (1 - pulse).clamp(0.0, 1.0) * 0.25,
                  child: Container(
                    width: 100 + pulse * 20,
                    height: 100 + pulse * 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: color, width: 1.5),
                    ),
                  ),
                ),
                // Middle ring
                Opacity(
                  opacity: pulse * 0.35,
                  child: Container(
                    width: 80 + pulse * 10,
                    height: 80 + pulse * 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color.withValues(alpha: 0.08),
                      border: Border.all(color: color, width: 1),
                    ),
                  ),
                ),
                // Inner circle with rotating dots
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withValues(alpha: 0.10),
                    border: Border.all(
                        color: color.withValues(alpha: 0.5), width: 2),
                  ),
                  child: Icon(Icons.search_rounded, color: color, size: 28),
                ),
                // Orbiting dot
                Transform.rotate(
                  angle: pulse * 2 * math.pi,
                  child: Transform.translate(
                    offset: const Offset(0, -36),
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color,
                        boxShadow: [
                          BoxShadow(
                              color: color.withValues(alpha: 0.6),
                              blurRadius: 6)
                        ],
                      ),
                    ),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 12),
            Text(
              'Finding your Pilot',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                  fontSize: 17, fontWeight: FontWeight.w400, color: color),
            ),
            const SizedBox(height: 4),
            Text(
              'Searching for available pilots near you...',
              style: GoogleFonts.poppins(
                  color: const Color(0xFF9CA3AF), fontSize: 12, height: 1.35),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: JT.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.timer_outlined, color: JT.primary, size: 13),
                const SizedBox(width: 5),
                Text('Est. wait: 3–5 min',
                    style: GoogleFonts.poppins(
                        color: JT.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w400)),
              ]),
            ),
            const SizedBox(height: 12),
            // Boost Fare button — visible during searching to attract more drivers
            GestureDetector(
              onTap: _boostLoading ? null : _showBoostFareSheet,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2F7BFF), Color(0xFF1A5FCC)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: const Color(0xFF2F7BFF).withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 3))],
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.bolt_rounded, color: Colors.white, size: 15),
                  const SizedBox(width: 6),
                  Text(_boostLoading ? 'Boosting...' : 'Boost Fare',
                    style: GoogleFonts.poppins(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
                ]),
              ),
            ),
            const SizedBox(height: 4),
          ]);
        },
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.18), width: 1),
      ),
      child: Row(children: [
        Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(info['icon'] as IconData, color: color, size: 22)),
        const SizedBox(width: 12),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            info['label'] as String,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: color,
                height: 1.3),
          ),
          if (_driverLatLng != null &&
              _status != 'completed' &&
              _status != 'cancelled')
            Text(
              'Live tracking active 📍',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                  color: _green, fontSize: 11, fontWeight: FontWeight.w400),
            ),
        ])),
        if (_status != 'completed' && _status != 'cancelled')
          GestureDetector(
            onTap: _shareRide,
            child: Container(
              constraints: const BoxConstraints(minWidth: 72),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                  color: JT.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.share_rounded, color: JT.primary, size: 15),
                const SizedBox(width: 4),
                Text('Share',
                    style: GoogleFonts.poppins(
                        color: JT.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w500)),
              ]),
            ),
          ),
      ]),
    );
  }

  Widget _buildDriverCard(String name, String? phone, dynamic rating,
      [String? photoUrl]) {
    final driverModel = _trip?['driverVehicleModel'] ?? '';
    final driverVehicle = _trip?['driverVehicleNumber'] ?? '';
    final vehicleName = _trip?['vehicleName'] ?? '';
    final resolvedPhotoUrl = _resolveNetworkImage(photoUrl);
    return Container(
      decoration: BoxDecoration(
        color: JT.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: JT.border, width: 1.5),
        boxShadow: JT.cardShadow,
      ),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: JT.primary,
                borderRadius: BorderRadius.circular(16),
                boxShadow: JT.btnShadow,
              ),
              child: resolvedPhotoUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        resolvedPhotoUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Center(
                            child: Text(
                                name.isNotEmpty ? name[0].toUpperCase() : 'P',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 22))),
                      ),
                    )
                  : Center(
                      child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'P',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                              fontSize: 22))),
            ),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w400,
                      fontSize: 15,
                      color: JT.textPrimary,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(children: [
                    const Icon(Icons.star_rounded,
                        color: Colors.amber, size: 14),
                    const SizedBox(width: 3),
                    Text(rating?.toString() ?? '5.0',
                        style: TextStyle(
                            color: JT.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500)),
                    if (vehicleName.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                              color: _blue.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(6)),
                          child: Text(
                            vehicleName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: _blue,
                                fontSize: 10,
                                fontWeight: FontWeight.w400),
                          ),
                        ),
                      ),
                    ],
                  ]),
                ])),
            Row(children: [
              if (phone != null) ...[
                GestureDetector(
                  onTap: () => _startInAppCall(name),
                  child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: JT.surfaceAlt,
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(color: JT.border),
                      ),
                      child: Icon(Icons.phone_rounded,
                          color: JT.primary, size: 20)),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _openTripChat(),
                  child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: JT.surfaceAlt,
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(color: JT.border),
                      ),
                      child: Icon(Icons.chat_rounded,
                          color: JT.primary, size: 20)),
                ),
                const SizedBox(width: 8),
              ],
              GestureDetector(
                onTap: _triggerSos,
                child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A6FDB),
                      borderRadius: BorderRadius.circular(13),
                      boxShadow: [
                        BoxShadow(
                            color:
                                const Color(0xFF1A6FDB).withValues(alpha: 0.24),
                            blurRadius: 8,
                            offset: const Offset(0, 3))
                      ],
                    ),
                    child: const Icon(Icons.sos_rounded,
                        color: Colors.white, size: 20)),
              ),
            ]),
          ]),
        ),
        if (driverVehicle.isNotEmpty ||
            driverModel.isNotEmpty ||
            (_trip?['estimatedTime'] != null))
          Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
                color: _blue.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _blue.withValues(alpha: 0.12))),
            child: Row(children: [
              Icon(Icons.directions_car_rounded, color: _blue, size: 14),
              const SizedBox(width: 6),
              Expanded(
                  child: Text(
                      [
                        if (driverVehicle.isNotEmpty)
                          driverVehicle.toUpperCase(),
                        if (driverModel.isNotEmpty) driverModel
                      ].join(' · '),
                      style: TextStyle(
                          color: _blue,
                          fontSize: 11,
                          fontWeight: FontWeight.w500))),
              if (_status != 'in_progress' && _status != 'completed') ...[
                const SizedBox(width: 8),
                Icon(Icons.access_time_rounded, color: _blue, size: 13),
                const SizedBox(width: 4),
                Text(
                    _status == 'arrived'
                        ? 'Pilot at pickup'
                        : 'ETA: ${_trip?['estimatedTime'] ?? '~5 min'}',
                    style: TextStyle(
                        color: _blue,
                        fontSize: 11,
                        fontWeight: FontWeight.w500)),
              ],
            ]),
          ),
      ]),
    );
  }

  Future<void> _shareRide() async {
    final tripId = widget.tripId;
    final shareText =
        '🚗 Track my JAGO ride!\nLive location: https://jagopro.org/track/$tripId\nDownload JAGO Pro: https://jagopro.org/download';
    final encoded = Uri.encodeComponent(shareText);
    final uri = Uri.parse('whatsapp://send?text=$encoded');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      await Clipboard.setData(ClipboardData(text: shareText));
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Share text copied! Paste in WhatsApp'),
            backgroundColor: JT.primary));
    }
  }

  Future<void> _triggerSos() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('🚨 SOS Alert',
            style: TextStyle(fontWeight: FontWeight.w500)),
        content: const Text(
            'Send an Emergency SOS? Our help team will contact you immediately.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: JT.primary),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Send SOS',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w500))),
        ],
      ),
    );
    if (confirm != true) return;
    final sosHeaders = await AuthService.getHeaders();
    try {
      await http.post(Uri.parse(ApiConfig.sos),
          headers: {...sosHeaders, 'Content-Type': 'application/json'},
          body: jsonEncode({
            'tripId': widget.tripId,
            'lat': _center.latitude,
            'lng': _center.longitude,
            'message': 'Customer SOS alert during trip',
          }));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('🚨 SOS Alert sent! Help is on the way.',
            style: TextStyle(fontWeight: FontWeight.w400)),
        backgroundColor: JT.primary,
        behavior: SnackBarBehavior.floating,
      ));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('SOS failed. Call 100 immediately!',
            style: TextStyle(fontWeight: FontWeight.w400)),
        backgroundColor: JT.primaryDark,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  Widget _buildOtpBox(String otp) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: JT.surfaceAlt,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: JT.border, width: 1.5),
        boxShadow: JT.cardShadow,
      ),
      child: Row(children: [
        Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: JT.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.lock_rounded, color: JT.primary, size: 20)),
        const SizedBox(width: 12),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Share this OTP with Pilot',
              style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 11,
                  color: JT.primary)),
          Text(otp,
              style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w500,
                  color: JT.primary,
                  letterSpacing: 10)),
        ])),
        GestureDetector(
          onTap: () {
            Clipboard.setData(ClipboardData(text: otp));
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: const Text('OTP copied!',
                  style: TextStyle(fontWeight: FontWeight.w400)),
              backgroundColor: JT.primary,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ));
          },
          child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: JT.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.copy_rounded, color: JT.primary, size: 16)),
        ),
      ]),
    );
  }

  Widget _buildFareRow(
      Map<String, dynamic> trip, dynamic actualFare, dynamic estimatedFare) {
    final fareVal = actualFare ?? estimatedFare;
    final dist = trip['estimatedDistance'] ?? trip['estimated_distance'];
    final vehicle = trip['vehicleName'] ?? trip['vehicle_name'];
    return Wrap(spacing: 8, children: [
      if (fareVal != null)
        _chip(Icons.currency_rupee_rounded, '₹$fareVal', _blue),
      if (dist != null)
        _chip(Icons.route_rounded, '$dist km', const Color(0xFF6B7280)),
      if (vehicle != null)
        _chip(Icons.electric_bike, vehicle.toString(), const Color(0xFF6B7280)),
    ]);
  }

  Widget _chip(IconData icon, String label, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 5),
        Text(label,
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w500, color: color)),
      ]),
    );
  }

  Widget _buildCompletedCard(dynamic actualFare,
      {double walletPendingAmount = 0}) {
    final dName = _trip?['driverName']?.toString() ??
        _trip?['driver_name']?.toString() ??
        'Pilot';
    final tId = _trip?['id']?.toString() ?? widget.tripId;
    final dist = _trip?['estimatedDistance'] ?? _trip?['estimated_distance'];
    final vehicle = _trip?['vehicleName'] ?? _trip?['vehicle_name'];

    return Column(children: [
      // Success banner
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border:
              Border.all(color: JT.primary.withValues(alpha: 0.16), width: 1.5),
          boxShadow: JT.cardShadow,
        ),
        child: Column(children: [
          Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: JT.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                      color: JT.primary.withValues(alpha: 0.18),
                      blurRadius: 16,
                      offset: const Offset(0, 4))
                ],
              ),
              child: const Icon(Icons.check_rounded,
                  color: Colors.white, size: 30)),
          const SizedBox(height: 12),
          Text('Trip Completed!',
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w400,
                  fontSize: 18,
                  color: JT.textPrimary)),
          if (actualFare != null) ...[
            const SizedBox(height: 8),
            Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: JT.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text('₹$actualFare',
                    style: GoogleFonts.poppins(
                        fontSize: 32,
                        fontWeight: FontWeight.w500,
                        color: JT.primary))),
          ],
          // Wallet insufficient — show "pay remaining" banner
          if (walletPendingAmount > 0) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: JT.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: JT.primary.withValues(alpha: 0.2), width: 1.5),
              ),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Icon(Icons.info_outline_rounded,
                          color: JT.primary, size: 20),
                      const SizedBox(width: 8),
                      Text('Wallet Insufficient',
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w400,
                              fontSize: 13,
                              color: JT.primaryDark)),
                    ]),
                    const SizedBox(height: 6),
                    Text(
                      'Your wallet had less balance. Please pay ₹${walletPendingAmount.toStringAsFixed(0)} to the pilot by Cash or UPI.',
                      style: GoogleFonts.poppins(
                          fontSize: 12, color: JT.textSecondary),
                    ),
                  ]),
            ),
          ],
          // ── Payment receipt breakdown ──────────────────────────────────
          if (actualFare != null) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Payment Receipt',
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                            color: const Color(0xFF6B7280))),
                    const SizedBox(height: 8),
                    _receiptRow('Trip Fare', '₹$actualFare'),
                    if ((_trip?['userDiscount'] ??
                            _trip?['user_discount'] ??
                            0) >
                        0)
                      _receiptRow('Discount',
                          '- ₹${_trip?['userDiscount'] ?? _trip?['user_discount']}',
                          valueColor: JT.primaryDark),
                    _receiptRow(
                      'Payment',
                      () {
                        final pm = (_trip?['paymentMethod'] ??
                                    _trip?['payment_method'] ??
                                    'cash')
                                .toString()
                                .toLowerCase();
                        if (pm == 'wallet') return 'Wallet';
                        if (pm == 'online' || pm == 'upi' || pm == 'razorpay')
                          return 'Online Paid';
                        return 'Cash to Pilot';
                      }(),
                      valueColor: const Color(0xFF2563EB),
                    ),
                    if (walletPendingAmount > 0)
                      _receiptRow(
                        'Cash to Pilot',
                        '₹${walletPendingAmount.toStringAsFixed(0)}',
                        valueColor: JT.primaryDark,
                      ),
                  ]),
            ),
          ],
          // Trip details chips
          if (dist != null || vehicle != null) ...[
            const SizedBox(height: 12),
            Wrap(
                spacing: 8,
                runSpacing: 6,
                alignment: WrapAlignment.center,
                children: [
                  if (dist != null)
                    _completedChip(Icons.route_rounded, '$dist km',
                        const Color(0xFF6B7280)),
                  if (vehicle != null)
                    _completedChip(
                        Icons.electric_bike, vehicle.toString(), _blue),
                ]),
          ],
          const SizedBox(height: 16),
          // Rating section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: _rated == 0
                ? Column(children: [
                    Text('How was your ride with $dName?',
                        style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: const Color(0xFF374151),
                            fontWeight: FontWeight.w400),
                        textAlign: TextAlign.center),
                    const SizedBox(height: 10),
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      for (int i = 1; i <= 5; i++)
                        GestureDetector(
                            onTap: () => _rateDriver(i),
                            child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                child: Icon(Icons.star_rounded,
                                    color: i <= _rated
                                        ? Colors.amber
                                        : Colors.grey.shade200,
                                    size: 40))),
                    ]),
                  ])
                : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Row(children: [
                      for (int i = 1; i <= 5; i++)
                        Icon(Icons.star_rounded,
                            color: i <= _rated
                                ? Colors.amber
                                : Colors.grey.shade300,
                            size: 24),
                    ]),
                    const SizedBox(width: 10),
                    Text('Thanks! 🙏',
                        style: GoogleFonts.poppins(
                            color: JT.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500)),
                  ]),
          ),
        ]),
      ),
      const SizedBox(height: 10),
      // Tip button
      OutlinedButton.icon(
        onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) =>
                    TipDriverScreen(tripId: tId, driverName: dName))),
        icon: const Icon(Icons.volunteer_activism_rounded,
            color: JT.primary, size: 18),
        label: Text('Tip your Pilot',
            style: GoogleFonts.poppins(
                color: JT.primary, fontWeight: FontWeight.w500, fontSize: 13)),
        style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 46),
            side: const BorderSide(color: JT.primary, width: 1.5),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14))),
      ),
      const SizedBox(height: 8),
      SizedBox(
          width: double.infinity,
          child: JT.gradientButton(
            label: 'Book Another Ride',
            onTap: () => Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const HomeScreen()),
                (_) => false),
          )),
    ]);
  }

  Widget _receiptRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 12, color: const Color(0xFF6B7280))),
          Text(value,
              style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: valueColor ?? const Color(0xFF111827))),
        ],
      ),
    );
  }

  Widget _completedChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Text(label,
            style: GoogleFonts.poppins(
                fontSize: 11, fontWeight: FontWeight.w500, color: color)),
      ]),
    );
  }

  Widget _buildCancelledCard() {
    final noDriver = _lastAnnouncedStatus == 'cancelled' ||
        _trip == null ||
        (_trip!['cancellationReason']?.toString().contains('no') == true);

    return Column(children: [
      // Status banner
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: noDriver
              ? JT.primary.withValues(alpha: 0.06)
              : const Color(0xFFF8FAFF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: noDriver
                  ? JT.primary.withValues(alpha: 0.18)
                  : JT.primary.withValues(alpha: 0.14)),
        ),
        child: Row(children: [
          Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: noDriver
                      ? JT.primary.withValues(alpha: 0.12)
                      : JT.primaryDark.withValues(alpha: 0.08),
                  shape: BoxShape.circle),
              child: Icon(
                  noDriver ? Icons.search_off_rounded : Icons.cancel_rounded,
                  color: noDriver ? JT.primary : JT.primaryDark,
                  size: 24)),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(
                  noDriver ? 'No Pilots Available' : 'Trip Cancelled',
                  style: GoogleFonts.poppins(
                    color: noDriver ? JT.primaryDark : JT.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  noDriver
                      ? 'No pilots found nearby. You can retry or try later.'
                      : 'Sorry for the inconvenience.',
                  style: GoogleFonts.poppins(
                      color: JT.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500),
                ),
              ])),
        ]),
      ),
      const SizedBox(height: 12),

      // Action buttons row
      Row(children: [
        // Retry — tries the same booking again
        Expanded(
          flex: 3,
          child: GestureDetector(
            onTap: _retryBooking,
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                color: JT.primary,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                      color: JT.primary.withValues(alpha: 0.14),
                      blurRadius: 12,
                      offset: const Offset(0, 4))
                ],
              ),
              child: Center(
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.refresh_rounded,
                    color: Colors.white, size: 18),
                const SizedBox(width: 6),
                Text('Retry Booking',
                    style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w400)),
              ])),
            ),
          ),
        ),
        const SizedBox(width: 10),
        // Home — go back to start
        Expanded(
          flex: 2,
          child: GestureDetector(
            onTap: () => Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const HomeScreen()),
                (_) => false),
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F7FF),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE8EFFF)),
              ),
              child: Center(
                  child: Text('Go Home',
                      style: GoogleFonts.poppins(
                          color: JT.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500))),
            ),
          ),
        ),
      ]),
    ]);
  }

  void _showPilotFoundBanner() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle),
          child: const Icon(Icons.electric_bike_rounded,
              color: Colors.white, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
              Text('Pilot Found!',
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w400,
                      fontSize: 14,
                      color: Colors.white)),
              Text('Your pilot is on the way to you',
                  style:
                      GoogleFonts.poppins(fontSize: 11, color: Colors.white70)),
            ])),
      ]),
      backgroundColor: _blue,
      duration: const Duration(seconds: 5),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
    ));
  }

  void _showArrivalBanner() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle),
          child: const Icon(Icons.where_to_vote_rounded,
              color: Colors.white, size: 18),
        ),
        const SizedBox(width: 12),
        const Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
              Text('Pilot has arrived!',
                  style: TextStyle(
                      fontWeight: FontWeight.w400,
                      fontSize: 14,
                      color: Colors.white)),
              Text('Share your OTP to start the trip',
                  style: TextStyle(fontSize: 11, color: Colors.white70)),
            ])),
      ]),
      backgroundColor: JT.primary,
      duration: const Duration(seconds: 5),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
    ));
  }

  Map<String, dynamic> _getStatusInfo(String status) {
    switch (status) {
      case 'searching':
        return {
          'label': 'Searching for nearby Pilots...',
          'icon': Icons.search_rounded,
          'color': JT.primary
        };
      case 'driver_assigned':
        return {
          'label': 'Pilot Assigned! 🎉',
          'icon': Icons.electric_bike,
          'color': _blue
        };
      case 'accepted':
        return {
          'label': 'Pilot is on the way 🏍️',
          'icon': Icons.navigation_rounded,
          'color': _blue
        };
      case 'arrived':
        return {
          'label': 'Pilot Arrived! 📍',
          'icon': Icons.where_to_vote_rounded,
          'color': JT.primaryDark
        };
      case 'in_progress':
        return {
          'label': 'Trip in Progress 🚀',
          'icon': Icons.speed_rounded,
          'color': _blue
        };
      case 'on_the_way':
        return {
          'label': 'Trip in Progress 🚀',
          'icon': Icons.speed_rounded,
          'color': _blue
        };
      case 'completed':
        return {
          'label': 'Trip Completed! ✅',
          'icon': Icons.check_circle_rounded,
          'color': JT.primary
        };
      case 'cancelled':
        return {
          'label': 'Trip Cancelled',
          'icon': Icons.cancel_rounded,
          'color': JT.primaryDark
        };
      default:
        return {
          'label': 'Loading...',
          'icon': Icons.hourglass_empty_rounded,
          'color': const Color(0xFF94A3B8)
        };
    }
  }
}
