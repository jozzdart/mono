import '../lib/src/src.dart';

void main() {
  final commands = <CommandEntry>[
    const CommandEntry(id: 'workbench.action.files.newUntitledFile', title: 'File: New Untitled File', subtitle: 'Create a new file'),
    const CommandEntry(id: 'workbench.action.files.openFile', title: 'File: Open...', subtitle: 'Open a file from disk'),
    const CommandEntry(id: 'workbench.action.quickOpen', title: 'Go to File...', subtitle: 'Quickly open files by name'),
    const CommandEntry(id: 'workbench.action.showCommands', title: 'Show All Commands', subtitle: 'Display available commands'),
    const CommandEntry(id: 'editor.action.rename', title: 'Rename Symbol', subtitle: 'Change all references'),
    const CommandEntry(id: 'editor.action.formatDocument', title: 'Format Document', subtitle: 'Apply code formatter'),
    const CommandEntry(id: 'workbench.action.closeAllEditors', title: 'Close All Editors'),
    const CommandEntry(id: 'workbench.action.toggleZenMode', title: 'Toggle Zen Mode'),
    const CommandEntry(id: 'workbench.action.toggleSidebarVisibility', title: 'View: Toggle Sidebar Visibility'),
    const CommandEntry(id: 'git.pull', title: 'Git: Pull'),
    const CommandEntry(id: 'git.push', title: 'Git: Push'),
    const CommandEntry(id: 'git.commit', title: 'Git: Commit', subtitle: 'Commit staged changes'),
  ];

  final palette = CommandPalette(
    commands: commands,
    label: 'Command Palette',
    theme: PromptTheme.dark, // Try PromptTheme.matrix, .fire, .pastel
    maxVisible: 10,
  );

  final selected = palette.run();
  if (selected == null) {
    print('Cancelled.');
  } else {
    print('Selected: ' + selected.id + '  (' + selected.title + ')');
  }
}


