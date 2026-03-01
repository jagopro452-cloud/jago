import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import '../../services/auth_service.dart';

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
      final res = await http.get(Uri.parse(ApiConfig.driverTrips), headers: {'Authorization': 'Bearer $token'});
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() { _trips = data['trips'] ?? []; _loading = false; });
      }
    } catch (_) { setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060D1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF060D1E), elevation: 0,
        leading: IconButton(icon: Icon(Icons.arrow_back_ios, color: Colors.white.withOpacity(0.7)), onPressed: () => Navigator.pop(context)),
        title: const Text('My Trips', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: _loading ? const Center(child: CircularProgressIndicator(color: Color(0xFF2563EB)))
        : _trips.isEmpty
          ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.route_outlined, size: 64, color: Color(0xFF2563EB)),
              const SizedBox(height: 16),
              Text('No trips yet', style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 16)),
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
                  decoration: BoxDecoration(color: const Color(0xFF0D1B4B), borderRadius: BorderRadius.circular(16)),
                  child: Row(children: [
                    Container(width: 44, height: 44,
                      decoration: BoxDecoration(color: const Color(0xFF2563EB).withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.route, color: Color(0xFF2563EB), size: 24)),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(t['destinationAddress'] ?? 'Destination', maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
                      const SizedBox(height: 4),
                      Text(t['pickupAddress'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.4))),
                    ])),
                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Text('₹${t['actualFare'] ?? t['estimatedFare'] ?? '0'}',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: status == 'completed' ? Colors.green.withOpacity(0.15) : Colors.orange.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6)),
                        child: Text(status, style: TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w500,
                          color: status == 'completed' ? Colors.green : Colors.orange))),
                    ]),
                  ]),
                );
              }),
    );
  }
}
