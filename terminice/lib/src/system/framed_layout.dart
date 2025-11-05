import 'dart:io';

import '../style/theme.dart';
import 'frame_renderer.dart';
import 'hints.dart';
import 'terminal.dart';

/// FramedLayout – small helper to standardize framed output:
/// - Title (with or without borders depending on theme.style.showBorder)
/// - Connector and bottom lines
/// - Left gutter rendering
/// - Hints grid printing
class FramedLayout {
  final String title;
  final PromptTheme theme;

  const FramedLayout(this.title, {this.theme = const PromptTheme()});

  /// Returns the top title line (unstyled; caller may add bold if desired).
  String top() {
    final s = theme.style;
    return s.showBorder
        ? FrameRenderer.titleWithBorders(title, theme)
        : FrameRenderer.plainTitle(title, theme);
  }

  /// Returns the connector line sized to the title/content width.
  String connector() {
    return FrameRenderer.connectorLine(title, theme);
  }

  /// Returns the bottom line sized to match the top.
  String bottom() {
    return FrameRenderer.bottomLine(title, theme);
  }

  /// Prints the top line. Set [bold] if the caller wants bold styling.
  void printTop({bool bold = false}) {
    final t = top();
    if (bold) {
      stdout.writeln('${theme.bold}$t${theme.reset}');
    } else {
      stdout.writeln(t);
    }
  }

  /// Prints the connector line if borders are enabled in the theme style.
  void printConnector() {
    if (theme.style.showBorder) {
      stdout.writeln(connector());
    }
  }

  /// Prints the bottom line if borders are enabled in the theme style.
  void printBottom() {
    if (theme.style.showBorder) {
      stdout.writeln(bottom());
    }
  }

  /// Writes one line prefixed with the themed left gutter.
  void gutter(String content) {
    final s = theme.style;
    if (content.trim().isEmpty) {
      stdout.writeln('${theme.gray}${s.borderVertical}${theme.reset}');
      return;
    }
    stdout.writeln('${theme.gray}${s.borderVertical}${theme.reset} $content');
  }

  /// Writes an empty gutter-only line.
  void gutterEmpty() {
    final s = theme.style;
    stdout.writeln('${theme.gray}${s.borderVertical}${theme.reset}');
  }

  /// Prints a grid of hints below the frame.
  void printHintsGrid(List<List<String>> rows) {
    stdout.writeln(Hints.grid(rows, theme));
  }

  /// Clears the screen and moves the cursor home.
  void clearAndHome() {
    Terminal.clearAndHome();
  }

  /// Convenience method to render a full frame around [body].
  void withFrame({required void Function() body, List<List<String>>? hints}) {
    // Respect the theme.showBorder setting for connector/bottom.
    final s = theme.style;
    printTop(bold: s.boldPrompt);
    if (s.showBorder) stdout.writeln(connector());
    body();
    if (s.showBorder) stdout.writeln(bottom());
    if (hints != null && hints.isNotEmpty) {
      printHintsGrid(hints);
    }
  }
}


