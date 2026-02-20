import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:travid/services/firestore_chat_service.dart';

/// Local chat storage service using Hive
/// Replaces Firestore for offline-first, billing-free chat history
class HiveChatService {
  static const String _boxName = 'chatSessions';
  Box<Map>? _chatBox;

  /// Initialize Hive box
  Future<void> init() async {
    _chatBox = await Hive.openBox<Map>(_boxName);
  }

  /// Save chat session locally
  Future<void> saveSession(ChatSession session) async {
    if (_chatBox == null) await init();
    await _chatBox!.put(session.id, session.toJson());
    debugPrint('✅ Chat session saved locally: ${session.topic}');
  }

  /// Update existing session
  Future<void> updateSession(ChatSession session) async {
    await saveSession(session); // Same as save for Hive
  }

  /// Get all chat sessions
  Future<List<ChatSession>> getHistory() async {
    if (_chatBox == null) await init();
    
    try {
      final sessions = _chatBox!.values
          .map((json) => ChatSession.fromJson(Map<String, dynamic>.from(json)))
          .toList();
      
      // Sort by creation date (newest first)
      sessions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      return sessions;
    } catch (e) {
      debugPrint('❌ Error loading chat history: $e');
      return [];
    }
  }

  /// Get a specific session
  Future<ChatSession?> getSession(String sessionId) async {
    if (_chatBox == null) await init();
    
    try {
      final json = _chatBox!.get(sessionId);
      if (json == null) return null;
      return ChatSession.fromJson(Map<String, dynamic>.from(json));
    } catch (e) {
      debugPrint('❌ Error loading session: $e');
      return null;
    }
  }

  /// Delete a session
  Future<void> deleteSession(String sessionId) async {
    if (_chatBox == null) await init();
    
    try {
      await _chatBox!.delete(sessionId);
      debugPrint('✅ Session deleted: $sessionId');
    } catch (e) {
      debugPrint('❌ Error deleting session: $e');
    }
  }

  /// Clear all chat history
  Future<void> clearHistory() async {
    if (_chatBox == null) await init();
    
    try {
      await _chatBox!.clear();
      debugPrint('✅ All chat history cleared');
    } catch (e) {
      debugPrint('❌ Error clearing history: $e');
    }
  }

  /// Stream of chat sessions (for real-time updates)
  /// Note: Hive doesn't have native streams, so we'll use a simple polling approach
  /// For real-time updates, you can use ValueListenableBuilder with box.listenable()
  Stream<List<ChatSession>> watchHistory() async* {
    if (_chatBox == null) await init();
    
    // Initial data
    yield await getHistory();
    
    // Listen for changes
    await for (final _ in _chatBox!.watch()) {
      yield await getHistory();
    }
  }

  /// Log activity (for analytics/debugging)
  /// Note: This is a no-op for Hive since we're storing locally
  /// You can extend this to save to a separate analytics box if needed
  Future<void> logActivity({
    required String action,
    Map<String, dynamic>? data,
  }) async {
    // For local storage, we can just print for debugging
    debugPrint('📊 Activity: $action ${data != null ? "- $data" : ""}');
    
    // Optional: Save to a separate analytics box
    // final analyticsBox = await Hive.openBox('analytics');
    // await analyticsBox.add({
    //   'action': action,
    //   'data': data,
    //   'timestamp': DateTime.now().toIso8601String(),
    // });
  }
}
