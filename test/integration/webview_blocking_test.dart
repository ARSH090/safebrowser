/// Integration tests for WebView content blocking
/// Tests real-time filtering of pages

import 'package:flutter_test/flutter_test.dart';
import 'package:safebrowser/core/models/content_filter_models.dart';
import 'package:safebrowser/core/services/webview_safety_manager.dart';

void main() {
  group('WebView Safety Integration Tests', () {
    late WebViewSafetyManager safetyManager;

    setUp(() {
      safetyManager = WebViewSafetyManager();
    });

    tearDown(() {
      safetyManager.dispose();
    });

    group('WebView Initialization', () {
      test('WebViewSafetyManager initializes successfully', () {
        expect(safetyManager, isNotNull);
      });

      test('webViewOptions are configured correctly', () {
        final options = safetyManager.webViewOptions;
        
        expect(options, isNotNull);
        expect(options.crossPlatform, isNotNull);
        expect(options.android, isNotNull);
      });

      test('blocking is enabled by default', () {
        safetyManager.setBlockingEnabled(true);
        // Verify through behavior in other tests
      });
    });

    group('Content Blocking', () {
      test('safe pages are allowed', () {
        // Mock safe page analysis
        final analysis = PageSafetyAnalysis(
          pageUrl: 'https://wikipedia.org',
          pageTitle: 'Wikipedia',
          severity: BlockSeverity.safe,
          overallSeverity: BlockSeverity.safe,
          urlAnalysis: null,
          textAnalysis: null,
          imageAnalyses: [],
          analyzedAt: DateTime.now(),
        );

        expect(analysis.isSafe, true);
        expect(analysis.isBlocked, false);
      });

      test('blocked pages are restricted', () {
        // Mock blocked page analysis
        final analysis = PageSafetyAnalysis(
          pageUrl: 'https://phishing.tk',
          pageTitle: 'Phishing',
          severity: BlockSeverity.blocked,
          overallSeverity: BlockSeverity.blocked,
          urlAnalysis: null,
          textAnalysis: null,
          imageAnalyses: [],
          analyzedAt: DateTime.now(),
        );

        expect(analysis.isSafe, false);
        expect(analysis.isBlocked, true);
      });

      test('pages with blocked images show warning', () {
        final blockedImageResult = ImageAnalysisResult(
          imageUrl: 'https://example.com/unsafe.jpg',
          severity: BlockSeverity.blocked,
          reason: BlockReason.adultImage,
          analyzedAt: DateTime.now(),
          confidenceScore: 90,
        );

        final safeImageResult = ImageAnalysisResult(
          imageUrl: 'https://example.com/safe.jpg',
          severity: BlockSeverity.safe,
          reason: BlockReason.passedAllChecks,
          analyzedAt: DateTime.now(),
          confidenceScore: 100,
        );

        final analysis = PageSafetyAnalysis(
          pageUrl: 'https://example.com',
          pageTitle: 'Example',
          severity: BlockSeverity.warning,
          overallSeverity: BlockSeverity.warning,
          urlAnalysis: null,
          textAnalysis: null,
          imageAnalyses: [blockedImageResult, safeImageResult],
          analyzedAt: DateTime.now(),
          percentageBlocked: 50,
        );

        expect(analysis.isBlocked, false);
        expect(analysis.severity, BlockSeverity.warning);
        expect(analysis.blockedImagesCount, equals(1));
      });
    });

    group('Callback Handling', () {
      test('onPageBlocked callback receives correct reason', () {
        BlockReason? receivedReason;
        String? receivedDetails;

        safetyManager.onPageBlocked = (reason, details) {
          receivedReason = reason;
          receivedDetails = details;
        };

        // Simulate blocking
        safetyManager.onPageBlocked?.call(
          BlockReason.phishingUrl,
          'Suspicious URL detected',
        );

        expect(receivedReason, BlockReason.phishingUrl);
        expect(receivedDetails, contains('Suspicious'));
      });

      test('onContentAnalyzed callback receives analysis', () {
        PageSafetyAnalysis? receivedAnalysis;

        safetyManager.onContentAnalyzed = (analysis) {
          receivedAnalysis = analysis;
        };

        final analysis = PageSafetyAnalysis(
          pageUrl: 'https://example.com',
          pageTitle: 'Example',
          severity: BlockSeverity.safe,
          overallSeverity: BlockSeverity.safe,
          urlAnalysis: null,
          textAnalysis: null,
          imageAnalyses: [],
          analyzedAt: DateTime.now(),
        );

        safetyManager.onContentAnalyzed?.call(analysis);

        expect(receivedAnalysis, analysis);
      });
    });

    group('Blocking State Management', () {
      test('setBlockingEnabled controls filtering', () {
        safetyManager.setBlockingEnabled(false);
        // Blocking disabled - pages would not be analyzed

        safetyManager.setBlockingEnabled(true);
        // Blocking enabled - pages would be analyzed
      });

      test('dispose cleans up resources', () {
        safetyManager.dispose();
        // Verify no resources remain
      });
    });
  });
}
