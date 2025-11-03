import 'package:mono_core_logger/mono_core_logger.dart';

/// Represents a group of related progress tasks (nesting/aggregation hint).
abstract class ProgressGroupHandle {
  String get groupId;
  ProgressHandle startChild(String label, {double? initialFraction});
  void finish({bool success = true});
}
