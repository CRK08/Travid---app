import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import '../../core/providers.dart';
import '../../core/app_translations.dart';
import '../../services/storage_service.dart';
import '../../services/local_profile_service.dart';

/// Edit Profile Screen
/// Allows users to edit their profile information including avatar
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _storageService = StorageService();
  final _imagePicker = ImagePicker();
  final _localProfileService = LocalProfileService();


  bool _isLoading = false;
  bool _isSaving = false;
  File? _selectedImage;
  String? _currentPhotoURL;



  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);

    // Load from Local Storage first
    final localData = await _localProfileService.loadProfile();
    final user = ref.read(currentUserProvider).value;

    if (localData['name'] != null) {
      _nameController.text = localData['name']!;
    } else if (user?.displayName != null) {
      _nameController.text = user!.displayName;
    }

    if (localData['email'] != null) {
      _emailController.text = localData['email']!;
    } else if (user?.email != null) {
      _emailController.text = user!.email;
    }

    if (localData['photoUrl'] != null) {
      _currentPhotoURL = localData['photoUrl'];
    } else if (user?.photoURL != null) {
      _currentPhotoURL = user!.photoURL;
    }

    if (user != null) {
      if (user.phoneNumber != null) {
        // Simple display of phone number
        _phoneController.text = user.phoneNumber!; 
      }
    }

    setState(() => _isLoading = false);
  }

  Future<void> _pickImage(ImageSource source) async {
    final settings = ref.read(settingsProvider);
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        // Crop the image
        final croppedFile = await ImageCropper().cropImage(
          sourcePath: pickedFile.path,
          aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: AppTranslations.get('edit_profile_title', settings.language), // Reusing 'Edit Profile' as crop title? Close enough.
              toolbarColor: Theme.of(context).primaryColor,
              toolbarWidgetColor: Colors.white,
              initAspectRatio: CropAspectRatioPreset.square,
              lockAspectRatio: true,
            ),
            IOSUiSettings(
              title: AppTranslations.get('edit_profile_title', settings.language),
              aspectRatioLockEnabled: true,
            ),
          ],
        );

        if (croppedFile != null) {
          setState(() {
            _selectedImage = File(croppedFile.path);
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppTranslations.get('pick_image_error', settings.language)}: $e')),
        );
      }
    }
  }

  Future<void> _showImageSourceDialog() async {
    final settings = ref.read(settingsProvider);
    String t(String key) => AppTranslations.get(key, settings.language);

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: Text(t('take_photo')),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(t('choose_gallery')),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            if (_currentPhotoURL != null || _selectedImage != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: Text(t('remove_photo'), style: const TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _selectedImage = null;
                    _currentPhotoURL = null;
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    
    final settings = ref.read(settingsProvider);
    setState(() => _isSaving = true);

    try {
      final authService = ref.read(authServiceProvider);
      String? newPhotoURL = _currentPhotoURL;

      // Upload new avatar if selected
      if (_selectedImage != null) {
        // Save image locally instead of uploading
        newPhotoURL = await _storageService.saveImageLocally(_selectedImage!);
      }

      // Update profile
      // 1. Update Firebase Auth (displayName only, not photoURL since it's local)
      await authService.updateUserProfile(
        displayName: _nameController.text.trim(),
        // photoURL: newPhotoURL, // Don't sync local path to Firebase
      );

      // 2. Save to Local Storage
      await _localProfileService.saveProfile(
        name: _nameController.text.trim(),
        photoUrl: newPhotoURL,
        email: _emailController.text.isNotEmpty ? _emailController.text : null,
        phone: _phoneController.text.isNotEmpty ? _phoneController.text : null,
      );

      // CRITICAL FIX: Force provider refresh to ensure UI updates
      ref.invalidate(currentUserProvider);

      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppTranslations.get('profile_updated', settings.language)),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppTranslations.get('profile_update_error', settings.language)}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(currentUserProvider, (previous, next) {
      final user = next.value;
      if (user != null) {
        if (_emailController.text.isEmpty) {
          _emailController.text = user.email;
          _localProfileService.saveProfile(email: user.email);
        }
        if (_phoneController.text.isEmpty && user.phoneNumber != null) {
          _phoneController.text = user.phoneNumber!;
          _localProfileService.saveProfile(phone: user.phoneNumber);
        }
        if (_nameController.text.isEmpty) {
           _nameController.text = user.displayName;
        }
      }
    });

    final theme = Theme.of(context);
    final settings = ref.watch(settingsProvider);
    String t(String key) => AppTranslations.get(key, settings.language);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(t('edit_profile_title'))),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(t('edit_profile_title')),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Avatar
                GestureDetector(
                  onTap: _showImageSourceDialog,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: theme.primaryColor.withValues(alpha: 0.1),
                        backgroundImage: _selectedImage != null
                            ? FileImage(_selectedImage!)
                            : (_currentPhotoURL != null
                                ? (_currentPhotoURL!.startsWith('http') 
                                    ? NetworkImage(_currentPhotoURL!) 
                                    : FileImage(File(_currentPhotoURL!)))
                                : null) as ImageProvider?,
                        child: _selectedImage == null && _currentPhotoURL == null
                            ? Icon(
                                Icons.person,
                                size: 60,
                                color: theme.primaryColor,
                              )
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: theme.primaryColor,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            size: 20,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  t('change_photo'),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 32),

                // Name Field
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: t('full_name'),
                    prefixIcon: const Icon(Icons.person_outline),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your name'; // Leaving English for validation now
                    }
                    if (value.length < 3) {
                      return 'Name must be at least 3 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Email Field (Read-only)
                TextFormField(
                  controller: _emailController,
                  enabled: false,
                  decoration: InputDecoration(
                    labelText: t('email'),
                    prefixIcon: const Icon(Icons.email_outlined),
                    suffixIcon: Icon(Icons.lock, color: Colors.grey.shade400),
                    helperText: 'Email cannot be changed', // Keeping English
                  ),
                ),
                const SizedBox(height: 16),

                // Phone Number Field (Read-only)
                TextFormField(
                  controller: _phoneController,
                  enabled: false,
                  decoration: InputDecoration(
                    labelText: t('phone'),
                    prefixIcon: const Icon(Icons.phone),
                    suffixIcon: Icon(Icons.lock, color: Colors.grey.shade400),
                    helperText: 'Phone number cannot be changed here', // Keeping English
                  ),
                ),
                const SizedBox(height: 32),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _handleSave,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(t('save_changes')),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
