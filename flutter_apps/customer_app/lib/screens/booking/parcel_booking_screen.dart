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

  List<dynamic> _categories = [];
  List<dynamic> _weights = [];
  List<dynamic> _vehicleCategories = [];

  String? _selectedCategoryId;
  String? _selectedCategoryName;
  String? _selectedCategoryIcon;
  String? _selectedWeightId;
  String? _selectedWeightLabel;
  String? _selectedVehicleId;
  String? _selectedVehicleName;

  double _destLat = 0, _destLng = 0;
  String _estimatedFare = '';
  bool _loading = false;
  bool _bookingLoading = false;
  int _step = 0;

  static const Color _blue = Color(0xFF1E6DE5);
  static const Color _bg = Color(0xFFF8FAFC);
  static const Color _dark = Color(0xFF0F172A);

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
      if (results[0].statusCode == 200) _categories = jsonDecode(results[0].body);
      if (results[1].statusCode == 200) _weights = jsonDecode(results[1].body);
      if (results[2].statusCode == 200) {
        final all = jsonDecode(results[2].body) as List;
        _vehicleCategories = all.where((v) => v['type'] == 'parcel' || v['type'] == 'cargo').toList();
        if (_vehicleCategories.isEmpty) _vehicleCategories = all.where((v) => v['name']?.toString().toLowerCase().contains('bike') == true).toList();
      }
      if (_vehicleCategories.isNotEmpty) {
        _selectedVehicleId = _vehicleCategories[0]['id'];
        _selectedVehicleName = _vehicleCategories[0]['name'];
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _estimateFare() async {
    if (_destLat == 0 && _destCtrl.text.isEmpty) return;
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
          'vehicleCategoryId': _selectedVehicleId,
        }),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final fare = data['estimatedFare'] ?? data['fare'] ?? '';
        if (mounted) setState(() => _estimatedFare = '₹$fare');
      }
    } catch (_) {}
  }

  Future<void> _bookParcel() async {
    if (_receiverNameCtrl.text.isEmpty || _receiverPhoneCtrl.text.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Receiver name & 10-digit phone number అవసరం'), backgroundColor: Color(0xFFEF4444)));
      return;
    }
    if (_destCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Delivery address enter cheyyandi'), backgroundColor: Color(0xFFEF4444)));
      return;
    }
    setState(() => _bookingLoading = true);
    try {
      final headers = await AuthService.getHeaders();
      headers['Content-Type'] = 'application/json';
      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/app/customer/book-ride'),
        headers: headers,
        body: jsonEncode({
          'pickupAddress': widget.pickupAddress,
          'destinationAddress': _destCtrl.text,
          'pickupLat': widget.pickupLat,
          'pickupLng': widget.pickupLng,
          'destinationLat': _destLat != 0 ? _destLat : 17.4,
          'destinationLng': _destLng != 0 ? _destLng : 78.5,
          'vehicleCategoryId': _selectedVehicleId,
          'paymentMethod': 'cash',
          'notes': '📦 Parcel | Category: ${_selectedCategoryIcon ?? ''}${_selectedCategoryName ?? 'Other'} | Weight: ${_selectedWeightLabel ?? 'Light'} | Receiver: ${_receiverNameCtrl.text} (+91${_receiverPhoneCtrl.text}) | Instructions: ${_instructionsCtrl.text.isEmpty ? 'None' : _instructionsCtrl.text}',
        }),
      );
      if (res.statusCode == 200 || res.statusCode == 201) {
        final data = jsonDecode(res.body);
        final tripId = data['tripId']?.toString() ?? data['trip']?['id']?.toString() ?? '';
        if (tripId.isNotEmpty && mounted) {
          Navigator.pushReplacement(context, MaterialPageRoute(
            builder: (_) => TrackingScreen(tripId: tripId)));
        }
      } else {
        final err = jsonDecode(res.body);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(err['message'] ?? 'Booking failed'), backgroundColor: const Color(0xFFEF4444)));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: $e'), backgroundColor: const Color(0xFFEF4444)));
    }
    if (mounted) setState(() => _bookingLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0F172A), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Parcel Booking', style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF0F172A), fontSize: 18)),
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: (_step + 1) / 3,
            backgroundColor: const Color(0xFFE2E8F0),
            valueColor: const AlwaysStoppedAnimation(_blue),
            minHeight: 3,
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _blue))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _buildStepIndicator(),
                const SizedBox(height: 20),
                if (_step == 0) _buildStep1() else if (_step == 1) _buildStep2() else _buildStep3(),
              ]),
            ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildStepIndicator() {
    final steps = ['📍 Locations', '📦 Parcel Info', '✅ Confirm'];
    return Row(children: List.generate(steps.length, (i) {
      final isActive = i == _step;
      final isDone = i < _step;
      return Expanded(child: Row(children: [
        if (i > 0) Expanded(child: Container(height: 2, color: isDone ? _blue : const Color(0xFFE2E8F0))),
        Column(children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: isDone ? _blue : isActive ? _blue : const Color(0xFFE2E8F0),
              shape: BoxShape.circle,
            ),
            child: Center(child: isDone
                ? const Icon(Icons.check, color: Colors.white, size: 16)
                : Text('${i + 1}', style: TextStyle(color: isActive ? Colors.white : const Color(0xFF94A3B8), fontWeight: FontWeight.w800, fontSize: 13))),
          ),
          const SizedBox(height: 4),
          Text(steps[i].split(' ')[1], style: TextStyle(fontSize: 9, color: isActive ? _blue : const Color(0xFF94A3B8), fontWeight: FontWeight.w600)),
        ]),
        if (i < steps.length - 1) Expanded(child: Container(height: 2, color: isDone ? _blue : const Color(0xFFE2E8F0))),
      ]));
    }));
  }

  Widget _buildStep1() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Pickup & Delivery Locations', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF0F172A))),
      const SizedBox(height: 16),
      _infoCard(
        icon: Icons.radio_button_checked_rounded, iconColor: _blue,
        label: 'Pickup From', value: widget.pickupAddress,
      ),
      const SizedBox(height: 12),
      const Text('Delivery Address', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF374151))),
      const SizedBox(height: 6),
      TextField(
        controller: _destCtrl,
        onChanged: (v) { if (v.length > 5) { _destLat = 17.4; _destLng = 78.5; _estimateFare(); } },
        decoration: InputDecoration(
          hintText: 'Enter delivery address...',
          prefixIcon: const Icon(Icons.location_on_rounded, color: Color(0xFFEF4444)),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _blue, width: 1.5)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
          filled: true, fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        ),
      ),
      const SizedBox(height: 20),
      const Text('Receiver Details', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF0F172A))),
      const SizedBox(height: 12),
      TextField(
        controller: _receiverNameCtrl,
        textCapitalization: TextCapitalization.words,
        decoration: InputDecoration(
          labelText: 'Receiver Name',
          prefixIcon: const Icon(Icons.person_rounded, color: Color(0xFF64748B)),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _blue, width: 1.5)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
          filled: true, fillColor: Colors.white,
        ),
      ),
      const SizedBox(height: 10),
      TextField(
        controller: _receiverPhoneCtrl,
        keyboardType: TextInputType.phone,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
        decoration: InputDecoration(
          labelText: 'Receiver Phone',
          prefixText: '+91 ',
          prefixIcon: const Icon(Icons.phone_rounded, color: Color(0xFF64748B)),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _blue, width: 1.5)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
          filled: true, fillColor: Colors.white,
        ),
      ),
    ]);
  }

  Widget _buildStep2() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Parcel Details', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF0F172A))),
      const SizedBox(height: 16),
      const Text('What are you sending?', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF374151))),
      const SizedBox(height: 10),
      GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, crossAxisSpacing: 8, mainAxisSpacing: 8, childAspectRatio: 0.85),
        itemCount: _categories.length,
        itemBuilder: (_, i) {
          final cat = _categories[i];
          final isSelected = _selectedCategoryId == cat['id'];
          return GestureDetector(
            onTap: () => setState(() {
              _selectedCategoryId = cat['id'];
              _selectedCategoryName = cat['name'];
              _selectedCategoryIcon = cat['icon'];
            }),
            child: Container(
              decoration: BoxDecoration(
                color: isSelected ? _blue.withOpacity(0.1) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isSelected ? _blue : const Color(0xFFE2E8F0), width: isSelected ? 2 : 1),
              ),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(cat['icon'] ?? '📦', style: const TextStyle(fontSize: 24)),
                const SizedBox(height: 4),
                Text(cat['name'] ?? '', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: isSelected ? _blue : const Color(0xFF374151)), textAlign: TextAlign.center, maxLines: 2),
              ]),
            ),
          );
        },
      ),
      const SizedBox(height: 20),
      const Text('Parcel Weight', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF374151))),
      const SizedBox(height: 10),
      ..._weights.map((w) {
        final isSelected = _selectedWeightId == w['id'];
        return GestureDetector(
          onTap: () => setState(() { _selectedWeightId = w['id']; _selectedWeightLabel = w['label']; }),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? _blue.withOpacity(0.08) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isSelected ? _blue : const Color(0xFFE2E8F0), width: isSelected ? 2 : 1),
            ),
            child: Row(children: [
              Icon(Icons.scale_rounded, color: isSelected ? _blue : const Color(0xFF64748B), size: 20),
              const SizedBox(width: 12),
              Expanded(child: Text(w['label'] ?? '', style: TextStyle(fontWeight: FontWeight.w600, color: isSelected ? _blue : const Color(0xFF374151)))),
              if (isSelected) const Icon(Icons.check_circle_rounded, color: _blue, size: 20),
            ]),
          ),
        );
      }),
      const SizedBox(height: 16),
      const Text('Special Instructions', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF374151))),
      const SizedBox(height: 6),
      TextField(
        controller: _instructionsCtrl,
        maxLines: 2,
        decoration: InputDecoration(
          hintText: 'e.g., Handle with care, Do not bend...',
          prefixIcon: const Padding(padding: EdgeInsets.only(bottom: 20), child: Icon(Icons.info_outline_rounded, color: Color(0xFF64748B))),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _blue, width: 1.5)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
          filled: true, fillColor: Colors.white,
        ),
      ),
    ]);
  }

  Widget _buildStep3() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Booking Summary', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF0F172A))),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _summaryRow('📍 From', widget.pickupAddress),
          const Divider(height: 20, color: Color(0xFFF1F5F9)),
          _summaryRow('📌 To', _destCtrl.text.isEmpty ? 'Not entered' : _destCtrl.text),
          const Divider(height: 20, color: Color(0xFFF1F5F9)),
          _summaryRow('👤 Receiver', '${_receiverNameCtrl.text}\n+91 ${_receiverPhoneCtrl.text}'),
          const Divider(height: 20, color: Color(0xFFF1F5F9)),
          _summaryRow('📦 Parcel', '${_selectedCategoryIcon ?? '📦'} ${_selectedCategoryName ?? 'Not selected'}\n${_selectedWeightLabel ?? 'Weight not selected'}'),
          if (_vehicleCategories.isNotEmpty) ...[
            const Divider(height: 20, color: Color(0xFFF1F5F9)),
            const Text('Delivery Vehicle', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: _vehicleCategories.map((v) {
                final sel = _selectedVehicleId == v['id'];
                return GestureDetector(
                  onTap: () => setState(() { _selectedVehicleId = v['id']; _selectedVehicleName = v['name']; _estimateFare(); }),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: sel ? _blue.withOpacity(0.1) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: sel ? _blue : const Color(0xFFE2E8F0), width: sel ? 1.5 : 1),
                    ),
                    child: Row(children: [
                      Text(v['icon'] ?? '📦', style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 6),
                      Text(v['name'] ?? '', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: sel ? _blue : const Color(0xFF374151))),
                    ]),
                  ),
                );
              }).toList()),
            ),
          ],
          if (_estimatedFare.isNotEmpty) ...[
            const Divider(height: 20, color: Color(0xFFF1F5F9)),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Estimated Fare', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF374151))),
              Text(_estimatedFare, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: _blue)),
            ]),
          ],
          if (_instructionsCtrl.text.isNotEmpty) ...[
            const Divider(height: 20, color: Color(0xFFF1F5F9)),
            _summaryRow('📝 Instructions', _instructionsCtrl.text),
          ],
        ]),
      ),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF0FDF4),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFBBF7D0)),
        ),
        child: const Row(children: [
          Icon(Icons.security_rounded, color: Color(0xFF16A34A), size: 20),
          SizedBox(width: 10),
          Expanded(child: Text('Parcel will be handled with care. Driver will verify OTP at pickup.', style: TextStyle(color: Color(0xFF166534), fontSize: 12, fontWeight: FontWeight.w500))),
        ]),
      ),
    ]);
  }

  Widget _infoCard({required IconData icon, required Color iconColor, required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
        ])),
      ]),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600)),
      const SizedBox(height: 4),
      Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
    ]);
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(children: [
        if (_step > 0) ...[
          Expanded(
            flex: 1,
            child: OutlinedButton(
              onPressed: () => setState(() => _step--),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFE2E8F0)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Back', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(width: 10),
        ],
        Expanded(
          flex: 3,
          child: ElevatedButton(
            onPressed: _bookingLoading ? null : () {
              if (_step < 2) {
                if (_step == 0 && (_receiverNameCtrl.text.isEmpty || _receiverPhoneCtrl.text.length < 10 || _destCtrl.text.isEmpty)) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Delivery address, receiver name & phone fill cheyyandi'), backgroundColor: Color(0xFFEF4444)));
                  return;
                }
                setState(() { _step++; if (_step == 2) _estimateFare(); });
              } else {
                _bookParcel();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _blue, foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(vertical: 14), elevation: 0,
            ),
            child: _bookingLoading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text(_step == 2 ? '📦 Parcel Book Cheyyandi' : 'Next →', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
          ),
        ),
      ]),
    );
  }
}
