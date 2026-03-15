import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../config/api_config.dart';
import '../../services/auth_service.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});
  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _wallet;
  bool _loading = true;
  bool _paying = false;
  double? _pendingAmount;
  late AnimationController _headerCtrl;
  late Animation<double> _headerFade;

  late Razorpay _razorpay;

  @override
  void initState() {
    super.initState();
    _headerCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _headerFade = CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOut);

    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    _fetchWallet();
  }

  @override
  void dispose() {
    _headerCtrl.dispose();
    _razorpay.clear();
    super.dispose();
  }

  Future<void> _fetchWallet() async {
    final headers = await AuthService.getHeaders();
    try {
      final res =
          await http.get(Uri.parse(ApiConfig.wallet), headers: headers);
      if (res.statusCode == 200) {
        if (mounted) {
          setState(() {
            _wallet = jsonDecode(res.body);
            _loading = false;
          });
          _headerCtrl.forward();
        }
      } else {
        if (mounted) setState(() => _loading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
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
        if (mounted) setState(() => _paying = false);
        if (mounted) {
          _showSnack(body['message'] ?? 'Failed to create order', Colors.red);
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
        'prefill': {'contact': '+91$phone', 'email': email},
        'theme': {'color': '#2F80ED'},
        'modal': {'confirm_close': true},
      };
      _razorpay.open(options);
    } catch (e) {
      if (mounted) setState(() => _paying = false);
      if (mounted) _showSnack('Network error. Please try again.', Colors.red);
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    if (mounted) setState(() => _paying = false);
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
          _showSnack(
              body['message'] ??
                  '₹${_pendingAmount?.toStringAsFixed(0)} added to wallet!',
              Colors.green);
          _fetchWallet();
        } else {
          _showSnack(
              body['message'] ?? 'Payment verification failed', Colors.orange);
        }
      }
    } catch (_) {
      if (mounted) {
        _showSnack(
            'Payment done but verification failed. Contact support.',
            Colors.orange);
      }
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    if (mounted) {
      setState(() => _paying = false);
      _showSnack(
          response.message ?? 'Payment failed. Please try again.', Colors.red);
    }
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    if (mounted) {
      setState(() => _paying = false);
      _showSnack('External wallet: ${response.walletName}', Colors.blue);
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  void _showAddMoneySheet() {
    double? selectedPreset;
    final customCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.fromLTRB(
              24, 16, 24, MediaQuery.of(ctx).viewInsets.bottom + 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Add Money',
                      style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF111827))),
                  IconButton(
                    icon: const Icon(Icons.close_rounded,
                        color: Color(0xFF9CA3AF)),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.verified_rounded,
                        color: Colors.green, size: 14),
                    const SizedBox(width: 5),
                    Text('Secured by Razorpay',
                        style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Colors.green,
                            fontWeight: FontWeight.w600)),
                  ]),
                ),
              ]),
              const SizedBox(height: 20),
              Text('Quick Add',
                  style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF6B7280),
                      letterSpacing: 0.5)),
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
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 11),
                      decoration: BoxDecoration(
                        color: sel
                            ? const Color(0xFF2F80ED)
                            : const Color(0xFFF3F6FB),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: sel
                                ? const Color(0xFF2F80ED)
                                : const Color(0xFFE5E7EB)),
                        boxShadow: sel
                            ? [
                                BoxShadow(
                                    color: const Color(0xFF2F80ED)
                                        .withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3))
                              ]
                            : [],
                      ),
                      child: Text('₹$amt',
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: sel
                                  ? Colors.white
                                  : const Color(0xFF374151))),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              Text('Custom Amount',
                  style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF6B7280),
                      letterSpacing: 0.5)),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                    color: const Color(0xFFF3F6FB),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE5E7EB))),
                child: Row(children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: Text('₹',
                        style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF111827))),
                  ),
                  Expanded(
                    child: TextField(
                      controller: customCtrl,
                      keyboardType: TextInputType.number,
                      onChanged: (_) =>
                          setModalState(() => selectedPreset = null),
                      style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF111827)),
                      decoration: InputDecoration(
                        hintText: 'Enter amount (min ₹10)',
                        hintStyle: GoogleFonts.poppins(
                            color: const Color(0xFF9CA3AF), fontSize: 14),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 16),
                      ),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1A6FE0), Color(0xFF2F80ED)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                          color: const Color(0xFF2F80ED).withValues(alpha: 0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 5))
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _paying
                        ? null
                        : () {
                            final raw = customCtrl.text.trim();
                            final amt = double.tryParse(raw);
                            if (amt == null || amt < 10) {
                              _showSnack('Minimum amount is ₹10', Colors.red);
                              return;
                            }
                            Navigator.pop(ctx);
                            _startRazorpayPayment(amt);
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: _paying
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.payment_rounded, size: 20),
                              const SizedBox(width: 8),
                              Text('Pay via Razorpay',
                                  style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700)),
                            ],
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final balance = _wallet?['balance'] ?? _wallet?['walletBalance'] ?? 0;
    final balanceDouble = balance is num
        ? balance.toDouble()
        : double.tryParse(balance.toString()) ?? 0.0;
    final transactions = (_wallet?['transactions'] as List?) ??
        (_wallet?['history'] as List?) ??
        [];

    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FB),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF2F80ED)))
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildHeader(balanceDouble)),
                SliverToBoxAdapter(child: _buildPaymentMethods()),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                    child: Row(children: [
                      Text('Transaction History',
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: const Color(0xFF111827))),
                      const Spacer(),
                      Text('${transactions.length} records',
                          style: GoogleFonts.poppins(
                              fontSize: 12, color: const Color(0xFF6B7280))),
                    ]),
                  ),
                ),
                if (transactions.isEmpty)
                  SliverFillRemaining(
                    child: _buildEmpty(),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) =>
                          _buildTransactionItem(transactions[i]),
                      childCount: transactions.length,
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ),
    );
  }

  Widget _buildHeader(double balance) {
    return FadeTransition(
      opacity: _headerFade,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1A6FE0), Color(0xFF2F80ED), Color(0xFF56CCF2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white, size: 18),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text('My Wallet',
                      style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700)),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      setState(() => _loading = true);
                      _fetchWallet();
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.refresh_rounded,
                          color: Colors.white, size: 20),
                    ),
                  ),
                ]),
                const SizedBox(height: 28),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.25), width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                              Icons.account_balance_wallet_rounded,
                              color: Colors.white,
                              size: 22),
                        ),
                        const SizedBox(width: 10),
                        Text('JAGO Wallet',
                            style: GoogleFonts.poppins(
                                color: Colors.white70,
                                fontSize: 13,
                                fontWeight: FontWeight.w500)),
                      ]),
                      const SizedBox(height: 16),
                      Text('₹${balance.toStringAsFixed(2)}',
                          style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 38,
                              fontWeight: FontWeight.w800,
                              height: 1.1)),
                      const SizedBox(height: 4),
                      Text('Available Balance',
                          style: GoogleFonts.poppins(
                              color: Colors.white60,
                              fontSize: 13)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _paying ? null : _showAddMoneySheet,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF2F80ED),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: _paying
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: Color(0xFF2F80ED), strokeWidth: 2))
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.add_circle_rounded, size: 20),
                              const SizedBox(width: 8),
                              Text('Add Money',
                                  style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15)),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentMethods() {
    final methods = [
      {
        'label': 'UPI',
        'icon': Icons.qr_code_rounded,
        'color': const Color(0xFF10B981),
        'bg': const Color(0xFFECFDF5),
      },
      {
        'label': 'Cards',
        'icon': Icons.credit_card_rounded,
        'color': const Color(0xFF2F80ED),
        'bg': const Color(0xFFEFF6FF),
      },
      {
        'label': 'Net Banking',
        'icon': Icons.account_balance_rounded,
        'color': const Color(0xFF7C3AED),
        'bg': const Color(0xFFF5F3FF),
      },
      {
        'label': 'Wallets',
        'icon': Icons.wallet_rounded,
        'color': const Color(0xFFF59E0B),
        'bg': const Color(0xFFFFFBEB),
      },
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Payment Methods',
              style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF111827))),
          const SizedBox(height: 4),
          Text('Powered by Razorpay — all methods accepted',
              style: GoogleFonts.poppins(
                  fontSize: 11, color: const Color(0xFF9CA3AF))),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: methods.map((m) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: m['bg'] as Color,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(m['icon'] as IconData,
                          color: m['color'] as Color, size: 22),
                    ),
                    const SizedBox(height: 6),
                    Text(m['label'] as String,
                        style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF374151))),
                  ]),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(24)),
            child: const Icon(Icons.receipt_long_outlined,
                size: 40, color: Color(0xFF2F80ED)),
          ),
          const SizedBox(height: 16),
          Text('No transactions yet',
              style: GoogleFonts.poppins(
                  color: const Color(0xFF374151),
                  fontSize: 16,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text('Add money to get started',
              style: GoogleFonts.poppins(
                  color: const Color(0xFF9CA3AF), fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(Map<String, dynamic> t) {
    final isCredit = t['type'] == 'credit';
    final method = (t['paymentMethod'] ?? t['payment_method'] ?? '')
        .toString()
        .toLowerCase();
    final isRazorpay = method.contains('razorpay');
    final date =
        t['date'] ?? t['created_at'] ?? t['createdAt'] ?? '';

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: (isCredit ? const Color(0xFF10B981) : const Color(0xFFEF4444))
                .withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
              isCredit
                  ? Icons.arrow_downward_rounded
                  : Icons.arrow_upward_rounded,
              color: isCredit
                  ? const Color(0xFF10B981)
                  : const Color(0xFFEF4444),
              size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t['description'] ?? 'Transaction',
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: const Color(0xFF111827)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Row(children: [
                if (isRazorpay) ...[
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                        color: const Color(0xFF2F80ED).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(5)),
                    child: Text('Razorpay',
                        style: GoogleFonts.poppins(
                            fontSize: 9,
                            color: const Color(0xFF2F80ED),
                            fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 6),
                ],
                Text(date,
                    style: GoogleFonts.poppins(
                        color: const Color(0xFF9CA3AF), fontSize: 11)),
              ]),
            ],
          ),
        ),
        Text(
          '${isCredit ? '+' : '-'}₹${t['amount']}',
          style: GoogleFonts.poppins(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: isCredit
                  ? const Color(0xFF10B981)
                  : const Color(0xFFEF4444)),
        ),
      ]),
    );
  }
}
