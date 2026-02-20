import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';
import '../../widgets/voice_settings_card.dart';
import 'voice_settings_page.dart';
import 'help_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final settingsNotifier = ref.read(settingsProvider.notifier);
    final feedback = ref.read(feedbackServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // General / Language Section
          _buildSectionHeader('General'),
          _buildCard([
             ListTile(
              leading: const Icon(Icons.language, color: Colors.blue),
              title: const Text('App Language'),
              subtitle: Text(settings.language == 'ta' ? 'Tamil (தமிழ்)' : 'English'),
              trailing: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: settings.language,
                  items: const [
                    DropdownMenuItem(
                      value: 'en',
                      child: Text('English'),
                    ),
                    DropdownMenuItem(
                      value: 'ta',
                      child: Text('Tamil (தமிழ்)'),
                    ),
                  ],
                  onChanged: (String? newValue) async {
                    if (newValue != null && newValue != settings.language) {
                      await feedback.medium();
                      final newSettings = settings.copyWith(language: newValue);
                      await settingsNotifier.updateSettings(newSettings);
                      
                      // Speak confirmation in new language
                      if (newValue == 'ta') {
                        await feedback.speak('மொழி தமிழுக்கு மாற்றப்பட்டது');
                      } else {
                        await feedback.speak('Language changed to English');
                      }
                    }
                  },
                ),
              ),
            ),
          ]),
          const SizedBox(height: 24),

          // Accessibility Mode Section
          _buildSectionHeader('Accessibility'),
          _buildCard([
            SwitchListTile(
              title: const Text(
                'Accessibility Mode',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: const Text('Optimized for blind users'),
              value: settings.accessibilityMode,
              onChanged: (value) async {
                await feedback.medium();
                await settingsNotifier.toggleAccessibilityMode();
                if (value) {
                  await feedback.speak('Accessibility mode enabled');
                } else {
                  await feedback.speak('Accessibility mode disabled');
                }
              },
              activeThumbColor: Colors.green,
            ),
            if (settings.accessibilityMode)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green.shade700),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Large buttons, voice feedback, and haptic enabled',
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ]),
          const SizedBox(height: 24),

          // AI Voice Assistant Section
          const VoiceSettingsCard(),
          const SizedBox(height: 24),

          // Voice Control Section
          _buildSectionHeader('Voice Control'),
          _buildCard([
            SwitchListTile(
              title: const Text(
                'Enable AI Voice Assistant',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                settings.voiceEnabled 
                  ? 'App is listening & speaking (Master Switch)' 
                  : 'All voice features disabled',
                  style: TextStyle(
                    color: settings.voiceEnabled ? Colors.green : Colors.red,
                    fontWeight: FontWeight.w500
                  ),
              ),
              value: settings.voiceEnabled,
              onChanged: (value) async {
                print('🔊 Toggling voice from ${settings.voiceEnabled} to $value');
                await feedback.medium();
                await settingsNotifier.toggleVoice();
                
                // Feedback handled by service mostly, but we can speak generic confirmation
                // Note: If disabling, service stops immediately, so feedback might not play fully
                // from GlobalService, but FeedbackService is separate.
              },
              activeThumbColor: Colors.blue,
            ),
            SwitchListTile(
              title: const Text('Wake Word Detection'),
              subtitle: const Text('Activate with "Hey Travid"'),
              value: settings.wakeWordEnabled,
              onChanged: settings.voiceEnabled ? (value) async {
                await feedback.light();
                final newSettings = settings.copyWith(wakeWordEnabled: value);
                await settingsNotifier.updateSettings(newSettings);
              } : null, // Disable if master switch is off
              activeThumbColor: Colors.blue,
            ),
            // REMOVED: Continuous Listening Switch
            if (settings.voiceEnabled)
              SwitchListTile(
                title: const Text('Voice for Maps Only'),
                subtitle: const Text('Voice guidance only during navigation'),
                value: settings.voiceForMapsOnly,
                onChanged: (value) async {
                  await feedback.light();
                  final newSettings = settings.copyWith(voiceForMapsOnly: value);
                  await settingsNotifier.updateSettings(newSettings);
                },
                activeThumbColor: Colors.blue,
              ),
            if (settings.voiceEnabled)
              ListTile(
                title: const Text('Voice Speed'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${settings.voiceSpeed.toStringAsFixed(1)}x'),
                    Slider(
                      value: settings.voiceSpeed,
                      min: 0.5,
                      max: 2.0,
                      divisions: 15,
                      label: '${settings.voiceSpeed.toStringAsFixed(1)}x',
                      onChanged: (value) async {
                        await settingsNotifier.setVoiceSpeed(value);
                      },
                      onChangeEnd: (value) async {
                        await feedback.speak(
                          'Voice speed set to ${value.toStringAsFixed(1)} times',
                        );
                      },
                    ),
                  ],
                ),
              ),
          ]),
          const SizedBox(height: 24),

          // Audio & Haptic Section
          _buildSectionHeader('Feedback'),
          _buildCard([
            SwitchListTile(
              title: const Text(
                'Audio Feedback',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              subtitle: const Text('Spoken confirmations for actions'),
              value: settings.audioFeedback,
              onChanged: (value) async {
                await feedback.medium();
                final newSettings = settings.copyWith(audioFeedback: value);
                await settingsNotifier.updateSettings(newSettings);
                if (value) {
                  await feedback.speak('Audio feedback enabled');
                }
              },
              activeThumbColor: Colors.orange,
            ),
            SwitchListTile(
              title: const Text(
                'Sound Effects',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              subtitle: const Text('Click sounds and alerts'),
              value: settings.soundEffects,
              onChanged: (value) async {
                await feedback.light();
                final newSettings = settings.copyWith(soundEffects: value);
                await settingsNotifier.updateSettings(newSettings);
              },
              activeThumbColor: Colors.orange,
            ),
            SwitchListTile(
              title: const Text(
                'Vibration',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              subtitle: const Text('Haptic feedback for interactions'),
              value: settings.hapticEnabled,
              onChanged: (value) async {
                if (value) {
                  await feedback.success();
                }
                await settingsNotifier.toggleHaptic();
                if (value && settings.audioFeedback) {
                  await feedback.speak('Vibration enabled');
                }
              },
              activeThumbColor: Colors.orange,
            ),
          ]),
          const SizedBox(height: 24),

          // Visual Settings Section
          _buildSectionHeader('Visual'),
          _buildCard([
            SwitchListTile(
              title: const Text(
                'High Contrast',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              subtitle: const Text('Increase color contrast'),
              value: settings.highContrast,
              onChanged: (value) async {
                await feedback.medium();
                final newSettings = settings.copyWith(highContrast: value);
                await settingsNotifier.updateSettings(newSettings);
                if (settings.audioFeedback) {
                  await feedback.speak(
                    value ? 'High contrast enabled' : 'High contrast disabled',
                  );
                }
              },
              activeThumbColor: Colors.purple,
            ),
            SwitchListTile(
              title: const Text(
                'Dark Mode',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              subtitle: const Text('Use dark theme'),
              value: settings.darkMode,
              onChanged: (value) async {
                await feedback.light();
                final newSettings = settings.copyWith(darkMode: value);
                await settingsNotifier.updateSettings(newSettings);
              },
              activeThumbColor: Colors.purple,
            ),
            ListTile(
              title: const Text('Text Size'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${(settings.textScale * 100).round()}%'),
                  Slider(
                    value: settings.textScale,
                    min: 0.8,
                    max: 2.0,
                    divisions: 12,
                    label: '${(settings.textScale * 100).round()}%',
                    onChanged: (value) async {
                      await settingsNotifier.setTextScale(value);
                    },
                    onChangeEnd: (value) async {
                      await feedback.light();
                      if (settings.audioFeedback) {
                        await feedback.speak(
                          'Text size set to ${(value * 100).round()} percent',
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ]),
          const SizedBox(height: 24),

          // Notifications Section
          _buildSectionHeader('Notifications'),
          _buildCard([
            SwitchListTile(
              title: const Text(
                'Notifications',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              subtitle: const Text('Enable app notifications'),
              value: settings.notificationsEnabled,
              onChanged: (value) async {
                await feedback.medium();
                final newSettings = settings.copyWith(notificationsEnabled: value);
                await settingsNotifier.updateSettings(newSettings);
              },
              activeThumbColor: Colors.red,
            ),
            if (settings.notificationsEnabled)
              SwitchListTile(
                title: const Text('Bus Arrival Alerts'),
                subtitle: const Text('Get notified when bus is approaching'),
                value: settings.busArrivalAlerts,
                onChanged: (value) async {
                  await feedback.light();
                  final newSettings = settings.copyWith(busArrivalAlerts: value);
                  await settingsNotifier.updateSettings(newSettings);
                },
                activeThumbColor: Colors.red,
              ),
            if (settings.notificationsEnabled && settings.busArrivalAlerts)
              ListTile(
                title: const Text('Alert Before'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${settings.alertMinutesBefore} minutes'),
                    Slider(
                      value: settings.alertMinutesBefore.toDouble(),
                      min: 1,
                      max: 15,
                      divisions: 14,
                      label: '${settings.alertMinutesBefore} min',
                      onChanged: (value) async {
                        final newSettings = settings.copyWith(
                          alertMinutesBefore: value.round(),
                        );
                        await settingsNotifier.updateSettings(newSettings);
                      },
                    ),
                  ],
                ),
              ),
          ]),
          const SizedBox(height: 24),

          // About Section
          _buildSectionHeader('About'),
          _buildCard([
            ListTile(
              leading: const Icon(Icons.settings_voice, color: Colors.blue),
              title: const Text('Voice Settings'),
              subtitle: const Text('Customize voice, accent, and parameters'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () async {
                await feedback.light();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const VoiceSettingsPage(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline, color: Colors.blue),
              title: const Text('About Travid'),
              subtitle: const Text('Version 1.0.0'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () async {
                await feedback.light();
                _showAboutDialog(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.help_outline, color: Colors.blue),
              title: const Text('Help & Tutorial'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () async {
                await feedback.light();
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const HelpScreen()),
                );
              },
            ),
          ]),
          const SizedBox(height: 24),

          // Test Feedback Button
          if (settings.accessibilityMode)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ElevatedButton.icon(
                onPressed: () async {
                  await feedback.success();
                  await feedback.speak(
                    'This is a test of voice and haptic feedback',
                  );
                },
                icon: const Icon(Icons.volume_up),
                label: const Text('Test Voice & Haptic'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
                  textStyle: const TextStyle(fontSize: 18),
                ),
              ),
            ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About Travid'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Travid - Voice-Enabled Travel Assistant',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('Version: 1.0.0'),
            SizedBox(height: 8),
            Text(
              'An accessible travel app designed for both blind and sighted users.',
            ),
            SizedBox(height: 16),
            Text(
              'Features:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text('• Voice-guided navigation'),
            Text('• Haptic feedback'),
            Text('• Accessibility mode'),
            Text('• Bus route search'),
            Text('• Real-time updates'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
