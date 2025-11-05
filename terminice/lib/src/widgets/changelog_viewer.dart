import 'dart:io';

import '../style/theme.dart';
import '../system/frame_renderer.dart';
import '../system/framed_layout.dart';

/// ChangeLogViewer – parse and display a Markdown CHANGELOG nicely.
///
/// Aligns with ThemeDemo styling: titled frame, themed left gutter,
/// tasteful use of accent/highlight colors, and clean spacing.
class ChangeLogViewer {
  final PromptTheme theme;
  final String? filePath;
  final String? content;
  final String title;
  final int maxReleases;
  final bool color;

  ChangeLogViewer({
    this.theme = PromptTheme.dark,
    this.filePath,
    this.content,
    this.title = 'Changelog',
    this.maxReleases = 6,
    this.color = true,
  }) : assert(filePath != null || content != null,
            'Provide either filePath or content');

  /// Parse, format and print to stdout.
  void show() {
    final style = theme.style;
    final label = title;
    final frame = FramedLayout(label, theme: theme);
    stdout.writeln('${theme.bold}${frame.top()}${theme.reset}');

    final raw = content ?? _readFile(filePath!);
    final releases = _parse(raw);

    final gutter = '${theme.gray}${style.borderVertical}${theme.reset} ';
    int count = 0;
    for (final r in releases) {
      if (count++ == maxReleases) break;
      // Release header
      final header = StringBuffer();
      header
        ..write(gutter)
        ..write('${theme.accent}${theme.bold}${r.version}${theme.reset}');
      if (r.date != null && r.date!.isNotEmpty) {
        header
          ..write('  ')
          ..write('${theme.gray}— ${r.date}${theme.reset}');
      }
      stdout.writeln(header.toString());

      // Optional summary notes without section
      for (final note in r.notes) {
        _wrapBulleted(note, gutter, bullet: '•');
      }

      // Sections
      for (final section in r.sections) {
        stdout.writeln(
            '$gutter${theme.dim}${section.name.toUpperCase()}${theme.reset}');
        for (final item in section.items) {
          _wrapBulleted(item, gutter,
              bulletColor: theme.highlight, textColor: theme.reset);
        }
      }

      // Spacing and subtle connector
      stdout.writeln(gutter);
      stdout.writeln(FrameRenderer.bottomLine(r.version, theme));
    }
  }

  void _wrapBulleted(
    String text,
    String gutter, {
    String bullet = '›',
    String? bulletColor,
    String? textColor,
    int width = 92,
  }) {
    final lead = '  ';
    final bulletStyled =
        (bulletColor ?? theme.accent) + bullet + theme.reset;
    final prefix = '$gutter$lead$bulletStyled ';
    final wrapPrefix = '$gutter$lead  ';
    for (final line in _wrap(text, width - _visibleLength(prefix))) {
      if (identical(line, text)) {
        stdout.writeln('$prefix${textColor ?? ''}$line${theme.reset}');
      } else {
        stdout.writeln('$wrapPrefix${textColor ?? ''}$line${theme.reset}');
      }
    }
  }

  static String _readFile(String path) {
    try {
      return File(path).readAsStringSync();
    } catch (_) {
      return '';
    }
  }

  List<_Release> _parse(String md) {
    final lines = md.split('\n');
    final releases = <_Release>[];
    _Release? cur;
    _Section? curSec;

    void endSection() {
      if (curSec != null) {
        cur?.sections.add(curSec!);
        curSec = null;
      }
    }

    void endRelease() {
      endSection();
      if (cur != null) releases.add(cur!);
      cur = null;
    }

    for (var raw in lines) {
      final line = raw.trimRight();
      // Version header: ## 1.2.3 (2025-01-01) or ## [1.2.3] - 2025-01-01
      if (line.startsWith('## ')) {
        endRelease();
        final h = line.substring(3).trim();
        final v = _extractVersion(h);
        final d = _extractDate(h);
        cur = _Release(version: v ?? h, date: d);
        continue;
      }

      // Section header: ### Added / Fixed / Changed / Removed / Security / Deprecated / Breaking
      if (line.startsWith('### ')) {
        endSection();
        final name = line.substring(4).trim();
        curSec = _Section(name: name);
        continue;
      }

      // Bullet items
      final bulletMatch = RegExp(r'^[-*+]\s+').firstMatch(line.trimLeft());
      if (bulletMatch != null) {
        final item = line.trimLeft().substring(bulletMatch.group(0)!.length);
        if (curSec == null) {
          cur?.notes.add(item);
        } else {
          curSec!.items.add(item);
        }
        continue;
      }

      // Plain paragraph line attached to the current context
      if (line.isNotEmpty) {
        if (curSec == null) {
          cur?.notes.add(line);
        } else {
          if (curSec!.items.isEmpty) {
            curSec!.items.add(line);
          } else {
            curSec!.items[curSec!.items.length - 1] += ' ${line.trim()}';
          }
        }
      }
    }

    endRelease();
    return releases;
  }

  static String? _extractVersion(String h) {
    final m = RegExp(r'(\[)?v?([0-9]+\.[0-9]+(?:\.[0-9]+)?)').firstMatch(h);
    return m != null ? 'v${m.group(2)!}' : null;
  }

  static String? _extractDate(String h) {
    // (2025-01-01) or - 2025-01-01
    final m = RegExp(r'(\(|-)\s*(\d{4}-\d{2}-\d{2})').firstMatch(h);
    return m?.group(2);
  }

  List<String> _wrap(String text, int width) {
    final words = text.split(RegExp(r'\s+'));
    final out = <String>[];
    final buf = StringBuffer();
    for (final w in words) {
      if (buf.isEmpty) {
        buf.write(w);
      } else if (_visibleLength(buf.toString()) + 1 + _visibleLength(w) <=
          width) {
        buf.write(' ');
        buf.write(w);
      } else {
        out.add(buf.toString());
        buf.clear();
        buf.write(w);
      }
    }
    if (buf.isNotEmpty) out.add(buf.toString());
    if (out.isEmpty) return [text];
    return out;
  }

  int _visibleLength(String s) {
    final ansi = RegExp(r'\x1B\[[0-9;]*m');
    return s.replaceAll(ansi, '').length;
  }
}

class _Release {
  final String version;
  final String? date;
  final List<String> notes = [];
  final List<_Section> sections = [];

  _Release({required this.version, required this.date});
}

class _Section {
  final String name;
  final List<String> items = [];

  _Section({required this.name});
}


