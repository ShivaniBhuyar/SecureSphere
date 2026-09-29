import 'package:flutter/material.dart';
import 'onboarding_screen.dart';
import '../theme/app_theme.dart';
import '../widgets/brand_logo.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _sequenceController;
  
  late Animation<double> _shieldFadeAnim;
  late Animation<double> _ambientGlowAnim;
  late Animation<double> _sphereFormAnim;
  late Animation<double> _logoScaleAnim;
  late Animation<double> _taglineFadeAnim;

  @override
  void initState() {
    super.initState();
    
    _sequenceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    );
    
    // 1. Shield fades in (0.0 - 0.2)
    _shieldFadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _sequenceController, curve: const Interval(0.0, 0.2, curve: Curves.easeIn)),
    );

    // 2. Ambient light appears (0.2 - 0.4)
    _ambientGlowAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _sequenceController, curve: const Interval(0.2, 0.4, curve: Curves.easeIn)),
    );

    // 3. Subtle sphere forms around it (0.4 - 0.6)
    _sphereFormAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _sequenceController, curve: const Interval(0.4, 0.6, curve: Curves.easeOutQuart)),
    );

    // 4. Logo gently scales (0.0 - 1.0 continuous)
    _logoScaleAnim = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _sequenceController, curve: Curves.easeOutCubic),
    );

    // 5. Tagline fades in (0.6 - 0.8)
    _taglineFadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _sequenceController, curve: const Interval(0.6, 0.8, curve: Curves.easeIn)),
    );

    _sequenceController.forward().then((_) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => const OnboardingScreen(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(opacity: animation, child: child);
              },
              transitionDuration: const Duration(milliseconds: 800),
            ),
          );
        }
      });
    });
  }

  @override
  void dispose() {
    _sequenceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.deepNavy,
      body: AnimatedBuilder(
        animation: _sequenceController,
        builder: (context, child) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Transform.scale(
                  scale: _logoScaleAnim.value,
                  child: SizedBox(
                    width: 160,
                    height: 160,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Ambient Light
                        Opacity(
                          opacity: _ambientGlowAnim.value,
                          child: Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.electricCyan.withValues(alpha: 0.3),
                                  blurRadius: 40,
                                  spreadRadius: 10,
                                ),
                                BoxShadow(
                                  color: AppTheme.softViolet.withValues(alpha: 0.2),
                                  blurRadius: 60,
                                  spreadRadius: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        // Subtle Sphere forming
                        Opacity(
                          opacity: _sphereFormAnim.value,
                          child: Transform.scale(
                            scale: 0.5 + (_sphereFormAnim.value * 0.5),
                            child: Container(
                              width: 160,
                              height: 160,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppTheme.electricCyan.withValues(alpha: 0.2),
                                  width: 1,
                                ),
                                gradient: RadialGradient(
                                  colors: [
                                    Colors.transparent,
                                    AppTheme.electricCyan.withValues(alpha: 0.1),
                                  ],
                                  stops: const [0.7, 1.0],
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Shield fades in
                        Opacity(
                          opacity: _shieldFadeAnim.value,
                          child: const BrandLogo(size: 80, showText: false),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                
                // Logo Text
                Opacity(
                  opacity: _shieldFadeAnim.value, // Fades in with the shield
                  child: const Text(
                    'SECURESPHERE',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4,
                      color: Colors.white,
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Tagline
                Opacity(
                  opacity: _taglineFadeAnim.value,
                  child: Text(
                    'AI-POWERED PERSONAL\nCYBERSECURITY GUARDIAN',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      color: AppTheme.electricCyan.withValues(alpha: 0.8),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
