/// Unit tests for Content Filter Service
/// Tests URL blocking, text analysis, image filtering

import 'package:flutter_test/flutter_test.dart';
import 'package:safebrowser/core/services/content_filter_service.dart';
import 'package:safebrowser/core/models/content_filter_models.dart';

void main() {
  group('ContentFilterService', () {
    late ContentFilterService filterService;

    setUp(() {
      filterService = ContentFilterService();
    });

    group('URL Analysis', () {
      test('analyzeUrl detects phishing URLs', () async {
        final result = await filterService.analyzeUrl(
          'https://login-verify-account.tk/pay?id=123',
        );
        
        expect(result.isBlocked, true);
        expect(result.reason, BlockReason.phishingUrl);
      });

      test('analyzeUrl passes safe HTTPS URLs', () async {
        final result = await filterService.analyzeUrl(
          'https://www.google.com',
        );
        
        expect(result.isSafe, true);
        expect(result.reason, BlockReason.passedAllChecks);
      });

      test('analyzeUrl warns non-HTTPS URLs', () async {
        final result = await filterService.analyzeUrl(
          'http://insecure.com',
        );
        
        expect(result.severity, BlockSeverity.warning);
      });

      test('analyzeUrl detects URL shorteners', () async {
        final result = await filterService.analyzeUrl(
          'https://bit.ly/malicious',
        );
        
        expect(result.isBlocked, true);
      });

      test('analyzeUrl handles malformed URLs gracefully', () async {
        final result = await filterService.analyzeUrl(
          'not-a-url-at-all',
        );
        
        // Should not throw, should handle gracefully
        expect(result, isNotNull);
      });
    });

    group('Text Analysis', () {
      test('analyzeText returns TextAnalysisResult', () async {
        final result = await filterService.analyzeText('Hello world');
        
        expect(result, isA<TextAnalysisResult>());
        expect(result.text, isNotEmpty);
      });

      test('analyzeText handles empty text', () async {
        final result = await filterService.analyzeText('');
        
        expect(result.isSafe, true);
      });

      test('analyzeText respects filter disabled state', () async {
        filterService.setFilterEnabled(false);
        final result = await filterService.analyzeText('adult content');
        
        expect(result.isSafe, true);
        expect(result.reasons.contains(BlockReason.filterDisabled), true);
      });

      test('analyzeText re-enables filtering', () async {
        filterService.setFilterEnabled(false);
        filterService.setFilterEnabled(true);
        
        expect(filterService.isFilterEnabled, true);
      });
    });

    group('Image Analysis', () {
      test('analyzeImageUrl returns ImageAnalysisResult', () async {
        final result = await filterService.analyzeImageUrl(
          'https://example.com/image.jpg',
        );
        
        expect(result, isA<ImageAnalysisResult>());
      });

      test('analyzeImageUrl detects suspicious URLs', () async {
        final result = await filterService.analyzeImageUrl(
          'https://example.com/adult-image.jpg',
        );
        
        expect(result.isBlocked, true);
      });

      test('analyzeImageUrl passes safe image URLs', () async {
        final result = await filterService.analyzeImageUrl(
          'https://example.com/landscape.jpg',
        );
        
        expect(result.isSafe, true);
      });
    });

    group('Page Analysis Synthesis', () {
      test('synthesizePageAnalysis blocks if URL is blocked', () {
        final urlResult = UrlAnalysisResult(
          url: 'https://phishing.tk',
          severity: BlockSeverity.blocked,
          reason: BlockReason.phishingUrl,
          analyzedAt: DateTime.now(),
          confidenceScore: 95,
        );

        final analysis = filterService.synthesizePageAnalysis(
          pageUrl: 'https://phishing.tk',
          pageTitle: 'Phishing Page',
          urlAnalysis: urlResult,
          textAnalysis: null,
          imageAnalyses: [],
        );

        expect(analysis.isBlocked, true);
      });

      test('synthesizePageAnalysis warns if many images blocked', () {
        final imageResults = [
          ImageAnalysisResult(
            imageUrl: 'https://example.com/adult1.jpg',
            severity: BlockSeverity.blocked,
            reason: BlockReason.adultImage,
            analyzedAt: DateTime.now(),
            confidenceScore: 90,
          ),
          ImageAnalysisResult(
            imageUrl: 'https://example.com/adult2.jpg',
            severity: BlockSeverity.blocked,
            reason: BlockReason.adultImage,
            analyzedAt: DateTime.now(),
            confidenceScore: 85,
          ),
          ImageAnalysisResult(
            imageUrl: 'https://example.com/safe.jpg',
            severity: BlockSeverity.safe,
            reason: BlockReason.passedAllChecks,
            analyzedAt: DateTime.now(),
            confidenceScore: 100,
          ),
        ];

        final analysis = filterService.synthesizePageAnalysis(
          pageUrl: 'https://example.com',
          pageTitle: 'Page',
          urlAnalysis: null,
          textAnalysis: null,
          imageAnalyses: imageResults,
        );

        expect(analysis.severity, BlockSeverity.warning);
        expect(analysis.percentageBlocked, greaterThan(50));
      });

      test('synthesizePageAnalysis calculates blocked image count', () {
        final imageResults = List.generate(
          10,
          (i) => ImageAnalysisResult(
            imageUrl: 'https://example.com/image$i.jpg',
            severity: i < 3 ? BlockSeverity.blocked : BlockSeverity.safe,
            reason: i < 3 ? BlockReason.adultImage : BlockReason.passedAllChecks,
            analyzedAt: DateTime.now(),
            confidenceScore: 85,
          ),
        );

        final analysis = filterService.synthesizePageAnalysis(
          pageUrl: 'https://example.com',
          pageTitle: 'Page',
          urlAnalysis: null,
          textAnalysis: null,
          imageAnalyses: imageResults,
        );

        expect(analysis.blockedImagesCount, equals(3));
        expect(analysis.totalImagesAnalyzed, equals(10));
      });
    });

    group('Filter State', () {
      test('isFilterEnabled defaults to true', () {
        expect(filterService.isFilterEnabled, true);
      });

      test('setFilterEnabled changes state', () {
        filterService.setFilterEnabled(false);
        expect(filterService.isFilterEnabled, false);
        
        filterService.setFilterEnabled(true);
        expect(filterService.isFilterEnabled, true);
      });
    });
  });
}
