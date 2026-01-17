import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:safebrowser/core/services/firebase_service.dart';

enum AuthState { authenticated, unauthenticated, unknown }

class AuthNotifier with ChangeNotifier {
  final FirebaseAuth _auth = firebaseService.auth;
  AuthState _state = AuthState.unknown;
  User? _user;

  AuthNotifier() {
    _auth.authStateChanges().listen((user) {
      if (user == null) {
        _state = AuthState.unauthenticated;
        _user = null;
      } else {
        _state = AuthState.authenticated;
        _user = user;
      }
      notifyListeners();
    });
  }

  AuthState get state => _state;
  User? get user => _user;

  Future<void> signInWithEmail(String email, String password) async {
    try {
      await firebaseService.signInWithEmail(email, password);
    } catch (e) {
      debugPrint('Error signing in: $e');
      rethrow;
    }
  }

  Future<void> signUpWithEmail(String email, String password) async {
    try {
      await firebaseService.createUserWithEmail(email, password);
    } catch (e) {
      debugPrint('Error signing up: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await firebaseService.signOut();
    } catch (e) {
      debugPrint('Error signing out: $e');
      rethrow;
    }
  }
}
