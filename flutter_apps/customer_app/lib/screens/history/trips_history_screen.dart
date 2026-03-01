import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/trip_service.dart';

class TripsHistoryScreen extends StatefulWidget {
  const TripsHistoryScreen({super.key});

  @override
  State<TripsHistoryScreen> createState() => _TripsHistoryScreenState();
}

class _TripsHistoryScreenState extends State<TripsHistoryScreen> {
  List<dynamic> _trips = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    _trips = await TripService.getTripHistory();
    if (mounted) setState(() => _loading = false);
  }

  Color _statusColor(String status) {
    if (status == 'completed') return const Color(0xFF22C55E);
    if (status == 'cancelled') return const Color(0xFFEF4444);
    return const Color(0xFF2563EB);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(backgroundColor: Colors.white, title: const Text('My Trips', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A))), centerTitle: true),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF2563EB)))
          : _trips.isEmpty
              ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.directions_car, size: 60, color: Color(0xFFCBD5E1)),
                  SizedBox(height: 16),
                  Text('No trips yet', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 16)),
                  SizedBox(height: 8),
                  Text('Book your first ride!', style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 13)),
                ]))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _trips.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _tripCard(_trips[i]),
                ),
    );
  }

  Widget _tripCard(dynamic t) {
    final status = t['currentStatus'] ?? t['current_status'] ?? '';
    final color = _statusColor(status);
    final fare = double.tryParse(t['actualFare']?.toString() ?? t['estimatedFare']?.toString() ?? '0') ?? 0;
    final createdAt = t['createdAt'] != null ? DateTime.tryParse(t['createdAt']) : null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(
        children: [
          Row(children: [
            Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Text(status.toUpperCase(), style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold))),
            const Spacer(),
            Text(createdAt != null ? DateFormat('dd MMM yyyy').format(createdAt) : '', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            const Icon(Icons.my_location, color: Color(0xFF2563EB), size: 16),
            const SizedBox(width: 8),
            Expanded(child: Text(t['pickupAddress'] ?? t['pickup_address'] ?? '', style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis)),
          ]),
          const SizedBox(height: 6),
          Row(children: [
            const Icon(Icons.location_on, color: Color(0xFFEF4444), size: 16),
            const SizedBox(width: 8),
            Expanded(child: Text(t['destinationAddress'] ?? t['destination_address'] ?? '', style: const TextStyle(color: Color(0xFF64748B), fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis)),
          ]),
          const Divider(color: Color(0xFFE2E8F0), height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                const Icon(Icons.person, color: Color(0xFF94A3B8), size: 14),
                const SizedBox(width: 4),
                Text(t['driverName'] ?? 'Driver', style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
              ]),
              Row(children: [
                const Icon(Icons.star, color: Colors.amber, size: 14),
                Text(' ${double.tryParse(t['driverRating']?.toString() ?? '5')?.toStringAsFixed(1) ?? '5.0'}', style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
              ]),
              Text('₹${fare.toStringAsFixed(0)}', style: const TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
        ],
      ),
    );
  }
}
