import 'dart:io';

import 'style/prompt_config.dart';
import 'style/theme.dart';
import 'widgets/badge.dart';
import 'widgets/banner.dart';
import 'widgets/bar_chart.dart';
import 'widgets/breadcrumbs.dart';
import 'widgets/checkbox_menu.dart';
import 'widgets/choice_map.dart';
import 'widgets/color_picker.dart';
import 'widgets/command_palette.dart';
import 'widgets/confirm_prompt.dart';
import 'widgets/date_field.dart';
import 'widgets/date_picker.dart';
import 'widgets/file_pickers.dart';
import 'widgets/flashcards.dart';
import 'widgets/form.dart';
import 'widgets/grid_select.dart';
import 'widgets/highlight.dart';
import 'widgets/hotkey_guide.dart';
import 'widgets/info_box.dart';
import 'widgets/line_chart_widget.dart';
import 'widgets/loading_spinner.dart';
import 'widgets/markdown_viewer.dart';
import 'widgets/multi_line_input.dart';
import 'widgets/password.dart';
import 'widgets/path_navigator.dart';
import 'widgets/progress_bar.dart';
import 'widgets/progress_dots.dart';
import 'widgets/quiz_widget.dart';
import 'widgets/range_prompt.dart';
import 'widgets/rating_prompt.dart';
import 'widgets/search_select.dart';
import 'widgets/slider_prompt.dart';
import 'widgets/snippet_editor.dart';
import 'widgets/status_line.dart';
import 'widgets/stepper.dart';
import 'widgets/survey_form.dart';
import 'widgets/table_editor.dart';
import 'widgets/table_view.dart';
import 'widgets/tag_selector.dart';
import 'widgets/text_prompt.dart';
import 'widgets/toast.dart';
import 'widgets/toggle_group.dart';
import 'widgets/tree_explorer.dart';
import 'widgets/wizard.dart';

/// Global terminice instance for easy widget access.
///
/// Example usage:
/// ```dart
/// // Basic usage
/// final password = await terminice.password(label: 'Enter password');
/// final confirmed = terminice.confirm(label: 'Delete', message: 'Are you sure?');
///
/// // With theme
/// final pwd = await terminice.arcane.password(label: 'Secret');
/// final name = await terminice.matrix.text(prompt: 'Your name');
///
/// // With custom theme
/// final result = terminice.themed(PromptTheme.fire).slider('Volume');
/// ```
final Terminice terminice = Terminice();

/// Centralized API for all terminice widgets.
///
/// Provides convenient factory methods for all interactive prompts,
/// display widgets, and utilities.
///
/// **Usage:**
/// ```dart
/// import 'package:terminice/terminice.dart';
///
/// void main() async {
///   // Basic usage
///   final pwd = await terminice.password(label: 'Password');
///
///   // With theme accessor
///   final name = await terminice.arcane.text(prompt: 'Your name');
///   final confirmed = terminice.matrix.confirm(label: 'Save', message: 'Continue?');
///
///   // With themed() method
///   final volume = terminice.themed(PromptTheme.fire).slider('Volume');
///
///   // With config
///   final config = PromptConfig.matrix;
///   final result = terminice.withConfig(config).rating('Rate this');
/// }
/// ```
class Terminice {
  /// Default theme for all widgets when not specified.
  final PromptTheme defaultTheme;

  /// Default config for all widgets when not specified.
  final PromptConfig? defaultConfig;

  /// Creates a Terminice instance with optional default theme and config.
  const Terminice({
    this.defaultTheme = PromptTheme.dark,
    this.defaultConfig,
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // THEME ACCESSORS - Static getters for themed instances
  // ═══════════════════════════════════════════════════════════════════════════

  /// Dark theme instance (default).
  ///
  /// **Example:**
  /// ```dart
  /// final pwd = await terminice.dark.password(label: 'Password');
  /// ```
  Terminice get dark => themed(PromptTheme.dark);

  /// Matrix theme instance (green, terminal-style).
  ///
  /// **Example:**
  /// ```dart
  /// final pwd = await terminice.matrix.password(label: 'Password');
  /// ```
  Terminice get matrix => themed(PromptTheme.matrix);

  /// Fire theme instance (red/orange, bold).
  ///
  /// **Example:**
  /// ```dart
  /// final pwd = await terminice.fire.password(label: 'Password');
  /// ```
  Terminice get fire => themed(PromptTheme.fire);

  /// Pastel theme instance (soft, gentle colors).
  ///
  /// **Example:**
  /// ```dart
  /// final pwd = await terminice.pastel.password(label: 'Password');
  /// ```
  Terminice get pastel => themed(PromptTheme.pastel);

  /// Ocean theme instance (calming blue/cyan).
  ///
  /// **Example:**
  /// ```dart
  /// final pwd = await terminice.ocean.password(label: 'Password');
  /// ```
  Terminice get ocean => themed(PromptTheme.ocean);

  /// Monochrome theme instance (high-contrast ASCII).
  ///
  /// **Example:**
  /// ```dart
  /// final pwd = await terminice.monochrome.password(label: 'Password');
  /// ```
  Terminice get monochrome => themed(PromptTheme.monochrome);

  /// Neon theme instance (vibrant synthwave).
  ///
  /// **Example:**
  /// ```dart
  /// final pwd = await terminice.neon.password(label: 'Password');
  /// ```
  Terminice get neon => themed(PromptTheme.neon);

  /// Arcane theme instance (mystical ancient tome).
  ///
  /// **Example:**
  /// ```dart
  /// final pwd = await terminice.arcane.password(label: 'Password');
  /// ```
  Terminice get arcane => themed(PromptTheme.arcane);

  /// Phantom theme instance (ghostly apparition).
  ///
  /// **Example:**
  /// ```dart
  /// final pwd = await terminice.phantom.password(label: 'Password');
  /// ```
  Terminice get phantom => themed(PromptTheme.phantom);

  // ═══════════════════════════════════════════════════════════════════════════
  // FACTORY METHODS - Create themed instances
  // ═══════════════════════════════════════════════════════════════════════════

  /// Creates a new Terminice instance with the specified theme.
  ///
  /// **Example:**
  /// ```dart
  /// final fire = terminice.themed(PromptTheme.fire);
  /// final pwd = await fire.password(label: 'Password');
  /// ```
  Terminice themed(PromptTheme theme) {
    return Terminice(
      defaultTheme: theme,
      defaultConfig: defaultConfig,
    );
  }

  /// Creates a new Terminice instance with the specified config.
  ///
  /// **Example:**
  /// ```dart
  /// final config = PromptConfig.matrix;
  /// final api = terminice.withConfig(config);
  /// final pwd = await api.password(label: 'Password');
  /// ```
  Terminice withConfig(PromptConfig config) {
    return Terminice(
      defaultTheme: config.theme,
      defaultConfig: config,
    );
  }

  /// Creates a new Terminice instance with both theme and config.
  ///
  /// **Example:**
  /// ```dart
  /// final api = terminice.configure(
  ///   theme: PromptTheme.arcane,
  ///   config: PromptConfig.animated,
  /// );
  /// ```
  Terminice configure({
    PromptTheme? theme,
    PromptConfig? config,
  }) {
    return Terminice(
      defaultTheme: theme ?? config?.theme ?? defaultTheme,
      defaultConfig: config ?? defaultConfig,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TEXT INPUT PROMPTS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Password input prompt with masked characters.
  ///
  /// Returns the entered password, or empty string if cancelled.
  ///
  /// **Example:**
  /// ```dart
  /// final pwd = await terminice.password(label: 'Password');
  /// final secret = await terminice.arcane.password(label: 'Secret');
  /// ```
  Future<String> password({
    required String label,
    bool allowEmpty = false,
    String maskChar = '•',
    PromptConfig? config,
    PromptTheme? theme,
  }) {
    return PasswordPrompt(
      label: label,
      allowEmpty: allowEmpty,
      maskChar: maskChar,
      config: config ?? defaultConfig,
      theme: theme ?? defaultTheme,
    ).run();
  }

  /// Text input prompt with optional validation and placeholder.
  ///
  /// Returns the entered text, or null if cancelled.
  ///
  /// **Example:**
  /// ```dart
  /// final name = await terminice.text(prompt: 'Your name');
  /// ```
  Future<String?> text({
    required String prompt,
    String? placeholder,
    String Function(String)? validator,
    bool required = true,
    PromptConfig? config,
    PromptTheme? theme,
  }) {
    return TextPrompt(
      prompt: prompt,
      placeholder: placeholder,
      validator: validator,
      required: required,
      config: config ?? defaultConfig,
      theme: theme ?? defaultTheme,
    ).run();
  }

  /// Multi-line text input with cursor navigation.
  ///
  /// Returns the entered text, or empty string if cancelled.
  ///
  /// **Example:**
  /// ```dart
  /// final notes = terminice.multiLine(label: 'Notes');
  /// ```
  String multiLine({
    required String label,
    int maxLines = 200,
    int visibleLines = 10,
    bool allowEmpty = true,
    PromptTheme? theme,
  }) {
    return MultiLineInputPrompt(
      label: label,
      maxLines: maxLines,
      visibleLines: visibleLines,
      allowEmpty: allowEmpty,
      theme: theme ?? defaultTheme,
    ).run();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CONFIRMATION & CHOICE PROMPTS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Confirmation prompt with Yes/No options.
  ///
  /// Returns true if confirmed, false otherwise.
  ///
  /// **Example:**
  /// ```dart
  /// if (terminice.confirm(label: 'Delete', message: 'Are you sure?')) {
  ///   // User confirmed
  /// }
  /// ```
  bool confirm({
    required String label,
    required String message,
    String yesLabel = 'Yes',
    String noLabel = 'No',
    bool defaultYes = true,
    PromptConfig? config,
    PromptTheme? theme,
  }) {
    return ConfirmPrompt(
      label: label,
      message: message,
      yesLabel: yesLabel,
      noLabel: noLabel,
      defaultYes: defaultYes,
      config: config ?? defaultConfig,
      theme: theme ?? defaultTheme,
    ).run();
  }

  /// Searchable select prompt for choosing from a list.
  ///
  /// Returns the selected items (single item in list for single-select mode).
  ///
  /// **Example:**
  /// ```dart
  /// final fruits = terminice.select(
  ///   ['Apple', 'Banana', 'Cherry'],
  ///   prompt: 'Pick a fruit',
  /// );
  /// ```
  List<String> select(
    List<String> options, {
    String prompt = 'Select an option',
    bool multiSelect = false,
    bool showSearch = false,
    int maxVisible = 10,
    PromptConfig? config,
    PromptTheme? theme,
  }) {
    return SearchSelectPrompt(
      options,
      prompt: prompt,
      multiSelect: multiSelect,
      showSearch: showSearch,
      maxVisible: maxVisible,
      config: config ?? defaultConfig,
      theme: theme ?? defaultTheme,
    ).run();
  }

  /// Checkbox menu for multi-select from a list.
  ///
  /// Returns the selected items.
  ///
  /// **Example:**
  /// ```dart
  /// final toppings = terminice.checkbox(
  ///   label: 'Toppings',
  ///   options: ['Cheese', 'Pepperoni', 'Mushrooms'],
  /// );
  /// ```
  List<String> checkbox({
    required String label,
    required List<String> options,
    int maxVisible = 12,
    Set<int>? initialSelected,
    PromptConfig? config,
    PromptTheme? theme,
  }) {
    return CheckboxMenu(
      label: label,
      options: options,
      maxVisible: maxVisible,
      initialSelected: initialSelected,
      config: config ?? defaultConfig,
      theme: theme ?? defaultTheme,
    ).run();
  }

  /// Grid-based selection prompt.
  ///
  /// Returns the selected items.
  ///
  /// **Example:**
  /// ```dart
  /// final emojis = terminice.grid(
  ///   ['😀', '😎', '🎉', '🚀', '💡', '🔥'],
  ///   prompt: 'Pick an emoji',
  /// );
  /// ```
  List<String> grid(
    List<String> options, {
    String prompt = 'Select',
    int columns = 0,
    bool multiSelect = false,
    int? cellWidth,
    int? maxColumns,
    PromptConfig? config,
    PromptTheme? theme,
  }) {
    return GridSelectPrompt(
      options,
      prompt: prompt,
      columns: columns,
      multiSelect: multiSelect,
      cellWidth: cellWidth,
      maxColumns: maxColumns,
      config: config ?? defaultConfig,
      theme: theme ?? defaultTheme,
    ).run();
  }

  /// Choice map for visual dashboard-like grid selection.
  ///
  /// Returns the selected labels.
  ///
  /// **Example:**
  /// ```dart
  /// final choices = terminice.choiceMap(
  ///   [
  ///     ChoiceMapItem('Small', subtitle: 'For individuals'),
  ///     ChoiceMapItem('Medium', subtitle: 'For teams'),
  ///     ChoiceMapItem('Large', subtitle: 'For enterprises'),
  ///   ],
  ///   prompt: 'Select Size',
  /// );
  /// ```
  List<String> choiceMap(
    List<ChoiceMapItem> items, {
    String prompt = 'Select',
    bool multiSelect = false,
    int columns = 0,
    int? cardWidth,
    int? maxColumns,
    PromptTheme? theme,
  }) {
    return ChoiceMap(
      items,
      prompt: prompt,
      multiSelect: multiSelect,
      columns: columns,
      cardWidth: cardWidth,
      maxColumns: maxColumns,
      theme: theme ?? defaultTheme,
    ).run();
  }

  /// Tag selector for chip-style multi-select.
  ///
  /// Returns the selected tags.
  ///
  /// **Example:**
  /// ```dart
  /// final tags = terminice.tags(
  ///   ['Flutter', 'Dart', 'CLI', 'Terminal'],
  ///   prompt: 'Select skills',
  /// );
  /// ```
  List<String> tags(
    List<String> tags, {
    String prompt = 'Select tags',
    PromptConfig? config,
    PromptTheme? theme,
  }) {
    return TagSelector(
      tags,
      prompt: prompt,
      config: config ?? defaultConfig,
      theme: theme ?? defaultTheme,
    ).run();
  }

  /// Toggle group for multiple on/off switches.
  ///
  /// Returns a map of label -> on/off state.
  ///
  /// **Example:**
  /// ```dart
  /// final settings = terminice.toggles(
  ///   'Settings',
  ///   [
  ///     ToggleItem('Dark Mode', initialOn: true),
  ///     ToggleItem('Notifications'),
  ///     ToggleItem('Auto-save'),
  ///   ],
  /// );
  /// ```
  Map<String, bool> toggles(
    String title,
    List<ToggleItem> items, {
    PromptConfig? config,
    PromptTheme? theme,
  }) {
    return ToggleGroup(
      title,
      items,
      config: config ?? defaultConfig,
      theme: theme ?? defaultTheme,
    ).run();
  }

  /// Command palette for fuzzy-finding commands.
  ///
  /// Returns the selected command, or null if cancelled.
  ///
  /// **Example:**
  /// ```dart
  /// final cmd = terminice.commandPalette(
  ///   commands: [
  ///     CommandEntry(id: 'save', title: 'Save File', subtitle: 'Ctrl+S'),
  ///     CommandEntry(id: 'open', title: 'Open File', subtitle: 'Ctrl+O'),
  ///   ],
  /// );
  /// ```
  CommandEntry? commandPalette({
    required List<CommandEntry> commands,
    String label = 'Command Palette',
    int maxVisible = 12,
    PromptConfig? config,
    PromptTheme? theme,
  }) {
    return CommandPalette(
      commands: commands,
      label: label,
      maxVisible: maxVisible,
      config: config ?? defaultConfig,
      theme: theme ?? defaultTheme,
    ).run();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // NUMERIC PROMPTS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Slider prompt for selecting a numeric value.
  ///
  /// Returns the selected value.
  ///
  /// **Example:**
  /// ```dart
  /// final volume = terminice.slider('Volume', initial: 50);
  /// ```
  num slider(
    String label, {
    num min = 0,
    num max = 100,
    num initial = 50,
    num step = 1,
    int width = 28,
    String unit = '%',
    PromptConfig? config,
    PromptTheme? theme,
    bool animated = true,
  }) {
    return SliderPrompt(
      label,
      min: min,
      max: max,
      initial: initial,
      step: step,
      width: width,
      unit: unit,
      config: config ?? defaultConfig,
      theme: theme ?? defaultTheme,
      animated: animated,
    ).run();
  }

  /// Rating prompt (1-5 stars or custom max).
  ///
  /// Returns the selected rating.
  ///
  /// **Example:**
  /// ```dart
  /// final rating = terminice.rating('Rate this product');
  /// ```
  int rating(
    String prompt, {
    int maxStars = 5,
    int initial = 3,
    List<String>? labels,
    PromptConfig? config,
    PromptTheme? theme,
    bool animated = false,
  }) {
    return RatingPrompt(
      prompt,
      maxStars: maxStars,
      initial: initial,
      labels: labels,
      config: config ?? defaultConfig,
      theme: theme ?? defaultTheme,
      animated: animated,
    ).run();
  }

  /// Range prompt for selecting a start/end range.
  ///
  /// Returns `(start, end)` tuple.
  ///
  /// **Example:**
  /// ```dart
  /// final (start, end) = terminice.range('Price Range');
  /// ```
  (num, num) range(
    String label, {
    num min = 0,
    num max = 100,
    num startInitial = 20,
    num endInitial = 80,
    num step = 1,
    int width = 28,
    String unit = '%',
    PromptConfig? config,
    PromptTheme? theme,
    bool animated = false,
  }) {
    return RangePrompt(
      label,
      min: min,
      max: max,
      startInitial: startInitial,
      endInitial: endInitial,
      step: step,
      width: width,
      unit: unit,
      config: config ?? defaultConfig,
      theme: theme ?? defaultTheme,
      animated: animated,
    ).run();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FORM & WIZARD
  // ═══════════════════════════════════════════════════════════════════════════

  /// Multi-field form with validation.
  ///
  /// Returns the form result, or null if cancelled.
  ///
  /// **Example:**
  /// ```dart
  /// final result = terminice.form(
  ///   title: 'Login',
  ///   fields: [
  ///     FormFieldSpec(name: 'email', label: 'Email'),
  ///     FormFieldSpec(name: 'password', label: 'Password', obscure: true),
  ///   ],
  /// );
  /// if (result != null) {
  ///   print('Email: ${result['email']}');
  /// }
  /// ```
  FormResult? form({
    required String title,
    required List<FormFieldSpec> fields,
    PromptConfig? config,
    PromptTheme? theme,
  }) {
    return Form(
      title: title,
      fields: fields,
      config: config ?? defaultConfig,
      theme: theme ?? defaultTheme,
    ).run();
  }

  /// Multi-step wizard with state passing.
  ///
  /// Returns the final state map, or null if cancelled.
  ///
  /// **Example:**
  /// ```dart
  /// final result = await terminice.wizard(
  ///   title: 'Setup',
  ///   steps: [
  ///     WizardStep(
  ///       id: 'name',
  ///       label: 'Your Name',
  ///       run: (state, theme) async {
  ///         return await terminice.text(prompt: 'Name');
  ///       },
  ///     ),
  ///   ],
  /// );
  /// ```
  Future<Map<String, dynamic>?> wizard({
    required String title,
    required List<WizardStep> steps,
    bool showProgress = true,
    PromptConfig? config,
    PromptTheme? theme,
  }) {
    return Wizard(
      title: title,
      steps: steps,
      showProgress: showProgress,
      config: config ?? defaultConfig,
      theme: theme ?? defaultTheme,
    ).run();
  }

  /// Step-by-step stepper navigation.
  ///
  /// Returns the last confirmed step index (0-based), or -1 if cancelled.
  ///
  /// **Example:**
  /// ```dart
  /// final step = terminice.stepper(
  ///   title: 'Setup Wizard',
  ///   steps: ['Account', 'Profile', 'Preferences', 'Finish'],
  /// );
  /// ```
  int stepper({
    required String title,
    required List<String> steps,
    int startIndex = 0,
    bool showStepNumbers = true,
    PromptConfig? config,
    PromptTheme? theme,
  }) {
    return StepperPrompt(
      title: title,
      steps: steps,
      startIndex: startIndex,
      showStepNumbers: showStepNumbers,
      config: config ?? defaultConfig,
      theme: theme ?? defaultTheme,
    ).run();
  }

  /// Interactive survey/questionnaire form.
  ///
  /// Returns survey results, or null if cancelled.
  ///
  /// **Example:**
  /// ```dart
  /// final result = terminice.survey(
  ///   title: 'Feedback',
  ///   questions: [
  ///     SurveyQuestionSpec.text(name: 'name', prompt: 'Your name'),
  ///     SurveyQuestionSpec.rating(name: 'score', prompt: 'Rate us'),
  ///     SurveyQuestionSpec.yesNo(name: 'recommend', prompt: 'Would you recommend?'),
  ///   ],
  /// );
  /// ```
  SurveyResult? survey({
    required String title,
    required List<SurveyQuestionSpec> questions,
    PromptTheme? theme,
  }) {
    return SurveyForm(
      title: title,
      questions: questions,
      theme: theme ?? defaultTheme,
    ).run();
  }

  /// Date picker with calendar view.
  ///
  /// Returns selected date, or null if cancelled.
  ///
  /// **Example:**
  /// ```dart
  /// final date = terminice.datePicker(label: 'Select date');
  /// ```
  DateTime? datePicker({
    required String label,
    DateTime? initial,
    bool allowPast = true,
    bool allowFuture = true,
    bool startWeekOnMonday = true,
    PromptTheme? theme,
  }) {
    return DatePickerPrompt(
      label: label,
      initial: initial,
      allowPast: allowPast,
      allowFuture: allowFuture,
      startWeekOnMonday: startWeekOnMonday,
      theme: theme ?? defaultTheme,
    ).run();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FILE & NAVIGATION PROMPTS
  // ═══════════════════════════════════════════════════════════════════════════

  /// File picker for selecting files or folders.
  ///
  /// Returns the selected path, or empty string if cancelled.
  ///
  /// **Example:**
  /// ```dart
  /// final path = terminice.filePicker(label: 'Select a file');
  /// ```
  String filePicker({
    required String label,
    Directory? startDir,
    bool showHidden = false,
    bool foldersOnly = false,
    PromptTheme? theme,
  }) {
    return FilePickerPrompt(
      label: label,
      startDir: startDir,
      showHidden: showHidden,
      foldersOnly: foldersOnly,
      theme: theme ?? defaultTheme,
    ).run();
  }

  /// Tree explorer for hierarchical navigation.
  ///
  /// Returns the selected path (e.g., "root/child/grandchild"), or null if cancelled.
  ///
  /// **Example:**
  /// ```dart
  /// final path = terminice.tree(
  ///   title: 'Files',
  ///   roots: [
  ///     TreeNode('Documents', children: [
  ///       TreeNode('Work'),
  ///       TreeNode('Personal'),
  ///     ]),
  ///   ],
  /// );
  /// ```
  String? tree({
    required String title,
    required List<TreeNode> roots,
    bool allowCollapseAll = true,
    int maxVisible = 18,
    PromptConfig? config,
    PromptTheme? theme,
  }) {
    return TreeExplorer(
      title: title,
      roots: roots,
      allowCollapseAll: allowCollapseAll,
      maxVisible: maxVisible,
      config: config ?? defaultConfig,
      theme: theme ?? defaultTheme,
    ).run();
  }

  /// Color picker for selecting a color.
  ///
  /// Returns a hex color string (e.g., "#FF00AA"), or null if cancelled.
  ///
  /// **Example:**
  /// ```dart
  /// final color = terminice.colorPicker(label: 'Pick a color');
  /// ```
  String? colorPicker({
    String label = 'Pick a color',
    String? initialHex,
    int cols = 24,
    int rows = 8,
    PromptConfig? config,
    PromptTheme? theme,
  }) {
    return ColorPickerPrompt(
      label: label,
      initialHex: initialHex,
      cols: cols,
      rows: rows,
      config: config ?? defaultConfig,
      theme: theme ?? defaultTheme,
    ).run();
  }

  /// Interactive path/directory navigator.
  ///
  /// Returns selected path, or empty string if cancelled.
  ///
  /// **Example:**
  /// ```dart
  /// final path = terminice.pathNavigator(label: 'Select folder');
  /// ```
  String pathNavigator({
    String label = 'Path Navigator',
    Directory? startDir,
    bool showHidden = false,
    bool allowFiles = false,
    int maxVisible = 18,
    PromptTheme? theme,
  }) {
    return PathNavigator(
      label: label,
      startDir: startDir,
      showHidden: showHidden,
      allowFiles: allowFiles,
      maxVisible: maxVisible,
      theme: theme ?? defaultTheme,
    ).run();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TABLE WIDGETS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Display a formatted table.
  ///
  /// **Example:**
  /// ```dart
  /// terminice.table(
  ///   'Users',
  ///   columns: ['Name', 'Email', 'Role'],
  ///   rows: [
  ///     ['Alice', 'alice@example.com', 'Admin'],
  ///     ['Bob', 'bob@example.com', 'User'],
  ///   ],
  /// );
  /// ```
  void table(
    String title, {
    required List<String> columns,
    required List<List<String>> rows,
    List<TableAlign>? columnAlignments,
    bool zebraStripes = true,
    PromptConfig? config,
    PromptTheme? theme,
  }) {
    TableView(
      title,
      columns: columns,
      rows: rows,
      columnAlignments: columnAlignments,
      zebraStripes: zebraStripes,
      config: config ?? defaultConfig,
      theme: theme ?? defaultTheme,
    ).run();
  }

  /// Interactive table editor.
  ///
  /// Returns edited table data.
  ///
  /// **Example:**
  /// ```dart
  /// final data = terminice.tableEditor(
  ///   'Edit Data',
  ///   columns: ['Name', 'Value'],
  ///   rows: [['key1', 'value1']],
  /// );
  /// ```
  List<List<String>> tableEditor(
    String title, {
    required List<String> columns,
    required List<List<String>> rows,
    bool zebraStripes = true,
    PromptTheme? theme,
  }) {
    return TableEditor(
      title,
      columns: columns,
      rows: rows,
      zebraStripes: zebraStripes,
      theme: theme ?? defaultTheme,
    ).run();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DISPLAY WIDGETS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Display an info/warning/error box.
  ///
  /// **Example:**
  /// ```dart
  /// terminice.info('Operation completed successfully');
  /// terminice.info('Check your connection', type: InfoBoxType.warn);
  /// ```
  void info(
    String message, {
    InfoBoxType type = InfoBoxType.info,
    String? title,
    PromptConfig? config,
    PromptTheme? theme,
  }) {
    InfoBox(
      message,
      type: type,
      title: title,
      config: config ?? defaultConfig,
      theme: theme ?? defaultTheme,
    ).show();
  }

  /// Display multiple lines in an info box.
  ///
  /// **Example:**
  /// ```dart
  /// terminice.infoMulti(['Line 1', 'Line 2', 'Line 3']);
  /// ```
  void infoMulti(
    List<String> messages, {
    InfoBoxType type = InfoBoxType.info,
    String? title,
    PromptConfig? config,
    PromptTheme? theme,
  }) {
    InfoBox.multi(
      messages,
      type: type,
      title: title,
      config: config ?? defaultConfig,
      theme: theme ?? defaultTheme,
    ).show();
  }

  /// Animated progress bar.
  ///
  /// **Example:**
  /// ```dart
  /// terminice.progress('Downloading');
  /// ```
  void progress(
    String label, {
    int total = 100,
    int width = 36,
    Duration? totalDuration,
    PromptConfig? config,
    PromptTheme? theme,
  }) {
    ProgressBar(
      label,
      total: total,
      width: width,
      totalDuration: totalDuration,
      config: config ?? defaultConfig,
      theme: theme ?? defaultTheme,
    ).run();
  }

  /// Toast notification that fades away.
  ///
  /// **Example:**
  /// ```dart
  /// terminice.toast('Saved!', variant: ToastVariant.success);
  /// ```
  void toast(
    String message, {
    String label = 'Toast',
    ToastVariant variant = ToastVariant.info,
    Duration duration = const Duration(milliseconds: 1200),
    Duration fadeOut = const Duration(milliseconds: 600),
    int fps = 18,
    PromptConfig? config,
    PromptTheme? theme,
  }) {
    Toast(
      message,
      label: label,
      variant: variant,
      duration: duration,
      fadeOut: fadeOut,
      fps: fps,
      config: config ?? defaultConfig,
      theme: theme ?? defaultTheme,
    ).run();
  }

  /// ASCII art banner.
  ///
  /// **Example:**
  /// ```dart
  /// terminice.banner('HELLO');
  /// ```
  void banner(
    String text, {
    bool showFrame = true,
    bool showShadow = true,
    int hScale = 1,
    int letterSpacing = 1,
    PromptConfig? config,
    PromptTheme? theme,
  }) {
    Banner(
      text,
      showFrame: showFrame,
      showShadow: showShadow,
      hScale: hScale,
      letterSpacing: letterSpacing,
      config: config ?? defaultConfig,
      theme: theme ?? defaultTheme,
    ).run();
  }

  /// Loading spinner animation.
  ///
  /// **Example:**
  /// ```dart
  /// terminice.spinner('Loading', duration: Duration(seconds: 2));
  /// ```
  void spinner(
    String label, {
    String message = 'Loading',
    SpinnerStyle style = SpinnerStyle.dots,
    Duration duration = const Duration(seconds: 2),
    int fps = 12,
    PromptConfig? config,
    PromptTheme? theme,
  }) {
    LoadingSpinner(
      label,
      message: message,
      style: style,
      duration: duration,
      fps: fps,
      config: config ?? defaultConfig,
      theme: theme ?? defaultTheme,
    ).run();
  }

  /// Animated progress dots (ellipsis).
  ///
  /// **Example:**
  /// ```dart
  /// terminice.progressDots('Working');
  /// ```
  void progressDots(
    String label, {
    String message = 'Working',
    int maxDots = 3,
    Duration duration = const Duration(seconds: 2),
    Duration interval = const Duration(milliseconds: 250),
    PromptTheme? theme,
  }) {
    ProgressDots(
      label,
      message: message,
      maxDots: maxDots,
      duration: duration,
      interval: interval,
      theme: theme ?? defaultTheme,
    ).run();
  }

  /// Syntax-highlighted code display.
  ///
  /// **Example:**
  /// ```dart
  /// terminice.highlight('final x = 42;', language: 'dart');
  /// ```
  void highlight(
    String text, {
    String language = 'auto',
    String? title,
    bool color = true,
    bool guides = false,
    PromptTheme? theme,
  }) {
    Highlight(
      text,
      language: language,
      title: title,
      color: color,
      guides: guides,
      theme: theme ?? defaultTheme,
    ).show();
  }

  /// Display breadcrumb path navigation.
  ///
  /// **Example:**
  /// ```dart
  /// terminice.breadcrumbs('/home/user/projects/myapp');
  /// ```
  void breadcrumbs(
    String path, {
    String? label,
    int maxWidth = 80,
    String separator = '/',
    PromptTheme? theme,
  }) {
    Breadcrumbs(
      path,
      label: label,
      maxWidth: maxWidth,
      separator: separator,
      theme: theme ?? defaultTheme,
    ).show();
  }

  /// Display hotkey/shortcut guide.
  ///
  /// **Example:**
  /// ```dart
  /// terminice.hotkeyGuide([
  ///   ['Ctrl+S', 'Save'],
  ///   ['Ctrl+Q', 'Quit'],
  /// ]);
  /// ```
  void hotkeyGuide(
    List<List<String>> shortcuts, {
    String title = 'Hotkeys',
    List<String>? footer,
    PromptTheme? theme,
  }) {
    HotkeyGuide(
      shortcuts,
      title: title,
      footer: footer,
      theme: theme ?? defaultTheme,
    ).run();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // INLINE UTILITIES (return strings, not void)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Create a colored inline badge string.
  ///
  /// Returns the styled badge string (use with stdout.write).
  ///
  /// **Example:**
  /// ```dart
  /// print('Status: ${terminice.badge('OK', tone: BadgeTone.success)}');
  /// ```
  String badge(
    String text, {
    BadgeTone tone = BadgeTone.info,
    bool inverted = true,
    bool bracketed = true,
    bool bold = true,
    PromptTheme? theme,
  }) {
    return Badge(
      text,
      tone: tone,
      inverted: inverted,
      bracketed: bracketed,
      bold: bold,
      theme: theme ?? defaultTheme,
    ).render();
  }

  /// Create a success badge string.
  String badgeSuccess(String text, {PromptTheme? theme}) {
    return Badge.success(text, theme: theme ?? defaultTheme).render();
  }

  /// Create an info badge string.
  String badgeInfo(String text, {PromptTheme? theme}) {
    return Badge.info(text, theme: theme ?? defaultTheme).render();
  }

  /// Create a warning badge string.
  String badgeWarning(String text, {PromptTheme? theme}) {
    return Badge.warning(text, theme: theme ?? defaultTheme).render();
  }

  /// Create a danger/error badge string.
  String badgeDanger(String text, {PromptTheme? theme}) {
    return Badge.danger(text, theme: theme ?? defaultTheme).render();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CHART & DATA VISUALIZATION WIDGETS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Display a horizontal bar chart.
  ///
  /// **Example:**
  /// ```dart
  /// terminice.barChart([
  ///   BarChartItem('Sales', 1250.0),
  ///   BarChartItem('Revenue', 3400.0),
  ///   BarChartItem('Costs', 800.0),
  /// ], title: 'Q4 Summary');
  /// ```
  void barChart(
    List<BarChartItem> items, {
    String? title,
    int barWidth = 30,
    bool showValues = true,
    String Function(double)? valueFormatter,
    BarStyle barStyle = BarStyle.solid,
    PromptTheme? theme,
  }) {
    BarChartWidget(
      items,
      title: title,
      barWidth: barWidth,
      showValues: showValues,
      valueFormatter: valueFormatter,
      barStyle: barStyle,
      theme: theme ?? defaultTheme,
    ).show();
  }

  /// Interactive real-time line chart.
  ///
  /// **Example:**
  /// ```dart
  /// await terminice.lineChart('CPU Usage', duration: Duration(seconds: 10));
  /// ```
  Future<void> lineChart(
    String title, {
    int width = 64,
    int height = 12,
    Duration tick = const Duration(milliseconds: 120),
    Duration? duration,
    bool yAutoScale = true,
    double? yMin,
    double? yMax,
    ChartGrid grid = ChartGrid.dots,
    double Function()? generator,
    PromptTheme? theme,
  }) {
    return LineChartWidget(
      title,
      width: width,
      height: height,
      tick: tick,
      duration: duration,
      yAutoScale: yAutoScale,
      yMin: yMin,
      yMax: yMax,
      grid: grid,
      generator: generator,
      theme: theme ?? defaultTheme,
    ).run();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DATE & TIME WIDGETS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Multi-field date selector (day/month/year fields).
  ///
  /// Returns selected date, or null if cancelled.
  ///
  /// **Example:**
  /// ```dart
  /// final date = terminice.dateField(label: 'Birthday');
  /// ```
  DateTime? dateField({
    required String label,
    DateTime? initial,
    PromptTheme? theme,
  }) {
    return DateFieldsPrompt(
      label: label,
      initial: initial,
      theme: theme ?? defaultTheme,
    ).run();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CONTENT & TEXT WIDGETS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Render and display markdown content.
  ///
  /// **Example:**
  /// ```dart
  /// terminice.markdown('''
  /// # Hello World
  /// This is **bold** and *italic*.
  /// ''');
  /// ```
  void markdown(
    String content, {
    String? title,
    bool color = true,
    PromptTheme? theme,
  }) {
    MarkdownViewer(
      content,
      title: title,
      color: color,
      theme: theme ?? defaultTheme,
    ).show();
  }

  /// Small code snippet editor with syntax highlighting.
  ///
  /// Returns the edited code, or empty string if cancelled.
  ///
  /// **Example:**
  /// ```dart
  /// final code = terminice.snippetEditor(title: 'Edit Code');
  /// ```
  String snippetEditor({
    required String title,
    String language = 'auto',
    int maxLines = 200,
    int visibleLines = 12,
    String initialText = '',
    bool allowEmpty = true,
    PromptTheme? theme,
  }) {
    return SnippetEditor(
      title: title,
      language: language,
      maxLines: maxLines,
      visibleLines: visibleLines,
      initialText: initialText,
      allowEmpty: allowEmpty,
      theme: theme ?? defaultTheme,
    ).run();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LEARNING & QUIZ WIDGETS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Interactive quiz with scoring.
  ///
  /// Returns quiz result with score and selections.
  ///
  /// **Example:**
  /// ```dart
  /// final result = terminice.quiz(
  ///   title: 'Dart Quiz',
  ///   questions: [
  ///     QuizQuestion(
  ///       text: 'What is Dart?',
  ///       options: ['A language', 'A game', 'A drink'],
  ///       correctIndex: 0,
  ///     ),
  ///   ],
  /// );
  /// print('Score: ${result.correct}/${result.total}');
  /// ```
  QuizResult quiz({
    required String title,
    required List<QuizQuestion> questions,
    bool showFeedback = true,
    bool allowNumberShortcuts = true,
    PromptTheme? theme,
  }) {
    return QuizWidget(
      title: title,
      questions: questions,
      showFeedback: showFeedback,
      allowNumberShortcuts: allowNumberShortcuts,
      theme: theme ?? defaultTheme,
    ).run();
  }

  /// Spaced repetition flashcard study session.
  ///
  /// **Example:**
  /// ```dart
  /// terminice.flashcards(
  ///   cards: [
  ///     CardItem(front: 'Capital of France?', back: 'Paris'),
  ///     CardItem(front: '2 + 2 = ?', back: '4'),
  ///   ],
  ///   title: 'Study Session',
  /// );
  /// ```
  void flashcards({
    required List<CardItem> cards,
    String title = 'Flashcards',
    PromptTheme? theme,
  }) {
    Flashcards(
      cards: cards,
      title: title,
      theme: theme ?? defaultTheme,
    ).run();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // STATUS & LIVE WIDGETS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Create a persistent status line for live updates.
  ///
  /// Returns a [StatusLine] instance for manual control.
  ///
  /// **Example:**
  /// ```dart
  /// final status = terminice.statusLine(label: 'Building');
  /// status.start();
  /// status.update('Compiling...');
  /// // ... work ...
  /// status.success('Done!');
  /// status.stop();
  /// ```
  StatusLine statusLine({
    required String label,
    bool showSpinner = true,
    Duration spinnerInterval = const Duration(milliseconds: 120),
    PromptTheme? theme,
  }) {
    return StatusLine(
      label: label,
      showSpinner: showSpinner,
      spinnerInterval: spinnerInterval,
      theme: theme ?? defaultTheme,
    );
  }
}
