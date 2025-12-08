// ============================================================================
// SHARED STYLE ENUMS
// ============================================================================

/// Badge/label tones for consistent color theming across widgets.
///
/// Used by [Badge], [InlineStyle], [FrameContext] and other components
/// that need semantic color variants.
enum BadgeTone {
  /// Neutral/default (gray)
  neutral,

  /// Informational (accent color)
  info,

  /// Success/positive (green/checkbox-on color)
  success,

  /// Warning (highlight/yellow color)
  warning,

  /// Danger/error (red color)
  danger,
}
