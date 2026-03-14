import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import '../../services/auth_service.dart';
import '../booking/booking_screen.dart';

class TripsHistoryScreen extends StatefulWidget {
  const TripsHistoryScreen({super.key});
  @override
  State<TripsHistoryScreen> createState() => _TripsHistoryScreenState();
}

class _TripsHistoryScreenState extends State<TripsHistoryScreen> {
  List<dynamic> _trips = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _fetchTrips(); }

  Future<void> _fetchTrips() async {
    final headers = await AuthService.getHeaders();
    try {
      final res = await http.get(Uri.parse(ApiConfig.trips), headers: headers);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (mounted) setState(() { _trips = data['trips'] ?? []; _loading = false; });
      } else {
        if (mounted) setState(() => _loading = false);
      }
    } catch (_) { if (mounted) setState(() => _loading = false); }
  }

  Future<void> _showReceipt(BuildContext ctx, String tripId) async {
    showDialog(context: ctx, barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: Color(0xFF2F80ED))));
    try {
      final headers = await AuthService.getHeaders();
      final res = await http.get(Uri.parse(ApiConfig.tripReceipt(tripId)),
        headers: headers);
      if (!mounted) return;
      Navigator.pop(ctx); // close loader
      if (res.statusCode == 200) {
        final receipt = jsonDecode(res.body)['receipt'];
        _showReceiptDialog(ctx, receipt);
      } else {
        ScaffoldMessenger.of(ctx).showSnackBar(
          const SnackBar(content: Text('Receipt not available'), backgroundColor: Colors.red));
      }
    } catch (_) {
      if (mounted) {
        Navigator.pop(ctx);
        ScaffoldMessenger.of(ctx).showSnackBar(
          const SnackBar(content: Text('Could not load receipt'), backgroundColor: Colors.red));
      }
    }
  }

  void _showReceiptDialog(BuildContext ctx, Map<String, dynamic> r) {
    final fare = r['fare'] ?? {};
    final vehicle = r['vehicle'] ?? {};
    final driver = r['driver'] ?? {};
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          // Header
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Trip Receipt', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
              Text(r['receiptNo'] ?? '', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
            ]),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: const Color(0xFF2F80ED).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: const Text('PAID', style: TextStyle(color: Color(0xFF2F80ED), fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          ]),
          const SizedBox(height: 16),
          const Divider(),
          // Route
          _receiptRow(Icons.my_location, 'Pickup', r['pickup']?['address'] ?? '', const Color(0xFF22C55E)),
          const SizedBox(height: 8),
          _receiptRow(Icons.location_on, 'Drop', r['destination']?['address'] ?? '', Colors.red),
          const Divider(),
          // Driver & Vehicle
          if (driver['name'] != null) _infoRow('Driver', driver['name'] ?? ''),
          if (vehicle['name'] != null) _infoRow('Vehicle', '${vehicle['name']} ${vehicle['number'] ?? ''}'),
          if ((r['distanceKm'] ?? 0) > 0) _infoRow('Distance', '${r['distanceKm']} km'),
          const Divider(),
          // Fare breakdown
          _fareRow('Base Fare', fare['baseFare'] ?? 0),
          if ((fare['distanceFare'] ?? 0) > 0) _fareRow('Distance Fare', fare['distanceFare'] ?? 0),
          if ((fare['waitingCharge'] ?? 0) > 0) _fareRow('Waiting', fare['waitingCharge'] ?? 0),
          if ((fare['discount'] ?? 0) > 0) _fareRow('Discount', fare['discount'] ?? 0, isDiscount: true),
          _fareRow('GST (5%)', fare['gst'] ?? 0, isGst: true),
          const Divider(),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Total Paid', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1A1A2E))),
            Text('₹${fare['payable'] ?? fare['total'] ?? 0}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF2F80ED))),
          ]),
          const SizedBox(height: 6),
          Row(children: [
            const Icon(Icons.payment, size: 14, color: Colors.grey),
            const SizedBox(width: 4),
            Text('Paid via ${(fare['paymentMethod'] ?? 'cash').toUpperCase()}',
              style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ]),
          const SizedBox(height: 20),
          SizedBox(width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2F80ED),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14)),
              child: const Text('Close', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )),
        ])),
      ),
    );
  }

  Widget _receiptRow(IconData icon, String label, String value, Color color) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, size: 16, color: color),
      const SizedBox(width: 8),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF1A1A2E))),
      ])),
    ]);
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF1A1A2E))),
      ]),
    );
  }

  Widget _fareRow(String label, dynamic amount, {bool isDiscount = false, bool isGst = false}) {
    final color = isDiscount ? Colors.green : isGst ? Colors.orange[700]! : const Color(0xFF1A1A2E);
    final prefix = isDiscount ? '-' : '';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(fontSize: 13, color: isGst ? Colors.orange[700] : Colors.grey[700])),
        Text('$prefix₹$amount', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: color)),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF1A1A2E)), onPressed: () => Navigator.pop(context)),
        title: const Text('My Rides', style: TextStyle(color: Color(0xFF1A1A2E), fontWeight: FontWeight.bold)),
      ),
      body: _loading
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF2F80ED)))
        : _trips.isEmpty
          ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.receipt_long_outlined, size: 80, color: Colors.grey[300]),
              const SizedBox(height: 16),
              Text('No rides yet', style: TextStyle(color: Colors.grey[500], fontSize: 16, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Text('Your completed rides will appear here', style: TextStyle(color: Colors.grey[400], fontSize: 13)),
            ]))
          : RefreshIndicator(
              onRefresh: _fetchTrips,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _trips.length,
                itemBuilder: (ctx, i) {
                  final t = _trips[i];
                  final status = t['currentStatus'] ?? t['status'] ?? '';
                  final isCompleted = status == 'completed';
                  final isCancelled = status == 'cancelled';
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))]),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(
                            color: (isCompleted ? const Color(0xFF2F80ED) : isCancelled ? Colors.red : Colors.orange).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12)),
                          child: Icon(
                            isCompleted ? Icons.check_circle_outline : isCancelled ? Icons.cancel_outlined : Icons.directions_bike,
                            color: isCompleted ? const Color(0xFF2F80ED) : isCancelled ? Colors.red : Colors.orange,
                            size: 24)),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(t['destinationAddress'] ?? 'Destination',
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E))),
                          const SizedBox(height: 4),
                          Text(t['pickupAddress'] ?? '',
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                        ])),
                        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                          Text('₹${t['actualFare'] ?? t['estimatedFare'] ?? '0'}',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E), fontSize: 16)),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: (isCompleted ? Colors.green : isCancelled ? Colors.red : Colors.orange).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6)),
                            child: Text(isCompleted ? 'Completed' : isCancelled ? 'Cancelled' : status,
                              style: TextStyle(
                                fontSize: 11, fontWeight: FontWeight.w500,
                                color: isCompleted ? Colors.green : isCancelled ? Colors.red : Colors.orange))),
                        ]),
                      ]),
                      if (isCompleted) ...[
                        const SizedBox(height: 10),
                        Row(children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _showReceipt(ctx, t['id'] ?? t['tripId'] ?? ''),
                              icon: const Icon(Icons.receipt_long, size: 15, color: Color(0xFF2F80ED)),
                              label: const Text('Receipt', style: TextStyle(fontSize: 12, color: Color(0xFF2F80ED), fontWeight: FontWeight.w600)),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFFBFDBFE)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.symmetric(vertical: 8)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if ((t['destinationAddress'] ?? '').isNotEmpty) Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => Navigator.push(context, MaterialPageRoute(
                                builder: (_) => BookingScreen(
                                  pickup: t['pickupAddress'] ?? 'Current Location',
                                  destination: t['destinationAddress'] ?? '',
                                  pickupLat: double.tryParse(t['pickupLat']?.toString() ?? t['pickup_lat']?.toString() ?? '17.3850') ?? 17.3850,
                                  pickupLng: double.tryParse(t['pickupLng']?.toString() ?? t['pickup_lng']?.toString() ?? '78.4867') ?? 78.4867,
                                  destLat: double.tryParse(t['destinationLat']?.toString() ?? t['destination_lat']?.toString() ?? '0') ?? 0,
                                  destLng: double.tryParse(t['destinationLng']?.toString() ?? t['destination_lng']?.toString() ?? '0') ?? 0,
                                  vehicleCategoryId: t['vehicleCategoryId']?.toString() ?? t['vehicle_category_id']?.toString(),
                                  vehicleCategoryName: t['vehicleCategoryName']?.toString() ?? t['vehicle_category_name']?.toString(),
                                ),
                              )),
                              icon: const Icon(Icons.refresh_rounded, size: 15, color: Color(0xFF2F80ED)),
                              label: const Text('Book Again', style: TextStyle(fontSize: 12, color: Color(0xFF2F80ED), fontWeight: FontWeight.w600)),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFFBFDBFE)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.symmetric(vertical: 8)),
                            ),
                          ),
                        ]),
                      ],
                    ]),
                  );
                }),
            ),
    );
  }
}
