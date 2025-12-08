import 'dart:io';
import '../lib/src/src.dart';

void main() {
  // Example 1: Show toast while doing work
  print('Example 1: Toast during work\n');
  Toast('Processing...', variant: ToastVariant.info, theme: PromptTheme.pastel)
      .showWhile(() {
    sleep(const Duration(seconds: 1));
  });

  // Example 2: Manual show/clear
  print('\nExample 2: Manual toast control\n');
  final successToast = Toast(
    'Saved successfully',
    variant: ToastVariant.success,
    theme: PromptTheme.matrix,
  );
  successToast.show();
  sleep(const Duration(milliseconds: 800));
  successToast.clear();

  // Example 3: Simple toast
  print('\nExample 3: Simple inline toast\n');
  final simple = SimpleToast('Operation complete', variant: ToastVariant.success);
  simple.show();
  sleep(const Duration(milliseconds: 600));
  simple.clear();

  print('\nAll examples complete!');
}
