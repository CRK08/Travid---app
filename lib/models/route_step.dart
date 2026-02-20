
import 'package:latlong2/latlong.dart';

class RouteStep {
  final String instruction; // "Turn left onto Main St"
  final double distance; // Distance to next maneuver in meters
  final double duration; // Expected duration in seconds
  final LatLng location; // Location of the maneuver
  final String maneuverType; // "turn", "new name", "depart", "arrive", "roundabout"
  final String? modifier; // "left", "right", "sharp right", etc.

  RouteStep({
    required this.instruction,
    required this.distance,
    required this.duration,
    required this.location,
    required this.maneuverType,
    this.modifier,
  });

  factory RouteStep.fromJson(Map<String, dynamic> json) {
    final maneuver = json['maneuver'];
    final locationList = maneuver['location'] as List;
    final location = LatLng((locationList[1] as num).toDouble(), (locationList[0] as num).toDouble());
    
    // Construct readable instruction if not provided (OSRM sometimes provides minimal info)
    String instructionText = json['name'] ?? "";
    final type = maneuver['type'];
    final mod = maneuver['modifier'];
    
    if (instructionText.isEmpty) {
      if (type == 'turn') {
        instructionText = "Turn $mod";
      } else if (type == 'new name') {
        instructionText = "Continue";
      } else if (type == 'depart') {
        instructionText = "Start route";
      } else if (type == 'arrive') {
        instructionText = "Arrive at destination";
      } else {
        instructionText = type.toString();
      }
    } else {
      // Enhanced instruction
       if (type == 'turn') {
        instructionText = "Turn $mod onto $instructionText";
      } else if (type == 'new name') {
        instructionText = "Continue onto $instructionText";
      }
    }

    return RouteStep(
      instruction: instructionText,
      distance: (json['distance'] as num).toDouble(),
      duration: (json['duration'] as num).toDouble(),
      location: location,
      maneuverType: type,
      modifier: mod,
    );
  }
}
