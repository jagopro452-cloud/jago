import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import '../../services/auth_service.dart';

class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key});
  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen>
    with SingleTickerProviderStateMixin {
  static const _bg = Color(0xFF0B0B0B);
  static const _surface = Color(0xFF1A1A1A);
  static const _card = Color(0xFF222222);
  static const _green = Color(0xFF10B981);
  static const _blue = Color(0xFF2F80ED);
  static const _amber = Color(0xFFF59E0B);

  String _period = 'today';
  bool _loading = true;
  bool _weekLoading = true;
  Map<String, dynamic> _stats = {};
  List<Map<String, dynamic>> _weekDays = [];
  double _weekTotal = 0;

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  final _tabs = [
    {'label': 'Today', 'value': 'today'},
    {'label': 'Week', 'value': 'week'},
    {'label': 'Month', 'value': 'month'},
    {'label': 'All Time', 'value': 'all'},
  ];

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _loadStats();
    _loadWeekly();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    if (mounted) setState(() => _loading = true);
    try {
      final headers = await AuthService.getHeaders();
      final res = await http.get(
        Uri.parse(
            '${ApiConfig.baseUrl}/api/app/driver/earnings?period=$_period'),
        headers: headers,
      );
      if (res.statusCode == 200 && mounted) {
        setState(() => _stats = jsonDecode(res.body));
        _fadeCtrl.forward(from: 0);
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadWeekly() async {
    if (mounted) setState(() => _weekLoading = true);
    try {
      final headers = await AuthService.getHeaders();
      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/app/driver/weekly-earnings'),
        headers: headers,
      );
      if (res.statusCode == 200 && mounted) {
        final d = jsonDecode(res.body);
        setState(() {
          _weekDays = List<Map<String, dynamic>>.from(d['days'] ?? []);
          _weekTotal = (d['total'] ?? 0).toDouble();
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _weekLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final gross = (_stats['grossFare'] ?? 0).toDouble();
    final commission = (_stats['commission'] ?? 0).toDouble();
    final net = (_stats['netEarnings'] ?? 0).toDouble();
    final completed = _stats['completedTrips'] ?? 0;
    final cancelled = _stats['cancelledTrips'] ?? 0;
    final maxWeek = _weekDays.isEmpty
        ? 1.0
        : _weekDays
            .map((d) => (d['gross'] as num).toDouble())
            .reduce((a, b) => a > b ? a : b)
            .clamp(1.0, double.infinity);

    return Scaffold(
      backgroundColor: _bg,
      body: RefreshIndicator(
        onRefresh: () async {
          _loadStats();
          _loadWeekly();
        },
        color: _green,
        backgroundColor: _surface,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader()),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: _buildTabs(),
              ),
            ),
            if (_loading)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(
                      child: CircularProgressIndicator(color: _green)),
                ),
              )
            else
              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(children: [
                      _bigEarningCard(net),
                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(
                            child: _statCard('Gross Fare',
                                '₹${gross.toStringAsFixed(0)}',
                                Icons.monetization_on_rounded, _amber)),
                        const SizedBox(width: 10),
                        Expanded(
                            child: _statCard('Commission',
                                '-₹${commission.toStringAsFixed(0)}',
                                Icons.percent_rounded, Colors.redAccent)),
                      ]),
                      const SizedBox(height: 10),
                      Row(children: [
                        Expanded(
                            child: _statCard('Completed',
                                '$completed trips',
                                Icons.check_circle_rounded, _green)),
                        const SizedBox(width: 10),
                        Expanded(
                            child: _statCard('Cancelled',
                                '$cancelled trips',
                                Icons.cancel_rounded,
                                const Color(0xFFEF4444))),
                      ]),
                    ]),
                  ),
                ),
              ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                child: _buildWeeklyChart(maxWeek),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0D1B2A), Color(0xFF1A2E1A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Row(children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.12)),
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white, size: 18),
              ),
            ),
            const SizedBox(width: 14),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('My Earnings',
                  style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700)),
              Text('Track your income & trips',
                  style: GoogleFonts.poppins(
                      color: Colors.white54, fontSize: 12)),
            ]),
            const Spacer(),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _green.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border:
                    Border.all(color: _green.withValues(alpha: 0.3)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.trending_up_rounded,
                    color: _green, size: 16),
                const SizedBox(width: 4),
                Text('Live',
                    style: GoogleFonts.poppins(
                        color: _green,
                        fontSize: 11,
                        fontWeight: FontWeight.w700)),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
          color: _surface, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: _tabs.map((t) {
          final active = _period == t['value'];
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => _period = t['value']!);
                _loadStats();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  gradient: active
                      ? const LinearGradient(
                          colors: [Color(0xFF0D9F6E), Color(0xFF10B981)])
                      : null,
                  color: active ? null : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: active
                      ? [
                          BoxShadow(
                              color: _green.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2))
                        ]
                      : [],
                ),
                child: Text(t['label']!,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                        color: active ? Colors.white : Colors.white38,
                        fontSize: 11,
                        fontWeight: FontWeight.w700)),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _bigEarningCard(double net) {
    final periodLabel = _period == 'today'
        ? 'Today'
        : _period == 'week'
            ? 'This Week'
            : _period == 'month'
                ? 'This Month'
                : 'All Time';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: [
              _green.withValues(alpha: 0.2),
              _blue.withValues(alpha: 0.1)
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _green.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _green.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.account_balance_wallet_rounded,
              color: _green, size: 28),
        ),
        const SizedBox(height: 14),
        Text('Net Earnings',
            style: GoogleFonts.poppins(
                color: Colors.white60, fontSize: 13)),
        const SizedBox(height: 6),
        Text('₹${net.toStringAsFixed(2)}',
            style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 40,
                fontWeight: FontWeight.w800,
                height: 1.1)),
        const SizedBox(height: 6),
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(periodLabel,
              style: GoogleFonts.poppins(
                  color: Colors.white54,
                  fontSize: 12,
                  fontWeight: FontWeight.w500)),
        ),
      ]),
    );
  }

  Widget _statCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: Colors.white.withValues(alpha: 0.07), width: 1),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: GoogleFonts.poppins(
                      color: Colors.white54,
                      fontSize: 10,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 3),
              Text(value,
                  style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w800)),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _buildWeeklyChart(double maxWeek) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: Colors.white.withValues(alpha: 0.07), width: 1),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Weekly Earnings',
                style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700)),
            Text('Last 7 days overview',
                style: GoogleFonts.poppins(
                    color: Colors.white38, fontSize: 11)),
          ]),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _green.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _green.withValues(alpha: 0.25)),
            ),
            child: Text('₹${_weekTotal.toStringAsFixed(0)}',
                style: GoogleFonts.poppins(
                    color: _green,
                    fontSize: 14,
                    fontWeight: FontWeight.w800)),
          ),
        ]),
        const SizedBox(height: 24),
        if (_weekLoading)
          const Center(
              child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(color: _green)))
        else if (_weekDays.isEmpty)
          Center(
            child: Text('No weekly data',
                style: GoogleFonts.poppins(
                    color: Colors.white38, fontSize: 13)),
          )
        else
          SizedBox(
            height: 130,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: _weekDays.map((d) {
                final val = (d['gross'] as num).toDouble();
                final frac = val / maxWeek;
                final today = DateTime.now();
                final isToday =
                    d['date'] == today.toIso8601String().substring(0, 10);
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (val > 0)
                          Text('₹${val.toInt()}',
                              style: GoogleFonts.poppins(
                                  color: isToday ? _green : Colors.white38,
                                  fontSize: 8,
                                  fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Container(
                          height: (frac * 90).clamp(4.0, 90.0),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isToday
                                  ? [
                                      const Color(0xFF0D9F6E),
                                      _green
                                    ]
                                  : [
                                      _blue.withValues(alpha: 0.4),
                                      _blue.withValues(alpha: 0.7)
                                    ],
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                            ),
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(6)),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(d['day'] as String,
                            style: GoogleFonts.poppins(
                                color:
                                    isToday ? _green : Colors.white38,
                                fontSize: 10,
                                fontWeight: isToday
                                    ? FontWeight.w800
                                    : FontWeight.w500)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
      ]),
    );
  }
}
