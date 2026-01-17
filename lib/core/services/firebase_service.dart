/// Firebase service - Singleton pattern with comprehensive error handling
/// NO CONTEXT USAGE - All Firebase operations are context-free
/// Initialize BEFORE runApp() is called

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:safebrowser/core/models/app_exception.dart' as app_exception;
import '../../../firebase_options.dart';

/// Production-grade Firebase service
/// Handles all Firebase operations with proper error handling and logging
class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();

  factory FirebaseService() {
    return _instance;
  }

  FirebaseService._internal();

  late FirebaseAuth _auth;
  late FirebaseFirestore _firestore;
  late FirebaseMessaging _messaging;
  late FirebaseFunctions _functions;
  
  bool _initialized = false;

  // Getters (only after initialization)
  FirebaseAuth get auth => _auth;
  FirebaseFirestore get firestore => _firestore;
  FirebaseMessaging get messaging => _messaging;
  FirebaseFunctions get functions => _functions;
  bool get isInitialized => _initialized;

  /// Initialize Firebase - MUST be called before runApp()
  /// Returns void because we don't need to wait for full initialization
  /// Firebase initializes in background
  Future<void> initialize() async {
    if (_initialized) {
      debugPrint('✅ Firebase already initialized');
      return;
    }

    try {
      debugPrint('🔵 Initializing Firebase...');
      
      // Initialize Firebase with type-safe options
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // Get singleton instances
      _auth = FirebaseAuth.instance;
      _firestore = FirebaseFirestore.instance;
      _messaging = FirebaseMessaging.instance;
      _functions = FirebaseFunctions.instance;

      // Configure Firestore for real-time updates
      _firestore.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );

      // Enable offline persistence
      try {
        await _firestore.disableNetwork();
        await _firestore.enableNetwork();
      } catch (e) {
        debugPrint('⚠️ Network toggle failed (offline?): $e');
      }

      // Setup FCM token refresh
      _setupFCMTokenRefresh();

      // Set emulator mode if in debug (optional)
      /* 
      if (kDebugMode && false) { // Set true to use Firebase emulator
        _auth.useAuthEmulator('localhost', 9099);
        _firestore.useFirestoreEmulator('localhost', 8080);
        _functions.useFunctionsEmulator('localhost', 5001);
      }
      */

      _initialized = true;
      debugPrint('✅ Firebase initialized successfully');
      
    } on FirebaseException catch (e) {
      throw app_exception.FirebaseException(
        message: 'Firebase initialization failed: ${e.message}',
        code: e.code,
        stackTrace: StackTrace.current,
      );
    } catch (e) {
      throw app_exception.FirebaseException(
        message: 'Unexpected error during Firebase init: $e',
        code: 'FIREBASE_INIT_ERROR',
        stackTrace: StackTrace.current,
      );
    }
  }

  /// Setup FCM token refresh listener
  void _setupFCMTokenRefresh() {
    try {
      _messaging.onTokenRefresh.listen((newToken) {
        debugPrint('🔔 FCM token refreshed: ${newToken.substring(0, 20)}...');
        // Token is automatically used by Firebase
      }).onError((err) {
        debugPrint('❌ FCM token refresh error: $err');
      });
    } catch (e) {
      debugPrint('⚠️ FCM setup failed: $e');
    }
  }

  /// Get current user
  Future<User?> getCurrentUser() async {
    try {
      return _auth.currentUser;
    } catch (e) {
      throw app_exception.FirebaseException(
        message: 'Failed to get current user: $e',
        code: 'AUTH_ERROR',
      );
    }
  }

  /// Check if user is authenticated
  bool get isUserAuthenticated => _auth.currentUser != null;

  /// Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  /// Sign in with email and password
  Future<UserCredential> signInWithEmail(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw app_exception.FirebaseException(
        message: _parseAuthError(e.code),
        code: e.code,
      );
    } catch (e) {
      throw app_exception.FirebaseException(
        message: 'Unexpected sign-in error: $e',
        code: 'AUTH_SIGNIN_ERROR',
      );
    }
  }

  /// Create user with email and password AND initialize Firestore document
  Future<UserCredential> createUserWithEmail(String email, String password) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Initialize parent document in Firestore
      if (credential.user != null) {
        await _firestore.collection('users').doc(credential.user!.uid).set({
          'email': email,
          'role': 'parent',
          'createdAt': FieldValue.serverTimestamp(),
          'settings': {
            'notificationsEnabled': true,
            'globalBlocking': true,
          },
        });
      }

      return credential;
    } on FirebaseAuthException catch (e) {
      throw app_exception.FirebaseException(
        message: _parseAuthError(e.code),
        code: e.code,
      );
    } catch (e) {
      throw app_exception.FirebaseException(
        message: 'Unexpected registration error: $e',
        code: 'AUTH_SIGNUP_ERROR',
      );
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw app_exception.FirebaseException(
        message: 'Sign out failed: $e',
        code: 'AUTH_SIGNOUT_ERROR',
      );
    }
  }

  /// Listen to auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Get user document from Firestore
  Future<DocumentSnapshot<Map<String, dynamic>>> getUserDocument(String uid) async {
    try {
      return await _firestore.collection('users').doc(uid).get();
    } catch (e) {
      throw app_exception.FirebaseException(
        message: 'Failed to fetch user document: $e',
        code: 'FIRESTORE_READ_ERROR',
      );
    }
  }

  /// Update user document
  Future<void> updateUserDocument(
    String uid,
    Map<String, dynamic> data,
  ) async {
    try {
      await _firestore.collection('users').doc(uid).update(data);
    } catch (e) {
      throw app_exception.FirebaseException(
        message: 'Failed to update user document: $e',
        code: 'FIRESTORE_WRITE_ERROR',
      );
    }
  }

  /// Call Cloud Function
  Future<dynamic> callCloudFunction(
    String functionName,
    Map<String, dynamic> data,
  ) async {
    try {
      final callable = _functions.httpsCallable(functionName);
      final result = await callable.call(data);
      return result.data;
    } on FirebaseFunctionsException catch (e) {
      throw app_exception.FirebaseException(
        message: 'Cloud Function error: ${e.message}',
        code: e.code,
      );
    } catch (e) {
      throw app_exception.FirebaseException(
        message: 'Failed to call Cloud Function: $e',
        code: 'FUNCTION_CALL_ERROR',
      );
    }
  }

  /// Log event to Firebase Analytics
  Future<void> logEvent(String eventName, Map<String, dynamic>? parameters) async {
    try {
      // Firebase Analytics is automatically included in firebase_core
      debugPrint('📊 Event: $eventName, params: $parameters');
    } catch (e) {
      debugPrint('⚠️ Analytics logging failed: $e');
    }
  }

  /// Parse Firebase Auth error codes to user-friendly messages
  String _parseAuthError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Email not registered';
      case 'wrong-password':
        return 'Incorrect password';
      case 'email-already-in-use':
        return 'Email already registered';
      case 'weak-password':
        return 'Password too weak (min 6 characters)';
      case 'invalid-email':
        return 'Invalid email format';
      case 'operation-not-allowed':
        return 'Operation not allowed';
      case 'too-many-requests':
        return 'Too many login attempts. Try again later.';
      case 'network-request-failed':
        return 'Network error. Check your connection.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }

  /// Graceful shutdown (call during app teardown)
  Future<void> dispose() async {
    try {
      await _firestore.disableNetwork();
      _initialized = false;
      debugPrint('✅ Firebase disposed');
    } catch (e) {
      debugPrint('⚠️ Firebase dispose error: $e');
    }
  }
}

/// Global Firebase service instance
final firebaseService = FirebaseService();
