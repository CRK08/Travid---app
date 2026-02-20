import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:travid/features/chat/widgets/gradient_bubble.dart';
import 'package:travid/features/chat/widgets/chat_input_bar.dart';
import 'package:travid/services/global_ai_service.dart';
import 'package:travid/services/hive_chat_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travid/core/providers.dart';
import 'package:travid/core/app_translations.dart';
import 'package:travid/services/firestore_chat_service.dart'; // Keep for ChatMessage/ChatSession models

class ChatPage extends ConsumerStatefulWidget {
  const ChatPage({super.key});

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GlobalAIService _aiService = GlobalAIService();
  final HiveChatService _chatService = HiveChatService();
  
  // Local state for current conversation
  List<ChatMessage> _messages = [];
  bool _isLoading = false;
  bool _isListening = false;
  
  // History stream
  late Stream<List<ChatSession>> _historyStream;

  @override
  void initState() {
    super.initState();
    _initChatService();
    _historyStream = _chatService.watchHistory();
    // Start with a greeting if empty
    final lang = ref.read(settingsProvider).language;
    _messages.add(ChatMessage(
      text: AppTranslations.get('greeting_message', lang), 
      role: 'ai', 
      timestamp: DateTime.now()
    ));
    
    // Listen for AI service changes (e.g. listening state)
    _aiService.addListener(_onAIStateChange);
  }
  
  Future<void> _initChatService() async {
    await _chatService.init();
  }
  
  @override
  void dispose() {
    // Stop AI speaking and listening when leaving chat page
    _aiService.stopSpeaking();
    _aiService.stopListening();
    
    _aiService.removeListener(_onAIStateChange);
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
  
  void _onAIStateChange() {
    if (mounted) {
      setState(() {
        _isListening = _aiService.isListening;
        // If AI is processing, we can show loading if we want, but we handle it via _handleSubmitted too
      });
    }
  }

  void _addMessage(String text, String role) {
    if (!mounted) return;
    setState(() {
      _messages.add(ChatMessage(text: text, role: role, timestamp: DateTime.now()));
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleSubmitted(String text) async {
    if (text.trim().isEmpty) return;
    _textController.clear();
    _addMessage(text, 'user');

    setState(() => _isLoading = true);

    try {
      // Call GlobalAIService to process text
      // It handles calling AI, saving to Firestore, and speaking response
      final response = await _aiService.processTextQuery(text);
      
      _addMessage(response, 'ai');
    } catch (e) {
      _addMessage("Sorry, I encountered an error: $e", 'ai');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _listen() {
    if (_isListening) {
      _aiService.stopListening();
    } else {
      // Start listening (continuous mode or wake word mode handled by service)
      _aiService.startListeningSession();
    }
  }

  void _startNewChat() {
    setState(() {
      _messages.clear();
      final lang = ref.read(settingsProvider).language;
      _messages.add(ChatMessage(
        text: AppTranslations.get('greeting_message', lang), 
        role: 'ai', 
        timestamp: DateTime.now()
      ));
      _aiService.startNewSession(); 
    });
  }

  void _loadSession(ChatSession session) {
    setState(() {
      _messages = List.from(session.messages);
      // Ensure messages are sorted by timestamp if needed (usually saved in order)
    });
    Navigator.pop(context);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    String t(String key) => AppTranslations.get(key, settings.language);

    return Scaffold(
      appBar: AppBar(
        title: Text(t('chat_title')),
        centerTitle: true,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Theme.of(context).primaryColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_comment_outlined),
            onPressed: _startNewChat,
            tooltip: t('new_chat'),
          ),
        ],
      ),
      drawer: _buildDrawer(t),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isUser = message.role == 'user';
                return GradientBubble(
                  message: message.text, 
                  isUser: isUser,
                  time: DateFormat('h:mm a').format(message.timestamp),
                );
              },
            ),
          ),
          if (_isLoading || _aiService.isProcessing)
             Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: LinearProgressIndicator(
                minHeight: 2, 
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
              ),
            ),
          ChatInputBar(
            controller: _textController,
            onVoicePressed: _listen,
            onSendPressed: () => _handleSubmitted(_textController.text),
            isListening: _isListening,
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(String Function(String) t) {
     return Drawer(
      child: Column(
        children: [
          // Simplified Header (No gradient)
          Container(
            height: 140,
            color: Theme.of(context).scaffoldBackgroundColor,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history, 
                    color: Theme.of(context).primaryColor, 
                    size: 48
                  ),
                  const SizedBox(height: 12),
                  Text(
                    t('chat_history'),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: StreamBuilder<List<ChatSession>>(
              stream: _historyStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.error_outline, size: 40, color: Theme.of(context).colorScheme.error),
                          const SizedBox(height: 12),
                          Text(
                            "Could not load history",
                            style: Theme.of(context).textTheme.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                          TextButton(
                            onPressed: () {
                               setState(() {
                                 _historyStream = _chatService.watchHistory();
                               });
                            }, 
                            child: const Text("Retry")
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                final history = snapshot.data ?? [];
                
                if (history.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.chat_bubble_outline, size: 48, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text(
                          t('no_history'),
                          style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          t('start_conversation'),
                          style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                        ),
                      ],
                    ),
                  );
                }
                
                return ListView.builder(
                  itemCount: history.length,
                  itemBuilder: (context, index) {
                    final session = history[index];
                    return ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, 
                        vertical: 4
                      ),
                      leading: Icon(
                        Icons.chat_bubble_outline,
                        size: 20,
                        color: Theme.of(context).primaryColor,
                      ),
                      title: Text(
                        session.topic,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        DateFormat('MMM d, h:mm a').format(session.createdAt),
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                      onTap: () => _loadSession(session),
                      trailing: IconButton(
                        icon: Icon(
                          Icons.delete_outline, 
                          size: 18,
                          color: Colors.grey.shade600,
                        ),
                        onPressed: () {
                           // Option to delete session
                           _chatService.deleteSession(session.id);
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.delete_sweep),
            title: Text(t('clear_history')),
            onTap: () {
              // Confirm dialog
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text(t('clear_history_confirm')),
                  content: Text(t('action_undone')),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: Text(t('cancel'))),
                    TextButton(
                      onPressed: () {
                        _chatService.clearHistory();
                        Navigator.pop(ctx);
                      }, 
                      child: Text(t('clear'), style: const TextStyle(color: Colors.red))
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
