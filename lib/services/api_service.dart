import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/knowledge_entry.dart';
import '../models/monitoring_event.dart';
import '../models/threat_analysis_result.dart';
import '../models/security_report.dart';

/// Service connecting SecureSphere Flutter app to the FastAPI backend.
/// Provides resilient network calls, configurable backend URL, and clean error handling.
class ApiService {
  static const String _prefBaseUrlKey = 'securesphere_api_base_url';

  static String get defaultBaseUrl => ApiConfig.initialBaseUrl;
  static List<String> get candidateUrls => ApiConfig.candidateUrls;

  String _baseUrl = ApiConfig.initialBaseUrl;

  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal() {
    _loadSavedBaseUrl();
  }

  String get baseUrl => _baseUrl;

  Future<void> _loadSavedBaseUrl() async {
    try {
      // 1. If explicit compile-time override is supplied via --dart-define, honor it immediately
      if (ApiConfig.compileTimeBaseUrl.isNotEmpty) {
        _baseUrl = ApiConfig.sanitizeUrl(ApiConfig.compileTimeBaseUrl);
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final savedUrl = prefs.getString(_prefBaseUrlKey);
      if (savedUrl != null && savedUrl.isNotEmpty) {
        _baseUrl = ApiConfig.sanitizeUrl(savedUrl);
      }
    } catch (_) {}
  }

  Future<void> setBaseUrl(String newUrl) async {
    _baseUrl = ApiConfig.sanitizeUrl(newUrl);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefBaseUrlKey, _baseUrl);
  }

  /// Probes an individual URL to see if it responds to /api/health
  Future<bool> _probeUrl(
    String url, {
    Duration timeout = const Duration(seconds: 3),
  }) async {
    try {
      final response = await http
          .get(Uri.parse('$url/api/health'))
          .timeout(timeout);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['status'] == 'online';
      }
    } catch (_) {}
    return false;
  }

  /// Checks if the backend is reachable and online.
  /// Automatically tries candidate URLs (production HTTPS, USB reverse, Wi-Fi LAN, emulator)
  /// and locks onto whichever is actively responding.
  Future<bool> checkHealth({
    Duration timeout = const Duration(seconds: 4),
  }) async {
    // 1. Try current _baseUrl first
    if (await _probeUrl(_baseUrl, timeout: timeout)) {
      return true;
    }

    // 2. Try candidate fallback addresses
    for (final candidate in ApiConfig.candidateUrls) {
      if (candidate == _baseUrl) continue;
      if (await _probeUrl(candidate, timeout: timeout)) {
        _baseUrl = candidate;
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_prefBaseUrlKey, _baseUrl);
        } catch (_) {}
        return true;
      }
    }

    return false;
  }

  /// Fetches all cyber safety knowledge topics from the online backend.
  Future<List<KnowledgeEntry>?> getKnowledgeEntries({
    Duration timeout = const Duration(seconds: 5),
  }) async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/api/knowledge'))
          .timeout(timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List items = data['items'] ?? [];
        return items.map((item) => _parseKnowledgeEntry(item)).toList();
      }
    } catch (_) {}
    return null; // Signals caller to use local fallback
  }

  /// Searches cyber safety topics via online backend.
  Future<List<KnowledgeEntry>?> searchKnowledge(
    String query, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    try {
      final uri = Uri.parse(
        '$_baseUrl/api/knowledge/search',
      ).replace(queryParameters: {'q': query});
      final response = await http.get(uri).timeout(timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List items = data['items'] ?? [];
        return items.map((item) => _parseKnowledgeEntry(item)).toList();
      }
    } catch (_) {}
    return null; // Signals caller to use local fallback
  }

  /// Sends content to the online backend for AI & external threat analysis (VirusTotal, Safe Browsing).
  Future<Map<String, dynamic>?> analyzeThreat({
    required String type,
    required String content,
    Map<String, dynamic>? metadata,
    Duration timeout = const Duration(seconds: 6),
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/api/threat/analyze'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'type': type,
              'content': content,
              'metadata': metadata ?? {},
            }),
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null; // Signals caller to use local analyzer
  }

  /// Sends a security alert to the backend for storage and history tracking.
  Future<Map<String, dynamic>?> createAlert(
    Map<String, dynamic> alertData, {
    Duration timeout = const Duration(seconds: 4),
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/api/alerts'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(alertData),
          )
          .timeout(timeout);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  /// Fetches security alerts from the backend.
  Future<List<Map<String, dynamic>>?> getAlerts({
    bool unreadOnly = false,
    int limit = 50,
    Duration timeout = const Duration(seconds: 4),
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/api/alerts').replace(
        queryParameters: {
          'unread_only': unreadOnly.toString(),
          'limit': limit.toString(),
        },
      );
      final response = await http.get(uri).timeout(timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List items = data['items'] ?? [];
        return items.cast<Map<String, dynamic>>();
      }
    } catch (_) {}
    return null;
  }

  /// Gets the unread alert count from the backend.
  Future<int?> getUnreadAlertsCount({
    Duration timeout = const Duration(seconds: 3),
  }) async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/api/alerts/unread-count'))
          .timeout(timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['unreadCount'] as num?)?.toInt();
      }
    } catch (_) {}
    return null;
  }

  /// Marks a specific alert as read on the backend.
  Future<bool> markAlertRead(
    String alertId, {
    Duration timeout = const Duration(seconds: 3),
  }) async {
    try {
      final response = await http
          .patch(Uri.parse('$_baseUrl/api/alerts/$alertId/read'))
          .timeout(timeout);
      return response.statusCode == 200;
    } catch (_) {}
    return false;
  }

  /// Marks all alerts as read on the backend.
  Future<bool> markAllAlertsRead({
    Duration timeout = const Duration(seconds: 4),
  }) async {
    try {
      final response = await http
          .post(Uri.parse('$_baseUrl/api/alerts/mark-all-read'))
          .timeout(timeout);
      return response.statusCode == 200;
    } catch (_) {}
    return false;
  }

  /// Sends a cybersecurity query or incident message to the Module 6 AI Chatbot backend.
  Future<Map<String, dynamic>?> sendChatMessage({
    required String message,
    String? conversationId,
    Map<String, dynamic>? context,
    Duration timeout = const Duration(seconds: 8),
  }) async {
    try {
      final payload = <String, dynamic>{'message': message};
      if (conversationId != null) {
        payload['conversationId'] = conversationId;
      }
      if (context != null) {
        payload['context'] = context;
      }

      final response = await http
          .post(
            Uri.parse('$_baseUrl/api/chat'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  /// Fetches default cybersecurity quick-prompt suggestions from backend.
  Future<List<String>?> getChatSuggestions({
    Duration timeout = const Duration(seconds: 4),
  }) async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/api/chat/suggestions'))
          .timeout(timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List list = data['suggestions'] ?? [];
        return list.map((e) => e.toString()).toList();
      }
    } catch (_) {}
    return null;
  }

  /// Converts backend JSON payload to a Flutter [KnowledgeEntry].
  KnowledgeEntry _parseKnowledgeEntry(Map<String, dynamic> json) {
    // Map category string to KnowledgeCategory enum
    final catStr = (json['category'] ?? '').toString().toLowerCase();
    KnowledgeCategory category = KnowledgeCategory.commonThreats;
    for (final c in KnowledgeCategory.values) {
      if (c.label.toLowerCase() == catStr) {
        category = c;
        break;
      }
    }

    // Map risk level string to ThreatRiskLevel enum
    final riskStr = (json['riskLevel'] ?? '').toString().toLowerCase();
    ThreatRiskLevel riskLevel = ThreatRiskLevel.medium;
    if (riskStr == 'high') {
      riskLevel = ThreatRiskLevel.high;
    } else if (riskStr == 'low') {
      riskLevel = ThreatRiskLevel.low;
    }

    // Map icon name
    IconData icon = Icons.shield_outlined;
    final iconName = (json['iconName'] ?? '').toString().toLowerCase();
    if (iconName.contains('pin')) {
      icon = Icons.pin_outlined;
    } else if (iconName.contains('qr')) {
      icon = Icons.qr_code_scanner;
    } else if (iconName.contains('link')) {
      icon = Icons.link_off;
    } else if (iconName.contains('support')) {
      icon = Icons.support_agent;
    } else if (iconName.contains('android')) {
      icon = Icons.android;
    } else if (iconName.contains('chat')) {
      icon = Icons.chat;
    } else if (iconName.contains('password')) {
      icon = Icons.password;
    } else if (iconName.contains('badge')) {
      icon = Icons.badge_outlined;
    } else if (iconName.contains('wifi')) {
      icon = Icons.wifi_lock;
    } else if (iconName.contains('warning')) {
      icon = Icons.warning_amber;
    } else if (iconName.contains('mail') || iconName.contains('email')) {
      icon = Icons.mark_email_unread_outlined;
    } else if (iconName.contains('shield')) {
      icon = Icons.shield;
    }

    // Parse related event types
    final List<MonitoringEventType> relatedEvents = [];
    final List eventStrings = json['relatedEventTypes'] ?? [];
    for (final e in eventStrings) {
      final s = e.toString().toLowerCase();
      if (s == 'sms') {
        relatedEvents.add(MonitoringEventType.sms);
      } else if (s == 'url') {
        relatedEvents.add(MonitoringEventType.url);
      } else if (s == 'app') {
        relatedEvents.add(MonitoringEventType.app);
      } else if (s == 'email') {
        relatedEvents.add(MonitoringEventType.email);
      } else if (s == 'device') {
        relatedEvents.add(MonitoringEventType.device);
      }
    }

    return KnowledgeEntry(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      category: category,
      description: json['description'] ?? '',
      riskLevel: riskLevel,
      howScammersDoIt: json['howScammersDoIt'] ?? '',
      warningSigns: List<String>.from(json['warningSigns'] ?? []),
      recommendedActions: List<String>.from(json['recommendedActions'] ?? []),
      preventionTips: List<String>.from(json['preventionTips'] ?? []),
      keywords: List<String>.from(json['keywords'] ?? []),
      icon: icon,
      relatedEventTypes: relatedEvents,
    );
  }

  // ==========================================
  // MODULE 7: REPORTS & ANALYTICS APIS
  // ==========================================

  /// Fetches an aggregated cybersecurity executive report summary from the backend.
  Future<ReportSummary?> getReportSummary({
    int days = 7,
    Duration timeout = const Duration(seconds: 5),
  }) async {
    try {
      final uri = Uri.parse(
        '$_baseUrl/api/reports/summary',
      ).replace(queryParameters: {'days': days.toString()});
      final response = await http.get(uri).timeout(timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return ReportSummary.fromJson(data);
      }
    } catch (_) {}
    return null;
  }

  /// Fetches historical threat analyses with optional filters.
  Future<List<HistoricalThreatRecord>?> getThreatHistory({
    int limit = 50,
    int offset = 0,
    String? eventType,
    String? riskLevel,
    Duration timeout = const Duration(seconds: 5),
  }) async {
    try {
      final queryParams = <String, String>{
        'limit': limit.toString(),
        'offset': offset.toString(),
      };
      if (eventType != null &&
          eventType.isNotEmpty &&
          eventType.toLowerCase() != 'all') {
        queryParams['event_type'] = eventType.toLowerCase();
      }
      if (riskLevel != null &&
          riskLevel.isNotEmpty &&
          riskLevel.toLowerCase() != 'all') {
        queryParams['risk_level'] = riskLevel.toLowerCase();
      }

      final uri = Uri.parse(
        '$_baseUrl/api/reports/history',
      ).replace(queryParameters: queryParams);
      final response = await http.get(uri).timeout(timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final List items = data['items'] ?? [];
        return items
            .map(
              (item) =>
                  HistoricalThreatRecord.fromJson(item as Map<String, dynamic>),
            )
            .toList();
      }
    } catch (_) {}
    return null;
  }

  /// Computes and returns the SecureSphere Device Security Score.
  Future<DeviceScoreData?> getDeviceSecurityScore({
    Duration timeout = const Duration(seconds: 4),
  }) async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/api/reports/device-score'))
          .timeout(timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return DeviceScoreData.fromJson(data);
      }
    } catch (_) {}
    return null;
  }

  /// Evaluates device security score on-demand with live device metadata signals.
  Future<DeviceScoreData?> evaluateDeviceSecurityScore({
    required Map<String, dynamic> metadata,
    Duration timeout = const Duration(seconds: 5),
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/api/reports/device-score/evaluate'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'metadata': metadata}),
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return DeviceScoreData.fromJson(data);
      }
    } catch (_) {}
    return null;
  }

  /// Fetches time-series incident trends and automated security insights.
  Future<TrendsReport?> getSecurityTrends({
    int days = 7,
    Duration timeout = const Duration(seconds: 5),
  }) async {
    try {
      final uri = Uri.parse(
        '$_baseUrl/api/reports/trends',
      ).replace(queryParameters: {'days': days.toString()});
      final response = await http.get(uri).timeout(timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return TrendsReport.fromJson(data);
      }
    } catch (_) {}
    return null;
  }
}
