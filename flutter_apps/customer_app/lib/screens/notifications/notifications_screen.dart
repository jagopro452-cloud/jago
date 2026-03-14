import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import '../../services/auth_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _loading = true;
  List<dynamic> _notifications = [];

  static const Color _blue = Color(0xFF2F80ED);

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    if (mounted) setState(() => _loading = true);
    final headers = await AuthService.getHeaders();
    try {
      final res = await http.get(Uri.parse(ApiConfig.notifications),
          headers: headers);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (mounted) setState(() {
          _notifications = List<dynamic>.from(data['notifications'] ?? data ?? []);
          _loading = false;
        });
      } else {
        if (mounted) setState(() => _loading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _markAllRead() async {
    final headers = await AuthService.getHeaders();
    await http.patch(Uri.parse(ApiConfig.notificationsReadAll),
        headers: headers);
    _fetch();
  }

  IconData _iconForType(String? type) {
    switch (type) {
      case 'trip_new': return Icons.directions_car_rounded;
      case 'trip_accepted': return Icons.check_circle_rounded;
      case 'trip_completed': return Icons.flag_rounded;
      case 'trip_cancelled': return Icons.cancel_rounded;
      case 'payment': return Icons.payment_rounded;
      case 'promo': return Icons.local_offer_rounded;
      case 'wallet': return Icons.account_balance_wallet_rounded;
      default: return Icons.notifications_rounded;
    }
  }

  Color _colorForType(String? type) {
    switch (type) {
      case 'trip_accepted': return Colors.green;
      case 'trip_completed': return Colors.teal;
      case 'trip_cancelled': return Colors.red;
      case 'payment': case 'wallet': return Colors.blue;
      case 'promo': return Colors.orange;
      default: return _blue;
    }
  }

  String _timeAgo(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'ఇప్పుడే';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFF);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final subColor = isDark ? Colors.white54 : Colors.grey.shade600;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: _blue,
        foregroundColor: Colors.white,
        title: const Text('Notifications', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        actions: [
          if (_notifications.isNotEmpty)
            TextButton(
              onPressed: _markAllRead,
              child: const Text('అన్నీ చదివాను', style: TextStyle(color: Colors.white70, fontSize: 12)),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF2F80ED)))
          : _notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_none_rounded, size: 80, color: subColor),
                      const SizedBox(height: 16),
                      Text('Notifications లేవు', style: TextStyle(color: subColor, fontSize: 16)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetch,
                  color: _blue,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: _notifications.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final n = _notifications[i] as Map<String, dynamic>;
                      final isRead = n['is_read'] == true || n['isRead'] == true;
                      final type = n['type']?.toString();
                      final color = _colorForType(type);
                      return Container(
                        decoration: BoxDecoration(
                          color: isRead ? cardBg : (isDark ? _blue.withValues(alpha: 0.08) : const Color(0xFFEFF6FF)),
                          borderRadius: BorderRadius.circular(14),
                          border: isRead ? null : Border.all(color: _blue.withValues(alpha: 0.2)),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          leading: Container(
                            width: 42, height: 42,
                            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                            child: Icon(_iconForType(type), color: color, size: 22),
                          ),
                          title: Text(
                            n['title']?.toString() ?? '',
                            style: TextStyle(fontWeight: isRead ? FontWeight.w500 : FontWeight.bold, color: textColor, fontSize: 14),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 2),
                              Text(n['body']?.toString() ?? n['message']?.toString() ?? '',
                                  style: TextStyle(color: subColor, fontSize: 12)),
                              const SizedBox(height: 4),
                              Text(_timeAgo(n['created_at']?.toString() ?? n['createdAt']?.toString()),
                                  style: TextStyle(color: subColor, fontSize: 11)),
                            ],
                          ),
                          trailing: !isRead
                              ? Container(width: 8, height: 8,
                                  decoration: const BoxDecoration(color: Color(0xFF2F80ED), shape: BoxShape.circle))
                              : null,
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
