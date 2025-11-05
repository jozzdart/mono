import 'dart:io';
import 'dart:math' as math;

import '../style/theme.dart';
import '../system/frame_renderer.dart';
import '../system/hints.dart';
import '../system/key_events.dart';
import '../system/terminal.dart';

/// Form – multi-field form builder for CLI with auto validation and Tab navigation.
///
/// Aligns with ThemeDemo styling: bordered title, themed accents, and
/// inverse-highlight for focused rows where applicable.
///
/// Controls:
/// - Tab / ↓ next field
/// - ↑ previous field
/// - Backspace delete
/// - Enter submit (validates all fields)
/// - Esc cancel (returns null)
class FormFieldSpec {
  final String name; // key in the result map
  final String label; // human friendly label rendered left of value
  final String? placeholder;
  final String initialValue;
  final bool obscure; // password-like
  final String? Function(String value)?
      validator; // return error message or null

  const FormFieldSpec({
    required this.name,
    required this.label,
    this.placeholder,
    this.initialValue = '',
    this.obscure = false,
    this.validator,
  });
}

class FormResult {
  final Map<String, String> values;
  const FormResult(this.values);
  String operator [](String key) => values[key] ?? '';
}

class Form {
  final String title;
  final List<FormFieldSpec> fields;
  final PromptTheme theme;

  Form({
    required this.title,
    required this.fields,
    this.theme = PromptTheme.dark,
  }) : assert(fields.isNotEmpty, 'Form requires at least one field');

  /// Runs the interactive form. Returns null if cancelled.
  FormResult? run() {
    final style = theme.style;

    // State
    int focusedIndex = 0;
    final values =
        List<String>.generate(fields.length, (i) => fields[i].initialValue);
    final errors = List<String?>.filled(fields.length, null);
    bool cancelled = false;

    void validateField(int index) {
      final spec = fields[index];
      final val = values[index];
      if (spec.validator != null) {
        errors[index] = spec.validator!(val);
      } else {
        errors[index] = null;
      }
    }

    bool validateAllAndFocusFirstInvalid() {
      int? firstInvalid;
      for (var i = 0; i < fields.length; i++) {
        validateField(i);
        if (errors[i] != null &&
            errors[i]!.isNotEmpty &&
            firstInvalid == null) {
          firstInvalid = i;
        }
      }
      if (firstInvalid != null) focusedIndex = firstInvalid;
      return firstInvalid == null;
    }

    String renderValue(String value, FormFieldSpec spec) {
      if (value.isEmpty && (spec.placeholder?.isNotEmpty ?? false)) {
        return '${theme.dim}${spec.placeholder}${theme.reset}';
      }
      if (spec.obscure) {
        return '${theme.accent}${'•' * value.length}${theme.reset}';
      }
      return '${theme.accent}$value${theme.reset}';
    }

    void render() {
      Terminal.clearAndHome();

      final baseTitle = style.showBorder
          ? FrameRenderer.titleWithBorders(title, theme)
          : FrameRenderer.plainTitle(title, theme);
      final header = style.boldPrompt
          ? '${theme.bold}$baseTitle${theme.reset}'
          : baseTitle;
      stdout.writeln(header);

      // Optional connector line for separation
      if (style.showBorder) {
        stdout.writeln(FrameRenderer.connectorLine(title, theme));
      }

      // Render each field line
      for (var i = 0; i < fields.length; i++) {
        final spec = fields[i];
        final isFocused = i == focusedIndex;
        final prefix = '${theme.gray}${style.borderVertical}${theme.reset} ';
        final arrow =
            isFocused ? '${theme.accent}${style.arrow}${theme.reset}' : ' ';

        final labelPart = '${theme.selection}${spec.label}${theme.reset}';
        final valuePart = renderValue(values[i], spec);
        var line = '$arrow $labelPart: $valuePart';

        if (isFocused && style.useInverseHighlight) {
          stdout.writeln('$prefix${theme.inverse}$line${theme.reset}');
        } else {
          stdout.writeln('$prefix$line');
        }

        // Error line if invalid
        final err = errors[i];
        if (err != null && err.isNotEmpty) {
          stdout.writeln('$prefix${theme.highlight}$err${theme.reset}');
        }
      }

      // Bottom border
      if (style.showBorder) {
        stdout.writeln(FrameRenderer.bottomLine(title, theme));
      }

      // Hints footer
      stdout.writeln(Hints.grid([
        [Hints.key('Tab', theme), 'next field'],
        [Hints.key('↑/↓', theme), 'navigate'],
        [Hints.key('Backspace', theme), 'delete'],
        [Hints.key('Enter', theme), 'submit'],
        [Hints.key('Esc', theme), 'cancel'],
      ], theme));

      Terminal.hideCursor();
    }

    void moveFocus(int delta) {
      final len = fields.length;
      focusedIndex = (focusedIndex + delta + len) % len;
    }

    void backspace() {
      final current = values[focusedIndex];
      if (current.isEmpty) return;
      values[focusedIndex] =
          current.substring(0, math.max(0, current.length - 1));
      validateField(focusedIndex);
    }

    void appendChar(String ch) {
      values[focusedIndex] = values[focusedIndex] + ch;
      validateField(focusedIndex);
    }

    // Setup terminal
    final term = Terminal.enterRaw();
    void cleanup() {
      term.restore();
      Terminal.showCursor();
    }

    // Initial validation pass for placeholders/initial
    for (var i = 0; i < fields.length; i++) {
      validateField(i);
    }

    render();

    try {
      while (true) {
        final ev = KeyEventReader.read();

        if (ev.type == KeyEventType.esc || ev.type == KeyEventType.ctrlC) {
          cancelled = true;
          break;
        }

        if (ev.type == KeyEventType.enter) {
          if (validateAllAndFocusFirstInvalid()) {
            break;
          }
        } else if (ev.type == KeyEventType.tab ||
            ev.type == KeyEventType.arrowDown) {
          moveFocus(1);
        } else if (ev.type == KeyEventType.arrowUp) {
          moveFocus(-1);
        } else if (ev.type == KeyEventType.backspace) {
          backspace();
        } else if (ev.type == KeyEventType.char && ev.char != null) {
          appendChar(ev.char!);
        }

        render();
      }
    } finally {
      cleanup();
    }

    Terminal.clearAndHome();
    if (cancelled) return null;
    final result = <String, String>{};
    for (var i = 0; i < fields.length; i++) {
      result[fields[i].name] = values[i];
    }
    return FormResult(result);
  }
}

/// Convenience function mirroring the requested API name.
FormResult? form(String title, List<FormFieldSpec> fields,
        {PromptTheme theme = PromptTheme.dark}) =>
    Form(title: title, fields: fields, theme: theme).run();
