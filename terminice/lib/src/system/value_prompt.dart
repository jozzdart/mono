import 'dart:math' as math;

import 'key_bindings.dart';
import 'key_events.dart';
import 'prompt_animations.dart';
import 'widget_frame.dart';
import 'prompt_runner.dart';
import '../style/theme.dart';

/// ValuePrompt – composable system for continuous value selection.
///
/// Handles patterns for numeric/continuous value input:
/// - Sliders (single value)
/// - Ratings (discrete stars)
/// - Ranges (two values with handles)
///
/// **Design principles:**
/// - Composition over inheritance
/// - Separation of concerns (value management separate from rendering)
/// - DRY: Centralizes continuous value patterns
///
/// **Usage:**
/// ```dart
/// final prompt = ValuePrompt(
///   title: 'Volume',
///   min: 0,
///   max: 100,
///   initial: 50,
/// );
///
/// final value = prompt.run(
///   render: (ctx, value, ratio) {
///     ctx.progressBar(ratio);
///     ctx.labeledAccent('Value', '$value%');
///   },
/// );
/// ```
class ValuePrompt {
  /// Title for the frame header.
  final String title;

  /// Minimum value.
  final num min;

  /// Maximum value.
  final num max;

  /// Initial value.
  final num initial;

  /// Step size for adjustments.
  final num step;

  /// Theme for styling.
  final PromptTheme theme;

  /// Hint style for key bindings display.
  final HintStyle hintStyle;

  // ──────────────────────────────────────────────────────────────────────────
  // INTERNAL STATE
  // ──────────────────────────────────────────────────────────────────────────

  late num _value;
  late KeyBindings _bindings;
  bool _cancelled = false;

  ValuePrompt({
    required this.title,
    this.min = 0,
    this.max = 100,
    this.initial = 50,
    this.step = 1,
    this.theme = PromptTheme.dark,
    this.hintStyle = HintStyle.bullets,
  });

  // ──────────────────────────────────────────────────────────────────────────
  // ACCESSORS
  // ──────────────────────────────────────────────────────────────────────────

  /// Current value.
  num get value => _value;

  /// Current value as ratio (0.0 to 1.0).
  double get ratio => ((_value - min) / (max - min)).clamp(0.0, 1.0);

  /// Current key bindings.
  KeyBindings get bindings => _bindings;

  /// Whether the prompt was cancelled.
  bool get wasCancelled => _cancelled;

  // ──────────────────────────────────────────────────────────────────────────
  // RUN
  // ──────────────────────────────────────────────────────────────────────────

  /// Runs the value prompt with custom rendering.
  ///
  /// [render] - Custom renderer receiving current value and ratio.
  /// [extraBindings] - Additional key bindings.
  /// [useNumberKeys] - Whether 1-9 keys set value directly.
  /// [numberKeyMax] - Max number for number keys (default: 9).
  ///
  /// Returns selected value on confirm, initial on cancel.
  num run({
    required void Function(FrameContext ctx, num value, double ratio) render,
    KeyBindings? extraBindings,
    bool useNumberKeys = false,
    int numberKeyMax = 9,
  }) {
    _initState();

    // Create bindings
    _bindings = KeyBindings.horizontalNavigation(
      onLeft: () => _value = math.max(min, _value - step),
      onRight: () => _value = math.min(max, _value + step),
    );

    if (useNumberKeys) {
      _bindings = _bindings +
          KeyBindings.numbers(
            onNumber: (n) {
              if (n >= 1 && n <= numberKeyMax) {
                // Map 1-N to the value range
                final normalized = (n - 1) / (numberKeyMax - 1);
                _value = min + normalized * (max - min);
              }
            },
            max: numberKeyMax,
            hintLabel: '1–$numberKeyMax',
            hintDescription: 'set value',
          );
    }

    _bindings =
        _bindings + KeyBindings.prompt(onCancel: () => _cancelled = true);

    if (extraBindings != null) {
      _bindings = _bindings + extraBindings;
    }

    final frame = WidgetFrame(
      title: title,
      theme: theme,
      bindings: _bindings,
      hintStyle: hintStyle,
    );

    void renderFrame(RenderOutput out) {
      frame.render(out, (ctx) {
        render(ctx, _value, ratio);
      });
    }

    final runner = PromptRunner(hideCursor: true);
    final result = runner.runWithBindings(
      render: renderFrame,
      bindings: _bindings,
    );

    return (result == PromptResult.cancelled || _cancelled) ? initial : _value;
  }

  // ──────────────────────────────────────────────────────────────────────────
  // INITIALIZATION
  // ──────────────────────────────────────────────────────────────────────────

  void _initState() {
    _cancelled = false;
    _value = initial.clamp(min, max);
  }
}

// ════════════════════════════════════════════════════════════════════════════
// DISCRETE VALUE PROMPT (Rating style)
// ════════════════════════════════════════════════════════════════════════════

/// DiscreteValuePrompt – for discrete value selection (ratings, stars).
///
/// Similar to ValuePrompt but with integer steps and direct number key support.
class DiscreteValuePrompt {
  /// Title for the frame header.
  final String title;

  /// Maximum value (1 to maxValue).
  final int maxValue;

  /// Initial value.
  final int initial;

  /// Theme for styling.
  final PromptTheme theme;

  /// Hint style for key bindings display.
  final HintStyle hintStyle;

  // ──────────────────────────────────────────────────────────────────────────
  // INTERNAL STATE
  // ──────────────────────────────────────────────────────────────────────────

  late int _value;
  late KeyBindings _bindings;
  bool _cancelled = false;

  DiscreteValuePrompt({
    required this.title,
    this.maxValue = 5,
    this.initial = 3,
    this.theme = PromptTheme.dark,
    this.hintStyle = HintStyle.grid,
  }) : assert(maxValue > 0);

  // ──────────────────────────────────────────────────────────────────────────
  // ACCESSORS
  // ──────────────────────────────────────────────────────────────────────────

  /// Current value.
  int get value => _value;

  /// Current key bindings.
  KeyBindings get bindings => _bindings;

  /// Whether the prompt was cancelled.
  bool get wasCancelled => _cancelled;

  // ──────────────────────────────────────────────────────────────────────────
  // RUN
  // ──────────────────────────────────────────────────────────────────────────

  /// Runs the discrete value prompt.
  ///
  /// [render] - Custom renderer receiving current value.
  /// [extraBindings] - Additional key bindings.
  ///
  /// Returns selected value on confirm, initial on cancel.
  int run({
    required void Function(FrameContext ctx, int value, int maxValue) render,
    KeyBindings? extraBindings,
  }) {
    _initState();

    // Create bindings
    _bindings = KeyBindings.horizontalNavigation(
          onLeft: () => _value = (_value - 1).clamp(1, maxValue),
          onRight: () => _value = (_value + 1).clamp(1, maxValue),
        ) +
        KeyBindings.numbers(
          onNumber: (n) {
            if (n >= 1 && n <= maxValue) _value = n;
          },
          max: maxValue,
          hintLabel: '1–$maxValue',
          hintDescription: 'set exact',
        ) +
        KeyBindings.prompt(onCancel: () => _cancelled = true);

    if (extraBindings != null) {
      _bindings = _bindings + extraBindings;
    }

    final frame = WidgetFrame(
      title: title,
      theme: theme,
      bindings: _bindings,
      showConnector: true,
      hintStyle: hintStyle,
    );

    void renderFrame(RenderOutput out) {
      frame.render(out, (ctx) {
        render(ctx, _value, maxValue);
      });
    }

    final runner = PromptRunner(hideCursor: true);
    final result = runner.runWithBindings(
      render: renderFrame,
      bindings: _bindings,
    );

    return (result == PromptResult.cancelled || _cancelled)
        ? initial.clamp(1, maxValue)
        : _value;
  }

  // ──────────────────────────────────────────────────────────────────────────
  // INITIALIZATION
  // ──────────────────────────────────────────────────────────────────────────

  void _initState() {
    _cancelled = false;
    _value = initial.clamp(1, maxValue);
  }
}

// ════════════════════════════════════════════════════════════════════════════
// ANIMATED DISCRETE VALUE PROMPT
// ════════════════════════════════════════════════════════════════════════════

/// AnimatedDiscreteValuePrompt – composes DiscreteValuePrompt with PromptAnimations.
///
/// Adds entry/exit animations and pulse effects to discrete value selection
/// (ratings, stars, step selectors).
///
/// **Design principles:**
/// - Composition over inheritance (wraps discrete value logic, doesn't extend)
/// - Separation of concerns (animation logic separate from value logic)
/// - DRY: Reuses PromptAnimations system
///
/// **Usage:**
/// ```dart
/// final rating = AnimatedDiscreteValuePrompt(
///   title: 'Rate this',
///   maxValue: 5,
///   initial: 3,
///   animations: PromptAnimations.quick(),
/// ).run(
///   render: (ctx, value, max, phase) {
///     ctx.animatedStarsDisplay(value, max, phase: phase);
///   },
/// );
/// ```
class AnimatedDiscreteValuePrompt {
  /// Title for the frame header.
  final String title;

  /// Maximum value (1 to maxValue).
  final int maxValue;

  /// Initial value.
  final int initial;

  /// Theme for styling.
  final PromptTheme theme;

  /// Hint style for key bindings display.
  final HintStyle hintStyle;

  /// Animation configuration.
  final PromptAnimations animations;

  // Internal state
  late int _value;
  late KeyBindings _bindings;
  bool _cancelled = false;

  AnimatedDiscreteValuePrompt({
    required this.title,
    this.maxValue = 5,
    this.initial = 3,
    this.theme = PromptTheme.dark,
    this.hintStyle = HintStyle.grid,
    this.animations = const PromptAnimations(),
  }) : assert(maxValue > 0);

  /// Current value.
  int get value => _value;

  /// Current key bindings.
  KeyBindings get bindings => _bindings;

  /// Whether the prompt was cancelled.
  bool get wasCancelled => _cancelled;

  /// Runs the animated discrete value prompt.
  ///
  /// [render] receives context, value, maxValue, and animation phase.
  /// [extraBindings] adds custom key bindings.
  ///
  /// Returns selected value on confirm, initial on cancel.
  int run({
    required void Function(
      FrameContext ctx,
      int value,
      int maxValue,
      AnimationPhase phase,
    ) render,
    KeyBindings? extraBindings,
  }) {
    _initState();

    // Create bindings
    _bindings = KeyBindings.horizontalNavigation(
          onLeft: () => _value = (_value - 1).clamp(1, maxValue),
          onRight: () => _value = (_value + 1).clamp(1, maxValue),
        ) +
        KeyBindings.numbers(
          onNumber: (n) {
            if (n >= 1 && n <= maxValue) _value = n;
          },
          max: maxValue,
          hintLabel: '1–$maxValue',
          hintDescription: 'set exact',
        ) +
        KeyBindings.prompt(onCancel: () => _cancelled = true);

    if (extraBindings != null) {
      _bindings = _bindings + extraBindings;
    }

    final frame = WidgetFrame(
      title: title,
      theme: theme,
      bindings: _bindings,
      showConnector: true,
      hintStyle: hintStyle,
    );

    // Animated render function
    void renderFrame(RenderOutput out, AnimationPhase phase) {
      // Calculate display value based on phase
      int displayValue;

      if (phase.isEntry) {
        // During entry, animate from 1 to initial
        displayValue = 1 + ((initial - 1) * phase.entryProgress).round();
        displayValue = displayValue.clamp(1, maxValue);
      } else {
        displayValue = _value;
      }

      frame.render(out, (ctx) {
        render(ctx, displayValue, maxValue, phase);
      });
    }

    final runner = PromptRunner(hideCursor: true);

    // Run with animations
    if (animations.entry.enabled ||
        animations.exit.enabled ||
        animations.pulse.enabled) {
      return _runAnimated(runner, renderFrame);
    }

    // Run without animations (fast path)
    void renderSimple(RenderOutput out) {
      renderFrame(out, AnimationPhase.normal);
    }

    final result = runner.runWithBindings(
      render: renderSimple,
      bindings: _bindings,
    );

    return (result == PromptResult.cancelled || _cancelled)
        ? initial.clamp(1, maxValue)
        : _value;
  }

  int _runAnimated(
    PromptRunner runner,
    void Function(RenderOutput out, AnimationPhase phase) renderFrame,
  ) {
    return runner.runCustom((out) {
      // Entry animation
      if (animations.entry.enabled) {
        animations.entry.run(
          out: out,
          start: 1.0,
          end: initial.toDouble(),
          render: (animValue) {
            final progress = initial > 1
                ? (animValue - 1) / (initial - 1)
                : 1.0;
            renderFrame(out, AnimationPhase.entry(progress.clamp(0.0, 1.0)));
          },
        );
      } else {
        renderFrame(out, AnimationPhase.normal);
      }

      // Track previous value for pulse detection
      int prevValue = _value;

      // Main input loop
      while (true) {
        final ev = KeyEventReader.read();
        final result = _bindings.handle(ev);

        if (result == KeyActionResult.confirmed) break;
        if (result == KeyActionResult.cancelled) break;

        final valueChanged = _value != prevValue;
        prevValue = _value;

        if (result == KeyActionResult.handled || valueChanged) {
          out.clear();
          renderFrame(
            out,
            valueChanged && animations.pulse.enabled
                ? AnimationPhase.pulse
                : AnimationPhase.normal,
          );
        }
      }

      // Exit animation
      if (animations.exit.enabled) {
        animations.exit.run(
          out: out,
          render: (frame) => renderFrame(out, AnimationPhase.exit(frame)),
        );
      }

      return _cancelled ? initial.clamp(1, maxValue) : _value;
    });
  }

  void _initState() {
    _cancelled = false;
    _value = initial.clamp(1, maxValue);
  }
}

// ════════════════════════════════════════════════════════════════════════════
// RANGE VALUE PROMPT (Two handles)
// ════════════════════════════════════════════════════════════════════════════

/// RangeValuePrompt – for selecting a range with two handles.
class RangeValuePrompt {
  /// Title for the frame header.
  final String title;

  /// Minimum value.
  final num min;

  /// Maximum value.
  final num max;

  /// Initial start value.
  final num startInitial;

  /// Initial end value.
  final num endInitial;

  /// Step size for adjustments.
  final num step;

  /// Theme for styling.
  final PromptTheme theme;

  /// Hint style for key bindings display.
  final HintStyle hintStyle;

  // ──────────────────────────────────────────────────────────────────────────
  // INTERNAL STATE
  // ──────────────────────────────────────────────────────────────────────────

  late num _start;
  late num _end;
  late bool _editingStart;
  late KeyBindings _bindings;
  bool _cancelled = false;

  RangeValuePrompt({
    required this.title,
    this.min = 0,
    this.max = 100,
    this.startInitial = 20,
    this.endInitial = 80,
    this.step = 1,
    this.theme = PromptTheme.dark,
    this.hintStyle = HintStyle.bullets,
  });

  // ──────────────────────────────────────────────────────────────────────────
  // ACCESSORS
  // ──────────────────────────────────────────────────────────────────────────

  /// Current start value.
  num get start => _start;

  /// Current end value.
  num get end => _end;

  /// Whether currently editing start (vs end).
  bool get editingStart => _editingStart;

  /// Current key bindings.
  KeyBindings get bindings => _bindings;

  /// Whether the prompt was cancelled.
  bool get wasCancelled => _cancelled;

  // ──────────────────────────────────────────────────────────────────────────
  // RUN
  // ──────────────────────────────────────────────────────────────────────────

  /// Runs the range value prompt.
  ///
  /// [render] - Custom renderer receiving current values and active handle.
  /// [extraBindings] - Additional key bindings.
  ///
  /// Returns selected range on confirm, initial on cancel.
  (num start, num end) run({
    required void Function(
      FrameContext ctx,
      num start,
      num end,
      bool editingStart,
    ) render,
    KeyBindings? extraBindings,
  }) {
    _initState();

    // Create bindings
    _bindings = KeyBindings([
          // Toggle handle
          KeyBinding.multi(
            {KeyEventType.arrowUp, KeyEventType.arrowDown, KeyEventType.space},
            (event) {
              _editingStart = !_editingStart;
              return KeyActionResult.handled;
            },
            hintLabel: '↑/↓/Space',
            hintDescription: 'toggle handle',
          ),
        ]) +
        KeyBindings.horizontalNavigation(
          onLeft: () {
            if (_editingStart) {
              _start = math.max(min, _start - step);
              if (_start > _end) _end = _start;
            } else {
              _end = math.max(min, _end - step);
              if (_end < _start) _start = _end;
            }
            _start = _start.clamp(min, max);
            _end = _end.clamp(min, max);
          },
          onRight: () {
            if (_editingStart) {
              _start = math.min(max, _start + step);
              if (_start > _end) _end = _start;
            } else {
              _end = math.min(max, _end + step);
              if (_end < _start) _start = _end;
            }
            _start = _start.clamp(min, max);
            _end = _end.clamp(min, max);
          },
        ) +
        KeyBindings.prompt(onCancel: () => _cancelled = true);

    if (extraBindings != null) {
      _bindings = _bindings + extraBindings;
    }

    final frame = WidgetFrame(
      title: title,
      theme: theme,
      bindings: _bindings,
      hintStyle: hintStyle,
    );

    void renderFrame(RenderOutput out) {
      frame.render(out, (ctx) {
        render(ctx, _start, _end, _editingStart);
      });
    }

    final runner = PromptRunner(hideCursor: true);
    final result = runner.runWithBindings(
      render: renderFrame,
      bindings: _bindings,
    );

    return (result == PromptResult.cancelled || _cancelled)
        ? (startInitial, endInitial)
        : (_start, _end);
  }

  // ──────────────────────────────────────────────────────────────────────────
  // INITIALIZATION
  // ──────────────────────────────────────────────────────────────────────────

  void _initState() {
    _cancelled = false;
    _start = math.min(startInitial, endInitial).clamp(min, max);
    _end = math.max(startInitial, endInitial).clamp(min, max);
    _editingStart = true;
  }
}

// ════════════════════════════════════════════════════════════════════════════
// ANIMATED RANGE VALUE PROMPT
// ════════════════════════════════════════════════════════════════════════════

/// AnimatedRangeValuePrompt – composes RangeValuePrompt with PromptAnimations.
///
/// Adds entry/exit animations and pulse effects to range selection prompts.
///
/// **Design principles:**
/// - Composition over inheritance
/// - Separation of concerns (animation logic separate from value logic)
/// - DRY: Reuses PromptAnimations system
class AnimatedRangeValuePrompt {
  /// Title for the frame header.
  final String title;

  /// Minimum value.
  final num min;

  /// Maximum value.
  final num max;

  /// Initial start value.
  final num startInitial;

  /// Initial end value.
  final num endInitial;

  /// Step size for adjustments.
  final num step;

  /// Theme for styling.
  final PromptTheme theme;

  /// Hint style for key bindings display.
  final HintStyle hintStyle;

  /// Animation configuration.
  final PromptAnimations animations;

  // Internal state
  late num _start;
  late num _end;
  late bool _editingStart;
  late KeyBindings _bindings;
  bool _cancelled = false;

  AnimatedRangeValuePrompt({
    required this.title,
    this.min = 0,
    this.max = 100,
    this.startInitial = 20,
    this.endInitial = 80,
    this.step = 1,
    this.theme = PromptTheme.dark,
    this.hintStyle = HintStyle.bullets,
    this.animations = const PromptAnimations(),
  });

  /// Current start value.
  num get start => _start;

  /// Current end value.
  num get end => _end;

  /// Whether currently editing start (vs end).
  bool get editingStart => _editingStart;

  /// Whether the prompt was cancelled.
  bool get wasCancelled => _cancelled;

  /// Runs the animated range prompt.
  (num start, num end) run({
    required void Function(
      FrameContext ctx,
      num start,
      num end,
      bool editingStart,
      AnimationPhase phase,
    ) render,
    KeyBindings? extraBindings,
  }) {
    _initState();

    // Create bindings
    _bindings = KeyBindings([
          KeyBinding.multi(
            {KeyEventType.arrowUp, KeyEventType.arrowDown, KeyEventType.space},
            (event) {
              _editingStart = !_editingStart;
              return KeyActionResult.handled;
            },
            hintLabel: '↑/↓/Space',
            hintDescription: 'toggle handle',
          ),
        ]) +
        KeyBindings.horizontalNavigation(
          onLeft: () {
            if (_editingStart) {
              _start = math.max(min, _start - step);
              if (_start > _end) _end = _start;
            } else {
              _end = math.max(min, _end - step);
              if (_end < _start) _start = _end;
            }
            _start = _start.clamp(min, max);
            _end = _end.clamp(min, max);
          },
          onRight: () {
            if (_editingStart) {
              _start = math.min(max, _start + step);
              if (_start > _end) _end = _start;
            } else {
              _end = math.min(max, _end + step);
              if (_end < _start) _start = _end;
            }
            _start = _start.clamp(min, max);
            _end = _end.clamp(min, max);
          },
        ) +
        KeyBindings.prompt(onCancel: () => _cancelled = true);

    if (extraBindings != null) {
      _bindings = _bindings + extraBindings;
    }

    final frame = WidgetFrame(
      title: title,
      theme: theme,
      bindings: _bindings,
      hintStyle: hintStyle,
    );

    void renderFrame(RenderOutput out, AnimationPhase phase) {
      frame.render(out, (ctx) {
        render(ctx, _start, _end, _editingStart, phase);
      });
    }

    final runner = PromptRunner(hideCursor: true);

    // Run with animations
    if (animations.entry.enabled ||
        animations.exit.enabled ||
        animations.pulse.enabled) {
      return _runAnimated(runner, renderFrame);
    }

    // Fast path: no animations
    void renderSimple(RenderOutput out) {
      renderFrame(out, AnimationPhase.normal);
    }

    final result = runner.runWithBindings(
      render: renderSimple,
      bindings: _bindings,
    );

    return (result == PromptResult.cancelled || _cancelled)
        ? (startInitial, endInitial)
        : (_start, _end);
  }

  (num, num) _runAnimated(
    PromptRunner runner,
    void Function(RenderOutput out, AnimationPhase phase) renderFrame,
  ) {
    return runner.runCustom((out) {
      // Entry animation (animate handles from center outward)
      if (animations.entry.enabled) {
        final centerStart = (min + max) / 2;
        animations.entry.run(
          out: out,
          start: 0.0,
          end: 1.0,
          render: (progress) {
            // Animate start from center toward startInitial
            _start = centerStart + (startInitial - centerStart) * progress;
            // Animate end from center toward endInitial
            _end = centerStart + (endInitial - centerStart) * progress;
            _start = _start.clamp(min, max);
            _end = _end.clamp(min, max);
            renderFrame(out, AnimationPhase.entry(progress));
          },
        );
        // Reset to actual initial values
        _start = math.min(startInitial, endInitial).clamp(min, max);
        _end = math.max(startInitial, endInitial).clamp(min, max);
      } else {
        renderFrame(out, AnimationPhase.normal);
      }

      // Track previous values for pulse detection
      num prevStart = _start;
      num prevEnd = _end;

      // Main input loop
      while (true) {
        final ev = KeyEventReader.read();
        final result = _bindings.handle(ev);

        if (result == KeyActionResult.confirmed) break;
        if (result == KeyActionResult.cancelled) break;

        final valueChanged = _start != prevStart || _end != prevEnd;
        prevStart = _start;
        prevEnd = _end;

        if (result == KeyActionResult.handled || valueChanged) {
          out.clear();
          renderFrame(
            out,
            valueChanged && animations.pulse.enabled
                ? AnimationPhase.pulse
                : AnimationPhase.normal,
          );
        }
      }

      // Exit animation
      if (animations.exit.enabled) {
        animations.exit.run(
          out: out,
          render: (frame) => renderFrame(out, AnimationPhase.exit(frame)),
        );
      }

      return _cancelled ? (startInitial, endInitial) : (_start, _end);
    });
  }

  void _initState() {
    _cancelled = false;
    _start = math.min(startInitial, endInitial).clamp(min, max);
    _end = math.max(startInitial, endInitial).clamp(min, max);
    _editingStart = true;
  }
}

// ════════════════════════════════════════════════════════════════════════════
// RENDERING HELPERS
// ════════════════════════════════════════════════════════════════════════════

// ════════════════════════════════════════════════════════════════════════════
// ANIMATED VALUE PROMPT
// ════════════════════════════════════════════════════════════════════════════

/// AnimatedValuePrompt – composes ValuePrompt with PromptAnimations.
///
/// Adds entry/exit animations and pulse effects to value selection prompts.
/// This is the recommended way to create animated sliders.
///
/// **Design principles:**
/// - Composition over inheritance (wraps ValuePrompt, doesn't extend)
/// - Separation of concerns (animation logic separate from value logic)
/// - DRY: Reuses PromptAnimations system
///
/// **Usage:**
/// ```dart
/// final value = AnimatedValuePrompt(
///   title: 'Volume',
///   min: 0,
///   max: 100,
///   initial: 50,
///   animations: PromptAnimations.smooth(),
/// ).run(
///   render: (ctx, value, ratio, phase) {
///     ctx.animatedSliderBar(ratio, phase: phase);
///     ctx.labeledAccent('Value', '$value%');
///   },
/// );
/// ```
class AnimatedValuePrompt {
  /// Title for the frame header.
  final String title;

  /// Minimum value.
  final num min;

  /// Maximum value.
  final num max;

  /// Initial value.
  final num initial;

  /// Step size for adjustments.
  final num step;

  /// Theme for styling.
  final PromptTheme theme;

  /// Hint style for key bindings display.
  final HintStyle hintStyle;

  /// Animation configuration.
  final PromptAnimations animations;

  // Internal state
  late num _value;
  late KeyBindings _bindings;
  bool _cancelled = false;

  AnimatedValuePrompt({
    required this.title,
    this.min = 0,
    this.max = 100,
    this.initial = 50,
    this.step = 1,
    this.theme = PromptTheme.dark,
    this.hintStyle = HintStyle.bullets,
    this.animations = const PromptAnimations(),
  });

  /// Current value.
  num get value => _value;

  /// Current value as ratio (0.0 to 1.0).
  double get ratio => ((_value - min) / (max - min)).clamp(0.0, 1.0);

  /// Current key bindings.
  KeyBindings get bindings => _bindings;

  /// Whether the prompt was cancelled.
  bool get wasCancelled => _cancelled;

  /// Runs the animated value prompt.
  ///
  /// [render] receives context, value, ratio, and animation phase.
  /// [extraBindings] adds custom key bindings.
  /// [useNumberKeys] enables 1-9 for direct value setting.
  ///
  /// Returns selected value on confirm, initial on cancel.
  num run({
    required void Function(
      FrameContext ctx,
      num value,
      double ratio,
      AnimationPhase phase,
    ) render,
    KeyBindings? extraBindings,
    bool useNumberKeys = false,
    int numberKeyMax = 9,
  }) {
    _initState();

    // Create bindings
    _bindings = KeyBindings.horizontalNavigation(
      onLeft: () => _value = math.max(min, _value - step),
      onRight: () => _value = math.min(max, _value + step),
    );

    if (useNumberKeys) {
      _bindings = _bindings +
          KeyBindings.numbers(
            onNumber: (n) {
              if (n >= 1 && n <= numberKeyMax) {
                final normalized = (n - 1) / (numberKeyMax - 1);
                _value = min + normalized * (max - min);
              }
            },
            max: numberKeyMax,
            hintLabel: '1–$numberKeyMax',
            hintDescription: 'set value',
          );
    }

    _bindings =
        _bindings + KeyBindings.prompt(onCancel: () => _cancelled = true);

    if (extraBindings != null) {
      _bindings = _bindings + extraBindings;
    }

    final frame = WidgetFrame(
      title: title,
      theme: theme,
      bindings: _bindings,
      hintStyle: hintStyle,
    );

    // Animated render function
    void renderFrame(RenderOutput out, AnimationPhase phase) {
      // Calculate ratio based on phase
      double currentRatio;
      num displayValue;

      if (phase.isEntry) {
        // During entry, animate from min to initial
        final entryValue = min + (initial - min) * phase.entryProgress;
        displayValue = entryValue;
        currentRatio = ((entryValue - min) / (max - min)).clamp(0.0, 1.0);
      } else {
        displayValue = _value;
        currentRatio = ratio;
      }

      frame.render(out, (ctx) {
        render(ctx, displayValue, currentRatio, phase);
      });
    }

    final runner = PromptRunner(hideCursor: true);

    // Run with animations
    if (animations.entry.enabled ||
        animations.exit.enabled ||
        animations.pulse.enabled) {
      return _runAnimated(runner, renderFrame);
    }

    // Run without animations (fast path)
    void renderSimple(RenderOutput out) {
      renderFrame(out, AnimationPhase.normal);
    }

    final result = runner.runWithBindings(
      render: renderSimple,
      bindings: _bindings,
    );

    return (result == PromptResult.cancelled || _cancelled) ? initial : _value;
  }

  num _runAnimated(
    PromptRunner runner,
    void Function(RenderOutput out, AnimationPhase phase) renderFrame,
  ) {
    return runner.runCustom((out) {
      // Entry animation
      if (animations.entry.enabled) {
        animations.entry.run(
          out: out,
          start: min.toDouble(),
          end: initial.toDouble(),
          render: (animValue) {
            final progress = initial != min
                ? (animValue - min.toDouble()) / (initial - min)
                : 1.0;
            renderFrame(out, AnimationPhase.entry(progress.clamp(0.0, 1.0)));
          },
        );
      } else {
        renderFrame(out, AnimationPhase.normal);
      }

      // Track previous value for pulse detection
      num prevValue = _value;

      // Main input loop
      while (true) {
        final ev = KeyEventReader.read();
        final result = _bindings.handle(ev);

        if (result == KeyActionResult.confirmed) break;
        if (result == KeyActionResult.cancelled) break;

        final valueChanged = _value != prevValue;
        prevValue = _value;

        if (result == KeyActionResult.handled || valueChanged) {
          out.clear();
          renderFrame(
            out,
            valueChanged && animations.pulse.enabled
                ? AnimationPhase.pulse
                : AnimationPhase.normal,
          );
        }
      }

      // Exit animation
      if (animations.exit.enabled) {
        animations.exit.run(
          out: out,
          render: (frame) => renderFrame(out, AnimationPhase.exit(frame)),
        );
      }

      return _cancelled ? initial : _value;
    });
  }

  void _initState() {
    _cancelled = false;
    _value = initial.clamp(min, max);
  }
}

// ════════════════════════════════════════════════════════════════════════════
// RENDERING HELPERS
// ════════════════════════════════════════════════════════════════════════════

/// Helper extension for rendering value prompts.
extension ValuePromptRendering on FrameContext {
  /// Renders a slider bar with head indicator.
  void sliderBar(
    double ratio, {
    int width = 28,
    String filledChar = '█',
    String emptyChar = '·',
    String? headChar,
    bool showPercent = true,
  }) {
    final clamped = ratio.clamp(0.0, 1.0);
    final filled = (clamped * width).round();
    final pct = (clamped * 100).round();

    final filledPart = '${theme.accent}${filledChar * filled}${theme.reset}';
    final head = headChar ?? (pct < 50 ? '◉' : '●');
    final emptyPart =
        '${theme.dim}${emptyChar * (width - filled)}${theme.reset}';

    final percentPart = showPercent ? ' ${theme.dim}$pct%${theme.reset}' : '';

    gutterLine(
        '$filledPart${theme.accent}$head${theme.reset}$emptyPart$percentPart');
  }

  /// Renders star rating display.
  void starsDisplay(
    int value,
    int maxStars, {
    String filledStar = '★',
    String emptyStar = '☆',
  }) {
    final buffer = StringBuffer();
    for (int i = 1; i <= maxStars; i++) {
      final isFilled = i <= value;
      final isCurrent = i == value;
      final color =
          isCurrent ? theme.highlight : (isFilled ? theme.accent : theme.gray);
      final glyph = isFilled ? filledStar : emptyStar;
      final star = isCurrent ? '${theme.bold}$glyph${theme.reset}' : glyph;
      buffer.write('$color$star${theme.reset}');
      if (i < maxStars) buffer.write(' ');
    }
    gutterLine(buffer.toString());
  }

  /// Renders numeric scale display.
  void numericScale(int value, int max) {
    final buffer = StringBuffer();
    for (int i = 1; i <= max; i++) {
      final color = i == value ? theme.accent : theme.dim;
      buffer.write('$color$i${theme.reset}');
      if (i < max) buffer.write(' ');
    }
    gutterLine(
        '$buffer   ${theme.dim}(${theme.reset}${theme.accent}$value${theme.reset}${theme.dim}/$max)${theme.reset}');
  }

  // ──────────────────────────────────────────────────────────────────────────
  // ANIMATED SLIDER RENDERING
  // ──────────────────────────────────────────────────────────────────────────

  /// Renders an animated slider bar with phase-aware styling.
  ///
  /// [ratio] is the current value ratio (0.0 to 1.0).
  /// [phase] controls animation styling (pulse, shimmer, etc).
  /// [width] is the bar width in characters.
  /// [showTooltip] shows the percentage above the slider head.
  /// [unit] is the unit suffix for the tooltip (default '%').
  void animatedSliderBar(
    double ratio, {
    AnimationPhase phase = AnimationPhase.normal,
    int width = 28,
    bool showTooltip = true,
    String unit = '%',
  }) {
    final clamped = ratio.clamp(0.0, 1.0);
    final filledLength = (clamped * width).round().clamp(0, width);
    final percent = (clamped * 100).round();

    // Determine styling based on animation phase
    final isPulsing = phase.isPulsing;
    final isExitPulse = phase.exitFrame?.isPulseOn ?? false;
    final isFlare = phase.isExit && isExitPulse;

    // Gradient shades based on ratio
    final shades = ['░', '▒', '▓', '█'];
    final shade = shades[(clamped * (shades.length - 1)).clamp(0, 3).round()];

    // Color based on animation state
    final barColor = isFlare || isPulsing ? theme.bold : theme.accent;

    final filledPart =
        '$barColor${shade * math.max(0, filledLength)}${theme.reset}';
    final emptyPart =
        '${theme.dim}${'·' * (width - filledLength)}${theme.reset}';

    // Slider head styling
    final head = _animatedSliderHead(percent, isPulsing, isFlare);

    // Tooltip styling
    if (showTooltip) {
      final tooltipOffset = filledLength;
      final paddingLeft = ' ' * tooltipOffset;
      final tooltipText = isPulsing || isFlare
          ? '${theme.bold}$percent$unit${theme.reset}'
          : '${theme.dim}$percent$unit${theme.reset}';
      gutterLine('$paddingLeft$tooltipText');
    }

    gutterLine('$filledPart$barColor$head${theme.reset}$emptyPart');
  }

  /// Returns an animated slider head glyph based on state.
  String _animatedSliderHead(int percent, bool pulse, bool flare) {
    if (flare) return '★';
    if (pulse) return '⦿';
    if (percent < 25) return '◉';
    if (percent < 50) return '◎';
    if (percent < 75) return '●';
    if (percent < 90) return '⦾';
    return '★';
  }

  // ──────────────────────────────────────────────────────────────────────────
  // ANIMATED DISCRETE RENDERING
  // ──────────────────────────────────────────────────────────────────────────

  /// Renders an animated star rating display with phase-aware styling.
  ///
  /// [value] is the current rating value.
  /// [maxStars] is the maximum number of stars.
  /// [phase] controls animation styling (pulse, shimmer, etc).
  void animatedStarsDisplay(
    int value,
    int maxStars, {
    AnimationPhase phase = AnimationPhase.normal,
    String filledStar = '★',
    String emptyStar = '☆',
  }) {
    final isPulsing = phase.isPulsing;
    final isExitPulse = phase.exitFrame?.isPulseOn ?? false;
    final isFlare = phase.isExit && isExitPulse;

    final buffer = StringBuffer();
    for (int i = 1; i <= maxStars; i++) {
      final isFilled = i <= value;
      final isCurrent = i == value;

      // Determine color based on state and animation
      String color;
      if (isCurrent) {
        if (isPulsing || isFlare) {
          color = '${theme.bold}${theme.highlight}';
        } else {
          color = theme.highlight;
        }
      } else if (isFilled) {
        color = isPulsing ? '${theme.bold}${theme.accent}' : theme.accent;
      } else {
        color = theme.gray;
      }

      final glyph = isFilled ? filledStar : emptyStar;

      // Add extra emphasis for current star
      String star;
      if (isCurrent && (isPulsing || isFlare)) {
        star = '${theme.bold}${theme.inverse}$glyph${theme.reset}';
      } else if (isCurrent) {
        star = '${theme.bold}$glyph${theme.reset}';
      } else {
        star = glyph;
      }

      buffer.write('$color$star${theme.reset}');
      if (i < maxStars) buffer.write(' ');
    }
    gutterLine(buffer.toString());
  }

  /// Renders an animated numeric scale display with phase-aware styling.
  ///
  /// [value] is the current value.
  /// [max] is the maximum value.
  /// [phase] controls animation styling.
  void animatedNumericScale(
    int value,
    int max, {
    AnimationPhase phase = AnimationPhase.normal,
  }) {
    final isPulsing = phase.isPulsing;
    final isExitPulse = phase.exitFrame?.isPulseOn ?? false;
    final isFlare = phase.isExit && isExitPulse;

    final buffer = StringBuffer();
    for (int i = 1; i <= max; i++) {
      final isCurrent = i == value;

      String color;
      if (isCurrent) {
        if (isPulsing || isFlare) {
          color = '${theme.bold}${theme.inverse}${theme.accent}';
        } else {
          color = theme.accent;
        }
      } else {
        color = theme.dim;
      }

      buffer.write('$color$i${theme.reset}');
      if (i < max) buffer.write(' ');
    }

    // Value indicator with animation awareness
    final valueColor = isPulsing || isFlare
        ? '${theme.bold}${theme.accent}'
        : theme.accent;
    gutterLine(
        '$buffer   ${theme.dim}(${theme.reset}$valueColor$value${theme.reset}${theme.dim}/$max)${theme.reset}');
  }
}
