import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';

/// Context entry for tracking queries and responses
class ContextEntry {
  final String query;
  final String response;
  final DateTime timestamp;
  final LatLng? location;

  ContextEntry({
    required this.query,
    required this.response,
    required this.timestamp,
    this.location,
  });

  /// Check if this entry is still relevant (less than 1 hour old)
  bool get isRelevant {
    final age = DateTime.now().difference(timestamp);
    return age.inHours < 1;
  }
}

/// Time of day context
enum TimeOfDay {
  morning,   // 5 AM - 12 PM
  afternoon, // 12 PM - 5 PM
  evening,   // 5 PM - 9 PM
  night,     // 9 PM - 5 AM
}

/// Context Service - Tracks conversation and location context
/// 
/// This service maintains:
/// - Recent conversation history
/// - Current user location
/// - Time-based context
/// - User patterns and preferences
class ContextService {
  // Singleton pattern
  static final ContextService _instance = ContextService._internal();
  factory ContextService() => _instance;
  ContextService._internal();

  // State
  LatLng? _currentLocation;
  String? _currentLocationName;
  final List<ContextEntry> _queryHistory = [];
  final Map<String, int> _queryPatterns = {}; // Track common queries
  
  // Configuration
  static const int _maxHistorySize = 10;
  static const int _maxPatternTracking = 50;

  // Getters
  LatLng? get currentLocation => _currentLocation;
  String? get currentLocationName => _currentLocationName;
  List<ContextEntry> get recentQueries => _queryHistory
      .where((entry) => entry.isRelevant)
      .toList();

  /// Update current location
  void updateLocation(LatLng location, {String? locationName}) {
    _currentLocation = location;
    _currentLocationName = locationName;
  }

  /// Add a query-response pair to history
  void addQuery(String query, String response, {LatLng? location}) {
    final entry = ContextEntry(
      query: query,
      response: response,
      timestamp: DateTime.now(),
      location: location ?? _currentLocation,
    );

    _queryHistory.add(entry);

    // Track query patterns
    final normalizedQuery = query.toLowerCase().trim();
    _queryPatterns[normalizedQuery] = (_queryPatterns[normalizedQuery] ?? 0) + 1;

    // Cleanup old entries
    _cleanupHistory();
    _cleanupPatterns();
  }

  /// Get recent conversation context as a summary
  String getRecentContext() {
    final relevant = recentQueries;
    
    if (relevant.isEmpty) {
      return "No recent conversation history.";
    }

    final buffer = StringBuffer();
    buffer.writeln("Recent conversation:");
    
    for (var i = 0; i < relevant.length && i < 3; i++) {
      final entry = relevant[relevant.length - 1 - i]; // Most recent first
      final timeAgo = _formatTimeAgo(entry.timestamp);
      buffer.writeln("- $timeAgo: User asked \"${entry.query}\"");
    }

    return buffer.toString().trim();
  }

  /// Get location context description
  String getLocationContext() {
    if (_currentLocation == null) {
      return "Location unknown.";
    }

    final buffer = StringBuffer();
    buffer.write("Current location: ");
    
    if (_currentLocationName != null) {
      buffer.write(_currentLocationName);
      buffer.write(" ");
    }
    
    buffer.write("(${_currentLocation!.latitude.toStringAsFixed(4)}, ");
    buffer.write("${_currentLocation!.longitude.toStringAsFixed(4)})");

    return buffer.toString();
  }

  /// Get time-based context
  String getTimeContext() {
    final now = DateTime.now();
    final timeOfDay = _getTimeOfDay(now);
    final dayOfWeek = DateFormat.EEEE().format(now);
    final time = DateFormat.jm().format(now);

    String greeting;
    switch (timeOfDay) {
      case TimeOfDay.morning:
        greeting = "Good morning";
        break;
      case TimeOfDay.afternoon:
        greeting = "Good afternoon";
        break;
      case TimeOfDay.evening:
        greeting = "Good evening";
        break;
      case TimeOfDay.night:
        greeting = "Good night";
        break;
    }

    return "$greeting. It's $time on $dayOfWeek.";
  }

  /// Get time of day enum
  TimeOfDay _getTimeOfDay(DateTime time) {
    final hour = time.hour;
    
    if (hour >= 5 && hour < 12) {
      return TimeOfDay.morning;
    } else if (hour >= 12 && hour < 17) {
      return TimeOfDay.afternoon;
    } else if (hour >= 17 && hour < 21) {
      return TimeOfDay.evening;
    } else {
      return TimeOfDay.night;
    }
  }

  /// Get full context as a map for AI processing
  Map<String, dynamic> getFullContext() {
    return {
      'location': _currentLocation != null
          ? {
              'lat': _currentLocation!.latitude,
              'lng': _currentLocation!.longitude,
              'name': _currentLocationName,
            }
          : null,
      'recentQueries': recentQueries.map((e) => {
            'query': e.query,
            'response': e.response,
            'timestamp': e.timestamp.toIso8601String(),
          }).toList(),
      'timeOfDay': _getTimeOfDay(DateTime.now()).toString(),
      'currentTime': DateTime.now().toIso8601String(),
      'commonPatterns': _getTopPatterns(3),
    };
  }

  /// Get top N query patterns
  List<String> _getTopPatterns(int n) {
    final sorted = _queryPatterns.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sorted.take(n).map((e) => e.key).toList();
  }

  /// Check if a query is similar to recent queries
  bool hasSimilarRecentQuery(String query) {
    final normalized = query.toLowerCase().trim();
    
    return recentQueries.any((entry) {
      final entryQuery = entry.query.toLowerCase().trim();
      return _calculateSimilarity(normalized, entryQuery) > 0.5;
    });
  }

  /// Simple similarity calculation (Jaccard similarity on words)
  double _calculateSimilarity(String a, String b) {
    final wordsA = a.split(' ').where((w) => w.isNotEmpty).toSet();
    final wordsB = b.split(' ').where((w) => w.isNotEmpty).toSet();
    
    final intersection = wordsA.intersection(wordsB).length;
    final union = wordsA.union(wordsB).length;
    
    return union > 0 ? intersection / union : 0.0;
  }

  /// Format time ago in human-readable format
  String _formatTimeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    
    if (diff.inMinutes < 1) {
      return "just now";
    } else if (diff.inMinutes < 60) {
      return "${diff.inMinutes}m ago";
    } else if (diff.inHours < 24) {
      return "${diff.inHours}h ago";
    } else {
      return "${diff.inDays}d ago";
    }
  }

  /// Cleanup old history entries
  void _cleanupHistory() {
    // Remove entries older than 1 hour
    _queryHistory.removeWhere((entry) => !entry.isRelevant);
    
    // Keep only last N entries
    if (_queryHistory.length > _maxHistorySize) {
      _queryHistory.removeRange(0, _queryHistory.length - _maxHistorySize);
    }
  }

  /// Cleanup pattern tracking
  void _cleanupPatterns() {
    if (_queryPatterns.length > _maxPatternTracking) {
      // Remove least common patterns
      final sorted = _queryPatterns.entries.toList()
        ..sort((a, b) => a.value.compareTo(b.value));
      
      final toRemove = sorted.take(_queryPatterns.length - _maxPatternTracking);
      for (final entry in toRemove) {
        _queryPatterns.remove(entry.key);
      }
    }
  }

  /// Clear all context (useful for testing or privacy)
  void clearContext() {
    _queryHistory.clear();
    _queryPatterns.clear();
    _currentLocation = null;
    _currentLocationName = null;
  }

  /// Get context summary for debugging
  String getDebugSummary() {
    return '''
Context Service Summary:
- Location: ${_currentLocation != null ? 'Set' : 'Not set'}
- Query History: ${_queryHistory.length} entries (${recentQueries.length} relevant)
- Tracked Patterns: ${_queryPatterns.length}
- Top Patterns: ${_getTopPatterns(3).join(', ')}
''';
  }
}
