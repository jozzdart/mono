import 'package:mono_cli/mono_cli.dart';

import 'package:mono_core/mono_core.dart';

class FileGroupStore implements GroupStore {
  const FileGroupStore(this._folder);

  final ListConfigFolder _folder;

  @override
  Future<void> deleteGroup(String groupName) => _folder.delete(groupName);

  @override
  Future<bool> exists(String groupName) => _folder.exists(groupName);

  @override
  Future<List<String>> listGroups() => _folder.listNames();

  @override
  Future<List<String>> readGroup(String groupName) =>
      _folder.readList(groupName);

  @override
  Future<void> writeGroup(String groupName, List<String> members) =>
      _folder.writeList(groupName, members);

  static Future<FileGroupStore> create({
    required LoadedRootConfig loadedRootConfig,
    required PathService pathService,
  }) async {
    final groupsPath =
        pathService.join([loadedRootConfig.monocfgPath, 'groups']);
    final folder = FileListConfigFolder(
      basePath: groupsPath,
    );
    return FileGroupStore(folder);
  }

  static Future<FileGroupStore> createFromContext(CliContext context) async {
    return await create(
      pathService: context.pathService,
      loadedRootConfig: await context.workspaceConfig.loadRootConfig(),
    );
  }
}
