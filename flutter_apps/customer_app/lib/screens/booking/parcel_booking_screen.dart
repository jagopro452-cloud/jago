import 'dart:math';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import '../../config/jago_theme.dart';
import '../../services/auth_service.dart';
import '../tracking/tracking_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// JAGO Logistics — Porter-style parcel booking screen
// Vehicles: Bike Parcel (≤10 kg) · Mini Truck / Tata Ace (≤500 kg) · Pickup Truck (≤2000 kg)
// ─────────────────────────────────────────────────────────────────────────────

class ParcelBookingScreen extends StatefulWidget {
  final String pickupAddress;
  final double pickupLat;
  final double pickupLng;
  final String? initialVehicleKey;
  const ParcelBookingScreen({
    super.key,
    this.pickupAddress = 'Getting location...',
    this.pickupLat = 17.3850,
    this.pickupLng = 78.4867,
    this.initialVehicleKey,
  });
  @override
  State<ParcelBookingScreen> createState() => _ParcelBookingScreenState();
}

// ── Static vehicle catalogue ──────────────────────────────────────────────────
class _ParcelVehicle {
  final String key;
  final String name;
  final String subtitle;
  final String icon;
  final String capacity;
  final int maxKg;
  final String suitable;
  final Color accentColor;
  const _ParcelVehicle({
    required this.key, required this.name, required this.subtitle,
    required this.icon, required this.capacity, required this.maxKg,
    required this.suitable, required this.accentColor,
  });
}

const _kVehicles = [
  _ParcelVehicle(
    key: 'bike_parcel', name: 'Bike Parcel', subtitle: 'Fast & lightweight',
    icon: '🏍️', capacity: 'Up to 10 kg', maxKg: 10,
    suitable: 'Documents · Small boxes · Groceries · Medicine',
    accentColor: Color(0xFF2F7BFF),
  ),
  _ParcelVehicle(
    key: 'tata_ace', name: 'Mini Truck', subtitle: 'Tata Ace · Medium goods',
    icon: '🚛', capacity: 'Up to 500 kg', maxKg: 500,
    suitable: 'Furniture · Appliances · Bulk items · Shop stock',
    accentColor: Color(0xFFFF6B35),
  ),
  _ParcelVehicle(
    key: 'pickup_truck', name: 'Pickup Truck', subtitle: 'Heavy goods & business',
    icon: '🛻', capacity: 'Up to 2,000 kg', maxKg: 2000,
    suitable: 'Heavy machinery · Construction · Business logistics',
    accentColor: Color(0xFF7C3AED),
  ),
];

// ── Static item types ─────────────────────────────────────────────────────────
const _kItemTypes = [
  {'icon': '📄', 'label': 'Documents'},
  {'icon': '👕', 'label': 'Clothing'},
  {'icon': '📱', 'label': 'Electronics'},
  {'icon': '🛒', 'label': 'Groceries'},
  {'icon': '🪑', 'label': 'Furniture'},
  {'icon': '💊', 'label': 'Medicine'},
  {'icon': '🏺', 'label': 'Fragile'},
  {'icon': '📦', 'label': 'Other'},
];

// ── Static weight options ─────────────────────────────────────────────────────
const _kWeightOptions = [
  {'label': '< 1 kg',  'value': 0.5,  'desc': 'Envelopes, documents'},
  {'label': '1–5 kg',  'value': 3.0,  'desc': 'Small parcel'},
  {'label': '5–10 kg', 'value': 7.5,  'desc': 'Medium box'},
  {'label': '10–50 kg','value': 30.0, 'desc': 'Furniture part / appliance'},
  {'label': '50–200 kg','value':125.0,'desc': 'Bulk goods'},
  {'label': '200+ kg', 'value': 400.0,'desc': 'Heavy / commercial load'},
];

// ── Prohibited items ─────────────────────────────────────────────────────────
const _kProhibited = ['Weapons & ammunition', 'Drugs & narcotics',
  'Explosives', 'Hazardous chemicals', 'Counterfeit goods', 'Illegal items'];

// ─────────────────────────────────────────────────────────────────────────────

class _ParcelBookingScreenState extends State<ParcelBookingScreen>
    with SingleTickerProviderStateMixin {

  // Controllers
  final _dropAddressCtrl    = TextEditingController();
  final _receiverNameCtrl   = TextEditingController();
  final _receiverPhoneCtrl  = TextEditingController();
  final _instructionsCtrl   = TextEditingController();
  final _descCtrl           = TextEditingController();

  // Step (0=vehicle, 1=locations, 2=package, 3=confirm)
  int _step = 0;

  // Selections
  int _vehicleIdx = 0;
  String? _itemType;
  int _weightIdx = 0;
  bool _safetyAgreed = false;

  // Dynamic vehicles from backend (overrides _kVehicles when loaded)
  List<_ParcelVehicle> _dynamicVehicles = [];

  // Drop location
  double _destLat = 0, _destLng = 0;
  List<Map<String, dynamic>> _suggestions = [];
  Timer? _debounce;
  bool _searchingDrop = false;

  // Fare estimate
  Map<String, dynamic>? _estimate;
  bool _estimating = false;

  // Booking
  bool _booking = false;

  late PageController _pageCtrl;

  List<_ParcelVehicle> get _vehicles => _dynamicVehicles.isNotEmpty ? _dynamicVehicles : _kVehicles;

  @override
  void initState() {
    super.initState();
    _fetchDynamicVehicles();
    if (widget.initialVehicleKey != null) {
      final idx = _kVehicles.indexWhere((v) => v.key == widget.initialVehicleKey);
      if (idx >= 0) _vehicleIdx = idx;
    }
    _pageCtrl = PageController();
  }

  Future<void> _fetchDynamicVehicles() async {
    try {
      final uri = Uri.parse(ApiConfig.parcelVehicles).replace(queryParameters: {
        'lat': widget.pickupLat.toString(),
        'lng': widget.pickupLng.toString(),
      });
      final r = await http.get(uri);
      if (r.statusCode == 200) {
        final data = jsonDecode(r.body) as Map<String, dynamic>;
        final list = (data['vehicles'] as List<dynamic>?) ?? [];
        final parsed = list.map<_ParcelVehicle>((v) {
          final m = v as Map<String, dynamic>;
          final colorStr = m['color']?.toString() ?? '#2F7BFF';
          final colorVal = int.tryParse(colorStr.replaceFirst('#', '0xFF')) ?? 0xFF2F7BFF;
          return _ParcelVehicle(
            key: m['vehicle_key']?.toString() ?? '',
            name: m['display_name']?.toString() ?? m['vehicle_key']?.toString() ?? '',
            subtitle: m['description']?.toString() ?? '',
            icon: m['icon']?.toString() ?? '📦',
            capacity: 'Up to ${m['max_weight_kg'] ?? 10} kg',
            maxKg: (m['max_weight_kg'] as num?)?.toInt() ?? 10,
            suitable: m['suitable_items']?.toString() ?? '',
            accentColor: Color(colorVal),
          );
        }).toList();
        if (mounted && parsed.isNotEmpty) {
          setState(() => _dynamicVehicles = parsed);
          // Re-align initial vehicle selection
          if (widget.initialVehicleKey != null) {
            final idx = _dynamicVehicles.indexWhere((v) => v.key == widget.initialVehicleKey);
            if (idx >= 0) setState(() => _vehicleIdx = idx);
          }
        }
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _dropAddressCtrl.dispose();
    _receiverNameCtrl.dispose();
    _receiverPhoneCtrl.dispose();
    _instructionsCtrl.dispose();
    _descCtrl.dispose();
    _debounce?.cancel();
    _pageCtrl.dispose();
    super.dispose();
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  _ParcelVehicle get _vehicle => _vehicles[_vehicleIdx];
  double get _weightKg => (_kWeightOptions[_weightIdx]['value'] as num).toDouble();

  bool get _step0Valid => true;
  bool get _step1Valid => _dropAddressCtrl.text.trim().isNotEmpty && _destLat != 0;
  bool get _step2Valid => _itemType != null && _safetyAgreed;
  bool get _step3Valid => _receiverNameCtrl.text.trim().isNotEmpty &&
      _receiverPhoneCtrl.text.trim().length == 10;

  void _next() {
    if (_step < 3) {
      setState(() => _step++);
      _pageCtrl.animateToPage(_step,
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      if (_step == 3) _fetchEstimate();
    }
  }

  void _back() {
    if (_step > 0) {
      setState(() => _step--);
      _pageCtrl.animateToPage(_step,
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      Navigator.pop(context);
    }
  }

  bool get _canNext {
    switch (_step) {
      case 0: return _step0Valid;
      case 1: return _step1Valid;
      case 2: return _step2Valid;
      case 3: return _step3Valid;
      default: return false;
    }
  }

  // ── Drop address search ───────────────────────────────────────────────────────

  void _onDropSearch(String q) {
    _debounce?.cancel();
    if (q.length < 3) { setState(() => _suggestions = []); return; }
    _debounce = Timer(const Duration(milliseconds: 400), () => _searchAddress(q));
  }

  Future<void> _searchAddress(String q) async {
    setState(() => _searchingDrop = true);
    try {
      final headers = await AuthService.getHeaders();
      final r = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/app/places/autocomplete?input=${Uri.encodeComponent(q)}'),
        headers: headers,
      ).timeout(const Duration(seconds: 6));
      if (r.statusCode == 200) {
        final body = jsonDecode(r.body);
        final list = (body['predictions'] ?? body['results'] ?? body) as List;
        if (mounted) setState(() {
          _suggestions = list.map<Map<String, dynamic>>((p) => {
            'description': p['description'] ?? p['formatted_address'] ?? p['name'] ?? '',
            'place_id': p['place_id'] ?? '',
            'lat': (p['lat'] ?? p['geometry']?['location']?['lat'] ?? 0).toDouble(),
            'lng': (p['lng'] ?? p['geometry']?['location']?['lng'] ?? 0).toDouble(),
          }).toList();
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _searchingDrop = false);
  }

  void _selectSuggestion(Map<String, dynamic> s) async {
    final desc = s['description'] as String;
    setState(() {
      _dropAddressCtrl.text = desc;
      _destLat = (s['lat'] as num).toDouble();
      _destLng = (s['lng'] as num).toDouble();
      _suggestions = [];
    });
    // Resolve lat/lng if not available
    if (_destLat == 0 && s['place_id'] != null && s['place_id'] != '') {
      try {
        final headers = await AuthService.getHeaders();
        final r = await http.get(
          Uri.parse('${ApiConfig.baseUrl}/api/app/places/details?place_id=${s['place_id']}'),
          headers: headers,
        ).timeout(const Duration(seconds: 5));
        if (r.statusCode == 200) {
          final d = jsonDecode(r.body);
          if (mounted) setState(() {
            _destLat = (d['lat'] ?? d['result']?['geometry']?['location']?['lat'] ?? 0).toDouble();
            _destLng = (d['lng'] ?? d['result']?['geometry']?['location']?['lng'] ?? 0).toDouble();
          });
        }
      } catch (_) {}
    }
  }

  // ── Fare estimate ─────────────────────────────────────────────────────────────

  Future<void> _fetchEstimate() async {
    setState(() { _estimating = true; _estimate = null; });
    try {
      // Rough haversine distance
      final dist = _haversine(
        widget.pickupLat, widget.pickupLng, _destLat, _destLng);
      final headers = await AuthService.getHeaders();
      final r = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/app/parcel/quote'),
        headers: {...headers, 'Content-Type': 'application/json'},
        body: jsonEncode({
          'vehicleCategory': _vehicle.key,
          'totalDistanceKm': dist,
          'weightKg': _weightKg,
          'dropLocations': [{'address': _dropAddressCtrl.text}],
        }),
      ).timeout(const Duration(seconds: 8));
      if (r.statusCode == 200 && mounted) {
        setState(() => _estimate = jsonDecode(r.body));
      } else if (r.statusCode == 400 && mounted) {
        final e = jsonDecode(r.body);
        _showSnack(e['message'] ?? 'Weight exceeds vehicle limit', error: true);
        setState(() { _step = 0; });
        _pageCtrl.animateToPage(0, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      }
    } catch (_) {}
    if (mounted) setState(() => _estimating = false);
  }

  double _haversine(double lat1, double lng1, double lat2, double lng2) {
    const r = 6371.0;
    final lat1Rad = lat1 * pi / 180;
    final lat2Rad = lat2 * pi / 180;
    final dLat = (lat2 - lat1) * pi / 180;
    final dLng = (lng2 - lng1) * pi / 180;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1Rad) * cos(lat2Rad) * sin(dLng / 2) * sin(dLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return (r * c * 1.3).clamp(0.5, 200.0);
  }

  // ── Book ─────────────────────────────────────────────────────────────────────

  Future<void> _book() async {
    if (!_step3Valid || _booking) return;
    setState(() => _booking = true);
    try {
      final dist = _haversine(widget.pickupLat, widget.pickupLng, _destLat, _destLng);
      final headers = await AuthService.getHeaders();
      final r = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/app/parcel/book'),
        headers: {...headers, 'Content-Type': 'application/json'},
        body: jsonEncode({
          'vehicleCategory': _vehicle.key,
          'pickupAddress': widget.pickupAddress,
          'pickupLat': widget.pickupLat,
          'pickupLng': widget.pickupLng,
          'pickupContactName': '',
          'pickupContactPhone': '',
          'dropLocations': [{
            'address': _dropAddressCtrl.text,
            'lat': _destLat,
            'lng': _destLng,
            'receiverName': _receiverNameCtrl.text.trim(),
            'receiverPhone': _receiverPhoneCtrl.text.trim(),
          }],
          'totalDistanceKm': dist,
          'weightKg': _weightKg,
          'paymentMethod': 'cash',
          'notes': [
            if (_itemType != null) 'Item: $_itemType',
            if (_descCtrl.text.trim().isNotEmpty) 'Desc: ${_descCtrl.text.trim()}',
            if (_instructionsCtrl.text.trim().isNotEmpty) 'Instructions: ${_instructionsCtrl.text.trim()}',
          ].join(' | '),
        }),
      ).timeout(const Duration(seconds: 12));
      if (!mounted) return;
      if (r.statusCode == 200 || r.statusCode == 201) {
        final data = jsonDecode(r.body);
        final orderId = data['orderId']?.toString() ?? data['id']?.toString() ?? '';
        Navigator.pushReplacement(context, MaterialPageRoute(
          builder: (_) => TrackingScreen(tripId: orderId),
        ));
      } else {
        final e = jsonDecode(r.body);
        _showSnack(e['message'] ?? 'Booking failed. Try again.', error: true);
      }
    } catch (e) {
      _showSnack('Network error. Please try again.', error: true);
    } finally {
      if (mounted) setState(() => _booking = false);
    }
  }

  void _showSnack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(color: Colors.white)),
      backgroundColor: error ? JT.error : JT.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: JT.bg,
      body: Column(children: [
        _buildHeader(),
        _buildStepBar(),
        Expanded(
          child: PageView(
            controller: _pageCtrl,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildStep0Vehicle(),
              _buildStep1Location(),
              _buildStep2Package(),
              _buildStep3Confirm(),
            ],
          ),
        ),
        _buildBottomBar(),
      ]),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(gradient: JT.grad),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 16, 16),
          child: Row(children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: _back,
            ),
            const SizedBox(width: 4),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('JAGO Logistics', style: GoogleFonts.poppins(
                  color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
              Text('Porter-style parcel delivery', style: GoogleFonts.poppins(
                  color: Colors.white70, fontSize: 12)),
            ]),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20)),
              child: Row(children: [
                const Text('📦', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 4),
                Text('Logistics', style: GoogleFonts.poppins(
                    color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  // ── Step bar ──────────────────────────────────────────────────────────────────

  Widget _buildStepBar() {
    const labels = ['Vehicle', 'Location', 'Package', 'Confirm'];
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(children: List.generate(4, (i) {
        final done = i < _step;
        final active = i == _step;
        return Expanded(child: Row(children: [
          Column(children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 28, height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: done ? JT.success : active ? JT.primary : JT.bgSoft,
                border: Border.all(
                  color: done ? JT.success : active ? JT.primary : JT.border,
                  width: 2),
              ),
              child: Center(child: done
                ? const Icon(Icons.check, color: Colors.white, size: 14)
                : Text('${i + 1}', style: GoogleFonts.poppins(
                    color: active ? JT.primary : JT.iconInactive,
                    fontSize: 12, fontWeight: FontWeight.w700))),
            ),
            const SizedBox(height: 4),
            Text(labels[i], style: GoogleFonts.poppins(
                fontSize: 9, fontWeight: FontWeight.w600,
                color: active ? JT.primary : done ? JT.success : JT.iconInactive)),
          ]),
          if (i < 3) Expanded(child: Container(
            height: 2, margin: const EdgeInsets.only(bottom: 18),
            color: done ? JT.success : JT.border)),
        ]));
      })),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // STEP 0 — Vehicle selection
  // ─────────────────────────────────────────────────────────────────────────────

  Widget _buildStep0Vehicle() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Choose Your Vehicle', style: GoogleFonts.poppins(
            fontSize: 20, fontWeight: FontWeight.w800, color: JT.textPrimary)),
        const SizedBox(height: 4),
        Text('Select based on your package size and weight',
            style: GoogleFonts.poppins(fontSize: 13, color: JT.textSecondary)),
        const SizedBox(height: 20),

        // Vehicle cards
        ...List.generate(_vehicles.length, (i) => _buildVehicleCard(i)),

        const SizedBox(height: 24),
        // What is Logistics section
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: JT.bgSoft,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: JT.border)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Text('🚚', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text('About JAGO Logistics', style: GoogleFonts.poppins(
                  fontSize: 14, fontWeight: FontWeight.w700, color: JT.textPrimary)),
            ]),
            const SizedBox(height: 10),
            for (final point in [
              '📍 Door-to-door parcel delivery',
              '🔐 OTP-verified secure pickup & delivery',
              '📡 Live GPS tracking throughout',
              '💰 Transparent pricing, no hidden charges',
            ])
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(point, style: GoogleFonts.poppins(
                    fontSize: 12, color: JT.textSecondary)),
              ),
          ]),
        ),
      ]),
    );
  }

  Widget _buildVehicleCard(int idx) {
    final v = _vehicles[idx];
    final selected = _vehicleIdx == idx;
    return GestureDetector(
      onTap: () => setState(() => _vehicleIdx = idx),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: selected ? v.accentColor.withValues(alpha: 0.06) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: selected ? v.accentColor : JT.border,
              width: selected ? 2 : 1),
          boxShadow: selected ? [
            BoxShadow(color: v.accentColor.withValues(alpha: 0.15),
                blurRadius: 16, offset: const Offset(0, 4))
          ] : [
            BoxShadow(color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8, offset: const Offset(0, 2))
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            // Vehicle icon
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                color: v.accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14)),
              child: Center(child: Text(v.icon,
                  style: const TextStyle(fontSize: 32))),
            ),
            const SizedBox(width: 14),
            // Info
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(v.name, style: GoogleFonts.poppins(
                    fontSize: 15, fontWeight: FontWeight.w800,
                    color: selected ? v.accentColor : JT.textPrimary)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: v.accentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8)),
                  child: Text(v.capacity, style: GoogleFonts.poppins(
                      fontSize: 10, fontWeight: FontWeight.w700,
                      color: v.accentColor)),
                ),
              ]),
              const SizedBox(height: 3),
              Text(v.subtitle, style: GoogleFonts.poppins(
                  fontSize: 12, color: JT.textSecondary)),
              const SizedBox(height: 4),
              Text(v.suitable, style: GoogleFonts.poppins(
                  fontSize: 11, color: JT.iconInactive)),
            ])),
            // Radio
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22, height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? v.accentColor : Colors.transparent,
                border: Border.all(
                    color: selected ? v.accentColor : JT.border, width: 2)),
              child: selected
                  ? const Icon(Icons.check, color: Colors.white, size: 13)
                  : null,
            ),
          ]),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // STEP 1 — Pickup & Drop locations
  // ─────────────────────────────────────────────────────────────────────────────

  Widget _buildStep1Location() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Pickup & Delivery', style: GoogleFonts.poppins(
            fontSize: 20, fontWeight: FontWeight.w800, color: JT.textPrimary)),
        const SizedBox(height: 4),
        Text('Confirm pickup and enter delivery address',
            style: GoogleFonts.poppins(fontSize: 13, color: JT.textSecondary)),
        const SizedBox(height: 20),

        // Pickup (read-only)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: JT.primary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: JT.primary.withValues(alpha: 0.3))),
          child: Row(children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                  color: JT.primary, shape: BoxShape.circle),
              child: const Icon(Icons.my_location, color: Colors.white, size: 18)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('PICKUP LOCATION', style: GoogleFonts.poppins(
                  fontSize: 9, color: JT.primary,
                  fontWeight: FontWeight.w800, letterSpacing: 1.2)),
              const SizedBox(height: 2),
              Text(widget.pickupAddress, style: GoogleFonts.poppins(
                  fontSize: 13, color: JT.textPrimary,
                  fontWeight: FontWeight.w600),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
            ])),
          ]),
        ),

        // Connector
        Padding(
          padding: const EdgeInsets.only(left: 34),
          child: Column(children: List.generate(4, (_) => Container(
              width: 2, height: 6, margin: const EdgeInsets.symmetric(vertical: 2),
              color: JT.border))),
        ),

        // Drop input
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: _destLat != 0 ? JT.success : JT.border),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Column(children: [
            Row(children: [
              const SizedBox(width: 16),
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                    color: _destLat != 0 ? JT.success : JT.border,
                    shape: BoxShape.circle),
                child: Icon(_destLat != 0 ? Icons.check : Icons.location_on_rounded,
                    color: Colors.white, size: 18)),
              const SizedBox(width: 12),
              Expanded(child: TextField(
                controller: _dropAddressCtrl,
                onChanged: _onDropSearch,
                style: GoogleFonts.poppins(fontSize: 13, color: JT.textPrimary,
                    fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  hintText: 'Enter delivery address',
                  hintStyle: GoogleFonts.poppins(
                      color: JT.iconInactive, fontSize: 13),
                  border: InputBorder.none,
                  labelText: 'DELIVERY LOCATION',
                  labelStyle: GoogleFonts.poppins(
                      fontSize: 9, color: _destLat != 0 ? JT.success : JT.textSecondary,
                      fontWeight: FontWeight.w800, letterSpacing: 1.2),
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              )),
              if (_searchingDrop)
                const Padding(
                  padding: EdgeInsets.only(right: 12),
                  child: SizedBox(width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2)),
                )
              else if (_dropAddressCtrl.text.isNotEmpty)
                IconButton(
                  icon: Icon(Icons.close, color: JT.iconInactive, size: 18),
                  onPressed: () => setState(() {
                    _dropAddressCtrl.clear();
                    _destLat = 0; _destLng = 0;
                    _suggestions = [];
                  }),
                ),
            ]),
            // Suggestions
            if (_suggestions.isNotEmpty) ...[
              Divider(color: JT.border, height: 1),
              ..._suggestions.take(5).map((s) => InkWell(
                onTap: () => _selectSuggestion(s),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(children: [
                    Icon(Icons.location_on_outlined, color: JT.textSecondary, size: 18),
                    const SizedBox(width: 10),
                    Expanded(child: Text(s['description'] ?? '',
                        style: GoogleFonts.poppins(fontSize: 13, color: JT.textPrimary),
                        maxLines: 2, overflow: TextOverflow.ellipsis)),
                  ]),
                ),
              )),
            ],
          ]),
        ),

        const SizedBox(height: 20),

        // Vehicle reminder
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _vehicle.accentColor.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _vehicle.accentColor.withValues(alpha: 0.3))),
          child: Row(children: [
            Text(_vehicle.icon, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 10),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_vehicle.name, style: GoogleFonts.poppins(
                  fontSize: 13, fontWeight: FontWeight.w700,
                  color: _vehicle.accentColor)),
              Text(_vehicle.capacity, style: GoogleFonts.poppins(
                  fontSize: 11, color: JT.textSecondary)),
            ]),
          ]),
        ),
      ]),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // STEP 2 — Package details
  // ─────────────────────────────────────────────────────────────────────────────

  Widget _buildStep2Package() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Package Details', style: GoogleFonts.poppins(
            fontSize: 20, fontWeight: FontWeight.w800, color: JT.textPrimary)),
        const SizedBox(height: 4),
        Text('Tell us what you\'re sending',
            style: GoogleFonts.poppins(fontSize: 13, color: JT.textSecondary)),
        const SizedBox(height: 20),

        // Item type grid
        Text('ITEM TYPE', style: GoogleFonts.poppins(
            fontSize: 10, fontWeight: FontWeight.w800,
            color: JT.iconInactive, letterSpacing: 1.5)),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 4, shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 1.0,
          children: _kItemTypes.map((t) {
            final sel = _itemType == t['label'];
            return GestureDetector(
              onTap: () => setState(() => _itemType = t['label'] as String),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                decoration: BoxDecoration(
                  color: sel ? JT.primary.withValues(alpha: 0.1) : JT.bgSoft,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: sel ? JT.primary : JT.border,
                      width: sel ? 2 : 1)),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(t['icon'] as String, style: const TextStyle(fontSize: 22)),
                  const SizedBox(height: 4),
                  Text(t['label'] as String, style: GoogleFonts.poppins(
                      fontSize: 10, fontWeight: FontWeight.w600,
                      color: sel ? JT.primary : JT.textSecondary),
                      textAlign: TextAlign.center),
                ]),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 20),

        // Weight
        Text('WEIGHT RANGE', style: GoogleFonts.poppins(
            fontSize: 10, fontWeight: FontWeight.w800,
            color: JT.iconInactive, letterSpacing: 1.5)),
        const SizedBox(height: 10),
        ...List.generate(_kWeightOptions.length, (i) {
          final w = _kWeightOptions[i];
          final kg = (w['value'] as num).toDouble();
          final overLimit = kg > _vehicle.maxKg;
          final sel = _weightIdx == i;
          return GestureDetector(
            onTap: overLimit ? null : () => setState(() => _weightIdx = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: overLimit ? JT.bgSoft.withValues(alpha: 0.5)
                    : sel ? JT.primary.withValues(alpha: 0.08) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: overLimit ? JT.border.withValues(alpha: 0.5)
                        : sel ? JT.primary : JT.border,
                    width: sel ? 2 : 1)),
              child: Row(children: [
                Icon(Icons.scale_outlined,
                    color: overLimit ? JT.iconInactive
                        : sel ? JT.primary : JT.textSecondary,
                    size: 20),
                const SizedBox(width: 12),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(w['label'] as String, style: GoogleFonts.poppins(
                      fontSize: 13, fontWeight: FontWeight.w700,
                      color: overLimit ? JT.iconInactive
                          : sel ? JT.primary : JT.textPrimary)),
                  Text(w['desc'] as String, style: GoogleFonts.poppins(
                      fontSize: 11, color: JT.iconInactive)),
                ])),
                if (overLimit)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: JT.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8)),
                    child: Text('Exceeds limit', style: GoogleFonts.poppins(
                        fontSize: 10, color: JT.error, fontWeight: FontWeight.w600)),
                  )
                else if (sel)
                  Container(
                    width: 20, height: 20,
                    decoration: BoxDecoration(
                        color: JT.primary, shape: BoxShape.circle),
                    child: const Icon(Icons.check, color: Colors.white, size: 12)),
              ]),
            ),
          );
        }),

        const SizedBox(height: 20),

        // Item description
        Text('ITEM DESCRIPTION (optional)', style: GoogleFonts.poppins(
            fontSize: 10, fontWeight: FontWeight.w800,
            color: JT.iconInactive, letterSpacing: 1.5)),
        const SizedBox(height: 8),
        TextField(
          controller: _descCtrl,
          maxLines: 2,
          style: GoogleFonts.poppins(fontSize: 13, color: JT.textPrimary),
          decoration: InputDecoration(
            hintText: 'e.g. Samsung TV 55 inch, packed in box',
            hintStyle: GoogleFonts.poppins(color: JT.iconInactive, fontSize: 12),
            filled: true, fillColor: JT.bgSoft,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: JT.border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: JT.border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: JT.primary, width: 1.5)),
            contentPadding: const EdgeInsets.all(14),
          ),
        ),

        const SizedBox(height: 20),

        // Special instructions
        Text('SPECIAL INSTRUCTIONS (optional)', style: GoogleFonts.poppins(
            fontSize: 10, fontWeight: FontWeight.w800,
            color: JT.iconInactive, letterSpacing: 1.5)),
        const SizedBox(height: 8),
        TextField(
          controller: _instructionsCtrl,
          maxLines: 2,
          style: GoogleFonts.poppins(fontSize: 13, color: JT.textPrimary),
          decoration: InputDecoration(
            hintText: 'Handle with care · Keep upright · Fragile',
            hintStyle: GoogleFonts.poppins(color: JT.iconInactive, fontSize: 12),
            filled: true, fillColor: JT.bgSoft,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: JT.border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: JT.border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: JT.primary, width: 1.5)),
            contentPadding: const EdgeInsets.all(14),
          ),
        ),

        const SizedBox(height: 20),

        // Safety confirmation
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _safetyAgreed
                ? JT.success.withValues(alpha: 0.06)
                : JT.error.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: _safetyAgreed ? JT.success : JT.error.withValues(alpha: 0.3))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Text('🚫', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Text('Prohibited Items', style: GoogleFonts.poppins(
                  fontSize: 13, fontWeight: FontWeight.w700, color: JT.error)),
            ]),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 6, children: _kProhibited.map((p) =>
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: JT.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8)),
                child: Text(p, style: GoogleFonts.poppins(
                    fontSize: 11, color: JT.error)),
              )
            ).toList()),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => setState(() => _safetyAgreed = !_safetyAgreed),
              child: Row(children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 22, height: 22,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    color: _safetyAgreed ? JT.success : Colors.transparent,
                    border: Border.all(
                        color: _safetyAgreed ? JT.success : JT.border, width: 2)),
                  child: _safetyAgreed
                      ? const Icon(Icons.check, color: Colors.white, size: 14)
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(
                  'I confirm my parcel does not contain any prohibited items',
                  style: GoogleFonts.poppins(fontSize: 12,
                      color: JT.textSecondary, fontWeight: FontWeight.w500))),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 20),
      ]),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // STEP 3 — Confirm & pay
  // ─────────────────────────────────────────────────────────────────────────────

  Widget _buildStep3Confirm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Confirm Booking', style: GoogleFonts.poppins(
            fontSize: 20, fontWeight: FontWeight.w800, color: JT.textPrimary)),
        const SizedBox(height: 4),
        Text('Enter receiver details and review your order',
            style: GoogleFonts.poppins(fontSize: 13, color: JT.textSecondary)),
        const SizedBox(height: 20),

        // Receiver details
        Text('RECEIVER DETAILS', style: GoogleFonts.poppins(
            fontSize: 10, fontWeight: FontWeight.w800,
            color: JT.iconInactive, letterSpacing: 1.5)),
        const SizedBox(height: 10),
        _inputField(_receiverNameCtrl, 'Receiver Name',
            Icons.person_outline_rounded, TextInputType.text),
        const SizedBox(height: 10),
        _inputField(_receiverPhoneCtrl, 'Receiver Phone (10 digits)',
            Icons.phone_outlined, TextInputType.phone,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10)]),

        const SizedBox(height: 24),

        // Order summary
        Text('ORDER SUMMARY', style: GoogleFonts.poppins(
            fontSize: 10, fontWeight: FontWeight.w800,
            color: JT.iconInactive, letterSpacing: 1.5)),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(16),
            border: Border.all(color: JT.border),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8)]),
          child: Column(children: [
            // Vehicle row
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                Text(_vehicle.icon, style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(_vehicle.name, style: GoogleFonts.poppins(
                      fontSize: 15, fontWeight: FontWeight.w800, color: JT.textPrimary)),
                  Text(_vehicle.capacity, style: GoogleFonts.poppins(
                      fontSize: 12, color: JT.textSecondary)),
                ])),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _vehicle.accentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8)),
                  child: Text(_vehicle.subtitle, style: GoogleFonts.poppins(
                      fontSize: 10, color: _vehicle.accentColor,
                      fontWeight: FontWeight.w700)),
                ),
              ]),
            ),
            Divider(color: JT.border, height: 1),
            // Route
            _summaryRow(Icons.trip_origin, 'Pickup', widget.pickupAddress,
                color: JT.primary),
            _summaryRow(Icons.location_on_outlined, 'Delivery',
                _dropAddressCtrl.text, color: JT.error),
            Divider(color: JT.border, height: 1),
            _summaryRow(Icons.inventory_2_outlined, 'Item Type',
                _itemType ?? '-'),
            _summaryRow(Icons.scale_outlined, 'Weight',
                _kWeightOptions[_weightIdx]['label'] as String),
            if (_instructionsCtrl.text.trim().isNotEmpty)
              _summaryRow(Icons.info_outline_rounded, 'Instructions',
                  _instructionsCtrl.text.trim()),
          ]),
        ),

        const SizedBox(height: 20),

        // Fare breakdown
        _estimating
            ? Center(child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 12),
                  Text('Calculating fare...', style: GoogleFonts.poppins(
                      color: JT.textSecondary, fontSize: 13)),
                ])))
            : _estimate != null
                ? _buildFareCard()
                : const SizedBox(),

        const SizedBox(height: 20),

        // Payment method
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: JT.bgSoft, borderRadius: BorderRadius.circular(14),
            border: Border.all(color: JT.border)),
          child: Row(children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                  color: JT.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(Icons.payments_outlined, color: JT.success, size: 22)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Cash on Delivery', style: GoogleFonts.poppins(
                  fontSize: 14, fontWeight: FontWeight.w700, color: JT.textPrimary)),
              Text('Pay driver after delivery', style: GoogleFonts.poppins(
                  fontSize: 11, color: JT.textSecondary)),
            ])),
            Icon(Icons.check_circle, color: JT.success),
          ]),
        ),

        const SizedBox(height: 24),
      ]),
    );
  }

  Widget _inputField(TextEditingController ctrl, String hint,
      IconData icon, TextInputType type,
      {List<TextInputFormatter>? inputFormatters}) {
    return TextField(
      controller: ctrl,
      keyboardType: type,
      inputFormatters: inputFormatters,
      onChanged: (_) => setState(() {}),
      style: GoogleFonts.poppins(fontSize: 14, color: JT.textPrimary,
          fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(color: JT.iconInactive, fontSize: 13),
        prefixIcon: Icon(icon, color: JT.textSecondary, size: 20),
        filled: true, fillColor: JT.bgSoft,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: JT.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: JT.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: JT.primary, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _summaryRow(IconData icon, String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(children: [
        Icon(icon, size: 18, color: color ?? JT.textSecondary),
        const SizedBox(width: 10),
        Text(label, style: GoogleFonts.poppins(
            fontSize: 12, color: JT.textSecondary)),
        const SizedBox(width: 8),
        Expanded(child: Text(value, style: GoogleFonts.poppins(
            fontSize: 12, fontWeight: FontWeight.w700,
            color: color ?? JT.textPrimary),
            textAlign: TextAlign.right,
            maxLines: 2, overflow: TextOverflow.ellipsis)),
      ]),
    );
  }

  Widget _buildFareCard() {
    final e = _estimate!;
    final total = (e['totalFare'] ?? 0) as num;
    final base  = (e['baseFare'] ?? 0) as num;
    final dist  = (e['distanceFare'] ?? 0) as num;
    final wt    = (e['weightFare'] ?? 0) as num;
    final load  = (e['loadCharge'] ?? 0) as num;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_vehicle.accentColor.withValues(alpha: 0.08),
              _vehicle.accentColor.withValues(alpha: 0.02)],
          begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _vehicle.accentColor.withValues(alpha: 0.3))),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(children: [
            Icon(Icons.receipt_long_outlined, color: _vehicle.accentColor, size: 18),
            const SizedBox(width: 8),
            Text('FARE BREAKDOWN', style: GoogleFonts.poppins(
                fontSize: 10, fontWeight: FontWeight.w800,
                color: _vehicle.accentColor, letterSpacing: 1.2)),
          ]),
        ),
        _fareRow('Base Fare', '₹$base'),
        _fareRow('Distance Charge', '₹$dist'),
        _fareRow('Weight Charge', '₹$wt'),
        if (load > 0) _fareRow('Load Charge', '₹$load'),
        Divider(color: _vehicle.accentColor.withValues(alpha: 0.2), height: 1),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Text('TOTAL', style: GoogleFonts.poppins(
                fontSize: 14, fontWeight: FontWeight.w900, color: JT.textPrimary)),
            const Spacer(),
            Text('₹$total', style: GoogleFonts.poppins(
                fontSize: 22, fontWeight: FontWeight.w900,
                color: _vehicle.accentColor)),
          ]),
        ),
      ]),
    );
  }

  Widget _fareRow(String label, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(children: [
        Text(label, style: GoogleFonts.poppins(fontSize: 13, color: JT.textSecondary)),
        const Spacer(),
        Text(val, style: GoogleFonts.poppins(
            fontSize: 13, fontWeight: FontWeight.w700, color: JT.textPrimary)),
      ]),
    );
  }

  // ── Bottom bar ────────────────────────────────────────────────────────────────

  Widget _buildBottomBar() {
    String btnLabel;
    switch (_step) {
      case 0: btnLabel = 'Select ${_vehicle.name}'; break;
      case 1: btnLabel = 'Add Package Details'; break;
      case 2: btnLabel = 'Review & Confirm'; break;
      case 3: btnLabel = 'Book Delivery'; break;
      default: btnLabel = 'Next';
    }

    final isLastStep = _step == 3;
    final enabled = _canNext && !_booking;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20, offset: const Offset(0, -4))]),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: Row(children: [
            if (_step > 0)
              GestureDetector(
                onTap: _back,
                child: Container(
                  width: 48, height: 52,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: JT.bgSoft, borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: JT.border)),
                  child: Icon(Icons.arrow_back_rounded,
                      color: JT.textSecondary, size: 22),
                ),
              ),
            Expanded(
              child: GestureDetector(
                onTap: enabled
                    ? (isLastStep ? _book : _next)
                    : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: enabled ? JT.grad : null,
                    color: enabled ? null : JT.bgSoft,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: enabled ? JT.btnShadow : [],
                  ),
                  child: Center(
                    child: _booking
                        ? const SizedBox(width: 22, height: 22,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : Row(mainAxisSize: MainAxisSize.min, children: [
                            Text(btnLabel, style: GoogleFonts.poppins(
                                fontSize: 15, fontWeight: FontWeight.w800,
                                color: enabled ? Colors.white : JT.iconInactive)),
                            if (enabled) ...[
                              const SizedBox(width: 8),
                              Icon(isLastStep
                                  ? Icons.local_shipping_rounded
                                  : Icons.arrow_forward_rounded,
                                  color: Colors.white, size: 18),
                            ],
                          ]),
                  ),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
