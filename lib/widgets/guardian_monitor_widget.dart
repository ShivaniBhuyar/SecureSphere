import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../theme/app_theme.dart';

class GuardianMonitorWidget extends StatefulWidget {
  final bool isActive;
  final double size;

  const GuardianMonitorWidget({
    super.key,
    required this.isActive,
    this.size = 200,
  });

  @override
  State<GuardianMonitorWidget> createState() => _GuardianMonitorWidgetState();
}

class _GuardianMonitorWidgetState extends State<GuardianMonitorWidget> with TickerProviderStateMixin {
  late AnimationController _orbitController;
  late AnimationController _pulseController;
  late AnimationController _floatController;
  late Animation<double> _pulseAnim;
  late Animation<double> _floatAnim;

  final List<IconData> _sourceIcons = [
    Icons.message_outlined,
    Icons.link,
    Icons.apps,
    Icons.email_outlined,
    Icons.security,
  ];

  @override
  void initState() {
    super.initState();
    _orbitController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 25),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );
    
    _pulseAnim = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOutSine)
    );

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    
    _floatAnim = Tween<double>(begin: -10, end: 10).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOutSine)
    );

    if (widget.isActive) {
      _orbitController.repeat();
      _pulseController.repeat(reverse: true);
      _floatController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(GuardianMonitorWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _orbitController.repeat();
      _pulseController.repeat(reverse: true);
      _floatController.repeat(reverse: true);
    } else if (!widget.isActive && oldWidget.isActive) {
      _orbitController.stop();
      _pulseController.stop();
      _floatController.stop();
    }
  }

  @override
  void dispose() {
    _orbitController.dispose();
    _pulseController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  Widget _buildSmartphone(double size) {
    return AnimatedBuilder(
      animation: _floatController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _floatAnim.value),
          child: Container(
            width: size * 0.45,
            height: size * 0.85,
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(size * 0.08),
              border: Border.all(
                color: widget.isActive ? AppTheme.safeGreen.withValues(alpha: 0.5) : AppTheme.silver.withValues(alpha: 0.5),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.isActive ? AppTheme.safeGreen.withValues(alpha: 0.2) : Colors.transparent,
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF060B19),
                    borderRadius: BorderRadius.circular(size * 0.06),
                  ),
                ),
                Icon(
                  Icons.security,
                  color: widget.isActive 
                      ? AppTheme.safeGreen.withValues(alpha: 0.6 + (_pulseAnim.value - 0.8))
                      : AppTheme.silver.withValues(alpha: 0.3),
                  size: size * 0.15,
                ),
              ],
            ),
          ),
        );
      }
    );
  }

  Widget _buildOrbitingIcons(double size) {
    return AnimatedBuilder(
      animation: _orbitController,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: List.generate(_sourceIcons.length, (index) {
            final double angle = (index / _sourceIcons.length) * 2 * math.pi + (_orbitController.value * 2 * math.pi);
            
            final double x = math.cos(angle) * (size * 0.65);
            final double y = math.sin(angle) * (size * 0.25);
            
            final double zDepth = math.sin(angle); // -1 (back) to 1 (front)
            final double scale = 0.6 + ((zDepth + 1) / 2) * 0.6; // 0.6 to 1.2
            final double opacity = 0.3 + ((zDepth + 1) / 2) * 0.7; // 0.3 to 1.0

            return Transform.translate(
              offset: Offset(x, y),
              child: Transform.scale(
                scale: scale,
                child: Opacity(
                  opacity: widget.isActive ? opacity : opacity * 0.5,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.deepNavy,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: widget.isActive ? AppTheme.electricCyan.withValues(alpha: 0.5) : AppTheme.silver.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Icon(
                      _sourceIcons[index],
                      size: size * 0.08,
                      color: widget.isActive ? Colors.white : AppTheme.silver,
                    ),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return SizedBox(
          width: widget.size * 1.5,
          height: widget.size * 1.2,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer Ambient Glow
              if (widget.isActive)
                Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.safeGreen.withValues(alpha: 0.1 * _pulseAnim.value),
                        blurRadius: 50,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                ),
              
              // The Protective Sphere
              Transform.scale(
                scale: widget.isActive ? 1.0 + (_pulseAnim.value - 1.0) * 0.05 : 1.0,
                child: Container(
                  width: widget.size * 1.1,
                  height: widget.size * 1.1,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: widget.isActive ? AppTheme.electricCyan.withValues(alpha: 0.3) : AppTheme.silver.withValues(alpha: 0.1),
                      width: 1,
                    ),
                    gradient: RadialGradient(
                      colors: [
                        Colors.transparent,
                        widget.isActive ? AppTheme.royalBlue.withValues(alpha: 0.1) : Colors.transparent,
                      ],
                      stops: const [0.7, 1.0],
                    ),
                  ),
                ),
              ),
              
              _buildSmartphone(widget.size),
              _buildOrbitingIcons(widget.size),
            ],
          ),
        );
      },
    );
  }
}
