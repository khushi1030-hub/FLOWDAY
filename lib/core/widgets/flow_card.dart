import 'package:material_ui/material_ui.dart';
import '../theme/flow_colors.dart';
import '../theme/flow_typography.dart';

/// Reusable dark surface card matching FlowDay specs.
class FlowCard extends StatelessWidget {
  const FlowCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.backgroundColor = FlowColors.surface,
    this.borderColor = FlowColors.surfaceBorder,
    this.borderRadius = 20,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color backgroundColor;
  final Color borderColor;
  final double borderRadius;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cardWidget = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: child,
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        child: cardWidget,
      );
    }

    return cardWidget;
  }
}

/// Compact recessed Stat Tile (e.g. "DONE / 3", "REMAINING / 5", "FOCUS / 1h 24m").
class FlowStatTile extends StatelessWidget {
  const FlowStatTile({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.accentColor,
    this.subtitle,
  });

  final String label;
  final String value;
  final Widget? icon;
  final Color? accentColor;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1A2F),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: FlowColors.surfaceBorderSubtle, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                icon!,
                const SizedBox(width: 6),
              ],
              Text(
                label.toUpperCase(),
                style: FlowTypography.labelSmall.copyWith(
                  color: FlowColors.textMuted,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: FlowTypography.headlineMedium.copyWith(
              color: accentColor ?? FlowColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: FlowTypography.bodyMedium.copyWith(
                fontSize: 11,
                color: FlowColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
