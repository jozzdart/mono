import 'package:terminice/terminice.dart';

void main() {
  final inspector = PackageInspector.fromPubspecFile('mono/pubspec.yaml');
  inspector.show();
}
