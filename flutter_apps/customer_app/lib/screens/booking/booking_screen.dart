import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../services/trip_service.dart';
import '../tracking/tracking_screen.dart';

class BookingScreen extends StatefulWidget {
  final LatLng currentLatLng;
  const BookingScreen({super.key, required this.currentLatLng});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final _destCtrl = TextEditingController();
  final _pickupCtrl = TextEditingController(text: 'Current Location');
  LatLng? _destLatLng;
  LatLng? _pickupLatLng;
  GoogleMapController? _mapCtrl;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};

  Map<String, dynamic>? _fareData;
  String? _selectedCategoryId;
  String _paymentMethod = 'cash';
  bool _loadingFare = false;
  bool _booking = false;
  bool _showFares = false;
  String? _couponCode;
  double? _discount;
  int _step = 0;

  @override
  void initState() {
    super.initState();
    _pickupLatLng = widget.currentLatLng;
    _markers.add(Marker(
      markerId: const MarkerId('pickup'),
      position: widget.currentLatLng,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      infoWindow: const InfoWindow(title: 'Pickup'),
    ));
  }

  Future<void> _estimateFare() async {
    if (_destLatLng == null || _pickupLatLng == null) return;
    setState(() { _loadingFare = true; _showFares = false; });
    final res = await TripService.estimateFare(
      pickupLat: _pickupLatLng!.latitude, pickupLng: _pickupLatLng!.longitude,
      destLat: _destLatLng!.latitude, destLng: _destLatLng!.longitude,
    );
    if (mounted && res['success'] == true) {
      setState(() { _fareData = res; _showFares = true; _step = 1; _loadingFare = false; });
      final categories = (res['categories'] as List?) ?? [];
      if (categories.isNotEmpty) setState(() => _selectedCategoryId = categories[0]['id']?.toString());
      _fitBounds();
    } else {
      setState(() => _loadingFare = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Estimate failed')));
    }
  }

  void _fitBounds() {
    if (_pickupLatLng == null || _destLatLng == null) return;
    final bounds = LatLngBounds(
      southwest: LatLng(
        _pickupLatLng!.latitude < _destLatLng!.latitude ? _pickupLatLng!.latitude : _destLatLng!.latitude,
        _pickupLatLng!.longitude < _destLatLng!.longitude ? _pickupLatLng!.longitude : _destLatLng!.longitude,
      ),
      northeast: LatLng(
        _pickupLatLng!.latitude > _destLatLng!.latitude ? _pickupLatLng!.latitude : _destLatLng!.latitude,
        _pickupLatLng!.longitude > _destLatLng!.longitude ? _pickupLatLng!.longitude : _destLatLng!.longitude,
      ),
    );
    _mapCtrl?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 80));
  }

  void _onMapTap(LatLng pos) {
    if (_step == 0) {
      setState(() {
        _destLatLng = pos;
        _destCtrl.text = '${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}';
        _markers.removeWhere((m) => m.markerId.value == 'dest');
        _markers.add(Marker(markerId: const MarkerId('dest'), position: pos, infoWindow: const InfoWindow(title: 'Destination'), icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed)));
      });
    }
  }

  Future<void> _bookRide() async {
    if (_selectedCategoryId == null || _destLatLng == null) return;
    setState(() => _booking = true);
    final cats = (_fareData?['categories'] as List?) ?? [];
    final cat = cats.firstWhere((c) => c['id']?.toString() == _selectedCategoryId, orElse: () => cats.isNotEmpty ? cats[0] : {});
    final fare = double.tryParse(cat['estimatedFare']?.toString() ?? '0') ?? 0;
    final dist = double.tryParse(_fareData?['distance']?.toString() ?? '0') ?? 0;
    final effectiveFare = fare - (_discount ?? 0);

    final res = await TripService.bookRide(
      pickupAddress: _pickupCtrl.text,
      pickupLat: _pickupLatLng!.latitude, pickupLng: _pickupLatLng!.longitude,
      destAddress: _destCtrl.text,
      destLat: _destLatLng!.latitude, destLng: _destLatLng!.longitude,
      vehicleCategoryId: _selectedCategoryId!,
      estimatedFare: effectiveFare, estimatedDistance: dist,
      paymentMethod: _paymentMethod,
    );
    setState(() => _booking = false);

    if (res['success'] == true && mounted) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => TrackingScreen(tripData: res['trip'])));
    } else {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Booking failed')));
    }
  }

  void _showCouponDialog() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Apply Coupon'),
        content: TextField(controller: ctrl, decoration: const InputDecoration(hintText: 'Enter coupon code', border: OutlineInputBorder())),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
            onPressed: () async {
              Navigator.pop(context);
              final cats = (_fareData?['categories'] as List?) ?? [];
              final cat = cats.firstWhere((c) => c['id']?.toString() == _selectedCategoryId, orElse: () => cats.isNotEmpty ? cats[0] : {});
              final fare = double.tryParse(cat['estimatedFare']?.toString() ?? '0') ?? 0;
              final res = await TripService.applyCoupon(code: ctrl.text.trim(), fareAmount: fare);
              if (res['success'] == true && mounted) {
                setState(() { _couponCode = ctrl.text.trim(); _discount = double.tryParse(res['discount']?.toString() ?? '0'); });
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Coupon applied! Save ₹${_discount?.toStringAsFixed(2)}')));
              } else if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Invalid coupon')));
              }
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF0F172A)), onPressed: () => Navigator.pop(context)),
        title: const Text('Book a Ride', style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          Expanded(
            flex: _showFares ? 4 : 7,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(target: widget.currentLatLng, zoom: 14),
              markers: _markers,
              polylines: _polylines,
              onMapCreated: (c) => _mapCtrl = c,
              onTap: _onMapTap,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
            ),
          ),
          Expanded(
            flex: _showFares ? 6 : 3,
            child: Container(
              color: Colors.white,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: _showFares ? _buildFareSelection() : _buildSearchPanel(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchPanel() {
    return Column(
      children: [
        _locationField(Icons.my_location, const Color(0xFF2563EB), 'Pickup', _pickupCtrl, readOnly: true),
        const SizedBox(height: 10),
        _locationField(Icons.location_on, const Color(0xFFEF4444), 'Destination', _destCtrl),
        const SizedBox(height: 16),
        const Text('Tap on map to select destination', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity, height: 50,
          child: ElevatedButton(
            onPressed: _destLatLng == null || _loadingFare ? null : _estimateFare,
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
            child: _loadingFare ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('See Available Rides', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Widget _locationField(IconData icon, Color color, String hint, TextEditingController ctrl, {bool readOnly = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Row(children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 10),
        Expanded(child: TextField(
          controller: ctrl,
          readOnly: readOnly,
          style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A)),
          decoration: InputDecoration(hintText: hint, hintStyle: const TextStyle(color: Color(0xFF94A3B8)), border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(vertical: 12)),
        )),
      ]),
    );
  }

  Widget _buildFareSelection() {
    final cats = (_fareData?['categories'] as List?) ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.directions_car, color: Color(0xFF2563EB), size: 16),
            const SizedBox(width: 6),
            Text('${_fareData?['distance']?.toStringAsFixed(1) ?? '0'} km • ${_fareData?['duration'] ?? '—'} min', style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
            const Spacer(),
            TextButton(onPressed: () => setState(() { _showFares = false; _step = 0; }), child: const Text('Change', style: TextStyle(color: Color(0xFF2563EB)))),
          ],
        ),
        const SizedBox(height: 12),
        ...cats.map((cat) => _categoryCard(cat)),
        const SizedBox(height: 12),
        _paymentRow(),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: _showCouponDialog,
          icon: const Icon(Icons.local_offer, size: 16, color: Color(0xFF2563EB)),
          label: Text(_couponCode != null ? 'Coupon: $_couponCode (−₹${_discount?.toStringAsFixed(0)})' : 'Apply Coupon', style: const TextStyle(color: Color(0xFF2563EB))),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity, height: 52,
          child: ElevatedButton(
            onPressed: _booking ? null : _bookRide,
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0),
            child: _booking ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2) : const Text('Confirm Booking', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ),
      ],
    );
  }

  Widget _categoryCard(Map<String, dynamic> cat) {
    final id = cat['id']?.toString() ?? '';
    final fare = double.tryParse(cat['estimatedFare']?.toString() ?? '0') ?? 0;
    final selected = _selectedCategoryId == id;
    return GestureDetector(
      onTap: () => setState(() => _selectedCategoryId = id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0), width: selected ? 2 : 1),
        ),
        child: Row(
          children: [
            Icon(Icons.directions_car, color: selected ? const Color(0xFF2563EB) : const Color(0xFF94A3B8), size: 28),
            const SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(cat['name'] ?? 'Ride', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: selected ? const Color(0xFF1D4ED8) : const Color(0xFF0F172A))),
                Text('${cat['capacity'] ?? '4'} seats • ${cat['eta'] ?? '—'} min away', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
              ],
            )),
            Text('₹${fare.toStringAsFixed(0)}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: selected ? const Color(0xFF2563EB) : const Color(0xFF0F172A))),
            if (selected) const Padding(padding: EdgeInsets.only(left: 8), child: Icon(Icons.check_circle, color: Color(0xFF2563EB), size: 20)),
          ],
        ),
      ),
    );
  }

  Widget _paymentRow() {
    final methods = [('cash', Icons.money, 'Cash'), ('wallet', Icons.account_balance_wallet, 'Wallet'), ('upi', Icons.payment, 'UPI')];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Payment Method', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF475569))),
        const SizedBox(height: 8),
        Row(
          children: methods.map((m) => GestureDetector(
            onTap: () => setState(() => _paymentMethod = m.$1),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _paymentMethod == m.$1 ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _paymentMethod == m.$1 ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0)),
              ),
              child: Row(children: [
                Icon(m.$2, size: 16, color: _paymentMethod == m.$1 ? const Color(0xFF2563EB) : const Color(0xFF94A3B8)),
                const SizedBox(width: 4),
                Text(m.$3, style: TextStyle(fontSize: 12, color: _paymentMethod == m.$1 ? const Color(0xFF2563EB) : const Color(0xFF64748B), fontWeight: FontWeight.w600)),
              ]),
            ),
          )).toList(),
        ),
      ],
    );
  }
}
