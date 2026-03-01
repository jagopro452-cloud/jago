import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import '../../services/auth_service.dart';

class CoinsScreen extends StatefulWidget {
  const CoinsScreen({super.key});
  @override
  State<CoinsScreen> createState() => _CoinsScreenState();
}

class _CoinsScreenState extends State<CoinsScreen> {
  bool _loading = true;
  Map<String, dynamic> _data = {};
  bool _redeeming = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final headers = await AuthService.getHeaders();
      final res = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/app/customer/coins'), headers: headers);
      if (res.statusCode == 200) setState(() => _data = jsonDecode(res.body));
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _redeem(int coins) async {
    setState(() => _redeeming = true);
    try {
      final headers = await AuthService.getHeaders();
      headers['Content-Type'] = 'application/json';
      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/app/customer/redeem-coins'),
        headers: headers,
        body: jsonEncode({'coins': coins}),
      );
      final body = jsonDecode(res.body);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(body['message'] ?? (res.statusCode == 200 ? 'Success!' : 'Failed')),
        backgroundColor: res.statusCode == 200 ? Colors.green : Colors.red,
      ));
      if (res.statusCode == 200) _load();
    } catch (_) {}
    setState(() => _redeeming = false);
  }

  @override
  Widget build(BuildContext context) {
    final balance = _data['balance'] ?? 0;
    final rupeeValue = _data['rupeeValue'] ?? 0;
    final history = (_data['history'] as List?) ?? [];
    final tips = (_data['howItWorks'] as List?) ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: const Color(0xFF2563EB).withOpacity(0.1), shape: BoxShape.circle),
            child: const Icon(Icons.monetization_on, color: Color(0xFF2563EB), size: 20),
          ),
          const SizedBox(width: 8),
          const Text('JAGO Coins', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ]),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF2563EB)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Balance card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.stars_rounded, color: Colors.amber, size: 48),
                        const SizedBox(height: 8),
                        Text('$balance', style: const TextStyle(color: Colors.white, fontSize: 52, fontWeight: FontWeight.bold)),
                        const Text('JAGO Coins', style: TextStyle(color: Colors.white70, fontSize: 16)),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                          child: Text('= ₹$rupeeValue cashback', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Redeem section
                  if (balance >= 100) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)]),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Redeem Coins', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          Row(
                            children: [100, 200, 500].where((v) => v <= balance).map((v) => Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: ElevatedButton(
                                  onPressed: _redeeming ? null : () => _redeem(v),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF2563EB),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                  child: Column(
                                    children: [
                                      Text('$v coins', style: const TextStyle(fontSize: 12)),
                                      Text('= ₹${v ~/ 10}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                              ),
                            )).toList(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  // How it works
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('How JAGO Coins work', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        ...tips.map((t) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(children: [
                            const Icon(Icons.check_circle, color: Color(0xFF2563EB), size: 18),
                            const SizedBox(width: 8),
                            Expanded(child: Text(t.toString(), style: const TextStyle(fontSize: 13))),
                          ]),
                        )),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // History
                  if (history.isNotEmpty) ...[
                    const Text('Transaction History', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ...history.take(20).map((h) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                      child: Row(children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: (h['amount'] > 0 ? Colors.green : Colors.red).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(h['amount'] > 0 ? Icons.add : Icons.remove,
                              color: h['amount'] > 0 ? Colors.green : Colors.red, size: 16),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(h['description'] ?? h['type'] ?? '', style: const TextStyle(fontSize: 13)),
                            Text(h['createdAt']?.toString().substring(0, 10) ?? '',
                                style: const TextStyle(fontSize: 11, color: Colors.grey)),
                          ],
                        )),
                        Text(
                          '${h['amount'] > 0 ? '+' : ''}${h['amount']} coins',
                          style: TextStyle(
                            color: h['amount'] > 0 ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ]),
                    )),
                  ],
                ],
              ),
            ),
    );
  }
}
