import 'package:terminice/terminice.dart';

void main() {
  CodePlayground(
    title: 'CodePlayground · mini REPL',
    theme: PromptTheme.pastel,
    inputVisibleLines: 8,
    outputVisibleLines: 10,
  ).run();
}
