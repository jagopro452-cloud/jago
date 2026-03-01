import 'dart:async';
import 'package:flutter/material.dart';
import '../models/trip_model.dart';

class IncomingTripSheet extends StatefulWidget {
  final TripModel trip;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  const IncomingTripSheet({super.key, required this.trip, required this.onAccept, required this.onReject});

  @override
  State<IncomingTripSheet> createState() => _IncomingTripSheetState();
}

class _IncomingTripSheetState extends State<IncomingTripSheet> {
  int _seconds = 30;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_seconds <= 0) {
        t.cancel();
        widget.onReject();
      } else {
        if (mounted) setState(() => _seconds--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.trip;
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF091629),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF1E3A5F)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 20)],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(color: const Color(0xFF1E3A5F), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.person, color: Color(0xFF3B82F6)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t.customerName ?? 'Customer', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      Row(children: [
                        const Icon(Icons.star, color: Colors.amber, size: 14),
                        Text(' ${t.customerRating.toStringAsFixed(1)}', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
                      ]),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('₹${t.estimatedFare.toStringAsFixed(0)}', style: const TextStyle(color: Color(0xFF3B82F6), fontSize: 22, fontWeight: FontWeight.bold)),
                    Text('${t.estimatedDistance.toStringAsFixed(1)} km', style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            _locationRow(Icons.my_location, const Color(0xFF3B82F6), 'Pickup', t.pickupAddress),
            const SizedBox(height: 8),
            _locationRow(Icons.location_on, const Color(0xFFEF4444), 'Drop', t.destinationAddress),
            const SizedBox(height: 16),
            Row(
              children: [
                _pill(Icons.payment, t.paymentMethod.toUpperCase()),
                const SizedBox(width: 8),
                _pill(Icons.directions_car, t.vehicleName ?? 'Ride'),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: widget.onReject,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFEF4444),
                      side: const BorderSide(color: Color(0xFFEF4444)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('✕  Decline', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: widget.onAccept,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: Text('Accept ($_seconds)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _locationRow(IconData icon, Color color, String label, String address) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 11)),
              Text(address, style: const TextStyle(color: Colors.white, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }

  Widget _pill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: const Color(0xFF060D1E), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFF1E3A5F))),
      child: Row(children: [
        Icon(icon, size: 14, color: const Color(0xFF64748B)),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
      ]),
    );
  }
}
