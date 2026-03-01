import 'package:flutter/material.dart';

class IncomingTripSheet extends StatefulWidget {
  final Map<String, dynamic> trip;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  const IncomingTripSheet({super.key, required this.trip, required this.onAccept, required this.onReject});
  @override
  State<IncomingTripSheet> createState() => _IncomingTripSheetState();
}

class _IncomingTripSheetState extends State<IncomingTripSheet> with TickerProviderStateMixin {
  late AnimationController _ringCtrl;
  late AnimationController _slideCtrl;
  int _countdown = 30;
  late final _timer = Stream.periodic(const Duration(seconds: 1)).listen((_) {
    if (_countdown <= 0) { widget.onReject(); return; }
    setState(() => _countdown--);
  });

  static const Color _blue = Color(0xFF2563EB);
  static const Color _bg = Color(0xFF060D1E);
  static const Color _surface = Color(0xFF0D1B3E);

  @override
  void initState() {
    super.initState();
    _ringCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 30))..forward();
    _slideCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 450))..forward();
  }

  @override
  void dispose() { _ringCtrl.dispose(); _slideCtrl.dispose(); _timer.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final trip = widget.trip;
    final pickup = trip['pickupAddress'] ?? 'Pickup';
    final dest = trip['destinationAddress'] ?? 'Destination';
    final dist = trip['estimatedDistance'] ?? '--';
    final fare = trip['estimatedFare'] ?? '--';
    final eta = trip['eta'] ?? 5;

    return SlideTransition(
      position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
          .animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOut)),
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 20),
        decoration: BoxDecoration(
          color: _bg,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: _blue.withOpacity(0.2), width: 1),
          boxShadow: [BoxShadow(color: _blue.withOpacity(0.2), blurRadius: 30, spreadRadius: 2)],
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          _buildTopBanner(),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Column(children: [
              _buildAddressCard(pickup, dest),
              const SizedBox(height: 14),
              _buildStatsRow(dist, fare, eta),
              const SizedBox(height: 18),
              _buildButtons(),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _buildTopBanner() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_blue.withOpacity(0.25), _blue.withOpacity(0.1)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28)),
      ),
      child: Row(children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('New Trip Request!',
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 2),
          Text('Accept karna cheyyi — expire avutundi!',
            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
        ]),
        const Spacer(),
        Stack(alignment: Alignment.center, children: [
          SizedBox(
            width: 56, height: 56,
            child: AnimatedBuilder(
              animation: _ringCtrl,
              builder: (_, __) => CircularProgressIndicator(
                value: 1 - _ringCtrl.value,
                strokeWidth: 4,
                backgroundColor: Colors.white.withOpacity(0.1),
                color: _countdown > 10 ? _blue : const Color(0xFFF59E0B),
              ),
            ),
          ),
          Text('$_countdown',
            style: TextStyle(
              color: _countdown > 10 ? Colors.white : const Color(0xFFF59E0B),
              fontSize: 16, fontWeight: FontWeight.w900)),
        ]),
      ]),
    );
  }

  Widget _buildAddressCard(String pickup, String dest) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(children: [
        Row(children: [
          Container(width: 10, height: 10,
            decoration: const BoxDecoration(color: Color(0xFF2563EB), shape: BoxShape.circle)),
          const SizedBox(width: 12),
          Expanded(child: Text(pickup,
            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
            maxLines: 1, overflow: TextOverflow.ellipsis)),
        ]),
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Row(children: [
            Container(width: 2, height: 16, color: Colors.white.withOpacity(0.12), margin: const EdgeInsets.only(left: 4)),
          ]),
        ),
        Row(children: [
          Container(width: 10, height: 10,
            decoration: BoxDecoration(color: const Color(0xFFF59E0B), borderRadius: BorderRadius.circular(3))),
          const SizedBox(width: 12),
          Expanded(child: Text(dest,
            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
            maxLines: 1, overflow: TextOverflow.ellipsis)),
        ]),
      ]),
    );
  }

  Widget _buildStatsRow(dynamic dist, dynamic fare, dynamic eta) {
    return Row(children: [
      Expanded(child: _stat(Icons.route_rounded, '$dist km', 'Distance', const Color(0xFF10B981))),
      _vertDivider(),
      Expanded(child: _stat(Icons.currency_rupee_rounded, 'Rs.$fare', 'Fare', const Color(0xFFF59E0B))),
      _vertDivider(),
      Expanded(child: _stat(Icons.access_time_rounded, '~$eta min', 'ETA', _blue)),
    ]);
  }

  Widget _stat(IconData icon, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w800)),
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 9, fontWeight: FontWeight.w500)),
      ]),
    );
  }

  Widget _vertDivider() {
    return Container(width: 1, height: 40, color: Colors.white.withOpacity(0.08),
      margin: const EdgeInsets.symmetric(horizontal: 4));
  }

  Widget _buildButtons() {
    return Row(children: [
      Expanded(
        child: GestureDetector(
          onTap: widget.onReject,
          child: Container(
            height: 54,
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.red.withOpacity(0.25), width: 1),
            ),
            child: const Center(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.close_rounded, color: Color(0xFFF87171), size: 20),
              SizedBox(width: 6),
              Text('Reject', style: TextStyle(color: Color(0xFFF87171), fontWeight: FontWeight.w700, fontSize: 14)),
            ])),
          ),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        flex: 2,
        child: GestureDetector(
          onTap: widget.onAccept,
          child: Container(
            height: 54,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF16A34A), Color(0xFF15803D)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(
                color: const Color(0xFF16A34A).withOpacity(0.3),
                blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: const Center(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.check_rounded, color: Colors.white, size: 22),
              SizedBox(width: 8),
              Text('Accept Trip', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
            ])),
          ),
        ),
      ),
    ]);
  }
}
