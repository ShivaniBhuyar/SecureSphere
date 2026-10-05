import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/chat_message.dart';
import '../models/knowledge_entry.dart';
import '../models/security_alert.dart';
import '../models/threat_analysis_result.dart';
import '../models/monitoring_event.dart';
import 'api_service.dart';
import 'knowledge_repository.dart';

/// Service managing Module 6 AI Chatbot state, backend integration, and offline fallback.
class ChatbotService extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final KnowledgeRepository _knowledgeRepo = KnowledgeRepository();

  String _conversationId = const Uuid().v4();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  List<String> _quickSuggestions = [
    "What should I do if someone asks for my OTP?",
    "How can I identify a fake UPI QR code?",
    "What should I do after clicking a suspicious link?",
    "How can I protect my bank account?",
    "Check a suspicious message",
    "What does my latest security alert mean?"
  ];

  ChatbotService() {
    _initWelcomeMessage();
  }

  String get conversationId => _conversationId;
  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;
  List<String> get quickSuggestions => List.unmodifiable(_quickSuggestions);

  void _initWelcomeMessage() {
    _messages.clear();
    _messages.add(
      ChatMessage(
        id: 'welcome_msg',
        text: "👋 Hi! I'm **SecureSphere AI Assistant**, your 24/7 cybersecurity guardian.\n\n"
              "I can help you analyze suspicious messages, guide you step-by-step through cyber incidents (OTP theft, UPI scams, phishing, fake apps), and explain your device security status.\n\n"
              "How can I protect you today?",
        isUser: false,
        timestamp: DateTime.now(),
        suggestions: _quickSuggestions,
      ),
    );
  }

  /// Clears current conversation history and resets session.
  void resetConversation() {
    _conversationId = const Uuid().v4();
    _initWelcomeMessage();
    notifyListeners();
  }

  /// Loads dynamic suggestion chips from backend if available.
  Future<void> fetchSuggestions() async {
    final remoteSuggestions = await _apiService.getChatSuggestions();
    if (remoteSuggestions != null && remoteSuggestions.isNotEmpty) {
      _quickSuggestions = remoteSuggestions;
      notifyListeners();
    }
  }

  /// Sends user query to FastAPI backend or falls back to local knowledge base.
  Future<ChatMessage> sendMessage({
    required String text,
    Map<String, dynamic>? clientContext,
  }) async {
    final cleanText = text.trim();
    if (cleanText.isEmpty) {
      throw ArgumentError('Message cannot be empty');
    }

    final userMsg = ChatMessage(
      id: const Uuid().v4(),
      text: cleanText,
      isUser: true,
      timestamp: DateTime.now(),
    );

    _messages.add(userMsg);
    _isLoading = true;
    notifyListeners();

    try {
      final responseData = await _apiService.sendChatMessage(
        message: cleanText,
        conversationId: _conversationId,
        context: clientContext,
      );

      if (responseData != null) {
        // Successful online backend response
        final String botText = responseData['message'] ?? 'Guidance received.';
        final String serverConvId = responseData['conversationId'] ?? _conversationId;
        _conversationId = serverConvId;

        // Parse suggestions
        final List<String> suggestions = List<String>.from(responseData['suggestions'] ?? []);
        if (suggestions.isNotEmpty) {
          _quickSuggestions = suggestions;
        }

        // Parse related knowledge entries
        final List<KnowledgeEntry> relatedKnowledge = [];
        final List kbJsonList = responseData['relatedKnowledgeEntries'] ?? [];
        for (final item in kbJsonList) {
          final id = item['id'];
          if (id != null) {
            final entry = _knowledgeRepo.getEntryById(id.toString());
            if (entry != null) {
              relatedKnowledge.add(entry);
            }
          }
        }

        // Parse related alerts
        final List<SecurityAlert> relatedAlerts = [];
        final List alertJsonList = responseData['relatedAlerts'] ?? [];
        for (final item in alertJsonList) {
          try {
            relatedAlerts.add(
              SecurityAlert(
                id: item['id'] ?? const Uuid().v4(),
                title: item['title'] ?? 'Security Alert',
                threatType: item['threatType'] ?? 'threat',
                riskLevel: ThreatRiskLevel.values.firstWhere(
                  (r) => r.name.toLowerCase() == (item['riskLevel'] ?? 'high').toString().toLowerCase(),
                  orElse: () => ThreatRiskLevel.high,
                ),
                riskScore: (item['riskScore'] as num?)?.toInt() ?? 75,
                confidence: (item['confidence'] as num?)?.toDouble() ?? 0.85,
                reason: item['reason'] ?? 'Flagged by real-time monitoring',
                indicators: List<String>.from(item['indicators'] ?? []),
                recommendedAction: item['recommendedAction'] ?? 'Follow recommended safety steps.',
                timestamp: DateTime.now(),
                isRead: item['isRead'] ?? false,
              ),
            );
          } catch (_) {}
        }

        // Parse incident guidance
        IncidentGuidanceData? guidance;
        if (responseData['incidentGuidance'] != null) {
          guidance = IncidentGuidanceData.fromJson(
            Map<String, dynamic>.from(responseData['incidentGuidance']),
          );
        }

        // Parse threat context if any
        ThreatAnalysisResult? threatCtx;
        if (responseData['threatContext'] != null) {
          final tc = Map<String, dynamic>.from(responseData['threatContext']);
          threatCtx = ThreatAnalysisResult(
            id: tc['id'] ?? const Uuid().v4(),
            eventId: tc['eventId'] ?? '',
            eventType: MonitoringEventType.values.firstWhere(
              (e) => e.name.toLowerCase() == (tc['eventType'] ?? 'sms').toString().toLowerCase(),
              orElse: () => MonitoringEventType.sms,
            ),
            riskScore: (tc['riskScore'] as num?)?.toInt() ?? 50,
            riskLevel: ThreatRiskLevel.values.firstWhere(
              (r) => r.name.toLowerCase() == (tc['riskLevel'] ?? 'medium').toString().toLowerCase(),
              orElse: () => ThreatRiskLevel.medium,
            ),
            title: tc['title'] ?? 'Threat Analysis',
            summary: tc['summary'] ?? '',
            indicators: List<String>.from(tc['indicators'] ?? []),
            recommendedAction: tc['recommendedAction'] ?? '',
            timestamp: DateTime.now(),
          );
        }

        final botMsg = ChatMessage(
          id: const Uuid().v4(),
          text: botText,
          isUser: false,
          timestamp: DateTime.now(),
          suggestions: suggestions,
          relatedKnowledge: relatedKnowledge,
          relatedAlerts: relatedAlerts,
          incidentGuidance: guidance,
          threatContext: threatCtx,
        );

        _messages.add(botMsg);
        _isLoading = false;
        notifyListeners();
        return botMsg;
      }
    } catch (_) {}

    // Offline Fallback handling (Preserves Module 4 local data)
    final offlineMsg = _generateOfflineFallback(cleanText);
    _messages.add(offlineMsg);
    _isLoading = false;
    notifyListeners();
    return offlineMsg;
  }

  /// Builds a graceful offline response leveraging Module 4 local knowledge data.
  ChatMessage _generateOfflineFallback(String query) {
    final searchResults = _knowledgeRepo.search(query);
    final relatedKnowledge = searchResults.take(2).toList();

    String responseText =
        "⚠️ **SecureSphere AI Assistant is currently offline.**\n\n"
        "I could not reach the cloud intelligence service. However, your **Cyber Safety Knowledge Base** is available offline.";

    if (relatedKnowledge.isNotEmpty) {
      responseText +=
          "\n\nHere are relevant offline safety guides matching your inquiry:";
    } else {
      responseText +=
          "\n\nYou can explore safety playbooks for OTP protection, UPI fraud defense, phishing prevention, and password hygiene.";
    }

    return ChatMessage(
      id: const Uuid().v4(),
      text: responseText,
      isUser: false,
      timestamp: DateTime.now(),
      suggestions: const [
        "What should I do if someone asks for my OTP?",
        "How can I identify a fake UPI QR code?",
        "What is phishing?",
        "Check my current security status"
      ],
      relatedKnowledge: relatedKnowledge,
      isOfflineFallback: true,
    );
  }
}
