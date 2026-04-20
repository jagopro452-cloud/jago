import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/api_config.dart';
import '../../config/jago_theme.dart';
import '../../services/auth_service.dart';
import '../tracking/tracking_screen.dart';
import 'ride_for_whom_screen.dart';

class BookingScreen extends StatefulWidget {
  final String pickup;
  final String destination;
  final double pickupLat, pickupLng, destLat, destLng;
  final String? vehicleCategoryId;
  final String? vehicleCategoryName;
  final String? category; // 'ride' | 'parcel' | 'pool'
  const BookingScreen({
    super.key,
    required this.pickup,
    required this.destination,
    this.pickupLat = 17.3850, this.pickupLng = 78.4867,
    this.destLat = 0, this.destLng = 0,
    this.vehicleCategoryId,
    this.vehicleCategoryName,
    this.category,
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
  Timer? _debounce;

  late Razorpay _razorpay;

  bool _bookForSomeone = false;
  final _passengerNameCtrl = TextEditingController();
  final _passengerPhoneCtrl = TextEditingController();
  final _receiverNameCtrl = TextEditingController();
  final _receiverPhoneCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  bool _popularForPickup = false;
  
  Set<Polyline> _polylines = {};
  double _routedDistanceKm = 0.0;

  // Populated dynamically from /api/app/popular-locations; static data used as fallback
  List<Map<String, dynamic>> _popularLocations = const [
    {'name': 'Benz Circle', 'lat': 16.5062, 'lng': 80.6480},
    {'name': 'Vijayawada Railway Station', 'lat': 16.5175, 'lng': 80.6400},
    {'name': 'Vijayawada Bus Stand', 'lat': 16.5179, 'lng': 80.6238},
    {'name': 'Balaji Bus Stand', 'lat': 16.5106, 'lng': 80.6248},
    {'name': 'Kanaka Durga Temple', 'lat': 16.5176, 'lng': 80.6121},
    {'name': 'Gannavaram Airport', 'lat': 16.5304, 'lng': 80.7968},
    {'name': 'Governorpet', 'lat': 16.5135, 'lng': 80.6346},
    {'name': 'Patamata', 'lat': 16.4883, 'lng': 80.6681},
  ];

  static const Color _jagoPrimary = JT.primary;
  static const Color _jagoSecondary = JT.secondary;

  static const Color _blue = Color(0xFF6366F1); // Vibrant Indigo
  static const Color _green = JT.success;

  LatLng get _pickupLatLng => LatLng(widget.pickupLat, widget.pickupLng);
  LatLng get _destLatLng => widget.destLat != 0 && widget.destLng != 0
    ? LatLng(widget.destLat, widget.destLng)
    : LatLng(widget.pickupLat + 0.02, widget.pickupLng + 0.02);

  Map<String, dynamic>? get _fare => _allFares.isNotEmpty ? _allFares[_selectedFareIndex] : null;

  String get _vehicleName => _fare?['vehicleCategoryName']?.toString() ?? _fare?['name']?.toString() ?? widget.vehicleCategoryName ?? 'Bike';

  static IconData _iconForVehicle(String name) {
    final n = name.toLowerCase();
    if (n.contains('pickup van') || n.contains('pickup')) return Icons.fire_truck_rounded;
    if (n.contains('mini truck') || n.contains('tata ace') || n.contains('mini cargo')) return Icons.local_shipping_rounded;
    if (n.contains('parcel bike') || n.contains('bike parcel') || n.contains('parcel auto')) return Icons.delivery_dining_rounded;
    if (n.contains('parcel')) return Icons.inventory_2_rounded;
    if (n.contains('bike')) return Icons.electric_bike_rounded;
    if (n.contains('auto')) return Icons.electric_rickshaw_rounded;
    if (n.contains('cargo truck')) return Icons.fire_truck_rounded;
    if (n.contains('cargo')) return Icons.local_shipping_rounded;
    if (n.contains('suv')) return Icons.directions_car_filled_rounded;
    if (n.contains('car')) return Icons.directions_car_filled_rounded;
    return Icons.directions_car_filled_rounded;
  }

  static String _emojiForVehicle(String name) {
    final n = name.toLowerCase();
    // Parcel vehicles — MUST show goods/delivery vehicles, NOT passenger
    if (n.contains('pickup van') || n.contains('pickup')) return '🚛';     // Heavy pickup van
    if (n.contains('mini truck') || n.contains('tata ace')) return '🚐';   // Mini cargo truck
    if (n.contains('parcel bike') || n.contains('bike parcel')) return '🛵'; // Delivery bike
    if (n.contains('parcel auto')) return '🛻';  // ✅ GOODS AUTO — pickup/cargo truck feel (not passenger auto 🛺, not bus)
    if (n.contains('parcel')) return '🚐';       // Generic parcel vehicle
    // Ride vehicles
    if (n.contains('bike')) return '🏍️';
    if (n.contains('auto')) return '🛺';         // Passenger auto only for ride
    if (n.contains('cargo truck')) return '🚛';
    if (n.contains('cargo')) return '🚐';
    if (n.contains('suv')) return '🚙';
    if (n.contains('car')) return '🚗';
    return '🚗';
  }

  // Rule 3: Parcel Auto subtitle must clearly say GOODS ONLY
  static String _subtitleForVehicle(String name) {
    final n = name.toLowerCase();
    if (n.contains('parcel auto')) return 'Goods Carrier Auto · CARGO ONLY';
    if (n.contains('parcel bike')) return 'Delivery bike · Up to 10 kg';
    if (n.contains('mini truck') || n.contains('tata ace')) return 'Mini cargo truck · Up to 500 kg';
    if (n.contains('pickup van') || n.contains('pickup')) return 'Large pickup van · Up to 2000 kg';
    if (n.contains('parcel')) return 'Parcel delivery';
    if (n.contains('bike')) return '1 passenger · Fastest';
    if (n.contains('auto')) return 'Up to 3 passengers';
    if (n.contains('suv')) return 'Up to 6 passengers · AC';
    if (n.contains('car')) return 'Up to 4 passengers · AC';
    return '';
  }

  // Rule 4: Returns true if vehicle should be HIDDEN
  static bool _shouldHideVehicle(String name) {
    final n = name.toLowerCase();
    
    // Whitelist only requested categories: bike, auto, cab, premium
    // Relaxed contains checks to avoid hiding valid variations (e.g. "Bike - Fast")
    if (n.contains('bike')) return false;
    if (n.contains('auto')) return false;
    if (n.contains('cab')) return false;
    if (n.contains('premium')) return false;
    if (n.contains('sedan')) return false;
    if (n.contains('car')) return false;

    // Hide everything else (Parcel, SUV, Pool, etc. if not requested)
    return true;
  }

  static Color _accentForVehicle(String name) {
    return const Color(0xFF6366F1); // Unified Premium Indigo
  }

  // ── Vehicle image URLs (real vehicle images, network with emoji fallback) ──
  // Matches the premium Cloudinary assets used in home_screen.dart
  static const Map<String, String> _vehicleImageUrls = {
    'bike': 'https://res.cloudinary.com/kits/image/upload/q_auto/f_auto/v1775123974/bike_logo_g7idrq.png',
    'auto': 'https://res.cloudinary.com/kits/image/upload/q_auto/f_auto/v1775125550/ChatGPT_Image_Apr_2_2026_03_55_30_PM_ywb7fj.png',
    'cab': 'https://res.cloudinary.com/dg5ct7fys/image/upload/f_auto,q_auto/ChatGPT_Image_Apr_17_2026_11_27_28_AM_w0rcnh',
    'premium': 'https://res.cloudinary.com/dg5ct7fys/image/upload/f_auto,q_auto/ChatGPT_Image_Apr_17_2026_11_31_05_AM_kavp5e',
    'parcel_bike': 'https://res.cloudinary.com/dg5ct7fys/image/upload/f_auto,q_auto/ChatGPT_Image_Apr_17_2026_11_49_26_AM_gjbrxs',
    'parcel_auto': 'https://oyster-app-9e9cd.ondigitalocean.app/static/vehicles/parcel_auto.png',
    'mini_truck':  'https://res.cloudinary.com/dg5ct7fys/image/upload/f_auto,q_auto/ChatGPT_Image_Apr_17_2026_11_51_59_AM_jzd119',
    'pickup_van':  'https://res.cloudinary.com/dg5ct7fys/image/upload/f_auto,q_auto/ChatGPT_Image_Apr_17_2026_11_54_02_AM_hicx7s',
  };

  static String? _vehicleImageKey(String name) {
    final n = name.toLowerCase();
    if (n.contains('premium')) return 'premium';
    if (n.contains('pickup van') || n.contains('pickup')) return 'pickup_van';
    if (n.contains('mini truck') || n.contains('tata ace')) return 'mini_truck';
    if (n.contains('parcel bike') || n.contains('bike parcel')) return 'parcel_bike';
    if (n.contains('parcel auto')) return 'parcel_auto';
    if (n.contains('parcel')) return 'parcel_bike';
    if (n.contains('bike')) return 'bike';
    if (n.contains('auto')) return 'auto';
    if (n.contains('cab') || n.contains('car') || n.contains('suv')) return 'cab';
    return null;
  }

  /// Renders vehicle artwork — real network image with icon fallback.
  Widget _buildVehicleArtwork(String name, Color accent, bool isSelected, {double size = 96}) {
    final imageKey = _vehicleImageKey(name);
    final imageUrl = imageKey != null ? _vehicleImageUrls[imageKey] : null;
    final icon = _iconForVehicle(name);
    final isParcel = widget.category == 'parcel';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      width: size, height: size,
      decoration: BoxDecoration(
        color: isSelected ? accent.withValues(alpha: 0.08) : const Color(0xFFF8FAFC),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(14), bottomLeft: Radius.circular(14)),
      ),
      child: Stack(alignment: Alignment.center, children: [
        // Vehicle image (real) with icon fallback
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 18),
          child: imageUrl != null
            ? Image.network(
                imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Icon(
                  icon, size: size * 0.44,
                  color: accent.withValues(alpha: isSelected ? 0.85 : 0.60),
                ),
              )
            : Icon(
                icon, size: size * 0.44,
                color: accent.withValues(alpha: isSelected ? 0.85 : 0.60),
              ),
        ),
        // DELIVERY / RIDE badge at bottom
        Positioned(
          bottom: 5,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isSelected ? accent : accent.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              isParcel ? 'DELIVERY' : 'RIDE',
              style: const TextStyle(color: Colors.white, fontSize: 7,
                fontWeight: FontWeight.w500, letterSpacing: 0.5),
            ),
          ),
        ),
      ]),
    );
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
                color: Colors.white, fontSize: 9, fontWeight: FontWeight.w500, letterSpacing: 1.5)),
            ),
            const SizedBox(height: 8),
            Text(name, style: const TextStyle(
              color: Colors.white, fontSize: 22, fontWeight: FontWeight.w500, letterSpacing: -0.5)),
            const SizedBox(height: 4),
            Text('₹${displayMin.floor()} – ₹${displayMax.ceil()}',
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w400)),
            Text('estimated fare', style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 11)),
          ])),
          // Real vehicle image — emoji fallback if network fails
          Builder(builder: (_) {
            final imgKey = _vehicleImageKey(name);
            final imgUrl = imgKey != null ? _vehicleImageUrls[imgKey] : null;
            return SizedBox(
              width: 100, height: 80,
              child: imgUrl != null
                ? Image.network(
                    imgUrl,
                    fit: BoxFit.contain,
                    color: Colors.white.withValues(alpha: 0.92),
                    colorBlendMode: BlendMode.modulate,
                    errorBuilder: (_, __, ___) =>
                        Text(emoji, style: const TextStyle(fontSize: 64)),
                  )
                : Text(emoji, style: const TextStyle(fontSize: 64)),
            );
          }),
        ]),
      ),
    );
  }

  /// Parse "~5 min" / "5 min" / "5-8 min" → arrival minutes number
  static int _etaMins(String timeStr) {
    final match = RegExp(r'(\d+)').firstMatch(timeStr);
    return match != null ? int.tryParse(match.group(1) ?? '5') ?? 5 : 5;
  }

  /// "Drop 6:14 pm" style string from eta
  static String _dropTimeStr(String timeStr) {
    final mins = _etaMins(timeStr);
    final dropTime = DateTime.now().add(Duration(minutes: mins + 10));
    final h = dropTime.hour > 12 ? dropTime.hour - 12 : (dropTime.hour == 0 ? 12 : dropTime.hour);
    final m = dropTime.minute.toString().padLeft(2, '0');
    final ampm = dropTime.hour >= 12 ? 'pm' : 'am';
    return '$h:$m $ampm';
  }

  static String _capacityForVehicle(String name) {
    final n = name.toLowerCase();
    if (n.contains('pickup van') || n.contains('pickup')) return 'Up to 2000 kg';
    if (n.contains('mini truck') || n.contains('tata ace')) return 'Up to 500 kg';
    if (n.contains('parcel bike') || n.contains('bike parcel')) return 'Up to 10 kg';
    if (n.contains('parcel auto')) return 'Up to 50 kg';
    if (n.contains('parcel')) return 'Package delivery';
    if (n.contains('suv')) return '6 seats';
    if (n.contains('car')) return '4 seats';
    if (n.contains('auto')) return '3 seats';
    if (n.contains('bike')) return '1 rider';
    if (n.contains('cargo truck')) return 'Up to 1000 kg';
    if (n.contains('cargo')) return 'Up to 500 kg';
    return '';
  }

  double get _distanceKm {
    if (_routedDistanceKm > 0) return _routedDistanceKm;
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

  String _shortLocation(String value) {
    final v = value.trim();
    if (v.isEmpty) return v;
    return v.split(',').first.trim();
  }

  void _quickSelectPopular(Map<String, dynamic> location) {
    final name = (location['name'] ?? '').toString();
    final lat = (location['lat'] as num?)?.toDouble() ?? 0.0;
    final lng = (location['lng'] as num?)?.toDouble() ?? 0.0;
    if (name.isEmpty || lat == 0 || lng == 0) return;

    final next = BookingScreen(
      pickup: _popularForPickup ? name : widget.pickup,
      destination: _popularForPickup ? widget.destination : name,
      pickupLat: _popularForPickup ? lat : widget.pickupLat,
      pickupLng: _popularForPickup ? lng : widget.pickupLng,
      destLat: _popularForPickup ? widget.destLat : lat,
      destLng: _popularForPickup ? widget.destLng : lng,
      vehicleCategoryId: widget.vehicleCategoryId,
      vehicleCategoryName: widget.vehicleCategoryName,
      category: widget.category,
    );
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => next));
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
    _fetchPopularLocations();
    _fetchRoutePolyline();
  }

  Future<void> _fetchPopularLocations() async {
    try {
      final uri = Uri.parse(ApiConfig.popularLocations).replace(
        queryParameters: {'lat': widget.pickupLat.toString(), 'lng': widget.pickupLng.toString()},
      );
      final r = await http.get(uri).timeout(const Duration(seconds: 5));
      if (r.statusCode == 200) {
        final data = jsonDecode(r.body);
        if (data is! Map) return;
        final rawList = data['locations'];
        final list = rawList is List ? rawList.whereType<Map<String, dynamic>>().toList() : <Map<String, dynamic>>[];
        if (mounted && list.isNotEmpty) {
          setState(() => _popularLocations = list.map((l) => {
            'name': l['name']?.toString() ?? '',
            'lat': (l['lat'] as num?)?.toDouble() ?? 0.0,
            'lng': (l['lng'] as num?)?.toDouble() ?? 0.0,
          }).toList());
        }
      }
    } catch (_) { /* keep static fallback */ }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _promoCtrl.dispose();
    _razorpay.clear();
    _passengerNameCtrl.dispose();
    _passengerPhoneCtrl.dispose();
    _receiverNameCtrl.dispose();
    _receiverPhoneCtrl.dispose();
    _noteCtrl.dispose();
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

  void _onCouponChanged(String value) {
    // Clear stale error/discount on code change
    if (_promoError != null) setState(() => _promoError = null);
    _debounce?.cancel();
    // Only auto-apply when user has typed a plausible code (≥4 chars)
    if (value.trim().length >= 4) {
      _debounce = Timer(const Duration(milliseconds: 600), () {
        if (_promoCtrl.text.trim().isNotEmpty) _applyPromo();
      });
    }
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
      if (res.statusCode == 200) {
        try {
          final data = jsonDecode(res.body);
          setState(() {
            _appliedPromo = code;
            _promoDiscount = double.tryParse(data['discount']?.toString() ?? '0') ?? 0;
            _promoLoading = false;
          });
        } catch (_) {
          setState(() { _promoError = 'Invalid response from server'; _promoLoading = false; });
        }
      } else {
        try {
          final data = jsonDecode(res.body);
          setState(() { _promoError = data['message'] ?? 'Invalid code'; _promoLoading = false; });
        } catch (_) {
          setState(() { _promoError = 'Invalid coupon code'; _promoLoading = false; });
        }
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
      if (widget.category != null) body['category'] = widget.category;
      final res = await http.post(Uri.parse(ApiConfig.estimateFare),
        headers: headers,
        body: jsonEncode(body));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final rawFares = data['fares'];
        final fares = rawFares is List ? rawFares.whereType<Map<String, dynamic>>().toList() : null;
        if (fares != null && fares.isNotEmpty) {
          setState(() {
            // Rule 2: Strict service separation — filter by category, hide inactive
            var filtered = fares.toList();
            final cat = widget.category ?? 'ride';
            if (cat == 'parcel') {
              filtered = filtered.where((f) {
                final vname = (f['vehicleCategoryName'] ?? f['name'] ?? '').toString().toLowerCase();
                final vtype = (f['type'] ?? f['vehicleType'] ?? '').toString().toLowerCase();
                return vtype == 'parcel' || vname.contains('parcel') ||
                    vname.contains('truck') || vname.contains('van') ||
                    vname.contains('tata') || vname.contains('mini');
              }).toList();
            } else {
              filtered = filtered.where((f) {
                final vname = (f['vehicleCategoryName'] ?? f['name'] ?? '').toString().toLowerCase();
                final vtype = (f['type'] ?? f['vehicleType'] ?? '').toString().toLowerCase();
                // Exclude parcel/cargo vehicles from ride
                if (vtype == 'parcel' || vname.contains('parcel') || vname.contains('truck') || vname.contains('cargo')) return false;
                // Rule 4: Hide inactive services
                if (_shouldHideVehicle(vname)) return false;
                return true;
              }).toList();
            }
            _allFares = filtered;
            
            // Ensure we have at least the core categories (Bike, Auto, Cab)
            if (widget.category != 'parcel') {
              final fallbacks = _buildFallbackFares();
              for (var fb in fallbacks) {
                final fbName = fb['vehicleCategoryName'].toString();
                // Add fallback if no similar category exists in server result
                if (!_allFares.any((f) {
                  final name = (f['vehicleCategoryName'] ?? f['name'] ?? '').toString().toLowerCase();
                  return name.contains(fbName.split(' ').first.toLowerCase());
                })) {
                  _allFares.add(fb);
                }
              }
            }
            
            // Final safety check: if still empty (shouldn't happen with fallbacks), use all fallbacks
            if (_allFares.isEmpty) _allFares = _buildFallbackFares();
            if (widget.vehicleCategoryId != null || widget.vehicleCategoryName != null) {
              final targetName = (widget.vehicleCategoryName ?? '').toLowerCase();
              final idx = _allFares.indexWhere((f) {
                final fName = (f['vehicleCategoryName'] ?? f['name'] ?? '').toString().toLowerCase();
                final fId = f['vehicleCategoryId']?.toString() ?? f['id']?.toString();
                return fId == widget.vehicleCategoryId || 
                       (targetName.isNotEmpty && fName.contains(targetName));
              });
              if (idx >= 0) _selectedFareIndex = idx;
            }
          });
        } else {
          // Server returned 200 but body wasn't as expected — use fallbacks
          if (mounted) setState(() => _allFares = _buildFallbackFares());
        }
      } else {
        // Server returned error status — use fallbacks
        if (mounted) setState(() => _allFares = _buildFallbackFares());
      }
    } catch (_) {
      // Network error — show client-side estimates only on connectivity failure
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
    // Parcel-specific vehicles — never mix with ride vehicles
    if (widget.category == 'parcel') {
      return [
        make('Parcel Bike',  20,  8,  25, (dist * 4).ceil()),
        make('Parcel Auto',  30, 10,  35, (dist * 4).ceil()),
        make('Mini Truck',  100, 25, 120, (dist * 5).ceil()),
        make('Pickup Van',  150, 35, 180, (dist * 5).ceil()),
      ];
    }
    // Ride vehicles (default)
    return [
      make('Bike', 25, 10, 28, (dist * 3).ceil()),
      make('Auto', 35, 13, 40, (dist * 3.5).ceil()),
      make('Cab',  50, 16, 60, (dist * 4).ceil()),
      make('Premium Cab', 70, 20, 80, (dist * 4).ceil()),
    ];
  }

  Future<void> _confirmBooking({String? razorpayPaymentId}) async {
    setState(() => _loading = true);
    try {
      final headers = await AuthService.getHeaders();
      final body = <String, dynamic>{
        'pickupAddress': widget.pickup,
        'destinationAddress': widget.destination,
        'pickupShortName': _shortLocation(widget.pickup),
        'destinationShortName': _shortLocation(widget.destination),
        'pickupLat': widget.pickupLat, 'pickupLng': widget.pickupLng,
        'destinationLat': widget.destLat, 'destinationLng': widget.destLng,
        'estimatedFare': _finalFare,
        'estimatedDistance': _distanceKm,
        'paymentMethod': _paymentMethod,
        if (_promoDiscount > 0) 'promoDiscount': _promoDiscount,
        if (_appliedPromo != null) 'couponCode': _appliedPromo,
        if (razorpayPaymentId != null) 'razorpayPaymentId': razorpayPaymentId,
        'ride_for': _bookForSomeone ? 'other' : 'self',
        if (_bookForSomeone) 'isForSomeoneElse': true,
        if (_bookForSomeone && _passengerNameCtrl.text.trim().isNotEmpty) ...{
          'passengerName': _passengerNameCtrl.text.trim(),
          'passenger_name': _passengerNameCtrl.text.trim(),
        },
        if (_bookForSomeone && _passengerPhoneCtrl.text.trim().isNotEmpty) ...{
          'passengerPhone': _passengerPhoneCtrl.text.trim(),
          'passenger_mobile': _passengerPhoneCtrl.text.trim(),
        },
        if (_bookForSomeone && _receiverNameCtrl.text.trim().isNotEmpty)
          'receiverName': _receiverNameCtrl.text.trim(),
        if (_bookForSomeone && _receiverPhoneCtrl.text.trim().isNotEmpty)
          'receiverPhone': _receiverPhoneCtrl.text.trim(),
        if (_bookForSomeone && _noteCtrl.text.trim().isNotEmpty)
          'note': _noteCtrl.text.trim(),
      };
      final vcId = _fare?['vehicleCategoryId']?.toString() ?? _fare?['id']?.toString() ?? widget.vehicleCategoryId;
      if (vcId != null && vcId.isNotEmpty) body['vehicleCategoryId'] = vcId;
      final res = await http.post(Uri.parse(ApiConfig.bookRide),
        headers: headers,
        body: jsonEncode(body));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final tripId = data['trip']?['id']?.toString() ?? '';
        if (!mounted) return;
        if (tripId.isEmpty) {
          _showSnack('Booking confirmed but could not track trip. Please check My Trips.', error: false);
          setState(() => _loading = false);
          Navigator.pop(context);
          return;
        }
        Navigator.pushReplacement(context, MaterialPageRoute(
          builder: (_) => TrackingScreen(tripId: tripId)));
      } else {
        if (!mounted) return;
        try {
          final err = jsonDecode(res.body);
          _showSnack(err['message'] ?? 'Booking failed', error: true);
        } catch (_) {
          _showSnack('Booking failed. Please try again.', error: true);
        }
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
          color: Colors.white,
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
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500,
              color: JT.textPrimary)),
          const SizedBox(height: 8),
          Text('Navigate to pickup location?',
            style: TextStyle(fontSize: 14, color: Colors.grey[600])),
          const SizedBox(height: 6),
          Text(pickupAddr,
            style: const TextStyle(fontSize: 13, color: JT.primary, fontWeight: FontWeight.w400),
            maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Center(child: Text('Skip',
                    style: TextStyle(fontWeight: FontWeight.w500,
                      color: Colors.grey[700]))),
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
                    gradient: const LinearGradient(colors: [JT.primary, Color(0xFF1244A2)]),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [BoxShadow(color: JT.primary.withValues(alpha: 0.35), blurRadius: 12)],
                  ),
                  child: const Center(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.navigation_rounded, color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    Text('Navigate Now', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 14)),
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

  Future<void> _goToRideForWhomScreen() async {
    final result = await Navigator.push(context, MaterialPageRoute(
      builder: (_) => RideForWhomScreen(vehicleName: _vehicleName),
    ));
    if (result != null && result is Map) {
      setState(() {
        _bookForSomeone = result['isForSomeone'] == true;
        if (_bookForSomeone) {
          _passengerNameCtrl.text = result['name'] ?? '';
          _passengerPhoneCtrl.text = result['phone'] ?? '';
          _noteCtrl.text = result['note'] ?? '';
        } else {
          _passengerNameCtrl.clear();
          _passengerPhoneCtrl.clear();
          _noteCtrl.clear();
        }
      });
      _handleOnConfirm();
    }
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
        try {
          final err = jsonDecode(res.body);
          _showSnack(err['message'] ?? 'Payment setup failed', error: true);
        } catch (_) {
          _showSnack('Payment setup failed. Try again.', error: true);
        }
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
        'name': 'Jago Rides',
        'description': 'Ride to ${_shortLocation(widget.destination)}',
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
      content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w400, color: Colors.white)),
      backgroundColor: error ? const Color(0xFFDC2626) : _green,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  List<LatLng> _decodePolyline(String encoded) {
    final List<LatLng> pts = [];
    int index = 0;
    int lat = 0, lng = 0;
    while (index < encoded.length) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      final dLat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dLat;
      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      final dLng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dLng;
      pts.add(LatLng(lat / 1e5, lng / 1e5));
    }
    return pts;
  }

  Future<void> _fetchRoutePolyline() async {
    bool success = false;
    List<LatLng> points = [];
    double fetchedDistMeters = 0.0;

    // Attempt 1: OSRM Public Routing API (Highly reliable, no API key, returns distance)
    try {
      final uri = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/${widget.pickupLng},${widget.pickupLat};${widget.destLng},${widget.destLat}?overview=full&geometries=polyline'
      );
      final res = await http.get(uri).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['code'] == 'Ok' && data['routes'] != null && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final encoded = route['geometry'];
          points = _decodePolyline(encoded);
          fetchedDistMeters = (route['distance'] as num).toDouble();
          success = points.isNotEmpty;
        }
      }
    } catch (_) {}

    // Attempt 2: Direct Google Directions API
    if (!success) {
      try {
        final uri = Uri.parse(
          'https://maps.googleapis.com/maps/api/directions/json?origin=${widget.pickupLat},${widget.pickupLng}&destination=${widget.destLat},${widget.destLng}&key=${ApiConfig.googleMapsApiKey}'
        );
        final res = await http.get(uri).timeout(const Duration(seconds: 4));
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          if (data['routes'] != null && data['routes'].isNotEmpty) {
            final encoded = data['routes'][0]['overview_polyline']['points'];
            points = _decodePolyline(encoded);
            final legs = data['routes'][0]['legs'];
            if (legs != null && legs.isNotEmpty) {
               fetchedDistMeters = (legs[0]['distance']['value'] as num).toDouble();
            }
            success = points.isNotEmpty;
          }
        }
      } catch (_) {}
    }

    // Attempt 3: Backend Navigation API
    if (!success) {
      try {
        final headers = await AuthService.getHeaders();
        final res = await http.post(
          Uri.parse(ApiConfig.routeMultiWaypoint),
          headers: {...headers, 'Content-Type': 'application/json'},
          body: jsonEncode({
            'origin': {'lat': widget.pickupLat, 'lng': widget.pickupLng},
            'destination': {'lat': widget.destLat, 'lng': widget.destLng},
            'waypoints': [],
            'optimize': false,
          }),
        ).timeout(const Duration(seconds: 4));
        
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body) as Map<String, dynamic>;
          final overviewPolyline = data['overviewPolyline']?.toString();
          if (overviewPolyline != null && overviewPolyline.isNotEmpty) {
            points = _decodePolyline(overviewPolyline);
            success = points.isNotEmpty;
          }
        }
      } catch (_) {}
    }

    if (!mounted) return;

    if (success) {
      if (fetchedDistMeters > 0) {
        _routedDistanceKm = fetchedDistMeters / 1000.0;
        // Recalculate true road distance fares
        _estimateFare();
      }

      setState(() {
        _polylines = {
          Polyline( // Production quality curvy road line constraint
            polylineId: const PolylineId('route'),
            points: points,
            color: _jagoPrimary,
            width: 5,
            jointType: JointType.round,
            startCap: Cap.roundCap,
            endCap: Cap.roundCap,
            geodesic: true,
          )
        };
      });
      _fitMapToRoute(routePoints: points);
    } else {
      setState(() {
        _polylines = {
          Polyline(
            polylineId: const PolylineId('route_fallback'),
            points: [_pickupLatLng, _destLatLng],
            color: _blue, width: 4,
            patterns: [PatternItem.dash(20), PatternItem.gap(10)]
          )
        };
      });
      _fitMapToRoute();
    }
  }

  @override
  Widget build(BuildContext context) {
    const panelBg = JT.surface;
    const cardBg = JT.bgSoft;
    const textMain = JT.textPrimary;
    const borderCol = JT.border;
    return Scaffold(
      backgroundColor: JT.bg,
      body: Stack(children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(target: _pickupLatLng, zoom: 13),
          onMapCreated: (c) {
            _mapController = c;
            _fitMapToRoute();
          },
          markers: {
            Marker(markerId: const MarkerId('pickup'), position: _pickupLatLng,
              infoWindow: InfoWindow(title: 'Pickup', snippet: widget.pickup),
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure)),
            Marker(markerId: const MarkerId('dest'), position: _destLatLng,
              infoWindow: InfoWindow(title: 'Drop', snippet: widget.destination),
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue)),
          },
          polylines: _polylines,
          zoomControlsEnabled: false, mapToolbarEnabled: false,
          myLocationEnabled: true, myLocationButtonEnabled: false,
        ),

        // Floating Top Bar matching image
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF7FAFF), // Very soft lavender/white
                borderRadius: BorderRadius.circular(30),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Color(0xFF1E293B)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(text: _shortLocation(widget.pickup), style: const TextStyle(fontWeight: FontWeight.w400, color: Color(0xFF475569), fontSize: 14)),
                          const WidgetSpan(child: Padding(padding: EdgeInsets.symmetric(horizontal: 6), child: Icon(Icons.arrow_forward_rounded, size: 14, color: Color(0xFF64748B)))),
                          TextSpan(text: _shortLocation(widget.destination), style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF1E293B), fontSize: 15)),
                        ],
                      ),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(color: Color(0xFFE9D5FF), shape: BoxShape.circle),
                    child: const Icon(Icons.location_on_rounded, color: Color(0xFF7C3AED), size: 16),
                  ),
                ],
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
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 24, offset: const Offset(0, -4))],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(top: 12, bottom: 8),
                  decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(2)))),

                // Vehicle selector (Scrollable)
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: _buildVehicleSelector(),
                  ),
                ),

                // Payment and Booking Row
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), offset: const Offset(0, -4), blurRadius: 10)],
                  ),
                  child: Column(
                    children: [
                      // Payment Methods
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Payment Method', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
                          Row(
                            children: [
                              _payBtn('cash', Icons.payments_rounded, 'Cash'),
                              const SizedBox(width: 8),
                              _payBtn('upi', Icons.qr_code_scanner_rounded, 'UPI'),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Big Book Button
                      GestureDetector(
                        onTap: _loading || _estimating || _allFares.isEmpty ? null : _goToRideForWhomScreen,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: double.infinity,
                          height: 52,
                          decoration: BoxDecoration(
                            color: const Color(0xFF6366F1), // vibrant indigo
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                               BoxShadow(color: const Color(0xFF6366F1).withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4)),
                            ],
                          ),
                          child: Center(
                            child: _loading 
                               ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                               : Text('Confirm Ride', style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: Colors.white)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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

  Widget _buildPaymentSection() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Payment Method',
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF374151), letterSpacing: 0.2)),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: _payBtn('cash', Icons.payments_rounded, 'Cash')),
        const SizedBox(width: 8),
        Expanded(child: _payBtn('wallet', Icons.account_balance_wallet_rounded, 'Wallet')),
        const SizedBox(width: 8),
        Expanded(child: _payBtn('upi', Icons.qr_code_scanner_rounded, 'UPI')),
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
                fontSize: 12, fontWeight: FontWeight.w400,
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
              style: TextStyle(fontSize: 12, color: JT.primary, fontWeight: FontWeight.w500),
            )),
          ]),
        ),
      ],
    ]);
  }

  Widget _payBtn(String method, IconData icon, String label) {
    final selected = _paymentMethod == method;
    const unselBorder = Color(0xFFE2E8F0);
    const selBorder = Color(0xFF7C3AED);
    const selText = Color(0xFF7C3AED);
    const unselText = Color(0xFF64748B);
    
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _paymentMethod = method);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFF3E8FF) : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: selected ? selBorder : unselBorder,
            width: 1,
          ),
          boxShadow: selected ? [BoxShadow(color: selBorder.withValues(alpha: 0.1), blurRadius: 8)] : [],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 14, color: selected ? selText : unselText),
          const SizedBox(width: 6),
          Text(label, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: selected ? selText : unselText)),
        ]),
      ),
    );
  }

  Widget _addressRow(IconData icon, Color color, String text, [Color? textColor]) {
    final tColor = textColor ?? JT.textPrimary;
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
            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w500, color: color.withValues(alpha: 0.8), letterSpacing: 0.8)),
          const SizedBox(height: 2),
          Text(text,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: tColor),
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
          color: JT.surfaceAlt, borderRadius: BorderRadius.circular(12),
          border: Border.all(color: JT.border)),
        child: Row(children: [
          const Text('🌙', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(child: Text('Night charges apply (10PM - 6AM)',
            style: TextStyle(color: JT.textPrimary, fontSize: 13, fontWeight: FontWeight.w400))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: JT.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: Text('1.25x', style: TextStyle(color: JT.primary, fontSize: 12, fontWeight: FontWeight.w400)),
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
        color = const Color(0xFF7C3AED); // Premium Purple matching image
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
        Text(tag, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w500, letterSpacing: 0.5)),
      ]),
    );
  }

  void _fitMapToRoute({List<LatLng>? routePoints}) {
    if (_mapController == null) return;
    Future.delayed(const Duration(milliseconds: 300), () {
      double minLat, maxLat, minLng, maxLng;
      
      if (routePoints != null && routePoints.isNotEmpty) {
        minLat = maxLat = routePoints.first.latitude;
        minLng = maxLng = routePoints.first.longitude;
        for (final p in routePoints) {
          if (p.latitude < minLat) minLat = p.latitude;
          if (p.latitude > maxLat) maxLat = p.latitude;
          if (p.longitude < minLng) minLng = p.longitude;
          if (p.longitude > maxLng) maxLng = p.longitude;
        }
      } else {
        final pLat = _pickupLatLng.latitude;
        final pLng = _pickupLatLng.longitude;
        final dLat = widget.destLat != 0 ? widget.destLat : pLat + 0.005;
        final dLng = widget.destLng != 0 ? widget.destLng : pLng + 0.005;
        minLat = min(pLat, dLat);
        maxLat = max(pLat, dLat);
        minLng = min(pLng, dLng);
        maxLng = max(pLng, dLng);
      }

      try {
        _mapController?.animateCamera(CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(minLat, minLng),
            northeast: LatLng(maxLat, maxLng),
          ),
          90, // Significant visual padding for the route
        ));
      } catch (_) {}
    });
  }

  Widget _buildVehicleSelector() {
    if (_estimating) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Shimmer.fromColors(
          baseColor: const Color(0xFFE5E7EB),
          highlightColor: const Color(0xFFF3F4F6),
          child: Column(children: List.generate(3, (_) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(height: 70, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16))),
          ))),
        ),
      );
    }
    if (_allFares.isEmpty && !_estimating) return const SizedBox.shrink();

    return Column(
      children: _allFares.asMap().entries.map((entry) {
        final i = entry.key;
        final f = entry.value;
        final isSelected = i == _selectedFareIndex;
        final name = f['vehicleCategoryName']?.toString() ?? f['vehicleName']?.toString() ?? f['name']?.toString() ?? 'Bike';
        final fareVal = (f['estimatedFare'] ?? 0).toDouble();
        final time = f['estimatedTime']?.toString() ?? '~5 min';
        final displayFare = isSelected ? (fareVal - _promoDiscount).clamp(0.0, double.infinity) : fareVal;
        
        final etaMins = _etaMins(time);
        final dropTime = _dropTimeStr(time);
        final tag = _getVehicleTag(i);
        final isFastest = tag == 'FASTEST';
        final isPremium = name.toLowerCase().contains('premium') || tag == 'PREMIUM';
        
        final subtitle = '$etaMins min • Drop $dropTime';

        // Styling matches the image exactly.
        final cardBgColor = isSelected ? const Color(0xFFF3E8FF) : Colors.transparent;
        final cardBorderColor = isSelected ? const Color(0xFFE9D5FF) : Colors.transparent;
        
        return GestureDetector(
          key: ValueKey(i),
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _selectedFareIndex = i);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.fromLTRB(8, 6, 16, 6),
            decoration: BoxDecoration(
              color: cardBgColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cardBorderColor),
            ),
            child: Row(
              children: [
                // Vehicle image with optional selection badge overlay
                SizedBox(
                  width: 66, height: 44,
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      // Car image placeholder or network image
                      Builder(builder: (_) {
                        final imgKey = _vehicleImageKey(name);
                        final imgUrl = imgKey != null ? _vehicleImageUrls[imgKey] : null;
                        return imgUrl != null 
                            ? Image.network(imgUrl, fit: BoxFit.contain, width: 52)
                            : Text(_emojiForVehicle(name), style: const TextStyle(fontSize: 32));
                      }),
                      if (isSelected)
                        Positioned(
                          left: -4, bottom: -4,
                          child: Container(
                            width: 18, height: 18,
                            decoration: const BoxDecoration(
                              color: Color(0xFF7C3AED), // vibrant purple badge
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.check_rounded, color: Colors.white, size: 12),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                
                // Name & Subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: RichText(
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: name,
                                    style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B)),
                                  ),
                                  if (isFastest)
                                    WidgetSpan(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        margin: const EdgeInsets.only(left: 6),
                                        decoration: BoxDecoration(color: const Color(0xFFF3E8FF), borderRadius: BorderRadius.circular(4)),
                                        child: const Text('FASTEST', style: TextStyle(color: Color(0xFF7C3AED), fontSize: 9, fontWeight: FontWeight.w700)),
                                      ),
                                    ),
                                  if (isSelected) 
                                    TextSpan(
                                      text: ' • $subtitle', 
                                      style: const TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w400),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          if (tag == 'FASTEST') ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF3E8FF),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text('FASTEST', style: TextStyle(color: Color(0xFF7C3AED), fontSize: 9, fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(subtitle, style: const TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w400)),
                    ],
                  ),
                ),
                
                // Price
                Text('₹${displayFare.toStringAsFixed(0)}', style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF1E293B),
                )),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFareBreakdown(Map<String, dynamic> fare) {
    const cardBg = Color(0xFFF8FAFF);
    const borderCol = Color(0xFFE8EFFF);
    const textMain = JT.textPrimary;
    final textSub = Colors.grey.shade600;

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
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w400, color: _jagoPrimary)),
            const Spacer(),
            if (isMinFareApplied)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: JT.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: JT.primary.withValues(alpha: 0.3)),
                ),
                child: const Text('Min fare', style: TextStyle(
                  fontSize: 10, color: JT.primary, fontWeight: FontWeight.w400)),
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
                  fontSize: 10, color: Color(0xFF8B5CF6), fontWeight: FontWeight.w400)),
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
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF10B981))),
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
                Text('Total Fare', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: textMain)),
                if (minFare > 0 && isMinFareApplied)
                  Text('Min fare applied', style: TextStyle(fontSize: 10, color: Colors.grey[400])),
              ]),
              const Spacer(),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('₹${_finalFare.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w500, color: _jagoPrimary)),
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
          fontWeight: bold ? FontWeight.w500 : FontWeight.w500,
          color: positive ? _green : sub)),
      ]),
    );
  }

  Widget _buildPromoRow() {
    const cardBg = Color(0xFFF8FAFF);
    const borderCol = Color(0xFFE2E8F0);
    const textColor = JT.textPrimary;
    if (_appliedPromo != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF0FDF4),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF86EFAC))),
        child: Row(children: [
          const Icon(Icons.local_offer_rounded, color: Color(0xFF16A34A), size: 18),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('$_appliedPromo applied!',
              style: const TextStyle(fontWeight: FontWeight.w500, color: Color(0xFF16A34A), fontSize: 13)),
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
              onChanged: _onCouponChanged,
              decoration: InputDecoration(
                hintText: 'Promo code',
                border: InputBorder.none, isDense: true,
                hintStyle: const TextStyle(fontSize: 13, color: Color(0xFFADB5BD))),
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, letterSpacing: 1.5, color: textColor),
            ),
          ),
          GestureDetector(
            onTap: _promoLoading ? null : _applyPromo,
            child: _promoLoading
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: _jagoPrimary))
              : const Text('APPLY', style: TextStyle(color: _jagoPrimary, fontSize: 13, fontWeight: FontWeight.w400)),
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
