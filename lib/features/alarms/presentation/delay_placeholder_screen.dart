import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/database_providers.dart';
import '../../../core/theme/flow_colors.dart';
import '../../../core/theme/flow_spacing.dart';
import '../../../core/theme/flow_typography.dart';
import '../../../core/widgets/flow_buttons.dart';

/// Placeholder screen for `/delay/:taskId` (Screen 14) arriving in Phase 8.
class DelayPlaceholderScreen extends ConsumerWidget {
  const DelayPlaceholderScreen({super.key, required this.taskId});

  final String taskId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final taskRepo = ref.watch(taskRepositoryProvider);

    return Scaffold(
      backgroundColor: FlowColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: FlowColors.textPrimary),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/schedule');
            }
          },
        ),
        title: const Text('Delay Management', style: FlowTypography.headlineMedium),
      ),
      body: FutureBuilder(
        future: taskRepo.getTaskById(taskId),
        builder: (context, snapshot) {
          final task = snapshot.data;
          final title = task?.title ?? 'Task';

          return Padding(
            padding: const EdgeInsets.all(FlowSpacing.space24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: FlowColors.error.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.hourglass_bottom_rounded,
                      color: FlowColors.error,
                      size: 40,
                    ),
                  ),
                ),
                const SizedBox(height: FlowSpacing.space24),
                Text(
                  title,
                  style: FlowTypography.headlineLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: FlowSpacing.space12),
                const Text(
                  'Smart delay management and schedule adjustment arrive in Phase 8.\n\nYour task remains marked as incomplete so you can adjust your schedule.',
                  style: FlowTypography.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: FlowSpacing.space32),
                FlowPrimaryButton(
                  label: 'Back to Schedule',
                  icon: const Icon(Icons.calendar_today, size: 18),
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/schedule');
                    }
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
