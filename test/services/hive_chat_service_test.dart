import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:travid/services/firestore_chat_service.dart'; // ChatSession model
import 'package:travid/services/hive_chat_service.dart';

void main() {
  group('HiveChatService Tests', () {
    late Directory tempDir;
    late HiveChatService chatService;

    setUp(() async {
      // Create a temporary directory for Hive
      tempDir = await Directory.systemTemp.createTemp();
      Hive.init(tempDir.path);
      
      chatService = HiveChatService();
      await chatService.init();
    });

    tearDown(() async {
      await Hive.deleteFromDisk(); // Cleanup
    });

    test('should start with empty history', () async {
      final history = await chatService.getHistory();
      expect(history, isEmpty);
    });

    test('should save and retrieve a session', () async {
      final session = ChatSession(
        id: 'test_session_1',
        createdAt: DateTime.now(),
        topic: 'Test Topic',
        messages: [],
      );

      await chatService.saveSession(session);
      
      final history = await chatService.getHistory();
      expect(history.length, 1);
      expect(history.first.id, 'test_session_1');
      expect(history.first.topic, 'Test Topic');
    });

    test('should update existing session', () async {
      final session = ChatSession(
        id: 'session_update',
        createdAt: DateTime.now(),
        topic: 'Original Topic',
        messages: [],
      );

      await chatService.saveSession(session);
      
      // Update topic
      final updatedSession = ChatSession(
        id: 'session_update',
        createdAt: session.createdAt,
        topic: 'Updated Topic',
        messages: [],
      );
      
      await chatService.updateSession(updatedSession);
      
      final history = await chatService.getHistory();
      expect(history.length, 1);
      expect(history.first.topic, 'Updated Topic');
    });

    test('should delete a session', () async {
      final session = ChatSession(
        id: 'session_delete',
        createdAt: DateTime.now(),
        topic: 'Delete Me',
        messages: [],
      );

      await chatService.saveSession(session);
      expect((await chatService.getHistory()).length, 1);
      
      await chatService.deleteSession('session_delete');
      expect((await chatService.getHistory()).isEmpty, true);
    });
  });
}
