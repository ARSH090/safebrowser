import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:safebrowser/features/auth/presentation/notifiers/auth_notifier.dart';
import 'package:safebrowser/features/child/presentation/pages/browser_page.dart';
import 'package:safebrowser/features/parent/presentation/pages/parent_dashboard.dart';
import 'login_page.dart';

class AuthGate extends StatelessWidget {
  final String? initialUrl;
  const AuthGate({Key? key, this.initialUrl}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (initialUrl != null) {
      return BrowserPage(initialUrl: initialUrl);
    }

    final authNotifier = Provider.of<AuthNotifier>(context);

    switch (authNotifier.state) {
      case AuthState.authenticated:
        return const ParentDashboard();
      case AuthState.unauthenticated:
        return const LoginPage();
      case AuthState.unknown:
      default:
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
    }
  }
}
