import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import '../../config/jago_theme.dart';

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

  const MapLocationPicker({
    super.key,
    this.title = 'Select Location',
    this.initialLat,
    this.initialLng,
  });

  @override
  State<MapLocationPicker> createState() => _MapLocationPickerState();
}

class _MapLocationPickerState extends State<MapLocationPicker> {
  GoogleMapController? _mapController;
  LatLng? _pendingCamera; // camera move queued before map ready

  // Current center of the map (source of truth)
  double _lat = 17.3850;
  double _lng = 78.4867;
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

  static const _apiKey = ApiConfig.googleMapsApiKey;

  @override
  void initState() {
    super.initState();
    if (widget.initialLat != null && widget.initialLng != null) {
      _lat = widget.initialLat!;
      _lng = widget.initialLng!;
      _locationLoading = false;
      _reverseGeocode(_lat, _lng);
    } else {
      _getCurrentLocation();
    }
  }

  @override
  void dispose() {
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
      if (!serviceEnabled) {
        setState(() => _locationLoading = false);
        return;
      }
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
        setState(() => _locationLoading = false);
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      setState(() {
        _lat = pos.latitude;
        _lng = pos.longitude;
        _locationLoading = false;
      });
      final target = LatLng(_lat, _lng);
      if (_mapController != null) {
        _mapController!.animateCamera(CameraUpdate.newLatLngZoom(target, 16));
      } else {
        _pendingCamera = target; // map not ready yet — will animate in onMapCreated
      }
      _reverseGeocode(_lat, _lng);
    } catch (_) {
      setState(() => _locationLoading = false);
    }
  }

  // ─── Reverse geocode ────────────────────────────────────────────────────

  Future<void> _reverseGeocode(double lat, double lng) async {
    setState(() => _geocoding = true);
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json'
        '?latlng=$lat,$lng&key=$_apiKey',
      );
      final res = await http.get(url);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final results = data['results'] as List<dynamic>?;
        if (results != null && results.isNotEmpty && mounted) {
          setState(() => _address = results[0]['formatted_address'] ?? 'Unknown location');
        }
      }
    } catch (_) {
      if (mounted) setState(() => _address = 'Unable to get address');
    }
    if (mounted) setState(() => _geocoding = false);
  }

  // ─── Places Autocomplete Search ─────────────────────────────────────────

  Future<void> _searchPlaces(String query) async {
    if (query.length < 3) {
      setState(() => _predictions = []);
      return;
    }
    setState(() => _searching = true);
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/autocomplete/json'
        '?input=${Uri.encodeComponent(query)}'
        '&key=$_apiKey'
        '&sessiontoken=$_sessionToken'
        '&location=$_lat,$_lng'
        '&radius=50000'
        '&components=country:in',
      );
      final res = await http.get(url);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final preds = (data['predictions'] as List<dynamic>?) ?? [];
        if (mounted) {
          setState(() {
            _predictions = preds.map((p) => _PlacePrediction(
              placeId: p['place_id'] ?? '',
              description: p['description'] ?? '',
              mainText: p['structured_formatting']?['main_text'] ?? p['description'] ?? '',
              secondaryText: p['structured_formatting']?['secondary_text'] ?? '',
            )).toList();
          });
        }
      }
    } catch (_) {}
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

    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/details/json'
        '?place_id=${pred.placeId}'
        '&fields=geometry,formatted_address'
        '&key=$_apiKey'
        '&sessiontoken=$_sessionToken',
      );
      final res = await http.get(url);
      // Generate a new session token after a detail fetch
      _sessionToken = DateTime.now().millisecondsSinceEpoch.toString();
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final result = data['result'];
        if (result != null) {
          final loc = result['geometry']?['location'];
          final addr = result['formatted_address'] ?? pred.description;
          if (loc != null) {
            final lat = (loc['lat'] as num).toDouble();
            final lng = (loc['lng'] as num).toDouble();
            setState(() {
              _lat = lat;
              _lng = lng;
              _address = addr;
              _geocoding = false;
            });
            _mapController?.animateCamera(
              CameraUpdate.newLatLngZoom(LatLng(lat, lng), 16),
            );
            return;
          }
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _geocoding = false);
  }

  // ─── Map callbacks ─────────────────────────────────────────────────────

  void _onCameraIdle() {
    _reverseGeocode(_lat, _lng);
  }

  void _onCameraMove(CameraPosition pos) {
    _lat = pos.target.latitude;
    _lng = pos.target.longitude;
  }

  void _onMyLocationTap() async {
    await _getCurrentLocation();
  }

  void _confirmLocation() {
    Navigator.pop(
      context,
      PickedLocation(lat: _lat, lng: _lng, address: _address),
    );
  }

  // ─── Build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      body: Stack(
        children: [
          // ── Google Map ──────────────────────────────────────────────────
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(_lat, _lng),
              zoom: 16,
            ),
            onMapCreated: (c) {
              _mapController = c;
              if (_pendingCamera != null) {
                c.animateCamera(CameraUpdate.newLatLngZoom(_pendingCamera!, 16));
                _pendingCamera = null;
              }
            },
            onCameraMove: _onCameraMove,
            onCameraIdle: _onCameraIdle,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            compassEnabled: false,
          ),

          // ── Fixed center pin ────────────────────────────────────────────
          const Center(
            child: Padding(
              padding: EdgeInsets.only(bottom: 36), // offset for pin tip
              child: Icon(Icons.location_on, size: 48, color: Color(0xFFE53935)),
            ),
          ),

          // ── Top bar (back + search) ─────────────────────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            right: 16,
            child: _showSearch ? _buildSearchBar() : _buildTopBar(),
          ),

          // ── Search results overlay ──────────────────────────────────────
          if (_showSearch && _predictions.isNotEmpty)
            Positioned(
              top: MediaQuery.of(context).padding.top + 68,
              left: 16,
              right: 16,
              child: _buildSearchResults(),
            ),

          // ── Bottom card (address + confirm) ─────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomCard(bottomPadding),
          ),

          // ── My location FAB ─────────────────────────────────────────────
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
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: JT.textPrimary),
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
              '${_lat.toStringAsFixed(6)}, ${_lng.toStringAsFixed(6)}',
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

  const _PlacePrediction({
    required this.placeId,
    required this.description,
    required this.mainText,
    required this.secondaryText,
  });
}
