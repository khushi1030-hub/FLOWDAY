import 'package:material_ui/material_ui.dart';
import '../theme/flow_colors.dart';
import '../theme/flow_typography.dart';
import 'flow_buttons.dart';

/// Calm, encouraging empty state placeholder.
class FlowEmptyState extends StatelessWidget {
  const FlowEmptyState({
    super.key,
    required this.title,
    required this.description,
    this.icon = Icons.calendar_today_outlined,
    this.buttonLabel,
    this.onButtonPressed,
  });

  final String title;
  final String description;
  final IconData icon;
  final String? buttonLabel;
  final VoidCallback? onButtonPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: FlowColors.surfaceElevated,
                shape: BoxShape.circle,
                border: Border.all(color: FlowColors.surfaceBorder, width: 1),
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: 32, color: FlowColors.primaryLight),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: FlowTypography.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: FlowTypography.bodyLarge,
              textAlign: TextAlign.center,
            ),
            if (buttonLabel != null && onButtonPressed != null) ...[
              const SizedBox(height: 24),
              FlowPrimaryButton(
                label: buttonLabel!,
                onPressed: onButtonPressed!,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
