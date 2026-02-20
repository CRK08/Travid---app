import 'package:flutter/material.dart';

/// Animated voice indicator that pulses when listening
class VoiceIndicator extends StatefulWidget {
  final bool isListening;
  final VoidCallback? onTap;
  
  const VoiceIndicator({
    super.key,
    required this.isListening,
    this.onTap,
  });

  @override
  State<VoiceIndicator> createState() => _VoiceIndicatorState();
}

class _VoiceIndicatorState extends State<VoiceIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _opacityAnimation = Tween<double>(begin: 0.5, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    if (widget.isListening) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(VoiceIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isListening && !oldWidget.isListening) {
      _controller.repeat(reverse: true);
    } else if (!widget.isListening && oldWidget.isListening) {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Pulsing outer circle (only when listening)
          if (widget.isListening)
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Container(
                  width: 80 * _scaleAnimation.value,
                  height: 80 * _scaleAnimation.value,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.blue.withValues(
                      alpha: 0.3 * (1 - _opacityAnimation.value),
                    ),
                  ),
                );
              },
            ),

          // Middle pulsing circle
          if (widget.isListening)
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Container(
                  width: 65 * (1 + (_scaleAnimation.value - 1) * 0.5),
                  height: 65 * (1 + (_scaleAnimation.value - 1) * 0.5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.blue.withValues(
                      alpha: 0.5 * (1 - _opacityAnimation.value * 0.5),
                    ),
                  ),
                );
              },
            ),

          // Main microphone button
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: widget.isListening
                    ? [Colors.red.shade400, Colors.red.shade600]
                    : [Colors.blue.shade400, Colors.blue.shade600],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.isListening
                      ? Colors.red.withValues(alpha: 0.4)
                      : Colors.blue.withValues(alpha: 0.4),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(
              widget.isListening ? Icons.mic : Icons.mic_none,
              color: Colors.white,
              size: 28,
            ),
          ),

          // Listening text below
          if (widget.isListening)
            Positioned(
              bottom: -25,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Opacity(
                    opacity: 0.7 + (0.3 * _controller.value),
                    child: Text(
                      'Listening...',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

/// Compact voice indicator for use in input fields
class CompactVoiceIndicator extends StatelessWidget {
  final bool isListening;
  final VoidCallback? onTap;

  const CompactVoiceIndicator({
    super.key,
    required this.isListening,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(
        isListening ? Icons.mic : Icons.mic_none,
        color: isListening ? Colors.red : Colors.blue,
      ),
      tooltip: isListening ? 'Stop listening' : 'Start voice input',
    );
  }
}
