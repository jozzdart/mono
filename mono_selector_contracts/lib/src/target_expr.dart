import 'package:meta/meta.dart';

@immutable
sealed class TargetExpr {
  const TargetExpr();
}

class TargetAll extends TargetExpr {
  const TargetAll();
}

class TargetPackage extends TargetExpr {
  const TargetPackage(this.name);
  final String name;
}

class TargetGroup extends TargetExpr {
  const TargetGroup(this.groupName);
  final String groupName;
}

class TargetGlob extends TargetExpr {
  const TargetGlob(this.pattern);
  final String pattern;
}

