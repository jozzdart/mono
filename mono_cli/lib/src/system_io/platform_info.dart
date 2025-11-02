import 'dart:io' show Platform;

import 'package:mono_cli/mono_cli.dart';

class DefaultPlatformInfo implements PlatformInfo {
  const DefaultPlatformInfo();

  @override
  bool get isWindows => Platform.isWindows;
  @override
  bool get isLinux => Platform.isLinux;
  @override
  bool get isMacOS => Platform.isMacOS;

  @override
  String get shell => isWindows ? 'powershell' : '/bin/bash';
}
