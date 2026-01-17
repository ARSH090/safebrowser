import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:safebrowser/features/auth/presentation/notifiers/auth_notifier.dart';
import 'package:safebrowser/features/auth/presentation/pages/login_page.dart';
import 'package:safebrowser/features/onboarding/presentation/pages/onboarding_screen.dart';
import 'package:safebrowser/features/parent/presentation/pages/parent_dashboard.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final _storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkStatus();
    });
  }

  Future<void> _checkStatus() async {
    if (!mounted) return;
    
    try {
      final authNotifier = Provider.of<AuthNotifier>(context, listen: false);
      
      // Check auth first
      if (authNotifier.state == AuthState.authenticated) {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const ParentDashboard()),
          );
        }
        return;
      }

      // Check onboarding flag
      final hasSeenOnboarding = await _storage.read(key: 'has_seen_onboarding');
      
      if (mounted) {
        if (hasSeenOnboarding == 'true') {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const LoginPage()),
          );
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const OnboardingScreen()),
          );
        }
      }
    } catch (e) {
      debugPrint('Error during splash check: $e');
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const OnboardingScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[800], // Deep Blue from the design
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Placeholder for Logo
            const Icon(Icons.shield, size: 100, color: Colors.white),
            const SizedBox(height: 20),
            const Text(
              'SafeBrowse',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const Text(
              'Safe Learning. Smart Protection.',
              style: TextStyle(fontSize: 16, color: Colors.white70),
            ),
            const SizedBox(height: 40),
            const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
          ],
        ),
      ),
    );
  }
}
