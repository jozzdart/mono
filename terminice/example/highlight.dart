import 'dart:io';

import 'package:terminice/terminice.dart';

void main() {
  final dartSample = '''
import 'dart:math';

class Greeter {
  final String name;
  Greeter(this.name);
  void sayHello() {
    final n = 42;
    print('Hello, ' + name + ' #' + n.toString()); // greeting
  }
}
''';

  final jsonSample = '''
{
  "name": "terminice",
  "version": 1.0,
  "colors": ["red", "green", "blue"],
  // comment supported for demo
  "active": true,
  "meta": null
}
''';

  final shellSample = '''
# sample shell
curl -X POST https://api.example.com/v1/items \
  -H "Authorization: Bearer TOKEN" \
  -d '{"name":"demo","count":3}'
''';

  Highlight(dartSample,
      theme: PromptTheme.dark,
      language: 'dart',
      title: 'Dart',
      color: false,
      guides: true)
    ..show();
  stdout.writeln();

  Highlight(jsonSample,
      theme: PromptTheme.pastel,
      language: 'json',
      title: 'JSON',
      color: false,
      guides: true)
    ..show();
  stdout.writeln();

  Highlight(shellSample,
      theme: PromptTheme.matrix,
      language: 'shell',
      title: 'Shell',
      color: false,
      guides: true)
    ..show();
}
