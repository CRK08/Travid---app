import 'package:flutter/material.dart';

class GradientBubble extends StatelessWidget {
  final String message;
  final bool isUser;
  final String? time;

  const GradientBubble({
    super.key,
    required this.message,
    required this.isUser,
    this.time,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final radius = const Radius.circular(20);

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: isUser
                ? LinearGradient(
                    colors: [
                      theme.primaryColor,
                      theme.colorScheme.secondary,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isUser ? null : theme.cardColor,
            borderRadius: BorderRadius.only(
              topLeft: radius,
              topRight: radius,
              bottomLeft: isUser ? radius : Radius.zero,
              bottomRight: isUser ? Radius.zero : radius,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isUser ? Colors.white : theme.textTheme.bodyMedium?.color,
                ),
              ),
              if (time != null) ...[
                const SizedBox(height: 4),
                Text(
                  time!,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: isUser ? Colors.white70 : Colors.grey,
                    fontSize: 10,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
