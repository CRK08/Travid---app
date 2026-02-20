import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../models/app_settings.dart';
import '../services/auth_service.dart';
import '../services/feedback_service.dart';

/// Auth service provider
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

/// Auth state changes stream provider
final authStateProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

/// Current user data provider
final currentUserProvider = FutureProvider<UserModel?>((ref) async {
  final authState = ref.watch(authStateProvider);
  
  return authState.when(
    data: (user) async {
      if (user != null) {
        final authService = ref.watch(authServiceProvider);
        return await authService.getUserData(user.uid);
      }
      return null;
    },
    loading: () => null,
    error: (_, __) => null,
  );
});

/// Is logged in provider
final isLoggedInProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.value != null;
});

/// App settings provider
final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  return SettingsNotifier();
});

/// Settings notifier
class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier() : super(AppSettings()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    state = await AppSettings.load();
    // Initialize feedback service with loaded settings
    await FeedbackService().initialize(state);
  }

  Future<void> updateSettings(AppSettings newSettings) async {
    state = newSettings;
    await newSettings.save();
    // Update feedback service
    FeedbackService().updateSettings(newSettings);
  }

  Future<void> toggleAccessibilityMode() async {
    final newSettings = state.copyWith(
      accessibilityMode: !state.accessibilityMode,
      // When enabling accessibility mode, enable audio feedback
      audioFeedback: !state.accessibilityMode ? true : state.audioFeedback,
    );
    await updateSettings(newSettings);
  }

  Future<void> toggleVoice() async {
    final newSettings = state.copyWith(voiceEnabled: !state.voiceEnabled);
    await updateSettings(newSettings);
  }

  Future<void> toggleHaptic() async {
    final newSettings = state.copyWith(hapticEnabled: !state.hapticEnabled);
    await updateSettings(newSettings);
  }

  Future<void> setVoiceSpeed(double speed) async {
    final newSettings = state.copyWith(voiceSpeed: speed);
    await updateSettings(newSettings);
  }

  Future<void> setTextScale(double scale) async {
    final newSettings = state.copyWith(textScale: scale);
    await updateSettings(newSettings);
  }
}

/// Feedback service provider
final feedbackServiceProvider = Provider<FeedbackService>((ref) {
  return FeedbackService();
});
