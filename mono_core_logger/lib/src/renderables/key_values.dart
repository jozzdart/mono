import 'package:mono_core_logger/mono_core_logger.dart';

class KeyValueItem {
  final String key;
  final Object value; // string or Renderable
  const KeyValueItem(this.key, this.value);
}

class KeyValuesRenderable extends Renderable {
  final List<KeyValueItem> items;
  const KeyValuesRenderable(this.items);
}
