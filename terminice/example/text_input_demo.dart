import 'package:terminice/src/rendering/src.dart';
import 'package:terminice/src/terminice/text_input.dart';

class ResultsPage extends StatelessWidget {
  final String value;
  ResultsPage(this.value);

  @override
  void build(BuildContext context) {
    context.widget(Text(value));
  }
}

class InputTextPage extends StatelessWidget {
  @override
  void build(BuildContext context) {
    context.widget(Column([
      Text('Type and press Enter'),
      TextInput(
        onSubmitted: (v) {
          Navigator.of(context).push(ResultsPage(v));
        },
      ),
    ]));
  }
}

void main() {
  buildApp(InputTextPage());
}
