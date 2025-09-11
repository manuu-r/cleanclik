import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cleanclik/core/services/system/logging_service.dart';

/// Debug overlay widget for development mode performance monitoring
class DebugOverlayWidget extends StatefulWidget {
  final Widget child;
  final bool enabled;

  const DebugOverlayWidget({
    super.key,
    required this.child,
    this.enabled = false,
  });

  @override
  State<DebugOverlayWidget> createState() => _DebugOverlayWidgetState();
}

class _DebugOverlayWidgetState extends State<DebugOverlayWidget> {
  Timer? _updateTimer;
  bool _isVisible = false;

  // Performance metrics
  int _fps = 0;
  double _memoryUsage = 0.0;
  int _frameTime = 0;
  List<PerformanceMetric> _recentMetrics = [];

  // Frame rate calculation
  int _frameCount = 0;
  DateTime _lastFpsUpdate = DateTime.now();

  @override
  void initState() {
    super.initState();
    if (widget.enabled) {
      _startMonitoring();
    }
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  void _startMonitoring() {
    _updateTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        _updateMetrics();
      }
    });
  }

  void _updateMetrics() {
    setState(() {
      // Update FPS
      final now = DateTime.now();
      final elapsed = now.difference(_lastFpsUpdate);
      if (elapsed.inMilliseconds > 0) {
        _fps = (_frameCount * 1000 / elapsed.inMilliseconds).round();
        _frameCount = 0;
        _lastFpsUpdate = now;
      }

      // Get recent performance metrics
      _recentMetrics = logger.getRecentMetrics(
        since: const Duration(seconds: 5),
      );

      // Calculate average frame time from recent metrics
      final frameTimes = _recentMetrics
          .where(
            (m) =>
                m.operation.contains('frame') ||
                m.operation.contains('detection'),
          )
          .map((m) => m.duration.inMilliseconds)
          .toList();

      if (frameTimes.isNotEmpty) {
        _frameTime = (frameTimes.reduce((a, b) => a + b) / frameTimes.length)
            .round();
      }
    });
  }

  void _toggleVisibility() {
    setState(() {
      _isVisible = !_isVisible;
    });

    // Haptic feedback
    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return widget.child;
    }

    // Ensure we have proper context before rendering debug UI
    try {
      // This will throw if Directionality is not available
      Directionality.of(context);
    } catch (e) {
      // Return child without debug overlay if context is not ready
      return widget.child;
    }

    // Count frames for FPS calculation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _frameCount++;
    });

    return Stack(
      children: [
        widget.child,

        // Debug toggle button
        Positioned(
          top: MediaQuery.of(context).padding.top + 10,
          right: 10,
          child: GestureDetector(
            onTap: _toggleVisibility,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.green, width: 1),
              ),
              child: const Icon(
                Icons.bug_report,
                color: Colors.green,
                size: 20,
              ),
            ),
          ),
        ),

        // Debug overlay panel
        if (_isVisible)
          Positioned(
            top: MediaQuery.of(context).padding.top + 60,
            right: 10,
            child: _buildDebugPanel(),
          ),
      ],
    );
  }

  Widget _buildDebugPanel() {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.85),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.analytics, color: Colors.green, size: 16),
              const SizedBox(width: 8),
              const Text(
                'Performance Monitor',
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _toggleVisibility,
                child: const Icon(Icons.close, color: Colors.white54, size: 16),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Performance metrics
          _buildMetricRow('FPS', '$_fps', _getFpsColor()),
          _buildMetricRow(
            'Frame Time',
            '${_frameTime}ms',
            _getFrameTimeColor(),
          ),
          _buildMetricRow(
            'Memory',
            '${_memoryUsage.toStringAsFixed(1)}MB',
            Colors.blue,
          ),

          const SizedBox(height: 8),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 8),

          // Recent operations
          const Text(
            'Recent Operations',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),

          ..._recentMetrics.take(5).map((metric) => _buildOperationRow(metric)),

          const SizedBox(height: 8),

          // Log level controls
          Row(
            children: [
              const Text(
                'Log Level:',
                style: TextStyle(color: Colors.white70, fontSize: 11),
              ),
              const SizedBox(width: 8),
              _buildLogLevelButton(LogLevel.debug),
              _buildLogLevelButton(LogLevel.info),
              _buildLogLevelButton(LogLevel.warning),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOperationRow(PerformanceMetric metric) {
    final color = metric.duration.inMilliseconds > 100
        ? Colors.red
        : Colors.white54;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        children: [
          Expanded(
            child: Text(
              metric.operation,
              style: TextStyle(color: color, fontSize: 10),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '${metric.duration.inMilliseconds}ms',
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogLevelButton(LogLevel level) {
    final isActive = LoggingService.instance.currentLevel == level;

    return GestureDetector(
      onTap: () {
        logger.setLogLevel(level);
        setState(() {});
      },
      child: Container(
        margin: const EdgeInsets.only(right: 4),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: isActive ? Colors.green.withOpacity(0.3) : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isActive ? Colors.green : Colors.white24,
            width: 1,
          ),
        ),
        child: Text(
          level.name.toUpperCase(),
          style: TextStyle(
            color: isActive ? Colors.green : Colors.white54,
            fontSize: 9,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Color _getFpsColor() {
    if (_fps >= 30) return Colors.green;
    if (_fps >= 15) return Colors.orange;
    return Colors.red;
  }

  Color _getFrameTimeColor() {
    if (_frameTime <= 33) return Colors.green; // 30 FPS
    if (_frameTime <= 66) return Colors.orange; // 15 FPS
    return Colors.red;
  }
}
