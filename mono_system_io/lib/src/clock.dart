import 'package:mono_ports/mono_ports.dart';

class SystemClock implements Clock {
  const SystemClock();
  @override
  DateTime now() => DateTime.now();
}


