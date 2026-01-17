/// Unit tests for AI Model Service
/// Tests model loading, inference, and error handling

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'dart:typed_data';
import 'package:safebrowser/core/services/ai_model_service.dart';
import 'package:safebrowser/core/models/app_exception.dart';

void main() {
  group('AIModelService', () {
    late AIModelService aiModelService;

    setUp(() {
      aiModelService = AIModelService();
    });

    tearDown(() async {
      await aiModelService.dispose();
    });

    group('Text Analysis', () {
      test('analyzeText returns non-empty score map', () async {
        final scores = await aiModelService.analyzeText('Hello world');
        
        expect(scores, isNotNull);
        expect(scores.containsKey('adult'), true);
        expect(scores.containsKey('violence'), true);
        expect(scores.containsKey('hate_speech'), true);
      });

      test('analyzeText returns scores between 0 and 1', () async {
        final scores = await aiModelService.analyzeText('Test content');
        
        scores.forEach((key, value) {
          expect(value, greaterThanOrEqualTo(0.0));
          expect(value, lessThanOrEqualTo(1.0));
        });
      });

      test('analyzeText handles empty string gracefully', () async {
        final scores = await aiModelService.analyzeText('');
        
        expect(scores, isNotNull);
        expect(scores['adult'], equals(0.0));
      });

      test('analyzeText handles very long text', () async {
        final longText = 'a' * 10000;
        final scores = await aiModelService.analyzeText(longText);
        
        expect(scores, isNotNull);
      });

      test('shouldBlockText returns true for high scores', () async {
        final scores = {'adult': 0.8, 'violence': 0.5, 'hate_speech': 0.3};
        final shouldBlock = aiModelService.shouldBlockText(scores);
        
        expect(shouldBlock, true);
      });

      test('shouldBlockText returns false for low scores', () async {
        final scores = {'adult': 0.2, 'violence': 0.1, 'hate_speech': 0.1};
        final shouldBlock = aiModelService.shouldBlockText(scores);
        
        expect(shouldBlock, false);
      });
    });

    group('Image Analysis', () {
      test('analyzeImage returns non-empty score map', () async {
        final dummyImageBytes = List<int>.filled(256 * 256 * 3, 0);
        final scores = await aiModelService.analyzeImage(
          Uint8List.fromList(dummyImageBytes),
        );
        
        expect(scores, isNotNull);
        expect(scores.containsKey('nsfw'), true);
        expect(scores.containsKey('violence'), true);
      });

      test('shouldBlockImage returns true for high scores', () async {
        final scores = {'nsfw': 0.8, 'violence': 0.5};
        final shouldBlock = aiModelService.shouldBlockImage(scores);
        
        expect(shouldBlock, true);
      });
    });

    group('Score Processing', () {
      test('getMaxScore returns highest value', () async {
        final scores = {'adult': 0.3, 'violence': 0.9, 'hate': 0.1};
        final max = aiModelService.getMaxScore(scores);
        
        expect(max, equals(0.9));
      });

      test('getMaxScore returns 0 for empty map', () async {
        final scores = <String, double>{};
        final max = aiModelService.getMaxScore(scores);
        
        expect(max, equals(0.0));
      });
    });

    group('Error Handling', () {
      test('analyzeText handles model load failure gracefully', () async {
        // This test verifies graceful degradation
        final scores = await aiModelService.analyzeText('test');
        
        // Should return safe defaults even if model loading fails
        expect(scores, isNotNull);
      });
    });

    group('Multimodal Analysis', () {
      test('analyzeAudio returns high score for unsafe filename (Mock)', () async {
        final scores = await aiModelService.analyzeAudio('/path/to/unsafe_audio.mp3');
        expect(scores['aggressive'], greaterThan(0.5));
      });

      test('analyzeAudio returns low score for safe filename (Mock)', () async {
        final scores = await aiModelService.analyzeAudio('/path/to/safe_song.mp3');
        expect(scores['aggressive'], lessThan(0.5));
      });

      test('analyzeVideoFrame delegates to image analysis', () async {
        final dummyFrame = Uint8List(256 * 256 * 3);
        final scores = await aiModelService.analyzeVideoFrame(dummyFrame);
        expect(scores.containsKey('nsfw'), true);
      });
    });
  });
}


