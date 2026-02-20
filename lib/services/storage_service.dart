import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// Service for handling file uploads to Firebase Storage
class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Upload user avatar to Firebase Storage
  /// Returns the download URL of the uploaded image
  Future<String> uploadAvatar(File imageFile) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw 'No user is currently signed in.';
      }

      // Validate file size (max 5MB)
      final fileSize = await imageFile.length();
      if (fileSize > 5 * 1024 * 1024) {
        throw 'Image size must be less than 5MB.';
      }

      // Create a reference to the file location
      final fileName = 'avatar_${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      debugPrint('Uploading to bucket: ${_storage.bucket}, path: avatars/$fileName');
      final ref = _storage.ref().child('avatars').child(fileName);

      // Upload the file
      final uploadTask = ref.putFile(
        imageFile,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {'userId': user.uid},
        ),
      );

      // Wait for upload to complete
      final snapshot = await uploadTask;

      // Get download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      throw 'Failed to upload avatar: $e';
    }
  }

  /// Delete user's old avatar
  Future<void> deleteAvatar(String avatarUrl) async {
    try {
      if (avatarUrl.isEmpty) return;
      
      // Only attempt to delete if it's a Firebase Storage URL
      if (!avatarUrl.contains('firebasestorage')) {
        debugPrint('Skipping delete for non-Firebase URL: $avatarUrl');
        return;
      }

      // Extract file path from URL
      final ref = _storage.refFromURL(avatarUrl);
      debugPrint('Deleting avatar: ${ref.fullPath}');
      await ref.delete();
    } catch (e) {
      // Silently fail - old avatar might already be deleted
      debugPrint('Failed to delete old avatar: $e');
    }
  }

  /// Upload any file to Firebase Storage
  Future<String> uploadFile({
    required File file,
    required String folder,
    String? customFileName,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw 'No user is currently signed in.';
      }

      final fileName = customFileName ?? 
          '${user.uid}_${DateTime.now().millisecondsSinceEpoch}';
      final ref = _storage.ref().child(folder).child(fileName);

      final uploadTask = ref.putFile(file);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      throw 'Failed to upload file: $e';
    }
  }

  /// Save image locally to app documents directory
  /// Returns the absolute path of the saved file
  Future<String> saveImageLocally(File imageFile) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = 'avatar_${DateTime.now().millisecondsSinceEpoch}${path.extension(imageFile.path)}';
      final savedImage = await imageFile.copy('${appDir.path}/$fileName');
      return savedImage.path;
    } catch (e) {
      throw 'Failed to save image locally: $e';
    }
  }
}
