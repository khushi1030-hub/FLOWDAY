import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import '../../../../core/theme/flow_colors.dart';
import '../../../../core/theme/flow_radii.dart';
import '../../../../core/theme/flow_spacing.dart';
import '../providers/schedule_providers.dart';

/// Horizontal 7-day strip allowing quick switching between days of the week.
///
/// Matches Screen 08 layout:
/// - 7 days of the selected week (Sun to Sat).
/// - Selected day is highlighted in a lavender card with white text and indicator dot.
/// - Other days display day abbreviation, date number, and an activity indicator dot.
class WeekDayStrip extends ConsumerWidget {
  const WeekDayStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDateKey = ref.watch(selectedScheduleDateProvider);
    final parts = selectedDateKey.split('-');
    final selectedDate = DateTime(
      int.tryParse(parts[0]) ?? 2026,
      int.tryParse(parts[1]) ?? 1,
      int.tryParse(parts[2]) ?? 1,
    );

    // Calculate Sunday (start of week) for the week containing selectedDate
    // In Dart: weekday is 1 for Mon, 7 for Sun.
    final daysSinceSunday = selectedDate.weekday % 7;
    final sunday = selectedDate.subtract(Duration(days: daysSinceSunday));

    final weekDays = List.generate(7, (index) => sunday.add(Duration(days: index)));

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: FlowSpacing.space16,
        vertical: FlowSpacing.space8,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: weekDays.map((date) {
          final y = date.year.toString().padLeft(4, '0');
          final m = date.month.toString().padLeft(2, '0');
          final d = date.day.toString().padLeft(2, '0');
          final dateKey = '$y-$m-$d';
          final isSelected = dateKey == selectedDateKey;

          final dayName = DateFormat('E').format(date); // Sun, Mon...
          final dayNumber = date.day.toString();

          return Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                ref.read(selectedScheduleDateProvider.notifier).selectDate(dateKey);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: FlowSpacing.space2),
                padding: const EdgeInsets.symmetric(vertical: FlowSpacing.space10),
                decoration: BoxDecoration(
                  color: isSelected ? FlowColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(FlowRadii.squircle),
                  border: isSelected
                      ? null
                      : Border.all(color: FlowColors.surfaceBorderSubtle, width: 1),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        dayName,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? FlowColors.textPrimary : FlowColors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: FlowSpacing.space4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        dayNumber,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: FlowColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: FlowSpacing.space6),
                    // Activity indicator dot
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected ? Colors.white : FlowColors.primaryLight.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
