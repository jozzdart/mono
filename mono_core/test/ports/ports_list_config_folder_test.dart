import 'package:mono_core/mono_core.dart';
import 'package:test/test.dart';

class InMemoryListConfigFolder implements ListConfigFolder {
  final Map<String, List<String>> _lists = <String, List<String>>{};

  @override
  Future<void> delete(String name) async {
    _lists.remove(name);
  }

  @override
  Future<bool> exists(String name) async => _lists.containsKey(name);

  @override
  Future<List<String>> listNames() async => _lists.keys.toList()..sort();

  @override
  Future<List<String>> readList(String name) async =>
      List<String>.unmodifiable(_lists[name] ?? const <String>[]);

  @override
  Future<void> writeList(String name, List<String> items) async {
    _lists[name] = List<String>.from(items);
  }
}

class InMemoryGroupStore implements GroupStore {
  final Map<String, List<String>> _groups = <String, List<String>>{};

  @override
  Future<void> deleteGroup(String groupName) async {
    _groups.remove(groupName);
  }

  @override
  Future<bool> exists(String groupName) async => _groups.containsKey(groupName);

  @override
  Future<List<String>> listGroups() async => _groups.keys.toList()..sort();

  @override
  Future<List<String>> readGroup(String groupName) async =>
      List<String>.unmodifiable(_groups[groupName] ?? const <String>[]);

  @override
  Future<void> writeGroup(String groupName, List<String> members) async {
    _groups[groupName] = List<String>.from(members);
  }
}

void main() {
  group('ListConfigFolder', () {
    test('write, exists, read, overwrite, delete', () async {
      final store = InMemoryListConfigFolder();

      expect(await store.exists('tools'), isFalse);
      await store.writeList('tools', ['a', 'b']);
      expect(await store.exists('tools'), isTrue);
      expect(await store.readList('tools'), ['a', 'b']);

      await store.writeList('tools', ['c']);
      expect(await store.readList('tools'), ['c']);

      await store.writeList('other', ['x']);
      final names = await store.listNames();
      expect(names, containsAll(['other', 'tools']));

      await store.delete('tools');
      expect(await store.exists('tools'), isFalse);
      expect(await store.readList('tools'), isEmpty);
    });
  });

  group('GroupStore', () {
    test('write, exists, read, overwrite, delete', () async {
      final gs = InMemoryGroupStore();

      expect(await gs.exists('devs'), isFalse);
      await gs.writeGroup('devs', ['alice', 'bob']);
      expect(await gs.exists('devs'), isTrue);
      expect(await gs.readGroup('devs'), ['alice', 'bob']);

      await gs.writeGroup('devs', ['carol']);
      expect(await gs.readGroup('devs'), ['carol']);

      await gs.writeGroup('qa', ['zoe']);
      final groups = await gs.listGroups();
      expect(groups, containsAll(['devs', 'qa']));

      await gs.deleteGroup('devs');
      expect(await gs.exists('devs'), isFalse);
      expect(await gs.readGroup('devs'), isEmpty);
    });
  });
}
