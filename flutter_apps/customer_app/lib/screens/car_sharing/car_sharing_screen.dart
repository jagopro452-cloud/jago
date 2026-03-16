import 'dart:convert';
import 'package:flutter/material.dart';
import '../../config/jago_theme.dart';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import '../../services/auth_service.dart';

class CarSharingScreen extends StatefulWidget {
  const CarSharingScreen({super.key});
  @override
  State<CarSharingScreen> createState() => _CarSharingScreenState();
}

class _CarSharingScreenState extends State<CarSharingScreen> with SingleTickerProviderStateMixin {
  static const _bg = Color(0xFFF8FAFC);
  static const _blue = JT.primary;
  static const _green = Color(0xFF10B981);
  static const _amber = Color(0xFFD97706);

  late TabController _tabs;
  bool _loading = true;
  bool _myLoading = true;
  List _rides = [];
  List _myBookings = [];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _loadRides();
    _loadMyBookings();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _loadRides() async {
    if (mounted) setState(() => _loading = true);
    try {
      final headers = await AuthService.getHeaders();
      final res = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/app/customer/car-sharing/rides'), headers: headers);
      if (res.statusCode == 200 && mounted) setState(() => _rides = jsonDecode(res.body)['data'] ?? []);
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadMyBookings() async {
    if (mounted) setState(() => _myLoading = true);
    try {
      final headers = await AuthService.getHeaders();
      final res = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/app/customer/car-sharing/my-bookings'), headers: headers);
      if (res.statusCode == 200 && mounted) setState(() => _myBookings = jsonDecode(res.body)['data'] ?? []);
    } catch (_) {}
    if (mounted) setState(() => _myLoading = false);
  }

  Future<void> _book(String rideId, String from, String to, double seatPrice) async {
    final res = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Booking'),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Route: $from → $to', style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('Fare: ₹${seatPrice.toStringAsFixed(0)} / seat', style: const TextStyle(color: Colors.green, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Amount will be deducted from your wallet.', style: TextStyle(color: Colors.grey, fontSize: 12)),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: _green),
            child: const Text('Book 1 Seat', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (res != true) return;
    try {
      final headers = await AuthService.getHeaders();
      final bookRes = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/app/customer/car-sharing/book'),
        headers: {...headers, 'Content-Type': 'application/json'},
        body: jsonEncode({'rideId': rideId, 'seatsBooked': 1}),
      );
      final d = jsonDecode(bookRes.body);
      if (!mounted) return;
      if (bookRes.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(d['message'] ?? 'Booking confirmed!'),
          backgroundColor: Colors.green,
        ));
        _loadRides();
        _loadMyBookings();
        _tabs.animateTo(1);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(d['message'] ?? 'Booking failed'),
          backgroundColor: Colors.red,
        ));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: _blue,
        elevation: 0.5,
        title: const Text('Car Sharing', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabs,
          labelColor: _blue,
          unselectedLabelColor: Colors.grey,
          indicatorColor: _blue,
          tabs: const [Tab(text: 'Available Rides'), Tab(text: 'My Bookings')],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _buildRidesList(),
          _buildMyBookings(),
        ],
      ),
    );
  }

  Widget _buildRidesList() {
    if (_loading) return const Center(child: CircularProgressIndicator(color: JT.primary));
    if (_rides.isEmpty) return _empty('No shared rides available', '🚗', 'Check back later or post your own!');
    return RefreshIndicator(
      onRefresh: _loadRides,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _rides.length,
        itemBuilder: (_, i) => _rideCard(_rides[i]),
      ),
    );
  }

  Widget _buildMyBookings() {
    if (_myLoading) return const Center(child: CircularProgressIndicator(color: JT.primary));
    if (_myBookings.isEmpty) return _empty('No bookings yet', '🎫', 'Book a seat on an available shared ride!');
    return RefreshIndicator(
      onRefresh: _loadMyBookings,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _myBookings.length,
        itemBuilder: (_, i) => _bookingCard(_myBookings[i]),
      ),
    );
  }

  Widget _rideCard(Map d) {
    final from = d['fromLocation'] ?? 'From';
    final to = d['toLocation'] ?? 'To';
    final driver = d['driverName'] ?? 'Driver';
    final vehicle = d['vehicleName'] ?? 'Vehicle';
    final available = d['availableSeats'] ?? 0;
    final seatPrice = (d['seatPrice'] ?? 0).toDouble();
    final depTime = d['departureTime'] != null ? _fmt(d['departureTime']) : '--';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('📍', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 6),
          Expanded(child: Text('$from → $to',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
            maxLines: 1, overflow: TextOverflow.ellipsis)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: _green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
            child: Text('₹${seatPrice.toStringAsFixed(0)}/seat', style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.w800, fontSize: 12)),
          ),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          const Icon(Icons.person_rounded, size: 14, color: Colors.grey),
          const SizedBox(width: 4),
          Text(driver, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(width: 12),
          const Icon(Icons.directions_car_rounded, size: 14, color: Colors.grey),
          const SizedBox(width: 4),
          Text(vehicle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ]),
        const SizedBox(height: 6),
        Row(children: [
          const Icon(Icons.access_time_rounded, size: 14, color: Colors.grey),
          const SizedBox(width: 4),
          Text(depTime, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: available > 0 ? _blue.withValues(alpha: 0.08) : Colors.red.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('$available seats left',
              style: TextStyle(color: available > 0 ? _blue : Colors.red, fontSize: 11, fontWeight: FontWeight.w700)),
          ),
        ]),
        if (available > 0) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 40,
            child: ElevatedButton(
              onPressed: () => _book(d['id'], from, to, seatPrice),
              style: ElevatedButton.styleFrom(
                backgroundColor: _blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              child: const Text('Book a Seat', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            ),
          ),
        ],
      ]),
    );
  }

  Widget _bookingCard(Map d) {
    final from = d['fromLocation'] ?? 'From';
    final to = d['toLocation'] ?? 'To';
    final driver = d['driverName'] ?? 'Driver';
    final status = d['status'] ?? 'confirmed';
    final seats = d['seatsBooked'] ?? 1;
    final total = (d['totalFare'] ?? 0).toDouble();
    final depTime = d['departureTime'] != null ? _fmt(d['departureTime']) : '--';
    final Color statusColor = status == 'confirmed' ? _green : status == 'cancelled' ? Colors.red : _amber;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text('$from → $to',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            maxLines: 1, overflow: TextOverflow.ellipsis)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
            child: Text(status.toUpperCase(), style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w800)),
          ),
        ]),
        const SizedBox(height: 6),
        Text('Driver: $driver', style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 4),
        Row(children: [
          const Icon(Icons.access_time_rounded, size: 12, color: Colors.grey),
          const SizedBox(width: 4),
          Text(depTime, style: const TextStyle(color: Colors.grey, fontSize: 11)),
          const Spacer(),
          Text('$seats seat(s) • ₹${total.toStringAsFixed(0)}',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Color(0xFF2563EB))),
        ]),
      ]),
    );
  }

  Widget _empty(String title, String emoji, String sub) {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Text(emoji, style: const TextStyle(fontSize: 52)),
      const SizedBox(height: 12),
      Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Colors.black87)),
      const SizedBox(height: 6),
      Text(sub, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, fontSize: 13)),
    ]));
  }

  String _fmt(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      final h = dt.hour;
      final m = dt.minute.toString().padLeft(2, '0');
      final ampm = h >= 12 ? 'PM' : 'AM';
      final hr = h % 12 == 0 ? 12 : h % 12;
      return '${dt.day}/${dt.month} $hr:$m $ampm';
    } catch (_) {
      return iso.substring(0, 16);
    }
  }
}
