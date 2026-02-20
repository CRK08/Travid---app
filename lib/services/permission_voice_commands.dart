import 'package:travid/services/global_ai_service.dart';
import 'package:travid/services/permission_service.dart';
import 'package:permission_handler/permission_handler.dart';

/// Extension to add permission voice commands to GlobalAIService
class PermissionVoiceCommands {
  final GlobalAIService _aiService;
  final PermissionService _permissionService = PermissionService();

  PermissionVoiceCommands(this._aiService);

  /// Register all permission-related voice commands
  void registerCommands() {
    // Location permission
    _aiService.registerCommand("enable location", (_) => _handleLocationPermission());
    _aiService.registerCommand("allow location", (_) => _handleLocationPermission());
    _aiService.registerCommand("grant location", (_) => _handleLocationPermission());
    
    // Microphone permission
    _aiService.registerCommand("enable microphone", (_) => _handleMicrophonePermission());
    _aiService.registerCommand("allow microphone", (_) => _handleMicrophonePermission());
    _aiService.registerCommand("grant microphone", (_) => _handleMicrophonePermission());
    
    // Camera permission
    _aiService.registerCommand("enable camera", (_) => _handleCameraPermission());
    _aiService.registerCommand("allow camera", (_) => _handleCameraPermission());
    _aiService.registerCommand("grant camera", (_) => _handleCameraPermission());
    
    // Storage permission
    _aiService.registerCommand("enable storage", (_) => _handleStoragePermission());
    _aiService.registerCommand("allow storage", (_) => _handleStoragePermission());
    
    // Open settings
    _aiService.registerCommand("open settings", (_) => _handleOpenSettings());
    _aiService.registerCommand("app settings", (_) => _handleOpenSettings());
    _aiService.registerCommand("permission settings", (_) => _handleOpenSettings());
    
    // Check permissions
    _aiService.registerCommand("check permissions", (_) => _handleCheckPermissions());
    _aiService.registerCommand("permission status", (_) => _handleCheckPermissions());
  }

  /// Unregister all permission commands
  void unregisterCommands() {
    _aiService.unregisterCommand("enable location");
    _aiService.unregisterCommand("allow location");
    _aiService.unregisterCommand("grant location");
    _aiService.unregisterCommand("enable microphone");
    _aiService.unregisterCommand("allow microphone");
    _aiService.unregisterCommand("grant microphone");
    _aiService.unregisterCommand("enable camera");
    _aiService.unregisterCommand("allow camera");
    _aiService.unregisterCommand("grant camera");
    _aiService.unregisterCommand("enable storage");
    _aiService.unregisterCommand("allow storage");
    _aiService.unregisterCommand("open settings");
    _aiService.unregisterCommand("app settings");
    _aiService.unregisterCommand("permission settings");
    _aiService.unregisterCommand("check permissions");
    _aiService.unregisterCommand("permission status");
  }

  Future<void> _handleLocationPermission() async {
    await _handlePermissionRequest(Permission.location, "Location");
  }

  Future<void> _handleMicrophonePermission() async {
    await _handlePermissionRequest(Permission.microphone, "Microphone");
  }

  Future<void> _handleCameraPermission() async {
    await _handlePermissionRequest(Permission.camera, "Camera");
  }

  Future<void> _handleStoragePermission() async {
    await _handlePermissionRequest(Permission.storage, "Storage");
  }

  Future<void> _handlePermissionRequest(Permission permission, String name) async {
    _aiService.speak("Checking $name permission...");
    
    final status = await permission.status;
    
    if (status.isGranted) {
      _aiService.speak("$name permission is already granted.");
      return;
    }
    
    if (status.isPermanentlyDenied) {
      _aiService.speak(
        "$name permission is permanently denied. "
        "Opening settings where you can enable it manually."
      );
      await _permissionService.openSettings();
      return;
    }
    
    // Request permission
    _aiService.speak("Requesting $name permission...");
    final newStatus = await permission.request();
    
    if (newStatus.isGranted) {
      _aiService.speak("$name permission granted. Thank you!");
    } else if (newStatus.isPermanentlyDenied) {
      _aiService.speak(
        "$name permission denied. "
        "You can enable it later in app settings."
      );
    } else {
      _aiService.speak("$name permission was not granted.");
    }
  }

  Future<void> _handleOpenSettings() async {
    _aiService.speak("Opening app settings...");
    final opened = await _permissionService.openSettings();
    
    if (!opened) {
      _aiService.speak("Could not open settings. Please open it manually from your device settings.");
    }
  }

  Future<void> _handleCheckPermissions() async {
    _aiService.speak("Checking all permissions...");
    
    final statuses = await _permissionService.checkAllPermissions();
    final granted = <String>[];
    final denied = <String>[];
    
    statuses.forEach((permission, status) {
      final name = _permissionService.getPermissionName(permission);
      if (status.isGranted) {
        granted.add(name);
      } else {
        denied.add(name);
      }
    });
    
    String message = "";
    
    if (granted.isNotEmpty) {
      message += "Granted permissions: ${granted.join(', ')}. ";
    }
    
    if (denied.isNotEmpty) {
      message += "Denied permissions: ${denied.join(', ')}. ";
      message += "Say 'enable' followed by the permission name to grant it.";
    } else {
      message += "All permissions are granted!";
    }
    
    _aiService.speak(message);
  }
}
