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

class _WalletScreenState extends State<WalletScreen> {
  Map<String, dynamic>? _wallet;
  bool _loading = true;
  bool _paying = false;
  double? _pendingAmount;

  late Razorpay _razorpay;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    _fetchWallet();
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  Future<void> _fetchWallet() async {
    final headers = await AuthService.getHeaders();
    try {
      final res = await http.get(Uri.parse(ApiConfig.wallet),
          headers: headers);
      if (res.statusCode == 200) {
        setState(() {
          _wallet = jsonDecode(res.body);
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _startRazorpayPayment(double amount) async {
    setState(() => _paying = true);
    _pendingAmount = amount;
    try {
      final headers = await AuthService.getHeaders();
      final profileData = await AuthService.getProfile();
      final res = await http.post(
        Uri.parse(ApiConfig.walletCreateOrder),
        headers: {...headers, 'Content-Type': 'application/json'},
        body: jsonEncode({'amount': amount}),
      );
      final body = jsonDecode(res.body);
      if (res.statusCode != 200) {
        setState(() => _paying = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(body['message'] ?? 'Failed to create order'),
              backgroundColor: Colors.red));
        }
        return;
      }
      final order = body['order'];
      final keyId = body['keyId'] as String;
      final phone = profileData?['phone'] ?? '';
      final email = profileData?['email'] ?? 'customer@jago.com';

      final options = {
        'key': keyId,
        'amount': (amount * 100).toInt(),
        'name': 'JAGO Rides',
        'description': 'Wallet Recharge',
        'order_id': order['id'],
        'prefill': {
          'contact': '+91$phone',
          'email': email,
        },
        'theme': {'color': '#1E6DE5'},
        'modal': {'confirm_close': true},
      };
      _razorpay.open(options);
    } catch (e) {
      setState(() => _paying = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Network error. Please try again.'),
                backgroundColor: Colors.red));
      }
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    setState(() => _paying = false);
    try {
      final headers = await AuthService.getHeaders();
      final res = await http.post(
        Uri.parse(ApiConfig.walletVerifyPayment),
        headers: {...headers, 'Content-Type': 'application/json'},
        body: jsonEncode({
          'razorpayOrderId': response.orderId,
          'razorpayPaymentId': response.paymentId,
          'razorpaySignature': response.signature,
          'amount': _pendingAmount,
        }),
      );
      final body = jsonDecode(res.body);
      if (mounted) {
        if (res.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(body['message'] ?? '₹${_pendingAmount?.toStringAsFixed(0)} added to wallet!'),
              backgroundColor: Colors.green));
          _fetchWallet();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(body['message'] ?? 'Payment verification failed'),
              backgroundColor: Colors.orange));
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Payment done but verification failed. Contact support.'),
            backgroundColor: Colors.orange));
      }
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    setState(() => _paying = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(response.message ?? 'Payment failed. Please try again.'),
          backgroundColor: Colors.red));
    }
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    setState(() => _paying = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('External wallet: ${response.walletName}'),
          backgroundColor: Colors.blue));
    }
  }

  void _showAddMoneySheet() {
    double? selectedPreset;
    final customCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final sheetBg = isDark ? const Color(0xFF141B2D) : Colors.white;
        final textColor = isDark ? Colors.white : const Color(0xFF111827);
        final subColor = isDark ? Colors.white54 : const Color(0xFF6B7280);
        final fieldBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFF5F7FA);
        final borderColor = isDark ? Colors.white12 : const Color(0xFFE5E7EB);

        return StatefulBuilder(
          builder: (ctx, setModalState) => Container(
            decoration: BoxDecoration(
              color: sheetBg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.fromLTRB(
                24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Add Money to Wallet',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: textColor)),
                    IconButton(
                      icon: Icon(Icons.close_rounded, color: subColor),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6)),
                    child: const Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.verified_rounded, color: Colors.green, size: 14),
                      SizedBox(width: 4),
                      Text('Secured by Razorpay',
                          style: TextStyle(
                              fontSize: 11,
                              color: Colors.green,
                              fontWeight: FontWeight.w600)),
                    ]),
                  ),
                ]),
                const SizedBox(height: 20),
                Text('Quick Select',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: subColor,
                        letterSpacing: 0.8)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [100, 200, 500, 1000, 2000].map((amt) {
                    final sel = selectedPreset == amt.toDouble();
                    return GestureDetector(
                      onTap: () => setModalState(() {
                        selectedPreset = amt.toDouble();
                        customCtrl.text = amt.toString();
                      }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: sel
                              ? const Color(0xFFFF6200)
                              : fieldBg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: sel
                                  ? const Color(0xFFFF6200)
                                  : borderColor),
                        ),
                        child: Text('₹$amt',
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: sel ? Colors.white : textColor)),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                Text('Custom Amount',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: subColor,
                        letterSpacing: 0.8)),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                      color: fieldBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderColor)),
                  child: Row(children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: Text('₹',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: textColor)),
                    ),
                    Expanded(
                      child: TextField(
                        controller: customCtrl,
                        keyboardType: TextInputType.number,
                        onChanged: (_) =>
                            setModalState(() => selectedPreset = null),
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: textColor),
                        decoration: InputDecoration(
                          hintText: 'Enter amount (min ₹10)',
                          hintStyle: TextStyle(color: subColor, fontSize: 14),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 16),
                        ),
                      ),
                    ),
                  ]),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _paying
                        ? null
                        : () {
                            final raw = customCtrl.text.trim();
                            final amt = double.tryParse(raw);
                            if (amt == null || amt < 10) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Minimum amount is ₹10'),
                                      backgroundColor: Colors.red));
                              return;
                            }
                            Navigator.pop(ctx);
                            _startRazorpayPayment(amt);
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6200),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: _paying
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.payment_rounded, size: 20),
                              SizedBox(width: 8),
                              Text('Pay via Razorpay',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700)),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg =
        isDark ? const Color(0xFF0A0F1E) : const Color(0xFFF3F6FB);
    final cardBg = isDark ? const Color(0xFF141B2D) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF111827);
    final subColor = isDark ? Colors.white54 : const Color(0xFF6B7280);

    final balance =
        (_wallet?['balance'] ?? _wallet?['walletBalance'] ?? 0);
    final balanceDouble = balance is num
        ? balance.toDouble()
        : double.tryParse(balance.toString()) ?? 0.0;
    final transactions =
        (_wallet?['transactions'] as List?) ?? (_wallet?['history'] as List?) ?? [];

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: cardBg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: textColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Wallet',
            style: TextStyle(color: textColor, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: subColor),
            onPressed: () {
              setState(() => _loading = true);
              _fetchWallet();
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFFF6200)))
          : Column(children: [
              Container(
                width: double.infinity,
                color: cardBg,
                padding: const EdgeInsets.fromLTRB(28, 28, 28, 24),
                child: Column(children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF6200), Color(0xFF3B82F6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                            Icons.account_balance_wallet_rounded,
                            color: Colors.white,
                            size: 26),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('JAGO Wallet',
                                style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500)),
                            Text(
                                '₹${balanceDouble.toStringAsFixed(2)}',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 30,
                                    fontWeight: FontWeight.w900)),
                            const Text('Available Balance',
                                style: TextStyle(
                                    color: Colors.white60, fontSize: 11)),
                          ],
                        ),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _paying ? null : _showAddMoneySheet,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF6200),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: _paying
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_rounded, size: 20),
                                SizedBox(width: 8),
                                Text('Add Money',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15)),
                              ],
                            ),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(children: [
                  Text('Transaction History',
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: textColor)),
                  const Spacer(),
                  Text('${transactions.length} records',
                      style: TextStyle(fontSize: 12, color: subColor)),
                ]),
              ),
              const SizedBox(height: 6),
              Expanded(
                child: transactions.isEmpty
                    ? Center(
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                          Icon(Icons.receipt_long_outlined,
                              size: 64,
                              color: isDark
                                  ? Colors.white24
                                  : Colors.grey.shade300),
                          const SizedBox(height: 12),
                          Text('No transactions yet',
                              style:
                                  TextStyle(color: subColor, fontSize: 15)),
                          const SizedBox(height: 6),
                          Text('Add money to see your history',
                              style:
                                  TextStyle(color: subColor, fontSize: 12)),
                        ]))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: transactions.length,
                        itemBuilder: (_, i) {
                          final t = transactions[i];
                          final isCredit = (t['type'] == 'credit');
                          final isRazorpay =
                              (t['paymentMethod'] ?? t['payment_method'] ?? '')
                                  .toString()
                                  .toLowerCase()
                                  .contains('razorpay');
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                                color: cardBg,
                                borderRadius: BorderRadius.circular(14)),
                            child: Row(children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: (isCredit ? Colors.green : Colors.red)
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                    isCredit
                                        ? Icons.arrow_downward_rounded
                                        : Icons.arrow_upward_rounded,
                                    color: isCredit ? Colors.green : Colors.red,
                                    size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                  Text(
                                      t['description'] ?? 'Transaction',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: textColor),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 3),
                                  Row(children: [
                                    if (isRazorpay)
                                      Container(
                                        margin:
                                            const EdgeInsets.only(right: 6),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                            color: Colors.blue
                                                .withValues(alpha: 0.12),
                                            borderRadius:
                                                BorderRadius.circular(4)),
                                        child: const Text('Razorpay',
                                            style: TextStyle(
                                                fontSize: 9,
                                                color: Colors.blue,
                                                fontWeight: FontWeight.w700)),
                                      ),
                                    Text(
                                        t['date'] ??
                                            t['created_at'] ??
                                            t['createdAt'] ??
                                            '',
                                        style: TextStyle(
                                            color: subColor, fontSize: 11)),
                                  ]),
                                ]),
                              ),
                              Text(
                                  '${isCredit ? '+' : '-'}₹${t['amount']}',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                      color: isCredit
                                          ? Colors.green
                                          : Colors.red)),
                            ]),
                          );
                        }),
              ),
            ]),
    );
  }
}
