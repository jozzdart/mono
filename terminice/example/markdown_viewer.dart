import 'dart:io';

import 'package:terminice/terminice.dart';

void main() {
  Terminal.clearAndHome();

  const md = '''
# Markdown Viewer

Render beautiful markdown in your terminal, aligned with the ThemeDemo styling.

## Features

- Headers `#`..`######` with tasteful colors
- Lists, blockquotes, code fences
- Inline `code`, *italic*, **bold**, and [links](https://example.com)

> Tip: Try different themes for varied aesthetics.

---

### Code

```dart
void main() {
  final msg = "Hello";
  print(msg);
}
```

#### Ordered

1. First
2. Second
3. Third
 
#### Tasks

- [x] Add headings
- [ ] Make lists gorgeous
- [x] Support code fences

#### Table

| Feature | Status |
|:--------|:------:|
| Headings | ✅ |
| Lists | ✅ |
| Code | ✅ |
| Tables | ✅ |
''';

  MarkdownViewer(
    md,
    theme: PromptTheme.pastel,
    title: 'Markdown Viewer',
    color: true,
  ).show();

  stdout.writeln();
  MarkdownViewer(
    md,
    theme: PromptTheme.matrix,
    title: 'Markdown Viewer',
    color: false, // demonstrate clean no-color rendering
  ).show();
}


