import 'package:mono_core/mono_core.dart';

class VersionCommand {
  static Future<int> run({
    required CliInvocation inv,
    required Logger logger,
    required VersionInfo version,
  }) async {
    logger.log('${version.name} ${version.version}');
    return 0;
  }
}
