abstract class MonoError implements Exception {
  String get message;
  @override
  String toString() => message;
}

class ValidationError extends MonoError {
  ValidationError(this.message);
  @override
  final String message;
}

class SelectionError extends MonoError {
  SelectionError(this.message);
  @override
  final String message;
}

class GraphCycleError extends MonoError {
  GraphCycleError(this.message, {this.cycle});
  @override
  final String message;
  final List<String>? cycle;
}

