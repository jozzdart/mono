import 'package:mono_core_logger/mono_core_logger.dart';

/// Portable key description.
class KeyDescriptor {
  final String code; // e.g., 'up', 'down', 'enter', 'space', 'a'
  final bool ctrl;
  final bool alt;
  final bool shift;
  const KeyDescriptor(this.code,
      {this.ctrl = false, this.alt = false, this.shift = false});
}

/// Maps keys to logical prompt inputs.
abstract class PromptKeyMap {
  PromptInput? map(KeyDescriptor key);
}
