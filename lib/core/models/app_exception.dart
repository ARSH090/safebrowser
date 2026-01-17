/// Production-grade exception handling for SafeBrowse
/// All operations must use these exceptions for consistent error handling
sealed class AppException implements Exception {
  final String message;
  final String code;
  final StackTrace? stackTrace;

  AppException({
    required this.message,
    required this.code,
    this.stackTrace,
  });

  @override
  String toString() => 'AppException($code): $message';
}

/// Firebase authentication & initialization failures
class FirebaseException extends AppException {
  FirebaseException({
    required String message,
    String code = 'FIREBASE_ERROR',
    StackTrace? stackTrace,
  }) : super(
    message: message,
    code: code,
    stackTrace: stackTrace,
  );
}

/// WebView and page loading failures
class WebViewException extends AppException {
  WebViewException({
    required String message,
    String code = 'WEBVIEW_ERROR',
    StackTrace? stackTrace,
  }) : super(
    message: message,
    code: code,
    stackTrace: stackTrace,
  );
}

/// Content filtering and AI model failures
class ContentFilterException extends AppException {
  ContentFilterException({
    required String message,
    String code = 'FILTER_ERROR',
    StackTrace? stackTrace,
  }) : super(
    message: message,
    code: code,
    stackTrace: stackTrace,
  );
}

/// Network and connectivity failures
class NetworkException extends AppException {
  NetworkException({
    required String message,
    String code = 'NETWORK_ERROR',
    StackTrace? stackTrace,
  }) : super(
    message: message,
    code: code,
    stackTrace: stackTrace,
  );
}

/// Model loading and AI inference failures
class ModelException extends AppException {
  ModelException({
    required String message,
    String code = 'MODEL_ERROR',
    StackTrace? stackTrace,
  }) : super(
    message: message,
    code: code,
    stackTrace: stackTrace,
  );
}

/// Permission and security failures
class SecurityException extends AppException {
  SecurityException({
    required String message,
    String code = 'SECURITY_ERROR',
    StackTrace? stackTrace,
  }) : super(
    message: message,
    code: code,
    stackTrace: stackTrace,
  );
}
