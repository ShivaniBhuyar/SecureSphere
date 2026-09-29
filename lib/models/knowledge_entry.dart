import 'package:flutter/material.dart';
import 'monitoring_event.dart';
import 'threat_analysis_result.dart';

/// Categories of cyber safety topics in SecureSphere.
enum KnowledgeCategory {
  scamProtection,
  safeLinks,
  mobileSafety,
  paymentSafety,
  passwordSafety,
  emailMessages,
  privacy,
  commonThreats;

  String get label {
    switch (this) {
      case KnowledgeCategory.scamProtection:
        return 'Scam Protection';
      case KnowledgeCategory.safeLinks:
        return 'Safe Links';
      case KnowledgeCategory.mobileSafety:
        return 'Mobile Safety';
      case KnowledgeCategory.paymentSafety:
        return 'Payment Safety';
      case KnowledgeCategory.passwordSafety:
        return 'Password Safety';
      case KnowledgeCategory.emailMessages:
        return 'Email & Messages';
      case KnowledgeCategory.privacy:
        return 'Privacy';
      case KnowledgeCategory.commonThreats:
        return 'Common Threats';
    }
  }

  IconData get icon {
    switch (this) {
      case KnowledgeCategory.scamProtection:
        return Icons.shield_outlined;
      case KnowledgeCategory.safeLinks:
        return Icons.link;
      case KnowledgeCategory.mobileSafety:
        return Icons.phone_android;
      case KnowledgeCategory.paymentSafety:
        return Icons.credit_card;
      case KnowledgeCategory.passwordSafety:
        return Icons.lock_outline;
      case KnowledgeCategory.emailMessages:
        return Icons.mail_outline;
      case KnowledgeCategory.privacy:
        return Icons.person_outline;
      case KnowledgeCategory.commonThreats:
        return Icons.warning_amber_rounded;
    }
  }
}

/// A structured knowledge entry providing beginner-friendly cybersecurity guidance.
class KnowledgeEntry {
  final String id;
  final String title;
  final KnowledgeCategory category;
  final String description;
  final ThreatRiskLevel riskLevel;
  final String howScammersDoIt;
  final List<String> warningSigns;
  final List<String> recommendedActions;
  final List<String> preventionTips;
  final List<String> keywords;
  final IconData icon;
  final List<MonitoringEventType> relatedEventTypes;

  const KnowledgeEntry({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    required this.riskLevel,
    required this.howScammersDoIt,
    required this.warningSigns,
    required this.recommendedActions,
    required this.preventionTips,
    required this.keywords,
    required this.icon,
    this.relatedEventTypes = const [],
  });
}
