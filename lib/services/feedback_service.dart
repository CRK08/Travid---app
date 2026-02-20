import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:vibration/vibration.dart';
import '../models/app_settings.dart';

/// Audio and Haptic feedback service for accessibility
class FeedbackService {
  static final FeedbackService _instance = FeedbackService._internal();
  factory FeedbackService() => _instance;
  FeedbackService._internal();

  final FlutterTts _tts = FlutterTts();
  AppSettings? _settings;
  bool _isInitialized = false;

  /// Initialize TTS
  Future<void> initialize(AppSettings settings) async {
    _settings = settings;
    
    if (!_isInitialized) {
      await _tts.setLanguage(settings.language == 'en' ? 'en-US' : 'ta-IN');
      await _tts.setSpeechRate(settings.voiceSpeed);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
      _isInitialized = true;
    }
  }

  /// Update settings
  void updateSettings(AppSettings settings) {
    _settings = settings;
    _tts.setSpeechRate(settings.voiceSpeed);
  }

  /// Speak text (TTS)
  Future<void> speak(String text, {bool force = false}) async {
    if (_settings == null) return;
    
    // Speak if:
    // 1. Accessibility mode is on, OR
    // 2. Audio feedback is enabled, OR
    // 3. Force is true
    if (_settings!.accessibilityMode || 
        _settings!.audioFeedback || 
        force) {
      try {
        await _tts.speak(text);
      } catch (e) {
        print('TTS error: $e');
      }
    }
  }

  /// Stop speaking
  Future<void> stop() async {
    await _tts.stop();
  }

  /// Haptic feedback - Light (button press)
  Future<void> light() async {
    if (_settings?.hapticEnabled ?? false) {
      try {
        if (await Vibration.hasVibrator() ?? false) {
          Vibration.vibrate(duration: 10);
        } else {
          HapticFeedback.lightImpact();
        }
      } catch (e) {
        HapticFeedback.lightImpact();
      }
    }
  }

  /// Haptic feedback - Medium (navigation)
  Future<void> medium() async {
    if (_settings?.hapticEnabled ?? false) {
      try {
        if (await Vibration.hasVibrator() ?? false) {
          Vibration.vibrate(duration: 30);
        } else {
          HapticFeedback.mediumImpact();
        }
      } catch (e) {
        HapticFeedback.mediumImpact();
      }
    }
  }

  /// Haptic feedback - Heavy (important action)
  Future<void> heavy() async {
    if (_settings?.hapticEnabled ?? false) {
      try {
        if (await Vibration.hasVibrator() ?? false) {
          Vibration.vibrate(duration: 50);
        } else {
          HapticFeedback.heavyImpact();
        }
      } catch (e) {
        HapticFeedback.heavyImpact();
      }
    }
  }

  /// Haptic feedback - Success (double vibration)
  Future<void> success() async {
    if (_settings?.hapticEnabled ?? false) {
      try {
        if (await Vibration.hasVibrator() ?? false) {
          Vibration.vibrate(duration: 50);
          await Future.delayed(const Duration(milliseconds: 100));
          Vibration.vibrate(duration: 50);
        } else {
          HapticFeedback.heavyImpact();
          await Future.delayed(const Duration(milliseconds: 100));
          HapticFeedback.heavyImpact();
        }
      } catch (e) {
        HapticFeedback.heavyImpact();
      }
    }
  }

  /// Haptic feedback - Error (long vibration)
  Future<void> error() async {
    if (_settings?.hapticEnabled ?? false) {
      try {
        if (await Vibration.hasVibrator() ?? false) {
          Vibration.vibrate(duration: 200);
        } else {
          HapticFeedback.heavyImpact();
        }
      } catch (e) {
        HapticFeedback.heavyImpact();
      }
    }
  }

  /// Haptic feedback - Warning (triple vibration)
  Future<void> warning() async {
    if (_settings?.hapticEnabled ?? false) {
      try {
        if (await Vibration.hasVibrator() ?? false) {
          for (int i = 0; i < 3; i++) {
            Vibration.vibrate(duration: 30);
            await Future.delayed(const Duration(milliseconds: 80));
          }
        } else {
          HapticFeedback.mediumImpact();
        }
      } catch (e) {
        HapticFeedback.mediumImpact();
      }
    }
  }

  /// Combined feedback - Button press
  Future<void> buttonPress(String label) async {
    await light();
    if (_settings?.audioFeedback ?? false) {
      await speak('$label button pressed');
    }
  }

  /// Combined feedback - Navigation
  Future<void> navigate(String destination) async {
    await medium();
    if (_settings?.audioFeedback ?? false) {
      await speak('Opening $destination');
    }
  }

  /// Combined feedback - Success action
  Future<void> successAction(String message) async {
    await success();
    await speak(message);
  }

  /// Combined feedback - Error action
  Future<void> errorAction(String message) async {
    await error();
    await speak(message);
  }
}
