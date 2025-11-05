import '../lib/src/src.dart';

void main() {
  final theme = PromptTheme.pastel;

  final tree = [
    TreeNode('apps', initiallyExpanded: true, children: [
      TreeNode('web', children: [
        TreeNode('lib', children: [
          TreeNode('components'),
          TreeNode('pages'),
        ]),
        TreeNode('test'),
      ]),
      TreeNode('mobile', children: [
        TreeNode('ios'),
        TreeNode('android'),
      ]),
    ]),
    TreeNode('packages', children: [
      TreeNode('core', initiallyExpanded: true, children: [
        TreeNode('src', children: [
          TreeNode('cli'),
          TreeNode('graph'),
        ]),
        TreeNode('test'),
      ]),
      TreeNode('ui'),
    ]),
    TreeNode('tools', children: [
      TreeNode('scripts'),
      TreeNode('formatters'),
    ]),
  ];

  final explorer = TreeExplorer(
    title: 'Tree Explorer',
    roots: tree,
    theme: theme,
    maxVisible: 10,
  );

  final result = explorer.run();
  if (result == null) {
    print('Cancelled.');
  } else {
    print('Selected: $result');
  }
}


