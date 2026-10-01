import 'package:flutter/material.dart';
import '../models/security_alert.dart';
import '../models/threat_analysis_result.dart';
import '../theme/app_theme.dart';

/// Notification Service for Module 5 — Alert & Notification.
/// Handles high/medium/low priority security notifications, sanitized notification
/// previews (avoiding exposure of sensitive personal content), and in-app alert banners.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  /// Global messenger key so notifications can be shown from anywhere in the app
  static final GlobalKey<ScaffoldMessengerState> messengerKey =
      GlobalKey<ScaffoldMessengerState>();

  bool _notificationsEnabled = true;
  bool get notificationsEnabled => _notificationsEnabled;

  void setNotificationsEnabled(bool enabled) {
    _notificationsEnabled = enabled;
  }

  /// Dispatches an appropriate security notification based on risk severity:
  /// - High: Prominent security alert (critical red, immediate attention required)
  /// - Medium: Warning notification (suspicious activity)
  /// - Low: Informational notification (safe / verified)
  void notifyAlert(SecurityAlert alert, {VoidCallback? onTap}) {
    if (!_notificationsEnabled) return;

    final messenger = messengerKey.currentState;
    if (messenger == null) return;

    final payload = _buildNotificationPayload(alert);

    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        duration: alert.isHighRisk
            ? const Duration(seconds: 6)
            : const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        backgroundColor: AppTheme.darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: payload.accentColor.withValues(alpha: 0.8),
            width: 1.5,
          ),
        ),
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: payload.accentColor.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(payload.icon, color: payload.accentColor, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: payload.accentColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          payload.tag,
                          style: TextStyle(
                            color: payload.accentColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          payload.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    payload.body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.grey.shade300,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        action: onTap != null
            ? SnackBarAction(
                label: 'VIEW',
                textColor: payload.accentColor,
                onPressed: onTap,
              )
            : SnackBarAction(
                label: 'DISMISS',
                textColor: Colors.grey.shade400,
                onPressed: () => messenger.hideCurrentSnackBar(),
              ),
      ),
    );
  }

  /// Builds a sanitized, non-sensitive notification preview
  NotificationPayload _buildNotificationPayload(SecurityAlert alert) {
    final cleanType = alert.threatType
        .replaceAll('_threat', '')
        .replaceAll('_', ' ')
        .toUpperCase();

    switch (alert.riskLevel) {
      case ThreatRiskLevel.high:
        return NotificationPayload(
          tag: 'CRITICAL',
          title: 'Security Alert',
          body: 'High-risk $cleanType threat detected. Immediate attention required.',
          accentColor: AppTheme.criticalRed,
          icon: Icons.gpp_bad_rounded,
        );
      case ThreatRiskLevel.medium:
        return NotificationPayload(
          tag: 'WARNING',
          title: 'Security Warning',
          body: 'Suspicious $cleanType activity detected. Please review recommendations.',
          accentColor: AppTheme.warningAmber,
          icon: Icons.warning_amber_rounded,
        );
      case ThreatRiskLevel.low:
        return NotificationPayload(
          tag: 'INFO',
          title: 'Security Info',
          body: '$cleanType verified. No threats detected.',
          accentColor: AppTheme.safeGreen,
          icon: Icons.verified_user_outlined,
        );
    }
  }
}

class NotificationPayload {
  final String tag;
  final String title;
  final String body;
  final Color accentColor;
  final IconData icon;

  const NotificationPayload({
    required this.tag,
    required this.title,
    required this.body,
    required this.accentColor,
    required this.icon,
  });
}
