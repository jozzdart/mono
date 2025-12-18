import 'dart:io';

import 'package:terminice/terminice.dart';

/// Global terminice instance for easy widget access.
///
/// Example usage:
/// ```dart
/// // Basic usage
/// final password = terminice.password(label: 'Enter password');
/// final confirmed = terminice.confirm(label: 'Delete', message: 'Are you sure?');
///
/// // With theme
/// final pwd = terminice.arcane.password(label: 'Secret');
/// final name = terminice.matrix.text(prompt: 'Your name');
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
/// void main() {
///   // Basic usage
///   final pwd = terminice.password(label: 'Password');
///
///   // With theme accessor
///   final name = terminice.arcane.text(prompt: 'Your name');
///   final confirmed = terminice.matrix.confirm(label: 'Save', message: 'Continue?');
///
///   // With themed() method
///   final volume = terminice.themed(PromptTheme.fire).slider('Volume');
/// }
/// ```
class Terminice {
  /// Default theme for all widgets when not specified.
  final PromptTheme defaultTheme;

  /// Creates a Terminice instance with optional default theme.
  const Terminice({
    this.defaultTheme = PromptTheme.dark,
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // THEME ACCESSORS - Static getters for themed instances
  // ═══════════════════════════════════════════════════════════════════════════

  /// Dark theme instance (default).
  ///
  /// **Example:**
  /// ```dart
  /// final pwd = terminice.dark.password(label: 'Password');
  /// ```
  Terminice get dark => themed(PromptTheme.dark);

  /// Matrix theme instance (green, terminal-style).
  ///
  /// **Example:**
  /// ```dart
  /// final pwd = terminice.matrix.password(label: 'Password');
  /// ```
  Terminice get matrix => themed(PromptTheme.matrix);

  /// Fire theme instance (red/orange, bold).
  ///
  /// **Example:**
  /// ```dart
  /// final pwd = terminice.fire.password(label: 'Password');
  /// ```
  Terminice get fire => themed(PromptTheme.fire);

  /// Pastel theme instance (soft, gentle colors).
  ///
  /// **Example:**
  /// ```dart
  /// final pwd = terminice.pastel.password(label: 'Password');
  /// ```
  Terminice get pastel => themed(PromptTheme.pastel);

  /// Ocean theme instance (calming blue/cyan).
  ///
  /// **Example:**
  /// ```dart
  /// final pwd = terminice.ocean.password(label: 'Password');
  /// ```
  Terminice get ocean => themed(PromptTheme.ocean);

  /// Monochrome theme instance (high-contrast ASCII).
  ///
  /// **Example:**
  /// ```dart
  /// final pwd = terminice.monochrome.password(label: 'Password');
  /// ```
  Terminice get monochrome => themed(PromptTheme.monochrome);

  /// Neon theme instance (vibrant synthwave).
  ///
  /// **Example:**
  /// ```dart
  /// final pwd = terminice.neon.password(label: 'Password');
  /// ```
  Terminice get neon => themed(PromptTheme.neon);

  /// Arcane theme instance (mystical ancient tome).
  ///
  /// **Example:**
  /// ```dart
  /// final pwd = terminice.arcane.password(label: 'Password');
  /// ```
  Terminice get arcane => themed(PromptTheme.arcane);

  /// Phantom theme instance (ghostly apparition).
  ///
  /// **Example:**
  /// ```dart
  /// final pwd = terminice.phantom.password(label: 'Password');
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
  /// final pwd = fire.password(label: 'Password');
  /// ```
  Terminice themed(PromptTheme theme) {
    return Terminice(defaultTheme: theme);
  }

  // ═══════════════════════════════════════════════════════════════════════════

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
    PromptTheme? theme,
  }) {
    return SearchSelectPrompt(
      options,
      prompt: prompt,
      multiSelect: multiSelect,
      showSearch: showSearch,
      maxVisible: maxVisible,
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
    PromptTheme? theme,
  }) {
    return CheckboxMenu(
      label: label,
      options: options,
      maxVisible: maxVisible,
      initialSelected: initialSelected,
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
    PromptTheme? theme,
  }) {
    return GridSelectPrompt(
      options,
      prompt: prompt,
      columns: columns,
      multiSelect: multiSelect,
      cellWidth: cellWidth,
      maxColumns: maxColumns,
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
    PromptTheme? theme,
  }) {
    return TagSelector(
      tags,
      prompt: prompt,
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
    PromptTheme? theme,
  }) {
    return ToggleGroup(
      title,
      items,
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
    PromptTheme? theme,
  }) {
    return CommandPalette(
      commands: commands,
      label: label,
      maxVisible: maxVisible,
      theme: theme ?? defaultTheme,
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
    PromptTheme? theme,
  }) {
    return Form(
      title: title,
      fields: fields,
      theme: theme ?? defaultTheme,
    ).run();
  }

  /// Multi-step wizard with state passing.
  ///
  /// Returns the final state map, or null if cancelled.
  ///
  /// **Example:**
  /// ```dart
  /// final result = terminice.wizard(
  ///   title: 'Setup',
  ///   steps: [
  ///     WizardStep(
  ///       id: 'name',
  ///       label: 'Your Name',
  ///       run: (state, theme) => terminice.text(prompt: 'Name'),
  ///     ),
  ///   ],
  /// );
  /// ```
  Map<String, dynamic>? wizard({
    required String title,
    required List<WizardStep> steps,
    bool showProgress = true,
    PromptTheme? theme,
  }) {
    return Wizard(
      title: title,
      steps: steps,
      showProgress: showProgress,
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
    PromptTheme? theme,
  }) {
    return StepperPrompt(
      title: title,
      steps: steps,
      startIndex: startIndex,
      showStepNumbers: showStepNumbers,
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
  /// Returns the selected path, or `null` if cancelled.
  ///
  /// **Example:**
  /// ```dart
  /// final path = terminice.filePicker(label: 'Select a file');
  /// ```
  String? filePicker({
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
    PromptTheme? theme,
  }) {
    return TreeExplorer(
      title: title,
      roots: roots,
      allowCollapseAll: allowCollapseAll,
      maxVisible: maxVisible,
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
    PromptTheme? theme,
  }) {
    return ColorPickerPrompt(
      label: label,
      initialHex: initialHex,
      cols: cols,
      rows: rows,
      theme: theme ?? defaultTheme,
    ).run();
  }

  /// Interactive path/directory navigator.
  ///
  /// Returns selected path, or `null` if cancelled.
  ///
  /// **Example:**
  /// ```dart
  /// final path = terminice.pathNavigator(label: 'Select folder');
  /// ```
  String? pathNavigator({
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
    PromptTheme? theme,
  }) {
    TableView(
      title,
      columns: columns,
      rows: rows,
      columnAlignments: columnAlignments,
      zebraStripes: zebraStripes,
      theme: theme ?? defaultTheme,
    ).show();
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
    PromptTheme? theme,
  }) {
    InfoBox(
      message,
      type: type,
      title: title,
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
    PromptTheme? theme,
  }) {
    InfoBox.multi(
      messages,
      type: type,
      title: title,
      theme: theme ?? defaultTheme,
    ).show();
  }

  /// Animated progress bar.
  ///
  /// Creates a progress bar for manual updates.
  ///
  /// Returns a [ProgressBar] instance. Call `.show(current:, total:)` to update,
  /// and `.clear()` when done.
  ///
  /// **Example:**
  /// ```dart
  /// final bar = terminice.progress('Downloading');
  /// bar.show(current: 0, total: 100);
  /// // ... do work ...
  /// bar.show(current: 50, total: 100);
  /// bar.clear();
  /// ```
  ProgressBar progress(
    String label, {
    int width = 36,
    PromptTheme? theme,
  }) {
    return ProgressBar(
      label,
      width: width,
      theme: theme ?? defaultTheme,
    );
  }

  /// Creates a toast notification for manual display.
  ///
  /// Returns a [Toast] instance. Call `.show()` to display, `.clear()` to remove.
  ///
  /// **Example:**
  /// ```dart
  /// final t = terminice.toast('Saved!', variant: ToastVariant.success);
  /// t.show();
  /// // ... do something ...
  /// t.clear();
  /// ```
  Toast toast(
    String message, {
    String label = 'Toast',
    ToastVariant variant = ToastVariant.info,
    PromptTheme? theme,
  }) {
    return Toast(
      message,
      label: label,
      variant: variant,
      theme: theme ?? defaultTheme,
    );
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
    PromptTheme? theme,
  }) {
    Banner(
      text,
      showFrame: showFrame,
      showShadow: showShadow,
      hScale: hScale,
      letterSpacing: letterSpacing,
      theme: theme ?? defaultTheme,
    ).show();
  }

  /// Creates a loading spinner for manual updates.
  ///
  /// Returns a [LoadingSpinner] instance. Call `.show(frame:)` to update,
  /// and `.clear()` when done.
  ///
  /// **Example:**
  /// ```dart
  /// final spinner = terminice.spinner('Loading');
  /// spinner.show(frame: 0);
  /// // ... do work ...
  /// spinner.show(frame: 1);
  /// spinner.clear();
  /// ```
  LoadingSpinner spinner(
    String label, {
    String message = 'Loading',
    SpinnerStyle style = SpinnerStyle.dots,
    PromptTheme? theme,
  }) {
    return LoadingSpinner(
      label,
      message: message,
      style: style,
      theme: theme ?? defaultTheme,
    );
  }

  /// Animated progress dots (ellipsis).
  ///
  /// **Example:**
  /// ```dart
  /// terminice.progressDots('Working').show(phase: 0);
  /// ```
  ProgressDots progressDots(
    String label, {
    String message = 'Working',
    int maxDots = 3,
    PromptTheme? theme,
  }) {
    return ProgressDots(
      label,
      message: message,
      maxDots: maxDots,
      theme: theme ?? defaultTheme,
    );
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
  void badge(
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
    ).show();
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
  /// Returns the edited code, or `null` if cancelled.
  ///
  /// **Example:**
  /// ```dart
  /// final code = terminice.snippetEditor(title: 'Edit Code');
  /// ```
  String? snippetEditor({
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
  /// status.show('Compiling...');
  /// // ... work ...
  /// status.success('Done!');
  /// ```
  StatusLine statusLine({
    required String label,
    PromptTheme? theme,
  }) {
    return StatusLine(
      label: label,
      theme: theme ?? defaultTheme,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DISPLAY WIDGETS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Display a changelog from a file or content.
  ///
  /// **Example:**
  /// ```dart
  /// terminice.changelog(filePath: 'CHANGELOG.md');
  /// ```
  void changelog({
    String? filePath,
    String? content,
    String title = 'Changelog',
    int maxReleases = 6,
    PromptTheme? theme,
  }) {
    ChangeLogViewer(
      filePath: filePath,
      content: content,
      title: title,
      maxReleases: maxReleases,
      theme: theme ?? defaultTheme,
    ).show();
  }

  /// Display a command cheat sheet.
  ///
  /// **Example:**
  /// ```dart
  /// terminice.cheatSheet([
  ///   ['git status', 'gs', 'Show working tree status'],
  ///   ['git add', 'ga', 'Add files to staging'],
  /// ]);
  /// ```
  void cheatSheet(
    List<List<String>> entries, {
    String title = 'Cheat Sheet',
    PromptTheme? theme,
  }) {
    CheatSheet(
      entries,
      title: title,
      theme: theme ?? defaultTheme,
    ).show();
  }

  /// Display stat cards with big numeric highlights.
  ///
  /// **Example:**
  /// ```dart
  /// terminice.stats([
  ///   StatCardItem(label: 'Tests', value: '98%'),
  ///   StatCardItem(label: 'Coverage', value: '85%'),
  /// ]);
  /// ```
  void stats(
    List<StatCardItem> items, {
    String? title,
    PromptTheme? theme,
  }) {
    StatCards(
      items: items,
      title: title,
      theme: theme ?? defaultTheme,
    ).show();
  }

  /// Display a system clock line with scheduled events.
  ///
  /// **Example:**
  /// ```dart
  /// terminice.clockLine([
  ///   CronEvent('Backup', DateTime.now().add(Duration(minutes: 10))),
  /// ]);
  /// ```
  void clockLine(
    List<CronEvent> events, {
    String? title,
    Duration window = const Duration(hours: 1),
    PromptTheme? theme,
  }) {
    SystemClockLine(
      events,
      title: title,
      window: window,
      theme: theme ?? defaultTheme,
    ).show();
  }

  /// Interactive environment variable manager.
  ///
  /// **Example:**
  /// ```dart
  /// terminice.envManager();
  /// ```
  void envManager({
    String? title,
    PromptTheme? theme,
  }) {
    EnvManager(
      title: title,
      theme: theme ?? defaultTheme,
    ).run();
  }

  /// Display a mini-map showing document position.
  ///
  /// **Example:**
  /// ```dart
  /// terminice.miniMap(totalLines: 1000, viewportStart: 100, viewportSize: 50);
  /// ```
  void miniMap({
    required int totalLines,
    required int viewportStart,
    required int viewportSize,
    String? label,
    PromptTheme? theme,
  }) {
    MiniMap(
      totalLines: totalLines,
      viewportStart: viewportStart,
      viewportSize: viewportSize,
      label: label,
      theme: theme ?? defaultTheme,
    ).show();
  }

  /// Display mini analytics sparkline with trend.
  ///
  /// **Example:**
  /// ```dart
  /// terminice.miniAnalytics(series: [10, 25, 18, 30, 22]);
  /// ```
  void miniAnalytics({
    required List<num> series,
    String label = 'Growth',
    String? title,
    PromptTheme? theme,
  }) {
    MiniAnalytics(
      series: series,
      label: label,
      title: title,
      theme: theme ?? defaultTheme,
    ).show();
  }

  /// Display a resource grid with cells.
  ///
  /// **Example:**
  /// ```dart
  /// terminice.resourceGrid(
  ///   title: 'System Resources',
  ///   resources: [
  ///     ResourceCell(label: 'CPU', value: '45%', series: [10, 20, 45]),
  ///   ],
  /// );
  /// ```
  void resourceGrid({
    required String title,
    required List<ResourceCell> resources,
    int columns = 0,
    PromptTheme? theme,
  }) {
    ResourceGrid(
      title: title,
      resources: resources,
      columns: columns,
      theme: theme ?? defaultTheme,
    ).show();
  }
}
