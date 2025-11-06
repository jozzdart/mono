import 'package:terminice/src/rendering/src.dart';
import 'package:terminice/src/terminice/text_input.dart';

class ResultsPage extends StatelessWidget {
  final String value;
  ResultsPage(this.value);

  @override
  Widget? buildWidget(BuildContext context) {
    return Text(value);
  }
}

class InputTextPage extends StatelessWidget {
  @override
  Widget? buildWidget(BuildContext context) {
    return Column(
      children: [
        Text('Type and press Enter'),
        TextInput(
          onSubmitted: (v) {
            Navigator.of(context).push(ResultsPage(v));
          },
        ),
      ],
    );
  }
}

void main() {
  buildApp(InputTextPage());
}
