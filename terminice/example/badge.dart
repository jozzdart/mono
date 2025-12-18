import 'dart:io';

import 'package:terminice/terminice.dart';

void main() {
  final theme = PromptTheme.pastel;
  terminice.badge('Build', tone: BadgeTone.success);
  terminice.badge('Tests', tone: BadgeTone.danger);
  terminice.badge('Docs', tone: BadgeTone.info);
  terminice.badge('Linter', tone: BadgeTone.warning);
  terminice.badge('Cache', tone: BadgeTone.neutral);

  stdout.writeln('\n${theme.bold}Inline Badges${theme.reset}');
  stdout.writeln(
    'Build:   ${Badge.success('SUCCESS').withPastelTheme().render()}',
  );
  stdout.writeln(
    'Tests:   ${Badge.danger('FAILED').withPastelTheme().render()}',
  );
  stdout.writeln(
    'Docs:    ${Badge.info('GENERATING', inverted: false).withPastelTheme().render()}',
  );
  stdout.writeln(
    'Linter:  ${Badge.warning('DEPRECATED').withPastelTheme().render()}',
  );
  stdout.writeln(
    'Cache:   ${Badge.neutral('PENDING', inverted: false).withPastelTheme().render()}',
  );

  // Demonstrate inline concatenation with fluent API
  stdout.writeln('\n${theme.gray}Pipeline:${theme.reset} '
      '${Badge.info('SETUP').withPastelTheme().render()} '
      '${Badge.success('COMPILE').withPastelTheme().render()} '
      '${Badge.warning('WARNINGS', inverted: false).withPastelTheme().render()} '
      '${Badge.danger('FAILED').withPastelTheme().render()}');
}
