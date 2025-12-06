import 'dart:io';

import 'package:terminice/terminice.dart';

void main() {
  final items = <StatCardItem>[
    const StatCardItem(
        label: 'Tests', value: '98%', icon: '✔', tone: StatCardTone.info),
    const StatCardItem(
        label: 'Builds', value: '12', icon: '⬤', tone: StatCardTone.accent),
    const StatCardItem(
        label: 'Warnings', value: '2', icon: '⚠', tone: StatCardTone.warn),
    const StatCardItem(
        label: 'Uptime', value: '24d', icon: '⏱', tone: StatCardTone.accent),
  ];

  // Dark theme
  StatCards(items: items, theme: PromptTheme.dark, title: 'Stat Cards · Dark')
    ..show();
  stdout.writeln();

  // Pastel theme
  StatCards(
      items: items, theme: PromptTheme.pastel, title: 'Stat Cards · Pastel')
    ..show();
  stdout.writeln();

  // Fire theme
  statCards(items, theme: PromptTheme.fire, title: 'Stat Cards · Fire');
}
