import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:latlong2/latlong.dart';
import 'package:travid/models/route_step.dart';

class RoutingService {
  final Dio _dio = Dio();
  static const String _osrmUrl = 'https://router.project-osrm.org/route/v1/driving';

  /// Get route points between start and end
  Future<Map<String, dynamic>?> getRoute(LatLng start, LatLng end) async {
    try {
      final url = '$_osrmUrl/${start.longitude},${start.latitude};${end.longitude},${end.latitude}';
      
      final response = await _dio.get(
        url,
        queryParameters: {
          'overview': 'full',
          'geometries': 'geojson',
          'steps': 'true',
        },
      );

      if (response.statusCode == 200 && response.data['code'] == 'Ok') {
        final route = response.data['routes'][0];
        final geometry = route['geometry'];
        final coordinates = geometry['coordinates'] as List;
        
        // Convert to LatLng list safely
        final points = coordinates.map((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble())).toList();
        
        // Parse steps
        final legs = route['legs'] as List;
        List<RouteStep> steps = [];
        if (legs.isNotEmpty) {
          final stepsJson = legs[0]['steps'] as List;
          steps = stepsJson.map((s) => RouteStep.fromJson(s)).toList();
        }

        return {
          'points': points,
          'distance': route['distance'], // meters
          'duration': route['duration'], // seconds
          'summary': legs.isNotEmpty ? (legs[0]['summary'] ?? '') : '',
          'steps': steps,
        };
      }
      return null;
    } catch (e) {
      debugPrint("Routing error: $e");
      return null;
    }
  }

  String formatDistance(double meters) {
    if (meters < 1000) {
      return "${meters.round()} meters";
    } else {
      return "${(meters / 1000).toStringAsFixed(1)} kilometers";
    }
  }

  String formatDuration(double seconds) {
    if (seconds < 60) {
      return "${seconds.round()} seconds";
    } else if (seconds < 3600) {
      return "${(seconds / 60).round()} minutes";
    } else {
      final hours = (seconds / 3600).floor();
      final minutes = ((seconds % 3600) / 60).round();
      return "$hours hours ${minutes > 0 ? '$minutes mins' : ''}";
    }
  }
}
