import 'package:flutter/material.dart';
import 'package:get/get.dart';

class WalletBalanceCard extends StatelessWidget {
  final double balance;
  final double negativeLimit;
  final bool isLocked;
  final VoidCallback? onAddMoney;

  const WalletBalanceCard({
    super.key,
    required this.balance,
    this.negativeLimit = 200,
    this.isLocked = false,
    this.onAddMoney,
  });

  @override
  Widget build(BuildContext context) {
    final isNegative = balance < 0;
    final isWarning = isNegative && balance.abs() >= negativeLimit * 0.7;
    final isDanger = isNegative && balance.abs() >= negativeLimit;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDanger
              ? [const Color(0xFFDC2626), const Color(0xFFB91C1C)]
              : isWarning
                  ? [const Color(0xFFF59E0B), const Color(0xFFD97706)]
                  : [const Color(0xFF2563EB), const Color(0xFF1E3A8A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (isDanger ? Colors.red : isWarning ? Colors.amber : Colors.blue).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('wallet_balance'.tr, style: const TextStyle(color: Colors.white70, fontSize: 14)),
              if (isLocked)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.lock, color: Colors.white, size: 14),
                      const SizedBox(width: 4),
                      Text('account_locked'.tr, style: const TextStyle(color: Colors.white, fontSize: 12)),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '₹${balance.toStringAsFixed(2)}',
            style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
          ),
          if (isNegative) ...[
            const SizedBox(height: 8),
            Text(
              isDanger
                  ? 'account_locked_add_money'.tr
                  : 'negative_balance_warning'.tr,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ],
          if (isNegative) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onAddMoney,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: isDanger ? Colors.red : Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text('add_money'.tr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
