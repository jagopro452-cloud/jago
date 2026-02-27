import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jago_user_app/features/spin_wheel/controllers/spin_wheel_controller.dart';
import 'package:jago_user_app/util/dimensions.dart';
import 'package:jago_user_app/util/styles.dart';

class SpinWheelScreen extends StatefulWidget {
  final String? tripRequestId;
  const SpinWheelScreen({super.key, this.tripRequestId});

  @override
  State<SpinWheelScreen> createState() => _SpinWheelScreenState();
}

class _SpinWheelScreenState extends State<SpinWheelScreen> with TickerProviderStateMixin {
  late AnimationController _wheelController;
  late AnimationController _pulseController;
  late AnimationController _glowController;
  late AnimationController _confettiController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _glowAnimation;
  double _currentAngle = 0;
  bool _hasSpun = false;
  bool _showResult = false;
  Map<String, dynamic>? _winResult;
  final List<_ConfettiParticle> _confettiParticles = [];
  final Random _random = Random();

  static const Color _jagoPrimary = Color(0xFF2563EB);
  static const Color _jagoDark = Color(0xFF1E3A8A);
  static const Color _jagoDeep = Color(0xFF0F172A);
  static const Color _jagoAccent = Color(0xFF3B82F6);

  static const List<Color> _wheelColors = [
    Color(0xFF2563EB),
    Color(0xFF10B981),
    Color(0xFFEF4444),
    Color(0xFFF59E0B),
    Color(0xFF8B5CF6),
    Color(0xFF06B6D4),
    Color(0xFFEC4899),
    Color(0xFFF97316),
  ];

  @override
  void initState() {
    super.initState();
    _wheelController = AnimationController(vsync: this, duration: const Duration(seconds: 5));
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat(reverse: true);
    _glowController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _confettiController = AnimationController(vsync: this, duration: const Duration(seconds: 3));

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));
    _glowAnimation = Tween<double>(begin: 0.3, end: 0.7).animate(CurvedAnimation(parent: _glowController, curve: Curves.easeInOut));

    Get.find<SpinWheelController>().getConfig();
    Get.find<SpinWheelController>().getHistory();
  }

  @override
  void dispose() {
    _wheelController.dispose();
    _pulseController.dispose();
    _glowController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  void _generateConfetti() {
    _confettiParticles.clear();
    for (int i = 0; i < 80; i++) {
      _confettiParticles.add(_ConfettiParticle(
        x: _random.nextDouble(),
        y: -_random.nextDouble() * 0.3,
        speed: 0.3 + _random.nextDouble() * 0.7,
        size: 4 + _random.nextDouble() * 8,
        color: _wheelColors[_random.nextInt(_wheelColors.length)],
        rotation: _random.nextDouble() * 2 * pi,
        rotationSpeed: (_random.nextDouble() - 0.5) * 6,
        swayAmount: 0.02 + _random.nextDouble() * 0.04,
        swaySpeed: 1 + _random.nextDouble() * 3,
        isCircle: _random.nextBool(),
      ));
    }
  }

  void _spinWheel() async {
    if (_hasSpun || Get.find<SpinWheelController>().isSpinning) return;

    final controller = Get.find<SpinWheelController>();
    int? winIndex = await controller.spin(widget.tripRequestId);
    if (winIndex == null) return;

    int segmentCount = controller.segments.length;
    if (segmentCount == 0) return;

    double segmentAngle = 2 * pi / segmentCount;
    double targetAngle = 2 * pi * 8 + (2 * pi - (winIndex * segmentAngle) - segmentAngle / 2);

    _wheelController.reset();
    Animation<double> spinAnimation = Tween<double>(
      begin: _currentAngle,
      end: targetAngle,
    ).animate(CurvedAnimation(parent: _wheelController, curve: Curves.easeOutCubic));

    _wheelController.addListener(() {
      _currentAngle = spinAnimation.value;
    });

    _wheelController.forward().then((_) {
      _currentAngle = targetAngle % (2 * pi);
      _hasSpun = true;
      _winResult = controller.lastResult;
      _generateConfetti();
      _confettiController.reset();
      _confettiController.forward();
      setState(() => _showResult = true);
    });

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: GetBuilder<SpinWheelController>(builder: (controller) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDark
                  ? [const Color(0xFF0A1628), const Color(0xFF0F172A), const Color(0xFF0A0F1C)]
                  : [_jagoDeep, _jagoDark, _jagoPrimary],
            ),
          ),
          child: Stack(
            children: [
              _buildBackgroundEffects(),
              SafeArea(
                child: controller.isLoading
                    ? const Center(child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Column(
                        children: [
                          _buildAppBar(controller),
                          Expanded(
                            child: SingleChildScrollView(
                              physics: const BouncingScrollPhysics(),
                              child: Column(
                                children: [
                                  const SizedBox(height: 12),
                                  _buildWheelSection(controller),
                                  const SizedBox(height: 24),
                                  _buildSpinButton(controller),
                                  const SizedBox(height: 28),
                                  if (controller.history.isNotEmpty) _buildHistorySection(controller),
                                  const SizedBox(height: 40),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
              if (_showResult) _buildResultOverlay(),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildBackgroundEffects() {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, _) {
        return Stack(
          children: [
            Positioned(
              top: -80, right: -60,
              child: Container(
                width: 260, height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [_jagoAccent.withValues(alpha: _glowAnimation.value * 0.15), Colors.transparent],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -100, left: -40,
              child: Container(
                width: 300, height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [const Color(0xFF8B5CF6).withValues(alpha: _glowAnimation.value * 0.1), Colors.transparent],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 200, left: -80,
              child: Container(
                width: 200, height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [const Color(0xFF10B981).withValues(alpha: _glowAnimation.value * 0.08), Colors.transparent],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAppBar(SpinWheelController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Get.back(),
            child: Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  controller.title.isNotEmpty ? controller.title : 'spin_and_win'.tr,
                  style: textBold.copyWith(color: Colors.white, fontSize: 20, letterSpacing: -0.3),
                ),
                if (controller.subtitle.isNotEmpty)
                  Text(
                    controller.subtitle,
                    style: textRegular.copyWith(color: Colors.white.withValues(alpha: 0.65), fontSize: 12),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Colors.white.withValues(alpha: 0.15), Colors.white.withValues(alpha: 0.05)]),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.stars_rounded, color: Color(0xFFF59E0B), size: 16),
                const SizedBox(width: 4),
                Text('rewards'.tr, style: textSemiBold.copyWith(color: Colors.white, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWheelSection(SpinWheelController controller) {
    final segments = controller.segments;
    final colors = controller.segmentColors;
    int segCount = segments.length;
    if (segCount == 0) segCount = 2;

    return AnimatedBuilder(
      animation: Listenable.merge([_wheelController, _pulseAnimation, _glowAnimation]),
      builder: (context, _) {
        return Column(
          children: [
            SizedBox(
              height: 340,
              width: 340,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 320, height: 320,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _jagoPrimary.withValues(alpha: _glowAnimation.value * 0.5),
                          blurRadius: 60, spreadRadius: 10,
                        ),
                        BoxShadow(
                          color: const Color(0xFF8B5CF6).withValues(alpha: _glowAnimation.value * 0.2),
                          blurRadius: 80, spreadRadius: 20,
                        ),
                      ],
                    ),
                  ),
                  Transform.scale(
                    scale: _wheelController.isAnimating ? 1.0 : _pulseAnimation.value,
                    child: SizedBox(
                      width: 310, height: 310,
                      child: CustomPaint(
                        painter: _PremiumOuterRingPainter(
                          dotCount: segCount * 4,
                          glowValue: _glowAnimation.value,
                        ),
                      ),
                    ),
                  ),
                  Transform.rotate(
                    angle: _currentAngle,
                    child: SizedBox(
                      width: 280, height: 280,
                      child: CustomPaint(
                        painter: _PremiumWheelPainter(
                          segments: segments.isNotEmpty ? segments : ['₹5', '₹10'],
                          colors: colors.isNotEmpty
                              ? colors.map((c) => _parseHexColor(c.toString())).toList()
                              : [_jagoPrimary, const Color(0xFF10B981)],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 2,
                    child: Container(
                      width: 30, height: 36,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFFDC2626), Color(0xFF991B1B)],
                        ),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(20),
                          bottomRight: Radius.circular(20),
                          topLeft: Radius.circular(4),
                          topRight: Radius.circular(4),
                        ),
                        boxShadow: [BoxShadow(color: Color(0x40000000), blurRadius: 8, offset: Offset(0, 3))],
                      ),
                      child: Center(
                        child: Container(
                          width: 8, height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: _hasSpun ? null : _spinWheel,
                    child: Container(
                      width: 64, height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFFFFFFFF), Color(0xFFF1F5F9)],
                        ),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 12, offset: const Offset(0, 4)),
                          BoxShadow(color: _jagoPrimary.withValues(alpha: 0.15), blurRadius: 20, spreadRadius: 2),
                        ],
                        border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 3),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _hasSpun ? Icons.check_rounded : Icons.touch_app_rounded,
                            color: _hasSpun ? const Color(0xFF10B981) : _jagoPrimary,
                            size: 22,
                          ),
                          Text(
                            _hasSpun ? 'done'.tr : 'SPIN',
                            style: textBold.copyWith(
                              color: _hasSpun ? const Color(0xFF10B981) : _jagoPrimary,
                              fontSize: 9,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSpinButton(SpinWheelController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, _) {
          return Transform.scale(
            scale: (_hasSpun || controller.isSpinning) ? 1.0 : _pulseAnimation.value,
            child: GestureDetector(
              onTap: _hasSpun ? null : _spinWheel,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: _hasSpun
                      ? LinearGradient(colors: [Colors.white.withValues(alpha: 0.08), Colors.white.withValues(alpha: 0.04)])
                      : const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFFF59E0B), Color(0xFFEF4444), Color(0xFFEC4899)],
                        ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _hasSpun ? Colors.white.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.25),
                    width: 1.5,
                  ),
                  boxShadow: _hasSpun ? null : [
                    BoxShadow(color: const Color(0xFFF59E0B).withValues(alpha: 0.35), blurRadius: 20, offset: const Offset(0, 8)),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _hasSpun ? Icons.check_circle_outline_rounded : Icons.rocket_launch_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _hasSpun ? 'already_spun'.tr : 'spin_now'.tr,
                      style: textBold.copyWith(color: Colors.white, fontSize: 16, letterSpacing: 0.5),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHistorySection(SpinWheelController controller) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 4),
            child: Row(
              children: [
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.history_rounded, color: Colors.white70, size: 18),
                ),
                const SizedBox(width: 10),
                Text('spin_history'.tr, style: textSemiBold.copyWith(color: Colors.white, fontSize: 15)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${controller.history.length} ${'spins'.tr}',
                    style: textMedium.copyWith(color: Colors.white60, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Divider(color: Colors.white10, height: 20),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: controller.history.length,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            itemBuilder: (context, index) {
              final item = controller.history[index];
              final amount = item['wallet_amount'] ?? 0;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42, height: 42,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFF10B981).withValues(alpha: 0.2),
                            const Color(0xFF10B981).withValues(alpha: 0.08),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.2)),
                      ),
                      child: const Icon(Icons.monetization_on_rounded, color: Color(0xFF10B981), size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '+₹$amount',
                            style: textBold.copyWith(color: const Color(0xFF10B981), fontSize: 16),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item['created_at'] ?? '',
                            style: textRegular.copyWith(color: Colors.white38, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'credited'.tr,
                        style: textSemiBold.copyWith(color: const Color(0xFF10B981), fontSize: 10),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildResultOverlay() {
    final amount = _winResult?['wallet_amount'] ?? 0;
    final message = _winResult?['message'] ?? '';

    return AnimatedBuilder(
      animation: _confettiController,
      builder: (context, _) {
        return GestureDetector(
          onTap: () {},
          child: Container(
            color: Colors.black.withValues(alpha: 0.7),
            child: Stack(
              children: [
                CustomPaint(
                  size: MediaQuery.of(context).size,
                  painter: _ConfettiPainter(
                    particles: _confettiParticles,
                    progress: _confettiController.value,
                  ),
                ),
                Center(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.elasticOut,
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: value,
                        child: child,
                      );
                    },
                    child: Container(
                      width: 320,
                      margin: const EdgeInsets.symmetric(horizontal: 32),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFFFFFFFF), Color(0xFFF8FAFC)],
                        ),
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(color: _jagoPrimary.withValues(alpha: 0.2), blurRadius: 40, spreadRadius: 5),
                          BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 20),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0xFF2563EB), Color(0xFF1E3A8A), Color(0xFF8B5CF6)],
                              ),
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(28),
                                topRight: Radius.circular(28),
                              ),
                            ),
                            child: Column(
                              children: [
                                const Text('🎉', style: TextStyle(fontSize: 48)),
                                const SizedBox(height: 6),
                                Text(
                                  'congratulations'.tr,
                                  style: textBold.copyWith(color: Colors.white, fontSize: 22, letterSpacing: -0.3),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(28, 28, 28, 24),
                            child: Column(
                              children: [
                                Text('you_won'.tr, style: textMedium.copyWith(color: const Color(0xFF64748B), fontSize: 14)),
                                const SizedBox(height: 8),
                                ShaderMask(
                                  shaderCallback: (bounds) => const LinearGradient(
                                    colors: [Color(0xFF2563EB), Color(0xFF8B5CF6)],
                                  ).createShader(bounds),
                                  child: Text(
                                    '₹$amount',
                                    style: textHeavy.copyWith(color: Colors.white, fontSize: 56, letterSpacing: -2, height: 1.1),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.2)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.account_balance_wallet_rounded, color: Color(0xFF10B981), size: 14),
                                      const SizedBox(width: 6),
                                      Text(
                                        'added_to_wallet'.tr,
                                        style: textSemiBold.copyWith(color: const Color(0xFF10B981), fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                                if (message.toString().isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  Text(
                                    message.toString(),
                                    style: textRegular.copyWith(color: const Color(0xFF94A3B8), fontSize: 13),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                                const SizedBox(height: 24),
                                GestureDetector(
                                  onTap: () {
                                    setState(() => _showResult = false);
                                    Get.find<SpinWheelController>().getHistory();
                                  },
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFF2563EB), Color(0xFF1E3A8A)],
                                      ),
                                      borderRadius: BorderRadius.circular(14),
                                      boxShadow: [
                                        BoxShadow(color: _jagoPrimary.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4)),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.thumb_up_alt_rounded, color: Colors.white, size: 18),
                                        const SizedBox(width: 8),
                                        Text(
                                          'awesome'.tr,
                                          style: textBold.copyWith(color: Colors.white, fontSize: 15),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
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

  Color _parseHexColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }
}

class _ConfettiParticle {
  final double x, y, speed, size, rotation, rotationSpeed, swayAmount, swaySpeed;
  final Color color;
  final bool isCircle;

  _ConfettiParticle({
    required this.x, required this.y, required this.speed, required this.size,
    required this.color, required this.rotation, required this.rotationSpeed,
    required this.swayAmount, required this.swaySpeed, required this.isCircle,
  });
}

class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiParticle> particles;
  final double progress;

  _ConfettiPainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final currentY = p.y + p.speed * progress * 1.5;
      if (currentY > 1.1) continue;
      final currentX = p.x + sin(progress * p.swaySpeed * 2 * pi) * p.swayAmount;
      final opacity = (1.0 - progress).clamp(0.0, 1.0);

      final paint = Paint()..color = p.color.withValues(alpha: opacity * 0.85);
      final offset = Offset(currentX * size.width, currentY * size.height);

      canvas.save();
      canvas.translate(offset.dx, offset.dy);
      canvas.rotate(p.rotation + p.rotationSpeed * progress);

      if (p.isCircle) {
        canvas.drawCircle(Offset.zero, p.size / 2, paint);
      } else {
        canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.6), paint);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) => oldDelegate.progress != progress;
}

class _PremiumOuterRingPainter extends CustomPainter {
  final int dotCount;
  final double glowValue;

  _PremiumOuterRingPainter({required this.dotCount, required this.glowValue});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final ringPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(center, radius, ringPaint);

    final innerRingPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, radius - 8, innerRingPaint);

    for (int i = 0; i < dotCount; i++) {
      final angle = (i / dotCount) * 2 * pi - pi / 2;
      final dx = center.dx + radius * cos(angle);
      final dy = center.dy + radius * sin(angle);
      final isHighlight = i % 4 == 0;
      final dotPaint = Paint()
        ..color = isHighlight
            ? Colors.white.withValues(alpha: 0.6 + glowValue * 0.4)
            : Colors.white.withValues(alpha: 0.2);
      canvas.drawCircle(Offset(dx, dy), isHighlight ? 3.5 : 2, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _PremiumOuterRingPainter oldDelegate) => oldDelegate.glowValue != glowValue;
}

class _PremiumWheelPainter extends CustomPainter {
  final List<dynamic> segments;
  final List<Color> colors;

  _PremiumWheelPainter({required this.segments, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final segmentCount = segments.length;
    if (segmentCount == 0) return;

    final sweepAngle = 2 * pi / segmentCount;
    final rect = Rect.fromCircle(center: center, radius: radius);

    for (int i = 0; i < segmentCount; i++) {
      final startAngle = i * sweepAngle - pi / 2;
      final color = colors[i % colors.length];
      final hsl = HSLColor.fromColor(color);

      final gradient = SweepGradient(
        center: Alignment.center,
        startAngle: startAngle,
        endAngle: startAngle + sweepAngle,
        colors: [
          hsl.withLightness((hsl.lightness + 0.08).clamp(0, 1)).toColor(),
          color,
          hsl.withLightness((hsl.lightness - 0.08).clamp(0, 1)).toColor(),
        ],
      );

      final paint = Paint()..shader = gradient.createShader(rect);
      canvas.drawArc(rect, startAngle, sweepAngle, true, paint);

      final borderPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawArc(rect, startAngle, sweepAngle, true, borderPaint);

      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(startAngle + sweepAngle / 2);

      final shadowPainter = TextPainter(
        text: TextSpan(
          text: segments[i].toString(),
          style: TextStyle(
            color: Colors.black.withValues(alpha: 0.25),
            fontSize: (180 / segmentCount).clamp(12.0, 28.0),
            fontWeight: FontWeight.w800,
            fontFamily: 'Poppins',
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      shadowPainter.layout();
      shadowPainter.paint(canvas, Offset(radius * 0.55 - shadowPainter.width / 2 + 1, -shadowPainter.height / 2 + 1));

      final textPainter = TextPainter(
        text: TextSpan(
          text: segments[i].toString(),
          style: TextStyle(
            color: Colors.white,
            fontSize: (180 / segmentCount).clamp(12.0, 28.0),
            fontWeight: FontWeight.w800,
            fontFamily: 'Poppins',
            shadows: const [Shadow(color: Color(0x40000000), blurRadius: 4, offset: Offset(0, 1))],
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(radius * 0.55 - textPainter.width / 2, -textPainter.height / 2));
      canvas.restore();
    }

    final outerBorderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(center, radius, outerBorderPaint);

    final innerCirclePaint = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFFFFFFFF), Color(0xFFF1F5F9)],
      ).createShader(Rect.fromCircle(center: center, radius: 22));
    canvas.drawCircle(center, 22, innerCirclePaint);

    final innerBorderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, 22, innerBorderPaint);
  }

  @override
  bool shouldRepaint(covariant _PremiumWheelPainter oldDelegate) => true;
}
