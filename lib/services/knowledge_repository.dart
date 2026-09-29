import '../models/knowledge_entry.dart';
import '../models/threat_analysis_result.dart';
import 'api_service.dart';
import 'knowledge_data.dart';

/// Repository providing online/offline access, search, and Module 3 threat correlation
/// for cyber safety topics.
class KnowledgeRepository {
  List<KnowledgeEntry> _entries;
  final ApiService _apiService = ApiService();

  KnowledgeRepository({List<KnowledgeEntry>? entries})
      : _entries = entries ?? List.from(KnowledgeData.entries);

  /// Returns all currently available safety entries (cached or local fallback).
  List<KnowledgeEntry> getAllEntries() => List.unmodifiable(_entries);

  /// Attempts to refresh knowledge base from online backend; falls back to local data if offline.
  Future<bool> refreshFromOnline() async {
    try {
      final onlineEntries = await _apiService.getKnowledgeEntries();
      if (onlineEntries != null && onlineEntries.isNotEmpty) {
        _entries = onlineEntries;
        return true;
      }
    } catch (_) {}
    return false;
  }

  /// Searches topics online if available; falls back immediately to local data.
  Future<List<KnowledgeEntry>> searchOnlineOrOffline(String query, {KnowledgeCategory? category}) async {
    if (query.trim().isNotEmpty) {
      try {
        final onlineResults = await _apiService.searchKnowledge(query);
        if (onlineResults != null && onlineResults.isNotEmpty) {
          if (category != null) {
            return onlineResults.where((e) => e.category == category).toList();
          }
          return onlineResults;
        }
      } catch (_) {}
    }
    return search(query, category: category);
  }

  /// Returns an entry by its ID, or null if not found.
  KnowledgeEntry? getEntryById(String id) {
    try {
      return _entries.firstWhere((entry) => entry.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Searches topics by query string with optional category filter.
  /// Fast, local, offline search across title, description, keywords, and category.
  List<KnowledgeEntry> search(String query, {KnowledgeCategory? category}) {
    final cleanQuery = query.trim().toLowerCase();

    return _entries.where((entry) {
      if (category != null && entry.category != category) {
        return false;
      }

      if (cleanQuery.isEmpty) {
        return true;
      }

      // Match title
      if (entry.title.toLowerCase().contains(cleanQuery)) {
        return true;
      }

      // Match category name
      if (entry.category.label.toLowerCase().contains(cleanQuery)) {
        return true;
      }

      // Match keywords
      if (entry.keywords.any((kw) => kw.toLowerCase().contains(cleanQuery))) {
        return true;
      }

      // Match description
      if (entry.description.toLowerCase().contains(cleanQuery)) {
        return true;
      }

      // Match warning signs
      if (entry.warningSigns.any((sign) => sign.toLowerCase().contains(cleanQuery))) {
        return true;
      }

      return false;
    }).toList();
  }

  /// Finds the most relevant knowledge base topic for a Module 3 [ThreatAnalysisResult].
  /// Directly consumes Module 3's output without duplicating detection logic.
  KnowledgeEntry findRelevantKnowledge(ThreatAnalysisResult threatResult) {
    final combinedText = (
      '${threatResult.title} '
      '${threatResult.summary} '
      '${threatResult.indicators.join(" ")} '
      '${threatResult.recommendedAction}'
    ).toLowerCase();

    // 1. High-priority keyword matching based on threat detection indicators
    if (combinedText.contains('otp') ||
        combinedText.contains('one-time') ||
        combinedText.contains('verification code') ||
        combinedText.contains('secret pin')) {
      final match = getEntryById('otp_scam');
      if (match != null) return match;
    }

    if (combinedText.contains('upi') ||
        combinedText.contains('qr code') ||
        combinedText.contains('collect request') ||
        combinedText.contains('phonepe') ||
        combinedText.contains('gpay') ||
        combinedText.contains('paytm')) {
      final match = getEntryById('upi_scam');
      if (match != null) return match;
    }

    if (combinedText.contains('customer care') ||
        combinedText.contains('bank official') ||
        combinedText.contains('call from') ||
        combinedText.contains('remote access') ||
        combinedText.contains('anydesk')) {
      final match = getEntryById('fake_customer_care');
      if (match != null) return match;
    }

    if (combinedText.contains('url') ||
        combinedText.contains('link') ||
        combinedText.contains('phish') ||
        combinedText.contains('bit.ly') ||
        combinedText.contains('website') ||
        combinedText.contains('.xyz') ||
        combinedText.contains('fake login')) {
      final match = getEntryById('phishing_links');
      if (match != null) return match;
    }

    if (combinedText.contains('apk') ||
        combinedText.contains('loan') ||
        combinedText.contains('side-load') ||
        combinedText.contains('app installed') ||
        combinedText.contains('dangerous permission') ||
        combinedText.contains('spyware')) {
      final match = getEntryById('fake_apps');
      if (match != null) return match;
    }

    if (combinedText.contains('aadhaar') ||
        combinedText.contains('pan card') ||
        combinedText.contains('kyc document') ||
        combinedText.contains('identity')) {
      final match = getEntryById('identity_theft');
      if (match != null) return match;
    }

    if (combinedText.contains('urgent') ||
        combinedText.contains('blocked today') ||
        combinedText.contains('arrest') ||
        combinedText.contains('police') ||
        combinedText.contains('suspended')) {
      final match = getEntryById('social_engineering');
      if (match != null) return match;
    }

    // 2. Secondary matching by event type
    final typeMatches = _entries
        .where((entry) => entry.relatedEventTypes.contains(threatResult.eventType))
        .toList();

    if (typeMatches.isNotEmpty) {
      return typeMatches.first;
    }

    // 3. Fallback default entry
    return _entries.first;
  }
}
