// ════════════════════════════════════════════════════════════════════════════
// CORE SYSTEM EXPORTS
// ════════════════════════════════════════════════════════════════════════════

export 'core/core.dart';

// Terminal & I/O
export 'system/terminal.dart';
export 'system/key_events.dart';
export 'system/key_bindings.dart';

// Rendering Infrastructure
export 'system/prompt_runner.dart';
export 'system/framed_layout.dart';
export 'system/frame_renderer.dart';
export 'system/widget_frame.dart';
export 'system/line_builder.dart';
export 'system/hints.dart';
export 'system/table_renderer.dart';
export 'system/text_utils.dart';
export 'system/highlighter.dart';
export 'system/rendering.dart';
export 'system/inline_style.dart';
export 'system/syntax_highlight.dart';

// Navigation & Selection
export 'system/list_navigation.dart';
export 'system/grid_navigation.dart';
export 'system/focus_navigation.dart';
export 'system/selection_controller.dart';

// Input Handling
export 'system/text_input_buffer.dart';

// Composable Prompt Systems
export 'system/simple_prompt.dart';
export 'system/value_prompt.dart';
export 'system/selectable_list_prompt.dart';
export 'system/searchable_list_prompt.dart';
export 'system/selectable_grid_prompt.dart';
export 'system/ranked_list_prompt.dart';
export 'system/dynamic_list_prompt.dart';

// Central API
export 'terminice_api.dart';

// ════════════════════════════════════════════════════════════════════════════
// INTERACTIVE WIDGET EXPORTS (Prompts that return values)
// ════════════════════════════════════════════════════════════════════════════

// Text Input
export 'widgets/text_prompt.dart';
export 'widgets/password.dart';
export 'widgets/multi_line_input.dart';

// Confirmation & Choice
export 'widgets/confirm_prompt.dart';
export 'widgets/search_select.dart';
export 'widgets/checkbox_menu.dart';
export 'widgets/grid_select.dart';
export 'widgets/choice_map.dart';
export 'widgets/toggle_group.dart';
export 'widgets/tag_selector.dart';
export 'widgets/command_palette.dart';

// Numeric Input
export 'widgets/slider_prompt.dart';
export 'widgets/rating_prompt.dart';
export 'widgets/range_prompt.dart';

// Date & Time
export 'widgets/date_field.dart';
export 'widgets/date_picker.dart';

// File & Navigation
export 'widgets/file_pickers.dart';
export 'widgets/path_navigator.dart';
export 'widgets/tree_explorer.dart';
export 'widgets/color_picker.dart';

// Forms & Wizards
export 'widgets/form.dart';
export 'widgets/wizard.dart';
export 'widgets/stepper.dart';
export 'widgets/survey_form.dart';

// Tables
export 'widgets/table_view.dart';
export 'widgets/table_editor.dart';

// Code & Text Editing
export 'widgets/snippet_editor.dart';
export 'widgets/config_editor.dart';
export 'widgets/env_manager.dart';

// Learning & Quiz
export 'widgets/quiz_widget.dart';
export 'widgets/flashcards.dart';

// ════════════════════════════════════════════════════════════════════════════
// DISPLAY WIDGET EXPORTS (Non-interactive, show information)
// ════════════════════════════════════════════════════════════════════════════

// Banners & Headers
export 'widgets/banner.dart';
export 'widgets/breadcrumbs.dart';

// Information Display
export 'widgets/info_box.dart';
export 'widgets/badge.dart';
export 'widgets/toast.dart';
export 'widgets/highlight.dart';

// Progress & Status
export 'widgets/progress_bar.dart';
export 'widgets/progress_dots.dart';
export 'widgets/loading_spinner.dart';
export 'widgets/status_line.dart';

// Charts & Analytics
export 'widgets/bar_chart.dart';
export 'widgets/line_chart_widget.dart';
export 'widgets/mini_analytics.dart';
export 'widgets/stat_cards.dart';

// Dashboards & Monitors
export 'widgets/system_dashboard.dart';
export 'widgets/project_dashboard.dart';
export 'widgets/service_monitor.dart';
export 'widgets/resource_grid.dart';
export 'widgets/todo_dashboard.dart';

// Time & Scheduling
export 'widgets/clock_widget.dart';
export 'widgets/system_clock_line.dart';
export 'widgets/weather_widget.dart';

// Launchers & Guides
export 'widgets/launch_pad.dart';
export 'widgets/hotkey_guide.dart';
export 'widgets/mini_map.dart';

// Documentation & Help
export 'widgets/changelog_viewer.dart';
export 'widgets/help_center.dart';
export 'widgets/tutorial_runner.dart';
export 'widgets/cheat_sheet.dart';
export 'widgets/cli_manual.dart';
export 'widgets/doc_navigator.dart';
export 'widgets/package_inspector.dart';
export 'widgets/markdown_viewer.dart';
export 'widgets/code_playground.dart';

// Utilities
export 'widgets/unit_converter.dart';
export 'widgets/theme_demo.dart';
