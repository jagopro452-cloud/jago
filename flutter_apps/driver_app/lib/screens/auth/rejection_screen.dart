import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'register_screen.dart';

class RejectionScreen extends StatelessWidget {
  final String? reason;
  final List<dynamic> rejectedDocs;

  const RejectionScreen({super.key, this.reason, this.rejectedDocs = const []});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0B0B),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Application Rejected', style: TextStyle(color: Colors.white)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(child: Icon(Icons.error_outline, size: 80, color: Color(0xFFEF4444))),
            const SizedBox(height: 24),
            const Text('Your application was not approved', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 8),
            Text(
              reason ?? 'Please review the comments below and re-upload the necessary documents.',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 15),
            ),
            const SizedBox(height: 32),
            const Text('Rejected Documents', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 16),
            ...rejectedDocs.map((doc) => _buildRejectedDocCard(doc)).toList(),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2F80ED), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                child: const Text('Re-upload Documents', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton(
                onPressed: () => _launchWhatsApp(),
                style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white24), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                child: const Text('Contact Support', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRejectedDocCard(dynamic doc) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(doc['docType']?.toString().toUpperCase() ?? 'DOCUMENT', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(doc['adminNote'] ?? 'No reason provided', style: const TextStyle(color: Color(0xFFEF4444), fontSize: 13)),
        ],
      ),
    );
  }

  void _launchWhatsApp() async {
    final url = Uri.parse('https://wa.me/910000000000');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }
}
