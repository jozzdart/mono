import 'dart:io';
import 'dart:math' as math;

import '../style/theme.dart';
import '../system/terminal.dart';
import '../system/key_events.dart';
import '../system/hints.dart';
import '../system/framed_layout.dart';
// no import for TextPrompt; hex input handled synchronously

/// Interactive color picker with ANSI preview and hex output.
///
/// - Arrow keys move the selection on a color grid
/// - Enter confirms the selected color
/// - Esc cancels
///
/// Visuals align with ThemeDemo via FrameRenderer and PromptTheme.
class ColorPickerPrompt {
  final String label;
  final PromptTheme theme;
  final String? initialHex; // e.g., "#FF00AA"

  /// Columns (hue steps) and rows (value/brightness steps)
  final int cols;
  final int rows;

  ColorPickerPrompt({
    this.label = 'Pick a color',
    this.theme = PromptTheme.dark,
    this.initialHex,
    this.cols = 24,
    this.rows = 8,
  })  : assert(cols >= 6 && cols <= 48),
        assert(rows >= 3 && rows <= 24);

  // ───────── Runtime state ─────────
  late PromptStyle _style;
  int _selX = 0;
  int _selY = 0;
  double _saturation = 1.0;
  int _presetIndex = -1;
  late List<Map<String, String>> _presets;
  bool _cancelled = false;

  /// Runs the picker and returns a hex string like "#RRGGBB" or null if cancelled.
  String? run() {
    _style = theme.style;
    _selX = 0;
    _selY = math.max(0, rows ~/ 2 - 1);
    _saturation = 1.0;
    _presetIndex = -1;
    // Curated vibrant presets (Tailwind-like palette)
    _presets = [
      {'h': '#EF4444'}, // Red 500
      {'h': '#F97316'}, // Orange 500
      {'h': '#F59E0B'}, // Amber 500
      {'h': '#EAB308'}, // Yellow 500
      {'h': '#84CC16'}, // Lime 500
      {'h': '#22C55E'}, // Green 500
      {'h': '#14B8A6'}, // Teal 500
      {'h': '#0EA5E9'}, // Sky 500
      {'h': '#3B82F6'}, // Blue 500
      {'h': '#8B5CF6'}, // Violet 500
    ];

    if (initialHex != null && _isValidHex(initialHex!)) {
      _setFromHex(initialHex!);
    }

    final term = Terminal.enterRaw();
    Terminal.hideCursor();

    void cleanup() {
      term.restore();
      Terminal.showCursor();
    }

    void render() {
      Terminal.clearAndHome();
      _renderTitle();
      _renderSubtitle();
      if (_style.showBorder) {
        final frame = FramedLayout(label, theme: theme);
        stdout.writeln(frame.connector());
      }
      _renderCaretLine();
      _renderGrid();
      _renderPresets();
      _renderSwatchAndHex();
      if (_style.showBorder) {
        final frame = FramedLayout(label, theme: theme);
        stdout.writeln(frame.bottom());
      }
      _renderHints();
    }

    render();

    try {
      while (true) {
        final ev = KeyEventReader.read();
        if (ev.type == KeyEventType.enter) break;
        if (ev.type == KeyEventType.esc || ev.type == KeyEventType.ctrlC) {
          _cancelled = true;
          break;
        }
        _handleKey(ev);
        render();
      }
    } finally {
      cleanup();
    }

    Terminal.clearAndHome();
    Terminal.showCursor();
    return _cancelled ? null : _selectedHex();
  }

  // ───────── Rendering ─────────
  void _renderTitle() {
    final frame = FramedLayout(label, theme: theme);
    final top = frame.top();
    if (_style.boldPrompt) stdout.writeln('${theme.bold}$top${theme.reset}');
  }

  void _renderSubtitle() {
    final subtitle =
        '${theme.gray}${_style.borderVertical}${theme.reset} ${theme.accent}Pick visually. ${theme.reset}${theme.dim}(←/→ hue, ↑/↓ brightness, S saturation)${theme.reset}';
    stdout.writeln(subtitle);
  }

  void _renderCaretLine() {
    final caretColumn = _selX * 2;
    final prefix = '${theme.gray}${_style.borderVertical}${theme.reset} ';
    final caretPad = ' ' * caretColumn;
    final caretLine = '$prefix$caretPad${theme.selection}^^${theme.reset}';
    stdout.writeln(caretLine);
  }

  void _renderGrid() {
    for (int y = 0; y < rows; y++) {
      final line = StringBuffer();
      line.write('${theme.gray}${_style.borderVertical}${theme.reset} ');
      for (int x = 0; x < cols; x++) {
        final hsv = _cellToHsv(x, y, cols, rows, _saturation);
        final rgb = _hsvToRgb(hsv[0], hsv[1], hsv[2]);
        final isSel = (x == _selX && y == _selY);
        line
          ..write(_bg(rgb[0], rgb[1], rgb[2]))
          ..write(isSel ? '${theme.inverse}  ${theme.reset}' : '  ')
          ..write(theme.reset);
      }
      stdout.writeln(line.toString());
    }
  }

  void _renderPresets() {
    final presetsLine = StringBuffer();
    presetsLine.write('${theme.gray}${_style.borderVertical}${theme.reset} ');
    for (int i = 0; i < _presets.length; i++) {
      final hex = _presets[i]['h']!;
      final rgb = _hexToRgb(hex);
      final isCur = i == _presetIndex;
      final indexLabel = ((i + 1) % 10).toString();
      final labelText =
          isCur ? '${theme.inverse}$indexLabel${theme.reset}' : indexLabel;
      presetsLine
        ..write(_bg(rgb[0], rgb[1], rgb[2]))
        ..write(' $labelText ')
        ..write(theme.reset);
    }
    stdout.writeln(presetsLine.toString());
  }

  void _renderSwatchAndHex() {
    final hex = _selectedHex();
    final rgb = _hexToRgb(hex);
    final swatch = '${_bg(rgb[0], rgb[1], rgb[2])}      ${theme.reset}';
    stdout.writeln(
        '${theme.gray}${_style.borderVertical}${theme.reset} $swatch ${theme.accent}$hex${theme.reset}');
  }

  void _renderHints() {
    stdout.writeln(Hints.grid([
      ['←/→', 'hue'],
      ['↑/↓', 'brightness'],
      ['[ / ]', 'sat − / +'],
      ['- / =', 'bright − / +'],
      ['S', 'cycle saturation'],
      ['H', 'type hex'],
      ['X', 'reset'],
      ['1-0', 'presets'],
      ['R', 'random'],
      ['Enter', 'confirm'],
      ['Esc', 'cancel'],
    ], theme));
  }

  // ───────── Behavior ─────────
  void _handleKey(KeyEvent ev) {
    if (ev.type == KeyEventType.arrowLeft) {
      _selX = (_selX - 1 + cols) % cols;
      return;
    }
    if (ev.type == KeyEventType.arrowRight) {
      _selX = (_selX + 1) % cols;
      return;
    }
    if (ev.type == KeyEventType.arrowUp) {
      _selY = math.max(0, _selY - 1);
      return;
    }
    if (ev.type == KeyEventType.arrowDown) {
      _selY = math.min(rows - 1, _selY + 1);
      return;
    }
    if (ev.type == KeyEventType.char && ev.char != null) {
      final c = ev.char!;
      if (c == 's' || c == 'S') {
        if (_saturation > 0.9) {
          _saturation = 0.7;
        } else if (_saturation > 0.6) {
          _saturation = 0.4;
        } else {
          _saturation = 1.0;
        }
        return;
      }
      if (c == '[') {
        _saturation = (_saturation - 0.1).clamp(0.0, 1.0);
        return;
      }
      if (c == ']') {
        _saturation = (_saturation + 0.1).clamp(0.0, 1.0);
        return;
      }
      if (c == '-') {
        _selY = math.min(rows - 1, _selY + 1);
        return;
      }
      if (c == '=' || c == '+') {
        _selY = math.max(0, _selY - 1);
        return;
      }
      if (c == 'r' || c == 'R') {
        _selX = math.Random().nextInt(cols);
        _selY = math.Random().nextInt(rows);
        _presetIndex = -1;
        return;
      }
      if (c == 'x' || c == 'X') {
        if (initialHex != null && _isValidHex(initialHex!)) {
          _setFromHex(initialHex!);
        } else {
          _selX = 0;
          _selY = math.max(0, rows ~/ 2 - 1);
          _saturation = 1.0;
          _presetIndex = -1;
        }
        return;
      }
      if (c == 'h' || c == 'H') {
        final value = _promptHexSync();
        if (value != null && _isValidHex(value)) {
          _setFromHex(value);
          _presetIndex = -1;
        }
        return;
      }
      if (RegExp(r'^[0-9]$').hasMatch(c)) {
        int idx = c == '0' ? 9 : int.parse(c) - 1;
        if (idx < _presets.length) {
          _setFromHex(_presets[idx]['h']!);
          _presetIndex = idx;
        }
        return;
      }
    }
  }

  void _setFromHex(String hex) {
    final rgb = _hexToRgb(hex);
    final hsv = _rgbToHsv(rgb[0], rgb[1], rgb[2]);
    _selX = (hsv[0] / 360 * cols).round().clamp(0, cols - 1);
    final v = hsv[2].clamp(0.0, 1.0);
    _selY = ((1 - v) * (rows - 1)).round().clamp(0, rows - 1);
    _saturation = hsv[1].clamp(0.0, 1.0);
  }

  String _selectedHex() {
    final hsv = _cellToHsv(_selX, _selY, cols, rows, _saturation);
    final rgb = _hsvToRgb(hsv[0], hsv[1], hsv[2]);
    return _rgbToHex(rgb[0], rgb[1], rgb[2]);
  }

  String? _promptHexSync() {
    stdout.writeln('');
    final prevEcho = stdin.echoMode;
    final prevLine = stdin.lineMode;
    try {
      stdin.echoMode = true;
      stdin.lineMode = true;
      Terminal.showCursor();
      stdout.write('${theme.accent}Hex${theme.reset} (#RRGGBB): ');
      final input = stdin.readLineSync();
      final value = input?.trim();
      if (value == null) return null;
      return value;
    } finally {
      stdin.echoMode = prevEcho == true ? true : false;
      stdin.lineMode = prevLine == true ? true : false;
      Terminal.hideCursor();
    }
  }
}

// ───────────────────────── Utilities ─────────────────────────

bool _isValidHex(String s) => RegExp(r'^#?[0-9a-fA-F]{6}$').hasMatch(s.trim());

List<int> _hexToRgb(String hex) {
  final h = hex.startsWith('#') ? hex.substring(1) : hex;
  final r = int.parse(h.substring(0, 2), radix: 16);
  final g = int.parse(h.substring(2, 4), radix: 16);
  final b = int.parse(h.substring(4, 6), radix: 16);
  return [r, g, b];
}

String _rgbToHex(int r, int g, int b) {
  String two(int v) => v.toRadixString(16).padLeft(2, '0');
  return '#${two(r)}${two(g)}${two(b)}'.toUpperCase();
}

/// hsv: h in [0,360), s,v in [0,1]
List<int> _hsvToRgb(double h, double s, double v) {
  final c = v * s;
  final hp = (h % 360) / 60.0;
  final x = c * (1 - (hp % 2 - 1).abs());
  double r1 = 0, g1 = 0, b1 = 0;
  if (hp < 1) {
    r1 = c;
    g1 = x;
  } else if (hp < 2) {
    r1 = x;
    g1 = c;
  } else if (hp < 3) {
    g1 = c;
    b1 = x;
  } else if (hp < 4) {
    g1 = x;
    b1 = c;
  } else if (hp < 5) {
    r1 = x;
    b1 = c;
  } else {
    r1 = c;
    b1 = x;
  }
  final m = v - c;
  final r = ((r1 + m) * 255).round().clamp(0, 255);
  final g = ((g1 + m) * 255).round().clamp(0, 255);
  final b = ((b1 + m) * 255).round().clamp(0, 255);
  return [r, g, b];
}

/// rgb 0..255 -> hsv with h in 0..360, s,v 0..1
List<double> _rgbToHsv(int r, int g, int b) {
  final double rf = r / 255.0;
  final double gf = g / 255.0;
  final double bf = b / 255.0;
  final double maxv = [rf, gf, bf].reduce(math.max);
  final double minv = [rf, gf, bf].reduce(math.min);
  final double d = maxv - minv;
  double h = 0.0;
  if (d == 0) {
    h = 0.0;
  } else if (maxv == rf) {
    h = 60 * (((gf - bf) / d) % 6);
  } else if (maxv == gf) {
    h = 60 * (((bf - rf) / d) + 2);
  } else {
    h = 60 * (((rf - gf) / d) + 4);
  }
  if (h < 0) h += 360;
  final double s = maxv == 0.0 ? 0.0 : d / maxv;
  final double v = maxv;
  return [h, s, v];
}

String _bg(int r, int g, int b) => '\x1B[48;2;$r;$g;${b}m';

List<double> _cellToHsv(int x, int y, int cols, int rows, double sat) {
  final hue = (x / (cols)) * 360.0;
  final s = sat.clamp(0.0, 1.0);
  // Bright at top row, darker towards bottom (min ~0.35)
  final v = 1.0 - (y / (rows - 1)) * 0.65;
  return [hue, s, v];
}
