import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../screens/permissions_screen.dart';

class PrivacyCard extends StatelessWidget {
  const PrivacyCard({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.deepNavy.withValues(alpha: 0.8) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.electricCyan.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.electricCyan.withValues(alpha: 0.05),
            blurRadius: 20,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.shield_outlined, color: AppTheme.electricCyan, size: 28),
              const SizedBox(width: 12),
              Text(
                'Your Privacy Matters',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppTheme.deepNavy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'SecureSphere only checks the information you allow.',
            style: TextStyle(
              color: isDark ? AppTheme.silver : Colors.grey.shade700,
              height: 1.5,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 20),
          _buildPrivacyItem(Icons.check, 'Local-first processing', isDark),
          _buildPrivacyItem(Icons.check, 'User-controlled permissions', isDark),
          _buildPrivacyItem(Icons.check, 'No hidden monitoring', isDark),
          _buildPrivacyItem(Icons.check, 'Transparent protection', isDark),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PermissionsScreen()),
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.electricCyan,
                side: const BorderSide(color: AppTheme.electricCyan),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('MANAGE PRIVACY', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyItem(IconData icon, String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.safeGreen),
          const SizedBox(width: 12),
          Text(
            text,
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.grey.shade800,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
