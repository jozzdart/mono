import 'dart:io';

import 'package:terminice/terminice.dart';

void main() {
  final series = <num>[
    12,
    13,
    11,
    14,
    16,
    18,
    17,
    19,
    22,
    25,
    24,
    28,
    31,
    29,
    35
  ];

  MiniAnalytics(
    series: series,
    label: 'Revenue',
    theme: PromptTheme.dark,
    title: 'Mini Analytics · Dark',
  ).show();
  stdout.writeln();

  MiniAnalytics(
    series: series,
    label: 'Users',
    theme: PromptTheme.pastel,
    title: 'Mini Analytics · Pastel',
  ).show();
  stdout.writeln();

  miniAnalytics(
    series,
    label: 'Sessions',
    theme: PromptTheme.fire,
    title: 'Mini Analytics · Fire',
  );

  miniAnalytics(
    series,
    label: 'Sessions',
    theme: PromptTheme.matrix,
    title: 'Mini Analytics · Fire',
  );
}
