/// Hint for implementations to throttle UI updates to avoid flicker.
abstract class UpdateRateController {
  /// Returns true if an update should be emitted at the provided time.
  bool shouldEmit(DateTime now);
}
