import '../style/theme.dart';
import '../system/focus_navigation.dart';
import '../system/key_bindings.dart';
import '../system/prompt_runner.dart';
import '../system/text_input_buffer.dart';
import '../system/widget_frame.dart';

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
///
/// **Mixins:** Implements [Themeable] for fluent theme configuration:
/// ```dart
/// final result = Form(title: 'Login', fields: fields)
///   .withMatrixTheme()
///   .run();
/// ```
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

class Form with Themeable {
  final String title;
  final List<FormFieldSpec> fields;
  @override
  final PromptTheme theme;

  Form({
    required this.title,
    required this.fields,
    this.theme = PromptTheme.dark,
  }) : assert(fields.isNotEmpty, 'Form requires at least one field');

  @override
  Form copyWithTheme(PromptTheme theme) {
    return Form(
      title: title,
      fields: fields,
      theme: theme,
    );
  }

  /// Runs the interactive form. Returns null if cancelled.
  FormResult? run() {
    // State - use centralized focus navigation for index + error tracking
    final focus = FocusNavigation(itemCount: fields.length);
    // Use centralized text input for each field
    final values = List<TextInputBuffer>.generate(
      fields.length,
      (i) => TextInputBuffer(initialText: fields[i].initialValue),
    );
    bool cancelled = false;
    bool submitted = false;

    // Validator function for FocusNavigation
    String? validateField(int index) {
      final spec = fields[index];
      final val = values[index].text;
      return spec.validator?.call(val);
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

    void handleTextInput(KeyEvent event) {
      if (values[focus.focusedIndex].handleKey(event)) {
        focus.validateOne(focus.focusedIndex, validateField);
      }
    }

    // Initial validation pass for placeholders/initial
    focus.validateAll(validateField, focusFirstInvalid: false);

    // Use KeyBindings for declarative key handling
    final bindings = KeyBindings([
          // Enter: submit
          KeyBinding.single(
            KeyEventType.enter,
            (event) {
              if (focus.validateAll(validateField, focusFirstInvalid: true)) {
                submitted = true;
                return KeyActionResult.confirmed;
              }
              return KeyActionResult.handled;
            },
            hintLabel: 'Enter',
            hintDescription: 'submit',
          ),
          // Tab / Down: next field
          KeyBinding.multi(
            {KeyEventType.tab, KeyEventType.arrowDown},
            (event) {
              focus.moveDown();
              return KeyActionResult.handled;
            },
            hintLabel: 'Tab',
            hintDescription: 'next field',
          ),
          // Up: previous field
          KeyBinding.single(
            KeyEventType.arrowUp,
            (event) {
              focus.moveUp();
              return KeyActionResult.handled;
            },
            hintLabel: '↑/↓',
            hintDescription: 'navigate',
          ),
          // Text input (typing)
          KeyBinding.char(
            (c) => true,
            (event) {
              handleTextInput(event);
              return KeyActionResult.handled;
            },
          ),
          // Backspace
          KeyBinding.single(
            KeyEventType.backspace,
            (event) {
              handleTextInput(event);
              return KeyActionResult.handled;
            },
            hintLabel: 'Backspace',
            hintDescription: 'delete',
          ),
        ]) +
        KeyBindings.cancel(onCancel: () => cancelled = true);

    // Use WidgetFrame for consistent frame rendering
    final frame = WidgetFrame(
      title: title,
      theme: theme,
      bindings: bindings,
      showConnector: true,
      hintStyle: HintStyle.grid,
    );

    final runner = PromptRunner(hideCursor: true);
    runner.runWithBindings(
      render: (out) {
        frame.render(out, (ctx) {
          // Render each field line
          for (var i = 0; i < fields.length; i++) {
            final spec = fields[i];
            final isFocused = focus.isFocused(i);
            // Use LineBuilder for arrow
            final arrow = ctx.lb.arrow(isFocused);

            final labelPart = '${theme.selection}${spec.label}${theme.reset}';
            final valuePart = renderValue(values[i], spec);
            var line = '$arrow $labelPart: $valuePart';

            // Use LineBuilder's writeLine for consistent highlight handling
            ctx.highlightedLine(line, highlighted: isFocused);

            // Error line if invalid - use FocusNavigation's error tracking
            final err = focus.getError(i);
            if (err != null && err.isNotEmpty) {
              ctx.gutterLine('${theme.highlight}$err${theme.reset}');
            }
          }
        });
      },
      bindings: bindings,
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
