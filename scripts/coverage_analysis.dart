#!/usr/bin/env dart

/// CleanClik Coverage Analysis Tool
/// Analyzes test coverage and generates detailed reports with threshold checking

import 'dart:io';
import 'dart:convert';

class CoverageAnalyzer {
  static const Map<String, double> thresholds = {
    'overall': 85.0,
    'services': 85.0,
    'supabase_integration': 90.0,
    'models': 95.0,
    'providers': 85.0,
    'widgets': 80.0,
  };

  static const Map<String, List<String>> pathPatterns = {
    'services': ['lib/core/services/'],
    'supabase_integration': [
      'lib/core/services/auth/',
      'lib/core/services/data/',
      'lib/core/services/social/',
    ],
    'models': ['lib/core/models/'],
    'providers': ['lib/core/providers/'],
    'widgets': ['lib/presentation/widgets/'],
  };

  Future<void> analyze() async {
    print('🔍 CleanClik Coverage Analysis');
    print('==============================\n');

    final lcovFile = File('coverage/lcov_filtered.info');
    if (!lcovFile.existsSync()) {
      print('❌ Coverage file not found. Run test coverage first.');
      exit(1);
    }

    final lcovContent = await lcovFile.readAsString();
    final coverageData = _parseLcovFile(lcovContent);

    // Generate reports
    await _generateOverallReport(coverageData);
    await _generateCategoryReports(coverageData);
    await _generateUncoveredFilesReport(coverageData);
    await _generateRiverpodProviderReport();
    await _checkThresholds(coverageData);
  }

  Map<String, FileCoverage> _parseLcovFile(String content) {
    final Map<String, FileCoverage> coverage = {};
    final lines = content.split('\n');
    
    String? currentFile;
    int? linesFound;
    int? linesHit;

    for (final line in lines) {
      if (line.startsWith('SF:')) {
        currentFile = line.substring(3);
      } else if (line.startsWith('LF:')) {
        linesFound = int.tryParse(line.substring(3));
      } else if (line.startsWith('LH:')) {
        linesHit = int.tryParse(line.substring(3));
      } else if (line == 'end_of_record' && currentFile != null) {
        if (linesFound != null && linesHit != null) {
          coverage[currentFile] = FileCoverage(
            file: currentFile,
            linesFound: linesFound,
            linesHit: linesHit,
          );
        }
        currentFile = null;
        linesFound = null;
        linesHit = null;
      }
    }

    return coverage;
  }

  Future<void> _generateOverallReport(Map<String, FileCoverage> coverage) async {
    final totalLines = coverage.values.fold(0, (sum, file) => sum + file.linesFound);
    final totalHit = coverage.values.fold(0, (sum, file) => sum + file.linesHit);
    final overallPercentage = totalLines > 0 ? (totalHit / totalLines) * 100 : 0.0;

    print('📊 Overall Coverage Report');
    print('=========================');
    print('Total Files: ${coverage.length}');
    print('Total Lines: $totalLines');
    print('Lines Hit: $totalHit');
    print('Coverage: ${overallPercentage.toStringAsFixed(2)}%');
    print('');
  }

  Future<void> _generateCategoryReports(Map<String, FileCoverage> coverage) async {
    print('📂 Category Coverage Reports');
    print('============================');

    for (final category in pathPatterns.keys) {
      final patterns = pathPatterns[category]!;
      final categoryFiles = coverage.entries
          .where((entry) => patterns.any((pattern) => entry.key.contains(pattern)))
          .map((entry) => entry.value)
          .toList();

      if (categoryFiles.isEmpty) {
        print('$category: No files found');
        continue;
      }

      final totalLines = categoryFiles.fold(0, (sum, file) => sum + file.linesFound);
      final totalHit = categoryFiles.fold(0, (sum, file) => sum + file.linesHit);
      final percentage = totalLines > 0 ? (totalHit / totalLines) * 100 : 0.0;
      final threshold = thresholds[category] ?? 0.0;
      final status = percentage >= threshold ? '✅' : '❌';

      print('$status $category: ${percentage.toStringAsFixed(2)}% (${categoryFiles.length} files)');
      
      // Show poorly covered files
      final poorlyCovered = categoryFiles
          .where((file) => file.percentage < threshold)
          .toList()
        ..sort((a, b) => a.percentage.compareTo(b.percentage));

      if (poorlyCovered.isNotEmpty) {
        print('   Needs attention:');
        for (final file in poorlyCovered.take(5)) {
          final fileName = file.file.split('/').last;
          print('   - $fileName: ${file.percentage.toStringAsFixed(1)}%');
        }
      }
    }
    print('');
  }

  Future<void> _generateUncoveredFilesReport(Map<String, FileCoverage> coverage) async {
    print('🚨 Uncovered Files Report');
    print('=========================');

    final uncoveredFiles = coverage.values
        .where((file) => file.percentage == 0.0)
        .toList()
      ..sort((a, b) => a.file.compareTo(b.file));

    if (uncoveredFiles.isEmpty) {
      print('✅ No completely uncovered files found!');
    } else {
      print('Found ${uncoveredFiles.length} completely uncovered files:');
      for (final file in uncoveredFiles) {
        final fileName = file.file.split('/').last;
        print('- $fileName');
      }
    }
    print('');
  }

  Future<void> _generateRiverpodProviderReport() async {
    print('🔧 Riverpod Provider Coverage');
    print('=============================');

    // Find all provider files
    final libDir = Directory('lib');
    final providerFiles = <File>[];

    await for (final entity in libDir.list(recursive: true)) {
      if (entity is File && 
          entity.path.endsWith('.dart') && 
          !entity.path.endsWith('.g.dart') &&
          !entity.path.endsWith('.freezed.dart')) {
        final content = await entity.readAsString();
        if (content.contains('@riverpod') || content.contains('Provider')) {
          providerFiles.add(entity);
        }
      }
    }

    print('Found ${providerFiles.length} files with Riverpod providers');

    // Check if they have corresponding tests
    final missingTests = <String>[];
    for (final file in providerFiles) {
      final relativePath = file.path.replaceFirst('lib/', '');
      final testPath = 'test/unit/${relativePath.replaceFirst('.dart', '_test.dart')}';
      
      if (!File(testPath).existsSync()) {
        missingTests.add(relativePath);
      }
    }

    if (missingTests.isEmpty) {
      print('✅ All provider files have corresponding tests');
    } else {
      print('❌ Missing tests for ${missingTests.length} provider files:');
      for (final file in missingTests) {
        print('- $file');
      }
    }
    print('');
  }

  Future<void> _checkThresholds(Map<String, FileCoverage> coverage) async {
    print('🎯 Threshold Check Results');
    print('==========================');

    bool allPassed = true;

    // Overall threshold
    final totalLines = coverage.values.fold(0, (sum, file) => sum + file.linesFound);
    final totalHit = coverage.values.fold(0, (sum, file) => sum + file.linesHit);
    final overallPercentage = totalLines > 0 ? (totalHit / totalLines) * 100 : 0.0;
    
    final overallPassed = overallPercentage >= thresholds['overall']!;
    allPassed &= overallPassed;
    print('${overallPassed ? '✅' : '❌'} Overall: ${overallPercentage.toStringAsFixed(2)}% (required: ${thresholds['overall']}%)');

    // Category thresholds
    for (final category in pathPatterns.keys) {
      final patterns = pathPatterns[category]!;
      final categoryFiles = coverage.entries
          .where((entry) => patterns.any((pattern) => entry.key.contains(pattern)))
          .map((entry) => entry.value)
          .toList();

      if (categoryFiles.isEmpty) continue;

      final totalLines = categoryFiles.fold(0, (sum, file) => sum + file.linesFound);
      final totalHit = categoryFiles.fold(0, (sum, file) => sum + file.linesHit);
      final percentage = totalLines > 0 ? (totalHit / totalLines) * 100 : 0.0;
      final threshold = thresholds[category]!;
      final passed = percentage >= threshold;
      
      allPassed &= passed;
      print('${passed ? '✅' : '❌'} $category: ${percentage.toStringAsFixed(2)}% (required: ${threshold}%)');
    }

    print('');
    if (allPassed) {
      print('🎉 All coverage thresholds met!');
      exit(0);
    } else {
      print('💥 Some coverage thresholds not met. Please add more tests.');
      exit(1);
    }
  }
}

class FileCoverage {
  final String file;
  final int linesFound;
  final int linesHit;

  FileCoverage({
    required this.file,
    required this.linesFound,
    required this.linesHit,
  });

  double get percentage => linesFound > 0 ? (linesHit / linesFound) * 100 : 0.0;
}

void main() async {
  final analyzer = CoverageAnalyzer();
  await analyzer.analyze();
}