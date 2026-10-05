import 'dart:async';
import 'package:flutter/material.dart';
import '../models/chat_message.dart';
import '../models/knowledge_entry.dart';
import '../models/security_alert.dart';
import '../services/api_service.dart';
import '../services/chatbot_service.dart';
import '../services/voice_service.dart';
import '../theme/app_theme.dart';
import '../widgets/assistant_avatar.dart';
import '../widgets/typing_indicator.dart';
import '../widgets/knowledge_card.dart';
import 'knowledge_detail_screen.dart';

/// Module 6: AI Chatbot Screen
/// Provides 24/7 intelligent cybersecurity assistance, step-by-step incident guidance,
/// Knowledge Base correlation, Alert context resolution, and Text & Voice interaction.
class AskScreen extends StatefulWidget {
  final Map<String, dynamic>? initialContext;
  final String? initialQuery;

  const AskScreen({
    super.key,
    this.initialContext,
    this.initialQuery,
  });

  @override
  State<AskScreen> createState() => _AskScreenState();
}

class _AskScreenState extends State<AskScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatbotService _chatbotService = ChatbotService();
  final VoiceService _voiceService = VoiceService();

  AvatarState _avatarState = AvatarState.idle;
  bool _isOnline = true;
  bool _isListeningVoice = false;
  bool _isVoiceSpeaking = false;
  String? _currentlySpeakingMessageId;
  String _liveRecognizedSpeech = '';

  Timer? _idleTimer;

  @override
  void initState() {
    super.initState();
    _chatbotService.addListener(_onChatbotStateChanged);
    _checkOnlineHealth();
    _voiceService.initSpeech();
    _voiceService.initTts();

    // If initial query provided (e.g. from Alert or Threat detection), send it
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleSendMessage(widget.initialQuery!, clientContext: widget.initialContext);
      });
    }
  }

  @override
  void dispose() {
    _idleTimer?.cancel();
    _voiceService.stopListening();
    _voiceService.stopSpeaking();
    _chatbotService.removeListener(_onChatbotStateChanged);
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onChatbotStateChanged() {
    if (mounted) {
      setState(() {
        if (_chatbotService.isLoading) {
          _avatarState = AvatarState.thinking;
        } else if (_isListeningVoice) {
          _avatarState = AvatarState.listening;
        } else if (_isVoiceSpeaking) {
          _avatarState = AvatarState.talking;
        } else {
          _avatarState = AvatarState.idle;
        }
      });
      _scrollToBottom();
    }
  }

  Future<void> _checkOnlineHealth() async {
    final online = await ApiService().checkHealth();
    if (mounted) {
      setState(() {
        _isOnline = online;
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 80,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleSendMessage(String text, {Map<String, dynamic>? clientContext}) async {
    final cleanText = text.trim();
    if (cleanText.isEmpty) return;

    _textController.clear();
    setState(() {
      _avatarState = AvatarState.thinking;
    });

    try {
      await _chatbotService.sendMessage(
        text: cleanText,
        clientContext: clientContext ?? widget.initialContext,
      );
    } catch (_) {}

    if (mounted) {
      setState(() {
        _avatarState = AvatarState.talking;
      });
      _idleTimer?.cancel();
      _idleTimer = Timer(const Duration(seconds: 3), () {
        if (mounted && _avatarState == AvatarState.talking) {
          setState(() {
            _avatarState = AvatarState.idle;
          });
        }
      });
    }
  }

  /// Voice input handler (Step 10: Text & Voice Support)
  void _toggleVoiceInput() {
    if (_isListeningVoice) {
      // Stop listening
      _voiceService.stopListening();
      setState(() {
        _isListeningVoice = false;
        _avatarState = AvatarState.idle;
      });
    } else {
      // Start voice interaction mode
      setState(() {
        _isListeningVoice = true;
        _liveRecognizedSpeech = '';
        _avatarState = AvatarState.listening;
      });

      // Show interactive voice dialog/prompt
      _showVoiceRecognitionSheet();
    }
  }

  void _showVoiceRecognitionSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            // Start real hardware speech recognition
            if (!_voiceService.isListening) {
              _voiceService.startListening(
                onResult: (recognized, isFinal) {
                  setSheetState(() {
                    _liveRecognizedSpeech = recognized;
                  });
                  if (isFinal && recognized.trim().isNotEmpty) {
                    Navigator.pop(ctx);
                    setState(() {
                      _isListeningVoice = false;
                      _avatarState = AvatarState.thinking;
                    });
                    _handleSendMessage(recognized);
                  }
                },
              );
            }

            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const AssistantAvatar(state: AvatarState.listening, size: 64),
                    const SizedBox(height: 16),
                    Text(
                      'Listening for Cybersecurity Query...',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppTheme.deepNavy,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _liveRecognizedSpeech.isNotEmpty
                          ? '"$_liveRecognizedSpeech"'
                          : 'Speak clearly into the microphone or tap a sample prompt',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: _liveRecognizedSpeech.isNotEmpty ? FontWeight.bold : FontWeight.normal,
                        color: _liveRecognizedSpeech.isNotEmpty
                            ? AppTheme.electricCyan
                            : (isDark ? AppTheme.silver : Colors.grey.shade600),
                      ),
                    ),
                    if (_liveRecognizedSpeech.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.send, size: 16),
                        label: const Text('Send Spoken Query'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.royalBlue,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          final query = _liveRecognizedSpeech;
                          Navigator.pop(ctx);
                          setState(() {
                            _isListeningVoice = false;
                            _avatarState = AvatarState.thinking;
                          });
                          _handleSendMessage(query);
                        },
                      ),
                    ],
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        "What should I do if someone asks for my OTP?",
                        "How can I identify a fake UPI QR code?",
                        "What should I do after clicking a suspicious link?",
                        "Is my device safe from threats?"
                      ].map((sampleVoiceQuery) {
                        return ActionChip(
                          avatar: const Icon(Icons.mic, size: 14, color: AppTheme.royalBlue),
                          label: Text(sampleVoiceQuery, style: const TextStyle(fontSize: 12)),
                          backgroundColor: AppTheme.royalBlue.withValues(alpha: 0.1),
                          side: BorderSide(color: AppTheme.royalBlue.withValues(alpha: 0.3)),
                          onPressed: () {
                            _voiceService.stopListening();
                            Navigator.pop(ctx);
                            setState(() {
                              _isListeningVoice = false;
                              _avatarState = AvatarState.thinking;
                            });
                            _handleSendMessage(sampleVoiceQuery);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () {
                        _voiceService.stopListening();
                        Navigator.pop(ctx);
                        setState(() {
                          _isListeningVoice = false;
                          _avatarState = AvatarState.idle;
                        });
                      },
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('Cancel Voice Input'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade800,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      _voiceService.stopListening();
      if (mounted && _isListeningVoice) {
        setState(() {
          _isListeningVoice = false;
          _avatarState = AvatarState.idle;
        });
      }
    });
  }

  /// Text-to-speech audio feedback
  void _toggleMessageSpeech(ChatMessage msg) async {
    if (_currentlySpeakingMessageId == msg.id) {
      // Stop speaking
      await _voiceService.stopSpeaking();
      setState(() {
        _isVoiceSpeaking = false;
        _currentlySpeakingMessageId = null;
        _avatarState = AvatarState.idle;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Audio playback stopped.'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } else {
      // Start real voice speech
      setState(() {
        _isVoiceSpeaking = true;
        _currentlySpeakingMessageId = msg.id;
        _avatarState = AvatarState.talking;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.volume_up, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text('Reading cybersecurity response aloud...'),
              ],
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
      await _voiceService.speak(msg.text);
      if (mounted && _currentlySpeakingMessageId == msg.id) {
        setState(() {
          _isVoiceSpeaking = false;
          _currentlySpeakingMessageId = null;
          _avatarState = AvatarState.idle;
        });
      }
    }
  }

  void _confirmClearConversation() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Conversation?'),
        content: const Text(
          'This will reset your chat session and clear all active assistant messages.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.criticalRed,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _chatbotService.resetConversation();
              setState(() {
                _avatarState = AvatarState.happy;
              });
              Future.delayed(const Duration(seconds: 2), () {
                if (mounted) {
                  setState(() => _avatarState = AvatarState.idle);
                }
              });
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final messages = _chatbotService.messages;
    final isLoading = _chatbotService.isLoading;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            const SizedBox(width: 12),
            AssistantAvatar(state: _avatarState, size: 38),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'SecureSphere AI',
                    style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  InkWell(
                    onTap: _checkOnlineHealth,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: _isOnline ? AppTheme.safeGreen : Colors.amber.shade700,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          _isOnline ? 'Online • 24/7 Active Shield' : 'Offline Mode • Local Intelligence',
                          style: TextStyle(
                            fontSize: 11,
                            color: _isOnline ? AppTheme.safeGreen : Colors.amber.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            tooltip: 'Sync Online Status',
            onPressed: _checkOnlineHealth,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 20),
            tooltip: 'Clear Conversation',
            onPressed: _confirmClearConversation,
          ),
        ],
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0.5,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Offline Info Banner (if offline)
            if (!_isOnline)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: AppTheme.warningAmber.withValues(alpha: 0.15),
                child: Row(
                  children: [
                    const Icon(Icons.cloud_off, size: 16, color: AppTheme.warningAmber),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Offline Mode active. Local Knowledge Base available.',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.warningAmber),
                      ),
                    ),
                    InkWell(
                      onTap: _checkOnlineHealth,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4.0),
                        child: Text(
                          'Retry',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.royalBlue,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Message List
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                itemCount: messages.length + (isLoading ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == messages.length && isLoading) {
                    return _buildTypingIndicatorBubble(isDark);
                  }
                  final msg = messages[index];
                  return _buildMessageItem(isDark, msg);
                },
              ),
            ),

            // Suggestions bar below conversation
            if (!isLoading && messages.isNotEmpty)
              _buildSuggestionsRow(isDark, messages.last.suggestions.isNotEmpty
                  ? messages.last.suggestions
                  : _chatbotService.quickSuggestions),

            // Input Bar (Text & Voice)
            _buildInputArea(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageItem(bool isDark, ChatMessage msg) {
    if (msg.isUser) {
      return _buildUserBubble(isDark, msg);
    }
    return _buildAssistantBubble(isDark, msg);
  }

  Widget _buildUserBubble(bool isDark, ChatMessage msg) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.royalBlue,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                  bottomLeft: Radius.circular(18),
                  bottomRight: Radius.circular(4),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                msg.text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14.5,
                  height: 1.35,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: isDark ? AppTheme.darkSurface : Colors.grey.shade300,
            radius: 15,
            child: const Icon(Icons.person, size: 16, color: AppTheme.royalBlue),
          ),
        ],
      ),
    );
  }

  Widget _buildAssistantBubble(bool isDark, ChatMessage msg) {
    final bool isSpeaking = _currentlySpeakingMessageId == msg.id;

    return Padding(
      padding: const EdgeInsets.only(bottom: 18.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: msg.isOfflineFallback
                ? AppTheme.warningAmber
                : AppTheme.electricCyan,
            radius: 15,
            child: Icon(
              msg.isOfflineFallback ? Icons.cloud_off : Icons.security,
              size: 16,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Bubble Container
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkSurface : Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(18),
                      bottomLeft: Radius.circular(18),
                      bottomRight: Radius.circular(18),
                    ),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.06),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Text content
                      Text(
                        msg.text,
                        style: TextStyle(
                          color: isDark ? Colors.white : AppTheme.deepNavy,
                          fontSize: 14.5,
                          height: 1.45,
                        ),
                      ),

                      // Step-by-Step Incident Guidance Card (Step 7)
                      if (msg.incidentGuidance != null) ...[
                        const SizedBox(height: 14),
                        _buildIncidentGuidanceCard(isDark, msg.incidentGuidance!),
                      ],

                      // Related Knowledge Base Cards (Module 4 Integration)
                      if (msg.relatedKnowledge.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        _buildRelatedKnowledgeSection(isDark, msg.relatedKnowledge),
                      ],

                      // Related Alert Cards (Module 5 Integration)
                      if (msg.relatedAlerts.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        _buildRelatedAlertsSection(isDark, msg.relatedAlerts),
                      ],

                      const SizedBox(height: 10),

                      // Audio / TTS Action Bar
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          InkWell(
                            onTap: () => _toggleMessageSpeech(msg),
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isSpeaking ? Icons.volume_up : Icons.volume_mute,
                                    size: 15,
                                    color: isSpeaking ? AppTheme.electricCyan : Colors.grey.shade500,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    isSpeaking ? 'Speaking...' : 'Listen',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      color: isSpeaking ? AppTheme.electricCyan : Colors.grey.shade500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Step-by-Step Incident Guidance Card (Step 7)
  Widget _buildIncidentGuidanceCard(bool isDark, IncidentGuidanceData guidance) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.warningAmber.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.warningAmber.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.shield_outlined, size: 18, color: AppTheme.warningAmber),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'INCIDENT ACTION PLAN • ${guidance.severity}',
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    color: AppTheme.warningAmber,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Threat: ${guidance.threatIdentified}',
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppTheme.deepNavy,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Immediate Steps to Take:',
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          ...guidance.immediateActions.map(
            (action) => Padding(
              padding: const EdgeInsets.only(bottom: 3.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('✅ ', style: TextStyle(fontSize: 11)),
                  Expanded(
                    child: Text(action, style: const TextStyle(fontSize: 12.5)),
                  ),
                ],
              ),
            ),
          ),
          if (guidance.actionsToAvoid.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text(
              'Actions to AVOID:',
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppTheme.criticalRed),
            ),
            const SizedBox(height: 4),
            ...guidance.actionsToAvoid.map(
              (avoid) => Padding(
                padding: const EdgeInsets.only(bottom: 3.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('🚫 ', style: TextStyle(fontSize: 11)),
                    Expanded(
                      child: Text(avoid, style: const TextStyle(fontSize: 12.5)),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (guidance.emergencyHelplines.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.royalBlue.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.phone_in_talk, size: 14, color: AppTheme.royalBlue),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Helpline: ${guidance.emergencyHelplines.join(" • ")}',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.royalBlue,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Related Knowledge Base list (Module 4)
  Widget _buildRelatedKnowledgeSection(bool isDark, List<KnowledgeEntry> entries) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Icon(Icons.menu_book_outlined, size: 15, color: AppTheme.royalBlue),
            SizedBox(width: 6),
            Text(
              'RELATED SAFETY TOPICS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
                color: AppTheme.royalBlue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ...entries.map(
          (entry) => Padding(
            padding: const EdgeInsets.only(bottom: 6.0),
            child: KnowledgeCard(
              entry: entry,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => KnowledgeDetailScreen(entry: entry),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  /// Related Alerts section (Module 5)
  Widget _buildRelatedAlertsSection(bool isDark, List<SecurityAlert> alerts) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Icon(Icons.notifications_active_outlined, size: 15, color: AppTheme.criticalRed),
            SizedBox(width: 6),
            Text(
              'CORRELATED SECURITY ALERTS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
                color: AppTheme.criticalRed,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ...alerts.map(
          (alert) => Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: alert.riskLevel.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: alert.riskLevel.color.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(alert.riskLevel.icon, size: 18, color: alert.riskLevel.color),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        alert.title,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppTheme.deepNavy,
                        ),
                      ),
                      if (alert.reason.isNotEmpty)
                        Text(
                          alert.reason,
                          style: TextStyle(
                            fontSize: 11.5,
                            color: isDark ? AppTheme.silver : Colors.grey.shade700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTypingIndicatorBubble(bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const CircleAvatar(
            backgroundColor: AppTheme.electricCyan,
            radius: 15,
            child: Icon(Icons.security, size: 16, color: Colors.white),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.06),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'SecureSphere is analyzing',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: isDark ? AppTheme.silver : Colors.grey.shade600,
                  ),
                ),
                const SizedBox(width: 8),
                const TypingIndicator(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Suggestions horizontal chip strip
  Widget _buildSuggestionsRow(bool isDark, List<String> suggestions) {
    if (suggestions.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 44,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: suggestions.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final s = suggestions[index];
          return ActionChip(
            label: Text(s),
            labelStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.royalBlue,
            ),
            backgroundColor: isDark
                ? AppTheme.royalBlue.withValues(alpha: 0.15)
                : AppTheme.royalBlue.withValues(alpha: 0.08),
            side: BorderSide(
              color: isDark
                  ? AppTheme.royalBlue.withValues(alpha: 0.3)
                  : AppTheme.royalBlue.withValues(alpha: 0.2),
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            onPressed: () => _handleSendMessage(s),
          );
        },
      ),
    );
  }

  /// Bottom Chat Input Area (Text, Send & Voice buttons)
  Widget _buildInputArea(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.06),
          ),
        ),
      ),
      child: Row(
        children: [
          // Voice Microphone Button (Step 10)
          IconButton(
            icon: Icon(
              _isListeningVoice ? Icons.mic : Icons.mic_none,
              color: _isListeningVoice ? AppTheme.criticalRed : AppTheme.royalBlue,
              size: 26,
            ),
            tooltip: 'Voice Input',
            onPressed: _toggleVoiceInput,
          ),
          const SizedBox(width: 4),

          // Text Field
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? AppTheme.deepNavy : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.08),
                ),
              ),
              child: TextField(
                controller: _textController,
                textInputAction: TextInputAction.send,
                style: TextStyle(
                  color: isDark ? Colors.white : AppTheme.deepNavy,
                  fontSize: 14.5,
                ),
                decoration: InputDecoration(
                  hintText: 'Ask cybersecurity question or paste SMS/URL...',
                  hintStyle: TextStyle(
                    color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
                    fontSize: 13,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onSubmitted: (text) => _handleSendMessage(text),
              ),
            ),
          ),
          const SizedBox(width: 6),

          // Send Button
          IconButton(
            icon: const Icon(Icons.send_rounded, color: AppTheme.royalBlue, size: 26),
            tooltip: 'Send Message',
            onPressed: () => _handleSendMessage(_textController.text),
          ),
        ],
      ),
    );
  }
}
