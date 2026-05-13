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
    this.pickupLat = 0,
    this.pickupLng = 0,
    this.vehicleCategoryId,
    this.vehicleCategoryName,
  });

  @override
  State<PremiumLocationScreen> createState() => _PremiumLocationScreenState();
}

class _PremiumLocationScreenState extends State<PremiumLocationScreen> {
  final TextEditingController _pickupCtrl = TextEditingController();
  final TextEditingController _dropCtrl = TextEditingController();
  final FocusNode _pickupFocus = FocusNode();
  final FocusNode _dropFocus = FocusNode();

  String _pickup = '';
  String _drop = '';
  double _pickupLat = 0;
  double _pickupLng = 0;
  double _dropLat = 0;
  double _dropLng = 0;

  List<Map<String, dynamic>> _searchResults = [];
  Timer? _debounce;
  bool _isTyping = false;
  bool _detectingLocation = false;
  bool _searching = false;
  int _searchRequestId = 0;
  String _sessionToken = '';
  String? _zoneWarning;

  @override
  void initState() {
    super.initState();
    _pickup = widget.pickupAddress ?? '';
    _pickupLat = widget.pickupLat;
    _pickupLng = widget.pickupLng;
    _pickupCtrl.text = _pickup;
    _sessionToken = DateTime.now().millisecondsSinceEpoch.toString();
    _pickupFocus.addListener(_onFocusChange);
    _dropFocus.addListener(_onFocusChange);
  }

  void _showNotServingMessage([String? zoneName]) {
    final zoneSuffix = (zoneName != null && zoneName.trim().isNotEmpty)
        ? ' in $zoneName'
        : '';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'We are not serving this area$zoneSuffix yet. Please choose a location inside your active service zone.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
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

  void _onFocusChange() {
    if (mounted) {
      setState(() {
        _isTyping = _pickupFocus.hasFocus || _dropFocus.hasFocus;
        if (!_isTyping) _searchResults = [];
      });
    }
  }

  Future<void> _detectLocation() async {
    setState(() => _detectingLocation = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      Position p = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.best),
      );
      final addr = await _reverseGeocode(p.latitude, p.longitude);
      if (!mounted) return;
      setState(() {
        _pickup = addr;
        _pickupLat = p.latitude;
        _pickupLng = p.longitude;
        _pickupCtrl.text = addr;
        _detectingLocation = false;
      });
    } catch (e) {
      if (mounted) setState(() => _detectingLocation = false);
    }
  }

  Future<String> _reverseGeocode(double lat, double lng) async {
    try {
      Map<String, String> headers = const {};
      try {
        headers = await AuthService.getHeaders();
      } catch (_) {}
      final res = await http.get(
        Uri.parse('${ApiConfig.reverseGeocode}?lat=$lat&lng=$lng'),
        headers: headers,
      );
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        return data['formattedAddress']?.toString() ??
            data['address']?.toString() ??
            "Selected Location";
      }
    } catch (_) {}
    return "Selected Location";
  }

  void _onSearch(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      final q = query.trim();
      if (q.length < 2) {
        if (mounted) {
          setState(() {
            _searchResults = [];
            _searching = false;
            _zoneWarning = null;
          });
        }
        return;
      }
      final requestId = ++_searchRequestId;
      if (mounted) setState(() => _searching = true);
      try {
        Map<String, String> headers = const {};
        try {
          headers = await AuthService.getHeaders();
        } catch (_) {}

        final qp = StringBuffer('?query=${Uri.encodeComponent(q)}');
        qp.write('&sessionToken=$_sessionToken');
        if (_pickupLat != 0 && _pickupLng != 0) {
          qp.write('&lat=$_pickupLat&lng=$_pickupLng');
        }

        final res = await http
            .get(Uri.parse('${ApiConfig.placesAutocomplete}$qp'), headers: headers)
            .timeout(const Duration(seconds: 6));
        if (!mounted || requestId != _searchRequestId) return;

        if (res.statusCode == 200) {
          final data = json.decode(res.body) as Map<String, dynamic>;
          final zoneWarning = data['message']?.toString();
          final predictions = (data['predictions'] as List<dynamic>? ?? [])
              .map((p) => <String, dynamic>{
                    'name': p['fullDescription']?.toString() ??
                        p['description']?.toString() ??
                        p['mainText']?.toString() ??
                        '',
                    'mainText': p['mainText']?.toString() ?? '',
                    'secondaryText': p['secondaryText']?.toString() ?? '',
                    'placeId': p['placeId']?.toString() ??
                        p['place_id']?.toString() ??
                        '',
                    'lat': (p['lat'] as num?)?.toDouble() ?? 0.0,
                    'lng': (p['lng'] as num?)?.toDouble() ?? 0.0,
                    'serviceable': p['serviceable'] == true,
                    'zoneName': p['zoneName']?.toString() ?? '',
                    'notServing': p['notServing'] == true,
                  })
              .where((p) => (p['name'] as String).isNotEmpty)
              .toList();
          setState(() {
            _zoneWarning = zoneWarning;
            _searchResults = predictions;
          });
        } else {
          setState(() {
            _zoneWarning = null;
            _searchResults = [];
          });
        }
      } catch (_) {
        if (mounted && requestId == _searchRequestId) {
          setState(() {
            _zoneWarning = null;
            _searchResults = [];
          });
        }
      } finally {
        if (mounted && requestId == _searchRequestId) {
          setState(() => _searching = false);
        }
      }
    });
  }

  Future<void> _selectPlace(Map<String, dynamic> p) async {
    final placeId = p['placeId']?.toString() ?? p['place_id']?.toString() ?? '';
    if (placeId.isEmpty) return;
    try {
      double lat = (p['lat'] as num?)?.toDouble() ?? 0.0;
      double lng = (p['lng'] as num?)?.toDouble() ?? 0.0;
      String addr = p['name']?.toString() ?? 'Selected Location';
      final alreadyServiceable = p['serviceable'] == true;
      final predictionZoneName = p['zoneName']?.toString();

      if (lat == 0.0 || lng == 0.0) {
        Map<String, String> headers = const {};
        try {
          headers = await AuthService.getHeaders();
        } catch (_) {}
        final res = await http.get(
          Uri.parse(
              '${ApiConfig.placeDetails}?placeId=${Uri.encodeComponent(placeId)}&sessionToken=$_sessionToken'),
          headers: headers,
        ).timeout(const Duration(seconds: 6));
        _sessionToken = DateTime.now().millisecondsSinceEpoch.toString();
        if (res.statusCode != 200) return;
        final data = json.decode(res.body) as Map<String, dynamic>;
        lat = (data['lat'] as num?)?.toDouble() ?? 0.0;
        lng = (data['lng'] as num?)?.toDouble() ?? 0.0;
        addr = data['address']?.toString() ?? addr;
        if (data['serviceable'] != true) {
          if (mounted) _showNotServingMessage(data['zoneName']?.toString());
          return;
        }
      }

      if (lat == 0.0 || lng == 0.0) return;
      if (!alreadyServiceable &&
          (placeId.startsWith('local:') || placeId.startsWith('nom:'))) {
        if (p['serviceable'] != true) {
          if (mounted) _showNotServingMessage(predictionZoneName);
          return;
        }
      }
      if (mounted) {
        setState(() {
          if (_pickupFocus.hasFocus) {
            _pickup = addr;
            _pickupLat = lat;
            _pickupLng = lng;
            _pickupCtrl.text = addr;
          } else {
            _drop = addr;
            _dropLat = lat;
            _dropLng = lng;
            _dropCtrl.text = addr;
          }
          _searchResults = [];
          _searching = false;
          FocusScope.of(context).unfocus();
        });
      }
    } catch (_) {}
  }

  void _clearResults() {
    if (!mounted) return;
    setState(() {
      _searchResults = [];
      _searching = false;
    });
  }

  void _swapLocations() {
    setState(() {
      final tTxt = _pickup; final tLat = _pickupLat; final tLng = _pickupLng;
      _pickup = _drop; _pickupLat = _dropLat; _pickupLng = _dropLng; _pickupCtrl.text = _pickup;
      _drop = tTxt; _dropLat = tLat; _dropLng = tLng; _dropCtrl.text = _drop;
    });
  }

  void _proceedToBooking() {
    if (_pickupLat == 0 || _dropLat == 0) return;
    if (widget.serviceType == 'parcel') {
      Navigator.push(context, MaterialPageRoute(builder: (context) => ParcelBookingScreen(
        pickupLat: _pickupLat, pickupLng: _pickupLng, dropLat: _dropLat, dropLng: _dropLng,
        pickupAddress: _pickup, dropAddress: _drop,
      )));
    } else {
      Navigator.push(context, MaterialPageRoute(builder: (context) => BookingScreen(
        pickup: _pickup, destination: _drop, pickupLat: _pickupLat, pickupLng: _pickupLng,
        destLat: _dropLat, destLng: _dropLng, vehicleCategoryId: widget.vehicleCategoryId,
        vehicleCategoryName: widget.vehicleCategoryName, category: widget.serviceType,
      )));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(children: [
        Positioned(top: -100, right: -50, child: Container(width: 300, height: 300, decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF6366F1).withOpacity(0.15)))),
        Positioned(top: 200, left: -80, child: Container(width: 250, height: 250, decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFFF43F5E).withOpacity(0.1)))),
        SafeArea(child: Column(children: [
          _buildHeader(),
          Expanded(child: Stack(children: [
            Positioned(bottom: -40, left: 0, right: 0, child: AnimatedSwitcher(duration: const Duration(milliseconds: 400), child: _isTyping ? const SizedBox.shrink() : Transform(
              transform: Matrix4.identity()..setEntry(3, 2, 0.001)..rotateX(0.08), alignment: Alignment.bottomCenter,
              child: Container(padding: const EdgeInsets.only(bottom: 20), child: Stack(alignment: Alignment.bottomCenter, children: [
                Container(width: 400, height: 400, decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [const Color(0xFF6366F1).withOpacity(0.1), Colors.transparent]))),
                Image.network('https://res.cloudinary.com/kits/image/upload/q_auto/f_auto/v1775197692/ride_image_qffoic.png', height: 350, fit: BoxFit.contain, errorBuilder: (_, __, ___) => const SizedBox.shrink()),
              ])),
            ))),
            SingleChildScrollView(physics: const BouncingScrollPhysics(), padding: const EdgeInsets.symmetric(horizontal: 20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const SizedBox(height: 10),
              Text("Where to go?", style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.w800, color: const Color(0xFF1E293B), letterSpacing: -1.0)),
              const SizedBox(height: 16),
              _buildRouteCard(),
              const SizedBox(height: 250),
            ])),
          ])),
        ])),
      ]),
    );
  }

  Widget _buildHeader() {
    return Container(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF334155), size: 20), style: IconButton.styleFrom(backgroundColor: Colors.white, padding: const EdgeInsets.all(12))),
      JT.logoBlue(height: 28),
      Row(children: [
        IconButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationsScreen())), icon: const Icon(Icons.notifications_none_rounded, color: Color(0xFF64748B), size: 22), style: IconButton.styleFrom(backgroundColor: Colors.white, padding: const EdgeInsets.all(12))),
        const SizedBox(width: 12),
        GestureDetector(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const WalletScreen())), child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))]), child: Row(children: [
          const Icon(Icons.account_balance_wallet_rounded, color: Color(0xFF6366F1), size: 16),
          const SizedBox(width: 8),
          Text("Wallet", style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B))),
        ]))),
      ]),
    ]));
  }

  Widget _buildRouteCard() {
    return Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 30, offset: const Offset(0, 15))], border: Border.all(color: const Color(0xFFF1F5F9))), child: Column(children: [
      _buildLocationInput(title: "Pickup", hint: "Starting point?", controller: _pickupCtrl, focusNode: _pickupFocus, icon: Icons.my_location_rounded, iconColor: const Color(0xFF6366F1), isPickup: true, loading: _detectingLocation && _pickup.isEmpty, onChanged: _onSearch, trailing: GestureDetector(onTap: _detectLocation, child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: const Color(0xFF6366F1).withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Text("Current", style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF6366F1)))))),
      const SizedBox(height: 12),
      _buildDividerWithSwap(),
      const SizedBox(height: 12),
      _buildLocationInput(title: "Destination", hint: "Where are we going?", controller: _dropCtrl, focusNode: _dropFocus, icon: Icons.location_on_rounded, iconColor: const Color(0xFFF43F5E), isPickup: false, onChanged: _onSearch, trailing: GestureDetector(onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => const MapLocationPicker())).then((res) {
          if (res != null) { setState(() { _drop = res.address; _dropLat = res.lat; _dropLng = res.lng; _dropCtrl.text = _drop; }); }
        });
      }, child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), decoration: BoxDecoration(color: const Color(0xFFF43F5E).withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Text("Map", style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFFF43F5E)))))),
      if (_isTyping && _zoneWarning != null && _searchResults.every((item) => item['serviceable'] != true))
        Padding(
          padding: const EdgeInsets.only(top: 14),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF43F5E).withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFF43F5E).withOpacity(0.18)),
            ),
            child: Text(
              _zoneWarning!,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFBE123C),
              ),
            ),
          ),
        ),
      AnimatedSwitcher(duration: const Duration(milliseconds: 300), child: (_isTyping && _searchResults.isNotEmpty) ? Column(children: [const SizedBox(height: 16), _buildSearchResults()]) : const SizedBox.shrink()),
      const SizedBox(height: 32),
      GestureDetector(onTap: _proceedToBooking, child: AnimatedContainer(duration: const Duration(milliseconds: 200), height: 58, decoration: BoxDecoration(gradient: (_pickupLat != 0 && _dropLat != 0) ? const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF4338CA), Color(0xFFF43F5E)]) : const LinearGradient(colors: [Color(0xFFE2E8F0), Color(0xFFE2E8F0)]), borderRadius: BorderRadius.circular(20), boxShadow: (_pickupLat != 0 && _dropLat != 0) ? [BoxShadow(color: const Color(0xFF6366F1).withOpacity(0.3), blurRadius: 25, offset: const Offset(0, 10))] : []), child: Center(child: Text((_pickup.isEmpty || _drop.isEmpty) ? "Set your journey" : "Explore Premium Rides", style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.w700, color: (_pickupLat != 0 && _dropLat != 0) ? Colors.white : const Color(0xFF94A3B8)))))),
    ]));
  }

  Widget _buildDividerWithSwap() {
    return Row(children: [
      const Expanded(child: Divider(color: Color(0xFFF1F5F9), thickness: 1)),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: GestureDetector(onTap: _swapLocations, child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xFF6366F1).withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.swap_vert_rounded, color: Color(0xFF6366F1), size: 22)))),
      const Expanded(child: Divider(color: Color(0xFFF1F5F9), thickness: 1)),
    ]);
  }

  Widget _buildLocationInput({required String title, required String hint, required TextEditingController controller, required FocusNode focusNode, required IconData icon, required Color iconColor, required bool isPickup, bool loading = false, Widget? trailing, required Function(String) onChanged}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(title.toUpperCase(), style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w800, color: isPickup ? const Color(0xFF6366F1) : const Color(0xFFF43F5E), letterSpacing: 1.2)), if (trailing != null) trailing]),
      const SizedBox(height: 10),
      TextField(controller: controller, focusNode: focusNode, onChanged: onChanged, style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B)), decoration: InputDecoration(hintText: loading ? "Locating you..." : hint, hintStyle: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFFCBD5E1), fontWeight: FontWeight.w400), prefixIcon: Icon(icon, color: iconColor, size: 22), filled: true, fillColor: const Color(0xFFF8FAFC), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFF1F5F9), width: 1.5)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: iconColor, width: 2)), suffixIcon: loading || (_searching && focusNode.hasFocus) ? const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF6366F1)))) : (controller.text.isNotEmpty && focusNode.hasFocus ? IconButton(onPressed: () { controller.clear(); _clearResults(); }, icon: const Icon(Icons.close_rounded, color: Color(0xFF94A3B8), size: 18)) : null))),
    ]);
  }

  Widget _buildSearchResults() {
    return Container(constraints: const BoxConstraints(maxHeight: 250), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFF1F5F9))), child: ListView.separated(shrinkWrap: true, padding: EdgeInsets.zero, itemCount: _searchResults.length, separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFF1F5F9)), itemBuilder: (context, index) {
      final p = _searchResults[index];
      final mainText = p['mainText']?.toString().isNotEmpty == true
          ? p['mainText'].toString()
          : (p['name']?.toString().split(',').first ?? 'Location');
      final secText = p['secondaryText']?.toString() ?? '';
      final serviceable = p['serviceable'] == true;
      final zoneName = p['zoneName']?.toString() ?? '';
      return ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Icon(
          serviceable ? Icons.location_on_rounded : Icons.location_off_rounded,
          color: serviceable ? const Color(0xFF6366F1) : const Color(0xFFF43F5E),
          size: 20,
        ),
        title: Text(mainText, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B))),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (secText.isNotEmpty)
              Text(secText, style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF64748B)), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: serviceable
                    ? const Color(0xFF6366F1).withOpacity(0.08)
                    : const Color(0xFFF43F5E).withOpacity(0.08),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                serviceable
                    ? (zoneName.isNotEmpty ? 'Serving in $zoneName' : 'Serving area')
                    : 'Not serving this area',
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: serviceable ? const Color(0xFF4338CA) : const Color(0xFFBE123C),
                ),
              ),
            ),
          ],
        ),
        onTap: () => _selectPlace(p),
      );
    }));
  }
}
