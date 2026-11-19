import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import '../../../core/providers/database_providers.dart';
import '../../../core/theme/flow_colors.dart';

/// Screen 01: Branded Splash Screen with animated logo, tagline, and router redirection.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeIn),
    );

    _animController.forward();
    _checkRedirect();
  }

  Future<void> _checkRedirect() async {
    // Wait for animation & initialization
    await Future.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;

    try {
      final settingsRepo = ref.read(settingsRepositoryProvider);
      final settings = await settingsRepo.getSettings();

      if (!mounted) return;

      // If a notification or intent already navigated to another screen (e.g. /alarm/:id), don't overwrite it!
      final currentLoc = GoRouter.of(context).state.matchedLocation;
      if (currentLoc != '/splash') return;

      if (settings.onboardingDone) {
        context.go('/home');
      } else {
        context.go('/onboarding/1');
      }
    } catch (_) {
      if (mounted) {
        context.go('/onboarding/1');
      }
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FlowColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background subtle ambient radial glow
          Positioned(
            top: MediaQuery.of(context).size.height * 0.25,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      FlowColors.primary.withValues(alpha: 0.15),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Central content: Logo, Title, Subtitle, Pulsing Dots
          Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Centered Logo Squircle (96x96dp)
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: const Color(0xFF181528),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: const Color(0xFF2E284A), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: FlowColors.primary.withValues(alpha: 0.2),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: CustomPaint(
                        size: const Size(48, 48),
                        painter: _SplashLogoPainter(),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // App Name: Flow (white) + Day (lavender)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text(
                          'Flow',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text(
                          'Day',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w700,
                            color: FlowColors.primaryLight,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Subtitle
                    const Text(
                      'Make time for what matters.',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF8E8CA3),
                      ),
                    ),
                    const SizedBox(height: 48),

                    // 3 Pulsing Dots Loading Indicator
                    const _PulsingDots(),
                  ],
                ),
              ),
            ),
          ),

          // Pinned Bottom Tagline
          Positioned(
            bottom: 32 + MediaQuery.of(context).padding.bottom,
            left: 20,
            right: 20,
            child: const Text(
              'PLAN SMART · STAY FLEXIBLE · FLOW BETTER',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF44415C),
                letterSpacing: 2.0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for the clock squircle with checkmark and top dot.
class _SplashLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;

    final circlePaint = Paint()
      ..color = FlowColors.primaryLight
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    // Draw open clock arc (from ~-60 deg to ~220 deg)
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -1.0,
      5.2,
      false,
      circlePaint,
    );

    // Draw center checkmark
    final checkPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path()
      ..moveTo(center.dx - 9, center.dy)
      ..lineTo(center.dx - 2, center.dy + 7)
      ..lineTo(center.dx + 10, center.dy - 6);

    canvas.drawPath(path, checkPaint);

    // Top dot at 12 o'clock
    final dotPaint = Paint()
      ..color = FlowColors.primaryLight
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(center.dx, center.dy - radius), 2.5, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Three animated pulsing dots
class _PulsingDots extends StatefulWidget {
  const _PulsingDots();

  @override
  State<_PulsingDots> createState() => _PulsingDotsState();
}

class _PulsingDotsState extends State<_PulsingDots> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final delay = index * 0.25;
            final progress = (_controller.value - delay) % 1.0;
            final scale = (progress < 0.5) ? 0.7 + (progress * 0.6) : 1.0 - ((progress - 0.5) * 0.6);
            final opacity = (progress < 0.5) ? 0.4 + (progress * 1.2) : 1.0 - ((progress - 0.5) * 1.2);

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 7 * scale,
              height: 7 * scale,
              decoration: BoxDecoration(
                color: FlowColors.primaryLight.withValues(alpha: opacity.clamp(0.2, 1.0)),
                shape: BoxShape.circle,
              ),
            );
          }),
        );
      },
    );
  }
}
