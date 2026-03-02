import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
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
  static const Color _bg = Color(0xFF060D1E);
  static const Color _surface = Color(0xFF0D1B3E);
  static const Color _green = Color(0xFF16A34A);

  @override
  void initState() {
    super.initState();
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
            style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14)),
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
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      final lat = pos.latitude;
      final lng = pos.longitude;

      if (mounted) {
        setState(() => _center = LatLng(lat, lng));
        _mapController?.animateCamera(CameraUpdate.newLatLng(_center));
      }

      // Socket — real-time (fastest, broadcasts to customer's map)
      _socket.sendLocation(lat: lat, lng: lng, speed: pos.speed);

      // HTTP fallback — always update DB
      final token = await AuthService.getToken();
      http.post(Uri.parse(ApiConfig.driverLocation),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: jsonEncode({'lat': lat, 'lng': lng, 'isOnline': true})).catchError((_) {});
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
    final token = await AuthService.getToken();
    final tripId = _trip?['id'] ?? _trip?['tripId'] ?? '';

    try {
      if (_status == 'accepted') {
        // Mark arrived — HTTP + Socket
        final res = await http.post(Uri.parse(ApiConfig.driverArrived),
          headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
          body: jsonEncode({'tripId': tripId}));
        if (res.statusCode == 200) {
          _socket.updateTripStatus(tripId, 'arrived');
          setState(() => _status = 'arrived');
        } else {
          _showSnack(jsonDecode(res.body)['message'] ?? 'Error', error: true);
        }
      } else if (_status == 'in_progress' || _status == 'on_the_way') {
        await _completeTrip(token ?? '');
        return;
      }
    } catch (_) {
      if (!mounted) return;
      _showSnack('Network error. Try again.', error: true);
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _completeTrip(String token) async {
    final tripId = _trip?['id'] ?? _trip?['tripId'] ?? '';
    final estimatedFare = _trip?['estimatedFare'] ?? _trip?['estimated_fare'] ?? 0.0;
    final estimatedDistance = _trip?['estimatedDistance'] ?? _trip?['estimated_distance'] ?? 0.0;
    try {
      final res = await http.post(Uri.parse(ApiConfig.driverCompleteTrip),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
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

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => Dialog(
          backgroundColor: _surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  color: _green.withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: _green.withOpacity(0.3), width: 2),
                ),
                child: const Icon(Icons.check_rounded, color: Color(0xFF16A34A), size: 44)),
              const SizedBox(height: 20),
              const Text('Trip Complete! 🎉',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: _green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _green.withOpacity(0.2)),
                ),
                child: Column(children: [
                  Text('₹$fare',
                    style: const TextStyle(color: Color(0xFF4ADE80), fontSize: 36, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 2),
                  Text('Trip Fare', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
                ]),
              ),
              const SizedBox(height: 8),
              Text('Platform commission deduct avutundi',
                style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 11), textAlign: TextAlign.center),
              const SizedBox(height: 20),
              // Rate customer section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: _ratingSubmitted
                    ? Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                        const SizedBox(width: 6),
                        Text('Rating submitted! Thanks', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13)),
                      ])
                    : Column(children: [
                        Text('Customer ki Rating ivvandi',
                          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 10),
                        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          for (int i = 1; i <= 5; i++)
                            GestureDetector(
                              onTap: () async {
                                setStateDialog(() => _selectedRating = i);
                                final token = await AuthService.getToken();
                                try {
                                  await http.post(Uri.parse(ApiConfig.driverRateCustomer),
                                    headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
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
                  child: const Text('Home ki Vellandi →', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15))),
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
              decoration: BoxDecoration(color: _blue.withOpacity(0.15), shape: BoxShape.circle),
              child: const Icon(Icons.lock_open_rounded, color: Color(0xFF2563EB), size: 32)),
            const SizedBox(height: 16),
            const Text('Customer OTP',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
            const SizedBox(height: 4),
            Text('Customer app lo OTP chusi enter cheyyandi',
              style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13), textAlign: TextAlign.center),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _blue.withOpacity(0.2)),
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
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.15), letterSpacing: 10, fontSize: 24),
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
                child: Text('Cancel', style: TextStyle(color: Colors.white.withOpacity(0.4), fontWeight: FontWeight.w600)))),
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
    final token = await AuthService.getToken();
    final tripId = _trip?['id'] ?? _trip?['tripId'] ?? '';
    try {
      final res = await http.post(Uri.parse(ApiConfig.driverVerifyOtp),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: jsonEncode({'tripId': tripId, 'otp': otp}));
      if (res.statusCode == 200) {
        // Notify customer trip started via socket
        _socket.updateTripStatus(tripId, 'in_progress', otp: otp);
        setState(() => _status = 'in_progress');
        final destLat = (_trip?['destinationLat'] as num?)?.toDouble();
        final destLng = (_trip?['destinationLng'] as num?)?.toDouble();
        if (destLat != null && destLng != null && destLat != 0) {
          _mapController?.animateCamera(CameraUpdate.newLatLng(LatLng(destLat, destLng)));
        }
      } else {
        final err = jsonDecode(res.body);
        if (!mounted) return;
        _showSnack(err['message'] ?? 'Wrong OTP', error: true);
      }
    } catch (_) {
      if (!mounted) return;
      _showSnack('Network error. Try again.', error: true);
    }
    if (mounted) setState(() => _loading = false);
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
              decoration: BoxDecoration(color: Colors.red.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.cancel_rounded, color: Color(0xFFF87171), size: 20)),
            const SizedBox(width: 12),
            const Text('Cancel Reason', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
          ]),
          const SizedBox(height: 16),
          ...reasons.map((r) => ListTile(
            title: Text(r, style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13)),
            leading: Icon(Icons.chevron_right_rounded, color: Colors.white.withOpacity(0.3), size: 18),
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
    final token = await AuthService.getToken();
    final tripId = _trip?['id'] ?? _trip?['tripId'] ?? '';
    // Notify customer via socket
    _socket.updateTripStatus(tripId, 'cancelled');
    try {
      await http.post(Uri.parse(ApiConfig.driverCancelTrip),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: jsonEncode({'tripId': tripId, 'reason': reason}));
    } catch (_) {}
    _locationTimer?.cancel();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(context,
      MaterialPageRoute(builder: (_) => const HomeScreen()), (_) => false);
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

    return WillPopScope(
      onWillPop: () async => false,
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
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 24)],
              ),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 40, height: 4,
                  margin: const EdgeInsets.only(top: 10, bottom: 4),
                  decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(2))),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    _buildStatusHeader(step, pickupAddress, destAddress),
                    const SizedBox(height: 14),
                    _buildCustomerCard(customerName, customerPhone, estimatedFare, estimatedDistance),
                    if (_trip?['notes']?.toString().startsWith('📦 Parcel') == true) ...[
                      const SizedBox(height: 10),
                      _buildParcelCard(_trip!['notes'].toString()),
                    ],
                    const SizedBox(height: 14),
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
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withOpacity(0.2), width: 1),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(step['icon'] as IconData, color: statusColor, size: 24)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(step['label'] as String,
            style: TextStyle(color: statusColor, fontSize: 15, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(
            _status == 'accepted' ? pickup : dest,
            style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 11),
            maxLines: 1, overflow: TextOverflow.ellipsis),
        ])),
        // Live location indicator
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.15),
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
        color: const Color(0xFFD97706).withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD97706).withOpacity(0.3), width: 1),
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

  Widget _buildCustomerCard(String name, String? phone, dynamic fare, dynamic dist) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06), width: 1),
      ),
      child: Row(children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: _blue.withOpacity(0.2),
          child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'C',
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
            maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Row(children: [
            _pill('₹$fare', const Color(0xFF10B981)),
            const SizedBox(width: 6),
            _pill('$dist km', _blue),
          ]),
        ])),
        if (phone != null)
          GestureDetector(
            onTap: () => _showSnack('Call: $phone'),
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: _blue.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.phone_rounded, color: Color(0xFF2563EB), size: 18)),
          ),
      ]),
    );
  }

  Widget _pill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
      child: Text(text, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }

  Widget _buildActionBtn(Map<String, dynamic> step) {
    final isComplete = _status == 'in_progress' || _status == 'on_the_way';
    return SizedBox(
      width: double.infinity, height: 56,
      child: ElevatedButton(
        onPressed: _loading ? null : _nextStep,
        style: ElevatedButton.styleFrom(
          backgroundColor: isComplete ? _green : _blue,
          foregroundColor: Colors.white,
          disabledBackgroundColor: (isComplete ? _green : _blue).withOpacity(0.4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0),
        child: _loading
          ? const SizedBox(width: 22, height: 22,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
          : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(step['icon'] as IconData, size: 20),
              const SizedBox(width: 8),
              Text(step['action'] as String,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 0.2)),
            ]),
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
    final token = await AuthService.getToken();
    final tripId = _trip?['id'] ?? _trip?['tripId'] ?? '';
    try {
      await http.post(Uri.parse(ApiConfig.sos),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: jsonEncode({'tripId': tripId, 'lat': _center.latitude, 'lng': _center.longitude, 'message': 'Driver SOS alert during trip'}));
      if (!mounted) return;
      _showSnack('🚨 SOS Alert sent! Help is on the way.');
    } catch (_) {
      if (!mounted) return;
      _showSnack('SOS send failed. Call 100 immediately!', error: true);
    }
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
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: _blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _blue.withOpacity(0.2)),
            ),
            child: const Row(children: [
              Icon(Icons.phone_rounded, color: Color(0xFF2563EB), size: 16),
              SizedBox(width: 6),
              Text('Call', style: TextStyle(color: Color(0xFF2563EB), fontSize: 12, fontWeight: FontWeight.w700)),
            ]),
          ),
        ),
      GestureDetector(
        onTap: _triggerSos,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.red.withOpacity(0.3)),
          ),
          child: const Row(children: [
            Icon(Icons.sos_rounded, color: Colors.red, size: 16),
            SizedBox(width: 6),
            Text('SOS', style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.w800)),
          ]),
        ),
      ),
      GestureDetector(
        onTap: _showCancelDialog,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.orange.withOpacity(0.2)),
          ),
          child: const Row(children: [
            Icon(Icons.cancel_rounded, color: Colors.orange, size: 16),
            SizedBox(width: 6),
            Text('Cancel', style: TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.w700)),
          ]),
        ),
      ),
    ]);
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
