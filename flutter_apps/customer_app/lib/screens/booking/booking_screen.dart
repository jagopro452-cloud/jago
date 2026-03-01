import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import '../../services/auth_service.dart';
import '../tracking/tracking_screen.dart';

class BookingScreen extends StatefulWidget {
  final String pickup;
  final String destination;
  final String? vehicleCategoryId;
  final String? vehicleCategoryName;
  const BookingScreen({super.key, required this.pickup, required this.destination,
    this.vehicleCategoryId, this.vehicleCategoryName});
  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  GoogleMapController? _mapController;
  bool _loading = false;
  bool _confirmed = false;
  Map<String, dynamic>? _fare;

  final LatLng _pickupLatLng = const LatLng(12.9716, 77.5946);
  final LatLng _destLatLng = const LatLng(12.9800, 77.6100);

  String get _vehicleName => widget.vehicleCategoryName ?? 'Bike';

  static IconData _iconForVehicle(String name) {
    final n = name.toLowerCase();
    if (n.contains('bike')) return Icons.electric_bike;
    if (n.contains('auto')) return Icons.electric_rickshaw;
    if (n.contains('suv')) return Icons.directions_car;
    if (n.contains('temo') || n.contains('tempo')) return Icons.airport_shuttle;
    if (n.contains('car')) return Icons.directions_car_filled;
    return Icons.directions_car;
  }

  @override
  void initState() {
    super.initState();
    _estimateFare();
  }

  Future<void> _estimateFare() async {
    final token = await AuthService.getToken();
    try {
      final body = <String, dynamic>{
        'pickupLat': _pickupLatLng.latitude, 'pickupLng': _pickupLatLng.longitude,
        'destinationLat': _destLatLng.latitude, 'destinationLng': _destLatLng.longitude,
      };
      if (widget.vehicleCategoryId != null) {
        body['vehicleCategoryId'] = widget.vehicleCategoryId;
      } else {
        body['vehicleType'] = _vehicleName.toLowerCase();
      }
      final res = await http.post(Uri.parse(ApiConfig.estimateFare),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      if (res.statusCode == 200) setState(() => _fare = jsonDecode(res.body));
    } catch (_) {}
  }

  Future<void> _confirmBooking() async {
    setState(() => _loading = true);
    final token = await AuthService.getToken();
    try {
      final body = <String, dynamic>{
        'pickupAddress': widget.pickup, 'destinationAddress': widget.destination,
        'pickupLat': _pickupLatLng.latitude, 'pickupLng': _pickupLatLng.longitude,
        'destinationLat': _destLatLng.latitude, 'destinationLng': _destLatLng.longitude,
        'paymentMethod': 'cash',
      };
      if (widget.vehicleCategoryId != null) {
        body['vehicleCategoryId'] = widget.vehicleCategoryId;
      } else {
        body['vehicleType'] = _vehicleName.toLowerCase();
      }
      final res = await http.post(Uri.parse(ApiConfig.bookRide),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (!mounted) return;
        Navigator.pushReplacement(context, MaterialPageRoute(
          builder: (_) => TrackingScreen(tripId: data['tripId'] ?? data['trip']?['id'] ?? '')));
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(jsonDecode(res.body)['message'] ?? 'Booking failed'),
            backgroundColor: Colors.red));
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final price = _fare?['estimatedFare'] ?? _fare?['totalFare'] ?? '--';
    final distance = _fare?['distance'] ?? _fare?['estimatedDistance'] ?? '--';
    final eta = _fare?['estimatedTime'] ?? 4;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(target: _pickupLatLng, zoom: 13),
          onMapCreated: (c) => _mapController = c,
          markers: {
            Marker(markerId: const MarkerId('pickup'), position: _pickupLatLng,
              infoWindow: InfoWindow(title: widget.pickup)),
            Marker(markerId: const MarkerId('dest'), position: _destLatLng,
              infoWindow: InfoWindow(title: widget.destination),
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue)),
          },
          polylines: {
            Polyline(polylineId: const PolylineId('route'),
              points: [_pickupLatLng, _destLatLng],
              color: const Color(0xFF1E6DE5), width: 4),
          },
          zoomControlsEnabled: false, mapToolbarEnabled: false,
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8)],
                ),
                child: const Icon(Icons.arrow_back_ios, color: Color(0xFF1A1A2E), size: 20),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 0, left: 0, right: 0,
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 12),
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E6DE5).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10)),
                  child: Icon(_iconForVehicle(_vehicleName), color: const Color(0xFF1E6DE5), size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(_vehicleName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1A1A2E))),
                  Text('Arriving in $eta mins',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                ])),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text('₹$price', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
                  Text('$distance km', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                ]),
              ]),
              const SizedBox(height: 16),
              _addressRow(Icons.location_on, const Color(0xFF1E6DE5), widget.pickup),
              const Padding(padding: EdgeInsets.only(left: 11), child: Divider(height: 8)),
              _addressRow(Icons.location_searching, Colors.orange, widget.destination),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F7FA), borderRadius: BorderRadius.circular(12)),
                child: Column(children: [
                  _fareRow('Distance', '$distance km'),
                  if (_fare != null) ...[
                    if (_fare!['baseFare'] != null) _fareRow('Base Fare', '₹${_fare!['baseFare']}'),
                    if (_fare!['distanceFare'] != null) _fareRow('Distance Fare', '₹${_fare!['distanceFare']}'),
                    if (_fare!['gst'] != null) _fareRow('GST (5%)', '₹${_fare!['gst']}'),
                  ],
                  const Divider(height: 16),
                  _fareRow('Total Fare', '₹$price', bold: true),
                ]),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity, height: 52,
                child: _confirmed
                  ? ElevatedButton(
                      onPressed: _loading ? null : _confirmBooking,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E6DE5), foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: _loading
                        ? const SizedBox(width: 22, height: 22,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('CONFIRM BOOKING',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                    )
                  : ElevatedButton(
                      onPressed: () => setState(() => _confirmed = true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E6DE5), foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
                      child: const Text('Continue', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
              ),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _addressRow(IconData icon, Color color, String text) {
    return Row(children: [
      Icon(icon, color: color, size: 18),
      const SizedBox(width: 10),
      Expanded(child: Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF1A1A2E)),
        maxLines: 1, overflow: TextOverflow.ellipsis)),
    ]);
  }

  Widget _fareRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(children: [
        Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
        const Spacer(),
        Text(value, style: TextStyle(fontSize: 13,
          fontWeight: bold ? FontWeight.bold : FontWeight.w500,
          color: bold ? const Color(0xFF1A1A2E) : Colors.grey[700])),
      ]),
    );
  }
}
