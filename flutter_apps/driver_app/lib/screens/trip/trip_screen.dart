import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import '../../services/auth_service.dart';
import '../home/home_screen.dart';

class TripScreen extends StatefulWidget {
  const TripScreen({super.key});
  @override
  State<TripScreen> createState() => _TripScreenState();
}

class _TripScreenState extends State<TripScreen> {
  GoogleMapController? _mapController;
  final LatLng _center = const LatLng(12.9716, 77.5946);
  String _status = 'accepted';
  Map<String, dynamic>? _trip;
  bool _loading = false;

  final Map<String, Map<String, dynamic>> _steps = {
    'accepted': {'label': 'Drive to Pickup', 'action': 'Arrived at Pickup', 'icon': Icons.navigation_outlined},
    'arrived': {'label': 'Verify & Start Ride', 'action': 'Start Trip', 'icon': Icons.play_circle_outline},
    'on_the_way': {'label': 'Trip in Progress', 'action': 'Complete Trip', 'icon': Icons.flag_outlined},
  };

  Future<void> _nextStep() async {
    setState(() => _loading = true);
    final token = await AuthService.getToken();
    String endpoint;
    String nextStatus;
    switch (_status) {
      case 'accepted': endpoint = ApiConfig.driverArrived; nextStatus = 'arrived'; break;
      case 'arrived': endpoint = ApiConfig.driverCompleteTrip; nextStatus = 'on_the_way'; break;
      default: endpoint = ApiConfig.driverCompleteTrip; nextStatus = 'completed'; break;
    }
    try {
      final res = await http.post(Uri.parse(endpoint),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: jsonEncode({'tripId': _trip?['id'] ?? ''}));
      if (res.statusCode == 200) {
        if (nextStatus == 'completed') {
          Navigator.pushAndRemoveUntil(context,
            MaterialPageRoute(builder: (_) => const HomeScreen()), (_) => false);
        } else {
          setState(() => _status = nextStatus);
        }
      }
    } catch (_) {}
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final step = _steps[_status] ?? _steps['accepted']!;
    return Scaffold(
      backgroundColor: const Color(0xFF060D1E),
      body: Stack(children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(target: _center, zoom: 14),
          onMapCreated: (c) => _mapController = c,
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
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB).withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
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
              const SizedBox(height: 20),
              _infoRow(Icons.payments_outlined, 'Fare', '₹${_trip?['estimatedFare'] ?? '--'}'),
              _infoRow(Icons.route_outlined, 'Distance', '${_trip?['estimatedDistance'] ?? '--'} km'),
              _infoRow(Icons.person_outline, 'Customer', _trip?['customerName'] ?? 'Customer'),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity, height: 54,
                child: ElevatedButton(
                  onPressed: _loading ? null : _nextStep,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0),
                  child: _loading
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(step['action'] as String,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.phone_outlined, size: 18, color: Color(0xFF2563EB)),
                label: const Text('Call Customer', style: TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.w600)),
              ),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Icon(icon, color: Colors.white.withOpacity(0.4), size: 18),
        const SizedBox(width: 10),
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13)),
        const Spacer(),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}
