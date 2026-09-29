import 'package:flutter/material.dart';
import '../models/monitoring_event.dart';
import '../theme/app_theme.dart';

class MonitoringCard extends StatelessWidget {
  final MonitoringEventType type;
  final String title;
  final String description;
  final bool isGranted;
  final VoidCallback onTap;

  const MonitoringCard({
    super.key,
    required this.type,
    required this.title,
    required this.description,
    required this.isGranted,
    required this.onTap,
  });

  IconData _getIcon() {
    switch (type) {
      case MonitoringEventType.sms: return Icons.message_outlined;
      case MonitoringEventType.url: return Icons.link;
      case MonitoringEventType.app: return Icons.apps;
      case MonitoringEventType.email: return Icons.email_outlined;
      case MonitoringEventType.device: return Icons.security;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isGranted ? AppTheme.safeGreen : AppTheme.warningAmber;

    return Card(
      elevation: 0,
      color: isDark ? AppTheme.deepNavy.withValues(alpha: 0.5) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isGranted ? AppTheme.safeGreen.withValues(alpha: 0.3) : AppTheme.silver.withValues(alpha: 0.2),
        ),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withValues(alpha: 0.5)),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.1),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Icon(_getIcon(), color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppTheme.deepNavy,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? AppTheme.silver : Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isGranted ? Icons.check_circle : Icons.info_outline,
                            size: 14,
                            color: color,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isGranted ? 'Active' : 'Permission Required',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
