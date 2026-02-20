import 'package:equatable/equatable.dart';

/// User model representing a Travid user
class UserModel extends Equatable {
  final String uid;
  final String email;
  final String displayName;
  final String? photoURL;
  final String? phoneNumber;  // E.164 format (e.g., +919876543210)
  final String? countryCode;  // Country code (e.g., "+91")
  final bool isEmailVerified;
  final bool isPhoneVerified;
  final List<String> favoriteRoutes;
  final DateTime createdAt;
  final DateTime? lastLoginAt;

  const UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoURL,
    this.phoneNumber,
    this.countryCode,
    this.isEmailVerified = false,
    this.isPhoneVerified = false,
    this.favoriteRoutes = const [],
    required this.createdAt,
    this.lastLoginAt,
  });

  /// Create UserModel from Firestore document
  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      email: map['email'] as String? ?? '',
      displayName: map['displayName'] as String? ?? 'User',
      photoURL: map['photoURL'] as String?,
      phoneNumber: map['phoneNumber'] as String?,
      countryCode: map['countryCode'] as String?,
      isEmailVerified: map['isEmailVerified'] as bool? ?? false,
      isPhoneVerified: map['isPhoneVerified'] as bool? ?? false,
      favoriteRoutes: List<String>.from(map['favoriteRoutes'] ?? []),
      createdAt: DateTime.parse(map['createdAt'] as String),
      lastLoginAt: map['lastLoginAt'] != null
          ? DateTime.parse(map['lastLoginAt'] as String)
          : null,
    );
  }

  /// Convert UserModel to Firestore document
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'phoneNumber': phoneNumber,
      'countryCode': countryCode,
      'isEmailVerified': isEmailVerified,
      'isPhoneVerified': isPhoneVerified,
      'favoriteRoutes': favoriteRoutes,
      'createdAt': createdAt.toIso8601String(),
      'lastLoginAt': lastLoginAt?.toIso8601String(),
    };
  }

  /// Create a copy with updated fields
  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoURL,
    String? phoneNumber,
    String? countryCode,
    bool? isEmailVerified,
    bool? isPhoneVerified,
    List<String>? favoriteRoutes,
    DateTime? createdAt,
    DateTime? lastLoginAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      countryCode: countryCode ?? this.countryCode,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      isPhoneVerified: isPhoneVerified ?? this.isPhoneVerified,
      favoriteRoutes: favoriteRoutes ?? this.favoriteRoutes,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }

  /// Validate email format
  static bool isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  /// Validate phone number format (basic validation)
  static bool isValidPhoneNumber(String phone) {
    // Remove all non-digit characters
    final digitsOnly = phone.replaceAll(RegExp(r'\D'), '');
    // Phone number should have 10-15 digits
    return digitsOnly.length >= 10 && digitsOnly.length <= 15;
  }

  @override
  List<Object?> get props => [
        uid,
        email,
        displayName,
        photoURL,
        phoneNumber,
        countryCode,
        isEmailVerified,
        isPhoneVerified,
        favoriteRoutes,
        createdAt,
        lastLoginAt,
      ];

  @override
  String toString() {
    return 'UserModel(uid: $uid, email: $email, displayName: $displayName, phone: $phoneNumber)';
  }
}
