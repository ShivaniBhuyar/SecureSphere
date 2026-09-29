import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../theme/app_theme.dart';

enum AvatarState { idle, thinking, talking, warning, listening, happy }

class AssistantAvatar extends StatefulWidget {
  final AvatarState state;
  final double size;

  const AssistantAvatar({
    super.key,
    this.state = AvatarState.idle,
    this.size = 50,
  });

  @override
  State<AssistantAvatar> createState() => _AssistantAvatarState();
}

class _AssistantAvatarState extends State<AssistantAvatar> with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _stateController;

  @override
  void initState() {
    super.initState();
    // Continuous floating/pulsing
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    // State transition animations
    _stateController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
  }

  @override
  void didUpdateWidget(AssistantAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state) {
      _stateController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _mainController.dispose();
    _stateController.dispose();
    super.dispose();
  }

  Color _getPrimaryColor() {
    switch (widget.state) {
      case AvatarState.warning:
        return AppTheme.warningAmber;
      case AvatarState.listening:
        return AppTheme.softViolet;
      case AvatarState.happy:
        return AppTheme.safeGreen;
      case AvatarState.talking:
      case AvatarState.thinking:
      case AvatarState.idle:
        return AppTheme.electricCyan;
    }
  }

  IconData _getIcon() {
    switch (widget.state) {
      case AvatarState.listening:
        return Icons.mic;
      case AvatarState.warning:
        return Icons.warning_amber_rounded;
      case AvatarState.happy:
        return Icons.check_circle_outline;
      case AvatarState.thinking:
        return Icons.more_horiz;
      case AvatarState.talking:
      case AvatarState.idle:
        return Icons.security;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_mainController, _stateController]),
      builder: (context, child) {
        // Calculate physics/animations based on state
        double floatOffset = 0.0;
        double scale = 1.0;
        double pulseIntensity = _mainController.value;

        switch (widget.state) {
          case AvatarState.idle:
            floatOffset = math.sin(_mainController.value * math.pi) * 4;
            break;
          case AvatarState.talking:
            floatOffset = math.sin(_mainController.value * math.pi * 2) * 6;
            scale = 1.05;
            break;
          case AvatarState.thinking:
            pulseIntensity = math.sin(_mainController.value * math.pi * 4).abs();
            break;
          case AvatarState.listening:
            scale = 1.1;
            break;
          case AvatarState.happy:
            floatOffset = -(_stateController.value * 10 * math.sin(_stateController.value * math.pi));
            scale = 1.0 + math.sin(_stateController.value * math.pi) * 0.2;
            break;
          case AvatarState.warning:
            floatOffset = math.sin(_mainController.value * math.pi * 8) * 2; // Shaking
            pulseIntensity = 1.0;
            break;
        }

        final Color currentColor = _getPrimaryColor();

        return Transform.translate(
          offset: Offset(0, floatOffset),
          child: Transform.scale(
            scale: scale,
            child: SizedBox(
              width: widget.size,
              height: widget.size,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Ambient Glow
                  Container(
                    width: widget.size * 0.9,
                    height: widget.size * 0.9,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: currentColor.withValues(alpha: 0.2 + (pulseIntensity * 0.3)),
                          blurRadius: 15 + (pulseIntensity * 10),
                          spreadRadius: 2 + (pulseIntensity * 4),
                        ),
                      ],
                    ),
                  ),
                  
                  // Translucent Glass Orb
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.deepNavy.withValues(alpha: 0.8),
                      border: Border.all(
                        color: currentColor.withValues(alpha: 0.5),
                        width: 1.5,
                      ),
                      gradient: RadialGradient(
                        colors: [
                          currentColor.withValues(alpha: 0.2),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                  
                  // Inner Core / Icon
                  Icon(
                    _getIcon(),
                    color: currentColor.withValues(alpha: 0.8 + (pulseIntensity * 0.2)),
                    size: widget.size * 0.5,
                  ),
                  
                  // Network details (tiny dots on the border)
                  if (widget.state == AvatarState.thinking)
                    ...List.generate(3, (index) {
                      final angle = (_mainController.value * 2 * math.pi) + (index * math.pi * 2 / 3);
                      return Transform.translate(
                        offset: Offset(
                          math.cos(angle) * (widget.size / 2),
                          math.sin(angle) * (widget.size / 2),
                        ),
                        child: Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: currentColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
