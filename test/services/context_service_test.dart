import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:travid/services/context_service.dart';

void main() {
  group('ContextService', () {
    late ContextService contextService;

    setUp(() {
      contextService = ContextService();
      contextService.clearContext(); // Start fresh for each test
    });

    tearDown(() {
      contextService.clearContext();
    });

    group('Location Context', () {
      test('should update and retrieve current location', () {
        final location = LatLng(11.0168, 76.9558); // Coimbatore
        contextService.updateLocation(location, locationName: 'Coimbatore');

        expect(contextService.currentLocation, equals(location));
        expect(contextService.currentLocationName, equals('Coimbatore'));
      });

      test('should format location context correctly', () {
        final location = LatLng(11.0168, 76.9558);
        contextService.updateLocation(location, locationName: 'Coimbatore');

        final context = contextService.getLocationContext();
        expect(context, contains('Coimbatore'));
        expect(context, contains('11.0168'));
        expect(context, contains('76.9558'));
      });

      test('should handle missing location', () {
        final context = contextService.getLocationContext();
        expect(context, equals('Location unknown.'));
      });
    });

    group('Query History', () {
      test('should add query to history', () {
        contextService.addQuery('What time is it?', 'It is 2:30 PM');

        final recent = contextService.recentQueries;
        expect(recent.length, equals(1));
        expect(recent[0].query, equals('What time is it?'));
        expect(recent[0].response, equals('It is 2:30 PM'));
      });

      test('should track multiple queries', () {
        contextService.addQuery('Where am I?', 'You are in Coimbatore');
        contextService.addQuery('What time is it?', 'It is 2:30 PM');
        contextService.addQuery('Find bus to Chennai', 'Route 123 available');

        final recent = contextService.recentQueries;
        expect(recent.length, equals(3));
      });

      test('should limit history size', () {
        // Add more than max history size
        for (int i = 0; i < 15; i++) {
          contextService.addQuery('Query $i', 'Response $i');
        }

        final recent = contextService.recentQueries;
        expect(recent.length, lessThanOrEqualTo(10));
      });

      test('should include location in query entry', () {
        final location = LatLng(11.0168, 76.9558);
        contextService.updateLocation(location);
        contextService.addQuery('Where am I?', 'You are in Coimbatore');

        final recent = contextService.recentQueries;
        expect(recent[0].location, equals(location));
      });
    });

    group('Recent Context Summary', () {
      test('should generate context summary', () {
        contextService.addQuery('What time is it?', 'It is 2:30 PM');
        contextService.addQuery('Where am I?', 'You are in Coimbatore');

        final summary = contextService.getRecentContext();
        expect(summary, contains('Recent conversation'));
        expect(summary, contains('What time is it?'));
        expect(summary, contains('Where am I?'));
      });

      test('should handle empty history', () {
        final summary = contextService.getRecentContext();
        expect(summary, equals('No recent conversation history.'));
      });

      test('should limit summary to 3 most recent queries', () {
        for (int i = 0; i < 5; i++) {
          contextService.addQuery('Query $i', 'Response $i');
        }

        final summary = contextService.getRecentContext();
        // Should contain most recent 3
        expect(summary, contains('Query 4'));
        expect(summary, contains('Query 3'));
        expect(summary, contains('Query 2'));
        // Should not contain older ones
        expect(summary, isNot(contains('Query 0')));
        expect(summary, isNot(contains('Query 1')));
      });
    });

    group('Time Context', () {
      test('should generate time context', () {
        final context = contextService.getTimeContext();
        expect(context, contains('Good'));
        expect(context, isNot(isEmpty));
      });
    });

    group('Full Context', () {
      test('should generate full context map', () {
        final location = LatLng(11.0168, 76.9558);
        contextService.updateLocation(location, locationName: 'Coimbatore');
        contextService.addQuery('What time is it?', 'It is 2:30 PM');

        final fullContext = contextService.getFullContext();

        expect(fullContext['location'], isNotNull);
        expect(fullContext['location']['lat'], equals(11.0168));
        expect(fullContext['location']['lng'], equals(76.9558));
        expect(fullContext['location']['name'], equals('Coimbatore'));
        expect(fullContext['recentQueries'], isNotEmpty);
        expect(fullContext['timeOfDay'], isNotNull);
        expect(fullContext['currentTime'], isNotNull);
      });

      test('should handle missing location in full context', () {
        contextService.addQuery('What time is it?', 'It is 2:30 PM');

        final fullContext = contextService.getFullContext();
        expect(fullContext['location'], isNull);
        expect(fullContext['recentQueries'], isNotEmpty);
      });
    });

    group('Query Patterns', () {
      test('should track query patterns', () {
        contextService.addQuery('what time is it', 'It is 2:30 PM');
        contextService.addQuery('what time is it', 'It is 3:00 PM');
        contextService.addQuery('where am i', 'You are in Coimbatore');

        final fullContext = contextService.getFullContext();
        final patterns = fullContext['commonPatterns'] as List<String>;

        expect(patterns, contains('what time is it'));
      });

      test('should detect similar queries', () {
        contextService.addQuery('What is the time', 'It is 2:30 PM');

        final similar1 = contextService.hasSimilarRecentQuery('What time is it');
        final similar2 = contextService.hasSimilarRecentQuery('Find bus to Chennai');

        expect(similar1, isTrue);
        expect(similar2, isFalse);
      });
    });

    group('Context Cleanup', () {
      test('should clear all context', () {
        final location = LatLng(11.0168, 76.9558);
        contextService.updateLocation(location, locationName: 'Coimbatore');
        contextService.addQuery('What time is it?', 'It is 2:30 PM');

        contextService.clearContext();

        expect(contextService.currentLocation, isNull);
        expect(contextService.currentLocationName, isNull);
        expect(contextService.recentQueries, isEmpty);
      });
    });

    group('Debug Summary', () {
      test('should generate debug summary', () {
        contextService.addQuery('What time is it?', 'It is 2:30 PM');

        final summary = contextService.getDebugSummary();
        expect(summary, contains('Context Service Summary'));
        expect(summary, contains('Query History'));
      });
    });
  });
}
