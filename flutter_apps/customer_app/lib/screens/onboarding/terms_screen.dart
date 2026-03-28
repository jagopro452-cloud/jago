import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../auth/login_screen.dart';

class TermsScreen extends StatefulWidget {
  const TermsScreen({super.key});
  @override
  State<TermsScreen> createState() => _TermsScreenState();
}

class _TermsScreenState extends State<TermsScreen> {
  bool _agreed = false;
  bool _saving = false;

  Future<void> _accept() async {
    if (!_agreed) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please check the box to agree before continuing.'),
        backgroundColor: Color(0xFFDC2626),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    setState(() => _saving = true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('terms_accepted', true);
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0B0B0B) : Colors.white;
    final card = isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF5F8FF);
    final border = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFDCE9FF);
    final textPrimary = isDark ? Colors.white : const Color(0xFF0B0B0B);
    final textSecondary = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Text('Before you begin', style: GoogleFonts.poppins(fontSize: 26, fontWeight: FontWeight.w500, color: textPrimary)),
              const SizedBox(height: 8),
              Text('Please review our terms to continue using JAGO Pro.',
                  style: GoogleFonts.poppins(fontSize: 14, color: textSecondary)),
              const SizedBox(height: 32),

              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: border),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionTitle('Terms of Service', textPrimary),
                        _body('By using JAGO Pro, you agree to use the service lawfully and only for legitimate transportation needs. You must provide accurate pickup and destination information. Misuse or abuse of the platform will result in account suspension.', textSecondary),
                        const SizedBox(height: 16),
                        _sectionTitle('Payments & Cancellations', textPrimary),
                        _body('Wallet balance deducted for rides is non-refundable except in cases of driver no-show or technical failure. Cancelling after a driver is assigned will incur a small cancellation fee. Unused wallet balance can be refunded on account closure upon request.', textSecondary),
                        const SizedBox(height: 16),
                        _sectionTitle('Safety', textPrimary),
                        _body('Always verify the vehicle number and driver details before boarding. Use the SOS feature in emergencies. Share your ride with trusted contacts using the ride-share link for your safety.', textSecondary),
                        const SizedBox(height: 16),
                        _sectionTitle('Data & Privacy', textPrimary),
                        _body('We collect your location, trip history, and device information to provide and improve our services. Your phone number is used for ride coordination and support. We never sell your personal data to third parties.', textSecondary),
                        const SizedBox(height: 20),
                        Row(children: [
                          GestureDetector(
                            onTap: () => _openUrl('https://jagopro.in/privacy-policy'),
                            child: Text('Privacy Policy', style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF2F80ED), decoration: TextDecoration.underline)),
                          ),
                          const SizedBox(width: 16),
                          GestureDetector(
                            onTap: () => _openUrl('https://jagopro.in/terms'),
                            child: Text('Full Terms', style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF2F80ED), decoration: TextDecoration.underline)),
                          ),
                        ]),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),
              GestureDetector(
                onTap: () => setState(() => _agreed = !_agreed),
                child: Row(children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 22, height: 22,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      color: _agreed ? const Color(0xFF2F80ED) : Colors.transparent,
                      border: Border.all(color: _agreed ? const Color(0xFF2F80ED) : const Color(0xFF9CA3AF), width: 2),
                    ),
                    child: _agreed ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text('I have read and agree to the Terms of Service and Privacy Policy',
                    style: GoogleFonts.poppins(fontSize: 13, color: textSecondary))),
                ]),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _accept,
                  child: _saving
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                      : Text('Accept & Continue', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String text, Color color) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(text, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: color)),
  );

  Widget _body(String text, Color color) => Text(text,
    style: GoogleFonts.poppins(fontSize: 13, color: color, height: 1.6));
}
