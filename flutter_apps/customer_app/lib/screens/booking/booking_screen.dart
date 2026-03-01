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
  final double pickupLat, pickupLng, destLat, destLng;
  final String? vehicleCategoryId;
  final String? vehicleCategoryName;
  const BookingScreen({
    super.key,
    required this.pickup,
    required this.destination,
    this.pickupLat = 17.3850, this.pickupLng = 78.4867,
    this.destLat = 0, this.destLng = 0,
    this.vehicleCategoryId,
    this.vehicleCategoryName,
  });
  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  GoogleMapController? _mapController;
  bool _loading = false;
  bool _estimating = true;
  Map<String, dynamic>? _fare;
  String _paymentMethod = 'cash';

  LatLng get _pickupLatLng => LatLng(widget.pickupLat, widget.pickupLng);
  LatLng get _destLatLng => widget.destLat != 0 && widget.destLng != 0
    ? LatLng(widget.destLat, widget.destLng)
    : LatLng(widget.pickupLat + 0.02, widget.pickupLng + 0.02);

  String get _vehicleName => widget.vehicleCategoryName ?? 'Bike';

  static IconData _iconForVehicle(String name) {
    final n = name.toLowerCase();
    if (n.contains('bike parcel') || n.contains('parcel bike')) return Icons.delivery_dining;
    if (n.contains('bike')) return Icons.electric_bike;
    if (n.contains('mini auto') || n.contains('temo auto')) return Icons.electric_rickshaw;
    if (n.contains('auto')) return Icons.electric_rickshaw;
    if (n.contains('tata ace') || n.contains('mini cargo')) return Icons.local_shipping;
    if (n.contains('cargo truck')) return Icons.fire_truck;
    if (n.contains('cargo')) return Icons.local_shipping;
    if (n.contains('parcel')) return Icons.delivery_dining;
    if (n.contains('suv')) return Icons.directions_car;
    if (n.contains('car')) return Icons.directions_car_filled;
    return Icons.directions_car;
  }

  double get _distanceKm {
    if (widget.destLat == 0 && widget.destLng == 0) return 3.0;
    final dlat = widget.destLat - widget.pickupLat;
    final dlng = widget.destLng - widget.pickupLng;
    return ((dlat * dlat + dlng * dlng) * 12321).clamp(0.5, 100.0);
  }

  @override
  void initState() {
    super.initState();
    _estimateFare();
  }

  Future<void> _estimateFare() async {
    setState(() => _estimating = true);
    final token = await AuthService.getToken();
    try {
      final body = <String, dynamic>{
        'pickupLat': widget.pickupLat,
        'pickupLng': widget.pickupLng,
        'destLat': widget.destLat,
        'destLng': widget.destLng,
        'distanceKm': _distanceKm,
      };
      if (widget.vehicleCategoryId != null) body['vehicleCategoryId'] = widget.vehicleCategoryId;
      final res = await http.post(Uri.parse(ApiConfig.estimateFare),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final fares = data['fares'] as List<dynamic>?;
        if (fares != null && fares.isNotEmpty) {
          setState(() => _fare = (fares[0] as Map<String, dynamic>));
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _estimating = false);
  }

  Future<void> _confirmBooking() async {
    setState(() => _loading = true);
    final token = await AuthService.getToken();
    try {
      final body = <String, dynamic>{
        'pickupAddress': widget.pickup,
        'destinationAddress': widget.destination,
        'pickupLat': widget.pickupLat,
        'pickupLng': widget.pickupLng,
        'destinationLat': widget.destLat,
        'destinationLng': widget.destLng,
        'estimatedFare': _fare?['estimatedFare'] ?? 0,
        'estimatedDistance': _distanceKm,
        'paymentMethod': _paymentMethod,
      };
      if (widget.vehicleCategoryId != null) body['vehicleCategoryId'] = widget.vehicleCategoryId;
      final res = await http.post(Uri.parse(ApiConfig.bookRide),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final tripId = data['trip']?['id'] ?? '';
        if (!mounted) return;
        Navigator.pushReplacement(context, MaterialPageRoute(
          builder: (_) => TrackingScreen(tripId: tripId)));
      } else {
        if (!mounted) return;
        final err = jsonDecode(res.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err['message'] ?? 'Booking failed'),
            backgroundColor: Colors.red));
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Network error. Try again.'), backgroundColor: Colors.red));
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final fare = _fare;
    final price = fare?['estimatedFare'];
    final eta = fare?['estimatedTime'] ?? '~5 min';

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(target: _pickupLatLng, zoom: 13),
          onMapCreated: (c) {
            _mapController = c;
            Future.delayed(const Duration(milliseconds: 500), () {
              _mapController?.animateCamera(CameraUpdate.newLatLngBounds(
                LatLngBounds(
                  southwest: LatLng(
                    _pickupLatLng.latitude < _destLatLng.latitude ? _pickupLatLng.latitude : _destLatLng.latitude,
                    _pickupLatLng.longitude < _destLatLng.longitude ? _pickupLatLng.longitude : _destLatLng.longitude,
                  ),
                  northeast: LatLng(
                    _pickupLatLng.latitude > _destLatLng.latitude ? _pickupLatLng.latitude : _destLatLng.latitude,
                    _pickupLatLng.longitude > _destLatLng.longitude ? _pickupLatLng.longitude : _destLatLng.longitude,
                  ),
                ),
                80,
              ));
            });
          },
          markers: {
            Marker(
              markerId: const MarkerId('pickup'),
              position: _pickupLatLng,
              infoWindow: InfoWindow(title: 'Pickup', snippet: widget.pickup),
            ),
            Marker(
              markerId: const MarkerId('dest'),
              position: _destLatLng,
              infoWindow: InfoWindow(title: 'Drop', snippet: widget.destination),
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
            ),
          },
          polylines: {
            Polyline(
              polylineId: const PolylineId('route'),
              points: [_pickupLatLng, _destLatLng],
              color: const Color(0xFF1E6DE5), width: 4,
              patterns: [PatternItem.dash(20), PatternItem.gap(10)],
            ),
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
                  Text(eta.toString(),
                    style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                ])),
                if (_estimating)
                  const SizedBox(width: 22, height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1E6DE5)))
                else
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text(price != null ? '₹${price.toString()}' : '--',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
                    Text('${_distanceKm.toStringAsFixed(1)} km',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                  ]),
              ]),
              const SizedBox(height: 12),
              _addressRow(Icons.location_on, const Color(0xFF1E6DE5), widget.pickup),
              const Padding(padding: EdgeInsets.only(left: 11), child: Divider(height: 8)),
              _addressRow(Icons.flag, Colors.orange, widget.destination),
              const SizedBox(height: 12),
              if (fare != null)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F7FA), borderRadius: BorderRadius.circular(12)),
                  child: Column(children: [
                    _fareRow('Base Fare', '₹${fare['baseFare'] ?? 0}'),
                    _fareRow('Distance Fare', '₹${fare['distanceFare'] ?? 0}'),
                    if ((fare['helperCharge'] ?? 0) > 0)
                      _fareRow('Helper Charge', '₹${fare['helperCharge']}'),
                    _fareRow('GST (5%)', '₹${fare['gst'] ?? 0}'),
                    const Divider(height: 12),
                    _fareRow('Total', '₹${fare['estimatedFare'] ?? 0}', bold: true),
                  ]),
                ),
              const SizedBox(height: 12),
              Row(children: [
                const Text('Payment:', style: TextStyle(fontSize: 13, color: Color(0xFF1A1A2E))),
                const SizedBox(width: 8),
                _payBtn('cash', Icons.money, 'Cash'),
                const SizedBox(width: 8),
                _payBtn('wallet', Icons.account_balance_wallet, 'Wallet'),
              ]),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity, height: 52,
                child: ElevatedButton(
                  onPressed: _loading || _estimating ? null : _confirmBooking,
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
                ),
              ),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _payBtn(String method, IconData icon, String label) {
    final selected = _paymentMethod == method;
    return GestureDetector(
      onTap: () => setState(() => _paymentMethod = method),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF1E6DE5) : const Color(0xFFF5F7FA),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: selected ? const Color(0xFF1E6DE5) : Colors.transparent)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 15, color: selected ? Colors.white : Colors.grey[600]),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
            color: selected ? Colors.white : Colors.grey[700])),
        ]),
      ),
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
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        const Spacer(),
        Text(value, style: TextStyle(fontSize: 12,
          fontWeight: bold ? FontWeight.bold : FontWeight.w500,
          color: bold ? const Color(0xFF1A1A2E) : Colors.grey[800])),
      ]),
    );
  }
}
