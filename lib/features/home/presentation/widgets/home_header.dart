import 'package:material_ui/material_ui.dart';
import '../../../../core/theme/flow_colors.dart';
import '../../../../core/theme/flow_spacing.dart';
import '../../../../core/theme/flow_typography.dart';

/// Top Bar for Screen 07: Home Dashboard with initials avatar, dynamic greeting, and bell action.
class HomeHeader extends StatelessWidget {
  const HomeHeader({
    super.key,
    required this.formattedDate,
    required this.greeting,
    required this.userName,
    this.onBellTap,
  });

  final String formattedDate;
  final String greeting;
  final String userName;
  final VoidCallback? onBellTap;

  /// Derives user initials from name (e.g. "Alex Morgan" -> "AM", "Khushi" -> "K", empty -> "U").
  String get initials {
    final trimmed = userName.trim();
    if (trimmed.isEmpty) return 'U';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return trimmed[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: FlowSpacing.space16,
        vertical: FlowSpacing.space8,
      ),
      child: Row(
        children: [
          // Circular Initials Avatar (42dp)
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: FlowColors.surfaceElevated,
              border: Border.all(color: FlowColors.surfaceBorder, width: 1.5),
            ),
            alignment: Alignment.center,
            child: Text(
              initials,
              style: FlowTypography.titleMedium.copyWith(
                color: FlowColors.primaryLight,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: FlowSpacing.space12),

          // Date & Greeting column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  formattedDate,
                  style: FlowTypography.labelMedium.copyWith(
                    color: FlowColors.textSecondary,
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: FlowSpacing.space2),
                Text(
                  greeting,
                  style: FlowTypography.headlineMedium.copyWith(
                    color: FlowColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Bell Button (40dp circle, no unread badge per Decision 2)
          IconButton(
            onPressed: onBellTap ??
                () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Notifications coming soon'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
            icon: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Color(0xFF1D1B2B),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.notifications_none_rounded,
                color: FlowColors.textPrimary,
                size: 20,
              ),
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          ),
        ],
      ),
    );
  }
}
