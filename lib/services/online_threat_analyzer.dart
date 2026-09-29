import 'package:uuid/uuid.dart';
import '../models/monitoring_event.dart';
import '../models/threat_analysis_result.dart';
import 'api_service.dart';
import 'local_threat_analyzer.dart';
import 'threat_analyzer.dart';

/// Hybrid threat analyzer that queries the FastAPI backend (and external APIs like
/// VirusTotal / Google Safe Browsing) when online, and falls back to local
/// heuristics when offline.
class OnlineThreatAnalyzer implements ThreatAnalyzer {
  final ApiService _apiService = ApiService();
  final LocalThreatAnalyzer _localFallback = LocalThreatAnalyzer();
  static const _uuid = Uuid();

  @override
  Future<ThreatAnalysisResult> analyze(MonitoringEvent event) async {
    // 1. Attempt online backend threat analysis with a short timeout
    try {
      final onlineResult = await _apiService.analyzeThreat(
        type: event.type.name,
        content: _extractContent(event),
        metadata: event.metadata,
        timeout: const Duration(seconds: 4),
      );

      if (onlineResult != null) {
        return _mapOnlineResult(event, onlineResult);
      }
    } catch (_) {
      // Backend unreachable; proceed to local defensive fallback
    }

    // 2. Offline fallback to local rule-based analyzer
    return _localFallback.analyze(event);
  }

  ThreatAnalysisResult _mapOnlineResult(
    MonitoringEvent event,
    Map<String, dynamic> data,
  ) {
    final riskStr = (data['riskLevel'] ?? 'medium').toString().toLowerCase();
    ThreatRiskLevel level = ThreatRiskLevel.medium;
    if (riskStr == 'high') level = ThreatRiskLevel.high;
    if (riskStr == 'low') level = ThreatRiskLevel.low;

    final score = (data['riskScore'] as num?)?.toInt() ?? 50;
    final reason = data['reason']?.toString() ?? 'Threat analyzed by SecureSphere Online Engine.';
    final title = reason.contains('.') ? reason.split('.').first : reason;

    return ThreatAnalysisResult(
      id: data['id'] ?? _uuid.v4(),
      eventId: event.id,
      eventType: event.type,
      riskScore: score,
      riskLevel: level,
      title: title,
      summary: reason,
      indicators: List<String>.from(data['indicators'] ?? []),
      recommendedAction: data['recommendedAction'] ?? 'Follow standard safety precautions.',
      timestamp: DateTime.now(),
      metadata: event.metadata,
    );
  }

  String _extractContent(MonitoringEvent event) {
    if (event.metadata != null) {
      if (event.metadata!['text'] != null) return event.metadata!['text'].toString();
      if (event.metadata!['url'] != null) return event.metadata!['url'].toString();
      if (event.metadata!['appName'] != null) return event.metadata!['appName'].toString();
    }
    return event.source;
  }
}
