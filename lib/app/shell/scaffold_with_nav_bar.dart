import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import '../../core/theme/flow_colors.dart';
import '../../core/theme/flow_typography.dart';

/// App scaffold hosting the persistent 4-tab bottom navigation bar.
class ScaffoldWithNavBar extends StatelessWidget {
  const ScaffoldWithNavBar({
    super.key,
    required this.navigationShell,
  });

  final StatefulNavigationShell navigationShell;

  void _onTap(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: FlowColors.background,
          border: Border(
            top: BorderSide(color: FlowColors.surfaceBorderSubtle, width: 1),
          ),
        ),
        padding: const EdgeInsets.only(top: 8, bottom: 12),
        child: SafeArea(
          top: false,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavBarItem(
                key: const ValueKey('tab_home'),
                icon: Icons.home_rounded,
                label: 'Home',
                isSelected: navigationShell.currentIndex == 0,
                onTap: () => _onTap(0),
              ),
              _NavBarItem(
                key: const ValueKey('tab_schedule'),
                icon: Icons.calendar_today_rounded,
                label: 'Schedule',
                isSelected: navigationShell.currentIndex == 1,
                onTap: () => _onTap(1),
              ),
              _NavBarItem(
                key: const ValueKey('tab_insights'),
                icon: Icons.bar_chart_rounded,
                label: 'Insights',
                isSelected: navigationShell.currentIndex == 2,
                onTap: () => _onTap(2),
              ),
              _NavBarItem(
                key: const ValueKey('tab_settings'),
                icon: Icons.settings_rounded,
                label: 'Settings',
                isSelected: navigationShell.currentIndex == 3,
                onTap: () => _onTap(3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  const _NavBarItem({
    super.key,
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? Colors.white : FlowColors.textMuted;

    return InkWell(
      onTap: onTap,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 22, color: color),
          const SizedBox(height: 3),
          Text(
            label,
            style: FlowTypography.labelMedium.copyWith(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: color,
            ),
          ),
          const SizedBox(height: 3),
          // Active lavender dot indicator below active tab
          Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: isSelected ? FlowColors.primary : Colors.transparent,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}
