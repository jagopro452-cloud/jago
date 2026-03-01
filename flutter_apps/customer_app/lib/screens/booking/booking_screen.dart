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
  const BookingScreen({super.key, required this.pickup, required this.destination});
  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  GoogleMapController? _mapController;
  bool _loading = false;
  bool _confirmed = false;
  Map<String, dynamic>? _fare;
  int _selectedRide = 0;

  final LatLng _pickupLatLng = const LatLng(12.9716, 77.5946);
  final LatLng _destLatLng = const LatLng(12.9800, 77.6100);

  final List<String> _rideLabels = ['Bike', 'Car', 'Delivery'];
  final List<IconData> _rideIcons = [Icons.electric_bike, Icons.directions_car, Icons.delivery_dining];
  final List<int> _ridePrices = [50, 80, 55];

  @override
  void initState() {
    super.initState();
    _estimateFare();
  }

  Future<void> _estimateFare() async {
    final token = await AuthService.getToken();
    try {
      final res = await http.post(Uri.parse(ApiConfig.estimateFare),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: jsonEncode({
          'pickupLat': _pickupLatLng.latitude, 'pickupLng': _pickupLatLng.longitude,
          'destinationLat': _destLatLng.latitude, 'destinationLng': _destLatLng.longitude,
          'vehicleType': _rideLabels[_selectedRide].toLowerCase(),
        }),
      );
      if (res.statusCode == 200) setState(() => _fare = jsonDecode(res.body));
    } catch (_) {}
  }

  Future<void> _confirmBooking() async {
    setState(() => _loading = true);
    final token = await AuthService.getToken();
    try {
      final res = await http.post(Uri.parse(ApiConfig.bookRide),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: jsonEncode({
          'pickupAddress': widget.pickup, 'destinationAddress': widget.destination,
          'pickupLat': _pickupLatLng.latitude, 'pickupLng': _pickupLatLng.longitude,
          'destinationLat': _destLatLng.latitude, 'destinationLng': _destLatLng.longitude,
          'paymentMethod': 'cash', 'vehicleType': _rideLabels[_selectedRide].toLowerCase(),
        }),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        Navigator.pushReplacement(context, MaterialPageRoute(
          builder: (_) => TrackingScreen(tripId: data['tripId'] ?? '')));
      }
    } catch (_) {}
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final price = _fare?['estimatedFare'] ?? _ridePrices[_selectedRide];
    final distance = _fare?['distance'] ?? 7.4;

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
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Row(children: [
                Container(width: 40, height: 4,
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
                const Spacer(),
                Text('${_fare?['estimatedTime'] ?? 4} mins', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
              ]),
              const SizedBox(height: 16),
              _addressRow(Icons.location_on, const Color(0xFF1E6DE5), widget.pickup),
              const Padding(padding: EdgeInsets.only(left: 11), child: Divider(height: 8)),
              _addressRow(Icons.location_searching, Colors.orange, widget.destination),
              const SizedBox(height: 16),
              Row(children: [
                for (int i = 0; i < _rideLabels.length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(child: _miniRideCard(i)),
                ],
              ]),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F7FA), borderRadius: BorderRadius.circular(12)),
                child: Column(children: [
                  _fareRow('Distance', '${distance} km'),
                  _fareRow('Flat Fare', '₹${_ridePrices[_selectedRide]}'),
                  if (_selectedRide == 2) _fareRow('Delivery', '₹55'),
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
                        backgroundColor: Colors.white, foregroundColor: const Color(0xFF1E6DE5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: Color(0xFF1E6DE5), width: 1.5)),
                        elevation: 0,
                      ),
                      child: _loading
                        ? const SizedBox(width: 22, height: 22,
                            child: CircularProgressIndicator(color: Color(0xFF1E6DE5), strokeWidth: 2))
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

  Widget _miniRideCard(int i) {
    final sel = _selectedRide == i;
    return GestureDetector(
      onTap: () { setState(() => _selectedRide = i); _estimateFare(); },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: sel ? const Color(0xFF1E6DE5) : const Color(0xFFF5F7FA),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: sel ? const Color(0xFF1E6DE5) : Colors.transparent)),
        child: Column(children: [
          Icon(_rideIcons[i], color: sel ? Colors.white : Colors.grey[600], size: 22),
          const SizedBox(height: 2),
          Text(_rideLabels[i], style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
            color: sel ? Colors.white : Colors.grey[700])),
        ]),
      ),
    );
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
