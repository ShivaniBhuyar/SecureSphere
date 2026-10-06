import '../models/monitoring_event.dart';
import '../models/threat_analysis_result.dart';

/// Module 7 — Security Report Summary Model
class ReportSummary {
  final int? timeframeDays;
  final int totalScans;
  final int threatsDetected;
  final int totalAlerts;
  final int unreadAlerts;
  final int highRiskEvents;
  final int mediumRiskEvents;
  final int lowRiskEvents;
  final double averageRiskScore;
  final int highestRiskScore;
  final String securityPosture;
  final String securityPostureDescription;
  final Map<String, int> eventTypeBreakdown;
  final Map<String, int> threatTypeBreakdown;
  final List<String> topRiskIndicators;
  final List<String> recommendedActions;
  final DateTime generatedAt;

  const ReportSummary({
    this.timeframeDays,
    required this.totalScans,
    required this.threatsDetected,
    required this.totalAlerts,
    required this.unreadAlerts,
    required this.highRiskEvents,
    required this.mediumRiskEvents,
    required this.lowRiskEvents,
    required this.averageRiskScore,
    required this.highestRiskScore,
    required this.securityPosture,
    required this.securityPostureDescription,
    required this.eventTypeBreakdown,
    required this.threatTypeBreakdown,
    required this.topRiskIndicators,
    required this.recommendedActions,
    required this.generatedAt,
  });

  factory ReportSummary.fromJson(Map<String, dynamic> json) {
    return ReportSummary(
      timeframeDays: json['timeframeDays'] as int?,
      totalScans: (json['totalScans'] as num?)?.toInt() ?? 0,
      threatsDetected: (json['threatsDetected'] as num?)?.toInt() ?? 0,
      totalAlerts: (json['totalAlerts'] as num?)?.toInt() ?? 0,
      unreadAlerts: (json['unreadAlerts'] as num?)?.toInt() ?? 0,
      highRiskEvents: (json['highRiskEvents'] as num?)?.toInt() ?? 0,
      mediumRiskEvents: (json['mediumRiskEvents'] as num?)?.toInt() ?? 0,
      lowRiskEvents: (json['lowRiskEvents'] as num?)?.toInt() ?? 0,
      averageRiskScore: (json['averageRiskScore'] as num?)?.toDouble() ?? 0.0,
      highestRiskScore: (json['highestRiskScore'] as num?)?.toInt() ?? 0,
      securityPosture: json['securityPosture']?.toString() ?? 'Good',
      securityPostureDescription:
          json['securityPostureDescription']?.toString() ?? '',
      eventTypeBreakdown:
          (json['eventTypeBreakdown'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, (v as num).toInt()),
          ) ??
          {},
      threatTypeBreakdown:
          (json['threatTypeBreakdown'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, (v as num).toInt()),
          ) ??
          {},
      topRiskIndicators:
          (json['topRiskIndicators'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      recommendedActions:
          (json['recommendedActions'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      generatedAt: json['generatedAt'] != null
          ? DateTime.tryParse(json['generatedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

/// Contributing Factor for Device Security Score
class DeviceScoreFactor {
  final String factor;
  final String status; // "secure", "warning", "critical"
  final String impact;
  final String detail;

  const DeviceScoreFactor({
    required this.factor,
    required this.status,
    required this.impact,
    required this.detail,
  });

  factory DeviceScoreFactor.fromJson(Map<String, dynamic> json) {
    return DeviceScoreFactor(
      factor: json['factor']?.toString() ?? '',
      status: json['status']?.toString() ?? 'secure',
      impact: json['impact']?.toString() ?? 'Normal',
      detail: json['detail']?.toString() ?? '',
    );
  }
}

/// Module 7 — SecureSphere Device Security Score Model
class DeviceScoreData {
  final int score;
  final String grade;
  final String status;
  final String summary;
  final List<DeviceScoreFactor> factors;
  final List<String> recommendations;
  final DateTime? lastAssessed;
  final String source;

  const DeviceScoreData({
    required this.score,
    required this.grade,
    required this.status,
    required this.summary,
    required this.factors,
    required this.recommendations,
    this.lastAssessed,
    required this.source,
  });

  factory DeviceScoreData.fromJson(Map<String, dynamic> json) {
    return DeviceScoreData(
      score: (json['score'] as num?)?.toInt() ?? 85,
      grade: json['grade']?.toString() ?? 'B (Good)',
      status: json['status']?.toString() ?? 'Protected',
      summary:
          json['summary']?.toString() ?? 'Device security posture evaluated.',
      factors:
          (json['factors'] as List?)
              ?.map(
                (e) => DeviceScoreFactor.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
      recommendations:
          (json['recommendations'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      lastAssessed: json['lastAssessed'] != null
          ? DateTime.tryParse(json['lastAssessed'].toString())
          : null,
      source:
          json['source']?.toString() ?? 'SecureSphere Device Security Engine',
    );
  }
}

/// Module 7 — Single Trend Time-Series Data Point
class TrendDataPoint {
  final String date;
  final int scanCount;
  final int threatCount;
  final double averageRiskScore;
  final int alertCount;

  const TrendDataPoint({
    required this.date,
    required this.scanCount,
    required this.threatCount,
    required this.averageRiskScore,
    required this.alertCount,
  });

  factory TrendDataPoint.fromJson(Map<String, dynamic> json) {
    return TrendDataPoint(
      date: json['date']?.toString() ?? '',
      scanCount: (json['scanCount'] as num?)?.toInt() ?? 0,
      threatCount: (json['threatCount'] as num?)?.toInt() ?? 0,
      averageRiskScore: (json['averageRiskScore'] as num?)?.toDouble() ?? 0.0,
      alertCount: (json['alertCount'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Dynamic Cybersecurity Insight
class ReportInsight {
  final String type; // "positive", "warning", "info"
  final String title;
  final String description;

  const ReportInsight({
    required this.type,
    required this.title,
    required this.description,
  });

  factory ReportInsight.fromJson(Map<String, dynamic> json) {
    return ReportInsight(
      type: json['type']?.toString() ?? 'info',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
    );
  }
}

/// Module 7 — Trends & Insights Report Model
class TrendsReport {
  final int days;
  final List<TrendDataPoint> dataPoints;
  final Map<String, int> categoryDistribution;
  final Map<String, int> riskLevelDistribution;
  final List<ReportInsight> insights;
  final String startDate;
  final String endDate;

  const TrendsReport({
    required this.days,
    required this.dataPoints,
    required this.categoryDistribution,
    required this.riskLevelDistribution,
    required this.insights,
    required this.startDate,
    required this.endDate,
  });

  factory TrendsReport.fromJson(Map<String, dynamic> json) {
    return TrendsReport(
      days: (json['days'] as num?)?.toInt() ?? 7,
      dataPoints:
          (json['dataPoints'] as List?)
              ?.map((e) => TrendDataPoint.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      categoryDistribution:
          (json['categoryDistribution'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, (v as num).toInt()),
          ) ??
          {},
      riskLevelDistribution:
          (json['riskLevelDistribution'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, (v as num).toInt()),
          ) ??
          {},
      insights:
          (json['insights'] as List?)
              ?.map((e) => ReportInsight.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      startDate: json['startDate']?.toString() ?? '',
      endDate: json['endDate']?.toString() ?? '',
    );
  }
}

/// Single Threat History Item from /api/reports/history
class HistoricalThreatRecord {
  final String id;
  final DateTime? timestamp;
  final MonitoringEventType eventType;
  final String threatType;
  final ThreatRiskLevel riskLevel;
  final int riskScore;
  final double confidence;
  final String? contentSnippet;
  final String reason;
  final List<String> indicators;
  final String? recommendedAction;

  const HistoricalThreatRecord({
    required this.id,
    this.timestamp,
    required this.eventType,
    required this.threatType,
    required this.riskLevel,
    required this.riskScore,
    required this.confidence,
    this.contentSnippet,
    required this.reason,
    required this.indicators,
    this.recommendedAction,
  });

  factory HistoricalThreatRecord.fromJson(Map<String, dynamic> json) {
    final typeStr = (json['eventType'] ?? 'sms').toString().toLowerCase();
    MonitoringEventType evType = MonitoringEventType.sms;
    for (final e in MonitoringEventType.values) {
      if (e.name == typeStr) {
        evType = e;
        break;
      }
    }

    final levelStr = (json['riskLevel'] ?? 'low').toString().toLowerCase();
    ThreatRiskLevel rLevel = ThreatRiskLevel.low;
    if (levelStr == 'high' || levelStr == 'critical') {
      rLevel = ThreatRiskLevel.high;
    } else if (levelStr == 'medium') {
      rLevel = ThreatRiskLevel.medium;
    }

    return HistoricalThreatRecord(
      id: json['id']?.toString() ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString())
          : null,
      eventType: evType,
      threatType: json['threatType']?.toString() ?? 'normal_activity',
      riskLevel: rLevel,
      riskScore: (json['riskScore'] as num?)?.toInt() ?? 0,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      contentSnippet: json['contentSnippet']?.toString(),
      reason: json['reason']?.toString() ?? '',
      indicators:
          (json['indicators'] as List?)?.map((e) => e.toString()).toList() ??
          [],
      recommendedAction: json['recommendedAction']?.toString(),
    );
  }

  /// Converts to standard ThreatAnalysisResult for unified widget rendering
  ThreatAnalysisResult toThreatAnalysisResult() {
    return ThreatAnalysisResult(
      id: id,
      eventId: 'hist-$id',
      eventType: eventType,
      riskScore: riskScore,
      riskLevel: riskLevel,
      title: threatType.replaceAll('_', ' ').toUpperCase(),
      summary: reason,
      indicators: indicators,
      recommendedAction: recommendedAction ?? '',
      timestamp: timestamp ?? DateTime.now(),
    );
  }
}
