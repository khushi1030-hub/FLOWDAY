import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import '../../../core/providers/database_providers.dart';
import '../../../core/providers/notification_providers.dart';
import '../../../core/theme/flow_colors.dart';
import '../../../core/widgets/flow_buttons.dart';

/// Screen 06: Notification Permissions Rationale Screen
class PermissionsScreen extends ConsumerStatefulWidget {
  const PermissionsScreen({super.key});

  @override
  ConsumerState<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends ConsumerState<PermissionsScreen> {
  bool _isLoading = false;

  Future<void> _completeOnboarding() async {
    final settingsRepo = ref.read(settingsRepositoryProvider);
    final current = await settingsRepo.getSettings();
    await settingsRepo.updateSettings(current.copyWith(onboardingDone: true));

    if (mounted) {
      context.go('/home');
    }
  }

  Future<void> _requestPermission() async {
    setState(() => _isLoading = true);
    try {
      final gateway = ref.read(notificationGatewayProvider);
      await gateway.requestNotificationPermission();
    } catch (_) {
      // Permission request failure or cancellation must not crash the flow
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        await _completeOnboarding();
      }
    }
  }

  Future<void> _onSkip() async {
    await _completeOnboarding();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FlowColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar: Back button, 100% progress line, "2 of 2"
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Colors.white),
                    onPressed: () => context.go('/onboarding/personalize'),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        height: 4,
                        color: FlowColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Text('2 of 2', style: TextStyle(fontSize: 12, color: Color(0xFF71717A), fontWeight: FontWeight.w600)),
                ],
              ),
            ),

            // Scrollable body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Column(
                  children: [
                  // Hero Graphic
                  Center(
                    child: Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        // Sound wave outer rings
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: FlowColors.primary.withValues(alpha: 0.2), width: 1.5),
                          ),
                        ),
                        Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF1E1A36),
                            border: Border.all(color: const Color(0xFF352F5C), width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: FlowColors.primary.withValues(alpha: 0.25),
                                blurRadius: 20,
                              ),
                            ],
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              const Icon(Icons.notifications_active_rounded, size: 40, color: FlowColors.primaryLight),
                              Positioned(
                                top: 22,
                                right: 24,
                                child: Container(
                                  width: 10,
                                  height: 10,
                                  decoration: const BoxDecoration(
                                    color: FlowColors.error,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Floating Chip 1: DSA reminder
                        Positioned(
                          top: -6,
                          left: -40,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF18152B),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFF2E2850), width: 1),
                              boxShadow: const [
                                BoxShadow(color: Colors.black45, blurRadius: 8),
                              ],
                            ),
                            child: const Text('▶ DSA starts in 5 min', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                          ),
                        ),

                        // Floating Chip 2: Review tomorrow
                        Positioned(
                          bottom: -6,
                          right: -30,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF18152B),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFF2E2850), width: 1),
                              boxShadow: const [
                                BoxShadow(color: Colors.black45, blurRadius: 8),
                              ],
                            ),
                            child: const Text('🌙 Review tomorrow?', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: FlowColors.warning)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Header & Subtitle
                  const Text(
                    'Never miss an\nimportant moment.',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'FlowDay uses notifications and alarms to keep your day gently on track — only when it matters.',
                    style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF), height: 1.4),
                  ),
                  const SizedBox(height: 24),

                  // 3 Rationale Cards
                  _buildRationaleCard(
                    icon: Icons.alarm_rounded,
                    iconBg: const Color(0xFF252048),
                    iconColor: FlowColors.primaryLight,
                    title: 'Task reminders',
                    subtitle: 'A heads-up before each task begins',
                  ),
                  const SizedBox(height: 12),
                  _buildRationaleCard(
                    icon: Icons.hourglass_top_rounded,
                    iconBg: const Color(0xFF381F26),
                    iconColor: FlowColors.error,
                    title: 'End-of-task alarms',
                    subtitle: 'Check in when your time is up — even when locked',
                  ),
                  const SizedBox(height: 12),
                  _buildRationaleCard(
                    icon: Icons.nights_stay_rounded,
                    iconBg: const Color(0xFF30271B),
                    iconColor: FlowColors.warning,
                    title: 'Nightly schedule review',
                    subtitle: 'A calm nudge to plan tomorrow at 09:30 PM',
                  ),
                  const SizedBox(height: 20),

                  // Privacy Note
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.shield_outlined, size: 14, color: Color(0xFF71717A)),
                      SizedBox(width: 6),
                      Text(
                        'No spam. You control every alert in Settings.',
                        style: TextStyle(fontSize: 11, color: Color(0xFF71717A)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // Actions: Enable Notifications & Skip
                  FlowPrimaryButton(
                    label: '🔔 Enable Notifications',
                    isLoading: _isLoading,
                    onPressed: _requestPermission,
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: TextButton(
                      onPressed: _onSkip,
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF71717A),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      child: const Text(
                        'Skip for now',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          ],
        ),
      ),
    );
  }

  Widget _buildRationaleCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF161424),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF262244), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
