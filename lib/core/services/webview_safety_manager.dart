/// WebView Manager - Safe web rendering with real-time content blocking
/// Intercepts navigation, page load, and renders
/// Works with flutter_inappwebview

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:safebrowser/core/services/content_filter_service.dart';
import 'package:safebrowser/features/logs/data/models/log_model.dart';
import 'package:safebrowser/features/logs/data/services/log_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Callbacks for WebView events
typedef OnPageStarted = void Function(String url);
typedef OnPageFinished = void Function(String url);
typedef OnPageBlocked = void Function(BlockReason reason, String details);
typedef OnContentAnalyzed = void Function(PageSafetyAnalysis analysis);

/// Production-grade WebView safety manager
class WebViewSafetyManager {
  late InAppWebViewController? _webViewController;
  late InAppWebViewGroupOptions _webViewOptions;
  
  // Callbacks
  OnPageStarted? onPageStarted;
  OnPageFinished? onPageFinished;
  OnPageBlocked? onPageBlocked;
  OnContentAnalyzed? onContentAnalyzed;

  final _contentFilter = contentFilterService;
  bool _blockingEnabled = true;
  
  String? _parentId;
  String? _childId;

  /// Set context for logging
  void setContext({required String parentId, required String childId}) {
    _parentId = parentId;
    _childId = childId;
  }

  WebViewSafetyManager() {
    _setupWebViewOptions();
  }

  /// Configure WebView with security hardening
  void _setupWebViewOptions() {
    _webViewOptions = InAppWebViewGroupOptions(
      crossPlatform: InAppWebViewOptions(
        useShouldOverrideUrlLoading: true,
        useOnLoadResource: true,
        useOnDownloadStart: true,
        javaScriptEnabled: true,
        mediaPlaybackRequiresUserGesture: false,
        supportZoom: false,
      ),
      android: AndroidInAppWebViewOptions(
        useHybridComposition: true,
        supportMultipleWindows: false,
        databaseEnabled: false,
        domStorageEnabled: false,
        geolocationEnabled: false,
        allowFileAccess: false,
        allowContentAccess: false,
      ),
    );
  }

  /// Initialize WebView controller
  void initialize(InAppWebViewController controller) {
    _webViewController = controller;
    _setupInterceptors();
  }

  /// Setup all interception points
  void _setupInterceptors() {
    if (_webViewController == null) return;

    // Note: Callbacks are set when creating InAppWebView widget
    // See initializeWebViewOptions for useShouldOverrideUrlLoading: true
  }

  /// Analyze page content after loading
  Future<void> analyzePageContent(
    InAppWebViewController controller,
    Uri pageUrl,
    String pageTitle,
  ) async {
    try {
      // Step 1: URL already analyzed before load
      final urlAnalysis = await _contentFilter.analyzeUrl(pageUrl.toString());

      // Step 2: Extract and analyze text
      TextAnalysisResult? textAnalysis;
      try {
        // Extract all text content from page
        final textContent = await _extractPageText(controller);
        if (textContent.isNotEmpty) {
          textAnalysis = await _contentFilter.analyzeText(textContent);
        }
      } catch (e) {
        debugPrint('⚠️ Text extraction failed: $e');
      }

      // Step 3: Find and analyze images
      final imageAnalyses = <ImageAnalysisResult>[];
      try {
        final imageUrls = await _extractImageUrls(controller);
        for (final imageUrl in imageUrls) {
          final analysis = await _contentFilter.analyzeImageUrl(imageUrl);
          imageAnalyses.add(analysis);
          
          // Block unsafe images
          if (analysis.shouldBlock) {
            await _hideImage(controller, imageUrl);
          }
        }
      } catch (e) {
        debugPrint('⚠️ Image analysis failed: $e');
      }

      // Step 4: Synthesize final verdict
      final pageAnalysis = _contentFilter.synthesizePageAnalysis(
        pageUrl: pageUrl.toString(),
        pageTitle: pageTitle,
        urlAnalysis: urlAnalysis,
        textAnalysis: textAnalysis,
        imageAnalyses: imageAnalyses,
      );

      onContentAnalyzed?.call(pageAnalysis);

      // Block page if needed
      if (pageAnalysis.isBlocked && _blockingEnabled) {
        await _showBlockedPage(controller, pageAnalysis);
        
        // Log the event
        if (_parentId != null && _childId != null) {
          final log = LogModel(
            id: '', // Firestore will generate
            type: _getLogType(pageAnalysis),
            reason: _formatBlockReason(pageAnalysis),
            timestamp: Timestamp.now(),
            childId: _childId!,
            url: pageUrl.toString(),
          );
          await logService.addLog(_parentId!, log);
        }
      }
    } catch (e) {
      debugPrint('❌ Page analysis error: $e');
    }
  }

  /// Extract all text from page
  Future<String> _extractPageText(InAppWebViewController controller) async {
    try {
      final result = await controller.evaluateJavascript(
        source: '''
          document.body.innerText
        ''',
      );
      return result?.toString() ?? '';
    } catch (e) {
      debugPrint('⚠️ Text extraction error: $e');
      return '';
    }
  }

  /// Extract all image URLs from page
  Future<List<String>> _extractImageUrls(InAppWebViewController controller) async {
    try {
      final result = await controller.evaluateJavascript(
        source: '''
          Array.from(document.querySelectorAll('img')).map(img => img.src).filter(src => src.length > 0)
        ''',
      );
      
      if (result is List) {
        return result.map((e) => e.toString()).toList();
      }
      return [];
    } catch (e) {
      debugPrint('⚠️ Image URL extraction error: $e');
      return [];
    }
  }

  /// Hide specific image
  Future<void> _hideImage(
    InAppWebViewController controller,
    String imageUrl,
  ) async {
    try {
      await controller.evaluateJavascript(
        source: '''
          document.querySelectorAll('img').forEach(img => {
            if (img.src === '$imageUrl') {
              img.style.display = 'none';
              img.setAttribute('data-blocked', 'true');
            }
          });
        ''',
      );
    } catch (e) {
      debugPrint('⚠️ Image hiding error: $e');
    }
  }

  /// Show blocked page overlay
  Future<void> _showBlockedPage(
    InAppWebViewController controller,
    PageSafetyAnalysis analysis,
  ) async {
    try {
      final html = _buildBlockedPageHtml(analysis);
      await controller.loadData(data: html);
    } catch (e) {
      debugPrint('⚠️ Blocked page display error: $e');
    }
  }

  /// Build HTML for blocked page
  String _buildBlockedPageHtml(PageSafetyAnalysis analysis) {
    final reason = _formatBlockReason(analysis);
    
    return '''
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Page Blocked</title>
        <style>
          * { margin: 0; padding: 0; }
          body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 20px;
          }
          .container {
            background: white;
            border-radius: 12px;
            box-shadow: 0 20px 60px rgba(0,0,0,0.3);
            padding: 40px;
            max-width: 500px;
            text-align: center;
          }
          .icon {
            font-size: 64px;
            margin-bottom: 20px;
          }
          h1 {
            color: #333;
            margin-bottom: 10px;
            font-size: 28px;
          }
          p {
            color: #666;
            line-height: 1.6;
            margin-bottom: 20px;
          }
          .reason {
            background: #f5f5f5;
            border-left: 4px solid #667eea;
            padding: 12px;
            text-align: left;
            border-radius: 4px;
            font-family: monospace;
            font-size: 12px;
            color: #333;
          }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="icon">🛑</div>
          <h1>This Page Is Blocked</h1>
          <p>SafeBrowse has blocked this page to keep you safe.</p>
          <div class="reason">
            <strong>Reason:</strong><br>
            $reason<br><br>
            <strong>URL:</strong><br>
            ${_truncateUrl(analysis.pageUrl)}<br><br>
            <strong>Analysis:</strong><br>
            ${analysis.imageAnalyses.isNotEmpty ? 'Blocked ${analysis.blockedImagesCount} of ${analysis.totalImagesAnalyzed} images' : 'Content flagged for child safety'}
          </div>
        </div>
      </body>
      </html>
    ''';
  }

  /// Format block reason for display
  String _formatBlockReason(PageSafetyAnalysis analysis) {
    if (analysis.urlAnalysis?.isBlocked == true) {
      return 'URL identified as suspicious or phishing attempt';
    }
    if (analysis.textAnalysis?.isBlocked == true) {
      return 'Page contains inappropriate content';
    }
    if (analysis.blockedImagesCount > 0) {
      return 'Page contains unsafe images';
    }
    return 'Page does not meet safety standards';
  }

  /// Truncate URL for display
  String _truncateUrl(String url) {
    if (url.length > 50) {
      return '${url.substring(0, 50)}...';
    }
    return url;
  }

  /// Map analysis to LogType
  LogType _getLogType(PageSafetyAnalysis analysis) {
    if (analysis.urlAnalysis?.isBlocked == true) return LogType.phishing;
    if (analysis.textAnalysis?.isBlocked == true) return LogType.text;
    return LogType.image;
  }

  /// Get WebView options
  InAppWebViewGroupOptions get webViewOptions => _webViewOptions;

  /// Enable/disable blocking
  void setBlockingEnabled(bool enabled) {
    _blockingEnabled = enabled;
    debugPrint('🔒 WebView blocking: ${enabled ? 'ENABLED' : 'DISABLED'}');
  }

  /// Cleanup
  void dispose() {
    _webViewController = null;
  }
}
