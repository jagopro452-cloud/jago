import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/api_config.dart';
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
  int _countdown = 40;
  Timer? _countdownTimer;
  bool _responded = false;

  static const Color _blue = Color(0xFF1677FF);
  static const Color _bg = Color(0xFFF7FAFF);
  static const Color _surface = Color(0xFFFFFFFF);

  String _shortLocation(String value) {
    final v = value.trim();
    if (v.isEmpty) return v;
    return v.split(',').first.trim();
  }

  Timer? _vibrationTimer;

  @override
  void initState() {
    super.initState();

    _ringCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 40),
    )..forward();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);

    // Start looping alarm immediately (loud square-wave siren)
    AlarmService().startAlarm();

    // Immediate burst
    _triggerAlertBurst();

    // Continuous vibration every 400ms — felt even with phone in pocket/mount
    _vibrationTimer = Timer.periodic(const Duration(milliseconds: 400), (t) {
      if (!mounted) { t.cancel(); return; }
      HapticFeedback.heavyImpact();
    });

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
    // 5× heavy haptic burst in first 600ms for immediate physical alert
    for (int i = 0; i < 5; i++) {
      Future.delayed(Duration(milliseconds: 80 * i), () {
        if (mounted) {
          HapticFeedback.heavyImpact();
          if (i % 2 == 0) SystemSound.play(SystemSoundType.alert);
        }
      });
    }
  }

  Future<void> _stopAndRespond(bool accepted) async {
    if (_responded) return;
    _responded = true;
    _countdownTimer?.cancel();
    _vibrationTimer?.cancel();
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
    _vibrationTimer?.cancel();
    await AlarmService().stopAlarm();
    widget.onReject();
  }

  @override
  void dispose() {
    _ringCtrl.dispose();
    _pulseCtrl.dispose();
    _countdownTimer?.cancel();
    _vibrationTimer?.cancel();
    if (!_responded) AlarmService().stopAlarm();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final trip = widget.trip;
    final pickup = _shortLocation((trip['pickupShortName'] ?? trip['pickupAddress'] ?? 'Pickup location').toString());
    final dest = _shortLocation((trip['destinationShortName'] ?? trip['destinationAddress'] ?? 'Destination').toString());
    final dist = trip['estimatedDistance'] ?? trip['driverDistanceKm'] ?? '--';
    final fare = trip['estimatedFare'] ?? '--';
    final eta = trip['eta'] ?? 5;
    final urgency = _countdown <= 10;

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
        ? const Color(0xFF1A6FDB)
        : isParcel
            ? const Color(0xFF5B9DFF)
            : _blue;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          bottom: BorderSide(color: Color(0xFFE5EDF7)),
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
                        ? const Color(0xFF1A6FDB)
                        : _blue,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                urgency ? 'Respond Now!' : 'New Trip Request!',
                style: TextStyle(
                  color: const Color(0xFF111827),
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.3,
                ),
              ),
            ]),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: typeColor.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: typeColor.withValues(alpha: 0.18)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(typeEmoji, style: const TextStyle(fontSize: 13)),
                const SizedBox(width: 6),
                Text(
                  typeLabel,
                  style: TextStyle(
                    color: typeColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.4,
                  ),
                ),
              ]),
            ),
          ]),
        ),
        const SizedBox(width: 16),
        // Circular countdown timer — large and prominent
        Stack(alignment: Alignment.center, children: [
          SizedBox(
            width: 84,
            height: 84,
            child: AnimatedBuilder(
              animation: _ringCtrl,
              builder: (_, __) => CircularProgressIndicator(
                value: 1.0 - _ringCtrl.value,
                strokeWidth: 6,
                backgroundColor: Colors.white.withValues(alpha: 0.10),
                valueColor: AlwaysStoppedAnimation<Color>(
                  urgency ? const Color(0xFF1A6FDB) : _blue,
                ),
              ),
            ),
          ),
          Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(
              '$_countdown',
              style: TextStyle(
                color: const Color(0xFF111827),
                fontSize: 28,
                fontWeight: FontWeight.w500,
                height: 1.0,
              ),
            ),
            Text(
              'sec',
              style: TextStyle(
                color: const Color(0xFF94A3B8),
                fontSize: 10,
                fontWeight: FontWeight.w400,
              ),
            ),
          ]),
        ]),
      ]),
    );
  }

  // Returns the appropriate icon for the vehicle type in the trip
  IconData _vehicleIcon() {
    final trip = widget.trip;
    final name = (trip['vehicleCategoryName'] ?? trip['vehicleName'] ?? trip['vehicle_name'] ?? '').toString().toLowerCase();
    final type = (trip['type'] ?? trip['tripType'] ?? '').toString().toLowerCase();
    final isParcel = type.contains('parcel') || name.contains('parcel');
    if (name.contains('pickup van') || name.contains('pickup')) return Icons.fire_truck_rounded;
    if (name.contains('mini truck') || name.contains('tata ace')) return Icons.local_shipping_rounded;
    if (isParcel) return Icons.delivery_dining_rounded;
    if (name.contains('bike')) return Icons.electric_bike_rounded;
    if (name.contains('auto')) return Icons.electric_rickshaw_rounded;
    if (name.contains('car') || name.contains('suv')) return Icons.directions_car_filled_rounded;
    return Icons.directions_car_rounded;
  }

  Widget _buildPulsingIcon(bool urgency) {
    final accentColor = urgency ? const Color(0xFF1A6FDB) : _blue;

    return AnimatedBuilder(
      animation: _pulseCtrl,
      builder: (_, __) {
        final scale = 1.0 + 0.04 * _pulseCtrl.value;
        return Transform.scale(
          scale: scale,
          child: Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accentColor.withValues(alpha: 0.07),
              border: Border.all(
                color: accentColor.withValues(alpha: 0.20),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.12 + 0.10 * _pulseCtrl.value),
                  blurRadius: 24 + 12 * _pulseCtrl.value,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(_vehicleIcon(), color: accentColor, size: 60),
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
        border: Border.all(color: const Color(0xFFE5EDF7)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
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
                  color: const Color(0xFFD8E6F8),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ),
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: const Color(0xFF1A6FDB),
                borderRadius: BorderRadius.circular(3),
                boxShadow: [
                  BoxShadow(
                      color: const Color(0xFF1A6FDB).withValues(alpha: 0.28),
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
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.8)),
              const SizedBox(height: 3),
              Text(pickup,
                  style: const TextStyle(
                      color: Color(0xFF111827),
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      height: 1.3),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Container(
                    height: 1, color: Color(0xFFE5EDF7)),
              ),
              const Text('DROP-OFF',
                  style: TextStyle(
                      color: Color(0xFF1A6FDB),
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.8)),
              const SizedBox(height: 3),
              Text(dest,
                  style: const TextStyle(
                      color: Color(0xFF111827),
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
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
              const Color(0xFF5B9DFF))),
      _vertDivider(),
      Expanded(
          child: _stat(Icons.currency_rupee_rounded, fareLabel, 'Fare',
              const Color(0xFF1A6FDB))),
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
        ? const Color(0xFF1A6FDB)
        : method == 'online'
            ? _blue
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
              color: color, fontSize: 12, fontWeight: FontWeight.w500),
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
                fontWeight: FontWeight.w500,
                height: 1.0)),
        const SizedBox(height: 3),
        Text(label,
            style: TextStyle(
                color: const Color(0xFF94A3B8),
                fontSize: 9,
                fontWeight: FontWeight.w400,
                letterSpacing: 0.3)),
      ]),
    );
  }

  Widget _vertDivider() => Container(
      width: 1,
      height: 40,
      color: const Color(0xFFE5EDF7),
      margin: const EdgeInsets.symmetric(horizontal: 4));

  Widget _buildButtons() {
    return Column(children: [
      // ACCEPT — full width, dominant green button
      GestureDetector(
        onTap: () => _stopAndRespond(true),
        child: Container(
          width: double.infinity,
          height: 76,
          decoration: BoxDecoration(
            color: _blue,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: _blue.withValues(alpha: 0.14),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Center(
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 30),
              SizedBox(width: 12),
              Text(
                'ACCEPT TRIP',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 20,
                  letterSpacing: 0.5,
                ),
              ),
            ]),
          ),
        ),
      ),
      const SizedBox(height: 12),
      // REJECT — smaller, de-emphasised
      GestureDetector(
        onTap: () => _stopAndRespond(false),
        child: Container(
          width: double.infinity,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFF3D2D2), width: 1.2),
          ),
          child: const Center(
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.close_rounded, color: Color(0xFFF87171), size: 20),
              SizedBox(width: 8),
              Text(
                'Skip this trip',
                style: TextStyle(
                  color: Color(0xFFF87171),
                  fontWeight: FontWeight.w400,
                  fontSize: 15,
                ),
              ),
            ]),
          ),
        ),
      ),
    ]);
  }
}
