import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Safety Alerts', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(
              'Important reminders from SecureSphere',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildAlertCard(
            context,
            icon: Icons.warning_amber_rounded,
            title: 'SAFETY REMINDER',
            message: 'Never share an OTP with someone who calls or messages you.',
            color: AppTheme.warningAmber,
            date: 'Just now',
          ),
          const SizedBox(height: 12),
          _buildAlertCard(
            context,
            icon: Icons.check_circle_outline,
            title: 'SECURITY TIP',
            message: 'Check the sender before opening unexpected links.',
            color: AppTheme.safeGreen,
            date: 'Yesterday',
          ),
          const SizedBox(height: 12),
          _buildAlertCard(
            context,
            icon: Icons.info_outline,
            title: 'APP UPDATE',
            message: 'SecureSphere has been updated with new safety features.',
            color: AppTheme.electricCyan,
            date: 'Last week',
          ),
        ],
      ),
    );
  }

  Widget _buildAlertCard(BuildContext context, {required IconData icon, required String title, required String message, required Color color, required String date}) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        date,
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
