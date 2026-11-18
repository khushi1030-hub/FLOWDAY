import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/providers/database_providers.dart';
import '../../../../core/theme/flow_colors.dart';
import '../../../../core/widgets/flow_buttons.dart';
import '../domain/entities/task.dart';
import '../domain/services/task_overlap_detector.dart';
import '../domain/services/task_validation.dart';
import 'widgets/category_selector.dart';
import 'widgets/reminder_offset_picker.dart';
import 'widgets/task_preview_card.dart';
import 'widgets/time_range_picker.dart';

/// Screen 09: New Task creation form with live preview and conflict detection.
class NewTaskScreen extends ConsumerStatefulWidget {
  const NewTaskScreen({
    super.key,
    this.initialDateKey,
    this.initialStartMin,
    this.initialEndMin,
  });

  final String? initialDateKey;
  final int? initialStartMin;
  final int? initialEndMin;

  @override
  ConsumerState<NewTaskScreen> createState() => _NewTaskScreenState();
}

class _NewTaskScreenState extends ConsumerState<NewTaskScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _notesController = TextEditingController();
  final _scrollController = ScrollController();

  late String _dateKey;
  late int _startMin;
  late int _endMin;
  int _categoryId = 1; // Study default
  int _priority = 1; // Medium default
  bool _isFixed = false;
  bool _alarmEnabled = true;
  int? _reminderOffsetMin = 10; // 10m before default
  bool _showNotesField = false;

  String? _errorMessage;
  List<Task> _existingTasks = [];

  @override
  void initState() {
    super.initState();
    final clock = ref.read(clockProvider);
    _dateKey = widget.initialDateKey ?? clock.currentDateKey;

    // Default: nearest upcoming 30m slot, 45m duration
    final currentMin = clock.currentMinutesSinceMidnight;
    final defaultStart = widget.initialStartMin ?? (((currentMin ~/ 30) + 1) * 30).clamp(0, 1380);
    _startMin = defaultStart;
    _endMin = widget.initialEndMin ?? (_startMin + 45).clamp(5, 1440);

    _titleController.addListener(() => setState(() {}));
    _loadExistingTasks();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _notesController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingTasks() async {
    final taskRepo = ref.read(taskRepositoryProvider);
    final tasks = await taskRepo.getTasksForDate(_dateKey);
    if (mounted) {
      setState(() => _existingTasks = tasks);
    }
  }

  List<Task> get _conflicts {
    final candidate = Task(
      id: 'candidate',
      title: _titleController.text.trim(),
      dateKey: _dateKey,
      startMin: _startMin,
      endMin: _endMin,
      createdAt: 0,
      updatedAt: 0,
    );
    return TaskOverlapDetector.findOverlaps(
      candidate: candidate,
      existingTasks: _existingTasks,
    );
  }

  void _onDurationChanged(int newDuration) {
    setState(() {
      _endMin = (_startMin + newDuration).clamp(5, 1440);
    });
  }

  Future<void> _onSave({bool allowConflict = false}) async {
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
      if (_scrollController.hasClients && _scrollController.offset > 0) {
        _scrollController.animateTo(0, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
      }
      return;
    }

    // 2. Overlap Checking
    final conflicts = _conflicts;
    if (conflicts.isNotEmpty && !allowConflict) {
      _showConflictDialog(conflicts.first, settings.defaultBreakMin, settings.sleepMin);
      return;
    }

    // 3. Persist Task
    final clock = ref.read(clockProvider);
    final nowMs = clock.now().millisecondsSinceEpoch;

    final newTask = Task(
      id: const Uuid().v4(),
      title: title,
      description: _descController.text.trim().isNotEmpty ? _descController.text.trim() : null,
      dateKey: _dateKey,
      startMin: _startMin,
      endMin: _endMin,
      priority: _priority,
      kind: _categoryId == 6 ? 'break' : 'task',
      isFixed: _isFixed,
      categoryId: _categoryId,
      alarmEnabled: _alarmEnabled,
      reminderOffsetMin: _reminderOffsetMin,
      notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
      hasConflict: conflicts.isNotEmpty,
      createdAt: nowMs,
      updatedAt: nowMs,
    );

    final taskRepo = ref.read(taskRepositoryProvider);
    await taskRepo.insertTask(newTask);

    if (mounted) {
      Navigator.of(context).maybePop();
    }
  }

  void _showConflictDialog(Task conflict, int breakMin, int dayEndMin) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E161C),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.warning_amber_rounded, color: FlowColors.warning, size: 22),
                  SizedBox(width: 8),
                  Text(
                    'Schedule Conflict',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'This task overlaps with "${conflict.title}" (${conflict.durationMin}m). How would you like to handle this?',
                style: const TextStyle(fontSize: 13, color: Color(0xFF8E8CA3)),
              ),
              const SizedBox(height: 20),
              FlowPrimaryButton(
                label: 'Adjust Times (Next Slot)',
                onPressed: () {
                  Navigator.of(ctx).pop();
                  final nextStart = TaskOverlapDetector.suggestNextSlotStart(
                    conflictingTask: conflict,
                    durationMin: _endMin - _startMin,
                    breakMin: breakMin,
                    dayEndMin: dayEndMin,
                  );
                  setState(() {
                    final duration = _endMin - _startMin;
                    _startMin = nextStart;
                    _endMin = (_startMin + duration).clamp(5, 1440);
                  });
                },
              ),
              const SizedBox(height: 10),
              FlowSecondaryButton(
                label: 'Keep Overlap Anyway',
                onPressed: () {
                  Navigator.of(ctx).pop();
                  _onSave(allowConflict: true);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
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
                      child: const Icon(Icons.close_rounded, size: 16, color: Colors.white),
                    ),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  const Spacer(),
                  const Text(
                    'New task',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                  const Spacer(),
                  const SizedBox(width: 40), // Balance close button
                ],
              ),
            ),

            // Form Body
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Error Banner if present
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

                    // Live Preview Card
                    TaskPreviewCard(
                      title: _titleController.text,
                      startMin: _startMin,
                      endMin: _endMin,
                      categoryId: _categoryId,
                      priority: _priority,
                      isFixed: _isFixed,
                      reminderOffsetMin: _reminderOffsetMin,
                    ),
                    const SizedBox(height: 20),

                    // Title Input
                    const Text(
                      'TASK TITLE',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF71717A), letterSpacing: 1.2),
                    ),
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
                        decoration: const InputDecoration(
                          hintText: 'e.g. Call with mentor',
                          hintStyle: TextStyle(color: Color(0xFF71717A)),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Description Input
                    const Text(
                      'DESCRIPTION',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF71717A), letterSpacing: 1.2),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF161424),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFF2A2640), width: 1),
                      ),
                      child: TextField(
                        controller: _descController,
                        maxLines: 2,
                        style: const TextStyle(fontSize: 13, color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: 'Add details or context...',
                          hintStyle: TextStyle(color: Color(0xFF71717A)),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Date & Time Picker
                    TimeRangePicker(
                      dateKey: _dateKey,
                      startMin: _startMin,
                      endMin: _endMin,
                      conflictCount: conflicts.length,
                      conflictingTaskTitle: conflicts.isNotEmpty ? conflicts.first.title : null,
                      onDateSelected: (newDate) {
                        setState(() => _dateKey = newDate);
                        _loadExistingTasks();
                      },
                      onStartSelected: (val) => setState(() => _startMin = val),
                      onEndSelected: (val) => setState(() => _endMin = val),
                      onDurationChanged: _onDurationChanged,
                    ),
                    const SizedBox(height: 20),

                    // Category Selector
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

                    // Notes Toggle
                    if (!_showNotesField)
                      GestureDetector(
                        onTap: () => setState(() => _showNotesField = true),
                        child: Row(
                          children: const [
                            Icon(Icons.edit_note_rounded, size: 18, color: FlowColors.primaryLight),
                            SizedBox(width: 8),
                            Text('📝 Add notes', style: TextStyle(fontSize: 13, color: FlowColors.primaryLight, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      )
                    else ...[
                      const Text(
                        'NOTES',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF71717A), letterSpacing: 1.2),
                      ),
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
                    ],
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
                            label: '✓ Save Task',
                            onPressed: () => _onSave(),
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
}
