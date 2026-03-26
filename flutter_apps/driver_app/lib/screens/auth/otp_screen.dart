import 'dart:async';
import 'package:flutter/material.dart';
import '../../config/jago_theme.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../../services/auth_service.dart';
import '../../services/firebase_otp_service.dart';
import '../home/home_screen.dart';

class OtpScreen extends StatefulWidget {
  final String phone;
  final String otp;
  final String? firebaseVerificationId;
  const OtpScreen({super.key, required this.phone, required this.otp, this.firebaseVerificationId});
  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> with SingleTickerProviderStateMixin {
  final _otpCtrl = TextEditingController();
  bool _loading = false;
  int _seconds = 30;
  Timer? _timer;
  String? _verificationId;
  bool _hasError = false;

  late AnimationController _slideCtrl;
  late Animation<Offset> _slideAnim;

  static const Color _blue = Color(0xFF2F7BFF);

  @override
  void initState() {
    super.initState();
    _verificationId = widget.firebaseVerificationId;
    _startTimer();

    _slideCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 550));
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero)
        .animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOutCubic));
    Future.delayed(const Duration(milliseconds: 50), () {
      if (mounted) _slideCtrl.forward();
    });
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _seconds = 30);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_seconds == 0) { t.cancel(); return; }
      if (mounted) setState(() => _seconds--);
    });
  }

  Future<void> _verify() async {
    if (_otpCtrl.text.length != 6) return;
    setState(() { _loading = true; _hasError = false; });

    if (_verificationId != null) {
      // Firebase path
      try {
        final idToken = await FirebaseOtpService.verifyOtp(
          smsCode: _otpCtrl.text,
          verificationId: _verificationId,
        );
        final res = await AuthService.verifyFirebaseToken(idToken, widget.phone, 'driver');
        setState(() => _loading = false);
        if (!mounted) return;
        if (res['success'] == true) {
          Navigator.pushAndRemoveUntil(context,
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => const HomeScreen(),
              transitionDuration: const Duration(milliseconds: 400),
              transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
            ),
            (_) => false);
        } else {
          _showSnack(res['message'] ?? 'Verification failed. Try again.', error: true);
          setState(() => _hasError = true);
          _otpCtrl.clear();
        }
      } catch (e) {
        setState(() { _loading = false; _hasError = true; });
        _showSnack(e.toString().replaceAll('Exception: ', ''), error: true);
        _otpCtrl.clear();
      }
    } else {
      // Firebase verification ID not available — ask user to retry
      setState(() => _loading = false);
      _showSnack('Session expired. Please go back and request a new OTP.', error: true);
      setState(() => _hasError = true);
    }
  }

  void _showSnack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.white, fontSize: 13)),
      backgroundColor: error ? const Color(0xFFEF4444) : _blue,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 3),
    ));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpCtrl.dispose();
    _slideCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFF1A3A70),
        body: Stack(
          children: [
            // ── Dark gradient hero background ──
            Positioned(
              top: 0, left: 0, right: 0,
              height: size.height * 0.42,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF0D1B3E), Color(0xFF1A3A70)],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(top: -50, right: -50,
                      child: Container(width: 180, height: 180,
                        decoration: BoxDecoration(shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.04)))),
                    Positioned(bottom: 10, left: -40,
                      child: Container(width: 140, height: 140,
                        decoration: BoxDecoration(shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.03)))),
                    // Back button
                    Positioned(
                      top: MediaQuery.of(context).padding.top + 8,
                      left: 8,
                      child: IconButton(
                        icon: Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white.withValues(alpha: 0.85), size: 22),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    // Hero content
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 24),
                          Container(
                            width: 72, height: 72,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [JT.primary, Color(0xFF1A3A70)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: _blue.withValues(alpha: 0.4),
                                  blurRadius: 20,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.lock_open_rounded, color: Colors.white, size: 36),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'OTP Verification',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Code sent to +91 ${widget.phone}',
                            style: GoogleFonts.poppins(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Bottom card (dark) ──
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: SlideTransition(
                position: _slideAnim,
                child: Container(
                  constraints: BoxConstraints(minHeight: size.height * 0.60),
                  decoration: const BoxDecoration(
                    color: Color(0xFF111827),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                    boxShadow: [
                      BoxShadow(color: Color(0x33000000), blurRadius: 32, offset: Offset(0, -8)),
                    ],
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(28, 28, 28, 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Drag handle
                        Center(
                          child: Container(
                            width: 40, height: 4,
                            margin: const EdgeInsets.only(bottom: 24),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),

                        // Pilot badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: _blue.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            const Icon(Icons.directions_bike_rounded, color: _blue, size: 14),
                            const SizedBox(width: 6),
                            Text('Pilot App', style: GoogleFonts.poppins(color: _blue, fontWeight: FontWeight.w700, fontSize: 12)),
                          ]),
                        ),
                        const SizedBox(height: 14),

                        Text(
                          'Enter 6-digit OTP',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Check your SMS for the verification code',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.45),
                          ),
                        ),

                        const SizedBox(height: 32),

                        // OTP PIN input
                        PinCodeTextField(
                          appContext: context,
                          length: 6,
                          controller: _otpCtrl,
                          keyboardType: TextInputType.number,
                          animationType: AnimationType.scale,
                          pinTheme: PinTheme(
                            shape: PinCodeFieldShape.box,
                            borderRadius: BorderRadius.circular(14),
                            fieldHeight: 56,
                            fieldWidth: 48,
                            activeFillColor: Colors.white.withValues(alpha: 0.08),
                            inactiveFillColor: Colors.white.withValues(alpha: 0.05),
                            selectedFillColor: _blue.withValues(alpha: 0.15),
                            activeColor: _blue,
                            inactiveColor: _hasError
                              ? const Color(0xFFEF4444)
                              : Colors.white.withValues(alpha: 0.15),
                            selectedColor: _blue,
                            errorBorderColor: const Color(0xFFEF4444),
                            borderWidth: 1.5,
                          ),
                          enableActiveFill: true,
                          textStyle: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                          onCompleted: (_) => _verify(),
                          onChanged: (v) {
                            if (_hasError && v.isNotEmpty) setState(() => _hasError = false);
                          },
                        ),

                        const SizedBox(height: 12),

                        // Timer / resend
                        Center(
                          child: _seconds > 0
                            ? RichText(
                                text: TextSpan(
                                  style: GoogleFonts.poppins(fontSize: 13, color: Colors.white.withValues(alpha: 0.4)),
                                  children: [
                                    const TextSpan(text: 'Resend OTP in '),
                                    TextSpan(
                                      text: '${_seconds}s',
                                      style: GoogleFonts.poppins(
                                        color: _blue,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : GestureDetector(
                                onTap: () async {
                                  _otpCtrl.clear();
                                  setState(() => _hasError = false);
                                  _startTimer();
                                  FirebaseOtpService.sendOtp(
                                    phoneNumber: '+91${widget.phone}',
                                    forceResend: true,
                                    onCodeSent: (vId) => setState(() => _verificationId = vId),
                                    onError: (e) {
                                      _showSnack('OTP send failed. Check your phone number and try again.', error: true);
                                    },
                                  );
                                },
                                child: Text(
                                  'Resend OTP',
                                  style: GoogleFonts.poppins(
                                    color: _blue,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                        ),

                        const SizedBox(height: 32),

                        // Verify button
                        SizedBox(
                          width: double.infinity,
                          height: 58,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: _loading ? null : const LinearGradient(
                                colors: [JT.primary, Color(0xFF0D3F8F)],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              color: _loading ? _blue.withValues(alpha: 0.4) : null,
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: _loading ? [] : [
                                BoxShadow(
                                  color: _blue.withValues(alpha: 0.45),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: _loading ? null : _verify,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                disabledBackgroundColor: Colors.transparent,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                                elevation: 0,
                              ),
                              child: _loading
                                ? const SizedBox(width: 24, height: 24,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                                : Text(
                                    'Verify & Continue',
                                    style: GoogleFonts.poppins(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                      letterSpacing: 0.1,
                                    ),
                                  ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        Center(
                          child: GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Text(
                              '← Change Phone Number',
                              style: GoogleFonts.poppins(
                                color: Colors.white.withValues(alpha: 0.4),
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
