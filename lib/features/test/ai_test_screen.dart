import 'package:flutter/material.dart';
import '../../services/ai_service.dart';
import 'model_list_screen.dart';

/// Test screen to verify AI integration
class AITestScreen extends StatefulWidget {
  const AITestScreen({super.key});

  @override
  State<AITestScreen> createState() => _AITestScreenState();
}

class _AITestScreenState extends State<AITestScreen> {
  final AIService _aiService = AIService();
  String _response = 'Tap button to test AI...';
  bool _isLoading = false;

  Future<void> _testAI() async {
    setState(() {
      _isLoading = true;
      _response = 'Testing AI...';
    });

    try {
      // Test simple query
      final response = await _aiService.processQuery(
        userQuery: 'How do I get to Gandhipuram?',
        currentLocation: '11.0402, 76.9115',
        nearbyStops: ['Vadavalli', 'Ganapathy', 'PN Pudur'],
        stopRoutes: {
          'Vadavalli': ['1', '1A', '1B', '1F'],
          'Ganapathy': ['2', '3', '3A'],
          'Gandhipuram': ['1', '1A', '2', '3'],
        },
      );

      setState(() {
        _isLoading = false;
        if (response.isError) {
          _response = '❌ Error: ${response.response}';
        } else {
          _response = '''
✅ AI Working!

Intent: ${response.intent}
Action: ${response.action}
Destination: ${response.destination ?? 'N/A'}
Confidence: ${(response.confidence * 100).toStringAsFixed(0)}%

Response:
${response.response}
''';
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _response = '❌ Error: $e';
      });
    }
  }

  Future<void> _testRecommendation() async {
    setState(() {
      _isLoading = true;
      _response = 'Getting recommendation...';
    });

    try {
      final recommendation = await _aiService.getRecommendations(
        from: 'Vadavalli',
        to: 'Gandhipuram',
        availableRoutes: ['1', '1A', '1B', '1F'],
      );

      setState(() {
        _isLoading = false;
        _response = '''
✅ Recommendation:

$recommendation
''';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _response = '❌ Error: $e';
      });
    }
  }

  Future<void> _testQuestion() async {
    setState(() {
      _isLoading = true;
      _response = 'Asking AI...';
    });

    try {
      final answer = await _aiService.answerQuestion(
        'What is the best time to travel by bus in Coimbatore?',
      );

      setState(() {
        _isLoading = false;
        _response = '''
✅ Answer:

$answer
''';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _response = '❌ Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Test'),
        backgroundColor: Colors.blue.shade700,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Test buttons
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _testAI,
              icon: const Icon(Icons.smart_toy),
              label: const Text('Test Route Query'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 12),
            
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _testRecommendation,
              icon: const Icon(Icons.recommend),
              label: const Text('Test Recommendation'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 12),
            
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _testQuestion,
              icon: const Icon(Icons.question_answer),
              label: const Text('Test General Question'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 12),
            
            // Diagnostic button
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ModelListScreen()),
                );
              },
              icon: const Icon(Icons.list),
              label: const Text('🔍 Test Available Models'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
            ),
            
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            
            // Response area
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: SingleChildScrollView(
                  child: _isLoading
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 16),
                              Text('Processing with AI...'),
                            ],
                          ),
                        )
                      : Text(
                          _response,
                          style: const TextStyle(
                            fontSize: 16,
                            fontFamily: 'monospace',
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
