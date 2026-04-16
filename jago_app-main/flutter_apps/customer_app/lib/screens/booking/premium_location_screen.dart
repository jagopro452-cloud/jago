import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import '../../config/jago_theme.dart';
import '../../services/auth_service.dart';
import 'booking_screen.dart';
import 'map_location_picker.dart';
import '../wallet/wallet_screen.dart';
import '../notifications/notifications_screen.dart';
import 'parcel_booking_screen.dart';

class PremiumLocationScreen extends StatefulWidget {
  final String serviceType; // 'ride' or 'parcel'
  final String? pickupAddress;
  final double pickupLat;
  final double pickupLng;
  final String? vehicleCategoryId;
  final String? vehicleCategoryName;

  const PremiumLocationScreen({
    super.key,
    required this.serviceType,
    this.pickupAddress,
    this.pickupLat = 0.0,
    this.pickupLng = 0.0,
    this.vehicleCategoryId,
    this.vehicleCategoryName,
  });

  @override
  State<PremiumLocationScreen> createState() => _PremiumLocationScreenState();
}

class _PremiumLocationScreenState extends State<PremiumLocationScreen> with TickerProviderStateMixin {
  final _pickupCtrl = TextEditingController();
  final _dropCtrl = TextEditingController();
  final FocusNode _pickupFocus = FocusNode();
  final FocusNode _dropFocus = FocusNode();

  String _pickup = '';
  double _pickupLat = 0.0;
  double _pickupLng = 0.0;

  String _drop = '';
  double _dropLat = 0.0;
  double _dropLng = 0.0;

  bool _detectingLocation = false;
  List<Map<String, dynamic>> _searchResults = [];
  bool _searching = false;
  String? _searchError;
  bool _editingPickup = false; // true = editing pickup, false = editing drop
  Timer? _debounce;

  // Header state (simulating home header)
  int _unreadNotifCount = 0;

  bool get _isTyping => _pickupFocus.hasFocus || _dropFocus.hasFocus;

  void _onFocusChange() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _pickup = widget.pickupAddress ?? '';
    _pickupLat = widget.pickupLat;
    _pickupLng = widget.pickupLng;
    _pickupCtrl.text = _pickup;

    if (_pickup.isEmpty) _detectLocation();
    _fetchUnreadCount();

    _pickupFocus.addListener(_onFocusChange);
    _dropFocus.addListener(_onFocusChange);

    // Auto-focus drop field if pickup is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_pickup.isNotEmpty) {
        _dropFocus.requestFocus();
      } else {
        _pickupFocus.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _pickupCtrl.dispose();
    _dropCtrl.dispose();
    _pickupFocus.dispose();
    _dropFocus.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _fetchUnreadCount() async {
    try {
      final headers = await AuthService.getHeaders();
      final r = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/app/notifications?limit=1'), headers: headers);
      if (r.statusCode == 200 && mounted) {
        final data = jsonDecode(r.body);
        setState(() => _unreadNotifCount = (data['unreadCount'] as int?) ?? 0);
      }
    } catch (_) {}
  }

  Future<void> _detectLocation() async {
    setState(() => _detectingLocation = true);
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() => _detectingLocation = false);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location permission required')));
        }
        return;
      }

      var pos = await Geolocator.getLastKnownPosition();
      if (pos == null || pos.latitude == 0) {
        pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high).timeout(const Duration(seconds: 8));
      }
      final addr = await _reverseGeocode(pos!.latitude, pos!.longitude);
      if (!mounted) return;
      setState(() {
        _pickup = addr;
        _pickupLat = pos!.latitude;
        _pickupLng = pos!.longitude;
        _pickupCtrl.text = addr;
      });
    } catch (_) {
    } finally {
      if (mounted) setState(() => _detectingLocation = false);
    }
  }

  Future<String> _reverseGeocode(double lat, double lng) async {
    try {
      final headers = await AuthService.getHeaders();
      final r = await http.get(Uri.parse('${ApiConfig.reverseGeocode}?lat=$lat&lng=$lng'), headers: headers);
      if (r.statusCode == 200) {
        final d = jsonDecode(r.body);
        return d['area'] ?? d['formattedAddress']?.toString().split(',').first ?? 'Current Location';
      }
    } catch (_) {}
    return 'Current Location';
  }

  void _onQueryChanged(String q, bool isPickup) {
    _editingPickup = isPickup;
    if (_debounce?.isActive == true) _debounce!.cancel();
    if (q.length < 3) {
      setState(() => _searchResults = []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 300), () => _search(q));
  }

  Future<void> _search(String query) async {
    setState(() {
      _searching = true;
      _searchError = null;
    });
    
    try {
      final headers = await AuthService.getHeaders();
      final url = Uri.parse('${ApiConfig.placesAutocomplete}?query=$query');
      print('DEBUG: Searching locations with URL: $url');
      
      final r = await http.get(url, headers: headers).timeout(const Duration(seconds: 10));
      print('DEBUG: Search response status: ${r.statusCode}');
      
      if (r.statusCode == 200) {
        final data = jsonDecode(r.body);
        final List preds = data['predictions'] ?? [];
        print('DEBUG: Found ${preds.length} predictions');
        
        setState(() {
          _searchResults = preds.map((p) => {
            'placeId': p['placeId'] ?? p['place_id'] ?? '',
            'mainText': p['mainText'] ?? p['structured_formatting']?['main_text'] ?? p['description']?.split(',')[0] ?? '',
            'secondaryText': p['secondaryText'] ?? p['structured_formatting']?['secondary_text'] ?? '',
            'name': p['mainText'] ?? p['structured_formatting']?['main_text'] ?? p['description']?.split(',')[0] ?? '',
            'lat': (p['lat'] as num?)?.toDouble() ?? 0.0,
            'lng': (p['lng'] as num?)?.toDouble() ?? 0.0,
          }).toList();
          _searching = false;
        });
      } else {
        print('DEBUG: Search failed with status: ${r.statusCode}, body: ${r.body}');
        setState(() {
          _searchError = 'Search failed (Status ${r.statusCode})';
          _searching = false;
        });
      }
    } catch (e) {
      print('DEBUG: Search error: $e');
      setState(() {
        _searchError = 'Network error during search';
        _searching = false;
      });
    }
  }

  Future<void> _selectPlace(Map<String, dynamic> p) async {
    final name = p['name'];
    var lat = p['lat'];
    var lng = p['lng'];
    final placeId = p['placeId'];

    if (lat == 0.0 && placeId.isNotEmpty) {
      setState(() => _detectingLocation = true);
      try {
        final headers = await AuthService.getHeaders();
        final r = await http.get(Uri.parse('${ApiConfig.placeDetails}?placeId=$placeId'), headers: headers);
        if (r.statusCode == 200) {
          final d = jsonDecode(r.body);
          lat = (d['lat'] as num).toDouble();
          lng = (d['lng'] as num).toDouble();
        }
      } catch (_) {}
      setState(() => _detectingLocation = false);
    }

    // Dismiss keyboard BEFORE setState so _isTyping = false makes Confirm button visible
    FocusManager.instance.primaryFocus?.unfocus();
    await Future.delayed(const Duration(milliseconds: 80));

    if (!mounted) return;
    setState(() {
      if (_editingPickup) {
        _pickup = name; _pickupLat = lat; _pickupLng = lng; _pickupCtrl.text = name;
      } else {
        _drop = name; _dropLat = lat; _dropLng = lng; _dropCtrl.text = name;
      }
      _searchResults = [];
    });

    // Auto-focus the next empty field to speed up the flow
    await Future.delayed(const Duration(milliseconds: 120));
    if (!mounted) return;
    if (_editingPickup && _drop.isEmpty) {
      _dropFocus.requestFocus();
    } else if (!_editingPickup && _pickup.isEmpty) {
      _pickupFocus.requestFocus();
    }
    // If both are filled → leave keyboard closed so Confirm Route is visible
  }

  void _swapLocations() {
    setState(() {
      final tN = _pickup; final tLa = _pickupLat; final tLo = _pickupLng;
      _pickup = _drop; _pickupLat = _dropLat; _pickupLng = _dropLng;
      _drop = tN; _dropLat = tLa; _dropLng = tLo;
      _pickupCtrl.text = _pickup; _dropCtrl.text = _drop;
    });
  }

  void _confirm() {
    if (_pickupLat == 0 || _dropLat == 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select both locations')));
      return;
    }
    if (widget.serviceType == 'parcel') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => ParcelBookingScreen(
        pickupAddress: _pickup,
        pickupLat: _pickupLat,
        pickupLng: _pickupLng,
      )));
      return;
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => BookingScreen(
      pickup: _pickup,
      destination: _drop,
      pickupLat: _pickupLat,
      pickupLng: _pickupLng,
      destLat: _dropLat,
      destLng: _dropLng,
      category: widget.serviceType,
      vehicleCategoryId: widget.vehicleCategoryId,
      vehicleCategoryName: widget.vehicleCategoryName,
    )));
  }

  Future<void> _pickOnMap() async {
    final result = await Navigator.push<PickedLocation>(
      context,
      MaterialPageRoute(
        builder: (_) => MapLocationPicker(
          title: 'Select Location',
          initialLat: _editingPickup ? (_pickupLat != 0 ? _pickupLat : null) : (_dropLat != 0 ? _dropLat : null),
          initialLng: _editingPickup ? (_pickupLng != 0 ? _pickupLng : null) : (_dropLng != 0 ? _dropLng : null),
        ),
      ),
    );
    if (result != null && mounted) {
      setState(() {
        if (_editingPickup) {
          _pickup = result.address;
          _pickupLat = result.lat;
          _pickupLng = result.lng;
          _pickupCtrl.text = result.address;
        } else {
          _drop = result.address;
          _dropLat = result.lat;
          _dropLng = result.lng;
          _dropCtrl.text = result.address;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD3C7FE),
      body: Stack(
        children: [
          // Background accents
          Positioned(bottom: -50, left: -50, right: -50,
            child: Container(height: 250, decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: const BorderRadius.all(Radius.elliptical(400, 200)))),
          ),
          Positioned(bottom: -100, left: -100, right: -100,
            child: Container(height: 300, decoration: BoxDecoration(color: Colors.white.withOpacity(0.35), borderRadius: const BorderRadius.all(Radius.elliptical(500, 250)))),
          ),

          // Ride illustration fixed at bottom of screen
          Positioned(
            bottom: -10,
            left: -20,
            right: -20,
            child: Image.network(
              'https://res.cloudinary.com/kits/image/upload/q_auto/f_auto/v1775197692/ride_image_qffoic.png',
              fit: BoxFit.contain,
              height: 380,
              alignment: Alignment.bottomCenter,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),

          // Main content on top
          SafeArea(
            child: Column(
              children: [
                if (!_isTyping) _buildHeader(),
                if (!_isTyping) const SizedBox(height: 10),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: _isTyping ? 0 : 20),
                    child: Column(
                      children: [
                        if (!_isTyping) ...[
                          const SizedBox(height: 10),
                          // "Set your route" text
                          Text(
                            "Set your route",
                            style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1E293B),
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 20),
                        ] else ...[
                          const SizedBox(height: 10),
                        ],

                        // Route card
                        _buildRouteCard(),

                        // Bottom padding so card doesn't overlap the image
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back Button
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 48, height: 48,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 4))]),
              child: const Icon(Icons.arrow_back_rounded, color: Color(0xFF64748B), size: 24),
            ),
          ),
          
          // Jago Logo
          JT.logoWhite(height: 64),
          
          // Actions
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WalletScreen())),
                child: Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 3))]),
                  child: const Icon(Icons.account_balance_wallet_outlined, color: Color(0xFF64748B), size: 20),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen())),
                child: Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 3))]),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const Icon(Icons.notifications_none_rounded, color: Color(0xFF64748B), size: 20),
                      if (_unreadNotifCount > 0)
                        Positioned(top: 10, right: 10, child: Container(width: 7, height: 7, decoration: const BoxDecoration(color: Color(0xFFEF4444), shape: BoxShape.circle))),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSelectOnMapBtn() {
    return GestureDetector(
      onTap: () {
        _editingPickup = false;
        _pickOnMap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.location_searching_rounded, color: Color(0xFF6366F1), size: 16),
            const SizedBox(width: 8),
            Text(
              "Select on\nMap",
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1E293B),
                height: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(color: const Color(0xFF6366F1).withOpacity(0.08), blurRadius: 40, offset: const Offset(0, 15)),
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      child: Column(
        children: [
          _buildLocationInput(
            title: "Pickup Location",
            hint: "Enter pickup location",
            controller: _pickupCtrl,
            focusNode: _pickupFocus,
            icon: Icons.location_on_rounded,
            iconColor: const Color(0xFF10B981), // Green
            isPickup: true,
            loading: _detectingLocation && _pickup.isEmpty,
            trailing: _buildCurrentLocationBtn(),
          ),
          
          const SizedBox(height: 8),
          _buildDividerWithSwap(),
          const SizedBox(height: 8),

          _buildLocationInput(
            title: "Drop Location",
            hint: "Enter drop location",
            controller: _dropCtrl,
            focusNode: _dropFocus,
            icon: Icons.location_on_rounded,
            iconColor: const Color(0xFFEF4444), // Red
            isPickup: false,
            trailing: _buildSelectOnMapBtn(),
          ),

          // Search Results Dynamic Inject
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_searching) ...[
                  const SizedBox(height: 30),
                  const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3B48D1))),
                  const SizedBox(height: 10),
                  const Text("Searching available locations...", style: TextStyle(color: Colors.grey, fontSize: 13)),
                ] else if (_searchError != null) ...[
                  const SizedBox(height: 30),
                  Text(_searchError!, style: const TextStyle(color: Colors.redAccent)),
                  TextButton(onPressed: () => _search(_editingPickup ? _pickupCtrl.text : _dropCtrl.text), child: const Text("Retry"))
                ] else if (_searchResults.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _buildSearchResults(),
                ] else if ((_editingPickup ? _pickupCtrl.text : _dropCtrl.text).length >= 3) ...[
                  const SizedBox(height: 30),
                  const Text("No locations found. Try a different search.", style: TextStyle(color: Colors.grey, fontSize: 13)),
                ],
              ],
            ),
          ),

          // Show Confirm button whenever NOT actively typing OR both locations are filled
          if (!_isTyping || (_pickupLat != 0 && _dropLat != 0)) ...[
            const SizedBox(height: 28),
            // Full-width Confirm button
            SizedBox(
              width: double.infinity,
              height: 58,
              child: GestureDetector(
                onTap: _confirm,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    gradient: (_pickupLat != 0 && _dropLat != 0)
                      ? const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF4F46E5)])
                      : const LinearGradient(colors: [Color(0xFFCBD5E1), Color(0xFFCBD5E1)]),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: (_pickupLat != 0 && _dropLat != 0) ? [
                      BoxShadow(color: const Color(0xFF6366F1).withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6)),
                    ] : [],
                  ),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          (_pickup.isEmpty || _drop.isEmpty)
                            ? "Enter Pickup & Drop"
                            : "Confirm Route",
                          style: GoogleFonts.poppins(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            letterSpacing: 0.3,
                          ),
                        ),
                        if (_pickupLat != 0 && _dropLat != 0) ...[
                          const SizedBox(width: 10),
                          const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 22),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLocationInput({
    required String title,
    required String hint,
    required TextEditingController controller,
    required FocusNode focusNode,
    required IconData icon,
    required Color iconColor,
    required bool isPickup,
    bool loading = false,
    Widget? trailing,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, color: iconColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF334155),
                  ),
                ),
              ],
            ),
            if (trailing != null) trailing,
          ],
        ),
        const SizedBox(height: 10),
        // Clean rounded outlined input — single layer, no extra wrapper
        TextField(
          controller: controller,
          focusNode: focusNode,
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF1E293B),
          ),
          decoration: InputDecoration(
            hintText: loading ? "Detecting location..." : hint,
            hintStyle: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF94A3B8)),
            filled: false,
            contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
            ),
            suffixIcon: loading
                ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF6366F1)),
                    ),
                  )
                : null,
          ),
          onChanged: (q) => _onQueryChanged(q, isPickup),
          onTap: () => setState(() => _editingPickup = isPickup),
        ),
      ],
    );
  }

  Widget _buildCurrentLocationBtn() {
    return GestureDetector(
      onTap: _detectLocation,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.gps_fixed_rounded, color: Color(0xFF6366F1), size: 16),
            const SizedBox(width: 8),
            Text(
              "Current\nLocation",
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1E293B),
                height: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDividerWithSwap() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1.5,
            margin: const EdgeInsets.only(left: 4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xFFE2E8F0), const Color(0xFFE2E8F0).withOpacity(0.0)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
          ),
        ),
        GestureDetector(
          onTap: _swapLocations,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFC7D2FE), width: 1),
              boxShadow: [
                BoxShadow(color: const Color(0xFF6366F1).withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: const Icon(Icons.swap_vert_rounded, color: Color(0xFF6366F1), size: 20),
          ),
        ),
        Expanded(
          child: Container(
            height: 1.5,
            margin: const EdgeInsets.only(right: 4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xFFE2E8F0).withOpacity(0.0), const Color(0xFFE2E8F0)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF6366F1).withOpacity(0.8), size: 18),
        const SizedBox(width: 8),
        Text(label, style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF64748B), fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildButton({required String label, required VoidCallback onTap, required bool isOutline, IconData? icon}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: isOutline ? Colors.white : const Color(0xFF6366F1),
          borderRadius: BorderRadius.circular(16),
          gradient: isOutline ? null : const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF4F46E5)]),
          border: isOutline ? Border.all(color: const Color(0xFFE2E8F0), width: 1.5) : null,
          boxShadow: isOutline ? null : [BoxShadow(color: const Color(0xFF6366F1).withValues(alpha: 0.25), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, color: isOutline ? const Color(0xFF6366F1) : Colors.white, size: 18),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isOutline ? const Color(0xFF334155) : Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _searchResults.length,
        separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey.shade100),
        itemBuilder: (context, index) {
          final p = _searchResults[index];
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.location_on_outlined, color: Color(0xFF3B48D1), size: 20),
            ),
            title: Text(
              p['mainText'] ?? p['name'] ?? '',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1E293B),
              ),
            ),
            subtitle: (p['secondaryText'] ?? '').toString().isNotEmpty
                ? Text(
                    p['secondaryText'],
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: const Color(0xFF64748B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )
                : null,
            onTap: () => _selectPlace(p),
          );
        },
      ),
    );
  }
}
