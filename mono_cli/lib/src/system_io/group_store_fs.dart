import 'package:mono_core/mono_core.dart';

class FileGroupStore implements GroupStore {
  FileGroupStore(this._folder);

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
}
