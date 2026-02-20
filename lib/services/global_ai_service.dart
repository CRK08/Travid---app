import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:travid/services/ai_service.dart';
import 'package:travid/services/hive_chat_service.dart';
import 'package:travid/services/firestore_chat_service.dart'; // Added for ChatSession/ChatMessage
import 'package:travid/services/context_service.dart';
import 'package:travid/models/voice_info.dart';
import 'package:travid/models/app_settings.dart';
import 'package:uuid/uuid.dart';

/// Supported languages
enum AppLanguage {
  english,
  tamil,
  tanglish, // Tamil + English mix
}

/// Global AI Voice Service
/// Manual "Tap to Speak" listening only.
/// Multi-language support: Tamil, English, Tanglish
/// Settings persistence: Saves user preferences
class GlobalAIService extends ChangeNotifier {
  // Singleton
  static final GlobalAIService _instance = GlobalAIService._internal();
  factory GlobalAIService() => _instance;
  GlobalAIService._internal();

  // Services
  final AIService _aiService = AIService();
  final HiveChatService _chatService = HiveChatService();
  // REMOVED: WakeWordService
  final ContextService _contextService = ContextService();
  late stt.SpeechToText _speech;
  late FlutterTts _tts;
  late SharedPreferences _prefs;

  // Persistence Key
  static const String _prefVoice = 'ai_selected_voice'; // Keeping voice specific pref here

  // State
  bool _isListening = false; // "Microphone is technically on"
  bool _isProcessing = false;
  bool _isSpeaking = false;
  
  // Settings Logic
  bool _voiceEnabled = true;
  bool _tapToSpeakEnabled = false;
  // REMOVED: ListeningMode (Only manual now)
  
  String _currentSessionId = const Uuid().v4();
  
  // Voice Input State

  String _lastRecognizedText = "";
  
  AppLanguage _currentLanguage = AppLanguage.english;
  
  // Language settings
  final Map<AppLanguage, String> _languageCodes = {
    AppLanguage.english: 'en-US',
    AppLanguage.tamil: 'ta-IN',
    AppLanguage.tanglish: 'en-IN', // Indian English for Tanglish
  };

  // Voice Settings - Synced with AppSettings
  double _speechRate = 0.5;
  double _speechPitch = 1.0;
  double _speechVolume = 1.0;

  List<dynamic> _availableVoices = [];
  Map<String, String>? _selectedVoice; // {name: ..., locale: ...}
  List<VoiceInfo> _voiceInfoList = [];

  // Getters
  bool get isListening => _isListening;
  bool get isProcessing => _isProcessing;
  bool get isSpeaking => _isSpeaking;
  bool get isActive => _isListening || _isProcessing || _isSpeaking;
  bool get voiceEnabled => _voiceEnabled;
  // REMOVED: continuousListeningEnabled getter
  bool get tapToSpeakEnabled => _tapToSpeakEnabled;
  AppLanguage get currentLanguage => _currentLanguage;
  double get speechRate => _speechRate;
  double get speechPitch => _speechPitch;
  double get speechVolume => _speechVolume;
  List<dynamic> get availableVoices => _availableVoices;
  Map<String, String>? get selectedVoice => _selectedVoice;
  List<VoiceInfo> get voiceInfoList => _voiceInfoList;
  ContextService get contextService => _contextService;
  String get lastRecognizedText => _lastRecognizedText;

  // Command registry
  final Map<String, Function(String)> _localCommands = {};

  void registerCommand(String keyword, Function(String) callback) {
    _localCommands[keyword.toLowerCase()] = callback;
  }

  void unregisterCommand(String keyword) {
    _localCommands.remove(keyword.toLowerCase());
  }

  /// Initialize AI services
  Future<void> initialize() async {
    _speech = stt.SpeechToText();
    _tts = FlutterTts();
    _prefs = await SharedPreferences.getInstance();
    
    // Configure concurrent audio session (Play AND Record)
    await _configureAudioSession();

    // Load local prefs (Voice selection)
    
    final voiceJson = _prefs.getString(_prefVoice);
    if (voiceJson != null) {
      try {
        _selectedVoice = Map<String, String>.from(json.decode(voiceJson));
      } catch (e) {
        debugPrint('Error loading saved voice: $e');
      }
    }
    
    // Load available voices
    try {
      _availableVoices = await _tts.getVoices;
    } catch (e) {
      debugPrint('❌ Error loading voices: $e');
    }
    
    // Configure TTS
    await _configureTTS();
    
    // TTS callbacks
    _tts.setCompletionHandler(() {
      _isSpeaking = false;
      notifyListeners();
      // STRICT TURN-TAKING: Do NOT restart listening automatically.
      // User must tap to reply.
      debugPrint("🔊 TTS Complete. Waiting for user input.");
    });

    _tts.setStartHandler(() {
      _isSpeaking = true;
      notifyListeners();
    });

    _tts.setCancelHandler(() {
      _isSpeaking = false;
      notifyListeners();
      debugPrint("🛑 TTS Cancelled.");
    });

    _tts.setErrorHandler((msg) {
      _isSpeaking = false;
      notifyListeners();
      debugPrint("❌ TTS Error: $msg");
    });

    // Initialize (No Wake Word)
    // REMOVED: await _wakeWordService.initialize();

    debugPrint('✅ Global AI Service initialized (Waiting for startService)');
  }
  
  /// Configure Audio Session for Simultaneous I/O
  Future<void> _configureAudioSession() async {
    final session = await AudioSession.instance;
    await session.configure(AudioSessionConfiguration(
      avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
      avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.allowBluetooth |
          AVAudioSessionCategoryOptions.defaultToSpeaker | 
          AVAudioSessionCategoryOptions.mixWithOthers, // Mix to allow bg audio if needed
      avAudioSessionMode: AVAudioSessionMode.voiceChat, // Optimize for voice
      avAudioSessionRouteSharingPolicy: AVAudioSessionRouteSharingPolicy.defaultPolicy,
      avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
      androidAudioAttributes: const AndroidAudioAttributes(
        contentType: AndroidAudioContentType.speech,
        flags: AndroidAudioFlags.none,
        usage: AndroidAudioUsage.voiceCommunication,
      ),
      androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
      androidWillPauseWhenDucked: true,
    ));
  }
  
  /// Sync with AppSettings from Riverpod
  Future<void> updateSettings(AppSettings settings) async {
    bool wasEnabled = _voiceEnabled;
    AppLanguage wasLanguage = _currentLanguage;
    
    _voiceEnabled = settings.voiceEnabled;
    _tapToSpeakEnabled = settings.tapToSpeakEnabled;
    _speechRate = settings.voiceSpeed;
    
    // Map string language code to AppLanguage
    if (settings.language == 'ta') {
      _currentLanguage = AppLanguage.tamil;
    } else {
      _currentLanguage = AppLanguage.english;
    }

    // Update TTS params
    await _tts.setSpeechRate(_speechRate);
    
    // If language changed, reconfigure TTS
    if (wasLanguage != _currentLanguage) {
      await _configureTTS();
    }

    // Handle Enable/Disable Voice master switch logic
    if (_voiceEnabled && !wasEnabled) {
      // Just enabled -> Start (Ready state)
      await startService();
    } else if (!_voiceEnabled && wasEnabled) {
      // Just disabled -> Stop
      await stopService();
    } else if (_voiceEnabled) {
      // Already enabled
      if (wasLanguage != _currentLanguage) {
         // Just ensure TTS is updated, no need to restart listening if we aren't listening
      }
    }
    
    notifyListeners();
  }

  /// Manually set language (for UI switching)
  Future<void> setLanguage(AppLanguage lang) async {
    if (_currentLanguage == lang) return;
    
    _currentLanguage = lang;
    await _configureTTS();
    
    // Restart voice service if active to apply language change
    // Restart voice service if active to apply language change
    // Manual Mode: do nothing.
    
    notifyListeners();
  }

  /// Start the AI Service (Call after login)
  Future<void> startService() async {
    if (!_voiceEnabled) return;
    debugPrint('🚀 Starting Global AI Service (Ready for Tap)...');
    // NOTE: We do NOT auto-start listening here. 
    // We wait for the user to Tap to Speak.
  }

  /// Manually set listening mode
  // REMOVED: setListeningMode (No longer needed, only Manual exists)

  void setTapToSpeak(bool enabled) {
    if (_tapToSpeakEnabled == enabled) return;
    _tapToSpeakEnabled = enabled;
    notifyListeners();
  }

  /// Stop all AI services
  Future<void> stopService() async {
    debugPrint('🛑 Stopping Global AI Service...');
    if (_isListening) {
      await _speech.stop();
    }
    await _tts.stop();
    // REMOVED: Wake Word stop
    _isListening = false;
    _isSpeaking = false;
    _isProcessing = false;
    notifyListeners();
  }

  // REMOVED: _startWakeWordListening

  /// Set custom voice
  Future<void> setVoice(Map<String, String> voice) async {
    _selectedVoice = voice;
    await _prefs.setString(_prefVoice, json.encode(voice)); // Save
    await _tts.setVoice(voice);
    notifyListeners();
  }

  /// Set voice by VoiceInfo
  Future<void> setVoiceByInfo(VoiceInfo voiceInfo) async {
    final voiceMap = {
      'name': voiceInfo.name,
      'locale': voiceInfo.locale,
    };
    await setVoice(voiceMap);
  }
  
  /// Set voice parameters in one call (for preview/settings page)
  Future<void> setVoiceParameters({
    double? speed,
    double? pitch,
    double? volume,
  }) async {
    if (speed != null) _speechRate = speed;
    if (pitch != null) _speechPitch = pitch;
    if (volume != null) _speechVolume = volume;
    
    await _tts.setSpeechRate(_speechRate);
    await _tts.setPitch(_speechPitch);
    await _tts.setVolume(_speechVolume);
  }

  /// Get available voices filtered by gender and/or accent
  Future<List<VoiceInfo>> getFilteredVoices({
    String? gender,
    String? accent,
  }) async {
    if (_voiceInfoList.isEmpty && _availableVoices.isNotEmpty) {
      _voiceInfoList = _availableVoices
          .map((v) => VoiceInfo.fromMap(v as Map<dynamic, dynamic>))
          .toList();
    }

    var filtered = _voiceInfoList;
    if (gender != null) {
      filtered = filtered.where((v) => v.gender == gender).toList();
    }
    if (accent != null) {
      filtered = filtered.where((v) => v.accent == accent).toList();
    }

    return filtered;
  }

  /// Preview a voice with sample text
  Future<void> previewVoice(VoiceInfo voiceInfo, String sampleText) async {
    final previousVoice = _selectedVoice;
    try {
      await setVoiceByInfo(voiceInfo);
      await speak(sampleText);
    } catch (e) {
      debugPrint('❌ Error previewing voice: $e');
      if (previousVoice != null) {
        await setVoice(previousVoice);
      }
    }
  }

  /// Configure TTS for current language
  Future<void> _configureTTS() async {
    final languageCode = _languageCodes[_currentLanguage]!;
    await _tts.setLanguage(languageCode);
    await _tts.setSpeechRate(_speechRate);
    await _tts.setPitch(_speechPitch);
    
    // Check if selected voice is compatible (basic check)
    if (_selectedVoice != null && 
        _selectedVoice!['locale'].toString().startsWith(languageCode.split('-')[0])) {
      await _tts.setVoice(_selectedVoice!);
      return;
    }
    
    // Auto-select best voice if none selected or incompatible
    if (_currentLanguage == AppLanguage.tamil) {
      try {
        final voices = await _tts.getVoices;
        final tamilVoice = voices.firstWhere(
          (voice) => voice['locale'].toString().contains('ta'),
          orElse: () => null,
        );
        if (tamilVoice != null) {
           final Map<String, String> voiceParams = {
             "name": tamilVoice['name'].toString(), 
             "locale": tamilVoice['locale'].toString()
           };
           await _tts.setVoice(voiceParams);
        }
      } catch (e) {
        debugPrint("Error setting Tamil voice: $e");
      }
    }
  }

  /// Quick voice query from UI button
  Future<void> quickVoiceQuery({String? context}) async {
    if (context != null) {
       // Log context if needed, or update context service
       debugPrint("Voice Query Context: $context");
    }
    
    // Ensure service is started
    if (!_isListening) {
      await startListeningSession();
    }
  }

  /// Start a single listening session (e.g. after tap)
  Future<void> startListeningSession() async {
    if (!_voiceEnabled) return;
    
    // If already listening, just return
    if (_isListening) return; 

    // Initialize if needed (might have been disposed or error)
    bool available = await _speech.initialize(
      onStatus: (status) {
        debugPrint('🎤 Voice status: $status');
        if (status == 'listening') {
          _isListening = true;
          notifyListeners();
        } else if (status == 'done' || status == 'notListening') {
           _isListening = false;
           notifyListeners();
           
           // STRICT TURN-TAKING: No auto-restart here.
           // Session ends. User must tap again.
        }
      },
      onError: (error) {
        // Known issue: frequent 'error_no_match' on silence is normal for continuous listening
        // Only log real errors
        if (error.errorMsg != 'error_no_match') {
           debugPrint('❌ Voice error: ${error.errorMsg}');
        }
        
        _isListening = false;
        notifyListeners();
        
        // STRICT TURN-TAKING: No auto-restart on error.
      },
    );

    if (!available) {
      debugPrint('❌ Speech recognition not available - attempting re-init');
      // Force re-init attempt if first failed
      available = await _speech.initialize();
      if (!available) return;
    }

    _isListening = true;
    notifyListeners();

    // Greeting logic (Only once per session/app launch)
    if (!_hasGreeted) {
       await speak("Hello I'm Travid"); // Updated greeting
       _hasGreeted = true;
    }

    // Get available locales for speech recognition
    final locales = await _speech.locales();
    final currentLocale = _languageCodes[_currentLanguage]!;
    
    // Find matching locale or use default
    final matchingLocale = locales.firstWhere(
      (locale) => locale.localeId.startsWith(currentLocale.split('-')[0]),
      orElse: () => locales.first,
    );

    _speech.listen(
      onResult: (result) async {
        // Barge-in: If users speaks while AI is speaking, stop AI
        if (_isSpeaking && result.recognizedWords.isNotEmpty) {
           debugPrint("🗣️ Barge-in Detected: ${result.recognizedWords}");
           await stopSpeaking(); // Silence AI immediately 
        }

        if (result.finalResult) {
          final text = result.recognizedWords;
          _lastRecognizedText = text;
          
          if (text.trim().isNotEmpty) {
            // Process with AI
            // Note: We do NOT stop listening here. The loop keeps going.
            await _processVoiceInput(text);
          }
        }
      },
      localeId: matchingLocale.localeId,
      listenOptions: stt.SpeechListenOptions(
        cancelOnError: false, // Keep listening on minor errors
        partialResults: true, // Enable for simultaneous barge-in detection
        autoPunctuation: true,
        enableHapticFeedback: false, // Silent
        listenMode: stt.ListenMode.dictation, // Optimized for voice
      ),
    );
  }

  // State for greeting
  bool _hasGreeted = false;

  /// Stop listening
  Future<void> stopListening() async {
    // Stop continuous listening
    if (_isListening) {
      await _speech.stop();
      _isListening = false;
    }
    
    // REMOVED: Wake Word stop
    
    notifyListeners();
  }

  /// Process text input with AI (same as voice but without cues if desired)
  Future<String> processTextQuery(String text, {bool speakResponse = true}) async {
    if (text.trim().isEmpty) return "Please say something.";

    _isProcessing = true;
    notifyListeners();

    try {
      // Gather context
      final context = _contextService.getFullContext();

      // Log activity
      await _chatService.logActivity(
        action: 'text_query',
        data: {'query': text},
      );

      // Get AI response with context
      final response = await _aiService.processQueryWithContext(text, context);
      
      // Update context
      _contextService.addQuery(text, response);
      
      // Save to chat history
      final session = ChatSession(
        id: _currentSessionId,
        createdAt: DateTime.now(),
        topic: text.length > 30 ? '${text.substring(0, 30)}...' : text,
        messages: [
          ChatMessage(
            role: 'user',
            text: text,
            timestamp: DateTime.now(),
          ),
          ChatMessage(
            role: 'ai',
            text: response,
            timestamp: DateTime.now(),
          ),
        ],
      );
      
      await _chatService.saveSession(session);

      // Speak response if requested
      if (speakResponse && _voiceEnabled) {
        await speak(response);
      }
      
      return response;

    } catch (e) {
      debugPrint('❌ AI Error: $e');
      return "I'm sorry, I encountered an error. Please try again.";
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  /// Process voice input with AI
  Future<void> _processVoiceInput(String userInput) async {
    if (userInput.trim().isEmpty) return;

    // Check for "Stop" command
    final lower = userInput.toLowerCase();
    if (lower == 'stop' || lower == 'quiet' || lower == 'niruthu') {
      await _tts.stop();
      _isSpeaking = false;
      notifyListeners();
      return;
    }

    // Voice customization commands (simplified)
    if (lower.contains('speak faster')) {
      final newSpeed = (_speechRate + 0.2).clamp(0.5, 2.0);
      _speechRate = newSpeed;
      await _tts.setSpeechRate(newSpeed);
      await speak('Speaking faster now');
      return;
    }
    
    // Check registered commands
    for (final command in _localCommands.keys) {
      if (lower.contains(command)) {
        debugPrint("Executing local command: $command");
        _localCommands[command]?.call(userInput);
        return;
      }
    }

    _isProcessing = true;
    notifyListeners();

    try {
      // Gather full context
      final context = _contextService.getFullContext();

      // Log activity
      await _chatService.logActivity(
        action: 'voice_query',
        data: {'query': userInput},
      );

      // DIRECT AI CALL - No separate intent detection to save quota (50% reduction)
      // The main prompt handles navigation/context anyway.
      String response = await _aiService.processQueryWithContext(userInput, context);
      
      // Update context with this interaction
      _contextService.addQuery(userInput, response);
      
      // Save to chat history
      final session = ChatSession(
        id: _currentSessionId,
        createdAt: DateTime.now(),
        topic: userInput.length > 30 ? '${userInput.substring(0, 30)}...' : userInput,
        messages: [
          ChatMessage(
            role: 'user',
            text: userInput,
            timestamp: DateTime.now(),
          ),
          ChatMessage(
            role: 'ai',
            text: response,
            timestamp: DateTime.now(),
          ),
        ],
      );
      
      await _chatService.saveSession(session);

      // Speak response
      await speak(response);

    } catch (e) {
      debugPrint('❌ AI Error: $e');
      
      // Offline / Error Handling
      final lowerInput = userInput.toLowerCase();
      String fallbackResponse = "";
      
      if (e.toString().contains('quota') || e.toString().contains('429')) {
        fallbackResponse = "Usage limit reached. Please wait a moment.";
      } else if (lowerInput.contains('time')) {
        final time = DateFormat.jm().format(DateTime.now());
        fallbackResponse = "The time is $time";
      } else {
        fallbackResponse = "I'm having trouble connecting. Please try again later.";
      }
      
      await speak(fallbackResponse);
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  /// Speak text using TTS
  Future<void> speak(String text) async {
    if (text.isEmpty || !_voiceEnabled) return;

    // Optional: Stop listening before speaking to avoid echo and resource conflict
    // for a more robust "Turn-Taking" experience.
    await stopListening(); 

    _isSpeaking = true;
    notifyListeners();

    try {
      await _tts.setSpeechRate(_speechRate);
      await _tts.setPitch(_speechPitch);
      await _tts.speak(text);
      // Completion handler will resume listening
    } catch (e) {
      debugPrint('❌ Error speaking: $e');
      _isSpeaking = false;
      notifyListeners();
      // STRICT TURN-TAKING: No auto-restart on error.
    }
  }

  /// Stop speaking and reset state
  Future<void> stopSpeaking() async {
    await _tts.stop();
    _isSpeaking = false;
    _isProcessing = false; // Ensure we aren't stuck in processing
    notifyListeners();
  }

  /// Start new session
  void startNewSession() {
    _currentSessionId = const Uuid().v4();
    notifyListeners();
  }
  
  @override
  void dispose() {
    _speech.stop();
    _tts.stop();
    super.dispose();
  }
}
