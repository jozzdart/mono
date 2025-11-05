import '../lib/src/src.dart';

void main() async {
  final monitor = ServiceMonitor([
    ServiceEndpoint('Example', 'https://example.org'),
    ServiceEndpoint('Dart', 'https://dart.dev'),
    ServiceEndpoint('Google', 'https://google.com'),
    ServiceEndpoint('Invalid', 'https://localhost:65535'),
  ], theme: PromptTheme.pastel);

  await monitor.run();
}
