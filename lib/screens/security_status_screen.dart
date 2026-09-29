import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SecurityStatusScreen extends StatelessWidget {
  const SecurityStatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Security Status'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppTheme.safeGreen.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.shield,
                      size: 80,
                      color: AppTheme.safeGreen,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'SECURESPHERE STATUS',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.grey,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Basic protection ready',
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      color: AppTheme.safeGreen,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'SecureSphere is ready to help you identify suspicious online activity.',
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),
            Text(
              'Your Safety Checklist',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildStatusCard(
              context,
              icon: Icons.lock_outline,
              title: 'Account Safety',
              description: 'Keep passwords and OTPs private.',
              color: AppTheme.electricCyan,
            ),
            const SizedBox(height: 12),
            _buildStatusCard(
              context,
              icon: Icons.link,
              title: 'Link Safety',
              description: 'Check links before opening them.',
              color: AppTheme.softViolet,
            ),
            const SizedBox(height: 12),
            _buildStatusCard(
              context,
              icon: Icons.smartphone,
              title: 'Device Safety',
              description: 'Keep your phone updated.',
              color: AppTheme.warningAmber,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context, {required IconData icon, required String title, required String description, required Color color}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            Icon(Icons.check_circle, color: AppTheme.safeGreen),
          ],
        ),
      ),
    );
  }
}
