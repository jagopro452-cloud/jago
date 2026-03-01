import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/api_config.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';
import '../history/trips_history_screen.dart';
import '../wallet/wallet_screen.dart';
import '../coins/coins_screen.dart';
import '../monthly_pass/monthly_pass_screen.dart';
import '../profile/profile_screen.dart';
import '../booking/booking_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  GoogleMapController? _mapController;
  LatLng _center = const LatLng(17.3850, 78.4867);
  String _userName = 'there';
  String _userPhone = '';
  String _pickup = 'Current Location';
  String _destination = '';
  double _pickupLat = 17.3850, _pickupLng = 78.4867;
  double _destLat = 0, _destLng = 0;
  int _selectedRide = 0;
  bool _loading = true;
  List<Map<String, dynamic>> _vehicleCategories = [];

  static IconData _iconForVehicle(String name, {String? type}) {
    final n = name.toLowerCase();
    if (n.contains('bike parcel') || n.contains('parcel bike')) return Icons.delivery_dining;
    if (n.contains('bike')) return Icons.electric_bike;
    if (n.contains('mini auto') || n.contains('temo auto')) return Icons.electric_rickshaw;
    if (n.contains('auto')) return Icons.electric_rickshaw;
    if (n.contains('suv')) return Icons.directions_car;
    if (n.contains('tata ace') || n.contains('mini cargo')) return Icons.local_shipping;
    if (n.contains('cargo truck')) return Icons.fire_truck;
    if (n.contains('cargo')) return Icons.local_shipping;
    if (n.contains('parcel')) return Icons.delivery_dining;
    if (n.contains('car')) return Icons.directions_car_filled;
    if (type == 'cargo') return Icons.local_shipping;
    if (type == 'parcel') return Icons.delivery_dining;
    return Icons.directions_car;
  }

  @override
  void initState() {
    super.initState();
    _loadUser();
    _getLocation();
    _fetchHome();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('user_name') ?? 'there';
      _userPhone = prefs.getString('user_phone') ?? '';
    });
  }

  Future<void> _getLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
        if (perm == LocationPermission.denied) return;
      }
      if (perm == LocationPermission.deniedForever) return;
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _center = LatLng(pos.latitude, pos.longitude);
        _pickupLat = pos.latitude;
        _pickupLng = pos.longitude;
      });
      _mapController?.animateCamera(CameraUpdate.newLatLng(_center));
      _reverseGeocode(pos.latitude, pos.longitude);
    } catch (_) {}
  }

  Future<void> _reverseGeocode(double lat, double lng) async {
    try {
      final url = 'https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lng&key=${ApiConfig.googleMapsApiKey}';
      final res = await http.get(Uri.parse(url));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final results = data['results'] as List<dynamic>?;
        if (results != null && results.isNotEmpty) {
          final address = results[0]['formatted_address'] as String? ?? 'Current Location';
          setState(() => _pickup = address);
        }
      }
    } catch (_) {}
  }

  Future<void> _fetchHome() async {
    final token = await AuthService.getToken();
    try {
      final res = await http.get(Uri.parse(ApiConfig.customerHomeData),
        headers: {'Authorization': 'Bearer $token'});
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final cats = (data['vehicleCategories'] as List<dynamic>?)
          ?.cast<Map<String, dynamic>>() ?? [];
        setState(() {
          _vehicleCategories = cats.isNotEmpty ? cats : _defaultVehicleCategories();
          _loading = false;
        });
      } else {
        setState(() { _vehicleCategories = _defaultVehicleCategories(); _loading = false; });
      }
    } catch (_) { setState(() { _vehicleCategories = _defaultVehicleCategories(); _loading = false; }); }
  }

  List<Map<String, dynamic>> _defaultVehicleCategories() => [
    {'name': 'Bike', 'type': 'ride', 'minimumFare': '20', 'baseFare': '20'},
    {'name': 'Mini Auto', 'type': 'ride', 'minimumFare': '30', 'baseFare': '30'},
    {'name': 'Bike Parcel', 'type': 'parcel', 'minimumFare': '25', 'baseFare': '25'},
    {'name': 'Tata Ace', 'type': 'cargo', 'minimumFare': '200', 'baseFare': '200'},
  ];

  void _bookRide() {
    if (_destination.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Destination enter cheyyandi'), backgroundColor: Color(0xFF1E6DE5)));
      return;
    }
    final cat = _vehicleCategories.isNotEmpty ? _vehicleCategories[_selectedRide] : null;
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => BookingScreen(
        pickup: _pickup,
        destination: _destination,
        pickupLat: _pickupLat,
        pickupLng: _pickupLng,
        destLat: _destLat,
        destLng: _destLng,
        vehicleCategoryId: cat?['id']?.toString(),
        vehicleCategoryName: cat?['name']?.toString(),
      )));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildDrawer(),
      body: Stack(children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(target: _center, zoom: 14),
          onMapCreated: (c) => _mapController = c,
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
        ),
        SafeArea(
          child: Column(children: [
            _buildTopBar(),
            const Spacer(),
            _buildBottomCard(),
          ]),
        ),
      ]),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(children: [
        GestureDetector(
          onTap: () => _scaffoldKey.currentState?.openDrawer(),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: const Icon(Icons.menu, color: Color(0xFF1A1A2E), size: 22),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Row(children: [
              Expanded(
                child: Text('Hi ${_userName.split(' ').first} 👋',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Color(0xFF1A1A2E))),
              ),
              const Icon(Icons.notifications_none, color: Color(0xFF1E6DE5), size: 22),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _buildBottomCard() {
    final cats = _vehicleCategories;
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 20, offset: const Offset(0, -4))],
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        _locationRow(Icons.location_on, const Color(0xFF1E6DE5), _pickup, 'Current Location'),
        const Padding(padding: EdgeInsets.only(left: 11), child: Divider(height: 12)),
        _locationRow(Icons.location_searching, Colors.grey, _destination, 'Where to?', onTap: _showDestinationSearch),
        const SizedBox(height: 16),
        if (_loading)
          const Center(child: SizedBox(width: 24, height: 24,
            child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1E6DE5))))
        else
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(cats.length, (i) {
                return Padding(
                  padding: EdgeInsets.only(right: i < cats.length - 1 ? 10 : 0),
                  child: _rideTypeCard(i, cats[i]),
                );
              }),
            ),
          ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity, height: 50,
          child: ElevatedButton(
            onPressed: _bookRide,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E6DE5),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: const Text('Continue', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ),
      ]),
    );
  }

  Widget _locationRow(IconData icon, Color color, String value, String hint, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Row(children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(value.isEmpty ? hint : value,
            style: TextStyle(
              fontSize: 14, fontWeight: FontWeight.w500,
              color: value.isEmpty ? Colors.grey[400] : const Color(0xFF1A1A2E),
            )),
        ),
        if (value.isNotEmpty) Icon(Icons.edit_outlined, size: 16, color: Colors.grey[400]),
      ]),
    );
  }

  Widget _rideTypeCard(int i, Map<String, dynamic> cat) {
    final selected = _selectedRide == i;
    final name = cat['name']?.toString() ?? '';
    final type = cat['type']?.toString();
    final minFare = double.tryParse(cat['minimumFare']?.toString() ?? '0') ?? 0;
    final fareLabel = minFare > 0 ? '₹${minFare.toInt()}+' : '—';
    return GestureDetector(
      onTap: () => setState(() => _selectedRide = i),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 90,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF1E6DE5) : const Color(0xFFF5F7FA),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? const Color(0xFF1E6DE5) : Colors.transparent, width: 1.5),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(_iconForVehicle(name, type: type),
            color: selected ? Colors.white : Colors.grey[600], size: 26),
          const SizedBox(height: 4),
          Text(name,
            textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
              color: selected ? Colors.white : Colors.grey[700])),
          Text(fareLabel,
            style: TextStyle(fontSize: 10,
              color: selected ? Colors.white.withOpacity(0.85) : Colors.grey[500])),
        ]),
      ),
    );
  }

  void _showDestinationSearch() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _PlaceSearchSheet(
        pickupLat: _pickupLat,
        pickupLng: _pickupLng,
        onPlaceSelected: (name, lat, lng) {
          setState(() {
            _destination = name;
            _destLat = lat;
            _destLng = lng;
          });
        },
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Container(
        color: const Color(0xFF0D1B4B),
        child: SafeArea(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(children: [
                CircleAvatar(
                  radius: 28, backgroundColor: const Color(0xFF1E6DE5),
                  child: Text(_userName.isNotEmpty ? _userName[0].toUpperCase() : 'U',
                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Hi, ${_userName.split(' ').first}!',
                    style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
                  Text('+91-$_userPhone',
                    style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13)),
                ])),
                IconButton(
                  icon: Icon(Icons.logout, color: Colors.white.withOpacity(0.5), size: 20),
                  onPressed: () => _logout(),
                ),
              ]),
            ),
            const Divider(color: Colors.white12, height: 1),
            const SizedBox(height: 8),
            _drawerItem(Icons.directions_bike, 'My Rides', () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const TripsHistoryScreen()));
            }),
            _drawerItem(Icons.account_balance_wallet, 'Payments', () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const WalletScreen()));
            }),
            _drawerItem(Icons.stars_rounded, 'JAGO Coins', () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const CoinsScreen()));
            }),
            _drawerItem(Icons.card_membership, 'Monthly Pass', () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const MonthlyPassScreen()));
            }),
            _drawerItem(Icons.person_outline, 'Profile', () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
            }),
            _drawerItem(Icons.headset_mic_outlined, 'Support', () {}),
            _drawerItem(Icons.card_giftcard_outlined, 'Refer & Earn', () {}),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text('v1.0.2 • MindWhile IT Solutions',
                style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 11)),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _drawerItem(IconData icon, String label, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.white.withOpacity(0.75), size: 22),
      title: Text(label, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500)),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 2),
    );
  }

  Future<void> _logout() async {
    await AuthService.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(context,
      MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
  }
}

// ── Google Places Search Sheet ─────────────────────────────────────────────
class _PlaceSearchSheet extends StatefulWidget {
  final double pickupLat, pickupLng;
  final Function(String name, double lat, double lng) onPlaceSelected;
  const _PlaceSearchSheet({required this.pickupLat, required this.pickupLng, required this.onPlaceSelected});
  @override
  State<_PlaceSearchSheet> createState() => _PlaceSearchSheetState();
}

class _PlaceSearchSheetState extends State<_PlaceSearchSheet> {
  final _ctrl = TextEditingController();
  List<Map<String, dynamic>> _predictions = [];
  bool _searching = false;
  Timer? _debounce;

  @override
  void dispose() { _ctrl.dispose(); _debounce?.cancel(); super.dispose(); }

  void _onChanged(String q) {
    _debounce?.cancel();
    if (q.length < 2) { setState(() => _predictions = []); return; }
    _debounce = Timer(const Duration(milliseconds: 400), () => _search(q));
  }

  Future<void> _search(String q) async {
    setState(() => _searching = true);
    try {
      final url = 'https://maps.googleapis.com/maps/api/place/autocomplete/json'
        '?input=${Uri.encodeComponent(q)}'
        '&location=${widget.pickupLat},${widget.pickupLng}'
        '&radius=50000'
        '&components=country:in'
        '&key=${ApiConfig.googleMapsApiKey}';
      final res = await http.get(Uri.parse(url));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final preds = (data['predictions'] as List<dynamic>? ?? [])
          .map((p) => {
            'placeId': p['place_id'],
            'description': p['description'],
            'mainText': p['structured_formatting']?['main_text'] ?? p['description'],
            'secondaryText': p['structured_formatting']?['secondary_text'] ?? '',
          }).toList();
        if (mounted) setState(() => _predictions = preds.cast<Map<String, dynamic>>());
      }
    } catch (_) {}
    if (mounted) setState(() => _searching = false);
  }

  Future<void> _selectPlace(Map<String, dynamic> place) async {
    try {
      final placeId = place['placeId'];
      final url = 'https://maps.googleapis.com/maps/api/geocode/json?place_id=$placeId&key=${ApiConfig.googleMapsApiKey}';
      final res = await http.get(Uri.parse(url));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final results = data['results'] as List<dynamic>?;
        if (results != null && results.isNotEmpty) {
          final loc = results[0]['geometry']['location'];
          final lat = (loc['lat'] as num).toDouble();
          final lng = (loc['lng'] as num).toDouble();
          if (mounted) Navigator.pop(context);
          widget.onPlaceSelected(place['description'], lat, lng);
          return;
        }
      }
    } catch (_) {}
    if (mounted) {
      Navigator.pop(context);
      widget.onPlaceSelected(place['description'], 0, 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(height: 12),
        Container(width: 40, height: 4,
          decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            controller: _ctrl,
            autofocus: true,
            onChanged: _onChanged,
            decoration: InputDecoration(
              hintText: 'Where to go?',
              prefixIcon: const Icon(Icons.search, color: Color(0xFF1E6DE5)),
              filled: true, fillColor: const Color(0xFFF5F7FA),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              suffixIcon: _searching
                ? const Padding(padding: EdgeInsets.all(14), child: SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1E6DE5))))
                : null,
            ),
          ),
        ),
        const SizedBox(height: 8),
        ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.45),
          child: _predictions.isEmpty
            ? Padding(
                padding: const EdgeInsets.all(32),
                child: Column(children: [
                  Icon(Icons.location_on_outlined, color: Colors.grey[300], size: 48),
                  const SizedBox(height: 12),
                  Text('Destination search cheyyandi', textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[400], fontSize: 14)),
                ]))
            : ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                itemCount: _predictions.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final p = _predictions[i];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E6DE5).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.location_on, color: Color(0xFF1E6DE5), size: 18)),
                    title: Text(p['mainText'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: p['secondaryText'] != ''
                      ? Text(p['secondaryText'], style: TextStyle(color: Colors.grey[500], fontSize: 12), maxLines: 1)
                      : null,
                    onTap: () => _selectPlace(p),
                  );
                }),
        ),
        const SizedBox(height: 16),
      ]),
    );
  }
}
