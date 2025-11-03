import 'models.dart';

class SelectionConstraints {
  final int? min;
  final int? max;
  const SelectionConstraints({this.min, this.max});
}

class ChecklistOption<T> {
  final T value;
  final String label;
  final bool disabled;
  final String? hint;
  const ChecklistOption(this.value, this.label,
      {this.disabled = false, this.hint});
}

/// Single-selection model exposing a highlighted index.
abstract class SelectPromptModel<T> extends PromptModel<int> {
  const SelectPromptModel();
  List<ChecklistOption<T>> get options;
  int get highlightedIndex;
}

/// Multi-selection model exposing a set of selected indices.
abstract class MultiSelectPromptModel<T> extends PromptModel<Set<int>> {
  const MultiSelectPromptModel();
  List<ChecklistOption<T>> get options;
  SelectionConstraints get constraints;
}

/// Checkboxes-based multi-select model alias.
abstract class ChecklistPromptModel<T> extends MultiSelectPromptModel<T> {
  const ChecklistPromptModel();
}
