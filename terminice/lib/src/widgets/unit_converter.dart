import 'dart:io';

import '../style/theme.dart';
import '../system/framed_layout.dart';
import '../system/rendering.dart';
import '../system/key_events.dart';
import '../system/hints.dart';
import '../system/prompt_runner.dart';

/// UnitConverter – quick conversion panel (cm↔in, USD↔EUR)
///
/// Aligns with ThemeDemo styling: titled frame, left gutter using the
/// theme's vertical border glyph, and tasteful use of accent/highlight colors.
class UnitConverter {
  final PromptTheme theme;
  final String title;

  // Length
  final double? centimeters;
  final double? inches;

  // Currency
  final double? usd;
  final double? eur;
  final double usdToEurRate;

  UnitConverter({
    this.theme = const PromptTheme(),
    this.title = 'Unit Converter',
    this.centimeters,
    this.inches,
    this.usd,
    this.eur,
    this.usdToEurRate = 0.92,
  }) : assert(usdToEurRate > 0, 'Exchange rate must be > 0');

  /// Render the converter panel.
  void show() {
    final style = theme.style;

    final frame = FramedLayout(title, theme: theme);
    final top = frame.top();
    stdout.writeln('${theme.bold}$top${theme.reset}');

    // Length section
    stdout.writeln(gutterLine(theme, sectionHeader(theme, 'Length · cm ↔ in')));
    final pairLen = _resolveLengthPair();
    stdout.writeln(gutterLine(theme, _equation(
      leftLabel: 'cm',
      leftValue: pairLen.cm,
      rightLabel: 'in',
      rightValue: pairLen.in_,
      direction: '→',
    )));
    stdout.writeln(gutterLine(theme, _equation(
      leftLabel: 'in',
      leftValue: pairLen.in_,
      rightLabel: 'cm',
      rightValue: pairLen.cm,
      direction: '→',
    )));

    // Currency section
    stdout.writeln(gutterLine(theme, sectionHeader(theme, 'Currency · USD ↔ EUR')));
    final pairCur = _resolveCurrencyPair();
    stdout.writeln(gutterLine(theme, _rateLine()));
    stdout.writeln(gutterLine(theme, _equation(
      leftLabel: 'USD',
      leftValue: pairCur.usd,
      rightLabel: 'EUR',
      rightValue: pairCur.eur,
      direction: '→',
    )));
    stdout.writeln(gutterLine(theme, _equation(
      leftLabel: 'EUR',
      leftValue: pairCur.eur,
      rightLabel: 'USD',
      rightValue: pairCur.usd,
      direction: '→',
    )));

    if (style.showBorder) {
      stdout.writeln(frame.bottom());
    }
  }

  /// Interactive mode: live input with toggles.
  /// Controls:
  /// - Type numbers to edit active side
  /// - Backspace to delete
  /// - T to flip sides (left/right input)
  /// - R to change converter (cm↔in, USD↔EUR)
  /// - Enter / Esc to exit
  void run() {
    // Build converters
    final converters = <_Converter>[
      _Converter(
        name: 'Length · cm ↔ in',
        leftLabel: 'cm',
        rightLabel: 'in',
        aToB: (cm) => cm / 2.54,
        bToA: (inch) => inch * 2.54,
        details: '1 in = 2.54 cm   |   1 cm = 0.3937 in',
      ),
      _Converter(
        name: 'Currency · USD ↔ EUR',
        leftLabel: 'USD',
        rightLabel: 'EUR',
        aToB: (u) => u * usdToEurRate,
        bToA: (e) => e / usdToEurRate,
        details:
            'Rate: 1 USD = ${usdToEurRate.toStringAsFixed(4)} EUR   |   1 EUR = ${(1 / usdToEurRate).toStringAsFixed(4)} USD',
      ),
    ];

    int mode = 0; // which converter
    bool inputLeft = true; // which side is active input
    String buffer = _initialBuffer(mode, inputLeft);

    void render(RenderOutput out) {
      final style = theme.style;
      final conv = converters[mode];

      final frame = FramedLayout(title, theme: theme);
      final top = frame.top();
      out.writeln('${theme.bold}$top${theme.reset}');

      // Section
      out.writeln(gutterLine(theme, sectionHeader(theme, conv.name)));
      if (conv.details.isNotEmpty) {
        out.writeln(gutterLine(theme, '${theme.gray}${conv.details}${theme.reset}'));
      }

      // Compute values based on buffer and active side
      final inputValue = _parseNum(buffer) ?? 0.0;
      final leftVal = inputLeft ? inputValue : conv.bToA(inputValue);
      final rightVal = inputLeft ? conv.aToB(inputValue) : inputValue;

      // Active indicator
      final lLabel = inputLeft
          ? '${theme.inverse}${theme.highlight}${conv.leftLabel}${theme.reset}'
          : '${theme.highlight}${conv.leftLabel}${theme.reset}';
      final rLabel = !inputLeft
          ? '${theme.inverse}${theme.highlight}${conv.rightLabel}${theme.reset}'
          : '${theme.highlight}${conv.rightLabel}${theme.reset}';

      out.writeln(gutterLine(theme, _equation(
        leftLabel: lLabel,
        leftValue: leftVal,
        rightLabel: rLabel,
        rightValue: rightVal,
        direction: '→',
      )));

      // Also show reverse for clarity
      out.writeln(gutterLine(theme, _equation(
        leftLabel: rLabel,
        leftValue: rightVal,
        rightLabel: lLabel,
        rightValue: leftVal,
        direction: '→',
      )));

      if (style.showBorder) {
        out.writeln(frame.bottom());
      }

      // Hints
      out.writeln(Hints.grid([
        [Hints.key('type', theme), 'enter amount'],
        [Hints.key('Backspace', theme), 'delete'],
        [Hints.key('T', theme), 'flip sides'],
        [Hints.key('R', theme), 'change converter'],
        [Hints.key('Enter / Esc', theme), 'exit'],
      ], theme));
    }

    final runner = PromptRunner(hideCursor: true);
    runner.run(
      render: render,
      onKey: (ev) {
        if (ev.type == KeyEventType.enter || ev.type == KeyEventType.esc) {
          return PromptResult.confirmed;
        }
        if (ev.type == KeyEventType.backspace) {
          if (buffer.isNotEmpty) buffer = buffer.substring(0, buffer.length - 1);
        } else if (ev.type == KeyEventType.char && ev.char != null) {
          final ch = ev.char!;
          if (RegExp(r'[0-9]').hasMatch(ch)) {
            buffer += ch;
          } else if (ch == '.' && !buffer.contains('.')) {
            buffer += ch;
          } else if ((ch == 't' || ch == 'T')) {
            inputLeft = !inputLeft;
          } else if ((ch == 'r' || ch == 'R')) {
            mode = (mode + 1) % converters.length;
            // Reset buffer to keep the same physical quantity when switching
            buffer = _initialBuffer(mode, inputLeft, fallback: buffer);
          }
        }

        return null;
      },
    );
  }

  // --- Rendering helpers -------------------------------------------------



  String _equation({
    required String leftLabel,
    required double leftValue,
    required String rightLabel,
    required double rightValue,
    String direction = '→',
  }) {
    final numL = '${theme.selection}${leftValue.toStringAsFixed(2)}${theme.reset}';
    final numR = '${theme.selection}${rightValue.toStringAsFixed(2)}${theme.reset}';
    final labL = '${theme.highlight}$leftLabel${theme.reset}';
    final labR = '${theme.highlight}$rightLabel${theme.reset}';
    final arrow = '${theme.dim}$direction${theme.reset}';
    final eq = '${theme.dim}=${theme.reset}';
    return '$labL $numL $arrow $labR $eq $numR';
  }

  String _rateLine() {
    final inv = 1 / usdToEurRate;
    final r1 = '${theme.dim}Rate:${theme.reset} 1 ${theme.highlight}USD${theme.reset} '
        '${theme.dim}=${theme.reset} ${theme.selection}${usdToEurRate.toStringAsFixed(4)}${theme.reset} ${theme.highlight}EUR${theme.reset}';
    final r2 = '     1 ${theme.highlight}EUR${theme.reset} ${theme.dim}=${theme.reset} '
        '${theme.selection}${inv.toStringAsFixed(4)}${theme.reset} ${theme.highlight}USD${theme.reset}';
    return '$r1  ${theme.dim}|${theme.reset}  $r2';
  }

  // --- Conversion logic --------------------------------------------------

  _LengthPair _resolveLengthPair() {
    const cmPerIn = 2.54;
    if (centimeters != null) {
      final cm = centimeters!;
      return _LengthPair(cm: cm, in_: cm / cmPerIn);
    }
    if (inches != null) {
      final inch = inches!;
      return _LengthPair(cm: inch * cmPerIn, in_: inch);
    }
    // Defaults
    const cm = 10.0;
    return _LengthPair(cm: cm, in_: cm / cmPerIn);
  }

  _CurrencyPair _resolveCurrencyPair() {
    if (usd != null) {
      final u = usd!;
      return _CurrencyPair(usd: u, eur: u * usdToEurRate);
    }
    if (eur != null) {
      final e = eur!;
      return _CurrencyPair(usd: e / usdToEurRate, eur: e);
    }
    // Defaults
    const u = 100.0;
    return _CurrencyPair(usd: u, eur: u * usdToEurRate);
  }
}

class _Converter {
  final String name;
  final String leftLabel; // A
  final String rightLabel; // B
  final double Function(double) aToB;
  final double Function(double) bToA;
  final String details;

  _Converter({
    required this.name,
    required this.leftLabel,
    required this.rightLabel,
    required this.aToB,
    required this.bToA,
    this.details = '',
  });
}

class _LengthPair {
  final double cm;
  final double in_;
  _LengthPair({required this.cm, required this.in_});
}

class _CurrencyPair {
  final double usd;
  final double eur;
  _CurrencyPair({required this.usd, required this.eur});
}

/// Convenience function mirroring the requested API name.
void unitConverter({
  PromptTheme theme = const PromptTheme(),
  String title = 'Unit Converter',
  double? centimeters,
  double? inches,
  double? usd,
  double? eur,
  double usdToEurRate = 0.92,
}) {
  UnitConverter(
    theme: theme,
    title: title,
    centimeters: centimeters,
    inches: inches,
    usd: usd,
    eur: eur,
    usdToEurRate: usdToEurRate,
  ).show();
}

// --- Utilities ------------------------------------------------------------

String _sanitizeNum(String s) {
  // Keep digits and a single dot
  final buf = StringBuffer();
  bool sawDot = false;
  for (final ch in s.split('')) {
    if (RegExp(r'[0-9]').hasMatch(ch)) buf.write(ch);
    if (ch == '.' && !sawDot) {
      buf.write(ch);
      sawDot = true;
    }
  }
  return buf.toString();
}

double? _parseNum(String s) {
  if (s.isEmpty || s == '.') return null;
  try {
    return double.parse(_sanitizeNum(s));
  } catch (_) {
    return null;
  }
}

String _initialBuffer(int mode, bool inputLeft, {String? fallback}) {
  // Try to seed with provided constructor values if present
  if (fallback != null && fallback.isNotEmpty) return fallback;
  // Favor centimeters or inches for mode 0 (length), usd/eur for mode 1.
  if (mode == 0) {
    // Length
    // Without direct access to instance here, default to '10'
    return '10';
  } else {
    // Currency
    return '100';
  }
}


