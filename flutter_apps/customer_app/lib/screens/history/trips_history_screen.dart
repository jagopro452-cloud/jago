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
    final token = await AuthService.getToken();
    try {
      final res = await http.get(Uri.parse(ApiConfig.trips), headers: {'Authorization': 'Bearer $token'});
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() { _trips = data['trips'] ?? []; _loading = false; });
      }
    } catch (_) { setState(() => _loading = false); }
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
      body: _loading ? const Center(child: CircularProgressIndicator(color: Color(0xFF1E6DE5)))
        : _trips.isEmpty
          ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.directions_bike_outlined, size: 64, color: Color(0xFF1E6DE5)),
              const SizedBox(height: 16),
              Text('No rides yet', style: TextStyle(color: Colors.grey[500], fontSize: 16)),
            ]))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _trips.length,
              itemBuilder: (_, i) {
                final t = _trips[i];
                final status = t['currentStatus'] ?? t['status'] ?? '';
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))]),
                  child: Column(children: [
                    Row(children: [
                      Container(width: 44, height: 44,
                        decoration: BoxDecoration(color: const Color(0xFF1E6DE5).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.directions_bike, color: Color(0xFF1E6DE5), size: 24)),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(t['destinationAddress'] ?? 'Destination', maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E))),
                        const SizedBox(height: 4),
                        Text(t['pickupAddress'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                      ])),
                      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                        Text('₹${t['actualFare'] ?? t['estimatedFare'] ?? '0'}',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E), fontSize: 16)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: status == 'completed' ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6)),
                          child: Text(status, style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w500,
                            color: status == 'completed' ? Colors.green : Colors.orange))),
                      ]),
                    ]),
                    if (status == 'completed' && (t['destinationAddress'] ?? '').isNotEmpty) ...[
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
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
                          icon: const Icon(Icons.refresh_rounded, size: 16, color: Color(0xFF1E6DE5)),
                          label: const Text('Book Again', style: TextStyle(fontSize: 13, color: Color(0xFF1E6DE5), fontWeight: FontWeight.w700)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFBFDBFE)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 8)),
                        ),
                      ),
                    ],
                  ]),
                );
              }),
    );
  }
}
