import 'package:terminice/terminice.dart';

void main() {
  final sheet = CheatSheet([
    ['init', 'i', 'Initialize workspace'],
    ['build', 'b', 'Compile all projects'],
    ['test', 't', 'Run unit tests'],
    ['format', 'f', 'Format codebase'],
    ['scan', 's', 'Scan for changes'],
    ['deploy', 'd', 'Deploy selected targets'],
  ],
      title: 'Cheat Sheet · CLI',
      theme: PromptTheme.pastel);

  sheet.show();
}


