import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import '../../../../core/providers/database_providers.dart';
import '../../../../core/theme/flow_colors.dart';
import '../../../../core/theme/flow_spacing.dart';
import '../../../../core/theme/flow_typography.dart';
import '../../../../core/widgets/flow_empty_state.dart';
import '../../tasks/domain/entities/task.dart';
import '../../tasks/presentation/widgets/category_selector.dart';
import '../../tasks/presentation/widgets/swipeable_task_card.dart';
import 'providers/home_providers.dart';
import 'widgets/daily_progress_card.dart';
import 'widgets/home_header.dart';
import 'widgets/now_task_card.dart';

/// Screen 07: Home Dashboard with greeting, live progress ring, NOW card, and timeline list.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  Future<void> _onCompleteTask(BuildContext context, WidgetRef ref, Task task) async {
    final clock = ref.read(clockProvider);
    final nowMs = clock.now().millisecondsSinceEpoch;
    final taskRepo = ref.read(taskRepositoryProvider);
    await taskRepo.markCompleted(task.id, nowMs);

    if (context.mounted) {
      try {
        context.push('/completed/${task.id}');
      } catch (_) {
        // Safe fallback when GoRouter is not in widget test harness
      }
    }
  }

  Future<void> _onIncompleteTask(BuildContext context, WidgetRef ref, Task task) async {
    final taskRepo = ref.read(taskRepositoryProvider);
    await taskRepo.markIncomplete(task.id);

    if (context.mounted) {
      try {
        context.push('/delay/${task.id}');
      } catch (_) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Adjust task: Smart rescheduling coming in Phase 8'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(homeDashboardProvider);
    final clock = ref.watch(clockProvider);
    final tickAsync = ref.watch(minuteTickProvider);
    final now = tickAsync.value ?? clock.now();
    final currentMinutes = now.hour * 60 + now.minute;

    return Scaffold(
      backgroundColor: FlowColors.background,
      floatingActionButton: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: FlowColors.primary,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
              color: FlowColors.primaryGlow,
              blurRadius: 16,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: IconButton(
          icon: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
          onPressed: () => context.push('/task/new'),
        ),
      ),
      body: SafeArea(
        child: dashboardAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: FlowColors.primary),
          ),
          error: (error, _) => Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(FlowSpacing.space24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline_rounded, color: FlowColors.error, size: 48),
                  const SizedBox(height: FlowSpacing.space16),
                  Text(
                    'Unable to load schedule',
                    style: FlowTypography.headlineMedium.copyWith(color: FlowColors.textPrimary),
                  ),
                  const SizedBox(height: FlowSpacing.space8),
                  Text(
                    error is UnimplementedError ? 'Database initializing...' : '$error',
                    style: FlowTypography.bodyMedium.copyWith(color: FlowColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: FlowSpacing.space16),
                  ElevatedButton(
                    onPressed: () => ref.invalidate(homeDashboardProvider),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
          data: (state) {
            return RefreshIndicator(
              color: FlowColors.primary,
              backgroundColor: FlowColors.surface,
              onRefresh: () async {
                ref.invalidate(homeDashboardProvider);
              },
              child: ListView(
                padding: const EdgeInsets.only(bottom: 96),
                children: [
                  // Top Bar
                  HomeHeader(
                    formattedDate: state.formattedDate,
                    greeting: state.greeting,
                    userName: state.userName,
                  ),
                  const SizedBox(height: FlowSpacing.space12),

                  // Progress Summary Card
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: FlowSpacing.space16),
                    child: DailyProgressCard(state: state),
                  ),
                  const SizedBox(height: FlowSpacing.space20),

                  // Empty Day State OR Active Schedule Section
                  if (state.totalCount == 0) ...[
                    const SizedBox(height: FlowSpacing.space24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: FlowSpacing.space16),
                      child: FlowEmptyState(
                        title: 'No tasks scheduled',
                        description: 'Your day is open and free. Tap + below to add your first task.',
                        icon: Icons.calendar_today_outlined,
                        buttonLabel: '+ Add First Task',
                        onButtonPressed: () => context.push('/task/new'),
                      ),
                    ),
                  ] else ...[
                    // Prominent NOW Card (when present)
                    if (state.nowTask != null) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: FlowSpacing.space16),
                        child: NowTaskCard(
                          task: state.nowTask!,
                          nowType: state.nowTaskType,
                          currentMinutes: currentMinutes,
                          onFocusTap: () => context.push('/focus/${state.nowTask!.id}'),
                          onMarkDoneTap: () => _onCompleteTask(context, ref, state.nowTask!),
                        ),
                      ),
                      const SizedBox(height: FlowSpacing.space24),
                    ],

                    // Section "Today's schedule"
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: FlowSpacing.space16),
                      child: Row(
                        children: [
                          Text(
                            "Today's schedule",
                            style: FlowTypography.headlineMedium.copyWith(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: FlowColors.textPrimary,
                            ),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: () => context.go('/schedule'),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'See all',
                                  style: FlowTypography.bodyMedium.copyWith(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: FlowColors.primaryLight,
                                  ),
                                ),
                                const SizedBox(width: FlowSpacing.space4),
                                const Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 14,
                                  color: FlowColors.primaryLight,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: FlowSpacing.space4),

                    // Gesture Hint subheader
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: FlowSpacing.space16),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.swipe_rounded,
                            size: 13,
                            color: FlowColors.textMuted,
                          ),
                          const SizedBox(width: FlowSpacing.space4),
                          Text(
                            'Swipe right to complete · left to adjust',
                            style: FlowTypography.bodySmall.copyWith(
                              fontSize: 11,
                              color: FlowColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: FlowSpacing.space12),

                    // Vertical Timeline Task Cards
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: FlowSpacing.space16),
                      child: Column(
                        children: state.tasks.map((task) {
                          final cat = defaultCategoryOptions.firstWhere(
                            (c) => c.id == task.categoryId,
                            orElse: () => defaultCategoryOptions.first,
                          );
                          final runtime = task.runtimeStatus(now);

                          return SwipeableTaskCard(
                            key: ValueKey('home_task_${task.id}'),
                            task: task,
                            category: cat.toDomainCategory(),
                            runtimeStatus: runtime,
                            onTap: () => context.push('/task/${task.id}/edit'),
                            onComplete: (t) => _onCompleteTask(context, ref, t),
                            onIncomplete: (t) => _onIncompleteTask(context, ref, t),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
