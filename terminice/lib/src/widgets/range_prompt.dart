import 'dart:math' as math;

import '../style/theme.dart';
import '../system/prompt_animations.dart';
import '../system/terminal.dart';
import '../system/value_prompt.dart';
import '../system/widget_frame.dart';

/// RangePrompt – select a numeric or percent range with two handles.
///
/// Controls:
/// - ← / → adjust active handle
/// - ↑ / ↓ or Space toggles which handle is active (start/end)
/// - Enter confirms
/// - Esc / Ctrl+C cancels (returns initial values)
///
/// **Implementation:** Uses [AnimatedRangeValuePrompt] when animations are enabled,
/// demonstrating composition over inheritance.
///
/// **Mixins:** Implements [Animatable] and [Themeable] for fluent configuration:
/// ```dart
/// final (start, end) = RangePrompt('Price Range')
///   .withMatrixTheme()        // Theme customization
///   .withSmoothAnimations()   // Animation customization
///   .run();
/// ```
///
/// **Example:**
/// ```dart
/// // Basic usage
/// final (start, end) = RangePrompt('Price Range').run();
///
/// // With theme and animations (fluent API)
/// final (start, end) = RangePrompt('Price Range')
///   .withFireTheme()
///   .withQuickAnimations()
///   .run();
/// ```
class RangePrompt with Animatable, Themeable {
  final String label;
  final num min;
  final num max;
  final num startInitial;
  final num endInitial;
  final num step;
  @override
  final PromptTheme theme;
  final int width;
  final String unit; // "%" for percent, "" for plain numbers

  /// Whether to show animations (entry/exit/pulse).
  @override
  final bool animated;

  /// Custom animation configuration (overrides [animated]).
  @override
  final PromptAnimations? animations;

  RangePrompt(
    this.label, {
    this.min = 0,
    this.max = 100,
    this.startInitial = 20,
    this.endInitial = 80,
    this.step = 1,
    this.theme = PromptTheme.dark,
    this.width = 28,
    this.unit = '%',
    this.animated = false,
    this.animations,
  });

  @override
  RangePrompt copyWithAnimations(
      {bool? animated, PromptAnimations? animations}) {
    return RangePrompt(
      label,
      min: min,
      max: max,
      startInitial: startInitial,
      endInitial: endInitial,
      step: step,
      theme: theme,
      width: width,
      unit: unit,
      animated: animated ?? this.animated,
      animations: animations ?? this.animations,
    );
  }

  @override
  RangePrompt copyWithTheme(PromptTheme theme) {
    return RangePrompt(
      label,
      min: min,
      max: max,
      startInitial: startInitial,
      endInitial: endInitial,
      step: step,
      theme: theme,
      width: width,
      unit: unit,
      animated: animated,
      animations: animations,
    );
  }

  /// Returns the selected range as (start: x, end: y)
  (num start, num end) run() {
    // Use Animatable helper to resolve animation configuration
    final anims = resolveAnimations(PromptAnimations.quick);

    // Use animated prompt if any animation is enabled
    if (anims.entry.enabled || anims.exit.enabled || anims.pulse.enabled) {
      return _runAnimated(anims);
    }

    return _runSimple();
  }

  (num, num) _runSimple() {
    final rangePrompt = RangeValuePrompt(
      title: label,
      min: min,
      max: max,
      startInitial: startInitial,
      endInitial: endInitial,
      step: step,
      theme: theme,
    );

    return rangePrompt.run(
      render: (ctx, start, end, editingStart) {
        _renderBar(ctx, start, end, editingStart);
      },
    );
  }

  (num, num) _runAnimated(PromptAnimations anims) {
    final rangePrompt = AnimatedRangeValuePrompt(
      title: label,
      min: min,
      max: max,
      startInitial: startInitial,
      endInitial: endInitial,
      step: step,
      theme: theme,
      animations: anims,
    );

    return rangePrompt.run(
      render: (ctx, start, end, editingStart, phase) {
        _renderBar(ctx, start, end, editingStart, phase: phase);
      },
    );
  }

  void _renderBar(
    FrameContext ctx,
    num start,
    num end,
    bool editingStart, {
    AnimationPhase phase = AnimationPhase.normal,
  }) {
    // Animation state
    final isPulsing = phase.isPulsing;
    final isExitPulse = phase.exitFrame?.isPulseOn ?? false;
    final isFlare = phase.isExit && isExitPulse;

    // Effective width (responsive to terminal columns)
    final effWidth = math.max(10, math.min(width, TerminalInfo.columns - 8));

    int valueToIndex(num v, int w) {
      final ratio = (v - min) / (max - min);
      return (ratio * w).round().clamp(0, w);
    }

    // Compute positions
    final startIdx = valueToIndex(start, effWidth);
    final endIdx = valueToIndex(end, effWidth);

    // Format values
    final sRaw = (start == start.roundToDouble()
            ? start.toInt().toString()
            : start.toStringAsFixed(1)) +
        unit;
    final eRaw = (end == end.roundToDouble()
            ? end.toInt().toString()
            : end.toStringAsFixed(1)) +
        unit;

    // Layout
    final displayLen = sRaw.length + 1 + eRaw.length;
    final centerIdx = ((startIdx + endIdx) / 2).round();
    final leftPad = math.max(0, centerIdx - (displayLen ~/ 2));

    // Range text with animation styling
    String rangeTxt;
    if (isPulsing || isFlare) {
      rangeTxt =
          '${theme.bold}${theme.inverse}${theme.accent}$sRaw—$eRaw${theme.reset}';
    } else {
      rangeTxt = '${theme.bold}${theme.accent}$sRaw—$eRaw${theme.reset}';
    }

    final border = '${theme.gray}┃${theme.reset}';
    final activeIdx = editingStart ? startIdx : endIdx;

    // Caret pointer with animation styling
    final caretChar = isPulsing || isFlare ? '▼' : '^';
    ctx.line(
        '$border${' ' * (2 + activeIdx)}${theme.accent}$caretChar${theme.reset}');
    ctx.line('$border${' ' * (2 + leftPad)}$rangeTxt');

    // Bar with handles
    final barLine = StringBuffer();
    barLine.write('$border ');
    for (int i = 0; i <= effWidth; i++) {
      if (i == startIdx) {
        final isActive = editingStart;
        String glyph;
        if (isActive && (isPulsing || isFlare)) {
          glyph = '${theme.bold}${theme.inverse}${theme.accent}█${theme.reset}';
        } else if (isActive) {
          glyph = '${theme.inverse}${theme.accent}█${theme.reset}';
        } else {
          glyph = '${theme.accent}█${theme.reset}';
        }
        barLine.write(glyph);
      } else if (i == endIdx) {
        final isActive = !editingStart;
        String glyph;
        if (isActive && (isPulsing || isFlare)) {
          glyph = '${theme.bold}${theme.inverse}${theme.accent}█${theme.reset}';
        } else if (isActive) {
          glyph = '${theme.inverse}${theme.accent}█${theme.reset}';
        } else {
          glyph = '${theme.accent}█${theme.reset}';
        }
        barLine.write(glyph);
      } else if (i > startIdx && i < endIdx) {
        final char = isPulsing || isFlare ? '━' : '━';
        barLine.write('${theme.accent}$char${theme.reset}');
      } else if (i < effWidth) {
        barLine.write('${theme.dim}·${theme.reset}');
      }
    }
    ctx.line(barLine.toString());

    // Active indicator with animation styling
    final activeLabel = editingStart ? 'start' : 'end';
    if (isPulsing || isFlare) {
      ctx.gutterLine(
          '${theme.dim}Active:${theme.reset} ${theme.bold}${theme.accent}$activeLabel${theme.reset}');
    } else {
      ctx.labeledAccent('Active', activeLabel);
    }
  }
}

// Builder methods (withAnimations, withSmoothAnimations, etc.) are provided
// automatically by the Animatable mixin. See AnimatableBuilder extension.
