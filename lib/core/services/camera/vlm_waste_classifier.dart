/// On-device VLM waste classifier powered by Cactus.
///
/// Runs a small vision-language model (LFM2-VL 450M) fully on-device to
/// classify picked-up items into waste categories with an explanation.
/// This refines the fast-but-brittle keyword categorization from ML Kit
/// labels. Fully offline — no cloud fallback by design.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cactus/cactus.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:synchronized/synchronized.dart';

/// Result of a VLM classification.
class VlmClassification {
  /// One of: recycle, organic, ewaste, hazardous, landfill.
  final String categoryId;

  /// Short human-readable item name, e.g. "crushed aluminum can".
  final String itemName;

  /// One-line explanation of why the item belongs in this category.
  final String reasoning;

  /// False when the model decided the image does not show a waste item.
  final bool isWaste;

  const VlmClassification({
    required this.categoryId,
    required this.itemName,
    required this.reasoning,
    required this.isWaste,
  });

  @override
  String toString() =>
      'VlmClassification($categoryId, "$itemName", waste: $isWaste)';
}

class VlmWasteClassifier {
  static VlmWasteClassifier? _instance;
  static VlmWasteClassifier get instance =>
      _instance ??= VlmWasteClassifier._();

  VlmWasteClassifier._();

  static const String _modelSlug = 'lfm2-vl-450m';
  static const Duration _inferenceTimeout = Duration(seconds: 25);

  static const Set<String> _validCategories = {
    'recycle',
    'organic',
    'ewaste',
    'hazardous',
    'landfill',
    'not_waste',
  };

  static const String _systemPrompt =
      'You are a waste-sorting assistant. Look at the image and classify the '
      'main object into exactly one category:\n'
      '- recycle: plastic, glass, metal, paper, cardboard, textiles\n'
      '- organic: food scraps, plants, compostable material\n'
      '- ewaste: electronics, batteries, cables, devices\n'
      '- hazardous: chemicals, paint, medicine, aerosols, oil\n'
      '- landfill: non-recyclable trash (wrappers, cigarette butts, mixed waste)\n'
      '- not_waste: the object is not a waste item\n'
      'Respond with ONLY a JSON object, no other text:\n'
      '{"item": "<short name>", "category": "<category>", "reason": "<one short sentence>"}';

  final CactusLM _lm = CactusLM();
  final Lock _inferenceLock = Lock();

  bool _ready = false;
  bool _initializing = false;
  double _downloadProgress = 0.0;

  bool get isReady => _ready;
  bool get isInitializing => _initializing;
  double get downloadProgress => _downloadProgress;

  /// Download (first run) and load the model. Safe to call repeatedly.
  Future<void> initialize() async {
    if (_ready || _initializing) return;
    _initializing = true;

    try {
      if (kDebugMode) {
        print('🧠 [VlmWasteClassifier] Initializing model "$_modelSlug"...');
      }

      await _lm.downloadModel(
        model: _modelSlug,
        downloadProcessCallback: (progress, status, isError) {
          if (progress != null) _downloadProgress = progress;
          if (kDebugMode && isError) {
            print('❌ [VlmWasteClassifier] Download: $status');
          }
        },
      );

      await _lm.initializeModel(params: CactusInitParams(model: _modelSlug));

      _ready = true;
      if (kDebugMode) {
        print('✅ [VlmWasteClassifier] Model ready');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ [VlmWasteClassifier] Initialization failed: $e');
      }
      _ready = false;
    } finally {
      _initializing = false;
    }
  }

  /// Classify a JPEG snapshot of a detected object.
  ///
  /// Returns null when the model is not ready, inference fails, or the
  /// response cannot be parsed — callers keep their existing category.
  /// Inference calls are serialized; the model cannot run concurrently.
  Future<VlmClassification?> classifyJpeg(Uint8List jpegBytes) async {
    if (!_ready) return null;

    return _inferenceLock.synchronized(() async {
      File? tempFile;
      try {
        final dir = await getTemporaryDirectory();
        tempFile = File(
          '${dir.path}/vlm_snap_${DateTime.now().microsecondsSinceEpoch}.jpg',
        );
        await tempFile.writeAsBytes(jpegBytes, flush: true);

        final stopwatch = Stopwatch()..start();
        final result = await _lm
            .generateCompletion(
              messages: [
                ChatMessage(content: _systemPrompt, role: 'system'),
                ChatMessage(
                  content: 'Classify the main object in this image.',
                  role: 'user',
                  images: [tempFile.path],
                ),
              ],
              params: CactusCompletionParams(maxTokens: 120, temperature: 0.1),
            )
            .timeout(_inferenceTimeout);
        stopwatch.stop();

        if (kDebugMode) {
          print(
            '🧠 [VlmWasteClassifier] Inference took '
            '${stopwatch.elapsedMilliseconds}ms: ${result.response}',
          );
        }

        return _parseResponse(result.response);
      } catch (e) {
        if (kDebugMode) {
          print('❌ [VlmWasteClassifier] Classification failed: $e');
        }
        return null;
      } finally {
        try {
          await tempFile?.delete();
        } catch (_) {}
      }
    });
  }

  VlmClassification? _parseResponse(String response) {
    final start = response.indexOf('{');
    final end = response.lastIndexOf('}');
    if (start == -1 || end <= start) return null;

    try {
      final json =
          jsonDecode(response.substring(start, end + 1))
              as Map<String, dynamic>;
      final category = (json['category'] as String?)?.trim().toLowerCase();
      if (category == null || !_validCategories.contains(category)) {
        return null;
      }

      final isWaste = category != 'not_waste';
      return VlmClassification(
        categoryId: isWaste ? category : 'landfill',
        itemName: (json['item'] as String?)?.trim() ?? '',
        reasoning: (json['reason'] as String?)?.trim() ?? '',
        isWaste: isWaste,
      );
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ [VlmWasteClassifier] Failed to parse response: $e');
      }
      return null;
    }
  }

  Future<void> dispose() async {
    _ready = false;
    try {
      _lm.unload();
    } catch (_) {}
  }
}
