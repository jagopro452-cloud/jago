import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
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
  final TextEditingController _promoCtrl = TextEditingController();
  String? _appliedPromo;
  double _promoDiscount = 0;
  bool _promoLoading = false;
  String? _promoError;

  late Razorpay _razorpay;

  // Book for someone else
  bool _bookForSomeone = false;
  final _passengerNameCtrl = TextEditingController();
  final _passengerPhoneCtrl = TextEditingController();
  final _receiverNameCtrl = TextEditingController();
  final _receiverPhoneCtrl = TextEditingController();

  static const Color _jagoPrimary = Color(0xFF2F80ED);
  static const Color _jagoSecondary = Color(0xFF56CCF2);

  static const Color _blue = _jagoPrimary;
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

  static String _emojiForVehicle(String name) {
    final n = name.toLowerCase();
    if (n.contains('bike parcel') || n.contains('parcel bike')) return '🛵';
    if (n.contains('bike')) return '🏍️';
    if (n.contains('auto')) return '🛺';
    if (n.contains('cargo truck')) return '🚛';
    if (n.contains('cargo') || n.contains('tata ace')) return '🚐';
    if (n.contains('parcel')) return '🛵';
    if (n.contains('suv')) return '🚙';
    if (n.contains('car')) return '🚗';
    return '🚗';
  }

  static Color _accentForVehicle(String name) {
    final n = name.toLowerCase();
    if (n.contains('bike')) return const Color(0xFF2F80ED);
    if (n.contains('auto')) return const Color(0xFF059669);
    if (n.contains('cargo') || n.contains('truck')) return const Color(0xFF7C3AED);
    if (n.contains('parcel')) return const Color(0xFFF59E0B);
    if (n.contains('suv')) return const Color(0xFF0EA5E9);
    if (n.contains('car')) return const Color(0xFF2563EB);
    return const Color(0xFF2F80ED);
  }

  Widget _buildVehicleHero() {
    if (_allFares.isEmpty) return const SizedBox.shrink();
    final fare = _allFares[_selectedFareIndex];
    final name = fare['vehicleCategoryName']?.toString() ?? fare['name']?.toString() ?? 'Bike';
    final emoji = _emojiForVehicle(name);
    final accent = _accentForVehicle(name);
    final fareVal = (fare['estimatedFare'] ?? 0).toDouble();
    final rawMin = (fare['fareMin'] ?? (fareVal * 0.95)).toDouble();
    final rawMax = (fare['fareMax'] ?? (fareVal * 1.05)).toDouble();
    final displayMin = (rawMin - _promoDiscount).clamp(0.0, double.infinity);
    final displayMax = (rawMax - _promoDiscount).clamp(0.0, double.infinity);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 320),
      transitionBuilder: (child, anim) => SlideTransition(
        position: Tween<Offset>(begin: const Offset(0.3, 0), end: Offset.zero).animate(
          CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
        child: FadeTransition(opacity: anim, child: child),
      ),
      child: Container(
        key: ValueKey('hero_$name'),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [accent, accent.withValues(alpha: 0.75)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: accent.withValues(alpha: 0.35), blurRadius: 18, offset: const Offset(0, 6)),
          ],
        ),
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8)),
              child: Text('SELECTED', style: const TextStyle(
                color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
            ),
            const SizedBox(height: 8),
            Text(name, style: const TextStyle(
              color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
            const SizedBox(height: 4),
            Text('₹${displayMin.floor()} – ₹${displayMax.ceil()}',
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
            Text('estimated fare', style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 11)),
          ])),
          Text(emoji, style: const TextStyle(fontSize: 72)),
        ]),
      ),
    );
  }

  static String _capacityForVehicle(String name) {
    final n = name.toLowerCase();
    if (n.contains('suv')) return '6 seats';
    if (n.contains('car')) return '4 seats';
    if (n.contains('auto')) return '3 seats';
    if (n.contains('bike')) return '1 rider';
    if (n.contains('cargo truck')) return 'Up to 1000 kg';
    if (n.contains('cargo') || n.contains('tata ace')) return 'Up to 500 kg';
    if (n.contains('parcel')) return 'Package delivery';
    return '';
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
    _passengerNameCtrl.dispose();
    _passengerPhoneCtrl.dispose();
    _receiverNameCtrl.dispose();
    _receiverPhoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchWallet() async {
    try {
      final headers = await AuthService.getHeaders();
      final res = await http.get(Uri.parse(ApiConfig.wallet),
        headers: headers);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (mounted) setState(() => _walletBalance = (data['balance'] ?? 0).toDouble());
      }
    } catch (_) {}
  }

  Future<void> _applyPromo() async {
    final code = _promoCtrl.text.trim().toUpperCase();
    if (code.isEmpty) return;
    setState(() { _promoLoading = true; _promoError = null; });
    try {
      final headers = await AuthService.getHeaders();
      final res = await http.post(Uri.parse(ApiConfig.applyCoupon),
        headers: headers,
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
    try {
      final headers = await AuthService.getHeaders();
      final body = <String, dynamic>{
        'pickupLat': widget.pickupLat, 'pickupLng': widget.pickupLng,
        'destLat': widget.destLat, 'destLng': widget.destLng,
        'distanceKm': _distanceKm,
      };
      if (widget.vehicleCategoryId != null) body['vehicleCategoryId'] = widget.vehicleCategoryId;
      final res = await http.post(Uri.parse(ApiConfig.estimateFare),
        headers: headers,
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
        } else {
          // Server returned no fares — compute client-side estimates so the UI always shows a price
          if (mounted) setState(() => _allFares = _buildFallbackFares());
        }
      }
    } catch (_) {
      // Network error — show client-side estimates
      if (mounted) setState(() => _allFares = _buildFallbackFares());
    }
    if (mounted) setState(() => _estimating = false);
  }

  /// Builds client-side fare estimates (Bike/Auto/Car) when the server returns
  /// no fares. Formula: Total = Base + (Distance × Per-KM Rate) + 5% GST.
  List<Map<String, dynamic>> _buildFallbackFares() {
    final dist = _distanceKm;
    Map<String, dynamic> make(
        String name, double base, double perKm, double minFareVal, int eta) {
      final raw = (base + dist * perKm).clamp(minFareVal, double.infinity);
      final gst = double.parse((raw * 0.05).toStringAsFixed(2));
      final grandTotal = double.parse((raw + gst).toStringAsFixed(2));
      return {
        'vehicleCategoryId': null,
        'vehicleCategoryName': name,
        'vehicleName': name,
        'baseFare': base,
        'farePerKm': perKm,
        'billableKm': dist,
        'distanceFare': double.parse((dist * perKm).toStringAsFixed(2)),
        'timeFare': 0.0,
        'subtotal': double.parse(raw.toStringAsFixed(2)),
        'gst': gst,
        'estimatedFare': grandTotal,
        'fareMin': (grandTotal * 0.95).floor(),
        'fareMax': (grandTotal * 1.05).ceil(),
        'minimumFare': minFareVal,
        'cancellationFee': 10.0,
        'waitingChargePerMin': 0.0,
        'isNightCharge': false,
        'nightMultiplier': 1.0,
        'helperCharge': 0.0,
        'estimatedTime': '$eta min',
      };
    }
    return [
      make('Bike', 25, 10, 28, (dist * 3).ceil()),
      make('Auto', 35, 13, 40, (dist * 3.5).ceil()),
      make('Car',  50, 16, 60, (dist * 4).ceil()),
    ];
  }

  Future<void> _confirmBooking({String? razorpayPaymentId}) async {
    setState(() => _loading = true);
    try {
      final headers = await AuthService.getHeaders();
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
        headers: headers,
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

  /// Offers Google Maps navigation to pickup location after booking is confirmed.
  /// Shows a premium bottom sheet with "Navigate" and "Skip" options.
  Future<void> _offerNavigateToPickup() async {
    if (!mounted) return;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pickupLat = widget.pickupLat;
    final pickupLng = widget.pickupLng;
    final pickupAddr = widget.pickup;

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      builder: (_) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 30)],
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF16A34A), Color(0xFF15803D)]),
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: const Color(0xFF16A34A).withValues(alpha: 0.35), blurRadius: 16)],
            ),
            child: const Icon(Icons.check_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 16),
          Text('Ride Booked! 🎉',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : const Color(0xFF111827))),
          const SizedBox(height: 8),
          Text('Navigate to pickup location?',
            style: TextStyle(fontSize: 14, color: isDark ? Colors.white70 : Colors.grey[600])),
          const SizedBox(height: 6),
          Text(pickupAddr,
            style: const TextStyle(fontSize: 13, color: Color(0xFF2F80ED), fontWeight: FontWeight.w600),
            maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white10 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
                  ),
                  child: Center(child: Text('Skip',
                    style: TextStyle(fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white70 : Colors.grey[700]))),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: GestureDetector(
                onTap: () async {
                  Navigator.pop(context);
                  // Try Google Maps first, fallback to geo: URI
                  final gmUrl = 'google.navigation:q=$pickupLat,$pickupLng&mode=d';
                  final geoUrl = 'geo:$pickupLat,$pickupLng?q=$pickupLat,$pickupLng($pickupAddr)';
                  final mapsUrl = 'https://maps.google.com/?daddr=$pickupLat,$pickupLng&directionsmode=driving';
                  if (await canLaunchUrl(Uri.parse(gmUrl))) {
                    await launchUrl(Uri.parse(gmUrl));
                  } else if (await canLaunchUrl(Uri.parse(geoUrl))) {
                    await launchUrl(Uri.parse(geoUrl));
                  } else {
                    await launchUrl(Uri.parse(mapsUrl), mode: LaunchMode.externalApplication);
                  }
                },
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF2F80ED), Color(0xFF1244A2)]),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [BoxShadow(color: const Color(0xFF2F80ED).withValues(alpha: 0.35), blurRadius: 12)],
                  ),
                  child: const Center(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.navigation_rounded, color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    Text('Navigate Now', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14)),
                  ])),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 8),
        ]),
      ),
    );
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
    try {
      final headers = await AuthService.getHeaders();
      final fare = _finalFare;
      final res = await http.post(Uri.parse(ApiConfig.rideCreateOrder),
        headers: headers,
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
      if (order == null || keyId == null) {
        setState(() => _loading = false);
        _showSnack('Payment setup failed. Try again.', error: true);
        return;
      }
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
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final headers = await AuthService.getHeaders();
      final verifyRes = await http.post(Uri.parse(ApiConfig.rideVerifyPayment),
        headers: headers,
        body: jsonEncode({
          'razorpayOrderId': response.orderId,
          'razorpayPaymentId': response.paymentId,
          'razorpaySignature': response.signature,
          'amount': _finalFare,
        }));
      if (verifyRes.statusCode == 200) {
        await _confirmBooking(razorpayPaymentId: response.paymentId);
      } else {
        if (!mounted) return;
        setState(() => _loading = false);
        _showSnack('Payment verification failed. Contact support.', error: true);
      }
    } catch (_) {
      if (!mounted) return;
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
    final panelBg = isDark ? const Color(0xFF0F172A) : Colors.white;
    final cardBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFF);
    final textMain = isDark ? Colors.white : const Color(0xFF0F172A);
    final borderCol = isDark ? Colors.white12 : const Color(0xFFE8EFFF);
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
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
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 12, offset: const Offset(0, 4))],
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
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.12), blurRadius: 24, offset: const Offset(0, -4))],
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
                      colors: [_jagoPrimary, Color(0xFF56CCF2)],
                      begin: Alignment.centerLeft, end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: _jagoPrimary.withValues(alpha: 0.45),
                        blurRadius: 20, offset: const Offset(0, 6),
                      ),
                      BoxShadow(
                        color: _jagoPrimary.withValues(alpha: 0.2),
                        blurRadius: 40, offset: const Offset(0, 10),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      GestureDetector(
        onTap: () => setState(() { _bookForSomeone = !_bookForSomeone; }),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: _bookForSomeone ? _blue.withValues(alpha: 0.06) : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFF)),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _bookForSomeone ? _blue.withValues(alpha: 0.3) : (isDark ? Colors.white12 : const Color(0xFFE8EFFF))),
          ),
          child: Row(children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: _bookForSomeone ? _blue.withValues(alpha: 0.12) : (isDark ? Colors.white10 : Colors.grey.shade100),
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
                  color: _bookForSomeone ? _blue : (isDark ? Colors.white : const Color(0xFF0F172A)))),
              const SizedBox(height: 2),
              Text(_isParcel ? 'Set sender & receiver details' : 'Enter passenger contact details',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
            ])),
            Switch(
              value: _bookForSomeone,
              onChanged: (v) => setState(() => _bookForSomeone = v),
              activeThumbColor: _blue,
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
            color: _blue.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _blue.withValues(alpha: 0.12)),
          ),
          child: Builder(builder: (ctx) {
            final isDarkLocal = Theme.of(ctx).brightness == Brightness.dark;
            return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_isParcel ? 'Sender Details' : 'Passenger Details',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                color: isDarkLocal ? Colors.white70 : const Color(0xFF374151), letterSpacing: 0.5)),
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
              Text('Receiver Details',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                  color: isDarkLocal ? Colors.white70 : const Color(0xFF374151), letterSpacing: 0.5)),
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
          ]);
          }),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE8EFFF)),
      ),
      child: Row(children: [
        Padding(
          padding: const EdgeInsets.only(left: 10),
          child: Icon(icon, size: 18, color: isDark ? Colors.white38 : Colors.grey.shade400),
        ),
        Expanded(
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: TextStyle(fontSize: 14, color: isDark ? Colors.white : const Color(0xFF0F172A)),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.grey.shade400, fontSize: 13),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildPaymentSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Payment Method',
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: isDark ? Colors.white70 : const Color(0xFF374151), letterSpacing: 0.2)),
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
            border: Border.all(color: _blue.withValues(alpha: 0.2)),
          ),
          child: Row(children: [
            const Icon(Icons.lock_rounded, color: _blue, size: 15),
            const SizedBox(width: 8),
            const Expanded(child: Text(
              'Secure payment via Razorpay — UPI, Cards, Netbanking accepted',
              style: TextStyle(fontSize: 12, color: Color(0xFF2F80ED), fontWeight: FontWeight.w500),
            )),
          ]),
        ),
      ],
    ]);
  }

  Widget _payBtn(String method, IconData icon, String label, String? subtitle) {
    final selected = _paymentMethod == method;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final unselBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFF);
    final unselBorder = isDark ? Colors.white12 : const Color(0xFFE2E8F0);
    final unselText = isDark ? Colors.white70 : const Color(0xFF374151);
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _paymentMethod = method);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: selected ? _blue : unselBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? _blue : unselBorder,
            width: selected ? 2 : 1,
          ),
          boxShadow: selected ? [BoxShadow(color: _blue.withValues(alpha: 0.3), blurRadius: 14, offset: const Offset(0, 5))] : [],
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 22, color: selected ? Colors.white : (isDark ? Colors.white54 : Colors.grey[500])),
          const SizedBox(height: 5),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
            color: selected ? Colors.white : unselText)),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(subtitle, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500,
              color: selected ? Colors.white.withValues(alpha: 0.75) : Colors.grey[400]),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ]),
      ),
    );
  }

  Widget _addressRow(IconData icon, Color color, String text, [Color? textColor]) {
    final tColor = textColor ?? const Color(0xFF0F172A);
    final isPickup = icon == Icons.circle;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        Container(
          width: 28, height: 28,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
          ),
          child: Icon(icon, color: color, size: isPickup ? 10 : 16),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(isPickup ? 'PICKUP' : 'DROP',
            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: color.withValues(alpha: 0.8), letterSpacing: 0.8)),
          const SizedBox(height: 2),
          Text(text,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: tColor),
            maxLines: 1, overflow: TextOverflow.ellipsis),
        ])),
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
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 1),
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
    final cardBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFF);
    final textMain = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSub = isDark ? Colors.white54 : Colors.grey.shade600;
    final borderCol = isDark ? Colors.white12 : const Color(0xFFE8EFFF);
    if (_estimating) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          CircularProgressIndicator(strokeWidth: 2.5, color: _jagoPrimary),
          SizedBox(height: 12),
          Text('Getting best fares...', style: TextStyle(color: Color(0xFF6B7280), fontSize: 13, fontWeight: FontWeight.w500)),
        ])));
    }
    if (_allFares.isEmpty) {
      final fbDist = _distanceKm;
      final fbSubtotal = (25.0 + fbDist * 10.0).clamp(28.0, double.infinity);
      final fbTotal = fbSubtotal * 1.05;
      final fbMin = (fbTotal * 0.95).floor();
      final fbMax = (fbTotal * 1.05).ceil();
      return Row(children: [
        Container(width: 52, height: 52,
          decoration: BoxDecoration(color: _jagoPrimary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(16)),
          child: Icon(_iconForVehicle(_vehicleName), color: _jagoPrimary, size: 26)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_vehicleName, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: textMain)),
          Text('${fbDist.toStringAsFixed(1)} km • Est. ~${(fbDist * 3).ceil()} min',
            style: TextStyle(fontSize: 13, color: textSub, fontWeight: FontWeight.w500)),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('₹$fbMin–₹$fbMax',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: _jagoPrimary)),
          Text('est. fare', style: TextStyle(fontSize: 9, color: Colors.grey[400])),
        ]),
      ]);
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _buildVehicleHero(),
      Row(children: [
        const Icon(Icons.directions_rounded, color: _jagoPrimary, size: 18),
        const SizedBox(width: 6),
        Text('Choose Your Ride',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: textMain, letterSpacing: -0.3)),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _jagoPrimary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _jagoPrimary.withValues(alpha: 0.25))),
          child: Text('${_allFares.length} options',
            style: const TextStyle(color: _jagoPrimary, fontSize: 11, fontWeight: FontWeight.w800)),
        ),
      ]),
      const SizedBox(height: 8),
      // Route summary strip
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade100),
        ),
        child: Row(children: [
          const Icon(Icons.route_rounded, size: 13, color: _jagoPrimary),
          const SizedBox(width: 6),
          Text('${_distanceKm.toStringAsFixed(1)} km',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: textMain)),
          Text('  ·  ', style: TextStyle(color: textSub, fontSize: 12)),
          Icon(Icons.access_time_rounded, size: 12, color: Colors.grey[400]),
          const SizedBox(width: 4),
          Text('~${(_distanceKm / 25 * 60).ceil()} min',
            style: TextStyle(fontSize: 12, color: textSub, fontWeight: FontWeight.w600)),
          const SizedBox(width: 6),
          Expanded(child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            Icon(Icons.location_on_rounded, size: 11, color: const Color(0xFF16A34A).withValues(alpha: 0.8)),
            const SizedBox(width: 2),
            Flexible(child: Text(widget.pickup.split(',').first,
              style: TextStyle(fontSize: 9, color: textSub.withValues(alpha: 0.65), fontWeight: FontWeight.w500),
              maxLines: 1, overflow: TextOverflow.ellipsis)),
            const Text(' → ', style: TextStyle(fontSize: 9, color: Color(0xFF2F80ED))),
            Flexible(child: Text(widget.destination.split(',').first,
              style: TextStyle(fontSize: 9, color: textSub.withValues(alpha: 0.65), fontWeight: FontWeight.w500),
              maxLines: 1, overflow: TextOverflow.ellipsis)),
          ])),
        ]),
      ),
      const SizedBox(height: 10),
      ..._allFares.asMap().entries.map((entry) {
        final i = entry.key;
        final f = entry.value;
        final isSelected = i == _selectedFareIndex;
        final name = f['vehicleCategoryName']?.toString() ?? f['vehicleName']?.toString() ?? f['name']?.toString() ?? 'Vehicle';
        final fareVal = (f['estimatedFare'] ?? 0).toDouble();
        final rawMin = (f['fareMin'] ?? (fareVal * 0.95)).toDouble();
        final rawMax = (f['fareMax'] ?? (fareVal * 1.05)).toDouble();
        final time = f['estimatedTime']?.toString() ?? '~5 min';
        final displayFare = isSelected ? (fareVal - _promoDiscount).clamp(0.0, double.infinity) : fareVal;
        final displayMin = (isSelected ? rawMin - _promoDiscount : rawMin).clamp(0.0, double.infinity);
        final displayMax = (isSelected ? rawMax - _promoDiscount : rawMax).clamp(0.0, double.infinity);
        final tag = _getVehicleTag(i);
        final minFareVal = (f['minimumFare'] ?? 0).toDouble();
        final farePerKmVal = (f['farePerKm'] ?? 0).toDouble();
        return GestureDetector(
          key: ValueKey(i),
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _selectedFareIndex = i);
          },
          child: Stack(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isSelected ? _accentForVehicle(name).withValues(alpha: 0.06) : cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? _accentForVehicle(name) : borderCol,
                    width: isSelected ? 2 : 1),
                  boxShadow: isSelected ? [
                    BoxShadow(color: _accentForVehicle(name).withValues(alpha: 0.25), blurRadius: 16, offset: const Offset(0, 4))
                  ] : [],
                ),
                child: Row(children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 56, height: 56,
                    decoration: BoxDecoration(
                      gradient: isSelected ? LinearGradient(
                        colors: [_accentForVehicle(name), _accentForVehicle(name).withValues(alpha: 0.7)],
                        begin: Alignment.topLeft, end: Alignment.bottomRight) : null,
                      color: isSelected ? null : _accentForVehicle(name).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _accentForVehicle(name).withValues(alpha: isSelected ? 0.8 : 0.15), width: isSelected ? 2 : 1),
                      boxShadow: isSelected ? [BoxShadow(color: _accentForVehicle(name).withValues(alpha: 0.4), blurRadius: 10, offset: const Offset(0, 4))] : [],
                    ),
                    child: Center(child: Text(_emojiForVehicle(name), style: TextStyle(fontSize: isSelected ? 28 : 24)))),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Flexible(child: Text(name, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15,
                        color: isSelected ? _accentForVehicle(name) : textMain), overflow: TextOverflow.ellipsis)),
                      if (tag != null) ...[
                        const SizedBox(width: 8),
                        _vehicleTagBadge(tag),
                      ],
                    ]),
                    const SizedBox(height: 5),
                    Wrap(spacing: 8, runSpacing: 4, children: [
                      Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.route_rounded, size: 11, color: Colors.grey[400]),
                        const SizedBox(width: 3),
                        Text('${_distanceKm.toStringAsFixed(1)} km',
                          style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                      ]),
                      Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.access_time_rounded, size: 11, color: Colors.grey[400]),
                        const SizedBox(width: 3),
                        Text(time, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                      ]),
                      if (_capacityForVehicle(name).isNotEmpty)
                        Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.people_alt_rounded, size: 11,
                            color: isSelected ? _jagoPrimary.withValues(alpha: 0.7) : Colors.grey[400]),
                          const SizedBox(width: 3),
                          Text(_capacityForVehicle(name),
                            style: TextStyle(fontSize: 11,
                              color: isSelected ? _jagoPrimary.withValues(alpha: 0.85) : Colors.grey[500],
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400)),
                        ]),
                    ]),
                  ])),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text('₹${displayMin.floor()}–₹${displayMax.ceil()}',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: _accentForVehicle(name))),
                    Text('est. fare', style: TextStyle(fontSize: 9, color: Colors.grey[400])),
                    if (isSelected && _promoDiscount > 0)
                      Text('saved ₹${_promoDiscount.toInt()}',
                        style: const TextStyle(fontSize: 10, color: Color(0xFF16A34A), fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(time, style: TextStyle(fontSize: 11, color: textSub)),
                    if (minFareVal > 0) ...[
                      const SizedBox(height: 2),
                      Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.info_outline_rounded, size: 9, color: Colors.grey[400]),
                        const SizedBox(width: 2),
                        Text('Min ₹${minFareVal.toStringAsFixed(0)}',
                          style: TextStyle(fontSize: 9, color: Colors.grey[400])),
                      ]),
                    ],
                    if (farePerKmVal > 0) ...[
                      Text('₹${farePerKmVal.toStringAsFixed(0)}/km',
                        style: TextStyle(fontSize: 9, color: Colors.grey[400])),
                    ],
                  ]),
                  const SizedBox(width: 28),
                ]),
              ),
              if (isSelected)
                Positioned(
                  top: 0, right: 0,
                  child: Container(
                    width: 28, height: 28,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_accentForVehicle(name), _accentForVehicle(name).withValues(alpha: 0.75)],
                        begin: Alignment.topLeft, end: Alignment.bottomRight),
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: _accentForVehicle(name).withValues(alpha: 0.45), blurRadius: 8, offset: const Offset(0, 2))],
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
    final cardBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFF);
    final borderCol = isDark ? Colors.white12 : const Color(0xFFE8EFFF);
    final textMain = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSub = isDark ? Colors.white54 : Colors.grey.shade600;

    final baseFare = (fare['baseFare'] ?? 0).toDouble();
    final distanceFare = (fare['distanceFare'] ?? 0).toDouble();
    final timeFare = (fare['timeFare'] ?? 0).toDouble();
    final helperCharge = (fare['helperCharge'] ?? 0).toDouble();
    final gst = (fare['gst'] ?? 0).toDouble();
    final minFare = (fare['minimumFare'] ?? 0).toDouble();
    final farePerKm = (fare['farePerKm'] ?? 0).toDouble();
    final waitingChargePerMin = (fare['waitingChargePerMin'] ?? 0).toDouble();
    final subtotal = (fare['subtotal'] ?? (baseFare + distanceFare + timeFare)).toDouble();
    final isMinFareApplied = minFare > 0 && subtotal <= minFare + 0.01;
    final isNight = fare['isNightCharge'] == true;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderCol),
      ),
      child: Column(children: [
        // Header
        Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          decoration: BoxDecoration(
            color: _jagoPrimary.withValues(alpha: 0.06),
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(15), topRight: Radius.circular(15)),
            border: Border(bottom: BorderSide(color: borderCol)),
          ),
          child: Row(children: [
            const Icon(Icons.receipt_long_rounded, size: 16, color: _jagoPrimary),
            const SizedBox(width: 8),
            Text(_isParcel ? 'Delivery Fare Details' : 'Fare Breakdown',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: _jagoPrimary)),
            const Spacer(),
            if (isMinFareApplied)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF2F80ED).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF2F80ED).withValues(alpha: 0.3)),
                ),
                child: const Text('Min fare', style: TextStyle(
                  fontSize: 10, color: Color(0xFF2F80ED), fontWeight: FontWeight.w800)),
              )
            else if (isNight)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF8B5CF6).withValues(alpha: 0.3)),
                ),
                child: const Text('Night fare', style: TextStyle(
                  fontSize: 10, color: Color(0xFF8B5CF6), fontWeight: FontWeight.w800)),
              )
            else
              Text('Incl. GST', style: TextStyle(fontSize: 10, color: Colors.grey[400], fontWeight: FontWeight.w500)),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.all(14),
          child: Column(children: [
            // Base fare row with rate info
            _fareRow('Base Fare (Booking Fee)', '₹${baseFare.toStringAsFixed(0)}', textSub: textSub),
            // Distance fare — always show when farePerKm > 0
            if (farePerKm > 0) ...[
              _fareRow(
                '${_distanceKm.toStringAsFixed(1)} km × ₹${farePerKm.toStringAsFixed(0)}/km',
                '₹${distanceFare.toStringAsFixed(0)}',
                textSub: textSub,
              ),
            ] else if (distanceFare > 0)
              _fareRow('Distance (${_distanceKm.toStringAsFixed(1)} km)',
                '₹${distanceFare.toStringAsFixed(0)}', textSub: textSub),
            if (timeFare > 0)
              _fareRow('Time Charge (per min)', '₹${timeFare.toStringAsFixed(0)}', textSub: textSub),
            if (waitingChargePerMin > 0)
              _fareRow('Waiting Charge (₹${waitingChargePerMin.toStringAsFixed(0)}/min)', '—', textSub: textSub),
            // Parcel-specific: helper charge (Porter style)
            if (_isParcel && helperCharge > 0)
              Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.2)),
                ),
                child: Row(children: [
                  const Icon(Icons.person_2_rounded, size: 13, color: Color(0xFF10B981)),
                  const SizedBox(width: 6),
                  Expanded(child: Text('Helper Charge (loading/unloading)',
                    style: TextStyle(fontSize: 11, color: textSub))),
                  Text('₹${helperCharge.toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF10B981))),
                ]),
              )
            else if (!_isParcel && helperCharge > 0)
              _fareRow('Helper Charge', '₹${helperCharge.toStringAsFixed(0)}', textSub: textSub),
            // Night multiplier
            if (isNight) ...[
              const SizedBox(height: 2),
              Row(children: [
                const Icon(Icons.nightlight_round, size: 12, color: Color(0xFF8B5CF6)),
                const SizedBox(width: 5),
                Text('Night fare applies (1.0x–1.25x)',
                  style: TextStyle(fontSize: 11, color: textSub, fontStyle: FontStyle.italic)),
              ]),
            ],
            // Minimum fare note
            if (minFare > 0) ...[
              const SizedBox(height: 4),
              Row(children: [
                Icon(Icons.info_outline_rounded, size: 12, color: Colors.grey[400]),
                const SizedBox(width: 5),
                Text('Minimum fare: ₹${minFare.toStringAsFixed(0)}',
                  style: TextStyle(fontSize: 11, color: Colors.grey[400])),
              ]),
            ],
            Divider(height: 18, color: borderCol, thickness: 1),
            _fareRow('GST (5%)', '₹${gst.toStringAsFixed(0)}', textSub: textSub),
            if (_promoDiscount > 0)
              _fareRow('Promo Discount', '-₹${_promoDiscount.toInt()}', positive: true, textSub: textSub),
            const SizedBox(height: 8),
            // Total row — bold, large, orange
            Row(children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Total Fare', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: textMain)),
                if (minFare > 0 && isMinFareApplied)
                  Text('Min fare applied', style: TextStyle(fontSize: 10, color: Colors.grey[400])),
              ]),
              const Spacer(),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('₹${_finalFare.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: _jagoPrimary)),
                Text('incl. GST', style: TextStyle(fontSize: 10, color: Colors.grey[400])),
              ]),
            ]),
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
        Expanded(child: Text(label, style: TextStyle(fontSize: 12, color: sub))),
        Text(value, style: TextStyle(fontSize: 12,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
          color: positive ? _green : sub)),
      ]),
    );
  }

  Widget _buildPromoRow() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFF);
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
          const Icon(Icons.local_offer_outlined, color: _jagoPrimary, size: 18),
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
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: _jagoPrimary))
              : const Text('APPLY', style: TextStyle(color: _jagoPrimary, fontSize: 13, fontWeight: FontWeight.w800)),
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
