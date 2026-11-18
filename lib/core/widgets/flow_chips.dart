import 'package:material_ui/material_ui.dart';
import '../theme/flow_colors.dart';
import '../theme/flow_typography.dart';

/// Reusable Chip component matching FlowDay designs.
/// Supports Category, Priority, and Status variants.
class FlowChip extends StatelessWidget {
  const FlowChip({
    super.key,
    required this.label,
    this.isSelected = false,
    this.onTap,
    this.leadingDotColor,
    this.icon,
    this.backgroundColor,
    this.textColor,
    this.borderColor,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
  });

  /// Factory for priority chips (Low, Medium, High).
  factory FlowChip.priority({
    required String priority,
    bool isSelected = false,
    VoidCallback? onTap,
  }) {
    Color dotColor;
    Color textColor;
    Color borderColor;

    switch (priority.toLowerCase()) {
      case 'high':
        dotColor = FlowColors.error;
        textColor = FlowColors.error;
        borderColor = FlowColors.errorBorder;
        break;
      case 'medium':
        dotColor = FlowColors.warning;
        textColor = FlowColors.warning;
        borderColor = FlowColors.warningBorder;
        break;
      case 'low':
      default:
        dotColor = FlowColors.info;
        textColor = FlowColors.info;
        borderColor = FlowColors.infoContainer;
        break;
    }

    return FlowChip(
      label: priority,
      isSelected: isSelected,
      onTap: onTap,
      leadingDotColor: dotColor,
      textColor: isSelected ? textColor : FlowColors.textSecondary,
      borderColor: isSelected ? borderColor : FlowColors.surfaceBorder,
      backgroundColor: isSelected ? borderColor.withValues(alpha: 0.3) : FlowColors.surfaceDark,
    );
  }

  /// Factory for status badge chips (Completed, Pending, Overdue, Shifted, Carried Over).
  factory FlowChip.status({
    required String label,
    Color? color,
    Color? backgroundColor,
    IconData? icon,
  }) {
    final effectiveColor = color ?? FlowColors.textSecondary;
    return FlowChip(
      label: label,
      textColor: effectiveColor,
      borderColor: effectiveColor.withValues(alpha: 0.4),
      backgroundColor: backgroundColor ?? effectiveColor.withValues(alpha: 0.12),
      icon: icon != null ? Icon(icon, size: 12, color: effectiveColor) : null,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    );
  }

  final String label;
  final bool isSelected;
  final VoidCallback? onTap;
  final Color? leadingDotColor;
  final Widget? icon;
  final Color? backgroundColor;
  final Color? textColor;
  final Color? borderColor;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final effectiveBg = isSelected
        ? (backgroundColor ?? Colors.white)
        : (backgroundColor ?? FlowColors.surfaceDark);
    final effectiveText = isSelected
        ? (textColor ?? const Color(0xFF0B0B14))
        : (textColor ?? FlowColors.textSecondary);
    final effectiveBorder = isSelected
        ? (borderColor ?? Colors.white)
        : (borderColor ?? FlowColors.surfaceBorder);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: effectiveBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: effectiveBorder, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (leadingDotColor != null) ...[
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: leadingDotColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
            ],
            if (icon != null) ...[
              icon!,
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: FlowTypography.labelMedium.copyWith(
                color: effectiveText,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
