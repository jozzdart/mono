import 'package:mono_core_logger/mono_core_logger.dart';

class ExceptionInfo {
  final String type;
  final String message;
  final List<StackFrame> frames;
  const ExceptionInfo(
      {required this.type,
      required this.message,
      this.frames = const <StackFrame>[]});
}

class StackFrame {
  final String library;
  final String member;
  final String? file;
  final int? line;
  final int? column;
  const StackFrame(this.library, this.member,
      {this.file, this.line, this.column});
}

class ErrorRecord extends LogRecord {
  final ExceptionInfo exception;

  const ErrorRecord({
    required this.exception,
    required super.timestamp,
    required super.level,
    required super.body,
    super.tags,
    super.category,
    super.fields,
    super.context,
  });
}
