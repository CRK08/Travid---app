// lib/home1.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travid/core/providers.dart';

// Import pages
import 'bus1.dart' as bus;
import 'map1.dart' as map_page;
import 'profile1.dart' as profile;
import 'features/chat/chat_page.dart';
import 'features/home/home_page.dart';
import 'services/global_ai_service.dart';

class TravidHome extends ConsumerStatefulWidget {
  const TravidHome({super.key});

  @override
  ConsumerState<TravidHome> createState() => _TravidHomeState();
}

class _TravidHomeState extends ConsumerState<TravidHome> {
  // Legacy notifier - kept for compatibility with page constructors
  final ValueNotifier<String?> voiceNotifier = ValueNotifier<String?>(null);

  @override
  void initState() {
    super.initState();
    // Start AI Service now that we are logged in/home
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settings = ref.read(settingsProvider);
      GlobalAIService().updateSettings(settings);
    });
    
    // Connect Global AI Voice to Legacy Notifier for pages
    GlobalAIService().addListener(_onVoiceUpdate);
  }

  void _onVoiceUpdate() {
    // Rebuild UI to update Blocking Layer state
    if (mounted) setState(() {});
    
    final text = GlobalAIService().lastRecognizedText;
    // Only update if text is new and not empty (simple debounce/dedupe)
    if (text.isNotEmpty && text != voiceNotifier.value) {
      voiceNotifier.value = text;
    }
  }

  @override
  void dispose() {
    GlobalAIService().removeListener(_onVoiceUpdate);
    super.dispose();
  }

  int _selectedIndex = 0;

  List<Widget> buildPages() {
    return [
      const HomePage(),
      bus.BusPage(voiceNotifier: voiceNotifier),
      const ChatPage(),
      map_page.MapPage(voiceNotifier: voiceNotifier),
      profile.ProfilePage(voiceNotifier: voiceNotifier),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Listen to settings changes to update AI Service
    ref.listen(settingsProvider, (previous, next) {
      GlobalAIService().updateSettings(next);
    });

    // Determine current page
    final pages = buildPages();
    Widget currentPage = pages[_selectedIndex];
    
    final aiService = GlobalAIService();
    
    // User Request: "Profile and settings" should be EXCEPTIONS to blocking.
    // So we disable the overlay entirely if we are on the Profile tab (index 4).
    final isProfilePage = _selectedIndex == 4; 
    
    // Blocking is active if:
    // 1. AI is Speaking (Global block to prevent conflicts) - UNLESS on Profile? 
    //    User said "blocking should apply for profile" earlier but now says "exceptional".
    //    Interpretation: User wants to be able to change settings EVEN IF AI is speaking or listening.
    // 2. TapToSpeak is enabled - but we don't want to block buttons on Profile.
    
    // Revised Logic:
    // - If AI is Speaking: Block EVERYTHING (Strict Turn-Taking) EXCEPT Profile (so they can stop it/change settings).
    // - If TapToSpeak: Overlay captures background taps, but we want buttons to work. 
    //   Flutter's Stack+GestureDetector is "all or nothing" for touches below it if opaque.
    //   To support "Tap Background to Speak" but "Tap Button to Click", we can't easily use a global overlay.
    //   
    //   ALTERNATIVE: We only block when `isSpeaking`.
    //   For "Tap to Speak", we rely on the specific page to implement it, OR we accept that "Tap to Speak" blocks non-button areas?
    //   Actually, `HitTestBehavior.translucent` lets touches pass through IF they hit a child? No, Stack overlay sits on top.
    
    // REVISED LOGIC (User Request): 
    // The overlay should ONLY appear if "Tap to Speak" is explicitly ENABLED.
    // If "Tap to Speak" is OFF, we should NOT block the screen, even if AI is speaking.
    // This allows natural interaction in Chat/Map when not using the accessibility mode.
    
    // We still exempt Profile so they can turn it off if they get stuck.
    final isProfile = _selectedIndex == 4;
    
    final shouldBlock = aiService.tapToSpeakEnabled && !isProfile;

    return Scaffold(
      body: Stack(
        children: [
          // 1. Current Page Content
          currentPage,
          
          // 2. Accessibility / Blocking Layer
          if (shouldBlock)
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  // If speaking, allow Tap to Interrupt (Stop Speaking)
                  if (aiService.isSpeaking) {
                     debugPrint("🛑 Tap interrupt: Stopping AI");
                     aiService.stopSpeaking();
                     return;
                  }
                  
                  // Tap to Speak
                  if (aiService.tapToSpeakEnabled) {
                     debugPrint("👆 Tap detected: Starting Listening");
                     aiService.quickVoiceQuery();
                  }
                },
                child: Container(
                  // VISUALS: Show distinct background for Speaking OR Listening
                  color: (aiService.isSpeaking || aiService.isListening)
                      ? Colors.black.withValues(alpha: 0.6) // Darker for better visibility
                      : Colors.transparent, // Invisible for Tap Area waiting
                  child: Center(
                    child: aiService.isSpeaking 
                      ? const Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.record_voice_over, size: 64, color: Colors.blueAccent),
                            SizedBox(height: 16),
                            Text(
                              "AI Speaking...",
                              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            Text("Tap to interrupt", style: TextStyle(color: Colors.white70, fontSize: 14)),
                          ],
                        )
                      : aiService.isListening
                          ? const Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.mic, size: 64, color: Colors.redAccent),
                                SizedBox(height: 16),
                                Text(
                                  "Listening...",
                                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                                ),
                              ],
                            )
                          : null, // Nothing if just waiting for tap
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.directions_bus),
            label: 'Bus',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble),
            label: 'Assistant',
          ),
          NavigationDestination(
            icon: Icon(Icons.map),
            label: 'Map',
          ),
          NavigationDestination(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
