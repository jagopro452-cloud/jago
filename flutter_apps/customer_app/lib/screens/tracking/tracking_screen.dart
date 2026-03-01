import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  LatLng _center = const LatLng(17.3850, 78.4867);
  String _status = 'searching';
  Map<String, dynamic>? _trip;
  Timer? _pollTimer;
  int _rated = 0;
  List<String> _cancelReasons = [];

  @override
  void initState() {
    super.initState();
    _pollStatus();
    _loadCancelReasons();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) => _pollStatus());
  }

  @override
  void dispose() { _pollTimer?.cancel(); super.dispose(); }

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
    final token = await AuthService.getToken();
    try {
      final res = await http.get(Uri.parse(ApiConfig.activeTrip),
        headers: {'Authorization': 'Bearer $token'});
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final trip = data['trip'];
        if (trip != null) {
          final lat = (trip['pickupLat'] as num?)?.toDouble();
          final lng = (trip['pickupLng'] as num?)?.toDouble();
          if (mounted) {
            setState(() {
              _trip = trip;
              _status = trip['currentStatus'] ?? _status;
              if (lat != null && lng != null && lat != 0) {
                _center = LatLng(lat, lng);
                _mapController?.animateCamera(CameraUpdate.newLatLng(_center));
              }
            });
          }
          if (_status == 'completed' || _status == 'cancelled') _pollTimer?.cancel();
        }
      }
    } catch (_) {}
  }

  Future<void> _cancelTrip(String reason) async {
    final token = await AuthService.getToken();
    try {
      await http.post(Uri.parse(ApiConfig.cancelTrip),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: jsonEncode({'tripId': _trip?['id'] ?? widget.tripId, 'reason': reason}));
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(context,
        MaterialPageRoute(builder: (_) => const HomeScreen()), (_) => false);
    } catch (_) {}
  }

  Future<void> _rateDriver(int stars) async {
    setState(() => _rated = stars);
    final token = await AuthService.getToken();
    try {
      await http.post(Uri.parse(ApiConfig.rateDriver),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
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
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          const Text('Cancel Reason', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
          const SizedBox(height: 16),
          ...reasons.map((r) => ListTile(
            title: Text(r, style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A2E))),
            leading: const Icon(Icons.radio_button_unchecked, color: Color(0xFF1E6DE5), size: 20),
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

  @override
  Widget build(BuildContext context) {
    final statusInfo = _getStatusInfo(_status);
    final trip = _trip;
    final otp = trip?['pickupOtp']?.toString();
    final driverName = trip?['driverName']?.toString() ?? trip?['driver_name']?.toString();
    final driverPhone = trip?['driverPhone']?.toString() ?? trip?['driver_phone']?.toString();
    final driverRating = trip?['driverRating'] ?? trip?['driver_rating'];
    final actualFare = trip?['actualFare'] ?? trip?['actual_fare'];
    final estimatedFare = trip?['estimatedFare'] ?? trip?['estimated_fare'];

    return WillPopScope(
      onWillPop: () async {
        if (_status == 'completed' || _status == 'cancelled') return true;
        return false;
      },
      child: Scaffold(
        body: Stack(children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: _center, zoom: 15),
            onMapCreated: (c) => _mapController = c,
            myLocationEnabled: true,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
          ),
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 40, height: 4, margin: const EdgeInsets.only(top: 12),
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: (statusInfo['color'] as Color).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12)),
                        child: Icon(statusInfo['icon'] as IconData,
                          color: statusInfo['color'] as Color, size: 26)),
                      const SizedBox(width: 14),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(statusInfo['label'] as String,
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
                        if (_status == 'searching')
                          Text('Nearby drivers search avutundi...',
                            style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                      ])),
                      if (_status == 'searching')
                        const SizedBox(width: 22, height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1E6DE5))),
                    ]),

                    // Driver info card
                    if (driverName != null && _status != 'searching') ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F7FA),
                          borderRadius: BorderRadius.circular(12)),
                        child: Row(children: [
                          CircleAvatar(
                            radius: 24, backgroundColor: const Color(0xFF1E6DE5),
                            child: Text(driverName[0].toUpperCase(),
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(driverName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1A1A2E))),
                            if (driverRating != null)
                              Row(children: [
                                const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                                const SizedBox(width: 3),
                                Text(driverRating.toString(), style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                              ]),
                          ])),
                          if (driverPhone != null)
                            GestureDetector(
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Call: $driverPhone'), backgroundColor: const Color(0xFF1E6DE5)));
                              },
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E6DE5).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10)),
                                child: const Icon(Icons.phone_outlined, color: Color(0xFF1E6DE5), size: 20)),
                            ),
                        ]),
                      ),
                    ],

                    // OTP Box - show when driver assigned/accepted, before ride starts
                    if (otp != null && otp.isNotEmpty && (_status == 'driver_assigned' || _status == 'accepted' || _status == 'arrived')) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF3CD),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.orange.withOpacity(0.4))),
                        child: Row(children: [
                          const Icon(Icons.lock_outlined, color: Colors.orange, size: 22),
                          const SizedBox(width: 12),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            const Text('Pickup OTP', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.orange)),
                            Text(otp, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E), letterSpacing: 8)),
                            const Text('Driver ki ichi share cheyyandi', style: TextStyle(fontSize: 11, color: Colors.orange)),
                          ])),
                          GestureDetector(
                            onTap: () {
                              Clipboard.setData(ClipboardData(text: otp));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('OTP copied!'), backgroundColor: Colors.orange, duration: Duration(seconds: 2)));
                            },
                            child: const Icon(Icons.copy, color: Colors.orange, size: 18)),
                        ]),
                      ),
                    ],

                    // Fare info
                    if (trip != null) ...[
                      const SizedBox(height: 12),
                      Row(children: [
                        _chip(Icons.payments_outlined, actualFare != null ? '₹$actualFare' : '₹${estimatedFare ?? "--"}'),
                        const SizedBox(width: 8),
                        _chip(Icons.route_outlined, '${trip['estimatedDistance'] ?? trip['estimated_distance'] ?? '--'} km'),
                        if (trip['vehicleName'] != null || trip['vehicle_name'] != null) ...[
                          const SizedBox(width: 8),
                          _chip(Icons.directions_bike, trip['vehicleName'] ?? trip['vehicle_name'] ?? ''),
                        ],
                      ]),
                    ],

                    // Completed - rating
                    if (_status == 'completed') ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green.withOpacity(0.2))),
                        child: Column(children: [
                          const Text('Trip completed!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1A1A2E))),
                          if (actualFare != null)
                            Text('Total: ₹$actualFare', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green)),
                          const SizedBox(height: 12),
                          if (_rated == 0) ...[
                            const Text('Driver rate cheyyandi:', style: TextStyle(fontSize: 13, color: Color(0xFF1A1A2E))),
                            const SizedBox(height: 6),
                            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                              for (int i = 1; i <= 5; i++)
                                GestureDetector(
                                  onTap: () => _rateDriver(i),
                                  child: Icon(Icons.star_rounded,
                                    color: i <= _rated ? Colors.amber : Colors.grey[300], size: 36)),
                            ]),
                          ] else
                            const Text('Thanks for rating! 🙏', style: TextStyle(color: Colors.green, fontWeight: FontWeight.w600)),
                        ]),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(width: double.infinity, height: 50,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pushAndRemoveUntil(context,
                            MaterialPageRoute(builder: (_) => const HomeScreen()), (_) => false),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E6DE5), foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
                          child: const Text('Done', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        )),
                    ] else if (_status == 'cancelled') ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: Colors.red.withOpacity(0.05), borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.withOpacity(0.2))),
                        child: const Text('Trip cancelled. Sorry for the inconvenience.',
                          textAlign: TextAlign.center, style: TextStyle(color: Colors.red, fontWeight: FontWeight.w500)),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(width: double.infinity, height: 50,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pushAndRemoveUntil(context,
                            MaterialPageRoute(builder: (_) => const HomeScreen()), (_) => false),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red, foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
                          child: const Text('New Ride Book Cheyyandi', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                        )),
                    ] else ...[
                      const SizedBox(height: 14),
                      SizedBox(width: double.infinity, height: 48,
                        child: OutlinedButton.icon(
                          onPressed: _showCancelDialog,
                          icon: const Icon(Icons.cancel_outlined, size: 18, color: Colors.red),
                          label: const Text('Trip Cancel', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.red.withOpacity(0.4)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        )),
                    ],

                    const SizedBox(height: 16),
                  ]),
                ),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _chip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FA), borderRadius: BorderRadius.circular(8)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: Colors.grey[600]),
        const SizedBox(width: 5),
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[700])),
      ]),
    );
  }

  Map<String, dynamic> _getStatusInfo(String status) {
    switch (status) {
      case 'searching': return {'label': 'Driver Search avutundi...', 'icon': Icons.search, 'color': Colors.orange};
      case 'driver_assigned': return {'label': 'Driver Assign ayyadu!', 'icon': Icons.directions_bike, 'color': const Color(0xFF1E6DE5)};
      case 'accepted': return {'label': 'Driver vachestunnadu', 'icon': Icons.navigation_outlined, 'color': const Color(0xFF1E6DE5)};
      case 'arrived': return {'label': 'Driver Arrived!', 'icon': Icons.where_to_vote, 'color': Colors.green};
      case 'on_the_way': return {'label': 'Trip Progress lo undi', 'icon': Icons.speed, 'color': const Color(0xFF1E6DE5)};
      case 'completed': return {'label': 'Trip Completed!', 'icon': Icons.check_circle, 'color': Colors.green};
      case 'cancelled': return {'label': 'Trip Cancelled', 'icon': Icons.cancel, 'color': Colors.red};
      default: return {'label': 'Loading...', 'icon': Icons.hourglass_empty, 'color': Colors.grey};
    }
  }
}
