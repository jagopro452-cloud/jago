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

class _TrackingScreenState extends State<TrackingScreen> with TickerProviderStateMixin {
  final SocketService _socket = SocketService();
  GoogleMapController? _mapController;
  LatLng _center = const LatLng(17.3850, 78.4867);
  LatLng? _driverLatLng;
  String _status = 'searching';
  Map<String, dynamic>? _trip;
  Timer? _pollTimer;
  int _rated = 0;
  double _walletPendingAmount = 0; // amount customer still owes after wallet deduction
  List<String> _cancelReasons = [];
  late AnimationController _pulseCtrl;
  final Set<Marker> _markers = {};
  final List<StreamSubscription> _subs = [];
  final FlutterTts _tts = FlutterTts();
  String _lastAnnouncedStatus = '';
  StreamSubscription? _incomingCallSub;

  static const Color _blue = Color(0xFF2F7BFF);
  static const Color _green = JT.success;

  @override
  void initState() {
    super.initState();
    _initTts();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _connectSocket();
    _pollStatus();
    _loadCancelReasons();
    CallService().init();
    _listenForIncomingCalls();
    // HTTP polling as fallback (every 3s — socket handles real-time)
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) => _pollStatus());
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
        final newStatus = data['status']?.toString() ?? _status;
        final otp = data['otp']?.toString();
        setState(() {
          _status = newStatus;
          if (otp != null && _trip != null) {
            _trip!['pickupOtp'] = otp;
          }
          // Capture wallet pending amount when trip completes
          if (newStatus == 'completed') {
            _walletPendingAmount = (data['walletPendingAmount'] as num?)?.toDouble() ?? 0.0;
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
        }
        if (newStatus == 'completed') AlarmService().playChime();
        if (newStatus == 'completed' || newStatus == 'cancelled') {
          _pollTimer?.cancel();
          _pollStatus(); // fetch final state
        }
      }));

      // Driver assigned (from searching state)
      _subs.add(_socket.onDriverAssigned.listen((data) {
        if (!mounted) return;
        setState(() => _status = 'driver_assigned');
        AlarmService().playChime();
        HapticFeedback.heavyImpact();
        _announceStatus('driver_assigned');
        _pollStatus();
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
        Expanded(child: Text('No pilots nearby. Try again!',
          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13))),
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
          pickup: t['pickupAddress']?.toString() ?? t['pickup_address']?.toString() ?? 'Pickup',
          destination: t['destinationAddress']?.toString() ?? t['destination_address']?.toString() ?? 'Destination',
          pickupLat: double.tryParse(t['pickupLat']?.toString() ?? '') ?? 0.0,
          pickupLng: double.tryParse(t['pickupLng']?.toString() ?? '') ?? 0.0,
          destLat: double.tryParse(t['destinationLat']?.toString() ?? '') ?? 0.0,
          destLng: double.tryParse(t['destinationLng']?.toString() ?? '') ?? 0.0,
          vehicleCategoryId: t['vehicleCategoryId']?.toString(),
          vehicleCategoryName: t['vehicleName']?.toString(),
          category: (t['tripType']?.toString() == 'parcel' || t['trip_type']?.toString() == 'parcel')
              ? 'parcel' : 'ride',
        ),
      ),
      (_) => false,
    );
  }

  BitmapDescriptor _vehicleMarkerIcon() {
    final vehicle = (_trip?['vehicleName'] ?? _trip?['vehicle_name'] ?? '').toString().toLowerCase();
    if (vehicle.contains('bike') || vehicle.contains('moto') || vehicle.contains('two')) {
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);   // Bike → Orange
    } else if (vehicle.contains('auto') || vehicle.contains('rick')) {
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);    // Auto → Green
    } else if (vehicle.contains('suv') || vehicle.contains('innova')) {
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet);   // SUV → Violet
    } else if (vehicle.contains('parcel') || vehicle.contains('truck') || vehicle.contains('tata')) {
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueMagenta);  // Parcel → Magenta
    } else if (vehicle.contains('car') || vehicle.contains('sedan') || vehicle.contains('mini')) {
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure);    // Car → Azure
    }
    return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);       // Default → Blue
  }

  void _updateDriverMarker(LatLng pos) {
    _markers.removeWhere((m) => m.markerId.value == 'driver');
    final vehicleName = (_trip?['vehicleName'] ?? _trip?['vehicle_name'] ?? 'Pilot').toString();
    _markers.add(Marker(
      markerId: const MarkerId('driver'),
      position: pos,
      icon: _vehicleMarkerIcon(),
      infoWindow: InfoWindow(title: vehicleName.isNotEmpty ? vehicleName : 'Your Pilot'),
    ));
    // Keep camera on driver when trip is in progress (driver arriving or started)
    if (_status == 'driver_assigned' || _status == 'accepted' ||
        _status == 'arrived' || _status == 'in_progress' || _status == 'on_the_way') {
      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(pos, 16));
    }
  }

  @override
  void dispose() {
    for (final s in _subs) s.cancel();
    _incomingCallSub?.cancel();
    _pollTimer?.cancel();
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
    final driverId = _trip?['driverId']?.toString() ?? _trip?['driver_id']?.toString();
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

  Future<void> _loadCancelReasons() async {
    try {
      final res = await http.get(Uri.parse(ApiConfig.configs));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final reasons = (data['cancellationReasons'] as List<dynamic>? ?? [])
          .where((r) => r['userType'] == 'customer' || r['user_type'] == 'customer')
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
      final res = await http.get(Uri.parse(ApiConfig.activeTrip),
        headers: headers);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final trip = data['trip'];
        if (trip != null && mounted) {
          final dLat = double.tryParse(trip['driverLat']?.toString() ?? '');
          final dLng = double.tryParse(trip['driverLng']?.toString() ?? '');
          setState(() {
            _trip = trip;
            _status = trip['currentStatus'] ?? _status;
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
          if (_status == 'completed' || _status == 'cancelled') _pollTimer?.cancel();
        }
      }
    } catch (_) {}
  }

  Future<void> _cancelTrip(String reason) async {
    // Cancel via socket first
    _socket.cancelTrip(_trip?['id']?.toString() ?? widget.tripId);
    // Also HTTP for persistence
    double? walletRefund;
    try {
      final headers = await AuthService.getHeaders();
      final res = await http.post(Uri.parse(ApiConfig.cancelTrip),
        headers: headers,
        body: jsonEncode({'tripId': _trip?['id'] ?? widget.tripId, 'reason': reason}));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        walletRefund = (data['walletRefund'] as num?)?.toDouble();
      }
    } catch (_) {}
    if (!mounted) return;
    if (walletRefund != null && walletRefund > 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          '₹${walletRefund.toStringAsFixed(0)} refunded to your wallet',
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF16A34A),
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
    final reasons = _cancelReasons.isNotEmpty ? _cancelReasons : [
      'Driver is taking too long',
      'I booked by mistake',
      'Changed travel plans',
      'Other reason',
    ];
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4,
            decoration: BoxDecoration(color: JT.border, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          Row(children: [
            Container(padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.cancel_rounded, color: Color(0xFFEF4444), size: 20)),
            const SizedBox(width: 12),
            Text('Cancel Reason', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: JT.textPrimary)),
          ]),
          const SizedBox(height: 16),
          ...reasons.map((r) => ListTile(
            title: Text(r, style: TextStyle(fontSize: 14, color: JT.textSecondary, fontWeight: FontWeight.w500)),
            leading: Icon(Icons.chevron_right_rounded, color: Colors.grey[400], size: 18),
            contentPadding: EdgeInsets.zero,
            dense: true,
            onTap: () { Navigator.pop(context); _cancelTrip(r); },
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
    final otp = trip?['pickupOtp']?.toString() ?? trip?['pickup_otp']?.toString();
    final driverName = trip?['driverName']?.toString() ?? trip?['driver_name']?.toString();
    final driverPhone = trip?['driverPhone']?.toString() ?? trip?['driver_phone']?.toString();
    final driverRating = trip?['driverRating'] ?? trip?['driver_rating'];
    final driverPhoto = trip?['driverPhoto']?.toString() ?? trip?['driver_photo']?.toString();
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
            },
            markers: _markers,
            myLocationEnabled: true,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
          ),
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.62),
              decoration: BoxDecoration(
                color: panelBg,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 24)],
              ),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 40, height: 4,
                  margin: const EdgeInsets.only(top: 10, bottom: 4),
                  decoration: BoxDecoration(color: JT.border, borderRadius: BorderRadius.circular(2))),
                Flexible(
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _buildStatusHeader(statusInfo),
                    if (driverName != null && _status != 'searching') ...[
                      const SizedBox(height: 14),
                      _buildDriverCard(driverName, driverPhone, driverRating, driverPhoto),
                    ],
                    if (otp != null && otp.isNotEmpty &&
                        (_status == 'driver_assigned' || _status == 'accepted' || _status == 'arrived')) ...[
                      const SizedBox(height: 12),
                      _buildOtpBox(otp),
                    ],
                    if (trip != null) ...[
                      const SizedBox(height: 12),
                      _buildFareRow(trip, actualFare, estimatedFare),
                    ],
                    if (_status == 'completed') ...[
                      const SizedBox(height: 16),
                      _buildCompletedCard(actualFare, walletPendingAmount: _walletPendingAmount),
                    ] else if (_status == 'cancelled') ...[
                      const SizedBox(height: 16),
                      _buildCancelledCard(),
                    ] else ...[
                      const SizedBox(height: 16),
                      Row(children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: _showCancelDialog,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: [Colors.red.withValues(alpha: 0.15), Colors.red.withValues(alpha: 0.07)]),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                              ),
                              child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                Icon(Icons.cancel_rounded, size: 16, color: Color(0xFFEF4444)),
                                SizedBox(width: 6),
                                Text('Cancel', style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.w800, fontSize: 13)),
                              ]),
                            ),
                          )),
                        const SizedBox(width: 10),
                        Expanded(
                          child: GestureDetector(
                            onTap: () async {
                              final phone = await _getSupportPhone();
                              final uri = Uri(scheme: 'tel', path: phone);
                              if (await canLaunchUrl(uri)) await launchUrl(uri);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: [Colors.green.withValues(alpha: 0.15), Colors.green.withValues(alpha: 0.07)]),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: Colors.green.withValues(alpha: 0.35)),
                              ),
                              child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                Icon(Icons.phone_in_talk_rounded, size: 16, color: Colors.green),
                                SizedBox(width: 6),
                                Text('Support', style: TextStyle(color: Colors.green, fontWeight: FontWeight.w800, fontSize: 13)),
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
                    gradient: RadialGradient(colors: [
                      color.withValues(alpha: 0.25),
                      color.withValues(alpha: 0.08),
                    ]),
                    border: Border.all(color: color.withValues(alpha: 0.5), width: 2),
                  ),
                  child: Icon(Icons.search_rounded, color: color, size: 28),
                ),
                // Orbiting dot
                Transform.rotate(
                  angle: pulse * 2 * math.pi,
                  child: Transform.translate(
                    offset: const Offset(0, -36),
                    child: Container(
                      width: 8, height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color,
                        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 6)],
                      ),
                    ),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 12),
            Text('Finding your Pilot',
              style: GoogleFonts.poppins(
                fontSize: 17, fontWeight: FontWeight.w800, color: color)),
            const SizedBox(height: 4),
            Text('Searching for available pilots near you...',
              style: GoogleFonts.poppins(
                color: const Color(0xFF9CA3AF), fontSize: 12),
              textAlign: TextAlign.center),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.timer_outlined, color: Colors.orange, size: 13),
                const SizedBox(width: 5),
                Text('Est. wait: 3–5 min',
                  style: GoogleFonts.poppins(
                    color: Colors.orange, fontSize: 11, fontWeight: FontWeight.w600)),
              ]),
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
          width: 44, height: 44,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
          child: Icon(info['icon'] as IconData, color: color, size: 22)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(info['label'] as String,
            style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w800, color: color)),
          if (_driverLatLng != null && _status != 'completed' && _status != 'cancelled')
            Text('Live tracking active 📍',
              style: GoogleFonts.poppins(color: _green, fontSize: 11, fontWeight: FontWeight.w600)),
        ])),
        if (_status != 'completed' && _status != 'cancelled')
          GestureDetector(
            onTap: _shareRide,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: JT.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.share_rounded, color: JT.primary, size: 15),
                const SizedBox(width: 4),
                Text('Share', style: GoogleFonts.poppins(color: JT.primary, fontSize: 11, fontWeight: FontWeight.w700)),
              ]),
            ),
          ),
      ]),
    );
  }

  Widget _buildDriverCard(String name, String? phone, dynamic rating, [String? photoUrl]) {
    final driverModel = _trip?['driverVehicleModel'] ?? '';
    final driverVehicle = _trip?['driverVehicleNumber'] ?? '';
    final vehicleName = _trip?['vehicleName'] ?? '';
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
              width: 52, height: 52,
              decoration: BoxDecoration(
                gradient: JT.grad,
                borderRadius: BorderRadius.circular(16),
                boxShadow: JT.btnShadow,
              ),
              child: photoUrl != null && photoUrl.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      photoUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Center(child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : 'P',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 22))),
                    ),
                  )
                : Center(child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'P',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 22))),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15,
                color: JT.textPrimary, letterSpacing: -0.3)),
              const SizedBox(height: 3),
              Row(children: [
                const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                const SizedBox(width: 3),
                Text(rating?.toString() ?? '5.0',
                  style: TextStyle(color: JT.textSecondary, fontSize: 12, fontWeight: FontWeight.w700)),
                if (vehicleName.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: _blue.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6)),
                    child: Text(vehicleName, style: TextStyle(color: _blue, fontSize: 10, fontWeight: FontWeight.w800)),
                  ),
                ],
              ]),
            ])),
            Row(children: [
              if (phone != null) ...[
                GestureDetector(
                  onTap: () => _startInAppCall(name),
                  child: Container(
                    width: 42, height: 42,
                    decoration: BoxDecoration(
                      color: JT.surfaceAlt,
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(color: JT.border),
                    ),
                    child: Icon(Icons.phone_rounded, color: JT.primary, size: 20)),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _openTripChat(),
                  child: Container(
                    width: 42, height: 42,
                    decoration: BoxDecoration(
                      color: JT.surfaceAlt,
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(color: JT.border),
                    ),
                    child: Icon(Icons.chat_rounded, color: JT.primary, size: 20)),
                ),
                const SizedBox(width: 8),
              ],
              GestureDetector(
                onTap: _triggerSos,
                child: Container(
                  width: 42, height: 42,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF7F1D1D), Colors.red]),
                    borderRadius: BorderRadius.circular(13),
                    boxShadow: [BoxShadow(color: Colors.red.withValues(alpha: 0.35), blurRadius: 8, offset: const Offset(0,3))],
                  ),
                  child: const Icon(Icons.sos_rounded, color: Colors.white, size: 20)),
              ),
            ]),
          ]),
        ),
        if (driverVehicle.isNotEmpty || driverModel.isNotEmpty || (_trip?['estimatedTime'] != null))
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
              Expanded(child: Text(
                [if (driverVehicle.isNotEmpty) driverVehicle.toUpperCase(), if (driverModel.isNotEmpty) driverModel].join(' · '),
                style: TextStyle(color: _blue, fontSize: 11, fontWeight: FontWeight.w700))),
              if (_status != 'in_progress' && _status != 'completed') ...[
                const SizedBox(width: 8),
                Icon(Icons.access_time_rounded, color: _blue, size: 13),
                const SizedBox(width: 4),
                Text(
                  _status == 'arrived' ? 'Pilot at pickup' : 'ETA: ${_trip?['estimatedTime'] ?? '~5 min'}',
                  style: TextStyle(color: _blue, fontSize: 11, fontWeight: FontWeight.w700)),
              ],
            ]),
          ),
      ]),
    );
  }

  Future<void> _shareRide() async {
    final tripId = widget.tripId;
    final shareText = '🚗 Track my JAGO ride!\nLive location: https://jagopro.org/track/$tripId\nDownload JAGO Pro: https://jagopro.org/download';
    final encoded = Uri.encodeComponent(shareText);
    final uri = Uri.parse('whatsapp://send?text=$encoded');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      await Clipboard.setData(ClipboardData(text: shareText));
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Share text copied! Paste in WhatsApp'), backgroundColor: JT.primary));
    }
  }

  Future<void> _triggerSos() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('🚨 SOS Alert', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Send an Emergency SOS? Our help team will contact you immediately.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Send SOS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
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
        content: Text('🚨 SOS Alert sent! Help is on the way.', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('SOS failed. Call 100 immediately!', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.red,
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
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Share this OTP with Pilot',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: JT.primary)),
          Text(otp,
            style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: JT.primary, letterSpacing: 10)),
        ])),
        GestureDetector(
          onTap: () {
            Clipboard.setData(ClipboardData(text: otp));
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: const Text('OTP copied!', style: TextStyle(fontWeight: FontWeight.w600)),
              backgroundColor: JT.primary,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

  Widget _buildFareRow(Map<String, dynamic> trip, dynamic actualFare, dynamic estimatedFare) {
    final fareVal = actualFare ?? estimatedFare;
    final dist = trip['estimatedDistance'] ?? trip['estimated_distance'];
    final vehicle = trip['vehicleName'] ?? trip['vehicle_name'];
    return Wrap(spacing: 8, children: [
      if (fareVal != null) _chip(Icons.currency_rupee_rounded, '₹$fareVal', _blue),
      if (dist != null) _chip(Icons.route_rounded, '$dist km', const Color(0xFF6B7280)),
      if (vehicle != null) _chip(Icons.electric_bike, vehicle.toString(), const Color(0xFF6B7280)),
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
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
      ]),
    );
  }

  Widget _buildCompletedCard(dynamic actualFare, {double walletPendingAmount = 0}) {

    final dName = _trip?['driverName']?.toString() ?? _trip?['driver_name']?.toString() ?? 'Pilot';
    final tId = _trip?['id']?.toString() ?? widget.tripId;
    final dist = _trip?['estimatedDistance'] ?? _trip?['estimated_distance'];
    final vehicle = _trip?['vehicleName'] ?? _trip?['vehicle_name'];

    return Column(children: [
      // Success banner
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [_green.withValues(alpha: 0.08), _green.withValues(alpha: 0.03)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _green.withValues(alpha: 0.25), width: 1.5),
        ),
        child: Column(children: [
          Container(
            width: 60, height: 60,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0D9F6E), Color(0xFF16A34A)]),
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(
                color: const Color(0xFF16A34A).withValues(alpha: 0.35),
                blurRadius: 16, offset: const Offset(0, 4))],
            ),
            child: const Icon(Icons.check_rounded, color: Colors.white, size: 30)),
          const SizedBox(height: 12),
          Text('Trip Completed!',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w800, fontSize: 18,
              color: JT.textPrimary)),
          if (actualFare != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: _green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text('₹$actualFare',
                style: GoogleFonts.poppins(
                  fontSize: 32, fontWeight: FontWeight.w900,
                  color: const Color(0xFF16A34A)))),
          ],
          // Wallet insufficient — show "pay remaining" banner
          if (walletPendingAmount > 0) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFF97316), width: 1.5),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  const Icon(Icons.warning_amber_rounded, color: Color(0xFFF97316), size: 20),
                  const SizedBox(width: 8),
                  Text('Wallet Insufficient',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w800, fontSize: 13,
                      color: const Color(0xFFEA580C))),
                ]),
                const SizedBox(height: 6),
                Text(
                  'Your wallet had less balance. Please pay ₹${walletPendingAmount.toStringAsFixed(0)} to the pilot by Cash or UPI.',
                  style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF78350F)),
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
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Payment Receipt',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700, fontSize: 12,
                    color: const Color(0xFF6B7280))),
                const SizedBox(height: 8),
                _receiptRow('Trip Fare', '₹$actualFare'),
                if ((_trip?['userDiscount'] ?? _trip?['user_discount'] ?? 0) > 0)
                  _receiptRow('Discount', '- ₹${_trip?['userDiscount'] ?? _trip?['user_discount']}',
                    valueColor: const Color(0xFF16A34A)),
                _receiptRow(
                  'Payment',
                  () {
                    final pm = _trip?['paymentMethod'] ?? _trip?['payment_method'] ?? 'cash';
                    if (pm == 'wallet') return 'Wallet';
                    if (pm == 'online') return 'Online Paid';
                    return 'Cash to Pilot';
                  }(),
                  valueColor: const Color(0xFF2563EB),
                ),
                if (walletPendingAmount > 0)
                  _receiptRow(
                    'Cash to Pilot',
                    '₹${walletPendingAmount.toStringAsFixed(0)}',
                    valueColor: const Color(0xFFF97316),
                  ),
              ]),
            ),
          ],
          // Trip details chips
          if (dist != null || vehicle != null) ...[
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 6, alignment: WrapAlignment.center, children: [
              if (dist != null)
                _completedChip(Icons.route_rounded, '$dist km', const Color(0xFF6B7280)),
              if (vehicle != null)
                _completedChip(Icons.electric_bike, vehicle.toString(), _blue),
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
                        fontSize: 13, color: const Color(0xFF374151),
                        fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center),
                    const SizedBox(height: 10),
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      for (int i = 1; i <= 5; i++)
                        GestureDetector(
                          onTap: () => _rateDriver(i),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
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
                          color: i <= _rated ? Colors.amber : Colors.grey.shade300,
                          size: 24),
                    ]),
                    const SizedBox(width: 10),
                    Text('Thanks! 🙏',
                      style: GoogleFonts.poppins(
                        color: _green, fontSize: 13, fontWeight: FontWeight.w700)),
                  ]),
          ),
        ]),
      ),
      const SizedBox(height: 10),
      // Tip button
      OutlinedButton.icon(
        onPressed: () => Navigator.push(context, MaterialPageRoute(
          builder: (_) => TipDriverScreen(tripId: tId, driverName: dName))),
        icon: const Icon(Icons.volunteer_activism_rounded,
          color: Color(0xFF16A34A), size: 18),
        label: Text('Tip your Pilot',
          style: GoogleFonts.poppins(
            color: const Color(0xFF16A34A),
            fontWeight: FontWeight.w700, fontSize: 13)),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 46),
          side: const BorderSide(color: Color(0xFF16A34A), width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
      ),
      const SizedBox(height: 8),
      SizedBox(
        width: double.infinity,
        child: JT.gradientButton(
          label: 'Book Another Ride',
          onTap: () => Navigator.pushAndRemoveUntil(context,
            MaterialPageRoute(builder: (_) => const HomeScreen()), (_) => false),
        )),
    ]);
  }

  Widget _receiptRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.poppins(
            fontSize: 12, color: const Color(0xFF6B7280))),
          Text(value, style: GoogleFonts.poppins(
            fontSize: 12, fontWeight: FontWeight.w700,
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
        Text(label, style: GoogleFonts.poppins(
          fontSize: 11, fontWeight: FontWeight.w700, color: color)),
      ]),
    );
  }

  Widget _buildCancelledCard() {
    final noDriver = _lastAnnouncedStatus == 'cancelled' || _trip == null ||
        (_trip!['cancellationReason']?.toString().contains('no') == true);

    return Column(children: [
      // Status banner
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: noDriver
              ? const Color(0xFFFEF3C7)
              : Colors.red.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: noDriver ? const Color(0xFFFDE68A) : Colors.red.withValues(alpha: 0.15)),
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: noDriver
                  ? const Color(0xFFF59E0B).withValues(alpha: 0.15)
                  : Colors.red.withValues(alpha: 0.08),
              shape: BoxShape.circle),
            child: Icon(
              noDriver ? Icons.search_off_rounded : Icons.cancel_rounded,
              color: noDriver ? const Color(0xFFD97706) : const Color(0xFFEF4444),
              size: 24)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              noDriver ? 'No Pilots Available' : 'Trip Cancelled',
              style: GoogleFonts.poppins(
                color: noDriver ? const Color(0xFFB45309) : JT.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              noDriver
                  ? 'No pilots found nearby. You can retry or try later.'
                  : 'Sorry for the inconvenience.',
              style: GoogleFonts.poppins(
                color: JT.textSecondary, fontSize: 12, fontWeight: FontWeight.w500),
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
                gradient: const LinearGradient(
                  colors: [Color(0xFF1244A2), Color(0xFF2F7BFF)],
                  begin: Alignment.centerLeft, end: Alignment.centerRight),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(color: _blue.withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 4))
                ],
              ),
              child: Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.refresh_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 6),
                Text('Retry Booking',
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 14,
                    fontWeight: FontWeight.w800)),
              ])),
            ),
          ),
        ),
        const SizedBox(width: 10),
        // Home — go back to start
        Expanded(
          flex: 2,
          child: GestureDetector(
            onTap: () => Navigator.pushAndRemoveUntil(context,
              MaterialPageRoute(builder: (_) => const HomeScreen()), (_) => false),
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F7FF),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE8EFFF)),
              ),
              child: Center(child: Text('Go Home',
                style: GoogleFonts.poppins(color: JT.textSecondary, fontSize: 13,
                  fontWeight: FontWeight.w700))),
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
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
          child: const Icon(Icons.electric_bike_rounded, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Text('Pilot Found!', style: GoogleFonts.poppins(fontWeight: FontWeight.w800, fontSize: 14, color: Colors.white)),
          Text('Your pilot is on the way to you', style: GoogleFonts.poppins(fontSize: 11, color: Colors.white70)),
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
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
          child: const Icon(Icons.where_to_vote_rounded, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 12),
        const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Text('Pilot has arrived!', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Colors.white)),
          Text('Share your OTP to start the trip', style: TextStyle(fontSize: 11, color: Colors.white70)),
        ])),
      ]),
      backgroundColor: const Color(0xFF16A34A),
      duration: const Duration(seconds: 5),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
    ));
  }

  Map<String, dynamic> _getStatusInfo(String status) {
    switch (status) {
      case 'searching': return {'label': 'Searching for nearby Pilots...', 'icon': Icons.search_rounded, 'color': Colors.orange};
      case 'driver_assigned': return {'label': 'Pilot Assigned! 🎉', 'icon': Icons.electric_bike, 'color': _blue};
      case 'accepted': return {'label': 'Pilot is on the way 🏍️', 'icon': Icons.navigation_rounded, 'color': _blue};
      case 'arrived': return {'label': 'Pilot Arrived! 📍', 'icon': Icons.where_to_vote_rounded, 'color': _green};
      case 'in_progress': return {'label': 'Trip in Progress 🚀', 'icon': Icons.speed_rounded, 'color': _blue};
      case 'on_the_way': return {'label': 'Trip in Progress 🚀', 'icon': Icons.speed_rounded, 'color': _blue};
      case 'completed': return {'label': 'Trip Completed! ✅', 'icon': Icons.check_circle_rounded, 'color': _green};
      case 'cancelled': return {'label': 'Trip Cancelled', 'icon': Icons.cancel_rounded, 'color': Colors.red};
      default: return {'label': 'Loading...', 'icon': Icons.hourglass_empty_rounded, 'color': Colors.grey};
    }
  }
}
