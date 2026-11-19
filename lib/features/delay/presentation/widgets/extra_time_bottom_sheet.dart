import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/providers/database_providers.dart';
import '../../../../core/theme/flow_colors.dart';
import '../../../../core/theme/flow_typography.dart';
import '../../../../core/utils/time_utils.dart';
import '../../../tasks/domain/entities/task.dart';
import '../../domain/delay_calculator.dart';

/// Screen 15: Extra Time Bottom Sheet.
///
/// Lets the user choose an extra-time duration preset (10m, 15m, 30m, 45m, 1h, Custom),
/// preview the new end time and the downstream ripple impact on subsequent tasks and breaks,
/// and apply the changes atomically to the database.
class ExtraTimeBottomSheet extends ConsumerStatefulWidget {
  const ExtraTimeBottomSheet({
    super.key,
    required this.task,
    required this.dayTasks,
    this.initialMinutes = 30,
  });

  final Task task;
  final List<Task> dayTasks;
  final int initialMinutes;

  static Future<void> show(
    BuildContext context, {
    required Task task,
    required List<Task> dayTasks,
    int initialMinutes = 30,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ExtraTimeBottomSheet(
        task: task,
        dayTasks: dayTasks,
        initialMinutes: initialMinutes,
      ),
    );
  }

  @override
  ConsumerState<ExtraTimeBottomSheet> createState() => _ExtraTimeBottomSheetState();
}

class _ExtraTimeBottomSheetState extends ConsumerState<ExtraTimeBottomSheet> {
  late int _selectedMinutes;
  bool _isCustom = false;
  final _calculator = const DelayCalculator();

  @override
  void initState() {
    super.initState();
    _selectedMinutes = widget.initialMinutes;
    _isCustom = ![10, 15, 30, 45, 60].contains(_selectedMinutes);
  }

  Future<void> _pickCustomMinutes() async {
    int tempMinutes = _selectedMinutes;
    final result = await showDialog<int>(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              backgroundColor: FlowColors.surface,
              title: const Text('Custom Extra Time', style: FlowTypography.headlineMedium),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$tempMinutes minutes',
                    style: FlowTypography.headlineLarge.copyWith(color: FlowColors.primaryLight),
                  ),
                  const SizedBox(height: 16),
                  Slider(
                    value: tempMinutes.toDouble(),
                    min: 5,
                    max: 120,
                    divisions: 23,
                    activeColor: FlowColors.primary,
                    inactiveColor: FlowColors.surfaceBorder,
                    onChanged: (val) {
                      setDialogState(() {
                        tempMinutes = val.round();
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogCtx).pop(),
                  child: const Text('Cancel', style: TextStyle(color: FlowColors.textMuted)),
                ),
                TextButton(
                  onPressed: () => Navigator.of(dialogCtx).pop(tempMinutes),
                  child: const Text('Set', style: TextStyle(color: FlowColors.primaryLight)),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null && mounted) {
      setState(() {
        _selectedMinutes = result;
        _isCustom = true;
      });
    }
  }

  Future<void> _applyChanges(DelayCalculationResult calculation) async {
    final taskRepo = ref.read(taskRepositoryProvider);
    final extendedTask = widget.task.copyWith(
      endMin: calculation.newEndMin,
      wasRescheduled: true,
    );

    await taskRepo.applyDelayShift(
      extendedTask: extendedTask,
      shiftedTasks: calculation.tasksToUpdate,
    );

    if (!mounted) return;

    // Pop the bottom sheet
    Navigator.of(context).pop();

    // Also pop the delay screen back to the previous screen (Home/Schedule)
    try {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/home');
      }
    } catch (_) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Schedule updated: ${widget.task.title} extended by ${_selectedMinutes}m',
          style: FlowTypography.bodyMedium.copyWith(color: FlowColors.textPrimary),
        ),
        backgroundColor: FlowColors.surface,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const sleepMin = 1380; // 23:00

    final calculation = _calculator.calculateImpact(
      delayedTask: widget.task,
      extraMinutes: _selectedMinutes,
      dayTasks: widget.dayTasks,
      dayEndMin: sleepMin,
    );

    final presetOptions = [
      {'label': '10 minutes', 'minutes': 10},
      {'label': '15 minutes', 'minutes': 15},
      {'label': '30 minutes', 'minutes': 30},
      {'label': '45 minutes', 'minutes': 45},
      {'label': '1 hour', 'minutes': 60},
    ];

    return Container(
      decoration: const BoxDecoration(
        color: FlowColors.surfaceDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 12,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Drag Handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: FlowColors.textDisabled,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Header Row: Title & Close Button
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'How much more time\ndo you need?',
                          style: FlowTypography.headlineMedium.copyWith(
                            color: FlowColors.textPrimary,
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(
                              Icons.code_rounded,
                              size: 14,
                              color: FlowColors.primaryLight,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '${widget.task.title} · originally ends ${TimeUtils.formatMinutesToTime(widget.task.endMin)}',
                                style: FlowTypography.bodySmall.copyWith(
                                  color: FlowColors.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: FlowColors.surface,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        size: 20,
                        color: FlowColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 2. Grid of 6 Duration Tiles
              GridView.count(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 2.1,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  ...presetOptions.map((opt) {
                    final minutes = opt['minutes'] as int;
                    final isSelected = !_isCustom && _selectedMinutes == minutes;
                    return _DurationTile(
                      label: opt['label'] as String,
                      isSelected: isSelected,
                      onTap: () {
                        setState(() {
                          _selectedMinutes = minutes;
                          _isCustom = false;
                        });
                      },
                    );
                  }),
                  _DurationTile(
                    label: _isCustom ? '$_selectedMinutes min' : 'Custom',
                    icon: Icons.tune_rounded,
                    isSelected: _isCustom,
                    onTap: _pickCustomMinutes,
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // 3. Result Card
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: FlowColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: FlowColors.surfaceBorder),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'NEW END TIME',
                          style: FlowTypography.labelSmall.copyWith(
                            color: FlowColors.textMuted,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              TimeUtils.formatMinutesToTime(widget.task.endMin),
                              style: FlowTypography.bodyLarge.copyWith(
                                color: FlowColors.textSecondary,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.arrow_forward_rounded,
                              size: 14,
                              color: FlowColors.textSecondary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              TimeUtils.formatMinutesToTime(calculation.newEndMin),
                              style: FlowTypography.headlineMedium.copyWith(
                                color: FlowColors.textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: FlowColors.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '+$_selectedMinutes min',
                        style: FlowTypography.bodySmall.copyWith(
                          color: FlowColors.primaryLight,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // 4. Downstream Ripple Impact List
              Text(
                'IMPACT ON TODAY',
                style: FlowTypography.labelSmall.copyWith(
                  color: FlowColors.textMuted,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 8),

              if (calculation.impactedItems.isEmpty)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: FlowColors.surface,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle_outline_rounded,
                        color: FlowColors.success,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Free time ahead — no other tasks affected!',
                          style: FlowTypography.bodyMedium.copyWith(color: FlowColors.textPrimary),
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...calculation.impactedItems.map((item) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _ImpactItemCard(item: item),
                  );
                }),

              // 5. Warning note if collision with fixed task
              if (calculation.hasFixedCollision) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: FlowColors.errorContainer,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: FlowColors.errorBorder),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.auto_awesome_rounded,
                        color: FlowColors.primaryLight,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Extending ${widget.task.title} would overlap your fixed ${calculation.firstConflictingTask?.title ?? "task"} — Smart Rescheduling will offer options.',
                          style: FlowTypography.bodySmall.copyWith(
                            color: const Color(0xFFE9D5FF),
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 22),

              // 6. Action Buttons Row
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: FlowColors.surfaceBorder),
                          backgroundColor: FlowColors.surface,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: FlowTypography.bodyLarge.copyWith(
                            color: FlowColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          if (calculation.hasFixedCollision) {
                            Navigator.of(context).pop();
                            context.push('/reschedule');
                          } else {
                            _applyChanges(calculation);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: FlowColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          calculation.hasFixedCollision ? 'Reschedule' : 'Apply Changes',
                          style: FlowTypography.bodyLarge.copyWith(
                            color: FlowColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DurationTile extends StatelessWidget {
  const _DurationTile({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? FlowColors.textPrimary : FlowColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? FlowColors.textPrimary : FlowColors.surfaceBorder,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 16,
                  color: isSelected ? FlowColors.background : FlowColors.textPrimary,
                ),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: FlowTypography.bodySmall.copyWith(
                  color: isSelected ? FlowColors.background : FlowColors.textPrimary,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImpactItemCard extends StatelessWidget {
  const _ImpactItemCard({required this.item});

  final DelayImpactItem item;

  @override
  Widget build(BuildContext context) {
    Color chipBg;
    Color chipText;
    String chipLabel;
    IconData? chipIcon;

    switch (item.impactType) {
      case DelayImpactType.shifted:
        chipBg = FlowColors.infoContainer;
        chipText = FlowColors.info;
        chipLabel = 'Shifted';
        break;
      case DelayImpactType.breakShortened:
        chipBg = FlowColors.warningContainer;
        chipText = FlowColors.warning;
        chipLabel = item.message ?? 'Shortened to 15m';
        break;
      case DelayImpactType.overlapsFixed:
        chipBg = FlowColors.errorContainer;
        chipText = FlowColors.error;
        chipLabel = item.message ?? 'Overlaps fixed';
        break;
      case DelayImpactType.fixed:
        chipBg = const Color(0xFF27272A);
        chipText = FlowColors.textSecondary;
        chipLabel = 'Fixed';
        chipIcon = Icons.lock_rounded;
        break;
    }

    String timeDescription;
    if (item.impactType == DelayImpactType.fixed) {
      timeDescription = TimeUtils.formatMinutesToTime(item.originalStartMin);
    } else if (item.impactType == DelayImpactType.breakShortened) {
      timeDescription = '${item.task.durationMin} min';
    } else {
      timeDescription =
          '${TimeUtils.formatMinutesToTime(item.originalStartMin)} -> ${TimeUtils.formatMinutesToTime(item.newStartMin)}';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: FlowColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: item.impactType == DelayImpactType.overlapsFixed
              ? FlowColors.errorBorder
              : FlowColors.surfaceBorder,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.task.title,
                  style: FlowTypography.bodyMedium.copyWith(
                    color: FlowColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  timeDescription,
                  style: FlowTypography.bodySmall.copyWith(
                    color: FlowColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: chipBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (chipIcon != null) ...[
                  Icon(chipIcon, size: 12, color: chipText),
                  const SizedBox(width: 4),
                ],
                Text(
                  chipLabel,
                  style: FlowTypography.bodySmall.copyWith(
                    color: chipText,
                    fontWeight: FontWeight.w700,
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
