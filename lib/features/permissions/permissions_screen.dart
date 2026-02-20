import 'package:flutter/material.dart';
import 'package:travid/services/permission_service.dart';
import 'package:travid/services/global_ai_service.dart';
import 'package:permission_handler/permission_handler.dart';

/// Screen to request permissions on first launch
class PermissionsScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const PermissionsScreen({super.key, required this.onComplete});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> {
  final PermissionService _permissionService = PermissionService();
  final GlobalAIService _aiService = GlobalAIService();
  
  bool _isRequesting = false;
  Map<Permission, PermissionStatus> _statuses = {};

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    _speakWelcome();
  }

  void _speakWelcome() {
    _aiService.speak(
      "Welcome to Travid! To provide you with the best experience, "
      "we need a few permissions. Tap Continue to grant permissions."
    );
  }

  Future<void> _checkPermissions() async {
    final statuses = await _permissionService.checkAllPermissions();
    setState(() => _statuses = statuses);
  }

  Future<void> _requestPermissions() async {
    setState(() => _isRequesting = true);
    
    _aiService.speak("Requesting permissions...");
    final statuses = await _permissionService.requestAllPermissions();
    
    setState(() {
      _statuses = statuses;
      _isRequesting = false;
    });

    // Check results
    final granted = statuses.values.where((s) => s.isGranted).length;
    final total = statuses.length;
    
    if (granted == total) {
      _aiService.speak("All permissions granted. You're all set!");
      await Future.delayed(const Duration(seconds: 2));
      widget.onComplete();
    } else {
      _aiService.speak("$granted out of $total permissions granted. You can continue, but some features may be limited.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              
              // Header
              const Icon(Icons.security, size: 80, color: Colors.blue),
              const SizedBox(height: 24),
              Text(
                'Permissions Required',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Travid needs these permissions to work properly',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 40),
              
              // Permission list
              Expanded(
                child: ListView(
                  children: [
                    _buildPermissionTile(
                      icon: Icons.location_on,
                      title: 'Location',
                      description: 'For navigation and finding nearby places',
                      permission: Permission.location,
                    ),
                    _buildPermissionTile(
                      icon: Icons.mic,
                      title: 'Microphone',
                      description: 'For voice commands and AI assistant',
                      permission: Permission.microphone,
                    ),
                    _buildPermissionTile(
                      icon: Icons.camera_alt,
                      title: 'Camera',
                      description: 'For profile photos',
                      permission: Permission.camera,
                    ),
                    _buildPermissionTile(
                      icon: Icons.folder,
                      title: 'Storage',
                      description: 'For saving data and images',
                      permission: Permission.storage,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Continue button
              ElevatedButton(
                onPressed: _isRequesting ? null : _requestPermissions,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: _isRequesting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Continue', style: TextStyle(fontSize: 16)),
              ),
              
              const SizedBox(height: 12),
              
              // Skip button
              TextButton(
                onPressed: _isRequesting ? null : widget.onComplete,
                child: const Text('Skip for now'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionTile({
    required IconData icon,
    required String title,
    required String description,
    required Permission permission,
  }) {
    final status = _statuses[permission];
    final isGranted = status?.isGranted ?? false;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isGranted ? Colors.green[100] : Colors.grey[200],
          child: Icon(
            icon,
            color: isGranted ? Colors.green : Colors.grey[600],
          ),
        ),
        title: Text(title),
        subtitle: Text(description, style: const TextStyle(fontSize: 12)),
        trailing: isGranted
            ? const Icon(Icons.check_circle, color: Colors.green)
            : const Icon(Icons.circle_outlined, color: Colors.grey),
      ),
    );
  }
}
