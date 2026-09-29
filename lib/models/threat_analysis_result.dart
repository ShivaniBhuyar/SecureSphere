import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'monitoring_event.dart';

enum ThreatRiskLevel {
  low,
  medium,
  high;

  String get label {
    switch (this) {
      case ThreatRiskLevel.low:
        return 'LOW';
      case ThreatRiskLevel.medium:
        return 'MEDIUM';
      case ThreatRiskLevel.high:
        return 'HIGH';
    }
  }

  String get fullLabel {
    switch (this) {
      case ThreatRiskLevel.low:
        return 'LOW RISK';
      case ThreatRiskLevel.medium:
        return 'MEDIUM RISK';
      case ThreatRiskLevel.high:
        return 'HIGH RISK';
    }
  }

  Color get color {
    switch (this) {
      case ThreatRiskLevel.low:
        return AppTheme.safeGreen;
      case ThreatRiskLevel.medium:
        return AppTheme.warningAmber;
      case ThreatRiskLevel.high:
        return AppTheme.criticalRed;
    }
  }

  IconData get icon {
    switch (this) {
      case ThreatRiskLevel.low:
        return Icons.check_circle_outline;
      case ThreatRiskLevel.medium:
        return Icons.warning_amber_rounded;
      case ThreatRiskLevel.high:
        return Icons.gpp_bad_outlined;
    }
  }
}

class ThreatAnalysisResult {
  final String id;
  final String eventId;
  final MonitoringEventType eventType;
  final int riskScore; // 0 - 100
  final ThreatRiskLevel riskLevel;
  final String title;
  final String summary;
  final List<String> indicators;
  final String recommendedAction;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  const ThreatAnalysisResult({
    required this.id,
    required this.eventId,
    required this.eventType,
    required this.riskScore,
    required this.riskLevel,
    required this.title,
    required this.summary,
    required this.indicators,
    required this.recommendedAction,
    required this.timestamp,
    this.metadata,
  });

  String get riskScoreDisplay => '$riskScore / 100';
}
