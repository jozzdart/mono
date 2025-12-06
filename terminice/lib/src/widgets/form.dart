import '../style/theme.dart';
import '../system/framed_layout.dart';
import '../system/hints.dart';
import '../system/key_events.dart';
import '../system/prompt_runner.dart';
import '../system/text_input_buffer.dart';

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
    // Use centralized text input for each field
    final values = List<TextInputBuffer>.generate(
      fields.length,
      (i) => TextInputBuffer(initialText: fields[i].initialValue),
    );
    final errors = List<String?>.filled(fields.length, null);
    bool cancelled = false;
    bool submitted = false;

    void validateField(int index) {
      final spec = fields[index];
      final val = values[index].text;
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

    String renderValue(TextInputBuffer buffer, FormFieldSpec spec) {
      final value = buffer.text;
      if (value.isEmpty && (spec.placeholder?.isNotEmpty ?? false)) {
        return '${theme.dim}${spec.placeholder}${theme.reset}';
      }
      if (spec.obscure) {
        return '${theme.accent}${'•' * value.length}${theme.reset}';
      }
      return '${theme.accent}$value${theme.reset}';
    }

    void render(RenderOutput out) {
      final frame = FramedLayout(title, theme: theme);
      final baseTitle = frame.top();
      final header = style.boldPrompt
          ? '${theme.bold}$baseTitle${theme.reset}'
          : baseTitle;
      out.writeln(header);

      // Optional connector line for separation
      if (style.showBorder) {
        out.writeln(frame.connector());
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
          out.writeln('$prefix${theme.inverse}$line${theme.reset}');
        } else {
          out.writeln('$prefix$line');
        }

        // Error line if invalid
        final err = errors[i];
        if (err != null && err.isNotEmpty) {
          out.writeln('$prefix${theme.highlight}$err${theme.reset}');
        }
      }

      // Bottom border
      if (style.showBorder) {
        out.writeln(frame.bottom());
      }

      // Hints footer
      out.writeln(Hints.grid([
        [Hints.key('Tab', theme), 'next field'],
        [Hints.key('↑/↓', theme), 'navigate'],
        [Hints.key('Backspace', theme), 'delete'],
        [Hints.key('Enter', theme), 'submit'],
        [Hints.key('Esc', theme), 'cancel'],
      ], theme));
    }

    void moveFocus(int delta) {
      final len = fields.length;
      focusedIndex = (focusedIndex + delta + len) % len;
    }

    void handleTextInput(KeyEvent ev) {
      if (values[focusedIndex].handleKey(ev)) {
        validateField(focusedIndex);
      }
    }

    // Initial validation pass for placeholders/initial
    for (var i = 0; i < fields.length; i++) {
      validateField(i);
    }

    final runner = PromptRunner(hideCursor: true);
    runner.run(
      render: render,
      onKey: (ev) {
        if (ev.type == KeyEventType.esc || ev.type == KeyEventType.ctrlC) {
          cancelled = true;
          return PromptResult.cancelled;
        }

        if (ev.type == KeyEventType.enter) {
          if (validateAllAndFocusFirstInvalid()) {
            submitted = true;
            return PromptResult.confirmed;
          }
        } else if (ev.type == KeyEventType.tab ||
            ev.type == KeyEventType.arrowDown) {
          moveFocus(1);
        } else if (ev.type == KeyEventType.arrowUp) {
          moveFocus(-1);
        } else {
          // Text input (typing, backspace) - handled by centralized TextInputBuffer
          handleTextInput(ev);
        }

        return null;
      },
    );

    if (cancelled || !submitted) return null;
    final result = <String, String>{};
    for (var i = 0; i < fields.length; i++) {
      result[fields[i].name] = values[i].text;
    }
    return FormResult(result);
  }
}

/// Convenience function mirroring the requested API name.
FormResult? form(String title, List<FormFieldSpec> fields,
        {PromptTheme theme = PromptTheme.dark}) =>
    Form(title: title, fields: fields, theme: theme).run();
