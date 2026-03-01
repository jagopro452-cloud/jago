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
      if (res.statusCode == 200) {
        setState(() { _wallet = jsonDecode(res.body); _loading = false; });
      } else { setState(() => _loading = false); }
    } catch (_) { setState(() => _loading = false); }
  }

  void _showAddMoneyDialog() {
    final amountController = TextEditingController();
    final utrController = TextEditingController();
    String selectedMethod = 'upi';
    double? selectedPreset;
    bool isLoading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Add Money to Wallet',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
            ]),
            const SizedBox(height: 16),
            const Text('Select Amount', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF6B7280))),
            const SizedBox(height: 10),
            Wrap(spacing: 10, runSpacing: 10, children: [100, 200, 500, 1000].map((amt) {
              final selected = selectedPreset == amt.toDouble();
              return GestureDetector(
                onTap: () => setModalState(() {
                  selectedPreset = amt.toDouble();
                  amountController.text = amt.toString();
                }),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: selected ? const Color(0xFF1E6DE5) : const Color(0xFFF5F7FA),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: selected ? const Color(0xFF1E6DE5) : const Color(0xFFE5E7EB)),
                  ),
                  child: Text('₹$amt',
                    style: TextStyle(fontWeight: FontWeight.w600,
                      color: selected ? Colors.white : const Color(0xFF1A1A2E))),
                ),
              );
            }).toList()),
            const SizedBox(height: 14),
            const Text('Or Enter Amount', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF6B7280))),
            const SizedBox(height: 8),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              onChanged: (_) => setModalState(() => selectedPreset = null),
              decoration: InputDecoration(
                hintText: '₹ Enter amount (min ₹10)',
                prefixText: '₹ ',
                filled: true, fillColor: const Color(0xFFF5F7FA),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 14),
            const Text('Payment Method', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF6B7280))),
            const SizedBox(height: 8),
            Row(children: [
              _MethodChip(label: 'UPI', icon: Icons.qr_code, value: 'upi', selected: selectedMethod == 'upi',
                onTap: () => setModalState(() => selectedMethod = 'upi')),
              const SizedBox(width: 10),
              _MethodChip(label: 'Card', icon: Icons.credit_card, value: 'card', selected: selectedMethod == 'card',
                onTap: () => setModalState(() => selectedMethod = 'card')),
              const SizedBox(width: 10),
              _MethodChip(label: 'NetBanking', icon: Icons.account_balance, value: 'netbanking', selected: selectedMethod == 'netbanking',
                onTap: () => setModalState(() => selectedMethod = 'netbanking')),
            ]),
            const SizedBox(height: 14),
            Text(
              selectedMethod == 'upi' ? 'UPI Transaction ID / UTR Number'
                : selectedMethod == 'card' ? 'Card Transaction Reference'
                : 'Bank Transaction Reference',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: utrController,
              decoration: InputDecoration(
                hintText: 'Enter transaction reference ID',
                filled: true, fillColor: const Color(0xFFF5F7FA),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(width: double.infinity, height: 50,
              child: ElevatedButton(
                onPressed: isLoading ? null : () async {
                  final rawAmt = amountController.text.trim();
                  final utr = utrController.text.trim();
                  if (rawAmt.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter an amount'), backgroundColor: Colors.red));
                    return;
                  }
                  if (utr.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter the transaction reference ID'), backgroundColor: Colors.red));
                    return;
                  }
                  setModalState(() => isLoading = true);
                  try {
                    final token = await AuthService.getToken();
                    final res = await http.post(
                      Uri.parse(ApiConfig.walletRecharge),
                      headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
                      body: jsonEncode({'amount': double.tryParse(rawAmt) ?? 0, 'paymentRef': utr, 'paymentMethod': selectedMethod}),
                    );
                    final body = jsonDecode(res.body);
                    if (!mounted) return;
                    Navigator.pop(ctx);
                    if (res.statusCode == 200) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(body['message'] ?? 'Money added successfully!'),
                          backgroundColor: Colors.green));
                      _fetchWallet();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(body['message'] ?? 'Failed to add money'), backgroundColor: Colors.red));
                    }
                  } catch (_) {
                    setModalState(() => isLoading = false);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Network error. Please try again.'), backgroundColor: Colors.red));
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E6DE5), foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0),
                child: isLoading
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Add Money', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              )),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final balance = (_wallet?['balance'] ?? _wallet?['walletBalance'] ?? 0);
    final transactions = (_wallet?['transactions'] as List?) ?? (_wallet?['history'] as List?) ?? [];
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
              Text('₹${(balance is num ? balance.toDouble() : double.tryParse(balance.toString()) ?? 0.0).toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
              Text('Available Balance', style: TextStyle(color: Colors.grey[500], fontSize: 14)),
              const SizedBox(height: 20),
              SizedBox(width: double.infinity, height: 46,
                child: ElevatedButton.icon(
                  onPressed: _showAddMoneyDialog,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Money', style: TextStyle(fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E6DE5), foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
                )),
            ]),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(children: [
              const Text('Transaction History',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1A1A2E))),
              const Spacer(),
              Text('${transactions.length} records',
                style: TextStyle(fontSize: 12, color: Colors.grey[400])),
            ]),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: transactions.isEmpty
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 12),
                  Text('No transactions yet', style: TextStyle(color: Colors.grey[400], fontSize: 15)),
                ]))
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
                          child: Icon(isCredit ? Icons.arrow_downward : Icons.arrow_upward,
                            color: isCredit ? Colors.green : Colors.red, size: 20)),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(t['description'] ?? 'Transaction',
                            style: const TextStyle(fontWeight: FontWeight.w500, color: Color(0xFF1A1A2E)), maxLines: 1, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 2),
                          Text(t['date'] ?? t['created_at'] ?? '',
                            style: TextStyle(color: Colors.grey[400], fontSize: 12)),
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

class _MethodChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final String value;
  final bool selected;
  final VoidCallback onTap;
  const _MethodChip({required this.label, required this.icon, required this.value, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF1E6DE5) : const Color(0xFFF5F7FA),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? const Color(0xFF1E6DE5) : const Color(0xFFE5E7EB)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 16, color: selected ? Colors.white : const Color(0xFF6B7280)),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
            color: selected ? Colors.white : const Color(0xFF1A1A2E))),
        ]),
      ),
    );
  }
}
