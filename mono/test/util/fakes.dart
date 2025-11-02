import 'package:mono_cli/mono_cli.dart';

class FakePrompter implements Prompter {
  FakePrompter({this.nextConfirm = true, this.checklistIndices = const []});

  final bool nextConfirm;
  final List<int> checklistIndices;

  @override
  Future<bool> confirm(String message, {bool defaultValue = false}) async =>
      nextConfirm;

  @override
  Future<List<int>> checklist(
          {required String title, required List<String> items}) async =>
      checklistIndices;
}
