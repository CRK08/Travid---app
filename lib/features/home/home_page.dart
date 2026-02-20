import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travid/core/app_theme.dart';
import 'package:travid/core/providers.dart';
import 'package:travid/core/app_translations.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    String t(String key) => AppTranslations.get(key, settings.language);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              
              // App Logo/Title
              Center(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryLight.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.assistant,
                        size: 60,
                        color: AppTheme.primaryLight,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      t('app_title'),
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryLight,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      t('app_subtitle'),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 40),
              
              // Quick Start Guide
              _buildCard(
                context,
                icon: Icons.mic,
                iconColor: AppTheme.secondaryLight,
                title: t('wake_word_card'),
                description: t('wake_word_desc'),
              ),
              
              const SizedBox(height: 12),
              
              _buildCard(
                context,
                icon: Icons.directions_bus,
                iconColor: Colors.orange,
                title: t('bus_card'),
                description: t('bus_desc'),
              ),
              
              const SizedBox(height: 12),
              
              _buildCard(
                context,
                icon: Icons.map,
                iconColor: Colors.blue,
                title: t('nav_card'),
                description: t('nav_desc'),
              ),
              
              const SizedBox(height: 12),
              
              _buildCard(
                context,
                icon: Icons.chat,
                iconColor: Colors.purple,
                title: t('chat_card'),
                description: t('chat_desc'),
              ),
              
              const SizedBox(height: 12),
              
              _buildCard(
                context,
                icon: Icons.settings_voice,
                iconColor: Colors.green,
                title: t('voice_settings_card'),
                description: t('voice_settings_desc'),
              ),
              
              const SizedBox(height: 30),
              
              // Quick Tips
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark 
                    ? AppTheme.surfaceDark 
                    : AppTheme.primaryLight.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppTheme.primaryLight.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          size: 20,
                          color: AppTheme.primaryLight,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          t('quick_tips'),
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildTip(t('tip_continuous')),
                    _buildTip(t('tip_stop')),
                    _buildTip(t('tip_wake')),
                    _buildTip(t('tip_features')),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTip(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 14)),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
