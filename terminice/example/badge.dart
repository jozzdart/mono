import 'dart:io';

import 'package:terminice/src/style/theme.dart';
import 'package:terminice/src/widgets/badge.dart';

void main() {
  final theme = PromptTheme.pastel;

  stdout.writeln('\n${theme.bold}Inline Badges${theme.reset}');
  stdout.writeln(
    'Build:   ' + const Badge.success('SUCCESS', theme: PromptTheme.pastel).render(),
  );
  stdout.writeln(
    'Tests:   ' + const Badge.danger('FAILED', theme: PromptTheme.pastel).render(),
  );
  stdout.writeln(
    'Docs:    ' + const Badge.info('GENERATING', theme: PromptTheme.pastel, inverted: false).render(),
  );
  stdout.writeln(
    'Linter:  ' + const Badge.warning('DEPRECATED', theme: PromptTheme.pastel).render(),
  );
  stdout.writeln(
    'Cache:   ' + const Badge.neutral('PENDING', theme: PromptTheme.pastel, inverted: false).render(),
  );

  // Demonstrate inline concatenation
  stdout.writeln('\n${theme.gray}Pipeline:${theme.reset} '
      '${const Badge.info('SETUP', theme: PromptTheme.pastel).render()} '
      '${const Badge.success('COMPILE', theme: PromptTheme.pastel).render()} '
      '${const Badge.warning('WARNINGS', theme: PromptTheme.pastel, inverted: false).render()} '
      '${const Badge.danger('FAILED', theme: PromptTheme.pastel).render()}');
}


