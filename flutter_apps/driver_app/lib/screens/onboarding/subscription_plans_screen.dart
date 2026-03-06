import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../config/api_config.dart';
import '../../services/auth_service.dart';
import '../home/home_screen.dart';

class SubscriptionPlansScreen extends StatefulWidget {
  final String selectedModel;

  const SubscriptionPlansScreen({
    super.key,
    this.selectedModel = 'subscription',
  });

  @override
  State<SubscriptionPlansScreen> createState() => _SubscriptionPlansScreenState();
}

class _SubscriptionPlansScreenState extends State<SubscriptionPlansScreen> {
  late Razorpay _razorpay;
  List<dynamic> _plans = [];
  bool _isLoading = true;
  String? _selectedPlanId;
  dynamic _selectedPlan;

  final Color _darkBg = const Color(0xFF060D1E);
  final Color _primary = const Color(0xFF1E6DE5);
  final Color _surface = const Color(0xFF0D1B3E);
  final Color _gold = const Color(0xFFFFD700);

  @override
  void initState() {
    super.initState();
    _syncSelectedModel();
    _fetchPlans();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  Future<void> _syncSelectedModel() async {
    try {
      final token = await AuthService.getToken();
      await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/app/driver/choose-model'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'model': widget.selectedModel}),
      );
    } catch (_) {
      // Ignore silently; payment flow still works and activation can set model server-side.
    }
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  Future<void> _fetchPlans() async {
    try {
      final token = await AuthService.getToken();
      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/app/driver/subscription-plans'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final plans = (body is List)
            ? body
            : List<dynamic>.from((body['plans'] as List?) ?? const []);
        setState(() {
          _plans = plans;
          _isLoading = false;
          if (_plans.isNotEmpty) {
            _selectedPlanId = _plans[0]['id'].toString();
            _selectedPlan = _plans[0];
          }
        });
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
          _showError('Failed to load plans');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('Failed to load plans');
      }
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    try {
      final token = await AuthService.getToken();
      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/app/driver/activate-subscription'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'planId': _selectedPlanId,
          'razorpayPaymentId': response.paymentId,
        }),
      );

      if (res.statusCode == 200) {
        if (!mounted) return;
        _showSuccessDialog();
      } else {
        _showError('Failed to activate subscription');
      }
    } catch (e) {
      _showError('Error finalizing payment');
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    _showError('Payment failed: ${response.message}');
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    _showError('External wallet selected: ${response.walletName}');
  }

  Future<void> _subscribe() async {
    if (_selectedPlanId == null) return;
    
    try {
      final token = await AuthService.getToken();
      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/app/driver/subscribe'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'planId': _selectedPlanId}),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final orderId = data['orderId'];
        final amount = data['amount'];
        final keyId = data['keyId'] ?? '';
        final token2 = await AuthService.getToken();
        String driverPhone = '';
        try {
          final profRes = await http.get(
            Uri.parse('${ApiConfig.baseUrl}/api/app/driver/profile'),
            headers: {'Authorization': 'Bearer $token2'},
          );
          if (profRes.statusCode == 200) {
            final profData = jsonDecode(profRes.body);
            driverPhone = profData['phone']?.toString() ?? '';
          }
        } catch (_) {}

        var options = {
          'key': keyId,
          'amount': amount,
          'currency': 'INR',
          'name': 'JAGO Pilot',
          'order_id': orderId,
          'description': 'Subscription Plan: ${_selectedPlan?['name']}',
          'timeout': 300,
          'prefill': {
            'contact': driverPhone,
            'email': '',
          },
          'theme': {'color': '#1E6DE5'},
        };
        _razorpay.open(options);
      } else {
        _showError('Failed to create order');
      }
    } catch (e) {
      _showError('Error initiating payment');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: _surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Success!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text('Your subscription is now active.', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const HomeScreen()),
                (route) => false,
              );
            },
            child: Text('Start Earning', style: TextStyle(color: _primary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _darkBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Choose Plan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1E6DE5)))
          : Column(
              children: [
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Unlock Full Earnings',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Subscribe and keep 100% of every ride',
                        style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: _plans.length,
                    itemBuilder: (context, index) {
                      final plan = _plans[index];
                      return _buildPlanCard(plan);
                    },
                  ),
                ),
                _buildBenefitsSection(),
                _buildBottomButton(),
              ],
            ),
    );
  }

  Widget _buildPlanCard(dynamic plan) {
    final id = plan['id'].toString();
    final isSelected = _selectedPlanId == id;
    final name = plan['name'];
    final price = plan['price'];
    final durationDays = plan['durationDays'];
    final dailyRate = (price / durationDays).toStringAsFixed(0);
    final features = List<String>.from(plan['features'] ?? []);
    
    // Logic for badges and colors
    bool isPopular = name.toString().toLowerCase().contains('weekly');
    bool isBestValue = name.toString().toLowerCase().contains('basic');
    
    Color borderColor = Colors.white.withOpacity(0.1);
    if (isSelected) borderColor = _primary;
    if (isBestValue && isSelected) borderColor = _gold;

    return GestureDetector(
      onTap: () => setState(() {
        _selectedPlanId = id;
        _selectedPlan = plan;
      }),
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor, width: 2),
          boxShadow: isSelected ? [
            BoxShadow(color: (isBestValue ? _gold : _primary).withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 8))
          ] : [],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: (isBestValue ? _gold : _primary).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '$durationDays DAYS',
                          style: TextStyle(color: isBestValue ? _gold : _primary, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                      if (isPopular || isBestValue)
                        Text(
                          isBestValue ? 'BEST VALUE' : 'POPULAR',
                          style: TextStyle(color: isBestValue ? _gold : _primary, fontSize: 10, fontWeight: FontWeight.w900),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('₹$price', style: TextStyle(color: _primary, fontSize: 28, fontWeight: FontWeight.w900)),
                      const SizedBox(width: 4),
                      Text('per $durationDays days', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),
                      const Spacer(),
                      Text('≈ ₹$dailyRate/day', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13, fontWeight: FontWeight.w500)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: Colors.white10),
                  const SizedBox(height: 12),
                  ...features.map((f) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Icon(Icons.check, color: Colors.green.shade400, size: 16),
                        const SizedBox(width: 8),
                        Text(f, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13)),
                      ],
                    ),
                  )),
                ],
              ),
            ),
            Positioned(
              bottom: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isSelected ? _primary : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(color: isSelected ? _primary : Colors.white24),
                ),
                child: Icon(Icons.check, color: isSelected ? Colors.white : Colors.transparent, size: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitsSection() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _benefitItem(Icons.trending_up, 'Max Earnings'),
          _benefitItem(Icons.security, 'Safe Payments'),
          _benefitItem(Icons.support_agent, 'Priority Support'),
        ],
      ),
    );
  }

  Widget _benefitItem(IconData icon, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white30, size: 24),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white30, fontSize: 10)),
      ],
    );
  }

  Widget _buildBottomButton() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [_primary, const Color(0xFF4A8FEF)]),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: _primary.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: ElevatedButton(
          onPressed: _subscribe,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: Text(
            'Subscribe & Pay ₹${_selectedPlan?['price'] ?? ''}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
