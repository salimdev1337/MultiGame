import 'package:flutter/painting.dart';
import 'package:multigame/utils/secure_logger.dart';

/// Manages Flutter's image cache for optimal game image performance.
///
/// Sets cache limits, provides preloading helpers, and exposes cache stats.
/// Uses Flutter's built-in [PaintingBinding.imageCache] — no extra packages needed.
class ImageCacheService {
  static const int _maxCacheSizeMB = 100;
  static const int _maxCacheObjects = 200;

  bool _isInitialized = false;

  // ── Initialization ───────────────────────────────────────────────────────

  void initialize() {
    if (_isInitialized) return;
    final cache = PaintingBinding.instance.imageCache;
    cache.maximumSizeBytes = _maxCacheSizeMB * 1024 * 1024;
    cache.maximumSize = _maxCacheObjects;
    _isInitialized = true;
    SecureLogger.log(
      'ImageCache configured: ${_maxCacheSizeMB}MB, $_maxCacheObjects objects',
      tag: 'Performance',
    );
  }

  // ── Cache Stats ──────────────────────────────────────────────────────────

  /// Current number of cached images.
  int get cachedCount => PaintingBinding.instance.imageCache.currentSize;

  /// Current cache size in bytes.
  int get cacheSizeBytes =>
      PaintingBinding.instance.imageCache.currentSizeBytes;

  /// Current cache size in MB.
  double get cacheSizeMB => cacheSizeBytes / (1024 * 1024);

  // ── Cache Control ─────────────────────────────────────────────────────────

  /// Clear all cached images to free memory.
  void clearCache() {
    PaintingBinding.instance.imageCache.clear();
    SecureLogger.log('Image cache cleared', tag: 'Performance');
  }

  /// Clear live (in-use) images from cache.
  void clearLiveImages() {
    PaintingBinding.instance.imageCache.clearLiveImages();
    SecureLogger.log('Live images cleared from cache', tag: 'Performance');
  }

  /// Reduce cache size for low-memory conditions (battery saver mode).
  void reduceCacheForBatterySaver() {
    final cache = PaintingBinding.instance.imageCache;
    cache.maximumSizeBytes = 30 * 1024 * 1024; // 30 MB
    cache.maximumSize = 50;
  }

  /// Restore cache to full size.
  void restoreFullCache() {
    final cache = PaintingBinding.instance.imageCache;
    cache.maximumSizeBytes = _maxCacheSizeMB * 1024 * 1024;
    cache.maximumSize = _maxCacheObjects;
  }

  Map<String, dynamic> getStats() => {
    'cachedObjects': cachedCount,
    'cacheSizeMB': cacheSizeMB.toStringAsFixed(1),
    'maxSizeMB': _maxCacheSizeMB,
    'maxObjects': _maxCacheObjects,
  };
}
