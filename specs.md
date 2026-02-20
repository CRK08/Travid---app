# Travid Specifications

## 1. Project Overview
Travid is an AI-powered, voice-controlled travel assistant designed for accessibility, specifically focusing on blind and visually impaired users. It provides intelligent route planning, real-time navigation, and proactive travel assistance through natural voice interaction.

## 2. Technical Specifications

### Tech Stack
- **Framework:** Flutter (Dart)
- **State Management:** Riverpod
- **Backend:** Firebase (Auth, Firestore, Analytics, Crashlytics, Storage)
- **AI Engine:** Google Gemini (models/gemini-2.5-flash) via `google_generative_ai`
- **Voice Stack:**
    - Speech-to-Text: `speech_to_text` (CSL)
    - Text-to-Speech: `flutter_tts`
    - Interaction: Tap-to-Speak
- **Maps & Navigation:**
    - `flutter_map` (OpenStreetMap)
    - `geolocator`
    - `geocoding`
    - `latlong2`
- **Local Storage:**
    - `shared_preferences` (Settings)
    - `hive` (Chat history - Migrating)
- **UI/UX:**
    - Material Design 3
    - Accessibility-first design (Haptic feedback, Audio cues)

### Key Dependencies
- `firebase_core`, `firebase_auth`, `cloud_firestore`
- `google_generative_ai`
- `speech_to_text`, `flutter_tts`
- `flutter_riverpod`, `go_router`
- `flutter_map`
- `vibration`, `audioplayers`

## 3. Features & Functional Requirements

### Voice & AI
- **Tap-to-Speak:** Manual activation via prominent microphone button.
- **Unified AI:** Single endpoint for chat, navigation, and system control.
- **Multi-language:** Support for English (US/IN), Tamil, and Tanglish.
- **Voice Customization:** Adjustable speed, pitch, and voice profiles.

### User Interface
- **Accessibility Mode:** High contrast, large touch targets, screen reader compatibility.
- **Visual Feedback:** Pulsing voice indicators, minimal text for blind users.
- **Theme:** Dynamic light/dark mode based on system systems.

### Navigation
- **Route Planning:** Bus and walk routes.
- **Location Awareness:** "Where am I?", "What's around me?".

### Security
- **Authentication:** Email/Password, Anonymous login.
- **Privacy:** Local storage for sensitive settings.

## 4. Control Flow & Architecture

### Application Lifecycle
1. **Splash Screen:**
   - Checks permissions (Microphone, Location).
   - Initializes Firebase & AI services.
   - Navigates to `HomeScreen` or `PermissionsScreen`.

2. **Authentication Flow:**
   - `AuthWrapper` checks `currentUser`.
   - If null -> `LoginScreen` / `SignUpScreen`.
   - If authenticated -> `HomeScreen`.

3. **Voice Interaction Loop:**
   - **Idle:** Waiting for user to tap microphone.
   - **Listening:** User taps -> `SpeechToText` active, visual pulse.
   - **Processing:** Silence detected (3s) -> Send to `GlobalAIService`.
   - **Response:** AI generates text -> `FlutterTTS` speaks.
   - **Resume:** Back to Idle.

### Data Flow
- **User Settings:** Persisted in `SharedPreferences` (Voice speed, Language).
- **Chat History:** Stored in Firestore (sync) or Hive (local).
- **Navigation Data:** Fetched from OpenStreetMap / OSRM API via `MapService`.

## 5. Directory Structure
```
lib/
├── core/                  # Core utilities, theme, constants
├── features/              # Feature-based modules
│   ├── auth/             # Login, Signup, Profile
│   ├── chat/             # AI Logic, Voice UI
│   ├── home/             # Dashboard, Main navigation
│   ├── maps/             # Map implementation
│   ├── settings/         # App settings
│   └── splash/           # Startup logic
├── models/               # Data models (User, Message, Route)
├── services/             # Singletons (AI, Auth, Voice, Loc)
└── widgets/              # Shared UI components
```
