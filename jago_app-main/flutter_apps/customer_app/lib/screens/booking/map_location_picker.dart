import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import '../../config/jago_theme.dart';
import '../../services/auth_service.dart';
import '../../services/socket_service.dart';

/// Result returned by [MapLocationPicker] when user confirms a location.
class PickedLocation {
  final double lat;
  final double lng;
  final String address;
  const PickedLocation({required this.lat, required this.lng, required this.address});
}

/// Uber-style full-screen map location picker.
///
/// Usage:
/// ```dart
/// final result = await Navigator.push<PickedLocation>(
///   context,
///   MaterialPageRoute(builder: (_) => MapLocationPicker(title: 'Select Pickup')),
/// );
/// if (result != null) {
///   print('${result.lat}, ${result.lng} → ${result.address}');
/// }
/// ```
///
/// Reuse for different purposes:
/// - **Pickup**: `MapLocationPicker(title: 'Select Pickup Location')`
/// - **Drop**: `MapLocationPicker(title: 'Select Drop Location')`
/// - **Saved places**: `MapLocationPicker(title: 'Set Home Location')`
/// - **Pre-filled**: `MapLocationPicker(initialLat: 16.5, initialLng: 80.6)`
class MapLocationPicker extends StatefulWidget {
  /// Header title shown in the app bar.
  final String title;

  /// Optional initial position. If null, uses device GPS.
  final double? initialLat;
  final double? initialLng;
  final String serviceType;
  final String? vehicleCategoryId;
  final String? vehicleCategoryName;

  const MapLocationPicker({
    super.key,
    this.title = 'Select Location',
    this.initialLat,
    this.initialLng,
    this.serviceType = 'ride',
    this.vehicleCategoryId,
    this.vehicleCategoryName,
  });

  @override
  State<MapLocationPicker> createState() => _MapLocationPickerState();
}

class _MapLocationPickerState extends State<MapLocationPicker> {
  final SocketService _socket = SocketService();
  GoogleMapController? _mapController;
  LatLng? _pendingCamera; // camera move queued before map ready
  final Map<String, BitmapDescriptor> _markerIconCache = {};
  final Map<String, LatLng> _vehiclePositions = {};
  final Map<String, double> _vehicleHeadings = {};
  final Map<String, String> _vehicleTypes = {};
  final Map<String, String> _vehicleTitles = {};
  Set<Marker> _nearbyVehicleMarkers = {};
  StreamSubscription? _nearbyDriversSub;
  StreamSubscription? _socketConnSub;
  Timer? _nearbyResubscribeDebounce;
  Timer? _nearbyInterpolationTimer;
  String _availabilityText = 'Looking for nearby drivers';
  bool _groupingEnabled = true;

  // Current center of the map (source of truth)
  // null until GPS is confirmed — avoids biasing search toward a hardcoded city
  double? _gpsLat;
  double? _gpsLng;
  double? _lat; // null until GPS is fetched
  double? _lng;
  String _address = 'Move the map to select location';
  bool _geocoding = false;
  bool _locationLoading = true;

  // Search state
  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();
  List<_PlacePrediction> _predictions = [];
  bool _searching = false;
  bool _showSearch = false;
  Timer? _debounce;

  // Session token for Places Autocomplete (reduces billing)
  String _sessionToken = DateTime.now().millisecondsSinceEpoch.toString();
  static const List<Map<String, dynamic>> _fallbackPlaces = [
    {'name': 'Benz Circle', 'address': 'Benz Circle, Vijayawada, Andhra Pradesh', 'lat': 16.5062, 'lng': 80.6480},
    {'name': 'Vijayawada Railway Station', 'address': 'Vijayawada Junction, Vijayawada, Andhra Pradesh', 'lat': 16.5175, 'lng': 80.6400},
    {'name': 'PNBS Bus Stand', 'address': 'Pandit Nehru Bus Station, Vijayawada, Andhra Pradesh', 'lat': 16.5179, 'lng': 80.6238},
    {'name': 'Kanaka Durga Temple', 'address': 'Kanaka Durga Temple, Vijayawada, Andhra Pradesh', 'lat': 16.5176, 'lng': 80.6121},
    {'name': 'Patamata', 'address': 'Patamata, Vijayawada, Andhra Pradesh', 'lat': 16.4883, 'lng': 80.6681},
    {'name': 'Labbipet', 'address': 'Labbipet, Vijayawada, Andhra Pradesh', 'lat': 16.5034, 'lng': 80.6488},
    {'name': 'Moghalrajpuram', 'address': 'Moghalrajpuram, Vijayawada, Andhra Pradesh', 'lat': 16.5057, 'lng': 80.6465},
    {'name': 'NTR Circle', 'address': 'NTR Circle, Vijayawada, Andhra Pradesh', 'lat': 16.5065, 'lng': 80.6443},
  ];

  List<_PlacePrediction> _localFallbackMatches(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.length < 2) return const [];
    final tokens = normalized.split(RegExp(r'\s+')).where((token) => token.isNotEmpty).toList();
    final matches = _fallbackPlaces.map((place) {
      final haystack = '${place['name']} ${place['address']}'.toLowerCase();
      var score = 0;
      if (haystack.startsWith(normalized)) score += 40;
      if (haystack.contains(normalized)) score += 24;
      for (final token in tokens) {
        if (haystack.contains(token)) score += 8;
      }
      return {'score': score, 'place': place};
    }).where((entry) => (entry['score'] as int) > 0).toList()
      ..sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));

    return matches.take(8).map((entry) {
      final place = entry['place'] as Map<String, dynamic>;
      return _PlacePrediction(
        placeId: 'curated:${place['name'].toString().toLowerCase().replaceAll(' ', '-')}',
        description: '${place['name']}, ${place['address']}',
        mainText: place['name'].toString(),
        secondaryText: place['address'].toString(),
        lat: (place['lat'] as num).toDouble(),
        lng: (place['lng'] as num).toDouble(),
      );
    }).toList();
  }

  // API calls are proxied through server — no client-side key needed

  // ─── Reverse Geocode ─────────────────────────────────────────────
  Future<void> _reverseGeocode(double? lat, double? lng) async {
    if (lat == null || lng == null) return;
    setState(() => _geocoding = true);
    // Try server proxy first for consistency with the main home screen logic
    try {
      final headers = await AuthService.getHeaders();
      final res = await http.get(
        Uri.parse('${ApiConfig.reverseGeocode}?lat=$lat&lng=$lng'),
        headers: headers,
      ).timeout(const Duration(seconds: 6));
      if (res.statusCode == 200 && mounted && lat == _lat && lng == _lng) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final addr = data['formattedAddress']?.toString() ?? '';
        if (addr.isNotEmpty) {
          setState(() { _address = addr; _geocoding = false; });
          return;
        }
      }
    } catch (_) {}
    // Nominatim fallback
    try {
      final res = await http.get(
        Uri.parse('https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lng'),
        headers: const {'User-Agent': 'JagoPro/1.0'},
      ).timeout(const Duration(seconds: 5));
      // Defensive check: ensure results match current map center to avoid stale address updates
      if (res.statusCode == 200 && mounted && lat == _lat && lng == _lng) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final addr = data['display_name']?.toString() ?? '';
        if (addr.isNotEmpty) {
          setState(() { _address = addr; _geocoding = false; });
          return;
        }
      }
    } catch (e) {
      debugPrint('[MAP] Geocode error: $e');
    }
    if (mounted) setState(() { _address = _address == 'Move the map to select location' ? 'Unknown Location' : _address; _geocoding = false; });
  }

  @override
  void initState() {
    super.initState();
    if (widget.initialLat != null && widget.initialLng != null) {
      _lat = widget.initialLat!;
      _lng = widget.initialLng!;
      _locationLoading = false;
      _reverseGeocode(_lat!, _lng!);
      _subscribeNearbyDrivers();
    } else {
      _getCurrentLocation();
    }
    _socket.connect(ApiConfig.socketUrl);
    _nearbyDriversSub =
        _socket.onNearbyDrivers.listen(_handleNearbyDriversSnapshot);
    _socketConnSub = _socket.onConnectionChanged.listen((connected) {
      if (connected) {
        _subscribeNearbyDrivers();
      }
    });
  }

  @override
  void dispose() {
    _socket.unsubscribeNearbyDrivers();
    _nearbyDriversSub?.cancel();
    _socketConnSub?.cancel();
    _nearbyResubscribeDebounce?.cancel();
    _nearbyInterpolationTimer?.cancel();
    _searchCtrl.dispose();
    _searchFocus.dispose();
    _debounce?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  // ─── Location ───────────────────────────────────────────────────────────

  Future<void> _getCurrentLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      final lastPos = await Geolocator.getLastKnownPosition();
      if (!serviceEnabled) {
        if (lastPos != null && mounted) {
          setState(() {
            // Use last known if valid, otherwise fallback to a default city center
            _lat = (lastPos.latitude != 0 && lastPos.latitude != 0.0) ? lastPos.latitude : 16.5062;
            _lng = (lastPos.longitude != 0 && lastPos.longitude != 0.0) ? lastPos.longitude : 80.6480;
            _gpsLat = lastPos.latitude;
            _gpsLng = lastPos.longitude;
            _locationLoading = false;
            _address = 'Using last known location';
          });
          final target = LatLng(_lat!, _lng!);
          if (_mapController != null) {
            _mapController!.animateCamera(CameraUpdate.newLatLngZoom(target, 14));
          } else {
            _pendingCamera = target;
          }
          _reverseGeocode(_lat, _lng);
          _subscribeNearbyDrivers();
          return;
        }
        // Ensure loading is stopped even if no location is found
        setState(() {
          _lat = 16.5062; // Default (e.g., Vijayawada)
          _lng = 80.6480;
          _locationLoading = false;
          _address = 'Location services disabled. Showing default.';
        });
        _subscribeNearbyDrivers();
        return;
      }
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied) {
        setState(() {
          _locationLoading = false;
          _lat = 16.5062;
          _lng = 80.6480;
          _address = 'Location permission is needed to detect your current location.';
        });
        _subscribeNearbyDrivers();
        return;
      }
      if (perm == LocationPermission.deniedForever) {
        setState(() {
          _locationLoading = false;
          _lat = 16.5062;
          _lng = 80.6480;
          _address = 'Location permission is blocked. Enable it from settings.';
        });
        _subscribeNearbyDrivers();
        return;
      }

      if (lastPos != null && mounted) {
        setState(() {
          // Ensure we have non-zero coordinates, otherwise fallback to default
          final isValid = lastPos.latitude != 0 && lastPos.longitude != 0;
          _lat = isValid ? lastPos.latitude : (_lat ?? 16.5062);
          _lng = isValid ? lastPos.longitude : (_lng ?? 80.6480);
          _gpsLat = lastPos.latitude;
          _gpsLng = lastPos.longitude;
        });
        final target = LatLng(_lat!, _lng!);
        if (_mapController != null) {
          _mapController!.animateCamera(CameraUpdate.newLatLngZoom(target, 14));
        } else {
          _pendingCamera = target;
        }
        _reverseGeocode(_lat, _lng);
        _subscribeNearbyDrivers();
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      if (!mounted) return;
      setState(() {
        _lat = pos.latitude != 0 ? pos.latitude : (_lat ?? 16.5062);
        _lng = pos.longitude != 0 ? pos.longitude : (_lng ?? 80.6480);
        _gpsLat = pos.latitude;
        _gpsLng = pos.longitude;
        _locationLoading = false;
        _address = 'Current location';
      });
      final target = LatLng(_lat!, _lng!);
      if (_mapController != null) {
        _mapController!.animateCamera(CameraUpdate.newLatLngZoom(target, 14));
      } else {
        _pendingCamera = target;
      }
      _reverseGeocode(_lat, _lng);
      _subscribeNearbyDrivers();
    } catch (e) {
      setState(() => _locationLoading = false);
    }
  }

  // ─── Places Autocomplete Search ─────────────────────────────────────────

  Future<void> _searchPlaces(String query) async {
    if (query.length < 3) {
      setState(() => _predictions = []);
      return;
    }
    setState(() => _searching = true);
    try {
      final headers = await AuthService.getHeaders();
      final hasGps = _gpsLat != null && _gpsLng != null;
      final qp = StringBuffer('?query=${Uri.encodeComponent(query)}&sessionToken=$_sessionToken');
      if (hasGps) qp.write('&lat=$_gpsLat&lng=$_gpsLng');
      final res = await http.get(
        Uri.parse('${ApiConfig.placesAutocomplete}$qp'),
        headers: headers,
      ).timeout(const Duration(seconds: 6));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final preds = (data['predictions'] as List<dynamic>?) ?? [];
        if (mounted) {
          setState(() {
            _predictions = (preds.isNotEmpty ? preds.map((p) => _PlacePrediction(
              placeId: p['placeId']?.toString() ?? '',
              description: p['fullDescription']?.toString() ?? p['mainText']?.toString() ?? '',
              mainText: p['mainText']?.toString() ?? '',
              secondaryText: p['secondaryText']?.toString() ?? '',
              lat: (p['lat'] as num?)?.toDouble(),
              lng: (p['lng'] as num?)?.toDouble(),
            )).toList() : _localFallbackMatches(query));
          });
        }
      }
    } catch (_) {
      if (mounted) setState(() => _predictions = _localFallbackMatches(query));
    }
    if (mounted) setState(() => _searching = false);
  }

  /// Get lat/lng from a Place ID using Place Details API.
  Future<void> _selectPrediction(_PlacePrediction pred) async {
    setState(() {
      _showSearch = false;
      _predictions = [];
      _searchCtrl.clear();
      _geocoding = true;
    });
    _searchFocus.unfocus();

    // If the prediction already has coordinates (local DB result), use them directly
    if (pred.lat != null && pred.lng != null && pred.lat != 0.0 && pred.lng != 0.0) {
      if (mounted) {
        setState(() {
          _lat = pred.lat!;
          _lng = pred.lng!;
          _address = pred.description;
          _geocoding = false;
        });
        final target = LatLng(_lat!, _lng!);
        if (_mapController != null) {
          _mapController!.animateCamera(CameraUpdate.newLatLngZoom(target, 16));
        } else {
          _pendingCamera = target;
        }
      }
      return;
    }

    try {
      final headers = await AuthService.getHeaders();
      final res = await http.get(
        Uri.parse(
          '${ApiConfig.placeDetails}?placeId=${Uri.encodeComponent(pred.placeId)}&sessionToken=$_sessionToken',
        ),
        headers: headers,
      ).timeout(const Duration(seconds: 6));
      // Generate a new session token after a detail fetch
      _sessionToken = DateTime.now().millisecondsSinceEpoch.toString();
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final newLat = (data['lat'] as num?)?.toDouble() ?? 0.0;
        final newLng = (data['lng'] as num?)?.toDouble() ?? 0.0;
        final address = data['formattedAddress']?.toString() ??
            data['address']?.toString() ??
            pred.description;
        if (newLat != 0.0 && newLng != 0.0 && mounted) {
          setState(() {
            _lat = newLat;
            _lng = newLng;
            _address = address;
            _geocoding = false;
          });
          _mapController?.animateCamera(
            CameraUpdate.newLatLngZoom(LatLng(newLat, newLng), 16),
          );
          return;
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _geocoding = false);
  }

  // ─── Map callbacks ─────────────────────────────────────────────────────

  void _onCameraIdle() {
    _reverseGeocode(_lat, _lng);
    _scheduleNearbySubscription();
  }

  void _onCameraMove(CameraPosition pos) {
    _lat = pos.target.latitude;
    _lng = pos.target.longitude;
  }

  void _onMyLocationTap() async {
    await _getCurrentLocation();
    _subscribeNearbyDrivers();
  }

  void _confirmLocation() {
    if (_lat != null && _lng != null) {
      Navigator.pop(
        context,
        PickedLocation(lat: _lat!, lng: _lng!, address: _address),
      );
    }
  }

  void _scheduleNearbySubscription() {
    _nearbyResubscribeDebounce?.cancel();
    _nearbyResubscribeDebounce =
        Timer(const Duration(milliseconds: 450), _subscribeNearbyDrivers);
  }

  void _subscribeNearbyDrivers() {
    final lat = _lat;
    final lng = _lng;
    if (lat == null || lng == null) return;
    _socket.subscribeNearbyDrivers(
      lat: lat,
      lng: lng,
      serviceType: widget.serviceType,
      vehicleCategoryId: widget.vehicleCategoryId,
      parcelVehicleCategory:
          widget.serviceType == 'parcel' ? widget.vehicleCategoryName : null,
      radiusKm: 5,
    );
  }

  Future<BitmapDescriptor> _getVehicleMarkerIcon(String vehicleType) async {
    if (_markerIconCache.containsKey(vehicleType)) {
      return _markerIconCache[vehicleType]!;
    }
    final descriptor = await _drawVehicleMarker(vehicleType);
    _markerIconCache[vehicleType] = descriptor;
    return descriptor;
  }

  Future<BitmapDescriptor> _drawVehicleMarker(String vehicleType) async {
    const size = 72.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, size, size));

    Color bg;
    String emoji;
    final normalized = vehicleType.toLowerCase();
    if (normalized.contains('bike')) {
      bg = const Color(0xFF2563EB);
      emoji = '🏍️';
    } else if (normalized.contains('auto')) {
      bg = const Color(0xFF0891B2);
      emoji = '🛺';
    } else if (normalized.contains('parcel') ||
        normalized.contains('cargo') ||
        normalized.contains('truck') ||
        normalized.contains('pickup')) {
      bg = const Color(0xFFEA580C);
      emoji = '📦';
    } else if (normalized.contains('premium') || normalized.contains('suv')) {
      bg = const Color(0xFF7C3AED);
      emoji = '🚘';
    } else {
      bg = const Color(0xFF059669);
      emoji = '🚗';
    }

    final shadowPaint = Paint()
      ..color = bg.withValues(alpha: 0.28)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(
        const Offset(size / 2, size / 2 + 2), size / 2 - 8, shadowPaint);

    canvas.drawCircle(
        const Offset(size / 2, size / 2), size / 2 - 10, Paint()..color = bg);
    canvas.drawCircle(
      const Offset(size / 2, size / 2),
      size / 2 - 10,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    final tp = TextPainter(
      text: TextSpan(text: emoji, style: const TextStyle(fontSize: 26)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset((size - tp.width) / 2, (size - tp.height) / 2 - 1));

    final image = await recorder.endRecording().toImage(size.toInt(), size.toInt());
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(data!.buffer.asUint8List());
  }

  void _handleNearbyDriversSnapshot(Map<String, dynamic> snapshot) {
    if (!mounted) return;
    final summary = snapshot['summary'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(snapshot['summary'])
        : <String, dynamic>{};
    final drivers =
        (snapshot['drivers'] as List<dynamic>? ?? const []).cast<dynamic>();
    final nextTargets = <String, LatLng>{};
    final nextHeadings = <String, double>{};
    final nextTypes = <String, String>{};
    final nextTitles = <String, String>{};

    for (final raw in drivers) {
      final driver = Map<String, dynamic>.from(raw as Map);
      final id = driver['id']?.toString() ?? '';
      final lat = double.tryParse(driver['lat']?.toString() ?? '');
      final lng = double.tryParse(driver['lng']?.toString() ?? '');
      if (id.isEmpty || lat == null || lng == null) continue;
      nextTargets[id] = LatLng(lat, lng);
      nextHeadings[id] =
          double.tryParse(driver['heading']?.toString() ?? '0') ?? 0;
      nextTypes[id] = (driver['vehicleName'] ??
              driver['vehicle_name'] ??
              driver['vehicleType'] ??
              'car')
          .toString();
      nextTitles[id] = driver['fullName']?.toString() ?? 'Nearby driver';
    }

    final removedIds = _vehiclePositions.keys
        .where((id) => !nextTargets.containsKey(id))
        .toList(growable: false);
    for (final id in removedIds) {
      _vehiclePositions.remove(id);
      _vehicleHeadings.remove(id);
      _vehicleTypes.remove(id);
      _vehicleTitles.remove(id);
    }

    _nearbyInterpolationTimer?.cancel();
    final startPositions = Map<String, LatLng>.from(_vehiclePositions);
    var step = 0;
    const totalSteps = 5;
    _nearbyInterpolationTimer =
        Timer.periodic(const Duration(milliseconds: 180), (timer) async {
      step += 1;
      final t = step / totalSteps;
      nextTargets.forEach((id, target) {
        final start = startPositions[id] ?? target;
        _vehiclePositions[id] = LatLng(
          start.latitude + (target.latitude - start.latitude) * t,
          start.longitude + (target.longitude - start.longitude) * t,
        );
        _vehicleHeadings[id] = nextHeadings[id] ?? 0;
        _vehicleTypes[id] = nextTypes[id] ?? 'car';
        _vehicleTitles[id] = nextTitles[id] ?? 'Nearby driver';
      });
      await _rebuildNearbyMarkers();
      if (step >= totalSteps) {
        timer.cancel();
      }
    });

    setState(() {
      _availabilityText =
          summary['availabilityText']?.toString() ?? _availabilityText;
      _groupingEnabled = summary['groupingEnabled'] != false;
    });
  }

  Future<void> _rebuildNearbyMarkers() async {
    final markers = <Marker>{};
    for (final entry in _vehiclePositions.entries) {
      final id = entry.key;
      final icon = await _getVehicleMarkerIcon(_vehicleTypes[id] ?? 'car');
      markers.add(Marker(
        markerId: MarkerId('nearby_$id'),
        position: entry.value,
        icon: icon,
        rotation: _vehicleHeadings[id] ?? 0,
        anchor: const Offset(0.5, 0.5),
        flat: true,
        infoWindow: InfoWindow(title: _vehicleTitles[id] ?? 'Nearby driver'),
      ));
    }
    if (!mounted) return;
    setState(() {
      _nearbyVehicleMarkers = markers;
    });
  }

  // ─── Build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return Scaffold(
      backgroundColor: JT.bg,
      body: Stack(
        children: [
          // ── Google Map ────────────────────────────────────────────────
          if (!_locationLoading && _lat != null && _lng != null)
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(_lat!, _lng!),
                zoom: 15,
              ),
              markers: _nearbyVehicleMarkers,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              padding: const EdgeInsets.only(bottom: 240),
              onMapCreated: (controller) {
                _mapController = controller;
                if (_pendingCamera != null) {
                  _mapController!.animateCamera(CameraUpdate.newLatLngZoom(_pendingCamera!, 15));
                  _pendingCamera = null;
                }
              },
              onCameraMove: _onCameraMove,
              onCameraIdle: () {
                if (mounted) setState(() {});
                _onCameraIdle();
              },
            ),
          if (_locationLoading)
            const Center(child: CircularProgressIndicator()),

          // ── Center Map Pointer ─────────────────────────────────────────
          if (!_locationLoading && _lat != null && _lng != null)
            IgnorePointer(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 240),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Floating Icon
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        margin: const EdgeInsets.only(bottom: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 4)),
                          ],
                        ),
                        child: Text(
                          _geocoding ? 'Loading...' : 'Set Location Here',
                          style: GoogleFonts.poppins(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ),
                      const Icon(Icons.location_on, size: 48, color: JT.primary),
                      // Small dot representing the exact coordinate
                      Container(
                        width: 8, height: 4,
                        margin: const EdgeInsets.only(top: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      // Spacer to ensure the dot rests at the exact vertical center
                      const SizedBox(height: 80), 
                    ],
                  ),
                ),
              ),
            ),

        // ── Top layer (Search or Title) ──────────────────────────────
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: _showSearch
                  ? Column(
                      children: [
                        _buildSearchBar(),
                        const SizedBox(height: 8),
                        _buildSearchResults(),
                      ],
                    )
                  : _buildTopBar(),
            ),
          ),
        ),

          // ── Bottom card (address + confirm) ─────────────────────────
          Positioned(
            top: _showSearch ? 124 : 72,
            left: 16,
            right: 16,
            child: IgnorePointer(
              child: AnimatedOpacity(
                opacity: _locationLoading ? 0 : 1,
                duration: const Duration(milliseconds: 180),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.96),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: _groupingEnabled
                            ? JT.primary.withValues(alpha: 0.18)
                            : const Color(0xFFEA580C).withValues(alpha: 0.18),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: _nearbyVehicleMarkers.isEmpty
                                ? const Color(0xFFF59E0B)
                                : const Color(0xFF16A34A),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: (_nearbyVehicleMarkers.isEmpty
                                        ? const Color(0xFFF59E0B)
                                        : const Color(0xFF16A34A))
                                    .withValues(alpha: 0.32),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            _availabilityText,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              color: JT.textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (widget.serviceType == 'parcel') ...[
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF7ED),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              (widget.vehicleCategoryName ?? 'Parcel').toUpperCase(),
                              style: GoogleFonts.poppins(
                                color: const Color(0xFFEA580C),
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomCard(bottomPadding),
          ),

          // ── My location FAB ─────────────────────────────────────────
          Positioned(
            bottom: 200 + bottomPadding,
            right: 16,
            child: FloatingActionButton.small(
              heroTag: 'my_loc',
              backgroundColor: Colors.white,
              onPressed: _onMyLocationTap,
              child: _locationLoading
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: JT.primary),
                    )
                  : const Icon(Icons.my_location, color: JT.primary, size: 22),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Top bar widgets ────────────────────────────────────────────────────

  Widget _buildTopBar() {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 12, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: JT.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Text(
              widget.title,
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w400, color: JT.textPrimary),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.search_rounded, color: JT.primary),
            onPressed: () {
              setState(() => _showSearch = true);
              Future.delayed(const Duration(milliseconds: 100), () => _searchFocus.requestFocus());
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 12, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: JT.textPrimary),
            onPressed: () {
              setState(() {
                _showSearch = false;
                _predictions = [];
                _searchCtrl.clear();
              });
              _searchFocus.unfocus();
            },
          ),
          Expanded(
            child: TextField(
              controller: _searchCtrl,
              focusNode: _searchFocus,
              style: GoogleFonts.poppins(fontSize: 15, color: JT.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search for a place...',
                hintStyle: GoogleFonts.poppins(fontSize: 15, color: JT.textSecondary),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onChanged: (v) {
                _debounce?.cancel();
                _debounce = Timer(const Duration(milliseconds: 350), () => _searchPlaces(v));
              },
            ),
          ),
          if (_searchCtrl.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear, color: JT.textSecondary, size: 20),
              onPressed: () {
                _searchCtrl.clear();
                setState(() => _predictions = []);
              },
            ),
          if (_searching)
            const Padding(
              padding: EdgeInsets.only(right: 14),
              child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: JT.primary)),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    return Container(
      constraints: const BoxConstraints(maxHeight: 300),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _predictions.length,
        separatorBuilder: (_, __) => const Divider(height: 1, indent: 56),
        itemBuilder: (_, i) {
          final pred = _predictions[i];
          return ListTile(
            leading: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: JT.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.location_on_outlined, color: JT.primary, size: 20),
            ),
            title: Text(
              pred.mainText,
              style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: JT.textPrimary),
              maxLines: 1, overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              pred.secondaryText,
              style: GoogleFonts.poppins(fontSize: 12, color: JT.textSecondary),
              maxLines: 1, overflow: TextOverflow.ellipsis,
            ),
            dense: true,
            onTap: () => _selectPrediction(pred),
          );
        },
      ),
    );
  }

  // ─── Bottom card ────────────────────────────────────────────────────────

  Widget _buildBottomCard(double bottomPadding) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 16, offset: Offset(0, -4))],
      ),
      padding: EdgeInsets.fromLTRB(20, 20, 20, 16 + bottomPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(color: const Color(0xFFDCE9FF), borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),

          // Location icon + address
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: JT.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.location_on_rounded, color: JT.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Selected Location',
                      style: GoogleFonts.poppins(fontSize: 12, color: JT.textSecondary, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 2),
                    _geocoding
                        ? Row(children: [
                            const SizedBox(
                              width: 14, height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: JT.primary),
                            ),
                            const SizedBox(width: 8),
                            Text('Getting address...', style: GoogleFonts.poppins(fontSize: 13, color: JT.textSecondary)),
                          ])
                        : Text(
                            _address,
                            style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: JT.textPrimary),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Lat/lng display
          Padding(
            padding: const EdgeInsets.only(left: 52),
            child: Text(
              (_lat != null && _lng != null)
                  ? '${_lat!.toStringAsFixed(6)}, ${_lng!.toStringAsFixed(6)}'
                  : 'Location not set',
              style: GoogleFonts.poppins(fontSize: 11, color: JT.textSecondary),
            ),
          ),
          const SizedBox(height: 20),

          // Confirm button
          JT.gradientButton(
            label: 'Confirm Location',
            onTap: _confirmLocation,
          ),
        ],
      ),
    );
  }
}

// ─── Data model for Place predictions ──────────────────────────────────────
class _PlacePrediction {
  final String placeId;
  final String description;
  final String mainText;
  final String secondaryText;
  final double? lat;
  final double? lng;
  const _PlacePrediction({
    required this.placeId,
    required this.description,
    required this.mainText,
    required this.secondaryText,
    this.lat,
    this.lng,
  });
}
