import 'package:flutter/material.dart';
import 'package:travid/services/global_ai_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travid/core/providers.dart';
import 'package:travid/models/app_settings.dart';

/// Voice Settings Widget
/// Controls Language, Wake Word Mode, and Custom Wake Word
class VoiceSettingsCard extends StatefulWidget {
  const VoiceSettingsCard({super.key});

  @override
  State<VoiceSettingsCard> createState() => _VoiceSettingsCardState();
}

class _VoiceSettingsCardState extends State<VoiceSettingsCard> {
  final GlobalAIService _aiService = GlobalAIService();
  @override
  void initState() {
    super.initState();
    _aiService.addListener(_onServiceChanged);
  }

  @override
  void dispose() {
    _aiService.removeListener(_onServiceChanged);
    super.dispose();
  }

  void _onServiceChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const Row(
              children: [
                Icon(Icons.record_voice_over, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Voice Settings',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            
            // Language Selection
            const Text(
              'Language',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            _buildLanguageOption(AppLanguage.english, 'English (US)', 'en-US'),
            _buildLanguageOption(AppLanguage.tamil, 'தமிழ் (Tamil)', 'ta-IN'),
            _buildLanguageOption(AppLanguage.tanglish, 'Tanglish', 'en-IN'),
            
            const SizedBox(height: 24),
            
            // Tap to Speak Option
            Consumer(
              builder: (context, ref, child) {
                final settings = ref.watch(settingsProvider);
                return SwitchListTile(
                  title: const Text('Tap Anywhere to Speak'),
                  subtitle: const Text('Tap screen to start listening (Accessibility)'),
                  value: settings.tapToSpeakEnabled,
                  onChanged: (value) {
                     ref.read(settingsProvider.notifier).updateSettings(
                       settings.copyWith(tapToSpeakEnabled: value)
                     );
                  },
                  activeThumbColor: Colors.blue,
                  contentPadding: EdgeInsets.zero,
                );
              },
            ),
            
            const SizedBox(height: 24),
            
            // Voice Character
            const Text(
              'Voice Customization',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            
            // Speed Slider
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Speed'),
                Text('${_aiService.speechRate.toStringAsFixed(1)}x', 
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
              ],
            ),
            Slider(
              value: _aiService.speechRate,
              min: 0.1,
              max: 2.0,
              divisions: 19,
              onChanged: (value) => _aiService.setSpeechRate(value),
            ),
            
            // Pitch Slider
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Pitch'),
                Text(_aiService.speechPitch.toStringAsFixed(1),
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
              ],
            ),
            Slider(
              value: _aiService.speechPitch,
              min: 0.5,
              max: 2.0,
              divisions: 15,
              onChanged: (value) => _aiService.setSpeechPitch(value),
            ),

            // Voice Selector
            if (_aiService.availableVoices.isNotEmpty) ...[
               const SizedBox(height: 8),
               const Text('Select Voice'),
               const SizedBox(height: 8),
               DropdownButtonFormField<String>(
                 isExpanded: true,
                 decoration: InputDecoration(
                   border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                   contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                 ),
                 // We use name as value to avoid object equality issues
                 initialValue: _aiService.selectedVoice?['name'], 
                 hint: const Text("Default System Voice"),
                 items: _getFilteredVoices().map((voice) {
                   return DropdownMenuItem<String>(
                     value: voice['name'],
                     child: Text(
                       voice['name']!, 
                       overflow: TextOverflow.ellipsis,
                       style: const TextStyle(fontSize: 14),
                     ),
                   );
                 }).toList(),
                 onChanged: (name) {
                   if (name != null) {
                     final voice = _getFilteredVoices().firstWhere((v) => v['name'] == name);
                     _aiService.setVoice(voice);
                   }
                 },
               ),
             
             const SizedBox(height: 16),
             Center(
               child: ElevatedButton.icon(
                 onPressed: () {
                   final text = _aiService.currentLanguage == AppLanguage.tamil
                       ? "இது ஒரு சோதனை குரல்" 
                       : "This is a test of the customized voice";
                   _aiService.speak(text);
                 },
                 icon: const Icon(Icons.volume_up),
                 label: const Text("Test Voice"),
                 style: ElevatedButton.styleFrom(
                   backgroundColor: Colors.blue.withValues(alpha: 0.1),
                   foregroundColor: Colors.blue,
                   elevation: 0,
                 ),
               ),
             ),
            ],
          ],
        ),
      ),
    );
  }

  /// Get voices filtered by current language
  List<Map<String, String>> _getFilteredVoices() {
    try {
      final languageCode = _aiService.currentLanguage == AppLanguage.tamil 
          ? 'ta' 
          : 'en';
          
      return _aiService.availableVoices
          .where((voice) => voice['locale'].toString().contains(languageCode))
          .map<Map<String, String>>((voice) => {
            "name": voice['name'].toString(), 
            "locale": voice['locale'].toString()
          })
          .toList();
    } catch (e) {
      debugPrint("Error filtering voices: $e");
      return [];
    }
  }

  Widget _buildLanguageOption(AppLanguage lang, String label, String code) {
    return RadioListTile<AppLanguage>(
      title: Text(label),
      subtitle: Text(code),
      value: lang,
      groupValue: _aiService.currentLanguage,
      onChanged: (value) {
        if (value != null) {
          _aiService.setLanguage(value);
        }
      },
      contentPadding: EdgeInsets.zero,
      activeColor: Colors.blue,
    );
  }
}
