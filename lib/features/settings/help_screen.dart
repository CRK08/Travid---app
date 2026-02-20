import 'package:flutter/material.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Tutorial'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection(
            context,
            'Getting Started',
            'Travid is your voice-enabled travel assistant. You can use voice commands or the touch interface to navigate.',
            Icons.start,
          ),
          const SizedBox(height: 16),
          _buildSection(
            context,
            'Voice Commands',
            '• "Take me to [Destination]"\n'
            '• "Where am I?"\n'
            '• "Stop navigation"\n'
            '• "Help" or "What can I say?"',
            Icons.mic,
          ),
           const SizedBox(height: 16),
          _buildSection(
            context,
            'Navigation',
            '1. Open the Map tab.\n'
            '2. Tap the microphone button or say "Take me to...".\n'
            '3. Follow the voice instructions.\n'
            '4. Use "Simulate" to test without moving.',
            Icons.navigation,
          ),
          const SizedBox(height: 16),
          _buildSection(
            context,
            'Settings',
            'Customize voice speed, pitch, and high contrast mode in the Settings tab.',
            Icons.settings,
          ),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String content, IconData icon) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              content,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
