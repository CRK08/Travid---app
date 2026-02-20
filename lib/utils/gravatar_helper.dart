import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';

/// Helper class for fetching profile photos from Gravatar
/// Gravatar is a free service that provides profile photos based on email addresses
class GravatarHelper {
  static final Dio _dio = Dio();

  /// Get Gravatar URL from email
  /// 
  /// Example:
  /// ```dart
  /// final url = GravatarHelper.getGravatarUrl('user@example.com');
  /// // Returns: https://www.gravatar.com/avatar/{hash}?s=200&d=404
  /// ```
  static String getGravatarUrl(String email, {int size = 200}) {
    final hash = md5.convert(utf8.encode(email.trim().toLowerCase())).toString();
    return 'https://www.gravatar.com/avatar/$hash?s=$size&d=404';
  }

  /// Check if Gravatar exists for email
  /// 
  /// Returns `true` if a Gravatar profile photo exists, `false` otherwise
  static Future<bool> hasGravatar(String email) async {
    try {
      final url = getGravatarUrl(email);
      final response = await _dio.head(url);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Download Gravatar and return bytes
  /// 
  /// Returns image bytes if successful, `null` otherwise
  static Future<List<int>?> downloadGravatar(String email) async {
    try {
      final url = getGravatarUrl(email);
      final response = await _dio.get<List<int>>(
        url,
        options: Options(responseType: ResponseType.bytes),
      );
      return response.data;
    } catch (e) {
      debugPrint('Failed to download Gravatar: $e');
      return null;
    }
  }
}
