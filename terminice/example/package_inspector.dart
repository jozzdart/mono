import '../lib/src/src.dart';

void main() {
  final inspector = PackageInspector.fromPubspecFile('mono/pubspec.yaml');
  inspector.show();
}
