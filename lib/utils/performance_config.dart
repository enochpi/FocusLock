import 'dart:io';

class PerformanceConfig {
  static final PerformanceConfig _instance = PerformanceConfig._internal();
  factory PerformanceConfig() => _instance;
  PerformanceConfig._internal();

  // ✅ Set to false on low-end devices to skip expensive blur effects
  // Can be detected automatically or set by user in settings
  bool enableBlurEffects = true;
  bool enableParticles   = true;
  bool enableButterfly   = true;

  /// Call this on app start to auto-detect device capability
  /// based on available memory or other heuristics
  void autoDetect() {
    // On Android, we can check if it's a low RAM device
    // For now default to enabled — user can toggle in settings
    enableBlurEffects = true;
    enableParticles   = true;
    enableButterfly   = true;
  }
}