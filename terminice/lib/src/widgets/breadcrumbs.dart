import 'dart:io';

import '../style/theme.dart';
import '../system/framed_layout.dart';

/// Breadcrumbs – file path navigation line.
///
/// Aligns with ThemeDemo styling:
/// - Themed title bar and bottom border
/// - Left gutter uses the theme's vertical border glyph
/// - Alternating accent/highlight for segments, with bold selected segment
class Breadcrumbs {
  final String path;
  final PromptTheme theme;
  final String? label;
  final int maxWidth; // Maximum printable width (approx chars)
  final String separator; // visual separator between segments

  const Breadcrumbs(
    this.path, {
    this.theme = const PromptTheme(),
    this.label,
    this.maxWidth = 80,
    this.separator = '/',
  });

  void show() {
    final style = theme.style;
    final titleText = label ?? 'Breadcrumbs';

    final frame = FramedLayout(titleText, theme: theme);
    stdout.writeln('${theme.bold}${frame.top()}${theme.reset}');

    final rendered = _renderBreadcrumbLine();
    stdout.writeln('${theme.gray}${style.borderVertical}${theme.reset} $rendered');

    if (style.showBorder) {
      stdout.writeln(frame.bottom());
    }
  }

  String _renderBreadcrumbLine() {
    final parts = _splitSegments(path);
    if (parts.isEmpty) return '${theme.dim}$separator${theme.reset}';

    // Build colored segments (last segment emphasized)
    final colored = <String>[];
    for (var i = 0; i < parts.length; i++) {
      final seg = parts[i];
      final isLast = i == parts.length - 1;
      final color = isLast
          ? '${theme.bold}${theme.selection}'
          : (i % 2 == 0 ? theme.accent : theme.highlight);
      final end = theme.reset;
      colored.add('$color$seg$end');
    }

    final sepColored = '${theme.dim}$separator${theme.reset}';
    var line = colored.join('${theme.dim} $separator ${theme.reset}');

    // Ensure we respect maxWidth by collapsing leading segments into ellipsis
    if (_visibleLength(line) > maxWidth) {
      line = _collapseToFit(parts, colored, sepColored, maxWidth);
    }
    return line;
  }

  String _collapseToFit(
    List<String> rawParts,
    List<String> coloredParts,
    String sep,
    int width,
  ) {
    // Always keep last segment visible. Remove from the front until it fits.
    final kept = <String>[];
    // Add ellipsis placeholder (not counted in rawParts)
    final ellipsis = '${theme.dim}…${theme.reset}';

    // Start by keeping the last segment and work backwards.
    int idx = rawParts.length - 1;
    kept.insert(0, coloredParts[idx]);
    idx--;

    // Try to keep as many trailing segments as possible.
    while (idx >= 0) {
      final candidate = '${coloredParts[idx]}$sep${kept.isEmpty ? '' : ' '}${kept.join(' $sep ')}';
      final full = '$ellipsis $sep $candidate';
      if (_visibleLength(full) <= width) {
        kept.insert(0, coloredParts[idx]);
        idx--;
      } else {
        break;
      }
    }

    return kept.length == rawParts.length
        ? kept.join(' $sep ')
        : '$ellipsis $sep ${kept.join(' $sep ')}';
  }

  List<String> _splitSegments(String p) {
    if (p.trim().isEmpty) return <String>[];

    // Normalize and split by either '/' or '\\' to handle cross-platform paths
    final norm = p.replaceAll('\\', '/');

    // Handle absolute root specially to avoid an empty first segment
    final segments = norm.split('/').where((s) => s.isNotEmpty).toList();

    // Windows drive prefix (e.g., C:) or Unix root
    final hasWindowsDrive = RegExp(r'^[A-Za-z]:').hasMatch(norm);
    final isUnixRoot = norm.startsWith('/');

    final out = <String>[];
    if (hasWindowsDrive) {
      final drive = norm.substring(0, 2); // e.g., C:
      out.add(drive);
      // remaining segments already include the first folder
      if (segments.isNotEmpty && segments.first.toUpperCase() == drive.toUpperCase()) {
        segments.removeAt(0);
      }
    } else if (isUnixRoot) {
      out.add('/');
    }

    out.addAll(segments);
    return out;
  }

  int _visibleLength(String s) => _stripAnsi(s).length;

  String _stripAnsi(String input) {
    final ansi = RegExp(r'\x1B\[[0-9;]*m');
    return input.replaceAll(ansi, '');
  }
}

/// Convenience function mirroring the class API.
void breadcrumbs(
  String path, {
  PromptTheme theme = const PromptTheme(),
  String? label,
  int maxWidth = 80,
  String separator = '/',
}) {
  Breadcrumbs(
    path,
    theme: theme,
    label: label,
    maxWidth: maxWidth,
    separator: separator,
  ).show();
}


