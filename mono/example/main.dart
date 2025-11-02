import 'dart:io';

import 'package:mono/mono.dart';

Future<void> main() async {
  final code = await runCli(['help'], stdout, stderr);
  print('mono exited with code $code');
}
