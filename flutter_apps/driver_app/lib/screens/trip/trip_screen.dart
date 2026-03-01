import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import '../../services/auth_service.dart';
import '../home/home_screen.dart';

class TripScreen extends StatefulWidget {
  final Map<String, dynamic>? trip;
  const TripScreen({super.key, this.trip});
  @override
  State<TripScreen> createState() => _TripScreenState();
}

class _TripScreenState extends State<TripScreen> {
  GoogleMapController? _mapController;
  LatLng _center = const LatLng(17.3850, 78.4867);
  String _status = 'accepted';
  Map<String, dynamic>? _trip;
  bool _loading = false;
  final _otpCtrl = TextEditingController();
  Timer? _locationTimer;
  List<String> _cancelReasons = [];

  static const Color _blue = Color(0xFF2563EB);
  static const Color _dark = Color(0xFF060D1E);

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
  }

  @override
  void dispose() {
    _otpCtrl.dispose();
    _locationTimer?.cancel();
    super.dispose();
  }

  void _startLocationUpdates() {
    _locationTimer = Timer.periodic(const Duration(seconds: 10), (_) => _updateLocation());
  }

  Future<void> _updateLocation() async {
    try {
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      final token = await AuthService.getToken();
      await http.post(Uri.parse(ApiConfig.driverLocation),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: jsonEncode({'lat': pos.latitude, 'lng': pos.longitude, 'isOnline': true}));
      if (mounted) {
        setState(() => _center = LatLng(pos.latitude, pos.longitude));
        _mapController?.animateCamera(CameraUpdate.newLatLng(_center));
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
    final token = await AuthService.getToken();
    try {
      String endpoint;
      switch (_status) {
        case 'accepted':
          endpoint = ApiConfig.driverArrived;
          break;
        case 'on_the_way':
          await _completeTrip(token ?? '');
          return;
        default:
          endpoint = ApiConfig.driverArrived;
      }
      final res = await http.post(Uri.parse(endpoint),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: jsonEncode({'tripId': _trip?['id'] ?? ''}));
      if (res.statusCode == 200) {
        setState(() => _status = 'arrived');
      } else {
        if (!mounted) return;
        final err = jsonDecode(res.body);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(err['message'] ?? 'Error occurred'),
          backgroundColor: Colors.red));
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Network error. Try again.'), backgroundColor: Colors.red));
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _completeTrip(String token) async {
    final estimatedFare = (_trip?['estimatedFare'] ?? _trip?['estimated_fare'] ?? 0.0);
    final estimatedDistance = (_trip?['estimatedDistance'] ?? _trip?['estimated_distance'] ?? 0.0);
    try {
      final res = await http.post(Uri.parse(ApiConfig.driverCompleteTrip),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: jsonEncode({
          'tripId': _trip?['id'] ?? '',
          'actualFare': estimatedFare,
          'actualDistance': estimatedDistance,
        }));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final actualFare = data['trip']?['actualFare'] ?? data['trip']?['actual_fare'] ?? estimatedFare;
        if (!mounted) return;
        _showCompletionDialog(actualFare.toString());
      } else {
        if (!mounted) return;
        final err = jsonDecode(res.body);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(err['message'] ?? 'Error completing trip'),
          backgroundColor: Colors.red));
        setState(() => _loading = false);
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Network error. Try again.'), backgroundColor: Colors.red));
      setState(() => _loading = false);
    }
  }

  void _showCompletionDialog(String fare) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0D1B2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.green.withOpacity(0.15), shape: BoxShape.circle),
            child: const Icon(Icons.check_circle_outline, color: Colors.green, size: 56)),
          const SizedBox(height: 16),
          const Text('Trip Completed!', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Fare: ₹$fare', style: const TextStyle(color: Colors.green, fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text('Platform commission deduct avutundi', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11)),
          const SizedBox(height: 20),
          SizedBox(width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _blue, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 14)),
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pushAndRemoveUntil(context,
                  MaterialPageRoute(builder: (_) => const HomeScreen()), (_) => false);
              },
              child: const Text('Home ki Vellandi', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)))),
        ]),
      ),
    );
  }

  void _showOtpDialog() {
    _otpCtrl.clear();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0D1B2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Customer OTP Enter Cheyyandi',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Customer app lo OTP chusi idi enter cheyyandi',
            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13)),
          const SizedBox(height: 16),
          TextField(
            controller: _otpCtrl,
            keyboardType: TextInputType.number,
            maxLength: 6,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 8),
            decoration: InputDecoration(
              counterText: '',
              hintText: '- - - -',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.2), letterSpacing: 8),
              filled: true, fillColor: Colors.white.withOpacity(0.06),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.15))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.15))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _blue)),
            ),
          ),
        ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: Colors.white.withOpacity(0.4)))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _blue, foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () async {
              final otp = _otpCtrl.text.trim();
              if (otp.isEmpty) return;
              Navigator.pop(ctx);
              await _verifyOtpAndStart(otp);
            },
            child: const Text('Verify & Start', style: TextStyle(fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }

  Future<void> _verifyOtpAndStart(String otp) async {
    setState(() => _loading = true);
    final token = await AuthService.getToken();
    try {
      final res = await http.post(Uri.parse(ApiConfig.driverVerifyOtp),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: jsonEncode({'tripId': _trip?['id'] ?? '', 'otp': otp}));
      if (res.statusCode == 200) {
        setState(() => _status = 'on_the_way');
        final destLat = (_trip?['destinationLat'] as num?)?.toDouble();
        final destLng = (_trip?['destinationLng'] as num?)?.toDouble();
        if (destLat != null && destLng != null && destLat != 0) {
          _mapController?.animateCamera(CameraUpdate.newLatLng(LatLng(destLat, destLng)));
        }
      } else {
        final err = jsonDecode(res.body);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(err['message'] ?? 'Wrong OTP'),
          backgroundColor: Colors.red));
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Network error. Try again.'), backgroundColor: Colors.red));
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
      backgroundColor: const Color(0xFF0D1B2E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          const Text('Cancel Reason', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ...reasons.map((r) => ListTile(
            title: Text(r, style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 14)),
            leading: Icon(Icons.radio_button_unchecked, color: Colors.white.withOpacity(0.4), size: 20),
            contentPadding: EdgeInsets.zero,
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

  Future<void> _cancelTrip(String reason) async {
    setState(() => _loading = true);
    final token = await AuthService.getToken();
    try {
      await http.post(Uri.parse(ApiConfig.driverCancelTrip),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: jsonEncode({'tripId': _trip?['id'] ?? '', 'reason': reason}));
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
        backgroundColor: _dark,
        body: Stack(children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: _center, zoom: 15),
            onMapCreated: (c) {
              _mapController = c;
              c.animateCamera(CameraUpdate.newLatLng(_center));
            },
            myLocationEnabled: true,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
          ),
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              decoration: const BoxDecoration(
                color: Color(0xFF0A1628),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(2))),

                // Status header
                Row(children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: _blue.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                    child: Icon(step['icon'] as IconData, color: _blue, size: 26)),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(step['label'] as String,
                      style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
                    Text(_status == 'accepted' ? pickupAddress : destAddress,
                      style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  ])),
                ]),
                const SizedBox(height: 14),

                // Trip info grid
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(12)),
                  child: Column(children: [
                    Row(children: [
                      Expanded(child: _infoTile(Icons.person_outline, 'Customer', customerName)),
                      Expanded(child: _infoTile(Icons.payments_outlined, 'Fare', '₹$estimatedFare')),
                    ]),
                    const SizedBox(height: 8),
                    Row(children: [
                      Expanded(child: _infoTile(Icons.route_outlined, 'Distance', '${estimatedDistance} km')),
                      Expanded(child: _infoTile(Icons.location_on_outlined, 'Pickup',
                        pickupAddress.length > 20 ? '${pickupAddress.substring(0, 20)}...' : pickupAddress)),
                    ]),
                  ]),
                ),
                const SizedBox(height: 14),

                // Main action button
                SizedBox(
                  width: double.infinity, height: 54,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _nextStep,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _status == 'on_the_way' ? Colors.green : _blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0),
                    child: _loading
                      ? const SizedBox(width: 22, height: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(step['action'] as String,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(height: 10),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  if (customerPhone != null)
                    TextButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Call: $customerPhone'), backgroundColor: _blue));
                      },
                      icon: const Icon(Icons.phone_outlined, size: 18, color: _blue),
                      label: const Text('Customer Call', style: TextStyle(color: _blue, fontWeight: FontWeight.w600))),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: _showCancelDialog,
                    icon: Icon(Icons.cancel_outlined, size: 18, color: Colors.red.withOpacity(0.7)),
                    label: Text('Cancel', style: TextStyle(color: Colors.red.withOpacity(0.7), fontWeight: FontWeight.w600))),
                ]),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  Map<String, dynamic> _getStep(String status) {
    switch (status) {
      case 'accepted': return {
        'label': 'Pickup ki Vellandi',
        'action': 'Pickup ki Cherchukunna',
        'icon': Icons.navigation_outlined,
      };
      case 'arrived': return {
        'label': 'OTP Verify Cheyyandi',
        'action': 'Enter Customer OTP',
        'icon': Icons.lock_open_outlined,
      };
      case 'on_the_way': return {
        'label': 'Trip Progress lo undi',
        'action': 'Trip Complete Cheyyandi',
        'icon': Icons.flag_outlined,
      };
      default: return {
        'label': 'Trip',
        'action': 'Next',
        'icon': Icons.arrow_forward,
      };
    }
  }

  Widget _infoTile(IconData icon, String label, String value) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: Colors.white.withOpacity(0.3), size: 16),
      const SizedBox(width: 6),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 10)),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
          maxLines: 1, overflow: TextOverflow.ellipsis),
      ])),
    ]);
  }
}
