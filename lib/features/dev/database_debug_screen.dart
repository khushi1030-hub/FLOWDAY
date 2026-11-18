import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:uuid/uuid.dart';
import '../../core/providers/database_providers.dart';
import '../../core/theme/flow_colors.dart';
import '../../core/theme/flow_typography.dart';
import '../../core/widgets/flow_buttons.dart';
import '../../core/widgets/flow_card.dart';
import '../../features/tasks/domain/entities/task.dart';
import '../tasks/presentation/widgets/swipeable_task_card.dart';

/// Temporary database debug screen for Phase 2 persistence verification.
class DatabaseDebugScreen extends ConsumerStatefulWidget {
  const DatabaseDebugScreen({super.key});

  @override
  ConsumerState<DatabaseDebugScreen> createState() => _DatabaseDebugScreenState();
}

class _DatabaseDebugScreenState extends ConsumerState<DatabaseDebugScreen> {
  int _counter = 1;

  @override
  Widget build(BuildContext context) {
    final clock = ref.watch(clockProvider);
    final todayKey = clock.currentDateKey;
    final tasksAsync = ref.watch(tasksForDayProvider(todayKey));
    final categoryRepo = ref.watch(categoryRepositoryProvider);
    final taskRepo = ref.watch(taskRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: FlowColors.background,
        elevation: 0,
        title: const Text('Database Debug (/dev/database)', style: FlowTypography.headlineMedium),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        children: [
          // Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: FlowColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: FlowColors.warning.withValues(alpha: 0.5), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: FlowColors.warning,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('DEBUG ONLY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black)),
                    ),
                    const SizedBox(width: 8),
                    const Text('Phase 2 Persistence Test', style: FlowTypography.titleMedium),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Date: $todayKey | Time: ${clock.currentMinutesSinceMidnight ~/ 60}:${(clock.currentMinutesSinceMidnight % 60).toString().padLeft(2, '0')}',
                  style: FlowTypography.bodyMedium.copyWith(color: FlowColors.textSecondary),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Add a task, close/kill the app completely, reopen, and verify persistence.',
                  style: FlowTypography.bodyLarge,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Action buttons
          FlowPrimaryButton(
            label: '+ Create Task with Form (Screen 09)',
            icon: const Icon(Icons.add_task_rounded, color: Colors.white, size: 20),
            onPressed: () => context.push('/task/new'),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FlowSecondaryButton(
                  label: '+ Quick Task',
                  icon: const Icon(Icons.bolt_rounded, color: FlowColors.primaryLight, size: 18),
                  onPressed: () async {
                    final now = clock.now();
                    final startMin = (now.hour * 60 + now.minute) % 1400;
                    final endMin = startMin + 45;
                    final sampleTitles = [
                      'Deep Work Session',
                      'Architecture Review',
                      'Hydration & Movement',
                      'Project Planning',
                      'Focused Reading',
                    ];
                    final title = '${sampleTitles[_counter % sampleTitles.length]} #$_counter';
                    _counter++;

                    final task = Task(
                      id: const Uuid().v4(),
                      title: title,
                      dateKey: todayKey,
                      startMin: startMin,
                      endMin: endMin,
                      priority: (_counter % 3),
                      createdAt: now.millisecondsSinceEpoch,
                      updatedAt: now.millisecondsSinceEpoch,
                    );

                    await taskRepo.insertTask(task);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FlowSecondaryButton(
                  label: 'Delete All',
                  icon: const Icon(Icons.delete_outline_rounded, color: FlowColors.error, size: 18),
                  onPressed: () async {
                    await taskRepo.deleteAll();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Category Seed Verification
          Text('SEEDED CATEGORIES', style: FlowTypography.labelSmall.copyWith(color: FlowColors.primaryLight)),
          const SizedBox(height: 8),
          FutureBuilder(
            future: categoryRepo.getAllCategories(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final categories = snapshot.data!;
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: categories.map((cat) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Color(cat.color).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Color(cat.color), width: 1),
                    ),
                    child: Text(cat.name, style: TextStyle(color: Color(cat.color), fontSize: 12, fontWeight: FontWeight.bold)),
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 24),

          // Tasks List for Today
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("TODAY'S PERSISTED TASKS ($todayKey)", style: FlowTypography.labelSmall.copyWith(color: FlowColors.primaryLight)),
              const Text('Swipe right: Done | Left: Incomplete', style: TextStyle(color: FlowColors.textMuted, fontSize: 10)),
            ],
          ),
          const SizedBox(height: 8),
          tasksAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Text('Error loading tasks: $err', style: const TextStyle(color: FlowColors.error)),
            data: (tasks) {
              if (tasks.isEmpty) {
                return FlowCard(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(Icons.inbox_outlined, size: 40, color: FlowColors.textMuted),
                        const SizedBox(height: 8),
                        const Text('No tasks in database for today.', style: FlowTypography.bodyLarge),
                        const SizedBox(height: 4),
                        Text('Tap "+ Create Task" above to test persistence.', style: FlowTypography.bodyMedium.copyWith(color: FlowColors.textSecondary)),
                      ],
                    ),
                  ),
                );
              }

              return Column(
                children: tasks.map((task) {
                  final runtimeStatus = task.runtimeStatus(clock.now());

                  return SwipeableTaskCard(
                    key: ValueKey(task.id),
                    task: task,
                    runtimeStatus: runtimeStatus,
                    onTap: () => context.push('/task/${task.id}/edit'),
                    onComplete: (t) async {
                      await taskRepo.markCompleted(t.id, clock.now().millisecondsSinceEpoch);
                      if (context.mounted) {
                        context.push('/completed/${t.id}');
                      }
                    },
                    onIncomplete: (t) async {
                      await taskRepo.markIncomplete(t.id);
                    },
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
