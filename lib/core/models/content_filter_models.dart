/// Content filtering result models - used throughout the pipeline
/// These must be immutable for state management safety

import 'package:flutter/foundation.dart';

/// Severity levels for blocked content
enum BlockSeverity {
  safe,       // No issues detected
  warning,    // Questionable but might be OK
  blocked,    // Should not be shown to child
}

/// Reason why content was blocked or allowed
enum BlockReason {
  // Safe content
  passedAllChecks,
  
  // Text blocking reasons
  adultText,
  violentText,
  hateSpeech,
  
  // Image blocking reasons
  adultImage,
  violentImage,
  
  // URL blocking reasons
  phishingUrl,
  knownMalware,
  suspiciousDomain,
  ageInappropriate,
  
  // System reasons
  modelUnavailable,
  filterDisabled,
  unknownReason,
}

/// Result of URL analysis - performed BEFORE page load
@immutable
class UrlAnalysisResult {
  final String url;
  final BlockSeverity severity;
  final BlockReason reason;
  final String? details;
  final DateTime analyzedAt;
  final int confidenceScore; // 0-100

  const UrlAnalysisResult({
    required this.url,
    required this.severity,
    required this.reason,
    this.details,
    required this.analyzedAt,
    required this.confidenceScore,
  });

  bool get isSafe => severity == BlockSeverity.safe;
  bool get isBlocked => severity == BlockSeverity.blocked;

  @override
  String toString() =>
      'UrlAnalysis($url): $severity ($reason, confidence: $confidenceScore%)';
}

/// Result of text content analysis - performed AFTER HTML load
@immutable
class TextAnalysisResult {
  final String text;
  final BlockSeverity severity;
  final List<BlockReason> reasons;
  final String? flaggedContent;
  final DateTime analyzedAt;
  final int confidenceScore; // 0-100

  const TextAnalysisResult({
    required this.text,
    required this.severity,
    required this.reasons,
    this.flaggedContent,
    required this.analyzedAt,
    required this.confidenceScore,
  });

  bool get isSafe => severity == BlockSeverity.safe;
  bool get isBlocked => severity == BlockSeverity.blocked;

  @override
  String toString() =>
      'TextAnalysis: $severity (${reasons.join(', ')}, confidence: $confidenceScore%)';
}

/// Result of image analysis - performed DURING render
@immutable
class ImageAnalysisResult {
  final String imageUrl;
  final BlockSeverity severity;
  final BlockReason reason;
  final DateTime analyzedAt;
  final int confidenceScore; // 0-100

  const ImageAnalysisResult({
    required this.imageUrl,
    required this.severity,
    required this.reason,
    required this.analyzedAt,
    required this.confidenceScore,
  });

  bool get isSafe => severity == BlockSeverity.safe;
  bool get shouldBlock => severity == BlockSeverity.blocked;
  bool get isBlocked => shouldBlock;

  @override
  String toString() =>
      'ImageAnalysis($imageUrl): $severity ($reason, confidence: $confidenceScore%)';
}

/// Page safety summary - final verdict for entire page
@immutable
class PageSafetyAnalysis {
  final String pageUrl;
  final String pageTitle;
  final BlockSeverity severity;
  final BlockSeverity overallSeverity;
  final UrlAnalysisResult? urlAnalysis;
  final TextAnalysisResult? textAnalysis;
  final List<ImageAnalysisResult> imageAnalyses;
  final DateTime analyzedAt;
  final int? percentageBlocked; // Percentage of images/content blocked

  const PageSafetyAnalysis({
    required this.pageUrl,
    required this.pageTitle,
    required this.severity,
    required this.overallSeverity,
    this.urlAnalysis,
    this.textAnalysis,
    required this.imageAnalyses,
    required this.analyzedAt,
    this.percentageBlocked,
  });

  bool get isSafe => severity == BlockSeverity.safe;
  bool get isBlocked => severity == BlockSeverity.blocked;
  
  int get totalImagesAnalyzed => imageAnalyses.length;
  int get blockedImagesCount => 
      imageAnalyses.where((img) => img.shouldBlock).length;

  @override
  String toString() =>
      'PageAnalysis($pageUrl): $severity, blocked: $blockedImagesCount/$totalImagesAnalyzed images';
}
