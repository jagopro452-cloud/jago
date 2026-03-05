import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import '../../services/auth_service.dart';
import '../tracking/tracking_screen.dart';

class ParcelBookingScreen extends StatefulWidget {
  final String pickupAddress;
  final double pickupLat;
  final double pickupLng;
  const ParcelBookingScreen({
    super.key,
    this.pickupAddress = 'Getting location...',
    this.pickupLat = 17.3850,
    this.pickupLng = 78.4867,
  });
  @override
  State<ParcelBookingScreen> createState() => _ParcelBookingScreenState();
}

class _ParcelBookingScreenState extends State<ParcelBookingScreen> {
  final _destCtrl = TextEditingController();
  final _receiverNameCtrl = TextEditingController();
  final _receiverPhoneCtrl = TextEditingController();
  final _instructionsCtrl = TextEditingController();

  List<dynamic> _parcelCategories = [];
  List<dynamic> _weights = [];
  List<Map<String, dynamic>> _allVehicles = [];

  String? _selectedCategoryId;
  String? _selectedCategoryName;
  String? _selectedCategoryIcon;
  String? _selectedWeightId;
  String? _selectedWeightLabel;
  Map<String, dynamic>? _selectedVehicle;
  String? _cargoType;
  bool _needsHelper = false;

  static const _cargoTypes = ['General Goods', 'Electronics', 'Furniture', 'Fragile Items', 'Bulk Materials', 'Perishable Goods', 'Construction Material', 'Other'];

  String _destAddress = '';
  double _destLat = 0, _destLng = 0;
  String _estimatedFare = '';
  bool _loading = true;
  bool _estimatingFare = false;
  bool _bookingLoading = false;
  int _step = 0;

  static const Color _dark = Color(0xFF1A1A1A);
  static const Color _yellow = Color(0xFFFBBC04);
  static const Color _lightBg = Color(0xFFF5F5F5);
  static const Color _blue = Color(0xFF1E6DE5);

  final _steps = ['Vehicle', 'Delivery', 'Details', 'Confirm'];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _destCtrl.dispose();
    _receiverNameCtrl.dispose();
    _receiverPhoneCtrl.dispose();
    _instructionsCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final headers = await AuthService.getHeaders();
      final results = await Future.wait([
        http.get(Uri.parse('${ApiConfig.baseUrl}/api/parcel-categories'), headers: headers),
        http.get(Uri.parse('${ApiConfig.baseUrl}/api/parcel-weights'), headers: headers),
        http.get(Uri.parse('${ApiConfig.baseUrl}/api/vehicle-categories'), headers: headers),
      ]);
      if (results[0].statusCode == 200) {
        final raw = jsonDecode(results[0].body);
        _parcelCategories = raw is List ? raw : (raw['data'] ?? []);
      }
      if (results[1].statusCode == 200) {
        final raw = jsonDecode(results[1].body);
        _weights = raw is List ? raw : (raw['data'] ?? []);
      }
      if (results[2].statusCode == 200) {
        final all = jsonDecode(results[2].body) as List;
        _allVehicles = _buildParcelVehicleList(all);
      }
      if (_allVehicles.isEmpty) _allVehicles = _defaultVehicles();
    } catch (_) {
      _allVehicles = _defaultVehicles();
    }
    if (mounted) setState(() => _loading = false);
  }

  List<Map<String, dynamic>> _buildParcelVehicleList(List<dynamic> all) {
    final parcelOrder = ['bike parcel', 'bike', 'mini auto', 'temo auto', 'tata ace', 'mini cargo', 'cargo truck'];
    final result = <Map<String, dynamic>>[];
    for (final key in parcelOrder) {
      for (final v in all) {
        final name = (v['name'] ?? '').toString().toLowerCase();
        if (name.contains(key) && !result.any((r) => r['id'] == v['id'])) {
          result.add(Map<String, dynamic>.from(v));
        }
      }
    }
    for (final v in all) {
      if (v['type'] == 'parcel' || v['type'] == 'cargo') {
        if (!result.any((r) => r['id'] == v['id'])) {
          result.add(Map<String, dynamic>.from(v));
        }
      }
    }
    return result;
  }

  List<Map<String, dynamic>> _defaultVehicles() => [
    {'id': null, 'name': 'Bike Parcel', 'type': 'parcel', 'minimumFare': '25', 'baseFare': '25'},
    {'id': null, 'name': 'Mini Auto', 'type': 'ride', 'minimumFare': '35', 'baseFare': '35'},
    {'id': null, 'name': 'Temo Auto', 'type': 'ride', 'minimumFare': '30', 'baseFare': '30'},
    {'id': null, 'name': 'Tata Ace', 'type': 'cargo', 'minimumFare': '200', 'baseFare': '200'},
  ];

  String _emojiFor(String name) {
    final n = name.toLowerCase();
    if (n.contains('bike')) return '🏍️';
    if (n.contains('temo') || n.contains('auto')) return '🛺';
    if (n.contains('tata ace')) return '🚚';
    if (n.contains('cargo truck')) return '🚛';
    if (n.contains('cargo van') || n.contains('mini cargo')) return '🚐';
    return '📦';
  }

  String _descFor(String name, String type) {
    final n = name.toLowerCase();
    if (n.contains('bike parcel') || (n.contains('bike') && type == 'parcel')) return 'Small parcels • Fastest delivery';
    if (n.contains('bike')) return 'Small parcels • Envelopes • Quick';
    if (n.contains('temo')) return 'Medium parcels • Good capacity';
    if (n.contains('mini auto')) return 'Medium parcels • Boxes & bags';
    if (n.contains('tata ace')) return 'Large cargo • Furniture • Bulk';
    if (n.contains('cargo truck')) return 'Heavy cargo • Commercial use';
    if (n.contains('mini cargo') || n.contains('cargo van')) return 'Medium cargo • Shop deliveries';
    return 'Parcel delivery';
  }

  Future<void> _estimateFare() async {
    if (_selectedVehicle == null || (_destLat == 0 && _destLng == 0)) return;
    setState(() => _estimatingFare = true);
    try {
      final headers = await AuthService.getHeaders();
      headers['Content-Type'] = 'application/json';
      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/app/customer/estimate-fare'),
        headers: headers,
        body: jsonEncode({
          'pickupLat': widget.pickupLat,
          'pickupLng': widget.pickupLng,
          'destLat': _destLat != 0 ? _destLat : 17.4,
          'destLng': _destLng != 0 ? _destLng : 78.5,
          'vehicleCategoryId': _selectedVehicle?['id'],
        }),
      );
      if (res.statusCode == 200 && mounted) {
        final data = jsonDecode(res.body);
        final fare = data['estimatedFare'] ?? data['fare'] ?? data['fares']?[0]?['estimatedFare'] ?? '';
        setState(() => _estimatedFare = '₹${fare.toString()}');
      }
    } catch (_) {}
    if (mounted) setState(() => _estimatingFare = false);
  }

  bool get _isCargoVehicle {
    final name = (_selectedVehicle?['name'] ?? '').toString().toLowerCase();
    return name.contains('cargo') || name.contains('tata ace') || name.contains('truck');
  }

  Future<void> _bookParcel() async {
    if (_receiverNameCtrl.text.trim().isEmpty) {
      _showSnack('Please enter receiver name');
      return;
    }
    if (_receiverPhoneCtrl.text.length < 10) {
      _showSnack('Please enter a valid 10-digit phone number');
      return;
    }
    if (_destAddress.isEmpty && _destCtrl.text.isEmpty) {
      _showSnack('Please enter delivery address');
      return;
    }
    setState(() => _bookingLoading = true);
    try {
      final headers = await AuthService.getHeaders();
      headers['Content-Type'] = 'application/json';
      final dest = _destAddress.isNotEmpty ? _destAddress : _destCtrl.text;
      final isCargoVeh = _isCargoVehicle;
      final cargoDetails = isCargoVeh && _cargoType != null ? ' | Cargo Type: $_cargoType | Helper: ${_needsHelper ? 'Yes' : 'No'}' : '';
      final notes = '${isCargoVeh ? '🚛 Cargo' : '📦 Parcel'} | Vehicle: ${_selectedVehicle?['name'] ?? ''}$cargoDetails | Category: ${_selectedCategoryIcon ?? ''}${_selectedCategoryName ?? 'Other'} | Weight: ${_selectedWeightLabel ?? 'Light'} | Receiver: ${_receiverNameCtrl.text.trim()} (+91 ${_receiverPhoneCtrl.text}) | ${_instructionsCtrl.text.isNotEmpty ? 'Note: ${_instructionsCtrl.text}' : ''}';
      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/app/customer/book-ride'),
        headers: headers,
        body: jsonEncode({
          'pickupAddress': widget.pickupAddress,
          'destinationAddress': dest,
          'pickupLat': widget.pickupLat,
          'pickupLng': widget.pickupLng,
          'destinationLat': _destLat != 0 ? _destLat : 17.4,
          'destinationLng': _destLng != 0 ? _destLng : 78.5,
          'vehicleCategoryId': _selectedVehicle?['id'],
          'paymentMethod': 'cash',
          'notes': notes,
          'receiverName': _receiverNameCtrl.text.trim(),
          'receiverPhone': _receiverPhoneCtrl.text,
          if (isCargoVeh && _cargoType != null) 'cargoType': _cargoType,
          if (isCargoVeh) 'helperRequired': _needsHelper,
        }),
      );
      if (res.statusCode == 200 || res.statusCode == 201) {
        final data = jsonDecode(res.body);
        final tripId = data['tripId']?.toString() ?? data['trip']?['id']?.toString() ?? '';
        if (tripId.isNotEmpty && mounted) {
          Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => TrackingScreen(tripId: tripId)));
        }
      } else {
        final err = jsonDecode(res.body);
        if (mounted) _showSnack(err['message'] ?? 'Booking failed');
      }
    } catch (e) {
      if (mounted) _showSnack('Error: $e');
    }
    if (mounted) setState(() => _bookingLoading = false);
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
      backgroundColor: Colors.red[600],
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  bool _canGoNext() {
    if (_step == 0) return _selectedVehicle != null;
    if (_step == 1) return (_destAddress.isNotEmpty || _destCtrl.text.isNotEmpty) && _receiverNameCtrl.text.isNotEmpty && _receiverPhoneCtrl.text.length == 10;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _dark, size: 20),
          onPressed: () {
            if (_step > 0) {
              setState(() => _step--);
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Parcel Delivery', style: TextStyle(fontWeight: FontWeight.w800, color: _dark, fontSize: 17)),
          Text(_steps[_step], style: TextStyle(fontSize: 11, color: Colors.grey[500], fontWeight: FontWeight.w500)),
        ]),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(child: Text('${_step + 1}/${_steps.length}',
              style: TextStyle(fontSize: 13, color: Colors.grey[500], fontWeight: FontWeight.w600))),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: (_step + 1) / _steps.length,
            backgroundColor: Colors.grey[100],
            valueColor: const AlwaysStoppedAnimation(_dark),
            minHeight: 3,
          ),
        ),
      ),
      body: _loading
        ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
        : SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: KeyedSubtree(
                key: ValueKey(_step),
                child: _step == 0 ? _buildVehicleStep()
                  : _step == 1 ? _buildDeliveryStep()
                  : _step == 2 ? _buildDetailsStep()
                  : _buildConfirmStep(),
              ),
            ),
          ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  // ── STEP 0: Vehicle Selection ──────────────────────────────────────────────
  Widget _buildVehicleStep() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Select Delivery Vehicle',
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _dark)),
      const SizedBox(height: 6),
      Text('Choose vehicle based on parcel size',
        style: TextStyle(fontSize: 13, color: Colors.grey[500])),
      const SizedBox(height: 20),
      ..._allVehicles.map((v) {
        final name = v['name']?.toString() ?? '';
        final isSelected = _selectedVehicle?['id'] == v['id'] && _selectedVehicle?['name'] == name;
        final minFare = v['minimumFare']?.toString() ?? v['base_fare']?.toString() ?? '25';
        final type = v['type']?.toString() ?? 'parcel';
        return GestureDetector(
          onTap: () {
            setState(() => _selectedVehicle = v);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected ? _dark : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? _dark : Colors.grey[200]!,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected ? [BoxShadow(color: _dark.withOpacity(0.15), blurRadius: 16, offset: const Offset(0, 4))] : [],
            ),
            child: Row(children: [
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white.withOpacity(0.12) : const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(child: Text(_emojiFor(name), style: const TextStyle(fontSize: 28))),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(name,
                    style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700,
                      color: isSelected ? Colors.white : _dark,
                    )),
                  const SizedBox(height: 3),
                  Text(_descFor(name, type),
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected ? Colors.white.withOpacity(0.65) : Colors.grey[500],
                    )),
                ]),
              ),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('₹$minFare+',
                  style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w800,
                    color: isSelected ? _yellow : _dark,
                  )),
                const SizedBox(height: 2),
                Text('base fare',
                  style: TextStyle(
                    fontSize: 10,
                    color: isSelected ? Colors.white.withOpacity(0.5) : Colors.grey[400],
                  )),
              ]),
            ]),
          ),
        );
      }).toList(),
    ]);
  }

  // ── STEP 1: Delivery Details ───────────────────────────────────────────────
  Widget _buildDeliveryStep() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (_selectedVehicle != null) ...[
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: _lightBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(children: [
            Text(_emojiFor(_selectedVehicle!['name'] ?? ''), style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 10),
            Text(_selectedVehicle!['name'] ?? '',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: _dark)),
            const Spacer(),
            GestureDetector(
              onTap: () => setState(() => _step = 0),
              child: Text('Change', style: TextStyle(fontSize: 12, color: Colors.blue[700], fontWeight: FontWeight.w600)),
            ),
          ]),
        ),
        const SizedBox(height: 20),
      ],
      const Text('Pickup Location', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF374151))),
      const SizedBox(height: 8),
      _locationTile(Icons.radio_button_checked_rounded, Colors.blue, widget.pickupAddress),
      const SizedBox(height: 12),
      const Text('Delivery Location', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF374151))),
      const SizedBox(height: 8),
      GestureDetector(
        onTap: _openDestinationSearch,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: _destAddress.isNotEmpty ? const Color(0xFFF0FDF4) : _lightBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _destAddress.isNotEmpty ? Colors.green[300]! : Colors.grey[200]!,
            ),
          ),
          child: Row(children: [
            Icon(Icons.location_on_rounded,
              color: _destAddress.isNotEmpty ? Colors.green[600] : Colors.red[400],
              size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _destAddress.isNotEmpty ? _destAddress : 'Search delivery location...',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: _destAddress.isNotEmpty ? FontWeight.w600 : FontWeight.w400,
                  color: _destAddress.isNotEmpty ? _dark : Colors.grey[500],
                ),
                maxLines: 2, overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(Icons.search, color: Colors.grey[400], size: 20),
          ]),
        ),
      ),
      const SizedBox(height: 24),
      const Text('Receiver Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _dark)),
      const SizedBox(height: 14),
      _inputField(
        controller: _receiverNameCtrl,
        label: 'Receiver Name',
        icon: Icons.person_outline_rounded,
        caps: TextCapitalization.words,
      ),
      const SizedBox(height: 10),
      _inputField(
        controller: _receiverPhoneCtrl,
        label: 'Receiver Phone',
        icon: Icons.phone_outlined,
        keyboard: TextInputType.phone,
        prefix: '+91 ',
        maxLength: 10,
        digitsOnly: true,
      ),
    ]);
  }

  void _openDestinationSearch() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _DestSearchSheet(
        pickupLat: widget.pickupLat,
        pickupLng: widget.pickupLng,
        onSelected: (name, lat, lng) {
          setState(() {
            _destAddress = name;
            _destLat = lat;
            _destLng = lng;
          });
          _estimateFare();
        },
      ),
    );
  }

  Widget _locationTile(IconData icon, Color color, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: _lightBg, borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text(text,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: _dark),
          maxLines: 2, overflow: TextOverflow.ellipsis)),
      ]),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboard = TextInputType.text,
    TextCapitalization caps = TextCapitalization.none,
    String? prefix,
    int? maxLength,
    bool digitsOnly = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboard,
      textCapitalization: caps,
      inputFormatters: [
        if (digitsOnly) FilteringTextInputFormatter.digitsOnly,
        if (maxLength != null) LengthLimitingTextInputFormatter(maxLength),
      ],
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: _dark),
      decoration: InputDecoration(
        labelText: label,
        prefixText: prefix,
        prefixIcon: Icon(icon, color: Colors.grey[400], size: 20),
        filled: true, fillColor: _lightBg,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _dark, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      onChanged: (_) => setState(() {}),
    );
  }

  // ── STEP 2: Parcel Info ────────────────────────────────────────────────────
  Widget _buildDetailsStep() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('What are you sending?', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _dark)),
      const SizedBox(height: 6),
      Text('Select category and weight', style: TextStyle(fontSize: 13, color: Colors.grey[500])),
      const SizedBox(height: 20),
      if (_parcelCategories.isNotEmpty) ...[
        const Text('Parcel Category', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _dark)),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4, crossAxisSpacing: 8, mainAxisSpacing: 8, childAspectRatio: 0.85),
          itemCount: _parcelCategories.length,
          itemBuilder: (_, i) {
            final cat = _parcelCategories[i];
            final isSelected = _selectedCategoryId == cat['id']?.toString();
            return GestureDetector(
              onTap: () => setState(() {
                _selectedCategoryId = cat['id']?.toString();
                _selectedCategoryName = cat['name'];
                _selectedCategoryIcon = cat['icon'];
              }),
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected ? _dark : _lightBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isSelected ? _dark : Colors.transparent),
                ),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(cat['icon'] ?? '📦', style: const TextStyle(fontSize: 26)),
                  const SizedBox(height: 4),
                  Text(cat['name'] ?? '',
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : _dark),
                    textAlign: TextAlign.center, maxLines: 2),
                ]),
              ),
            );
          },
        ),
        const SizedBox(height: 24),
      ],
      if (_weights.isNotEmpty) ...[
        const Text('Parcel Weight', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _dark)),
        const SizedBox(height: 12),
        ..._weights.map((w) {
          final isSelected = _selectedWeightId == w['id']?.toString();
          return GestureDetector(
            onTap: () => setState(() {
              _selectedWeightId = w['id']?.toString();
              _selectedWeightLabel = w['label'];
            }),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: isSelected ? _dark : _lightBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(children: [
                Icon(Icons.scale_rounded, color: isSelected ? Colors.white : Colors.grey[500], size: 20),
                const SizedBox(width: 12),
                Expanded(child: Text(w['label'] ?? '',
                  style: TextStyle(fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : _dark))),
                if (isSelected) const Icon(Icons.check_circle_rounded, color: Color(0xFFFBBC04), size: 20),
              ]),
            ),
          );
        }),
        const SizedBox(height: 20),
      ],
      if (_isCargoVehicle) ...[
        const Text('Cargo Type', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _dark)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8, runSpacing: 8,
          children: _cargoTypes.map((t) {
            final isSelected = _cargoType == t;
            return GestureDetector(
              onTap: () => setState(() => _cargoType = t),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  color: isSelected ? _dark : _lightBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isSelected ? _dark : Colors.grey[200]!),
                ),
                child: Text(t, style: TextStyle(
                  fontSize: 12.5, fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : _dark)),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(color: _lightBg, borderRadius: BorderRadius.circular(12)),
          child: Row(children: [
            const Icon(Icons.person_outline_rounded, size: 20, color: Color(0xFF374151)),
            const SizedBox(width: 12),
            const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Loading Helper Required?', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _dark)),
              SizedBox(height: 2),
              Text('Add helper for loading/unloading heavy goods', style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
            ])),
            Switch(
              value: _needsHelper,
              onChanged: (v) => setState(() => _needsHelper = v),
              activeColor: _dark,
            ),
          ]),
        ),
        const SizedBox(height: 20),
      ],
      const Text('Special Instructions (Optional)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _dark)),
      const SizedBox(height: 8),
      TextField(
        controller: _instructionsCtrl,
        maxLines: 3,
        style: const TextStyle(fontSize: 14, color: _dark),
        decoration: InputDecoration(
          hintText: 'e.g., Handle with care, Fragile, Do not bend...',
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
          filled: true, fillColor: _lightBg,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _dark, width: 1.5)),
          contentPadding: const EdgeInsets.all(14),
        ),
      ),
    ]);
  }

  // ── STEP 3: Confirm ────────────────────────────────────────────────────────
  Widget _buildConfirmStep() {
    final dest = _destAddress.isNotEmpty ? _destAddress : _destCtrl.text;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Booking Summary', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _dark)),
      const SizedBox(height: 6),
      Text('Review before confirming', style: TextStyle(fontSize: 13, color: Colors.grey[500])),
      const SizedBox(height: 20),
      // Vehicle card
      if (_selectedVehicle != null) _confirmCard(
        child: Row(children: [
          Text(_emojiFor(_selectedVehicle!['name'] ?? ''), style: const TextStyle(fontSize: 30)),
          const SizedBox(width: 14),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_selectedVehicle!['name'] ?? '',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _dark)),
            Text(_descFor(_selectedVehicle!['name'] ?? '', _selectedVehicle!['type'] ?? ''),
              style: TextStyle(fontSize: 12, color: Colors.grey[500])),
          ]),
        ]),
      ),
      const SizedBox(height: 10),
      // Route card
      _confirmCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _routeRow('📍', 'Pickup', widget.pickupAddress),
          const SizedBox(height: 12),
          Container(height: 1, color: Colors.grey[100]),
          const SizedBox(height: 12),
          _routeRow('📦', 'Delivery', dest.isEmpty ? 'Not entered' : dest),
        ]),
      ),
      const SizedBox(height: 10),
      // Receiver card
      _confirmCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Receiver', style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF), fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(_receiverNameCtrl.text, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _dark)),
          const SizedBox(height: 2),
          Text('+91 ${_receiverPhoneCtrl.text}', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
        ]),
      ),
      if (_selectedCategoryName != null || _selectedWeightLabel != null) ...[
        const SizedBox(height: 10),
        _confirmCard(
          child: Row(children: [
            if (_selectedCategoryIcon != null) ...[
              Text(_selectedCategoryIcon!, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 10),
            ],
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (_selectedCategoryName != null)
                Text(_selectedCategoryName!, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _dark)),
              if (_selectedWeightLabel != null)
                Text(_selectedWeightLabel!, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
            ]),
          ]),
        ),
      ],
      if (_isCargoVehicle && (_cargoType != null || _needsHelper)) ...[
        const SizedBox(height: 10),
        _confirmCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Cargo Details', style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF), fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            if (_cargoType != null) Row(children: [
              const Icon(Icons.inventory_2_outlined, size: 16, color: Color(0xFF374151)),
              const SizedBox(width: 8),
              Text(_cargoType!, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _dark)),
            ]),
            if (_needsHelper) ...[
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.person_outline_rounded, size: 16, color: Color(0xFF374151)),
                const SizedBox(width: 8),
                Text('Loading helper requested', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
              ]),
            ],
          ]),
        ),
      ],
      if (_instructionsCtrl.text.isNotEmpty) ...[
        const SizedBox(height: 10),
        _confirmCard(
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.info_outline, size: 18, color: Color(0xFF9CA3AF)),
            const SizedBox(width: 10),
            Expanded(child: Text(_instructionsCtrl.text,
              style: TextStyle(fontSize: 13, color: Colors.grey[600]))),
          ]),
        ),
      ],
      // Fare card
      const SizedBox(height: 10),
      _confirmCard(
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Payment', style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF), fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            const Text('💵 Cash on Delivery', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _dark)),
          ]),
          _estimatingFare
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
            : Text(_estimatedFare.isNotEmpty ? _estimatedFare : 'Calculating...',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900,
                  color: _estimatedFare.isNotEmpty ? _dark : Colors.grey[400])),
        ]),
      ),
    ]);
  }

  Widget _confirmCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _lightBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: child,
    );
  }

  Widget _routeRow(String emoji, String label, String value) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(emoji, style: const TextStyle(fontSize: 16)),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF), fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _dark),
          maxLines: 2, overflow: TextOverflow.ellipsis),
      ])),
    ]);
  }

  // ── Bottom Bar ─────────────────────────────────────────────────────────────
  Widget _buildBottomBar() {
    final isLast = _step == _steps.length - 1;
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[100]!, width: 1)),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: GestureDetector(
          onTap: (_canGoNext() && !_bookingLoading)
            ? () {
                if (isLast) {
                  _bookParcel();
                } else {
                  setState(() => _step++);
                  if (_step == _steps.length - 1) _estimateFare();
                }
              }
            : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: _canGoNext() && !_bookingLoading ? _dark : Colors.grey[200],
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: _bookingLoading
                ? const SizedBox(width: 22, height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text(
                    isLast ? '📦 Confirm Booking' : 'Continue →',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: _canGoNext() ? Colors.white : Colors.grey[400],
                    ),
                  ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Destination Search Sheet ─────────────────────────────────────────────────
class _DestSearchSheet extends StatefulWidget {
  final double pickupLat, pickupLng;
  final Function(String name, double lat, double lng) onSelected;
  const _DestSearchSheet({required this.pickupLat, required this.pickupLng, required this.onSelected});
  @override
  State<_DestSearchSheet> createState() => _DestSearchSheetState();
}

class _DestSearchSheetState extends State<_DestSearchSheet> {
  final _ctrl = TextEditingController();
  List<Map<String, dynamic>> _predictions = [];
  bool _searching = false;
  Timer? _debounce;

  static const Color _dark = Color(0xFF1A1A1A);
  static const Color _lightBg = Color(0xFFF5F5F5);

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
        '&radius=50000&components=country:in'
        '&key=${ApiConfig.googleMapsApiKey}';
      final res = await http.get(Uri.parse(url));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          _predictions = ((data['predictions'] as List<dynamic>?) ?? []).map((p) => {
            'placeId': p['place_id'],
            'description': p['description'],
            'mainText': p['structured_formatting']?['main_text'] ?? p['description'],
            'secondaryText': p['structured_formatting']?['secondary_text'] ?? '',
          }).toList().cast<Map<String, dynamic>>();
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _searching = false);
  }

  Future<void> _selectPlace(Map<String, dynamic> place) async {
    try {
      final url = 'https://maps.googleapis.com/maps/api/geocode/json?place_id=${place['placeId']}&key=${ApiConfig.googleMapsApiKey}';
      final res = await http.get(Uri.parse(url));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final results = data['results'] as List?;
        if (results != null && results.isNotEmpty) {
          final loc = results[0]['geometry']['location'];
          if (mounted) Navigator.pop(context);
          widget.onSelected(place['description'],
            (loc['lat'] as num).toDouble(), (loc['lng'] as num).toDouble());
          return;
        }
      }
    } catch (_) {}
    if (mounted) { Navigator.pop(context); widget.onSelected(place['description'], 0, 0); }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 40, height: 4, margin: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(2))),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Delivery Location', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _dark)),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(color: _lightBg, borderRadius: BorderRadius.circular(12)),
              child: TextField(
                controller: _ctrl,
                autofocus: true,
                onChanged: _onChanged,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: _dark),
                decoration: InputDecoration(
                  hintText: 'Search delivery address...',
                  hintStyle: TextStyle(color: Colors.grey[400], fontWeight: FontWeight.w400),
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF6B7280), size: 22),
                  suffixIcon: _searching
                    ? const Padding(padding: EdgeInsets.all(14),
                        child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)))
                    : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 8),
        ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.5),
          child: _predictions.isEmpty
            ? Padding(
                padding: const EdgeInsets.all(40),
                child: Column(children: [
                  Icon(Icons.location_on_outlined, size: 48, color: Colors.grey[300]),
                  const SizedBox(height: 12),
                  Text('Type to search delivery location',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[400], fontSize: 14)),
                ]))
            : ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                itemCount: _predictions.length,
                separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey[100]),
                itemBuilder: (_, i) {
                  final p = _predictions[i];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    leading: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(color: _lightBg, borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.location_on_rounded, color: Color(0xFF6B7280), size: 18)),
                    title: Text(p['mainText'] ?? '',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: _dark)),
                    subtitle: (p['secondaryText'] ?? '').isNotEmpty
                      ? Text(p['secondaryText'],
                          style: TextStyle(color: Colors.grey[500], fontSize: 12),
                          maxLines: 1, overflow: TextOverflow.ellipsis)
                      : null,
                    onTap: () => _selectPlace(p),
                  );
                }),
        ),
      ]),
    );
  }
}
