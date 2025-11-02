import 'dart:io';

import 'package:mono_cli/mono_cli.dart';
import 'package:test/test.dart';

void main() {
  group('ConsolePrompter (non-TTY)', () {
    const prompter = ConsolePrompter();

    test('confirm throws without TTY', () async {
      if (stdin.hasTerminal) {
        return; // Skip when running interactively
      }
      expect(
        () => prompter.confirm('Are you sure?'),
        throwsA(isA<StateError>()),
      );
    });

    test('checklist throws without TTY', () async {
      if (stdin.hasTerminal) {
        return; // Skip when running interactively
      }
      expect(
        () => prompter.checklist(title: 'Pick', items: ['a', 'b']),
        throwsA(isA<StateError>()),
      );
    });
  });
}
