import 'dart:async';
import 'dart:convert';
import 'dart:math' show max, min;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/api_config.dart';
import '../../config/jago_theme.dart';
import '../../services/auth_service.dart';
import '../../services/active_ride_persistence_service.dart';
import '../../services/trip_navigation_controller.dart';
import '../../services/socket_service.dart';
import '../../services/call_service.dart';
import '../call/call_screen.dart';
import '../chat/trip_chat_sheet.dart';
import '../home/home_screen.dart';

// Quick polyline decoder (no extra package needed)
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

// ─────────────────────────────────────────────────────────────────────────────

class TripScreen extends StatefulWidget {
  final Map<String, dynamic>? trip;
  const TripScreen({super.key, this.trip});
  @override
  State<TripScreen> createState() => _TripScreenState();
}

class _TripScreenState extends State<TripScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  final SocketService _socket = SocketService();
  GoogleMapController? _mapController;
  LatLng _center = const LatLng(17.3850, 78.4867);
  String _status = 'accepted';
  Map<String, dynamic>? _trip;
  bool _loading = false;
  bool _nearPickup = false;
  final _otpCtrl = TextEditingController();
  Timer? _locationTimer;
  StreamSubscription<Position>? _posStream;
  Position? _lastTripPosition;
  Timer? _tripTimer;
  Timer? _statePollTimer; // 5s poll — server is source of truth
  List<String> _cancelReasons = [];
  StreamSubscription? _cancelSub;
  StreamSubscription? _incomingCallSub;
  StreamSubscription? _tripStatusSub;
  StreamSubscription? _tripRecoveredSub;
  StreamSubscription? _socketConnSub;
  bool _locationWarningShown = false;
  bool _hasLiveLocationAccess = false;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  Timer? _waitingLifecycleTimer;
  int _lastTripEventAtMs = 0;
  String _lastTripStateVersion = '';
  int _lastRouteRefreshAtMs = 0;
  int _lastCameraSyncAtMs = 0;
  String _lastRouteKey = '';
  String _lastCameraViewKey = '';
  LatLng? _lastRouteOriginLatLng;
  String? _routeIssue;
  int _arrivedGeofenceMeters = 250;
  int _waitingElapsedSeconds = 0;
  int _waitingBillableSeconds = 0;
  int _waitingGraceSeconds = 0;
  double _waitingCharge = 0;
  double _waitingChargePerMin = 0;
  bool _waitingActive = false;
  bool _internalNavigationActive = true;

  // Live stats
  double _distanceToTargetM = 0;
  int _etaSec = 0;
  int _tripElapsedSec = 0;
  DateTime? _tripStartTime;

  // Animation for status pill
  late AnimationController _pulseCtrl;

  String get _tripId =>
      (_trip?['id'] ?? _trip?['tripId'] ?? widget.trip?['id'] ?? widget.trip?['tripId'] ?? '')
          .toString();

  String _normalizedStatus(String? raw) {
    final status = (raw ?? '').trim().toLowerCase();
    switch (status) {
      case 'payment_pending':
        return 'payment_pending';
      case 'waiting_for_otp':
        return 'otp_pending';
      case 'trip_started':
        return 'in_progress';
      case 'cancelled_by_user':
      case 'cancelled_by_driver':
      case 'cancelled_by_admin':
        return 'cancelled';
      default:
        return status;
    }
  }

  String _lifecycleStatusFromTrip(Map<String, dynamic>? trip, {String fallback = 'accepted'}) {
    final explicit = (trip?['currentStatus'] ??
            trip?['current_status'] ??
            trip?['status'])
        ?.toString()
        .trim();
    if (explicit != null && explicit.isNotEmpty) {
      return explicit;
    }
    final canonical = trip?['canonicalState']?.toString().trim();
    if (canonical != null && canonical.isNotEmpty) {
      return canonical;
    }
    return fallback;
  }

  String _canonicalizeRouteState(String? raw) {
    final status = _normalizedStatus(raw);
    switch (status) {
      case 'driver_assigned':
      case 'accepted':
      case 'heading_to_pickup':
        return 'heading_to_pickup';
      case 'arrived':
      case 'waiting':
      case 'otp_pending':
        return status;
      case 'otp_verified':
      case 'in_progress':
      case 'on_the_way':
      case 'heading_to_destination':
        return status == 'otp_verified' ? 'heading_to_destination' : status;
      case 'payment_pending':
        return 'completed';
      case 'completed':
      case 'cancelled':
        return status;
      default:
        return status;
    }
  }

  String _resolvedTripStatus(Map<String, dynamic>? trip, {String fallback = 'accepted'}) {
    final lifecycleStatus =
        _normalizedStatus(_lifecycleStatusFromTrip(trip, fallback: fallback));
    if (lifecycleStatus == 'payment_pending') {
      return lifecycleStatus;
    }
    return _canonicalizeRouteState(lifecycleStatus);
  }

  double _tripDouble(Map<String, dynamic>? trip, List<String> keys) {
    if (trip == null) return 0;
    for (final key in keys) {
      final value = double.tryParse(trip[key]?.toString() ?? '');
      if (value != null && value != 0) return value;
    }
    return 0;
  }

  String _tripString(
    Map<String, dynamic>? trip,
    List<String> keys, {
    String fallback = '',
  }) {
    if (trip == null) return fallback;
    for (final key in keys) {
      final value = trip[key]?.toString().trim() ?? '';
      if (value.isNotEmpty) return value;
    }
    return fallback;
  }

  bool get _isPrePickupStage => _isPickupNavigationStage || _isPickupArrivalStage;

  String get _canonicalRouteState {
    final raw = (_trip?['canonicalState'] ??
            _trip?['currentStatus'] ??
            _trip?['current_status'] ??
            _trip?['status'])
        ?.toString()
        .trim()
        .toLowerCase();
    if (raw != null && raw.isNotEmpty) {
      return _canonicalizeRouteState(raw);
    }
    return _canonicalizeRouteState(_status);
  }

  bool get _isPickupNavigationStage =>
      _canonicalRouteState == 'accepted' ||
      _canonicalRouteState == 'driver_assigned' ||
      _canonicalRouteState == 'heading_to_pickup';

  bool get _isPickupArrivalStage =>
      _canonicalRouteState == 'arrived' ||
      _canonicalRouteState == 'waiting' ||
      _canonicalRouteState == 'otp_pending' ||
      _canonicalRouteState == 'waiting_for_otp';

  bool get _isDestinationNavigationStage =>
      _canonicalRouteState == 'otp_verified' ||
      _canonicalRouteState == 'in_progress' ||
      _canonicalRouteState == 'on_the_way' ||
      _canonicalRouteState == 'heading_to_destination';

  bool get _canOpenOtpStage => _isPickupArrivalStage;

  bool get _isTripInMotion => _isDestinationNavigationStage;

  TripNavigationSnapshot get _navigationSnapshot =>
      TripNavigationController.resolve(
        trip: _trip,
        rawState: _canonicalRouteState,
        routeReady: _polylines.isNotEmpty,
        nearPickup: _nearPickup,
        waitingActive: _waitingActive,
        distanceMeters: _distanceToTargetM,
        etaSec: _etaSec,
      );

  double _pickupLat() => _tripDouble(_trip, const ['pickupLat', 'pickup_lat']);
  double _pickupLng() => _tripDouble(_trip, const ['pickupLng', 'pickup_lng']);
  double _destinationLat() => _tripDouble(_trip, const ['destinationLat', 'destination_lat']);
  double _destinationLng() => _tripDouble(_trip, const ['destinationLng', 'destination_lng']);

  LatLng? _activeRouteTarget() {
    final lat = _isPickupNavigationStage || _isPickupArrivalStage
        ? _pickupLat()
        : _destinationLat();
    final lng = _isPickupNavigationStage || _isPickupArrivalStage
        ? _pickupLng()
        : _destinationLng();
    if (lat == 0 || lng == 0) return null;
    return LatLng(lat, lng);
  }

  void _resetRouteSnapshot() {
    _lastRouteKey = '';
    _lastRouteOriginLatLng = null;
    _lastCameraViewKey = '';
    _lastRouteRefreshAtMs = 0;
    _lastCameraSyncAtMs = 0;
  }

  String _responseMessage(http.Response response, {String fallback = 'Request failed'}) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map && decoded['message'] != null) {
        final message = decoded['message'].toString().trim();
        if (message.isNotEmpty) return message;
      }
    } catch (_) {}
    return fallback;
  }

  Future<void> _pushDriverLocationSnapshot(
    Position pos, {
    bool awaitServer = false,
  }) async {
    final payload = {
      'lat': pos.latitude,
      'lng': pos.longitude,
      'heading': pos.heading.isNaN ? 0 : pos.heading,
      'speed': pos.speed,
      'isOnline': true,
    };
    _socket.sendLocation(
      lat: pos.latitude,
      lng: pos.longitude,
      heading: pos.heading.isNaN ? 0 : pos.heading,
      speed: pos.speed,
    );
    final headers = await AuthService.getHeaders();
    final request = http.post(
      Uri.parse(ApiConfig.driverLocation),
      headers: {...headers, 'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );
    if (awaitServer) {
      await request.timeout(const Duration(seconds: 6));
      return;
    }
    request.catchError((_) => http.Response('', 500));
  }

  void _mergeTripState(Map<String, dynamic>? nextTrip, {String? fallbackStatus}) {
    if (nextTrip == null && fallbackStatus == null) return;
    final merged =
        Map<String, dynamic>.from(_trip ?? widget.trip ?? const <String, dynamic>{});
    if (nextTrip != null) {
      merged.addAll(nextTrip);
    }
    final status = _resolvedTripStatus(
      merged,
      fallback: fallbackStatus ?? _status,
    );
    if ((merged['currentStatus']?.toString().trim().isEmpty ?? true) &&
        (merged['current_status']?.toString().trim().isEmpty ?? true)) {
      merged['currentStatus'] = status;
      merged['current_status'] = status;
    }
    _trip = merged;
    _status = status;
  }

  bool _hasTripRouteCoordinates(Map<String, dynamic>? trip) {
    if (trip == null) return false;
    final pickupLat = double.tryParse(
            trip['pickupLat']?.toString() ?? trip['pickup_lat']?.toString() ?? '') ??
        0;
    final pickupLng = double.tryParse(
            trip['pickupLng']?.toString() ?? trip['pickup_lng']?.toString() ?? '') ??
        0;
    final destinationLat = double.tryParse(trip['destinationLat']?.toString() ??
            trip['destination_lat']?.toString() ??
            '') ??
        0;
    final destinationLng = double.tryParse(trip['destinationLng']?.toString() ??
            trip['destination_lng']?.toString() ??
            '') ??
        0;
    return pickupLat != 0 &&
        pickupLng != 0 &&
        destinationLat != 0 &&
        destinationLng != 0;
  }

  Future<void> _refreshTripFromServer({bool force = false}) async {
    if (!force && _hasTripRouteCoordinates(_trip)) return;
    try {
      final headers = await AuthService.getHeaders();
      final res = await http
          .get(Uri.parse(ApiConfig.driverActiveTrip), headers: headers)
          .timeout(const Duration(seconds: 5));
      if (!mounted || res.statusCode != 200) return;
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final serverTrip = data['trip'];
      if (serverTrip is Map) {
        _applyRealtimeTripPayload(Map<String, dynamic>.from(serverTrip));
      }
    } catch (_) {}
  }

  void _focusRoute(double fromLat, double fromLng, double toLat, double toLng) {
    final controller = _mapController;
    if (controller == null) return;
    controller.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(min(fromLat, toLat), min(fromLng, toLng)),
          northeast: LatLng(max(fromLat, toLat), max(fromLng, toLng)),
        ),
        88,
      ),
    );
  }

  LatLng? _routeTargetForCurrentStatus() {
    return TripNavigationController.targetForState(_trip, _canonicalRouteState);
  }

  String _routeKeyForTarget(LatLng target) {
    return '${_canonicalRouteState}_${target.latitude.toStringAsFixed(5)}_${target.longitude.toStringAsFixed(5)}';
  }

  double _distanceBetweenLatLng(LatLng a, LatLng b) {
    return Geolocator.distanceBetween(
      a.latitude,
      a.longitude,
      b.latitude,
      b.longitude,
    );
  }

  bool _shouldRefreshRouteSnapshot(LatLng origin, {bool force = false}) {
    final target = _routeTargetForCurrentStatus();
    if (target == null) return false;
    final nextRouteKey = _routeKeyForTarget(target);
    if (force || _polylines.isEmpty || nextRouteKey != _lastRouteKey) {
      return true;
    }
    final previousOrigin = _lastRouteOriginLatLng;
    if (previousOrigin != null &&
        _distanceBetweenLatLng(previousOrigin, origin) < 45) {
      return false;
    }
    final now = DateTime.now().millisecondsSinceEpoch;
    return now - _lastRouteRefreshAtMs >= 6000;
  }

  void _maybeSyncTripCamera({bool force = false}) {
    final controller = _mapController;
    final origin = _lastTripPosition;
    final target = _routeTargetForCurrentStatus();
    if (controller == null || origin == null) return;
    final originLatLng = LatLng(origin.latitude, origin.longitude);
    final now = DateTime.now().millisecondsSinceEpoch;
    final viewKey = target == null
        ? 'self_${_canonicalRouteState}'
        : '${_canonicalRouteState}_${target.latitude.toStringAsFixed(5)}_${target.longitude.toStringAsFixed(5)}';
    if (!force &&
        viewKey == _lastCameraViewKey &&
        now - _lastCameraSyncAtMs < 2500) {
      return;
    }
    _lastCameraSyncAtMs = now;
    _lastCameraViewKey = viewKey;
    if (target == null) {
      controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: originLatLng,
            zoom: _internalNavigationActive ? 17.2 : 15.8,
            tilt: _internalNavigationActive ? 52 : 0,
            bearing: _internalNavigationActive && !origin.heading.isNaN
                ? origin.heading
                : 0,
          ),
        ),
      );
      return;
    }
    controller.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(
            min(originLatLng.latitude, target.latitude),
            min(originLatLng.longitude, target.longitude),
          ),
          northeast: LatLng(
            max(originLatLng.latitude, target.latitude),
            max(originLatLng.longitude, target.longitude),
          ),
        ),
        _internalNavigationActive ? 136 : 88,
      ),
    );
  }

  String _shortLocation(String v) {
    final s = v.trim();
    if (s.isEmpty) return s;
    return s.split(',').first.trim();
  }

  int? _parseEventAtMs(dynamic value) {
    final raw = value?.toString();
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw)?.millisecondsSinceEpoch;
  }

  int _statusRank(String status) {
    switch (_canonicalizeRouteState(status)) {
      case 'accepted':
      case 'driver_assigned':
      case 'heading_to_pickup':
        return 1;
      case 'arrived':
      case 'waiting':
      case 'otp_pending':
        return 2;
      case 'otp_verified':
      case 'heading_to_destination':
      case 'in_progress':
      case 'on_the_way':
        return 3;
      case 'payment_pending':
      case 'completed':
      case 'cancelled':
        return 4;
      default:
        return 0;
    }
  }

  void _bindSocketLifecycle() {
    _socketConnSub = _socket.onConnectionChanged.listen((connected) {
      if (!mounted) return;
      if (connected) {
        final tid = _tripId;
        if (tid.isNotEmpty) {
          _socket.setActiveTrip(tid);
        }
        _syncTripState();
      }
    });

    _tripStatusSub = _socket.onTripStatus.listen((data) {
      _applyRealtimeTripPayload(data, shouldSyncServer: true);
    });
    _tripRecoveredSub = _socket.onTripRecovered.listen((data) {
      _applyRealtimeTripPayload(data, shouldSyncServer: true);
    });
  }

  void _applyRealtimeTripPayload(
    Map<String, dynamic> payload, {
    bool shouldSyncServer = false,
  }) {
    if (!mounted) return;
    final nextStateVersion = payload['stateVersion']?.toString() ?? '';
    final nextEventAt = _parseEventAtMs(payload['serverTimestamp']) ?? 0;
    if (nextStateVersion.isNotEmpty &&
        nextStateVersion == _lastTripStateVersion &&
        nextEventAt <= _lastTripEventAtMs) {
      return;
    }
    if (nextEventAt != 0 && nextEventAt < _lastTripEventAtMs) {
      return;
    }

    final normalizedStatus = _resolvedTripStatus(payload, fallback: _status);
    if (_statusRank(normalizedStatus) < _statusRank(_status)) {
      return;
    }

    final previousStatus = _status;
    final previousRouteState = _canonicalRouteState;
    setState(() {
      _mergeTripState(payload, fallbackStatus: normalizedStatus);
    });
    if (previousStatus != _status) {
      _resetRouteSnapshot();
    }

    if (nextStateVersion.isNotEmpty) {
      _lastTripStateVersion = nextStateVersion;
    }
    if (nextEventAt != 0) {
      _lastTripEventAtMs = nextEventAt;
    }

    if (_trip != null &&
        _status != 'completed' &&
        _status != 'payment_pending' &&
        _status != 'cancelled') {
      ActiveRidePersistenceService.persistActiveRide(
        Map<String, dynamic>.from(_trip!),
        lastLat: _lastTripPosition?.latitude ?? _center.latitude,
        lastLng: _lastTripPosition?.longitude ?? _center.longitude,
        heading: _lastTripPosition?.heading,
        speed: _lastTripPosition?.speed,
        wasOnline: true,
      );
    }

    _syncWaitingLifecycle(payload);
    _initMapMarkers();
    _fetchRouteForCurrentStatus();

    if (_isDestinationNavigationStage &&
        previousRouteState != 'heading_to_destination' &&
        previousRouteState != 'in_progress' &&
        previousRouteState != 'on_the_way') {
      _startTripTimer();
    }
    if (_status == 'completed' ||
        _status == 'payment_pending' ||
        _status == 'cancelled') {
      _waitingLifecycleTimer?.cancel();
      _stopStatePoll();
      ActiveRidePersistenceService.clearActiveRide();
    }
    if (shouldSyncServer && previousStatus != _status) {
      _syncTripState();
    }
  }

  void _syncWaitingLifecycle(Map<String, dynamic> trip) {
    final lifecycle = trip['lifecycle'];
    final waiting =
        lifecycle is Map ? Map<String, dynamic>.from(lifecycle['waiting'] ?? {}) : null;
    if (waiting == null || waiting.isEmpty) {
      _waitingLifecycleTimer?.cancel();
      if (mounted) {
        setState(() {
          _waitingActive = false;
          _waitingElapsedSeconds = 0;
          _waitingBillableSeconds = 0;
          _waitingGraceSeconds = 0;
          _waitingCharge = 0;
          _waitingChargePerMin = 0;
        });
      }
      return;
    }

    final baseElapsed = int.tryParse(waiting['elapsedSeconds']?.toString() ?? '0') ?? 0;
    final graceSeconds =
        int.tryParse(waiting['graceSeconds']?.toString() ?? '0') ?? 0;
    final chargePerMin =
        double.tryParse(waiting['waitingChargePerMin']?.toString() ?? '0') ?? 0;
    final active = waiting['active'] == true;
    final serverAt = _parseEventAtMs(trip['serverTimestamp']) ??
        DateTime.now().millisecondsSinceEpoch;

    void applyTick() {
      if (!mounted) return;
      final extraSeconds = active
          ? ((DateTime.now().millisecondsSinceEpoch - serverAt) / 1000).floor()
          : 0;
      final elapsed = max(0, baseElapsed + extraSeconds);
      final billable = max(0, elapsed - graceSeconds);
      final charge = chargePerMin > 0
          ? double.parse(((billable / 60) * chargePerMin).toStringAsFixed(2))
          : 0.0;
      setState(() {
        _waitingActive = active;
        _waitingElapsedSeconds = elapsed;
        _waitingBillableSeconds = billable;
        _waitingGraceSeconds = graceSeconds;
        _waitingChargePerMin = chargePerMin;
        _waitingCharge = charge;
      });
    }

    _waitingLifecycleTimer?.cancel();
    applyTick();
    if (active) {
      _waitingLifecycleTimer =
          Timer.periodic(const Duration(seconds: 1), (_) => applyTick());
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _socket.connect(ApiConfig.socketUrl);
    _trip = widget.trip;
    if (_trip != null) {
      _status = _resolvedTripStatus(_trip);
      _syncWaitingLifecycle(_trip!);
      // Register active trip so socket can rejoin room on reconnect
      final tripId = _trip!['tripId'] ?? _trip!['id'];
      if (tripId != null) _socket.setActiveTrip(tripId.toString());
      ActiveRidePersistenceService.persistActiveRide(
        Map<String, dynamic>.from(_trip!),
        wasOnline: true,
      );
      final lat = _tripDouble(_trip, const ['pickupLat', 'pickup_lat']);
      final lng = _tripDouble(_trip, const ['pickupLng', 'pickup_lng']);
      if (lat != 0 && lng != 0) _center = LatLng(lat, lng);
    }
    _startLocationUpdates();
    _startStatePoll();
    _loadCancelReasons();
    _listenForCancel();
    CallService().init();
    _listenForIncomingCalls();
    _bindSocketLifecycle();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initMapMarkers();
      _fetchRouteForCurrentStatus();
      if (_isTripInMotion) {
        _startTripTimer();
      }
      _validateActiveTrip();
      _refreshTripFromServer();
    });
    print(
        '[TRIP] Screen init — tripId=${_trip?['tripId'] ?? _trip?['id']} status=$_status');
  }

  // ── Validate trip still active on screen load ─────────────────────────────

  Future<void> _validateActiveTrip() async {
    final tripId = _trip?['tripId'] ?? _trip?['id'];
    if (tripId == null) return;
    try {
      final headers = await AuthService.getHeaders();
      final res = await http.get(Uri.parse(ApiConfig.driverActiveTrip),
          headers: headers);
      if (!mounted) return;
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final serverTrip = data['trip'];
        if (serverTrip == null) {
          // No active trip on server — this screen is stale
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Trip no longer active. Returning home.'),
                backgroundColor: Colors.orange),
          );
          Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const HomeScreen()),
              (_) => false);
        }
      }
    } catch (_) {
      // Network error — keep screen, socket cancel handler will catch real cancels
    }
  }

  // ── State polling — server is source of truth ────────────────────────────

  void _startStatePoll() {
    _statePollTimer?.cancel();
    _statePollTimer =
        Timer.periodic(const Duration(seconds: 5), (_) => _syncTripState());
  }

  void _stopStatePoll() {
    _statePollTimer?.cancel();
    _statePollTimer = null;
  }

  Future<void> _syncTripState() async {
    if (!mounted) return;
    final tripId = _trip?['tripId'] ?? _trip?['id'];
    if (tripId == null) return;
    try {
      final headers = await AuthService.getHeaders();
      final res = await http
          .get(Uri.parse(ApiConfig.driverActiveTrip), headers: headers)
          .timeout(const Duration(seconds: 4));
      if (!mounted) return;
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final serverTrip = data['trip'] as Map<String, dynamic>?;
        if (serverTrip == null) {
          // Trip ended on server — pop to home
          _stopStatePoll();
          ActiveRidePersistenceService.clearActiveRide();
          if (mounted) {
            Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const HomeScreen()),
                (_) => false);
          }
          return;
        }
        final serverStatus = _resolvedTripStatus(serverTrip, fallback: _status);
        if (serverStatus == 'completed' ||
            serverStatus == 'payment_pending' ||
            serverStatus == 'cancelled') {
          _stopStatePoll();
          ActiveRidePersistenceService.clearActiveRide();
          if (mounted) {
            Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const HomeScreen()),
                (_) => false);
          }
          return;
        }
        _applyRealtimeTripPayload(serverTrip);
        return;
        // Sync status if server differs from local (handles race conditions)
        if (serverStatus.isNotEmpty && serverStatus != _status) {
          final previousStatus = _status;
          setState(() {
            _mergeTripState(serverTrip, fallbackStatus: serverStatus);
          });
          // Route + nav triggers based on new server-authoritative status
          _initMapMarkers();
          _fetchRouteForCurrentStatus();
          if (serverStatus == 'on_the_way' &&
              previousStatus != 'in_progress' &&
              previousStatus != 'on_the_way') {
            _startTripTimer();
          }
          print('[TRIP] Poll sync: $previousStatus → $serverStatus');
        }
      }
    } catch (_) {} // network error — keep polling
  }

  // ── Timers ────────────────────────────────────────────────────────────────

  void _startTripTimer() {
    _tripStartTime ??= DateTime.now();
    _tripTimer?.cancel();
    _tripTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _tripElapsedSec = DateTime.now().difference(_tripStartTime!).inSeconds;
      });
    });
  }

  void _stopTripTimer() {
    _tripTimer?.cancel();
    _tripTimer = null;
  }

  String _formatElapsed(int secs) {
    final m = (secs ~/ 60).toString().padLeft(2, '0');
    final s = (secs % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String _formatEta(int secs) {
    if (secs <= 0) return '--';
    if (secs < 60) return '< 1 min';
    final mins = (secs / 60).ceil();
    if (mins < 60) return '$mins min';
    return '${(mins / 60).floor()}h ${mins % 60}m';
  }

  String _formatDist(double m) {
    if (m <= 0) return '--';
    if (m < 1000) return '${m.round()} m';
    return '${(m / 1000).toStringAsFixed(1)} km';
  }

  // ── Socket listeners ──────────────────────────────────────────────────────

  void _listenForCancel() {
    _cancelSub = _socket.onTripCancelled.listen((data) {
      if (!mounted) return;
      _locationTimer?.cancel();
      _stopTripTimer();
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          backgroundColor: JT.surface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Trip Cancelled',
              style: GoogleFonts.poppins(
                  color: JT.textPrimary, fontWeight: FontWeight.w400)),
          content: Text('Customer cancelled the trip.',
              style:
                  GoogleFonts.poppins(color: JT.textSecondary, fontSize: 14)),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: JT.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10))),
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const HomeScreen()),
                    (_) => false);
              },
              child: const Text('OK',
                  style: TextStyle(fontWeight: FontWeight.w500)),
            ),
          ],
        ),
      );
    });
  }

  void _listenForIncomingCalls() {
    _incomingCallSub = _socket.onCallIncoming.listen((data) {
      if (!mounted) return;
      final callerName = data['callerName']?.toString() ?? 'Customer';
      final callerId = data['callerId']?.toString() ?? '';
      final tripId =
          data['tripId']?.toString() ?? (_trip?['id']?.toString() ?? '');
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => CallScreen(
          contactName: callerName,
          tripId: tripId,
          targetUserId: callerId,
          isIncoming: true,
          callerIdForIncoming: callerId,
        ),
      ));
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (_trip != null &&
        _status != 'completed' &&
        _status != 'payment_pending' &&
        _status != 'cancelled') {
      ActiveRidePersistenceService.persistActiveRide(
        Map<String, dynamic>.from(_trip!),
        lastLat: _lastTripPosition?.latitude ?? _center.latitude,
        lastLng: _lastTripPosition?.longitude ?? _center.longitude,
        heading: _lastTripPosition?.heading,
        speed: _lastTripPosition?.speed,
        wasOnline: true,
      );
    }
    _otpCtrl.dispose();
    _locationTimer?.cancel();
    _posStream?.cancel();
    _stopTripTimer();
    _stopStatePoll();
    _cancelSub?.cancel();
    _incomingCallSub?.cancel();
    _tripStatusSub?.cancel();
    _tripRecoveredSub?.cancel();
    _socketConnSub?.cancel();
    _waitingLifecycleTimer?.cancel();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (!_socket.isConnected) {
        _socket.connect(ApiConfig.socketUrl);
      }
      final tid = _trip?['id']?.toString() ?? _trip?['tripId']?.toString();
      if (tid != null) {
        _socket.setActiveTrip(tid);
      }
      _resetRouteSnapshot();
      _syncTripState();
      _refreshTripFromServer(force: true);
      _fetchRouteForCurrentStatus(force: true);
      _maybeSyncTripCamera(force: true);
    }
  }

  // ── Map & Route ───────────────────────────────────────────────────────────

  void _initMapMarkers() {
    if (!mounted || _trip == null) return;
    final pLat = double.tryParse(_trip!['pickupLat']?.toString() ??
        _trip!['pickup_lat']?.toString() ??
        '');
    final pLng = double.tryParse(_trip!['pickupLng']?.toString() ??
        _trip!['pickup_lng']?.toString() ??
        '');
    final dLat = double.tryParse(_trip!['destinationLat']?.toString() ??
        _trip!['destination_lat']?.toString() ??
        '');
    final dLng = double.tryParse(_trip!['destinationLng']?.toString() ??
        _trip!['destination_lng']?.toString() ??
        '');
    setState(() {
      _markers.clear();
      if (pLat != null && pLat != 0 && pLng != null) {
        _markers.add(Marker(
          markerId: const MarkerId('pickup'),
          position: LatLng(pLat, pLng),
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: InfoWindow(
            title: 'Pickup',
            snippet: _shortLocation(
                (_trip!['pickupShortName'] ?? _trip!['pickupAddress'] ?? '')
                    .toString()),
          ),
        ));
      }
      if (dLat != null && dLat != 0 && dLng != null) {
        _markers.add(Marker(
          markerId: const MarkerId('destination'),
          position: LatLng(dLat, dLng),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(
            title: 'Drop',
            snippet: _shortLocation((_trip!['destinationShortName'] ??
                    _trip!['destinationAddress'] ??
                    '')
                .toString()),
          ),
        ));
      }
    });
  }

  void _updateSelfMarker(double lat, double lng, {double heading = 0}) {
    if (!mounted) return;
    setState(() {
      _markers.removeWhere((m) => m.markerId.value == 'self');
      _markers.add(Marker(
        markerId: const MarkerId('self'),
        position: LatLng(lat, lng),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: const InfoWindow(title: 'You'),
        zIndexInt: 2,
        rotation: heading,
        flat: true,
      ));
    });
  }

  Future<void> _showLocationPrompt({
    required String title,
    required String message,
    required Future<bool> Function() openSettings,
  }) async {
    if (!mounted || _locationWarningShown) return;
    _locationWarningShown = true;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await openSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  Future<Position?> _resolveTripLocation({Position? fallback}) async {
    try {
      fallback ??= await Geolocator.getLastKnownPosition();
    } catch (_) {}

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _hasLiveLocationAccess = false;
      if (fallback != null) return fallback;
      await _showLocationPrompt(
        title: 'Location Services Off',
        message:
            'Turn on device location so the customer can see your live trip movement.',
        openSettings: Geolocator.openLocationSettings,
      );
      return null;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      _hasLiveLocationAccess = false;
      if (fallback != null) return fallback;
      await _showLocationPrompt(
        title: 'Location Required',
        message:
            'Location access is required during trips so the customer can track you live.',
        openSettings: Geolocator.openAppSettings,
      );
      return null;
    }
    _hasLiveLocationAccess = true;

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
    } catch (_) {
      return fallback;
    }
  }

  Future<void> _fetchRouteForCurrentStatus({bool force = false}) async {
    final t = _trip;
    if (t == null) return;
    // Use best available GPS origin: prefer real GPS > last cached > map center
    final origin = _lastTripPosition;
    final myLat = origin?.latitude ?? _center.latitude;
    final myLng = origin?.longitude ?? _center.longitude;

    final target = _routeTargetForCurrentStatus();
    final destLat = target?.latitude ?? 0;
    final destLng = target?.longitude ?? 0;
    if (destLat == 0 || destLng == 0) {
      if (mounted) {
        setState(() => _routeIssue = 'Navigation target unavailable for current trip stage.');
      }
      print('[ROUTE] Skipping fetch — no valid destination coords (status=$_status)');
      return;
    }
    print('[ROUTE] Fetching route from ($myLat,$myLng) → ($destLat,$destLng) [status=$_status]');
    final originLatLng = LatLng(myLat, myLng);
    if (!_shouldRefreshRouteSnapshot(originLatLng, force: force)) {
      _maybeSyncTripCamera();
      return;
    }
    _lastRouteRefreshAtMs = DateTime.now().millisecondsSinceEpoch;
    await _fetchRoute(myLat, myLng, destLat, destLng);
  }

  Future<void> _fetchRoute(
      double fromLat, double fromLng, double toLat, double toLng) async {
    try {
      final headers = await AuthService.getHeaders();
      final res = await http
          .post(
            Uri.parse(ApiConfig.routeMultiWaypoint),
            headers: {...headers, 'Content-Type': 'application/json'},
            body: jsonEncode({
              'origin': {'lat': fromLat, 'lng': fromLng},
              'destination': {'lat': toLat, 'lng': toLng},
              'waypoints': [],
              'optimize': false,
            }),
          )
          .timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final overviewPolyline = data['overviewPolyline']?.toString();
        final distKm = (data['totalDistanceKm'] as num?)?.toDouble() ?? 0.0;
        final durMin =
            (data['totalDurationMinutes'] as num?)?.toDouble() ?? 0.0;
        if (overviewPolyline != null && mounted) {
          final pts = _decodePolyline(overviewPolyline);
          setState(() {
            _polylines.clear();
            _polylines.add(Polyline(
              polylineId: const PolylineId('route'),
              points: pts,
              color: JT.primary,
              width: 5,
              patterns: [],
            ));
            _distanceToTargetM = distKm * 1000;
            _etaSec = (durMin * 60).round();
            _routeIssue = null;
          });
          _lastRouteOriginLatLng = LatLng(fromLat, fromLng);
          _lastRouteKey = _routeKeyForTarget(LatLng(toLat, toLng));
          _maybeSyncTripCamera(force: true);
        } else if (mounted) {
          setState(() => _routeIssue = 'Navigation route is not available yet. Pull to refresh trip details.');
        }
      } else if (mounted) {
        setState(() => _routeIssue = 'Route service failed to return directions. Check network and retry navigation.');
      }
    } catch (_) {
      if (mounted) {
        setState(() => _routeIssue = 'Could not load live route. Check network and retry.');
      }
    }
  }

  // ── Location updates ──────────────────────────────────────────────────────

  String? _arrivedPreflightError(Position? latestPos) {
    return TripNavigationController.validateArrivedPreflight(
      trip: _trip,
      driverLocation: latestPos == null
          ? null
          : LatLng(latestPos.latitude, latestPos.longitude),
      geofenceMeters: _arrivedGeofenceMeters,
    );
  }

  Future<void> _startLocationUpdates() async {
    _locationTimer?.cancel();
    _posStream?.cancel();

    final initialPos = await _resolveTripLocation();
    if (initialPos == null) {
      _showSnack(
          'Live location is unavailable. Enable GPS to continue trip tracking.',
          error: true);
      return;
    }
    _lastTripPosition = initialPos;
    if (mounted) {
      setState(
          () => _center = LatLng(initialPos.latitude, initialPos.longitude));
      _updateSelfMarker(
        initialPos.latitude,
        initialPos.longitude,
        heading: initialPos.heading.isNaN ? 0 : initialPos.heading,
      );
      // Now that we have real GPS, re-fetch route with accurate origin
      _fetchRouteForCurrentStatus();
    }
    if (!_hasLiveLocationAccess) {
      _showSnack('Enable GPS permission to resume live customer tracking.',
          error: true);
      return;
    }

    // GPS stream: high-accuracy (active trip), but emits only on movement ≥ 5 m
    _posStream = Geolocator.getPositionStream(
      locationSettings: AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
        intervalDuration: Duration(seconds: 3),
        foregroundNotificationConfig: ForegroundNotificationConfig(
          notificationText: 'JAGO Pro Pilot is sharing your live trip location',
          notificationTitle: 'Trip tracking active',
          enableWakeLock: true,
          setOngoing: true,
        ),
      ),
    ).listen((pos) {
      _lastTripPosition = pos;
      if (!mounted) return;
      setState(() => _center = LatLng(pos.latitude, pos.longitude));
      _updateSelfMarker(
        pos.latitude,
        pos.longitude,
        heading: pos.heading.isNaN ? 0 : pos.heading,
      );
      ActiveRidePersistenceService.updateTrackingHeartbeat(
        tripId: _tripId,
        status: _status,
        lat: pos.latitude,
        lng: pos.longitude,
        heading: pos.heading.isNaN ? 0 : pos.heading,
        speed: pos.speed,
        wasOnline: true,
      );
      _computeDistanceAndEta(pos.latitude, pos.longitude);
      _maybeSyncTripCamera();
      _fetchRouteForCurrentStatus();
    }, onError: (_) {
      _showSnack('Could not read live location. Check GPS permissions.',
          error: true);
    });

    // Server-update timer: every 3 s — uses cached position from stream
    _locationTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      final pos = _lastTripPosition;
      if (pos == null || !mounted) return;
      await _pushDriverLocationSnapshot(pos);
    });
  }

  void _computeDistanceAndEta(double lat, double lng) {
    if (_trip == null) return;
    final toPickup = _isPickupNavigationStage || _isPickupArrivalStage;
    if (lat == 0 && lng == 0) return; // Ignore invalid coordinates
    final tLat = toPickup
        ? _tripDouble(_trip, const ['pickupLat', 'pickup_lat'])
        : _tripDouble(_trip, const ['destinationLat', 'destination_lat']);
    final tLng = toPickup
        ? _tripDouble(_trip, const ['pickupLng', 'pickup_lng'])
        : _tripDouble(_trip, const ['destinationLng', 'destination_lng']);
    if (tLat == 0 && tLng == 0) return;
    final dm = Geolocator.distanceBetween(lat, lng, tLat, tLng);
    final etaS = dm > 0 ? (dm / 8.33).round() : 0;
    if (mounted)
      setState(() {
        _distanceToTargetM = dm;
        _etaSec = etaS;
      });
    if (toPickup) {
      final near = dm <= 100;
      if (mounted && near != _nearPickup) {
        setState(() => _nearPickup = near);
        if (near) _showSnack('You are near the pickup location!');
      }
    }
  }

  // ── Cancel reasons ────────────────────────────────────────────────────────

  Future<void> _loadCancelReasons() async {
    try {
      final res = await http.get(Uri.parse(ApiConfig.configs));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final reasons = (data['cancellationReasons'] as List<dynamic>? ?? [])
            .where(
                (r) => r['userType'] == 'driver' || r['user_type'] == 'driver')
            .map((r) => r['reason']?.toString() ?? '')
            .where((r) => r.isNotEmpty)
            .toList();
        if (mounted) setState(() => _cancelReasons = reasons);
      }
    } catch (_) {}
  }

  // ── Trip actions ──────────────────────────────────────────────────────────

  Future<void> _nextStep() async {
    if (_canOpenOtpStage) {
      _showOtpBottomSheet();
      return;
    }
    setState(() => _loading = true);
    final h = await AuthService.getHeaders();
    final tripId = _tripId;

    try {
      if (_isPickupNavigationStage) {
        final latestPos = await _resolveTripLocation(fallback: _lastTripPosition);
        final arrivedError = _arrivedPreflightError(latestPos);
        if (arrivedError != null) {
          _showSnack(
            arrivedError,
            error: true,
          );
          setState(() => _loading = false);
          return;
        }
        if (latestPos == null) {
          setState(() => _loading = false);
          return;
        }
        _lastTripPosition = latestPos;
        if (mounted) {
          setState(() => _center = LatLng(latestPos.latitude, latestPos.longitude));
          _updateSelfMarker(
            latestPos.latitude,
            latestPos.longitude,
            heading: latestPos.heading.isNaN ? 0 : latestPos.heading,
          );
        }
        await _pushDriverLocationSnapshot(latestPos, awaitServer: true);
        final res = await http.post(Uri.parse(ApiConfig.driverArrived),
            headers: {...h, 'Content-Type': 'application/json'},
            body: jsonEncode({
              'tripId': tripId,
              'lat': latestPos.latitude,
              'lng': latestPos.longitude,
              'heading': latestPos.heading.isNaN ? 0 : latestPos.heading,
              'speed': latestPos.speed,
            }));
        if (!mounted) return;
        if (res.statusCode == 200) {
          Map<String, dynamic>? responseBody;
          try {
            responseBody = jsonDecode(res.body) as Map<String, dynamic>;
          } catch (_) {}
          setState(() {
            _mergeTripState(
              responseBody?['trip'] is Map
                  ? Map<String, dynamic>.from(responseBody!['trip'] as Map)
                  : null,
              fallbackStatus: 'arrived',
            );
            _loading = false;
          });
          _resetRouteSnapshot();
          await _refreshTripFromServer(force: true);
          _initMapMarkers();
          print('[TRIP] ✅ Arrived at pickup — tripId=$tripId');
          _showSnack('Arrived! Ask customer for OTP 📍');
          _showOtpBottomSheet();
          // Pre-fetch route to destination while driver waits for OTP
          // (polylines will be ready the moment trip starts)
          await _fetchRouteForCurrentStatus(force: true);
          // Actually we want destination route pre-loaded, fetch it explicitly
          final t = _trip;
          if (false && t != null) {
            final dLat = double.tryParse(t['destinationLat']?.toString() ?? t['destination_lat']?.toString() ?? '') ?? 0.0;
            final dLng = double.tryParse(t['destinationLng']?.toString() ?? t['destination_lng']?.toString() ?? '') ?? 0.0;
            final origin = _lastTripPosition;
            final fromLat = origin?.latitude ?? _center.latitude;
            final fromLng = origin?.longitude ?? _center.longitude;
            if (dLat != 0 && dLng != 0) {
              await _fetchRoute(fromLat, fromLng, dLat, dLng);
            }
          }
        } else {
          final message = _responseMessage(res, fallback: 'Could not mark arrival');
          if (res.statusCode == 409 &&
              message.toLowerCase().contains('state changed before arrival')) {
            setState(() {
              _mergeTripState(null, fallbackStatus: 'arrived');
              _loading = false;
            });
            _resetRouteSnapshot();
            await _refreshTripFromServer(force: true);
            _initMapMarkers();
            _showSnack('Trip already marked arrived. Enter customer OTP.');
            _showOtpBottomSheet();
            return;
          }
          if (res.statusCode >= 500) {
            await _refreshTripFromServer(force: true);
            if (!mounted) return;
            if (_isPickupArrivalStage) {
              setState(() => _loading = false);
              _resetRouteSnapshot();
              _initMapMarkers();
              _showSnack('Trip reached arrived state. Enter customer OTP.');
              _showOtpBottomSheet();
              return;
            }
          }
          _showSnack(message, error: true);
          setState(() => _loading = false);
        }
      } else if (_isDestinationNavigationStage) {
        await _completeTrip(h);
        return;
      }
    } catch (_) {
      if (!mounted) return;
      _showSnack('Network error. Try again.', error: true);
      setState(() => _loading = false);
    }
  }

  Future<void> _completeTrip(Map<String, String> authHeaders) async {
    final tripId = _tripId;
    final estFare = _trip?['estimatedFare'] ?? _trip?['estimated_fare'] ?? 0.0;
    final estDist =
        _trip?['estimatedDistance'] ?? _trip?['estimated_distance'] ?? 0.0;
    try {
      final res = await http.post(Uri.parse(ApiConfig.driverCompleteTrip),
          headers: {...authHeaders, 'Content-Type': 'application/json'},
          body: jsonEncode({
            'tripId': tripId,
            'actualFare': estFare,
            'actualDistance': estDist
          }));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final pricing = data['pricing'] as Map<String, dynamic>? ?? {};
        final completionStatus =
            data['completionStatus']?.toString() ?? 'completed';
        final walletPendingAmount =
            double.tryParse(data['walletPendingAmount']?.toString() ?? '0') ??
                0.0;
        final requiresCashPayment = data['requiresCashPayment'] == true;
        final rideFare = pricing['rideFare'] ??
            data['trip']?['actualFare'] ??
            data['trip']?['actual_fare'] ??
            estFare;
        final driverEarnings = pricing['driverWalletCredit'] ?? rideFare;
        final commission = pricing['platformDeduction'] ?? 0;
        setState(() {
          _mergeTripState(
            {
              if (data['trip'] is Map) ...Map<String, dynamic>.from(data['trip']),
              'currentStatus': completionStatus,
              'current_status': completionStatus,
              'status': completionStatus,
              'walletPendingAmount': walletPendingAmount,
              'requiresCashPayment': requiresCashPayment,
            },
            fallbackStatus: completionStatus,
          );
        });
        _socket.setActiveTrip(null); // clear trip room tracking
        _locationTimer?.cancel();
        _posStream?.cancel();
        _stopTripTimer();
        print(
            '[TRIP] ✅ Ride completed — tripId=$tripId fare=$rideFare earnings=$driverEarnings');
        if (!mounted) return;
        _showCompletionSheet(
          rideFare.toString(),
          driverEarnings: driverEarnings.toString(),
          commission: commission.toString(),
          walletPendingAmount: walletPendingAmount,
          requiresCashPayment: requiresCashPayment,
          completionStatus: completionStatus,
        );
      } else {
        String errMsg = 'Error completing trip';
        try {
          errMsg = (jsonDecode(res.body) as Map)['message'] ?? errMsg;
        } catch (_) {}
        if (!mounted) return;
        _showSnack(errMsg, error: true);
        setState(() => _loading = false);
      }
    } catch (e) {
      print('[TRIP] ❌ complete-trip network error: $e');
      if (!mounted) return;
      _showSnack('Network error. Please tap "Complete" again.', error: true);
      setState(() => _loading = false);
    }
  }

  Future<void> _cancelTrip(String reason) async {
    setState(() => _loading = true);
    final cancelHeaders = await AuthService.getHeaders();
    final tripId = _tripId;
    try {
      await http.post(Uri.parse(ApiConfig.driverCancelTrip),
          headers: {...cancelHeaders, 'Content-Type': 'application/json'},
          body: jsonEncode({'tripId': tripId, 'reason': reason}));
    } catch (_) {}
    _socket.setActiveTrip(null); // clear trip room tracking
    _locationTimer?.cancel();
    _stopTripTimer();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(context,
        MaterialPageRoute(builder: (_) => const HomeScreen()), (_) => false);
  }

  // ── OTP ───────────────────────────────────────────────────────────────────

  void _showOtpBottomSheet() {
    _otpCtrl.clear();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                    color: JT.border, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Row(children: [
              Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: JT.primary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(16)),
                  child: const Icon(Icons.lock_open_rounded,
                      color: JT.primary, size: 28)),
              const SizedBox(width: 14),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text('Enter Customer OTP',
                        style: GoogleFonts.poppins(
                            color: JT.textPrimary,
                            fontWeight: FontWeight.w400,
                            fontSize: 18)),
                    Text('Ask customer for OTP shown in JAGO Pro app',
                        style: GoogleFonts.poppins(
                            color: JT.textSecondary, fontSize: 12)),
                  ])),
            ]),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                color: JT.bgSoft,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: JT.primary.withValues(alpha: 0.3), width: 1.5),
              ),
              child: TextField(
                controller: _otpCtrl,
                keyboardType: TextInputType.number,
                maxLength: 6,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                textAlign: TextAlign.center,
                autofocus: true,
                style: GoogleFonts.poppins(
                    color: JT.textPrimary,
                    fontSize: 32,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 12),
                decoration: InputDecoration(
                  counterText: '',
                  hintText: '——————',
                  hintStyle: GoogleFonts.poppins(
                      color: JT.iconInactive, letterSpacing: 8, fontSize: 24),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 18),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(
                  child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: JT.textSecondary,
                        side: BorderSide(color: JT.border),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: () => Navigator.pop(ctx),
                      child: Text('Cancel',
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w400)))),
              const SizedBox(width: 12),
              Expanded(
                  flex: 2,
                  child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: JT.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 0),
                      onPressed: () async {
                        final otp = _otpCtrl.text.trim();
                        if (otp.length < 4) return;
                        Navigator.pop(ctx);
                        await _verifyOtpAndStart(otp);
                      },
                      child: Text('Verify & Start Trip →',
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w400, fontSize: 14)))),
            ]),
            const SizedBox(height: 16),
            TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _showCancelDialog();
                },
                child: Text('Trouble with OTP? Cancel Trip',
                    style: GoogleFonts.poppins(
                        color: JT.error,
                        fontSize: 12,
                        fontWeight: FontWeight.w400))),
          ]),
        ),
      ),
    );
  }

  Future<void> _verifyOtpAndStart(String otp) async {
    setState(() => _loading = true);
    final h = await AuthService.getHeaders();
    final tripId = _tripId;
    try {
      final res = await http.post(Uri.parse(ApiConfig.driverVerifyOtp),
          headers: {...h, 'Content-Type': 'application/json'},
          body: jsonEncode({'tripId': tripId, 'otp': otp}));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final tripPayload =
            data['trip'] is Map ? Map<String, dynamic>.from(data['trip'] as Map) : null;
        print('[TRIP] ✅ OTP verified — trip started — tripId=$tripId');
        if (!mounted) return;
        setState(() {
          _mergeTripState(tripPayload, fallbackStatus: 'heading_to_destination');
          _loading = false;
        });
        _resetRouteSnapshot();
        await _refreshTripFromServer(force: true);
        _initMapMarkers();
        _startTripTimer();

        // Use real GPS position as route origin (not stale map center)
        final origin = _lastTripPosition;
        final fromLat = origin?.latitude ?? _center.latitude;
        final fromLng = origin?.longitude ?? _center.longitude;

        // Animate map + fetch route to destination
        final dLat =
            _tripDouble(_trip, const ['destinationLat', 'destination_lat']);
        final dLng =
            _tripDouble(_trip, const ['destinationLng', 'destination_lng']);
        if (dLat != 0 && dLng != 0) {
          _focusRoute(fromLat, fromLng, dLat, dLng);
          await _fetchRouteForCurrentStatus(force: true);
        }
        _showSnack('Trip started! Follow the map to reach destination');
        _showPickupPhotoPrompt(tripId);
      } else {
        if (!mounted) return;
        _showSnack(_responseMessage(res, fallback: 'Wrong OTP'), error: true);
        setState(() => _loading = false);
      }
    } catch (_) {
      if (!mounted) return;
      _showSnack('Network error. Try again.', error: true);
      setState(() => _loading = false);
    }
  }

  // ── Pickup photo ──────────────────────────────────────────────────────────

  void _showPickupPhotoPrompt(String tripId) {
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: JT.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: JT.border, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                color: JT.surfaceAlt,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: JT.border)),
            child: Row(children: [
              Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: JT.primary.withValues(alpha: 0.10),
                      shape: BoxShape.circle),
                  child: const Icon(Icons.camera_alt_rounded,
                      color: JT.primary, size: 26)),
              const SizedBox(width: 14),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text('Pickup Photo',
                        style: GoogleFonts.poppins(
                            color: JT.textPrimary,
                            fontWeight: FontWeight.w400,
                            fontSize: 15)),
                    Text('Capture for ride security',
                        style: GoogleFonts.poppins(
                            color: JT.textSecondary, fontSize: 12)),
                  ])),
            ]),
          ),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(
                child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                        foregroundColor: JT.textSecondary,
                        side: BorderSide(color: JT.border),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14)),
                    onPressed: () => Navigator.pop(context),
                    child: Text('Skip',
                        style:
                            GoogleFonts.poppins(fontWeight: FontWeight.w400)))),
            const SizedBox(width: 12),
            Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: JT.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0),
                    icon: const Icon(Icons.camera_alt_rounded, size: 18),
                    label: Text('Take Photo',
                        style:
                            GoogleFonts.poppins(fontWeight: FontWeight.w400)),
                    onPressed: () {
                      Navigator.pop(context);
                      _captureAndUploadPhoto(tripId);
                    })),
          ]),
        ]),
      ),
    );
  }

  Future<void> _captureAndUploadPhoto(String tripId) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
          source: ImageSource.camera, imageQuality: 70, maxWidth: 1280);
      if (picked == null || !mounted) return;
      _showSnack('Uploading photo…');
      final ph = await AuthService.getHeaders();
      final req = http.MultipartRequest('POST', Uri.parse(ApiConfig.tripPhoto));
      req.headers.addAll(ph);
      req.fields['tripId'] = tripId;
      req.files.add(await http.MultipartFile.fromPath('photo', picked.path));
      final resp = await req.send();
      if (!mounted) return;
      _showSnack(
          resp.statusCode == 200 ? 'Photo saved ✓' : 'Photo upload failed',
          error: resp.statusCode != 200);
    } catch (_) {
      if (mounted) _showSnack('Photo upload failed', error: true);
    }
  }

  // ── Completion sheet ──────────────────────────────────────────────────────

  void _showCompletionSheet(String fare,
      {String driverEarnings = '0',
      String commission = '0',
      double walletPendingAmount = 0,
      bool requiresCashPayment = false,
      String completionStatus = 'completed'}) {
    int selectedRating = 0;
    bool ratingSubmitted = false;
    final tripId = _trip?['id'] ?? _trip?['tripId'] ?? '';
    final pm = _trip?['paymentMethod'] ?? _trip?['payment_method'] ?? 'cash';
    final isCash = pm == 'cash';
    final netEarnings = double.tryParse(driverEarnings) ?? 0.0;
    final commissionAmt = double.tryParse(commission) ?? 0.0;
    final fullFare = double.tryParse(fare) ?? 0.0;
    final elapsed = _formatElapsed(_tripElapsedSec);
    final hasPendingSettlement = completionStatus == 'payment_pending' ||
        requiresCashPayment ||
        walletPendingAmount > 0;
    final title = hasPendingSettlement ? 'Ride Closed' : 'Trip Complete!';
    final subtitle = hasPendingSettlement
        ? 'Collect the pending amount to fully settle this ride.'
        : 'Great job! Ride completed successfully.';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                    color: JT.border, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            // Success icon
            Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                    color: JT.success.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: JT.success.withValues(alpha: 0.3), width: 2)),
                child: const Icon(Icons.check_rounded,
                    color: JT.success, size: 44)),
            const SizedBox(height: 16),
            Text(title,
                style: GoogleFonts.poppins(
                    color: JT.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Text(subtitle,
                style:
                    GoogleFonts.poppins(color: JT.textSecondary, fontSize: 13)),
            const SizedBox(height: 20),
            // Earnings card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                    colors: [JT.primary, JT.primary.withValues(alpha: 0.75)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(20),
                boxShadow: JT.btnShadow,
              ),
              child: Column(children: [
                Text('YOUR EARNINGS',
                    style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1.5)),
                const SizedBox(height: 6),
                Text('₹${netEarnings.toStringAsFixed(0)}',
                    style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.w500,
                        height: 1.1)),
                const SizedBox(height: 12),
                Container(height: 1, color: Colors.white24),
                const SizedBox(height: 12),
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _completionStat(
                          'Fare', '₹${fullFare.toStringAsFixed(0)}'),
                      _completionStat(
                          'Commission', '₹${commissionAmt.toStringAsFixed(0)}'),
                      _completionStat('Duration', elapsed),
                    ]),
              ]),
            ),
            const SizedBox(height: 14),
            // Payment instruction
            if (hasPendingSettlement)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.35))),
                child: Row(children: [
                  Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.payments_rounded,
                          color: Color(0xFFF59E0B), size: 24)),
                  const SizedBox(width: 14),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text('Collect ₹${walletPendingAmount.toStringAsFixed(0)} to settle the ride',
                            style: GoogleFonts.poppins(
                                color: const Color(0xFFB45309),
                                fontWeight: FontWeight.w400,
                                fontSize: 15)),
                        Text(
                            isCash
                                ? 'Cash collection is still pending for this trip'
                                : 'Wallet/online deduction left a pending balance to collect',
                            style: GoogleFonts.poppins(
                                color: JT.textSecondary, fontSize: 11)),
                      ])),
                ]),
              )
            else if (isCash)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(16),
                    border:
                        Border.all(color: JT.success.withValues(alpha: 0.35))),
                child: Row(children: [
                  Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                          color: JT.success.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.payments_rounded,
                          color: JT.success, size: 24)),
                  const SizedBox(width: 14),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text('Collect ₹${fullFare.toStringAsFixed(0)} Cash',
                            style: GoogleFonts.poppins(
                                color: JT.success,
                                fontWeight: FontWeight.w400,
                                fontSize: 15)),
                        Text(
                            'Platform fee ₹${commissionAmt.toStringAsFixed(0)} deducted from your wallet',
                            style: GoogleFonts.poppins(
                                color: JT.textSecondary, fontSize: 11)),
                      ])),
                ]),
              )
            else
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: JT.primary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                    border:
                        Border.all(color: JT.primary.withValues(alpha: 0.2))),
                child: Row(children: [
                  const Icon(Icons.account_balance_wallet_rounded,
                      color: JT.primary, size: 24),
                  const SizedBox(width: 14),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(
                            '₹${netEarnings.toStringAsFixed(0)} added to wallet',
                            style: GoogleFonts.poppins(
                                color: JT.primary,
                                fontWeight: FontWeight.w400,
                                fontSize: 15)),
                        Text(
                            pm == 'wallet'
                                ? 'Customer wallet deducted'
                                : 'Customer paid online',
                            style: GoogleFonts.poppins(
                                color: JT.textSecondary, fontSize: 11)),
                      ])),
                ]),
              ),
            const SizedBox(height: 14),
            // Rating
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: JT.bgSoft,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: JT.border)),
              child: ratingSubmitted
                  ? Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Icons.star_rounded,
                          color: Colors.amber, size: 22),
                      const SizedBox(width: 8),
                      Text('Thank you for rating!',
                          style: GoogleFonts.poppins(
                              color: JT.textSecondary,
                              fontWeight: FontWeight.w400)),
                    ])
                  : Column(children: [
                      Text('Rate this customer',
                          style: GoogleFonts.poppins(
                              color: JT.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w500)),
                      const SizedBox(height: 10),
                      Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            for (int i = 1; i <= 5; i++)
                              GestureDetector(
                                onTap: () async {
                                  setS(() => selectedRating = i);
                                  final rh = await AuthService.getHeaders();
                                  try {
                                    await http.post(
                                        Uri.parse(ApiConfig.driverRateCustomer),
                                        headers: {
                                          ...rh,
                                          'Content-Type': 'application/json'
                                        },
                                        body: jsonEncode(
                                            {'tripId': tripId, 'rating': i}));
                                  } catch (_) {}
                                  setS(() => ratingSubmitted = true);
                                },
                                child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6),
                                    child: Icon(
                                        i <= selectedRating
                                            ? Icons.star_rounded
                                            : Icons.star_border_rounded,
                                        color: Colors.amber,
                                        size: 40)),
                              ),
                          ]),
                    ]),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: JT.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 0),
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const HomeScreen()),
                        (_) => false);
                  },
                  child: Text('Back to Home →',
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w400, fontSize: 16))),
            ),
          ])),
        ),
      ),
    );
  }

  Widget _completionStat(String label, String value) {
    return Column(children: [
      Text(value,
          style: GoogleFonts.poppins(
              color: Colors.white, fontWeight: FontWeight.w400, fontSize: 15)),
      Text(label,
          style: GoogleFonts.poppins(
              color: Colors.white60,
              fontSize: 10,
              fontWeight: FontWeight.w400)),
    ]);
  }

  // ── Cancel dialog ─────────────────────────────────────────────────────────

  void _showCancelDialog() {
    final reasons = _cancelReasons.isNotEmpty
        ? _cancelReasons
        : [
            'Customer not at pickup location',
            'Customer is not responding',
            'Vehicle breakdown',
            'Customer requested to cancel',
            'Other reason',
          ];
    showModalBottomSheet(
      context: context,
      backgroundColor: JT.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: JT.border, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          Row(children: [
            Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: JT.error.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.cancel_rounded,
                    color: JT.error, size: 20)),
            const SizedBox(width: 12),
            Text('Cancel Reason',
                style: GoogleFonts.poppins(
                    color: JT.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w400)),
          ]),
          const SizedBox(height: 12),
          ...reasons.map((r) => ListTile(
              title: Text(r,
                  style:
                      GoogleFonts.poppins(color: JT.textPrimary, fontSize: 13)),
              leading: const Icon(Icons.chevron_right_rounded,
                  color: JT.iconInactive, size: 18),
              contentPadding: EdgeInsets.zero,
              dense: true,
              onTap: () {
                Navigator.pop(context);
                _cancelTrip(r);
              })),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  // ── Delivery OTP ──────────────────────────────────────────────────────────

  void _showDeliveryOtpDialog() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: JT.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: JT.warning.withValues(alpha: 0.10),
                    shape: BoxShape.circle),
                child: const Icon(Icons.local_shipping_rounded,
                    color: JT.warning, size: 32)),
            const SizedBox(height: 16),
            Text('Delivery OTP',
                style: GoogleFonts.poppins(
                    color: JT.textPrimary,
                    fontWeight: FontWeight.w400,
                    fontSize: 18)),
            const SizedBox(height: 4),
            Text('Ask receiver for OTP to confirm delivery',
                style:
                    GoogleFonts.poppins(color: JT.textSecondary, fontSize: 13),
                textAlign: TextAlign.center),
            const SizedBox(height: 20),
            Container(
                decoration: BoxDecoration(
                    color: JT.bgSoft,
                    borderRadius: BorderRadius.circular(14),
                    border:
                        Border.all(color: JT.warning.withValues(alpha: 0.3))),
                child: TextField(
                  controller: ctrl,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                      color: JT.textPrimary,
                      fontSize: 28,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 10),
                  decoration: InputDecoration(
                      counterText: '',
                      hintText: '------',
                      hintStyle: GoogleFonts.poppins(
                          color: JT.iconInactive,
                          letterSpacing: 10,
                          fontSize: 24),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 16)),
                )),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(
                  child: TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12))),
                      child: Text('Cancel',
                          style: GoogleFonts.poppins(
                              color: JT.textSecondary,
                              fontWeight: FontWeight.w400)))),
              const SizedBox(width: 12),
              Expanded(
                  child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: JT.warning,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0),
                      onPressed: () async {
                        final otp = ctrl.text.trim();
                        if (otp.isEmpty) return;
                        Navigator.pop(ctx);
                        await _verifyDeliveryOtp(otp);
                      },
                      child: Text('Verify ✓',
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w400)))),
            ]),
          ]),
        ),
      ),
    ).then((_) => ctrl.dispose());
  }

  Future<void> _verifyDeliveryOtp(String otp) async {
    setState(() => _loading = true);
    final h = await AuthService.getHeaders();
    final tripId = _trip?['id'] ?? _trip?['tripId'] ?? '';
    try {
      final res = await http.post(Uri.parse(ApiConfig.verifyDeliveryOtp),
          headers: {...h, 'Content-Type': 'application/json'},
          body: jsonEncode({'tripId': tripId, 'otp': otp}));
      if (!mounted) return;
      _showSnack(
          res.statusCode == 200
              ? 'Delivery verified! ✓'
              : (jsonDecode(res.body)['message'] ?? 'Wrong OTP'),
          error: res.statusCode != 200);
    } catch (_) {
      if (!mounted) return;
      _showSnack('Network error', error: true);
    }
    if (mounted) setState(() => _loading = false);
  }

  // ── Call / Navigation / SOS ───────────────────────────────────────────────

  void _startInAppCall(String contactName) {
    final customerId =
        _trip?['customerId']?.toString() ?? _trip?['customer_id']?.toString();
    final tripId =
        _trip?['id']?.toString() ?? _trip?['tripId']?.toString() ?? '';
    if (customerId == null || customerId.isEmpty) return;
    Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => CallScreen(
            contactName: contactName,
            tripId: tripId,
            targetUserId: customerId)));
  }

  void _openTripChat() {
    final tripId =
        _trip?['id']?.toString() ?? _trip?['tripId']?.toString() ?? '';
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => TripChatSheet(tripId: tripId, senderName: 'Driver'));
  }

  Future<void> _activateInAppNavigation({bool announce = true}) async {
    final toPickup = _isPickupNavigationStage || _isPickupArrivalStage;
    final tLat = toPickup ? _pickupLat() : _destinationLat();
    final tLng = toPickup ? _pickupLng() : _destinationLng();
    final label = toPickup
        ? _shortLocation(_tripString(_trip,
            const ['pickupShortName', 'pickupAddress', 'pickup_address'],
            fallback: 'Pickup'))
        : _shortLocation(_tripString(_trip, const [
            'destinationShortName',
            'destinationAddress',
            'destination_address',
          ], fallback: 'Destination'));

    if (tLat == 0 || tLng == 0) {
      await _refreshTripFromServer(force: true);
    }
    final targetLat = toPickup ? _pickupLat() : _destinationLat();
    final targetLng = toPickup ? _pickupLng() : _destinationLng();
    if (targetLat == 0 || targetLng == 0) {
      _showSnack('Navigation target unavailable. Refreshing trip details failed.', error: true);
      return;
    }

    if (mounted) {
      setState(() => _internalNavigationActive = true);
    }
    await _fetchRouteForCurrentStatus(force: true);
    _maybeSyncTripCamera(force: true);
    if (!announce) return;
    final nav = _navigationSnapshot;
    if (_polylines.isNotEmpty) {
      _showSnack(
        '${toPickup ? 'Pickup' : 'Destination'} navigation active in app${nav.etaLabel != '--' ? ' • ETA ${nav.etaLabel}' : ''}.',
      );
      return;
    }
    _showSnack(
      _routeIssue == null
          ? 'Live navigation focus active in app. Route preview is still loading.'
          : 'Map focus active in app. ${_routeIssue!}',
      error: _routeIssue != null,
    );
  }

  Future<void> _openNavigation() async {
    await _activateInAppNavigation();
  }

  Future<void> _openExternalNavigation() async {
    final toPickup = _isPickupNavigationStage || _isPickupArrivalStage;
    final tLat = toPickup ? _pickupLat() : _destinationLat();
    final tLng = toPickup ? _pickupLng() : _destinationLng();
    final label = toPickup
        ? _shortLocation(_tripString(_trip,
            const ['pickupShortName', 'pickupAddress', 'pickup_address'],
            fallback: 'Pickup'))
        : _shortLocation(_tripString(_trip, const [
            'destinationShortName',
            'destinationAddress',
            'destination_address',
          ], fallback: 'Destination'));
    if (tLat == 0 || tLng == 0) {
      await _refreshTripFromServer(force: true);
    }
    final targetLat = toPickup ? _pickupLat() : _destinationLat();
    final targetLng = toPickup ? _pickupLng() : _destinationLng();
    if (targetLat == 0 || targetLng == 0) {
      _showSnack('Navigation target unavailable. Refreshing trip details failed.', error: true);
      return;
    }
    await _activateInAppNavigation(announce: false);
    final candidates = <Uri>[
      Uri.parse('google.navigation:q=$targetLat,$targetLng&mode=d'),
      Uri.parse(
          'https://www.google.com/maps/dir/?api=1&destination=$targetLat,$targetLng&destination_place_id=&travelmode=driving'),
      Uri.parse('geo:$targetLat,$targetLng?q=$targetLat,$targetLng(${Uri.encodeComponent(label)})'),
    ];

    for (final uri in candidates) {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }
    }
    _showSnack(
      _routeIssue == null
          ? 'No navigation app found to open this route.'
          : 'Navigation app not available. ${_routeIssue!}',
      error: true,
    );
  }

  Future<void> _triggerSos() async {
    final confirm = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
                backgroundColor: JT.surface,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                title: Text('SOS Alert',
                    style: GoogleFonts.poppins(
                        color: JT.textPrimary, fontWeight: FontWeight.w500)),
                content: Text(
                    'Emergency SOS send చేయాలా? Help team contact అవుతారు.',
                    style: GoogleFonts.poppins(color: JT.textSecondary)),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text('Cancel',
                          style: GoogleFonts.poppins(color: JT.textSecondary))),
                  ElevatedButton(
                      style:
                          ElevatedButton.styleFrom(backgroundColor: JT.error),
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('SOS పంపు',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500))),
                ]));
    if (confirm != true) return;
    final h = await AuthService.getHeaders();
    final tripId = _trip?['id'] ?? _trip?['tripId'] ?? '';
    try {
      await http.post(Uri.parse(ApiConfig.sos),
          headers: {...h, 'Content-Type': 'application/json'},
          body: jsonEncode({
            'tripId': tripId,
            'lat': _center.latitude,
            'lng': _center.longitude,
            'message': 'Driver SOS alert during trip'
          }));
      if (!mounted) return;
      _showSnack('SOS Alert sent! Help is on the way.');
    } catch (_) {
      if (!mounted) return;
      _showSnack('SOS send failed. Call 100 immediately!', error: true);
    }
  }

  void _showSnack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg,
          style: const TextStyle(
              fontWeight: FontWeight.w400, color: Colors.white)),
      backgroundColor: error ? JT.error : JT.primary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final customerName =
        _trip?['customerName'] ?? _trip?['customer_name'] ?? 'Customer';
    final customerPhone = _trip?['customerPhone'] ?? _trip?['customer_phone'];
    final pickup = _shortLocation((_trip?['pickupShortName'] ??
            _trip?['pickupAddress'] ??
            _trip?['pickup_address'] ??
            'Pickup')
        .toString());
    final dest = _shortLocation((_trip?['destinationShortName'] ??
            _trip?['destinationAddress'] ??
            _trip?['destination_address'] ??
            'Destination')
        .toString());
    final isParcel = (_trip?['type'] ?? _trip?['tripType'] ?? '')
            .toString()
            .toLowerCase()
            .contains('parcel') ||
        (_trip?['notes']?.toString().startsWith('📦') ?? false);
    final isForSomeoneElse = _trip?['isForSomeoneElse'] == true ||
        _trip?['is_for_someone_else'] == true;
    final passengerName =
        _trip?['passengerName'] ?? _trip?['passenger_name'] ?? '';
    final passengerPhone =
        _trip?['passengerPhone'] ?? _trip?['passenger_phone'];

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: JT.bg,
        body: Stack(children: [
          // ── Full screen map ────────────────────────────────────────────────
          Positioned.fill(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(target: _center, zoom: 15),
              onMapCreated: (c) {
                _mapController = c;
                c.animateCamera(CameraUpdate.newLatLng(_center));
                _initMapMarkers();
                _maybeSyncTripCamera(force: true);
                _fetchRouteForCurrentStatus(force: true);
              },
              markers: _markers,
              polylines: _polylines,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              compassEnabled: false,
              padding: const EdgeInsets.only(bottom: 260, top: 100),
            ),
          ),

          // ── Top status bar ─────────────────────────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: Column(
                  children: [
                    _buildTopBar(pickup, dest),
                    const SizedBox(height: 10),
                    _buildNavigationInstructions(),
                  ],
                ),
              ),
            ),
          ),

          // ── Bottom action sheet ────────────────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.10),
                      blurRadius: 24)
                ],
              ),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(
                    width: 44,
                    height: 4,
                    margin: const EdgeInsets.only(top: 10, bottom: 4),
                    decoration: BoxDecoration(
                        color: JT.border,
                        borderRadius: BorderRadius.circular(2))),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    _buildCustomerCard(customerName, customerPhone),
                    if (isForSomeoneElse &&
                        passengerName.toString().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _buildPassengerCard(
                          passengerName.toString(), passengerPhone?.toString()),
                    ],
                    if (isParcel && _trip?['notes'] != null) ...[
                      const SizedBox(height: 8),
                      _buildParcelCard(_trip!['notes'].toString()),
                    ],
                    const SizedBox(height: 10),
                    _buildLiveStats(),
                    const SizedBox(height: 8),
                    _buildPaymentBadge(),
                    if (_isTripInMotion && isParcel) ...[
                      const SizedBox(height: 6),
                      _buildDeliveryOtpBtn(),
                    ],
                    _buildActionBtn(),
                    const SizedBox(height: 8),
                    _buildQuickActions(customerPhone?.toString()),
                  ]),
                ),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  // ── Top bar ───────────────────────────────────────────────────────────────

  Widget _buildTopBar(String pickup, String dest) {
    final nav = _navigationSnapshot;
    final stepInfo = _getStepInfo();
    final isOnTheWay = nav.isDestinationNavigationStage;
    final isArrived = nav.isPickupArrivalStage;
    final Color barColor = isOnTheWay
        ? JT.success
        : isArrived
            ? JT.warning
            : JT.primary;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, JT.bgSoft.withValues(alpha: 0.9)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 15,
              offset: const Offset(0, 4)),
          BoxShadow(
              color: barColor.withValues(alpha: 0.1),
              blurRadius: 1,
              spreadRadius: 1),
        ],
        border: Border.all(color: barColor.withValues(alpha: 0.15), width: 1.5),
      ),
      child: Row(children: [
        Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: barColor.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(14)),
            child:
                Icon(stepInfo['icon'] as IconData, color: barColor, size: 24)),
        const SizedBox(width: 12),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(nav.headline,
              style: GoogleFonts.poppins(
                  color: barColor, fontSize: 14, fontWeight: FontWeight.w400)),
          const SizedBox(height: 2),
          Text(nav.targetLabel.isNotEmpty ? nav.targetLabel : (isOnTheWay ? dest : pickup),
              style: GoogleFonts.poppins(color: JT.textSecondary, fontSize: 11),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ])),
        // LIVE indicator
        AnimatedBuilder(
          animation: _pulseCtrl,
          builder: (_, __) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: JT.success
                    .withValues(alpha: 0.08 + _pulseCtrl.value * 0.06),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                        color: JT.success, shape: BoxShape.circle)),
                const SizedBox(width: 4),
                Text('LIVE',
                    style: GoogleFonts.poppins(
                        color: JT.success,
                        fontSize: 9,
                        fontWeight: FontWeight.w400)),
              ])),
        ),
      ]),
    );
  }

  Widget _buildNavigationInstructions() {
    final nav = _navigationSnapshot;
    final isOnTheWay = nav.isDestinationNavigationStage;
    if (nav.isPickupArrivalStage) return const SizedBox.shrink();

    final Color accentColor = isOnTheWay ? JT.success : JT.primary;
    final String instruction = nav.headline;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: accentColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: accentColor.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.navigation_rounded, color: Colors.white, size: 24),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  instruction,
                  style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600),
                ),
                Text(
                  _routeIssue ??
                      (nav.routeReady
                          ? 'EST. ARRIVAL: ${nav.etaLabel}'
                          : nav.helperLabel),
                  style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 11,
                  fontWeight: FontWeight.w500),
                ),
                if (_internalNavigationActive) ...[
                  const SizedBox(height: 4),
                  Text(
                    'In-app navigation live • Camera and route stay synced on this map',
                    style: GoogleFonts.poppins(
                      color: Colors.white.withValues(alpha: 0.92),
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (_distanceToTargetM > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8)),
              child: Text(
                nav.distanceLabel,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14),
              ),
            ),
        ],
      ),
    );
  }

  // ── Customer card ─────────────────────────────────────────────────────────

  Widget _buildCustomerCard(String name, String? phone) {
    final pm = _trip?['paymentMethod'] ?? _trip?['payment_method'] ?? 'cash';
    final pmLabel = pm == 'wallet'
        ? 'Wallet'
        : (pm == 'upi' || pm == 'online' || pm == 'razorpay')
            ? 'UPI'
            : 'Cash';
    final pmColor = pm == 'wallet'
        ? JT.primary
        : (pm == 'upi' || pm == 'online' || pm == 'razorpay')
            ? JT.secondary
            : JT.success;
    final fare = double.tryParse(
            (_trip?['estimatedFare'] ?? _trip?['estimated_fare'] ?? 0)
                .toString()) ??
        0;

    return Container(
      decoration: BoxDecoration(
          color: JT.bgSoft,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: JT.border)),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                    gradient: JT.grad,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: JT.btnShadow),
                child: Center(
                    child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'C',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w500)))),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(name,
                      style: GoogleFonts.poppins(
                          color: JT.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w400),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  Text(pmLabel,
                      style: GoogleFonts.poppins(
                          color: pmColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500)),
                ])),
            if (phone != null)
              GestureDetector(
                  onTap: () => _startInAppCall(name),
                  child: Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                          gradient: JT.grad,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: JT.btnShadow),
                      child: const Icon(Icons.phone_rounded,
                          color: Colors.white, size: 20))),
          ]),
        ),
        Container(height: 1, color: JT.border),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(children: [
            Expanded(
                child: _pill(
                    'Fare', fare > 0 ? '₹${fare.toInt()}' : '₹--', JT.success)),
            const SizedBox(width: 6),
            Expanded(
                child: _pill(
                    'Distance',
                    (double.tryParse((_trip?['estimatedDistance'] ?? 0)
                                    .toString()) ??
                                0) >
                            0
                        ? '${(double.parse(_trip!['estimatedDistance'].toString())).toStringAsFixed(1)} km'
                        : '--',
                    JT.primary)),
            const SizedBox(width: 6),
            Expanded(child: _pill('Pay', pmLabel, pmColor)),
          ]),
        ),
      ]),
    );
  }

  Widget _pill(String label, String value, Color color) => Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.15))),
      child: Column(children: [
        Text(value,
            style: GoogleFonts.poppins(
                color: color, fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: 2),
        Text(label,
            style: GoogleFonts.poppins(
                color: JT.textSecondary,
                fontSize: 9,
                fontWeight: FontWeight.w400)),
      ]));

  // ── Live stats (distance/ETA/timer) ───────────────────────────────────────

  Widget _buildLiveStats() {
    final nav = _navigationSnapshot;
    final isOnTheWay = nav.isDestinationNavigationStage;
    final isNavigating = nav.isPickupNavigationStage;

    if (nav.isPickupArrivalStage) {
      return Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
              color: JT.warning.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: JT.warning.withValues(alpha: 0.3))),
          child: Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.location_on_rounded, color: JT.warning, size: 18),
              const SizedBox(width: 8),
              Text('At pickup - waiting for customer',
                  style: GoogleFonts.poppins(
                      color: JT.warning,
                      fontSize: 13,
                      fontWeight: FontWeight.w500)),
            ]),
            if (_waitingActive || _waitingElapsedSeconds > 0) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _pill(
                        'Wait Time', _formatElapsed(_waitingElapsedSeconds), JT.warning),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _pill(
                        'Waiting Earned',
                        _waitingCharge > 0
                            ? 'Rs ${_waitingCharge.toStringAsFixed(2)}'
                            : _waitingBillableSeconds > 0
                                ? _formatElapsed(_waitingBillableSeconds)
                                : '${_waitingGraceSeconds}s grace',
                        JT.success),
                  ),
                ],
              ),
            ],
          ]));
      return Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
              color: JT.warning.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: JT.warning.withValues(alpha: 0.3))),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.location_on_rounded, color: JT.warning, size: 18),
            const SizedBox(width: 8),
            Text('At pickup — waiting for customer',
                style: GoogleFonts.poppins(
                    color: JT.warning,
                    fontSize: 13,
                    fontWeight: FontWeight.w500)),
          ]));
    }

    if (!isNavigating && !isOnTheWay) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
          color: isOnTheWay
              ? JT.success.withValues(alpha: 0.06)
              : JT.primary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color:
                  isOnTheWay ? JT.success.withValues(alpha: 0.2) : JT.border)),
      child: Row(children: [
        Icon(isOnTheWay ? Icons.speed_rounded : Icons.navigation_rounded,
            color: isOnTheWay ? JT.success : JT.primary, size: 18),
        const SizedBox(width: 10),
        Expanded(
            child: Row(children: [
          Text(_distanceToTargetM > 0 ? _formatDist(_distanceToTargetM) : '--',
              style: GoogleFonts.poppins(
                  color: isOnTheWay ? JT.success : JT.primary,
                  fontSize: 15,
                  fontWeight: FontWeight.w500)),
          const SizedBox(width: 6),
          Text(nav.routeReady ? 'away' : 'route loading',
              style: GoogleFonts.poppins(
                  color: JT.textSecondary, fontSize: 12)),
          const SizedBox(width: 12),
          const Icon(Icons.access_time_rounded,
              size: 13, color: JT.iconInactive),
          const SizedBox(width: 4),
          Text(_etaSec > 0 ? _formatEta(_etaSec) : '--',
              style: GoogleFonts.poppins(
                  color: JT.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w400)),
        ])),
        if (isOnTheWay && _tripElapsedSec > 0)
          Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                  color: JT.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20)),
              child: Text(_formatElapsed(_tripElapsedSec),
                  style: GoogleFonts.poppins(
                      color: JT.success,
                      fontSize: 12,
                      fontWeight: FontWeight.w400))),
        if (_nearPickup && isNavigating)
          Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                  color: JT.success.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: JT.success.withValues(alpha: 0.4))),
              child: Text('Near Pickup!',
                  style: GoogleFonts.poppins(
                      color: JT.success,
                      fontSize: 11,
                      fontWeight: FontWeight.w400))),
      ]),
    );
  }

  // ── Payment badge ─────────────────────────────────────────────────────────

  Widget _buildPaymentBadge() {
    final pm = _trip?['paymentMethod'] ?? _trip?['payment_method'] ?? 'cash';
    final isCash = pm == 'cash';
    final fare = double.tryParse(
            (_trip?['estimatedFare'] ?? _trip?['estimated_fare'] ?? 0)
                .toString()) ??
        0;

    if (isCash && _isTripInMotion) {
      return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
              gradient: JT.grad,
              borderRadius: BorderRadius.circular(14),
              boxShadow: JT.btnShadow),
          child: Row(children: [
            Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(11)),
                child: const Icon(Icons.payments_rounded,
                    color: Colors.white, size: 20)),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text('COLLECT ₹${fare.toInt()} CASH',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w400,
                          fontSize: 13,
                          letterSpacing: 0.5)),
                  const Text('Remind customer to have exact change',
                      style: TextStyle(color: Colors.white70, fontSize: 11)),
                ])),
          ]));
    }
    if (isCash) {
      return Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
              color: JT.success.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: JT.success.withValues(alpha: 0.20))),
          child: const Row(children: [
            Icon(Icons.payments_rounded, color: JT.success, size: 14),
            SizedBox(width: 7),
            Text('Cash Payment — Collect at trip end',
                style: TextStyle(
                    color: JT.success,
                    fontSize: 11,
                    fontWeight: FontWeight.w400)),
          ]));
    }
    return Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
            color: JT.primary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: JT.border)),
        child: Row(children: [
          const Icon(Icons.account_balance_wallet_rounded,
              color: JT.primary, size: 14),
          const SizedBox(width: 7),
          Text(
              pm == 'wallet'
                  ? 'Wallet — Auto deducted'
                  : 'Online — Already paid',
              style: GoogleFonts.poppins(
                  color: JT.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w400)),
        ]));
  }

  // ── Delivery OTP button ───────────────────────────────────────────────────

  Widget _buildDeliveryOtpBtn() => GestureDetector(
      onTap: _showDeliveryOtpDialog,
      child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          margin: const EdgeInsets.only(bottom: 4),
          decoration: BoxDecoration(
              color: JT.warning.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: JT.warning.withValues(alpha: 0.3))),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.lock_open_rounded, color: JT.warning, size: 17),
            const SizedBox(width: 7),
            Text('Verify Delivery OTP',
                style: GoogleFonts.poppins(
                    color: JT.warning,
                    fontSize: 13,
                    fontWeight: FontWeight.w400)),
          ])));

  // ── Main action button ────────────────────────────────────────────────────

  Widget _buildActionBtn() {
    final step = _getStepInfo();
    final nav = _navigationSnapshot;
    final isOnTheWay = nav.isDestinationNavigationStage;
    final showGlow = nav.nearPickup && nav.isPickupNavigationStage;
    final pickupCoordsMissing =
        nav.isPickupNavigationStage && (_pickupLat() == 0 || _pickupLng() == 0);

    return GestureDetector(
      onTap: (_loading || pickupCoordsMissing) ? null : _nextStep,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity,
        height: 60,
        margin: const EdgeInsets.only(top: 6),
        decoration: BoxDecoration(
          gradient: isOnTheWay
              ? const LinearGradient(
                  colors: [JT.success, Color(0xFF15803D)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight)
              : JT.grad,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
                color: (isOnTheWay ? JT.success : JT.primary)
                    .withValues(alpha: showGlow ? 0.55 : 0.35),
                blurRadius: showGlow ? 28 : 18,
                offset: const Offset(0, 6)),
          ],
          border: showGlow ? Border.all(color: JT.success, width: 2) : null,
        ),
        child: Center(
          child: _loading
              ? const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                      SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5)),
                      SizedBox(width: 12),
                      Text('Please wait...',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                              fontSize: 14)),
                    ])
              : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle),
                      child: Icon(step['icon'] as IconData,
                          color: Colors.white, size: 20)),
                  const SizedBox(width: 12),
                  Text(step['action'] as String,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          letterSpacing: -0.2)),
                ]),
        ),
      ),
    );
  }

  // ── Quick action row ──────────────────────────────────────────────────────

  Widget _buildQuickActions(String? phone) {
    return Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: [
          if (phone != null)
            _quickBtn(Icons.phone_rounded, 'Call', JT.primary, () {
              final n = (_trip?['customerName'] ??
                      _trip?['customer_name'] ??
                      'Customer')
                  .toString();
              _startInAppCall(n);
            }),
          _quickBtn(Icons.chat_rounded, 'Chat', JT.primary, _openTripChat),
          _quickBtn(
            Icons.navigation_rounded,
            _internalNavigationActive ? 'Recenter' : 'Navigate',
            JT.primary,
            _openNavigation,
          ),
          _quickBtn(
            Icons.map_outlined,
            'Open Maps',
            JT.secondary,
            _openExternalNavigation,
          ),
          if (_isPickupNavigationStage || _isPickupArrivalStage)
            _quickBtn(
                Icons.cancel_outlined, 'Cancel', JT.warning, _showCancelDialog),
          _quickBtn(Icons.sos_rounded, 'SOS', JT.error, _triggerSos),
        ]);
  }

  Widget _quickBtn(
          IconData icon, String label, Color color, VoidCallback onTap) =>
      GestureDetector(
          onTap: onTap,
          child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withValues(alpha: 0.22))),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(icon, color: color, size: 15),
                const SizedBox(width: 5),
                Text(label,
                    style: GoogleFonts.poppins(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.w500)),
              ])));

  // ── Parcel card ───────────────────────────────────────────────────────────

  Widget _buildParcelCard(String notes) {
    String receiver = '', category = '', weight = '', instructions = '';
    for (final part in notes.split(' | ')) {
      if (part.startsWith('Category:'))
        category = part.replaceFirst('Category: ', '');
      if (part.startsWith('Weight:'))
        weight = part.replaceFirst('Weight: ', '');
      if (part.startsWith('Receiver:'))
        receiver = part.replaceFirst('Receiver: ', '');
      if (part.startsWith('Instructions:') && !part.contains('None'))
        instructions = part.replaceFirst('Instructions: ', '');
    }
    return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: JT.warning.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: JT.warning.withValues(alpha: 0.25))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Text('📦', style: TextStyle(fontSize: 15)),
            const SizedBox(width: 7),
            Text('PARCEL',
                style: GoogleFonts.poppins(
                    color: JT.warning,
                    fontSize: 10,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 1)),
          ]),
          if (receiver.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(children: [
              const Icon(Icons.person_rounded, color: JT.warning, size: 14),
              const SizedBox(width: 5),
              Expanded(
                  child: Text(receiver,
                      style: GoogleFonts.poppins(
                          color: JT.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w400)))
            ]),
          ],
          if (category.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text('$category  •  $weight',
                style:
                    GoogleFonts.poppins(color: JT.textSecondary, fontSize: 11)),
          ],
          if (instructions.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(instructions,
                style:
                    GoogleFonts.poppins(color: JT.textSecondary, fontSize: 11)),
          ],
        ]));
  }

  // ── Passenger card ────────────────────────────────────────────────────────

  Widget _buildPassengerCard(String passengerName, String? passengerPhone) =>
      Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
              color: JT.surfaceAlt,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: JT.border)),
          child: Row(children: [
            Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: JT.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.person_pin_rounded,
                    color: JT.primary, size: 17)),
            const SizedBox(width: 10),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text('PASSENGER',
                      style: GoogleFonts.poppins(
                          color: JT.primary,
                          fontSize: 9,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 1)),
                  Text(passengerName,
                      style: GoogleFonts.poppins(
                          color: JT.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500)),
                  if (passengerPhone != null && passengerPhone.isNotEmpty)
                    Text(passengerPhone,
                        style: GoogleFonts.poppins(
                            color: JT.textSecondary, fontSize: 11)),
                ])),
          ]));

  // ── Step info ─────────────────────────────────────────────────────────────

  Map<String, dynamic> _getStepInfo() {
    final nav = _navigationSnapshot;
    switch (nav.canonicalState) {
      case 'heading_to_pickup':
        return {
          'label': nav.headline,
          'icon': Icons.navigation_rounded,
          'action': nav.actionLabel
        };
      case 'arrived':
      case 'waiting':
      case 'otp_pending':
        return {
          'label': 'Arrived — Enter OTP to Start',
          'icon': Icons.lock_open_rounded,
          'action': 'Enter Customer OTP'
        };
      case 'otp_verified':
      case 'in_progress':
      case 'on_the_way':
      case 'heading_to_destination':
        return {
          'label': 'Trip in Progress',
          'icon': Icons.speed_rounded,
          'action': 'Complete Trip ✓'
        };
      default:
        return {
          'label': 'Trip Active',
          'icon': Icons.electric_bike,
          'action': 'Next Step'
        };
    }
  }
}
