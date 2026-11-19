import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/notifications/domain/alarm_audio_service.dart';
import '../../../core/notifications/domain/notification_gateway.dart';
import '../../../core/notifications/domain/notification_id_generator.dart';
import '../../../core/providers/database_providers.dart';
import '../../../core/providers/notification_providers.dart';
import '../../../core/services/alarm_window_service.dart';
import '../../../core/theme/flow_colors.dart';
import '../../../core/theme/flow_radii.dart';
import '../../../core/theme/flow_spacing.dart';
import '../../../core/theme/flow_typography.dart';
import '../../../core/utils/time_utils.dart';
import '../../tasks/domain/entities/task.dart';
import 'widgets/alarm_swipe_slider.dart';

/// Screen 12: Full-screen Alarm Experience ("Time's Up!").
///
/// Features concentric glowing rings, bi-directional completion slider,
/// backup buttons, snooze, validated +10 min extension, and audio management.
class AlarmScreen extends ConsumerStatefulWidget {
  const AlarmScreen({super.key, required this.taskId});

  final String taskId;

  @override
  ConsumerState<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends ConsumerState<AlarmScreen> {
  bool _muted = false;
  bool _vibrate = true;
  late final AlarmAudioService _audioService;

  @override
  void initState() {
    super.initState();
    _audioService = ref.read(alarmAudioServiceProvider);
    // Enable lockscreen presentation on Android
    AlarmWindowService.turnScreenOnAndShowWhenLocked();

    // Start playing alarm audio tone with user's configured sound
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final settings = await ref.read(settingsRepositoryProvider).getSettings();
      if (mounted) {
        _audioService.playAlarmTone(soundName: settings.notificationSound);
      }
    });
  }

  @override
  void dispose() {
    // Reset window flags and stop audio
    AlarmWindowService.resetScreenFlags();
    _audioService.stop();
    super.dispose();
  }


  Future<void> _completeTask(Task task) async {
    await ref.read(alarmAudioServiceProvider).stop();
    final clock = ref.read(clockProvider);
    final taskRepo = ref.read(taskRepositoryProvider);

    await taskRepo.markCompleted(task.id, clock.now().millisecondsSinceEpoch);

    if (mounted) {
      context.go('/completed/${task.id}');
    }
  }

  Future<void> _delayTask(Task task) async {
    await ref.read(alarmAudioServiceProvider).stop();
    final taskRepo = ref.read(taskRepositoryProvider);
    await taskRepo.markIncomplete(task.id);

    if (mounted) {
      context.go('/delay/${task.id}');
    }
  }

  Future<void> _snooze(Task task) async {
    await ref.read(alarmAudioServiceProvider).stop();
    final clock = ref.read(clockProvider);
    final gateway = ref.read(notificationGatewayProvider);

    // Schedule a snooze alarm in 5 minutes
    final snoozeTime = clock.now().add(const Duration(minutes: 5));
    final rawId = NotificationIdGenerator.getNotificationId(task.id, NotificationType.endAlarm);

    await gateway.scheduleZonedNotification(
      id: rawId,
      title: "Time's up! (Snoozed) ⏰",
      body: '${task.title} snooze is over',
      scheduledDate: snoozeTime,
      channelId: 'flowday_alarms_soft_chime',
      payload: '{"type":"alarm","taskId":"${task.id}","route":"/alarm/${task.id}"}',
      fullScreenIntent: true,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Alarm snoozed for 5 minutes')),
      );
      context.go('/');
    }
  }

  Future<void> _extendTenMinutes(Task task) async {
    final taskRepo = ref.read(taskRepositoryProvider);
    final existingTasks = await taskRepo.getTasksForDate(task.dateKey);

    final newEndMin = task.endMin + 10;
    if (newEndMin > 1440) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cannot extend past midnight')),
        );
      }
      return;
    }

    // Check for overlaps with other scheduled tasks
    final conflictingTask = existingTasks.cast<Task?>().firstWhere(
          (t) =>
              t!.id != task.id &&
              t.kind == 'task' &&
              t.status != 'skipped' &&
              t.status != 'completed' &&
              !(newEndMin <= t.startMin || task.startMin >= t.endMin),
          orElse: () => null,
        );

    if (conflictingTask != null && mounted) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: FlowColors.surface,
          title: const Text('Schedule Conflict', style: FlowTypography.headlineMedium),
          content: Text(
            'Extending by 10 minutes overlaps with "${conflictingTask.title}" (${TimeUtils.formatTimeRange(conflictingTask.startMin, conflictingTask.endMin)}). Extend anyway?',
            style: FlowTypography.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel', style: TextStyle(color: FlowColors.textSecondary)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Extend Anyway', style: TextStyle(color: FlowColors.primary)),
            ),
          ],
        ),
      );

      if (proceed != true) return;
    }

    // Apply validated extension
    final updated = task.copyWith(
      endMin: newEndMin,
      updatedAt: ref.read(clockProvider).now().millisecondsSinceEpoch,
    );
    await taskRepo.updateTask(updated);

    await ref.read(alarmAudioServiceProvider).stop();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Extended task by 10 minutes')),
      );
      context.go('/');
    }
  }

  void _dismiss() {
    ref.read(alarmAudioServiceProvider).stop();
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final taskRepo = ref.watch(taskRepositoryProvider);

    return Scaffold(
      backgroundColor: FlowColors.background,
      body: SafeArea(
        child: FutureBuilder<Task?>(
          future: taskRepo.getTaskById(widget.taskId),
          builder: (context, snapshot) {
            final task = snapshot.data;
            if (task == null) {
              return const Center(child: CircularProgressIndicator());
            }

            final timeStr = TimeUtils.formatMinutesToTime(task.endMin);

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: FlowSpacing.space20),
              child: Column(
                children: [
                  const SizedBox(height: FlowSpacing.space12),
                  // Top Bar: Speaker, Vibrate, FLOWDAY ALARM label
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          _muted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                          color: FlowColors.textSecondary,
                        ),
                        onPressed: () {
                          setState(() => _muted = !_muted);
                          ref.read(alarmAudioServiceProvider).toggleMute();
                        },
                      ),
                      IconButton(
                        icon: Icon(
                          _vibrate ? Icons.vibration_rounded : Icons.smartphone_rounded,
                          color: _vibrate ? FlowColors.primary : FlowColors.textSecondary,
                        ),
                        onPressed: () => setState(() => _vibrate = !_vibrate),
                      ),
                      const Spacer(),
                      const Text(
                        'FLOWDAY ALARM',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.4,
                          color: FlowColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),

                  // Concentric Glowing Rings with Clock Visualization
                  Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 220,
                          height: 220,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: FlowColors.primary.withValues(alpha: 0.15),
                              width: 2,
                            ),
                          ),
                        ),
                        Container(
                          width: 170,
                          height: 170,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: FlowColors.primary.withValues(alpha: 0.08),
                            border: Border.all(
                              color: FlowColors.primary.withValues(alpha: 0.35),
                              width: 2,
                            ),
                          ),
                        ),
                        Container(
                          width: 120,
                          height: 120,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: FlowColors.surface,
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.alarm_rounded,
                                  color: FlowColors.primary,
                                  size: 26,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  timeStr,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: FlowColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: FlowSpacing.space24),

                  // Alarm Copy
                  const Text(
                    "Time's up! ⏰",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: FlowColors.primary,
                    ),
                  ),
                  const SizedBox(height: FlowSpacing.space8),
                  Text(
                    task.title,
                    style: FlowTypography.headlineLarge.copyWith(fontSize: 26),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: FlowSpacing.space8),
                  Text(
                    'Your session is complete · ${TimeUtils.formatTimeRange(task.startMin, task.endMin)}',
                    style: FlowTypography.bodyMedium,
                    textAlign: TextAlign.center,
                  ),

                  const Spacer(),

                  // Completion Question
                  const Text(
                    'Did you complete your task?',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: FlowColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: FlowSpacing.space16),

                  // Bi-directional completion slider
                  AlarmSwipeSlider(
                    onComplete: () => _completeTask(task),
                    onDelay: () => _delayTask(task),
                  ),

                  const SizedBox(height: FlowSpacing.space12),

                  // Secondary backup buttons below slider
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _delayTask(task),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: FlowColors.error, width: 1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(FlowRadii.pill),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: FlowSpacing.space12),
                          ),
                          child: const Text(
                            '⌛ Not completed',
                            style: TextStyle(color: FlowColors.error, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                      const SizedBox(width: FlowSpacing.space12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _completeTask(task),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: FlowColors.success, width: 1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(FlowRadii.pill),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: FlowSpacing.space12),
                          ),
                          child: const Text(
                            '✓ Completed',
                            style: TextStyle(color: FlowColors.success, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: FlowSpacing.space16),

                  // Bottom Quick Row: Snooze, +10 min, Dismiss
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton.icon(
                        icon: const Icon(Icons.snooze_rounded, size: 16, color: FlowColors.textSecondary),
                        label: const Text('⏰ Snooze 5m', style: TextStyle(color: FlowColors.textSecondary)),
                        onPressed: () => _snooze(task),
                      ),
                      TextButton(
                        onPressed: () => _extendTenMinutes(task),
                        child: const Text('+ 10 min', style: TextStyle(color: FlowColors.primary, fontWeight: FontWeight.w700)),
                      ),
                      TextButton(
                        onPressed: _dismiss,
                        child: const Text('Dismiss', style: TextStyle(color: FlowColors.textSecondary)),
                      ),
                    ],
                  ),
                  const SizedBox(height: FlowSpacing.space16),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
