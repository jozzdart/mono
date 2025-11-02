import 'package:mono_cli/mono_cli.dart';

class SystemClock implements Clock {
  const SystemClock();
  @override
  DateTime now() => DateTime.now();
}
