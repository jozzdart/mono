class TerminalFrameBuffer {
  final List<String> _curr = [];
  List<String> _prev = const [];

  void addLine(String line) => _curr.add(line);

  void clear() => _curr.clear();

  void flushTo(void Function(String line) write,
      {bool clearBefore = true, bool diffMode = false}) {
    if (!diffMode || clearBefore) {
      if (clearBefore) {
        write('\x1B[2J\x1B[H'); // clear screen, cursor home
      }
      for (final l in _curr) {
        write(l);
      }
      _prev = List<String>.from(_curr);
      _curr.clear();
      return;
    }

    // Minimal diff: update only changed lines using cursor addressing.
    final maxLen = _curr.length > _prev.length ? _curr.length : _prev.length;
    for (int i = 0; i < maxLen; i++) {
      final newLine = i < _curr.length ? _curr[i] : '';
      final oldLine = i < _prev.length ? _prev[i] : '';
      if (newLine != oldLine) {
        // Move cursor to line (1-based), column 1 and overwrite.
        write('\x1B[${i + 1};1H');
        write(newLine);
      }
    }
    // If new content shorter than previous, clear trailing lines
    if (_curr.length < _prev.length) {
      for (int i = _curr.length; i < _prev.length; i++) {
        write('\x1B[${i + 1};1H');
        write('');
      }
    }
    _prev = List<String>.from(_curr);
    _curr.clear();
  }
}


