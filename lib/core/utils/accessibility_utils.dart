import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';

// Haptic feedback types
enum FeedbackType {
  lightImpact,
  mediumImpact,
  heavyImpact,
  selectionClick,
  vibrate,
}

class AccessibilityUtils {
  // Check if screen reader is enabled
  static bool get isScreenReaderEnabled {
    return WidgetsBinding
        .instance
        .platformDispatcher
        .accessibilityFeatures
        .accessibleNavigation;
  }

  // Check if high contrast is enabled
  static bool get isHighContrastEnabled {
    return WidgetsBinding
        .instance
        .platformDispatcher
        .accessibilityFeatures
        .highContrast;
  }

  // Check if reduce motion is enabled
  static bool get isReduceMotionEnabled {
    return WidgetsBinding
        .instance
        .platformDispatcher
        .accessibilityFeatures
        .reduceMotion;
  }

  // Check if bold text is enabled
  static bool get isBoldTextEnabled {
    return WidgetsBinding
        .instance
        .platformDispatcher
        .accessibilityFeatures
        .boldText;
  }

  // Announce message to screen reader
  static void announce(String message, {TextDirection? textDirection}) {
    SemanticsService.announce(message, textDirection ?? TextDirection.ltr);
  }

  // Create semantic label for buttons
  static String createButtonLabel(String text, {String? hint}) {
    if (hint != null) {
      return '$text. $hint';
    }
    return '$text button';
  }

  // Provide haptic feedback
  static void provideFeedback(FeedbackType type) {
    switch (type) {
      case FeedbackType.lightImpact:
        HapticFeedback.lightImpact();
        break;
      case FeedbackType.mediumImpact:
        HapticFeedback.mediumImpact();
        break;
      case FeedbackType.heavyImpact:
        HapticFeedback.heavyImpact();
        break;
      case FeedbackType.selectionClick:
        HapticFeedback.selectionClick();
        break;
      case FeedbackType.vibrate:
        HapticFeedback.vibrate();
        break;
    }
  }

  // Get appropriate touch target size
  static double getTouchTargetSize() {
    return 48.0; // Minimum recommended touch target size
  }

  // Create accessible list item
  static Widget createAccessibleListItem({
    required Widget child,
    required String semanticLabel,
    VoidCallback? onTap,
    String? hint,
    bool selected = false,
  }) {
    return Semantics(
      label: semanticLabel,
      hint: hint,
      button: onTap != null,
      selected: selected,
      child: InkWell(onTap: onTap, child: child),
    );
  }
}
