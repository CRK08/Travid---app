import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

/// Screen to test and list available Gemini models
class ModelListScreen extends StatefulWidget {
  const ModelListScreen({super.key});

  @override
  State<ModelListScreen> createState() => _ModelListScreenState();
}

class _ModelListScreenState extends State<ModelListScreen> {
  static const String _apiKey = const String.fromEnvironment('GEMINI_API_KEY', defaultValue: 'YOUR_GEMINI_API_KEY_HERE');
  List<String> _models = [];
  bool _isLoading = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _listModels();
  }

  Future<void> _listModels() async {
    setState(() {
      _isLoading = true;
      _error = '';
      _models = [];
    });

    try {
      // Try different model names to see which works
      final testModels = [
        'gemini-pro',
        'models/gemini-pro',
        'gemini-1.5-flash',
        'models/gemini-1.5-flash',
        'gemini-1.5-pro',
        'models/gemini-1.5-pro',
      ];

      for (final modelName in testModels) {
        try {
          final model = GenerativeModel(
            model: modelName,
            apiKey: _apiKey,
          );
          
          // Try a simple generation to test if model works
          final response = await model.generateContent([
            Content.text('Say "OK" if you can read this')
          ]);
          
          if (response.text != null) {
            setState(() {
              _models.add('✅ $modelName - WORKS! Response: ${response.text}');
            });
          }
        } catch (e) {
          setState(() {
            _models.add('❌ $modelName - Error: ${e.toString().substring(0, 100)}...');
          });
        }
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Models Test'),
        backgroundColor: Colors.blue.shade700,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Info card
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Testing Model Availability',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'This screen tests which Gemini models are accessible with your API key.',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Refresh button
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _listModels,
              icon: const Icon(Icons.refresh),
              label: const Text('Test Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 16),

            // Results
            if (_isLoading)
              const Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Testing models...'),
                    ],
                  ),
                ),
              )
            else if (_error.isNotEmpty)
              Expanded(
                child: Center(
                  child: Text(
                    _error,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: _models.length,
                  itemBuilder: (context, index) {
                    final model = _models[index];
                    final isWorking = model.startsWith('✅');
                    
                    return Card(
                      color: isWorking ? Colors.green.shade50 : Colors.red.shade50,
                      child: ListTile(
                        leading: Icon(
                          isWorking ? Icons.check_circle : Icons.error,
                          color: isWorking ? Colors.green : Colors.red,
                        ),
                        title: Text(
                          model,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
