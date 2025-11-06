export 'context.dart';
export 'widget.dart';
export 'renderer.dart';
export 'widgets.dart';
export 'engine.dart';
export 'app.dart';
export 'inherited.dart';
export 'layout/flex.dart';
export 'layout/padding.dart';
export 'layout/align.dart';
export 'layout/box.dart';
export 'layout/wrap.dart';
export 'list.dart';
export 'table.dart';
export 'text/rich_text.dart';
export 'app_host.dart';
export 'testing.dart';
export 'core/element.dart';
export 'modifiers.dart';
export 'input/key_events.dart';
export 'input/focus.dart';
export 'input/key_listener.dart';
export 'navigation/navigator.dart';
export 'scheduler.dart';

/// Quick example (not executed):
///
/// buildApp(
///   Frame(
///     'Demo',
///     Column([
///       SectionHeaderLine('Overview'),
///       MetricLine('Status', 'OK', color: PromptTheme.dark.info),
///       Gutter(Text('Hello world')),
///       DividerLine(),
///       TitleLine('Next', underline: true),
///     ]),
///   ),
///   theme: PromptTheme.dark,
/// );
