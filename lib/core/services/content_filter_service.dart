/// Content Filter Service - Real-time protection pipeline
/// Performs: URL analysis → Text scanning → Image blocking
/// All operations are ASYNC and NON-BLOCKING to UI

import 'package:flutter/foundation.dart';
import 'package:safebrowser/core/models/content_filter_models.dart';
import 'package:safebrowser/core/services/ai_model_service.dart';

/// Known phishing domains and suspicious patterns
class _KnownThreats {
  static const Set<String> phishingDomains = {
    'bit.ly',
    'tinyurl.com',
    'goo.gl',
    'ow.ly',
    'rebrand.ly',
  };

  static const Set<String> malwareDomains = {
    'malware.example.com',
    'virus.example.com',
  };

  static final RegExp phishingPatterns = RegExp(
    r'(login|signin|account|verify|confirm|update|security)\..*\.(xyz|top|tk|ml)',
    caseSensitive: false,
  );

  static final RegExp suspiciousPatterns = RegExp(
    r'(password|ssn|credit.*card|bank|account).*=.*(&|\?)',
    caseSensitive: false,
  );
}

/// Production-grade content filtering service
/// Thread-safe, non-blocking, with fallback behaviors
class ContentFilterService {
  static final ContentFilterService _instance = ContentFilterService._internal();

  factory ContentFilterService() {
    return _instance;
  }

  ContentFilterService._internal();

  final _aiModel = aiModelService;
  bool _filterEnabled = true;

  /// Step 1: Analyze URL BEFORE page loads
  /// Fast check without model inference
  Future<UrlAnalysisResult> analyzeUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      final domain = uri.host.toLowerCase();

      // Check known phishing domains
      if (_KnownThreats.phishingDomains.contains(domain)) {
        return UrlAnalysisResult(
          url: url,
          severity: BlockSeverity.blocked,
          reason: BlockReason.phishingUrl,
          details: 'Known URL shortener used for phishing',
          analyzedAt: DateTime.now(),
          confidenceScore: 95,
        );
      }

      // Check known malware domains
      if (_KnownThreats.malwareDomains.contains(domain)) {
        return UrlAnalysisResult(
          url: url,
          severity: BlockSeverity.blocked,
          reason: BlockReason.knownMalware,
          details: 'Known malware domain',
          analyzedAt: DateTime.now(),
          confidenceScore: 98,
        );
      }

      // Check for phishing patterns
      if (_KnownThreats.phishingPatterns.hasMatch(url)) {
        return UrlAnalysisResult(
          url: url,
          severity: BlockSeverity.warning,
          reason: BlockReason.phishingUrl,
          details: 'Suspicious domain pattern detected',
          analyzedAt: DateTime.now(),
          confidenceScore: 75,
        );
      }

      // Check for suspicious patterns (password stealing, etc.)
      if (_KnownThreats.suspiciousPatterns.hasMatch(url)) {
        return UrlAnalysisResult(
          url: url,
          severity: BlockSeverity.blocked,
          reason: BlockReason.ageInappropriate,
          details: 'Suspicious URL parameters detected',
          analyzedAt: DateTime.now(),
          confidenceScore: 85,
        );
      }

      // Check for HTTPS
      if (!url.startsWith('https://')) {
        return UrlAnalysisResult(
          url: url,
          severity: BlockSeverity.warning,
          reason: BlockReason.suspiciousDomain,
          details: 'Non-HTTPS connection',
          analyzedAt: DateTime.now(),
          confidenceScore: 40,
        );
      }

      // URL appears safe
      return UrlAnalysisResult(
        url: url,
        severity: BlockSeverity.safe,
        reason: BlockReason.passedAllChecks,
        analyzedAt: DateTime.now(),
        confidenceScore: 100,
      );
    } catch (e) {
      debugPrint('⚠️ URL analysis error: $e');
      // On error, allow but warn
      return UrlAnalysisResult(
        url: url,
        severity: BlockSeverity.warning,
        reason: BlockReason.unknownReason,
        details: 'Error during URL analysis: $e',
        analyzedAt: DateTime.now(),
        confidenceScore: 50,
      );
    }
  }

  /// Step 2: Analyze extracted text AFTER page load
  /// Uses AI model for content classification
  Future<TextAnalysisResult> analyzeText(String text) async {
    if (!_filterEnabled) {
      return TextAnalysisResult(
        text: text,
        severity: BlockSeverity.safe,
        reasons: [BlockReason.filterDisabled],
        analyzedAt: DateTime.now(),
        confidenceScore: 0,
      );
    }

    try {
      if (text.isEmpty) {
        return TextAnalysisResult(
          text: text,
          severity: BlockSeverity.safe,
          reasons: [BlockReason.passedAllChecks],
          analyzedAt: DateTime.now(),
          confidenceScore: 100,
        );
      }

      // Get AI model scores
      final scores = await _aiModel.analyzeText(text);
      final reasons = <BlockReason>[];

      if ((scores['adult'] ?? 0.0) > AIModelService.ADULT_THRESHOLD) {
        reasons.add(BlockReason.adultText);
      }
      if ((scores['violence'] ?? 0.0) > AIModelService.VIOLENCE_THRESHOLD) {
        reasons.add(BlockReason.violentText);
      }
      if ((scores['hate_speech'] ?? 0.0) > 0.7) {
        reasons.add(BlockReason.hateSpeech);
      }

      if (reasons.isEmpty) {
        return TextAnalysisResult(
          text: text,
          severity: BlockSeverity.safe,
          reasons: [BlockReason.passedAllChecks],
          analyzedAt: DateTime.now(),
          confidenceScore: 100,
        );
      }

      return TextAnalysisResult(
        text: text,
        severity: BlockSeverity.blocked,
        reasons: reasons,
        flaggedContent: text.substring(0, (text.length / 4).toInt()),
        analyzedAt: DateTime.now(),
        confidenceScore: (_aiModel.getMaxScore(scores) * 100).toInt(),
      );
    } catch (e) {
      debugPrint('⚠️ Text analysis error: $e');
      return TextAnalysisResult(
        text: text,
        severity: BlockSeverity.warning,
        reasons: [BlockReason.unknownReason],
        analyzedAt: DateTime.now(),
        confidenceScore: 50,
      );
    }
  }

  /// Step 3: Analyze images DURING render
  /// Processed asynchronously in background
  Future<ImageAnalysisResult> analyzeImageUrl(String imageUrl) async {
    if (!_filterEnabled) {
      return ImageAnalysisResult(
        imageUrl: imageUrl,
        severity: BlockSeverity.safe,
        reason: BlockReason.filterDisabled,
        analyzedAt: DateTime.now(),
        confidenceScore: 0,
      );
    }

    try {
      // Check URL patterns first (fast)
      if (_isSuspiciousImageUrl(imageUrl)) {
        return ImageAnalysisResult(
          imageUrl: imageUrl,
          severity: BlockSeverity.blocked,
          reason: BlockReason.adultImage,
          analyzedAt: DateTime.now(),
          confidenceScore: 70,
        );
      }

      // In production, download and analyze with AI model
      // For now, based on URL patterns only
      return ImageAnalysisResult(
        imageUrl: imageUrl,
        severity: BlockSeverity.safe,
        reason: BlockReason.passedAllChecks,
        analyzedAt: DateTime.now(),
        confidenceScore: 100,
      );
    } catch (e) {
      debugPrint('⚠️ Image analysis error: $e');
      return ImageAnalysisResult(
        imageUrl: imageUrl,
        severity: BlockSeverity.warning,
        reason: BlockReason.unknownReason,
        analyzedAt: DateTime.now(),
        confidenceScore: 50,
      );
    }
  }

  /// Quick check for suspicious image URLs
  bool _isSuspiciousImageUrl(String url) {
    final lowerUrl = url.toLowerCase();
    
    final suspiciousKeywords = [
      'adult', 'porn', 'xxx', 'sex', 'nude', 'nsfw',
      'violence', 'gore', 'blood',
    ];

    return suspiciousKeywords.any((keyword) => lowerUrl.contains(keyword));
  }

  /// Final verdict: Should entire page be blocked?
  PageSafetyAnalysis synthesizePageAnalysis({
    required String pageUrl,
    required String pageTitle,
    required UrlAnalysisResult? urlAnalysis,
    required TextAnalysisResult? textAnalysis,
    required List<ImageAnalysisResult> imageAnalyses,
  }) {
    // Determine overall severity
    BlockSeverity overallSeverity = BlockSeverity.safe;
    
    // URL is critical - if blocked, block entire page
    if (urlAnalysis?.isBlocked == true) {
      overallSeverity = BlockSeverity.blocked;
    }
    // Text content matters
    else if (textAnalysis?.isBlocked == true) {
      overallSeverity = BlockSeverity.blocked;
    }
    // If majority of images are blocked, warn about page
    else if (imageAnalyses.isNotEmpty) {
      final blockedCount = imageAnalyses.where((img) => img.shouldBlock).length;
      final percentage = (blockedCount / imageAnalyses.length * 100).toInt();
      
      if (percentage > 50) {
        overallSeverity = BlockSeverity.warning;
      }
    }

    return PageSafetyAnalysis(
      pageUrl: pageUrl,
      pageTitle: pageTitle,
      severity: overallSeverity,
      overallSeverity: overallSeverity,
      urlAnalysis: urlAnalysis,
      textAnalysis: textAnalysis,
      imageAnalyses: imageAnalyses,
      analyzedAt: DateTime.now(),
      percentageBlocked: imageAnalyses.isEmpty
          ? null
          : (imageAnalyses.where((img) => img.shouldBlock).length /
              imageAnalyses.length *
              100)
              .toInt(),
    );
  }

  /// Enable/disable filtering
  void setFilterEnabled(bool enabled) {
    _filterEnabled = enabled;
    debugPrint('🔒 Content filtering: ${enabled ? 'ENABLED' : 'DISABLED'}');
  }

  /// Get filter status
  bool get isFilterEnabled => _filterEnabled;
}

/// Global content filter service instance
final contentFilterService = ContentFilterService();
