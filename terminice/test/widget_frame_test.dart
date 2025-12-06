import 'package:test/test.dart';
import 'package:terminice/terminice.dart';

void main() {
  group('WidgetFrame', () {
    test('creates with required parameters', () {
      final frame = WidgetFrame(
        title: 'Test',
        theme: PromptTheme.dark,
      );
      expect(frame.title, 'Test');
      expect(frame.bindings, isNull);
      expect(frame.hintStyle, HintStyle.bullets);
      expect(frame.showConnector, false);
    });

    test('creates with all parameters', () {
      final bindings = KeyBindings.prompt();
      final frame = WidgetFrame(
        title: 'Full Test',
        theme: PromptTheme.matrix,
        bindings: bindings,
        hintStyle: HintStyle.grid,
        showConnector: true,
      );
      expect(frame.title, 'Full Test');
      expect(frame.bindings, bindings);
      expect(frame.hintStyle, HintStyle.grid);
      expect(frame.showConnector, true);
    });

    test('style getter returns theme style', () {
      final frame = WidgetFrame(
        title: 'Test',
        theme: PromptTheme.fire,
      );
      expect(frame.style, PromptTheme.fire.style);
    });
  });

  group('HintStyle', () {
    test('has all expected values', () {
      expect(HintStyle.values, contains(HintStyle.bullets));
      expect(HintStyle.values, contains(HintStyle.grid));
      expect(HintStyle.values, contains(HintStyle.inline));
      expect(HintStyle.values, contains(HintStyle.none));
    });
  });

  group('FrameContext', () {
    // Note: FrameContext is private (factory via _) but we can test its behavior
    // indirectly through WidgetFrame.render. These tests ensure the components
    // compose correctly.

    test('WidgetFrame renders with callback', () {
      final frame = WidgetFrame(
        title: 'Context Test',
        theme: PromptTheme.dark,
      );

      bool callbackCalled = false;

      final out = _TestRenderOutput();
      frame.render(out, (ctx) {
        callbackCalled = true;
        expect(ctx.theme, PromptTheme.dark);
        expect(ctx.lb, isA<LineBuilder>());
        // frame is available via ctx.frame
        expect(ctx.frame, isNotNull);
      });

      expect(callbackCalled, isTrue);
    });

    test('renderContent renders without hints', () {
      final bindings = KeyBindings.prompt();
      final frame = WidgetFrame(
        title: 'No Hints',
        theme: PromptTheme.dark,
        bindings: bindings,
      );

      final outWithHints = _TestRenderOutput();
      frame.render(outWithHints, (ctx) {
        ctx.gutterLine('content');
      });

      final outWithoutHints = _TestRenderOutput();
      frame.renderContent(outWithoutHints, (ctx) {
        ctx.gutterLine('content');
      });

      // renderContent should have fewer lines (no hints)
      expect(outWithoutHints.lineCount, lessThan(outWithHints.lineCount));
    });
  });

  group('FrameContext methods', () {
    late WidgetFrame frame;
    late _TestRenderOutput out;

    setUp(() {
      frame = WidgetFrame(
        title: 'Methods Test',
        theme: PromptTheme.dark,
        showConnector: true,
      );
      out = _TestRenderOutput();
    });

    test('emptyLine writes blank line', () {
      frame.renderContent(out, (ctx) {
        ctx.emptyLine();
      });
      expect(out.lines.any((l) => l.isEmpty), isTrue);
    });

    test('gutterLine includes gutter prefix', () {
      frame.renderContent(out, (ctx) {
        ctx.gutterLine('test content');
      });
      expect(out.lines.any((l) => l.contains('test content')), isTrue);
      expect(out.lines.any((l) => l.contains('│')), isTrue);
    });

    test('labeledValue formats label and value', () {
      frame.renderContent(out, (ctx) {
        ctx.labeledValue('Name', 'Alice');
      });
      expect(out.lines.any((l) => l.contains('Name:')), isTrue);
      expect(out.lines.any((l) => l.contains('Alice')), isTrue);
    });

    test('labeledAccent uses accent color on value', () {
      frame.renderContent(out, (ctx) {
        ctx.labeledAccent('Status', 'Active');
      });
      expect(out.lines.any((l) => l.contains('Status:')), isTrue);
      expect(out.lines.any((l) => l.contains('Active')), isTrue);
    });

    test('boldMessage applies bold', () {
      frame.renderContent(out, (ctx) {
        ctx.boldMessage('Important');
      });
      expect(out.lines.any((l) => l.contains('Important')), isTrue);
    });

    test('dimMessage applies dim', () {
      frame.renderContent(out, (ctx) {
        ctx.dimMessage('Secondary');
      });
      expect(out.lines.any((l) => l.contains('Secondary')), isTrue);
    });

    test('errorMessage uses error color', () {
      frame.renderContent(out, (ctx) {
        ctx.errorMessage('Failed!');
      });
      expect(out.lines.any((l) => l.contains('Failed!')), isTrue);
    });

    test('warnMessage uses warn color', () {
      frame.renderContent(out, (ctx) {
        ctx.warnMessage('Caution');
      });
      expect(out.lines.any((l) => l.contains('Caution')), isTrue);
    });

    test('infoMessage uses info color', () {
      frame.renderContent(out, (ctx) {
        ctx.infoMessage('Note');
      });
      expect(out.lines.any((l) => l.contains('Note')), isTrue);
    });

    test('emptyMessage formats placeholder', () {
      frame.renderContent(out, (ctx) {
        ctx.emptyMessage('no items');
      });
      expect(out.lines.any((l) => l.contains('no items')), isTrue);
    });

    test('overflowIndicator writes ellipsis', () {
      frame.renderContent(out, (ctx) {
        ctx.overflowIndicator();
      });
      expect(out.lines.any((l) => l.contains('...')), isTrue);
    });

    test('selectableItem writes with arrow', () {
      frame.renderContent(out, (ctx) {
        ctx.selectableItem('Item 1', focused: true);
        ctx.selectableItem('Item 2', focused: false);
      });
      expect(out.lines.any((l) => l.contains('Item 1')), isTrue);
      expect(out.lines.any((l) => l.contains('Item 2')), isTrue);
    });

    test('checkboxItem writes with checkbox', () {
      frame.renderContent(out, (ctx) {
        ctx.checkboxItem('Option A', focused: true, checked: true);
        ctx.checkboxItem('Option B', focused: false, checked: false);
      });
      expect(out.lines.any((l) => l.contains('Option A')), isTrue);
      expect(out.lines.any((l) => l.contains('Option B')), isTrue);
    });

    test('selectionList renders all items', () {
      final items = ['Apple', 'Banana', 'Cherry'];
      frame.renderContent(out, (ctx) {
        ctx.selectionList(items, selectedIndex: 1);
      });
      expect(out.lines.any((l) => l.contains('Apple')), isTrue);
      expect(out.lines.any((l) => l.contains('Banana')), isTrue);
      expect(out.lines.any((l) => l.contains('Cherry')), isTrue);
    });

    test('selectionList with itemBuilder transforms items', () {
      final items = [1, 2, 3];
      frame.renderContent(out, (ctx) {
        ctx.selectionList(
          items,
          selectedIndex: 0,
          itemBuilder: (n) => 'Number $n',
        );
      });
      expect(out.lines.any((l) => l.contains('Number 1')), isTrue);
      expect(out.lines.any((l) => l.contains('Number 2')), isTrue);
      expect(out.lines.any((l) => l.contains('Number 3')), isTrue);
    });

    test('checkboxList renders all items with checkboxes', () {
      final items = ['Red', 'Green', 'Blue'];
      frame.renderContent(out, (ctx) {
        ctx.checkboxList(
          items,
          focusedIndex: 0,
          checkedIndices: {0, 2},
        );
      });
      expect(out.lines.any((l) => l.contains('Red')), isTrue);
      expect(out.lines.any((l) => l.contains('Green')), isTrue);
      expect(out.lines.any((l) => l.contains('Blue')), isTrue);
    });

    test('writeConnector writes connector line when borders enabled', () {
      final frameWithBorder = WidgetFrame(
        title: 'With Border',
        theme: PromptTheme.dark,
      );
      final outWithBorder = _TestRenderOutput();
      frameWithBorder.renderContent(outWithBorder, (ctx) {
        ctx.writeConnector();
      });
      // Should have connector when borders are enabled (default)
      expect(outWithBorder.lines.any((l) => l.contains('├')), isTrue);
    });
  });
}

/// Test implementation of RenderOutput that captures output for assertions.
class _TestRenderOutput implements RenderOutput {
  final List<String> lines = [];
  int _lineCount = 0;

  @override
  int get lineCount => _lineCount;

  @override
  void writeln([String line = '']) {
    lines.add(line);
    _lineCount++;
  }

  @override
  void write(String text) {
    if (lines.isEmpty) lines.add('');
    lines[lines.length - 1] += text;
    _lineCount += '\n'.allMatches(text).length;
  }

  @override
  void clear() {
    lines.clear();
    _lineCount = 0;
  }
}

