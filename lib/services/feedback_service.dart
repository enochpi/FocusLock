import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

class FeedbackService {
  static final FeedbackService _instance = FeedbackService._internal();
  factory FeedbackService() => _instance;
  FeedbackService._internal();

  /// Vibrate when blocked app detected
  Future<void> vibrateOnBlock() async {
    try {
      await HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 100));
      await HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 100));
      await HapticFeedback.heavyImpact();
    } catch (e) {
      debugPrint('Vibration error: $e');
    }
  }

  /// Light vibration for success
  Future<void> vibrateOnSuccess() async {
    try {
      await HapticFeedback.mediumImpact();
    } catch (e) {
      debugPrint('Vibration error: $e');
    }
  }

  /// Very light tap
  Future<void> vibrateTap() async {
    try {
      await HapticFeedback.lightImpact();
    } catch (e) {
      debugPrint('Vibration error: $e');
    }
  }
}