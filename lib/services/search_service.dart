import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';

class SearchService {
  final Dio _dio = Dio();
  static const String _baseUrl = 'https://nominatim.openstreetmap.org/search';

  /// Search for places matching query
  Future<List<Map<String, dynamic>>> searchPlaces(String query) async {
    if (query.trim().isEmpty) return [];

    try {
      final response = await _dio.get(
        _baseUrl,
        queryParameters: {
          'q': query,
          'format': 'json',
          'addressdetails': '1',
          'limit': '5',
        },
        options: Options(
          headers: {
            'User-Agent': 'TravidApp/1.0', // Required by OSM
          },
        ),
      );

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(response.data);
      }
      return [];
    } catch (e) {
      debugPrint("Search error: $e");
      return [];
    }
  }
}
