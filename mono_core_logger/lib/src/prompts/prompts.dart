/// Prompt contracts (no actual IO/terminal interaction here).
abstract class PromptDriver {
  Future<bool> confirm(String message, {bool initialValue = false});
  Future<T> select<T>(String message, List<T> options, {T? initial});
  Future<String> input(String message, {String? initial, bool secret = false});
}
