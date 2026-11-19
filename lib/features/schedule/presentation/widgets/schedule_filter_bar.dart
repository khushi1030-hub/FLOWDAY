import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import '../../../../core/theme/flow_colors.dart';
import '../../../../core/theme/flow_radii.dart';
import '../../../../core/theme/flow_spacing.dart';
import '../providers/schedule_providers.dart';

/// Status filter chips matching Screen 08:
/// - "✓ X completed" (green border `#1E3A2F`, text `#10B981`)
/// - "⭘ Y pending" (grey border `#2B283E`, text `#9CA3AF`)
/// - "⚠ Z overdue" (coral border `#421D24`, text `#EF4444`)
class ScheduleFilterBar extends ConsumerWidget {
  const ScheduleFilterBar({
    super.key,
    required this.completedCount,
    required this.pendingCount,
    required this.overdueCount,
    required this.activeFilter,
  });

  final int completedCount;
  final int pendingCount;
  final int overdueCount;
  final ScheduleFilter activeFilter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(
        horizontal: FlowSpacing.space16,
        vertical: FlowSpacing.space6,
      ),
      child: Row(
        children: [
          _buildFilterChip(
            ref: ref,
            targetFilter: ScheduleFilter.completed,
            label: '✓ $completedCount completed',
            color: FlowColors.success,
            borderColor: const Color(0xFF1E3A2F),
            activeBg: FlowColors.successContainer,
          ),
          const SizedBox(width: FlowSpacing.space8),
          _buildFilterChip(
            ref: ref,
            targetFilter: ScheduleFilter.pending,
            label: '⭘ $pendingCount pending',
            color: FlowColors.textSecondary,
            borderColor: const Color(0xFF2B283E),
            activeBg: const Color(0xFF1F1C33),
          ),
          const SizedBox(width: FlowSpacing.space8),
          _buildFilterChip(
            ref: ref,
            targetFilter: ScheduleFilter.overdue,
            label: '⚠ $overdueCount overdue',
            color: FlowColors.error,
            borderColor: const Color(0xFF421D24),
            activeBg: FlowColors.errorContainer,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required WidgetRef ref,
    required ScheduleFilter targetFilter,
    required String label,
    required Color color,
    required Color borderColor,
    required Color activeBg,
  }) {
    final isSelected = activeFilter == targetFilter;

    return GestureDetector(
      onTap: () {
        final notifier = ref.read(scheduleFilterProvider.notifier);
        if (isSelected) {
          notifier.setFilter(ScheduleFilter.all);
        } else {
          notifier.setFilter(targetFilter);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: FlowSpacing.space12,
          vertical: FlowSpacing.space6,
        ),
        decoration: BoxDecoration(
          color: isSelected ? activeBg : Colors.transparent,
          borderRadius: BorderRadius.circular(FlowRadii.pill),
          border: Border.all(
            color: isSelected ? color : borderColor,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? FlowColors.textPrimary : color,
          ),
        ),
      ),
    );
  }
}
