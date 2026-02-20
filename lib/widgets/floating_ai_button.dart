import 'package:flutter/material.dart';
import 'package:travid/services/global_ai_service.dart';
import 'package:travid/widgets/voice_indicator.dart';

/// Floating AI Assistant Button
/// Shows on home screen and other pages
/// Tap to activate voice input
class FloatingAIButton extends StatefulWidget {
  final String? context; // Optional context for better AI responses
  
  const FloatingAIButton({
    super.key,
    this.context,
  });

  @override
  State<FloatingAIButton> createState() => _FloatingAIButtonState();
}

class _FloatingAIButtonState extends State<FloatingAIButton> {
  final GlobalAIService _aiService = GlobalAIService();

  @override
  void initState() {
    super.initState();
    _aiService.addListener(_onAIStateChanged);
  }

  @override
  void dispose() {
    _aiService.removeListener(_onAIStateChanged);
    super.dispose();
  }

  void _onAIStateChanged() {
    if (mounted) setState(() {});
  }

  void _handleTap() {
    if (_aiService.isActive) {
      // Stop current activity
      _aiService.stopListening();
      _aiService.stopSpeaking();
    } else {
      // Start voice input
      _aiService.quickVoiceQuery(context: widget.context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 16,
      bottom: 80,
      child: GestureDetector(
        onTap: _handleTap,
        child: VoiceIndicator(
          isListening: _aiService.isListening,
          onTap: _handleTap,
        ),
      ),
    );
  }
}

/// Compact AI Button for app bars
class CompactAIButton extends StatefulWidget {
  final String? context;
  
  const CompactAIButton({
    super.key,
    this.context,
  });

  @override
  State<CompactAIButton> createState() => _CompactAIButtonState();
}

class _CompactAIButtonState extends State<CompactAIButton> {
  final GlobalAIService _aiService = GlobalAIService();

  @override
  void initState() {
    super.initState();
    _aiService.addListener(_onAIStateChanged);
  }

  @override
  void dispose() {
    _aiService.removeListener(_onAIStateChanged);
    super.dispose();
  }

  void _onAIStateChanged() {
    if (mounted) setState(() {});
  }

  void _handleTap() {
    if (_aiService.isActive) {
      _aiService.stopListening();
      _aiService.stopSpeaking();
    } else {
      _aiService.quickVoiceQuery(context: widget.context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CompactVoiceIndicator(
      isListening: _aiService.isListening,
      onTap: _handleTap,
    );
  }
}

/// AI Status Indicator (shows when AI is processing/speaking)
class AIStatusIndicator extends StatefulWidget {
  const AIStatusIndicator({super.key});

  @override
  State<AIStatusIndicator> createState() => _AIStatusIndicatorState();
}

class _AIStatusIndicatorState extends State<AIStatusIndicator> {
  final GlobalAIService _aiService = GlobalAIService();

  @override
  void initState() {
    super.initState();
    _aiService.addListener(_onAIStateChanged);
  }

  @override
  void dispose() {
    _aiService.removeListener(_onAIStateChanged);
    super.dispose();
  }

  void _onAIStateChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (!_aiService.isActive) return const SizedBox.shrink();

    String status = '';
    Color color = Colors.blue;

    if (_aiService.isListening) {
      status = 'Listening...';
      color = Colors.red;
    } else if (_aiService.isProcessing) {
      status = 'Thinking...';
      color = Colors.orange;
    } else if (_aiService.isSpeaking) {
      status = 'Speaking...';
      color = Colors.green;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            status,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
