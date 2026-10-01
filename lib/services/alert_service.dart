import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/security_alert.dart';
import '../models/threat_analysis_result.dart';
import '../models/knowledge_entry.dart';
import 'api_service.dart';
import 'notification_service.dart';

/// State management and persistence service for Module 5 — Alert & Notification.
/// Connects Module 3 threat detection results to user-facing alerts.
/// Features local persistence, online backend sync, duplicate-alert prevention,
/// and risk-based notification triggering.
class AlertService extends ChangeNotifier {
  static const String _prefKey = 'securesphere_alerts_v1';
  static const int _dedupWindowSeconds = 30;
  static bool autoSyncBackend = true;

  static final AlertService _instance = AlertService._internal();
  factory AlertService() => _instance;

  final ApiService _apiService = ApiService();
  final NotificationService _notificationService = NotificationService();
  final List<SecurityAlert> _alerts = [];
  final Map<String, DateTime> _recentFingerprints = {};

  bool _isInitialized = false;

  late final Future<void> initFuture;

  AlertService._internal() {
    initFuture = _init();
  }

  bool get isInitialized => _isInitialized;

  Future<void> ensureInitialized() async {
    if (_isInitialized) return;
    await initFuture;
  }

  List<SecurityAlert> get alerts => List.unmodifiable(_alerts);

  int get unreadCount => _alerts.where((a) => !a.isRead).length;

  List<SecurityAlert> get unreadAlerts =>
      List.unmodifiable(_alerts.where((a) => !a.isRead));

  List<SecurityAlert> get highRiskAlerts =>
      List.unmodifiable(_alerts.where((a) => a.isHighRisk));

  List<SecurityAlert> get mediumRiskAlerts =>
      List.unmodifiable(_alerts.where((a) => a.isMediumRisk));

  List<SecurityAlert> get lowRiskAlerts =>
      List.unmodifiable(_alerts.where((a) => a.isLowRisk));

  Future<void> _init() async {
    await _loadFromLocal();
    if (_alerts.isEmpty) {
      _seedInitialAlerts();
      await _saveToLocal();
    }
    _isInitialized = true;
    notifyListeners();

    // Optionally sync with backend
    if (autoSyncBackend) {
      _syncWithBackendSilently();
    }
  }

  /// Creates a SecurityAlert from a Module 3 ThreatAnalysisResult.
  /// Applies deduplication: if the exact same threat was reported within
  /// the deduplication window, ignores the duplicate to protect user attention.
  Future<SecurityAlert?> createAlertFromThreat(
    ThreatAnalysisResult threat, {
    List<KnowledgeEntry>? relatedKnowledge,
    String? customTitle,
    bool triggerNotification = true,
    bool syncWithBackend = true,
  }) async {
    if (!_isInitialized) await initFuture;
    final fingerprint = '${threat.eventType.name}_${threat.summary.trim()}';
    final now = DateTime.now();

    // Deduplication check
    if (_recentFingerprints.containsKey(fingerprint)) {
      final lastSeen = _recentFingerprints[fingerprint]!;
      if (now.difference(lastSeen).inSeconds < _dedupWindowSeconds) {
        // Return existing matching alert without spamming
        try {
          return _alerts.firstWhere(
            (a) => a.threatId == threat.id || (a.reason == threat.summary),
          );
        } catch (_) {
          return null;
        }
      }
    }

    _recentFingerprints[fingerprint] = now;

    // Build the alert
    final alert = SecurityAlert.fromThreatResult(
      threat,
      relatedKnowledge: relatedKnowledge,
      customTitle: customTitle,
    );

    // Insert newest first
    _alerts.insert(0, alert);
    await _saveToLocal();
    notifyListeners();

    // Trigger in-app / system notification according to risk level
    if (triggerNotification) {
      _notificationService.notifyAlert(alert);
    }

    // Persist to backend asynchronously
    if (syncWithBackend) {
      _persistAlertToBackend(alert);
    }

    return alert;
  }

  /// Marks a specific alert as read
  Future<void> markAsRead(String alertId) async {
    final index = _alerts.indexWhere((a) => a.id == alertId);
    if (index != -1 && !_alerts[index].isRead) {
      _alerts[index] = _alerts[index].copyWith(isRead: true);
      await _saveToLocal();
      notifyListeners();

      // Notify backend
      _apiService.markAlertRead(alertId);
    }
  }

  /// Marks a specific alert as unread
  Future<void> markAsUnread(String alertId) async {
    final index = _alerts.indexWhere((a) => a.id == alertId);
    if (index != -1 && _alerts[index].isRead) {
      _alerts[index] = _alerts[index].copyWith(isRead: false);
      await _saveToLocal();
      notifyListeners();
    }
  }

  /// Marks all alerts as read
  Future<void> markAllAsRead() async {
    bool changed = false;
    for (int i = 0; i < _alerts.length; i++) {
      if (!_alerts[i].isRead) {
        _alerts[i] = _alerts[i].copyWith(isRead: true);
        changed = true;
      }
    }

    if (changed) {
      await _saveToLocal();
      notifyListeners();

      // Notify backend
      _apiService.markAllAlertsRead();
    }
  }

  /// Deletes an alert from history
  Future<void> deleteAlert(String alertId) async {
    final countBefore = _alerts.length;
    _alerts.removeWhere((a) => a.id == alertId);
    if (_alerts.length != countBefore) {
      await _saveToLocal();
      notifyListeners();
    }
  }

  /// Clears all alert history
  Future<void> clearAll() async {
    if (!_isInitialized) await initFuture;
    _alerts.clear();
    _recentFingerprints.clear();
    await _saveToLocal();
    notifyListeners();
  }

  /// Saves current alerts list to SharedPreferences
  Future<void> _saveToLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _alerts.map((a) => a.toJson()).toList();
      await prefs.setString(_prefKey, jsonEncode(jsonList));
    } catch (_) {}
  }

  /// Loads stored alerts from SharedPreferences
  Future<void> _loadFromLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefKey);
      if (raw != null && raw.isNotEmpty) {
        final List decoded = jsonDecode(raw);
        _alerts.clear();
        for (final item in decoded) {
          if (item is Map<String, dynamic>) {
            _alerts.add(SecurityAlert.fromJson(item));
          }
        }
      }
    } catch (_) {}
  }

  /// Asynchronously posts alert to backend
  Future<void> _persistAlertToBackend(SecurityAlert alert) async {
    try {
      await _apiService.createAlert({
        'threatId': alert.threatId,
        'threatType': alert.threatType,
        'riskLevel': alert.riskLevel.label.toLowerCase(),
        'riskScore': alert.riskScore,
        'confidence': alert.confidence,
        'title': alert.title,
        'reason': alert.reason,
        'indicators': alert.indicators,
        'recommendedAction': alert.recommendedAction,
        'timestamp': alert.timestamp.toIso8601String(),
        'relatedKnowledgeEntries': alert.relatedKnowledge.map((k) => {
          'id': k.id,
          'title': k.title,
          'description': k.description,
        }).toList(),
        'metadata': alert.metadata,
      });
    } catch (_) {}
  }

  /// Silently attempts to pull alerts from backend and merge new records
  Future<void> _syncWithBackendSilently() async {
    if (!autoSyncBackend) return;
    try {
      final remoteAlerts = await _apiService.getAlerts(limit: 30);
      if (remoteAlerts != null && remoteAlerts.isNotEmpty) {
        final existingIds = _alerts.map((a) => a.id).toSet();
        bool addedAny = false;

        for (final item in remoteAlerts) {
          final alert = SecurityAlert.fromJson(item);
          if (!existingIds.contains(alert.id)) {
            _alerts.add(alert);
            existingIds.add(alert.id);
            addedAny = true;
          }
        }

        if (addedAny) {
          _alerts.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          await _saveToLocal();
          notifyListeners();
        }
      }
    } catch (_) {}
  }

  void _seedInitialAlerts() {
    final now = DateTime.now();
    _alerts.addAll([
      SecurityAlert(
        id: const Uuid().v4(),
        threatId: 'seed-threat-1',
        threatType: 'sms_threat',
        riskLevel: ThreatRiskLevel.high,
        riskScore: 86,
        confidence: 0.94,
        title: 'High-Risk SMS Threat Detected',
        reason: 'Message requested an immediate OTP to avoid bank account blockage.',
        indicators: const [
          'The message asks for an OTP',
          'It creates false urgency',
          'It contains an unverified short link',
        ],
        recommendedAction: 'Do not share your OTP.\nDo not open the link.\nVerify the sender independently.',
        timestamp: now.subtract(const Duration(minutes: 38)),
        isRead: false,
      ),
      SecurityAlert(
        id: const Uuid().v4(),
        threatId: 'seed-threat-2',
        threatType: 'app_threat',
        riskLevel: ThreatRiskLevel.medium,
        riskScore: 54,
        confidence: 0.82,
        title: 'Suspicious App Permission Warning',
        reason: 'App installed outside official store requesting SMS and contact permissions.',
        indicators: const [
          'Installed from an unknown download source',
          'Requests access to sensitive SMS messages',
        ],
        recommendedAction: 'Review app permissions in Settings > Apps.\nRevoke SMS access if not strictly required.',
        timestamp: now.subtract(const Duration(hours: 3, minutes: 12)),
        isRead: false,
      ),
      SecurityAlert(
        id: const Uuid().v4(),
        threatId: 'seed-threat-3',
        threatType: 'url_threat',
        riskLevel: ThreatRiskLevel.low,
        riskScore: 12,
        confidence: 0.98,
        title: 'Safe Link Verified',
        reason: 'Standard encrypted web address with no deceptive markers.',
        indicators: const [
          'Valid secure HTTPS connection',
          'No fraudulent keywords or deceptive subdomains',
        ],
        recommendedAction: 'Safe to browse. Always keep your browser updated.',
        timestamp: now.subtract(const Duration(days: 1, hours: 2)),
        isRead: true,
      ),
    ]);
  }
}
