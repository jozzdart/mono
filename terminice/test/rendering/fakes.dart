import 'package:terminice/src/rendering/src.dart';
import 'package:terminice/src/style/theme.dart';

/// Simple helper to build a fixed-size RenderContext for tests.
RenderContext fixedContext({int columns = 80, bool colorEnabled = true, PromptTheme theme = const PromptTheme()}) {
  return RenderContext(theme: theme, terminalColumns: columns, colorEnabled: colorEnabled);
}


