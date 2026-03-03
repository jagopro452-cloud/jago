import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../../config/api_config.dart';
import '../../services/auth_service.dart';
import '../../services/socket_service.dart';
import '../home/home_screen.dart';
import '../tip/tip_driver_screen.dart';

class TrackingScreen extends StatefulWidget {
  final String tripId;
  const TrackingScreen({super.key, required this.tripId});
  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> with TickerProviderStateMixin {
  final SocketService _socket = SocketService();
  GoogleMapController? _mapController;
  LatLng _center = const LatLng(17.3850, 78.4867);
  LatLng? _driverLatLng;
  String _status = 'searching';
  Map<String, dynamic>? _trip;
  Timer? _pollTimer;
  int _rated = 0;
  List<String> _cancelReasons = [];
  late AnimationController _pulseCtrl;
  final Set<Marker> _markers = {};
  final List<StreamSubscription> _subs = [];

  static const Color _blue = Color(0xFF1E6DE5);
  static const Color _green = Color(0xFF16A34A);

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _connectSocket();
    _pollStatus();
    _loadCancelReasons();
    // HTTP polling as fallback (every 8s — socket handles real-time)
    _pollTimer = Timer.periodic(const Duration(seconds: 8), (_) => _pollStatus());
  }

  void _connectSocket() {
    _socket.connect(ApiConfig.socketUrl).then((_) {
      // Join this trip's tracking room
      _socket.trackTrip(widget.tripId);

      // Real-time driver GPS location
      _subs.add(_socket.onDriverLocation.listen((data) {
        if (!mounted) return;
        final lat = (data['lat'] as num?)?.toDouble();
        final lng = (data['lng'] as num?)?.toDouble();
        if (lat != null && lng != null) {
          setState(() {
            _driverLatLng = LatLng(lat, lng);
            _updateDriverMarker(_driverLatLng!);
          });
        }
      }));

      // Real-time trip status changes
      _subs.add(_socket.onTripStatus.listen((data) {
        if (!mounted) return;
        final newStatus = data['status']?.toString() ?? _status;
        final otp = data['otp']?.toString();
        setState(() {
          _status = newStatus;
          if (otp != null && _trip != null) {
            _trip!['pickupOtp'] = otp;
          }
        });
        if (newStatus == 'completed' || newStatus == 'cancelled') {
          _pollTimer?.cancel();
          _pollStatus(); // fetch final state
        }
      }));

      // Driver assigned (from searching state)
      _subs.add(_socket.onDriverAssigned.listen((data) {
        if (!mounted) return;
        setState(() => _status = 'driver_assigned');
        _pollStatus();
      }));

      // Trip cancelled by driver
      _subs.add(_socket.onTripCancelled.listen((data) {
        if (!mounted) return;
        setState(() => _status = 'cancelled');
        _pollTimer?.cancel();
      }));
    });
  }

  void _updateDriverMarker(LatLng pos) {
    _markers.removeWhere((m) => m.markerId.value == 'driver');
    _markers.add(Marker(
      markerId: const MarkerId('driver'),
      position: pos,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      infoWindow: const InfoWindow(title: 'Your Pilot'),
    ));
    _mapController?.animateCamera(CameraUpdate.newLatLng(pos));
  }

  @override
  void dispose() {
    for (final s in _subs) s.cancel();
    _pollTimer?.cancel();
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCancelReasons() async {
    try {
      final res = await http.get(Uri.parse(ApiConfig.configs));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final reasons = (data['cancellationReasons'] as List<dynamic>? ?? [])
          .where((r) => r['userType'] == 'customer' || r['user_type'] == 'customer')
          .map((r) => r['reason']?.toString() ?? '')
          .where((r) => r.isNotEmpty)
          .toList();
        if (mounted) setState(() => _cancelReasons = reasons);
      }
    } catch (_) {}
  }

  Future<void> _pollStatus() async {
    final token = await AuthService.getToken();
    try {
      final res = await http.get(Uri.parse(ApiConfig.activeTrip),
        headers: {'Authorization': 'Bearer $token'});
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final trip = data['trip'];
        if (trip != null && mounted) {
          final dLat = (trip['driverLat'] as num?)?.toDouble();
          final dLng = (trip['driverLng'] as num?)?.toDouble();
          setState(() {
            _trip = trip;
            _status = trip['currentStatus'] ?? _status;
            if (dLat != null && dLng != null && dLat != 0) {
              _driverLatLng = LatLng(dLat, dLng);
              _updateDriverMarker(_driverLatLng!);
            }
            // Update map to pickup position
            final pLat = (trip['pickupLat'] as num?)?.toDouble();
            final pLng = (trip['pickupLng'] as num?)?.toDouble();
            if (pLat != null && pLng != null && pLat != 0) {
              _center = LatLng(pLat, pLng);
            }
          });
          if (_status == 'completed' || _status == 'cancelled') _pollTimer?.cancel();
        }
      }
    } catch (_) {}
  }

  Future<void> _cancelTrip(String reason) async {
    // Cancel via socket first
    _socket.cancelTrip(_trip?['id']?.toString() ?? widget.tripId);
    // Also HTTP for persistence
    final token = await AuthService.getToken();
    try {
      await http.post(Uri.parse(ApiConfig.cancelTrip),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: jsonEncode({'tripId': _trip?['id'] ?? widget.tripId, 'reason': reason}));
    } catch (_) {}
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(context,
      MaterialPageRoute(builder: (_) => const HomeScreen()), (_) => false);
  }

  Future<void> _rateDriver(int stars) async {
    setState(() => _rated = stars);
    final token = await AuthService.getToken();
    try {
      await http.post(Uri.parse(ApiConfig.rateDriver),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: jsonEncode({
          'tripId': _trip?['id'] ?? widget.tripId,
          'driverId': _trip?['driverId'],
          'rating': stars,
        }));
    } catch (_) {}
  }

  void _showCancelDialog() {
    final reasons = _cancelReasons.isNotEmpty ? _cancelReasons : [
      'Driver is taking too long',
      'I booked by mistake',
      'Changed travel plans',
      'Other reason',
    ];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          Row(children: [
            Container(padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.red.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.cancel_rounded, color: Color(0xFFEF4444), size: 20)),
            const SizedBox(width: 12),
            const Text('Cancel Reason', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF111827))),
          ]),
          const SizedBox(height: 16),
          ...reasons.map((r) => ListTile(
            title: Text(r, style: const TextStyle(fontSize: 14, color: Color(0xFF374151), fontWeight: FontWeight.w500)),
            leading: Icon(Icons.chevron_right_rounded, color: Colors.grey[400], size: 18),
            contentPadding: EdgeInsets.zero,
            dense: true,
            onTap: () { Navigator.pop(context); _cancelTrip(r); },
          )),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final statusInfo = _getStatusInfo(_status);
    final trip = _trip;
    final otp = trip?['pickupOtp']?.toString() ?? trip?['pickup_otp']?.toString();
    final driverName = trip?['driverName']?.toString() ?? trip?['driver_name']?.toString();
    final driverPhone = trip?['driverPhone']?.toString() ?? trip?['driver_phone']?.toString();
    final driverRating = trip?['driverRating'] ?? trip?['driver_rating'];
    final actualFare = trip?['actualFare'] ?? trip?['actual_fare'];
    final estimatedFare = trip?['estimatedFare'] ?? trip?['estimated_fare'];

    return WillPopScope(
      onWillPop: () async {
        if (_status == 'completed' || _status == 'cancelled') return true;
        return false;
      },
      child: Scaffold(
        body: Stack(children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: _center, zoom: 15),
            onMapCreated: (c) {
              _mapController = c;
              if (_driverLatLng != null) _updateDriverMarker(_driverLatLng!);
            },
            markers: _markers,
            myLocationEnabled: true,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
          ),
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [BoxShadow(color: Color(0x22000000), blurRadius: 24)],
              ),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 40, height: 4,
                  margin: const EdgeInsets.only(top: 10, bottom: 4),
                  decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(2))),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _buildStatusHeader(statusInfo),
                    if (driverName != null && _status != 'searching') ...[
                      const SizedBox(height: 14),
                      _buildDriverCard(driverName, driverPhone, driverRating),
                    ],
                    if (otp != null && otp.isNotEmpty &&
                        (_status == 'driver_assigned' || _status == 'accepted' || _status == 'arrived')) ...[
                      const SizedBox(height: 12),
                      _buildOtpBox(otp),
                    ],
                    if (trip != null) ...[
                      const SizedBox(height: 12),
                      _buildFareRow(trip, actualFare, estimatedFare),
                    ],
                    if (_status == 'completed') ...[
                      const SizedBox(height: 16),
                      _buildCompletedCard(actualFare),
                    ] else if (_status == 'cancelled') ...[
                      const SizedBox(height: 16),
                      _buildCancelledCard(),
                    ] else ...[
                      const SizedBox(height: 16),
                      Row(children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: _showCancelDialog,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: [Colors.red.withOpacity(0.15), Colors.red.withOpacity(0.07)]),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: Colors.red.withOpacity(0.3)),
                              ),
                              child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                Icon(Icons.cancel_rounded, size: 16, color: Color(0xFFEF4444)),
                                SizedBox(width: 6),
                                Text('Cancel', style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.w800, fontSize: 13)),
                              ]),
                            ),
                          )),
                        const SizedBox(width: 10),
                        Expanded(
                          child: GestureDetector(
                            onTap: () async {
                              final phone = await _getSupportPhone();
                              final uri = Uri(scheme: 'tel', path: phone);
                              if (await canLaunchUrl(uri)) await launchUrl(uri);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: [Colors.green.withOpacity(0.15), Colors.green.withOpacity(0.07)]),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: Colors.green.withOpacity(0.35)),
                              ),
                              child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                Icon(Icons.phone_in_talk_rounded, size: 16, color: Colors.green),
                                SizedBox(width: 6),
                                Text('Support', style: TextStyle(color: Colors.green, fontWeight: FontWeight.w800, fontSize: 13)),
                              ]),
                            ),
                          )),
                      ]),
                    ],
                  ]),
                ),
              ]),
            ),
          ),
        ]),
      ),
    );
  }


  Future<String> _getSupportPhone() async {
    try {
      final r = await http.get(Uri.parse(ApiConfig.configs));
      if (r.statusCode == 200) {
        final data = jsonDecode(r.body);
        return data['configs']?['support_phone'] ?? '+916303000000';
      }
    } catch (_) {}
    return '+916303000000';
  }

  Widget _buildStatusHeader(Map<String, dynamic> info) {
    final color = info['color'] as Color;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.18), width: 1),
      ),
      child: Row(children: [
        if (_status == 'searching')
          AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (_, __) => Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity(0.1 + _pulseCtrl.value * 0.1),
              ),
              child: Icon(info['icon'] as IconData, color: color, size: 22)),
          )
        else
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(info['icon'] as IconData, color: color, size: 22)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(info['label'] as String,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: color)),
          if (_status == 'searching')
            Text('Real-time లో nearby pilots search avutundi...',
              style: TextStyle(color: Colors.grey[500], fontSize: 12)),
          if (_driverLatLng != null && _status != 'searching' && _status != 'completed' && _status != 'cancelled')
            Text('Live tracking active 📍',
              style: TextStyle(color: _green, fontSize: 11, fontWeight: FontWeight.w600)),
        ])),
        if (_status == 'searching')
          SizedBox(width: 20, height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: color))
        else if (_status != 'completed' && _status != 'cancelled')
          GestureDetector(
            onTap: _shareRide,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFF1E6DE5).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.share_rounded, color: Color(0xFF1E6DE5), size: 15),
                const SizedBox(width: 4),
                const Text('Share', style: TextStyle(color: Color(0xFF1E6DE5), fontSize: 11, fontWeight: FontWeight.w700)),
              ]),
            ),
          ),
      ]),
    );
  }

  Widget _buildDriverCard(String name, String? phone, dynamic rating) {
    final driverModel = _trip?['driverVehicleModel'] ?? '';
    final driverVehicle = _trip?['driverVehicleNumber'] ?? '';
    final vehicleName = _trip?['vehicleName'] ?? '';
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFFF0F4FF), const Color(0xFFF8FAFF)],
          begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _blue.withOpacity(0.15), width: 1.5),
        boxShadow: [BoxShadow(color: _blue.withOpacity(0.08), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_blue, const Color(0xFF1244A2)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: _blue.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4))],
              ),
              child: Center(child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'P',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20))),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15,
                color: Color(0xFF0F172A), letterSpacing: -0.3)),
              const SizedBox(height: 3),
              Row(children: [
                const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                const SizedBox(width: 3),
                Text(rating?.toString() ?? '5.0',
                  style: const TextStyle(color: Color(0xFF374151), fontSize: 12, fontWeight: FontWeight.w700)),
                if (vehicleName.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: _blue.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(6)),
                    child: Text(vehicleName, style: TextStyle(color: _blue, fontSize: 10, fontWeight: FontWeight.w800)),
                  ),
                ],
              ]),
            ])),
            Row(children: [
              if (phone != null) ...[
                GestureDetector(
                  onTap: () async {
                    final uri = Uri(scheme: 'tel', path: phone);
                    if (await canLaunchUrl(uri)) await launchUrl(uri);
                    else if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Pilot: $phone'), backgroundColor: _blue, behavior: SnackBarBehavior.floating));
                  },
                  child: Container(
                    width: 42, height: 42,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [_blue, const Color(0xFF1244A2)]),
                      borderRadius: BorderRadius.circular(13),
                      boxShadow: [BoxShadow(color: _blue.withOpacity(0.35), blurRadius: 8, offset: const Offset(0,3))],
                    ),
                    child: const Icon(Icons.phone_rounded, color: Colors.white, size: 20)),
                ),
                const SizedBox(width: 8),
              ],
              GestureDetector(
                onTap: _triggerSos,
                child: Container(
                  width: 42, height: 42,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [const Color(0xFF7F1D1D), Colors.red]),
                    borderRadius: BorderRadius.circular(13),
                    boxShadow: [BoxShadow(color: Colors.red.withOpacity(0.35), blurRadius: 8, offset: const Offset(0,3))],
                  ),
                  child: const Icon(Icons.sos_rounded, color: Colors.white, size: 20)),
              ),
            ]),
          ]),
        ),
        if (driverVehicle.isNotEmpty || driverModel.isNotEmpty)
          Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _blue.withOpacity(0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _blue.withOpacity(0.12))),
            child: Row(children: [
              Icon(Icons.directions_car_rounded, color: _blue, size: 14),
              const SizedBox(width: 6),
              Text(
                [if (driverVehicle.isNotEmpty) driverVehicle.toUpperCase(), if (driverModel.isNotEmpty) driverModel].join(' · '),
                style: TextStyle(color: _blue, fontSize: 11, fontWeight: FontWeight.w700)),
            ]),
          ),
      ]),
    );
  }

  Future<void> _shareRide() async {
    final tripId = widget.tripId;
    final shareText = '🚗 JAGO ride track చేయండి!\nReal-time location: https://jagopro.org/track/$tripId\nJAGO app download: https://jagopro.org/download';
    final encoded = Uri.encodeComponent(shareText);
    final uri = Uri.parse('whatsapp://send?text=$encoded');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      await Clipboard.setData(ClipboardData(text: shareText));
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Share text copied! Paste in WhatsApp'), backgroundColor: Color(0xFF1E6DE5)));
    }
  }

  Future<void> _triggerSos() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('🚨 SOS Alert', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Emergency SOS పంపాలా? Help team వెంటనే contact అవుతారు.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('SOS పంపు', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
        ],
      ),
    );
    if (confirm != true) return;
    final token = await AuthService.getToken();
    try {
      await http.post(Uri.parse(ApiConfig.sos),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: jsonEncode({
          'tripId': widget.tripId,
          'lat': _center.latitude,
          'lng': _center.longitude,
          'message': 'Customer SOS alert during trip',
        }));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('🚨 SOS Alert sent! Help is on the way.', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('SOS failed. Call 100 immediately!', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  Widget _buildOtpBox(String otp) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withOpacity(0.35), width: 1.5),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.lock_rounded, color: Colors.orange, size: 20)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Share this OTP with Pilot',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: Colors.orange)),
          Text(otp,
            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: Color(0xFF111827), letterSpacing: 10)),
        ])),
        GestureDetector(
          onTap: () {
            Clipboard.setData(ClipboardData(text: otp));
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: const Text('OTP copied!', style: TextStyle(fontWeight: FontWeight.w600)),
              backgroundColor: Colors.orange[700],
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ));
          },
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.copy_rounded, color: Colors.orange, size: 16)),
        ),
      ]),
    );
  }

  Widget _buildFareRow(Map<String, dynamic> trip, dynamic actualFare, dynamic estimatedFare) {
    final fareVal = actualFare ?? estimatedFare;
    final dist = trip['estimatedDistance'] ?? trip['estimated_distance'];
    final vehicle = trip['vehicleName'] ?? trip['vehicle_name'];
    return Wrap(spacing: 8, children: [
      if (fareVal != null) _chip(Icons.currency_rupee_rounded, '₹$fareVal', _blue),
      if (dist != null) _chip(Icons.route_rounded, '$dist km', const Color(0xFF6B7280)),
      if (vehicle != null) _chip(Icons.electric_bike, vehicle.toString(), const Color(0xFF6B7280)),
    ]);
  }

  Widget _chip(IconData icon, String label, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 5),
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
      ]),
    );
  }

  Widget _buildCompletedCard(dynamic actualFare) {
    return Column(children: [
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _green.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _green.withOpacity(0.2), width: 1),
        ),
        child: Column(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: _green.withOpacity(0.1), shape: BoxShape.circle),
            child: const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 32)),
          const SizedBox(height: 10),
          const Text('Trip Completed! 🎉',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF111827))),
          if (actualFare != null) ...[
            const SizedBox(height: 4),
            Text('₹$actualFare',
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF16A34A))),
          ],
          if (_rated == 0) ...[
            const SizedBox(height: 16),
            const Text('Pilot rate cheyyandi',
              style: TextStyle(fontSize: 13, color: Color(0xFF6B7280), fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              for (int i = 1; i <= 5; i++)
                GestureDetector(
                  onTap: () => _rateDriver(i),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Icon(Icons.star_rounded,
                      color: i <= _rated ? Colors.amber : Colors.grey[200], size: 38))),
            ]),
          ] else ...[
            const SizedBox(height: 12),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.favorite_rounded, color: Color(0xFF1E6DE5), size: 16),
              const SizedBox(width: 6),
              Text('Thanks for rating! JAGO use చేసినందుకు 🙏',
                style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.w500)),
            ]),
          ],
        ]),
      ),
      const SizedBox(height: 12),
      Builder(builder: (ctx) {
        final dName = _trip?['driverName']?.toString() ?? _trip?['driver_name']?.toString() ?? 'Pilot';
        final tId = _trip?['id']?.toString() ?? widget.tripId;
        return OutlinedButton.icon(
          onPressed: () => Navigator.push(context, MaterialPageRoute(
            builder: (_) => TipDriverScreen(tripId: tId, driverName: dName))),
          icon: const Icon(Icons.volunteer_activism_rounded, color: Color(0xFF16A34A), size: 18),
          label: const Text('Tip Pilot ఇవ్వండి 💚', style: TextStyle(color: Color(0xFF16A34A), fontWeight: FontWeight.w700, fontSize: 13)),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 46),
            side: const BorderSide(color: Color(0xFF16A34A), width: 1.5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
        );
      }),
      const SizedBox(height: 8),
      SizedBox(
        width: double.infinity, height: 52,
        child: ElevatedButton(
          onPressed: () => Navigator.pushAndRemoveUntil(context,
            MaterialPageRoute(builder: (_) => const HomeScreen()), (_) => false),
          style: ElevatedButton.styleFrom(
            backgroundColor: _blue, foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0),
          child: const Text('Done →', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        )),
    ]);
  }

  Widget _buildCancelledCard() {
    return Column(children: [
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.withOpacity(0.15)),
        ),
        child: Row(children: [
          Container(padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.red.withOpacity(0.08), shape: BoxShape.circle),
            child: const Icon(Icons.cancel_rounded, color: Color(0xFFEF4444), size: 22)),
          const SizedBox(width: 12),
          const Expanded(child: Text('Trip cancelled. Sorry for the inconvenience.',
            style: TextStyle(color: Color(0xFF374151), fontSize: 13, fontWeight: FontWeight.w500))),
        ]),
      ),
      const SizedBox(height: 12),
      SizedBox(
        width: double.infinity, height: 52,
        child: ElevatedButton(
          onPressed: () => Navigator.pushAndRemoveUntil(context,
            MaterialPageRoute(builder: (_) => const HomeScreen()), (_) => false),
          style: ElevatedButton.styleFrom(
            backgroundColor: _blue, foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0),
          child: const Text('New Ride Book Cheyyandi →', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
        )),
    ]);
  }

  Map<String, dynamic> _getStatusInfo(String status) {
    switch (status) {
      case 'searching': return {'label': 'Pilot Search avutundi...', 'icon': Icons.search_rounded, 'color': Colors.orange};
      case 'driver_assigned': return {'label': 'Pilot Assign ayyadu! 🎉', 'icon': Icons.electric_bike, 'color': _blue};
      case 'accepted': return {'label': 'Pilot vachestunnadu 🏍️', 'icon': Icons.navigation_rounded, 'color': _blue};
      case 'arrived': return {'label': 'Pilot Arrived! 📍', 'icon': Icons.where_to_vote_rounded, 'color': _green};
      case 'in_progress': return {'label': 'Trip lo undi 🚀', 'icon': Icons.speed_rounded, 'color': _blue};
      case 'completed': return {'label': 'Trip Completed! ✅', 'icon': Icons.check_circle_rounded, 'color': _green};
      case 'cancelled': return {'label': 'Trip Cancelled', 'icon': Icons.cancel_rounded, 'color': Colors.red};
      default: return {'label': 'Loading...', 'icon': Icons.hourglass_empty_rounded, 'color': Colors.grey};
    }
  }
}
