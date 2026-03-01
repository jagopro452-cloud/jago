import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../../models/trip_model.dart';
import '../../services/trip_service.dart';
import '../home/home_screen.dart';

class TripScreen extends StatefulWidget {
  final TripModel trip;
  const TripScreen({super.key, required this.trip});

  @override
  State<TripScreen> createState() => _TripScreenState();
}

class _TripScreenState extends State<TripScreen> {
  late TripModel _trip;
  bool _loading = false;
  String? _error;
  String _otpInput = '';
  double _rating = 5;
  bool _showRating = false;

  String get _status => _trip.currentStatus;

  @override
  void initState() {
    super.initState();
    _trip = widget.trip;
  }

  Future<void> _markArrived() async {
    setState(() { _loading = true; _error = null; });
    final res = await TripService.markArrived(_trip.id);
    if (res['success'] == true) {
      setState(() { _trip = TripModel.fromJson({..._trip.toJson(), 'currentStatus': 'arrived'}); });
    } else {
      setState(() => _error = res['message']);
    }
    setState(() => _loading = false);
  }

  Future<void> _verifyOtp() async {
    if (_otpInput.length < 4) {
      setState(() => _error = 'Enter 4-digit OTP');
      return;
    }
    setState(() { _loading = true; _error = null; });
    final res = await TripService.verifyPickupOtp(_trip.id, _otpInput);
    if (res['success'] == true) {
      setState(() { _trip = TripModel.fromJson({..._trip.toJson(), 'currentStatus': 'on_the_way'}); });
    } else {
      setState(() => _error = res['message'] ?? 'Invalid OTP');
    }
    setState(() => _loading = false);
  }

  Future<void> _completeTrip() async {
    setState(() { _loading = true; _error = null; });
    final res = await TripService.completeTrip(
      tripId: _trip.id,
      actualFare: _trip.estimatedFare,
      actualDistance: _trip.estimatedDistance,
    );
    if (res['success'] == true) {
      setState(() { _showRating = true; _loading = false; });
    } else {
      setState(() { _error = res['message']; _loading = false; });
    }
  }

  Future<void> _submitRating() async {
    await TripService.rateCustomer(tripId: _trip.id, rating: _rating);
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (_) => false,
    );
  }

  void _showCancelDialog() {
    showDialog(
      context: context,
      builder: (_) {
        String reason = 'Customer unavailable';
        return AlertDialog(
          backgroundColor: const Color(0xFF091629),
          title: const Text('Cancel Trip', style: TextStyle(color: Colors.white)),
          content: DropdownButtonFormField<String>(
            value: reason,
            dropdownColor: const Color(0xFF091629),
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(border: OutlineInputBorder()),
            items: ['Customer unavailable', 'Traffic too heavy', 'Vehicle issue', 'Other']
                .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                .toList(),
            onChanged: (v) => reason = v!,
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Back')),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await TripService.cancelTrip(_trip.id, reason);
                if (mounted) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const HomeScreen()), (_) => false);
              },
              child: const Text('Confirm Cancel', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_showRating) return _buildRatingScreen();

    return Scaffold(
      backgroundColor: const Color(0xFF060D1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF060D1E),
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () {}),
        title: Text(_getStatusTitle(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          if (_status == 'accepted' || _status == 'arrived')
            TextButton(
              onPressed: _showCancelDialog,
              child: const Text('Cancel', style: TextStyle(color: Colors.red)),
            ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _buildCustomerCard(),
              const SizedBox(height: 16),
              _buildRouteCard(),
              const SizedBox(height: 16),
              _buildStatusCard(),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: const TextStyle(color: Colors.red)),
              ],
              const Spacer(),
              _buildActionButton(),
            ],
          ),
        ),
      ),
    );
  }

  String _getStatusTitle() {
    switch (_status) {
      case 'accepted': return 'Going to Pickup';
      case 'arrived': return 'Arrived at Pickup';
      case 'on_the_way': return 'Ride in Progress';
      default: return 'Active Trip';
    }
  }

  Widget _buildCustomerCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF091629), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF1E3A5F))),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(color: const Color(0xFF1E3A5F), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.person, color: Color(0xFF3B82F6)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_trip.customerName ?? 'Customer', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                Row(children: [
                  const Icon(Icons.star, color: Colors.amber, size: 14),
                  Text(' ${_trip.customerRating.toStringAsFixed(1)}', style: const TextStyle(color: Color(0xFF94A3B8))),
                ]),
              ],
            ),
          ),
          InkWell(
            onTap: () {},
            child: Container(
              width: 44, height: 44,
              decoration: BoxDecoration(color: const Color(0xFF1E3A5F), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.phone, color: Color(0xFF3B82F6)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF091629), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF1E3A5F))),
      child: Column(
        children: [
          Row(children: [
            const Icon(Icons.my_location, color: Color(0xFF3B82F6), size: 18),
            const SizedBox(width: 10),
            Expanded(child: Text(_trip.pickupAddress, style: const TextStyle(color: Colors.white, fontSize: 13), maxLines: 2)),
          ]),
          Container(margin: const EdgeInsets.only(left: 9, top: 6, bottom: 6), height: 24, width: 1, color: const Color(0xFF1E3A5F)),
          Row(children: [
            const Icon(Icons.location_on, color: Color(0xFFEF4444), size: 18),
            const SizedBox(width: 10),
            Expanded(child: Text(_trip.destinationAddress, style: const TextStyle(color: Colors.white, fontSize: 13), maxLines: 2)),
          ]),
          const Divider(color: Color(0xFF1E3A5F), height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _infoItem('Fare', '₹${_trip.estimatedFare.toStringAsFixed(0)}'),
              _infoItem('Distance', '${_trip.estimatedDistance.toStringAsFixed(1)} km'),
              _infoItem('Payment', _trip.paymentMethod.toUpperCase()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    if (_status == 'arrived') {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: const Color(0xFF091629), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF2563EB))),
        child: Column(
          children: [
            const Text('Customer OTP', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
            const SizedBox(height: 12),
            PinCodeTextField(
              appContext: context,
              length: 4,
              onChanged: (v) => setState(() => _otpInput = v),
              keyboardType: TextInputType.number,
              pinTheme: PinTheme(
                shape: PinCodeFieldShape.box,
                borderRadius: BorderRadius.circular(10),
                fieldHeight: 52, fieldWidth: 52,
                activeFillColor: const Color(0xFF060D1E),
                inactiveFillColor: const Color(0xFF060D1E),
                selectedFillColor: const Color(0xFF0C2050),
                activeColor: const Color(0xFF3B82F6),
                inactiveColor: const Color(0xFF1E3A5F),
                selectedColor: const Color(0xFF2563EB),
              ),
              enableActiveFill: true,
              textStyle: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text('Ask customer for 4-digit OTP to start the ride', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
          ],
        ),
      );
    }
    if (_status == 'on_the_way') {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: const Color(0xFF0C2050).withOpacity(0.5), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF2563EB))),
        child: const Row(
          children: [
            Icon(Icons.directions_car, color: Color(0xFF3B82F6)),
            SizedBox(width: 12),
            Text('Ride is in progress. Drive safely!', style: TextStyle(color: Colors.white, fontSize: 14)),
          ],
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF091629), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF1E3A5F))),
      child: const Row(
        children: [
          Icon(Icons.navigation, color: Color(0xFF3B82F6)),
          SizedBox(width: 12),
          Text('Navigate to pickup location', style: TextStyle(color: Colors.white, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildActionButton() {
    if (_status == 'accepted') {
      return _actionBtn('Arrived at Pickup', Icons.location_on, _loading ? null : _markArrived);
    }
    if (_status == 'arrived') {
      return _actionBtn('Verify OTP & Start Ride', Icons.play_arrow, _loading ? null : _verifyOtp);
    }
    if (_status == 'on_the_way') {
      return _actionBtn('Complete Trip', Icons.check_circle, _loading ? null : _completeTrip, color: const Color(0xFF16A34A));
    }
    return const SizedBox();
  }

  Widget _actionBtn(String label, IconData icon, VoidCallback? onTap, {Color color = const Color(0xFF2563EB)}) {
    return SizedBox(
      width: double.infinity, height: 56,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: _loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Icon(icon),
        label: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0),
      ),
    );
  }

  Widget _infoItem(String label, String value) {
    return Column(children: [
      Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
      Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 11)),
    ]);
  }

  Widget _buildRatingScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFF060D1E),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, color: Color(0xFF22C55E), size: 80),
              const SizedBox(height: 20),
              const Text('Trip Completed!', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Fare: ₹${_trip.estimatedFare.toStringAsFixed(2)}', style: const TextStyle(color: Color(0xFF3B82F6), fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 40),
              const Text('Rate the Customer', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 16)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) => GestureDetector(
                  onTap: () => setState(() => _rating = i + 1),
                  child: Icon(i < _rating ? Icons.star : Icons.star_border, color: Colors.amber, size: 40),
                )),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity, height: 56,
                child: ElevatedButton(
                  onPressed: _submitRating,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0),
                  child: const Text('Submit & Go Home', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

extension on TripModel {
  Map<String, dynamic> toJson() => {
    'id': id, 'refId': refId, 'pickupAddress': pickupAddress,
    'pickupLat': pickupLat, 'pickupLng': pickupLng,
    'destinationAddress': destinationAddress, 'destinationLat': destinationLat, 'destinationLng': destinationLng,
    'estimatedFare': estimatedFare, 'actualFare': actualFare, 'estimatedDistance': estimatedDistance,
    'currentStatus': currentStatus, 'paymentMethod': paymentMethod, 'pickupOtp': pickupOtp,
    'customerName': customerName, 'customerPhone': customerPhone, 'customerRating': customerRating,
  };
}
