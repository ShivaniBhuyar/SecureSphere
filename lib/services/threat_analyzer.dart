import '../models/monitoring_event.dart';
import '../models/threat_analysis_result.dart';

/// Abstract contract for threat analysis in SecureSphere.
/// Allows swapping between local rule-based analysis, OpenAI, Ollama, etc.
/// without modifying the UI layer.
abstract class ThreatAnalyzer {
  Future<ThreatAnalysisResult> analyze(MonitoringEvent event);
}
