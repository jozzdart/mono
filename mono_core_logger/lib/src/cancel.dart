abstract class CancelToken {
  bool get isCancelled;
  Object? get reason;
  Stream<void> get onCancel;
}
