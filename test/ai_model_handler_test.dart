import 'package:flutter_test/flutter_test.dart';
import 'package:safebrowser/features/ai/presentation/ai_model_handler.dart';

void main() {
  group('AIModelHandler URL Suspicion Tests', () {
    final aiModelHandler = AIModelHandler();

    test('should identify a URL with domain spoofing and suspicious keywords as suspicious', () async {
      final url = Uri.parse('http://login-paypal.com.xyz/verify-account');
      final isSuspicious = await aiModelHandler.isUrlSuspicious(url);
      expect(isSuspicious, isTrue);
    });

    test('should identify a URL with a suspicious TLD as suspicious', () async {
      final url = Uri.parse('https://get-free-stuff.loan');
      final isSuspicious = await aiModelHandler.isUrlSuspicious(url);
      expect(isSuspicious, isTrue);
    });

    test('should identify a URL with too many subdomains as suspicious', () async {
      final url = Uri.parse('https://secure.login.my-bank.com.long-domain.net/auth');
      final isSuspicious = await aiModelHandler.isUrlSuspicious(url);
      expect(isSuspicious, isTrue);
    });

    test('should identify a domain spoofing attempt as suspicious', () async {
      final url = Uri.parse('https://www.google-security-alert.com/');
      final isSuspicious = await aiModelHandler.isUrlSuspicious(url);
      expect(isSuspicious, isTrue);
    });

    test('should NOT identify a standard, safe URL as suspicious', () async {
      final url = Uri.parse('https://www.youtube.com/watch?v=dQw4w9WgXcQ');
      final isSuspicious = await aiModelHandler.isUrlSuspicious(url);
      expect(isSuspicious, isFalse);
    });

    test('should NOT identify a legitimate subdomain of a target as suspicious', () async {
      final url = Uri.parse('https://accounts.google.com/');
      final isSuspicious = await aiModelHandler.isUrlSuspicious(url);
      expect(isSuspicious, isFalse);
    });

     test('should NOT identify a non-suspicious URL as suspicious', () async {
      final url = Uri.parse('https://flutter.dev/');
      final isSuspicious = await aiModelHandler.isUrlSuspicious(url);
      expect(isSuspicious, isFalse);
    });

  });
}
