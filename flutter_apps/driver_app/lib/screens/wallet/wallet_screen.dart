import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import '../../services/auth_service.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});
  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  Map<String, dynamic>? _wallet;
  bool _loading = true;

  @override
  void initState() { super.initState(); _fetchWallet(); }

  Future<void> _fetchWallet() async {
    final token = await AuthService.getToken();
    try {
      final res = await http.get(Uri.parse(ApiConfig.driverWallet),
        headers: {'Authorization': 'Bearer $token'});
      if (res.statusCode == 200) setState(() { _wallet = jsonDecode(res.body); _loading = false; });
    } catch (_) { setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    final balance = _wallet?['balance'] ?? 0;
    final transactions = (_wallet?['transactions'] as List?) ?? [];
    return Scaffold(
      backgroundColor: const Color(0xFF060D1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF060D1E), elevation: 0,
        leading: IconButton(icon: Icon(Icons.arrow_back_ios, color: Colors.white.withOpacity(0.7)), onPressed: () => Navigator.pop(context)),
        title: const Text('Wallet', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: _loading ? const Center(child: CircularProgressIndicator(color: Color(0xFF2563EB)))
        : Column(children: [
          Container(
            width: double.infinity, color: const Color(0xFF0D1B4B),
            padding: const EdgeInsets.all(28),
            child: Column(children: [
              const Icon(Icons.savings_outlined, color: Color(0xFF2563EB), size: 40),
              const SizedBox(height: 12),
              Text('₹${balance.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white)),
              Text('Available Balance', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 14)),
            ]),
          ),
          const SizedBox(height: 2),
          Expanded(
            child: transactions.isEmpty
              ? Center(child: Text('No transactions yet', style: TextStyle(color: Colors.white.withOpacity(0.3))))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: transactions.length,
                  itemBuilder: (_, i) {
                    final t = transactions[i];
                    final isCredit = (t['type'] == 'credit');
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: const Color(0xFF0D1B4B), borderRadius: BorderRadius.circular(12)),
                      child: Row(children: [
                        Container(width: 40, height: 40,
                          decoration: BoxDecoration(
                            color: (isCredit ? Colors.green : Colors.red).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10)),
                          child: Icon(isCredit ? Icons.add : Icons.remove,
                            color: isCredit ? Colors.green : Colors.red)),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(t['description'] ?? 'Transaction',
                            style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.white)),
                          Text(t['date'] ?? '', style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 12)),
                        ])),
                        Text('${isCredit ? '+' : '-'}₹${t['amount']}',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15,
                            color: isCredit ? Colors.green : Colors.red)),
                      ]),
                    );
                  }),
          ),
        ]),
    );
  }
}
