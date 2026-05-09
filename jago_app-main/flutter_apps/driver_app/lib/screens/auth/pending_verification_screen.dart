import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import '../../config/jago_theme.dart';
import '../../services/auth_service.dart';
import 'register_screen.dart';
import '../home/home_screen.dart';
import 'login_screen.dart';

class PendingVerificationScreen extends StatefulWidget {
  const PendingVerificationScreen({super.key});

  @override
  State<PendingVerificationScreen> createState() => _PendingVerificationScreenState();
}

class _PendingVerificationScreenState extends State<PendingVerificationScreen> {
  Timer? _timer;
  Map<String, dynamic>? _data;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchStatus();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _fetchStatus());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchStatus() async {
    try {
      final headers = await AuthService.getHeaders();
      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/app/driver/verification-status'),
        headers: headers,
      ).timeout(const Duration(seconds: 20));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (mounted) {
          setState(() {
            _data = data;
            _loading = false;
            _error = null;
          });
          if (data['verificationStatus'] == 'approved') {
            _timer?.cancel();
          }
        }
      } else {
        String msg = 'Unable to load verification status right now.';
        try {
          if ((res.headers['content-type'] ?? '').contains('application/json')) {
            final data = jsonDecode(res.body);
            msg = (data['message'] ?? msg).toString();
          }
        } catch (_) {}
        if (mounted) {
          setState(() {
            _loading = false;
            _error = msg;
          });
        }
      }
    } on TimeoutException {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Verification status request timed out. Please try again.';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Unable to reach the server. Please check your connection and retry.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = _data?['verificationStatus'] ?? 'pending';
    final name = _data?['fullName'] ?? _data?['full_name'] ?? 'Pilot';
    final phone = _data?['phone']?.toString() ?? '';
    final city = _data?['city']?.toString() ?? '';
    final vehicleNumber = _data?['vehicleNumber']?.toString() ?? _data?['vehicle_number']?.toString() ?? '';
    final vehicleBrand = _data?['vehicleBrand']?.toString() ?? _data?['vehicle_brand']?.toString() ?? '';
    final vehicleModel = _data?['vehicleModel']?.toString() ?? _data?['vehicle_model']?.toString() ?? '';
    final licenseNumber = _data?['licenseNumber']?.toString() ?? _data?['license_number']?.toString() ?? '';
    final docs = (_data?['documents'] as List?) ?? [];
    final rejectionNote = _data?['rejectionNote'] ?? _data?['rejection_note'];

    return Scaffold(
      backgroundColor: JT.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Verification', style: TextStyle(fontWeight: FontWeight.w500, color: JT.textPrimary)),
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: JT.textPrimary),
            onPressed: () async {
              await AuthService.logout();
              if (!mounted) return;
              Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
            },
          )
        ],
      ),
      body: _loading
        ? Center(child: CircularProgressIndicator(color: JT.primary))
        : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 42),
                    const SizedBox(height: 16),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: JT.textPrimary, fontSize: 15, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _loading = true;
                          _error = null;
                        });
                        _fetchStatus();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: JT.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
        : SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 20),
                Center(child: JT.logoBlue(height: 60)),
                const SizedBox(height: 32),
                Text(
                  status == 'approved' ? 'Account Approved!' : (status == 'rejected' ? 'Verification Rejected' : 'Account Under Review'),
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w500, color: JT.textPrimary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Hello $name, your account is currently being verified by our team.',
                  style: TextStyle(color: JT.textSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                if (status == 'approved')
                  _buildStatusBanner(
                    'Your account has been approved. You can now start earning!',
                    const Color(0xFF22C55E),
                    () => Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const HomeScreen()), (_) => false),
                    'Start Driving!',
                  )
                else if (status == 'rejected')
                  _buildStatusBanner(
                    'Reason: ${rejectionNote ?? "Please re-upload documents"}',
                    const Color(0xFFEF4444),
                    () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                    'Re-upload Documents',
                  ),
                const SizedBox(height: 32),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Document Status', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: JT.textPrimary)),
                ),
                const SizedBox(height: 16),
                _buildInfoCard(name, phone, city, vehicleNumber, vehicleBrand, vehicleModel, licenseNumber),
                const SizedBox(height: 20),
                ...docs.map((doc) => _buildDocTile(doc)).toList(),
              ],
            ),
          ),
    );
  }

  Widget _buildInfoCard(
    String name,
    String phone,
    String city,
    String vehicleNumber,
    String vehicleBrand,
    String vehicleModel,
    String licenseNumber,
  ) {
    final rows = <Map<String, String>>[
      {'label': 'Name', 'value': name},
      if (phone.isNotEmpty) {'label': 'Phone', 'value': phone},
      if (city.isNotEmpty) {'label': 'City', 'value': city},
      if (vehicleNumber.isNotEmpty) {'label': 'Vehicle Number', 'value': vehicleNumber},
      if (vehicleBrand.isNotEmpty || vehicleModel.isNotEmpty) {'label': 'Vehicle', 'value': [vehicleBrand, vehicleModel].where((e) => e.isNotEmpty).join(' ')},
      if (licenseNumber.isNotEmpty) {'label': 'License Number', 'value': licenseNumber},
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: JT.surfaceAlt,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: JT.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Submitted Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: JT.textPrimary)),
          const SizedBox(height: 12),
          ...rows.map((row) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 116,
                  child: Text(
                    row['label']!,
                    style: TextStyle(color: JT.textSecondary, fontSize: 13, fontWeight: FontWeight.w400),
                  ),
                ),
                Expanded(
                  child: Text(
                    row['value']!,
                    style: TextStyle(color: JT.textPrimary, fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildStatusBanner(String message, Color color, VoidCallback onTap, String btnText) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(message, style: TextStyle(color: color, fontWeight: FontWeight.w500), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: Text(btnText),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildDocTile(Map<String, dynamic> doc) {
    final type = doc['docType'];
    final status = doc['status'];
    final note = doc['adminNote'];

    final labels = {
      'dl_front': 'DL Front',
      'dl_back': 'DL Back',
      'rc': 'RC Book',
      'aadhar_front': 'Aadhar Front',
      'aadhar_back': 'Aadhar Back',
      'insurance': 'Insurance',
      'selfie': 'Selfie',
      'vehicle_photo': 'Vehicle Photo',
    };

    Color statusColor = Colors.orange;
    if (status == 'approved') statusColor = const Color(0xFF22C55E);
    if (status == 'rejected') statusColor = const Color(0xFFEF4444);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: JT.surfaceAlt, borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(Icons.description, color: statusColor),
        title: Text(labels[type] ?? type, style: TextStyle(color: JT.textPrimary, fontWeight: FontWeight.w400)),
        subtitle: note != null ? Text(note, style: TextStyle(color: Colors.red.shade300, fontSize: 12)) : null,
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
          child: Text(
            status.toString().toUpperCase(),
            style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w500),
          ),
        ),
      ),
    );
  }
}
