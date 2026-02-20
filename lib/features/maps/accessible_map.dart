import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:vibration/vibration.dart';
import '../../services/ai_service.dart';

/// Accessible map with voice navigation for blind users
class AccessibleMapPage extends StatefulWidget {
  final ValueNotifier<String?> voiceNotifier;
  const AccessibleMapPage({super.key, required this.voiceNotifier});

  @override
  State<AccessibleMapPage> createState() => _AccessibleMapPageState();
}

class _AccessibleMapPageState extends State<AccessibleMapPage> {
  late final MapController _mapController;
  late final FlutterTts _tts;
  
  LatLng _currentLocation = const LatLng(11.0168, 76.9558); // Coimbatore default
  double _zoom = 15;
  bool _isLoading = true;
  final AIService _aiService = AIService();
  
  // Bus stops loaded from JSON
  List<BusStop> _busStops = [];


  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _tts = FlutterTts();
    _initTTS();
    _listenToVoice();
    _loadBusStops(); // Load from JSON
    _initLocation();
  }

  /// Load bus stops from JSON file
  Future<void> _loadBusStops() async {
    try {
      // Load JSON file
      final String jsonString = await rootBundle.loadString('assets/covai_all_routes_structured.json');
      final List<dynamic> jsonData = json.decode(jsonString);
      
      // Extract unique stops with coordinates
      final Map<String, BusStop> uniqueStops = {};
      final Map<String, Set<String>> routesPerStop = {};
      
      for (var route in jsonData) {
        final String? stopName = route['To'];
        final double? lat = route['To_lat'];
        final double? lng = route['To_lng'];
        final String? routeNo = route['Route no'];
        
        // Only add stops with valid coordinates
        if (stopName != null && lat != null && lng != null && routeNo != null) {
          if (!uniqueStops.containsKey(stopName)) {
            uniqueStops[stopName] = BusStop(
              name: stopName,
              location: LatLng(lat, lng),
              routes: [],
            );
            routesPerStop[stopName] = {};
          }
          routesPerStop[stopName]!.add(routeNo);
        }
      }
      
      // Convert sets to lists
      for (var entry in uniqueStops.entries) {
        entry.value.routes = routesPerStop[entry.key]!.toList()..sort();
      }
      
      setState(() {
        _busStops = uniqueStops.values.toList();
        _isLoading = false;
      });
      
      _speak("Loaded ${_busStops.length} bus stops from Coimbatore routes");
      debugPrint("✅ Loaded ${_busStops.length} bus stops");
    } catch (e) {
      debugPrint("❌ Error loading bus stops: $e");
      setState(() => _isLoading = false);
      _speak("Error loading bus stops");
    }
  }

  Future<void> _initTTS() async {
    await _tts.setLanguage("en-US");
    await _tts.setSpeechRate(0.5); // Slower for clarity
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
  }

  void _listenToVoice() {
    widget.voiceNotifier.addListener(() {
      final command = widget.voiceNotifier.value?.toLowerCase() ?? "";
      if (command.isNotEmpty) {
        _handleVoiceCommand(command);
      }
    });
  }

  Future<void> _initLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _speak("Please enable location services");
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _speak("Location permission denied");
          return;
        }
      }

      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
      });
      _mapController.move(_currentLocation, _zoom);
      _speak("Location found. You are in Chennai.");
      
      // Live location updates
      Geolocator.getPositionStream().listen((Position position) {
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
        });
      });
    } catch (e) {
      _speak("Could not get location");
    }
  }

  Future<void> _speak(String text) async {
    await _tts.speak(text);
  }

  Future<void> _vibrate({int duration = 50}) async {
    if (await Vibration.hasVibrator()) {
      Vibration.vibrate(duration: duration);
    }
  }



  Future<void> _handleVoiceCommand(String command) async {
    _vibrate(duration: 30); // Confirm command received
    
    // Quick local checks for common commands (latency optimization)
    if (command == "stop" || command == "cancel") {
      _tts.stop();
      return;
    }
    
    _speak("Processing...");
    
    // Get nearby stops for context
    final nearbyStops = _busStops.map((s) {
      final dist = _calculateDistance(_currentLocation, s.location);
      return MapEntry(s, dist);
    }).toList()
      ..sort((a, b) => a.value.compareTo(b.value));
      
    final topStops = nearbyStops.take(5).map((e) => e.key.name).toList();
    
    // Get routes for context
    final stopRoutes = {
      for (var s in nearbyStops.take(5))
        s.key.name: s.key.routes
    };

    // Process with AI
    final aiResponse = await _aiService.processQuery(
      userQuery: command,
      currentLocation: "${_currentLocation.latitude}, ${_currentLocation.longitude}",
      nearbyStops: topStops,
      stopRoutes: stopRoutes,
    );
    
    // Act on AI response
    if (aiResponse.shouldPlanRoute) {
      _planRoute(aiResponse.destination!);
    } else if (aiResponse.shouldFindStop) {
      // If destination provided, search for it
      if (aiResponse.destination != null) {
        _searchBusStop(aiResponse.destination!);
      } else {
        _speak("Which bus stop do you want to find?");
      }
    } else if (aiResponse.shouldListRoutes || aiResponse.action == 'find_nearby') {
      _findNearbyStops();
    } else if (aiResponse.action == 'zoom_in') {
      _zoomIn();
    } else if (aiResponse.action == 'zoom_out') {
      _zoomOut();
    } else if (aiResponse.action == 'center_map') {
      _centerOnUser();
    } else {
      // Just speak the response
      _speak(aiResponse.response);
    }
  }

  /// Plan route from current location to destination
  void _planRoute(String destinationName) {
    _speak("Planning route to $destinationName");
    
    // Find destination stop
    final destStops = _busStops.where((stop) => 
      stop.name.toLowerCase().contains(destinationName.toLowerCase())
    ).toList();
    
    if (destStops.isEmpty) {
      _speak("Could not find bus stop $destinationName");
      _vibrate(duration: 200);
      return;
    }
    
    final destination = destStops.first;
    
    // Find nearest stop to current location
    final stopsWithDistance = _busStops.map((stop) {
      final distance = _calculateDistance(_currentLocation, stop.location);
      return MapEntry(stop, distance);
    }).toList();
    
    stopsWithDistance.sort((a, b) => a.value.compareTo(b.value));
    final nearestStop = stopsWithDistance.first.key;
    final distanceToNearest = stopsWithDistance.first.value;
    
    // Find common routes between nearest and destination
    final commonRoutes = nearestStop.routes.where(
      (route) => destination.routes.contains(route)
    ).toList();
    
    // Calculate distance to destination
    final distanceToDest = _calculateDistance(_currentLocation, destination.location);
    final direction = _getDirection(_currentLocation, destination.location);
    
    // Build route message
    String message = "";
    
    if (commonRoutes.isNotEmpty) {
      // Direct route available
      message = "Route found. "
                "Walk ${distanceToNearest.round()} meters to ${nearestStop.name}. "
                "Take bus ${commonRoutes.join(' or ')}. "
                "Get off at ${destination.name}. "
                "Total distance: ${distanceToDest.round()} meters $direction.";
    } else {
      // No direct route - need transfer
      message = "No direct bus found. "
                "Nearest stop is ${nearestStop.name}, ${distanceToNearest.round()} meters away. "
                "Routes available: ${nearestStop.routes.take(3).join(', ')}. "
                "Destination ${destination.name} has routes: ${destination.routes.take(3).join(', ')}. "
                "You may need to transfer.";
    }
    
    _speak(message);
    _vibrate(duration: 100);
    
    // Show route on map
    _mapController.move(destination.location, 14);
  }

  void _findNearbyStops() {
    _speak("Finding nearby bus stops");
    
    // Calculate distances
    final stopsWithDistance = _busStops.map((stop) {
      final distance = _calculateDistance(_currentLocation, stop.location);
      return MapEntry(stop, distance);
    }).toList();
    
    // Sort by distance
    stopsWithDistance.sort((a, b) => a.value.compareTo(b.value));
    
    // Speak top 3
    final nearbyStops = stopsWithDistance.take(3).toList();
    
    String message = "${nearbyStops.length} bus stops found nearby. ";
    for (var i = 0; i < nearbyStops.length; i++) {
      final stop = nearbyStops[i].key;
      final distance = nearbyStops[i].value;
      final direction = _getDirection(_currentLocation, stop.location);
      message += "${i + 1}. ${stop.name}, ${distance.round()} meters $direction. ";
    }
    
    _speak(message);
    _vibrate(duration: 100); // Success vibration
  }



  void _searchBusStop(String query) {
    final found = _busStops.where((stop) => 
      stop.name.toLowerCase().contains(query)
    ).toList();
    
    if (found.isEmpty) {
      _speak("No bus stop found matching $query");
      _vibrate(duration: 200); // Error vibration
    } else {
      final stop = found.first;
      final distance = _calculateDistance(_currentLocation, stop.location);
      final direction = _getDirection(_currentLocation, stop.location);
      
      _speak("Found ${stop.name}, ${distance.round()} meters $direction. "
             "Routes: ${stop.routes.join(', ')}");
      
      // Move map to show the stop
      _mapController.move(stop.location, 16);
      _vibrate(duration: 100); // Success vibration
    }
  }

  void _zoomIn() {
    setState(() => _zoom += 1);
    _mapController.move(_mapController.camera.center, _zoom);
    _speak("Zoomed in");
  }

  void _zoomOut() {
    setState(() => _zoom -= 1);
    _mapController.move(_mapController.camera.center, _zoom);
    _speak("Zoomed out");
  }

  void _centerOnUser() {
    _mapController.move(_currentLocation, _zoom);
    _speak("Map centered on your location");
    _vibrate(duration: 50);
  }

  void _speakHelp() {
    _speak("Available commands: "
           "What's nearby, to find bus stops. "
           "Where am I, to hear your location. "
           "How do I get to, followed by destination, to plan a route. "
           "Find bus stop, to search. "
           "Zoom in, zoom out, center map. "
           "Say help to hear this again.");
  }

  double _calculateDistance(LatLng from, LatLng to) {
    return Geolocator.distanceBetween(
      from.latitude, from.longitude,
      to.latitude, to.longitude,
    );
  }

  String _getDirection(LatLng from, LatLng to) {
    final bearing = _calculateBearing(from, to);
    if (bearing >= 337.5 || bearing < 22.5) return "north";
    if (bearing >= 22.5 && bearing < 67.5) return "northeast";
    if (bearing >= 67.5 && bearing < 112.5) return "east";
    if (bearing >= 112.5 && bearing < 157.5) return "southeast";
    if (bearing >= 157.5 && bearing < 202.5) return "south";
    if (bearing >= 202.5 && bearing < 247.5) return "southwest";
    if (bearing >= 247.5 && bearing < 292.5) return "west";
    return "northwest";
  }

  double _calculateBearing(LatLng from, LatLng to) {
    final lat1 = from.latitude * (3.14159 / 180);
    final lat2 = to.latitude * (3.14159 / 180);
    final dLon = (to.longitude - from.longitude) * (3.14159 / 180);
    
    final y = Math.sin(dLon) * Math.cos(lat2);
    final x = Math.cos(lat1) * Math.sin(lat2) -
              Math.sin(lat1) * Math.cos(lat2) * Math.cos(dLon);
    
    final bearing = Math.atan2(y, x) * (180 / 3.14159);
    return (bearing + 360) % 360;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Accessible Map"),
        backgroundColor: Colors.blue.shade700,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _speakHelp,
            tooltip: "Help",
          ),
        ],
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // Voice command buttons for accessibility
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue.shade50,
            child: Column(
              children: [
                _buildVoiceButton(
                  icon: Icons.near_me,
                  label: "What's Nearby?",
                  onPressed: () => _handleVoiceCommand("what's nearby"),
                ),
                const SizedBox(height: 8),
                _buildVoiceButton(
                  icon: Icons.location_on,
                  label: "Where Am I?",
                  onPressed: () => _handleVoiceCommand("where am i"),
                ),
                const SizedBox(height: 8),
                _buildVoiceButton(
                  icon: Icons.search,
                  label: "Find Bus Stop",
                  onPressed: () => _handleVoiceCommand("find bus stop"),
                ),
              ],
            ),
          ),
          
          // Map
          Expanded(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _currentLocation,
                initialZoom: _zoom,
                onTap: (tapPosition, latlng) async {
                  // Speak what's at tapped location
                  await _vibrate(duration: 30);
                  
                  // Find nearest bus stop to tap
                  final nearest = _busStops.reduce((a, b) {
                    final distA = _calculateDistance(latlng, a.location);
                    final distB = _calculateDistance(latlng, b.location);
                    return distA < distB ? a : b;
                  });
                  
                  final distance = _calculateDistance(latlng, nearest.location);
                  if (distance < 500) {
                    _speak("${nearest.name}, ${distance.round()} meters away");
                  } else {
                    _speak("No bus stop nearby");
                  }
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                  subdomains: const ['a', 'b', 'c'],
                ),
                
                // Bus stop markers
                MarkerLayer(
                  markers: _busStops.map((stop) => Marker(
                    point: stop.location,
                    width: 40,
                    height: 40,
                    child: GestureDetector(
                      onTap: () async {
                        await _vibrate(duration: 50);
                        final distance = _calculateDistance(_currentLocation, stop.location);
                        _speak("${stop.name}, ${distance.round()} meters away. "
                               "Routes: ${stop.routes.join(', ')}");
                      },
                      child: const Icon(
                        Icons.directions_bus,
                        color: Colors.blue,
                        size: 30,
                      ),
                    ),
                  )).toList(),
                ),
                
                // Current location marker
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _currentLocation,
                      width: 60,
                      height: 60,
                      child: const Icon(
                        Icons.my_location,
                        color: Colors.red,
                        size: 40,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _centerOnUser,
        icon: const Icon(Icons.my_location),
        label: const Text("My Location"),
        backgroundColor: Colors.blue.shade700,
      ),
    );
  }

  Widget _buildVoiceButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 28),
        label: Text(
          label,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue.shade700,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }
}

/// Bus stop model
class BusStop {
  final String name;
  final LatLng location;
  List<String> routes;

  BusStop({
    required this.name,
    required this.location,
    required this.routes,
  });
}

/// Math helper (since dart:math might not be imported)
class Math {
  static double sin(double x) => x - (x * x * x) / 6 + (x * x * x * x * x) / 120;
  static double cos(double x) => 1 - (x * x) / 2 + (x * x * x * x) / 24;
  static double atan2(double y, double x) {
    if (x > 0) return _atan(y / x);
    if (x < 0 && y >= 0) return _atan(y / x) + 3.14159;
    if (x < 0 && y < 0) return _atan(y / x) - 3.14159;
    if (x == 0 && y > 0) return 3.14159 / 2;
    if (x == 0 && y < 0) return -3.14159 / 2;
    return 0;
  }
  static double _atan(double x) => x - (x * x * x) / 3 + (x * x * x * x * x) / 5;
}
