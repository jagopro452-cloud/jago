import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../../services/trip_service.dart';

class TrackingScreen extends StatefulWidget {
  final Map<String, dynamic> tripData;
  const TrackingScreen({super.key, required this.tripData});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  GoogleMapController? _mapCtrl;
  late Map<String, dynamic> _trip;
  Timer? _pollTimer;
  final Set<Marker> _markers = {};
  bool _showRating = false;
  double _rating = 5;
  bool _ratingSubmitted = false;

  @override
  void initState() {
    super.initState();
    _trip = widget.tripData;
    _startTracking();
    _updateMarkers();
  }

  void _startTracking() {
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) => _pollTrip());
  }

  Future<void> _pollTrip() async {
    final id = _trip['id']?.toString() ?? '';
    if (id.isEmpty) return;
    try {
      final data = await TripService.trackTrip(id);
      if (!mounted) return;
      if (data['trip'] != null) {
        setState(() => _trip = data['trip']);
        _updateMarkers();
        if (_trip['currentStatus'] == 'completed') {
          _pollTimer?.cancel();
          setState(() => _showRating = true);
        }
        if (_trip['currentStatus'] == 'cancelled') {
          _pollTimer?.cancel();
          _showCancelledDialog();
        }
        final driverLat = double.tryParse(_trip['driverLat']?.toString() ?? '');
        final driverLng = double.tryParse(_trip['driverLng']?.toString() ?? '');
        if (driverLat != null && driverLng != null) {
          _mapCtrl?.animateCamera(CameraUpdate.newLatLng(LatLng(driverLat, driverLng)));
        }
      }
    } catch (_) {}
  }

  void _updateMarkers() {
    _markers.clear();
    final pickLat = double.tryParse(_trip['pickupLat']?.toString() ?? '');
    final pickLng = double.tryParse(_trip['pickupLng']?.toString() ?? '');
    final destLat = double.tryParse(_trip['destinationLat']?.toString() ?? '');
    final destLng = double.tryParse(_trip['destinationLng']?.toString() ?? '');
    final driverLat = double.tryParse(_trip['driverLat']?.toString() ?? '');
    final driverLng = double.tryParse(_trip['driverLng']?.toString() ?? '');

    if (pickLat != null && pickLng != null) {
      _markers.add(Marker(markerId: const MarkerId('pickup'), position: LatLng(pickLat, pickLng), icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue), infoWindow: const InfoWindow(title: 'Pickup')));
    }
    if (destLat != null && destLng != null) {
      _markers.add(Marker(markerId: const MarkerId('dest'), position: LatLng(destLat, destLng), icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed), infoWindow: const InfoWindow(title: 'Destination')));
    }
    if (driverLat != null && driverLng != null) {
      _markers.add(Marker(markerId: const MarkerId('driver'), position: LatLng(driverLat, driverLng), icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen), infoWindow: const InfoWindow(title: 'Your Driver')));
    }
  }

  void _showCancelledDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Trip Cancelled'),
        content: Text(_trip['cancelReason'] ?? 'Trip was cancelled'),
        actions: [TextButton(onPressed: () { Navigator.pop(context); Navigator.pop(context); }, child: const Text('OK'))],
      ),
    );
  }

  Future<void> _submitRating() async {
    await TripService.rateDriver(tripId: _trip['id'] ?? '', rating: _rating);
    if (mounted) { setState(() => _ratingSubmitted = true); Navigator.pop(context); }
  }

  void _cancelTrip() {
    showDialog(
      context: context,
      builder: (_) {
        String reason = 'Changed my mind';
        return AlertDialog(
          title: const Text('Cancel Trip'),
          content: DropdownButtonFormField<String>(
            value: reason,
            items: ['Changed my mind', 'Driver too far', 'Wait too long', 'Other'].map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
            onChanged: (v) => reason = v!,
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Back')),
            TextButton(
              onPressed: () async { Navigator.pop(context); await TripService.cancelTrip(_trip['id'] ?? '', reason); if (mounted) Navigator.pop(context); },
              child: const Text('Cancel Trip', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  String get _statusText {
    switch (_trip['currentStatus']) {
      case 'searching': return 'Finding a driver...';
      case 'driver_assigned':
      case 'accepted': return '${_trip['driverName'] ?? 'Driver'} is coming to you';
      case 'arrived': return 'Driver arrived! Show your OTP';
      case 'on_the_way': return 'Ride in progress 🚗';
      case 'completed': return 'Trip Completed ✅';
      default: return 'Processing...';
    }
  }

  @override
  void dispose() { _pollTimer?.cancel(); _mapCtrl?.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    if (_showRating && !_ratingSubmitted) return _buildRatingScreen();

    final pickLat = double.tryParse(_trip['pickupLat']?.toString() ?? '') ?? 17.385044;
    final pickLng = double.tryParse(_trip['pickupLng']?.toString() ?? '') ?? 78.486671;

    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: LatLng(pickLat, pickLng), zoom: 15),
            markers: _markers,
            onMapCreated: (c) => _mapCtrl = c,
            myLocationEnabled: false,
            zoomControlsEnabled: false,
          ),
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.white, Color(0xF0FFFFFF), Colors.transparent]),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10)]),
                    child: Row(
                      children: [
                        Container(width: 36, height: 36, decoration: const BoxDecoration(color: Color(0xFFEFF6FF), shape: BoxShape.circle), child: const Icon(Icons.directions_car, color: Color(0xFF2563EB), size: 18)),
                        const SizedBox(width: 10),
                        Expanded(child: Text(_statusText, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF0F172A)))),
                        if (_trip['currentStatus'] == 'searching' || _trip['currentStatus'] == 'accepted')
                          const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF2563EB))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20)],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_trip['driverName'] != null) ...[
                    Row(
                      children: [
                        Container(width: 50, height: 50, decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.person, color: Color(0xFF2563EB), size: 28)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_trip['driverName'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A))),
                              Text(_trip['vehicleName'] ?? '', style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                            ],
                          ),
                        ),
                        Row(children: [
                          const Icon(Icons.star, color: Colors.amber, size: 16),
                          Text(' ${double.tryParse(_trip['driverRating']?.toString() ?? '5')?.toStringAsFixed(1) ?? '5.0'}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                        ]),
                        const SizedBox(width: 8),
                        Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(12)),
                          child: const Icon(Icons.phone, color: Color(0xFF2563EB), size: 20),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE2E8F0))),
                      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        const Icon(Icons.directions_car, color: Color(0xFF2563EB), size: 16),
                        const SizedBox(width: 6),
                        Text(_trip['vehicleNumber'] ?? _trip['vehiclePlate'] ?? 'XX-0000', style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2, color: Color(0xFF0F172A))),
                      ]),
                    ),
                  ],
                  if (_trip['currentStatus'] == 'arrived') ...[
                    const SizedBox(height: 12),
                    const Text('Your OTP', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFBFDBFE))),
                      child: Center(
                        child: Text(_trip['pickupOtp']?.toString() ?? '----', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF2563EB), letterSpacing: 8)),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text('Share this OTP with your driver to start the ride', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('₹${double.tryParse(_trip['estimatedFare']?.toString() ?? '0')?.toStringAsFixed(0) ?? '0'}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Color(0xFF2563EB))),
                          Text(_trip['paymentMethod']?.toString().toUpperCase() ?? 'CASH', style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                        ],
                      )),
                      if (_trip['currentStatus'] == 'searching' || _trip['currentStatus'] == 'accepted')
                        OutlinedButton(
                          onPressed: _cancelTrip,
                          style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                          child: const Text('Cancel Ride'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingScreen() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(width: 80, height: 80, decoration: const BoxDecoration(color: Color(0xFFEFF6FF), shape: BoxShape.circle), child: const Icon(Icons.check_circle, color: Color(0xFF2563EB), size: 48)),
              const SizedBox(height: 20),
              const Text('Trip Completed!', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
              const SizedBox(height: 8),
              Text('Total: ₹${double.tryParse(_trip['actualFare']?.toString() ?? _trip['estimatedFare']?.toString() ?? '0')?.toStringAsFixed(2)}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
              const SizedBox(height: 40),
              Text('Rate ${_trip['driverName'] ?? 'your driver'}', style: const TextStyle(fontSize: 16, color: Color(0xFF475569))),
              const SizedBox(height: 16),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(5, (i) => GestureDetector(onTap: () => setState(() => _rating = i + 1.0), child: Icon(i < _rating ? Icons.star : Icons.star_border, color: Colors.amber, size: 44)))),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity, height: 52,
                child: ElevatedButton(
                  onPressed: _submitRating,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0),
                  child: const Text('Submit Rating', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Skip', style: TextStyle(color: Color(0xFF94A3B8)))),
            ],
          ),
        ),
      ),
    );
  }
}
