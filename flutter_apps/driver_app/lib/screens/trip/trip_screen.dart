import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  LatLng _center = const LatLng(12.9716, 77.5946);
  String _status = 'accepted';
  Map<String, dynamic>? _trip;
  bool _loading = false;
  final _otpCtrl = TextEditingController();

  final Map<String, Map<String, dynamic>> _steps = {
    'accepted': {'label': 'Drive to Pickup', 'action': 'Arrived at Pickup', 'icon': Icons.navigation_outlined},
    'arrived': {'label': 'Verify & Start Ride', 'action': 'Enter Customer OTP', 'icon': Icons.lock_open_outlined},
    'on_the_way': {'label': 'Trip in Progress', 'action': 'Complete Trip', 'icon': Icons.flag_outlined},
  };

  @override
  void initState() {
    super.initState();
    _trip = widget.trip;
    if (_trip != null) {
      _status = _trip!['currentStatus'] ?? _trip!['status'] ?? 'accepted';
      final lat = (_trip!['pickupLat'] as num?)?.toDouble();
      final lng = (_trip!['pickupLng'] as num?)?.toDouble();
      if (lat != null && lng != null) _center = LatLng(lat, lng);
    }
  }

  @override
  void dispose() {
    _otpCtrl.dispose();
    super.dispose();
  }

  Future<void> _nextStep() async {
    if (_status == 'arrived') {
      _showOtpDialog();
      return;
    }
    setState(() => _loading = true);
    final token = await AuthService.getToken();
    String endpoint;
    String nextStatus;
    switch (_status) {
      case 'accepted':
        endpoint = ApiConfig.driverArrived;
        nextStatus = 'arrived';
        break;
      case 'on_the_way':
        endpoint = ApiConfig.driverCompleteTrip;
        nextStatus = 'completed';
        break;
      default:
        endpoint = ApiConfig.driverCompleteTrip;
        nextStatus = 'completed';
    }
    try {
      final res = await http.post(Uri.parse(endpoint),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: jsonEncode({'tripId': _trip?['id'] ?? ''}));
      if (res.statusCode == 200) {
        if (nextStatus == 'completed') {
          if (!mounted) return;
          Navigator.pushAndRemoveUntil(context,
            MaterialPageRoute(builder: (_) => const HomeScreen()), (_) => false);
        } else {
          setState(() => _status = nextStatus);
        }
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

  void _showOtpDialog() {
    _otpCtrl.clear();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0D1B2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Enter Customer OTP',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Ask customer to show OTP from their app',
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
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.15))),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.15))),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF2563EB))),
            ),
          ),
        ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: Colors.white.withOpacity(0.4)))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white,
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
        _mapController?.animateCamera(CameraUpdate.newLatLng(_center));
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

  @override
  Widget build(BuildContext context) {
    final step = _steps[_status] ?? _steps['accepted']!;
    return Scaffold(
      backgroundColor: const Color(0xFF060D1E),
      body: Stack(children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(target: _center, zoom: 14),
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
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Color(0xFF060D1E),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(2))),
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12)),
                  child: Icon(step['icon'] as IconData, color: const Color(0xFF2563EB), size: 28)),
                const SizedBox(width: 16),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(step['label'] as String,
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(_trip?['pickupAddress'] ?? 'Pickup location',
                    style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 13),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                ])),
              ]),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(12)),
                child: Column(children: [
                  _infoRow(Icons.payments_outlined, 'Fare', '₹${_trip?['estimatedFare'] ?? '--'}'),
                  _infoRow(Icons.route_outlined, 'Distance', '${_trip?['estimatedDistance'] ?? '--'} km'),
                  _infoRow(Icons.person_outline, 'Customer', _trip?['customerName'] ?? 'Customer'),
                  if (_trip?['destinationAddress'] != null)
                    _infoRow(Icons.location_on_outlined, 'Destination', _trip!['destinationAddress']),
                ]),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity, height: 54,
                child: ElevatedButton(
                  onPressed: _loading ? null : _nextStep,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white,
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
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.phone_outlined, size: 18, color: Color(0xFF2563EB)),
                  label: const Text('Call Customer',
                    style: TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.w600))),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: _showCancelDialog,
                  icon: Icon(Icons.cancel_outlined, size: 18, color: Colors.red.withOpacity(0.7)),
                  label: Text('Cancel Trip',
                    style: TextStyle(color: Colors.red.withOpacity(0.7), fontWeight: FontWeight.w600))),
              ]),
            ]),
          ),
        ),
      ]),
    );
  }

  void _showCancelDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0D1B2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cancel Trip?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to cancel this trip?',
          style: TextStyle(color: Colors.white.withOpacity(0.6))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx),
            child: const Text('No', style: TextStyle(color: Color(0xFF2563EB)))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red, foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () async {
              Navigator.pop(ctx);
              await _cancelTrip();
            },
            child: const Text('Yes, Cancel')),
        ],
      ),
    );
  }

  Future<void> _cancelTrip() async {
    setState(() => _loading = true);
    final token = await AuthService.getToken();
    try {
      await http.post(Uri.parse(ApiConfig.driverCancelTrip),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: jsonEncode({'tripId': _trip?['id'] ?? '', 'reason': 'Driver cancelled'}));
    } catch (_) {}
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(context,
      MaterialPageRoute(builder: (_) => const HomeScreen()), (_) => false);
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(children: [
        Icon(icon, color: Colors.white.withOpacity(0.4), size: 18),
        const SizedBox(width: 10),
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13)),
        const Spacer(),
        Flexible(child: Text(value,
          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
          textAlign: TextAlign.right, maxLines: 1, overflow: TextOverflow.ellipsis)),
      ]),
    );
  }
}
