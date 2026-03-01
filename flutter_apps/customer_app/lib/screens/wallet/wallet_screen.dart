import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/trip_service.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  Map<String, dynamic>? _wallet;
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    _wallet = await TripService.getWallet();
    if (mounted) setState(() => _loading = false);
  }

  void _rechargeDialog() {
    final amounts = [50, 100, 200, 500, 1000];
    int selected = 100;
    final refCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('Recharge Wallet', style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Select Amount', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: amounts.map((a) => GestureDetector(
                  onTap: () => setS(() => selected = a),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected == a ? const Color(0xFF2563EB) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: selected == a ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0)),
                    ),
                    child: Text('₹$a', style: TextStyle(fontWeight: FontWeight.bold, color: selected == a ? Colors.white : const Color(0xFF0F172A))),
                  ),
                )).toList(),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: refCtrl,
                decoration: const InputDecoration(hintText: 'UPI/Payment Ref No.', border: OutlineInputBorder(), prefixIcon: Icon(Icons.payment)),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white),
              onPressed: () async {
                Navigator.pop(ctx);
                final res = await TripService.rechargeWallet(amount: selected.toDouble(), paymentRef: refCtrl.text.isEmpty ? 'MANUAL' : refCtrl.text);
                if (res['success'] == true && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Wallet recharged!'), backgroundColor: Color(0xFF2563EB)));
                  _load();
                }
              },
              child: const Text('Recharge'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final balance = double.tryParse(_wallet?['walletBalance']?.toString() ?? '0') ?? 0;
    final history = (_wallet?['history'] as List?) ?? [];
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Wallet', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
        centerTitle: true,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF2563EB)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF1D4ED8), Color(0xFF3B82F6)]),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(children: [
                      const Text('JAGO Wallet', style: TextStyle(color: Colors.white70, fontSize: 13)),
                      const SizedBox(height: 8),
                      Text('₹${balance.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _rechargeDialog,
                          icon: const Icon(Icons.add, color: Colors.white),
                          label: const Text('Add Money', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white60), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                        ),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      _infoCard(Icons.shopping_bag, 'Total Spent', '₹${(_wallet?['totalSpent'] ?? 0).toStringAsFixed(0)}'),
                      const SizedBox(width: 12),
                      _infoCard(Icons.add_circle, 'Total Added', '₹${(_wallet?['totalRecharged'] ?? 0).toStringAsFixed(0)}'),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Align(alignment: Alignment.centerLeft, child: Text('Transaction History', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)))),
                  const SizedBox(height: 12),
                  if (history.isEmpty)
                    const Center(child: Padding(padding: EdgeInsets.all(32), child: Column(children: [
                      Icon(Icons.receipt_long, size: 48, color: Color(0xFFCBD5E1)),
                      SizedBox(height: 12),
                      Text('No transactions yet', style: TextStyle(color: Color(0xFF94A3B8))),
                    ])))
                  else
                    ...history.map((tx) => _txRow(tx)),
                ],
              ),
            ),
    );
  }

  Widget _infoCard(IconData icon, String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE2E8F0))),
        child: Column(children: [
          Icon(icon, color: const Color(0xFF2563EB), size: 22),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A))),
          Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
        ]),
      ),
    );
  }

  Widget _txRow(dynamic tx) {
    final isCredit = tx['payment_type'] == 'credit' || tx['type'] == 'credit';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Row(
        children: [
          Container(width: 40, height: 40, decoration: BoxDecoration(color: (isCredit ? const Color(0xFF2563EB) : const Color(0xFFEF4444)).withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Icon(isCredit ? Icons.add : Icons.remove, color: isCredit ? const Color(0xFF2563EB) : const Color(0xFFEF4444), size: 18)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(tx['description'] ?? 'Transaction', style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13, fontWeight: FontWeight.w600)),
            Text(tx['created_at'] != null ? DateFormat('dd MMM, hh:mm a').format(DateTime.tryParse(tx['created_at']) ?? DateTime.now()) : '', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
          ])),
          Text('${isCredit ? '+' : '-'}₹${double.tryParse(tx['amount']?.toString() ?? '0')?.toStringAsFixed(2)}', style: TextStyle(color: isCredit ? const Color(0xFF2563EB) : const Color(0xFFEF4444), fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }
}
