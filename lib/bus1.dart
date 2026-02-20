// lib/bus1.dart
// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fuzzywuzzy/fuzzywuzzy.dart';
import 'package:travid/core/providers.dart';
import 'package:travid/core/app_translations.dart';

class BusPage extends ConsumerStatefulWidget {
  final ValueNotifier<String?> voiceNotifier;
  const BusPage({super.key, required this.voiceNotifier});

  @override
  ConsumerState<BusPage> createState() => _BusPageState();
}

class _BusPageState extends ConsumerState<BusPage> {
  final TextEditingController _fromCtrl = TextEditingController();
  final TextEditingController _toCtrl = TextEditingController();
  String _statusKey = 'enter_route'; // Key instead of raw text
  List<dynamic> _statusArgs = []; // Arguments for status
  
  List<Map<String, dynamic>> _allRoutes = [];
  List<Map<String, dynamic>> _results = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    widget.voiceNotifier.addListener(_onVoiceCommand);
    _loadRoutes();
  }

  Future<void> _loadRoutes() async {
    try {
      final jsonString = await rootBundle
          .loadString('assets/covai_all_routes_structured.json');
      final List<dynamic> data = json.decode(jsonString);
      setState(() {
        _allRoutes = data.cast<Map<String, dynamic>>();
        _isLoading = false;
      });
    } catch (e) {
      print("Error loading routes: $e");
      setState(() => _isLoading = false);
    }
  }

  void _onVoiceCommand() {
    final raw = widget.voiceNotifier.value;
    if (raw == null || raw.isEmpty) return;
    final cmd = raw.toLowerCase();

    final matchFromTo = RegExp(
            r"(?:bus|search)?\s*(?:from\s*)?([a-zA-Z\s]+?)\s*(?:to|towards)\s*([a-zA-Z\s]+)")
        .firstMatch(cmd);
    if (matchFromTo != null) {
      final from = matchFromTo.group(1)?.trim() ?? "";
      final to = matchFromTo.group(2)?.trim() ?? "";
      if (from.isNotEmpty && to.isNotEmpty) {
        _fromCtrl.text = from;
        _toCtrl.text = to;
        _performSearch(from, to);
        return;
      }
    }

    final matchTo =
        RegExp(r"(?:bus|search)?\s*(?:to|for)\s*([a-zA-Z\s]+)").firstMatch(cmd);
    if (matchTo != null) {
      final to = matchTo.group(1)?.trim() ?? "";
      if (to.isNotEmpty) {
        _toCtrl.text = to;
        _performSmartFrom(to);
      }
      return;
    }

    final routeMatch =
        RegExp(r"(find|show|search)?\s*route\s*([a-zA-Z0-9]+)").firstMatch(cmd);
    if (routeMatch != null) {
      final routeNum = routeMatch.group(2) ?? "";
      _performRouteNumberSearch(routeNum);
      return;
    }
  }

  String _bestFuzzyMatch(List<String> options, String input) {
    if (options.isEmpty) return input;
    var bestScore = 0;
    var bestMatch = input;
    for (var o in options) {
      final score = ratio(o.toLowerCase(), input.toLowerCase());
      if (score > bestScore) {
        bestScore = score;
        bestMatch = o;
      }
    }
    return bestMatch;
  }

  void _performSearch(String from, String to) {
    final fromList =
        _allRoutes.map((r) => (r["From"] ?? "").toString()).toList();
    final toList = _allRoutes.map((r) => (r["To"] ?? "").toString()).toList();

    final bestFrom = _bestFuzzyMatch(fromList, from);
    final bestTo = _bestFuzzyMatch(toList, to);

    final results = _allRoutes.where((r) {
      final rf = (r["From"] ?? "").toString().toLowerCase();
      final rt = (r["To"] ?? "").toString().toLowerCase();
      return (rf.contains(bestFrom.toLowerCase()) &&
              rt.contains(bestTo.toLowerCase())) ||
          (rf.contains(bestTo.toLowerCase()) &&
              rt.contains(bestFrom.toLowerCase()));
    }).toList();

    setState(() {
      _results = results;
      // Using direct strings for dynamic content results
       _statusKey = results.isEmpty ? 'no_buses' : 'found_buses';
       _statusArgs = results.isEmpty 
          ? [bestFrom, bestTo] 
          : [results.length, bestFrom, bestTo];
    });
  }

  void _performSmartFrom(String to) {
    final toList = _allRoutes.map((r) => (r["To"] ?? "").toString()).toList();
    final bestTo = _bestFuzzyMatch(toList, to);

    final matches = _allRoutes.where((r) {
      final rf = (r["From"] ?? "").toString().toLowerCase();
      final rt = (r["To"] ?? "").toString().toLowerCase();
      return rf.contains(bestTo.toLowerCase()) ||
          rt.contains(bestTo.toLowerCase());
    }).toList();

    setState(() {
      _results = matches;
      _statusKey = matches.isEmpty ? 'no_buses' : 'found_buses';
      _statusArgs = matches.isEmpty 
          ? ["?", bestTo] 
          : [matches.length, "?", bestTo];
    });
  }

  void _performRouteNumberSearch(String routeNum) {
    final results = _allRoutes
        .where((r) => (r["Route no"] ?? "").toString().contains(routeNum))
        .toList();
    setState(() {
      _results = results;
      _statusKey = results.isEmpty ? 'no_buses' : 'found_buses';
      _statusArgs = results.isEmpty 
          ? ["Route $routeNum", ""] 
          : [results.length, "Route $routeNum", ""];
    });
  }

  @override
  void dispose() {
    widget.voiceNotifier.removeListener(_onVoiceCommand);
    _fromCtrl.dispose();
    _toCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    String t(String key) => AppTranslations.get(key, settings.language);

    // Helper to format status string
    String getStatusText() {
       if (_statusKey == 'enter_route') return t('enter_route');
       
       if (_statusKey == 'no_buses') {
         if (_statusArgs.length >= 2) {
           return "${t('no_buses')}: ${_statusArgs[0]} → ${_statusArgs[1]}";
         }
         return t('no_buses');
       }
       
       if (_statusKey == 'found_buses') {
          if (_statusArgs.length >= 3) {
             return "${t('found_buses')} (${_statusArgs[0]}): ${_statusArgs[1]} → ${_statusArgs[2]}";
          }
          return t('found_buses');
       }
       
       return _statusKey;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(t('bus_title')),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  children: [
                    TextField(
                      controller: _fromCtrl,
                      decoration: InputDecoration(
                        labelText: t('from_label'),
                        hintText: t('from_hint'),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _toCtrl,
                      decoration: InputDecoration(
                        labelText: t('to_label'),
                        hintText: t('to_hint'),
                        border: const OutlineInputBorder(),
                      ),
                      onSubmitted: (_) =>
                          _performSearch(_fromCtrl.text, _toCtrl.text),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.search),
                      label: Text(t('search_btn')),
                      onPressed: () =>
                          _performSearch(_fromCtrl.text, _toCtrl.text),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(getStatusText(), style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 10),
            Expanded(
              child: _results.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.directions_bus_outlined, size: 64, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          Text(
                            t('enter_route'),
                            style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _results.length,
                      itemBuilder: (context, i) {
                        final r = _results[i];
                        return Card(
                          child: ListTile(
                            title: Text(
                              "Route ${r["Route no"] ?? "-"}",
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            subtitle: Text(
                                "${r["From"] ?? "Unknown"} → ${r["To"] ?? "Unknown"}"),
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
