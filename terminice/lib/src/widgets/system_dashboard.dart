import 'dart:io';
import 'dart:math' as math;

import '../style/theme.dart';
import '../system/terminal.dart';
import '../system/framed_layout.dart';
import '../system/hints.dart';

/// SystemDashboard – themed, real-time CPU / Memory / Disk bars.
///
/// Aligns with ThemeDemo styling:
/// - Titled frame with themed borders
/// - Left gutter using the theme's vertical border glyph
/// - Accent/highlight colors and tasteful dim text
/// - Subtle shimmering head over filled bar segment
class SystemDashboard {
  final PromptTheme theme;
  final Duration refresh;
  final int barWidth;
  final String diskMount; // e.g. '/'

  SystemDashboard({
    this.theme = const PromptTheme(),
    this.refresh = const Duration(milliseconds: 300),
    this.barWidth = 36,
    this.diskMount = '/',
  }) : assert(barWidth > 6);

  void run() {
    final style = theme.style;

    final term = Terminal.enterRaw();
    Terminal.hideCursor();
    final frame = FramedLayout('System Dashboard', theme: theme);

    void cleanup() {
      term.restore();
      Terminal.showCursor();
    }

    int frameIdx = 0;
    bool firstFrame = true;

    try {
      while (true) {
        final stats = _SystemStats.fetch(diskMount: diskMount);

        final lines = <String>[];

        // Top line
        final top = frame.top();
        lines.add('${theme.bold}$top${theme.reset}');

        // CPU
        lines.add(_renderMetricLine(
          label: 'CPU',
          percent: stats.cpuPercent,
          extra: stats.cpuDetail,
          shimmerPhase: frameIdx,
        ));

        // Memory
        lines.add(_renderMetricLine(
          label: 'Memory',
          percent: stats.memPercent,
          extra: stats.memDetail,
          shimmerPhase: frameIdx + 2,
        ));

        // Disk
        lines.add(_renderMetricLine(
          label: 'Disk',
          percent: stats.diskPercent,
          extra: stats.diskDetail,
          shimmerPhase: frameIdx + 4,
        ));

        // Bottom border
        if (style.showBorder) {
          lines.add(frame.bottom());
        }

        // Hints
        lines.add(Hints.bullets([
          'Ctrl+C to exit',
          'Theme-aware accents',
        ], theme, dim: true));

        // Buffered write to reduce tearing/flicker
        final buffer = StringBuffer();
        if (firstFrame) {
          buffer.write('\x1B[2J\x1B[H'); // clear screen and home on first frame
          firstFrame = false;
        } else {
          buffer.write('\x1B[H'); // home only on subsequent frames
        }
        for (final line in lines) {
          buffer.write('\x1B[2K'); // clear entire line
          buffer.writeln(line);
        }
        stdout.write(buffer.toString());

        frameIdx = (frameIdx + 1) % 10000;
        sleep(refresh);
      }
    } finally {
      cleanup();
    }
  }

  String _renderMetricLine({
    required String label,
    required double percent,
    required String extra,
    required int shimmerPhase,
  }) {
    final style = theme.style;
    final pct = percent.clamp(0, 100);
    final filled = ((pct / 100) * barWidth).round();

    final line = StringBuffer();
    line.write('${theme.gray}${style.borderVertical}${theme.reset} ');
    line.write('${theme.dim}$label:${theme.reset} ');

    // Bar
    for (int i = 0; i < barWidth; i++) {
      if (i >= filled) {
        line.write('${theme.dim}·${theme.reset}');
        continue;
      }

      // Shimmer head near the frontier of the filled section
      final headPos = math.max(0, filled - 1);
      final distance = (i - headPos).abs();
      final headGlow = (3 - distance).clamp(0, 3); // 0..3
      final cycle = ((i + shimmerPhase) % 6);
      final baseColor = (cycle < 3) ? theme.accent : theme.highlight;
      const shades = ['░', '▒', '▓', '█'];
      final ch = shades[headGlow];

      if (i == headPos) {
        line.write('${theme.inverse}$baseColor$ch${theme.reset}');
      } else if (headGlow > 0) {
        line.write('${theme.bold}$baseColor$ch${theme.reset}');
      } else {
        line.write('$baseColor$ch${theme.reset}');
      }
    }

    // Percent and small detail at right
    final pctText = '${pct.toStringAsFixed(0)}%';
    line.write(
        '  ${theme.accent}$pctText${theme.reset}  ${theme.dim}$extra${theme.reset}');

    return line.toString();
  }
}

class _SystemStats {
  final double cpuPercent; // 0..100
  final double memPercent; // 0..100
  final double diskPercent; // 0..100 (mount)
  final String cpuDetail; // e.g., "user/sys/idle"
  final String memDetail; // e.g., "used/total"
  final String diskDetail; // e.g., "used/total on /"

  _SystemStats(
    this.cpuPercent,
    this.memPercent,
    this.diskPercent,
    this.cpuDetail,
    this.memDetail,
    this.diskDetail,
  );

  static _SystemStats fetch({String diskMount = '/'}) {
    if (_isMacOS) return _fetchMac(diskMount);
    if (_isLinux) return _fetchLinux(diskMount);
    return _fallback();
  }

  static _SystemStats _fallback() {
    return _SystemStats(0, 0, 0, 'N/A', 'N/A', 'N/A');
  }

  static bool get _isMacOS => Platform.isMacOS;
  static bool get _isLinux => Platform.isLinux;

  static _SystemStats _fetchMac(String diskMount) {
    // CPU via `top -l 1`: "CPU usage: 7.64% user, 4.39% sys, 87.95% idle"
    double cpuPct = 0;
    String cpuDetail = '—';
    try {
      final out =
          Process.runSync('top', ['-l', '1', '-n', '0']).stdout.toString();
      final line = out.split('\n').firstWhere(
            (l) => l.toLowerCase().contains('cpu usage'),
            orElse: () => '',
          );
      final re = RegExp(
          r'(\d+[\.,]?\d*)%\s*user.*?(\d+[\.,]?\d*)%\s*sys.*?(\d+[\.,]?\d*)%\s*idle',
          caseSensitive: false);
      final m = re.firstMatch(line);
      if (m != null) {
        final user = _parseNum(m.group(1));
        final sys = _parseNum(m.group(2));
        final idle = _parseNum(m.group(3));
        cpuPct = (user + sys).clamp(0, 100);
        cpuDetail =
            'user ${user.toStringAsFixed(1)}%, sys ${sys.toStringAsFixed(1)}%, idle ${idle.toStringAsFixed(1)}%';
      }
    } catch (_) {}

    // Memory via `vm_stat`
    double memPct = 0;
    String memDetail = '—';
    try {
      final out = Process.runSync('vm_stat', const []).stdout.toString();
      // Page size
      int pageSize = 4096;
      final sizeMatch =
          RegExp(r'page size of\s+(\d+) bytes', caseSensitive: false)
              .firstMatch(out);
      if (sizeMatch != null) pageSize = int.parse(sizeMatch.group(1)!);

      int pages(String key) {
        // Match lines like: "Pages free:               12345."
        final m =
            RegExp('^${RegExp.escape(key)}:\\s+(\\d+)\\.?', multiLine: true)
                .firstMatch(out);
        return m != null ? int.parse(m.group(1)!) : 0;
      }

      final free = pages('Pages free') + pages('Pages speculative');
      final active = pages('Pages active');
      final inactive = pages('Pages inactive');
      final wired = pages('Pages wired down') + pages('Pages wired');
      final purgeable = pages('Pages purgeable');
      final compressed = pages('Pages occupied by compressor');

      // Prefer total from sysctl for robustness
      int totalBytes = 0;
      try {
        final sysOut = Process.runSync('sysctl', ['-n', 'hw.memsize'])
            .stdout
            .toString()
            .trim();
        totalBytes = int.tryParse(sysOut) ?? 0;
      } catch (_) {}

      int usedBytes;
      if (totalBytes > 0) {
        // Estimate used as non-free pages
        usedBytes =
            (active + inactive + wired + purgeable + compressed) * pageSize;
      } else {
        final totalPages =
            free + active + inactive + wired + purgeable + compressed;
        totalBytes = totalPages * pageSize;
        usedBytes = (totalPages - free) * pageSize;
      }

      memPct = totalBytes > 0 ? (usedBytes * 100 / totalBytes) : 0;
      memDetail = '${_fmtBytes(usedBytes)}/${_fmtBytes(totalBytes)}';
    } catch (_) {}

    // Disk via `df -k <mount>`
    double diskPct = 0;
    String diskDetail = '—';
    try {
      final out = Process.runSync('df', ['-k', diskMount]).stdout.toString();
      final lines = out.split('\n');
      if (lines.length >= 2) {
        final cols =
            lines[1].split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
        if (cols.length >= 6) {
          final usedK = int.tryParse(cols[2]) ?? 0;
          final totalK = (int.tryParse(cols[1]) ?? 0);
          final usePctStr = cols[4].replaceAll('%', '');
          diskPct = double.tryParse(usePctStr) ??
              (totalK > 0 ? usedK * 100 / totalK : 0);
          diskDetail =
              '${_fmtBytes(usedK * 1024)}/${_fmtBytes(totalK * 1024)} on $diskMount';
        }
      }
    } catch (_) {}

    return _SystemStats(
        cpuPct, memPct, diskPct, cpuDetail, memDetail, diskDetail);
  }

  static _SystemStats _fetchLinux(String diskMount) {
    // CPU via /proc/stat (delta method not feasible in single snapshot here); fallback to load average → approx %
    double cpuPct = 0;
    String cpuDetail = '—';
    try {
      final stat1 = File('/proc/stat')
          .readAsLinesSync()
          .firstWhere((l) => l.startsWith('cpu '));
      sleep(const Duration(milliseconds: 120));
      final stat2 = File('/proc/stat')
          .readAsLinesSync()
          .firstWhere((l) => l.startsWith('cpu '));
      double parseTotals(String line) {
        final parts =
            line.split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
        final nums = parts.skip(1).map((e) => double.tryParse(e) ?? 0).toList();
        return nums.fold(0, (a, b) => a + b);
      }

      double parseIdle(String line) {
        final parts =
            line.split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
        return double.tryParse(parts[4]) ?? 0; // idle
      }

      final total1 = parseTotals(stat1);
      final idle1 = parseIdle(stat1);
      final total2 = parseTotals(stat2);
      final idle2 = parseIdle(stat2);
      final dt = (total2 - total1).abs();
      final di = (idle2 - idle1).abs();
      final busy = dt > 0 ? (1 - (di / dt)) : 0;
      cpuPct = ((busy * 100).clamp(0, 100)).toDouble();
      cpuDetail =
          'busy ${(cpuPct).toStringAsFixed(1)}%, idle ${(100 - cpuPct).toStringAsFixed(1)}%';
    } catch (_) {}

    // Memory via /proc/meminfo
    double memPct = 0;
    String memDetail = '—';
    try {
      final lines = File('/proc/meminfo').readAsLinesSync();
      int val(String key) {
        final l = lines.firstWhere((e) => e.startsWith(key), orElse: () => '');
        final m = RegExp(r'\d+').firstMatch(l);
        return m != null ? int.parse(m.group(0)!) : 0; // in kB
      }

      final total = val('MemTotal');
      final free = val('MemFree');
      final buffers = val('Buffers');
      final cached = val('Cached');
      final available = val('MemAvailable');
      final used = (available > 0)
          ? (total - available)
          : (total - free - buffers - cached);
      memPct = total > 0 ? used * 100 / total : 0;
      memDetail = '${_fmtBytes(used * 1024)}/${_fmtBytes(total * 1024)}';
    } catch (_) {}

    // Disk via df -k
    double diskPct = 0;
    String diskDetail = '—';
    try {
      final out = Process.runSync('df', ['-k', diskMount]).stdout.toString();
      final lines = out.split('\n');
      if (lines.length >= 2) {
        final cols =
            lines[1].split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
        if (cols.length >= 6) {
          final usedK = int.tryParse(cols[2]) ?? 0;
          final totalK = (int.tryParse(cols[1]) ?? 0);
          final usePctStr = cols[4].replaceAll('%', '');
          diskPct = double.tryParse(usePctStr) ??
              (totalK > 0 ? usedK * 100 / totalK : 0);
          diskDetail =
              '${_fmtBytes(usedK * 1024)}/${_fmtBytes(totalK * 1024)} on $diskMount';
        }
      }
    } catch (_) {}

    return _SystemStats(
        cpuPct, memPct, diskPct, cpuDetail, memDetail, diskDetail);
  }
}

double _parseNum(String? s) {
  if (s == null) return 0;
  return double.tryParse(s.replaceAll(',', '.')) ?? 0;
}

String _fmtBytes(int bytes) {
  const units = ['B', 'KB', 'MB', 'GB', 'TB'];
  double v = bytes.toDouble();
  int idx = 0;
  while (v >= 1024 && idx < units.length - 1) {
    v /= 1024;
    idx++;
  }
  return '${v.toStringAsFixed(v >= 10 || v >= 1 ? 1 : 2)} ${units[idx]}';
}
