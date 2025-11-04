import 'package:mono_core/mono_core.dart';

abstract class ConfigLoader {
  const ConfigLoader();
  MonoConfig load(String text);
}
