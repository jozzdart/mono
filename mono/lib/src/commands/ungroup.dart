import 'dart:io';

import 'package:mono_cli/mono_cli.dart';

import '../config_io.dart';

class UngroupCommand {
  static Future<int> run({
    required CliInvocation inv,
    required IOSink out,
    required IOSink err,
    required Prompter prompter,
    GroupStore Function(String monocfgPath)? groupStoreFactory,
  }) async {
    if (inv.positionals.isEmpty) {
      err.writeln('Usage: mono ungroup <group_name>');
      return 2;
    }
    final groupName = inv.positionals.first.trim();
    if (groupName.isEmpty || groupName.startsWith(':')) {
      err.writeln('Invalid group name: "$groupName"');
      return 2;
    }

    final loaded = await loadRootConfig();
    final store = (groupStoreFactory ??
        (String monocfgPath) {
          final groupsPath =
              const DefaultPathService().join([monocfgPath, 'groups']);
          final folder = FileListConfigFolder(
            basePath: groupsPath,
            namePolicy: const DefaultSlugNamePolicy(),
          );
          return FileGroupStore(folder);
        })(loaded.monocfgPath);
    if (!await store.exists(groupName)) {
      err.writeln('Group "$groupName" does not exist.');
      return 2;
    }

    final ok = await prompter.confirm(
      'Remove group "$groupName"? This cannot be undone.',
      defaultValue: false,
    );
    if (!ok) {
      err.writeln('Aborted.');
      return 1;
    }

    await store.deleteGroup(groupName);
    out.writeln('Group "$groupName" removed.');
    return 0;
  }
}
