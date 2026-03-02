import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/api_config.dart';
import '../../services/auth_service.dart';
import '../../services/trip_service.dart';
import '../../services/socket_service.dart';
import '../../widgets/incoming_trip_sheet.dart';
import '../auth/login_screen.dart';
import '../wallet/wallet_screen.dart';
import '../history/trips_history_screen.dart';
import '../profile/profile_screen.dart';
import '../break_mode/break_mode_screen.dart';
import '../fatigue/fatigue_screen.dart';
import '../trip/trip_screen.dart';
import '../notifications/notifications_screen.dart';
import '../referral/referral_screen.dart';
import '../profile/support_chat_screen.dart';
import '../earnings/earnings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final SocketService _socket = SocketService();
  GoogleMapController? _mapController;
  LatLng _center = const LatLng(16.5062, 80.6480);
  bool _isOnline = false;
  bool _loading = false;
  bool _toggling = false;
  bool _socketConnected = false;
  String _userName = 'Pilot';
  String _userPhone = '';
  double _walletBalance = 0;
  int _tripsToday = 0;
  double _earningsToday = 0;
  int _unreadNotifCount = 0;
  Map<String, dynamic>? _incomingTrip;
  Timer? _locationTimer;
  late AnimationController _pulseCtrl;
  final List<StreamSubscription> _subs = [];

  static const Color _blue = Color(0xFF2563EB);
  static const Color _bg = Color(0xFF060D1E);
  static const Color _surface = Color(0xFF0D1B3E);
  static const Color _green = Color(0xFF16A34A);

  String _getTimeGreeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning ☀️';
    if (h < 17) return 'Good Afternoon 🌤️';
    if (h < 20) return 'Good Evening 🌆';
    return 'Good Night 🌙';
  }

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _loadUser();
    _getLocation();
    _fetchDashboard();
    _connectSocket();
    // Check for pending FCM trip (app opened from notification while terminated)
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkPendingFcmTrip());
  }

  Future<void> _checkPendingFcmTrip() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pendingStr = prefs.getString('pending_trip_data');
      if (pendingStr != null && pendingStr.isNotEmpty) {
        await prefs.remove('pending_trip_data');
        final tripData = jsonDecode(pendingStr) as Map<String, dynamic>;
        if (!mounted) return;
        if (_incomingTrip == null) {
          await Future.delayed(const Duration(milliseconds: 800));
          setState(() => _incomingTrip = tripData);
          _showIncomingTrip();
        }
      }
    } catch (_) {}
  }

  Future<void> _connectSocket() async {
    await _socket.connect(ApiConfig.socketUrl);

    // Listen for connection status
    _subs.add(_socket.onConnectionChanged.listen((connected) {
      if (mounted) setState(() => _socketConnected = connected);
    }));

    // New trip request via real-time socket
    _subs.add(_socket.onNewTrip.listen((trip) {
      if (!mounted) return;
      if (_incomingTrip == null) {
        setState(() => _incomingTrip = trip);
        _showIncomingTrip();
      }
    }));

    // Trip cancelled by customer
    _subs.add(_socket.onTripCancelled.listen((data) {
      if (!mounted) return;
      setState(() => _incomingTrip = null);
      Navigator.of(context).popUntil((r) => r.isFirst);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Customer cancelled the trip', style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
      ));
    }));
  }

  @override
  void dispose() {
    for (final s in _subs) s.cancel();
    _locationTimer?.cancel();
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('user_name') ?? 'Pilot';
      _userPhone = prefs.getString('user_phone') ?? '';
    });
  }

  Future<void> _getLocation() async {
    try {
      await Geolocator.requestPermission();
      final pos = await Geolocator.getCurrentPosition();
      setState(() => _center = LatLng(pos.latitude, pos.longitude));
      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(_center, 15));
    } catch (_) {}
  }

  Future<void> _fetchDashboard() async {
    setState(() => _loading = true);
    final token = await AuthService.getToken();
    try {
      final res = await http.get(Uri.parse(ApiConfig.driverDashboard),
        headers: {'Authorization': 'Bearer $token'});
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          _isOnline = data['isOnline'] ?? false;
          _walletBalance = (data['walletBalance'] ?? 0).toDouble();
          _tripsToday = data['tripsToday'] ?? 0;
          _earningsToday = (data['earningsToday'] ?? 0).toDouble();
        });
        if (_isOnline) _startLocationStreaming();
      }
    } catch (_) {}
    setState(() => _loading = false);
  }

  // Real-time GPS location streaming to server via socket
  void _startLocationStreaming() {
    _locationTimer?.cancel();
    _locationTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      try {
        final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
        final lat = pos.latitude;
        final lng = pos.longitude;
        setState(() => _center = LatLng(lat, lng));

        // Send via socket (real-time)
        _socket.sendLocation(lat: lat, lng: lng, speed: pos.speed);

        // Fallback HTTP if socket not connected
        if (!_socketConnected) {
          final token = await AuthService.getToken();
          await http.post(Uri.parse(ApiConfig.driverLocation),
            headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
            body: jsonEncode({'lat': lat, 'lng': lng}));
        }
      } catch (_) {}
    });
  }

  void _stopLocationStreaming() {
    _locationTimer?.cancel();
    _locationTimer = null;
  }

  void _showIncomingTrip() {
    if (_incomingTrip == null) return;
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (_) => IncomingTripSheet(
        trip: _incomingTrip!,
        onAccept: () async {
          final trip = Map<String, dynamic>.from(_incomingTrip!);
          Navigator.pop(context);
          setState(() => _incomingTrip = null);

          // Accept via socket (real-time) + HTTP fallback
          final tripId = trip['tripId'] ?? trip['id'] ?? '';
          bool accepted = false;
          if (_socketConnected) {
            accepted = await _socket.acceptTrip(tripId);
          }
          if (!accepted) {
            final token = await AuthService.getToken();
            try {
              await http.post(Uri.parse(ApiConfig.driverAcceptTrip),
                headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
                body: jsonEncode({'tripId': tripId}));
            } catch (_) {}
          }
          if (!mounted) return;
          Navigator.push(context, MaterialPageRoute(builder: (_) => TripScreen(trip: trip)));
        },
        onReject: () async {
          final trip = Map<String, dynamic>.from(_incomingTrip!);
          Navigator.pop(context);
          setState(() => _incomingTrip = null);
          final token = await AuthService.getToken();
          try {
            await http.post(Uri.parse(ApiConfig.driverRejectTrip),
              headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
              body: jsonEncode({'tripId': trip['tripId'] ?? trip['id'] ?? ''}));
          } catch (_) {}
        },
      ),
    );
  }

  Future<void> _toggleOnline() async {
    setState(() => _toggling = true);
    final newStatus = !_isOnline;
    try {
      // Update via socket first (instant)
      _socket.setOnlineStatus(
        isOnline: newStatus,
        lat: _center.latitude,
        lng: _center.longitude,
      );

      // Also update via HTTP for persistence
      final token = await AuthService.getToken();
      final res = await http.post(Uri.parse(ApiConfig.driverOnlineStatus),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: jsonEncode({'isOnline': newStatus, 'lat': _center.latitude, 'lng': _center.longitude}));

      if (res.statusCode == 200) {
        setState(() => _isOnline = newStatus);
        if (_isOnline) {
          _startLocationStreaming();
        } else {
          _stopLocationStreaming();
        }
      }
    } catch (_) {}
    setState(() => _toggling = false);
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        key: _scaffoldKey,
        drawer: _buildDrawer(),
        body: Stack(children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: _center, zoom: 14),
            onMapCreated: (c) { _mapController = c; },
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
          ),
          SafeArea(
            child: Column(children: [
              _buildTopBar(),
              const Spacer(),
              _buildBottomPanel(),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(children: [
        _iconBtn(Icons.menu_rounded, () => _scaffoldKey.currentState?.openDrawer()),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.07), width: 1),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 16, offset: const Offset(0, 4))],
            ),
            child: Row(children: [
              Image.asset('assets/images/pilot_logo.png', height: 22, fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Text('PILOT',
                  style: TextStyle(color: Color(0xFF2563EB), fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 2))),
              Container(width: 1, height: 20, color: Colors.white.withOpacity(0.08), margin: const EdgeInsets.symmetric(horizontal: 10)),
              AnimatedBuilder(
                animation: _pulseCtrl,
                builder: (_, __) => Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isOnline ? _green : Colors.grey[600],
                    boxShadow: _isOnline ? [BoxShadow(
                      color: _green.withOpacity(0.4 + _pulseCtrl.value * 0.35),
                      blurRadius: 5 + _pulseCtrl.value * 6,
                      spreadRadius: _pulseCtrl.value * 2,
                    )] : [],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _isOnline ? 'Online — Ready ✓' : 'Offline — Go Online',
                  style: TextStyle(
                    color: _isOnline ? Colors.white : Colors.white.withOpacity(0.45),
                    fontSize: 13, fontWeight: FontWeight.w700),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Socket connection indicator
              Container(
                width: 6, height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _socketConnected ? const Color(0xFF34D399) : Colors.orange,
                ),
              ),
            ]),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()))
              .then((_) => _fetchUnreadCount());
          },
          child: Stack(children: [
            Container(
              width: 46, height: 46,
              decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withOpacity(0.07))),
              child: const Icon(Icons.notifications_outlined, color: Colors.white, size: 22),
            ),
            if (_unreadNotifCount > 0)
              Positioned(
                top: 6, right: 6,
                child: Container(
                  width: 16, height: 16,
                  decoration: const BoxDecoration(color: Color(0xFFEF4444), shape: BoxShape.circle),
                  child: Center(child: Text(
                    _unreadNotifCount > 9 ? '9+' : _unreadNotifCount.toString(),
                    style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900),
                  )),
                ),
              ),
          ]),
        ),
        const SizedBox(width: 8),
        _iconBtn(Icons.my_location_rounded, _getLocation),
      ]),
    );
  }

  Widget _iconBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 46, height: 46,
        decoration: BoxDecoration(
          color: _bg, borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.35), blurRadius: 10, offset: const Offset(0, 3))],
        ),
        child: Icon(icon, color: Colors.white.withOpacity(0.85), size: 20),
      ),
    );
  }

  Widget _buildBottomPanel() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 24, offset: const Offset(0, -4))],
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 36, height: 4,
          margin: const EdgeInsets.only(top: 10, bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.12),
            borderRadius: BorderRadius.circular(2)),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          child: Column(children: [
            // Time-based greeting + status indicator
            Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_getTimeGreeting(), style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 11, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(_userName.split(' ').first.isNotEmpty ? _userName.split(' ').first : 'Pilot',
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
              ])),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: (_isOnline ? _green : Colors.grey[700]!).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: (_isOnline ? _green : Colors.grey[600]!).withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  AnimatedBuilder(
                    animation: _pulseCtrl,
                    builder: (_, __) => Container(
                      width: 6, height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isOnline ? _green : Colors.grey[500],
                        boxShadow: _isOnline ? [BoxShadow(
                          color: _green.withOpacity(0.5 + _pulseCtrl.value * 0.3),
                          blurRadius: 4 + _pulseCtrl.value * 4,
                        )] : [],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(_isOnline ? 'Online' : 'Offline',
                    style: TextStyle(
                      color: _isOnline ? _green : Colors.grey[500]!,
                      fontSize: 11, fontWeight: FontWeight.w800,
                    )),
                ]),
              ),
            ]),
            const SizedBox(height: 14),
            _buildStatsRow(),
            const SizedBox(height: 16),
            _buildToggleBtn(),
            const SizedBox(height: 12),
            _buildActionRow(),
            const SizedBox(height: 20),
          ]),
        ),
      ]),
    );
  }

  Widget _buildStatsRow() {
    return Row(children: [
      _statTile('Today Earnings', '₹${_earningsToday.toStringAsFixed(0)}', Icons.currency_rupee_rounded, const Color(0xFF10B981)),
      const SizedBox(width: 10),
      _statTile('Trips Today', '$_tripsToday', Icons.route_rounded, _blue),
      const SizedBox(width: 10),
      _statTile('Wallet', '₹${_walletBalance.toStringAsFixed(0)}', Icons.account_balance_wallet_rounded, const Color(0xFFF59E0B)),
    ]);
  }

  Widget _statTile(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.15), width: 1),
        ),
        child: Column(children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 9, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
        ]),
      ),
    );
  }

  Widget _buildToggleBtn() {
    final isOn = _isOnline;
    return GestureDetector(
      onTap: _toggling ? null : _toggleOnline,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Multi-ring pulse animation when online
          if (isOn) ...[
            AnimatedBuilder(
              animation: _pulseCtrl,
              builder: (_, __) => Container(
                width: double.infinity,
                height: 60 + (_pulseCtrl.value * 16),
                margin: EdgeInsets.symmetric(vertical: -(_pulseCtrl.value * 8)),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16 + _pulseCtrl.value * 4),
                  border: Border.all(
                    color: _green.withOpacity(0.5 - _pulseCtrl.value * 0.5),
                    width: 1.5,
                  ),
                ),
              ),
            ),
            AnimatedBuilder(
              animation: _pulseCtrl,
              builder: (_, __) {
                final delay = (_pulseCtrl.value + 0.5) % 1.0;
                return Container(
                  width: double.infinity,
                  height: 60 + (delay * 24),
                  margin: EdgeInsets.symmetric(vertical: -(delay * 12)),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16 + delay * 6),
                    border: Border.all(
                      color: _green.withOpacity(0.3 - delay * 0.3),
                      width: 1,
                    ),
                  ),
                );
              },
            ),
          ],
          AnimatedContainer(
            duration: const Duration(milliseconds: 450),
            curve: Curves.easeInOutCubic,
            width: double.infinity,
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isOn
                  ? [const Color(0xFF15803D), const Color(0xFF16A34A), const Color(0xFF22C55E)]
                  : [const Color(0xFF1E3A8A), _blue],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(
                color: (isOn ? _green : _blue).withOpacity(isOn ? 0.5 : 0.3),
                blurRadius: isOn ? 22 : 14,
                spreadRadius: isOn ? 2 : 0,
                offset: const Offset(0, 5),
              )],
            ),
            child: Center(
              child: _toggling
                ? Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const SizedBox(width: 22, height: 22,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)),
                    const SizedBox(width: 12),
                    Text(
                      isOn ? 'Going Offline...' : 'Going Online...',
                      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                  ])
                : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Icon(
                        isOn ? Icons.power_settings_new_rounded : Icons.play_arrow_rounded,
                        key: ValueKey(isOn),
                        color: Colors.white, size: 26,
                      ),
                    ),
                    const SizedBox(width: 12),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Text(
                        isOn ? 'Online — Trip కోసం Ready ✓' : 'Go Online — Earn చేయండి',
                        key: ValueKey(isOn),
                        style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 0.2),
                      ),
                    ),
                  ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionRow() {
    return Row(children: [
      Expanded(child: _actionChip(Icons.coffee_rounded, 'Break', const Color(0xFFF59E0B), () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const BreakModeScreen()));
      })),
      const SizedBox(width: 10),
      Expanded(child: _actionChip(Icons.account_balance_wallet_rounded, 'Wallet', const Color(0xFF10B981), () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const WalletScreen()));
      })),
      const SizedBox(width: 10),
      Expanded(child: _actionChip(Icons.history_rounded, 'Trips', _blue, () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const TripsHistoryScreen()));
      })),
    ]);
  }

  Widget _actionChip(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.15), width: 1),
        ),
        child: Column(children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
        ]),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Container(
        color: _surface,
        child: SafeArea(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_blue.withOpacity(0.3), _blue.withOpacity(0.1)],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _blue.withOpacity(0.2), width: 1),
              ),
              child: Row(children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: _blue,
                  child: Text(_userName.isNotEmpty ? _userName[0].toUpperCase() : 'P',
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(_userName, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text('+91 $_userPhone',
                    style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
                  const SizedBox(height: 6),
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _blue.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(6)),
                      child: const Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.verified_rounded, color: Color(0xFF60A5FA), size: 12),
                        SizedBox(width: 4),
                        Text('JAGO PILOT', style: TextStyle(color: Color(0xFF60A5FA), fontSize: 10, fontWeight: FontWeight.w800)),
                      ]),
                    ),
                  ]),
                ])),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Divider(color: Colors.white.withOpacity(0.08), height: 1),
            ),
            const SizedBox(height: 8),
            _drawerItem(Icons.dashboard_rounded, 'Dashboard', null, () {}),
            _drawerItem(Icons.currency_rupee_rounded, 'Earnings', '₹${_earningsToday.toStringAsFixed(0)}', () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const EarningsScreen()));
            }),
            _drawerItem(Icons.route_rounded, 'My Trips', null, () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const TripsHistoryScreen()));
            }),
            _drawerItem(Icons.account_balance_wallet_rounded, 'Wallet', '₹${_walletBalance.toStringAsFixed(0)}', () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const WalletScreen()));
            }),
            _drawerItem(Icons.person_rounded, 'Profile', null, () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
            }),
            _drawerItem(Icons.health_and_safety_rounded, 'Safety & Fatigue', null, () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const FatigueScreen()));
            }),
            _drawerItem(Icons.headset_mic_rounded, 'Support', null, () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const DriverSupportChatScreen()));
            }),
            _drawerItem(Icons.card_giftcard_rounded, 'Refer & Earn', null, () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ReferralScreen()));
            }),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: GestureDetector(
                onTap: () async {
                  _socket.disconnect();
                  await AuthService.logout();
                  if (!mounted) return;
                  Navigator.pushAndRemoveUntil(context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.withOpacity(0.2), width: 1),
                  ),
                  child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.logout_rounded, color: Color(0xFFF87171), size: 18),
                    SizedBox(width: 8),
                    Text('Logout', style: TextStyle(color: Color(0xFFF87171), fontWeight: FontWeight.w700, fontSize: 14)),
                  ]),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Center(child: Text('v1.0.0 • MindWhile IT Solutions',
                style: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 10))),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _drawerItem(IconData icon, String label, String? badge, VoidCallback onTap) {
    return ListTile(
      leading: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: _blue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: _blue, size: 18),
      ),
      title: Text(label, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
      trailing: badge != null
        ? Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.15),
              borderRadius: BorderRadius.circular(8)),
            child: Text(badge, style: const TextStyle(color: Color(0xFF10B981), fontSize: 12, fontWeight: FontWeight.w700)))
        : Icon(Icons.chevron_right, color: Colors.white.withOpacity(0.2), size: 18),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
    );
  }
}
