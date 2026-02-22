import 'package:google_generative_ai/google_generative_ai.dart';

/// AI Service using Google Gemini for natural language understanding
class AIService {
  // ⚠️ REPLACE THIS KEY: Create new key at https://aistudio.google.com/app/apikey
  // IMPORTANT: Select "Create API key in new project" when creating
  static const String _apiKey = const String.fromEnvironment('GEMINI_API_KEY', defaultValue: 'YOUR_GEMINI_API_KEY_HERE');
  late final GenerativeModel _model;
  
  // Singleton pattern
  static final AIService _instance = AIService._internal();
  factory AIService() => _instance;
  
  AIService._internal() {
    _model = GenerativeModel(
      model: 'models/gemini-2.5-flash', // ✅ Confirmed available via API test
      apiKey: _apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.7,
        topK: 40,
        topP: 0.95,
        maxOutputTokens: 1024,
      ),
    );
  }

  /// Process user query with context about bus routes
  Future<AIResponse> processQuery({
    required String userQuery,
    required String currentLocation,
    required List<String> nearbyStops,
    required Map<String, List<String>> stopRoutes,
  }) async {
    try {
      // Build context for AI
      final context = _buildContext(
        currentLocation: currentLocation,
        nearbyStops: nearbyStops,
        stopRoutes: stopRoutes,
      );

      // Create prompt
      final prompt = '''
You are a helpful bus navigation assistant for blind users in Coimbatore, India.

CONTEXT:
$context

USER QUERY: "$userQuery"

INSTRUCTIONS:
1. Understand the user's intent (route planning, bus info, recommendations, etc.)
2. Provide clear, concise, voice-friendly response
3. Include specific bus numbers and stop names
4. Give step-by-step directions if asking for route
5. Be helpful and accessible
6. Keep response under 100 words
7. Use simple language

RESPONSE FORMAT:
{
  "intent": "route_planning|bus_info|recommendation|general_query",
  "action": "plan_route|find_stop|list_routes|provide_info",
  "destination": "stop name if route planning, else null",
  "response": "voice-friendly response text",
  "confidence": 0.0-1.0
}

Respond ONLY with valid JSON.
''';

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      
      if (response.text == null) {
        return AIResponse.error('No response from AI');
      }

      // Parse JSON response
      return AIResponse.fromJson(response.text!);
    } on GenerativeAIException catch (e) {
      print('❌ AI API Error: ${e.message}');
      return AIResponse.error('AI Error: ${e.message}');
    } catch (e) {
      print('❌ AI Error: $e');
      return AIResponse.error('Could not process query: $e');
    }
  }

  /// Build context string for AI
  String _buildContext({
    required String currentLocation,
    required List<String> nearbyStops,
    required Map<String, List<String>> stopRoutes,
  }) {
    final buffer = StringBuffer();
    
    buffer.writeln('Current Location: $currentLocation');
    buffer.writeln('\nNearby Bus Stops:');
    
    for (var i = 0; i < nearbyStops.length && i < 5; i++) {
      final stop = nearbyStops[i];
      final routes = stopRoutes[stop] ?? [];
      buffer.writeln('- $stop (Routes: ${routes.take(5).join(", ")})');
    }
    
    return buffer.toString();
  }

  /// Get recommendations based on user preferences
  Future<String> getRecommendations({
    required String from,
    required String to,
    required List<String> availableRoutes,
  }) async {
    try {
      final prompt = '''
As a bus navigation expert, recommend the best route from "$from" to "$to".

Available routes: ${availableRoutes.join(", ")}

Consider:
1. Fewest transfers
2. Shortest route
3. Most frequent buses

Provide a brief recommendation (max 50 words) in simple language for voice output.
''';

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      
      return response.text ?? 'No recommendation available';
    } on GenerativeAIException catch (e) {
      print('❌ AI API Error: ${e.message}');
      return 'AI Error: ${e.message}';
    } catch (e) {
      print('❌ Error: $e');
      return 'Could not generate recommendation: $e';
    }
  }

  /// Answer general questions about buses
  Future<String> answerQuestion(String question) async {
    try {
      final prompt = '''
You are a bus navigation assistant for Coimbatore, India.

User question: "$question"

Provide a helpful, concise answer (max 50 words) suitable for voice output.
If you don't know, say so clearly.
''';

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      
      return response.text ?? 'I could not answer that question';
    } on GenerativeAIException catch (e) {
      print('❌ AI API Error: ${e.message}');
      return 'AI Error: ${e.message}. Please check your API key and ensure the Generative Language API is enabled.';
    } catch (e) {
      print('❌ Error: $e');
      return 'Could not process question: $e';
    }
  }

  /// Process query with full context (location, history, time)
  Future<String> processQueryWithContext(
    String query,
    Map<String, dynamic> context,
  ) async {
    try {
      // Build context string
      final contextStr = _buildFullContext(context);

      final prompt = '''
You are Travid, an intelligent voice assistant for blind users in Coimbatore, India.
You help with navigation, bus routes, time, and general questions.

CONTEXT:
$contextStr

USER QUERY: "$query"

INSTRUCTIONS:
1. Use the context to provide relevant, personalized responses
2. Reference recent conversation if relevant (e.g., "As I mentioned earlier...")
3. Use location context when answering navigation questions
4. Be concise and voice-friendly (max 75 words)
5. Use simple, clear language
6. If the query relates to previous conversation, acknowledge it

Provide ONLY the response text, no JSON or formatting.
''';

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      
      return response.text ?? 'I could not process that request';
    } on GenerativeAIException catch (e) {
      print('❌ AI API Error: ${e.message}');
      return 'I\'m having trouble connecting. Please try again.';
    } catch (e) {
      print('❌ Error: $e');
      return 'I encountered an error. Please try again.';
    }
  }

  /// Build full context string from context map
  String _buildFullContext(Map<String, dynamic> context) {
    final buffer = StringBuffer();

    // Time context
    if (context['timeOfDay'] != null) {
      buffer.writeln('Time: ${context['timeOfDay']}');
    }

    // Location context
    if (context['location'] != null) {
      final loc = context['location'];
      buffer.write('Current Location: ');
      if (loc['name'] != null) {
        buffer.write(loc['name']);
      } else {
        buffer.write('${loc['lat']}, ${loc['lng']}');
      }
      buffer.writeln();
    }

    // Recent queries
    if (context['recentQueries'] != null && 
        (context['recentQueries'] as List).isNotEmpty) {
      buffer.writeln('\nRecent Conversation:');
      final queries = context['recentQueries'] as List;
      for (var i = 0; i < queries.length && i < 3; i++) {
        final q = queries[queries.length - 1 - i];
        buffer.writeln('- User: "${q['query']}"');
      }
    }

    // Common patterns
    if (context['commonPatterns'] != null &&
        (context['commonPatterns'] as List).isNotEmpty) {
      final patterns = context['commonPatterns'] as List<String>;
      buffer.writeln('\nUser often asks about: ${patterns.join(", ")}');
    }

    return buffer.toString();
  }

  /// Detect multiple intents in a query
  Future<List<String>> detectIntents(String query) async {
    try {
      final prompt = '''
Analyze this user query and identify ALL intents present.

Query: "$query"

Possible intents:
- time_query (asking for time)
- date_query (asking for date)
- location_query (where am I)
- navigation (directions, routes)
- bus_info (bus routes, stops)
- poi_search (nearby places)
- general_question (other questions)

Respond with ONLY a comma-separated list of detected intents.
Example: "time_query,navigation" or "location_query"
''';

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      
      if (response.text == null || response.text!.isEmpty) {
        return ['general_question'];
      }

      // Parse comma-separated intents
      return response.text!
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    } catch (e) {
      print('❌ Intent detection error: $e');
      return ['general_question'];
    }
  }

  /// Generate proactive suggestions based on context
  Future<String?> generateProactiveSuggestion(
    Map<String, dynamic> context,
  ) async {
    try {
      final contextStr = _buildFullContext(context);

      final prompt = '''
You are Travid, a proactive voice assistant.

CONTEXT:
$contextStr

Based on the context, should you make a helpful suggestion to the user?

Guidelines:
- Only suggest if truly helpful (don't be annoying)
- Consider time of day (morning commute, evening return)
- Consider location (near bus stops, familiar places)
- Consider patterns (frequently asked questions)
- Keep suggestion brief (max 30 words)

If you have a helpful suggestion, provide it.
If not, respond with exactly: "NO_SUGGESTION"

Provide ONLY the suggestion text or "NO_SUGGESTION".
''';

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      
      if (response.text == null || 
          response.text!.trim() == 'NO_SUGGESTION' ||
          response.text!.isEmpty) {
        return null;
      }

      return response.text!.trim();
    } catch (e) {
      print('❌ Suggestion generation error: $e');
      return null;
    }
  }
}

/// AI Response model
class AIResponse {
  final String intent;
  final String action;
  final String? destination;
  final String response;
  final double confidence;
  final bool isError;

  AIResponse({
    required this.intent,
    required this.action,
    this.destination,
    required this.response,
    required this.confidence,
    this.isError = false,
  });

  factory AIResponse.fromJson(String jsonString) {
    try {
      // Remove markdown code blocks if present
      String cleaned = jsonString
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();
      
      // Parse JSON
      final Map<String, dynamic> json = {};
      
      // Simple JSON parsing (you can use dart:convert for production)
      final intentMatch = RegExp(r'"intent":\s*"([^"]+)"').firstMatch(cleaned);
      final actionMatch = RegExp(r'"action":\s*"([^"]+)"').firstMatch(cleaned);
      final destMatch = RegExp(r'"destination":\s*"([^"]+)"').firstMatch(cleaned);
      final responseMatch = RegExp(r'"response":\s*"([^"]+)"').firstMatch(cleaned);
      final confMatch = RegExp(r'"confidence":\s*([0-9.]+)').firstMatch(cleaned);
      
      return AIResponse(
        intent: intentMatch?.group(1) ?? 'general_query',
        action: actionMatch?.group(1) ?? 'provide_info',
        destination: destMatch?.group(1),
        response: responseMatch?.group(1) ?? 'I can help you with bus navigation',
        confidence: double.tryParse(confMatch?.group(1) ?? '0.5') ?? 0.5,
      );
    } catch (e) {
      return AIResponse.error('Failed to parse AI response');
    }
  }

  factory AIResponse.error(String message) {
    return AIResponse(
      intent: 'error',
      action: 'none',
      response: message,
      confidence: 0.0,
      isError: true,
    );
  }

  bool get shouldPlanRoute => action == 'plan_route' && destination != null;
  bool get shouldFindStop => action == 'find_stop';
  bool get shouldListRoutes => action == 'list_routes';
}
