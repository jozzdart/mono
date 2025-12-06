// ignore_for_file: avoid_print
import 'package:terminice/terminice.dart';

/// Demonstrates the SimplePrompt system for creating reusable prompt patterns.
///
/// SimplePrompt<T> provides a composable way to build prompts that:
/// - Handle cancellation automatically
/// - Return initial value on cancel
/// - Reduce boilerplate compared to manual PromptRunner usage
void main() async {
  print('=== SimplePrompt Examples ===\n');

  // Example 1: Using SimplePrompts.confirm (preset factory)
  print('1. Confirm Prompt (using factory):');
  final confirmed = SimplePrompts.confirm(
    title: 'Delete File',
    message: 'Are you sure you want to delete this file?',
    yesLabel: 'Delete',
    noLabel: 'Cancel',
    defaultYes: false,
  ).run();

  print('   Result: ${confirmed ? "Confirmed" : "Cancelled"}');
  print('');

  // Example 2: Using SimplePrompts.choice for inline options
  print('2. Choice Prompt (inline options):');
  final mode = SimplePrompts.choice(
    title: 'Build Mode',
    options: ['Debug', 'Release', 'Profile'],
    initialIndex: 1,
  ).run();

  print('   Selected: $mode');
  print('');

  // Example 3: Using SimplePrompts.number for numeric input
  print('3. Number Prompt:');
  final count = SimplePrompts.number(
    title: 'Set Count',
    initial: 10,
    min: 1,
    max: 100,
    step: 5,
  ).run();

  print('   Count: $count');
  print('');

  // Example 4: Custom SimplePrompt with custom state
  print('4. Custom SimplePrompt (priority selector):');
  final priority = SimplePrompt<String>(
    title: 'Priority',
    initialValue: 'Medium',
    theme: PromptTheme.dark,
    buildBindings: (state) {
      final priorities = ['Low', 'Medium', 'High', 'Critical'];
      var index = priorities.indexOf(state.value);

      return KeyBindings.horizontalNavigation(
            onLeft: () {
              index = (index - 1).clamp(0, priorities.length - 1);
              state.value = priorities[index];
            },
            onRight: () {
              index = (index + 1).clamp(0, priorities.length - 1);
              state.value = priorities[index];
            },
          ) +
          KeyBindings.prompt(onCancel: state.cancel);
    },
    render: (ctx, state) {
      final priorities = ['Low', 'Medium', 'High', 'Critical'];
      final colors = {
        'Low': ctx.theme.dim,
        'Medium': ctx.theme.info,
        'High': ctx.theme.warn,
        'Critical': ctx.theme.error,
      };

      ctx.gutterEmpty();

      final buffer = StringBuffer();
      for (final p in priorities) {
        final isSelected = p == state.value;
        final color = colors[p] ?? ctx.theme.gray;
        if (isSelected) {
          buffer.write('${ctx.theme.inverse}$color $p ${ctx.theme.reset}');
        } else {
          buffer.write('${ctx.theme.dim}$p${ctx.theme.reset}');
        }
        buffer.write('  ');
      }

      ctx.gutterLine(buffer.toString());
      ctx.gutterEmpty();
    },
  ).run();

  print('   Priority: $priority');
  print('');

  // Example 5: Using existing ConfirmPrompt (which now uses SimplePrompt internally)
  print('5. ConfirmPrompt Widget (backward compatible):');
  final shouldProceed = ConfirmPrompt(
    label: 'Continue',
    message: 'Do you want to continue with the operation?',
  ).run();

  print('   Proceed: $shouldProceed');
  print('');

  // Example 6: Async text prompt with validation
  print('6. Async Text Prompt (with validation):');
  final name = await AsyncSimplePrompts.text(
    title: 'Enter Name',
    placeholder: 'Your name...',
    required: true,
  ).run();

  print('   Name: ${name ?? "(cancelled)"}');
  print('');

  // Example 7: Password prompt with reveal toggle
  print('7. Password Prompt (Ctrl+R to reveal):');
  final password = await AsyncSimplePrompts.password(
    title: 'Enter Password',
    required: true,
  ).run();

  print('   Password: ${password != null ? "***${password.length} chars***" : "(cancelled)"}');
  print('');

  // Example 8: Validated input (email example)
  print('8. Validated Input (email):');
  final email = await AsyncSimplePrompts.validated(
    title: 'Enter Email',
    placeholder: 'user@example.com',
    validator: (text) {
      if (!text.contains('@')) return 'Must contain @';
      if (!text.contains('.')) return 'Must contain domain';
      return '';
    },
  ).run();

  print('   Email: ${email ?? "(cancelled)"}');
  print('');

  // Example 9: Using TextPrompt widget (backward compatible)
  print('9. TextPrompt Widget (backward compatible):');
  final input = await TextPrompt(
    prompt: 'Enter anything',
    placeholder: 'Type here...',
    required: false,
  ).run();

  print('   Input: ${input ?? "(cancelled)"}');
  print('');

  // Example 10: Using PasswordPrompt widget (backward compatible)
  print('10. PasswordPrompt Widget (backward compatible):');
  final secret = await PasswordPrompt(
    label: 'Secret Key',
    allowEmpty: true,
  ).run();

  print('   Secret: ${secret.isEmpty ? "(empty)" : "***"}');
  print('');

  print('=== Done ===');
}

