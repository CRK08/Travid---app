import 'package:flutter/material.dart';

class ChatInputBar extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onVoicePressed;
  final VoidCallback onSendPressed;
  final bool isListening;

  const ChatInputBar({
    super.key,
    required this.controller,
    required this.onVoicePressed,
    required this.onSendPressed,
    required this.isListening,
  });

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_updateState);
  }

  void _updateState() {
    setState(() {
      _hasText = widget.controller.text.trim().isNotEmpty;
    });
  }

  @override
  void dispose() {
    widget.controller.removeListener(_updateState);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      color: theme.scaffoldBackgroundColor,
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Text Input Field - Compact, wide, round
            Expanded(
              child: Container(
                constraints: const BoxConstraints(maxHeight: 44),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: theme.brightness == Brightness.dark
                        ? Colors.grey.shade700
                        : Colors.grey.shade300,
                    width: 1,
                  ),
                ),
                child: TextField(
                  controller: widget.controller,
                  maxLines: 1,
                  textCapitalization: TextCapitalization.sentences,
                  style: const TextStyle(fontSize: 14),
                  decoration: const InputDecoration(
                    hintText: "Type a message...",
                    hintStyle: TextStyle(fontSize: 14),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                    isDense: true,
                  ),
                  onSubmitted: (_) {
                    if (_hasText) widget.onSendPressed();
                  },
                ),
              ),
            ),
            const SizedBox(width: 8),
            
            // Single Dynamic Button (Voice OR Send) - Compact, round
            GestureDetector(
              onTap: _hasText ? widget.onSendPressed : widget.onVoicePressed,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _hasText 
                      ? theme.primaryColor 
                      : (widget.isListening ? Colors.redAccent : theme.colorScheme.secondary),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: (_hasText 
                          ? theme.primaryColor 
                          : (widget.isListening ? Colors.redAccent : theme.colorScheme.secondary)
                      ).withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  _hasText 
                      ? Icons.send_rounded
                      : (widget.isListening ? Icons.mic : Icons.mic_none),
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
