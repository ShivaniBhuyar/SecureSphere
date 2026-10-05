import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';

/// Comprehensive Speech-to-Text and Text-to-Speech service for Module 6 Voice Support.
class VoiceService {
  static final VoiceService _instance = VoiceService._internal();
  factory VoiceService() => _instance;
  VoiceService._internal();

  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();

  bool _isSpeechInitialized = false;
  bool _isTtsInitialized = false;
  bool _isListening = false;
  bool _isSpeaking = false;

  bool get isListening => _isListening;
  bool get isSpeaking => _isSpeaking;
  bool get isSpeechAvailable => _isSpeechInitialized;

  /// Initializes speech recognition engine and requests microphone permission if needed.
  Future<bool> initSpeech() async {
    if (_isSpeechInitialized) return true;
    try {
      _isSpeechInitialized = await _speech.initialize(
        onError: (val) {
          debugPrint('Speech-to-Text Error: $val');
          _isListening = false;
        },
        onStatus: (val) {
          debugPrint('Speech-to-Text Status: $val');
          if (val == 'done' || val == 'notListening') {
            _isListening = false;
          }
        },
      );
    } catch (e) {
      debugPrint('Speech initialization exception: $e');
      _isSpeechInitialized = false;
    }
    return _isSpeechInitialized;
  }

  /// Initializes text-to-speech engine.
  Future<void> initTts() async {
    if (_isTtsInitialized) return;
    try {
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.5);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);

      _tts.setCompletionHandler(() {
        _isSpeaking = false;
      });
      _tts.setErrorHandler((msg) {
        debugPrint('TTS Error: $msg');
        _isSpeaking = false;
      });

      _isTtsInitialized = true;
    } catch (e) {
      debugPrint('TTS initialization exception: $e');
    }
  }

  /// Starts listening to microphone and streams recognized speech.
  Future<void> startListening({
    required Function(String recognizedWords, bool isFinal) onResult,
  }) async {
    final hasSpeech = await initSpeech();
    if (!hasSpeech) {
      debugPrint('Speech recognition unavailable or permission denied.');
      return;
    }

    // Stop speaking if currently playing TTS
    await stopSpeaking();

    _isListening = true;
    try {
      await _speech.listen(
        onResult: (result) {
          onResult(result.recognizedWords, result.finalResult);
        },
        listenOptions: stt.SpeechListenOptions(
          listenMode: stt.ListenMode.confirmation,
          cancelOnError: true,
          partialResults: true,
        ),
      );
    } catch (e) {
      debugPrint('Error starting speech listen: $e');
      _isListening = false;
    }
  }

  /// Stops speech recognition listening.
  Future<void> stopListening() async {
    _isListening = false;
    try {
      await _speech.stop();
    } catch (_) {}
  }

  /// Speaks assistant cybersecurity message aloud using device TTS engine.
  Future<void> speak(String text) async {
    await initTts();
    await stopListening();

    // Clean markdown stars and hashes for natural speech
    final cleanSpeechText = text
        .replaceAll(RegExp(r'\*\*|\*|#+|`'), '')
        .replaceAll(RegExp(r'•\s*'), ' ')
        .trim();

    if (cleanSpeechText.isEmpty) return;

    _isSpeaking = true;
    try {
      await _tts.speak(cleanSpeechText);
    } catch (e) {
      debugPrint('TTS speak error: $e');
      _isSpeaking = false;
    }
  }

  /// Stops TTS speech output immediately.
  Future<void> stopSpeaking() async {
    _isSpeaking = false;
    try {
      await _tts.stop();
    } catch (_) {}
  }
}
