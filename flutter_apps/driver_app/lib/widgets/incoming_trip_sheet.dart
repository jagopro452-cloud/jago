import 'package:flutter/material.dart';

class IncomingTripSheet extends StatefulWidget {
  final Map<String, dynamic> trip;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  const IncomingTripSheet({super.key, required this.trip, required this.onAccept, required this.onReject});
  @override
  State<IncomingTripSheet> createState() => _IncomingTripSheetState();
}

class _IncomingTripSheetState extends State<IncomingTripSheet> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  int _countdown = 30;
  late final _timer = Stream.periodic(const Duration(seconds: 1)).listen((_) {
    if (_countdown <= 0) { widget.onReject(); return; }
    setState(() => _countdown--);
  });

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 30))..forward();
  }

  @override
  void dispose() { _ctrl.dispose(); _timer.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final trip = widget.trip;
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1B4B), borderRadius: BorderRadius.circular(24)),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(height: 20),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF2563EB), width: 3),
            ),
            child: Center(child: Text('$_countdown',
              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold))),
          ),
        ]),
        const SizedBox(height: 16),
        const Text('New Trip Request!',
          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(children: [
            _row(Icons.location_on, const Color(0xFF2563EB), trip['pickupAddress'] ?? 'Pickup'),
            const Padding(padding: EdgeInsets.only(left: 12), child: Divider(color: Colors.white12, height: 12)),
            _row(Icons.flag, Colors.orange, trip['destinationAddress'] ?? 'Destination'),
          ]),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(children: [
            _info(Icons.route, '${trip['estimatedDistance'] ?? '--'} km'),
            const SizedBox(width: 16),
            _info(Icons.payments_outlined, '₹${trip['estimatedFare'] ?? '--'}'),
            const SizedBox(width: 16),
            _info(Icons.access_time, '~${trip['eta'] ?? 5} min'),
          ]),
        ),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: widget.onReject,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.white.withOpacity(0.2)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Reject', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: widget.onAccept,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14), elevation: 0),
                child: const Text('Accept', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 24),
      ]),
    );
  }

  Widget _row(IconData icon, Color color, String text) {
    return Row(children: [
      Icon(icon, color: color, size: 18),
      const SizedBox(width: 10),
      Expanded(child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
        maxLines: 1, overflow: TextOverflow.ellipsis)),
    ]);
  }

  Widget _info(IconData icon, String label) {
    return Row(children: [
      Icon(icon, color: Colors.white.withOpacity(0.5), size: 16),
      const SizedBox(width: 4),
      Text(label, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13, fontWeight: FontWeight.w500)),
    ]);
  }
}
