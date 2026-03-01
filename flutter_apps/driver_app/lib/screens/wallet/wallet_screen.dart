import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/trip_service.dart';
import '../../services/auth_service.dart';
import '../../config/api_config.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  Map<String, dynamic>? _wallet;
  Map<String, dynamic>? _earnings;
  bool _loading = true;
  String _period = 'today';

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      TripService.getWallet(),
      TripService.getEarnings(_period),
    ]);
    if (mounted) setState(() { _wallet = results[0]; _earnings = results[1]; _loading = false; });
  }

  Future<void> _requestWithdrawal() async {
    final amtCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF091629),
        title: const Text('Request Withdrawal', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Available: ₹${_wallet?['walletBalance']?.toStringAsFixed(2) ?? '0.00'}',
              style: const TextStyle(color: Color(0xFF3B82F6), fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller: amtCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Enter amount',
                hintStyle: TextStyle(color: Color(0xFF475569)),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF1E3A5F))),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF2563EB))),
                prefixText: '₹ ',
                prefixStyle: TextStyle(color: Color(0xFF3B82F6), fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final amt = double.tryParse(amtCtrl.text);
              if (amt == null || amt <= 0) return;
              Navigator.pop(context);
              final headers = await AuthService.getHeaders();
              await http.post(
                Uri.parse('${ApiConfig.baseUrl}/api/app/driver/withdraw'),
                headers: headers,
                body: jsonEncode({'amount': amt}),
              );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Withdrawal request submitted!'), backgroundColor: Color(0xFF2563EB)),
              );
              _loadData();
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
            child: const Text('Request'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final balance = _wallet?['walletBalance'] ?? 0.0;
    final isLocked = _wallet?['isLocked'] ?? false;
    final history = (_wallet?['history'] as List?) ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFF060D1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF060D1E),
        title: const Text('Wallet', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: const Color(0xFF3B82F6),
          labelColor: const Color(0xFF3B82F6),
          unselectedLabelColor: const Color(0xFF64748B),
          tabs: const [Tab(text: 'Wallet'), Tab(text: 'Earnings')],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _buildWalletTab(balance, isLocked, history),
          _buildEarningsTab(),
        ],
      ),
    );
  }

  Widget _buildWalletTab(dynamic balance, bool isLocked, List history) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF1D4ED8), Color(0xFF2563EB)]),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                const Text('Wallet Balance', style: TextStyle(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 8),
                Text('₹${double.tryParse(balance.toString())?.toStringAsFixed(2) ?? '0.00'}',
                  style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
                if (isLocked)
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: const Color(0xFFEF4444).withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                    child: const Text('🔒 Account Locked — Pay dues to go online', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFFEF4444), fontSize: 12)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: _requestWithdrawal,
              icon: const Icon(Icons.account_balance, color: Color(0xFF3B82F6)),
              label: const Text('Request Withdrawal', style: TextStyle(color: Color(0xFF3B82F6))),
              style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFF2563EB)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            ),
          ),
          const SizedBox(height: 24),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('Transaction History', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          const SizedBox(height: 12),
          if (_loading)
            const Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6)))
          else if (history.isEmpty)
            const Center(child: Padding(padding: EdgeInsets.all(40), child: Text('No transactions yet', style: TextStyle(color: Color(0xFF64748B)))))
          else
            ...history.map((tx) => _txRow(tx)),
        ],
      ),
    );
  }

  Widget _txRow(dynamic tx) {
    final isCredit = tx['payment_type'] == 'credit' || tx['type'] == 'credit';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: const Color(0xFF091629), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF1E3A5F))),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: (isCredit ? const Color(0xFF16A34A) : const Color(0xFFEF4444)).withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(isCredit ? Icons.arrow_downward : Icons.arrow_upward, color: isCredit ? const Color(0xFF22C55E) : const Color(0xFFEF4444), size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tx['description'] ?? tx['payment_type'] ?? 'Transaction', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                Text(tx['created_at'] != null ? DateFormat('dd MMM, hh:mm a').format(DateTime.tryParse(tx['created_at']) ?? DateTime.now()) : '', style: const TextStyle(color: Color(0xFF64748B), fontSize: 11)),
              ],
            ),
          ),
          Text(
            '${isCredit ? '+' : '-'}₹${double.tryParse(tx['amount']?.toString() ?? '0')?.toStringAsFixed(2)}',
            style: TextStyle(color: isCredit ? const Color(0xFF22C55E) : const Color(0xFFEF4444), fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildEarningsTab() {
    final periods = ['today', 'week', 'month', 'all'];
    final labels = ['Today', 'This Week', 'This Month', 'All Time'];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(periods.length, (i) => GestureDetector(
                onTap: () { setState(() => _period = periods[i]); _loadData(); },
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: _period == periods[i] ? const Color(0xFF2563EB) : const Color(0xFF091629),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _period == periods[i] ? const Color(0xFF2563EB) : const Color(0xFF1E3A5F)),
                  ),
                  child: Text(labels[i], style: TextStyle(color: _period == periods[i] ? Colors.white : const Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w600)),
                ),
              )),
            ),
          ),
          const SizedBox(height: 20),
          if (_loading)
            const Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6)))
          else ...[
            _earningsCard('Gross Fare', '₹${(_earnings?['grossFare'] ?? 0).toStringAsFixed(2)}', Icons.payments, const Color(0xFF3B82F6)),
            const SizedBox(height: 12),
            _earningsCard('Commission', '-₹${(_earnings?['commission'] ?? 0).toStringAsFixed(2)}', Icons.percent, const Color(0xFFEF4444)),
            const SizedBox(height: 12),
            _earningsCard('Net Earnings', '₹${(_earnings?['netEarnings'] ?? 0).toStringAsFixed(2)}', Icons.account_balance_wallet, const Color(0xFF22C55E)),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: _statCard('Trips Done', '${_earnings?['completedTrips'] ?? 0}', const Color(0xFF3B82F6))),
              const SizedBox(width: 12),
              Expanded(child: _statCard('Cancelled', '${_earnings?['cancelledTrips'] ?? 0}', const Color(0xFFEF4444))),
            ]),
          ],
        ],
      ),
    );
  }

  Widget _earningsCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF091629), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFF1E3A5F))),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14))),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18)),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF091629), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFF1E3A5F))),
      child: Column(children: [
        Text(value, style: TextStyle(color: color, fontSize: 28, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
      ]),
    );
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }
}
