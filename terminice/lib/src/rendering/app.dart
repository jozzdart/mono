import '../style/theme.dart';
import 'widget.dart';
import 'app_host.dart';

/// Entry point to build and render a terminal app from a root widget.
void buildApp(
  Widget root, {
  PromptTheme theme = const PromptTheme(),
  bool colorEnabled = true,
}) =>
    runApp(root, theme: theme, colorEnabled: colorEnabled);
