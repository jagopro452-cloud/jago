import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/api_config.dart';
import '../../services/auth_service.dart';
import '../../services/socket_service.dart';
import '../home/home_screen.dart';

class TripScreen extends StatefulWidget {
  final Map<String, dynamic>? trip;
  const TripScreen({super.key, this.trip});
  @override
  State<TripScreen> createState() => _TripScreenState();
}

class _TripScreenState extends State<TripScreen> {
  final SocketService _socket = SocketService();
  GoogleMapController? _mapController;
  LatLng _center = const LatLng(17.3850, 78.4867);
  String _status = 'accepted';
  Map<String, dynamic>? _trip;
  bool _loading = false;
  final _otpCtrl = TextEditingController();
  Timer? _locationTimer;
  List<String> _cancelReasons = [];
  StreamSubscription? _cancelSub;

  static const Color _blue = Color(0xFF2563EB);
  static const Color _bg = Color(0xFF0F172A);
  static const Color _surface = Color(0xFF1E293B);
  static const Color _green = Color(0xFF16A34A);

  @override
  void initState() {
    super.initState();
    _socket.connect(ApiConfig.socketUrl);
    _trip = widget.trip;
    if (_trip != null) {
      _status = _trip!['currentStatus'] ?? _trip!['status'] ?? 'accepted';
      final lat = (_trip!['pickupLat'] as num?)?.toDouble();
      final lng = (_trip!['pickupLng'] as num?)?.toDouble();
      if (lat != null && lng != null && lat != 0) _center = LatLng(lat, lng);
    }
    _startLocationUpdates();
    _loadCancelReasons();
    _listenForCancel();
  }

  void _listenForCancel() {
    // If customer cancels mid-trip, navigate back home
    _cancelSub = _socket.onTripCancelled.listen((data) {
      if (!mounted) return;
      _locationTimer?.cancel();
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          backgroundColor: _surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Trip Cancelled', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
          content: Text('Customer cancelled the trip.',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 14)),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _blue, foregroundColor: Colors.white,
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
    super.dispose();
  }

  void _startLocationUpdates() {
    _locationTimer = Timer.periodic(const Duration(seconds: 5), (_) => _updateLocation());
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
      }

      // Socket — real-time (fastest, broadcasts to customer's map)
      _socket.sendLocation(lat: lat, lng: lng, speed: pos.speed);

      // HTTP fallback — always update DB
      final locHeaders = await AuthService.getHeaders();
      http.post(Uri.parse(ApiConfig.driverLocation),
        headers: {...locHeaders, 'Content-Type': 'application/json'},
        body: jsonEncode({'lat': lat, 'lng': lng, 'isOnline': true})).catchError((_) => http.Response('', 500));
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
        // Mark arrived — HTTP + Socket
        final res = await http.post(Uri.parse(ApiConfig.driverArrived),
          headers: {...stepHeaders, 'Content-Type': 'application/json'},
          body: jsonEncode({'tripId': tripId}));
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
        final actualFare = data['trip']?['actualFare'] ?? data['trip']?['actual_fare'] ?? estimatedFare;
        // Notify customer via socket
        _socket.updateTripStatus(tripId, 'completed');
        _locationTimer?.cancel();
        if (!mounted) return;
        _showCompletionDialog(actualFare.toString());
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
      backgroundColor: error ? const Color(0xFFDC2626) : _blue,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  void _showCompletionDialog(String fare) {
    int _selectedRating = 0;
    bool _ratingSubmitted = false;
    final tripId = _trip?['id'] ?? _trip?['tripId'] ?? '';
    final pm = _trip?['paymentMethod'] ?? _trip?['payment_method'] ?? 'cash';
    final isCash = pm == 'cash';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => Dialog(
          backgroundColor: _surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 72, height: 72,
                decoration: BoxDecoration(
                  color: _green.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: _green.withValues(alpha: 0.3), width: 2),
                ),
                child: const Icon(Icons.check_rounded, color: Color(0xFF16A34A), size: 40)),
              const SizedBox(height: 16),
              const Text('Trip Complete! 🎉',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: _green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _green.withValues(alpha: 0.2)),
                ),
                child: Column(children: [
                  Text('₹$fare',
                    style: const TextStyle(color: Color(0xFF4ADE80), fontSize: 36, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(
                      isCash ? Icons.payments_rounded : pm == 'wallet' ? Icons.account_balance_wallet_rounded : Icons.qr_code_scanner_rounded,
                      color: Colors.white.withValues(alpha: 0.5),
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isCash ? 'Cash' : pm == 'wallet' ? 'Wallet' : 'UPI/Online',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
                    ),
                  ]),
                ]),
              ),
              if (isCash) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF16A34A), Color(0xFF15803D)],
                      begin: Alignment.centerLeft, end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [BoxShadow(color: const Color(0xFF16A34A).withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 4))],
                  ),
                  child: Row(children: [
                    const Icon(Icons.payments_rounded, color: Colors.white, size: 28),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('COLLECT ₹ CASH', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
                      Text('Collect ₹$fare cash from customer',
                        style: const TextStyle(color: Colors.white70, fontSize: 11)),
                    ])),
                  ]),
                ),
              ] else ...[
                const SizedBox(height: 8),
                Text(pm == 'wallet' ? 'Customer wallet deducted automatically' : 'Customer already paid online',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 11), textAlign: TextAlign.center),
              ],
              const SizedBox(height: 8),
              Text('Platform commission will be deducted',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 11), textAlign: TextAlign.center),
              const SizedBox(height: 20),
              // Rate customer section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: _ratingSubmitted
                    ? Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                        const SizedBox(width: 6),
                        Text('Rating submitted! Thanks', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13)),
                      ])
                    : Column(children: [
                        Text('Customer ki Rating ivvandi',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 10),
                        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          for (int i = 1; i <= 5; i++)
                            GestureDetector(
                              onTap: () async {
                                setStateDialog(() => _selectedRating = i);
                                final rateHeaders = await AuthService.getHeaders();
                                try {
                                  await http.post(Uri.parse(ApiConfig.driverRateCustomer),
                                    headers: {...rateHeaders, 'Content-Type': 'application/json'},
                                    body: jsonEncode({'tripId': tripId, 'rating': i}));
                                } catch (_) {}
                                setStateDialog(() => _ratingSubmitted = true);
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: Icon(
                                  i <= _selectedRating ? Icons.star_rounded : Icons.star_border_rounded,
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
                    backgroundColor: _blue, foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0),
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pushAndRemoveUntil(context,
                      MaterialPageRoute(builder: (_) => const HomeScreen()), (_) => false);
                  },
                  child: const Text('Go Home →', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15))),
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
        backgroundColor: _surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: _blue.withValues(alpha: 0.15), shape: BoxShape.circle),
              child: const Icon(Icons.lock_open_rounded, color: Color(0xFF2563EB), size: 32)),
            const SizedBox(height: 16),
            const Text('Customer OTP',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
            const SizedBox(height: 4),
            Text('Ask customer for OTP from their JAGO app',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 13), textAlign: TextAlign.center),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _blue.withValues(alpha: 0.2)),
              ),
              child: TextField(
                controller: _otpCtrl,
                keyboardType: TextInputType.number,
                maxLength: 6,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 10),
                decoration: InputDecoration(
                  counterText: '',
                  hintText: '------',
                  hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.15), letterSpacing: 10, fontSize: 24),
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
                child: Text('Cancel', style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontWeight: FontWeight.w600)))),
              const SizedBox(width: 12),
              Expanded(child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _blue, foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14), elevation: 0),
                onPressed: () async {
                  final otp = _otpCtrl.text.trim();
                  if (otp.isEmpty) return;
                  Navigator.pop(ctx);
                  await _verifyOtpAndStart(otp);
                },
                child: const Text('Verify ✓', style: TextStyle(fontWeight: FontWeight.w800)))),
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
        // Notify customer trip started via socket
        _socket.updateTripStatus(tripId, 'on_the_way', otp: otp);
        setState(() { _status = 'in_progress'; _loading = false; });
        final destLat = (_trip?['destinationLat'] as num?)?.toDouble();
        final destLng = (_trip?['destinationLng'] as num?)?.toDouble();
        if (destLat != null && destLng != null && destLat != 0) {
          _mapController?.animateCamera(CameraUpdate.newLatLng(LatLng(destLat, destLng)));
        }
        // Prompt driver to take a pickup location photo (ride security)
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

  /// Show a bottom sheet prompting driver to capture a pickup location photo.
  void _showPickupPhotoPrompt(String tripId) {
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: _surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _blue.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _blue.withValues(alpha: 0.25)),
            ),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: _blue.withValues(alpha: 0.18), shape: BoxShape.circle),
                child: const Icon(Icons.camera_alt_rounded, color: Color(0xFF60A5FA), size: 26)),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Pickup Location Photo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
                const SizedBox(height: 4),
                Text('Capture a photo at the pickup point for ride security.',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 12)),
              ])),
            ]),
          ),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white60,
                  side: const BorderSide(color: Colors.white24),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text('Skip', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _blue, foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14), elevation: 0),
                icon: const Icon(Icons.camera_alt_rounded, size: 18),
                label: const Text('Take Photo', style: TextStyle(fontWeight: FontWeight.w800)),
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

  /// Opens the camera, captures a pickup photo and uploads it to the server.
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
    } catch (_) {
      // Photo is optional — don't block trip on failure
    }
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
      backgroundColor: _surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          Row(children: [
            Container(padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.cancel_rounded, color: Color(0xFFF87171), size: 20)),
            const SizedBox(width: 12),
            const Text('Cancel Reason', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
          ]),
          const SizedBox(height: 16),
          ...reasons.map((r) => ListTile(
            title: Text(r, style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13)),
            leading: Icon(Icons.chevron_right_rounded, color: Colors.white.withValues(alpha: 0.3), size: 18),
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
    // Notify customer via socket
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
        backgroundColor: _surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFFD97706).withValues(alpha: 0.15), shape: BoxShape.circle),
              child: const Icon(Icons.local_shipping_rounded, color: Color(0xFFD97706), size: 32)),
            const SizedBox(height: 16),
            const Text('Delivery OTP',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
            const SizedBox(height: 4),
            Text('Ask receiver for OTP to confirm delivery',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 13), textAlign: TextAlign.center),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFD97706).withValues(alpha: 0.3)),
              ),
              child: TextField(
                controller: deliveryOtpCtrl,
                keyboardType: TextInputType.number,
                maxLength: 6,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 10),
                decoration: InputDecoration(
                  counterText: '',
                  hintText: '------',
                  hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.15), letterSpacing: 10, fontSize: 24),
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
                child: Text('Cancel', style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontWeight: FontWeight.w600)))),
              const SizedBox(width: 12),
              Expanded(child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD97706), foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14), elevation: 0),
                onPressed: () async {
                  final otp = deliveryOtpCtrl.text.trim();
                  if (otp.isEmpty) return;
                  Navigator.pop(ctx);
                  await _verifyDeliveryOtp(otp);
                },
                child: const Text('Verify ✓', style: TextStyle(fontWeight: FontWeight.w800)))),
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
        _showSnack('✅ Delivery verified! You can now complete the trip.');
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
    final pickupAddress = _trip?['pickupAddress'] ?? _trip?['pickup_address'] ?? 'Pickup';
    final destAddress = _trip?['destinationAddress'] ?? _trip?['destination_address'] ?? 'Destination';
    final isForSomeoneElse = _trip?['isForSomeoneElse'] == true || _trip?['is_for_someone_else'] == true;
    final passengerName = _trip?['passengerName'] ?? _trip?['passenger_name'] ?? '';
    final passengerPhone = _trip?['passengerPhone'] ?? _trip?['passenger_phone'];

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Stack(children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: _center, zoom: 15),
            onMapCreated: (c) { _mapController = c; c.animateCamera(CameraUpdate.newLatLng(_center)); },
            myLocationEnabled: true,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
          ),
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: _bg,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 24)],
              ),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 44, height: 4,
                  margin: const EdgeInsets.only(top: 10, bottom: 4),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [_blue.withValues(alpha: 0.4), Colors.white.withValues(alpha: 0.1)]),
                    borderRadius: BorderRadius.circular(2))),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    _buildStatusHeader(step, pickupAddress, destAddress),
                    const SizedBox(height: 14),
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

  Widget _buildStatusHeader(Map<String, dynamic> step, String pickup, String dest) {
    final isOnTheWay = _status == 'in_progress' || _status == 'on_the_way';
    final statusColor = isOnTheWay ? _green : _blue;
    final gradColors = isOnTheWay
      ? [const Color(0xFF064E3B), const Color(0xFF065F46)]
      : [const Color(0xFF1E3A8A), const Color(0xFF1E40AF)];
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradColors, begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: statusColor.withValues(alpha: 0.3), width: 1),
        boxShadow: [BoxShadow(color: statusColor.withValues(alpha: 0.2), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: statusColor.withValues(alpha: 0.3)),
          ),
          child: Icon(step['icon'] as IconData, color: statusColor, size: 24)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(step['label'] as String,
            style: TextStyle(color: statusColor, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: -0.3)),
          const SizedBox(height: 3),
          Text(
            _status == 'accepted' ? pickup : dest,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11),
            maxLines: 1, overflow: TextOverflow.ellipsis),
        ])),
        // Live location indicator
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 6, height: 6,
              decoration: const BoxDecoration(color: Color(0xFF4ADE80), shape: BoxShape.circle)),
            const SizedBox(width: 4),
            const Text('LIVE', style: TextStyle(color: Color(0xFF4ADE80), fontSize: 9, fontWeight: FontWeight.w800)),
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
        color: const Color(0xFFD97706).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD97706).withValues(alpha: 0.3), width: 1),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Text('📦', style: TextStyle(fontSize: 16)),
          SizedBox(width: 8),
          Text('PARCEL DELIVERY', style: TextStyle(color: Color(0xFFD97706), fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1)),
        ]),
        const SizedBox(height: 10),
        if (receiver.isNotEmpty) Row(children: [
          const Icon(Icons.person_rounded, color: Color(0xFFD97706), size: 15),
          const SizedBox(width: 6),
          Expanded(child: Text(receiver, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600))),
        ]),
        if (category.isNotEmpty) ...[
          const SizedBox(height: 4),
          Row(children: [
            const Icon(Icons.category_rounded, color: Color(0xFFD97706), size: 15),
            const SizedBox(width: 6),
            Text('$category  •  $weight', style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ]),
        ],
        if (instructions.isNotEmpty) ...[
          const SizedBox(height: 4),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.info_outline_rounded, color: Color(0xFFD97706), size: 15),
            const SizedBox(width: 6),
            Expanded(child: Text(instructions, style: const TextStyle(color: Colors.white70, fontSize: 11))),
          ]),
        ],
      ]),
    );
  }

  Widget _buildPassengerCard(String passengerName, String? passengerPhone) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.purple.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.purple.withValues(alpha: 0.25), width: 1),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.purple.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.person_pin_rounded, color: Colors.purple, size: 18)),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('PASSENGER', style: TextStyle(color: Colors.purple, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1)),
          const SizedBox(height: 2),
          Text(passengerName, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
          if (passengerPhone != null && passengerPhone.isNotEmpty) ...[
            const SizedBox(height: 1),
            Text(passengerPhone, style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 11)),
          ],
        ])),
        if (passengerPhone != null && passengerPhone.isNotEmpty)
          GestureDetector(
            onTap: () async {
              final uri = Uri(scheme: 'tel', path: passengerPhone);
              try {
                if (await canLaunchUrl(uri)) await launchUrl(uri);
                else _showSnack('Call: $passengerPhone');
              } catch (_) { _showSnack('Call: $passengerPhone'); }
            },
            child: Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                color: Colors.purple.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.phone_rounded, color: Colors.purple, size: 17)),
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
          gradient: const LinearGradient(
            colors: [Color(0xFFD97706), Color(0xFFB45309)],
            begin: Alignment.centerLeft, end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: const Color(0xFFD97706).withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 3))],
        ),
        child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.lock_open_rounded, color: Colors.white, size: 18),
          SizedBox(width: 8),
          Text('Verify Delivery OTP',
            style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800)),
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
          gradient: const LinearGradient(
            colors: [Color(0xFF16A34A), Color(0xFF15803D)],
            begin: Alignment.centerLeft, end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: const Color(0xFF16A34A).withValues(alpha: 0.35), blurRadius: 16, offset: const Offset(0, 4))],
        ),
        child: Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.payments_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('COLLECT CASH', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1)),
            SizedBox(height: 2),
            Text('Trip ending. Please collect cash from customer.', style: TextStyle(color: Colors.white70, fontSize: 11)),
          ])),
        ]),
      );
    }
    if (isCash) {
      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF16A34A).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF16A34A).withValues(alpha: 0.25)),
        ),
        child: const Row(children: [
          Icon(Icons.payments_rounded, color: Color(0xFF4ADE80), size: 16),
          SizedBox(width: 8),
          Text('💵 Cash Payment — Collect at trip end', style: TextStyle(color: Color(0xFF4ADE80), fontSize: 12, fontWeight: FontWeight.w600)),
        ]),
      );
    }
    if (isWallet) {
      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: _blue.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _blue.withValues(alpha: 0.25)),
        ),
        child: const Row(children: [
          Icon(Icons.account_balance_wallet_rounded, color: Color(0xFF60A5FA), size: 16),
          SizedBox(width: 8),
          Text('👛 Wallet Payment — Auto deducted from customer', style: TextStyle(color: Color(0xFF60A5FA), fontSize: 12, fontWeight: FontWeight.w600)),
        ]),
      );
    }
    if (isOnline) {
      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF7C3AED).withValues(alpha: 0.25)),
        ),
        child: const Row(children: [
          Icon(Icons.qr_code_scanner_rounded, color: Color(0xFFA78BFA), size: 16),
          SizedBox(width: 8),
          Text('📱 Online Payment — Already paid via UPI/Razorpay', style: TextStyle(color: Color(0xFFA78BFA), fontSize: 12, fontWeight: FontWeight.w600)),
        ]),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildCustomerCard(String name, String? phone, dynamic fare, dynamic dist) {
    final pm = _trip?['paymentMethod'] ?? _trip?['payment_method'] ?? 'cash';
    final pmLabel = pm == 'wallet' ? '💳 Wallet' : pm == 'upi' || pm == 'online' || pm == 'razorpay' ? '📱 UPI' : '💵 Cash';
    final pmColor = pm == 'wallet' ? _blue : pm == 'upi' || pm == 'online' || pm == 'razorpay' ? const Color(0xFF7C3AED) : _green;
    final fareVal = double.tryParse(fare?.toString() ?? '0') ?? 0;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF1E293B), const Color(0xFF0F172A)],
          begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 1),
      ),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Container(
              width: 46, height: 46,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_blue, const Color(0xFF1E40AF)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [BoxShadow(color: _blue.withValues(alpha: 0.35), blurRadius: 10, offset: const Offset(0,3))],
              ),
              child: Center(child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'C',
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900))),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: -0.3),
                maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Text(pmLabel, style: TextStyle(color: pmColor, fontSize: 12, fontWeight: FontWeight.w700)),
            ])),
            if (phone != null)
              GestureDetector(
                onTap: () async {
                  final uri = Uri(scheme: 'tel', path: phone);
                  try {
                    if (await canLaunchUrl(uri)) await launchUrl(uri);
                    else _showSnack('Call: $phone');
                  } catch (_) { _showSnack('Call: $phone'); }
                },
                child: Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [_blue, const Color(0xFF1E40AF)]),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [BoxShadow(color: _blue.withValues(alpha: 0.35), blurRadius: 8, offset: const Offset(0,3))],
                  ),
                  child: const Icon(Icons.phone_rounded, color: Colors.white, size: 20)),
              ),
          ]),
        ),
        Container(
          height: 1,
          color: Colors.white.withValues(alpha: 0.05),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(children: [
            Expanded(child: _statPill('Fare', fareVal > 0 ? '₹${fareVal.toInt()}' : '₹$fare', const Color(0xFF10B981))),
            const SizedBox(width: 8),
            Expanded(child: _statPill('Distance', '$dist km', _blue)),
            const SizedBox(width: 8),
            Expanded(child: _statPill('Pay', pm == 'cash' ? 'Cash' : pm == 'wallet' ? 'Wallet' : 'Online', pmColor)),
          ]),
        ),
      ]),
    );
  }

  Widget _statPill(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(children: [
        Text(value, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w900)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 9, fontWeight: FontWeight.w600)),
      ]),
    );
  }

  Widget _buildActionBtn(Map<String, dynamic> step) {
    final isComplete = _status == 'in_progress' || _status == 'on_the_way';
    final c1 = isComplete ? const Color(0xFF064E3B) : const Color(0xFF1E3A8A);
    final c2 = isComplete ? _green : _blue;
    final c3 = isComplete ? const Color(0xFF22C55E) : const Color(0xFF60A5FA);
    return GestureDetector(
      onTap: _loading ? null : _nextStep,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity, height: 60,
        margin: const EdgeInsets.only(top: 4),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [c1, c2, c3],
            begin: Alignment.centerLeft, end: Alignment.centerRight),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(color: c2.withValues(alpha: 0.5), blurRadius: 20, offset: const Offset(0, 6)),
            BoxShadow(color: c2.withValues(alpha: 0.2), blurRadius: 40, offset: const Offset(0, 10)),
          ],
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
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), shape: BoxShape.circle),
                  child: Icon(step['icon'] as IconData, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Text(step['action'] as String,
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: -0.2)),
              ]),
        ),
      ),
    );
  }

  Future<void> _triggerSos() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _surface,
        title: const Text('SOS Alert', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text('Emergency SOS send చేయాలా? Help team contact అవుతారు.',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
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
      _showSnack('🚨 SOS Alert sent! Help is on the way.');
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
          onTap: () async {
            final uri = Uri(scheme: 'tel', path: phone);
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri);
            } else {
              _showSnack('Call: $phone');
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [_blue.withValues(alpha: 0.15), _blue.withValues(alpha: 0.08)]),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _blue.withValues(alpha: 0.25)),
            ),
            child: const Row(children: [
              Icon(Icons.phone_rounded, color: Color(0xFF2563EB), size: 16),
              SizedBox(width: 6),
              Text('Call', style: TextStyle(color: Color(0xFF2563EB), fontSize: 13, fontWeight: FontWeight.w800)),
            ]),
          ),
        ),
      GestureDetector(
        onTap: _triggerSos,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [Colors.red.withValues(alpha: 0.18), Colors.red.withValues(alpha: 0.08)]),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red.withValues(alpha: 0.35)),
          ),
          child: const Row(children: [
            Icon(Icons.sos_rounded, color: Colors.red, size: 16),
            SizedBox(width: 6),
            Text('SOS', style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.w800)),
          ]),
        ),
      ),
      GestureDetector(
        onTap: _openNavigation,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF2F80ED).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF2F80ED).withValues(alpha: 0.25)),
          ),
          child: const Row(children: [
            Icon(Icons.navigation_rounded, color: Color(0xFF2F80ED), size: 16),
            SizedBox(width: 6),
            Text('Navigate', style: TextStyle(color: Color(0xFF2F80ED), fontSize: 12, fontWeight: FontWeight.w700)),
          ]),
        ),
      ),
      GestureDetector(
        onTap: _showCancelDialog,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
          ),
          child: const Row(children: [
            Icon(Icons.cancel_rounded, color: Colors.orange, size: 16),
            SizedBox(width: 6),
            Text('Cancel', style: TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.w700)),
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
            color: Colors.green.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.green.withValues(alpha: 0.25)),
          ),
          child: const Row(children: [
            Icon(Icons.phone_in_talk_rounded, color: Colors.green, size: 16),
            SizedBox(width: 6),
            Text('Support', style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.w700)),
          ]),
        ),
      ),
    ]);
  }

  Future<void> _openNavigation() async {
    final toPickup = _status == 'accepted' || _status == 'driver_assigned';
    final targetLat = toPickup
      ? ((_trip?['pickupLat'] as num?)?.toDouble() ?? (_trip?['pickup_lat'] as num?)?.toDouble() ?? 0)
      : ((_trip?['destinationLat'] as num?)?.toDouble() ?? (_trip?['destination_lat'] as num?)?.toDouble() ?? 0);
    final targetLng = toPickup
      ? ((_trip?['pickupLng'] as num?)?.toDouble() ?? (_trip?['pickup_lng'] as num?)?.toDouble() ?? 0)
      : ((_trip?['destinationLng'] as num?)?.toDouble() ?? (_trip?['destination_lng'] as num?)?.toDouble() ?? 0);
    final targetAddress = toPickup
      ? (_trip?['pickupAddress']?.toString() ?? _trip?['pickup_address']?.toString() ?? 'Pickup')
      : (_trip?['destinationAddress']?.toString() ?? _trip?['destination_address']?.toString() ?? 'Destination');

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
        return {'label': 'Pickup వైపు వెళ్తున్నారు 🏍️', 'icon': Icons.navigation_rounded, 'action': 'Arrived at Pickup'};
      case 'arrived':
        return {'label': 'Pickup Location కి చేరారు 📍', 'icon': Icons.location_on_rounded, 'action': 'Enter Customer OTP'};
      case 'in_progress':
      case 'on_the_way':
        return {'label': 'Trip పూర్తి చేస్తున్నారు 🚀', 'icon': Icons.speed_rounded, 'action': 'Complete Trip ✓'};
      default:
        return {'label': 'Trip Active', 'icon': Icons.electric_bike, 'action': 'Next Step'};
    }
  }
}
