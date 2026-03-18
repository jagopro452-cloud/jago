import 'dart:async';
import 'dart:convert';
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

class TripScreen extends StatefulWidget {
  final Map<String, dynamic>? trip;
  const TripScreen({super.key, this.trip});
  @override
  State<TripScreen> createState() => _TripScreenState();
}

class _TripScreenState extends State<TripScreen> {
    String _shortLocation(String value) {
      final v = value.trim();
      if (v.isEmpty) return v;
      return v.split(',').first.trim();
    }
  final SocketService _socket = SocketService();
  GoogleMapController? _mapController;
  LatLng _center = const LatLng(17.3850, 78.4867);
  String _status = 'accepted';
  Map<String, dynamic>? _trip;
  bool _loading = false;
  bool _nearPickup = false; // true when driver is within 100m of pickup
  final _otpCtrl = TextEditingController();
  Timer? _locationTimer;
  List<String> _cancelReasons = [];
  StreamSubscription? _cancelSub;
  StreamSubscription? _incomingCallSub;
  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _socket.connect(ApiConfig.socketUrl);
    _trip = widget.trip;
    if (_trip != null) {
      _status = _trip!['currentStatus'] ?? _trip!['status'] ?? 'accepted';
      final lat = double.tryParse(_trip!['pickupLat']?.toString() ?? '');
      final lng = double.tryParse(_trip!['pickupLng']?.toString() ?? '');
      if (lat != null && lng != null && lat != 0) _center = LatLng(lat, lng);
    }
    _startLocationUpdates();
    _loadCancelReasons();
    _listenForCancel();
    CallService().init();
    _listenForIncomingCalls();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initMapMarkers());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_status == 'accepted' || _status == 'driver_assigned') {
        _openNavigation();
      }
    });
  }

  void _listenForCancel() {
    _cancelSub = _socket.onTripCancelled.listen((data) {
      if (!mounted) return;
      _locationTimer?.cancel();
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

  @override
  void dispose() {
    _otpCtrl.dispose();
    _locationTimer?.cancel();
    _cancelSub?.cancel();
    _incomingCallSub?.cancel();
    super.dispose();
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

  void _startInAppCall(String contactName) {
    final customerId = _trip?['customerId']?.toString() ?? _trip?['customer_id']?.toString();
    final tripId = _trip?['id']?.toString() ?? _trip?['tripId']?.toString() ?? '';
    if (customerId == null || customerId.isEmpty) return;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => CallScreen(
        contactName: contactName,
        tripId: tripId,
        targetUserId: customerId,
      ),
    ));
  }

  void _openTripChat() {
    final tripId = _trip?['id']?.toString() ?? _trip?['tripId']?.toString() ?? '';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TripChatSheet(
        tripId: tripId,
        senderName: 'Driver',
      ),
    );
  }

  void _startLocationUpdates() {
    _locationTimer = Timer.periodic(const Duration(seconds: 3), (_) => _updateLocation());
  }

  void _initMapMarkers() {
    if (!mounted || _trip == null) return;
    final pickupLat = double.tryParse(_trip!['pickupLat']?.toString() ?? _trip!['pickup_lat']?.toString() ?? '');
    final pickupLng = double.tryParse(_trip!['pickupLng']?.toString() ?? _trip!['pickup_lng']?.toString() ?? '');
    final destLat = double.tryParse(_trip!['destinationLat']?.toString() ?? _trip!['destination_lat']?.toString() ?? '');
    final destLng = double.tryParse(_trip!['destinationLng']?.toString() ?? _trip!['destination_lng']?.toString() ?? '');
    setState(() {
      _markers.clear();
      if (pickupLat != null && pickupLat != 0 && pickupLng != null) {
        _markers.add(Marker(
          markerId: const MarkerId('pickup'),
          position: LatLng(pickupLat, pickupLng),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: const InfoWindow(title: 'Customer Pickup'),
        ));
      }
      if (destLat != null && destLat != 0 && destLng != null) {
        _markers.add(Marker(
          markerId: const MarkerId('destination'),
          position: LatLng(destLat, destLng),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(title: 'Destination'),
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
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: const InfoWindow(title: 'You'),
        zIndex: 2,
      ));
    });
  }

  Future<void> _updateLocation() async {
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
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

      // 100m arrival detection — auto-enable "Arrived" button when near pickup
      if (_status == 'accepted' || _status == 'driver_assigned') {
        final pickupLat = double.tryParse(_trip?['pickupLat']?.toString() ?? _trip?['pickup_lat']?.toString() ?? '');
        final pickupLng = double.tryParse(_trip?['pickupLng']?.toString() ?? _trip?['pickup_lng']?.toString() ?? '');
        if (pickupLat != null && pickupLng != null && pickupLat != 0) {
          final dist = Geolocator.distanceBetween(lat, lng, pickupLat, pickupLng);
          if (mounted && dist <= 100 && !_nearPickup) {
            setState(() => _nearPickup = true);
            _showSnack('You are near the pickup location!');
          } else if (mounted && dist > 100 && _nearPickup) {
            setState(() => _nearPickup = false);
          }
        }
      }
    } catch (_) {}
  }

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

  Future<void> _nextStep() async {
    if (_status == 'arrived') {
      _showOtpDialog();
      return;
    }
    setState(() => _loading = true);
    final stepHeaders = await AuthService.getHeaders();
    final tripId = _trip?['id'] ?? _trip?['tripId'] ?? '';

    try {
      if (_status == 'accepted') {
        final res = await http.post(Uri.parse(ApiConfig.driverArrived),
          headers: {...stepHeaders, 'Content-Type': 'application/json'},
          body: jsonEncode({'tripId': tripId}));
        if (!mounted) return;
        if (res.statusCode == 200) {
          _socket.updateTripStatus(tripId, 'arrived');
          setState(() => _status = 'arrived');
        } else {
          _showSnack(jsonDecode(res.body)['message'] ?? 'Error', error: true);
        }
      } else if (_status == 'in_progress' || _status == 'on_the_way') {
        await _completeTrip(stepHeaders);
        return;
      }
    } catch (_) {
      if (!mounted) return;
      _showSnack('Network error. Try again.', error: true);
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _completeTrip(Map<String, String> authHeaders) async {
    final tripId = _trip?['id'] ?? _trip?['tripId'] ?? '';
    final estimatedFare = _trip?['estimatedFare'] ?? _trip?['estimated_fare'] ?? 0.0;
    final estimatedDistance = _trip?['estimatedDistance'] ?? _trip?['estimated_distance'] ?? 0.0;
    try {
      final res = await http.post(Uri.parse(ApiConfig.driverCompleteTrip),
        headers: {...authHeaders, 'Content-Type': 'application/json'},
        body: jsonEncode({'tripId': tripId, 'actualFare': estimatedFare, 'actualDistance': estimatedDistance}));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final pricing = data['pricing'] as Map<String, dynamic>? ?? {};
        final rideFare = pricing['rideFare'] ?? data['trip']?['actualFare'] ?? data['trip']?['actual_fare'] ?? estimatedFare;
        final driverEarnings = pricing['driverWalletCredit'] ?? rideFare;
        final commission = pricing['platformDeduction'] ?? 0;
        _socket.updateTripStatus(tripId, 'completed');
        _locationTimer?.cancel();
        if (!mounted) return;
        _showCompletionDialog(
          rideFare.toString(),
          driverEarnings: driverEarnings.toString(),
          commission: commission.toString(),
        );
      } else {
        final err = jsonDecode(res.body);
        if (!mounted) return;
        _showSnack(err['message'] ?? 'Error completing trip', error: true);
        setState(() => _loading = false);
      }
    } catch (_) {
      if (!mounted) return;
      _showSnack('Network error. Try again.', error: true);
      setState(() => _loading = false);
    }
  }

  void _showSnack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
      backgroundColor: error ? JT.error : JT.primary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  void _showCompletionDialog(String fare, {String driverEarnings = '0', String commission = '0'}) {
    int selectedRating = 0;
    bool ratingSubmitted = false;
    final tripId = _trip?['id'] ?? _trip?['tripId'] ?? '';
    final pm = _trip?['paymentMethod'] ?? _trip?['payment_method'] ?? 'cash';
    final isCash = pm == 'cash';
    final netEarnings = double.tryParse(driverEarnings) ?? 0.0;
    final commissionAmt = double.tryParse(commission) ?? 0.0;
    final fullFare = double.tryParse(fare) ?? 0.0;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => Dialog(
          backgroundColor: JT.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 72, height: 72,
                decoration: BoxDecoration(
                  color: JT.success.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                  border: Border.all(color: JT.success.withValues(alpha: 0.3), width: 2),
                ),
                child: const Icon(Icons.check_rounded, color: JT.success, size: 40)),
              const SizedBox(height: 16),
              Text('Trip Complete!',
                style: GoogleFonts.poppins(color: JT.textPrimary, fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              // Fare breakdown card
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: JT.bgSoft,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: JT.border),
                ),
                child: Column(children: [
                  Text('₹${netEarnings.toStringAsFixed(0)}',
                    style: GoogleFonts.poppins(color: JT.primary, fontSize: 40, fontWeight: FontWeight.w900)),
                  Text('Your Earnings',
                    style: GoogleFonts.poppins(color: JT.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
                  if (commissionAmt > 0) ...[
                    const SizedBox(height: 12),
                    Container(height: 1, color: JT.border),
                    const SizedBox(height: 10),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text('Trip Fare', style: GoogleFonts.poppins(color: JT.textSecondary, fontSize: 13)),
                      Text('₹${fullFare.toStringAsFixed(0)}', style: GoogleFonts.poppins(color: JT.textSecondary, fontSize: 13)),
                    ]),
                    const SizedBox(height: 4),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text('Platform Fee', style: GoogleFonts.poppins(color: JT.textSecondary, fontSize: 12)),
                      Text('- ₹${commissionAmt.toStringAsFixed(0)}',
                        style: GoogleFonts.poppins(color: JT.error, fontSize: 12)),
                    ]),
                  ],
                ]),
              ),
              const SizedBox(height: 12),
              if (isCash) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: JT.grad,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: JT.btnShadow,
                  ),
                  child: Row(children: [
                    const Icon(Icons.payments_rounded, color: Colors.white, size: 28),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('COLLECT ₹${fullFare.toStringAsFixed(0)} CASH',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
                      Text('Commission ₹${commissionAmt.toStringAsFixed(0)} deducted from wallet',
                        style: const TextStyle(color: Colors.white70, fontSize: 11)),
                    ])),
                  ]),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: JT.surfaceAlt,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: JT.border),
                  ),
                  child: Row(children: [
                    const Icon(Icons.account_balance_wallet_rounded, color: JT.primary, size: 24),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('₹${netEarnings.toStringAsFixed(0)} Wallet ki Credit Aindi!',
                        style: GoogleFonts.poppins(color: JT.primary, fontWeight: FontWeight.w700, fontSize: 13)),
                      Text(pm == 'wallet' ? 'Customer wallet deducted automatically' : 'Customer already paid online',
                        style: GoogleFonts.poppins(color: JT.textSecondary, fontSize: 11)),
                    ])),
                  ]),
                ),
              ],
              const SizedBox(height: 20),
              // Rate customer section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: JT.bgSoft,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: JT.border),
                ),
                child: ratingSubmitted
                    ? Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                        const SizedBox(width: 6),
                        Text('Rating submitted! Thanks',
                          style: GoogleFonts.poppins(color: JT.textSecondary, fontSize: 13)),
                      ])
                    : Column(children: [
                        Text('Customer ki Rating ivvandi',
                          style: GoogleFonts.poppins(color: JT.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 10),
                        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          for (int i = 1; i <= 5; i++)
                            GestureDetector(
                              onTap: () async {
                                setStateDialog(() => selectedRating = i);
                                final rateHeaders = await AuthService.getHeaders();
                                try {
                                  await http.post(Uri.parse(ApiConfig.driverRateCustomer),
                                    headers: {...rateHeaders, 'Content-Type': 'application/json'},
                                    body: jsonEncode({'tripId': tripId, 'rating': i}));
                                } catch (_) {}
                                setStateDialog(() => ratingSubmitted = true);
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: Icon(
                                  i <= selectedRating ? Icons.star_rounded : Icons.star_border_rounded,
                                  color: Colors.amber, size: 36),
                              ),
                            ),
                        ]),
                      ]),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity, height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: JT.primary, foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0),
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pushAndRemoveUntil(context,
                      MaterialPageRoute(builder: (_) => const HomeScreen()), (_) => false);
                  },
                  child: Text('Go Home →',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w800, fontSize: 15))),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  void _showOtpDialog() {
    _otpCtrl.clear();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: JT.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: JT.surfaceAlt, shape: BoxShape.circle),
              child: const Icon(Icons.lock_open_rounded, color: JT.primary, size: 32)),
            const SizedBox(height: 16),
            Text('Customer OTP',
              style: GoogleFonts.poppins(color: JT.textPrimary, fontWeight: FontWeight.w800, fontSize: 18)),
            const SizedBox(height: 4),
            Text('Ask customer for OTP from their JAGO app',
              style: GoogleFonts.poppins(color: JT.textSecondary, fontSize: 13), textAlign: TextAlign.center),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                color: JT.bgSoft,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: JT.border),
              ),
              child: TextField(
                controller: _otpCtrl,
                keyboardType: TextInputType.number,
                maxLength: 6,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(color: JT.textPrimary, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 10),
                decoration: InputDecoration(
                  counterText: '',
                  hintText: '------',
                  hintStyle: GoogleFonts.poppins(color: JT.iconInactive, letterSpacing: 10, fontSize: 24),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: TextButton(
                onPressed: () => Navigator.pop(ctx),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('Cancel',
                  style: GoogleFonts.poppins(color: JT.textSecondary, fontWeight: FontWeight.w600)))),
              const SizedBox(width: 12),
              Expanded(child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: JT.primary, foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14), elevation: 0),
                onPressed: () async {
                  final otp = _otpCtrl.text.trim();
                  if (otp.isEmpty) return;
                  Navigator.pop(ctx);
                  await _verifyOtpAndStart(otp);
                },
                child: Text('Verify ✓',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w800)))),
            ]),
          ]),
        ),
      ),
    );
  }

  Future<void> _verifyOtpAndStart(String otp) async {
    setState(() => _loading = true);
    final otpHeaders = await AuthService.getHeaders();
    final tripId = _trip?['id'] ?? _trip?['tripId'] ?? '';
    try {
      final res = await http.post(Uri.parse(ApiConfig.driverVerifyOtp),
        headers: {...otpHeaders, 'Content-Type': 'application/json'},
        body: jsonEncode({'tripId': tripId, 'otp': otp}));
      if (res.statusCode == 200) {
        _socket.updateTripStatus(tripId, 'on_the_way', otp: otp);
        if (!mounted) return;
        setState(() { _status = 'in_progress'; _loading = false; });
        final destLat = (_trip?['destinationLat'] as num?)?.toDouble();
        final destLng = (_trip?['destinationLng'] as num?)?.toDouble();
        if (destLat != null && destLng != null && destLat != 0) {
          _mapController?.animateCamera(CameraUpdate.newLatLng(LatLng(destLat, destLng)));
        }
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
              color: JT.surfaceAlt,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: JT.border),
            ),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: JT.primary.withValues(alpha: 0.10), shape: BoxShape.circle),
                child: const Icon(Icons.camera_alt_rounded, color: JT.primary, size: 26)),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Pickup Location Photo',
                  style: GoogleFonts.poppins(color: JT.textPrimary, fontWeight: FontWeight.w800, fontSize: 15)),
                const SizedBox(height: 4),
                Text('Capture a photo at the pickup point for ride security.',
                  style: GoogleFonts.poppins(color: JT.textSecondary, fontSize: 12)),
              ])),
            ]),
          ),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: JT.textSecondary,
                  side: BorderSide(color: JT.border),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () => Navigator.pop(context),
                child: Text('Skip', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: JT.primary, foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14), elevation: 0),
                icon: const Icon(Icons.camera_alt_rounded, size: 18),
                label: Text('Take Photo', style: GoogleFonts.poppins(fontWeight: FontWeight.w800)),
                onPressed: () {
                  Navigator.pop(context);
                  _captureAndUploadPickupPhoto(tripId);
                },
              ),
            ),
          ]),
        ]),
      ),
    );
  }

  Future<void> _captureAndUploadPickupPhoto(String tripId) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
        maxWidth: 1280,
      );
      if (picked == null || !mounted) return;
      _showSnack('Uploading pickup photo…');
      final photoHeaders = await AuthService.getHeaders();
      final req = http.MultipartRequest('POST', Uri.parse(ApiConfig.tripPhoto));
      req.headers.addAll(photoHeaders);
      req.fields['tripId'] = tripId;
      req.files.add(await http.MultipartFile.fromPath('photo', picked.path));
      final response = await req.send();
      if (response.statusCode == 200 && mounted) {
        _showSnack('Pickup photo saved ✓');
      }
    } catch (_) {}
  }

  void _showCancelDialog() {
    final reasons = _cancelReasons.isNotEmpty ? _cancelReasons : [
      'Customer not at pickup location',
      'Customer is not responding',
      'Vehicle breakdown',
      'Customer requested to cancel',
      'Other reason',
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
          const SizedBox(height: 20),
          Row(children: [
            Container(padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: JT.error.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.cancel_rounded, color: JT.error, size: 20)),
            const SizedBox(width: 12),
            Text('Cancel Reason',
              style: GoogleFonts.poppins(color: JT.textPrimary, fontSize: 17, fontWeight: FontWeight.w800)),
          ]),
          const SizedBox(height: 16),
          ...reasons.map((r) => ListTile(
            title: Text(r, style: GoogleFonts.poppins(color: JT.textPrimary, fontSize: 13)),
            leading: const Icon(Icons.chevron_right_rounded, color: JT.iconInactive, size: 18),
            contentPadding: EdgeInsets.zero,
            dense: true,
            onTap: () { Navigator.pop(context); _cancelTrip(r); },
          )),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  Future<void> _cancelTrip(String reason) async {
    setState(() => _loading = true);
    final cancelHeaders = await AuthService.getHeaders();
    final tripId = _trip?['id'] ?? _trip?['tripId'] ?? '';
    _socket.updateTripStatus(tripId, 'cancelled');
    try {
      await http.post(Uri.parse(ApiConfig.driverCancelTrip),
        headers: {...cancelHeaders, 'Content-Type': 'application/json'},
        body: jsonEncode({'tripId': tripId, 'reason': reason}));
    } catch (_) {}
    _locationTimer?.cancel();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(context,
      MaterialPageRoute(builder: (_) => const HomeScreen()), (_) => false);
  }

  void _showDeliveryOtpDialog() {
    final deliveryOtpCtrl = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: JT.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: JT.warning.withValues(alpha: 0.10), shape: BoxShape.circle),
              child: const Icon(Icons.local_shipping_rounded, color: JT.warning, size: 32)),
            const SizedBox(height: 16),
            Text('Delivery OTP',
              style: GoogleFonts.poppins(color: JT.textPrimary, fontWeight: FontWeight.w800, fontSize: 18)),
            const SizedBox(height: 4),
            Text('Ask receiver for OTP to confirm delivery',
              style: GoogleFonts.poppins(color: JT.textSecondary, fontSize: 13), textAlign: TextAlign.center),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                color: JT.bgSoft,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: JT.warning.withValues(alpha: 0.3)),
              ),
              child: TextField(
                controller: deliveryOtpCtrl,
                keyboardType: TextInputType.number,
                maxLength: 6,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(color: JT.textPrimary, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 10),
                decoration: InputDecoration(
                  counterText: '',
                  hintText: '------',
                  hintStyle: GoogleFonts.poppins(color: JT.iconInactive, letterSpacing: 10, fontSize: 24),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: TextButton(
                onPressed: () => Navigator.pop(ctx),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('Cancel',
                  style: GoogleFonts.poppins(color: JT.textSecondary, fontWeight: FontWeight.w600)))),
              const SizedBox(width: 12),
              Expanded(child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: JT.warning, foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14), elevation: 0),
                onPressed: () async {
                  final otp = deliveryOtpCtrl.text.trim();
                  if (otp.isEmpty) return;
                  Navigator.pop(ctx);
                  await _verifyDeliveryOtp(otp);
                },
                child: Text('Verify ✓',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w800)))),
            ]),
          ]),
        ),
      ),
    ).then((_) => deliveryOtpCtrl.dispose());
  }

  Future<void> _verifyDeliveryOtp(String otp) async {
    setState(() => _loading = true);
    final delivOtpHeaders = await AuthService.getHeaders();
    final tripId = _trip?['id'] ?? _trip?['tripId'] ?? '';
    try {
      final res = await http.post(Uri.parse(ApiConfig.verifyDeliveryOtp),
        headers: {...delivOtpHeaders, 'Content-Type': 'application/json'},
        body: jsonEncode({'tripId': tripId, 'otp': otp}));
      if (res.statusCode == 200) {
        if (!mounted) return;
        _showSnack('Delivery verified! You can now complete the trip.');
      } else {
        final err = jsonDecode(res.body);
        if (!mounted) return;
        _showSnack(err['message'] ?? 'Wrong delivery OTP', error: true);
      }
    } catch (_) {
      if (!mounted) return;
      _showSnack('Network error. Try again.', error: true);
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final step = _getStep(_status);
    final customerName = _trip?['customerName'] ?? _trip?['customer_name'] ?? 'Customer';
    final customerPhone = _trip?['customerPhone'] ?? _trip?['customer_phone'];
    final estimatedFare = _trip?['estimatedFare'] ?? _trip?['estimated_fare'] ?? '--';
    final estimatedDistance = _trip?['estimatedDistance'] ?? _trip?['estimated_distance'] ?? '--';
    final pickupAddress = _shortLocation((_trip?['pickupShortName'] ?? _trip?['pickupAddress'] ?? _trip?['pickup_address'] ?? 'Pickup').toString());
    final destAddress = _shortLocation((_trip?['destinationShortName'] ?? _trip?['destinationAddress'] ?? _trip?['destination_address'] ?? 'Destination').toString());
    final isForSomeoneElse = _trip?['isForSomeoneElse'] == true || _trip?['is_for_someone_else'] == true;
    final passengerName = _trip?['passengerName'] ?? _trip?['passenger_name'] ?? '';
    final passengerPhone = _trip?['passengerPhone'] ?? _trip?['passenger_phone'];

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: JT.bg,
        body: Stack(children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: _center, zoom: 15),
            onMapCreated: (c) {
              _mapController = c;
              c.animateCamera(CameraUpdate.newLatLng(_center));
              _initMapMarkers();
            },
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
          ),
          // White floating status bar at top
          Positioned(
            top: 0, left: 0, right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: _buildFloatingStatusBar(step, pickupAddress, destAddress),
              ),
            ),
          ),
          // White bottom sheet
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: JT.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.10), blurRadius: 24)],
              ),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 44, height: 4,
                  margin: const EdgeInsets.only(top: 10, bottom: 4),
                  decoration: BoxDecoration(
                    color: JT.border,
                    borderRadius: BorderRadius.circular(2))),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    _buildCustomerCard(customerName, customerPhone, estimatedFare, estimatedDistance),
                    if (isForSomeoneElse && passengerName.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      _buildPassengerCard(passengerName, passengerPhone),
                    ],
                    if (_trip?['notes']?.toString().startsWith('📦 Parcel') == true) ...[
                      const SizedBox(height: 10),
                      _buildParcelCard(_trip!['notes'].toString()),
                    ],
                    const SizedBox(height: 12),
                    _buildPaymentBadge(),
                    if ((_status == 'in_progress' || _status == 'on_the_way') &&
                        _trip?['notes']?.toString().startsWith('📦 Parcel') == true) ...[
                      const SizedBox(height: 8),
                      _buildDeliveryOtpButton(),
                    ],
                    _buildActionBtn(step),
                    const SizedBox(height: 10),
                    _buildSecondaryActions(customerPhone),
                  ]),
                ),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildFloatingStatusBar(Map<String, dynamic> step, String pickup, String dest) {
    final isOnTheWay = _status == 'in_progress' || _status == 'on_the_way';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: JT.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: JT.border),
        boxShadow: JT.cardShadow,
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isOnTheWay ? JT.success.withValues(alpha: 0.10) : JT.surfaceAlt,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: isOnTheWay ? JT.success.withValues(alpha: 0.25) : JT.border),
          ),
          child: Icon(step['icon'] as IconData,
            color: isOnTheWay ? JT.success : JT.primary, size: 24)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(step['label'] as String,
            style: GoogleFonts.poppins(
              color: isOnTheWay ? JT.success : JT.primary,
              fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
          const SizedBox(height: 3),
          Text(
            _status == 'accepted' ? pickup : dest,
            style: GoogleFonts.poppins(color: JT.textSecondary, fontSize: 11),
            maxLines: 1, overflow: TextOverflow.ellipsis),
        ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: JT.success.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 6, height: 6,
              decoration: const BoxDecoration(color: JT.success, shape: BoxShape.circle)),
            const SizedBox(width: 4),
            Text('LIVE', style: GoogleFonts.poppins(color: JT.success, fontSize: 9, fontWeight: FontWeight.w800)),
          ]),
        ),
      ]),
    );
  }

  Widget _buildParcelCard(String notes) {
    String receiver = '';
    String category = '';
    String weight = '';
    String instructions = '';
    for (final part in notes.split(' | ')) {
      if (part.startsWith('Category:')) category = part.replaceFirst('Category: ', '');
      if (part.startsWith('Weight:')) weight = part.replaceFirst('Weight: ', '');
      if (part.startsWith('Receiver:')) receiver = part.replaceFirst('Receiver: ', '');
      if (part.startsWith('Instructions:') && !part.contains('None')) {
        instructions = part.replaceFirst('Instructions: ', '');
      }
    }
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: JT.warning.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: JT.warning.withValues(alpha: 0.25), width: 1),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('📦', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Text('PARCEL DELIVERY',
            style: GoogleFonts.poppins(color: JT.warning, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1)),
        ]),
        const SizedBox(height: 10),
        if (receiver.isNotEmpty) Row(children: [
          const Icon(Icons.person_rounded, color: JT.warning, size: 15),
          const SizedBox(width: 6),
          Expanded(child: Text(receiver,
            style: GoogleFonts.poppins(color: JT.textSecondary, fontSize: 12, fontWeight: FontWeight.w600))),
        ]),
        if (category.isNotEmpty) ...[
          const SizedBox(height: 4),
          Row(children: [
            const Icon(Icons.category_rounded, color: JT.warning, size: 15),
            const SizedBox(width: 6),
            Text('$category  •  $weight',
              style: GoogleFonts.poppins(color: JT.textSecondary, fontSize: 12)),
          ]),
        ],
        if (instructions.isNotEmpty) ...[
          const SizedBox(height: 4),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.info_outline_rounded, color: JT.warning, size: 15),
            const SizedBox(width: 6),
            Expanded(child: Text(instructions,
              style: GoogleFonts.poppins(color: JT.textSecondary, fontSize: 11))),
          ]),
        ],
      ]),
    );
  }

  Widget _buildPassengerCard(String passengerName, String? passengerPhone) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: JT.surfaceAlt,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: JT.border, width: 1),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: JT.primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.person_pin_rounded, color: JT.primary, size: 18)),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('PASSENGER',
            style: GoogleFonts.poppins(color: JT.primary, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1)),
          const SizedBox(height: 2),
          Text(passengerName,
            style: GoogleFonts.poppins(color: JT.textPrimary, fontSize: 13, fontWeight: FontWeight.w700)),
          if (passengerPhone != null && passengerPhone.isNotEmpty) ...[
            const SizedBox(height: 1),
            Text(passengerPhone,
              style: GoogleFonts.poppins(color: JT.textSecondary, fontSize: 11)),
          ],
        ])),
        if (passengerPhone != null && passengerPhone.isNotEmpty)
          GestureDetector(
            onTap: () {
              final customerId = _trip?['customerId']?.toString() ?? _trip?['customer_id']?.toString();
              final tripId = _trip?['id']?.toString() ?? _trip?['tripId']?.toString() ?? '';
              if (customerId == null || customerId.isEmpty) return;
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => CallScreen(
                  contactName: passengerName,
                  tripId: tripId,
                  targetUserId: customerId,
                ),
              ));
            },
            child: Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                color: JT.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.phone_rounded, color: JT.primary, size: 17)),
          ),
      ]),
    );
  }

  Widget _buildDeliveryOtpButton() {
    return GestureDetector(
      onTap: _showDeliveryOtpDialog,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        margin: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          color: JT.warning.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: JT.warning.withValues(alpha: 0.3)),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.lock_open_rounded, color: JT.warning, size: 18),
          const SizedBox(width: 8),
          Text('Verify Delivery OTP',
            style: GoogleFonts.poppins(color: JT.warning, fontSize: 14, fontWeight: FontWeight.w800)),
        ]),
      ),
    );
  }

  Widget _buildPaymentBadge() {
    final pm = _trip?['paymentMethod'] ?? _trip?['payment_method'] ?? 'cash';
    final isCash = pm == 'cash';
    final isWallet = pm == 'wallet';
    final isOnline = pm == 'online' || pm == 'upi' || pm == 'razorpay';
    final isCompleting = _status == 'in_progress' || _status == 'on_the_way';

    if (isCash && isCompleting) {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: JT.grad,
          borderRadius: BorderRadius.circular(16),
          boxShadow: JT.btnShadow,
        ),
        child: Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.payments_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('COLLECT CASH',
              style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1)),
            SizedBox(height: 2),
            Text('Trip ending. Please collect cash from customer.',
              style: TextStyle(color: Colors.white70, fontSize: 11)),
          ])),
        ]),
      );
    }
    if (isCash) {
      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: JT.success.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: JT.success.withValues(alpha: 0.20)),
        ),
        child: const Row(children: [
          Icon(Icons.payments_rounded, color: JT.success, size: 16),
          SizedBox(width: 8),
          Text('Cash Payment — Collect at trip end',
            style: TextStyle(color: JT.success, fontSize: 12, fontWeight: FontWeight.w600)),
        ]),
      );
    }
    if (isWallet) {
      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: JT.primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: JT.border),
        ),
        child: Row(children: [
          const Icon(Icons.account_balance_wallet_rounded, color: JT.primary, size: 16),
          const SizedBox(width: 8),
          Text('Wallet Payment — Auto deducted from customer',
            style: GoogleFonts.poppins(color: JT.primary, fontSize: 12, fontWeight: FontWeight.w600)),
        ]),
      );
    }
    if (isOnline) {
      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: JT.surfaceAlt,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: JT.border),
        ),
        child: Row(children: [
          const Icon(Icons.qr_code_scanner_rounded, color: JT.secondary, size: 16),
          const SizedBox(width: 8),
          Text('Online Payment — Already paid via UPI/Razorpay',
            style: GoogleFonts.poppins(color: JT.secondary, fontSize: 12, fontWeight: FontWeight.w600)),
        ]),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildCustomerCard(String name, String? phone, dynamic fare, dynamic dist) {
    final pm = _trip?['paymentMethod'] ?? _trip?['payment_method'] ?? 'cash';
    final pmLabel = pm == 'wallet' ? 'Wallet' : pm == 'upi' || pm == 'online' || pm == 'razorpay' ? 'UPI' : 'Cash';
    final pmColor = pm == 'wallet' ? JT.primary : pm == 'upi' || pm == 'online' || pm == 'razorpay' ? JT.secondary : JT.success;
    final fareVal = double.tryParse(fare?.toString() ?? '0') ?? 0;

    return Container(
      decoration: BoxDecoration(
        color: JT.bgSoft,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: JT.border),
      ),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Container(
              width: 46, height: 46,
              decoration: BoxDecoration(
                gradient: JT.grad,
                borderRadius: BorderRadius.circular(15),
                boxShadow: JT.btnShadow,
              ),
              child: Center(child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'C',
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900))),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name,
                style: GoogleFonts.poppins(color: JT.textPrimary, fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: -0.3),
                maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Text(pmLabel,
                style: GoogleFonts.poppins(color: pmColor, fontSize: 12, fontWeight: FontWeight.w700)),
            ])),
            if (phone != null)
              GestureDetector(
                onTap: () => _startInAppCall(name),
                child: Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    gradient: JT.grad,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: JT.btnShadow,
                  ),
                  child: const Icon(Icons.phone_rounded, color: Colors.white, size: 20)),
              ),
          ]),
        ),
        Container(height: 1, color: JT.border),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(children: [
            Expanded(child: _statPill('Fare', fareVal > 0 ? '₹${fareVal.toInt()}' : '₹$fare', JT.success)),
            const SizedBox(width: 8),
            Expanded(child: _statPill('Distance', '$dist km', JT.primary)),
            const SizedBox(width: 8),
            Expanded(child: _statPill('Pay', pmLabel, pmColor)),
          ]),
        ),
      ]),
    );
  }

  Widget _statPill(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(children: [
        Text(value,
          style: GoogleFonts.poppins(color: color, fontSize: 13, fontWeight: FontWeight.w900)),
        const SizedBox(height: 2),
        Text(label,
          style: GoogleFonts.poppins(color: JT.textSecondary, fontSize: 9, fontWeight: FontWeight.w600)),
      ]),
    );
  }

  Widget _buildActionBtn(Map<String, dynamic> step) {
    final isComplete = _status == 'in_progress' || _status == 'on_the_way';
    final isArriveStep = _status == 'accepted' || _status == 'driver_assigned';
    final showNearGlow = isArriveStep && _nearPickup;
    return Column(
      children: [
        if (showNearGlow) ...[
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: JT.success.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: JT.success.withValues(alpha: 0.4)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 8, height: 8,
                decoration: const BoxDecoration(color: JT.success, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Text('You are near the pickup — tap Arrived',
                style: GoogleFonts.poppins(color: JT.success, fontSize: 12, fontWeight: FontWeight.w700)),
            ]),
          ),
        ],
        GestureDetector(
          onTap: _loading ? null : _nextStep,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: double.infinity, height: 60,
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              gradient: isComplete
                  ? const LinearGradient(
                      colors: [JT.success, Color(0xFF15803D)],
                      begin: Alignment.centerLeft, end: Alignment.centerRight)
                  : JT.grad,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: (showNearGlow ? JT.success : isComplete ? JT.success : JT.primary).withValues(alpha: showNearGlow ? 0.55 : 0.35),
                  blurRadius: showNearGlow ? 28 : 20, offset: const Offset(0, 6)),
              ],
              border: showNearGlow ? Border.all(color: JT.success, width: 2) : null,
            ),
            child: Center(
              child: _loading
                ? Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const SizedBox(width: 22, height: 22,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)),
                    const SizedBox(width: 12),
                    const Text('Please wait...', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                  ])
                : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
                      child: Icon(step['icon'] as IconData, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Text(step['action'] as String,
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: -0.2)),
                  ]),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _triggerSos() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: JT.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('SOS Alert',
          style: GoogleFonts.poppins(color: JT.textPrimary, fontWeight: FontWeight.bold)),
        content: Text('Emergency SOS send చేయాలా? Help team contact అవుతారు.',
          style: GoogleFonts.poppins(color: JT.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.poppins(color: JT.textSecondary))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: JT.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('SOS పంపు', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
        ],
      ),
    );
    if (confirm != true) return;
    final sosHeaders = await AuthService.getHeaders();
    final tripId = _trip?['id'] ?? _trip?['tripId'] ?? '';
    try {
      await http.post(Uri.parse(ApiConfig.sos),
        headers: {...sosHeaders, 'Content-Type': 'application/json'},
        body: jsonEncode({'tripId': tripId, 'lat': _center.latitude, 'lng': _center.longitude, 'message': 'Driver SOS alert during trip'}));
      if (!mounted) return;
      _showSnack('SOS Alert sent! Help is on the way.');
    } catch (_) {
      if (!mounted) return;
      _showSnack('SOS send failed. Call 100 immediately!', error: true);
    }
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

  Widget _buildSecondaryActions(String? phone) {
    return Wrap(alignment: WrapAlignment.center, spacing: 8, runSpacing: 8, children: [
      if (phone != null)
        GestureDetector(
          onTap: () {
            final customerName = _trip?['customerName'] ?? _trip?['customer_name'] ?? 'Customer';
            _startInAppCall(customerName.toString());
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: JT.surfaceAlt,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: JT.border),
            ),
            child: Row(children: [
              const Icon(Icons.phone_rounded, color: JT.primary, size: 16),
              const SizedBox(width: 6),
              Text('Call', style: GoogleFonts.poppins(color: JT.primary, fontSize: 13, fontWeight: FontWeight.w700)),
            ]),
          ),
        ),
      GestureDetector(
        onTap: _openTripChat,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: JT.surfaceAlt,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: JT.border),
          ),
          child: Row(children: [
            const Icon(Icons.chat_rounded, color: JT.primary, size: 16),
            const SizedBox(width: 6),
            Text('Chat', style: GoogleFonts.poppins(color: JT.primary, fontSize: 13, fontWeight: FontWeight.w700)),
          ]),
        ),
      ),
      GestureDetector(
        onTap: _triggerSos,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: JT.error.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: JT.error.withValues(alpha: 0.25)),
          ),
          child: Row(children: [
            const Icon(Icons.sos_rounded, color: JT.error, size: 16),
            const SizedBox(width: 6),
            Text('SOS', style: GoogleFonts.poppins(color: JT.error, fontSize: 12, fontWeight: FontWeight.w800)),
          ]),
        ),
      ),
      GestureDetector(
        onTap: _openNavigation,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: JT.surfaceAlt,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: JT.border),
          ),
          child: Row(children: [
            const Icon(Icons.navigation_rounded, color: JT.primary, size: 16),
            const SizedBox(width: 6),
            Text('Navigate', style: GoogleFonts.poppins(color: JT.primary, fontSize: 12, fontWeight: FontWeight.w700)),
          ]),
        ),
      ),
      GestureDetector(
        onTap: _showCancelDialog,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: JT.warning.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: JT.warning.withValues(alpha: 0.2)),
          ),
          child: Row(children: [
            const Icon(Icons.cancel_rounded, color: JT.warning, size: 16),
            const SizedBox(width: 6),
            Text('Cancel', style: GoogleFonts.poppins(color: JT.warning, fontSize: 12, fontWeight: FontWeight.w700)),
          ]),
        ),
      ),
      GestureDetector(
        onTap: () async {
          final phone = await _getSupportPhone();
          final uri = Uri(scheme: 'tel', path: phone);
          if (await canLaunchUrl(uri)) await launchUrl(uri);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: JT.success.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: JT.success.withValues(alpha: 0.20)),
          ),
          child: Row(children: [
            const Icon(Icons.phone_in_talk_rounded, color: JT.success, size: 16),
            const SizedBox(width: 6),
            Text('Support', style: GoogleFonts.poppins(color: JT.success, fontSize: 12, fontWeight: FontWeight.w700)),
          ]),
        ),
      ),
    ]);
  }

  Future<void> _openNavigation() async {
    final toPickup = _status == 'accepted' || _status == 'driver_assigned';
    final targetLat = toPickup
      ? (double.tryParse(_trip?['pickupLat']?.toString() ?? '') ?? double.tryParse(_trip?['pickup_lat']?.toString() ?? '') ?? 0.0)
      : (double.tryParse(_trip?['destinationLat']?.toString() ?? '') ?? double.tryParse(_trip?['destination_lat']?.toString() ?? '') ?? 0.0);
    final targetLng = toPickup
      ? (double.tryParse(_trip?['pickupLng']?.toString() ?? '') ?? double.tryParse(_trip?['pickup_lng']?.toString() ?? '') ?? 0.0)
      : (double.tryParse(_trip?['destinationLng']?.toString() ?? '') ?? double.tryParse(_trip?['destination_lng']?.toString() ?? '') ?? 0.0);
    final targetAddress = toPickup
      ? _shortLocation((_trip?['pickupShortName']?.toString() ?? _trip?['pickupAddress']?.toString() ?? _trip?['pickup_address']?.toString() ?? 'Pickup'))
      : _shortLocation((_trip?['destinationShortName']?.toString() ?? _trip?['destinationAddress']?.toString() ?? _trip?['destination_address']?.toString() ?? 'Destination'));

    Uri uri;
    if (targetLat != 0 && targetLng != 0) {
      uri = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$targetLat,$targetLng&travelmode=driving');
    } else {
      uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(targetAddress)}');
    }
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      _showSnack('Unable to open navigation', error: true);
    }
  }

  Map<String, dynamic> _getStep(String status) {
    switch (status) {
      case 'driver_assigned':
      case 'accepted':
        return {'label': 'Pickup వైపు వెళ్తున్నారు', 'icon': Icons.navigation_rounded, 'action': 'Arrived at Pickup'};
      case 'arrived':
        return {'label': 'Pickup Location కి చేరారు', 'icon': Icons.location_on_rounded, 'action': 'Enter Customer OTP'};
      case 'in_progress':
      case 'on_the_way':
        return {'label': 'Trip పూర్తి చేస్తున్నారు', 'icon': Icons.speed_rounded, 'action': 'Complete Trip ✓'};
      default:
        return {'label': 'Trip Active', 'icon': Icons.electric_bike, 'action': 'Next Step'};
    }
  }
}
