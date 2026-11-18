import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import '../../../../core/providers/database_providers.dart';
import '../../../../core/theme/flow_colors.dart';
import '../../../../core/utils/time_utils.dart';
import '../../../../core/widgets/flow_buttons.dart';
import '../domain/entities/task.dart';
import '../domain/services/task_overlap_detector.dart';
import '../domain/services/task_validation.dart';
import 'widgets/category_selector.dart';
import 'widgets/reminder_offset_picker.dart';
import 'widgets/time_range_picker.dart';

/// Screen 10: Edit Task with Conflict Resolution and Deletion Confirmation.
class EditTaskScreen extends ConsumerStatefulWidget {
  const EditTaskScreen({
    super.key,
    required this.taskId,
  });

  final String taskId;

  @override
  ConsumerState<EditTaskScreen> createState() => _EditTaskScreenState();
}

class _EditTaskScreenState extends ConsumerState<EditTaskScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _notesController = TextEditingController();

  Task? _loadedTask;
  bool _isLoading = true;
  String? _errorMessage;

  late String _dateKey;
  late int _startMin;
  late int _endMin;
  int _categoryId = 1;
  int _priority = 1;
  bool _isFixed = false;
  bool _alarmEnabled = true;
  int? _reminderOffsetMin;
  int _conflictResolutionOption = 0; // 0: shift, 1: revert, 2: keep

  List<Task> _existingTasks = [];

  @override
  void initState() {
    super.initState();
    _loadTask();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadTask() async {
    final taskRepo = ref.read(taskRepositoryProvider);
    final task = await taskRepo.getTaskById(widget.taskId);

    if (task == null) {
      if (mounted) {
        context.pop();
      }
      return;
    }

    final tasksForDate = await taskRepo.getTasksForDate(task.dateKey);

    if (mounted) {
      setState(() {
        _loadedTask = task;
        _dateKey = task.dateKey;
        _startMin = task.startMin;
        _endMin = task.endMin;
        _categoryId = task.categoryId ?? 1;
        _priority = task.priority;
        _isFixed = task.isFixed;
        _alarmEnabled = task.alarmEnabled;
        _reminderOffsetMin = task.reminderOffsetMin;
        _titleController.text = task.title;
        _descController.text = task.description ?? '';
        _notesController.text = task.notes ?? '';
        _existingTasks = tasksForDate;
        _isLoading = false;
      });
    }
  }

  List<Task> get _conflicts {
    if (_loadedTask == null) return [];
    final candidate = _loadedTask!.copyWith(
      title: _titleController.text.trim(),
      dateKey: _dateKey,
      startMin: _startMin,
      endMin: _endMin,
    );
    return TaskOverlapDetector.findOverlaps(
      candidate: candidate,
      existingTasks: _existingTasks,
    );
  }

  Future<void> _onSave() async {
    if (_loadedTask == null) return;
    setState(() => _errorMessage = null);

    final title = _titleController.text.trim();
    final settingsRepo = ref.read(settingsRepositoryProvider);
    final settings = await settingsRepo.getSettings();

    // 1. Validation
    final validation = TaskValidator.validate(
      title: title,
      startMin: _startMin,
      endMin: _endMin,
      dayStartMin: settings.wakeMin,
      dayEndMin: settings.sleepMin,
    );

    if (!validation.isValid) {
      setState(() => _errorMessage = validation.errorMessage);
      return;
    }

    final conflicts = _conflicts;
    final bool hasConflict = conflicts.isNotEmpty;

    // Apply conflict resolution if user chose to adjust
    int finalStart = _startMin;
    int finalEnd = _endMin;

    if (hasConflict) {
      if (_conflictResolutionOption == 0) {
        // Shift
        finalStart = TaskOverlapDetector.suggestNextSlotStart(
          conflictingTask: conflicts.first,
          durationMin: _endMin - _startMin,
          breakMin: settings.defaultBreakMin,
          dayEndMin: settings.sleepMin,
        );
        finalEnd = (finalStart + (_endMin - _startMin)).clamp(5, 1440);
      } else if (_conflictResolutionOption == 1) {
        // Revert to original duration
        finalEnd = finalStart + _loadedTask!.durationMin;
      }
    }

    final clock = ref.read(clockProvider);
    final nowMs = clock.now().millisecondsSinceEpoch;

    final updated = _loadedTask!.copyWith(
      title: title,
      description: _descController.text.trim().isNotEmpty ? _descController.text.trim() : null,
      dateKey: _dateKey,
      startMin: finalStart,
      endMin: finalEnd,
      priority: _priority,
      kind: _categoryId == 6 ? 'break' : 'task',
      isFixed: _isFixed,
      categoryId: _categoryId,
      alarmEnabled: _alarmEnabled,
      reminderOffsetMin: _reminderOffsetMin,
      notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
      hasConflict: hasConflict && _conflictResolutionOption == 2,
      updatedAt: nowMs,
    );

    final taskRepo = ref.read(taskRepositoryProvider);
    await taskRepo.updateTask(updated);

    if (mounted) {
      Navigator.of(context).maybePop();
    }
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: FlowColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Delete Task?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: const Text(
            'This action cannot be undone. Are you sure you want to remove this task from your schedule?',
            style: TextStyle(color: Color(0xFF8E8CA3), fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel', style: TextStyle(color: Colors.white)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(ctx).pop();
                final taskRepo = ref.read(taskRepositoryProvider);
                await taskRepo.deleteTask(widget.taskId);
                if (mounted) {
                  Navigator.of(context).maybePop();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: FlowColors.error,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: FlowColors.background,
        body: Center(child: CircularProgressIndicator(color: FlowColors.primary)),
      );
    }

    final conflicts = _conflicts;

    return Scaffold(
      backgroundColor: FlowColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Color(0xFF1D1B2B),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded, size: 14, color: Colors.white),
                    ),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  const Spacer(),
                  const Text(
                    'Edit task',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                  const Spacer(),
                  // Trash Action
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: FlowColors.error.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.delete_outline_rounded, size: 18, color: FlowColors.error),
                    ),
                    onPressed: _confirmDelete,
                  ),
                ],
              ),
            ),

            // Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Error Banner
                    if (_errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: FlowColors.errorContainer,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: FlowColors.error, width: 1),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline_rounded, color: FlowColors.error, size: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Title
                    const Text('TASK TITLE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF71717A), letterSpacing: 1.2)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF161424),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFF2A2640), width: 1),
                      ),
                      child: TextField(
                        controller: _titleController,
                        style: const TextStyle(fontSize: 15, color: Colors.white),
                        decoration: const InputDecoration(border: InputBorder.none),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Time Range
                    TimeRangePicker(
                      dateKey: _dateKey,
                      startMin: _startMin,
                      endMin: _endMin,
                      conflictCount: conflicts.length,
                      conflictingTaskTitle: conflicts.isNotEmpty ? conflicts.first.title : null,
                      onDateSelected: (val) => setState(() => _dateKey = val),
                      onStartSelected: (val) {
                        setState(() {
                          final duration = _endMin > _startMin ? _endMin - _startMin : 45;
                          _startMin = val;
                          _endMin = (_startMin + duration).clamp(5, 1440);
                        });
                      },
                      onEndSelected: (val) => setState(() => _endMin = val),
                      onDurationChanged: (val) => setState(() => _endMin = (_startMin + val).clamp(5, 1440)),
                    ),
                    const SizedBox(height: 20),

                    // Inline Conflict Resolution Card if conflicts detected
                    if (conflicts.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF23151B),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFF4A2027), width: 1.2),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.warning_amber_rounded, color: FlowColors.warning, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'This overlaps with ${conflicts.length} task${conflicts.length > 1 ? 's' : ''}',
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Nothing changes until you choose. Choose an option:',
                              style: TextStyle(fontSize: 12, color: Color(0xFF8E8CA3)),
                            ),
                            const SizedBox(height: 12),

                            // Option 0: Shift
                            _buildResolutionRadio(
                              index: 0,
                              title: 'Shift later tasks',
                              subtitle: 'Shift conflicting tasks to protect breaks and priorities.',
                            ),
                            const SizedBox(height: 8),

                            // Option 1: Revert duration
                            _buildResolutionRadio(
                              index: 1,
                              title: 'Keep original duration',
                              subtitle: 'Revert end time to ${TimeUtils.formatMinutesToTime(_startMin + _loadedTask!.durationMin)}.',
                            ),
                            const SizedBox(height: 8),

                            // Option 2: Keep overlap
                            _buildResolutionRadio(
                              index: 2,
                              title: 'Keep the overlap',
                              subtitle: "I'll sort it out myself. Flag as conflict.",
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Category
                    CategorySelector(
                      selectedCategoryId: _categoryId,
                      onSelected: (id) => setState(() => _categoryId = id),
                    ),
                    const SizedBox(height: 20),

                    // Priority, Fixed, Alarm, Reminders
                    ReminderOffsetPicker(
                      priority: _priority,
                      isFixed: _isFixed,
                      alarmEnabled: _alarmEnabled,
                      reminderOffsetMin: _reminderOffsetMin,
                      onPriorityChanged: (val) => setState(() => _priority = val),
                      onIsFixedChanged: (val) => setState(() => _isFixed = val),
                      onAlarmEnabledChanged: (val) => setState(() => _alarmEnabled = val),
                      onReminderOffsetChanged: (val) => setState(() => _reminderOffsetMin = val),
                    ),
                    const SizedBox(height: 16),

                    // Notes
                    const Text('NOTES', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF71717A), letterSpacing: 1.2)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF161424),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFF2A2640), width: 1),
                      ),
                      child: TextField(
                        controller: _notesController,
                        maxLines: 3,
                        style: const TextStyle(fontSize: 13, color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: 'Private notes, links, checklist items...',
                          hintStyle: TextStyle(color: Color(0xFF71717A)),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Bottom Action Buttons
                    Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: FlowSecondaryButton(
                            label: 'Cancel',
                            onPressed: () => Navigator.of(context).maybePop(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: FlowPrimaryButton(
                            label: 'Save Changes',
                            onPressed: _onSave,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResolutionRadio({
    required int index,
    required String title,
    required String subtitle,
  }) {
    final isSelected = _conflictResolutionOption == index;
    return InkWell(
      onTap: () => setState(() => _conflictResolutionOption = index),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2F1D24) : const Color(0xFF191116),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? FlowColors.warning : const Color(0xFF3B1B22),
            width: 1.2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
              color: isSelected ? FlowColors.warning : const Color(0xFF71717A),
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 11, color: Color(0xFF8E8CA3))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
