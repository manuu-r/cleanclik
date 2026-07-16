/// In-memory cache of JPEG snapshots for tracked detections.
///
/// The waste detection pipeline stores a cropped JPEG of each tracked object
/// here (keyed by ML Kit tracking ID) so that the on-device VLM can classify
/// the item after a pickup is confirmed, when the original camera frame is
/// long gone.
library;

import 'dart:collection';
import 'dart:typed_data';

class DetectionSnapshotCache {
  static final DetectionSnapshotCache instance = DetectionSnapshotCache._();

  DetectionSnapshotCache._();

  static const int _maxEntries = 24;
  static const Duration _maxAge = Duration(seconds: 30);

  final LinkedHashMap<String, _SnapshotEntry> _entries = LinkedHashMap();

  /// Store the latest snapshot for a tracked object, evicting stale entries.
  void put(String trackingId, Uint8List jpegBytes) {
    _entries.remove(trackingId);
    _entries[trackingId] = _SnapshotEntry(jpegBytes, DateTime.now());
    _evict();
  }

  /// Latest snapshot for the tracked object, or null if absent/expired.
  Uint8List? get(String trackingId) {
    final entry = _entries[trackingId];
    if (entry == null) return null;
    if (DateTime.now().difference(entry.capturedAt) > _maxAge) {
      _entries.remove(trackingId);
      return null;
    }
    return entry.jpegBytes;
  }

  void clear() => _entries.clear();

  void _evict() {
    final now = DateTime.now();
    _entries.removeWhere(
      (_, entry) => now.difference(entry.capturedAt) > _maxAge,
    );
    while (_entries.length > _maxEntries) {
      _entries.remove(_entries.keys.first);
    }
  }
}

class _SnapshotEntry {
  final Uint8List jpegBytes;
  final DateTime capturedAt;

  _SnapshotEntry(this.jpegBytes, this.capturedAt);
}
