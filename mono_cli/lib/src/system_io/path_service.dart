import 'package:mono_core/mono_core.dart';
import 'package:path/path.dart' as p;

class DefaultPathService implements PathService {
  const DefaultPathService();
  @override
  String join(Iterable<String> parts) => p.joinAll(parts);
  @override
  String normalize(String path) => p.normalize(path);
}
