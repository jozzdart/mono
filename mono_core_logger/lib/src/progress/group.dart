import '../progress.dart';

/// Represents a group of related progress tasks (nesting/aggregation hint).
abstract class ProgressGroupHandle {
  String get groupId;
  ProgressHandle startChild(String label, {double? initialFraction});
  void finish({bool success = true});
}
