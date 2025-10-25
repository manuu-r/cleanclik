import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cleanclik/core/services/camera/waste_categorizer.dart';
import 'package:cleanclik/core/models/camera_models.dart';
import 'package:cleanclik/core/models/waste_models.dart';

void main() {
  group('WasteCategorizer', () {
    late WasteCategorizer categorizer;

    setUp(() async {
      // Mock SharedPreferences for testing
      SharedPreferences.setMockInitialValues({});
      categorizer = WasteCategorizer.instance;
      await categorizer.initialize();
    });

    tearDown(() {
      categorizer.dispose();
    });

    group('Label Mapping', () {
      test('should categorize bottle as recycle', () {
        final labels = [ImageLabel(text: 'bottle', confidence: 0.9, index: 0)];

        final result = categorizer.categorize(labels, null);

        expect(result, isNotNull);
        expect(result!.category, WasteCategory.recycle);
        expect(result.confidence, greaterThan(0.8));
        expect(result.matchedLabel, 'bottle');
      });

      test('should categorize apple as organic', () {
        final labels = [ImageLabel(text: 'apple', confidence: 0.85, index: 0)];

        final result = categorizer.categorize(labels, null);

        expect(result, isNotNull);
        expect(result!.category, WasteCategory.organic);
        expect(result.confidence, greaterThan(0.7));
        expect(result.matchedLabel, 'apple');
      });

      test('should categorize phone as ewaste', () {
        final labels = [ImageLabel(text: 'phone', confidence: 0.92, index: 0)];

        final result = categorizer.categorize(labels, null);

        expect(result, isNotNull);
        expect(result!.category, WasteCategory.ewaste);
        expect(result.confidence, greaterThan(0.8));
        expect(result.matchedLabel, 'phone');
      });

      test('should categorize battery as hazardous', () {
        final labels = [
          ImageLabel(text: 'car battery', confidence: 0.88, index: 0),
        ];

        final result = categorizer.categorize(labels, null);

        expect(result, isNotNull);
        expect(result!.category, WasteCategory.hazardous);
        expect(result.confidence, greaterThan(0.7));
        expect(result.matchedLabel, 'car battery');
      });

      test('should handle ML Kit specific categories', () {
        final labels = [
          ImageLabel(text: 'fashion_good', confidence: 0.9, index: 0),
        ];

        final result = categorizer.categorize(labels, null);

        expect(result, isNotNull);
        expect(result!.category, WasteCategory.recycle);
        expect(result.confidence, greaterThan(0.8));
      });
    });

    group('Confidence Calculation', () {
      test('should calculate confidence for single matching label', () {
        final labels = [
          ImageLabel(text: 'bottle', confidence: 0.9, index: 0),
          ImageLabel(text: 'unknown', confidence: 0.5, index: 1),
        ];

        final confidence = categorizer.calculateCategoryConfidence(
          labels,
          WasteCategory.recycle,
        );

        expect(confidence, greaterThan(0.8));
      });

      test('should boost confidence for multiple matching labels', () {
        final labels = [
          ImageLabel(text: 'bottle', confidence: 0.8, index: 0),
          ImageLabel(text: 'plastic', confidence: 0.7, index: 1),
        ];

        final confidence = categorizer.calculateCategoryConfidence(
          labels,
          WasteCategory.recycle,
        );

        expect(
          confidence,
          greaterThan(0.7),
        ); // Should be boosted above individual average
      });

      test('should return zero confidence for non-matching category', () {
        final labels = [ImageLabel(text: 'bottle', confidence: 0.9, index: 0)];

        final confidence = categorizer.calculateCategoryConfidence(
          labels,
          WasteCategory.organic,
        );

        expect(confidence, equals(0.0));
      });
    });

    group('Compound Categorization', () {
      test('should categorize fashion_good + home_good as ewaste', () {
        final labels = [
          ImageLabel(text: 'fashion_good', confidence: 0.8, index: 0),
          ImageLabel(text: 'home_good', confidence: 0.7, index: 1),
        ];

        final result = categorizer.categorize(labels, null);

        expect(result, isNotNull);
        expect(result!.category, WasteCategory.ewaste);
        expect(result.reasoning, contains('Multi-category detection'));
      });

      test('should handle multiple labels with different categories', () {
        final labels = [
          ImageLabel(text: 'bottle', confidence: 0.9, index: 0),
          ImageLabel(text: 'apple', confidence: 0.6, index: 1),
        ];

        final result = categorizer.categorize(labels, null);

        expect(result, isNotNull);
        expect(
          result!.category,
          WasteCategory.recycle,
        ); // Higher confidence wins
      });
    });

    group('Fuzzy Matching', () {
      test('should handle common typos', () {
        final labels = [
          ImageLabel(
            text: 'bottel',
            confidence: 0.8,
            index: 0,
          ), // Typo for bottle
        ];

        final result = categorizer.categorize(labels, null);

        expect(result, isNotNull);
        expect(result!.category, WasteCategory.recycle);
        expect(result.reasoning, contains('Fuzzy'));
      });

      test('should handle partial matches', () {
        final labels = [
          ImageLabel(
            text: 'plastic bottle container',
            confidence: 0.8,
            index: 0,
          ),
        ];

        final result = categorizer.categorize(labels, null);

        expect(result, isNotNull);
        expect(result!.category, WasteCategory.recycle);
      });
    });

    group('User Corrections', () {
      test('should apply user correction', () async {
        // Apply correction
        await categorizer.applyUserCorrection(
          'test_item',
          WasteCategory.organic,
        );

        // Test that correction is applied
        final labels = [
          ImageLabel(text: 'test_item', confidence: 0.8, index: 0),
        ];

        final result = categorizer.categorize(labels, null);

        expect(result, isNotNull);
        expect(result!.category, WasteCategory.organic);
        expect(result.isUserCorrected, isTrue);
        expect(result.reasoning, contains('User correction'));
      });

      test('should retrieve user correction', () async {
        await categorizer.applyUserCorrection(
          'test_item',
          WasteCategory.ewaste,
        );

        final correction = categorizer.getUserCorrection('test_item');

        expect(correction, WasteCategory.ewaste);
      });

      test('should remove user correction', () async {
        await categorizer.applyUserCorrection(
          'test_item',
          WasteCategory.hazardous,
        );
        await categorizer.removeUserCorrection('test_item');

        final correction = categorizer.getUserCorrection('test_item');

        expect(correction, isNull);
      });

      test('should clear all user corrections', () async {
        await categorizer.applyUserCorrection('item1', WasteCategory.recycle);
        await categorizer.applyUserCorrection('item2', WasteCategory.organic);

        await categorizer.clearUserCorrections();

        final corrections = categorizer.getUserCorrections();
        expect(corrections, isEmpty);
      });
    });

    group('Edge Cases', () {
      test('should return null for empty labels', () {
        final result = categorizer.categorize([], null);
        expect(result, isNull);
      });

      test('should return null for low confidence labels', () {
        final labels = [
          ImageLabel(
            text: 'bottle',
            confidence: 0.2,
            index: 0,
          ), // Below threshold
        ];

        final result = categorizer.categorize(labels, null);
        expect(result, isNull);
      });

      test('should return null for unknown labels', () {
        final labels = [
          ImageLabel(
            text: 'completely_unknown_item',
            confidence: 0.9,
            index: 0,
          ),
        ];

        final result = categorizer.categorize(labels, null);
        expect(result, isNull);
      });

      test('should handle case insensitive matching', () {
        final labels = [ImageLabel(text: 'BOTTLE', confidence: 0.9, index: 0)];

        final result = categorizer.categorize(labels, null);

        expect(result, isNotNull);
        expect(result!.category, WasteCategory.recycle);
      });

      test('should handle labels with special characters', () {
        final labels = [
          ImageLabel(text: 'bottle!@#', confidence: 0.9, index: 0),
        ];

        final result = categorizer.categorize(labels, null);

        expect(result, isNotNull);
        expect(result!.category, WasteCategory.recycle);
      });
    });

    group('Statistics', () {
      test('should provide categorization statistics', () {
        final stats = categorizer.getStatistics();

        expect(stats, containsPair('total_mappings', greaterThan(0)));
        expect(stats, containsPair('user_corrections', 0));
        expect(stats, containsPair('corrections_loaded', true));
        expect(stats, contains('mappings_by_category'));
        expect(stats, contains('corrections_by_category'));
      });
    });
  });
}
