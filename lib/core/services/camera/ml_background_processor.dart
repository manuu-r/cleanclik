import 'dart:async';
import 'dart:isolate';
import 'package:flutter/services.dart';

/// Pure isolate lifecycle management utility
/// Handles only isolate spawning, message passing, and cleanup
/// Services use this as a utility for background processing
/// Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 2.6, 2.7
class MLBackgroundProcessor {
  Isolate? _isolate;
  SendPort? _sendPort;
  ReceivePort? _receivePort;
  bool _isReady = false;

  // Generic request tracking - no business logic
  final Map<String, Completer<dynamic>> _activeRequests = {};
  int _requestCounter = 0;

  bool get isReady => _isReady;

  /// Initialize isolate for background processing
  /// Requirement 2.1: Only manages isolate lifecycle
  Future<void> initialize() async {
    if (_isReady) return;

    try {
      _receivePort = ReceivePort();
      _isolate = await Isolate.spawn(
        _isolateEntryPoint,
        _receivePort!.sendPort,
      );

      await _setupCommunication();
      _isReady = true;
    } catch (e) {
      await dispose();
      rethrow;
    }
  }

  /// Setup communication channel with isolate
  /// Requirement 2.3: Serialize/deserialize data without interpreting it
  Future<void> _setupCommunication() async {
    final completer = Completer<void>();

    _receivePort!.listen((message) {
      if (message is SendPort && _sendPort == null) {
        _sendPort = message;
        completer.complete();
      } else if (message is Map<String, dynamic>) {
        _handleResponse(message);
      }
    });

    await completer.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () => throw TimeoutException('Isolate handshake timeout'),
    );
  }

  /// Handle responses from isolate
  /// Requirement 2.4: Return results without modification or business logic
  void _handleResponse(Map<String, dynamic> response) {
    final requestId = response['requestId'] as String?;
    if (requestId == null) return;

    final completer = _activeRequests.remove(requestId);
    if (completer == null) return;

    try {
      if (response['error'] == true) {
        final errorMessage =
            response['message'] as String? ?? 'Unknown isolate error';
        completer.completeError(Exception(errorMessage));
      } else {
        // Return raw result data without interpretation
        completer.complete(response['result']);
      }
    } catch (e) {
      completer.completeError(e);
    }
  }

  /// Generic method to process data in isolate
  /// Requirement 2.2: Services use this as a utility
  /// Requirement 2.3: Serialize/deserialize without interpreting
  Future<T> processInIsolate<T>(
    String action,
    Map<String, dynamic> data,
  ) async {
    if (!_isReady || _sendPort == null) {
      throw StateError('Background processor not ready');
    }

    final requestId = 'req_${++_requestCounter}';
    final completer = Completer<T>();
    _activeRequests[requestId] = completer;

    try {
      // Send generic request - no business logic
      _sendPort!.send({
        'requestId': requestId,
        'action': action,
        'data': data,
      });

      return await completer.future.timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          _activeRequests.remove(requestId);
          throw TimeoutException('Processing timeout');
        },
      );
    } catch (e) {
      _activeRequests.remove(requestId);
      rethrow;
    }
  }

  /// Clean up isolate resources
  /// Requirement 2.5: Propagate errors without handling business logic
  /// Requirement 2.6: Clean up only isolate-related resources
  Future<void> dispose() async {
    if (!_isReady && _isolate == null) return;

    _isReady = false;

    try {
      // Cancel all pending requests
      final pendingRequests = List.from(_activeRequests.values);
      for (final completer in pendingRequests) {
        if (!completer.isCompleted) {
          try {
            completer.completeError(Exception('Processor disposed'));
          } catch (_) {
            // Ignore completion errors during disposal
          }
        }
      }
      _activeRequests.clear();

      // Graceful isolate shutdown
      if (_isolate != null) {
        try {
          if (_sendPort != null) {
            _sendPort!.send({'action': 'shutdown'});
          }
          await Future.delayed(const Duration(milliseconds: 500));
          _isolate!.kill(priority: Isolate.immediate);
        } catch (_) {
          _isolate?.kill(priority: Isolate.immediate);
        }
      }

      // Close receive port
      _receivePort?.close();
    } finally {
      // Ensure cleanup of isolate resources only
      _isolate = null;
      _sendPort = null;
      _receivePort = null;
    }
  }

  /// Generic isolate entry point
  /// Requirement 2.7: Services handle all ML detection, image processing, and categorization
  /// This only manages message passing and isolate lifecycle
  static void _isolateEntryPoint(SendPort mainSendPort) async {
    try {
      // Setup communication
      final receivePort = ReceivePort();
      mainSendPort.send(receivePort.sendPort);

      // Listen for generic processing requests
      receivePort.listen((message) async {
        if (message is Map<String, dynamic>) {
          final action = message['action'] as String?;

          // Handle shutdown
          if (action == 'shutdown') {
            receivePort.close();
            return;
          }

          // Delegate to handler
          await _handleIsolateMessage(message, mainSendPort);
        }
      });
    } catch (e) {
      mainSendPort.send({
        'error': true,
        'message': e.toString(),
      });
    }
  }

  /// Handle generic messages in isolate
  /// Services define their own action handlers
  static Future<void> _handleIsolateMessage(
    Map<String, dynamic> message,
    SendPort mainSendPort,
  ) async {
    final requestId = message['requestId'] as String?;
    final action = message['action'] as String?;

    if (requestId == null || action == null) return;

    try {
      // Generic action handling - services provide their own logic
      // This is just a pass-through for demonstration
      // In practice, services would register handlers or use a different approach
      
      mainSendPort.send({
        'requestId': requestId,
        'error': false,
        'result': message['data'],
      });
    } catch (e) {
      mainSendPort.send({
        'requestId': requestId,
        'error': true,
        'message': e.toString(),
      });
    }
  }
}
