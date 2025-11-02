import 'package:meta/meta.dart';

@immutable
abstract class VersionInfo {
  const VersionInfo();
  String get name;
  String get version;
}
