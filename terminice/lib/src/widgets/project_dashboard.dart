import '../style/theme.dart';
import '../system/widget_frame.dart';

/// ProjectDashboard – comprehensive project stats (builds, tests, coverage)
///
/// Aligns with ThemeDemo styling:
/// - Themed title bar and bottom border
/// - Left gutter uses the theme's vertical border glyph
/// - Tasteful use of accent/info/warn/error colors
///
/// **Mixins:** Implements [Themeable] for fluent theme configuration:
/// ```dart
/// ProjectDashboard(projectName: 'MyApp').withPastelTheme().show();
/// ```
class ProjectDashboard with Themeable {
  final String projectName;
  @override
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
    this.theme = PromptTheme.dark,
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

  @override
  ProjectDashboard copyWithTheme(PromptTheme theme) {
    return ProjectDashboard(
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
    );
  }

  void show() {
    final frame = WidgetFrame(title: _title(), theme: theme);
    frame.show((ctx) {
      // Overview
      ctx.sectionHeader('Overview');
      ctx.labeledAccent('Project', projectName);
      if (branch != null && branch!.isNotEmpty) {
        ctx.keyValue('Branch', branch!);
      }
      if (sdk != null && sdk!.isNotEmpty) {
        ctx.keyValue('SDK', sdk!);
      }
      if (os != null && os!.isNotEmpty) {
        ctx.keyValue('OS', os!);
      }

      // CI Builds
      ctx.sectionHeader('Builds');
      final totalTests = testsPassed + testsFailed + testsSkipped;
      ctx.statItem('Success', '$buildsSuccess', icon: '✔', tone: StatTone.info);
      ctx.statItem('Failed', '$buildsFailed', icon: '✖', tone: StatTone.error);
      if (latestBuildLabel != null && latestBuildLabel!.isNotEmpty) {
        ctx.keyValue('Latest', latestBuildLabel!);
      }
      if (buildDuration != null && buildDuration!.isNotEmpty) {
        ctx.keyValue('Duration', buildDuration!);
      }
      if (buildHistory != null && buildHistory!.isNotEmpty) {
        ctx.gutterLine(
            '${theme.dim}Recent:${theme.reset} ${_buildHistoryLine(buildHistory!)}');
      }

      // Tests
      ctx.sectionHeader('Tests');
      ctx.statItem('Passed', '$testsPassed', icon: '✔', tone: StatTone.info);
      ctx.statItem('Failed', '$testsFailed', icon: '✖', tone: StatTone.error);
      ctx.statItem('Skipped', '$testsSkipped', icon: '⊘', tone: StatTone.warn);
      if (totalTests > 0) {
        ctx.keyValue('Pass Rate',
            '${((testsPassed / totalTests) * 100).clamp(0, 100).round()}%');
      }
      if (testDuration != null && testDuration!.isNotEmpty) {
        ctx.keyValue('Duration', testDuration!);
      }

      // Coverage
      ctx.sectionHeader('Coverage');
      ctx.progressBar(coveragePercent / 100, width: 30);
      ctx.keyValue('Percent', '${coveragePercent.toStringAsFixed(1)}%');
      if (coverageTarget != null) {
        final passed = coveragePercent >= coverageTarget!;
        ctx.statItem(
            'Quality Gate', passed ? 'PASS' : 'FAIL',
            icon: passed ? '✔' : '✖',
            tone: passed ? StatTone.info : StatTone.error);
      }
      if (coverageHistory != null && coverageHistory!.isNotEmpty) {
        ctx.gutterLine(
            '${theme.dim}History:${theme.reset} ${_sparkline(coverageHistory!, colorA: theme.accent, colorB: theme.highlight)}');
      }

      // Repository
      if ((lastCommit != null && lastCommit!.isNotEmpty) ||
          (author != null && author!.isNotEmpty) ||
          (committedAgo != null && committedAgo!.isNotEmpty)) {
        ctx.sectionHeader('Repository');
        if (lastCommit != null && lastCommit!.isNotEmpty) {
          ctx.keyValue('Commit', lastCommit!);
        }
        if (author != null && author!.isNotEmpty) {
          ctx.keyValue('Author', author!);
        }
        if (committedAgo != null && committedAgo!.isNotEmpty) {
          ctx.dimMessage('$committedAgo');
        }
      }
    });
  }

  String _title() => branch == null || branch!.isEmpty
      ? 'Project Dashboard'
      : 'Project Dashboard · $branch';

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
