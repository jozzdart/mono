import '../style/theme.dart';
import '../system/framed_layout.dart';
import '../system/rendering.dart';
import '../system/prompt_runner.dart';

/// ProjectDashboard – comprehensive project stats (builds, tests, coverage)
///
/// Aligns with ThemeDemo styling:
/// - Themed title bar and bottom border
/// - Left gutter uses the theme's vertical border glyph
/// - Tasteful use of accent/info/warn/error colors
class ProjectDashboard {
  final String projectName;
  final PromptTheme theme;

  // Builds
  final int buildsSuccess;
  final int buildsFailed;
  final String? latestBuildLabel; // e.g. Success · 1m42s or Failed · 3m10s
  final String? buildDuration; // e.g. 2m12s
  final List<bool>? buildHistory; // recent build outcomes, oldest -> newest

  // Tests
  final int testsPassed;
  final int testsFailed;
  final int testsSkipped;
  final String? testDuration; // e.g. 1m05s

  // Coverage percent [0..100]
  final double coveragePercent;
  final List<double>? coverageHistory; // recent coverage values [0..100]
  final double? coverageTarget; // quality gate target

  // Optional branch/context label
  final String? branch;

  // Optional repository context
  final String? lastCommit;
  final String? author;
  final String? committedAgo; // e.g. 2h ago
  final String? sdk; // e.g. Dart 3.5.0
  final String? os; // e.g. macOS 15

  ProjectDashboard({
    required this.projectName,
    this.theme = const PromptTheme(),
    this.buildsSuccess = 0,
    this.buildsFailed = 0,
    this.latestBuildLabel,
    this.buildDuration,
    this.buildHistory,
    this.testsPassed = 0,
    this.testsFailed = 0,
    this.testsSkipped = 0,
    this.testDuration,
    this.coveragePercent = 0,
    this.coverageHistory,
    this.coverageTarget,
    this.branch,
    this.lastCommit,
    this.author,
    this.committedAgo,
    this.sdk,
    this.os,
  }) : assert(coveragePercent >= 0 && coveragePercent <= 100);

  void show() {
    final out = RenderOutput();
    _render(out);
  }

  void _render(RenderOutput out) {
    final style = theme.style;

    final title = _title();
    final frame = FramedLayout(title, theme: theme);
    out.writeln('${theme.bold}${frame.top()}${theme.reset}');

    // Overview
    out.writeln(gutterLine(theme, sectionHeader(theme, 'Overview')));
    out.writeln(gutterLine(theme, metric(theme, 'Project', projectName, color: theme.accent)));
    if (branch != null && branch!.isNotEmpty) {
      out.writeln(gutterLine(theme, metric(theme, 'Branch', branch!, color: theme.highlight)));
    }
    if (sdk != null && sdk!.isNotEmpty) {
      out.writeln(gutterLine(theme, metric(theme, 'SDK', sdk!, color: theme.highlight)));
    }
    if (os != null && os!.isNotEmpty) {
      out.writeln(gutterLine(theme, metric(theme, 'OS', os!, color: theme.highlight)));
    }

    // CI Builds
    out.writeln(gutterLine(theme, sectionHeader(theme, 'Builds')));
    final totalTests = testsPassed + testsFailed + testsSkipped;
    out.writeln(gutterLine(theme, metric(theme, 'Success', '$buildsSuccess', color: theme.info)));
    out.writeln(gutterLine(theme, metric(theme, 'Failed', '$buildsFailed', color: theme.error)));
    if (latestBuildLabel != null && latestBuildLabel!.isNotEmpty) {
      out.writeln(gutterLine(theme, metric(theme, 'Latest', latestBuildLabel!, color: _latestColor())));
    }
    if (buildDuration != null && buildDuration!.isNotEmpty) {
      out.writeln(gutterLine(theme, metric(theme, 'Duration', buildDuration!, color: theme.accent)));
    }
    if (buildHistory != null && buildHistory!.isNotEmpty) {
      out.writeln(gutterLine(theme, metric(theme, 'Recent', _buildHistoryLine(buildHistory!))));
    }

    // Tests
    out.writeln(gutterLine(theme, sectionHeader(theme, 'Tests')));
    out.writeln(gutterLine(theme, metric(theme, 'Passed', '$testsPassed', color: theme.info)));
    out.writeln(gutterLine(theme, metric(theme, 'Failed', '$testsFailed', color: theme.error)));
    out.writeln(gutterLine(theme, metric(theme, 'Skipped', '$testsSkipped', color: theme.warn)));
    if (totalTests > 0) {
      out.writeln(gutterLine(theme, metric(
          theme,
          'Pass Rate',
          '${((testsPassed / totalTests) * 100).clamp(0, 100).round()}%',
          color: theme.accent)));
    }
    if (testDuration != null && testDuration!.isNotEmpty) {
      out.writeln(gutterLine(theme, metric(theme, 'Duration', testDuration!, color: theme.accent)));
    }

    // Coverage
    out.writeln(gutterLine(theme, sectionHeader(theme, 'Coverage')));
    out.writeln(gutterLine(theme, _coverageBar(width: 30)));
    out.writeln(gutterLine(theme, metric(theme, 'Percent', '${coveragePercent.toStringAsFixed(1)}%',
        color: _coverageColor())));
    if (coverageTarget != null) {
      out.writeln(gutterLine(theme, metric(
          theme,
          'Quality', (coveragePercent >= coverageTarget!) ? '[PASS]' : '[FAIL]',
          color:
              (coveragePercent >= coverageTarget!) ? theme.info : theme.error)));
    }
    if (coverageHistory != null && coverageHistory!.isNotEmpty) {
      out.writeln(gutterLine(theme, metric(
          theme,
          'History',
          _sparkline(coverageHistory!,
              colorA: theme.accent, colorB: theme.highlight))));
    }

    // Repository
    if ((lastCommit != null && lastCommit!.isNotEmpty) ||
        (author != null && author!.isNotEmpty) ||
        (committedAgo != null && committedAgo!.isNotEmpty)) {
      out.writeln(gutterLine(theme, sectionHeader(theme, 'Repository')));
      if (lastCommit != null && lastCommit!.isNotEmpty) {
        out.writeln(gutterLine(theme, metric(theme, 'Commit', lastCommit!, color: theme.selection)));
      }
      if (author != null && author!.isNotEmpty) {
        out.writeln(gutterLine(theme, metric(theme, 'Author', author!, color: theme.highlight)));
      }
      if (committedAgo != null && committedAgo!.isNotEmpty) {
        out.writeln(gutterLine(theme, metric(theme, 'When', committedAgo!, color: theme.gray)));
      }
    }

    // Bottom
    if (style.showBorder) {
      out.writeln(frame.bottom());
    }
  }

  String _title() => branch == null || branch!.isEmpty
      ? 'Project Dashboard'
      : 'Project Dashboard · $branch';

  String _coverageBar({int width = 20}) {
    final w = width < 6 ? 6 : width;
    final ratio = (coveragePercent / 100).clamp(0, 1.0);
    final filled = (ratio * w).round();
    final buf = StringBuffer();
    for (int i = 0; i < w; i++) {
      final on = i < filled;
      final ch = '─';
      if (on) {
        final color = (i % 2 == 0) ? theme.accent : theme.highlight;
        buf.write('$color$ch${theme.reset}');
      } else {
        buf.write('${theme.dim}$ch${theme.reset}');
      }
    }
    return buf.toString();
  }

  String _latestColor() {
    final label = (latestBuildLabel ?? '').toLowerCase();
    if (label.contains('fail') || label.contains('error')) return theme.error;
    if (label.contains('success') || label.contains('passed')) {
      return theme.info;
    }
    if (label.contains('running') || label.contains('in progress')) {
      return theme.highlight;
    }
    return theme.accent;
  }

  String _coverageColor() {
    if (coveragePercent >= 90) return theme.info;
    if (coveragePercent >= 75) return theme.highlight;
    if (coveragePercent >= 60) return theme.warn;
    return theme.error;
  }

  String _buildHistoryLine(List<bool> history) {
    final buf = StringBuffer();
    for (final ok in history) {
      final color = ok ? theme.info : theme.error;
      // Slim tick for success, subtle dot for failure
      buf.write(ok ? '$color│${theme.reset}' : '$color·${theme.reset}');
    }
    return buf.toString();
  }

  String _sparkline(List<double> values, {String? colorA, String? colorB}) {
    if (values.isEmpty) return '';
    final minV = values.reduce((a, b) => a < b ? a : b);
    final maxV = values.reduce((a, b) => a > b ? a : b);
    final span = (maxV - minV).abs() < 1e-9 ? 1.0 : (maxV - minV);
    const chars = ['▁', '▂', '▃', '▄', '▅', '▆', '▇', '█'];
    final a = colorA ?? theme.accent;
    final b = colorB ?? theme.highlight;
    final out = StringBuffer();
    for (var i = 0; i < values.length; i++) {
      final v = values[i];
      final n = ((v - minV) / span * (chars.length - 1)).clamp(0, 7).round();
      final color = (i % 2 == 0) ? a : b;
      out.write('$color${chars[n]}${theme.reset}');
    }
    return out.toString();
  }

  
}

/// Convenience function mirroring the requested API name.
void projectDashboard({
  required String projectName,
  PromptTheme theme = const PromptTheme(),
  int buildsSuccess = 0,
  int buildsFailed = 0,
  String? latestBuildLabel,
  String? buildDuration,
  List<bool>? buildHistory,
  int testsPassed = 0,
  int testsFailed = 0,
  int testsSkipped = 0,
  String? testDuration,
  double coveragePercent = 0,
  List<double>? coverageHistory,
  double? coverageTarget,
  String? branch,
  String? lastCommit,
  String? author,
  String? committedAgo,
  String? sdk,
  String? os,
}) {
  ProjectDashboard(
    projectName: projectName,
    theme: theme,
    buildsSuccess: buildsSuccess,
    buildsFailed: buildsFailed,
    latestBuildLabel: latestBuildLabel,
    buildDuration: buildDuration,
    buildHistory: buildHistory,
    testsPassed: testsPassed,
    testsFailed: testsFailed,
    testsSkipped: testsSkipped,
    testDuration: testDuration,
    coveragePercent: coveragePercent,
    coverageHistory: coverageHistory,
    coverageTarget: coverageTarget,
    branch: branch,
    lastCommit: lastCommit,
    author: author,
    committedAgo: committedAgo,
    sdk: sdk,
    os: os,
  ).show();
}
