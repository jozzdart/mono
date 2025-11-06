import 'package:test/test.dart';
import 'package:terminice/src/rendering/src.dart';
import 'test_utils.dart';

NavigatorState? _grabbed;

class _GrabNavigator extends StatelessWidget {
  @override
  void build(BuildContext context) {
    _grabbed = Navigator.of(context);
  }
}

Widget _page(String label) => Column([
      Text(label),
      _GrabNavigator(),
    ]);

void main() {
  test('Navigator renders only the top page', () {
    final nav = Navigator(initial: _page('Page1'));
    final h = ElementHarness(nav);
    final lines = h.render();
    expect(lines.join('\n'), contains('Page1'));
    expect(lines.join('\n'), isNot(contains('Page2')));
  });

  test('Navigator push and pop change the visible page', () {
    _grabbed = null;
    final nav = Navigator(initial: _page('Page1'));
    final h = ElementHarness(nav);

    // Initial render to bind _grabbed via _GrabNavigator.
    var lines = h.render();
    expect(_grabbed, isNotNull);
    expect(lines.join('\n'), contains('Page1'));

    // Push a new page and render again.
    _grabbed!.push(_page('Page2'));
    lines = h.render();
    expect(lines.join('\n'), contains('Page2'));
    expect(lines.join('\n'), isNot(contains('Page1')));

    // Pop back to the first page.
    final popped = _grabbed!.pop();
    expect(popped, isTrue);
    lines = h.render();
    expect(lines.join('\n'), contains('Page1'));
    expect(lines.join('\n'), isNot(contains('Page2')));
  });
}
