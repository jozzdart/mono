import 'dart:io';

import 'package:terminice/terminice.dart';

void main() {
  // Dark theme
  ProjectDashboard(
    projectName: 'mono',
    branch: 'main',
    theme: PromptTheme.dark,
    buildsSuccess: 128,
    buildsFailed: 3,
    latestBuildLabel: 'Success',
    buildDuration: '2m12s',
    buildHistory: [
      true,
      true,
      true,
      false,
      true,
      true,
      true,
      true,
      true,
      false,
      true,
      true
    ],
    testsPassed: 1540,
    testsFailed: 12,
    testsSkipped: 31,
    testDuration: '3m41s',
    coveragePercent: 87.6,
    coverageHistory: [83.2, 83.9, 84.1, 85.0, 85.8, 86.0, 86.4, 87.1, 87.6],
    coverageTarget: 85,
    lastCommit: 'a1b2c3d',
    author: 'Jane Doe',
    committedAgo: '2h ago',
    sdk: 'Dart 3.5.0',
    os: 'macOS 15',
  )..show();
  stdout.writeln();

  // Pastel theme
  ProjectDashboard(
    projectName: 'terminice',
    branch: 'feature/ui-polish',
    theme: PromptTheme.pastel,
    buildsSuccess: 42,
    buildsFailed: 1,
    latestBuildLabel: 'Running',
    buildDuration: '1m02s',
    buildHistory: [true, true, true, true, true, true, true, true, true, true],
    testsPassed: 820,
    testsFailed: 5,
    testsSkipped: 12,
    testDuration: '1m58s',
    coveragePercent: 92.3,
    coverageHistory: [90.0, 90.4, 90.8, 91.2, 91.5, 91.9, 92.1, 92.2, 92.3],
    coverageTarget: 90,
    lastCommit: '9f8e7d6',
    author: 'Sam Lee',
    committedAgo: '36m ago',
    sdk: 'Dart 3.5.0',
    os: 'macOS 15',
  )..show();
  stdout.writeln();

  // Matrix theme
  ProjectDashboard(
    projectName: 'mono_core',
    theme: PromptTheme.matrix,
    buildsSuccess: 301,
    buildsFailed: 0,
    latestBuildLabel: 'Success',
    buildDuration: '55s',
    buildHistory: [
      true,
      true,
      true,
      true,
      true,
      true,
      true,
      true,
      true,
      true,
      true,
      true
    ],
    testsPassed: 2310,
    testsFailed: 0,
    testsSkipped: 9,
    testDuration: '4m10s',
    coveragePercent: 96.4,
    coverageHistory: [95.1, 95.3, 95.5, 95.6, 95.9, 96.1, 96.2, 96.3, 96.4],
    coverageTarget: 95,
    lastCommit: 'c0ffee0',
    author: 'Alex Smith',
    committedAgo: '12m ago',
    sdk: 'Dart 3.5.0',
    os: 'macOS 15',
  )..show();
}
