import '../style/theme.dart';
import '../system/hints.dart';
import '../system/prompt_runner.dart';
import '../system/widget_frame.dart';

/// Renders a big ASCII banner aligned with ThemeDemo styling.
///
/// Example:
///   Banner('MONO', theme: PromptTheme.matrix).run();
class Banner {
  final String text;
  final PromptTheme theme;
  final bool showFrame;
  final bool showShadow;

  /// Scales glyphs horizontally by duplicating columns for a wider look.
  final int hScale;

  /// Space columns between glyphs.
  final int letterSpacing;

  Banner(
    this.text, {
    this.theme = PromptTheme.dark,
    this.showFrame = true,
    this.showShadow = true,
    this.hScale = 1,
    this.letterSpacing = 1,
  })  : assert(hScale >= 1),
        assert(letterSpacing >= 0);

  void run() {
    // Use TerminalSession for cursor hiding, RenderOutput for line tracking
    TerminalSession(hideCursor: true).runWithOutput(
      (out) => _render(out),
      clearOnEnd: false, // Keep banner visible
    );
  }

  void _render(RenderOutput out) {
    final frame = WidgetFrame(title: 'Banner', theme: theme);
    frame.showTo(out, (ctx) {
      // Build mask lines once; use it to produce colored and shadow layers
      final maskLines = _renderMaskLines(text);

      // Primary colored banner lines
      for (int i = 0; i < maskLines.length; i++) {
        ctx.gutterLine(_colorizeMask(maskLines[i], rowIndex: i));
      }

      // Optional drop shadow block printed after the banner
      if (showShadow) {
        for (int i = 0; i < maskLines.length; i++) {
          ctx.gutterLine('  ${_shadowizeMask(maskLines[i])}');
        }
      }
    });

    out.writeln(Hints.bullets([
      'Use different themes for varied vibes',
      'ASCII figlet-style banner',
    ], theme, dim: true));
  }

  /// Produces 5 mask lines where '1' means filled cell and '0' means empty.
  List<String> _renderMaskLines(String input) {
    final upper = input.toUpperCase();
    final glyphs = upper.runes
        .map((r) => _font[String.fromCharCode(r)] ?? _font['?']!)
        .toList();

    final List<String> lines = List.generate(5, (_) => '');
    for (int row = 0; row < 5; row++) {
      final rowBuf = StringBuffer();
      for (int gi = 0; gi < glyphs.length; gi++) {
        final pattern = glyphs[gi][row];
        for (int col = 0; col < pattern.length; col++) {
          final bit = pattern[col];
          for (int k = 0; k < hScale; k++) {
            rowBuf.write(bit);
          }
        }
        if (gi < glyphs.length - 1) {
          rowBuf.write('0' * letterSpacing);
        }
      }
      lines[row] = rowBuf.toString();
    }
    return lines;
  }

  String _colorizeMask(String mask, {required int rowIndex}) {
    final sb = StringBuffer();
    for (int i = 0; i < mask.length; i++) {
      if (mask[i] == '1') {
        final color = ((i + rowIndex) % 2 == 0) ? theme.accent : theme.highlight;
        sb.write('$color█${theme.reset}');
      } else {
        sb.write(' ');
      }
    }
    return sb.toString();
  }

  String _shadowizeMask(String mask) {
    final sb = StringBuffer();
    for (int i = 0; i < mask.length; i++) {
      if (mask[i] == '1') {
        sb.write('${theme.dim}░${theme.reset}');
      } else {
        sb.write(' ');
      }
    }
    return sb.toString();
  }
}

// 5x5 block font. Each character is 5 strings of 5 chars, '1' = filled, '0' = empty.
// Covers A-Z, 0-9 and few symbols. Unknown maps to '?'.
const Map<String, List<String>> _font = {
  'A': [
    '01110',
    '10001',
    '11111',
    '10001',
    '10001',
  ],
  'B': [
    '11110',
    '10001',
    '11110',
    '10001',
    '11110',
  ],
  'C': [
    '01111',
    '10000',
    '10000',
    '10000',
    '01111',
  ],
  'D': [
    '11110',
    '10001',
    '10001',
    '10001',
    '11110',
  ],
  'E': [
    '11111',
    '10000',
    '11110',
    '10000',
    '11111',
  ],
  'F': [
    '11111',
    '10000',
    '11110',
    '10000',
    '10000',
  ],
  'G': [
    '01111',
    '10000',
    '10111',
    '10001',
    '01111',
  ],
  'H': [
    '10001',
    '10001',
    '11111',
    '10001',
    '10001',
  ],
  'I': [
    '11111',
    '00100',
    '00100',
    '00100',
    '11111',
  ],
  'J': [
    '00111',
    '00010',
    '00010',
    '10010',
    '01100',
  ],
  'K': [
    '10001',
    '10010',
    '11100',
    '10010',
    '10001',
  ],
  'L': [
    '10000',
    '10000',
    '10000',
    '10000',
    '11111',
  ],
  'M': [
    '10001',
    '11011',
    '10101',
    '10001',
    '10001',
  ],
  'N': [
    '10001',
    '11001',
    '10101',
    '10011',
    '10001',
  ],
  'O': [
    '01110',
    '10001',
    '10001',
    '10001',
    '01110',
  ],
  'P': [
    '11110',
    '10001',
    '11110',
    '10000',
    '10000',
  ],
  'Q': [
    '01110',
    '10001',
    '10001',
    '10011',
    '01111',
  ],
  'R': [
    '11110',
    '10001',
    '11110',
    '10010',
    '10001',
  ],
  'S': [
    '01111',
    '10000',
    '01110',
    '00001',
    '11110',
  ],
  'T': [
    '11111',
    '00100',
    '00100',
    '00100',
    '00100',
  ],
  'U': [
    '10001',
    '10001',
    '10001',
    '10001',
    '01110',
  ],
  'V': [
    '10001',
    '10001',
    '10001',
    '01010',
    '00100',
  ],
  'W': [
    '10001',
    '10001',
    '10101',
    '11011',
    '10001',
  ],
  'X': [
    '10001',
    '01010',
    '00100',
    '01010',
    '10001',
  ],
  'Y': [
    '10001',
    '01010',
    '00100',
    '00100',
    '00100',
  ],
  'Z': [
    '11111',
    '00010',
    '00100',
    '01000',
    '11111',
  ],
  '0': [
    '01110',
    '10011',
    '10101',
    '11001',
    '01110',
  ],
  '1': [
    '00100',
    '01100',
    '00100',
    '00100',
    '01110',
  ],
  '2': [
    '01110',
    '10001',
    '00010',
    '00100',
    '11111',
  ],
  '3': [
    '11110',
    '00001',
    '00110',
    '00001',
    '11110',
  ],
  '4': [
    '10010',
    '10010',
    '11111',
    '00010',
    '00010',
  ],
  '5': [
    '11111',
    '10000',
    '11110',
    '00001',
    '11110',
  ],
  '6': [
    '01111',
    '10000',
    '11110',
    '10001',
    '01110',
  ],
  '7': [
    '11111',
    '00010',
    '00100',
    '01000',
    '01000',
  ],
  '8': [
    '01110',
    '10001',
    '01110',
    '10001',
    '01110',
  ],
  '9': [
    '01110',
    '10001',
    '01111',
    '00001',
    '11110',
  ],
  ' ': [
    '00000',
    '00000',
    '00000',
    '00000',
    '00000',
  ],
  '-': [
    '00000',
    '00000',
    '11111',
    '00000',
    '00000',
  ],
  '_': [
    '00000',
    '00000',
    '00000',
    '00000',
    '11111',
  ],
  '.': [
    '00000',
    '00000',
    '00000',
    '00110',
    '00110',
  ],
  '?': [
    '01110',
    '10001',
    '00110',
    '00000',
    '00100',
  ],
};


