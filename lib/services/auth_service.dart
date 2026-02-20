import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

/// Enhanced authentication service with phone auth, OTP, and email/password
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // For phone verification
  String? _verificationId;
  int? _resendToken;

  /// Get current user stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Get current user
  User? get currentUser => _auth.currentUser;

  /// Check if user is logged in
  bool get isLoggedIn => currentUser != null;

  // ==================== EMAIL/PASSWORD AUTHENTICATION ====================

  /// Sign in with email and password
  Future<UserModel?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        await _updateLastLogin(userCredential.user!.uid);
        return await getUserData(userCredential.user!.uid);
      }
      return null;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Sign in with phone number and password
  /// This checks if a user with this phone number exists and uses their email to login
  Future<UserModel?> signInWithPhone({
    required String phoneNumber,
    required String password,
  }) async {
    try {
      // Query Firestore to find user with this phone number
      final querySnapshot = await _firestore
          .collection('users')
          .where('phoneNumber', isEqualTo: phoneNumber)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        throw 'No user found with this phone number.';
      }

      final userDoc = querySnapshot.docs.first;
      final email = userDoc.data()['email'] as String;

      // Sign in with email and password
      return await signInWithEmail(email: email, password: password);
    } catch (e) {
      if (e is String) {
        rethrow;
      }
      throw 'Failed to sign in with phone number: $e';
    }
  }

  /// Register with email and password
  Future<UserModel?> registerWithEmail({
    required String email,
    required String password,
    required String displayName,
    String? phoneNumber,
    String? countryCode,
  }) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        // Update display name
        await userCredential.user!.updateDisplayName(displayName);

        // Create user document in Firestore
        final userModel = UserModel(
          uid: userCredential.user!.uid,
          email: email,
          displayName: displayName,
          phoneNumber: phoneNumber,
          countryCode: countryCode,
          isEmailVerified: userCredential.user!.emailVerified,
          isPhoneVerified: false,
          createdAt: DateTime.now(),
          lastLoginAt: DateTime.now(),
        );

        await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .set(userModel.toMap());

        return userModel;
      }
      return null;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // ==================== PHONE AUTHENTICATION ====================

  /// Send OTP to phone number
  Future<void> sendPhoneOTP({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(String error) onError,
    Function()? onAutoVerify,
  }) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-verification (Android only)
          await _auth.signInWithCredential(credential);
          if (onAutoVerify != null) onAutoVerify();
        },
        verificationFailed: (FirebaseAuthException e) {
          onError(_handleAuthException(e));
        },
        codeSent: (String verificationId, int? resendToken) {
          _verificationId = verificationId;
          _resendToken = resendToken;
          onCodeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
        forceResendingToken: _resendToken,
      );
    } catch (e) {
      onError('Failed to send OTP: $e');
    }
  }

  /// Verify phone OTP and link to current user
  Future<bool> verifyPhoneOTP({
    required String verificationId,
    required String otp,
  }) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otp,
      );

      // If user is already signed in, link the phone credential
      if (currentUser != null) {
        await currentUser!.linkWithCredential(credential);
        
        // Update Firestore
        await _firestore.collection('users').doc(currentUser!.uid).update({
          'isPhoneVerified': true,
        });
        
        return true;
      } else {
        // Sign in with phone credential
        await _auth.signInWithCredential(credential);
        return true;
      }
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }



  // ==================== EMAIL OTP VERIFICATION ====================

  /// Send email verification link
  Future<void> sendEmailVerification() async {
    try {
      final user = currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
      }
    } catch (e) {
      throw 'Failed to send email verification: $e';
    }
  }

  /// Check if email is verified and update Firestore
  Future<bool> checkEmailVerified() async {
    try {
      await currentUser?.reload();
      final user = _auth.currentUser;
      
      if (user != null && user.emailVerified) {
        // Update Firestore
        await _firestore.collection('users').doc(user.uid).update({
          'isEmailVerified': true,
        });
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // ==================== PASSWORD RESET ====================

  /// Reset password via email
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Reset password via phone OTP
  Future<void> resetPasswordWithPhone({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(String error) onError,
  }) async {
    await sendPhoneOTP(
      phoneNumber: phoneNumber,
      onCodeSent: onCodeSent,
      onError: onError,
    );
  }

  /// Update password after OTP verification
  Future<void> updatePassword(String newPassword) async {
    try {
      final user = currentUser;
      if (user != null) {
        await user.updatePassword(newPassword);
      } else {
        throw 'No user is currently signed in.';
      }
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // ==================== ANONYMOUS SIGN-IN ====================

  /// Sign in anonymously (for testing)
  Future<UserModel?> signInAnonymously() async {
    try {
      final userCredential = await _auth.signInAnonymously();

      if (userCredential.user != null) {
        final userModel = UserModel(
          uid: userCredential.user!.uid,
          email: 'anonymous@travid.app',
          displayName: 'Guest User',
          createdAt: DateTime.now(),
          lastLoginAt: DateTime.now(),
        );

        await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .set(userModel.toMap());

        return userModel;
      }
      return null;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // ==================== USER MANAGEMENT ====================

  /// Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Get user data from Firestore
  Future<UserModel?> getUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data()!, uid);
      }
      
      // If Firestore document doesn't exist, create UserModel from Firebase Auth
      final user = _auth.currentUser;
      if (user != null && user.uid == uid) {
        return UserModel(
          uid: user.uid,
          email: user.email ?? '',
          displayName: user.displayName ?? 'User',
          photoURL: user.photoURL,
          phoneNumber: user.phoneNumber,
          isEmailVerified: user.emailVerified,
          isPhoneVerified: false,
          createdAt: DateTime.now(),
          lastLoginAt: DateTime.now(),
        );
      }
      
      return null;
    } catch (e) {
      debugPrint('Error getting user data: $e');
      return null;
    }
  }

  /// Update user profile
  Future<void> updateUserProfile({
    String? displayName,
    String? photoURL,
    String? phoneNumber,
    String? countryCode,
  }) async {
    final user = currentUser;
    if (user == null) return;

    try {
      if (displayName != null) {
        await user.updateDisplayName(displayName);
      }
      if (photoURL != null) {
        await user.updatePhotoURL(photoURL);
      }

      // Update Firestore (use set with merge to create if doesn't exist)
      final updates = <String, dynamic>{};
      if (displayName != null) updates['displayName'] = displayName;
      if (photoURL != null) updates['photoURL'] = photoURL;
      if (phoneNumber != null) {
        updates['phoneNumber'] = phoneNumber;
        updates['isPhoneVerified'] = false; // Reset verification status
      }
      if (countryCode != null) updates['countryCode'] = countryCode;

      if (updates.isNotEmpty) {
        // Use set with merge: true to create document if it doesn't exist
        await _firestore.collection('users').doc(user.uid).set(
          {
            ...updates,
            'uid': user.uid,
            'email': user.email ?? '',
            'lastLoginAt': DateTime.now(),
          },
          SetOptions(merge: true),
        );
      }
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  /// Update Firebase Auth profile ONLY (No Firestore)
  Future<void> updateAuthProfileOnly({
    String? displayName,
    String? photoURL,
  }) async {
    final user = currentUser;
    if (user == null) return;

    try {
      if (displayName != null) {
        await user.updateDisplayName(displayName);
      }
      if (photoURL != null) {
        await user.updatePhotoURL(photoURL);
      }
      // Force reload to update listeners
      await user.reload();
    } catch (e) {
      throw Exception('Failed to update auth profile: $e');
    }
  }

  /// Update last login time
  Future<void> _updateLastLogin(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'lastLoginAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error updating last login: $e');
    }
  }

  // ==================== HELPER METHODS ====================

  /// Detect if input is email or phone number
  static bool isEmail(String input) {
    return input.contains('@');
  }

  /// Handle Firebase Auth exceptions
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'invalid-verification-code':
        return 'Invalid OTP code. Please try again.';
      case 'invalid-verification-id':
        return 'Verification session expired. Please request a new OTP.';
      case 'quota-exceeded':
        return 'SMS quota exceeded. Please try again later.';
      case 'credential-already-in-use':
        return 'This phone number is already linked to another account.';
      default:
        return 'Authentication failed: ${e.message}';
    }
  }
}
