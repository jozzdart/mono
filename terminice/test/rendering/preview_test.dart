import 'package:test/test.dart';
import 'package:terminice/src/rendering/src.dart';
import 'test_utils.dart';

/// Wraps a widget with a divider and a title label for quick visual preview.
class PreviewTestWidget extends StatelessWidget {
  final String name;
  final Widget child;
  PreviewTestWidget(this.name, this.child);

  @override
  void build(BuildContext context) {
    context.widget(DividerLine());
    context.widget(Text(name));
    context.widget(child);
  }
}

void main() {
  test('preview renders sample widgets to stdout', () {
    final harness = RenderHarness();

    // Add widgets you want to preview here.
    final previews = Column([
      PreviewTestWidget('Text: hello world', Text('hello world')),
      PreviewTestWidget(
          'SectionHeaderLine: Overview', SectionHeaderLine('Overview')),
      PreviewTestWidget(
        'MetricLine: Status OK',
        MetricLine('Status', 'OK'),
      ),
      PreviewTestWidget(
        'Frame + Text',
        Frame(
            'Demo',
            Column([
              Text('inside frame'),
              Row(children: [
                Text('left'),
                Text('right'),
              ])
            ])),
      ),
    ]);

    final lines =
        harness.renderWidget(previews, columns: 80, colorEnabled: true);

    // Print to console so you can visually inspect.
    // Keep assertion minimal to avoid hiding output.
    // You can add more widgets above to expand the preview.
    // ignore: avoid_print
    print(lines.join('\n'));
    expect(lines.isNotEmpty, isTrue);
  });
}
