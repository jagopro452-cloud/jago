import 'dart:convert';
import 'dart:math';
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
  List<Map<String, dynamic>> _allFares = [];
  int _selectedFareIndex = 0;
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

  static const Color _jagoOrange = Color(0xFFFF6B35);
  static const Color _jagoNavy = Color(0xFF060D1E);
  static const Color _jagoGold = Color(0xFFFFD700);

  static const Color _blue = _jagoOrange;
  static const Color _dark = _jagoNavy;
  static const Color _green = Color(0xFF16A34A);

  LatLng get _pickupLatLng => LatLng(widget.pickupLat, widget.pickupLng);
  LatLng get _destLatLng => widget.destLat != 0 && widget.destLng != 0
    ? LatLng(widget.destLat, widget.destLng)
    : LatLng(widget.pickupLat + 0.02, widget.pickupLng + 0.02);

  Map<String, dynamic>? get _fare => _allFares.isNotEmpty ? _allFares[_selectedFareIndex] : null;

  String get _vehicleName => _fare?['vehicleCategoryName']?.toString() ?? _fare?['name']?.toString() ?? widget.vehicleCategoryName ?? 'Bike';

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
    // Haversine formula for accurate distance calculation
    const double earthRadius = 6371.0;
    final double lat1 = widget.pickupLat * pi / 180;
    final double lat2 = widget.destLat * pi / 180;
    final double dlat = (widget.destLat - widget.pickupLat) * pi / 180;
    final double dlng = (widget.destLng - widget.pickupLng) * pi / 180;
    final double a = sin(dlat / 2) * sin(dlat / 2) +
        cos(lat1) * cos(lat2) * sin(dlng / 2) * sin(dlng / 2);
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    // Road distance is typically 1.3x aerial distance
    return (earthRadius * c * 1.3).clamp(0.5, 200.0);
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
          setState(() {
            _allFares = fares.cast<Map<String, dynamic>>();
            if (widget.vehicleCategoryId != null) {
              final idx = _allFares.indexWhere((f) =>
                f['vehicleCategoryId']?.toString() == widget.vehicleCategoryId ||
                f['id']?.toString() == widget.vehicleCategoryId);
              if (idx >= 0) _selectedFareIndex = idx;
            }
          });
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
      final vcId = _fare?['vehicleCategoryId']?.toString() ?? _fare?['id']?.toString() ?? widget.vehicleCategoryId;
      if (vcId != null && vcId.isNotEmpty) body['vehicleCategoryId'] = vcId;
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
        'theme': {'color': '#FF6B35'},
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final panelBg = isDark ? const Color(0xFF060D1E) : Colors.white;
    final cardBg = isDark ? const Color(0xFF0D1B3E) : const Color(0xFFF8FAFF);
    final textMain = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSub = isDark ? Colors.white54 : Colors.grey.shade600;
    final borderCol = isDark ? Colors.white12 : const Color(0xFFE8EFFF);
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF060D1E) : Colors.white,
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
            decoration: BoxDecoration(
              color: panelBg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.5 : 0.12), blurRadius: 24, offset: const Offset(0, -4))],
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(top: 8, bottom: 16),
                  decoration: BoxDecoration(color: isDark ? Colors.white12 : Colors.grey[200], borderRadius: BorderRadius.circular(2)))),

                // Vehicle selector
                _buildVehicleSelector(),
                const SizedBox(height: 16),

                // Addresses
                Container(
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderCol),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        left: 23,
                        top: 35,
                        bottom: 35,
                        child: CustomPaint(
                          size: const Size(1, double.infinity),
                          painter: DashedLinePainter(color: isDark ? Colors.white24 : Colors.grey.shade300),
                        ),
                      ),
                      Column(children: [
                        _addressRow(Icons.circle, const Color(0xFF16A34A), widget.pickup, textMain),
                        Padding(
                          padding: const EdgeInsets.only(left: 48),
                          child: Divider(height: 1, color: isDark ? Colors.white10 : Colors.grey[100]),
                        ),
                        _addressRow(Icons.location_on_rounded, const Color(0xFFE53935), widget.destination, textMain),
                      ]),
                    ],
                  ),
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
                Container(
                  width: double.infinity, height: 56,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_jagoOrange, Color(0xFFFF8C5A)],
                      begin: Alignment.centerLeft, end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: _jagoOrange.withOpacity(0.3),
                        blurRadius: 12, offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _loading || _estimating ? null : _handleOnConfirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent, foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey[200],
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0, shadowColor: Colors.transparent,
                    ),
                    child: _loading
                      ? const SizedBox(width: 24, height: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                      : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Text(
                            _paymentMethod == 'upi' ? 'PAY ₹${_finalFare.toStringAsFixed(0)} & BOOK' : 'BOOK NOW',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 0.8)),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_rounded, size: 20),
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

  Widget _addressRow(IconData icon, Color color, String text, [Color? textColor]) {
    final tColor = textColor ?? const Color(0xFF0F172A);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      child: Row(children: [
        Icon(icon, color: color, size: icon == Icons.circle ? 10 : 20),
        const SizedBox(width: 14),
        Expanded(child: Text(text,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: tColor),
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

  String? _getVehicleTag(int index) {
    if (_allFares.length < 2) return null;
    int fastestIdx = 0, saverIdx = 0, premiumIdx = 0;
    for (int j = 0; j < _allFares.length; j++) {
      final f = _allFares[j];
      final fare = (f['estimatedFare'] ?? 0).toDouble();
      final bestFare = (_allFares[saverIdx]['estimatedFare'] ?? 0).toDouble();
      final highFare = (_allFares[premiumIdx]['estimatedFare'] ?? 0).toDouble();
      if (fare < bestFare) saverIdx = j;
      if (fare > highFare) premiumIdx = j;
      final timeStr = f['estimatedTime']?.toString() ?? '99 min';
      final timeNum = int.tryParse(timeStr.replaceAll(RegExp(r'[^0-9]'), '')) ?? 99;
      final bestTimeStr = _allFares[fastestIdx]['estimatedTime']?.toString() ?? '99 min';
      final bestTimeNum = int.tryParse(bestTimeStr.replaceAll(RegExp(r'[^0-9]'), '')) ?? 99;
      if (timeNum < bestTimeNum) fastestIdx = j;
    }
    if (index == fastestIdx) return 'FASTEST';
    if (index == saverIdx && index != fastestIdx) return 'SAVER';
    if (index == premiumIdx && index != fastestIdx && _allFares.length >= 3) return 'PREMIUM';
    return null;
  }

  Widget _vehicleTagBadge(String tag) {
    Color color;
    IconData icon;
    switch (tag) {
      case 'FASTEST':
        color = const Color(0xFF3B82F6);
        icon = Icons.bolt_rounded;
        break;
      case 'SAVER':
        color = const Color(0xFF10B981);
        icon = Icons.savings_rounded;
        break;
      case 'PREMIUM':
        color = const Color(0xFFFFD700);
        icon = Icons.star_rounded;
        break;
      default:
        return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.35), width: 1),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: color, size: 10),
        const SizedBox(width: 3),
        Text(tag, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
      ]),
    );
  }

  Widget _buildVehicleSelector() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF0D1B3E) : const Color(0xFFF8FAFF);
    final textMain = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSub = isDark ? Colors.white54 : Colors.grey.shade600;
    final borderCol = isDark ? Colors.white12 : const Color(0xFFE8EFFF);
    if (_estimating) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          CircularProgressIndicator(strokeWidth: 2.5, color: _jagoOrange),
          SizedBox(height: 12),
          Text('Getting best fares...', style: TextStyle(color: Color(0xFF6B7280), fontSize: 13, fontWeight: FontWeight.w500)),
        ])));
    }
    if (_allFares.isEmpty) {
      return Row(children: [
        Container(width: 52, height: 52,
          decoration: BoxDecoration(color: _jagoOrange.withOpacity(0.08), borderRadius: BorderRadius.circular(16)),
          child: Icon(_iconForVehicle(_vehicleName), color: _jagoOrange, size: 26)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_vehicleName, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: textMain)),
          Text('${_distanceKm.toStringAsFixed(1)} km • Est. ~5 min',
            style: TextStyle(fontSize: 13, color: textSub, fontWeight: FontWeight.w500)),
        ])),
        Text('--', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: textMain)),
      ]);
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text('Choose Your Ride',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: textMain, letterSpacing: -0.3)),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _jagoOrange.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _jagoOrange.withOpacity(0.25))),
          child: Text('${_allFares.length} options',
            style: const TextStyle(color: _jagoOrange, fontSize: 11, fontWeight: FontWeight.w800)),
        ),
      ]),
      const SizedBox(height: 10),
      ..._allFares.asMap().entries.map((entry) {
        final i = entry.key;
        final f = entry.value;
        final isSelected = i == _selectedFareIndex;
        final name = f['vehicleCategoryName']?.toString() ?? f['name']?.toString() ?? 'Vehicle';
        final fareVal = (f['estimatedFare'] ?? 0).toDouble();
        final time = f['estimatedTime']?.toString() ?? '~5 min';
        final displayFare = isSelected ? (fareVal - _promoDiscount).clamp(0.0, double.infinity) : fareVal;
        final tag = _getVehicleTag(i);
        return GestureDetector(
          key: ValueKey(i),
          onTap: () => setState(() => _selectedFareIndex = i),
          child: Stack(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isSelected ? _jagoOrange.withOpacity(0.08) : cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? _jagoOrange : borderCol,
                    width: isSelected ? 2 : 1),
                  boxShadow: isSelected ? [
                    BoxShadow(color: _jagoOrange.withOpacity(0.2), blurRadius: 16, offset: const Offset(0, 4))
                  ] : [],
                ),
                child: Row(children: [
                  Container(
                    width: 52, height: 52,
                    decoration: BoxDecoration(
                      color: isSelected ? _jagoOrange.withOpacity(0.12) : (isDark ? Colors.white10 : Colors.grey.shade100),
                      borderRadius: BorderRadius.circular(14)),
                    child: Icon(_iconForVehicle(name),
                      color: isSelected ? _jagoOrange : textSub, size: 26)),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Flexible(child: Text(name, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15,
                        color: isSelected ? _jagoOrange : textMain), overflow: TextOverflow.ellipsis)),
                      if (tag != null) ...[
                        const SizedBox(width: 8),
                        _vehicleTagBadge(tag),
                      ],
                    ]),
                    const SizedBox(height: 5),
                    Row(children: [
                      Icon(Icons.route_rounded, size: 11, color: Colors.grey[400]),
                      const SizedBox(width: 3),
                      Text('${_distanceKm.toStringAsFixed(1)} km',
                        style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                      const SizedBox(width: 8),
                      Icon(Icons.access_time_rounded, size: 11, color: Colors.grey[400]),
                      const SizedBox(width: 3),
                      Text(time, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                    ]),
                  ])),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text('₹${displayFare.toStringAsFixed(0)}',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900,
                        color: isSelected ? _jagoOrange : textMain)),
                    if (isSelected && _promoDiscount > 0)
                      Text('saved ₹${_promoDiscount.toInt()}',
                        style: const TextStyle(fontSize: 10, color: Color(0xFF16A34A), fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(time, style: TextStyle(fontSize: 11, color: textSub)),
                  ]),
                  const SizedBox(width: 28),
                ]),
              ),
              if (isSelected)
                Positioned(
                  top: 0, right: 0,
                  child: Container(
                    width: 28, height: 28,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_jagoOrange, Color(0xFFFF8C5A)],
                        begin: Alignment.topLeft, end: Alignment.bottomRight),
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: Color(0x50FF6B35), blurRadius: 8, offset: Offset(0, 2))],
                    ),
                    child: const Icon(Icons.check_rounded, color: Colors.white, size: 17)),
                ),
            ],
          ),
        );
      }).toList(),
    ]);
  }

  Widget _buildFareBreakdown(Map<String, dynamic> fare) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF0D1B3E) : const Color(0xFFF8FAFF);
    final borderCol = isDark ? Colors.white12 : const Color(0xFFE8EFFF);
    final textMain = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSub = isDark ? Colors.white54 : Colors.grey.shade600;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderCol),
      ),
      child: Column(children: [
        Row(children: [
          Icon(Icons.receipt_long_rounded, size: 15, color: textSub),
          const SizedBox(width: 6),
          Text('Fare Breakdown', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: textSub)),
          const Spacer(),
          Text('Incl. GST', style: TextStyle(fontSize: 10, color: Colors.grey[400])),
        ]),
        const SizedBox(height: 10),
        _fareRow('Base Fare', '₹${fare['baseFare'] ?? 0}', textSub: textSub),
        _fareRow('Distance (${_distanceKm.toStringAsFixed(1)} km)', '₹${fare['distanceFare'] ?? 0}', textSub: textSub),
        if ((fare['helperCharge'] ?? 0) > 0)
          _fareRow('Helper Charge', '₹${fare['helperCharge']}', textSub: textSub),
        _fareRow('GST (5%)', '₹${fare['gst'] ?? 0}', textSub: textSub),
        if (_promoDiscount > 0)
          _fareRow('Promo Discount', '-₹${_promoDiscount.toInt()}', positive: true, textSub: textSub),
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(children: [
            Text('Total', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: textMain)),
            const Spacer(),
            Text('₹${_finalFare.toStringAsFixed(0)}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: _jagoOrange)),
          ]),
        ),
      ]),
    );
  }

  Widget _fareRow(String label, String value, {bool bold = false, bool positive = false, Color? textSub}) {
    final sub = textSub ?? Colors.grey.shade600;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(children: [
        Text(label, style: TextStyle(fontSize: 12, color: sub)),
        const Spacer(),
        Text(value, style: TextStyle(fontSize: 12,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
          color: positive ? _green : sub)),
      ]),
    );
  }

  Widget _buildPromoRow() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF0D1B3E) : const Color(0xFFF8FAFF);
    final borderCol = isDark ? Colors.white12 : const Color(0xFFE2E8F0);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    if (_appliedPromo != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF052e16) : const Color(0xFFF0FDF4),
          borderRadius: BorderRadius.circular(12),
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
        color: cardBg, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderCol)),
      child: Column(children: [
        Row(children: [
          const Icon(Icons.local_offer_outlined, color: _jagoOrange, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _promoCtrl,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                hintText: 'Promo code',
                border: InputBorder.none, isDense: true,
                hintStyle: TextStyle(fontSize: 13, color: isDark ? Colors.white38 : const Color(0xFFADB5BD))),
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 1.5, color: textColor),
            ),
          ),
          GestureDetector(
            onTap: _promoLoading ? null : _applyPromo,
            child: _promoLoading
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: _jagoOrange))
              : const Text('APPLY', style: TextStyle(color: _jagoOrange, fontSize: 13, fontWeight: FontWeight.w800)),
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

class DashedLinePainter extends CustomPainter {
  final Color color;
  const DashedLinePainter({required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    double dashHeight = 5, dashSpace = 3, startY = 0;
    final paint = Paint()..color = color..strokeWidth = 1;
    while (startY < size.height) {
      canvas.drawLine(Offset(0, startY), Offset(0, startY + dashHeight), paint);
      startY += dashHeight + dashSpace;
    }
  }
  @override
  bool shouldRepaint(DashedLinePainter oldDelegate) => oldDelegate.color != color;
}
