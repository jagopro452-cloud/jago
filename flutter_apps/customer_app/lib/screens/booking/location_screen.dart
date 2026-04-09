import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/api_config.dart';
import '../../config/jago_theme.dart';
import '../../services/auth_service.dart';
import 'booking_screen.dart';
import 'map_location_picker.dart';

// ─────────────────────────────────────────────────────────────────────────────
// JAGO Pro — Full-Screen Location Picker
// Rule 1: Location ALWAYS comes before vehicle selection.
// Rule 7: Pickup auto-detect · Drop auto-focus · Map pick · Add stop · Suggestions
// ─────────────────────────────────────────────────────────────────────────────

class LocationScreen extends StatefulWidget {
  final String serviceType; // 'ride' or 'parcel'
  final String? pickupAddress;
  final double pickupLat;
  final double pickupLng;
  final String? vehicleCategoryId;
  final String? vehicleCategoryName;

  const LocationScreen({
    super.key,
    required this.serviceType,
    this.pickupAddress,
    this.pickupLat = 0.0,
    this.pickupLng = 0.0,
    this.vehicleCategoryId,
    this.vehicleCategoryName,
  });

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen>
    with TickerProviderStateMixin {
  // ── Controllers ──────────────────────────────────────────────────────────
  final _dropCtrl = TextEditingController();
  final _stopCtrl = TextEditingController();
  final FocusNode _dropFocus = FocusNode();
  final FocusNode _stopFocus = FocusNode();

  // ── State ─────────────────────────────────────────────────────────────────
  String _pickup = '';
  double _pickupLat = 0.0;
  double _pickupLng = 0.0;

  String _drop = '';
  double _dropLat = 0.0;
  double _dropLng = 0.0;

  bool _showStop = false;
  String _stop = '';
  double _stopLat = 0.0;
  double _stopLng = 0.0;

  bool _detectingLocation = false;
  List<Map<String, dynamic>> _searchResults = [];
  List<Map<String, dynamic>> _recent = [];
  List<Map<String, dynamic>> _popular = [];
  bool _searching = false;
  bool _activeField = false; // true = editing drop, false = editing stop
  String _activeQuery = '';
  Timer? _debounce;

  // ── Animation ─────────────────────────────────────────────────────────────
  late AnimationController _slideCtrl;
  late Animation<Offset> _slideAnim;

  // ── Theme ─────────────────────────────────────────────────────────────────
  bool get _isParcel => widget.serviceType == 'parcel';
  Color get _accent => _isParcel ? const Color(0xFFEA580C) : JT.primary;
  Color get _accentLight =>
      _isParcel ? const Color(0xFFFFF7ED) : const Color(0xFFF0F7FF);

  @override
  void initState() {
    super.initState();
    _pickup = widget.pickupAddress ?? '';
    _pickupLat = widget.pickupLat;
    _pickupLng = widget.pickupLng;

    _slideCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
    _slideAnim = Tween<Offset>(
            begin: const Offset(0, 0.4), end: Offset.zero)
        .animate(
            CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOutCubic));
    _slideCtrl.forward();

    _loadRecent();
    _fetchPopular();
    if (_pickup.isEmpty) _detectLocation();

    // Auto-focus drop field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _dropFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _dropCtrl.dispose();
    _stopCtrl.dispose();
    _dropFocus.dispose();
    _stopFocus.dispose();
    _debounce?.cancel();
    _slideCtrl.dispose();
    super.dispose();
  }

  // ── Location Detection ────────────────────────────────────────────────────
  Future<void> _detectLocation() async {
    setState(() => _detectingLocation = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (!serviceEnabled) {
        if (lastKnown != null) {
          final addr = await _reverseGeocode(lastKnown.latitude, lastKnown.longitude);
          if (!mounted) return;
          setState(() {
            _pickup = addr;
            _pickupLat = lastKnown.latitude;
            _pickupLng = lastKnown.longitude;
          });
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Turn on location services to detect your pickup point.')),
          );
        }
        return;
      }

      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission is required to detect your current location.')),
          );
        }
        return;
      }
      if (perm == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission is blocked. Enable it from app settings.')),
          );
        }
        await Geolocator.openAppSettings();
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 8),
          ));
      final addr = await _reverseGeocode(pos.latitude, pos.longitude);
      if (!mounted) return;
      setState(() {
        _pickup = addr;
        _pickupLat = pos.latitude;
        _pickupLng = pos.longitude;
      });
    } catch (_) {
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) {
        final addr = await _reverseGeocode(lastKnown.latitude, lastKnown.longitude);
        if (!mounted) return;
        setState(() {
          _pickup = addr;
          _pickupLat = lastKnown.latitude;
          _pickupLng = lastKnown.longitude;
        });
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not detect your location. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _detectingLocation = false);
    }
  }

  Future<String> _reverseGeocode(double lat, double lng) async {
    // Try server proxy first
    try {
      final headers = await AuthService.getHeaders();
      final r = await http.get(
        Uri.parse('${ApiConfig.reverseGeocode}?lat=$lat&lng=$lng'),
        headers: headers,
      ).timeout(const Duration(seconds: 6));
      if (r.statusCode == 200) {
        final d = jsonDecode(r.body) as Map<String, dynamic>;
        final parts = <String>[];
        for (final k in ['area', 'city', 'state']) {
          final v = d[k]?.toString() ?? '';
          if (v.isNotEmpty && !parts.contains(v)) parts.add(v);
        }
        if (parts.isNotEmpty) return parts.take(3).join(', ');
        final full = d['formattedAddress']?.toString() ?? '';
        if (full.isNotEmpty) return full.split(', ').take(3).join(', ');
      }
    } catch (_) {}
    // Nominatim fallback
    try {
      final r = await http.get(
        Uri.parse(
            'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lng'),
        headers: const {'User-Agent': 'JagoPro/1.0'},
      ).timeout(const Duration(seconds: 5));
      if (r.statusCode == 200) {
        final d = jsonDecode(r.body) as Map<String, dynamic>;
        final addr = d['address'] as Map<String, dynamic>? ?? {};
        final parts = <String>[];
        for (final k in ['suburb', 'neighbourhood', 'city', 'town', 'state']) {
          final v = addr[k]?.toString() ?? '';
          if (v.isNotEmpty && !parts.contains(v)) parts.add(v);
        }
        if (parts.isNotEmpty) return parts.take(3).join(', ');
        final full = d['display_name']?.toString() ?? '';
        if (full.isNotEmpty) return full.split(',').take(3).join(',').trim();
      }
    } catch (_) {}
    return 'Current Location';
  }

  // ── Recent Places ─────────────────────────────────────────────────────────
  Future<void> _loadRecent() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList('recent_places') ?? [];
      final list = raw
          .map((s) => Map<String, dynamic>.from(jsonDecode(s) as Map))
          .take(5)
          .toList();
      if (mounted) setState(() => _recent = list);
    } catch (_) {}
  }

  Future<void> _saveRecent(String name, double lat, double lng) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final entry = jsonEncode({'name': name, 'lat': lat, 'lng': lng});
      final raw = prefs.getStringList('recent_places') ?? [];
      raw.removeWhere((s) {
        try {
          return (jsonDecode(s) as Map)['name'] == name;
        } catch (_) {
          return false;
        }
      });
      raw.insert(0, entry);
      await prefs.setStringList('recent_places', raw.take(10).toList());
    } catch (_) {}
  }

  // ── Popular Locations ─────────────────────────────────────────────────────
  Future<void> _fetchPopular() async {
    try {
      final headers = await AuthService.getHeaders();
      final r = await http.get(
          Uri.parse(
              '${ApiConfig.baseUrl}/api/app/popular-locations?lat=${widget.pickupLat}&lng=${widget.pickupLng}'),
          headers: headers);
      if (r.statusCode == 200) {
        final data = jsonDecode(r.body) as Map<String, dynamic>;
        final list = ((data['locations'] as List<dynamic>?) ?? [])
            .map((x) => Map<String, dynamic>.from(x as Map))
            .map((x) => {
                  'name': x['name']?.toString() ?? '',
                  'lat':
                      double.tryParse((x['lat'] ?? x['latitude'] ?? 0).toString()) ??
                          0.0,
                  'lng': double.tryParse(
                          (x['lng'] ?? x['longitude'] ?? 0).toString()) ??
                      0.0,
                })
            .where((x) => (x['name'] as String).isNotEmpty)
            .toList();
        if (mounted && list.isNotEmpty) {
          setState(() => _popular = list.cast<Map<String, dynamic>>());
          return;
        }
      }
    } catch (_) {}
    // No hardcoded fallback — popular locations come from the API only
  }

  // ── Search ────────────────────────────────────────────────────────────────
  void _onDropChanged(String q) {
    _activeQuery = q;
    _activeField = true;
    if (_debounce?.isActive == true) _debounce!.cancel();
    if (q.length < 2) {
      setState(() {
        _searchResults = [];
        _searching = false;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 450), () => _search(q));
  }

  void _onStopChanged(String q) {
    _activeQuery = q;
    _activeField = false;
    if (_debounce?.isActive == true) _debounce!.cancel();
    if (q.length < 2) {
      setState(() {
        _searchResults = [];
        _searching = false;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 450), () => _search(q));
  }

  Future<void> _search(String query) async {
    if (!mounted) return;
    setState(() => _searching = true);
    try {
      final headers = await AuthService.getHeaders();
      final lat = _pickupLat;
      final lng = _pickupLng;
      final qp = StringBuffer('?query=${Uri.encodeComponent(query)}');
      if (lat != 0.0 && lng != 0.0) qp.write('&lat=$lat&lng=$lng');
      final r = await http.get(
        Uri.parse('${ApiConfig.placesAutocomplete}$qp'),
        headers: headers,
      ).timeout(const Duration(seconds: 6));
      if (!mounted) return;
      if (r.statusCode == 200) {
        final data = jsonDecode(r.body) as Map<String, dynamic>;
        final preds = (data['predictions'] as List<dynamic>?) ?? [];
        setState(() {
          _searchResults = preds
              .map((p) {
                final lat2 = (p['lat'] as num?)?.toDouble() ?? 0.0;
                final lng2 = (p['lng'] as num?)?.toDouble() ?? 0.0;
                return <String, dynamic>{
                  'name': p['fullDescription']?.toString() ??
                      p['mainText']?.toString() ?? '',
                  'placeId': p['placeId']?.toString() ?? '',
                  'lat': lat2,
                  'lng': lng2,
                };
              })
              .where((r) => (r['name'] as String).isNotEmpty)
              .toList();
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _searching = false);
  }

  // ── Selection Handlers ────────────────────────────────────────────────────
  void _selectDrop(String name, double lat, double lng) {
    HapticFeedback.selectionClick();
    _saveRecent(name, lat, lng);
    setState(() {
      _drop = name;
      _dropLat = lat;
      _dropLng = lng;
      _dropCtrl.text = name;
      _searchResults = [];
    });
    FocusScope.of(context).unfocus();
    _tryProceed();
  }

  void _selectStop(String name, double lat, double lng) {
    HapticFeedback.selectionClick();
    setState(() {
      _stop = name;
      _stopLat = lat;
      _stopLng = lng;
      _stopCtrl.text = name;
      _searchResults = [];
    });
    FocusScope.of(context).unfocus();
  }

  /// Resolves place coordinates from server then selects drop/stop.
  /// For local DB predictions lat/lng are inline; Google predictions need a detail fetch.
  Future<void> _selectFromSearch(
      Map<String, dynamic> p, {required bool forDrop}) async {
    final name = p['name']?.toString() ?? '';
    var lat = (p['lat'] as num?)?.toDouble() ?? 0.0;
    var lng = (p['lng'] as num?)?.toDouble() ?? 0.0;
    final placeId = p['placeId']?.toString() ?? '';
    if ((lat == 0.0 || lng == 0.0) &&
        placeId.isNotEmpty &&
        !placeId.startsWith('local:')) {
      setState(() => _detectingLocation = true);
      try {
        final headers = await AuthService.getHeaders();
        final r = await http
            .get(
              Uri.parse(
                  '${ApiConfig.placeDetails}?placeId=${Uri.encodeComponent(placeId)}'),
              headers: headers,
            )
            .timeout(const Duration(seconds: 6));
        if (r.statusCode == 200) {
          final d = jsonDecode(r.body) as Map<String, dynamic>;
          lat = (d['lat'] as num?)?.toDouble() ?? 0.0;
          lng = (d['lng'] as num?)?.toDouble() ?? 0.0;
          final resolvedName = d['address']?.toString() ?? name;
          if (!mounted) return;
          setState(() => _detectingLocation = false);
          if (forDrop) {
            _selectDrop(resolvedName, lat, lng);
          } else {
            _selectStop(resolvedName, lat, lng);
          }
          return;
        }
      } catch (_) {}
      if (mounted) setState(() => _detectingLocation = false);
    }
    if (forDrop) {
      _selectDrop(name, lat, lng);
    } else {
      _selectStop(name, lat, lng);
    }
  }

  void _tryProceed() {
    if (_pickup.isEmpty || _drop.isEmpty) return;
    if (_pickupLat == 0 && _pickupLng == 0) return;
    _proceedToVehicles();
  }

  void _proceedToVehicles() {
    if (_dropLat == 0 && _dropLng == 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please select a valid destination from suggestions'),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    HapticFeedback.mediumImpact();
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => BookingScreen(
          pickup: _pickup,
          destination: _drop,
          pickupLat: _pickupLat,
          pickupLng: _pickupLng,
          destLat: _dropLat,
          destLng: _dropLng,
          category: widget.serviceType,
          vehicleCategoryId: widget.vehicleCategoryId,
          vehicleCategoryName: widget.vehicleCategoryName,
        ),
        transitionDuration: const Duration(milliseconds: 350),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(
          opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
          child: child,
        ),
      ),
    );
  }

  // ── Map Picker ────────────────────────────────────────────────────────────
  Future<void> _pickDropOnMap() async {
    FocusScope.of(context).unfocus();
    final result = await Navigator.push<PickedLocation>(
      context,
      MaterialPageRoute(
        builder: (_) => MapLocationPicker(
          title: 'Select Drop Location',
          initialLat: _pickupLat != 0 ? _pickupLat : null,
          initialLng: _pickupLng != 0 ? _pickupLng : null,
        ),
      ),
    );
    if (result != null) {
      _selectDrop(result.address, result.lat, result.lng);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(children: [
          _buildHeader(),
          _buildInputCard(),
          if (_showStop) _buildStopField(),
          Expanded(child: _buildSuggestions()),
        ]),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F7FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE8EFFF)),
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                size: 18, color: JT.textPrimary),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              _isParcel ? 'Send Parcel' : 'Book a Ride',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w400,
                color: JT.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
            Text(
              _isParcel
                  ? 'Choose pickup & delivery location'
                  : 'Where are you going?',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: JT.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ]),
        ),
        // Service badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: _accentLight,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _accent.withValues(alpha: 0.25)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(
              _isParcel
                  ? Icons.local_shipping_rounded
                  : Icons.electric_rickshaw_rounded,
              color: _accent,
              size: 14,
            ),
            const SizedBox(width: 4),
            Text(
              _isParcel ? 'Parcel' : 'Ride',
              style: GoogleFonts.poppins(
                color: _accent,
                fontSize: 11,
                fontWeight: FontWeight.w400,
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  // ── Input Card ────────────────────────────────────────────────────────────
  Widget _buildInputCard() {
    return SlideTransition(
      position: _slideAnim,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE8EFFF)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(children: [
          // ── Pickup row ──
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(children: [
              // Green dot
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: const Color(0xFF16A34A),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: const Color(0xFF16A34A).withValues(alpha: 0.3),
                      width: 3),
                  boxShadow: [
                    BoxShadow(
                        color:
                            const Color(0xFF16A34A).withValues(alpha: 0.3),
                        blurRadius: 6)
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _detectingLocation
                    ? Row(children: [
                        SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: _accent),
                        ),
                        const SizedBox(width: 8),
                        Text('Detecting your location…',
                            style: GoogleFonts.poppins(
                                color: JT.textSecondary,
                                fontSize: 13,
                                fontWeight: FontWeight.w500)),
                      ])
                    : GestureDetector(
                        onTap: _pickup.isEmpty ? _detectLocation : null,
                        child: Text(
                          _pickup.isEmpty
                              ? 'Detecting current location…'
                              : _pickup.split(', ').take(2).join(', '),
                          style: GoogleFonts.poppins(
                            color: _pickup.isEmpty
                                ? JT.textSecondary
                                : JT.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
              ),
              // GPS re-detect button
              GestureDetector(
                onTap: _detectLocation,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _accentLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.my_location_rounded,
                      color: _accent, size: 16),
                ),
              ),
            ]),
          ),

          // Divider with dashes
          Padding(
            padding: const EdgeInsets.only(left: 28),
            child: Row(children: List.generate(
                20,
                (i) => Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        height: 1,
                        color: i.isEven
                            ? const Color(0xFFE8EFFF)
                            : Colors.transparent,
                      ),
                    ))),
          ),

          // ── Drop row ──
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(children: [
              // Red pin
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: _accent,
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: _accent.withValues(alpha: 0.3), width: 3),
                  boxShadow: [
                    BoxShadow(
                        color: _accent.withValues(alpha: 0.35),
                        blurRadius: 6)
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _dropCtrl,
                  focusNode: _dropFocus,
                  style: GoogleFonts.poppins(
                    color: JT.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                  decoration: InputDecoration.collapsed(
                    hintText: _isParcel
                        ? 'Enter delivery location'
                        : 'Where to?',
                    hintStyle: GoogleFonts.poppins(
                      color: JT.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  onChanged: _onDropChanged,
                  onSubmitted: (_) => _tryProceed(),
                  textInputAction: TextInputAction.search,
                ),
              ),
              if (_dropCtrl.text.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    _dropCtrl.clear();
                    setState(() {
                      _drop = '';
                      _searchResults = [];
                    });
                    _dropFocus.requestFocus();
                  },
                  child: const Icon(Icons.close_rounded,
                      size: 18, color: JT.textSecondary),
                ),
            ]),
          ),

          // ── Action buttons ──
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFF),
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(16)),
              border: const Border(
                  top: BorderSide(color: Color(0xFFE8EFFF))),
            ),
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(children: [
              // Pick on Map
              _actionChip(
                Icons.map_rounded,
                'Pick on Map',
                onTap: _pickDropOnMap,
              ),
              const SizedBox(width: 8),
              // Add Stop
              if (!_showStop)
                _actionChip(
                  Icons.add_location_alt_rounded,
                  'Add Stop',
                  onTap: () {
                    setState(() => _showStop = true);
                    Future.delayed(const Duration(milliseconds: 100), () {
                      if (mounted) _stopFocus.requestFocus();
                    });
                  },
                ),
              if (_showStop)
                _actionChip(
                  Icons.remove_circle_outline_rounded,
                  'Remove Stop',
                  onTap: () {
                    setState(() {
                      _showStop = false;
                      _stop = '';
                      _stopCtrl.clear();
                    });
                  },
                  isDestructive: true,
                ),
              const Spacer(),
              // Proceed button (shows when drop is selected)
              if (_drop.isNotEmpty)
                GestureDetector(
                  onTap: _proceedToVehicles,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_accent, _accent.withValues(alpha: 0.8)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: _accent.withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Text(
                        'See Vehicles',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_forward_rounded,
                          color: Colors.white, size: 14),
                    ]),
                  ),
                ),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _actionChip(IconData icon, String label,
      {required VoidCallback onTap, bool isDestructive = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isDestructive
              ? const Color(0xFFFEF2F2)
              : const Color(0xFFF0F7FF),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDestructive
                ? const Color(0xFFFCA5A5)
                : const Color(0xFFBFDBFE),
          ),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(
            icon,
            size: 14,
            color: isDestructive
                ? const Color(0xFFEF4444)
                : JT.primary,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isDestructive
                  ? const Color(0xFFEF4444)
                  : JT.primary,
            ),
          ),
        ]),
      ),
    );
  }

  // ── Add Stop Field ─────────────────────────────────────────────────────────
  Widget _buildStopField() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8EFFF)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: const Color(0xFFF59E0B),
            shape: BoxShape.circle,
            border: Border.all(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                width: 3),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextField(
            controller: _stopCtrl,
            focusNode: _stopFocus,
            style: GoogleFonts.poppins(
              color: JT.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w400,
            ),
            decoration: InputDecoration.collapsed(
              hintText: 'Add a stop along the way',
              hintStyle: GoogleFonts.poppins(
                color: JT.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            onChanged: _onStopChanged,
          ),
        ),
        const Icon(Icons.add_circle_outline_rounded,
            size: 18, color: Color(0xFFF59E0B)),
      ]),
    );
  }

  // ── Suggestions ────────────────────────────────────────────────────────────
  Widget _buildSuggestions() {
    final isSearching = _activeQuery.length >= 2;
    final List<Map<String, dynamic>> items =
        isSearching ? _searchResults : [];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        // Search results
        if (isSearching && _searching)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: JT.primary),
            ),
          )
        else if (isSearching && items.isNotEmpty) ...[
          _sectionHeader('Search Results', Icons.search_rounded),
          ...items.map((p) => _placeRow(
                name: p['name']?.toString() ?? '',
                icon: Icons.location_on_rounded,
                iconColor: _accent,
                onTap: () => _selectFromSearch(p, forDrop: _activeField),
              )),
        ]

        // Default state: recent + popular
        else if (!isSearching) ...[
          // Recent places
          if (_recent.isNotEmpty) ...[
            _sectionHeader('Recent', Icons.history_rounded),
            ..._recent.map((p) => _placeRow(
                  name: p['name']?.toString() ?? '',
                  icon: Icons.history_rounded,
                  iconColor: JT.textSecondary,
                  onTap: () => _selectDrop(
                      p['name'] ?? '',
                      (p['lat'] as num).toDouble(),
                      (p['lng'] as num).toDouble()),
                )),
            const SizedBox(height: 12),
          ],

          // Popular locations
          if (_popular.isNotEmpty) ...[
            _sectionHeader('Popular Locations', Icons.star_rounded),
            ..._popular.map((p) => _placeRow(
                  name: p['name']?.toString() ?? '',
                  icon: Icons.place_rounded,
                  iconColor: const Color(0xFFF59E0B),
                  onTap: () => _selectDrop(
                      p['name'] ?? '',
                      (p['lat'] as num).toDouble(),
                      (p['lng'] as num).toDouble()),
                )),
          ],
        ],
      ],
    );
  }

  Widget _sectionHeader(String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Row(children: [
        Icon(icon, size: 14, color: JT.textSecondary),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.poppins(
            color: JT.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
          ),
        ),
      ]),
    );
  }

  Widget _placeRow({
    required String name,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFF1F5F9)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: GoogleFonts.poppins(
                color: JT.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w400,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Icon(Icons.chevron_right_rounded,
              size: 18, color: JT.textSecondary),
        ]),
      ),
    );
  }
}
