import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

/// Wake Word Detection Service
/// Listens for "Travid" keyword to activate full AI
/// Battery-efficient: only processes wake word, not full speech
class WakeWordService extends ChangeNotifier {
  // Singleton
  static final WakeWordService _instance = WakeWordService._internal();
  factory WakeWordService() => _instance;
  WakeWordService._internal();

  late stt.SpeechToText _speech;
  bool _isListeningForWakeWord = false;
  bool _isInitialized = false;
  String _wakeWord = "travid"; // Default wake word
  Function()? _onWakeWordDetected;

  // Getters
  bool get isListeningForWakeWord => _isListeningForWakeWord;
  String get wakeWord => _wakeWord;

  /// Initialize wake word detection
  Future<void> initialize() async {
    if (_isInitialized) return;

    _speech = stt.SpeechToText();
    bool available = await _speech.initialize(
      onStatus: (status) {
        debugPrint('🔊 Wake word status: $status');
        if ((status == 'done' || status == 'notListening') && _isListeningForWakeWord) {
           // Auto-restart if we should be listening
           Future.delayed(const Duration(milliseconds: 1000), () {
             if (_isListeningForWakeWord) {
               _listenForWakeWord();
             }
           });
        }
      },
      onError: (error) {
        debugPrint('❌ Wake word error: $error');
        // Auto-restart on error (timeout, etc)
        if (_isListeningForWakeWord) {
           Future.delayed(const Duration(seconds: 2), () {
             if (_isListeningForWakeWord) {
               _listenForWakeWord();
             }
           });
        }
      },
    );

    if (!available) {
      debugPrint('❌ Wake word detection not available');
      return;
    }

    _isInitialized = true;
    debugPrint('✅ Wake word service initialized');
  }

  /// Start listening for wake word
  Future<void> startListeningForWakeWord({
    required Function() onWakeWordDetected,
  }) async {
    if (!_isInitialized) await initialize();
    if (_isListeningForWakeWord) return;

    _onWakeWordDetected = onWakeWordDetected;
    _isListeningForWakeWord = true;
    notifyListeners();

    _listenForWakeWord();
  }

  /// Internal method to listen for wake word
  void _listenForWakeWord() {
    _speech.listen(
      onResult: (result) {
        final text = result.recognizedWords.toLowerCase();
        
        // Check if wake word is detected
        if (text.contains(_wakeWord)) {
          debugPrint('✅ Wake word detected: "$text"');
          
          // Stop listening for wake word
          stopListening();
          
          // Trigger callback
          _onWakeWordDetected?.call();
          
          // Auto-restart after a delay (will be controlled by GlobalAIService)
          // Don't restart here - let the AI service handle it
        } else if (result.finalResult) {
          // Not the wake word, restart listening
          Future.delayed(const Duration(milliseconds: 500), () {
            if (_isListeningForWakeWord) {
              _listenForWakeWord();
            }
          });
        }
      },
      listenOptions: stt.SpeechListenOptions(
        cancelOnError: true,
        partialResults: true, // Detect wake word quickly
        autoPunctuation: false,
        enableHapticFeedback: false, // Save battery
        listenMode: stt.ListenMode.dictation, // Continuous listening
      ),
    );
  }

  /// Stop listening for wake word
  Future<void> stopListening() async {
    if (!_isListeningForWakeWord) return;

    await _speech.stop();
    _isListeningForWakeWord = false;
    notifyListeners();
  }

  /// Set custom wake word
  void setWakeWord(String word) {
    _wakeWord = word.toLowerCase().trim();
    notifyListeners();
    
    // Restart listening with new wake word
    if (_isListeningForWakeWord) {
      stopListening().then((_) {
        if (_onWakeWordDetected != null) {
          startListeningForWakeWord(onWakeWordDetected: _onWakeWordDetected!);
        }
      });
    }
  }

  /// Dispose
  @override
  void dispose() {
    _speech.stop();
    super.dispose();
  }
}
