import 'package:flutter/material.dart';
import 'package:travid/services/global_ai_service.dart';

/// Language Selector Widget
/// Allows users to switch between Tamil, English, and Tanglish
class LanguageSelector extends StatefulWidget {
  const LanguageSelector({super.key});

  @override
  State<LanguageSelector> createState() => _LanguageSelectorState();
}

class _LanguageSelectorState extends State<LanguageSelector> {
  final GlobalAIService _aiService = GlobalAIService();

  @override
  void initState() {
    super.initState();
    _aiService.addListener(_onLanguageChanged);
  }

  @override
  void dispose() {
    _aiService.removeListener(_onLanguageChanged);
    super.dispose();
  }

  void _onLanguageChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Voice Language',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildLanguageOption(
              AppLanguage.english,
              'English',
              'en-US',
              Icons.language,
            ),
            const SizedBox(height: 8),
            _buildLanguageOption(
              AppLanguage.tamil,
              'தமிழ் (Tamil)',
              'ta-IN',
              Icons.language,
            ),
            const SizedBox(height: 8),
            _buildLanguageOption(
              AppLanguage.tanglish,
              'Tanglish (Tamil + English)',
              'en-IN',
              Icons.translate,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption(
    AppLanguage language,
    String label,
    String locale,
    IconData icon,
  ) {
    final isSelected = _aiService.currentLanguage == language;

    return InkWell(
      onTap: () async {
        await _aiService.setLanguage(language);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Language changed to $label'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.withValues(alpha: 0.1) : null,
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.blue : Colors.grey,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? Colors.blue : Colors.black87,
                    ),
                  ),
                  Text(
                    locale,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: Colors.blue,
              ),
          ],
        ),
      ),
    );
  }
}
