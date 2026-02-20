import 'package:shared_preferences/shared_preferences.dart';

/// App settings model for dual-mode (Accessibility + Standard)
class AppSettings {
  // Accessibility Mode
  bool accessibilityMode;
  
  // Voice Control
  bool voiceEnabled;
  bool voiceForMapsOnly;  // If true, voice only works on map screen
  double voiceSpeed;      // TTS speed (0.5 - 2.0)
  // REMOVED: wakeWordEnabled
  bool tapToSpeakEnabled; // Enable full-screen tap to speak
  
  // Audio Feedback
  bool audioFeedback;     // Spoken confirmations
  bool soundEffects;      // Click sounds, alerts
  
  // Haptic Feedback
  bool hapticEnabled;
  
  // Visual Settings
  bool highContrast;
  double textScale;       // 0.8 - 2.0
  bool darkMode;
  
  // Language
  String language;
  
  // Notifications
  bool notificationsEnabled;
  bool busArrivalAlerts;
  int alertMinutesBefore;  // Alert X minutes before bus arrival
  
  AppSettings({
    this.accessibilityMode = false,
    this.voiceEnabled = true,
    this.voiceForMapsOnly = true,  // Default: voice only for maps
    this.voiceSpeed = 1.0,
    // REMOVED: wakeWordEnabled
    this.tapToSpeakEnabled = false,
    this.audioFeedback = false,
    this.soundEffects = true,
    this.hapticEnabled = true,
    this.highContrast = false,
    this.textScale = 1.0,
    this.darkMode = false,
    this.language = 'en',
    this.notificationsEnabled = true,
    this.busArrivalAlerts = true,
    this.alertMinutesBefore = 5,
  });

  /// Load settings from SharedPreferences
  static Future<AppSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    
    return AppSettings(
      accessibilityMode: prefs.getBool('accessibilityMode') ?? false,
      voiceEnabled: prefs.getBool('voiceEnabled') ?? true,
      voiceForMapsOnly: prefs.getBool('voiceForMapsOnly') ?? true,
      voiceSpeed: prefs.getDouble('voiceSpeed') ?? 1.0,
      // REMOVED: wakeWordEnabled
      tapToSpeakEnabled: prefs.getBool('tapToSpeakEnabled') ?? false,
      audioFeedback: prefs.getBool('audioFeedback') ?? false,
      soundEffects: prefs.getBool('soundEffects') ?? true,
      hapticEnabled: prefs.getBool('hapticEnabled') ?? true,
      highContrast: prefs.getBool('highContrast') ?? false,
      textScale: prefs.getDouble('textScale') ?? 1.0,
      darkMode: prefs.getBool('darkMode') ?? false,
      language: prefs.getString('language') ?? 'en',
      notificationsEnabled: prefs.getBool('notificationsEnabled') ?? true,
      busArrivalAlerts: prefs.getBool('busArrivalAlerts') ?? true,
      alertMinutesBefore: prefs.getInt('alertMinutesBefore') ?? 5,
    );
  }

  /// Save settings to SharedPreferences
  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.setBool('accessibilityMode', accessibilityMode);
    await prefs.setBool('voiceEnabled', voiceEnabled);
    await prefs.setBool('voiceForMapsOnly', voiceForMapsOnly);
    await prefs.setDouble('voiceSpeed', voiceSpeed);
    // REMOVED: wakeWordEnabled
    await prefs.setBool('tapToSpeakEnabled', tapToSpeakEnabled);
    await prefs.setBool('audioFeedback', audioFeedback);
    await prefs.setBool('soundEffects', soundEffects);
    await prefs.setBool('hapticEnabled', hapticEnabled);
    await prefs.setBool('highContrast', highContrast);
    await prefs.setDouble('textScale', textScale);
    await prefs.setBool('darkMode', darkMode);
    await prefs.setString('language', language);
    await prefs.setBool('notificationsEnabled', notificationsEnabled);
    await prefs.setBool('busArrivalAlerts', busArrivalAlerts);
    await prefs.setInt('alertMinutesBefore', alertMinutesBefore);
  }

  /// Copy with updated values
  AppSettings copyWith({
    bool? accessibilityMode,
    bool? voiceEnabled,
    bool? voiceForMapsOnly,
    double? voiceSpeed,
    // REMOVED: wakeWordEnabled
    bool? tapToSpeakEnabled,
    bool? audioFeedback,
    bool? soundEffects,
    bool? hapticEnabled,
    bool? highContrast,
    double? textScale,
    bool? darkMode,
    String? language,
    bool? notificationsEnabled,
    bool? busArrivalAlerts,
    int? alertMinutesBefore,
  }) {
    return AppSettings(
      accessibilityMode: accessibilityMode ?? this.accessibilityMode,
      voiceEnabled: voiceEnabled ?? this.voiceEnabled,
      voiceForMapsOnly: voiceForMapsOnly ?? this.voiceForMapsOnly,
      voiceSpeed: voiceSpeed ?? this.voiceSpeed,
      // REMOVED: wakeWordEnabled
      tapToSpeakEnabled: tapToSpeakEnabled ?? this.tapToSpeakEnabled,
      audioFeedback: audioFeedback ?? this.audioFeedback,
      soundEffects: soundEffects ?? this.soundEffects,
      hapticEnabled: hapticEnabled ?? this.hapticEnabled,
      highContrast: highContrast ?? this.highContrast,
      textScale: textScale ?? this.textScale,
      darkMode: darkMode ?? this.darkMode,
      language: language ?? this.language,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      busArrivalAlerts: busArrivalAlerts ?? this.busArrivalAlerts,
      alertMinutesBefore: alertMinutesBefore ?? this.alertMinutesBefore,
    );
  }

  @override
  String toString() {
    return 'AppSettings(accessibilityMode: $accessibilityMode, '
        'voiceEnabled: $voiceEnabled, voiceForMapsOnly: $voiceForMapsOnly)';
  }
}
