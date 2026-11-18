import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import '../../../../core/providers/database_providers.dart';
import '../../../../core/theme/flow_colors.dart';
import '../../../../core/utils/time_utils.dart';
import '../../../../core/widgets/flow_buttons.dart';
import '../domain/entities/task.dart';
import 'widgets/category_selector.dart';

/// Screen 13: Task Completed Celebration Screen with stats, streak, and next task preview.
class TaskCompletedScreen extends ConsumerStatefulWidget {
  const TaskCompletedScreen({
    super.key,
    required this.taskId,
  });

  final String taskId;

  @override
  ConsumerState<TaskCompletedScreen> createState() => _TaskCompletedScreenState();
}

class _TaskCompletedScreenState extends ConsumerState<TaskCompletedScreen> {
  Task? _task;
  Task? _nextTask;
  int _completedCount = 1;
  int _totalCount = 1;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final taskRepo = ref.read(taskRepositoryProvider);
    final task = await taskRepo.getTaskById(widget.taskId);

    if (task != null) {
      final allToday = await taskRepo.getTasksForDate(task.dateKey);
      final completed = allToday.where((t) => t.status == 'completed').length;

      // Find next upcoming/pending task after this one
      final upcoming = allToday
          .where((t) => t.id != task.id && t.status == 'pending' && t.startMin >= task.endMin)
          .toList();

      if (mounted) {
        setState(() {
          _task = task;
          _completedCount = completed;
          _totalCount = allToday.length;
          _nextTask = upcoming.isNotEmpty ? upcoming.first : null;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) {
        context.pop();
      }
    }
  }

  void _navigateSafe(BuildContext context, String path) {
    try {
      context.go(path);
    } catch (_) {
      Navigator.of(context).maybePop();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: FlowColors.background,
        body: Center(child: CircularProgressIndicator(color: FlowColors.primary)),
      );
    }

    final task = _task!;
    final cat = defaultCategoryOptions.firstWhere(
      (c) => c.id == task.categoryId,
      orElse: () => defaultCategoryOptions.first,
    );

    final double progressRatio = _totalCount > 0 ? (_completedCount / _totalCount) : 1.0;
    final int progressPercent = (progressRatio * 100).toInt();

    return Scaffold(
      backgroundColor: FlowColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Color(0xFF1D1B2B),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close_rounded, size: 16, color: Colors.white),
                    ),
                    onPressed: () => _navigateSafe(context, '/home'),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Column(
                  children: [
                    // Celebration Check Graphic
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: FlowColors.success,
                        boxShadow: [
                          BoxShadow(
                            color: FlowColors.success.withValues(alpha: 0.35),
                            blurRadius: 24,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.check_rounded, color: Color(0xFF0B0B14), size: 44),
                    ),
                    const SizedBox(height: 16),

                    // Copy
                    const Text(
                      'Amazing! 🎉',
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Task completed.',
                      style: TextStyle(fontSize: 14, color: Color(0xFF8E8CA3)),
                    ),
                    const SizedBox(height: 24),

                    // Task Summary Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF161424),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFF262244), width: 1),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: cat.color.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(cat.icon, color: cat.color, size: 18),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      task.title,
                                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${TimeUtils.formatTimeRange(task.startMin, task.endMin)} · ${cat.name}',
                                      style: const TextStyle(fontSize: 12, color: Color(0xFF8E8CA3)),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.check_circle_rounded, color: FlowColors.success, size: 20),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Divider(color: Color(0xFF262244), height: 1),
                          const SizedBox(height: 16),

                          // 3 Stat Tiles
                          Row(
                            children: [
                              _buildStatTile('Duration', '${task.durationMin}m'),
                              const SizedBox(width: 8),
                              _buildStatTile('Finished', 'On time'),
                              const SizedBox(width: 8),
                              _buildStatTile('Deep focus', '${task.durationMin}m'),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Today's Progress Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF161424),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFF262244), width: 1),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Today's progress", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF36221A),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text('🔥 Streak active', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFF59E0B))),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text('$progressPercent%', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white)),
                              const SizedBox(width: 8),
                              Text('$_completedCount of $_totalCount tasks', style: const TextStyle(fontSize: 13, color: Color(0xFF8E8CA3))),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: progressRatio,
                              minHeight: 8,
                              backgroundColor: const Color(0xFF262244),
                              valueColor: const AlwaysStoppedAnimation<Color>(FlowColors.primary),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Next Task Preview if any
                    if (_nextTask != null)
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1B192E),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: FlowColors.primary.withValues(alpha: 0.3), width: 1),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: FlowColors.primary,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text('NEXT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                '${_nextTask!.title} · ${TimeUtils.formatTimeRange(_nextTask!.startMin, _nextTask!.endMin)}',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 32),

                    // Primary Button
                    FlowPrimaryButton(
                      label: _nextTask != null ? 'Continue to Next Task ->' : 'Back to Schedule',
                      onPressed: () => _navigateSafe(context, '/schedule'),
                    ),
                    const SizedBox(height: 12),

                    // Back to Home Link
                    TextButton(
                      onPressed: () => _navigateSafe(context, '/home'),
                      child: const Text(
                        'Back to Home',
                        style: TextStyle(color: Color(0xFF8E8CA3), fontSize: 13, fontWeight: FontWeight.w600),
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

  Widget _buildStatTile(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1F1C33),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF8E8CA3))),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
          ],
        ),
      ),
    );
  }
}
