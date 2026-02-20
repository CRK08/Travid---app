import 'package:shared_preferences/shared_preferences.dart';

class LocalProfileService {
  static const String _keyName = 'user_display_name';
  static const String _keyEmail = 'user_email';
  static const String _keyPhone = 'user_phone';
  static const String _keyPhotoUrl = 'user_photo_url';

  Future<void> saveProfile({String? name, String? email, String? phone, String? photoUrl}) async {
    final prefs = await SharedPreferences.getInstance();
    if (name != null) await prefs.setString(_keyName, name);
    if (email != null) await prefs.setString(_keyEmail, email);
    if (phone != null) await prefs.setString(_keyPhone, phone);
    if (photoUrl != null) await prefs.setString(_keyPhotoUrl, photoUrl);
  }

  Future<Map<String, String?>> loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'name': prefs.getString(_keyName),
      'email': prefs.getString(_keyEmail),
      'phone': prefs.getString(_keyPhone),
      'photoUrl': prefs.getString(_keyPhotoUrl),
    };
  }

  Future<void> clearProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyName);
    await prefs.remove(_keyEmail);
    await prefs.remove(_keyPhone);
    await prefs.remove(_keyPhotoUrl);
  }
}
