import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/flow_colors.dart';
import '../../../../core/theme/flow_radii.dart';
import '../../../../core/theme/flow_spacing.dart';

/// Tactile, full-width bi-directional swipe slider for Screen 12 Alarm.
///
/// Swiping anywhere on the track towards the right completes the task.
/// Swiping towards the left delays / marks the task not completed.
/// Releasing before threshold smoothly springs back to center.
class AlarmSwipeSlider extends StatefulWidget {
  const AlarmSwipeSlider({
    super.key,
    required this.onComplete,
    required this.onDelay,
  });

  final VoidCallback onComplete;
  final VoidCallback onDelay;

  @override
  State<AlarmSwipeSlider> createState() => _AlarmSwipeSliderState();
}

class _AlarmSwipeSliderState extends State<AlarmSwipeSlider>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late Animation<double> _thumbAnimation;

  // Normalized thumb position: 0.0 (far left) to 1.0 (far right). Center is 0.5.
  double _position = 0.5;
  bool _hasTriggeredHaptic = false;
  bool _isActionTriggered = false;

  static const double _thumbWidth = 72.0;
  static const double _sliderHeight = 60.0;
  static const double _rightThreshold = 0.72;
  static const double _leftThreshold = 0.28;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    )..addListener(() {
        setState(() {
          _position = _thumbAnimation.value;
        });
      });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _onDragStart(DragStartDetails details) {
    if (_isActionTriggered) return;
    _animController.stop();
    _hasTriggeredHaptic = false;
  }

  void _onDragUpdate(DragUpdateDetails details, double trackWidth) {
    if (_isActionTriggered) return;
    final maxTravel = trackWidth - _thumbWidth;
    if (maxTravel <= 0) return;

    final delta = details.primaryDelta ?? 0.0;
    final deltaNormalized = delta / maxTravel;

    setState(() {
      _position = (_position + deltaNormalized).clamp(0.0, 1.0);
    });

    if (!_hasTriggeredHaptic) {
      if (_position >= _rightThreshold || _position <= _leftThreshold) {
        HapticFeedback.mediumImpact();
        _hasTriggeredHaptic = true;
      }
    } else {
      if (_position > _leftThreshold && _position < _rightThreshold) {
        _hasTriggeredHaptic = false;
      }
    }
  }

  void _onDragEnd(DragEndDetails details) {
    if (_isActionTriggered) return;

    if (_position >= _rightThreshold) {
      _isActionTriggered = true;
      HapticFeedback.heavyImpact();
      widget.onComplete();
    } else if (_position <= _leftThreshold) {
      _isActionTriggered = true;
      HapticFeedback.heavyImpact();
      widget.onDelay();
    } else {
      // Snap back to center
      _thumbAnimation = Tween<double>(
        begin: _position,
        end: 0.5,
      ).animate(
        CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
      );
      _animController.forward(from: 0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final trackWidth = constraints.maxWidth;
        final maxTravel = trackWidth - _thumbWidth;
        final thumbLeft = (_position * maxTravel).clamp(0.0, maxTravel);

        // Dynamic background tint based on swipe direction
        Color dynamicBackgroundColor = FlowColors.surface;
        if (_position > 0.5) {
          final intensity = ((_position - 0.5) * 2).clamp(0.0, 1.0);
          dynamicBackgroundColor = Color.lerp(
            FlowColors.surface,
            FlowColors.success.withValues(alpha: 0.15),
            intensity,
          )!;
        } else if (_position < 0.5) {
          final intensity = ((0.5 - _position) * 2).clamp(0.0, 1.0);
          dynamicBackgroundColor = Color.lerp(
            FlowColors.surface,
            FlowColors.error.withValues(alpha: 0.15),
            intensity,
          )!;
        }

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragStart: _onDragStart,
          onHorizontalDragUpdate: (d) => _onDragUpdate(d, trackWidth),
          onHorizontalDragEnd: _onDragEnd,
          onHorizontalDragCancel: () => _onDragEnd(DragEndDetails()),
          child: Container(
            height: _sliderHeight,
            width: double.infinity,
            decoration: BoxDecoration(
              color: dynamicBackgroundColor,
              borderRadius: BorderRadius.circular(FlowRadii.pill),
              border: Border.all(
                color: _position >= _rightThreshold
                    ? FlowColors.success.withValues(alpha: 0.6)
                    : (_position <= _leftThreshold
                        ? FlowColors.error.withValues(alpha: 0.6)
                        : FlowColors.surfaceBorder),
                width: 1.5,
              ),
            ),
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                // Left Label: Not completed
                Positioned(
                  left: FlowSpacing.space16,
                  child: Text(
                    '< Not completed',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _position < 0.4
                          ? FlowColors.error
                          : FlowColors.error.withValues(alpha: 0.7),
                    ),
                  ),
                ),

                // Right Label: Completed
                Positioned(
                  right: FlowSpacing.space16,
                  child: Text(
                    'Completed >',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _position > 0.6
                          ? FlowColors.success
                          : FlowColors.success.withValues(alpha: 0.7),
                    ),
                  ),
                ),

                // Center Thumb / Handle
                Positioned(
                  left: thumbLeft,
                  child: Container(
                    width: _thumbWidth,
                    height: _sliderHeight - 10,
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(FlowRadii.pill),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 13,
                            color: _position < 0.4
                                ? FlowColors.error
                                : FlowColors.textSecondary,
                          ),
                          const SizedBox(width: 3),
                          Icon(
                            Icons.circle,
                            size: 8,
                            color: _position > 0.6
                                ? FlowColors.success
                                : (_position < 0.4
                                    ? FlowColors.error
                                    : FlowColors.primary),
                          ),
                          const SizedBox(width: 3),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 13,
                            color: _position > 0.6
                                ? FlowColors.success
                                : FlowColors.textSecondary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
