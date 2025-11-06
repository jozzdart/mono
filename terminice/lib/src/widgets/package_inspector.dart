import 'dart:io';

import '../style/theme.dart';
import '../system/framed_layout.dart';
import '../system/rendering.dart';

/// PackageInspector – explore package dependencies and info.
///
/// Aligns with ThemeDemo styling:
/// - Themed title bar and bottom border
/// - Left gutter uses the theme's vertical border glyph
/// - Tasteful use of accent/info/warn/error colors
class PackageInspector {
  final PromptTheme theme;
  final String packageName;
  final String? sdkConstraint;
  final Map<String, String> dependencies;
  final Map<String, String> devDependencies;

  PackageInspector({
    this.theme = const PromptTheme(),
    required this.packageName,
    this.sdkConstraint,
    Map<String, String>? dependencies,
    Map<String, String>? devDependencies,
  })  : dependencies = dependencies ?? const {},
        devDependencies = devDependencies ?? const {};

  void show() {
    final style = theme.style;

    final title = _title();
    final frame = FramedLayout(title, theme: theme);
    stdout.writeln('${theme.bold}${frame.top()}${theme.reset}');

    stdout.writeln(gutterLine(theme, sectionHeader(theme, 'Overview')));
    stdout.writeln(gutterLine(
        theme, metric(theme, 'Package', packageName, color: theme.accent)));
    if ((sdkConstraint ?? '').trim().isNotEmpty) {
      stdout.writeln(gutterLine(theme,
          metric(theme, 'SDK', sdkConstraint!.trim(), color: theme.highlight)));
    }
    stdout.writeln(gutterLine(
        theme,
        metric(theme, 'Dependencies', '${dependencies.length}',
            color: theme.info)));
    stdout.writeln(gutterLine(
        theme,
        metric(theme, 'Dev Dependencies', '${devDependencies.length}',
            color: theme.gray)));

    if (dependencies.isNotEmpty) {
      stdout.writeln(gutterLine(theme, sectionHeader(theme, 'Dependencies')));
      for (final entry in _sorted(dependencies)) {
        stdout.writeln(gutterLine(theme, _dep(entry.key, entry.value)));
      }
    }

    if (devDependencies.isNotEmpty) {
      stdout
          .writeln(gutterLine(theme, sectionHeader(theme, 'Dev Dependencies')));
      for (final entry in _sorted(devDependencies)) {
        stdout.writeln(
            gutterLine(theme, _dep(entry.key, entry.value, dev: true)));
      }
    }

    if (style.showBorder) {
      stdout.writeln(frame.bottom());
    }
  }

  String _title() => 'Package Inspector';

  List<MapEntry<String, String>> _sorted(Map<String, String> map) {
    final list = map.entries.toList();
    list.sort((a, b) => a.key.compareTo(b.key));
    return list;
  }

  String _dep(String name, String constraint, {bool dev = false}) {
    final label = dev ? '${theme.dim}$name${theme.reset}' : name;
    final constraintTrimmed = constraint.trim();
    final color = _constraintColor(constraintTrimmed);
    return '${theme.dim}- ${theme.reset}$label ${theme.dim}→${theme.reset} $color$constraintTrimmed${theme.reset}';
  }

  String _constraintColor(String constraint) {
    final c = constraint;
    if (c == 'any' || c == '*') return theme.warn;
    if (c.startsWith('^') || c.startsWith('~')) return theme.info;
    if (RegExp(r'\d').hasMatch(c)) return theme.highlight;
    return theme.accent;
  }

  /// Convenience helper to parse a minimal pubspec.yaml for common fields.
  /// This avoids third-party YAML dependencies by using a simple indentation
  /// aware reader for common cases. It supports simple `name:`,
  /// `environment: sdk:`, `dependencies:` and `dev_dependencies:` string forms.
  static PackageInspector fromPubspecFile(String path,
      {PromptTheme theme = const PromptTheme()}) {
    String name = 'unknown';
    String? sdk;
    final deps = <String, String>{};
    final devDeps = <String, String>{};

    try {
      final lines = File(path).readAsLinesSync();
      String currentTop = '';
      int currentIndent = 0;

      String trimmed(String s) => s.trimRight();
      int indentOf(String s) {
        int i = 0;
        while (i < s.length && s[i] == ' ') {
          i++;
        }
        return i;
      }

      for (var raw in lines) {
        var line = trimmed(raw);
        if (line.trim().isEmpty) continue;
        if (line.trimLeft().startsWith('#')) continue;

        final indent = indentOf(line);
        final t = line.trimLeft();

        // Top-level key detection
        if (!t.startsWith('-') && !t.startsWith('#') && indent == 0) {
          final parts = t.split(':');
          currentTop = parts.first.trim();
          currentIndent = indent;
          if (currentTop == 'name') {
            name = parts.skip(1).join(':').trim();
            name = name.replaceAll("'", '').replaceAll('"', '');
          }
          continue;
        }

        // environment.sdk (nested)
        if (currentTop == 'environment') {
          if (indent > currentIndent) {
            final parts = t.split(':');
            if (parts.first.trim() == 'sdk' && parts.length >= 2) {
              var v = parts.skip(1).join(':').trim();
              v = v.replaceAll("'", '').replaceAll('"', '');
              sdk = v;
            }
            continue;
          } else {
            currentTop = '';
          }
        }

        // Simple maps under dependencies and dev_dependencies
        if ((currentTop == 'dependencies' ||
            currentTop == 'dev_dependencies')) {
          if (indent > currentIndent) {
            final idx = t.indexOf(':');
            if (idx > 0) {
              final key = t.substring(0, idx).trim();
              var val = t.substring(idx + 1).trim();
              // Skip complex map/object values
              if (val.startsWith('{') || val.startsWith('[')) continue;
              if (val.isEmpty) continue;
              val = val.replaceAll("'", '').replaceAll('"', '');
              if (currentTop == 'dependencies') {
                deps[key] = val;
              } else {
                devDeps[key] = val;
              }
            }
            continue;
          } else {
            currentTop = '';
          }
        }
      }
    } catch (_) {
      // ignore parse errors and fall back to minimal info
    }

    return PackageInspector(
      theme: theme,
      packageName: name,
      sdkConstraint: sdk,
      dependencies: deps,
      devDependencies: devDeps,
    );
  }
}
