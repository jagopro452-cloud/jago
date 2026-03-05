import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import '../../services/auth_service.dart';

class LostFoundScreen extends StatefulWidget {
  const LostFoundScreen({super.key});
  @override
  State<LostFoundScreen> createState() => _LostFoundScreenState();
}

class _LostFoundScreenState extends State<LostFoundScreen> {
  bool _loading = true;
  bool _submitting = false;
  List _reports = [];
  final _formKey = GlobalKey<FormState>();
  final _descCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  String? _selectedTripId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final headers = await AuthService.getHeaders();
      final res = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/app/customer/lost-found'), headers: headers);
      if (res.statusCode == 200) setState(() => _reports = jsonDecode(res.body));
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      final headers = await AuthService.getHeaders();
      headers['Content-Type'] = 'application/json';
      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/app/lost-found'),
        headers: headers,
        body: jsonEncode({
          'tripId': _selectedTripId,
          'description': _descCtrl.text.trim(),
          'contactPhone': _phoneCtrl.text.trim(),
        }),
      );
      if (!mounted) return;
      final body = jsonDecode(res.body);
      if (res.statusCode == 200) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(body['message'] ?? 'Report submitted!'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 5),
        ));
        _load();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(body['message'] ?? 'Failed'), backgroundColor: Colors.red));
      }
    } catch (_) {}
    setState(() => _submitting = false);
  }

  void _showReportSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Text('Report Lost Item', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ]),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(10)),
                  child: const Row(children: [
                    Icon(Icons.info_outline, color: Colors.orange, size: 18),
                    SizedBox(width: 8),
                    Expanded(child: Text('We will contact the driver and get back to you within 2 hours.', style: TextStyle(fontSize: 12, color: Colors.orange))),
                  ]),
                ),
                const SizedBox(height: 16),
                const Text('What did you lose?', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'e.g., Black leather wallet, iPhone 14 Pro, Laptop bag...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF2563EB))),
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Please describe the item' : null,
                ),
                const SizedBox(height: 12),
                const Text('Contact Phone', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    hintText: '9876543210',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF2563EB))),
                    prefixIcon: const Icon(Icons.phone),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: _submitting
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Submit Report', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        title: const Text('Lost & Found', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showReportSheet,
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Report Lost Item'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF2563EB)))
          : _reports.isEmpty
              ? _emptyState()
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    const Text('Your Reports', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    ..._reports.map((r) => _reportCard(r)),
                  ],
                ),
    );
  }

  Widget _emptyState() => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: const Color(0xFF2563EB).withOpacity(0.1), shape: BoxShape.circle),
        child: const Icon(Icons.search, size: 64, color: Color(0xFF2563EB)),
      ),
      const SizedBox(height: 16),
      const Text('Lost something?', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      const Text('Report lost items from your recent\nrides and we\'ll help you find them.',
          textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
      const SizedBox(height: 80),
    ]),
  );

  Widget _reportCard(Map<String, dynamic> r) {
    final status = r['status'] ?? 'open';
    final statusColor = status == 'resolved' ? Colors.green : status == 'in_progress' ? Colors.blue : Colors.orange;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.inventory_2_outlined, color: Color(0xFF2563EB), size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(r['description'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
              child: Text(status.toUpperCase(), style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          ]),
          if (r['pickupAddress'] != null) ...[
            const SizedBox(height: 8),
            Text('Trip: ${r['pickupAddress']} → ${r['destinationAddress'] ?? '...'}',
                style: const TextStyle(fontSize: 12, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
          if (r['driverName'] != null) ...[
            const SizedBox(height: 4),
            Text('Driver: ${r['driverName']} • ${r['driverPhone'] ?? ''}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
          const SizedBox(height: 4),
          Text(r['createdAt']?.toString().substring(0, 10) ?? '', style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }
}
