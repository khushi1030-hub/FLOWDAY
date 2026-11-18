import 'package:material_ui/material_ui.dart';
import '../theme/flow_colors.dart';
import '../theme/flow_typography.dart';

/// Primary action button: Full-width pill (h: 56dp, radius: 28dp).
/// Variants: Brand Lavender (#7C6EF6) or Solid White (#FFFFFF).
class FlowPrimaryButton extends StatelessWidget {
  const FlowPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isWhite = false,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;
  final bool isWhite;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final Color bgColor = isWhite ? Colors.white : FlowColors.primary;
    final Color textColor = isWhite ? const Color(0xFF0B0B14) : Colors.white;

    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: isWhite
            ? null
            : const [
                BoxShadow(
                  color: FlowColors.primaryGlow,
                  blurRadius: 20,
                  offset: Offset(0, 8),
                ),
              ],
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: textColor,
          disabledBackgroundColor: bgColor.withValues(alpha: 0.5),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24),
        ),
        child: isLoading
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(textColor),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    icon!,
                    const SizedBox(width: 8),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      style: FlowTypography.labelLarge.copyWith(color: textColor),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Secondary action button: Dark card pill (#1A1828, border #2A2640, radius 28dp).
class FlowSecondaryButton extends StatelessWidget {
  const FlowSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        color: FlowColors.surfaceDark,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: FlowColors.surfaceBorder, width: 1),
      ),
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: FlowColors.textPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              icon!,
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Text(
                label,
                style: FlowTypography.titleMedium.copyWith(color: FlowColors.textPrimary),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Circular / Squircle Icon Button used in top bars and actions.
class FlowIconButton extends StatelessWidget {
  const FlowIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.size = 40,
    this.backgroundColor = const Color(0xFF1D1B2B),
    this.borderColor = FlowColors.surfaceBorder,
    this.badge,
  });

  final Widget icon;
  final VoidCallback? onPressed;
  final double size;
  final Color backgroundColor;
  final Color borderColor;
  final Widget? badge;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(size / 2),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: backgroundColor,
              shape: BoxShape.circle,
              border: Border.all(color: borderColor, width: 1),
            ),
            alignment: Alignment.center,
            child: icon,
          ),
        ),
        if (badge != null)
          Positioned(
            top: 2,
            right: 2,
            child: badge!,
          ),
      ],
    );
  }
}
