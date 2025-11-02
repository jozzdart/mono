import 'package:meta/meta.dart';

@immutable
abstract class NamePolicy {
  const NamePolicy();
  String normalize(String name);
  bool isValid(String name);
}

@immutable
abstract class ListConfigFolder {
  const ListConfigFolder();

  Future<List<String>> listNames();

  Future<List<String>> readList(String name);

  Future<void> writeList(String name, List<String> items);

  Future<void> delete(String name);

  Future<bool> exists(String name);
}

@immutable
abstract class GroupStore {
  const GroupStore();

  Future<List<String>> listGroups();

  Future<List<String>> readGroup(String groupName);

  Future<void> writeGroup(String groupName, List<String> members);

  Future<void> deleteGroup(String groupName);

  Future<bool> exists(String groupName);
}
