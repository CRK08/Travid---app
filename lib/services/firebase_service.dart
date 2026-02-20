import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

/// Firebase Service - Handles Firebase initialization
class FirebaseService {
  static FirebaseService? _instance;
  static FirebaseService get instance => _instance ??= FirebaseService._();
  
  FirebaseService._();

  bool _initialized = false;
  bool get isInitialized => _initialized;

  /// Initialize Firebase
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _initialized = true;
      debugPrint('✅ Firebase initialized successfully');
    } catch (e) {
      debugPrint('❌ Firebase initialization failed: $e');
      rethrow;
    }
  }
}
