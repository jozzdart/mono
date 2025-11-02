import 'package:meta/meta.dart';

@immutable
abstract class Prompter {
  const Prompter();

  Future<bool> confirm(String message, {bool defaultValue = false});

  /// Returns indices of selected items.
  Future<List<int>> checklist({
    required String title,
    required List<String> items,
  });
}
