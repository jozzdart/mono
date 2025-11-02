import 'package:mono_core/mono_core.dart';

@immutable
abstract class GraphBuilder {
  const GraphBuilder();
  DependencyGraph build(List<MonoPackage> packages);
}
