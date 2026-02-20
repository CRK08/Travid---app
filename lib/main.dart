import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'firebase_options.dart';
import 'core/providers.dart';
import 'core/app_theme.dart';
import 'features/auth/login_screen.dart';
import 'features/splash/splash_screen.dart';
import 'home1.dart';
import 'services/global_ai_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive for local storage
  try {
    await Hive.initFlutter();
    print('✅ Hive initialized successfully');
  } catch (e) {
    print('❌ Hive initialization failed: $e');
  }
  
  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase initialized successfully');
  } catch (e) {
    print('❌ Firebase initialization failed: $e');
  }
  
  // Initialize Global AI Service
  try {
    await GlobalAIService().initialize();
    print('✅ Global AI Service initialized');
  } catch (e) {
    print('❌ Global AI Service initialization failed: $e');
  }
  
  runApp(
    const ProviderScope(
      child: TravidApp(),
    ),
  );
}

class TravidApp extends ConsumerWidget {
  const TravidApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch settings to rebuild when they change
    final settings = ref.watch(settingsProvider);
    
    return MaterialApp(
      title: 'Travid',
      debugShowCheckedModeBanner: false,
      
      // DYNAMIC THEME - Changes based on settings
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.darkTheme(),
      themeMode: settings.darkMode ? ThemeMode.dark : ThemeMode.light,
      
      // LOCALIZATION
      locale: Locale(settings.language),
      supportedLocales: const [
        Locale('en', 'US'),
        Locale('ta', 'IN'),
      ],
      localizationsDelegates: const [
        // AppLocalizations.delegate, // TODO: Add if using generated localizations
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      
      // DYNAMIC TEXT SCALE - Changes based on settings
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(settings.textScale), // Use TextScaler
          ),
          child: child!,
        );
      },
      
      home: const AuthWrapper(),
    );
  }
}

/// Wrapper to handle authentication state with splash
class AuthWrapper extends ConsumerStatefulWidget {
  const AuthWrapper({super.key});

  @override
  ConsumerState<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends ConsumerState<AuthWrapper> {
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    // Auto-hide splash after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _showSplash = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Show splash screen first
    if (_showSplash) {
      return SplashScreen(onComplete: () {
        setState(() => _showSplash = false);
      });
    }

    // Show auth flow (system will request permissions when needed)
    final authState = ref.watch(authStateProvider);
    final settings = ref.watch(settingsProvider);

    return authState.when(
      data: (user) {
        if (user != null) {
          // User is logged in, show home screen
          return const TravidHome();
        } else {
          // User is not logged in, show login screen
          return const LoginScreen();
        }
      },
      loading: () => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'Loading...',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      ),
      error: (error, stack) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Theme.of(context).colorScheme.error),
              const SizedBox(height: 16),
              Text('Error: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  // Retry
                  ref.invalidate(authStateProvider);
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
