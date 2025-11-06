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


