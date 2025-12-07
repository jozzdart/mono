// ignore_for_file: unused_local_variable
/// Example demonstrating the PromptConfig system for reusable configuration.
///
/// PromptConfig is a composable configuration object that encapsulates
/// theme and animation settings. It enables:
///
/// 1. **Reusable Configurations** - Define once, use across multiple prompts
/// 2. **Fluent Builder Pattern** - Chain methods for clean API
/// 3. **Universal Compatibility** - Works with ALL Themeable widgets (60+)
///
/// Run with: dart run example/prompt_config.dart
library;

import 'package:terminice/terminice.dart';

void main() {
  print('PromptConfig Demo - Reusable Configuration System\n');
  print('=' * 60);

  // ─────────────────────────────────────────────────────────────────────────
  // APPROACH 1: Shared config across multiple widgets
  // ─────────────────────────────────────────────────────────────────────────

  print('\n📦 APPROACH 1: Shared Config Object\n');

  // Create a config that can be shared across ALL widgets
  final teamConfig = PromptConfig()
      .withMatrixTheme() // Green terminal aesthetic
      .withSmoothAnimations(); // Smooth entry/exit

  print('Create once, use everywhere:');
  print('  final teamConfig = PromptConfig()');
  print('    .withMatrixTheme()');
  print('    .withSmoothAnimations();\n');

  // Works with animated prompts
  final slider = SliderPrompt('Volume', config: teamConfig);
  final rating = RatingPrompt('Satisfaction', config: teamConfig);
  final range = RangePrompt('Price Range', config: teamConfig);

  print('Animated prompts:');
  print('  SliderPrompt("Volume", config: teamConfig)');
  print('  RatingPrompt("Satisfaction", config: teamConfig)');
  print('  RangePrompt("Price Range", config: teamConfig)\n');

  // Works with input prompts
  final text = TextPrompt(prompt: 'Name', config: teamConfig);
  final password = PasswordPrompt(label: 'Password', config: teamConfig);
  final search = SearchSelectPrompt(['A', 'B', 'C'], config: teamConfig);

  print('Input prompts:');
  print('  TextPrompt(prompt: "Name", config: teamConfig)');
  print('  PasswordPrompt(label: "Password", config: teamConfig)');
  print('  SearchSelectPrompt([...], config: teamConfig)\n');

  // Works with display widgets
  final banner = Banner('TEAM', config: teamConfig);
  final info = InfoBox('Welcome!', config: teamConfig);
  final checkbox = CheckboxMenu(label: 'Pick', options: ['X', 'Y'], config: teamConfig);

  print('Display widgets:');
  print('  Banner("TEAM", config: teamConfig)');
  print('  InfoBox("Welcome!", config: teamConfig)');
  print('  CheckboxMenu(label: "Pick", ..., config: teamConfig)');

  // ─────────────────────────────────────────────────────────────────────────
  // APPROACH 2: withConfig() works with ANY Themeable widget
  // ─────────────────────────────────────────────────────────────────────────

  print('\n📦 APPROACH 2: withConfig() Extension (Works with 60+ widgets!)\n');

  // Even widgets without explicit config parameter support work!
  final tableView = TableView(
    'Users',
    columns: ['Name', 'Age'],
    rows: [
      ['Alice', '30'],
      ['Bob', '25'],
    ],
  ).withConfig(teamConfig);

  final progressBar = ProgressBar('Loading').withConfig(teamConfig);
  final toast = Toast('Done!').withConfig(teamConfig);

  print('Extension method works with ALL Themeable widgets:');
  print('  TableView(...).withConfig(teamConfig)');
  print('  ProgressBar("Loading").withConfig(teamConfig)');
  print('  Toast("Done!").withConfig(teamConfig)');

  // ─────────────────────────────────────────────────────────────────────────
  // APPROACH 3: Factory presets for quick setup
  // ─────────────────────────────────────────────────────────────────────────

  print('\n📦 APPROACH 3: Factory Presets\n');

  print('Static presets:');
  print('  PromptConfig.defaults        -> Dark theme, no animations');
  print('  PromptConfig.matrix          -> Matrix theme');
  print('  PromptConfig.fire            -> Fire theme');
  print('  PromptConfig.pastel          -> Pastel theme');
  print('  PromptConfig.matrixAnimated()-> Matrix + smooth animations');
  print('  PromptConfig.darkAnimated()  -> Dark + smooth animations');

  // ─────────────────────────────────────────────────────────────────────────
  // APPROACH 4: Style presets (theme + animation combos)
  // ─────────────────────────────────────────────────────────────────────────

  print('\n📦 APPROACH 4: Style Presets\n');

  final cyberpunk = PromptConfig().withMatrixStyle();
  final dramatic = PromptConfig().withFireStyle();
  final gentle = PromptConfig().withPastelStyle();
  final minimal = PromptConfig().withMinimalStyle();

  print('Style presets combine theme + animation:');
  print('  .withMatrixStyle() -> Matrix theme + smooth animations');
  print('  .withFireStyle()   -> Fire theme + flashy animations');
  print('  .withPastelStyle() -> Pastel theme + quick animations');
  print('  .withMinimalStyle()-> Dark theme + no animations');

  // ─────────────────────────────────────────────────────────────────────────
  // APPROACH 5: Fluent chaining directly on widgets
  // ─────────────────────────────────────────────────────────────────────────

  print('\n📦 APPROACH 5: Fluent Widget Chaining\n');

  // Still works perfectly
  final fluentSlider = SliderPrompt('Volume')
      .withMatrixTheme()
      .withSmoothAnimations();

  final fluentBanner = Banner('TITLE')
      .withFireTheme();

  print('Chain directly on widgets:');
  print('  SliderPrompt("Volume")');
  print('    .withMatrixTheme()');
  print('    .withSmoothAnimations()\n');
  print('  Banner("TITLE")');
  print('    .withFireTheme()');

  // ─────────────────────────────────────────────────────────────────────────
  // SUMMARY: What PromptConfig enables
  // ─────────────────────────────────────────────────────────────────────────

  print('\n' + '=' * 60);
  print('SUMMARY: PromptConfig Benefits\n');
  print('✅ Reusable config objects - define once, use everywhere');
  print('✅ Works with ALL 60+ Themeable widgets via .withConfig()');
  print('✅ Direct config parameter support on popular prompts');
  print('✅ Factory presets for quick setup');
  print('✅ Style presets for common theme+animation combos');
  print('✅ Full backward compatibility with existing APIs');
  print('✅ Fluent builder pattern for clean code');

  print('\n✅ Demo complete!');
}
