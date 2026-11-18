import 'package:material_ui/material_ui.dart';

/// Design tokens for corner radii across FlowDay per UI_SPEC.md.
class FlowRadii {
  const FlowRadii._();

  static const double pill = 999.0;
  static const double card = 22.0;
  static const double sheet = 24.0;
  static const double squircle = 16.0;
  static const double badge = 8.0;
  static const double tile = 14.0;
  static const double button = 28.0;

  static final BorderRadius pillRadius = BorderRadius.circular(pill);
  static final BorderRadius cardRadius = BorderRadius.circular(card);
  static final BorderRadius sheetRadius = BorderRadius.circular(sheet);
  static final BorderRadius squircleRadius = BorderRadius.circular(squircle);
  static final BorderRadius badgeRadius = BorderRadius.circular(badge);
  static final BorderRadius tileRadius = BorderRadius.circular(tile);
  static final BorderRadius buttonRadius = BorderRadius.circular(button);
}
