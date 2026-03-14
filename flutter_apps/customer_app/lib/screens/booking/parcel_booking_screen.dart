import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
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

  static const _cargoTypes = [
    'General Goods', 'Electronics', 'Furniture', 'Fragile Items',
    'Bulk Materials', 'Perishable Goods', 'Construction Material', 'Other',
  ];

  // Static category chips shown when API returns none
  static const _staticCategories = [
    {'name': 'Household', 'icon': '🏠'},
    {'name': 'Electronics', 'icon': '📱'},
    {'name': 'Documents', 'icon': '📄'},
    {'name': 'Clothes', 'icon': '👕'},
    {'name': 'Food', 'icon': '🍱'},
    {'name': 'Other', 'icon': '📦'},
  ];

  String _destAddress = '';
  double _destLat = 0, _destLng = 0;

  // Per-vehicle fare estimates: vehicleId (or name) -> fare string
  final Map<String, String> _vehicleFares = {};
  final Map<String, bool> _vehicleEstimating = {};

  bool _loading = true;
  bool _bookingLoading = false;

  static const Color _blue = Color(0xFF2F80ED);
  static const Color _dark = Color(0xFF1A1A1A);
  static const Color _lightBg = Color(0xFFF7F8FA);
  static const Color _border = Color(0xFFE5E7EB);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _receiverNameCtrl.dispose();
    _receiverPhoneCtrl.dispose();
    _instructionsCtrl.dispose();
    super.dispose();
  }

  // ── Data Loading ─────────────────────────────────────────────────────────────

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
        final raw2 = jsonDecode(results[2].body);
        final all = raw2 is List ? raw2 : (raw2['data'] ?? []);
        _allVehicles = _buildParcelVehicleList(List<dynamic>.from(all));
      }
      if (_allVehicles.isEmpty) _allVehicles = _defaultVehicles();
    } catch (_) {
      _allVehicles = _defaultVehicles();
    }
    if (mounted) setState(() => _loading = false);
    // Auto-estimate fares if destination already set
    if (_destLat != 0 && _destLng != 0) _estimateAllFares();
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

  // ── Fare Estimation ───────────────────────────────────────────────────────────

  Future<void> _estimateAllFares() async {
    for (final v in _allVehicles) {
      _estimateFareForVehicle(v);
    }
  }

  Future<void> _estimateFareForVehicle(Map<String, dynamic> vehicle) async {
    if (_destLat == 0 && _destLng == 0) return;
    final key = vehicle['id']?.toString() ?? vehicle['name']?.toString() ?? '';
    if (key.isEmpty) return;
    setState(() => _vehicleEstimating[key] = true);
    try {
      final headers = await AuthService.getHeaders();
      headers['Content-Type'] = 'application/json';
      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/app/customer/estimate-fare'),
        headers: headers,
        body: jsonEncode({
          'pickupLat': widget.pickupLat,
          'pickupLng': widget.pickupLng,
          'destLat': _destLat,
          'destLng': _destLng,
          'vehicleCategoryId': vehicle['id'],
        }),
      );
      if (res.statusCode == 200 && mounted) {
        final data = jsonDecode(res.body);
        final fare = data['estimatedFare'] ?? data['fare'] ?? data['fares']?[0]?['estimatedFare'] ?? '';
        setState(() => _vehicleFares[key] = '₹${fare.toString()}');
      }
    } catch (_) {}
    if (mounted) setState(() => _vehicleEstimating[key] = false);
  }

  String _fareKeyFor(Map<String, dynamic> v) =>
      v['id']?.toString() ?? v['name']?.toString() ?? '';

  // ── Booking ───────────────────────────────────────────────────────────────────

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
    if (_destAddress.isEmpty) {
      _showSnack('Please select a delivery location');
      return;
    }
    if (_selectedVehicle == null) {
      _showSnack('Please select a delivery vehicle');
      return;
    }
    setState(() => _bookingLoading = true);
    try {
      final headers = await AuthService.getHeaders();
      headers['Content-Type'] = 'application/json';
      final isCargoVeh = _isCargoVehicle;
      final cargoDetails = isCargoVeh && _cargoType != null
          ? ' | Cargo Type: $_cargoType | Helper: ${_needsHelper ? 'Yes' : 'No'}'
          : '';
      final notes = '${isCargoVeh ? '🚛 Cargo' : '📦 Parcel'}'
          ' | Vehicle: ${_selectedVehicle?['name'] ?? ''}$cargoDetails'
          ' | Category: ${_selectedCategoryIcon ?? ''}${_selectedCategoryName ?? 'Other'}'
          ' | Weight: ${_selectedWeightLabel ?? 'Light'}'
          ' | Receiver: ${_receiverNameCtrl.text.trim()} (+91 ${_receiverPhoneCtrl.text})'
          '${_instructionsCtrl.text.isNotEmpty ? ' | Note: ${_instructionsCtrl.text}' : ''}';
      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/app/customer/book-ride'),
        headers: headers,
        body: jsonEncode({
          'pickupAddress': widget.pickupAddress,
          'destinationAddress': _destAddress,
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
      content: Text(msg,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.white)),
      backgroundColor: Colors.red[600],
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  void _openDestinationSearch() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _DestSearchSheet(
        pickupLat: widget.pickupLat,
        pickupLng: widget.pickupLng,
        onSelected: (name, lat, lng) {
          setState(() {
            _destAddress = name;
            _destLat = lat;
            _destLng = lng;
          });
          _estimateAllFares();
        },
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────────

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
    if (n.contains('bike parcel') || (n.contains('bike') && type == 'parcel')) {
      return 'Small parcels • Fastest delivery';
    }
    if (n.contains('bike')) return 'Small parcels • Envelopes • Quick';
    if (n.contains('temo')) return 'Medium parcels • Good capacity';
    if (n.contains('mini auto')) return 'Medium parcels • Boxes & bags';
    if (n.contains('tata ace')) return 'Large cargo • Furniture • Bulk';
    if (n.contains('cargo truck')) return 'Heavy cargo • Commercial use';
    if (n.contains('mini cargo') || n.contains('cargo van')) return 'Medium cargo • Shop deliveries';
    return 'Parcel delivery';
  }

  String _capacityFor(String name) {
    final n = name.toLowerCase();
    if (n.contains('bike')) return 'Up to 5 kg';
    if (n.contains('temo') || n.contains('auto')) return 'Up to 50 kg';
    if (n.contains('tata ace')) return 'Up to 750 kg';
    if (n.contains('cargo truck')) return 'Up to 2,000 kg';
    if (n.contains('mini cargo') || n.contains('cargo van')) return 'Up to 200 kg';
    return 'Varies';
  }

  // ── BUILD ─────────────────────────────────────────────────────────────────────

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
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Book Parcel',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: _dark,
          ),
        ),
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _border),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _blue))
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPickupCard(),
                  const SizedBox(height: 12),
                  _buildDestinationCard(),
                  const SizedBox(height: 20),
                  _buildReceiverCard(),
                  const SizedBox(height: 20),
                  _buildItemSection(),
                  const SizedBox(height: 20),
                  _buildVehicleSection(),
                  if (_isCargoVehicle) ...[
                    const SizedBox(height: 20),
                    _buildCargoSection(),
                  ],
                  const SizedBox(height: 20),
                  _buildInstructionsSection(),
                ],
              ),
            ),
      bottomNavigationBar: _buildBookButton(),
    );
  }

  // ── Pickup Card ───────────────────────────────────────────────────────────────

  Widget _buildPickupCard() {
    return _sectionCard(
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.radio_button_checked_rounded, color: _blue, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Pickup',
                  style: GoogleFonts.poppins(
                      fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF9CA3AF))),
              const SizedBox(height: 2),
              Text(
                widget.pickupAddress,
                style: GoogleFonts.poppins(
                    fontSize: 13, fontWeight: FontWeight.w600, color: _dark),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ]),
          ),
        ],
      ),
    );
  }

  // ── Destination Card ──────────────────────────────────────────────────────────

  Widget _buildDestinationCard() {
    return GestureDetector(
      onTap: _openDestinationSearch,
      child: _sectionCard(
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _destAddress.isNotEmpty
                    ? Colors.green.withValues(alpha: 0.1)
                    : const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.location_on_rounded,
                color: _destAddress.isNotEmpty ? Colors.green[600] : Colors.red[400],
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Destination',
                    style: GoogleFonts.poppins(
                        fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF9CA3AF))),
                const SizedBox(height: 2),
                Text(
                  _destAddress.isNotEmpty ? _destAddress : 'Search delivery location...',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: _destAddress.isNotEmpty ? FontWeight.w600 : FontWeight.w400,
                    color: _destAddress.isNotEmpty ? _dark : const Color(0xFF9CA3AF),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ]),
            ),
            Icon(Icons.search_rounded, color: Colors.grey[400], size: 20),
          ],
        ),
      ),
    );
  }

  // ── Receiver Card ─────────────────────────────────────────────────────────────

  Widget _buildReceiverCard() {
    return _sectionCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              color: _blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.person_outline_rounded, color: _blue, size: 16),
          ),
          const SizedBox(width: 10),
          Text('Receiver Details',
              style: GoogleFonts.poppins(
                  fontSize: 14, fontWeight: FontWeight.w700, color: _dark)),
        ]),
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
          label: 'Phone Number',
          icon: Icons.phone_outlined,
          keyboard: TextInputType.phone,
          prefix: '+91 ',
          maxLength: 10,
          digitsOnly: true,
        ),
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
      style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: _dark),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF9CA3AF)),
        prefixText: prefix,
        prefixStyle: GoogleFonts.poppins(fontSize: 14, color: _dark, fontWeight: FontWeight.w500),
        prefixIcon: Icon(icon, color: const Color(0xFF9CA3AF), size: 18),
        filled: true,
        fillColor: _lightBg,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _border, width: 1)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _blue, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      onChanged: (_) => setState(() {}),
    );
  }

  // ── Item / Category Section ───────────────────────────────────────────────────

  Widget _buildItemSection() {
    final categories = _parcelCategories.isNotEmpty
        ? _parcelCategories
        : _staticCategories;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _sectionHeader('What are you sending?', Icons.inventory_2_outlined),
      const SizedBox(height: 12),
      GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.1,
        ),
        itemCount: categories.length,
        itemBuilder: (_, i) {
          final cat = categories[i];
          final id = cat['id']?.toString() ?? cat['name']?.toString() ?? i.toString();
          final isSelected = _selectedCategoryId == id;
          return GestureDetector(
            onTap: () => setState(() {
              _selectedCategoryId = id;
              _selectedCategoryName = cat['name']?.toString();
              _selectedCategoryIcon = cat['icon']?.toString();
            }),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              decoration: BoxDecoration(
                color: isSelected ? _blue : _lightBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected ? _blue : _border,
                  width: isSelected ? 1.5 : 1,
                ),
                boxShadow: isSelected
                    ? [BoxShadow(color: _blue.withValues(alpha: 0.2), blurRadius: 12, offset: const Offset(0, 4))]
                    : [],
              ),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(cat['icon']?.toString() ?? '📦',
                    style: const TextStyle(fontSize: 26)),
                const SizedBox(height: 6),
                Text(
                  cat['name']?.toString() ?? '',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : _dark,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ]),
            ),
          );
        },
      ),
      // Weight chips from API if available
      if (_weights.isNotEmpty) ...[
        const SizedBox(height: 16),
        Text('Parcel Weight',
            style: GoogleFonts.poppins(
                fontSize: 13, fontWeight: FontWeight.w600, color: _dark)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _weights.map((w) {
            final wid = w['id']?.toString() ?? w['label']?.toString() ?? '';
            final isSelected = _selectedWeightId == wid;
            return GestureDetector(
              onTap: () => setState(() {
                _selectedWeightId = wid;
                _selectedWeightLabel = w['label']?.toString();
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? _blue : _lightBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isSelected ? _blue : _border),
                ),
                child: Text(
                  w['label']?.toString() ?? '',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : _dark,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    ]);
  }

  // ── Vehicle Section ───────────────────────────────────────────────────────────

  Widget _buildVehicleSection() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _sectionHeader('Choose Vehicle', Icons.local_shipping_outlined),
      const SizedBox(height: 2),
      Text('Select based on parcel size',
          style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF9CA3AF))),
      const SizedBox(height: 14),
      SizedBox(
        height: 148,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _allVehicles.length,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (_, i) {
            final v = _allVehicles[i];
            final name = v['name']?.toString() ?? '';
            final type = v['type']?.toString() ?? 'parcel';
            final isSelected = _selectedVehicle?['id'] == v['id'] &&
                _selectedVehicle?['name'] == name;
            final fareKey = _fareKeyFor(v);
            final fareStr = _vehicleFares[fareKey] ?? '';
            final isEstimating = _vehicleEstimating[fareKey] == true;
            final minFare =
                v['minimumFare']?.toString() ?? v['base_fare']?.toString() ?? '25';

            return GestureDetector(
              onTap: () => setState(() => _selectedVehicle = v),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 140,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isSelected ? _blue : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? _blue : _border,
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: isSelected
                      ? [BoxShadow(
                          color: _blue.withValues(alpha: 0.25),
                          blurRadius: 16,
                          offset: const Offset(0, 6))]
                      : [BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Emoji icon
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white.withValues(alpha: 0.18)
                            : _lightBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(_emojiFor(name),
                            style: const TextStyle(fontSize: 22)),
                      ),
                    ),
                    // Name
                    Text(name,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? Colors.white : _dark,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    // Capacity
                    Text(_capacityFor(name),
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: isSelected
                              ? Colors.white.withValues(alpha: 0.7)
                              : const Color(0xFF9CA3AF),
                        )),
                    // Fare
                    isEstimating
                        ? SizedBox(
                            width: 16, height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              color: isSelected ? Colors.white : _blue,
                            ))
                        : Text(
                            fareStr.isNotEmpty ? fareStr : '₹$minFare+',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: isSelected ? Colors.white : _blue,
                            ),
                          ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    ]);
  }

  // ── Cargo Section (only for cargo vehicles) ───────────────────────────────────

  Widget _buildCargoSection() {
    return _sectionCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              color: _blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.inventory_2_outlined, color: _blue, size: 16),
          ),
          const SizedBox(width: 10),
          Text('Cargo Details',
              style: GoogleFonts.poppins(
                  fontSize: 14, fontWeight: FontWeight.w700, color: _dark)),
        ]),
        const SizedBox(height: 14),
        Text('Cargo Type',
            style: GoogleFonts.poppins(
                fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF6B7280))),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _cargoTypes.map((t) {
            final isSelected = _cargoType == t;
            return GestureDetector(
              onTap: () => setState(() => _cargoType = t),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? _blue : _lightBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isSelected ? _blue : _border),
                ),
                child: Text(t,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : _dark,
                    )),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: _lightBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _border),
          ),
          child: Row(children: [
            const Icon(Icons.person_outline_rounded, size: 20, color: Color(0xFF6B7280)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Loading Helper',
                  style: GoogleFonts.poppins(
                      fontSize: 13, fontWeight: FontWeight.w700, color: _dark)),
              Text('Add helper for loading/unloading heavy goods',
                  style: GoogleFonts.poppins(
                      fontSize: 11, color: const Color(0xFF9CA3AF))),
            ])),
            Switch(
              value: _needsHelper,
              onChanged: (v) => setState(() => _needsHelper = v),
              activeColor: _blue,
            ),
          ]),
        ),
      ]),
    );
  }

  // ── Instructions Section ──────────────────────────────────────────────────────

  Widget _buildInstructionsSection() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _sectionHeader('Special Instructions', Icons.edit_note_rounded),
      const SizedBox(height: 4),
      Text('Optional', style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF9CA3AF))),
      const SizedBox(height: 10),
      TextField(
        controller: _instructionsCtrl,
        maxLines: 3,
        style: GoogleFonts.poppins(fontSize: 13, color: _dark),
        decoration: InputDecoration(
          hintText: 'e.g., Handle with care, Fragile, Do not bend...',
          hintStyle: GoogleFonts.poppins(color: const Color(0xFF9CA3AF), fontSize: 13),
          filled: true,
          fillColor: _lightBg,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _border, width: 1)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _blue, width: 1.5)),
          contentPadding: const EdgeInsets.all(14),
        ),
      ),
    ]);
  }

  // ── Shared UI Helpers ─────────────────────────────────────────────────────────

  Widget _sectionCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _sectionHeader(String title, IconData icon) {
    return Row(children: [
      Icon(icon, size: 18, color: _blue),
      const SizedBox(width: 8),
      Text(title,
          style: GoogleFonts.poppins(
              fontSize: 15, fontWeight: FontWeight.w700, color: _dark)),
    ]);
  }

  // ── Book Button ───────────────────────────────────────────────────────────────

  Widget _buildBookButton() {
    final canBook = _destAddress.isNotEmpty &&
        _receiverNameCtrl.text.trim().isNotEmpty &&
        _receiverPhoneCtrl.text.length == 10 &&
        _selectedVehicle != null &&
        !_bookingLoading;

    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _border, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            gradient: canBook
                ? const LinearGradient(
                    colors: [Color(0xFF5BA8FF), Color(0xFF2F80ED)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: canBook ? null : const Color(0xFFE5E7EB),
            borderRadius: BorderRadius.circular(14),
            boxShadow: canBook
                ? [BoxShadow(
                    color: _blue.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6))]
                : [],
          ),
          child: TextButton(
            onPressed: canBook ? _bookParcel : null,
            style: TextButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: _bookingLoading
                ? const SizedBox(
                    width: 22, height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.local_shipping_rounded,
                          color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Book Parcel',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: canBook ? Colors.white : const Color(0xFF9CA3AF),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

// ── Destination Search Sheet ──────────────────────────────────────────────────

class _DestSearchSheet extends StatefulWidget {
  final double pickupLat, pickupLng;
  final Function(String name, double lat, double lng) onSelected;
  const _DestSearchSheet({
    required this.pickupLat,
    required this.pickupLng,
    required this.onSelected,
  });
  @override
  State<_DestSearchSheet> createState() => _DestSearchSheetState();
}

class _DestSearchSheetState extends State<_DestSearchSheet> {
  final _ctrl = TextEditingController();
  List<Map<String, dynamic>> _predictions = [];
  bool _searching = false;
  Timer? _debounce;

  static const Color _blue = Color(0xFF2F80ED);
  static const Color _dark = Color(0xFF1A1A1A);
  static const Color _lightBg = Color(0xFFF7F8FA);
  static const Color _border = Color(0xFFE5E7EB);

  @override
  void dispose() {
    _ctrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String q) {
    _debounce?.cancel();
    if (q.length < 2) {
      setState(() => _predictions = []);
      return;
    }
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
      if (res.statusCode == 200 && mounted) {
        final data = jsonDecode(res.body);
        setState(() {
          _predictions = ((data['predictions'] as List<dynamic>?) ?? [])
              .map((p) => {
                    'placeId': p['place_id'],
                    'description': p['description'],
                    'mainText': p['structured_formatting']?['main_text'] ??
                        p['description'],
                    'secondaryText':
                        p['structured_formatting']?['secondary_text'] ?? '',
                  })
              .toList()
              .cast<Map<String, dynamic>>();
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _searching = false);
  }

  Future<void> _selectPlace(Map<String, dynamic> place) async {
    try {
      final url =
          'https://maps.googleapis.com/maps/api/geocode/json?place_id=${place['placeId']}&key=${ApiConfig.googleMapsApiKey}';
      final res = await http.get(Uri.parse(url));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final results = data['results'] as List?;
        if (results != null && results.isNotEmpty) {
          final loc = results[0]['geometry']['location'];
          if (mounted) Navigator.pop(context);
          widget.onSelected(
            place['description'],
            (loc['lat'] as num?)?.toDouble() ?? 0.0,
            (loc['lng'] as num?)?.toDouble() ?? 0.0,
          );
          return;
        }
      }
    } catch (_) {}
    if (mounted) {
      Navigator.pop(context);
      widget.onSelected(place['description'], 0, 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40, height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
                color: const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Delivery Location',
                  style: GoogleFonts.poppins(
                      fontSize: 18, fontWeight: FontWeight.w700, color: _dark)),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: _lightBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _border),
                ),
                child: TextField(
                  controller: _ctrl,
                  autofocus: true,
                  onChanged: _onChanged,
                  style: GoogleFonts.poppins(
                      fontSize: 14, fontWeight: FontWeight.w500, color: _dark),
                  decoration: InputDecoration(
                    hintText: 'Search delivery address...',
                    hintStyle: GoogleFonts.poppins(
                        color: const Color(0xFF9CA3AF), fontWeight: FontWeight.w400),
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF6B7280), size: 22),
                    suffixIcon: _searching
                        ? const Padding(
                            padding: EdgeInsets.all(14),
                            child: SizedBox(
                                width: 16, height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: _blue)))
                        : null,
                    border: InputBorder.none,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),
            ]),
          ),
          ConstrainedBox(
            constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.5),
            child: _predictions.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(children: [
                      Icon(Icons.location_on_outlined,
                          size: 48, color: Colors.grey[300]),
                      const SizedBox(height: 12),
                      Text('Type to search delivery location',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                              color: Colors.grey[400], fontSize: 14)),
                    ]))
                : ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    itemCount: _predictions.length,
                    separatorBuilder: (_, __) =>
                        Divider(height: 1, color: Colors.grey[100]),
                    itemBuilder: (_, i) {
                      final p = _predictions[i];
                      return ListTile(
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                        leading: Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                              color: _lightBg,
                              borderRadius: BorderRadius.circular(10)),
                          child: const Icon(Icons.location_on_rounded,
                              color: Color(0xFF6B7280), size: 18)),
                        title: Text(p['mainText'] ?? '',
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: _dark)),
                        subtitle: (p['secondaryText'] ?? '').isNotEmpty
                            ? Text(p['secondaryText'],
                                style: GoogleFonts.poppins(
                                    color: Colors.grey[500], fontSize: 12),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis)
                            : null,
                        onTap: () => _selectPlace(p),
                      );
                    }),
          ),
        ],
      ),
    );
  }
}
