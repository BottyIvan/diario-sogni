import 'package:sembast/sembast.dart';

import 'dart:math';

import 'dream.dart';

class DreamRepository {
  DreamRepository(this.database);
  final Database database;
  final _store = stringMapStoreFactory.store('dreams');
  final _versions = stringMapStoreFactory.store('archive_versions');
  final _deleted = stringMapStoreFactory.store('deleted_dreams');
  final _random = Random.secure();

  Future<String> _nextVersion(Transaction txn, String id) async {
    final previous = await _versions.record(id).get(txn);
    final last =
        int.tryParse(
          (previous?['version'] as String? ?? '').split('-').first,
        ) ??
        0;
    final time = max(DateTime.now().microsecondsSinceEpoch, last + 1);
    return '${time.toString().padLeft(20, '0')}-${_random.nextInt(0x7fffffff).toRadixString(16)}';
  }

  Future<bool> isDeleted(String id) async =>
      await _deleted.record(id).exists(database);

  // Keep only an ID and a pending local cleanup path, never the dream text.
  // The marker prevents a stale editor or an offline device resurrecting a dream.
  Future<void> markDeleted(String id) => database.transaction((txn) async {
    final current = await _store.record(id).get(txn);
    final existing = await _deleted.record(id).get(txn);
    await _deleted.record(id).put(txn, {
      'audio': current?['audio'] ?? existing?['audio'] ?? '',
    });
    await _store.record(id).delete(txn);
    await _versions.record(id).delete(txn);
  });

  Future<Map<String, String>> deletions() async => {
    for (final row in await _deleted.find(database))
      row.key: row.value['audio'] as String? ?? '',
  };

  Future<void> finishDeletion(String id) async {
    await _deleted.record(id).put(database, {'audio': ''});
  }

  Future<String> versionFor(Dream dream) => database.transaction((txn) async {
    final value = await _versions.record(dream.id).get(txn);
    if (value != null) return value['version'] as String;
    final version = await _nextVersion(txn, dream.id);
    await _versions.record(dream.id).put(txn, {'version': version});
    return version;
  });

  Future<List<({Dream dream, String version})>> archiveSnapshot() =>
      database.transaction((txn) async {
        final rows = await _store.find(txn);
        final result = <({Dream dream, String version})>[];
        for (final row in rows) {
          final previous = await _versions.record(row.key).get(txn);
          final version =
              previous?['version'] as String? ??
              await _nextVersion(txn, row.key);
          await _versions.record(row.key).put(txn, {'version': version});
          result.add((
            dream: Dream.fromMap(row.key, row.value),
            version: version,
          ));
        }
        return result;
      });

  Future<bool> importVersion(Dream dream, String version) =>
      database.transaction((txn) async {
        if (await _deleted.record(dream.id).exists(txn)) return false;
        final current = await _versions.record(dream.id).get(txn);
        if (current != null &&
            (current['version'] as String).compareTo(version) >= 0) {
          return false;
        }
        await _store.record(dream.id).put(txn, dream.toMap());
        await _versions.record(dream.id).put(txn, {'version': version});
        return true;
      });
  Future<Dream?> get(String id) async {
    final record = await _store.record(id).get(database);
    return record == null ? null : Dream.fromMap(id, record);
  }

  Future<Dream?> applyAutomaticTranscript(String id, String text) =>
      database.transaction((txn) async {
        final record = await _store.record(id).get(txn);
        if (record == null) return null;
        final updated = Dream.fromMap(
          id,
          record,
        ).withAutomaticTranscript(text.trim());
        await _store.record(id).put(txn, updated.toMap());
        await _versions.record(id).put(txn, {
          'version': await _nextVersion(txn, id),
        });
        return updated;
      });
  Future<List<Dream>> load() async {
    final records = await _store.find(database);
    final dreams = records.map((r) => Dream.fromMap(r.key, r.value)).toList();
    dreams.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return dreams;
  }

  Future<void> save(Dream dream) async {
    await database.transaction((txn) async {
      if (await _deleted.record(dream.id).exists(txn)) {
        throw StateError('Sogno eliminato');
      }
      final current = await _store.record(dream.id).get(txn);
      final automatic = current?['automaticTranscript'] as String?;
      final merged = automatic == null
          ? dream
          : dream.withAutomaticTranscript(automatic);
      await _store.record(dream.id).put(txn, merged.toMap());
      await _versions.record(dream.id).put(txn, {
        'version': await _nextVersion(txn, dream.id),
      });
    });
  }
}
