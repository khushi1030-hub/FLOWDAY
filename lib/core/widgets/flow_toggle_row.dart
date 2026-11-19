import 'package:material_ui/material_ui.dart';
import '../theme/flow_colors.dart';
import '../theme/flow_typography.dart';

/// Reusable toggle setting row with squircle icon, title, subtitle, and adaptive switch.
class FlowToggleRow extends StatelessWidget {
  const FlowToggleRow({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.iconColor,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final Color? iconColor;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: FlowColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: FlowColors.surfaceBorder, width: 1),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: (iconColor ?? FlowColors.primary).withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Icon(
                icon,
                size: 20,
                color: iconColor ?? FlowColors.primary,
              ),
            ),
            const SizedBox(width: 14),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: FlowTypography.titleMedium,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: FlowTypography.bodyMedium.copyWith(
                      fontSize: 12,
                      color: FlowColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: FlowColors.primary,
          ),
        ],
      ),
    );
  }
}
