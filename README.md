# Travid - Voice-Enabled Travel Assistant

## 🎯 Project Overview

Travid is an AI-powered, voice-controlled travel assistant app designed for accessibility, with a focus on blind and visually impaired users. The app provides intelligent route planning, real-time navigation, and proactive travel assistance through natural voice interaction.

## ✨ Key Features

### **🎤 Voice Control**
### **🎤 Voice Control**
- Tap-to-Speak activation
- Prominent accessibility-focused UI
- Natural conversation with AI
- Multiple voice options (male/female, accents)
- Voice biometric security

### **🤖 AI Assistant**
- Context-aware responses
- Proactive suggestions
- Route planning and optimization
- Real-time traffic updates
- Activity monitoring and insights

### **♿ Accessibility**
- Designed for blind users
- Haptic feedback
- Audio feedback for all actions
- High contrast mode
- Large touch targets

### **🗺️ Navigation**
- Voice-guided directions
- Bus route planning
- Nearby POI discovery
- Real-time arrival alerts
- Offline maps support

## 📥 Downloads & APKs

Optimized APKs are available for different architectures to reduce download size. These can be found in the `build/app/outputs/flutter-apk/` directory after building.

| Architecture | Description | File |
|--------------|-------------|------|
| **ARM64** | Most modern Android phones | `app-arm64-v8a-release.apk` |
| **ARMv7** | Older Android phones | `app-armeabi-v7a-release.apk` |
| **x86_64** | Emulators / Intel-based devices | `app-x86_64-release.apk` |

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (3.0+)
- Android Studio / VS Code
- Google Cloud account (for AI)
- Firebase account

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/travid.git
   cd travid
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase**
   - Add `google-services.json` to `android/app/`
   - Add `GoogleService-Info.plist` to `ios/Runner/`

4. **Set up AI API Key**
   - Get API key from [Google AI Studio](https://aistudio.google.com/app/apikey)
   - Update `lib/services/ai_service.dart` line 5

5. **Run the app**
   ```bash
   flutter run
   ```

## 📱 App Structure

```
lib/
├── core/                  # Core utilities
│   └── providers.dart     # Riverpod providers
├── features/              # Feature modules
│   ├── auth/             # Authentication
│   ├── chat/             # AI chat interface
│   ├── maps/             # Map & navigation
│   ├── settings/         # Settings
│   └── test/             # Test screens
├── models/               # Data models
├── services/             # Business logic
│   ├── ai_service.dart
│   ├── auth_service.dart
│   ├── voice_service.dart
│   └── feedback_service.dart
└── widgets/              # Reusable widgets
```

## 🛠️ Tech Stack

**Frontend:**
- Flutter 3.0+
- Riverpod (state management)
- Material Design 3

**Backend:**
- Firebase Auth, Cloud Firestore, Analytics
- Google Gemini AI (gemini-2.5-flash)

**Maps & Voice:**
- OpenStreetMap (`flutter_map`)
- Speech-to-Text & Text-to-Speech
- Tap-to-Speak Interaction
- Geolocator

## 📖 Documentation

For detailed technical specifications, control flow diagrams, and internal architecture notes, please refer to:
- **[Specifications (specs.md)](specs.md)**

## 🎯 Current Status

**Version:** 1.0.0 (Alpha)

**Completed:**
- ✅ Firebase integration
- ✅ Authentication (Email/Password, Anonymous)
- ✅ AI chat with Gemini
- ✅ Voice input/output
- ✅ Settings system
- ✅ Chat history
- ✅ Accessibility features

## 🤝 Contributing

We welcome contributions! Please check the issues page.

## 📄 License

© 2026 Travid. All rights reserved.

## 👥 Team

- **Developer:** CRK
- **Designer:** CRK

## 🙏 Acknowledgments

- Google Gemini AI team
- Flutter community
- OpenStreetMap contributors
- Accessibility advocates

---

**Made with ❤️ for accessible travel**
