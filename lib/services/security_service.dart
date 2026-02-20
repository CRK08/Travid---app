import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecurityService extends ChangeNotifier {
  static final SecurityService _instance = SecurityService._internal();
  factory SecurityService() => _instance;
  SecurityService._internal();

  static const String _prefPin = 'app_pin';
  static const String _prefSecurityEnabled = 'app_security_enabled';

  late SharedPreferences _prefs;
  bool _isInitialized = false;
  bool _isAuthenticated = false;

  bool get isAuthenticated => _isAuthenticated;
  bool get isSecurityEnabled => _prefs.getBool(_prefSecurityEnabled) ?? false;
  bool get hasPin => _prefs.getString(_prefPin) != null;

  Future<void> initialize() async {
    if (_isInitialized) return;
    _prefs = await SharedPreferences.getInstance();
    _isInitialized = true;
    
    // If security is not enabled or no PIN, we are authenticated by default
    if (!isSecurityEnabled || !hasPin) {
      _isAuthenticated = true;
    } else {
      _isAuthenticated = false; // Require login
    }
    notifyListeners();
  }

  /// Set a new PIN
  Future<void> setPin(String pin) async {
    await _prefs.setString(_prefPin, pin);
    await _prefs.setBool(_prefSecurityEnabled, true);
    _isAuthenticated = true;
    notifyListeners();
  }

  /// Verify entered PIN
  bool verifyPin(String enteredPin) {
    final storedPin = _prefs.getString(_prefPin);
    if (storedPin == enteredPin) {
      _isAuthenticated = true;
      notifyListeners();
      return true;
    }
    return false;
  }

  /// Disable security
  Future<void> disableSecurity() async {
    await _prefs.setBool(_prefSecurityEnabled, false);
    _isAuthenticated = true;
    notifyListeners();
  }
  
  /// Lock the app (require PIN again)
  void lockApp() {
    if (isSecurityEnabled) {
      _isAuthenticated = false;
      notifyListeners();
    }
  }
}
