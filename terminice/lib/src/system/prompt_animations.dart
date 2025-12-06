import 'dart:io' show sleep;
import 'dart:math' as math;

import 'prompt_runner.dart';
import 'key_bindings.dart';
import 'key_events.dart';
import '../style/theme.dart';

// ============================================================================
// PROMPT ANIMATIONS – Composable animation system for interactive prompts
// ============================================================================

/// `PromptAnimations` – Reusable animation effects for terminal prompts.
///
/// This system provides composable animation capabilities that can be added
/// to any prompt without modifying the prompt's core logic.
///
/// **Design principles:**
/// - Composition over inheritance
/// - Separation of concerns (animation separate from prompt logic)
/// - DRY: Centralizes animation patterns used across widgets
/// - Zero runtime cost when not used (lazy evaluation)
///
/// **Usage patterns:**
///
/// 1. **With AnimatedValuePrompt** (recommended for value prompts):
/// ```dart
/// final value = AnimatedValuePrompt(
///   prompt: ValuePrompt(title: 'Volume', min: 0, max: 100),
///   animations: PromptAnimations.smooth(),
/// ).run(render: (ctx, value, ratio) => renderSlider(ctx, ratio));
/// ```
///
/// 2. **Standalone animation runner**:
/// ```dart
/// PromptAnimations.smooth().runWithAnimation(
///   runner: PromptRunner(hideCursor: true),
///   render: (out, phase) => renderContent(out, phase.isPulsing),
///   bindings: myBindings,
///   initialValue: 50,
///   buildCurrentValue: () => currentValue,
/// );
/// ```
///
/// 3. **Custom animation sequences**:
/// ```dart
/// final anims = PromptAnimations(
///   entry: EntryAnimation.easeOut(frames: 15, durationMs: 120),
///   exit: ExitAnimation.shimmer(frames: 4),
///   pulse: PulseEffect.highlight,
/// );
/// ```
class PromptAnimations {
  /// Entry animation configuration.
  final EntryAnimation entry;

  /// Exit animation configuration.
  final ExitAnimation exit;

  /// Pulse effect for value changes.
  final PulseEffect pulse;

  const PromptAnimations({
    this.entry = EntryAnimation.none,
    this.exit = ExitAnimation.none,
    this.pulse = PulseEffect.none,
  });

  // ──────────────────────────────────────────────────────────────────────────
  // FACTORY PRESETS
  // ──────────────────────────────────────────────────────────────────────────

  /// No animations (instant transitions).
  static const PromptAnimations none = PromptAnimations();

  /// Smooth animations with easing (default for sliders).
  static PromptAnimations smooth({
    int entryFrames = 10,
    int entryDurationMs = 80,
    int exitFrames = 3,
    int exitDurationMs = 45,
  }) {
    return PromptAnimations(
      entry: EntryAnimation.easeOut(
        frames: entryFrames,
        durationMs: entryDurationMs,
      ),
      exit: ExitAnimation.shimmer(
        frames: exitFrames,
        durationMs: exitDurationMs,
      ),
      pulse: PulseEffect.highlight,
    );
  }

  /// Quick animations for responsive feel.
  static PromptAnimations quick({
    int entryFrames = 6,
    int entryDurationMs = 48,
  }) {
    return PromptAnimations(
      entry: EntryAnimation.easeOut(
        frames: entryFrames,
        durationMs: entryDurationMs,
      ),
      exit: ExitAnimation.flash(frames: 2),
      pulse: PulseEffect.subtle,
    );
  }

  /// Flashy animations for emphasis.
  static PromptAnimations flashy() {
    return PromptAnimations(
      entry: EntryAnimation.bounce(frames: 12, durationMs: 100),
      exit: ExitAnimation.shimmer(frames: 5, durationMs: 75),
      pulse: PulseEffect.bold,
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // BUILDER PATTERN
  // ──────────────────────────────────────────────────────────────────────────

  /// Creates a copy with modified entry animation.
  PromptAnimations withEntry(EntryAnimation entry) {
    return PromptAnimations(entry: entry, exit: exit, pulse: pulse);
  }

  /// Creates a copy with modified exit animation.
  PromptAnimations withExit(ExitAnimation exit) {
    return PromptAnimations(entry: entry, exit: exit, pulse: pulse);
  }

  /// Creates a copy with modified pulse effect.
  PromptAnimations withPulse(PulseEffect pulse) {
    return PromptAnimations(entry: entry, exit: exit, pulse: pulse);
  }

  /// Creates a copy with no entry animation.
  PromptAnimations withoutEntry() => withEntry(EntryAnimation.none);

  /// Creates a copy with no exit animation.
  PromptAnimations withoutExit() => withExit(ExitAnimation.none);

  /// Creates a copy with no pulse effect.
  PromptAnimations withoutPulse() => withPulse(PulseEffect.none);
}

// ============================================================================
// ENTRY ANIMATION
// ============================================================================

/// Configuration for prompt entry animations.
///
/// Entry animations play when the prompt first appears, typically animating
/// from a starting state to the initial value.
class EntryAnimation {
  /// Number of animation frames.
  final int frames;

  /// Total duration in milliseconds.
  final int durationMs;

  /// Easing function (0.0 to 1.0 input → 0.0 to 1.0 output).
  final double Function(double t) easing;

  /// Whether this animation is enabled.
  final bool enabled;

  const EntryAnimation._({
    this.frames = 0,
    this.durationMs = 0,
    required this.easing,
    this.enabled = true,
  });

  /// No entry animation.
  static const EntryAnimation none = EntryAnimation._(
    easing: _linear,
    enabled: false,
  );

  /// Linear interpolation (constant speed).
  static EntryAnimation linear({int frames = 10, int durationMs = 80}) {
    return EntryAnimation._(
      frames: frames,
      durationMs: durationMs,
      easing: _linear,
    );
  }

  /// Ease-out (fast start, slow end) - feels responsive.
  static EntryAnimation easeOut({int frames = 10, int durationMs = 80}) {
    return EntryAnimation._(
      frames: frames,
      durationMs: durationMs,
      easing: _easeOutQuad,
    );
  }

  /// Ease-in-out (slow start and end, fast middle).
  static EntryAnimation easeInOut({int frames = 10, int durationMs = 80}) {
    return EntryAnimation._(
      frames: frames,
      durationMs: durationMs,
      easing: _easeInOutQuad,
    );
  }

  /// Bounce effect (overshoots then settles).
  static EntryAnimation bounce({int frames = 12, int durationMs = 100}) {
    return EntryAnimation._(
      frames: frames,
      durationMs: durationMs,
      easing: _easeOutBounce,
    );
  }

  /// Custom easing function.
  static EntryAnimation custom({
    required int frames,
    required int durationMs,
    required double Function(double t) easing,
  }) {
    return EntryAnimation._(
      frames: frames,
      durationMs: durationMs,
      easing: easing,
    );
  }

  /// Delay per frame in milliseconds.
  int get frameDelayMs => frames > 0 ? (durationMs / frames).round() : 0;

  /// Generates animation values from start to end.
  ///
  /// [start] is the starting value (typically 0 or min).
  /// [end] is the target value (typically initial value).
  ///
  /// Returns an iterable of (value, frameIndex) pairs.
  Iterable<(double value, int frame)> animate(double start, double end) sync* {
    if (!enabled || frames <= 0) {
      yield (end, 0);
      return;
    }

    for (int i = 0; i <= frames; i++) {
      final t = i / frames;
      final easedT = easing(t);
      final value = start + (end - start) * easedT;
      yield (value, i);
    }
  }

  /// Runs the entry animation with the given render function.
  ///
  /// [out] is the render output.
  /// [start] is the starting value.
  /// [end] is the target value.
  /// [render] is called for each frame with the current value.
  void run({
    required RenderOutput out,
    required double start,
    required double end,
    required void Function(double value) render,
  }) {
    if (!enabled) {
      render(end);
      return;
    }

    for (final (value, frame) in animate(start, end)) {
      if (frame > 0) out.clear();
      render(value);
      if (frame < frames) {
        sleep(Duration(milliseconds: frameDelayMs));
      }
    }
  }
}

// ============================================================================
// EXIT ANIMATION
// ============================================================================

/// Configuration for prompt exit animations.
///
/// Exit animations play when the prompt confirms or cancels, providing
/// visual feedback before the prompt disappears.
class ExitAnimation {
  /// Number of animation frames.
  final int frames;

  /// Delay per frame in milliseconds.
  final int frameDelayMs;

  /// Whether this animation is enabled.
  final bool enabled;

  /// Animation style.
  final ExitStyle style;

  const ExitAnimation._({
    this.frames = 0,
    this.frameDelayMs = 15,
    this.enabled = true,
    this.style = ExitStyle.none,
  });

  /// No exit animation.
  static const ExitAnimation none = ExitAnimation._(enabled: false);

  /// Shimmer effect (alternating pulse).
  static ExitAnimation shimmer({int frames = 3, int durationMs = 45}) {
    return ExitAnimation._(
      frames: frames,
      frameDelayMs: frames > 0 ? (durationMs / frames).round() : 15,
      style: ExitStyle.shimmer,
    );
  }

  /// Quick flash effect.
  static ExitAnimation flash({int frames = 2, int durationMs = 30}) {
    return ExitAnimation._(
      frames: frames,
      frameDelayMs: frames > 0 ? (durationMs / frames).round() : 15,
      style: ExitStyle.flash,
    );
  }

  /// Fade out effect.
  static ExitAnimation fadeOut({int frames = 4, int durationMs = 60}) {
    return ExitAnimation._(
      frames: frames,
      frameDelayMs: frames > 0 ? (durationMs / frames).round() : 15,
      style: ExitStyle.fadeOut,
    );
  }

  /// Runs the exit animation with the given render function.
  ///
  /// [out] is the render output.
  /// [render] is called for each frame with animation state.
  void run({
    required RenderOutput out,
    required void Function(ExitAnimationFrame frame) render,
  }) {
    if (!enabled || frames <= 0) return;

    for (int i = 0; i < frames; i++) {
      out.clear();
      render(ExitAnimationFrame(
        frameIndex: i,
        totalFrames: frames,
        style: style,
      ));
      sleep(Duration(milliseconds: frameDelayMs));
    }
  }
}

/// Style options for exit animations.
enum ExitStyle {
  none,
  shimmer,
  flash,
  fadeOut,
}

/// Information about the current exit animation frame.
class ExitAnimationFrame {
  /// Current frame index (0-based).
  final int frameIndex;

  /// Total number of frames.
  final int totalFrames;

  /// Animation style.
  final ExitStyle style;

  const ExitAnimationFrame({
    required this.frameIndex,
    required this.totalFrames,
    required this.style,
  });

  /// Progress ratio (0.0 to 1.0).
  double get progress => totalFrames > 0 ? frameIndex / totalFrames : 1.0;

  /// Whether this is an "on" frame for shimmer/flash effects.
  bool get isPulseOn => frameIndex.isEven;

  /// Whether this is the last frame.
  bool get isLast => frameIndex >= totalFrames - 1;
}

// ============================================================================
// PULSE EFFECT
// ============================================================================

/// Configuration for value change pulse effects.
///
/// Pulse effects provide visual feedback when the value changes,
/// making the interaction feel more responsive.
enum PulseEffect {
  /// No pulse effect.
  none,

  /// Subtle pulse (slightly brighter).
  subtle,

  /// Standard highlight pulse.
  highlight,

  /// Bold emphasis pulse.
  bold,
}

/// Extension for pulse effect styling.
extension PulseEffectStyling on PulseEffect {
  /// Whether this effect is enabled.
  bool get enabled => this != PulseEffect.none;

  /// Gets style modifiers for the pulse effect.
  PulseStyleModifiers getModifiers(PromptTheme theme, {required bool active}) {
    if (!active || !enabled) {
      return PulseStyleModifiers.none;
    }

    switch (this) {
      case PulseEffect.none:
        return PulseStyleModifiers.none;
      case PulseEffect.subtle:
        return PulseStyleModifiers(
          colorOverride: theme.highlight,
          useBold: false,
        );
      case PulseEffect.highlight:
        return PulseStyleModifiers(
          colorOverride: theme.bold,
          useBold: true,
        );
      case PulseEffect.bold:
        return PulseStyleModifiers(
          colorOverride: theme.bold,
          useBold: true,
          useInverse: true,
        );
    }
  }
}

/// Style modifiers applied during pulse effect.
class PulseStyleModifiers {
  /// Color override (or null for default).
  final String? colorOverride;

  /// Whether to use bold styling.
  final bool useBold;

  /// Whether to use inverse styling.
  final bool useInverse;

  const PulseStyleModifiers({
    this.colorOverride,
    this.useBold = false,
    this.useInverse = false,
  });

  /// No modifiers (default styling).
  static const PulseStyleModifiers none = PulseStyleModifiers();

  /// Whether any modifiers are active.
  bool get hasModifiers => colorOverride != null || useBold || useInverse;
}

// ============================================================================
// ANIMATION STATE
// ============================================================================

/// Tracks the current animation state during prompt execution.
///
/// This is passed to render functions to allow them to apply appropriate
/// styling based on the current animation phase.
class AnimationPhase {
  /// Whether currently in entry animation.
  final bool isEntry;

  /// Whether currently in exit animation.
  final bool isExit;

  /// Whether value just changed (pulse active).
  final bool isPulsing;

  /// Current exit animation frame (if in exit).
  final ExitAnimationFrame? exitFrame;

  /// Entry animation progress (0.0 to 1.0).
  final double entryProgress;

  const AnimationPhase({
    this.isEntry = false,
    this.isExit = false,
    this.isPulsing = false,
    this.exitFrame,
    this.entryProgress = 1.0,
  });

  /// Default phase (no animation active).
  static const AnimationPhase normal = AnimationPhase();

  /// Entry animation phase.
  static AnimationPhase entry(double progress) => AnimationPhase(
        isEntry: true,
        entryProgress: progress,
      );

  /// Exit animation phase.
  static AnimationPhase exit(ExitAnimationFrame frame) => AnimationPhase(
        isExit: true,
        exitFrame: frame,
      );

  /// Pulse phase (value changed).
  static const AnimationPhase pulse = AnimationPhase(isPulsing: true);

  /// Whether any animation is currently active.
  bool get isAnimating => isEntry || isExit || isPulsing;
}

// ============================================================================
// EASING FUNCTIONS
// ============================================================================

/// Standard easing functions for animations.
///
/// These can be used directly or with [EntryAnimation.custom].
/// Exported for reuse across the library (e.g., ProgressBar).
///
/// **Usage:**
/// ```dart
/// // Direct use
/// final easedT = Easing.easeOutQuad(t);
///
/// // With EntryAnimation
/// EntryAnimation.custom(
///   frames: 10,
///   durationMs: 100,
///   easing: Easing.easeInOutCubic,
/// );
/// ```
class Easing {
  Easing._();

  /// Linear interpolation (constant speed).
  static double linear(double t) => t;

  /// Quadratic ease-out (fast start, slow end).
  static double easeOutQuad(double t) => 1 - (1 - t) * (1 - t);

  /// Quadratic ease-in (slow start, fast end).
  static double easeInQuad(double t) => t * t;

  /// Quadratic ease-in-out (slow start and end).
  static double easeInOutQuad(double t) {
    return t < 0.5 ? 2 * t * t : 1 - math.pow(-2 * t + 2, 2) / 2;
  }

  /// Cubic ease-out (fast start, very slow end).
  static num easeOutCubic(double t) => 1 - math.pow(1 - t, 3);

  /// Cubic ease-in (very slow start, fast end).
  static double easeInCubic(double t) => t * t * t;

  /// Cubic ease-in-out (smooth start and end).
  static double easeInOutCubic(double t) {
    if (t < 0.5) {
      return 4 * t * t * t;
    } else {
      final f = ((2 * t) - 2);
      return 0.5 * f * f * f + 1;
    }
  }

  /// Bounce ease-out (bouncy end).
  static double easeOutBounce(double t) {
    const n1 = 7.5625;
    const d1 = 2.75;

    if (t < 1 / d1) {
      return n1 * t * t;
    } else if (t < 2 / d1) {
      final t2 = t - 1.5 / d1;
      return n1 * t2 * t2 + 0.75;
    } else if (t < 2.5 / d1) {
      final t2 = t - 2.25 / d1;
      return n1 * t2 * t2 + 0.9375;
    } else {
      final t2 = t - 2.625 / d1;
      return n1 * t2 * t2 + 0.984375;
    }
  }

  /// Elastic ease-out (springy overshoot).
  static double easeOutElastic(double t) {
    const c4 = (2 * math.pi) / 3;
    if (t == 0) return 0;
    if (t == 1) return 1;
    return math.pow(2, -10 * t) * math.sin((t * 10 - 0.75) * c4) + 1;
  }

  /// Back ease-out (slight overshoot then settle).
  static double easeOutBack(double t) {
    const c1 = 1.70158;
    const c3 = c1 + 1;
    return 1 + c3 * math.pow(t - 1, 3) + c1 * math.pow(t - 1, 2);
  }
}

// Private aliases for internal use (backward compat)
double _linear(double t) => Easing.linear(t);
double _easeOutQuad(double t) => Easing.easeOutQuad(t);
double _easeInOutQuad(double t) => Easing.easeInOutQuad(t);
double _easeOutBounce(double t) => Easing.easeOutBounce(t);

// ============================================================================
// ANIMATED PROMPT RUNNER
// ============================================================================

/// Extension to run prompts with animations.
extension AnimatedPromptRunner on PromptAnimations {
  /// Runs a prompt with entry/exit animations and pulse effects.
  ///
  /// This is the low-level API for integrating animations with custom prompts.
  /// For value prompts, prefer using [AnimatedValuePrompt].
  ///
  /// [runner] is the PromptRunner to use.
  /// [render] is called for each frame with current animation phase.
  /// [bindings] handles key input.
  /// [initialValue] is the starting value for entry animation.
  /// [buildCurrentValue] returns the current value (for pulse detection).
  /// [minValue] is the minimum value (for entry animation start point).
  PromptResult runWithAnimation({
    required PromptRunner runner,
    required void Function(RenderOutput out, AnimationPhase phase) render,
    required KeyBindings bindings,
    required num initialValue,
    required num Function() buildCurrentValue,
    num minValue = 0,
  }) {
    return runner.runCustom((out) {
      // Entry animation
      if (entry.enabled) {
        entry.run(
          out: out,
          start: minValue.toDouble(),
          end: initialValue.toDouble(),
          render: (value) {
            final progress = entry.frames > 0
                ? (value - minValue) / (initialValue - minValue)
                : 1.0;
            render(out, AnimationPhase.entry(progress.clamp(0.0, 1.0)));
          },
        );
      } else {
        render(out, AnimationPhase.normal);
      }

      // Track previous value for pulse detection
      num prevValue = initialValue;
      bool cancelled = false;

      // Main input loop
      while (true) {
        final ev = KeyEventReader.read();
        final result = bindings.handle(ev);

        if (result == KeyActionResult.confirmed) break;
        if (result == KeyActionResult.cancelled) {
          cancelled = true;
          break;
        }

        final currentValue = buildCurrentValue();
        final valueChanged = currentValue != prevValue;
        prevValue = currentValue;

        if (result == KeyActionResult.handled || valueChanged) {
          out.clear();
          render(
            out,
            valueChanged && pulse.enabled
                ? AnimationPhase.pulse
                : AnimationPhase.normal,
          );
        }
      }

      // Exit animation
      if (exit.enabled) {
        exit.run(
          out: out,
          render: (frame) => render(out, AnimationPhase.exit(frame)),
        );
      }

      return cancelled ? PromptResult.cancelled : PromptResult.confirmed;
    });
  }
}

// ============================================================================
// ANIMATABLE MIXIN – DRY builder pattern for animation-enabled prompts
// ============================================================================

/// Mixin for prompts that support animations.
///
/// Implementing this mixin provides automatic builder methods via the
/// [AnimatableBuilder] extension, eliminating boilerplate across widgets.
///
/// **Why use this pattern?**
/// - **DRY**: Define animation properties once, get all builder methods free
/// - **Consistency**: All animatable prompts have the same API
/// - **Scalability**: New animation presets are added once, available everywhere
/// - **Type-safe**: Builder methods return the correct concrete type
///
/// **Implementation:**
///
/// 1. Add `with Animatable` to your prompt class
/// 2. Add `animated` and `animations` fields
/// 3. Implement `copyWithAnimations` to create a copy with new settings
///
/// ```dart
/// class MyPrompt with Animatable {
///   final String label;
///   @override
///   final bool animated;
///   @override
///   final PromptAnimations? animations;
///
///   MyPrompt(this.label, {this.animated = false, this.animations});
///
///   @override
///   MyPrompt copyWithAnimations({bool? animated, PromptAnimations? animations}) {
///     return MyPrompt(
///       label,
///       animated: animated ?? this.animated,
///       animations: animations ?? this.animations,
///     );
///   }
/// }
///
/// // Now you get all these methods automatically:
/// final prompt = MyPrompt('Test')
///   .withAnimations()           // Enable with default
///   .withQuickAnimations()      // Enable with quick preset
///   .withSmoothAnimations()     // Enable with smooth preset
///   .withFlashyAnimations()     // Enable with flashy preset
///   .withoutAnimations();       // Disable animations
/// ```
mixin Animatable {
  /// Whether animations are enabled by default.
  bool get animated;

  /// Custom animation configuration (overrides [animated]).
  PromptAnimations? get animations;

  /// Creates a copy with modified animation settings.
  ///
  /// Implementers should copy all fields and apply the new animation settings.
  /// Use null to preserve existing values.
  Animatable copyWithAnimations({
    bool? animated,
    PromptAnimations? animations,
  });
}

/// Builder extensions for [Animatable] prompts.
///
/// Provides a fluent API for configuring animations on any prompt
/// that implements [Animatable]. All methods return the same concrete
/// type as the receiver, enabling type-safe chaining.
///
/// **Available methods:**
/// - [withAnimations] - Enable with optional custom config
/// - [withoutAnimations] - Disable all animations
/// - [withQuickAnimations] - Fast, responsive animations
/// - [withSmoothAnimations] - Polished, eased animations
/// - [withFlashyAnimations] - Bold, attention-grabbing animations
/// - [withCustomAnimations] - Full control over animation config
///
/// **Example:**
/// ```dart
/// final result = SliderPrompt('Volume')
///   .withSmoothAnimations()
///   .run();
/// ```
extension AnimatableBuilder<T extends Animatable> on T {
  /// Creates a copy with animations enabled.
  ///
  /// If [animations] is provided, uses that configuration.
  /// Otherwise, uses the default animation preset for the widget.
  T withAnimations([PromptAnimations? animations]) {
    return copyWithAnimations(
      animated: true,
      animations: animations,
    ) as T;
  }

  /// Creates a copy with animations disabled.
  ///
  /// Useful for performance-critical scenarios or accessibility needs.
  T withoutAnimations() {
    return copyWithAnimations(
      animated: false,
      animations: PromptAnimations.none,
    ) as T;
  }

  /// Creates a copy with quick, responsive animations.
  ///
  /// Best for: Short interactions, confirmations, rapid feedback.
  /// Entry: 6 frames, 48ms | Exit: Flash | Pulse: Subtle
  T withQuickAnimations() {
    return copyWithAnimations(
      animated: true,
      animations: PromptAnimations.quick(),
    ) as T;
  }

  /// Creates a copy with smooth, polished animations.
  ///
  /// Best for: Sliders, ranges, value selection with visual feedback.
  /// Entry: 10 frames, 80ms | Exit: Shimmer | Pulse: Highlight
  T withSmoothAnimations() {
    return copyWithAnimations(
      animated: true,
      animations: PromptAnimations.smooth(),
    ) as T;
  }

  /// Creates a copy with flashy, attention-grabbing animations.
  ///
  /// Best for: Important selections, celebrations, emphasis.
  /// Entry: 12 frames, bounce | Exit: Shimmer | Pulse: Bold
  T withFlashyAnimations() {
    return copyWithAnimations(
      animated: true,
      animations: PromptAnimations.flashy(),
    ) as T;
  }

  /// Creates a copy with fully custom animation configuration.
  ///
  /// For complete control over entry, exit, and pulse animations.
  ///
  /// ```dart
  /// prompt.withCustomAnimations(
  ///   PromptAnimations(
  ///     entry: EntryAnimation.bounce(frames: 20, durationMs: 200),
  ///     exit: ExitAnimation.fadeOut(frames: 8),
  ///     pulse: PulseEffect.bold,
  ///   ),
  /// );
  /// ```
  T withCustomAnimations(PromptAnimations animations) {
    return copyWithAnimations(
      animated: true,
      animations: animations,
    ) as T;
  }

  /// Resolves the effective animation configuration.
  ///
  /// Returns [animations] if set, otherwise returns the appropriate preset
  /// based on [animated] flag.
  ///
  /// [defaultAnimated] - The preset to use when [animated] is true but
  /// [animations] is null. Defaults to [PromptAnimations.smooth].
  PromptAnimations resolveAnimations([
    PromptAnimations Function()? defaultAnimated,
  ]) {
    if (animations != null) return animations!;
    if (!animated) return PromptAnimations.none;
    return (defaultAnimated ?? PromptAnimations.smooth)();
  }

  /// Whether any animation is effectively enabled.
  bool get hasAnimations {
    final resolved = resolveAnimations();
    return resolved.entry.enabled ||
        resolved.exit.enabled ||
        resolved.pulse.enabled;
  }
}
