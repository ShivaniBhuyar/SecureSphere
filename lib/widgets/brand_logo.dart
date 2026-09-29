import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class BrandLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final Color? color;

  const BrandLogo({
    super.key,
    this.size = 32,
    this.showText = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color primaryColor = color ?? (isDark ? AppTheme.electricCyan : AppTheme.royalBlue);
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer minimal shield
              Icon(
                Icons.shield_outlined,
                size: size,
                color: primaryColor,
              ),
              // Inner AI/Network element (Subtle dot)
              Container(
                width: size * 0.25,
                height: size * 0.25,
                decoration: BoxDecoration(
                  color: AppTheme.softViolet,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.softViolet.withValues(alpha: 0.5),
                      blurRadius: size * 0.2,
                      spreadRadius: size * 0.05,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (showText) ...[
          const SizedBox(width: 12),
          Text(
            'SECURESPHERE',
            style: TextStyle(
              fontSize: size * 0.5,
              fontWeight: FontWeight.bold,
              letterSpacing: 2.0,
              color: isDark ? Colors.white : AppTheme.deepNavy,
              fontFamily: Theme.of(context).textTheme.titleLarge?.fontFamily,
            ),
          ),
        ],
      ],
    );
  }
}
