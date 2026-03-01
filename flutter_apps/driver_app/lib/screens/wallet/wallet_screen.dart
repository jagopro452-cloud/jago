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

class _WalletScreenState extends State<WalletScreen> with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _wallet;
  bool _loading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchWallet();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchWallet() async {
    final token = await AuthService.getToken();
    try {
      final res = await http.get(
        Uri.parse(ApiConfig.driverWallet),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (res.statusCode == 200) {
        setState(() { _wallet = jsonDecode(res.body); _loading = false; });
      } else {
        setState(() => _loading = false);
      }
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  void _showWithdrawDialog() {
    final amountCtrl = TextEditingController();
    final bankNameCtrl = TextEditingController();
    final accountCtrl = TextEditingController();
    final ifscCtrl = TextEditingController();
    final holderCtrl = TextEditingController();
    final upiCtrl = TextEditingController();
    String method = 'bank';
    bool loading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0D1B4B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 32,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.account_balance_wallet, color: Color(0xFF2563EB), size: 22),
                  const SizedBox(width: 8),
                  const Text('Withdraw Funds', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  IconButton(icon: const Icon(Icons.close, color: Colors.white54), onPressed: () => Navigator.pop(ctx)),
                ]),
                const SizedBox(height: 4),
                Text('Available: ₹${(_wallet?['walletBalance'] ?? _wallet?['balance'] ?? 0).toStringAsFixed(2)}',
                  style: const TextStyle(color: Color(0xFF2563EB), fontSize: 13)),
                const SizedBox(height: 16),

                // Amount
                _buildField(amountCtrl, 'Amount (min ₹100)', keyboardType: TextInputType.number, prefix: '₹'),
                const SizedBox(height: 12),

                // Method toggle
                const Text('Payment Method', style: TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 8),
                Row(children: [
                  _methodBtn(ctx, setModalState, 'Bank Transfer', 'bank', method, (v) => setModalState(() => method = v)),
                  const SizedBox(width: 8),
                  _methodBtn(ctx, setModalState, 'UPI', 'upi', method, (v) => setModalState(() => method = v)),
                ]),
                const SizedBox(height: 16),

                if (method == 'bank') ...[
                  _buildField(holderCtrl, 'Account Holder Name'),
                  const SizedBox(height: 10),
                  _buildField(bankNameCtrl, 'Bank Name'),
                  const SizedBox(height: 10),
                  _buildField(accountCtrl, 'Account Number', keyboardType: TextInputType.number),
                  const SizedBox(height: 10),
                  _buildField(ifscCtrl, 'IFSC Code'),
                ] else ...[
                  _buildField(upiCtrl, 'UPI ID (e.g. name@bank)'),
                ],

                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: loading ? null : () async {
                      final amt = double.tryParse(amountCtrl.text.trim());
                      if (amt == null || amt < 100) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Enter a valid amount (min ₹100)'), backgroundColor: Colors.red));
                        return;
                      }
                      if (method == 'bank' && (holderCtrl.text.isEmpty || accountCtrl.text.isEmpty || ifscCtrl.text.isEmpty)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Fill all bank details'), backgroundColor: Colors.red));
                        return;
                      }
                      if (method == 'upi' && upiCtrl.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Enter UPI ID'), backgroundColor: Colors.red));
                        return;
                      }
                      setModalState(() => loading = true);
                      try {
                        final token = await AuthService.getToken();
                        final body = method == 'upi'
                          ? {'amount': amt, 'method': 'upi', 'upiId': upiCtrl.text.trim()}
                          : {
                              'amount': amt, 'method': 'bank',
                              'bankName': bankNameCtrl.text.trim(),
                              'accountNumber': accountCtrl.text.trim(),
                              'ifscCode': ifscCtrl.text.trim(),
                              'accountHolderName': holderCtrl.text.trim(),
                            };
                        final res = await http.post(
                          Uri.parse(ApiConfig.driverWithdrawRequest),
                          headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
                          body: jsonEncode(body),
                        );
                        final data = jsonDecode(res.body);
                        if (mounted) Navigator.pop(ctx);
                        if (res.statusCode == 200) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(data['message'] ?? 'Withdrawal requested'), backgroundColor: Colors.green));
                          _fetchWallet();
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(data['message'] ?? 'Request failed'), backgroundColor: Colors.red));
                        }
                      } catch (e) {
                        setModalState(() => loading = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Network error. Try again.'), backgroundColor: Colors.red));
                      }
                    },
                    child: loading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Submit Withdrawal Request', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _methodBtn(BuildContext ctx, StateSetter setModalState, String label, String value, String current, ValueChanged<String> onTap) {
    final active = current == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? const Color(0xFF2563EB) : const Color(0xFF060D1E),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: active ? const Color(0xFF2563EB) : Colors.white24),
          ),
          child: Center(child: Text(label, style: TextStyle(color: active ? Colors.white : Colors.white54, fontWeight: FontWeight.w600, fontSize: 13))),
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController ctrl, String hint, {TextInputType keyboardType = TextInputType.text, String? prefix}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38),
        prefixText: prefix,
        prefixStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        filled: true,
        fillColor: const Color(0xFF060D1E),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final balance = (_wallet?['walletBalance'] ?? _wallet?['balance'] ?? 0).toDouble();
    final isLocked = _wallet?['isLocked'] ?? false;
    final history = (_wallet?['history'] ?? _wallet?['transactions'] ?? []) as List;
    final withdrawals = (_wallet?['withdrawRequests'] ?? []) as List;

    return Scaffold(
      backgroundColor: const Color(0xFF060D1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF060D1E),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.white.withOpacity(0.7)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Wallet', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white54),
            onPressed: () { setState(() => _loading = true); _fetchWallet(); },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF2563EB),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white38,
          tabs: const [Tab(text: 'Transactions'), Tab(text: 'Withdrawals')],
        ),
      ),
      body: _loading
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF2563EB)))
        : Column(children: [
            // Balance card
            Container(
              width: double.infinity,
              color: const Color(0xFF0D1B4B),
              padding: const EdgeInsets.all(24),
              child: Column(children: [
                Icon(isLocked ? Icons.lock : Icons.savings_outlined,
                  color: isLocked ? Colors.red : const Color(0xFF2563EB), size: 36),
                const SizedBox(height: 10),
                Text('₹${balance.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: Colors.white)),
                Text(isLocked ? 'Account Locked — Clear dues to unlock' : 'Available Balance',
                  style: TextStyle(color: isLocked ? Colors.red.shade300 : Colors.white.withOpacity(0.4), fontSize: 13)),
                if (!isLocked && balance >= 100) ...[
                  const SizedBox(height: 14),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    icon: const Icon(Icons.arrow_upward, color: Colors.white, size: 16),
                    label: const Text('Request Withdrawal', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    onPressed: _showWithdrawDialog,
                  ),
                ],
              ]),
            ),

            // Tabs content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Transactions tab
                  history.isEmpty
                    ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.receipt_long, color: Colors.white.withOpacity(0.2), size: 48),
                        const SizedBox(height: 12),
                        Text('No transactions yet', style: TextStyle(color: Colors.white.withOpacity(0.3))),
                      ]))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: history.length,
                        itemBuilder: (_, i) {
                          final t = history[i] as Map;
                          final isCredit = (t['type']?.toString() ?? '').contains('credit') || (t['type']?.toString() ?? '').contains('earn');
                          final amt = (t['amount'] as num?)?.toDouble() ?? 0;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0D1B4B),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(children: [
                              Container(
                                width: 38, height: 38,
                                decoration: BoxDecoration(
                                  color: (isCredit ? Colors.green : Colors.red).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(isCredit ? Icons.add : Icons.remove,
                                  color: isCredit ? Colors.green : Colors.red, size: 18),
                              ),
                              const SizedBox(width: 12),
                              Expanded(child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(t['description']?.toString() ?? 'Transaction',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 13)),
                                  Text(t['date']?.toString()?.substring(0, 10) ?? t['createdAt']?.toString()?.substring(0, 10) ?? '',
                                    style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 11)),
                                ],
                              )),
                              Text('${isCredit ? '+' : '-'}₹${amt.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 14,
                                  color: isCredit ? Colors.green : Colors.red)),
                            ]),
                          );
                        },
                      ),

                  // Withdrawals tab
                  withdrawals.isEmpty
                    ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.account_balance, color: Colors.white.withOpacity(0.2), size: 48),
                        const SizedBox(height: 12),
                        Text('No withdrawal requests yet', style: TextStyle(color: Colors.white.withOpacity(0.3))),
                        const SizedBox(height: 8),
                        if (!isLocked && balance >= 100)
                          TextButton.icon(
                            icon: const Icon(Icons.add, color: Color(0xFF2563EB)),
                            label: const Text('Request Withdrawal', style: TextStyle(color: Color(0xFF2563EB))),
                            onPressed: _showWithdrawDialog,
                          ),
                      ]))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: withdrawals.length,
                        itemBuilder: (_, i) {
                          final w = withdrawals[i] as Map;
                          final status = w['status']?.toString() ?? 'pending';
                          final statusColor = status == 'paid' ? Colors.green
                            : status == 'approved' ? Colors.blue
                            : status == 'rejected' ? Colors.red
                            : Colors.orange;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0D1B4B),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(children: [
                              Container(
                                width: 38, height: 38,
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(Icons.account_balance, color: statusColor, size: 18),
                              ),
                              const SizedBox(width: 12),
                              Expanded(child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('₹${(w['amount'] as num?)?.toStringAsFixed(2) ?? '0.00'}',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                                  Text(w['notes']?.toString() ?? '', maxLines: 1, overflow: TextOverflow.ellipsis,
                                    style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11)),
                                ],
                              )),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(status.toUpperCase(),
                                  style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                            ]),
                          );
                        },
                      ),
                ],
              ),
            ),
          ]),
    );
  }
}
