import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:safebrowser/core/services/firebase_service.dart';
import 'package:safebrowser/features/auth/presentation/notifiers/auth_notifier.dart';
import 'package:safebrowser/features/onboarding/presentation/pages/splash_screen.dart';
import 'package:safebrowser/features/parent/presentation/notifiers/child_profile_notifier.dart';
import 'package:safebrowser/app/themes.dart';

final firebaseService = FirebaseService();

void main() async {
  // CRITICAL: Initialize Flutter binding FIRST
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase (non-blocking, safe)
  try {
    await firebaseService.initialize();
  } catch (e) {
    debugPrint('❌ Firebase init failed: $e');
    // Continue anyway - app can work offline
  }

  // Start app
  runApp(const SafeBrowserApp());
}

/// Main app with proper provider setup
class SafeBrowserApp extends StatelessWidget {
  const SafeBrowserApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Auth notifier for user authentication state
        ChangeNotifierProvider(create: (_) => AuthNotifier()),
        // Child profile notifier for managing child settings
        ChangeNotifierProvider(create: (_) => ChildProfileNotifier()),
      ],
      child: MaterialApp(
        title: 'SafeBrowse',
        theme: ParentTheme.theme,
        darkTheme: ParentTheme.theme,
        home: const SplashScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
