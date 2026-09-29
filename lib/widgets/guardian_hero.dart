import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../theme/app_theme.dart';

class GuardianHero extends StatefulWidget {
  const GuardianHero({super.key});

  @override
  State<GuardianHero> createState() => _GuardianHeroState();
}

class _GuardianHeroState extends State<GuardianHero> with TickerProviderStateMixin {
  late AnimationController _floatController;
  late AnimationController _pulseController;
  late AnimationController _interactionController;
  late AnimationController _orbitController;

  late Animation<double> _floatAnim;
  late Animation<double> _phoneFloatAnim;
  late Animation<double> _pulseAnim;
  late Animation<double> _scaleAnim;
  late Animation<double> _glowAnim;
  late Animation<double> _waveAnim;

  bool _isInteracting = false;

  final List<IconData> _orbitIcons = [
    Icons.lock_outline,
    Icons.link,
    Icons.chat_bubble_outline,
    Icons.apps,
    Icons.warning_amber_rounded,
    Icons.security,
  ];

  @override
  void initState() {
    super.initState();
    
    // Slow Floating (4 seconds)
    _floatController = AnimationController(
      vsync: this, 
      duration: const Duration(milliseconds: 4000)
    )..repeat(reverse: true);
    
    _floatAnim = Tween<double>(begin: -8, end: 8).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut)
    );

    // Phone floats slightly out of phase
    _phoneFloatAnim = Tween<double>(begin: 6, end: -6).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOutSine)
    );

    // Breathing Glow (2.5 seconds)
    _pulseController = AnimationController(
      vsync: this, 
      duration: const Duration(milliseconds: 2500)
    )..repeat(reverse: true);
    
    _pulseAnim = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut)
    );

    // Orbiting elements (20 seconds for full rotation)
    _orbitController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    // Interaction (Wave & Scale) (1.5 seconds total)
    _interactionController = AnimationController(
      vsync: this, 
      duration: const Duration(milliseconds: 1000)
    );
    
    _scaleAnim = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _interactionController, curve: const Interval(0.0, 0.3, curve: Curves.easeOutCubic))
    );
    
    _glowAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _interactionController, curve: const Interval(0.0, 0.5, curve: Curves.easeOut))
    );
    
    _waveAnim = Tween<double>(begin: 0.0, end: 3.0).animate(
      CurvedAnimation(parent: _interactionController, curve: const Interval(0.2, 1.0, curve: Curves.easeOutQuart))
    );
  }

  @override
  void dispose() {
    _floatController.dispose();
    _pulseController.dispose();
    _interactionController.dispose();
    _orbitController.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (_interactionController.isAnimating || _isInteracting) return;
    
    setState(() => _isInteracting = true);
    _interactionController.forward().then((_) {
      Future.delayed(const Duration(milliseconds: 2000), () {
        if (mounted) {
          _interactionController.reverse().then((_) {
            if (mounted) setState(() => _isInteracting = false);
          });
        }
      });
    });
  }

  Widget _buildSmartphone(double size) {
    return Transform.translate(
      offset: Offset(0, _phoneFloatAnim.value),
      child: Container(
        width: size * 0.45,
        height: size * 0.85,
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(size * 0.08),
          border: Border.all(
            color: AppTheme.silver.withValues(alpha: 0.5),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.electricCyan.withValues(alpha: 0.1),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Screen
            Container(
              margin: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFF060B19),
                borderRadius: BorderRadius.circular(size * 0.06),
              ),
            ),
            // Minimal Logo on Screen
            Icon(
              Icons.security,
              color: AppTheme.electricCyan.withValues(alpha: 0.5 + (_pulseAnim.value * 0.3)),
              size: size * 0.15,
            ),
            // Screen glare
            Positioned(
              top: -size * 0.1,
              left: -size * 0.1,
              child: Transform.rotate(
                angle: math.pi / 4,
                child: Container(
                  width: size * 0.6,
                  height: size * 0.2,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.1),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrbitingObjects(double size) {
    return AnimatedBuilder(
      animation: _orbitController,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: List.generate(_orbitIcons.length, (index) {
            final double angle = (index / _orbitIcons.length) * 2 * math.pi + (_orbitController.value * 2 * math.pi);
            // Elliptical path for 3D depth effect
            final double x = math.cos(angle) * (size * 0.7);
            final double y = math.sin(angle) * (size * 0.2);
            
            // Scale and opacity based on Y position (Z-depth fake)
            final double zDepth = math.sin(angle); // -1 to 1
            final double scale = 0.7 + ((zDepth + 1) / 2) * 0.6; // 0.7 to 1.3
            final double opacity = 0.3 + ((zDepth + 1) / 2) * 0.7; // 0.3 to 1.0

            return Transform.translate(
              offset: Offset(x, y),
              child: Transform.scale(
                scale: scale,
                child: Opacity(
                  opacity: opacity,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.deepNavy.withValues(alpha: 0.8),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.electricCyan.withValues(alpha: 0.3),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.electricCyan.withValues(alpha: 0.1),
                          blurRadius: 5,
                        ),
                      ],
                    ),
                    child: Icon(
                      _orbitIcons[index],
                      size: size * 0.08,
                      color: AppTheme.silver,
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final double size = math.min(constraints.maxWidth * 0.8, 300);

        return GestureDetector(
          onTap: _handleTap,
          behavior: HitTestBehavior.opaque,
          child: AnimatedBuilder(
            animation: Listenable.merge([
              _floatController, 
              _pulseController, 
              _interactionController
            ]),
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnim.value,
                child: SizedBox(
                  width: size * 1.5,
                  height: size * 1.3,
                  child: Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      // Circular Energy Wave (Interaction)
                      if (_isInteracting || _interactionController.isAnimating)
                        Opacity(
                          opacity: 1.0 - (_waveAnim.value / 3.0).clamp(0.0, 1.0),
                          child: Transform.scale(
                            scale: _waveAnim.value,
                            child: Container(
                              width: size,
                              height: size,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppTheme.electricCyan,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                        ),

                      // Composite Hero (Phone + Shield + Sphere + Orbit)
                      Transform.translate(
                        offset: Offset(0, _floatAnim.value),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // 1. Ambient Background Glow
                            Container(
                              width: size,
                              height: size,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.electricCyan.withValues(alpha: 0.15 + (_glowAnim.value * 0.2)),
                                    blurRadius: 60 + (_pulseAnim.value * 20),
                                    spreadRadius: 10,
                                  ),
                                ],
                              ),
                            ),
                            
                            // 2. The Smartphone (Center)
                            _buildSmartphone(size),
                            
                            // 3. The Shield (In front of phone)
                            Transform.translate(
                              offset: const Offset(0, 20), // Slightly lower
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Metallic Inner Structure
                                  ShaderMask(
                                    shaderCallback: (bounds) {
                                      return LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          Colors.white,
                                          AppTheme.silver,
                                          AppTheme.deepNavy,
                                        ],
                                        stops: const [0.0, 0.5, 1.0],
                                      ).createShader(bounds);
                                    },
                                    child: Icon(
                                      Icons.shield,
                                      size: size * 0.8,
                                      color: Colors.white,
                                    ),
                                  ),
                                  // Blue/Cyan Edge Lighting
                                  Icon(
                                    Icons.shield_outlined,
                                    size: size * 0.8,
                                    color: AppTheme.electricCyan.withValues(alpha: 0.6 + (_pulseAnim.value * 0.2)),
                                    shadows: [
                                      Shadow(
                                        color: AppTheme.electricCyan,
                                        blurRadius: 10 + (_glowAnim.value * 15),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // 4. The Protective Sphere (Surrounding everything)
                            Container(
                              width: size * 1.1,
                              height: size * 1.1,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppTheme.royalBlue.withValues(alpha: 0.02 + (_glowAnim.value * 0.05)),
                                border: Border.all(
                                  color: AppTheme.electricCyan.withValues(alpha: 0.2 + (_pulseAnim.value * 0.1)),
                                  width: 1,
                                ),
                                gradient: RadialGradient(
                                  colors: [
                                    Colors.transparent,
                                    AppTheme.royalBlue.withValues(alpha: 0.1),
                                  ],
                                  stops: const [0.7, 1.0],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.white.withValues(alpha: 0.02),
                                    blurRadius: 20,
                                    spreadRadius: -5,
                                    offset: const Offset(-10, -10), // Highlight
                                  ),
                                ],
                              ),
                            ),
                            
                            // 5. Orbiting Security Objects
                            _buildOrbitingObjects(size),
                          ],
                        ),
                      ),
                      
                      // Floating Status Text
                      if (_isInteracting || _interactionController.isAnimating)
                        Positioned(
                          bottom: -30,
                          child: FadeTransition(
                            opacity: CurvedAnimation(parent: _interactionController, curve: Curves.easeIn),
                            child: Column(
                              children: [
                                Text(
                                  "SECURITY STATUS",
                                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                    color: AppTheme.silver,
                                    letterSpacing: 2.0,
                                    fontSize: 10,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 8, height: 8,
                                      decoration: const BoxDecoration(
                                        color: AppTheme.safeGreen,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      "PROTECTED",
                                      style: TextStyle(
                                        color: AppTheme.safeGreen,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "MONITORING ACTIVE",
                                  style: TextStyle(
                                    color: AppTheme.electricCyan.withValues(alpha: 0.7),
                                    fontSize: 10,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
