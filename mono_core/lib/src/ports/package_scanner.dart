import 'package:mono_core/mono_core.dart';

@immutable
abstract class PackageScanner {
  const PackageScanner();
  Future<List<MonoPackage>> scan({
    required String rootPath,
    required List<String> includeGlobs,
    required List<String> excludeGlobs,
  });
}
