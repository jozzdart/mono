import '../layout.dart';

/// Logical input events for prompts, independent of actual key presses.
abstract class PromptInput {
  const PromptInput();
}

class SubmitInput extends PromptInput {
  const SubmitInput();
}

class CancelInput extends PromptInput {
  const CancelInput();
}

class MoveUpInput extends PromptInput {
  const MoveUpInput();
}

class MoveDownInput extends PromptInput {
  const MoveDownInput();
}

class MoveHomeInput extends PromptInput {
  const MoveHomeInput();
}

class MoveEndInput extends PromptInput {
  const MoveEndInput();
}

class ToggleInput extends PromptInput {
  const ToggleInput();
}

class TypeTextInput extends PromptInput {
  final String text;
  const TypeTextInput(this.text);
}

/// Prompt events emitted by the model.
abstract class PromptEvent {
  const PromptEvent();
}

class StateChanged extends PromptEvent {
  const StateChanged();
}

class ValidationChanged extends PromptEvent {
  final String? message; // null means valid
  const ValidationChanged(this.message);
}

class Submitted<T> extends PromptEvent {
  final T value;
  const Submitted(this.value);
}

class Cancelled extends PromptEvent {
  const Cancelled();
}

typedef Validator<TState> = String? Function(TState state);

/// Base model of a prompt with a typed internal state.
abstract class PromptModel<TState> {
  const PromptModel();
  TState get state;
  Stream<PromptEvent> get events;
  bool get isComplete;
}

/// A running prompt session with a model and a future result.
abstract class PromptSession<T> {
  const PromptSession();
  PromptModel<dynamic> get model;
  Future<T> get result;
  void input(PromptInput input);
  void close();
}

/// Visual renderer contract that observes a prompt model and draws it into a region.
abstract class PromptRenderer {
  const PromptRenderer();
  void attach(PromptModel<dynamic> model, {RegionId? region});
  void detach(PromptModel<dynamic> model);
}
