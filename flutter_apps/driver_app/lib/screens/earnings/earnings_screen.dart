import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import '../../services/auth_service.dart';

class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key});
  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> {
  static const _bg = Color(0xFF0F172A);
  static const _surface = Color(0xFF1E293B);
  static const _green = Color(0xFF10B981);
  static const _blue = Color(0xFF2563EB);
  static const _amber = Color(0xFFD97706);

  String _period = 'today';
  bool _loading = true;
  bool _weekLoading = true;
  Map<String, dynamic> _stats = {};
  List<Map<String, dynamic>> _weekDays = [];
  double _weekTotal = 0;

  final _tabs = [
    {'label': 'Today', 'value': 'today'},
    {'label': 'This Week', 'value': 'week'},
    {'label': 'This Month', 'value': 'month'},
    {'label': 'All Time', 'value': 'all'},
  ];

  @override
  void initState() {
    super.initState();
    _loadStats();
    _loadWeekly();
  }

  Future<void> _loadStats() async {
    setState(() => _loading = true);
    try {
      final headers = await AuthService.getHeaders();
      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/app/driver/earnings?period=$_period'),
        headers: headers,
      );
      if (res.statusCode == 200) {
        setState(() => _stats = jsonDecode(res.body));
      }
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _loadWeekly() async {
    setState(() => _weekLoading = true);
    try {
      final headers = await AuthService.getHeaders();
      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/app/driver/weekly-earnings'),
        headers: headers,
      );
      if (res.statusCode == 200) {
        final d = jsonDecode(res.body);
        setState(() {
          _weekDays = List<Map<String, dynamic>>.from(d['days'] ?? []);
          _weekTotal = (d['total'] ?? 0).toDouble();
        });
      }
    } catch (_) {}
    setState(() => _weekLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final gross = (_stats['grossFare'] ?? 0).toDouble();
    final commission = (_stats['commission'] ?? 0).toDouble();
    final net = (_stats['netEarnings'] ?? 0).toDouble();
    final completed = _stats['completedTrips'] ?? 0;
    final cancelled = _stats['cancelledTrips'] ?? 0;
    final maxWeek = _weekDays.isEmpty ? 1.0 : _weekDays.map((d) => (d['gross'] as num).toDouble()).reduce((a, b) => a > b ? a : b).clamp(1.0, double.infinity);

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _surface,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('My Earnings', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: () async { _loadStats(); _loadWeekly(); },
        color: _green,
        backgroundColor: _surface,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildTabs(),
            const SizedBox(height: 16),
            if (_loading)
              const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator(color: Color(0xFF10B981))))
            else ...[
              _bigEarningCard(net),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _statCard('Gross Fare', '₹${gross.toStringAsFixed(0)}', Icons.monetization_on_rounded, _amber)),
                const SizedBox(width: 10),
                Expanded(child: _statCard('Commission', '-₹${commission.toStringAsFixed(0)}', Icons.percent_rounded, Colors.redAccent)),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: _statCard('Completed', '$completed trips', Icons.check_circle_rounded, _green)),
                const SizedBox(width: 10),
                Expanded(child: _statCard('Cancelled', '$cancelled trips', Icons.cancel_rounded, Colors.red.shade400)),
              ]),
            ],
            const SizedBox(height: 20),
            _buildWeeklyChart(maxWeek),
          ],
        ),
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(14)),
      child: Row(children: _tabs.map((t) {
        final active = _period == t['value'];
        return Expanded(child: GestureDetector(
          onTap: () { setState(() => _period = t['value']!); _loadStats(); },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: active ? _green : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(t['label']!, textAlign: TextAlign.center,
              style: TextStyle(
                color: active ? Colors.white : Colors.white54,
                fontSize: 11, fontWeight: FontWeight.w700,
              )),
          ),
        ));
      }).toList()),
    );
  }

  Widget _bigEarningCard(double net) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [_green.withValues(alpha: 0.15), _blue.withValues(alpha: 0.1)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _green.withValues(alpha: 0.25), width: 1),
      ),
      child: Column(children: [
        const Text('Net Earnings', style: TextStyle(color: Colors.white60, fontSize: 13)),
        const SizedBox(height: 6),
        Text('₹${net.toStringAsFixed(2)}',
          style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        Text(_period == 'today' ? 'Today' : _period == 'week' ? 'This Week' : _period == 'month' ? 'This Month' : 'All Time',
          style: const TextStyle(color: Colors.white38, fontSize: 11)),
      ]),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06), width: 1),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800)),
        ])),
      ]),
    );
  }

  Widget _buildWeeklyChart(double maxWeek) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06), width: 1),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Weekly Earnings', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
          Text('₹${_weekTotal.toStringAsFixed(0)}', style: const TextStyle(color: Color(0xFF10B981), fontSize: 14, fontWeight: FontWeight.w800)),
        ]),
        const SizedBox(height: 16),
        if (_weekLoading)
          const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: Color(0xFF10B981))))
        else SizedBox(
          height: 120,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: _weekDays.map((d) {
              final val = (d['gross'] as num).toDouble();
              final frac = val / maxWeek;
              final today = DateTime.now();
              final isToday = d['date'] == today.toIso8601String().substring(0, 10);
              return Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                if (val > 0) Text('₹${val.toInt()}', style: const TextStyle(color: Colors.white54, fontSize: 8)),
                const SizedBox(height: 4),
                Container(
                  width: 30,
                  height: (frac * 90).clamp(4.0, 90.0),
                  decoration: BoxDecoration(
                    color: isToday ? _green : _blue.withValues(alpha: 0.6),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                  ),
                ),
                const SizedBox(height: 6),
                Text(d['day'] as String,
                  style: TextStyle(
                    color: isToday ? _green : Colors.white38,
                    fontSize: 10,
                    fontWeight: isToday ? FontWeight.w800 : FontWeight.w500,
                  )),
              ]);
            }).toList(),
          ),
        ),
      ]),
    );
  }
}
