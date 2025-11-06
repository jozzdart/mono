class Scheduler {
  static final Scheduler instance = Scheduler._();
  Scheduler._();

  bool _frameScheduled = false;

  /// Requests a frame; coalesces multiple requests into a single microtask.
  void requestFrame(void Function() onFrame) {
    if (_frameScheduled) return;
    _frameScheduled = true;
    Future.microtask(() {
      _frameScheduled = false;
      onFrame();
    });
  }
}


class AppFramePump {
  static final AppFramePump instance = AppFramePump._();
  AppFramePump._();

  void Function()? _pump;

  void bind(void Function() pump) {
    _pump = pump;
  }

  void request() {
    final p = _pump;
    if (p != null) {
      Scheduler.instance.requestFrame(p);
    }
  }
}

