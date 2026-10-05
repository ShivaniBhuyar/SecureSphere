import 'knowledge_entry.dart';
import 'security_alert.dart';
import 'threat_analysis_result.dart';

/// Step-by-step defensive response guidance during suspected incidents.
class IncidentGuidanceData {
  final String threatIdentified;
  final String severity;
  final List<String> immediateActions;
  final List<String> actionsToAvoid;
  final List<String> emergencyHelplines;

  const IncidentGuidanceData({
    required this.threatIdentified,
    required this.severity,
    required this.immediateActions,
    required this.actionsToAvoid,
    required this.emergencyHelplines,
  });

  factory IncidentGuidanceData.fromJson(Map<String, dynamic> json) {
    return IncidentGuidanceData(
      threatIdentified: json['threatIdentified'] ?? 'Threat Detected',
      severity: json['severity'] ?? 'HIGH',
      immediateActions: List<String>.from(json['immediateActions'] ?? []),
      actionsToAvoid: List<String>.from(json['actionsToAvoid'] ?? []),
      emergencyHelplines: List<String>.from(json['emergencyHelplines'] ?? []),
    );
  }
}

/// A structured chat message in SecureSphere's Module 6 AI Assistant.
class ChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final List<String> suggestions;
  final List<KnowledgeEntry> relatedKnowledge;
  final List<SecurityAlert> relatedAlerts;
  final IncidentGuidanceData? incidentGuidance;
  final ThreatAnalysisResult? threatContext;
  final bool isError;
  final bool isOfflineFallback;

  const ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.suggestions = const [],
    this.relatedKnowledge = const [],
    this.relatedAlerts = const [],
    this.incidentGuidance,
    this.threatContext,
    this.isError = false,
    this.isOfflineFallback = false,
  });

  ChatMessage copyWith({
    String? id,
    String? text,
    bool? isUser,
    DateTime? timestamp,
    List<String>? suggestions,
    List<KnowledgeEntry>? relatedKnowledge,
    List<SecurityAlert>? relatedAlerts,
    IncidentGuidanceData? incidentGuidance,
    ThreatAnalysisResult? threatContext,
    bool? isError,
    bool? isOfflineFallback,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      text: text ?? this.text,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
      suggestions: suggestions ?? this.suggestions,
      relatedKnowledge: relatedKnowledge ?? this.relatedKnowledge,
      relatedAlerts: relatedAlerts ?? this.relatedAlerts,
      incidentGuidance: incidentGuidance ?? this.incidentGuidance,
      threatContext: threatContext ?? this.threatContext,
      isError: isError ?? this.isError,
      isOfflineFallback: isOfflineFallback ?? this.isOfflineFallback,
    );
  }
}
