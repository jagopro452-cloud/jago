import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import '../../services/auth_service.dart';
import '../home/home_screen.dart';

class TrackingScreen extends StatefulWidget {
  final String tripId;
  const TrackingScreen({super.key, required this.tripId});
  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  GoogleMapController? _mapController;
  final LatLng _center = const LatLng(12.9716, 77.5946);
  String _status = 'searching';
  Map<String, dynamic>? _trip;
  Timer? _pollTimer;
  bool _rated = false;

  final Map<String, Map<String, dynamic>> _statusInfo = {
    'searching': {'label': 'Finding your driver...', 'icon': Icons.search, 'color': Colors.orange},
    'driver_assigned': {'label': 'Driver assigned!', 'icon': Icons.directions_bike, 'color': Color(0xFF1E6DE5)},
    'accepted': {'label': 'Driver on the way', 'icon': Icons.navigation_outlined, 'color': Color(0xFF1E6DE5)},
    'arrived': {'label': 'Driver arrived!', 'icon': Icons.where_to_vote, 'color': Colors.green},
    'on_the_way': {'label': 'Trip in progress', 'icon': Icons.speed, 'color': Color(0xFF1E6DE5)},
    'completed': {'label': 'Trip completed!', 'icon': Icons.check_circle, 'color': Colors.green},
    'cancelled': {'label': 'Trip cancelled', 'icon': Icons.cancel, 'color': Colors.red},
  };

  @override
  void initState() { super.initState(); _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) => _pollStatus()); }

  Future<void> _pollStatus() async {
    final token = await AuthService.getToken();
    try {
      final res = await http.get(Uri.parse(ApiConfig.activeTrip), headers: {'Authorization': 'Bearer $token'});
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final trip = data['trip'];
        if (trip != null) setState(() { _trip = trip; _status = trip['currentStatus'] ?? _status; });
        if (_status == 'completed' || _status == 'cancelled') _pollTimer?.cancel();
      }
    } catch (_) {}
  }

  @override
  void dispose() { _pollTimer?.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final info = _statusInfo[_status] ?? _statusInfo['searching']!;
    return Scaffold(
      body: Stack(children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(target: _center, zoom: 14),
          onMapCreated: (c) => _mapController = c,
          myLocationEnabled: true, zoomControlsEnabled: false, mapToolbarEnabled: false),
        Positioned(
          bottom: 0, left: 0, right: 0,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (info['color'] as Color).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: Icon(info['icon'] as IconData, color: info['color'] as Color, size: 28)),
                const SizedBox(width: 16),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(info['label'] as String,
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
                  if (_trip?['driverName'] != null)
                    Text(_trip?['driverName'] ?? '', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                ])),
                if (_status == 'searching')
                  const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1E6DE5))),
              ]),
              if (_trip != null) ...[
                const SizedBox(height: 16),
                _infoRow(Icons.payments_outlined, 'Fare', '₹${_trip?['estimatedFare'] ?? '--'}'),
                if (_trip?['driverName'] != null)
                  _infoRow(Icons.person_outline, 'Driver', _trip?['driverName'] ?? ''),
              ],
              const SizedBox(height: 16),
              if (_status == 'completed' && !_rated) ...[
                const Text('Rate your ride', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  for (int i = 1; i <= 5; i++)
                    IconButton(
                      icon: const Icon(Icons.star_rounded, color: Colors.amber, size: 32),
                      onPressed: () { setState(() => _rated = true); }),
                ]),
              ] else if (_status == 'completed' && _rated)
                SizedBox(width: double.infinity, height: 50,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pushAndRemoveUntil(context,
                      MaterialPageRoute(builder: (_) => const HomeScreen()), (_) => false),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E6DE5), foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
                    child: const Text('Done', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ))
              else
                SizedBox(width: double.infinity, height: 50,
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: const Text('Cancel Trip', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
                  )),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Icon(icon, color: Colors.grey[400], size: 16),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 13)),
        const Spacer(),
        Text(value, style: const TextStyle(color: Color(0xFF1A1A2E), fontSize: 13, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}
