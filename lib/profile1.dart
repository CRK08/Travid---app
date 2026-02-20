import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travid/core/providers.dart';
import 'package:travid/models/app_settings.dart';
import 'features/settings/edit_profile_screen.dart';

import 'dart:io';
import 'package:travid/services/local_profile_service.dart';
import 'package:travid/core/app_translations.dart'; 

class ProfilePage extends ConsumerStatefulWidget {
  final ValueNotifier<String?> voiceNotifier;
  const ProfilePage({super.key, required this.voiceNotifier});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  // Account (Local state for text fields)
  final _nameCtl = TextEditingController();
  final _emailCtl = TextEditingController();
  String? _currentPhotoURL;
  String? _displayName;
  String? _email;
  bool _isLoading = true;
  final _localProfileService = LocalProfileService();
  
  @override
  void initState() {
    super.initState();
    widget.voiceNotifier.addListener(_onVoiceCommand);
    _loadUserData();
  }

  void _onVoiceCommand() {
    final raw = widget.voiceNotifier.value;
    if (raw == null || raw.isEmpty) return;
    final cmd = raw.toLowerCase().trim();

    if (cmd.contains('logout')) {
      _logout();
    }
  }
  Future<void> _loadUserData() async {
    // 1. Load from Local Storage
    final localData = await _localProfileService.loadProfile();
    
    // 2. Load from Firebase Auth (as fallback or sync source)
    final user = ref.read(currentUserProvider).value;

    if (localData['name'] != null) {
      _displayName = localData['name'];
      _nameCtl.text = localData['name']!;
    } else if (user?.displayName != null) {
      _displayName = user!.displayName;
      _nameCtl.text = user.displayName;
      // Sync to local
      await _localProfileService.saveProfile(name: user.displayName);
    }

    if (localData['email'] != null) {
      _email = localData['email'];
      _emailCtl.text = localData['email']!;
    } else if (user?.email != null) {
      _email = user!.email;
      _emailCtl.text = user.email;
      await _localProfileService.saveProfile(email: user.email);
    }
    
    if (localData['photoUrl'] != null) {
      _currentPhotoURL = localData['photoUrl'];
    } else if (user?.photoURL != null) {
      _currentPhotoURL = user!.photoURL;
    }
    
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
     final settings = ref.read(settingsProvider);
     String t(String key) => AppTranslations.get(key, settings.language);
    try {
      await _localProfileService.clearProfile();
      await ref.read(authServiceProvider).signOut();
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t('logout'))));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  void dispose() {
    widget.voiceNotifier.removeListener(_onVoiceCommand);
    _nameCtl.dispose();
    _emailCtl.dispose();
    super.dispose();
  }

  void _updateSettings(AppSettings newSettings) {
    ref.read(settingsProvider.notifier).updateSettings(newSettings);
  }
  
  Future<void> _editName() async {
    final settings = ref.read(settingsProvider);
    String t(String key) => AppTranslations.get(key, settings.language);
    
    final controller = TextEditingController(text: _nameCtl.text);
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t('edit_name')),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(labelText: t('full_name')),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(t('cancel'))),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                try {
                  Navigator.pop(context);
                  await ref.read(authServiceProvider).updateUserProfile(displayName: controller.text.trim());
                  _nameCtl.text = controller.text.trim();
                  setState(() {});
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t('name_updated'))));
                  }
                } catch (e) {
                   if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t('error') + ": $e")));
                  }
                }
              }
            }, 
            child: Text(t('save'))
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = ref.watch(settingsProvider);
    final user = ref.watch(currentUserProvider).value;
    String t(String key) => AppTranslations.get(key, settings.language);
    
    // Ensure controllers are in sync if user updates elsewhere
    if (user != null && _nameCtl.text != user.displayName) {
       _nameCtl.text = user.displayName;
    }
    
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Header
          SliverAppBar(
            expandedHeight: 220,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [theme.primaryColor, theme.colorScheme.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.white,
                            child: CircleAvatar(
                              radius: 46,
                              backgroundColor: Colors.grey.shade200,
                              backgroundImage: _currentPhotoURL != null
                                  ? (_currentPhotoURL!.startsWith('http')
                                      ? NetworkImage(_currentPhotoURL!)
                                      : FileImage(File(_currentPhotoURL!))) as ImageProvider
                                  : null,
                              child: _currentPhotoURL == null 
                                  ? Text((user?.displayName != null && user!.displayName.isNotEmpty) ? user.displayName.substring(0, 1).toUpperCase() : "U", style: const TextStyle(fontSize: 32)) 
                                  : null,
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const EditProfileScreen(),
                                  ),
                                );
                                _loadUserData();
                              },
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                                child: Icon(Icons.edit, size: 20, color: theme.primaryColor),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _displayName ?? user?.displayName ?? "User",
                        style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        _email ?? user?.email ?? "user@example.com",
                        style: const TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                   // Edit Profile Button
                   Padding(
                     padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                     child: ElevatedButton.icon(
                       onPressed: () {
                         Navigator.push(
                           context,
                           MaterialPageRoute(
                             builder: (context) => const EditProfileScreen(),
                           ),
                         );
                       },
                       icon: const Icon(Icons.edit),
                       label: Text(t('edit_profile')),
                       style: ElevatedButton.styleFrom(
                         minimumSize: const Size(double.infinity, 48),
                       ),
                     ),
                   ),
                   
                   const SizedBox(height: 16),
                   _buildSectionHeader(context, t('appearance')),
                   _buildCard(context, [
                     _buildSwitchTile(context, t('dark_mode'), settings.darkMode, (v) {
                       _updateSettings(settings.copyWith(darkMode: v));
                     }, Icons.dark_mode),
                     _buildDivider(),
                     ListTile(
                       leading: Icon(Icons.language, color: theme.primaryColor),
                       title: Text(t('language')),
                       trailing: DropdownButton<String>(
                         value: settings.language == 'ta' ? 'Tamil' : 'English',
                         underline: const SizedBox(),
                         dropdownColor: theme.cardColor,
                         borderRadius: BorderRadius.circular(12),
                         items: ['English', 'Tamil'].map((l) => DropdownMenuItem(value: l, child: Text(l == 'Tamil' ? 'தமிழ்' : l))).toList(),
                         onChanged: (v) {
                           if (v != null) {
                             _updateSettings(settings.copyWith(language: v == 'Tamil' ? 'ta' : 'en'));
                           }
                         },
                       ),
                     ),
                     _buildDivider(),
                     _buildSliderTile(context, t('text_size'), settings.textScale, 0.8, 1.5, (v) {
                        _updateSettings(settings.copyWith(textScale: v));
                     }, Icons.text_fields),
                   ]),

                   const SizedBox(height: 24),
                   _buildSectionHeader(context, t('voice_audio')),
                   _buildCard(context, [
                     _buildSliderTile(context, t('speech_rate'), settings.voiceSpeed, 0.5, 2.0, (v) {
                        _updateSettings(settings.copyWith(voiceSpeed: v));
                     }, Icons.speed),
                     _buildDivider(),
                     _buildSwitchTile(context, t('voice_enabled'), settings.voiceEnabled, (v) {
                        _updateSettings(settings.copyWith(voiceEnabled: v));
                     }, Icons.mic),
                      // NEW: Wake Word & Continuous Listening

                      if (settings.voiceEnabled) ...[
                        _buildDivider(),

                        _buildSwitchTile(context, "Tap to Speak", settings.tapToSpeakEnabled, (v) {
                           _updateSettings(settings.copyWith(tapToSpeakEnabled: v));
                        }, Icons.touch_app),

                      ],

                     _buildDivider(),
                     _buildSwitchTile(context, t('bus_alerts'), settings.busArrivalAlerts, (v) {
                        _updateSettings(settings.copyWith(busArrivalAlerts: v));
                     }, Icons.notifications_active),
                   ]),

                   const SizedBox(height: 24),
                   _buildSectionHeader(context, t('general')),
                   _buildCard(context, [
                     ListTile(
                       leading: const Icon(Icons.delete_outline, color: Colors.orange),
                       title: Text(t('clear_history')), 
                       onTap: () {
                         // Clear history logic could go here
                         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t('history_cleared'))));
                       },
                     ),
                     _buildDivider(),
                     ListTile(
                       leading: Icon(Icons.info_outline, color: theme.primaryColor),
                       title: Text(t('about')),
                       trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                       onTap: () {
                         showAboutDialog(
                           context: context,
                           applicationName: "Travid",
                           applicationVersion: "1.0.0",
                           applicationIcon: const Icon(Icons.directions_bus),
                           children: [const Text("Voice-Enabled Travel Assistant for the Visually Impaired.")], 
                         );
                       },
                     ),
                     _buildDivider(),
                     ListTile(
                       leading: const Icon(Icons.logout, color: Colors.red),
                       title: Text(t('logout'), style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                       onTap: _logout,
                     ),
                   ]),
                   const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSectionHeader(BuildContext context, String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade600,
        ),
      ),
    );
  }
  
  Widget _buildCard(BuildContext context, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
  
  Widget _buildDivider() {
    return const Divider(height: 1, indent: 16, endIndent: 16);
  }

  Widget _buildListTile(BuildContext context, String title, String value, IconData icon, {required VoidCallback onTap, bool showEditIcon = false}) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Theme.of(context).primaryColor),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(value, style: TextStyle(color: Colors.grey.shade600)),
      trailing: showEditIcon ? const Icon(Icons.edit, size: 16, color: Colors.grey) : const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      onTap: onTap,
    );
  }
  
  Widget _buildSwitchTile(BuildContext context, String title, bool value, Function(bool) onChanged, IconData icon) {
    return SwitchListTile(
      secondary: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Theme.of(context).primaryColor),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      value: value,
      onChanged: onChanged,
      activeThumbColor: Theme.of(context).primaryColor,
    );
  }
  
  Widget _buildSliderTile(BuildContext context, String title, double value, double min, double max, Function(double) onChanged, IconData icon) {
    return Column(
      children: [
        ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Theme.of(context).primaryColor),
          ),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
          trailing: Text(value.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: 10,
            label: value.toStringAsFixed(1),
            onChanged: onChanged,
            activeColor: Theme.of(context).primaryColor,
          ),
        ),
      ],
    );
  }
}

