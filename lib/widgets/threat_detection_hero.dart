import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../theme/app_theme.dart';
import '../models/threat_analysis_result.dart';

enum ThreatDetectionState {
  waiting,
  analyzing,
  complete,
  error,
}

class ThreatDetectionHero extends StatefulWidget {
  final ThreatDetectionState state;
  final ThreatRiskLevel? riskLevel;
  final double size;

  const ThreatDetectionHero({
    super.key,
    required this.state,
    this.riskLevel,
    this.size = 200,
  });

  @override
  State<ThreatDetectionHero> createState() => _ThreatDetectionHeroState();
}

class _ThreatDetectionHeroState extends State<ThreatDetectionHero> with TickerProviderStateMixin {
  late AnimationController _floatController;
  late AnimationController _pulseController;
  late AnimationController _scanController;
  late AnimationController _particleController;

  late Animation<double> _floatAnim;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();

    // 1. Slow floating animation (4 seconds)
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _floatAnim = Tween<double>(begin: -8.0, end: 8.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOutSine),
    );

    // 2. Gentle breathing pulse (2.8 seconds)
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // 3. Scanning ring rotation (3.5 seconds)
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    )..repeat();

    // 4. Particle orbiting (18 seconds)
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();
  }

  @override
  void didUpdateWidget(ThreatDetectionHero oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state == ThreatDetectionState.analyzing) {
      if (!_scanController.isAnimating) _scanController.repeat();
    }
  }

  @override
  void dispose() {
    _floatController.dispose();
    _pulseController.dispose();
    _scanController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  Color _getPrimaryAuraColor() {
    switch (widget.state) {
      case ThreatDetectionState.waiting:
        return AppTheme.electricCyan;
      case ThreatDetectionState.analyzing:
        return AppTheme.softViolet;
      case ThreatDetectionState.complete:
        return widget.riskLevel?.color ?? AppTheme.safeGreen;
      case ThreatDetectionState.error:
        return AppTheme.warningAmber;
    }
  }

  String _getStatusHeadline() {
    switch (widget.state) {
      case ThreatDetectionState.waiting:
        return 'AI THREAT DETECTION';
      case ThreatDetectionState.analyzing:
        return 'SCANNING ACTIVITY...';
      case ThreatDetectionState.complete:
        return 'THREAT ANALYSIS COMPLETE';
      case ThreatDetectionState.error:
        return 'ANALYSIS PAUSED';
    }
  }

  String _getStatusSubtitle() {
    switch (widget.state) {
      case ThreatDetectionState.waiting:
        return 'Waiting for security activity';
      case ThreatDetectionState.analyzing:
        return 'SecureSphere is checking this activity...';
      case ThreatDetectionState.complete:
        return 'Activity evaluated with defensive rules';
      case ThreatDetectionState.error:
        return 'Unable to analyze this activity';
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final auraColor = _getPrimaryAuraColor();
    final isAnalyzing = widget.state == ThreatDetectionState.analyzing;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: widget.size * 1.3,
          height: widget.size * 1.15,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer Ambient Breathing Aura
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Container(
                    width: widget.size * _pulseAnim.value,
                    height: widget.size * _pulseAnim.value,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: auraColor.withValues(alpha: isDark ? 0.22 : 0.14),
                          blurRadius: 55,
                          spreadRadius: 15,
                        ),
                      ],
                    ),
                  );
                },
              ),

              // Outer Orbiting Particles Ring
              AnimatedBuilder(
                animation: _particleController,
                builder: (context, child) {
                  return CustomPaint(
                    size: Size(widget.size * 1.25, widget.size * 1.25),
                    painter: _OrbitParticlesPainter(
                      progress: _particleController.value,
                      color: auraColor,
                      particleCount: 8,
                      isFast: isAnalyzing,
                    ),
                  );
                },
              ),

              // Scanning Radar / Concentric Rings
              AnimatedBuilder(
                animation: _scanController,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _scanController.value * 2 * math.pi,
                    child: Container(
                      width: widget.size * 0.95,
                      height: widget.size * 0.95,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: auraColor.withValues(alpha: isAnalyzing ? 0.5 : 0.2),
                          width: isAnalyzing ? 2.0 : 1.2,
                        ),
                        gradient: SweepGradient(
                          colors: [
                            Colors.transparent,
                            auraColor.withValues(alpha: isAnalyzing ? 0.35 : 0.08),
                          ],
                          stops: const [0.65, 1.0],
                        ),
                      ),
                    ),
                  );
                },
              ),

              // Floating 3D-style Core Shield
              AnimatedBuilder(
                animation: _floatController,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _floatAnim.value),
                    child: Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.0015)
                        ..rotateY((_floatAnim.value / 8.0) * 0.08)
                        ..rotateX((-_floatAnim.value / 8.0) * 0.05),
                      child: Container(
                        width: widget.size * 0.55,
                        height: widget.size * 0.65,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(widget.size * 0.16),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: isDark
                                ? [
                                    const Color(0xFF1E293B),
                                    AppTheme.deepNavy,
                                    const Color(0xFF0A1026),
                                  ]
                                : [
                                    Colors.white,
                                    const Color(0xFFF1F5F9),
                                    const Color(0xFFE2E8F0),
                                  ],
                          ),
                          border: Border.all(
                            color: auraColor.withValues(alpha: 0.6),
                            width: 2.0,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: auraColor.withValues(alpha: 0.3),
                              blurRadius: 20,
                              spreadRadius: 2,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Inner Glow ring
                            Container(
                              width: widget.size * 0.38,
                              height: widget.size * 0.38,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    auraColor.withValues(alpha: 0.25),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                            // Security Icon / Brain
                            Icon(
                              widget.state == ThreatDetectionState.analyzing
                                  ? Icons.radar
                                  : Icons.shield,
                              size: widget.size * 0.26,
                              color: auraColor,
                            ),
                            // Scanning Sweep Line if analyzing
                            if (isAnalyzing)
                              AnimatedBuilder(
                                animation: _scanController,
                                builder: (context, child) {
                                  final double sweepY = (_scanController.value * (widget.size * 0.65)) - (widget.size * 0.325);
                                  return Positioned(
                                    top: (widget.size * 0.65 / 2) + sweepY,
                                    left: 4,
                                    right: 4,
                                    child: Container(
                                      height: 2,
                                      decoration: BoxDecoration(
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppTheme.electricCyan,
                                            blurRadius: 6,
                                            spreadRadius: 1,
                                          ),
                                        ],
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.transparent,
                                            AppTheme.electricCyan,
                                            Colors.transparent,
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Headline
        Text(
          _getStatusHeadline(),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: auraColor,
            fontSize: 13,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 6),
        // Subtitle
        Text(
          _getStatusSubtitle(),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: isDark ? AppTheme.silver : Colors.grey.shade700,
          ),
        ),
      ],
    );
  }
}

class _OrbitParticlesPainter extends CustomPainter {
  final double progress;
  final Color color;
  final int particleCount;
  final bool isFast;

  _OrbitParticlesPainter({
    required this.progress,
    required this.color,
    required this.particleCount,
    required this.isFast,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radiusX = size.width * 0.46;
    final radiusY = size.height * 0.26;

    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < particleCount; i++) {
      final double baseAngle = (i / particleCount) * 2 * math.pi;
      final double angle = baseAngle + (progress * 2 * math.pi * (isFast ? 3.0 : 1.0));

      final double x = center.dx + (math.cos(angle) * radiusX);
      final double y = center.dy + (math.sin(angle) * radiusY);

      // Depth perception (-1 to 1)
      final double depth = math.sin(angle);
      final double particleSize = 2.5 + ((depth + 1) / 2) * 3.5;
      final double alpha = 0.25 + ((depth + 1) / 2) * 0.75;

      paint.color = color.withValues(alpha: alpha);
      canvas.drawCircle(Offset(x, y), particleSize, paint);
    }
  }

  @override
  bool shouldRepaint(_OrbitParticlesPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
