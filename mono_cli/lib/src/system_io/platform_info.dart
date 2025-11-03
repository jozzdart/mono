import 'dart:io' show Platform;

import 'package:mono_core/mono_core.dart';

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
