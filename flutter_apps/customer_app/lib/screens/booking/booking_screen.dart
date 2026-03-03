import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../config/api_config.dart';
import '../../services/auth_service.dart';
import '../tracking/tracking_screen.dart';

class BookingScreen extends StatefulWidget {
  final String pickup;
  final String destination;
  final double pickupLat, pickupLng, destLat, destLng;
  final String? vehicleCategoryId;
  final String? vehicleCategoryName;
  const BookingScreen({
    super.key,
    required this.pickup,
    required this.destination,
    this.pickupLat = 17.3850, this.pickupLng = 78.4867,
    this.destLat = 0, this.destLng = 0,
    this.vehicleCategoryId,
    this.vehicleCategoryName,
  });
  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> with TickerProviderStateMixin {
  GoogleMapController? _mapController;
  bool _loading = false;
  bool _estimating = true;
  Map<String, dynamic>? _fare;
  String _paymentMethod = 'cash';
  double _walletBalance = 0;
  bool _walletLoading = false;
  final TextEditingController _promoCtrl = TextEditingController();
  String? _appliedPromo;
  double _promoDiscount = 0;
  bool _promoLoading = false;
  String? _promoError;

  late Razorpay _razorpay;
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  // Book for someone else
  bool _bookForSomeone = false;
  final _passengerNameCtrl = TextEditingController();
  final _passengerPhoneCtrl = TextEditingController();
  final _receiverNameCtrl = TextEditingController();
  final _receiverPhoneCtrl = TextEditingController();

  static const Color _blue = Color(0xFF1E6DE5);
  static const Color _dark = Color(0xFF0F172A);
  static const Color _green = Color(0xFF16A34A);

  LatLng get _pickupLatLng => LatLng(widget.pickupLat, widget.pickupLng);
  LatLng get _destLatLng => widget.destLat != 0 && widget.destLng != 0
    ? LatLng(widget.destLat, widget.destLng)
    : LatLng(widget.pickupLat + 0.02, widget.pickupLng + 0.02);

  String get _vehicleName => widget.vehicleCategoryName ?? 'Bike';

  static IconData _iconForVehicle(String name) {
    final n = name.toLowerCase();
    if (n.contains('bike parcel') || n.contains('parcel bike')) return Icons.delivery_dining;
    if (n.contains('bike')) return Icons.electric_bike;
    if (n.contains('mini auto') || n.contains('temo auto')) return Icons.electric_rickshaw;
    if (n.contains('auto')) return Icons.electric_rickshaw;
    if (n.contains('tata ace') || n.contains('mini cargo')) return Icons.local_shipping;
    if (n.contains('cargo truck')) return Icons.fire_truck;
    if (n.contains('cargo')) return Icons.local_shipping;
    if (n.contains('parcel')) return Icons.delivery_dining;
    if (n.contains('suv')) return Icons.directions_car;
    if (n.contains('car')) return Icons.directions_car_filled;
    return Icons.directions_car;
  }

  double get _distanceKm {
    if (widget.destLat == 0 && widget.destLng == 0) return 3.0;
    final dlat = widget.destLat - widget.pickupLat;
    final dlng = widget.destLng - widget.pickupLng;
    return ((dlat * dlat + dlng * dlng) * 12321).clamp(0.5, 100.0);
  }

  double get _finalFare {
    final f = (_fare?['estimatedFare'] ?? 0).toDouble();
    return (f - _promoDiscount).clamp(0, double.infinity);
  }

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handleRazorpaySuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handleRazorpayError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    _estimateFare();
    _fetchWallet();
  }

  @override
  void dispose() {
    _promoCtrl.dispose();
    _razorpay.clear();
    _fadeCtrl.dispose();
    _passengerNameCtrl.dispose();
    _passengerPhoneCtrl.dispose();
    _receiverNameCtrl.dispose();
    _receiverPhoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchWallet() async {
    setState(() => _walletLoading = true);
    final token = await AuthService.getToken();
    try {
      final res = await http.get(Uri.parse(ApiConfig.wallet),
        headers: {'Authorization': 'Bearer $token'});
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (mounted) setState(() => _walletBalance = (data['balance'] ?? 0).toDouble());
      }
    } catch (_) {}
    if (mounted) setState(() => _walletLoading = false);
  }

  Future<void> _applyPromo() async {
    final code = _promoCtrl.text.trim().toUpperCase();
    if (code.isEmpty) return;
    setState(() { _promoLoading = true; _promoError = null; });
    final token = await AuthService.getToken();
    try {
      final res = await http.post(Uri.parse(ApiConfig.applyCoupon),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: jsonEncode({'code': code, 'fareAmount': (_fare?['estimatedFare'] ?? 0).toDouble()}));
      final data = jsonDecode(res.body);
      if (res.statusCode == 200) {
        setState(() {
          _appliedPromo = code;
          _promoDiscount = double.tryParse(data['discount']?.toString() ?? '0') ?? 0;
          _promoLoading = false;
        });
      } else {
        setState(() { _promoError = data['message'] ?? 'Invalid code'; _promoLoading = false; });
      }
    } catch (_) {
      setState(() { _promoError = 'Network error'; _promoLoading = false; });
    }
  }

  Future<void> _estimateFare() async {
    setState(() => _estimating = true);
    final token = await AuthService.getToken();
    try {
      final body = <String, dynamic>{
        'pickupLat': widget.pickupLat, 'pickupLng': widget.pickupLng,
        'destLat': widget.destLat, 'destLng': widget.destLng,
        'distanceKm': _distanceKm,
      };
      if (widget.vehicleCategoryId != null) body['vehicleCategoryId'] = widget.vehicleCategoryId;
      final res = await http.post(Uri.parse(ApiConfig.estimateFare),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: jsonEncode(body));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final fares = data['fares'] as List<dynamic>?;
        if (fares != null && fares.isNotEmpty) {
          setState(() => _fare = fares[0] as Map<String, dynamic>);
          _fadeCtrl.forward();
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _estimating = false);
  }

  Future<void> _confirmBooking({String? razorpayPaymentId}) async {
    setState(() => _loading = true);
    final token = await AuthService.getToken();
    try {
      final body = <String, dynamic>{
        'pickupAddress': widget.pickup,
        'destinationAddress': widget.destination,
        'pickupLat': widget.pickupLat, 'pickupLng': widget.pickupLng,
        'destinationLat': widget.destLat, 'destinationLng': widget.destLng,
        'estimatedFare': _finalFare,
        'estimatedDistance': _distanceKm,
        'paymentMethod': _paymentMethod,
        if (_promoDiscount > 0) 'promoDiscount': _promoDiscount,
        if (_appliedPromo != null) 'couponCode': _appliedPromo,
        if (razorpayPaymentId != null) 'razorpayPaymentId': razorpayPaymentId,
        if (_bookForSomeone) 'isForSomeoneElse': true,
        if (_bookForSomeone && _passengerNameCtrl.text.trim().isNotEmpty)
          'passengerName': _passengerNameCtrl.text.trim(),
        if (_bookForSomeone && _passengerPhoneCtrl.text.trim().isNotEmpty)
          'passengerPhone': _passengerPhoneCtrl.text.trim(),
        if (_bookForSomeone && _receiverNameCtrl.text.trim().isNotEmpty)
          'receiverName': _receiverNameCtrl.text.trim(),
        if (_bookForSomeone && _receiverPhoneCtrl.text.trim().isNotEmpty)
          'receiverPhone': _receiverPhoneCtrl.text.trim(),
      };
      if (widget.vehicleCategoryId != null) body['vehicleCategoryId'] = widget.vehicleCategoryId;
      final res = await http.post(Uri.parse(ApiConfig.bookRide),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: jsonEncode(body));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final tripId = data['trip']?['id'] ?? '';
        if (!mounted) return;
        Navigator.pushReplacement(context, MaterialPageRoute(
          builder: (_) => TrackingScreen(tripId: tripId)));
      } else {
        if (!mounted) return;
        final err = jsonDecode(res.body);
        _showSnack(err['message'] ?? 'Booking failed', error: true);
      }
    } catch (_) {
      if (!mounted) return;
      _showSnack('Network error. Try again.', error: true);
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _handleOnConfirm() async {
    if (_paymentMethod == 'upi') {
      await _startRazorpayRidePayment();
    } else {
      if (_paymentMethod == 'wallet') {
        final fare = _finalFare;
        if (_walletBalance < fare) {
          _showSnack('Insufficient wallet balance. Please recharge.', error: true);
          return;
        }
      }
      await _confirmBooking();
    }
  }

  Future<void> _startRazorpayRidePayment() async {
    setState(() => _loading = true);
    final token = await AuthService.getToken();
    try {
      final fare = _finalFare;
      final res = await http.post(Uri.parse(ApiConfig.rideCreateOrder),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: jsonEncode({'amount': fare}));
      if (res.statusCode != 200) {
        setState(() => _loading = false);
        final err = jsonDecode(res.body);
        _showSnack(err['message'] ?? 'Payment setup failed', error: true);
        return;
      }
      final data = jsonDecode(res.body);
      final order = data['order'];
      final keyId = data['keyId'];
      final profileData = await AuthService.getProfile();
      final options = {
        'key': keyId,
        'amount': order['amount'],
        'currency': 'INR',
        'name': 'JAGO Rides',
        'description': 'Ride to ${widget.destination}',
        'order_id': order['id'],
        'prefill': {
          'name': profileData?['fullName'] ?? '',
          'contact': profileData?['phone'] ?? '',
        },
        'theme': {'color': '#1E6DE5'},
      };
      _razorpay.open(options);
    } catch (_) {
      setState(() => _loading = false);
      _showSnack('Payment failed. Try again.', error: true);
    }
  }

  void _handleRazorpaySuccess(PaymentSuccessResponse response) async {
    setState(() => _loading = true);
    final token = await AuthService.getToken();
    try {
      final verifyRes = await http.post(Uri.parse(ApiConfig.rideVerifyPayment),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: jsonEncode({
          'razorpayOrderId': response.orderId,
          'razorpayPaymentId': response.paymentId,
          'razorpaySignature': response.signature,
          'amount': _finalFare,
        }));
      if (verifyRes.statusCode == 200) {
        await _confirmBooking(razorpayPaymentId: response.paymentId);
      } else {
        setState(() => _loading = false);
        _showSnack('Payment verification failed. Contact support.', error: true);
      }
    } catch (_) {
      setState(() => _loading = false);
      _showSnack('Payment verification failed.', error: true);
    }
  }

  void _handleRazorpayError(PaymentFailureResponse response) {
    setState(() => _loading = false);
    _showSnack(response.message ?? 'Payment cancelled', error: true);
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    setState(() => _loading = false);
  }

  void _showSnack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
      backgroundColor: error ? const Color(0xFFDC2626) : _green,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(target: _pickupLatLng, zoom: 13),
          onMapCreated: (c) {
            _mapController = c;
            Future.delayed(const Duration(milliseconds: 500), () {
              _mapController?.animateCamera(CameraUpdate.newLatLngBounds(
                LatLngBounds(
                  southwest: LatLng(
                    _pickupLatLng.latitude < _destLatLng.latitude ? _pickupLatLng.latitude : _destLatLng.latitude,
                    _pickupLatLng.longitude < _destLatLng.longitude ? _pickupLatLng.longitude : _destLatLng.longitude,
                  ),
                  northeast: LatLng(
                    _pickupLatLng.latitude > _destLatLng.latitude ? _pickupLatLng.latitude : _destLatLng.latitude,
                    _pickupLatLng.longitude > _destLatLng.longitude ? _pickupLatLng.longitude : _destLatLng.longitude,
                  ),
                ),
                80,
              ));
            });
          },
          markers: {
            Marker(markerId: const MarkerId('pickup'), position: _pickupLatLng,
              infoWindow: InfoWindow(title: 'Pickup', snippet: widget.pickup)),
            Marker(markerId: const MarkerId('dest'), position: _destLatLng,
              infoWindow: InfoWindow(title: 'Drop', snippet: widget.destination),
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue)),
          },
          polylines: {
            Polyline(polylineId: const PolylineId('route'),
              points: [_pickupLatLng, _destLatLng],
              color: _blue, width: 4,
              patterns: [PatternItem.dash(20), PatternItem.gap(10)]),
          },
          zoomControlsEnabled: false, mapToolbarEnabled: false,
        ),
        // Back button
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 12, offset: const Offset(0, 4))],
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0F172A), size: 18),
              ),
            ),
          ),
        ),
        // Bottom panel
        Positioned(
          bottom: 0, left: 0, right: 0,
          child: Container(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.72),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 24, offset: Offset(0, -4))],
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(top: 8, bottom: 16),
                  decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(2)))),

                // Ride header
                Row(children: [
                  Container(
                    width: 52, height: 52,
                    decoration: BoxDecoration(
                      color: _blue.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(_iconForVehicle(_vehicleName), color: _blue, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(_vehicleName,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Color(0xFF0F172A))),
                    Text('${_distanceKm.toStringAsFixed(1)} km • Est. ${_fare?['estimatedTime'] ?? '~5 min'}',
                      style: TextStyle(fontSize: 13, color: Colors.grey[500], fontWeight: FontWeight.w500)),
                  ])),
                  if (_estimating)
                    const SizedBox(width: 24, height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: _blue))
                  else
                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Text(_fare != null ? '₹${_finalFare.toStringAsFixed(0)}' : '--',
                        style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                      if (_promoDiscount > 0)
                        Text('₹${(_fare?['estimatedFare'] ?? 0).toStringAsFixed(0)} saved ₹${_promoDiscount.toInt()}',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF16A34A), fontWeight: FontWeight.w600)),
                    ]),
                ]),
                const SizedBox(height: 16),

                // Addresses
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFF),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE8EFFF)),
                  ),
                  child: Column(children: [
                    _addressRow(Icons.radio_button_checked_rounded, _blue, widget.pickup),
                    Padding(
                      padding: const EdgeInsets.only(left: 28),
                      child: Divider(height: 1, color: Colors.grey[200]),
                    ),
                    _addressRow(Icons.location_on_rounded, const Color(0xFFE53935), widget.destination),
                  ]),
                ),
                const SizedBox(height: 14),

                // Night charge
                _buildNightChargeIndicator(),

                // Fare breakdown
                if (_fare != null) ...[
                  _buildFareBreakdown(_fare!),
                  const SizedBox(height: 14),
                ],

                // Promo
                _buildPromoRow(),
                const SizedBox(height: 14),

                // Book for someone else
                _buildBookForSomeoneSection(),
                const SizedBox(height: 14),

                // Payment selection
                _buildPaymentSection(),
                const SizedBox(height: 16),

                // Confirm button
                SizedBox(
                  width: double.infinity, height: 56,
                  child: ElevatedButton(
                    onPressed: _loading || _estimating ? null : _handleOnConfirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _blue, foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey[200],
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: _loading
                      ? const SizedBox(width: 24, height: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                      : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Text(
                            _paymentMethod == 'upi' ? 'PAY ₹${_finalFare.toStringAsFixed(0)} & BOOK' : 'CONFIRM BOOKING',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_rounded, size: 18),
                        ]),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ]),
    );
  }

  bool get _isParcel {
    final n = _vehicleName.toLowerCase();
    return n.contains('parcel') || n.contains('cargo') || n.contains('delivery');
  }

  Widget _buildBookForSomeoneSection() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      GestureDetector(
        onTap: () => setState(() { _bookForSomeone = !_bookForSomeone; }),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: _bookForSomeone ? _blue.withOpacity(0.06) : const Color(0xFFF8FAFF),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _bookForSomeone ? _blue.withOpacity(0.3) : const Color(0xFFE8EFFF)),
          ),
          child: Row(children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: _bookForSomeone ? _blue.withOpacity(0.12) : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.person_add_rounded,
                color: _bookForSomeone ? _blue : Colors.grey.shade500, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_isParcel ? 'Book Parcel for Someone' : 'Book for Someone Else',
                style: TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 14,
                  color: _bookForSomeone ? _blue : const Color(0xFF0F172A))),
              const SizedBox(height: 2),
              Text(_isParcel ? 'Set sender & receiver details' : 'Enter passenger contact details',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
            ])),
            Switch(
              value: _bookForSomeone,
              onChanged: (v) => setState(() => _bookForSomeone = v),
              activeColor: _blue,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ]),
        ),
      ),
      if (_bookForSomeone) ...[
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _blue.withOpacity(0.04),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _blue.withOpacity(0.12)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_isParcel ? 'Sender Details' : 'Passenger Details',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                color: Color(0xFF374151), letterSpacing: 0.5)),
            const SizedBox(height: 10),
            _bookingInputField(
              controller: _passengerNameCtrl,
              hint: _isParcel ? 'Sender name' : 'Passenger name',
              icon: Icons.person_outline_rounded,
              keyboardType: TextInputType.name,
            ),
            const SizedBox(height: 8),
            _bookingInputField(
              controller: _passengerPhoneCtrl,
              hint: _isParcel ? 'Sender phone' : 'Passenger phone',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
            ),
            if (_isParcel) ...[
              const SizedBox(height: 14),
              const Text('Receiver Details',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                  color: Color(0xFF374151), letterSpacing: 0.5)),
              const SizedBox(height: 10),
              _bookingInputField(
                controller: _receiverNameCtrl,
                hint: 'Receiver name',
                icon: Icons.person_pin_outlined,
                keyboardType: TextInputType.name,
              ),
              const SizedBox(height: 8),
              _bookingInputField(
                controller: _receiverPhoneCtrl,
                hint: 'Receiver phone (for delivery OTP)',
                icon: Icons.phone_forwarded_outlined,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: const Row(children: [
                  Icon(Icons.info_outline_rounded, color: Colors.amber, size: 14),
                  SizedBox(width: 6),
                  Expanded(child: Text(
                    'Delivery OTP will be sent to receiver\'s phone when package is picked up.',
                    style: TextStyle(fontSize: 11, color: Color(0xFF92400E)),
                  )),
                ]),
              ),
            ],
          ]),
        ),
      ],
    ]);
  }

  Widget _bookingInputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE8EFFF)),
      ),
      child: Row(children: [
        Padding(
          padding: const EdgeInsets.only(left: 10),
          child: Icon(icon, size: 18, color: Colors.grey.shade400),
        ),
        Expanded(
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A)),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildPaymentSection() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Payment Method',
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF374151), letterSpacing: 0.2)),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: _payBtn('cash', Icons.payments_rounded, 'Cash', null)),
        const SizedBox(width: 8),
        Expanded(child: _payBtn('wallet', Icons.account_balance_wallet_rounded, 'Wallet',
          _walletBalance > 0 ? '₹${_walletBalance.toStringAsFixed(0)}' : '₹0')),
        const SizedBox(width: 8),
        Expanded(child: _payBtn('upi', Icons.qr_code_scanner_rounded, 'UPI', 'Razorpay')),
      ]),
      if (_paymentMethod == 'wallet') ...[
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: _walletBalance >= _finalFare
              ? const Color(0xFFF0FDF4)
              : const Color(0xFFFEF2F2),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _walletBalance >= _finalFare
                ? const Color(0xFF86EFAC)
                : const Color(0xFFFCA5A5)),
          ),
          child: Row(children: [
            Icon(
              _walletBalance >= _finalFare ? Icons.check_circle_rounded : Icons.warning_rounded,
              color: _walletBalance >= _finalFare ? _green : const Color(0xFFDC2626),
              size: 16,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(
              _walletBalance >= _finalFare
                ? 'Wallet balance ₹${_walletBalance.toStringAsFixed(0)} • Sufficient'
                : 'Insufficient balance (₹${_walletBalance.toStringAsFixed(0)}). Please recharge.',
              style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600,
                color: _walletBalance >= _finalFare ? _green : const Color(0xFFDC2626),
              ),
            )),
          ]),
        ),
      ],
      if (_paymentMethod == 'upi') ...[
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F7FF),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _blue.withOpacity(0.2)),
          ),
          child: Row(children: [
            const Icon(Icons.lock_rounded, color: _blue, size: 15),
            const SizedBox(width: 8),
            const Expanded(child: Text(
              'Secure payment via Razorpay — UPI, Cards, Netbanking accepted',
              style: TextStyle(fontSize: 12, color: Color(0xFF1E6DE5), fontWeight: FontWeight.w500),
            )),
          ]),
        ),
      ],
    ]);
  }

  Widget _payBtn(String method, IconData icon, String label, String? subtitle) {
    final selected = _paymentMethod == method;
    return GestureDetector(
      onTap: () => setState(() => _paymentMethod = method),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: selected ? _blue : const Color(0xFFF8FAFF),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? _blue : const Color(0xFFE2E8F0),
            width: selected ? 2 : 1,
          ),
          boxShadow: selected ? [BoxShadow(color: _blue.withOpacity(0.25), blurRadius: 12, offset: const Offset(0, 4))] : [],
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 22, color: selected ? Colors.white : Colors.grey[500]),
          const SizedBox(height: 5),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
            color: selected ? Colors.white : const Color(0xFF374151))),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(subtitle, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500,
              color: selected ? Colors.white.withOpacity(0.75) : Colors.grey[400]),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ]),
      ),
    );
  }

  Widget _addressRow(IconData icon, Color color, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      child: Row(children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 12),
        Expanded(child: Text(text,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
          maxLines: 1, overflow: TextOverflow.ellipsis)),
      ]),
    );
  }

  bool _isNightTime() {
    final hour = DateTime.now().hour;
    return hour >= 22 || hour < 6;
  }

  Widget _buildNightChargeIndicator() {
    if (!_isNightTime()) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF0D1B2A), borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF1E3A5F))),
        child: Row(children: [
          const Text('🌙', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          const Expanded(child: Text('Night charges apply (10PM - 6AM)',
            style: TextStyle(color: Color(0xFF93C5FD), fontSize: 13, fontWeight: FontWeight.w600))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: const Color(0xFF1E3A5F), borderRadius: BorderRadius.circular(8)),
            child: const Text('1.25x', style: TextStyle(color: Color(0xFFFFD700), fontSize: 12, fontWeight: FontWeight.w800)),
          ),
        ]),
      ),
    );
  }

  Widget _buildFareBreakdown(Map<String, dynamic> fare) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8EFFF)),
      ),
      child: Column(children: [
        Row(children: [
          const Icon(Icons.receipt_long_rounded, size: 15, color: Color(0xFF6B7280)),
          const SizedBox(width: 6),
          const Text('Fare Breakdown', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF374151))),
          const Spacer(),
          Text('Incl. GST', style: TextStyle(fontSize: 10, color: Colors.grey[400])),
        ]),
        const SizedBox(height: 10),
        _fareRow('Base Fare', '₹${fare['baseFare'] ?? 0}'),
        _fareRow('Distance (${_distanceKm.toStringAsFixed(1)} km)', '₹${fare['distanceFare'] ?? 0}'),
        if ((fare['helperCharge'] ?? 0) > 0)
          _fareRow('Helper Charge', '₹${fare['helperCharge']}'),
        _fareRow('GST (5%)', '₹${fare['gst'] ?? 0}'),
        if (_promoDiscount > 0)
          _fareRow('Promo Discount', '-₹${_promoDiscount.toInt()}', positive: true),
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(children: [
            const Text('Total', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
            const Spacer(),
            Text('₹${_finalFare.toStringAsFixed(0)}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1E6DE5))),
          ]),
        ),
      ]),
    );
  }

  Widget _fareRow(String label, String value, {bool bold = false, bool positive = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        const Spacer(),
        Text(value, style: TextStyle(fontSize: 12,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
          color: positive ? _green : (bold ? _dark : Colors.grey[800]))),
      ]),
    );
  }

  Widget _buildPromoRow() {
    if (_appliedPromo != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF0FDF4), borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF86EFAC))),
        child: Row(children: [
          const Icon(Icons.local_offer_rounded, color: Color(0xFF16A34A), size: 18),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('$_appliedPromo applied!',
              style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF16A34A), fontSize: 13)),
            Text('You save ₹${_promoDiscount.toInt()}',
              style: TextStyle(color: Colors.green[700], fontSize: 12)),
          ])),
          GestureDetector(
            onTap: () => setState(() { _appliedPromo = null; _promoDiscount = 0; _promoCtrl.clear(); }),
            child: const Icon(Icons.close_rounded, color: Color(0xFF16A34A), size: 20)),
        ]),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFF), borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(children: [
        Row(children: [
          const Icon(Icons.local_offer_outlined, color: _blue, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _promoCtrl,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                hintText: 'Promo code',
                border: InputBorder.none, isDense: true,
                hintStyle: TextStyle(fontSize: 13, color: Color(0xFFADB5BD))),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 1.5),
            ),
          ),
          GestureDetector(
            onTap: _promoLoading ? null : _applyPromo,
            child: _promoLoading
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: _blue))
              : const Text('APPLY', style: TextStyle(color: _blue, fontSize: 13, fontWeight: FontWeight.w800)),
          ),
        ]),
        if (_promoError != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8, left: 28),
            child: Text(_promoError!, style: const TextStyle(color: Color(0xFFDC2626), fontSize: 11))),
      ]),
    );
  }
}
