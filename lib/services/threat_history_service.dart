import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/monitoring_event.dart';
import '../models/threat_analysis_result.dart';
import 'api_service.dart';

class ThreatHistoryService extends ChangeNotifier {
  static final ThreatHistoryService _instance =
      ThreatHistoryService._internal();
  factory ThreatHistoryService() => _instance;

  final ApiService _apiService = ApiService();
  final List<ThreatAnalysisResult> _history = [];
  bool _isSyncing = false;

  ThreatHistoryService._internal() {
    _populateInitialHistory();
  }

  List<ThreatAnalysisResult> get history => List.unmodifiable(_history);
  bool get isSyncing => _isSyncing;

  void addResult(ThreatAnalysisResult result) {
    _history.insert(0, result);
    notifyListeners();
  }

  void clear() {
    _history.clear();
    notifyListeners();
  }

  /// Synchronizes threat history with the backend database logs.
  /// Seamlessly falls back to local history if offline.
  Future<void> syncWithBackend({int limit = 50}) async {
    if (_isSyncing) return;
    _isSyncing = true;
    notifyListeners();

    try {
      final records = await _apiService.getThreatHistory(limit: limit);
      if (records != null && records.isNotEmpty) {
        _history.clear();
        for (final r in records) {
          _history.add(r.toThreatAnalysisResult());
        }
      }
    } catch (_) {
      // Keep existing local history if backend is unreachable
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  void _populateInitialHistory() {
    final now = DateTime.now();
    _history.addAll([
      ThreatAnalysisResult(
        id: const Uuid().v4(),
        eventId: 'hist-1',
        eventType: MonitoringEventType.sms,
        riskScore: 86,
        riskLevel: ThreatRiskLevel.high,
        title: 'Suspicious SMS',
        summary:
            'Message requested an immediate OTP to avoid bank account blockage.',
        indicators: [
          'The message asks for an OTP',
          'It creates false urgency',
          'It contains an unverified short link',
        ],
        recommendedAction:
            'Do not share your OTP.\nDo not open the link.\nVerify the sender independently.',
        timestamp: now.subtract(const Duration(minutes: 38)),
      ),
      ThreatAnalysisResult(
        id: const Uuid().v4(),
        eventId: 'hist-2',
        eventType: MonitoringEventType.app,
        riskScore: 54,
        riskLevel: ThreatRiskLevel.medium,
        title: 'Unknown App',
        summary:
            'App installed outside official store requesting SMS and contact permissions.',
        indicators: [
          'Installed from an unknown download source',
          'Requests access to sensitive SMS messages',
        ],
        recommendedAction:
            'Review app permissions in Settings > Apps.\nRevoke SMS access if not strictly required.',
        timestamp: now.subtract(const Duration(hours: 3, minutes: 12)),
      ),
      ThreatAnalysisResult(
        id: const Uuid().v4(),
        eventId: 'hist-3',
        eventType: MonitoringEventType.url,
        riskScore: 12,
        riskLevel: ThreatRiskLevel.low,
        title: 'Normal Website',
        summary: 'Standard encrypted web address with no deceptive markers.',
        indicators: [
          'Valid secure HTTPS connection',
          'No fraudulent keywords or deceptive subdomains',
        ],
        recommendedAction: 'Safe to browse. Always keep your browser updated.',
        timestamp: now.subtract(const Duration(days: 1, hours: 2)),
      ),
    ]);
  }
}
