import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/alarm_service.dart';

/// Full-screen ride request overlay.
/// Pushed as a Navigator route so it sits above the home map.
/// Plays a looping alarm via AlarmService (audioplayers + generated WAV).
/// Stops alarm and pops automatically when timer hits 0 or driver responds.
class IncomingTripSheet extends StatefulWidget {
  final Map<String, dynamic> trip;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  const IncomingTripSheet({
    super.key,
    required this.trip,
    required this.onAccept,
    required this.onReject,
  });
  @override
  State<IncomingTripSheet> createState() => _IncomingTripSheetState();
}

class _IncomingTripSheetState extends State<IncomingTripSheet>
    with TickerProviderStateMixin {
  late AnimationController _ringCtrl;
  late AnimationController _pulseCtrl;
  int _countdown = 15;
  Timer? _countdownTimer;
  bool _responded = false;

  static const Color _blue = Color(0xFF2563EB);
  static const Color _bg = Color(0xFF060D1E);
  static const Color _surface = Color(0xFF0D1B3E);

  @override
  void initState() {
    super.initState();

    _ringCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..forward();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    // Start looping alarm immediately
    AlarmService().startAlarm();

    // Vibration burst on arrival
    _triggerAlertBurst();

    // Countdown: auto-reject at 0
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      if (_countdown <= 0) {
        t.cancel();
        _autoReject();
        return;
      }
      setState(() => _countdown--);
    });
  }

  void _triggerAlertBurst() {
    // Triple haptic + system beep for immediate physical alert
    HapticFeedback.heavyImpact();
    SystemSound.play(SystemSoundType.alert);
    Future.delayed(const Duration(milliseconds: 120), () {
      if (mounted) {
        HapticFeedback.heavyImpact();
        SystemSound.play(SystemSoundType.alert);
      }
    });
    Future.delayed(const Duration(milliseconds: 240), () {
      if (mounted) HapticFeedback.heavyImpact();
    });
  }

  Future<void> _stopAndRespond(bool accepted) async {
    if (_responded) return;
    _responded = true;
    _countdownTimer?.cancel();
    await AlarmService().stopAlarm();
    if (accepted) {
      widget.onAccept();
    } else {
      widget.onReject();
    }
  }

  Future<void> _autoReject() async {
    if (_responded) return;
    _responded = true;
    await AlarmService().stopAlarm();
    widget.onReject();
  }

  @override
  void dispose() {
    _ringCtrl.dispose();
    _pulseCtrl.dispose();
    _countdownTimer?.cancel();
    // If widget is disposed without responding (e.g. trip:taken event),
    // stop the alarm so it doesn't keep playing.
    if (!_responded) AlarmService().stopAlarm();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final trip = widget.trip;
    final pickup = trip['pickupAddress'] ?? 'Pickup location';
    final dest = trip['destinationAddress'] ?? 'Destination';
    final dist = trip['estimatedDistance'] ?? trip['driverDistanceKm'] ?? '--';
    final fare = trip['estimatedFare'] ?? '--';
    final eta = trip['eta'] ?? 5;
    final urgency = _countdown <= 7;

    return PopScope(
      canPop: false, // Disable back-button dismiss
      child: Scaffold(
        backgroundColor: _bg,
        body: SafeArea(
          child: Column(
            children: [
              // â”€â”€ Header â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
              _buildHeader(urgency, trip),
              // â”€â”€ Scrollable Details â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Column(children: [
                    _buildPulsingIcon(urgency),
                    const SizedBox(height: 20),
                    _buildAddressCard(pickup, dest),
                    const SizedBox(height: 16),
                    _buildStatsRow(dist, fare, eta),
                    const SizedBox(height: 8),
                    _buildPaymentBadge(trip),
                  ]),
                ),
              ),
              // â”€â”€ Action Buttons â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: _buildButtons(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool urgency, Map<String, dynamic> trip) {
    final rawType = (trip['type'] ?? trip['tripType'] ?? trip['trip_type'] ?? 'ride')
        .toString()
        .toLowerCase();
    final isParcel = rawType.contains('parcel');
    final isCargo = rawType.contains('cargo');
    final typeEmoji = isCargo ? 'ðŸš›' : isParcel ? 'ðŸ“¦' : 'ðŸš—';
    final typeLabel = isCargo ? 'Cargo' : isParcel ? 'Parcel' : 'Ride';
    final typeColor = isCargo
        ? const Color(0xFFF59E0B)
        : isParcel
            ? const Color(0xFF10B981)
            : _blue;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: urgency
              ? [
                  const Color(0xFFF59E0B).withValues(alpha: 0.18),
                  const Color(0xFFF59E0B).withValues(alpha: 0.05),
                ]
              : [
                  _blue.withValues(alpha: 0.20),
                  _blue.withValues(alpha: 0.05),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
        ),
      ),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              AnimatedBuilder(
                animation: _pulseCtrl,
                builder: (_, __) => Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: urgency
                        ? const Color(0xFFF59E0B)
                        : const Color(0xFF10B981),
                    boxShadow: [
                      BoxShadow(
                        color: (urgency
                                ? const Color(0xFFF59E0B)
                                : const Color(0xFF10B981))
                            .withValues(alpha: 0.4 + 0.4 * _pulseCtrl.value),
                        blurRadius: 8 + 4 * _pulseCtrl.value,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                urgency ? 'Respond Now!' : 'New Trip Request!',
                style: TextStyle(
                  color: urgency ? const Color(0xFFF59E0B) : Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.3,
                ),
              ),
            ]),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: typeColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: typeColor.withValues(alpha: 0.35)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(typeEmoji, style: const TextStyle(fontSize: 13)),
                const SizedBox(width: 6),
                Text(
                  typeLabel,
                  style: TextStyle(
                    color: typeColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                  ),
                ),
              ]),
            ),
          ]),
        ),
        const SizedBox(width: 16),
        // Circular countdown timer
        Stack(alignment: Alignment.center, children: [
          SizedBox(
            width: 68,
            height: 68,
            child: AnimatedBuilder(
              animation: _ringCtrl,
              builder: (_, __) => CircularProgressIndicator(
                value: 1.0 - _ringCtrl.value,
                strokeWidth: 5,
                backgroundColor: Colors.white.withValues(alpha: 0.08),
                valueColor: AlwaysStoppedAnimation<Color>(
                  urgency ? const Color(0xFFF59E0B) : _blue,
                ),
              ),
            ),
          ),
          Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(
              '$_countdown',
              style: TextStyle(
                color: urgency ? const Color(0xFFF59E0B) : Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                height: 1.0,
              ),
            ),
            Text(
              'sec',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.3),
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
            ),
          ]),
        ]),
      ]),
    );
  }

  Widget _buildPulsingIcon(bool urgency) {
    return AnimatedBuilder(
      animation: _pulseCtrl,
      builder: (_, __) {
        final scale = 1.0 + 0.06 * _pulseCtrl.value;
        return Transform.scale(
          scale: scale,
          child: Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: urgency
                  ? const Color(0xFFF59E0B).withValues(alpha: 0.12)
                  : _blue.withValues(alpha: 0.12),
              border: Border.all(
                color: urgency
                    ? const Color(0xFFF59E0B).withValues(alpha: 0.35)
                    : _blue.withValues(alpha: 0.35),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: (urgency ? const Color(0xFFF59E0B) : _blue)
                      .withValues(alpha: 0.15 + 0.15 * _pulseCtrl.value),
                  blurRadius: 20 + 10 * _pulseCtrl.value,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(
              Icons.directions_car_rounded,
              color: urgency ? const Color(0xFFF59E0B) : _blue,
              size: 40,
            ),
          ),
        );
      },
    );
  }

  Widget _buildAddressCard(String pickup, String dest) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _blue,
                boxShadow: [
                  BoxShadow(color: _blue.withValues(alpha: 0.4), blurRadius: 6)
                ],
              ),
            ),
            Expanded(
              child: Container(
                width: 2,
                margin: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      _blue.withValues(alpha: 0.5),
                      const Color(0xFFF59E0B).withValues(alpha: 0.5)
                    ],
                  ),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ),
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B),
                borderRadius: BorderRadius.circular(3),
                boxShadow: [
                  BoxShadow(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                      blurRadius: 6)
                ],
              ),
            ),
          ]),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('PICKUP',
                  style: TextStyle(
                      color: Color(0xFF60A5FA),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8)),
              const SizedBox(height: 3),
              Text(pickup,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      height: 1.3),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Container(
                    height: 1, color: Colors.white.withValues(alpha: 0.06)),
              ),
              const Text('DROP-OFF',
                  style: TextStyle(
                      color: Color(0xFFFBBF24),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8)),
              const SizedBox(height: 3),
              Text(dest,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      height: 1.3),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _buildStatsRow(dynamic dist, dynamic fare, dynamic eta) {
    final fareNum = double.tryParse(fare?.toString() ?? '0') ?? 0;
    final fareLabel = fareNum > 0 ? 'â‚¹${fareNum.toStringAsFixed(0)}' : 'â‚¹--';
    return Row(children: [
      Expanded(
          child: _stat(Icons.route_rounded, '$dist km', 'Distance',
              const Color(0xFF10B981))),
      _vertDivider(),
      Expanded(
          child: _stat(Icons.currency_rupee_rounded, fareLabel, 'Fare',
              const Color(0xFFF59E0B))),
      _vertDivider(),
      Expanded(
          child:
              _stat(Icons.access_time_rounded, '~$eta min', 'ETA', _blue)),
    ]);
  }

  Widget _buildPaymentBadge(Map<String, dynamic> trip) {
    final method =
        (trip['paymentMethod'] ?? trip['payment_method'] ?? 'cash').toString();
    final icon = method == 'wallet'
        ? Icons.account_balance_wallet_rounded
        : method == 'online'
            ? Icons.phone_android_rounded
            : Icons.money_rounded;
    final color = method == 'wallet'
        ? const Color(0xFF8B5CF6)
        : method == 'online'
            ? const Color(0xFF10B981)
            : const Color(0xFF6B7280);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 8),
        Text(
          'Payment: ${method.toUpperCase()}',
          style: TextStyle(
              color: color, fontSize: 12, fontWeight: FontWeight.w700),
        ),
      ]),
    );
  }

  Widget _stat(IconData icon, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.12)),
      ),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 17),
        ),
        const SizedBox(height: 6),
        Text(value,
            style: TextStyle(
                color: color,
                fontSize: 15,
                fontWeight: FontWeight.w900,
                height: 1.0)),
        const SizedBox(height: 3),
        Text(label,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.35),
                fontSize: 9,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3)),
      ]),
    );
  }

  Widget _vertDivider() => Container(
      width: 1,
      height: 40,
      color: Colors.white.withValues(alpha: 0.08),
      margin: const EdgeInsets.symmetric(horizontal: 4));

  Widget _buildButtons() {
    return Row(children: [
      // Reject
      Expanded(
        child: GestureDetector(
          onTap: () => _stopAndRespond(false),
          child: Container(
            height: 58,
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(18),
              border:
                  Border.all(color: Colors.red.withValues(alpha: 0.30), width: 1.5),
            ),
            child: const Center(
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.close_rounded, color: Color(0xFFF87171), size: 22),
                SizedBox(width: 8),
                Text('Reject',
                    style: TextStyle(
                        color: Color(0xFFF87171),
                        fontWeight: FontWeight.w700,
                        fontSize: 15)),
              ]),
            ),
          ),
        ),
      ),
      const SizedBox(width: 14),
      // Accept
      Expanded(
        flex: 2,
        child: GestureDetector(
          onTap: () => _stopAndRespond(true),
          child: Container(
            height: 58,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFF16A34A), Color(0xFF15803D)]),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                    color: const Color(0xFF16A34A).withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 5))
              ],
            ),
            child: const Center(
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 24),
                SizedBox(width: 10),
                Text('Accept Trip',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 17)),
              ]),
            ),
          ),
        ),
      ),
    ]);
  }
}
