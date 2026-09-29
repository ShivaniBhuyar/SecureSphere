import 'package:flutter/material.dart';
import 'main_layout.dart';
import '../theme/app_theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _pages = [
    {
      'title': 'STAY SAFE ONLINE',
      'description': 'SecureSphere helps you understand online risks in simple words.',
      'icon': Icons.security,
      'color': AppTheme.electricCyan,
    },
    {
      'title': 'STOP BEFORE YOU CLICK',
      'description': 'Learn what to do when a message, link or request feels suspicious.',
      'icon': Icons.warning_amber_rounded,
      'color': AppTheme.warningAmber,
    },
    {
      'title': 'YOUR DIGITAL GUARDIAN',
      'description': 'Ask SecureSphere whenever you need help staying safe.',
      'icon': Icons.smart_toy_outlined,
      'color': AppTheme.safeGreen,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Ambient Lighting Background (Visible primarily in Dark Mode)
          if (isDark)
            Positioned(
              top: -150,
              right: -100,
              child: Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppTheme.royalBlue.withValues(alpha: 0.15),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                      });
                    },
                    itemCount: _pages.length,
                    itemBuilder: (context, index) {
                      final color = _pages[index]['color'] as Color;
                      return Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // 3D Glass Icon Container
                            Container(
                              padding: const EdgeInsets.all(40),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: color.withValues(alpha: 0.05),
                                border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
                                boxShadow: [
                                  BoxShadow(
                                    color: color.withValues(alpha: 0.1),
                                    blurRadius: 40,
                                    spreadRadius: 10,
                                  ),
                                ],
                              ),
                              child: Icon(
                                _pages[index]['icon'],
                                size: 100,
                                color: color.withValues(alpha: 0.9),
                              ),
                            ),
                            const SizedBox(height: 60),
                            Text(
                              _pages[index]['title'],
                              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                                fontSize: 24,
                                letterSpacing: 1.5,
                                color: isDark ? Colors.white : AppTheme.deepNavy,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            Text(
                              _pages[index]['description'],
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: isDark ? AppTheme.silver : Colors.grey.shade700,
                                height: 1.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                
                // Bottom Navigation & Controls
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Page Indicators
                      Row(
                        children: List.generate(
                          _pages.length,
                          (index) => AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.only(right: 8),
                            width: _currentPage == index ? 24 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _currentPage == index 
                                ? AppTheme.electricCyan 
                                : (isDark ? AppTheme.silver.withValues(alpha: 0.3) : Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(4),
                              boxShadow: _currentPage == index 
                                ? [
                                    BoxShadow(
                                      color: AppTheme.electricCyan.withValues(alpha: 0.5),
                                      blurRadius: 10,
                                    )
                                  ] 
                                : null,
                            ),
                          ),
                        ),
                      ),
                      
                      // Premium Button
                      GestureDetector(
                        onTap: () {
                          if (_currentPage < _pages.length - 1) {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 500),
                              curve: Curves.easeInOutQuart,
                            );
                          } else {
                            Navigator.pushReplacement(
                              context,
                              PageRouteBuilder(
                                pageBuilder: (context, animation, secondaryAnimation) => const MainLayout(),
                                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                  return FadeTransition(opacity: animation, child: child);
                                },
                                transitionDuration: const Duration(milliseconds: 800),
                              ),
                            );
                          }
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.royalBlue,
                                AppTheme.electricCyan.withValues(alpha: 0.8),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.electricCyan.withValues(alpha: 0.3),
                                blurRadius: 15,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Text(
                            _currentPage == _pages.length - 1 ? 'GET STARTED' : 'NEXT',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
