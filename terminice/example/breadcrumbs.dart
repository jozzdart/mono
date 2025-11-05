import '../lib/src/src.dart';

void main() {
  final demoPaths = [
    '/Users/jozz/Documents/GitHub/mono/terminice/lib/src/widgets/breadcrumbs.dart',
    '/var/log/system',
    'C:/Program Files/Dart/bin',
    '/very/long/path/that/needs/to/be/collapsed/in/the/middle/for/clarity',
  ];

  for (final p in demoPaths) {
    Breadcrumbs(
      p,
      theme: PromptTheme.pastel,
      label: 'Breadcrumbs',
      maxWidth: 72,
      separator: '/',
    ).show();
    // Spacer between frames
    print('');
  }
}


