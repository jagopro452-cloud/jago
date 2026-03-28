import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import '../../services/auth_service.dart';

class TipDriverScreen extends StatefulWidget {
  final String tripId;
  final String driverName;
  const TipDriverScreen({super.key, required this.tripId, required this.driverName});
  @override
  State<TipDriverScreen> createState() => _TipDriverScreenState();
}

class _TipDriverScreenState extends State<TipDriverScreen> {
  int? _selectedTip;
  bool _sending = false;
  bool _done = false;
  String _doneMsg = '';

  final _tips = [10, 20, 30, 50];

  Future<void> _sendTip(int amount) async {
    setState(() => _sending = true);
    try {
      final headers = await AuthService.getHeaders();
      headers['Content-Type'] = 'application/json';
      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/app/tip-driver'),
        headers: headers,
        body: jsonEncode({'tripId': widget.tripId, 'amount': amount}),
      );
      if (!mounted) return;
      final body = jsonDecode(res.body);
      if (res.statusCode == 200) {
        setState(() { _done = true; _doneMsg = body['message'] ?? 'Tip sent!'; });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(body['message'] ?? 'Failed'), backgroundColor: Colors.red));
      }
    } catch (_) {}
    if (mounted) setState(() => _sending = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        title: const Text('Tip Your Driver', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
      ),
      body: _done ? _doneScreen() : _tipScreen(),
    );
  }

  Widget _tipScreen() => Padding(
    padding: const EdgeInsets.all(24),
    child: Column(
      children: [
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 20)]),
          child: const Icon(Icons.person, size: 60, color: Color(0xFF2563EB)),
        ),
        const SizedBox(height: 16),
        Text(widget.driverName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        const Text('Great service? Show your appreciation!', style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 32),
        const Text('Select tip amount', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        const SizedBox(height: 16),
        Row(
          children: _tips.map((t) => Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTip = t),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: _selectedTip == t ? const Color(0xFF2563EB) : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _selectedTip == t ? const Color(0xFF2563EB) : Colors.grey.shade200),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
                ),
                child: Column(
                  children: [
                    Text('₹$t', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500,
                        color: _selectedTip == t ? Colors.white : Colors.black)),
                  ],
                ),
              ),
            ),
          )).toList(),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.amber.shade200)),
          child: const Row(children: [
            Icon(Icons.stars, color: Colors.amber, size: 18),
            SizedBox(width: 8),
            Expanded(child: Text('You earn 10x JAGO Pro Coins for every rupee tipped!', style: TextStyle(fontSize: 12, color: Colors.amber))),
          ]),
        ),
        const Spacer(),
        if (_selectedTip != null)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _sending ? null : () => _sendTip(_selectedTip!),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _sending
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text('Send ₹$_selectedTip Tip', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            ),
          ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Skip', style: TextStyle(color: Colors.grey)),
        ),
      ],
    ),
  );

  Widget _doneScreen() => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.green.shade50, shape: BoxShape.circle),
            child: const Icon(Icons.favorite, color: Colors.green, size: 64),
          ),
          const SizedBox(height: 24),
          const Text('Tip Sent!', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w500, color: Colors.green)),
          const SizedBox(height: 12),
          Text(_doneMsg, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, fontSize: 15, height: 1.5)),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
            ),
            child: const Text('Done', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    ),
  );
}
