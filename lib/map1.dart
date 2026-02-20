import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Added
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:travid/core/providers.dart'; // Added
import 'package:travid/core/app_translations.dart';
import 'package:travid/services/global_ai_service.dart';
import 'package:travid/services/poi_service.dart';
import 'package:travid/services/routing_service.dart';
import 'package:travid/features/maps/widgets/floating_search_bar.dart';
import 'package:travid/models/map_models.dart';
import 'package:travid/models/route_step.dart';
import 'dart:async';

class MapPage extends ConsumerStatefulWidget { // Changed to ConsumerStatefulWidget
  final ValueNotifier<String?> voiceNotifier;
  const MapPage({super.key, required this.voiceNotifier});

  @override
  ConsumerState<MapPage> createState() => _MapPageState(); // Changed to ConsumerState
}

class _MapPageState extends ConsumerState<MapPage> { // Changed to ConsumerState
  late final MapController _mapController;
  LatLng _currentLocation = const LatLng(11.0168, 76.9558);
  double _zoom = 13;
  StreamSubscription<Position>? _positionSubscription;
  
  // Services
  final POIService _poiService = POIService();
  final RoutingService _routingService = RoutingService();
  
  // State
  List<LatLng> _routePoints = [];
  bool _isNavigating = false;
  Map<String, dynamic>? _selectedPlace;
  
  // Map theme
  MapTheme _currentMapTheme = MapTheme.standard;
  
  // Navigation info
  NavigationInfo? _navigationInfo;
  List<RouteStep> _routeSteps = [];
  int _currentStepIndex = 0;
  bool _isSimulating = false;
  Timer? _simulationTimer;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _listenToVoice();
    _initLiveLocation();
    _registerCommands();
  }
  
  @override
  void dispose() {
    _unregisterCommands();
    _positionSubscription?.cancel();
    super.dispose();
  }

  void _registerCommands() {
    final ai = GlobalAIService();
    ai.registerCommand("zoom in", (_) => _handleVoiceCommand("zoom in"));
    ai.registerCommand("zoom out", (_) => _handleVoiceCommand("zoom out"));
    ai.registerCommand("where am i", (_) => _handleVoiceCommand("where am i"));
    ai.registerCommand("current location", (_) => _handleVoiceCommand("current location"));
    ai.registerCommand("nearby", (_) => _handleVoiceCommand("nearby"));
    ai.registerCommand("around me", (_) => _handleVoiceCommand("around me"));
    ai.registerCommand("take me to", (input) => _handleVoiceCommand(input));
    ai.registerCommand("route to", (input) => _handleVoiceCommand(input));
    ai.registerCommand("go to", (input) => _handleVoiceCommand(input));
    ai.registerCommand("reset", (_) => _handleVoiceCommand("reset"));
  }

  void _unregisterCommands() {
    final ai = GlobalAIService();
    ai.unregisterCommand("zoom in");
    ai.unregisterCommand("zoom out");
    ai.unregisterCommand("where am i");
    ai.unregisterCommand("current location");
    ai.unregisterCommand("nearby");
    ai.unregisterCommand("around me");
    ai.unregisterCommand("take me to");
    ai.unregisterCommand("route to");
    ai.unregisterCommand("go to");
    ai.unregisterCommand("reset");
  }

  void _listenToVoice() {
    widget.voiceNotifier.addListener(() {
      final command = widget.voiceNotifier.value?.toLowerCase() ?? "";
      _handleVoiceCommand(command);
    });
  }

  Future<void> _initLiveLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please enable location services.")),
        );
      }
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    
    if (permission == LocationPermission.deniedForever) return;

    _positionSubscription = Geolocator.getPositionStream().listen((Position position) async {
      if (mounted) {
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
        });
        
        // Navigation Logic
        if (_isNavigating && _routeSteps.isNotEmpty && _currentStepIndex < _routeSteps.length) {
          final nextStep = _routeSteps[_currentStepIndex];
          final distanceToStep = Geolocator.distanceBetween(
            _currentLocation.latitude, 
            _currentLocation.longitude, 
            nextStep.location.latitude, 
            nextStep.location.longitude
          );
          
          // Debugging
          print("Distance to next step (${nextStep.instruction}): ${distanceToStep.toStringAsFixed(1)}m");
          
          // Announce if close (e.g. 30m)
          if (distanceToStep < 30) {
            // Announce turn
            GlobalAIService().speak(nextStep.instruction);
            
            // Advance step
            if (_currentStepIndex < _routeSteps.length - 1) {
              setState(() {
                _currentStepIndex++;
                _navigationInfo = _navigationInfo?.copyWith(
                  currentRoadName: _routeSteps[_currentStepIndex].instruction
                );
              });
              
              // Pre-announce next step if it's very close (e.g. quick turns)
              // For now, just wait for next loop
            } else {
              // Arrived
              GlobalAIService().speak("You have arrived at your destination.");
              setState(() {
                _isNavigating = false;
                _routePoints = [];
                _routeSteps = [];
              });
            }
          } else if (distanceToStep < 100 && distanceToStep > 80) {
             // Pre-warning (only once ideally, but simple check here might repeat)
             // To avoid repeat, we could track 'lastAnnouncedStep'
          }
        }
        
        // Update context service with location
        try {
          // ... existing geocoding logic ...
          // keeping it minimal to avoid huge file replacement, but user existing code had geocoding here
           final placemarks = await placemarkFromCoordinates(
            position.latitude,
            position.longitude,
          );
          if (placemarks.isNotEmpty) {
            final place = placemarks.first;
            final locationName = place.locality ?? place.subLocality ?? 'Unknown';
            GlobalAIService().contextService.updateLocation(
              _currentLocation,
              locationName: locationName,
            );
          }
        } catch (e) {
          // Update with just coordinates if geocoding fails
          GlobalAIService().contextService.updateLocation(_currentLocation);
        }
      }
    });

    try {
      final pos = await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() {
          _currentLocation = LatLng(pos.latitude, pos.longitude);
          _mapController.move(_currentLocation, 15);
        });
        
        // Update context service with initial location
        try {
          final placemarks = await placemarkFromCoordinates(
            pos.latitude,
            pos.longitude,
          );
          if (placemarks.isNotEmpty) {
            final place = placemarks.first;
            final locationName = place.locality ?? place.subLocality ?? 'Unknown';
            GlobalAIService().contextService.updateLocation(
              _currentLocation,
              locationName: locationName,
            );
          }
        } catch (e) {
          GlobalAIService().contextService.updateLocation(_currentLocation);
        }
      }
    } catch (e) {
      print("Error fetching location: $e");
    }
  }

  Future<void> _moveToCurrent() async {
    try {
      final pos = await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() {
          _currentLocation = LatLng(pos.latitude, pos.longitude);
        });
        _mapController.move(_currentLocation, _zoom);
      }
    } catch (e) {
      print("Error getting location: $e");
    }
  }

  // 📍 "Where am I?"
  Future<void> _announceLocation() async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        _currentLocation.latitude,
        _currentLocation.longitude,
      );
      
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final address = [
          place.street,
          place.subLocality,
          place.locality,
          place.postalCode
        ].where((e) => e != null && e.isNotEmpty).join(', ');
        
        final aiService = GlobalAIService();
        await aiService.speak("You are at $address");
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(address)),
          );
        }
      }
    } catch (e) {
      GlobalAIService().speak("Unable to determine address.");
    }
  }

  // 🏥 "What's around me?"
  Future<void> _announceSurroundings() async {
    try {
      final aiService = GlobalAIService();
      await aiService.speak("Scanning surroundings...");
      
      final summary = await _poiService.getNearbySummary(_currentLocation);
      await aiService.speak(summary);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(summary)),
        );
      }
    } catch (e) {
      GlobalAIService().speak("Unable to scan surroundings.");
    }
  }

  // 🚗 "Take me to..."
  Future<void> _calculateRoute(String destination) async {
    try {
      final aiService = GlobalAIService();
      aiService.speak("Looking for $destination...");
      
      // Geocode destination
      List<Location> locations = await locationFromAddress(destination);
      if (locations.isEmpty) {
        aiService.speak("I couldn't find that location.");
        return;
      }
      
      final end = LatLng(locations.first.latitude, locations.first.longitude);
      
      // Fetch route
      aiService.speak("Calculating route...");
      final route = await _routingService.getRoute(_currentLocation, end);
      
      if (route != null) {
        final points = List<LatLng>.from(route['points']);
        final steps = List<RouteStep>.from(route['steps'] ?? []);
        
        final distanceKm = (route['distance'] as num).toDouble() / 1000;
        final durationSeconds = (route['duration'] as num).toInt();
        final duration = Duration(seconds: durationSeconds);
        
        // Create navigation info with ETA
        final now = DateTime.now();
        final eta = now.add(duration);
        
        final firstInstruction = steps.isNotEmpty ? steps.first.instruction : destination;

        final navInfo = NavigationInfo(
          estimatedTime: duration,
          remainingTime: duration,
          totalDistanceKm: distanceKm,
          remainingDistanceKm: distanceKm,
          estimatedArrival: eta,
          currentRoadName: firstInstruction,
        );
        
        setState(() {
          _routePoints = points;
          _routeSteps = steps;
          _currentStepIndex = 0;
          _isNavigating = true;
          _navigationInfo = navInfo;
          // Zoom to show route
          _mapController.move(end, 13);
        });
        
        aiService.speak(
          "Found route to $destination. "
          "Distance is ${navInfo.formattedRemainingDistance}. "
          "Starting navigation. " 
          "${steps.isNotEmpty ? steps.first.instruction : ''}"
        );
      } else {
        aiService.speak("Sorry, I couldn't calculate the route.");
      }
    } catch (e) {
      print("Routing error: $e");
      GlobalAIService().speak("Error finding route.");
    }
  }

  void _handleVoiceCommand(String command) {
    if (!mounted) return;
    if (command.isEmpty) return;
    
    final cmd = command.toLowerCase();
    
    if (cmd.startsWith("take me to ") || cmd.startsWith("route to ") || cmd.startsWith("go to ")) {
      final destination = cmd
          .replaceAll("take me to ", "")
          .replaceAll("route to ", "")
          .replaceAll("go to ", "")
          .trim();
      if (destination.isNotEmpty) {
        _calculateRoute(destination);
      }
      return;
    }
    
    if (cmd.contains("zoom in")) {
      setState(() => _zoom += 1);
      _mapController.move(_mapController.camera.center, _zoom);
    } else if (cmd.contains("zoom out")) {
      setState(() => _zoom -= 1);
      _mapController.move(_mapController.camera.center, _zoom);
    } else if (cmd.contains("show my location") || cmd.contains("current location")) {
      _moveToCurrent();
    } else if (cmd.contains("where am i") || cmd.contains("address")) {
      _announceLocation();
    } else if (cmd.contains("nearby") || cmd.contains("around me") || cmd.contains("surroundings")) {
      _announceSurroundings();
    } else if (cmd.contains("reset")) {
      setState(() {
        _routePoints = [];
        _isNavigating = false;
        _selectedPlace = null;
      });
      _mapController.move(_currentLocation, 13);
    }
  }

  void _onPlaceSelected(Map<String, dynamic> place) {
    final latStr = place['lat'];
    final lonStr = place['lon'];
    
    if (latStr != null && lonStr != null) {
      final lat = double.tryParse(latStr.toString());
      final lon = double.tryParse(lonStr.toString());
      
      if (lat != null && lon != null) {
        final point = LatLng(lat, lon);
        _mapController.move(point, 15);
        setState(() {
          _selectedPlace = place;
        });
        _showPlaceDetails(place);
      }
    }
  }

  void _showPlaceDetails(Map<String, dynamic> place) {
    final settings = ref.read(settingsProvider);
    String t(String key) => AppTranslations.get(key, settings.language);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, 
                height: 4, 
                decoration: BoxDecoration(
                  color: Colors.grey.shade300, 
                  borderRadius: BorderRadius.circular(2)
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              place['display_name']?.split(',')[0] ?? "Selected Place",
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              place['display_name'] ?? "",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      final name = place['display_name']?.split(',')[0] ?? "";
                      if (name.isNotEmpty) _calculateRoute(name);
                    },
                    icon: const Icon(Icons.directions),
                    label: Text(t('directions')),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  ),
                  child: Text(t('close')),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Listen to global settings for Dark Mode synchronization
    ref.listen(settingsProvider, (previous, next) {
      if (previous?.darkMode != next.darkMode) {
        setState(() {
          _currentMapTheme = next.darkMode ? MapTheme.dark : MapTheme.standard;
        });
      }
    });

    final settings = ref.watch(settingsProvider);
    String t(String key) => AppTranslations.get(key, settings.language);

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentLocation,
              initialZoom: _zoom,
              onTap: (tapPosition, latlng) {
                 // Close keyboard or deselect?
                 FocusScope.of(context).unfocus();
              },
            ),
            children: [
              TileLayer(
                urlTemplate: MapThemeHelper.getTileUrl(_currentMapTheme),
                userAgentPackageName: 'com.travid.app',
              ),
              PolylineLayer(
                polylines: [
                  if (_routePoints.isNotEmpty)
                    Polyline(
                      points: _routePoints,
                      strokeWidth: 5.0,
                      color: Colors.blueAccent,
                    ),
                ],
              ),
              MarkerLayer(markers: [
                // Current Location
                Marker(
                  point: _currentLocation,
                  width: 50,
                  height: 50,
                  child: const Icon(Icons.my_location,
                      color: Colors.blue, size: 30),
                ),
                // Destination Flag
                if (_routePoints.isNotEmpty)
                  Marker(
                    point: _routePoints.last,
                    width: 50,
                    height: 50,
                    child: const Icon(Icons.flag, color: Colors.red, size: 30),
                  ),
                // Selected Place
                if (_selectedPlace != null)
                   Marker(
                    point: LatLng(
                      double.tryParse(_selectedPlace!['lat'].toString()) ?? 0, 
                      double.tryParse(_selectedPlace!['lon'].toString()) ?? 0
                    ),
                    width: 50,
                    height: 50,
                    child: const Icon(Icons.location_on, color: Colors.red, size: 40),
                   ),
              ]),
            ],
          ),

          // Floating Search Bar
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: FloatingSearchBar(
                onPlaceSelected: _onPlaceSelected,
              ),
            ),
          ),
          
          // Navigation Info
          if (_isNavigating && _routePoints.isNotEmpty && _navigationInfo != null)
             Positioned(
               top: 100,
               left: 16,
               right: 16,
               child: Card(
                 color: Theme.of(context).cardColor,
                 elevation: 8,
                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                 child: Padding(
                   padding: const EdgeInsets.all(16.0),
                   child: Row(
                     children: [
                       Container(
                         padding: const EdgeInsets.all(12),
                         decoration: BoxDecoration(
                           color: Colors.green.withValues(alpha: 0.1),
                           borderRadius: BorderRadius.circular(12),
                         ),
                         child: const Icon(Icons.directions, color: Colors.green, size: 28),
                       ),
                       const SizedBox(width: 16),
                       Expanded(
                         child: Column(
                           crossAxisAlignment: CrossAxisAlignment.start,
                           mainAxisSize: MainAxisSize.min,
                           children: [
                             Text(
                               _navigationInfo!.formattedRemainingTime,
                               style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                 fontWeight: FontWeight.bold,
                                 color: Colors.green,
                               ),
                             ),
                             const SizedBox(height: 4),
                             Text(
                               "${_navigationInfo!.formattedRemainingDistance} • Arrival ${_navigationInfo!.formattedETA}",
                               style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                 fontWeight: FontWeight.w500,
                               ),
                             ),
                           ],
                         ),
                       ),
                       IconButton(
                         icon: const Icon(Icons.close),
                         onPressed: () {
                           setState(() {
                             _routePoints = [];
                             _isNavigating = false;
                           });
                         },
                       )
                     ],
                   ),
                 ),
               ),
             ),
             
          // FABs (Bottom Right) - Styled with secondary color
          if (!_isNavigating)
          Positioned(
            right: 16,
            bottom: 32,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton(
                  heroTag: "layers_btn",
                  mini: true,
                  backgroundColor: Theme.of(context).colorScheme.tertiary, // Distinct color
                  foregroundColor: Colors.white,
                  child: const Icon(Icons.layers, size: 20),
                  onPressed: _showThemePicker,
                  tooltip: 'Change Map Theme',
                ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  heroTag: "zoom_in",
                  mini: true,
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  foregroundColor: Colors.white,
                  child: const Icon(Icons.add, size: 20),
                  onPressed: () {
                    final curr = _mapController.camera.zoom;
                    _mapController.move(_mapController.camera.center, curr + 1);
                  },
                ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  heroTag: "zoom_out",
                  mini: true,
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  foregroundColor: Colors.white,
                  child: const Icon(Icons.remove, size: 20),
                  onPressed: () {
                    final curr = _mapController.camera.zoom;
                    _mapController.move(_mapController.camera.center, curr - 1);
                  },
                ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  heroTag: "my_loc",
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  onPressed: _moveToCurrent,
                  child: const Icon(Icons.my_location, size: 22),
                ),
              ],
            ),
          ),
          
          // Simulation Button (Debug)
          if (_isNavigating && !_isSimulating)
             Positioned(
               bottom: 120,
               right: 16,
               child: FloatingActionButton.extended(
                 heroTag: "sim_btn",
                 onPressed: _startSimulation,
                 label: Text(t('simulate')),
                 icon: const Icon(Icons.play_arrow),
                 backgroundColor: Colors.orange,
               ),
             ),
        ],
      ),
    );
  }

  // 🏃‍♂️ "Simulate Navigation" (For Testing)
  void _startSimulation() {
    if (_routePoints.isEmpty) return;
    
    setState(() {
      _isSimulating = true;
      _currentStepIndex = 0;
    });

    int pointIndex = 0;
    _simulationTimer?.cancel();
    _simulationTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (!mounted || !_isNavigating || pointIndex >= _routePoints.length) {
        timer.cancel();
        setState(() => _isSimulating = false);
        return;
      }

      final point = _routePoints[pointIndex];
      
      // Update location manually
      setState(() {
        _currentLocation = point;
        _mapController.move(_currentLocation, 16);
      });
      
      // Trigger the navigation logic in _positionSubscription? 
      // Since we are mocking location, we need to trigger the check manually or expose the logic.
      // For simplicity in this demo, we'll duplicate the check logic here or trigger a manual check.
      
      _checkNavigationProgress(point);

      pointIndex += 2; // Speed up simulation (skip points)
    });
  }

  void _checkNavigationProgress(LatLng pos) {
     if (_isNavigating && _routeSteps.isNotEmpty && _currentStepIndex < _routeSteps.length) {
          final nextStep = _routeSteps[_currentStepIndex];
          final distanceToStep = Geolocator.distanceBetween(
            pos.latitude, 
            pos.longitude, 
            nextStep.location.latitude, 
            nextStep.location.longitude
          );
          
          if (distanceToStep < 40) { // Larger threshold for simulation speed
            GlobalAIService().speak(nextStep.instruction);
            if (_currentStepIndex < _routeSteps.length - 1) {
              setState(() {
                _currentStepIndex++;
                 _navigationInfo = _navigationInfo?.copyWith(
                  currentRoadName: _routeSteps[_currentStepIndex].instruction
                );
              });
            } else {
               GlobalAIService().speak("You have arrived.");
               _simulationTimer?.cancel();
               setState(() {
                  _isNavigating = false;
                  _isSimulating = false;
               });
            }
          }
     }
  }

  /// Show map theme picker dialog
  void _showThemePicker() {
    final settings = ref.read(settingsProvider);
    String t(String key) => AppTranslations.get(key, settings.language);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t('map_theme')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: MapTheme.values.where((t) => t != MapTheme.dark).map((theme) {
            return ListTile(
              leading: Icon(MapThemeHelper.getThemeIcon(theme)),
              title: Text(MapThemeHelper.getThemeName(theme)),
              trailing: _currentMapTheme == theme
                  ? const Icon(Icons.check, color: Colors.blue)
                  : null,
              onTap: () {
                setState(() => _currentMapTheme = theme);
                Navigator.pop(context);
                GlobalAIService().speak(
                  "Switched to ${MapThemeHelper.getThemeName(theme)} map theme"
                );
              },
            );
          }).toList(),
        ),
      ),
    );
  }
}
