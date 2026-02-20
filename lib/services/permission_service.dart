import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service to manage app permissions
class PermissionService {
  static const String _permissionsRequestedKey = 'permissions_requested';

  /// Check if permissions have been requested before
  Future<bool> hasRequestedPermissions() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_permissionsRequestedKey) ?? false;
  }

  /// Mark permissions as requested
  Future<void> markPermissionsRequested() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_permissionsRequestedKey, true);
  }

  /// Request all essential permissions on first launch
  Future<Map<Permission, PermissionStatus>> requestAllPermissions() async {
    final permissions = [
      Permission.location,
      Permission.microphone,
      Permission.camera,
      Permission.storage,
    ];

    final statuses = await permissions.request();
    await markPermissionsRequested();
    
    return statuses;
  }

  /// Check status of all permissions
  Future<Map<Permission, PermissionStatus>> checkAllPermissions() async {
    return {
      Permission.location: await Permission.location.status,
      Permission.microphone: await Permission.microphone.status,
      Permission.camera: await Permission.camera.status,
      Permission.storage: await Permission.storage.status,
    };
  }

  /// Request specific permission
  Future<PermissionStatus> requestPermission(Permission permission) async {
    return await permission.request();
  }

  /// Check if permission is granted
  Future<bool> isGranted(Permission permission) async {
    return await permission.isGranted;
  }

  /// Open app settings
  Future<bool> openSettings() async {
    return await openAppSettings();
  }

  /// Get permission name for voice feedback
  String getPermissionName(Permission permission) {
    if (permission == Permission.location) return 'Location';
    if (permission == Permission.microphone) return 'Microphone';
    if (permission == Permission.camera) return 'Camera';
    if (permission == Permission.storage) return 'Storage';
    return 'Unknown';
  }

  /// Get user-friendly status message
  String getStatusMessage(PermissionStatus status) {
    switch (status) {
      case PermissionStatus.granted:
        return 'granted';
      case PermissionStatus.denied:
        return 'denied';
      case PermissionStatus.permanentlyDenied:
        return 'permanently denied. Please enable it in settings';
      case PermissionStatus.restricted:
        return 'restricted';
      case PermissionStatus.limited:
        return 'limited';
      default:
        return 'unknown';
    }
  }

  /// Check if any critical permissions are missing
  Future<bool> hasCriticalPermissions() async {
    final location = await Permission.location.isGranted;
    final microphone = await Permission.microphone.isGranted;
    return location && microphone;
  }

  /// Get list of missing critical permissions
  Future<List<Permission>> getMissingCriticalPermissions() async {
    final missing = <Permission>[];
    
    if (!await Permission.location.isGranted) {
      missing.add(Permission.location);
    }
    if (!await Permission.microphone.isGranted) {
      missing.add(Permission.microphone);
    }
    
    return missing;
  }
}
