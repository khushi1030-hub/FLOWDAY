import 'package:material_ui/material_ui.dart';
import '../../../../core/theme/flow_colors.dart';
import '../../../../core/utils/time_utils.dart';

class TimeRangePicker extends StatelessWidget {
  const TimeRangePicker({
    super.key,
    required this.dateKey,
    required this.startMin,
    required this.endMin,
    required this.onDateSelected,
    required this.onStartSelected,
    required this.onEndSelected,
    required this.onDurationChanged,
    this.conflictCount = 0,
    this.conflictingTaskTitle,
  });

  final String dateKey;
  final int startMin;
  final int endMin;
  final ValueChanged<String> onDateSelected;
  final ValueChanged<int> onStartSelected;
  final ValueChanged<int> onEndSelected;
  final ValueChanged<int> onDurationChanged;
  final int conflictCount;
  final String? conflictingTaskTitle;

  int get durationMin => (endMin - startMin).clamp(5, 1440);

  Future<void> _pickTime(BuildContext context, int initialMin, ValueChanged<int> onPicked) async {
    final initial = TimeUtils.minutesToTimeOfDay(initialMin);
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: FlowColors.primary,
              surface: FlowColors.surface,
              onSurface: Colors.white,
            ),
            dialogTheme: const DialogThemeData(
              backgroundColor: FlowColors.surface,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      onPicked(TimeUtils.timeOfDayToMinutes(picked));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161424),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF262244), width: 1),
      ),
      child: Column(
        children: [
          // Date Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: FlowColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.calendar_today_rounded, size: 16, color: FlowColors.primaryLight),
              ),
              const SizedBox(width: 12),
              const Text(
                'Date',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
              ),
              const Spacer(),
              Text(
                dateKey,
                style: const TextStyle(fontSize: 13, color: FlowColors.primaryLight, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Color(0xFF262244), height: 1),
          const SizedBox(height: 16),

          // Start & End Row
          Row(
            children: [
              // Start Box
              Expanded(
                child: InkWell(
                  onTap: () => _pickTime(context, startMin, onStartSelected),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1F1C33),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF332F52), width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('START', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF8E8CA3))),
                        const SizedBox(height: 4),
                        Text(
                          TimeUtils.formatMinutesToTime(startMin),
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // End Box
              Expanded(
                child: InkWell(
                  onTap: () => _pickTime(context, endMin, onEndSelected),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1F1C33),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF332F52), width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('END', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF8E8CA3))),
                        const SizedBox(height: 4),
                        Text(
                          TimeUtils.formatMinutesToTime(endMin),
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Duration Stepper Row
          Row(
            children: [
              const Icon(Icons.hourglass_bottom_rounded, size: 16, color: Color(0xFF8E8CA3)),
              const SizedBox(width: 8),
              const Text('Duration', style: TextStyle(fontSize: 13, color: Color(0xFF8E8CA3))),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.remove_circle_outline_rounded, size: 20, color: Color(0xFF8E8CA3)),
                onPressed: durationMin > 15 ? () => onDurationChanged(durationMin - 15) : null,
              ),
              Text(
                TimeUtils.formatDuration(durationMin),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline_rounded, size: 20, color: FlowColors.primaryLight),
                onPressed: () => onDurationChanged(durationMin + 15),
              ),
            ],
          ),

          // Live Conflict Check
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: conflictCount > 0
                  ? FlowColors.warning.withValues(alpha: 0.12)
                  : FlowColors.success.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  conflictCount > 0 ? Icons.warning_amber_rounded : Icons.check_circle_outline_rounded,
                  size: 16,
                  color: conflictCount > 0 ? FlowColors.warning : FlowColors.success,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    conflictCount > 0
                        ? 'Conflicts with $conflictingTaskTitle'
                        : '✓ No conflicts — this slot is free.',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: conflictCount > 0 ? FlowColors.warning : FlowColors.success,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
