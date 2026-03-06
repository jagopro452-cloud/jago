import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import '../../services/auth_service.dart';

class MonthlyPassScreen extends StatefulWidget {
  const MonthlyPassScreen({super.key});
  @override
  State<MonthlyPassScreen> createState() => _MonthlyPassScreenState();
}

class _MonthlyPassScreenState extends State<MonthlyPassScreen> {
  bool _loading = true;
  Map<String, dynamic>? _activePlan;
  List _plans = [];
  bool _buying = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final headers = await AuthService.getHeaders();
      final res = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/app/customer/monthly-pass'), headers: headers);
      if (res.statusCode == 200) {
        final d = jsonDecode(res.body);
        setState(() {
          _activePlan = d['activePlan'];
          _plans = d['availablePlans'] ?? [];
        });
      }
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _buy(String planName) async {
    setState(() => _buying = true);
    try {
      final headers = await AuthService.getHeaders();
      headers['Content-Type'] = 'application/json';
      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/app/customer/monthly-pass/buy'),
        headers: headers,
        body: jsonEncode({'planName': planName}),
      );
      final body = jsonDecode(res.body);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(body['message'] ?? 'Failed'),
        backgroundColor: res.statusCode == 200 ? Colors.green : Colors.red,
        duration: const Duration(seconds: 4),
      ));
      if (res.statusCode == 200) _load();
    } catch (_) {}
    setState(() => _buying = false);
  }

  @override
  Widget build(BuildContext context) {
    final planColors = [const Color(0xFF2563EB), const Color(0xFF7C3AED), const Color(0xFFDC2626)];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        title: const Text('Monthly Pass', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF2563EB)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Active plan
                  if (_activePlan != null) ...[
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF7C3AED)]),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            const Icon(Icons.verified, color: Colors.amber),
                            const SizedBox(width: 8),
                            Text(_activePlan!['planName'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                          ]),
                          const SizedBox(height: 12),
                          Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                            _statBox('Rides Used', '${_activePlan!['ridesUsed']}'),
                            _statBox('Remaining', '${(_activePlan!['ridesTotal'] ?? 0) - (_activePlan!['ridesUsed'] ?? 0)}'),
                            _statBox('Days Left', _daysLeft()),
                          ]),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: ((_activePlan!['ridesUsed'] ?? 0) / (_activePlan!['ridesTotal'] ?? 30)).clamp(0.0, 1.0),
                              backgroundColor: Colors.white.withOpacity(0.3),
                              valueColor: const AlwaysStoppedAnimation(Colors.amber),
                              minHeight: 8,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  // Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.amber.shade200)),
                    child: Row(children: [
                      const Icon(Icons.info_outline, color: Colors.amber),
                      const SizedBox(width: 8),
                      const Expanded(child: Text('Save up to 35% on rides with Monthly Pass!\nBonus JAGO Coins on every purchase.',
                          style: TextStyle(fontSize: 13))),
                    ]),
                  ),
                  const SizedBox(height: 16),
                  const Text('Choose Your Plan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  ..._plans.asMap().entries.map((e) {
                    final p = e.value;
                    final color = planColors[e.key % planColors.length];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: color.withOpacity(0.3)),
                        boxShadow: [BoxShadow(color: color.withOpacity(0.08), blurRadius: 12)],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(children: [
                          Expanded(child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                Icon(Icons.confirmation_number_outlined, color: color, size: 20),
                                const SizedBox(width: 6),
                                Text(p['name'], style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
                              ]),
                              const SizedBox(height: 4),
                              Text('${p['rides']} rides for 30 days', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(6)),
                                child: Text('Save ${p['discount']}', style: TextStyle(color: Colors.green.shade700, fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          )),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('₹${p['price']}', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
                              const SizedBox(height: 8),
                              ElevatedButton(
                                onPressed: _buying ? null : () => _buy(p['name']),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: color,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                ),
                                child: _buying ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Buy'),
                              ),
                            ],
                          ),
                        ]),
                      ),
                    );
                  }),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('Pass Terms', style: TextStyle(fontWeight: FontWeight.bold)),
                        SizedBox(height: 8),
                        Text('• Payment via JAGO Wallet balance\n• Pass valid for 30 days from purchase\n• Rides within city limits only\n• Non-refundable after first ride\n• Bonus JAGO Coins credited instantly', style: TextStyle(fontSize: 12, color: Colors.grey, height: 1.8)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _statBox(String label, String val) => Column(children: [
    Text(val, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
    Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
  ]);

  String _daysLeft() {
    if (_activePlan?['validUntil'] == null) return '0';
    try {
      final d = DateTime.parse(_activePlan!['validUntil']);
      final diff = d.difference(DateTime.now()).inDays;
      return '$diff';
    } catch (_) { return '?'; }
  }
}
