import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/trip_model.dart';
import '../../services/trip_service.dart';

class TripsHistoryScreen extends StatefulWidget {
  const TripsHistoryScreen({super.key});

  @override
  State<TripsHistoryScreen> createState() => _TripsHistoryScreenState();
}

class _TripsHistoryScreenState extends State<TripsHistoryScreen> {
  List<TripModel> _trips = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    _trips = await TripService.getTripHistory();
    if (mounted) setState(() => _loading = false);
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'completed': return const Color(0xFF22C55E);
      case 'cancelled': return const Color(0xFFEF4444);
      default: return const Color(0xFF3B82F6);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060D1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF060D1E),
        title: const Text('Trip History', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6)))
          : _trips.isEmpty
              ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.receipt_long, size: 60, color: Color(0xFF1E3A5F)),
                  SizedBox(height: 16),
                  Text('No trips yet', style: TextStyle(color: Color(0xFF64748B), fontSize: 16)),
                ]))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _trips.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _tripCard(_trips[i]),
                ),
    );
  }

  Widget _tripCard(TripModel t) {
    final color = _statusColor(t.currentStatus);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF091629),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E3A5F)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Text(t.currentStatus.toUpperCase(), style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
              const Spacer(),
              Text(t.createdAt != null ? DateFormat('dd MMM yyyy').format(t.createdAt!) : '', style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
            ],
          ),
          const SizedBox(height: 12),
          Row(children: [
            const Icon(Icons.my_location, color: Color(0xFF3B82F6), size: 16),
            const SizedBox(width: 8),
            Expanded(child: Text(t.pickupAddress, style: const TextStyle(color: Colors.white, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis)),
          ]),
          const SizedBox(height: 6),
          Row(children: [
            const Icon(Icons.location_on, color: Color(0xFFEF4444), size: 16),
            const SizedBox(width: 8),
            Expanded(child: Text(t.destinationAddress, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis)),
          ]),
          const Divider(color: Color(0xFF1E3A5F), height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${t.estimatedDistance.toStringAsFixed(1)} km', style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
              Text(t.paymentMethod.toUpperCase(), style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
              Text('₹${(t.actualFare ?? t.estimatedFare).toStringAsFixed(0)}', style: const TextStyle(color: Color(0xFF3B82F6), fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
        ],
      ),
    );
  }
}
