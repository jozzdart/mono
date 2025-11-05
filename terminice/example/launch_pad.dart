import '../lib/src/src.dart';
import 'dart:io';

void main() {
  final actions = <LaunchAction>[
    LaunchAction('Build', icon: '>>', description: 'Compile project', onActivate: () {
      stdout.writeln('Building...');
      sleep(const Duration(milliseconds: 500));
      stdout.writeln('Done.');
    }),
    LaunchAction('Test', icon: 'OK', description: 'Run unit tests', onActivate: () {
      stdout.writeln('Running tests...');
      sleep(const Duration(milliseconds: 500));
      stdout.writeln('All tests passed.');
    }),
    LaunchAction('Docs', icon: 'DOC', description: 'Open documentation', onActivate: () {
      stdout.writeln('Opening docs...');
    }),
    LaunchAction('Lint', icon: 'LINT', description: 'Static analysis', onActivate: () {
      stdout.writeln('Linting...');
      sleep(const Duration(milliseconds: 400));
      stdout.writeln('No issues found.');
    }),
    LaunchAction('Format', icon: 'FMT', description: 'Format code', onActivate: () {
      stdout.writeln('Formatting...');
    }),
    LaunchAction('Publish', icon: 'PUB', description: 'Release package', onActivate: () {
      stdout.writeln('Publishing...');
    }),
    LaunchAction('Clean', icon: 'RM', description: 'Remove build outputs', onActivate: () {
      stdout.writeln('Cleaning...');
    }),
    LaunchAction('Serve', icon: 'SRV', description: 'Run dev server', onActivate: () {
      stdout.writeln('Starting dev server...');
    }),
    LaunchAction('Settings', icon: 'CFG', description: 'Configure tools', onActivate: () {
      stdout.writeln('Opening settings...');
    }),
  ];

  final pad = LaunchPad(
    'LaunchPad',
    actions,
    theme: PromptTheme.pastel, // Try .dark, .matrix, .fire, .pastel
    tileHeight: 4,
  );

  final chosen = pad.run(executeOnEnter: true);
  if (chosen == null) {
    stdout.writeln('Cancelled.');
  } else {
    stdout.writeln('Selected: ${chosen.label}');
  }
}


