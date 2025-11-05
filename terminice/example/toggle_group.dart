import '../lib/src/src.dart';
import 'dart:io';

void main() {
  final items = [
    const ToggleItem('Wi‑Fi', initialOn: true),
    const ToggleItem('Bluetooth'),
    const ToggleItem('Notifications', initialOn: true),
    const ToggleItem('Auto‑Update'),
    const ToggleItem('Dark Mode', initialOn: true),
  ];

  final group = ToggleGroup(
    'Preferences',
    items,
    theme: PromptTheme.pastel, // Try .dark, .matrix, .fire, .pastel
  );

  final result = group.run();
  stdout.writeln('Result:');
  for (final entry in result.entries) {
    stdout.writeln('  ${entry.key}: ${entry.value ? 'ON' : 'OFF'}');
  }
}


