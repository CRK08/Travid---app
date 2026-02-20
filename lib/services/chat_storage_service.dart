import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Service to manage chat history and storage
class ChatStorageService {
  static const String _historyKey = 'chat_history';
  
  // Singleton
  static final ChatStorageService _instance = ChatStorageService._internal();
  factory ChatStorageService() => _instance;
  ChatStorageService._internal();

  /// Save a new chat session to history
  Future<void> saveSession(ChatSession session) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Get existing history
    final history = await getHistory();
    
    // Add new session to top
    history.insert(0, session);
    
    // Save back
    final List<String> jsonList = history.map((s) => jsonEncode(s.toJson())).toList();
    await prefs.setStringList(_historyKey, jsonList);
  }

  /// Get entire chat history
  Future<List<ChatSession>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? jsonList = prefs.getStringList(_historyKey);
    
    if (jsonList == null) return [];
    
    try {
      return jsonList
          .map((s) => ChatSession.fromJson(jsonDecode(s)))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Update an existing session (e.g., adding messages)
  Future<void> updateSession(ChatSession updatedSession) async {
    final prefs = await SharedPreferences.getInstance();
    final history = await getHistory();
    
    final index = history.indexWhere((s) => s.id == updatedSession.id);
    if (index != -1) {
      history[index] = updatedSession;
      
      // Save back
      final List<String> jsonList = history.map((s) => jsonEncode(s.toJson())).toList();
      await prefs.setStringList(_historyKey, jsonList);
    } else {
      // If not found, save as new
      await saveSession(updatedSession);
    }
  }

  /// Clear all history
  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
  }
}

/// Model for a chat session
class ChatSession {
  final String id;
  final DateTime createdAt;
  final String topic; // Summary/Draft of what user asked
  final List<ChatMessage> messages;

  ChatSession({
    required this.id,
    required this.createdAt,
    required this.topic,
    required this.messages,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'createdAt': createdAt.toIso8601String(),
    'topic': topic,
    'messages': messages.map((m) => m.toJson()).toList(),
  };

  factory ChatSession.fromJson(Map<String, dynamic> json) {
    return ChatSession(
      id: json['id'],
      createdAt: DateTime.parse(json['createdAt']),
      topic: json['topic'],
      messages: (json['messages'] as List)
          .map((m) => ChatMessage.fromJson(m))
          .toList(),
    );
  }
}

/// Model for a single message
class ChatMessage {
  final String role; // 'user' or 'ai'
  final String text;
  final DateTime timestamp;

  ChatMessage({
    required this.role,
    required this.text,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'role': role,
    'text': text,
    'timestamp': timestamp.toIso8601String(),
  };

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      role: json['role'],
      text: json['text'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}
