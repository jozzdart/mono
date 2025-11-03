import '../renderables.dart';

class TreeNode {
  final String label;
  final List<TreeNode> children;
  final bool collapsed;
  const TreeNode(this.label,
      {this.children = const <TreeNode>[], this.collapsed = false});
}

class TreeRenderable extends Renderable {
  final TreeNode root;
  const TreeRenderable(this.root);
}
