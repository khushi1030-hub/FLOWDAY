import 'package:material_ui/material_ui.dart';
import '../theme/flow_colors.dart';
import '../theme/flow_typography.dart';
import 'flow_buttons.dart';

/// Modal bottom sheet wrapper with drag handle, title, and close button.
class FlowBottomSheetContainer extends StatelessWidget {
  const FlowBottomSheetContainer({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
    this.showClose = true,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final bool showClose;

  static Future<T?> show<T>({
    required BuildContext context,
    required WidgetBuilder builder,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: FlowColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: builder,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: FlowColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Centered drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFF4B5563),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: FlowTypography.headlineMedium),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(subtitle!, style: FlowTypography.bodyLarge),
                    ],
                  ],
                ),
              ),
              if (showClose)
                FlowIconButton(
                  size: 32,
                  icon: const Icon(Icons.close_rounded, size: 18, color: FlowColors.textSecondary),
                  onPressed: () => Navigator.of(context).pop(),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Content
          child,
        ],
      ),
    );
  }
}
