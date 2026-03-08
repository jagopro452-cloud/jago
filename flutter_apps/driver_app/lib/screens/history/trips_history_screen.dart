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

class _TripsHistoryScreenState extends State<TripsHistoryScreen>
    with SingleTickerProviderStateMixin {
  List<dynamic> _allTrips = [];
  List<dynamic> _filtered = [];
  bool _loading = true;
  String _activeFilter = 'All';
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();
  late TabController _tabCtrl;

  // Summary stats
  double _totalEarnings = 0;
  int _completedCount = 0;
  int _cancelledCount = 0;

  static const Color _bg = Color(0xFF060D1E);
  static const Color _surface = Color(0xFF0D1B3E);
  static const Color _blue = Color(0xFF2563EB);
  static const Color _green = Color(0xFF16A34A);
  static const Color _red = Color(0xFFDC2626);

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _tabCtrl.addListener(() {
      final filters = ['All', 'Completed', 'Cancelled'];
      setState(() { _activeFilter = filters[_tabCtrl.index]; });
      _applyFilter();
    });
    _fetchTrips();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchTrips({bool refresh = false}) async {
    if (refresh && mounted) setState(() => _loading = true);
    final token = await AuthService.getToken();
    try {
      final res = await http.get(
        Uri.parse('${ApiConfig.driverTrips}?limit=100'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (res.statusCode == 200 && mounted) {
        final data = jsonDecode(res.body);
        final trips = (data['trips'] as List?) ?? [];
        double total = 0;
        int comp = 0, canc = 0;
        for (final t in trips) {
          final status = t['currentStatus'] ?? t['status'] ?? '';
          if (status == 'completed') {
            comp++;
            total += double.tryParse(
                (t['actualFare'] ?? t['estimatedFare'] ?? '0').toString()) ?? 0;
          } else if (status == 'cancelled') {
            canc++;
          }
        }
        setState(() {
          _allTrips = trips;
          _totalEarnings = total;
          _completedCount = comp;
          _cancelledCount = canc;
          _loading = false;
        });
        _applyFilter();
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _applyFilter() {
    final q = _searchQuery.toLowerCase();
    setState(() {
      _filtered = _allTrips.where((t) {
        final status = (t['currentStatus'] ?? t['status'] ?? '').toString();
        final pickup = (t['pickupAddress'] ?? '').toString().toLowerCase();
        final dest = (t['destinationAddress'] ?? '').toString().toLowerCase();
        final matchFilter = _activeFilter == 'All' ||
            (_activeFilter == 'Completed' && status == 'completed') ||
            (_activeFilter == 'Cancelled' && status == 'cancelled');
        final matchSearch = q.isEmpty || pickup.contains(q) || dest.contains(q);
        return matchFilter && matchSearch;
      }).toList();
    });
  }

  String _formatDate(String? raw) {
    if (raw == null) return '';
    try {
      final dt = DateTime.parse(raw).toLocal();
      final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      final h = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
      final ampm = dt.hour >= 12 ? 'PM' : 'AM';
      final m = dt.minute.toString().padLeft(2, '0');
      return '${dt.day} ${months[dt.month - 1]} · $h:$m $ampm';
    } catch (_) { return ''; }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'completed': return _green;
      case 'cancelled': return _red;
      case 'ongoing': return _blue;
      default: return Colors.orange;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'completed': return 'Completed';
      case 'cancelled': return 'Cancelled';
      case 'ongoing': return 'Ongoing';
      case 'driver_assigned': return 'Driver Assigned';
      case 'arrived': return 'Arrived';
      default: return status;
    }
  }

  void _showTripDetail(Map t) {
    final status = (t['currentStatus'] ?? t['status'] ?? '').toString();
    final fare = double.tryParse(
        (t['actualFare'] ?? t['estimatedFare'] ?? '0').toString()) ?? 0;
    final isPaid = (t['paymentStatus'] ?? '') == 'paid';
    final type = (t['type'] ?? 'ride').toString();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0D1B3E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 20),
          Row(children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: _statusColor(status).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                type == 'parcel' ? Icons.inventory_2_rounded : Icons.route_rounded,
                color: _statusColor(status), size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                type == 'parcel' ? 'Parcel Delivery' : 'Ride',
                style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 2),
              Text(_formatDate(t['createdAt']?.toString()),
                style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12)),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _statusColor(status).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(_statusLabel(status),
                style: TextStyle(color: _statusColor(status), fontSize: 12, fontWeight: FontWeight.w700)),
            ),
          ]),
          const SizedBox(height: 20),
          _detailRow(Icons.my_location_rounded, 'Pickup',
            t['pickupAddress']?.toString() ?? '—', const Color(0xFF16A34A)),
          const SizedBox(height: 10),
          _detailRow(Icons.location_on_rounded, 'Drop',
            t['destinationAddress']?.toString() ?? '—', _red),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
            ),
            child: Row(children: [
              _tripStat('Fare', '₹${fare.toStringAsFixed(0)}', Icons.currency_rupee_rounded, _green),
              _vDivider(),
              _tripStat('Payment',
                isPaid ? 'Paid' : (t['paymentMethod']?.toString() ?? 'Cash'),
                isPaid ? Icons.check_circle_rounded : Icons.account_balance_wallet_rounded,
                isPaid ? _green : Colors.orange),
              _vDivider(),
              _tripStat('Distance',
                '${(double.tryParse(t['distanceKm']?.toString() ?? '0') ?? 0).toStringAsFixed(1)} km',
                Icons.straighten_rounded, _blue),
            ]),
          ),
          if (t['refId'] != null) ...[
            const SizedBox(height: 14),
            Row(children: [
              Icon(Icons.tag_rounded, size: 14, color: Colors.white.withValues(alpha: 0.3)),
              const SizedBox(width: 6),
              Text('Trip ID: ${t['refId']}',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 12, fontFamily: 'monospace')),
            ]),
          ],
        ]),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value, Color color) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: 32, height: 32,
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: color, size: 16),
      ),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
      ])),
    ]);
  }

  Widget _tripStat(String label, String value, IconData icon, Color color) {
    return Expanded(child: Column(children: [
      Icon(icon, color: color, size: 18),
      const SizedBox(height: 6),
      Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800)),
      const SizedBox(height: 2),
      Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 10)),
    ]));
  }

  Widget _vDivider() => Container(
    width: 1, height: 40,
    color: Colors.white.withValues(alpha: 0.07),
    margin: const EdgeInsets.symmetric(horizontal: 8),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            backgroundColor: _bg,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_rounded, color: Colors.white.withValues(alpha: 0.7)),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text('My Trips',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0D1B3E), Color(0xFF060D1E)],
                    begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 60, 16, 0),
                    child: Column(children: [
                      const SizedBox(height: 12),
                      Row(children: [
                        _summaryCard('Total Earned', '₹${_totalEarnings.toStringAsFixed(0)}',
                          Icons.currency_rupee_rounded, _green),
                        const SizedBox(width: 10),
                        _summaryCard('Completed', '$_completedCount',
                          Icons.check_circle_rounded, _blue),
                        const SizedBox(width: 10),
                        _summaryCard('Cancelled', '$_cancelledCount',
                          Icons.cancel_rounded, _red),
                      ]),
                    ]),
                  ),
                ),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: Container(
                color: _bg,
                child: TabBar(
                  controller: _tabCtrl,
                  indicatorColor: _blue,
                  indicatorWeight: 3,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white38,
                  labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  tabs: [
                    Tab(text: 'All (${_allTrips.length})'),
                    Tab(text: 'Done ($_completedCount)'),
                    Tab(text: 'Cancelled ($_cancelledCount)'),
                  ],
                ),
              ),
            ),
          ),
        ],
        body: Column(children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
              ),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) {
                  setState(() => _searchQuery = v);
                  _applyFilter();
                },
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Search by pickup or destination...',
                  hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 13),
                  prefixIcon: Icon(Icons.search_rounded, color: Colors.white.withValues(alpha: 0.3), size: 18),
                  suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear_rounded, color: Colors.white.withValues(alpha: 0.3), size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _searchQuery = '');
                          _applyFilter();
                        })
                    : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 11),
                ),
              ),
            ),
          ),

          // Trip list
          Expanded(
            child: _loading
              ? const Center(child: CircularProgressIndicator(color: _blue))
              : RefreshIndicator(
                  color: _blue, backgroundColor: _surface,
                  onRefresh: () => _fetchTrips(refresh: true),
                  child: _filtered.isEmpty
                    ? ListView(children: [
                        SizedBox(
                          height: 300,
                          child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Container(
                              width: 72, height: 72,
                              decoration: BoxDecoration(
                                color: _blue.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.route_outlined, size: 36, color: _blue.withValues(alpha: 0.6)),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isNotEmpty ? 'No trips found' : 'No trips yet',
                              style: const TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _searchQuery.isNotEmpty
                                ? 'Try a different search term'
                                : 'Your trip history will appear here',
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 13),
                            ),
                          ])),
                        )
                      ])
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                        itemCount: _filtered.length,
                        itemBuilder: (_, i) {
                          final t = _filtered[i] as Map;
                          final status = (t['currentStatus'] ?? t['status'] ?? '').toString();
                          final fare = double.tryParse(
                              (t['actualFare'] ?? t['estimatedFare'] ?? '0').toString()) ?? 0;
                          final type = (t['type'] ?? 'ride').toString();
                          final isPaid = (t['paymentStatus'] ?? '') == 'paid';
                          final statusColor = _statusColor(status);

                          return GestureDetector(
                            onTap: () => _showTripDetail(Map.from(t)),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              decoration: BoxDecoration(
                                color: _surface,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Row(children: [
                                    Container(
                                      width: 42, height: 42,
                                      decoration: BoxDecoration(
                                        color: statusColor.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        type == 'parcel' ? Icons.inventory_2_rounded : Icons.route_rounded,
                                        color: statusColor, size: 22),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      Text(
                                        t['destinationAddress']?.toString() ?? 'Destination',
                                        maxLines: 1, overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        t['pickupAddress']?.toString() ?? '',
                                        maxLines: 1, overflow: TextOverflow.ellipsis,
                                        style: TextStyle(color: Colors.white.withValues(alpha: 0.38), fontSize: 11),
                                      ),
                                    ])),
                                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                                      Text('₹${fare.toStringAsFixed(0)}',
                                        style: const TextStyle(
                                          color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: statusColor.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(_statusLabel(status),
                                          style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w700)),
                                      ),
                                    ]),
                                  ]),
                                  const SizedBox(height: 12),
                                  Row(children: [
                                    // Date
                                    Icon(Icons.schedule_rounded, size: 12, color: Colors.white.withValues(alpha: 0.3)),
                                    const SizedBox(width: 4),
                                    Text(_formatDate(t['createdAt']?.toString()),
                                      style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 11)),
                                    const Spacer(),
                                    // Payment
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: isPaid
                                          ? Colors.green.withValues(alpha: 0.1)
                                          : Colors.orange.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                                        Icon(
                                          isPaid ? Icons.check_circle_rounded : Icons.account_balance_wallet_rounded,
                                          size: 10,
                                          color: isPaid ? Colors.green : Colors.orange),
                                        const SizedBox(width: 3),
                                        Text(
                                          isPaid ? 'Paid' : (t['paymentMethod']?.toString() ?? 'Cash'),
                                          style: TextStyle(
                                            fontSize: 10, fontWeight: FontWeight.w700,
                                            color: isPaid ? Colors.green : Colors.orange)),
                                      ]),
                                    ),
                                    // Type badge
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: _blue.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                      child: Text(
                                        type == 'parcel' ? '📦 Parcel' : '🚗 Ride',
                                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _blue)),
                                    ),
                                  ]),
                                ]),
                              ),
                            ),
                          );
                        },
                      ),
                ),
          ),
        ]),
      ),
    );
  }

  Widget _summaryCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Column(children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 6),
          Text(value,
            style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.w900)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 9),
            textAlign: TextAlign.center),
        ]),
      ),
    );
  }
}
