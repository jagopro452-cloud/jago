import 'dart:convert';
import 'package:flutter/material.dart';
import '../../config/jago_theme.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import '../../services/auth_service.dart';
import '../booking/booking_screen.dart';

class TripsHistoryScreen extends StatefulWidget {
  const TripsHistoryScreen({super.key});
  @override
  State<TripsHistoryScreen> createState() => _TripsHistoryScreenState();
}

class _TripsHistoryScreenState extends State<TripsHistoryScreen>
    with SingleTickerProviderStateMixin {
  List<dynamic> _trips = [];
  bool _loading = true;
  String _filter = 'all'; // all | completed | cancelled

  late AnimationController _headerCtrl;
  late Animation<double> _headerAnim;

  static const Color _blue = Color(0xFF2F7BFF);
  static const Color _navy = Color(0xFF0F172A);

  @override
  void initState() {
    super.initState();
    _headerCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _headerAnim = CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOut);
    _fetchTrips();
  }

  @override
  void dispose() {
    _headerCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchTrips() async {
    setState(() => _loading = true);
    final headers = await AuthService.getHeaders();
    try {
      final res = await http.get(Uri.parse(ApiConfig.trips), headers: headers);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (mounted) {
          setState(() { _trips = data['trips'] ?? []; _loading = false; });
          _headerCtrl.forward(from: 0);
        }
      } else {
        if (mounted) setState(() => _loading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<dynamic> get _filtered {
    if (_filter == 'all') return _trips;
    return _trips.where((t) {
      final s = (t['currentStatus'] ?? t['status'] ?? '').toString();
      return s == _filter;
    }).toList();
  }

  int get _completedCount => _trips.where((t) =>
    (t['currentStatus'] ?? t['status'] ?? '') == 'completed').length;
  int get _cancelledCount => _trips.where((t) =>
    (t['currentStatus'] ?? t['status'] ?? '') == 'cancelled').length;

  Future<void> _showReceipt(BuildContext ctx, String tripId) async {
    showDialog(context: ctx, barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: JT.primary)));
    try {
      final headers = await AuthService.getHeaders();
      final res = await http.get(Uri.parse(ApiConfig.tripReceipt(tripId)), headers: headers);
      if (!mounted) return;
      Navigator.pop(ctx);
      if (res.statusCode == 200) {
        final receipt = jsonDecode(res.body)['receipt'];
        _showReceiptSheet(ctx, receipt);
      } else {
        _showSnack('Receipt not available', error: true);
      }
    } catch (_) {
      if (mounted) {
        Navigator.pop(ctx);
        _showSnack('Could not load receipt', error: true);
      }
    }
  }

  void _showSnack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.white, fontSize: 13)),
      backgroundColor: error ? const Color(0xFFEF4444) : _blue,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  void _showReceiptSheet(BuildContext ctx, Map<String, dynamic> r) {
    final fare = r['fare'] ?? {};
    final vehicle = r['vehicle'] ?? {};
    final driver = r['driver'] ?? {};
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.85),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // Handle
          Container(
            width: 40, height: 4,
            margin: const EdgeInsets.only(top: 14, bottom: 8),
            decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(2)),
          ),
          // Header gradient
          Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [JT.primary, Color(0xFF1A6FE0)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.receipt_long_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Trip Receipt', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
                Text(r['receiptNo'] ?? '', style: GoogleFonts.poppins(color: Colors.white.withValues(alpha: 0.7), fontSize: 12)),
              ])),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('PAID', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12)),
              ),
            ]),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Route card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: IntrinsicHeight(
                    child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Container(width: 10, height: 10, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF10B981))),
                        Expanded(child: Container(width: 2, color: const Color(0xFFE2E8F0), margin: const EdgeInsets.symmetric(vertical: 3))),
                        Container(width: 10, height: 10, decoration: BoxDecoration(color: const Color(0xFFEF4444), borderRadius: BorderRadius.circular(2))),
                      ]),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('PICKUP', style: GoogleFonts.poppins(color: const Color(0xFF10B981), fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
                        const SizedBox(height: 2),
                        Text(r['pickup']?['address'] ?? '', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: _navy), maxLines: 2),
                        const SizedBox(height: 12),
                        Text('DROP-OFF', style: GoogleFonts.poppins(color: const Color(0xFFEF4444), fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
                        const SizedBox(height: 2),
                        Text(r['destination']?['address'] ?? '', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: _navy), maxLines: 2),
                      ])),
                    ]),
                  ),
                ),
                const SizedBox(height: 16),

                // Driver & vehicle row
                if (driver['name'] != null || vehicle['name'] != null)
                  Row(children: [
                    if (driver['name'] != null) Expanded(child: _infoChip(Icons.person_rounded, driver['name'], JT.primary)),
                    if (driver['name'] != null && vehicle['name'] != null) const SizedBox(width: 10),
                    if (vehicle['name'] != null) Expanded(child: _infoChip(Icons.directions_car_rounded, '${vehicle['name']} ${vehicle['number'] ?? ''}', const Color(0xFF7C3AED))),
                  ]),
                if ((r['distanceKm'] ?? 0) > 0) ...[
                  const SizedBox(height: 10),
                  _infoChip(Icons.route_rounded, '${r['distanceKm']} km', const Color(0xFF10B981)),
                ],

                const SizedBox(height: 16),
                Text('Fare Breakdown', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: _navy)),
                const SizedBox(height: 10),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(children: [
                    _fareRow('Base Fare', fare['baseFare'] ?? 0),
                    if ((fare['distanceFare'] ?? 0) > 0) _fareRow('Distance Fare', fare['distanceFare'] ?? 0),
                    if ((fare['waitingCharge'] ?? 0) > 0) _fareRow('Waiting Charge', fare['waitingCharge'] ?? 0),
                    if ((fare['discount'] ?? 0) > 0) _fareRow('Discount', fare['discount'] ?? 0, isDiscount: true),
                    _fareRow('GST (5%)', fare['gst'] ?? 0, isGst: true),
                    const Divider(height: 20, color: Color(0xFFE2E8F0)),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text('Total Paid', style: GoogleFonts.poppins(fontWeight: FontWeight.w800, fontSize: 16, color: _navy)),
                      Text('₹${fare['payable'] ?? fare['total'] ?? 0}',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w900, fontSize: 20, color: _blue)),
                    ]),
                    const SizedBox(height: 8),
                    Row(children: [
                      const Icon(Icons.payment_rounded, size: 14, color: Color(0xFF94A3B8)),
                      const SizedBox(width: 6),
                      Text('Paid via ${(fare['paymentMethod'] ?? 'cash').toUpperCase()}',
                        style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF94A3B8))),
                    ]),
                  ]),
                ),

                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity, height: 54,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF56CCF2), Color(0xFF1A6FE0)], begin: Alignment.centerLeft, end: Alignment.centerRight),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: _blue.withValues(alpha: 0.35), blurRadius: 14, offset: const Offset(0, 6))],
                    ),
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent, shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0,
                      ),
                      child: Text('Close', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _infoChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(children: [
        Icon(icon, color: color, size: 15),
        const SizedBox(width: 6),
        Expanded(child: Text(text, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: color), maxLines: 1, overflow: TextOverflow.ellipsis)),
      ]),
    );
  }

  Widget _fareRow(String label, dynamic amount, {bool isDiscount = false, bool isGst = false}) {
    final color = isDiscount ? const Color(0xFF10B981) : isGst ? const Color(0xFFF59E0B) : const Color(0xFF475569);
    final prefix = isDiscount ? '-' : '';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF64748B))),
        Text('$prefix₹$amount', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFFF1F5F9),
        body: Column(children: [
          // ── Gradient header ──
          FadeTransition(
            opacity: _headerAnim,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1A6FE0), JT.primary, Color(0xFF56CCF2)],
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 38, height: 38,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Text('My Rides', style: GoogleFonts.poppins(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                    ]),
                    const SizedBox(height: 20),
                    // Stats row
                    Row(children: [
                      _headerStat('${_trips.length}', 'Total', Icons.directions_car_filled_rounded, Colors.white),
                      const SizedBox(width: 10),
                      _headerStat('$_completedCount', 'Completed', Icons.check_circle_rounded, const Color(0xFF4ADE80)),
                      const SizedBox(width: 10),
                      _headerStat('$_cancelledCount', 'Cancelled', Icons.cancel_rounded, const Color(0xFFF87171)),
                    ]),
                  ]),
                ),
              ),
            ),
          ),

          // ── Filter chips ──
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(children: [
              _filterChip('all', 'All Rides'),
              const SizedBox(width: 8),
              _filterChip('completed', 'Completed'),
              const SizedBox(width: 8),
              _filterChip('cancelled', 'Cancelled'),
            ]),
          ),

          // ── List ──
          Expanded(
            child: _loading
              ? const Center(child: CircularProgressIndicator(color: JT.primary))
              : filtered.isEmpty
                ? _buildEmpty()
                : RefreshIndicator(
                    onRefresh: _fetchTrips,
                    color: _blue,
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                      itemCount: filtered.length,
                      itemBuilder: (ctx, i) => _buildTripCard(ctx, filtered[i]),
                    ),
                  ),
          ),
        ]),
      ),
    );
  }

  Widget _headerStat(String value, String label, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Row(children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(value, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18, height: 1)),
            Text(label, style: GoogleFonts.poppins(color: Colors.white.withValues(alpha: 0.7), fontSize: 10, fontWeight: FontWeight.w500)),
          ]),
        ]),
      ),
    );
  }

  Widget _filterChip(String value, String label) {
    final active = _filter == value;
    return GestureDetector(
      onTap: () => setState(() => _filter = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: active ? _blue : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? _blue : const Color(0xFFE2E8F0)),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            color: active ? Colors.white : const Color(0xFF64748B),
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(
            color: const Color(0xFFEBF4FF),
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Icon(Icons.receipt_long_outlined, size: 40, color: JT.primary),
        ),
        const SizedBox(height: 16),
        Text(
          _filter == 'all' ? 'No rides yet' : 'No ${_filter} rides',
          style: GoogleFonts.poppins(color: const Color(0xFF475569), fontSize: 17, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Text(
          'Your ride history will appear here',
          style: GoogleFonts.poppins(color: const Color(0xFF94A3B8), fontSize: 13),
        ),
      ]),
    );
  }

  Widget _buildTripCard(BuildContext ctx, Map<String, dynamic> t) {
    final status = (t['currentStatus'] ?? t['status'] ?? '').toString();
    final isCompleted = status == 'completed';
    final isCancelled = status == 'cancelled';
    final statusColor = isCompleted ? const Color(0xFF10B981)
        : isCancelled ? const Color(0xFFEF4444)
        : const Color(0xFFF59E0B);
    final statusLabel = isCompleted ? 'Completed'
        : isCancelled ? 'Cancelled' : status;
    final date = t['createdAt'] ?? t['created_at'] ?? '';
    final formattedDate = _formatDate(date);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: JT.primary.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 3))],
      ),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Row(children: [
            // Vehicle icon
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                isCompleted ? Icons.check_circle_outline_rounded
                    : isCancelled ? Icons.cancel_outlined
                    : Icons.directions_car_rounded,
                color: statusColor, size: 24,
              ),
            ),
            const SizedBox(width: 12),
            // Route info
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                t['destinationAddress'] ?? 'Destination',
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 14, color: const Color(0xFF0F172A)),
              ),
              const SizedBox(height: 2),
              Text(
                t['pickupAddress'] ?? '',
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF94A3B8)),
              ),
              if (formattedDate.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(formattedDate, style: GoogleFonts.poppins(fontSize: 10, color: const Color(0xFFCBD5E1), fontWeight: FontWeight.w500)),
              ],
            ])),
            // Fare + status
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(
                '₹${t['actualFare'] ?? t['estimatedFare'] ?? '0'}',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w900, fontSize: 17, color: const Color(0xFF0F172A)),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(statusLabel, style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w700, color: statusColor)),
              ),
            ]),
          ]),
        ),

        if (isCompleted) ...[
          Container(height: 1, color: const Color(0xFFF1F5F9)),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Row(children: [
              Expanded(
                child: _actionButton(
                  icon: Icons.receipt_long_rounded,
                  label: 'Receipt',
                  onTap: () => _showReceipt(ctx, t['id'] ?? t['tripId'] ?? ''),
                ),
              ),
              const SizedBox(width: 8),
              if ((t['destinationAddress'] ?? '').isNotEmpty)
                Expanded(
                  child: _actionButton(
                    icon: Icons.refresh_rounded,
                    label: 'Book Again',
                    filled: true,
                    onTap: () => Navigator.push(context, MaterialPageRoute(
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
                  ),
                ),
            ]),
          ),
        ],
      ]),
    );
  }

  Widget _actionButton({required IconData icon, required String label, required VoidCallback onTap, bool filled = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 38,
        decoration: BoxDecoration(
          color: filled ? _blue : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
          border: filled ? null : Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 14, color: filled ? Colors.white : _blue),
          const SizedBox(width: 6),
          Text(label, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700, color: filled ? Colors.white : _blue)),
        ]),
      ),
    );
  }

  String _formatDate(String raw) {
    try {
      final d = DateTime.parse(raw).toLocal();
      final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      return '${d.day} ${months[d.month - 1]} ${d.year}';
    } catch (_) {
      return raw.length > 10 ? raw.substring(0, 10) : raw;
    }
  }
}
