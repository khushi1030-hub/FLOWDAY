import 'package:material_ui/material_ui.dart';

/// Design tokens: Exact color palette extracted from FlowDay UX designs.
class FlowColors {
  FlowColors._();

  // Backgrounds & Surface
  static const Color background = Color(0xFF0B0B14); // Pure dark screen background
  static const Color surface = Color(0xFF161426); // Default card surface
  static const Color surfaceElevated = Color(0xFF1D1B32); // Highlighted / selected card surface
  static const Color surfaceDark = Color(0xFF12101F); // Recessed inputs & containers
  static const Color surfaceBorder = Color(0xFF262244); // Standard 1px card border
  static const Color surfaceBorderSubtle = Color(0xFF1D1A33);

  // Brand / Primary Violet
  static const Color primary = Color(0xFF7C6EF6); // Main CTA button / active purple
  static const Color primaryLight = Color(0xFF9B8AFB); // Lavender text & glowing accents
  static const Color primaryDark = Color(0xFF5E4EE6); // Pressed CTA state
  static const Color primaryContainer = Color(0xFF221F45); // Lavender-tinted background
  static const Color primaryGlow = Color(0x667C6EF6); // 40% opacity button shadow

  // Pure Neutrals
  static const Color textPrimary = Color(0xFFFFFFFF); // Primary headings & text
  static const Color textSecondary = Color(0xFF9CA3AF); // Subtitles, metadata, timestamps
  static const Color textMuted = Color(0xFF6B7280); // Captions, inactive navigation
  static const Color textDisabled = Color(0xFF4B5563);

  // Semantic Status Colors
  static const Color success = Color(0xFF10B981); // Mint green (Completed, On track)
  static const Color successContainer = Color(0xFF0F2B20);
  static const Color successBorder = Color(0xFF1D4A38);

  static const Color warning = Color(0xFFF59E0B); // Amber / Orange (Medium priority, Streak)
  static const Color warningContainer = Color(0xFF2E2015);
  static const Color warningBorder = Color(0xFF4D3418);

  static const Color error = Color(0xFFEF4444); // Coral / Red (High priority, Overdue, Conflict)
  static const Color errorContainer = Color(0xFF2D151B);
  static const Color errorBorder = Color(0xFF4D1F28);

  static const Color info = Color(0xFF60A5FA); // Blue / Teal (Low priority, Info)
  static const Color infoContainer = Color(0xFF152238);

  // Task Category Accent Colors (ARGB)
  static const Color catStudy = Color(0xFF818CF8); // Lavender Blue
  static const Color catWork = Color(0xFF34D399); // Mint
  static const Color catHealth = Color(0xFFF472B6); // Soft Pink
  static const Color catPersonal = Color(0xFFFBBF24); // Warm Amber
  static const Color catSocial = Color(0xFFFB923C); // Warm Coral
  static const Color catBreak = Color(0xFFD97706); // Coffee / Ochre
}
