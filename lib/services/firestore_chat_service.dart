import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Model for chat messages
class ChatMessage {
  final String role; // 'user' or 'ai'
  final String text;
  final DateTime timestamp;
  final String? audioUrl; // For voice messages

  ChatMessage({
    required this.role,
    required this.text,
    required this.timestamp,
    this.audioUrl,
  });

  Map<String, dynamic> toJson() => {
        'role': role,
        'text': text,
        'timestamp': timestamp.toIso8601String(),
        'audioUrl': audioUrl,
      };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        role: json['role'],
        text: json['text'],
        timestamp: DateTime.parse(json['timestamp']),
        audioUrl: json['audioUrl'],
      );
}

/// Model for chat sessions
class ChatSession {
  final String id;
  final DateTime createdAt;
  final String topic;
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

  factory ChatSession.fromJson(Map<String, dynamic> json) => ChatSession(
        id: json['id'],
        createdAt: DateTime.parse(json['createdAt']),
        topic: json['topic'],
        messages: (json['messages'] as List)
            .map((m) => ChatMessage.fromJson(m))
            .toList(),
      );
}

/// Firestore-based chat storage service
/// Syncs chat history across devices for the same user
class FirestoreChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get current user's chat collection reference
  CollectionReference? _getUserChatsCollection() {
    final user = _auth.currentUser;
    if (user == null) return null;
    return _firestore.collection('users').doc(user.uid).collection('chats');
  }

  /// Save or update a chat session
  Future<void> saveSession(ChatSession session) async {
    final collection = _getUserChatsCollection();
    if (collection == null) {
      debugPrint('⚠️ No user logged in, cannot save chat');
      return;
    }

    try {
      await collection.doc(session.id).set(session.toJson());
      debugPrint('✅ Chat session saved: ${session.topic}');
    } catch (e) {
      debugPrint('❌ Error saving chat: $e');
    }
  }

  /// Update existing session
  Future<void> updateSession(ChatSession session) async {
    await saveSession(session); // Same as save for Firestore
  }

  /// Get all chat sessions for current user
  Future<List<ChatSession>> getHistory() async {
    final collection = _getUserChatsCollection();
    if (collection == null) return [];

    try {
      final snapshot = await collection
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

      return snapshot.docs
          .map((doc) => ChatSession.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('❌ Error loading chat history: $e');
      return [];
    }
  }

  /// Get a specific session
  Future<ChatSession?> getSession(String sessionId) async {
    final collection = _getUserChatsCollection();
    if (collection == null) return null;

    try {
      final doc = await collection.doc(sessionId).get();
      if (!doc.exists) return null;
      return ChatSession.fromJson(doc.data() as Map<String, dynamic>);
    } catch (e) {
      debugPrint('❌ Error loading session: $e');
      return null;
    }
  }

  /// Delete a session
  Future<void> deleteSession(String sessionId) async {
    final collection = _getUserChatsCollection();
    if (collection == null) return;

    try {
      await collection.doc(sessionId).delete();
      debugPrint('✅ Session deleted: $sessionId');
    } catch (e) {
      debugPrint('❌ Error deleting session: $e');
    }
  }

  /// Clear all chat history
  Future<void> clearHistory() async {
    final collection = _getUserChatsCollection();
    if (collection == null) return;

    try {
      final snapshot = await collection.get();
      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }
      debugPrint('✅ All chat history cleared');
    } catch (e) {
      debugPrint('❌ Error clearing history: $e');
    }
  }

  /// Stream of chat sessions (real-time updates)
  Stream<List<ChatSession>> watchHistory() {
    final collection = _getUserChatsCollection();
    if (collection == null) return Stream.value([]);

    return collection
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatSession.fromJson(doc.data() as Map<String, dynamic>))
            .toList());
  }

  /// Save activity log (for monitoring)
  Future<void> logActivity({
    required String action,
    required Map<String, dynamic> data,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('activity')
          .add({
        'action': action,
        'data': data,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('❌ Error logging activity: $e');
    }
  }
}
