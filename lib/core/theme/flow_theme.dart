import 'package:material_ui/material_ui.dart';
import 'flow_colors.dart';
import 'flow_typography.dart';

/// Pure dark Flutter ThemeData matching the FlowDay dark design system.
class FlowTheme {
  FlowTheme._();

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: FlowColors.background,
      fontFamily: FlowTypography.fontFamily,
      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: FlowColors.primary,
        onPrimary: Colors.white,
        primaryContainer: FlowColors.primaryContainer,
        onPrimaryContainer: FlowColors.primaryLight,
        secondary: FlowColors.primaryLight,
        onSecondary: Colors.black,
        surface: FlowColors.surface,
        onSurface: FlowColors.textPrimary,
        error: FlowColors.error,
        onError: Colors.white,
      ),
      textTheme: const TextTheme(
        displayLarge: FlowTypography.displayLarge,
        displayMedium: FlowTypography.displayMedium,
        headlineLarge: FlowTypography.headlineLarge,
        headlineMedium: FlowTypography.headlineMedium,
        titleMedium: FlowTypography.titleMedium,
        bodyLarge: FlowTypography.bodyLarge,
        bodyMedium: FlowTypography.bodyMedium,
        labelLarge: FlowTypography.labelLarge,
        labelMedium: FlowTypography.labelMedium,
        labelSmall: FlowTypography.labelSmall,
      ),
      cardTheme: CardThemeData(
        color: FlowColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: FlowColors.surfaceBorder, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: FlowColors.surface,
        elevation: 16,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: FlowColors.surfaceBorder, width: 1),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: FlowColors.surface,
        elevation: 16,
        modalBackgroundColor: FlowColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: FlowColors.surfaceBorder,
        thickness: 1,
        space: 1,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          return Colors.white;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return FlowColors.primary;
          }
          return FlowColors.surfaceDark;
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return FlowColors.primary;
          }
          return FlowColors.surfaceBorder;
        }),
      ),
    );
  }
}
