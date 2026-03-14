import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../config/api_config.dart';
import '../../services/auth_service.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});
  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> with SingleTickerProviderStateMixin {
  static const Color _primary = Color(0xFF2F80ED);
  static const Color _navy = Color(0xFF0B0B0B);
  static const Color _surface = Color(0xFF1A1A1A);

  Map<String, dynamic>? _wallet;
  bool _loading = true;
  late TabController _tabController;
  late Razorpay _razorpay;
  double _pendingAmount = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onPaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _onPaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _onExternalWallet);
    _fetchWallet();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _razorpay.clear();
    super.dispose();
  }

  Future<void> _fetchWallet() async {
    final headers = await AuthService.getHeaders();
    try {
      final res = await http.get(
        Uri.parse(ApiConfig.driverWallet),
        headers: headers,
      );
      if (res.statusCode == 200) {
        if (mounted) setState(() { _wallet = jsonDecode(res.body); _loading = false; });
      } else {
        if (mounted) setState(() => _loading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showRechargeSheet() {
    double selectedAmount = 200;
    final customCtrl = TextEditingController();
    bool isCustom = false;
    bool paying = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 32,
          ),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: _primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.account_balance_wallet, color: _primary, size: 20)),
              const SizedBox(width: 12),
              const Text('Recharge Wallet', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const Spacer(),
              IconButton(icon: const Icon(Icons.close, color: Colors.white54), onPressed: () => Navigator.pop(ctx)),
            ]),
            const SizedBox(height: 4),
            Text('Current balance: ₹${(_wallet?['walletBalance'] ?? 0).toStringAsFixed(2)}',
              style: const TextStyle(color: Colors.white54, fontSize: 13)),
            const SizedBox(height: 20),

            const Text('Select Amount', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),

            // Quick amount chips
            Wrap(spacing: 10, runSpacing: 10, children: [
              for (final amt in [100.0, 200.0, 500.0, 1000.0])
                GestureDetector(
                  onTap: () => setSheet(() { selectedAmount = amt; isCustom = false; customCtrl.clear(); }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: (!isCustom && selectedAmount == amt) ? _primary : _navy,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: (!isCustom && selectedAmount == amt) ? _primary : Colors.white24,
                        width: (!isCustom && selectedAmount == amt) ? 2 : 1),
                    ),
                    child: Text('₹${amt.toInt()}',
                      style: TextStyle(
                        color: (!isCustom && selectedAmount == amt) ? Colors.white : Colors.white70,
                        fontWeight: FontWeight.w700, fontSize: 15)),
                  ),
                ),
              GestureDetector(
                onTap: () => setSheet(() => isCustom = true),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: isCustom ? _primary : _navy,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isCustom ? _primary : Colors.white24,
                      width: isCustom ? 2 : 1),
                  ),
                  child: Text('Custom',
                    style: TextStyle(
                      color: isCustom ? Colors.white : Colors.white70,
                      fontWeight: FontWeight.w700, fontSize: 15)),
                ),
              ),
            ]),
            const SizedBox(height: 16),

            if (isCustom) ...[
              TextField(
                controller: customCtrl,
                keyboardType: TextInputType.number,
                autofocus: true,
                onChanged: (v) => setSheet(() { selectedAmount = double.tryParse(v) ?? 0; }),
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  hintText: 'Enter amount',
                  hintStyle: const TextStyle(color: Colors.white38),
                  prefixText: '₹',
                  prefixStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                  filled: true,
                  fillColor: _navy,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.white12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _primary, width: 2)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Summary
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _primary.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _primary.withValues(alpha: 0.3))),
              child: Row(children: [
                const Icon(Icons.info_outline, color: _primary, size: 16),
                const SizedBox(width: 8),
                Text('You will be charged ₹${selectedAmount.toInt()} via Razorpay',
                  style: const TextStyle(color: Colors.white70, fontSize: 13)),
              ]),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                onPressed: (paying || selectedAmount < 1) ? null : () async {
                  setSheet(() => paying = true);
                  final amt = isCustom ? (double.tryParse(customCtrl.text.trim()) ?? 0) : selectedAmount;
                  if (amt < 1) {
                    setSheet(() => paying = false);
                    _showSnack('Please enter a valid amount', error: true);
                    return;
                  }
                  Navigator.pop(ctx);
                  await _initiateRecharge(amt);
                },
                child: paying
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                  : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Icons.payment, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Pay ₹${(isCustom ? (double.tryParse(customCtrl.text.trim()) ?? 0) : selectedAmount).toInt()} via Razorpay',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                    ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Future<void> _initiateRecharge(double amount) async {
    try {
      final rechargeHeaders = await AuthService.getHeaders();
      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/app/driver/wallet/create-order'),
        headers: {...rechargeHeaders, 'Content-Type': 'application/json'},
        body: jsonEncode({'amount': amount}),
      );
      if (res.statusCode != 200) {
        _showSnack('Failed to create payment order. Try again.', error: true);
        return;
      }
      final data = jsonDecode(res.body);
      final order = data['order'];
      final keyId = data['keyId'] ?? '';

      String driverPhone = '';
      try {
        final profRes = await http.get(
          Uri.parse('${ApiConfig.baseUrl}/api/app/driver/profile'),
          headers: rechargeHeaders,
        );
        if (profRes.statusCode == 200) {
          driverPhone = jsonDecode(profRes.body)['phone']?.toString() ?? '';
        }
      } catch (_) {}

      _pendingAmount = amount;
      _razorpay.open({
        'key': keyId,
        'amount': order['amount'],
        'currency': 'INR',
        'order_id': order['id'],
        'name': 'JAGO Pilot',
        'description': 'Wallet Recharge ₹${amount.toInt()}',
        'timeout': 300,
        'prefill': {'contact': driverPhone, 'email': ''},
        'theme': {'color': '#1E6DE5'},
      });
    } catch (e) {
      _showSnack('Payment error: $e', error: true);
    }
  }

  void _onPaymentSuccess(PaymentSuccessResponse response) async {
    _showSnack('Processing payment...', error: false);
    try {
      final verifyHeaders = await AuthService.getHeaders();
      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/app/driver/wallet/verify-payment'),
        headers: {...verifyHeaders, 'Content-Type': 'application/json'},
        body: jsonEncode({
          'razorpayOrderId': response.orderId,
          'razorpayPaymentId': response.paymentId,
          'razorpaySignature': response.signature,
          'amount': _pendingAmount,
        }),
      );
      final data = jsonDecode(res.body);
      if (res.statusCode == 200 || res.statusCode == 409) {
        final newBal = data['newBalance']?.toStringAsFixed(2) ?? _pendingAmount.toStringAsFixed(2);
        final autoUnlocked = data['autoUnlocked'] == true;
        _showSuccessDialog(_pendingAmount, double.tryParse(newBal) ?? 0, autoUnlocked);
        _fetchWallet();
      } else {
        _showSnack(data['message'] ?? 'Verification failed. Contact support.', error: true);
      }
    } catch (e) {
      _showSnack('Verification error. Contact support with payment ID: ${response.paymentId}', error: true);
    }
  }

  void _onPaymentError(PaymentFailureResponse response) {
    if (response.code != 0) {
      _showSnack('Payment failed: ${response.message ?? 'Unknown error'}', error: true);
    }
  }

  void _onExternalWallet(ExternalWalletResponse response) {}

  void _showSuccessDialog(double amount, double newBalance, bool autoUnlocked) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: _surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.12), shape: BoxShape.circle),
            child: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 48)),
          const SizedBox(height: 16),
          const Text('Recharge Successful!',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('₹${amount.toInt()} added to your wallet',
            style: const TextStyle(color: Colors.white70, fontSize: 14), textAlign: TextAlign.center),
          const SizedBox(height: 6),
          Text('New balance: ₹${newBalance.toStringAsFixed(2)}',
            style: const TextStyle(color: Color(0xFF2F80ED), fontSize: 16, fontWeight: FontWeight.bold)),
          if (autoUnlocked) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.lock_open, color: Colors.green, size: 16),
                SizedBox(width: 6),
                Text('Account Unlocked! You can now go online.', style: TextStyle(color: Colors.green, fontSize: 12)),
              ]),
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              onPressed: () => Navigator.pop(context),
              child: const Text('Done', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ]),
      ),
    );
  }

  void _showSnack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? Colors.red : Colors.green,
    ));
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
      backgroundColor: _surface,
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
                  const Icon(Icons.account_balance_wallet, color: _primary, size: 22),
                  const SizedBox(width: 8),
                  const Text('Withdraw Funds', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  IconButton(icon: const Icon(Icons.close, color: Colors.white54), onPressed: () => Navigator.pop(ctx)),
                ]),
                const SizedBox(height: 4),
                Text('Available: ₹${(_wallet?['walletBalance'] ?? _wallet?['balance'] ?? 0).toStringAsFixed(2)}',
                  style: const TextStyle(color: _primary, fontSize: 13)),
                const SizedBox(height: 16),

                _buildField(amountCtrl, 'Amount (min ₹100)', keyboardType: TextInputType.number, prefix: '₹'),
                const SizedBox(height: 12),

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
                      backgroundColor: _primary,
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
                        final wdHeaders = await AuthService.getHeaders();
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
                          headers: {...wdHeaders, 'Content-Type': 'application/json'},
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
            color: active ? _primary : _navy,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: active ? _primary : Colors.white24),
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
        fillColor: _navy,
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
      backgroundColor: _navy,
      appBar: AppBar(
        backgroundColor: _navy,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.white.withValues(alpha: 0.7)),
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
          indicatorColor: _primary,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white38,
          tabs: const [Tab(text: 'Transactions'), Tab(text: 'Withdrawals')],
        ),
      ),
      body: _loading
        ? const Center(child: CircularProgressIndicator(color: _primary))
        : Column(children: [
            // Balance card
            Container(
              width: double.infinity,
              color: _surface,
              padding: const EdgeInsets.all(24),
              child: Column(children: [
                // Lock / wallet icon
                Container(
                  width: 64, height: 64,
                  decoration: BoxDecoration(
                    color: (isLocked ? Colors.red : _primary).withValues(alpha: 0.12),
                    shape: BoxShape.circle),
                  child: Icon(
                    isLocked ? Icons.lock_rounded : Icons.account_balance_wallet_rounded,
                    color: isLocked ? Colors.red : _primary, size: 32)),
                const SizedBox(height: 12),
                Text('₹${balance.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 36, fontWeight: FontWeight.w900,
                    color: isLocked ? Colors.red.shade300 : Colors.white)),
                const SizedBox(height: 4),
                Text(
                  isLocked ? 'Account Locked — Recharge to unlock' : 'Available Balance',
                  style: TextStyle(
                    color: isLocked ? Colors.red.shade300 : Colors.white38,
                    fontSize: 13)),

                const SizedBox(height: 16),

                // Recharge button — always visible
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.add_circle_outline, color: Colors.white, size: 20),
                    label: const Text('Recharge Wallet', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                    onPressed: _showRechargeSheet,
                  ),
                ),

                // Withdrawal button — only when balance >= 100 and not locked
                if (!isLocked && balance >= 100) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white24),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      ),
                      icon: const Icon(Icons.arrow_upward, color: Colors.white54, size: 18),
                      label: const Text('Request Withdrawal', style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold)),
                      onPressed: _showWithdrawDialog,
                    ),
                  ),
                ],

                if (isLocked) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.withValues(alpha: 0.3))),
                    child: const Row(children: [
                      Icon(Icons.info_outline, color: Colors.red, size: 16),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text('Recharge your wallet to unlock your account and go online.',
                          style: TextStyle(color: Colors.red, fontSize: 12))),
                    ]),
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
                        Icon(Icons.receipt_long, color: Colors.white.withValues(alpha: 0.2), size: 48),
                        const SizedBox(height: 12),
                        Text('No transactions yet', style: TextStyle(color: Colors.white.withValues(alpha: 0.3))),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                          icon: const Icon(Icons.add, color: Colors.white, size: 16),
                          label: const Text('Recharge Now', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          onPressed: _showRechargeSheet,
                        ),
                      ]))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: history.length,
                        itemBuilder: (_, i) {
                          final t = history[i] as Map;
                          final isCredit = (t['type']?.toString() ?? '').contains('credit') ||
                            (t['type']?.toString() ?? '').contains('earn') ||
                            (t['type']?.toString() ?? '').contains('topup') ||
                            (t['type']?.toString() ?? '').contains('recharge');
                          final amt = (t['amount'] as num?)?.toDouble() ?? 0;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: _surface, borderRadius: BorderRadius.circular(12)),
                            child: Row(children: [
                              Container(
                                width: 40, height: 40,
                                decoration: BoxDecoration(
                                  color: (isCredit ? Colors.green : Colors.red).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  isCredit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                                  color: isCredit ? Colors.green : Colors.red, size: 18)),
                              const SizedBox(width: 12),
                              Expanded(child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(t['description']?.toString() ?? 'Transaction',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 13)),
                                  Text((t['date'] ?? t['createdAt'] ?? '').toString().split('T').first,
                                    style: const TextStyle(color: Colors.white38, fontSize: 11)),
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
                        Icon(Icons.account_balance, color: Colors.white.withValues(alpha: 0.2), size: 48),
                        const SizedBox(height: 12),
                        Text('No withdrawal requests yet', style: TextStyle(color: Colors.white.withValues(alpha: 0.3))),
                        const SizedBox(height: 8),
                        if (!isLocked && balance >= 100)
                          TextButton.icon(
                            icon: const Icon(Icons.add, color: _primary),
                            label: const Text('Request Withdrawal', style: TextStyle(color: _primary)),
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
                              color: _surface, borderRadius: BorderRadius.circular(12)),
                            child: Row(children: [
                              Container(
                                width: 40, height: 40,
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(Icons.account_balance, color: statusColor, size: 18)),
                              const SizedBox(width: 12),
                              Expanded(child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('₹${(w['amount'] as num?)?.toStringAsFixed(2) ?? '0.00'}',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                                  Text(w['notes']?.toString() ?? '', maxLines: 1, overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(color: Colors.white38, fontSize: 11)),
                                ],
                              )),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.12),
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
