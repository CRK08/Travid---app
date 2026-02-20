import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:latlong2/latlong.dart';

class POIService {
  final Dio _dio = Dio();
  
  // Overpass API endpoint
  static const String _overpassUrl = 'https://overpass-api.de/api/interpreter';

  /// Get nearby POIs (amenities) within radius (meters)
  /// Types: restaurant, cafe, bus_station, hospital, pharmacy, bank, atm
  Future<List<Map<String, dynamic>>> getNearbyPOIs(LatLng location, {int radius = 500}) async {
    try {
      // Build Overpass QL query
      // node(around:radius, lat, lon)[amenity];
      // out body;
      final query = """
        [out:json];
        (
          node["amenity"](around:$radius,${location.latitude},${location.longitude});
          way["amenity"](around:$radius,${location.latitude},${location.longitude});
        );
        out center;
      """;

      final response = await _dio.get(
        _overpassUrl,
        queryParameters: {'data': query},
      );

      if (response.statusCode == 200 && response.data != null) {
        final elements = response.data['elements'] as List;
        return elements.map((e) {
          final tags = e['tags'] as Map<String, dynamic>;
          final lat = e['lat'] ?? e['center']['lat'];
          final lon = e['lon'] ?? e['center']['lon'];
          
          return {
            'type': tags['amenity'] ?? 'Unknown',
            'name': tags['name'] ?? tags['amenity'] ?? 'Unknown Place',
            'latitude': lat,
            'longitude': lon,
            'distance': const Distance().as(LengthUnit.Meter, location, LatLng(lat, lon)).round(),
          };
        }).toList();
      }
      return [];
    } catch (e) {
      debugPrint("Error fetching POIs: $e");
      return [];
    }
  }
  
  /// Get readable summary of nearby places
  Future<String> getNearbySummary(LatLng location) async {
    final pois = await getNearbyPOIs(location);
    if (pois.isEmpty) {
      return "I couldn't find any points of interest nearby.";
    }
    
    // Group by type
    final counts = <String, int>{};
    for (var poi in pois) {
      final type = poi['type'].toString().replaceAll('_', ' ');
      counts[type] = (counts[type] ?? 0) + 1;
    }
    
    // Sort by count
    final sortedKeys = counts.keys.toList()
      ..sort((a, b) => counts[b]!.compareTo(counts[a]!));
      
    // Construct sentence
    final parts = <String>[];
    for (var key in sortedKeys.take(3)) {
      final count = counts[key]!;
      parts.add("$count $key${count > 1 ? 's' : ''}");
    }
    
    String summary = "Nearby, there are ${parts.join(', ')}.";
    
    // Add closest POI details
    pois.sort((a, b) => (a['distance'] as int).compareTo(b['distance'] as int));
    if (pois.isNotEmpty) {
      final closest = pois.first;
      summary += " The closest is ${closest['name']}, ${closest['distance']} meters away.";
    }
    
    return summary;
  }
}
