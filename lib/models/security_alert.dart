import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'threat_analysis_result.dart';
import 'knowledge_entry.dart';

class SecurityAlert {
  final String id;
  final String? threatId;
  final String threatType;
  final ThreatRiskLevel riskLevel;
  final int riskScore; // 0 - 100
  final double confidence; // 0.0 - 1.0
  final String title;
  final String reason;
  final List<String> indicators;
  final String recommendedAction;
  final DateTime timestamp;
  final bool isRead;
  final List<KnowledgeEntry> relatedKnowledge;
  final Map<String, dynamic>? metadata;

  const SecurityAlert({
    required this.id,
    this.threatId,
    required this.threatType,
    required this.riskLevel,
    required this.riskScore,
    required this.confidence,
    required this.title,
    required this.reason,
    required this.indicators,
    required this.recommendedAction,
    required this.timestamp,
    this.isRead = false,
    this.relatedKnowledge = const [],
    this.metadata,
  });

  bool get isHighRisk => riskLevel == ThreatRiskLevel.high;
  bool get isMediumRisk => riskLevel == ThreatRiskLevel.medium;
  bool get isLowRisk => riskLevel == ThreatRiskLevel.low;

  Color get color => riskLevel.color;
  IconData get icon => riskLevel.icon;
  String get severityLabel => riskLevel.label;

  String get formattedTime {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inSeconds < 45) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      final mins = difference.inMinutes;
      return '$mins min${mins == 1 ? '' : 's'} ago';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return '$hours hr${hours == 1 ? '' : 's'} ago';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return '$days day${days == 1 ? '' : 's'} ago';
    } else {
      return DateFormat('MMM d, yyyy').format(timestamp);
    }
  }

  String get formattedFullDate {
    return DateFormat('MMM d, yyyy • h:mm a').format(timestamp);
  }

  SecurityAlert copyWith({
    String? id,
    String? threatId,
    String? threatType,
    ThreatRiskLevel? riskLevel,
    int? riskScore,
    double? confidence,
    String? title,
    String? reason,
    List<String>? indicators,
    String? recommendedAction,
    DateTime? timestamp,
    bool? isRead,
    List<KnowledgeEntry>? relatedKnowledge,
    Map<String, dynamic>? metadata,
  }) {
    return SecurityAlert(
      id: id ?? this.id,
      threatId: threatId ?? this.threatId,
      threatType: threatType ?? this.threatType,
      riskLevel: riskLevel ?? this.riskLevel,
      riskScore: riskScore ?? this.riskScore,
      confidence: confidence ?? this.confidence,
      title: title ?? this.title,
      reason: reason ?? this.reason,
      indicators: indicators ?? this.indicators,
      recommendedAction: recommendedAction ?? this.recommendedAction,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      relatedKnowledge: relatedKnowledge ?? this.relatedKnowledge,
      metadata: metadata ?? this.metadata,
    );
  }

  factory SecurityAlert.fromThreatResult(
    ThreatAnalysisResult threat, {
    List<KnowledgeEntry>? relatedKnowledge,
    String? customTitle,
  }) {
    String typeLabel = threat.eventType.name.toUpperCase();
    String defaultTitle;
    switch (threat.riskLevel) {
      case ThreatRiskLevel.high:
        defaultTitle = '$typeLabel Threat Detected';
        break;
      case ThreatRiskLevel.medium:
        defaultTitle = 'Suspicious $typeLabel Warning';
        break;
      case ThreatRiskLevel.low:
        defaultTitle = 'Safe $typeLabel Verified';
        break;
    }

    return SecurityAlert(
      id: threat.id,
      threatId: threat.id,
      threatType: '${threat.eventType.name}_threat',
      riskLevel: threat.riskLevel,
      riskScore: threat.riskScore,
      confidence: 0.90,
      title: customTitle ?? (threat.title.isNotEmpty ? threat.title : defaultTitle),
      reason: threat.summary.isNotEmpty ? threat.summary : 'Activity evaluated by AI threat analyzer.',
      indicators: List<String>.from(threat.indicators),
      recommendedAction: threat.recommendedAction.isNotEmpty
          ? threat.recommendedAction
          : 'Follow standard safety precautions.',
      timestamp: threat.timestamp,
      isRead: false,
      relatedKnowledge: relatedKnowledge ?? const [],
      metadata: threat.metadata,
    );
  }

  factory SecurityAlert.fromJson(Map<String, dynamic> json) {
    final riskStr = (json['riskLevel'] ?? 'medium').toString().toLowerCase();
    ThreatRiskLevel level = ThreatRiskLevel.medium;
    if (riskStr == 'high') level = ThreatRiskLevel.high;
    if (riskStr == 'low') level = ThreatRiskLevel.low;

    DateTime parsedDate;
    try {
      parsedDate = json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now();
    } catch (_) {
      parsedDate = DateTime.now();
    }

    List<KnowledgeEntry> knowledgeList = [];
    if (json['relatedKnowledgeEntries'] is List) {
      for (final item in json['relatedKnowledgeEntries']) {
        if (item is Map<String, dynamic>) {
          knowledgeList.add(KnowledgeEntry(
            id: item['id']?.toString() ?? '',
            title: item['title']?.toString() ?? '',
            category: KnowledgeCategory.commonThreats,
            description: item['description']?.toString() ?? (item['summary']?.toString() ?? ''),
            riskLevel: level,
            howScammersDoIt: item['howScammersDoIt']?.toString() ?? '',
            warningSigns: List<String>.from(item['warningSigns'] ?? []),
            recommendedActions: List<String>.from(item['recommendedActions'] ?? (item['recommendedSteps'] ?? [])),
            preventionTips: List<String>.from(item['preventionTips'] ?? []),
            keywords: List<String>.from(item['keywords'] ?? []),
            icon: Icons.shield_outlined,
          ));
        }
      }
    }

    return SecurityAlert(
      id: json['id']?.toString() ?? '',
      threatId: json['threatId']?.toString(),
      threatType: json['threatType']?.toString() ?? 'threat',
      riskLevel: level,
      riskScore: (json['riskScore'] as num?)?.toInt() ?? 0,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      title: json['title']?.toString() ?? 'Security Alert',
      reason: json['reason']?.toString() ?? '',
      indicators: List<String>.from(json['indicators'] ?? []),
      recommendedAction: json['recommendedAction']?.toString() ?? '',
      timestamp: parsedDate,
      isRead: json['isRead'] == true,
      relatedKnowledge: knowledgeList,
      metadata: json['metadata'] is Map<String, dynamic> ? json['metadata'] : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'threatId': threatId,
      'threatType': threatType,
      'riskLevel': riskLevel.label.toLowerCase(),
      'riskScore': riskScore,
      'confidence': confidence,
      'title': title,
      'reason': reason,
      'indicators': indicators,
      'recommendedAction': recommendedAction,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'relatedKnowledgeEntries': relatedKnowledge.map((k) => {
        'id': k.id,
        'title': k.title,
        'description': k.description,
        'recommendedActions': k.recommendedActions,
      }).toList(),
      'metadata': metadata,
    };
  }
}
