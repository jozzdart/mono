import 'dart:convert';
import 'dart:io';

import 'package:mono_cli/mono_cli.dart';

class ConsolePrompter implements Prompter {
  const ConsolePrompter();

  bool get _isTty => stdin.hasTerminal;

  @override
  Future<bool> confirm(String message, {bool defaultValue = false}) async {
    if (!_isTty) {
      throw StateError('Interactive confirmation requires a TTY.');
    }
    stdout.write('$message [${defaultValue ? 'Y/n' : 'y/N'}] ');
    final input = stdin.readLineSync(encoding: utf8)?.trim().toLowerCase() ?? '';
    if (input.isEmpty) return defaultValue;
    return input == 'y' || input == 'yes';
  }

  @override
  Future<List<int>> checklist({
    required String title,
    required List<String> items,
  }) async {
    if (!_isTty) {
      throw StateError('Interactive checklist requires a TTY.');
    }
    if (items.isEmpty) return const <int>[];

    final selected = List<bool>.filled(items.length, false);
    var index = 0;

    void render({bool fresh = false}) {
      if (!fresh) {
        // Move cursor up to redraw over previous render (title + items + help)
        final lines = 2 + items.length; // title + help + items
        stdout.write('\x1B[${lines}A');
      }
      // Title
      stdout.writeln(title);
      // Items
      for (var i = 0; i < items.length; i++) {
        final cursor = i == index ? '>' : ' ';
        final mark = selected[i] ? 'x' : ' ';
        stdout.writeln('$cursor [$mark] ${items[i]}');
      }
      // Help
      stdout.writeln('(↑/↓) move  (space) toggle  (a) toggle all  (enter) done  (q) cancel');
    }

    // Prepare terminal
    final origEcho = stdin.echoMode;
    final origLine = stdin.lineMode;
    stdin.echoMode = false;
    stdin.lineMode = false;

    try {
      render(fresh: true);
      while (true) {
        final byte = stdin.readByteSync();
        if (byte == 13 || byte == 10) {
          // Enter (CR or LF)
          break;
        }
        if (byte == 113) {
          // 'q'
          throw SelectionError('Checklist cancelled by user');
        }
        if (byte == 97) {
          // 'a'
          final all = selected.every((e) => e);
          for (var i = 0; i < selected.length; i++) {
            selected[i] = !all;
          }
          render();
          continue;
        }
        if (byte == 32) {
          // Space
          selected[index] = !selected[index];
          render();
          continue;
        }
        if (byte == 27) {
          // Escape sequences for arrows: ESC [ A/B
          final b1 = stdin.readByteSync();
          if (b1 == 91) {
            final b2 = stdin.readByteSync();
            if (b2 == 65) {
              // Up
              index = (index - 1) < 0 ? items.length - 1 : index - 1;
              render();
            } else if (b2 == 66) {
              // Down
              index = (index + 1) % items.length;
              render();
            }
          }
          continue;
        }
      }
    } finally {
      stdin.echoMode = origEcho;
      stdin.lineMode = origLine;
      stdout.writeln();
    }

    final out = <int>[];
    for (var i = 0; i < selected.length; i++) {
      if (selected[i]) out.add(i);
    }
    return out;
  }
}


