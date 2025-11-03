import 'renderables.dart';

/// Union for a log message body (text or renderable).
abstract class MessageBody {
  const MessageBody();
}

class TextMessage extends MessageBody {
  final String text;
  const TextMessage(this.text);
}

class RenderableMessage extends MessageBody {
  final Renderable renderable;
  const RenderableMessage(this.renderable);
}
