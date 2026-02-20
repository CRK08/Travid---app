import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

/// Map theme options for tile layers
enum MapTheme {
  standard,   // OpenStreetMap standard
  satellite,  // Satellite imagery
  dark,       // Dark mode tiles
  terrain,    // Terrain/topographic
}

/// Route preferences for navigation
class RoutePreferences {
  final RouteMode mode;
  final RouteType type;
  final bool avoidHighways;
  final bool avoidTolls;
  final List<LatLng> waypoints;

  const RoutePreferences({
    this.mode = RouteMode.driving,
    this.type = RouteType.fastest,
    this.avoidHighways = false,
    this.avoidTolls = false,
    this.waypoints = const [],
  });

  RoutePreferences copyWith({
    RouteMode? mode,
    RouteType? type,
    bool? avoidHighways,
    bool? avoidTolls,
    List<LatLng>? waypoints,
  }) {
    return RoutePreferences(
      mode: mode ?? this.mode,
      type: type ?? this.type,
      avoidHighways: avoidHighways ?? this.avoidHighways,
      avoidTolls: avoidTolls ?? this.avoidTolls,
      waypoints: waypoints ?? this.waypoints,
    );
  }
}

/// Route mode (transport type)
enum RouteMode {
  walking,
  driving,
  cycling,
  transit,
}

/// Route type (optimization preference)
enum RouteType {
  fastest,   // Minimize time
  shortest,  // Minimize distance
  scenic,    // Prefer scenic routes
}

/// Real-time navigation information
class NavigationInfo {
  final Duration estimatedTime;
  final Duration remainingTime;
  final double totalDistanceKm;
  final double remainingDistanceKm;
  final String? nextInstruction;
  final int? distanceToNextTurnMeters;
  final String? currentRoadName;
  final DateTime? estimatedArrival;

  const NavigationInfo({
    required this.estimatedTime,
    required this.remainingTime,
    required this.totalDistanceKm,
    required this.remainingDistanceKm,
    this.nextInstruction,
    this.distanceToNextTurnMeters,
    this.currentRoadName,
    this.estimatedArrival,
  });

  /// Format remaining time as "5 min" or "1h 23min"
  String get formattedRemainingTime {
    final hours = remainingTime.inHours;
    final minutes = remainingTime.inMinutes % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}min';
    }
    return '${minutes}min';
  }

  /// Format remaining distance as "1.2 km" or "350 m"
  String get formattedRemainingDistance {
    if (remainingDistanceKm < 1) {
      return '${(remainingDistanceKm * 1000).round()} m';
    }
    return '${remainingDistanceKm.toStringAsFixed(1)} km';
  }

  /// Format ETA as "10:45 AM"
  String get formattedETA {
    if (estimatedArrival == null) return '';
    final hour = estimatedArrival!.hour;
    final minute = estimatedArrival!.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }

  NavigationInfo copyWith({
    Duration? estimatedTime,
    Duration? remainingTime,
    double? totalDistanceKm,
    double? remainingDistanceKm,
    String? nextInstruction,
    int? distanceToNextTurnMeters,
    String? currentRoadName,
    DateTime? estimatedArrival,
  }) {
    return NavigationInfo(
      estimatedTime: estimatedTime ?? this.estimatedTime,
      remainingTime: remainingTime ?? this.remainingTime,
      totalDistanceKm: totalDistanceKm ?? this.totalDistanceKm,
      remainingDistanceKm: remainingDistanceKm ?? this.remainingDistanceKm,
      nextInstruction: nextInstruction ?? this.nextInstruction,
      distanceToNextTurnMeters: distanceToNextTurnMeters ?? this.distanceToNextTurnMeters,
      currentRoadName: currentRoadName ?? this.currentRoadName,
      estimatedArrival: estimatedArrival ?? this.estimatedArrival,
    );
  }
}

/// Helper class for map theme URLs
class MapThemeHelper {
  static String getTileUrl(MapTheme theme) {
    switch (theme) {
      case MapTheme.standard:
        return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
      
      case MapTheme.satellite:
        // Using ESRI World Imagery
        return 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';
      
      case MapTheme.dark:
        // Using Stadia Maps dark theme
        return 'https://tiles.stadiamaps.com/tiles/alidade_smooth_dark/{z}/{x}/{y}.png';
      
      case MapTheme.terrain:
        // Using OpenTopoMap
        return 'https://tile.opentopomap.org/{z}/{x}/{y}.png';
    }
  }

  static String getThemeName(MapTheme theme) {
    switch (theme) {
      case MapTheme.standard:
        return 'Standard';
      case MapTheme.satellite:
        return 'Satellite';
      case MapTheme.dark:
        return 'Dark';
      case MapTheme.terrain:
        return 'Terrain';
    }
  }

  static IconData getThemeIcon(MapTheme theme) {
    switch (theme) {
      case MapTheme.standard:
        return Icons.map;
      case MapTheme.satellite:
        return Icons.satellite_alt;
      case MapTheme.dark:
        return Icons.dark_mode;
      case MapTheme.terrain:
        return Icons.terrain;
    }
  }
}
