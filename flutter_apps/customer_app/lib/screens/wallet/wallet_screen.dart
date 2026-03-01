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
      final res = await http.get(Uri.parse(ApiConfig.wallet),
        headers: {'Authorization': 'Bearer $token'});
      if (res.statusCode == 200) setState(() { _wallet = jsonDecode(res.body); _loading = false; });
    } catch (_) { setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    final balance = _wallet?['balance'] ?? 0;
    final transactions = (_wallet?['transactions'] as List?) ?? [];
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF1A1A2E)), onPressed: () => Navigator.pop(context)),
        title: const Text('Wallet', style: TextStyle(color: Color(0xFF1A1A2E), fontWeight: FontWeight.bold)),
      ),
      body: _loading ? const Center(child: CircularProgressIndicator(color: Color(0xFF1E6DE5)))
        : Column(children: [
          Container(
            width: double.infinity, color: Colors.white,
            padding: const EdgeInsets.all(28),
            child: Column(children: [
              const Icon(Icons.account_balance_wallet, color: Color(0xFF1E6DE5), size: 40),
              const SizedBox(height: 12),
              Text('₹${balance.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
              Text('Available Balance', style: TextStyle(color: Colors.grey[500], fontSize: 14)),
              const SizedBox(height: 20),
              SizedBox(width: double.infinity, height: 46,
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Money', style: TextStyle(fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E6DE5), foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
                )),
            ]),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: transactions.isEmpty
              ? Center(child: Text('No transactions yet', style: TextStyle(color: Colors.grey[400])))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: transactions.length,
                  itemBuilder: (_, i) {
                    final t = transactions[i];
                    final isCredit = (t['type'] == 'credit');
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                      child: Row(children: [
                        Container(width: 40, height: 40,
                          decoration: BoxDecoration(
                            color: (isCredit ? Colors.green : Colors.red).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10)),
                          child: Icon(isCredit ? Icons.add : Icons.remove,
                            color: isCredit ? Colors.green : Colors.red)),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(t['description'] ?? 'Transaction',
                            style: const TextStyle(fontWeight: FontWeight.w500, color: Color(0xFF1A1A2E))),
                          Text(t['date'] ?? '', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
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
