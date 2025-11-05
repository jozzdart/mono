import '../lib/src/src.dart';

void main() {
  // Basic info toast
  Toast('Hello from Terminice Toast', theme: PromptTheme.pastel).run();

  // Success variant
  Toast(
    'Saved successfully',
    variant: ToastVariant.success,
    theme: PromptTheme.matrix,
  ).run();

  // Warning with longer hold and slower fade
  Toast(
    'Low disk space',
    label: 'Warning',
    variant: ToastVariant.warning,
    duration: const Duration(milliseconds: 1600),
    fadeOut: const Duration(milliseconds: 900),
    theme: PromptTheme.fire,
  ).run();

  // Error, short and sharp
  Toast(
    'Operation failed',
    label: 'Error',
    variant: ToastVariant.error,
    duration: const Duration(milliseconds: 900),
  ).run();
}


