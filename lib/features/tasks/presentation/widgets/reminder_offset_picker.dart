import 'package:material_ui/material_ui.dart';
import '../../../../core/theme/flow_colors.dart';

class ReminderOffsetPicker extends StatelessWidget {
  const ReminderOffsetPicker({
    super.key,
    required this.priority,
    required this.isFixed,
    required this.alarmEnabled,
    required this.reminderOffsetMin,
    required this.onPriorityChanged,
    required this.onIsFixedChanged,
    required this.onAlarmEnabledChanged,
    required this.onReminderOffsetChanged,
  });

  final int priority;
  final bool isFixed;
  final bool alarmEnabled;
  final int? reminderOffsetMin;
  final ValueChanged<int> onPriorityChanged;
  final ValueChanged<bool> onIsFixedChanged;
  final ValueChanged<bool> onAlarmEnabledChanged;
  final ValueChanged<int?> onReminderOffsetChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // PRIORITY SELECTOR
        const Text(
          'PRIORITY',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF71717A), letterSpacing: 1.2),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildPriorityChip(0, '• Low', FlowColors.catStudy),
            const SizedBox(width: 8),
            _buildPriorityChip(1, '• Medium', FlowColors.warning),
            const SizedBox(width: 8),
            _buildPriorityChip(2, '• High', FlowColors.error),
          ],
        ),
        const SizedBox(height: 20),

        // FLEXIBLE TASK TOGGLE CARD
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF161424),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF262244), width: 1),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          isFixed ? 'Fixed appointment 🔒' : 'Flexible task ↔',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isFixed
                          ? 'Engine will never move or split this task'
                          : 'FlowDay may suggest moving it if plans change',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF8E8CA3)),
                    ),
                  ],
                ),
              ),
              Switch(
                value: !isFixed,
                activeThumbColor: FlowColors.primary,
                onChanged: (val) => onIsFixedChanged(!val),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // REMINDERS & ALARM CARD
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF161424),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF262244), width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Reminder Offset row
              const Text(
                'REMINDER',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF71717A), letterSpacing: 1.2),
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildOffsetChip(null, 'None'),
                    const SizedBox(width: 8),
                    _buildOffsetChip(0, 'At start'),
                    const SizedBox(width: 8),
                    _buildOffsetChip(5, '5m before'),
                    const SizedBox(width: 8),
                    _buildOffsetChip(10, '10m before'),
                    const SizedBox(width: 8),
                    _buildOffsetChip(15, '15m before'),
                    const SizedBox(width: 8),
                    _buildOffsetChip(30, '30m before'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Divider(color: Color(0xFF262244), height: 1),
              const SizedBox(height: 12),

              // End-of-task Alarm row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: FlowColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.alarm_rounded, size: 16, color: FlowColors.primaryLight),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('End-of-task alarm', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
                        SizedBox(height: 2),
                        Text('Full-screen alert when time is up', style: TextStyle(fontSize: 11, color: Color(0xFF8E8CA3))),
                      ],
                    ),
                  ),
                  Switch(
                    value: alarmEnabled,
                    activeThumbColor: FlowColors.primary,
                    onChanged: onAlarmEnabledChanged,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPriorityChip(int level, String label, Color dotColor) {
    final isSelected = priority == level;
    return GestureDetector(
      onTap: () => onPriorityChanged(level),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF221F36) : const Color(0xFF161424),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? FlowColors.primary : const Color(0xFF262244),
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? dotColor : const Color(0xFF8E8CA3),
          ),
        ),
      ),
    );
  }

  Widget _buildOffsetChip(int? offset, String label) {
    final isSelected = reminderOffsetMin == offset;
    return GestureDetector(
      onTap: () => onReminderOffsetChanged(offset),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : const Color(0xFF1F1C33),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.white : const Color(0xFF332F52),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? const Color(0xFF0B0B14) : const Color(0xFF8E8CA3),
          ),
        ),
      ),
    );
  }
}

