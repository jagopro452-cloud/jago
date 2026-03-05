import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  Timer? _vibrationTimer;
  late final _timer = Stream.periodic(const Duration(seconds: 1)).listen((_) {
    if (_countdown <= 0) { widget.onReject(); return; }
    setState(() => _countdown--);
  });

  static const Color _primary = Color(0xFF1E6DE5);
  static const Color _blue = Color(0xFF2563EB);
  static const Color _bg = Color(0xFF060D1E);
  static const Color _surface = Color(0xFF0D1B3E);

  @override
  void initState() {
    super.initState();
    _ringCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 30))..forward();
    _slideCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 450))..forward();
    // STRONG initial alert: 3 rapid sound + haptic bursts
    _playAlertBurst();
    // Repeat every 1.5 seconds (double frequency vs before) for full 30s duration
    _vibrationTimer = Timer.periodic(const Duration(milliseconds: 1500), (t) {
      if (_countdown <= 3) t.cancel();
      if (mounted) _playAlertBurst();
    });
  }

  void _playAlertBurst() {
    // 3 rapid beeps + haptics with 150ms gaps for maximum alert effect
    SystemSound.play(SystemSoundType.alert);
    HapticFeedback.heavyImpact();
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) {
        SystemSound.play(SystemSoundType.alert);
        HapticFeedback.mediumImpact();
      }
    });
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        SystemSound.play(SystemSoundType.alert);
        HapticFeedback.heavyImpact();
      }
    });
  }

  @override
  void dispose() { _ringCtrl.dispose(); _slideCtrl.dispose(); _timer.cancel(); _vibrationTimer?.cancel(); super.dispose(); }

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
    final urgency = _countdown <= 10;
    final rawType = (widget.trip['type'] ?? widget.trip['tripType'] ?? widget.trip['trip_type'] ?? 'ride').toString().toLowerCase();
    final isParcel = rawType.contains('parcel');
    final isCargo = rawType.contains('cargo');
    final typeEmoji = isCargo ? '🚛' : isParcel ? '📦' : '🚗';
    final typeLabel = isCargo ? 'Cargo' : isParcel ? 'Parcel' : 'Ride';
    final typeColor = isCargo ? const Color(0xFFF59E0B) : isParcel ? const Color(0xFF10B981) : _blue;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: urgency
            ? [const Color(0xFFF59E0B).withOpacity(0.2), const Color(0xFFF59E0B).withOpacity(0.08)]
            : [_blue.withOpacity(0.22), _blue.withOpacity(0.06)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28)),
        border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.06))),
      ),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                width: 8, height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: urgency ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
                  boxShadow: [BoxShadow(
                    color: (urgency ? const Color(0xFFF59E0B) : const Color(0xFF10B981)).withOpacity(0.5),
                    blurRadius: 6)],
                ),
              ),
              const SizedBox(width: 8),
              Text(urgency ? 'Expiring Soon!' : 'New Trip Request!',
                style: TextStyle(
                  color: urgency ? const Color(0xFFF59E0B) : Colors.white,
                  fontSize: 20, fontWeight: FontWeight.w900)),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: typeColor.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: typeColor.withOpacity(0.4)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(typeEmoji, style: const TextStyle(fontSize: 12)),
                  const SizedBox(width: 5),
                  Text(typeLabel, style: TextStyle(
                    color: typeColor, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.3)),
                ]),
              ),
            ]),
            const SizedBox(height: 4),
            Text('Accept to earn more — every trip counts!',
              style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 12, fontWeight: FontWeight.w500)),
          ]),
        ),
        const SizedBox(width: 16),
        Stack(alignment: Alignment.center, children: [
          SizedBox(
            width: 62, height: 62,
            child: AnimatedBuilder(
              animation: _ringCtrl,
              builder: (_, __) => CircularProgressIndicator(
                value: 1 - _ringCtrl.value,
                strokeWidth: 5,
                backgroundColor: Colors.white.withOpacity(0.08),
                color: urgency ? const Color(0xFFF59E0B) : _blue,
              ),
            ),
          ),
          Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text('$_countdown',
              style: TextStyle(
                color: urgency ? const Color(0xFFF59E0B) : Colors.white,
                fontSize: 20, fontWeight: FontWeight.w900, height: 1)),
            Text('sec', style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 9, fontWeight: FontWeight.w600)),
          ]),
        ]),
      ]),
    );
  }

  Widget _buildAddressCard(String pickup, String dest) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(width: 12, height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle, color: _blue,
                boxShadow: [BoxShadow(color: _blue.withOpacity(0.4), blurRadius: 6)])),
            Expanded(
              child: Container(
                width: 2, margin: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter, end: Alignment.bottomCenter,
                    colors: [_blue.withOpacity(0.5), const Color(0xFFF59E0B).withOpacity(0.5)]),
                  borderRadius: BorderRadius.circular(1)),
              ),
            ),
            Container(width: 12, height: 12,
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B),
                borderRadius: BorderRadius.circular(3),
                boxShadow: [BoxShadow(color: const Color(0xFFF59E0B).withOpacity(0.4), blurRadius: 6)])),
          ]),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Pickup', style: TextStyle(color: Color(0xFF60A5FA), fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                const SizedBox(height: 2),
                Text(pickup,
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700, height: 1.3),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
              ]),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Container(height: 1, color: Colors.white.withOpacity(0.06)),
              ),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Destination', style: TextStyle(color: Color(0xFFFBBF24), fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                const SizedBox(height: 2),
                Text(dest,
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700, height: 1.3),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _buildStatsRow(dynamic dist, dynamic fare, dynamic eta) {
    final fareNum = double.tryParse(fare?.toString() ?? '0') ?? 0;
    final fareLabel = fareNum > 0 ? '₹${fareNum.toStringAsFixed(0)}' : '₹--';
    return Row(children: [
      Expanded(child: _stat(Icons.route_rounded, '$dist km', 'Distance', const Color(0xFF10B981))),
      _vertDivider(),
      Expanded(child: _stat(Icons.currency_rupee_rounded, fareLabel, 'Fare', const Color(0xFFF59E0B))),
      _vertDivider(),
      Expanded(child: _stat(Icons.access_time_rounded, '~$eta min', 'ETA', _blue)),
    ]);
  }

  Widget _stat(IconData icon, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.12), width: 1),
      ),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(height: 6),
        Text(value, style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.w900, height: 1)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 9, fontWeight: FontWeight.w600, letterSpacing: 0.3)),
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
