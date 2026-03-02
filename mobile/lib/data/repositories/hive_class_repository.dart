import 'package:hive_flutter/hive_flutter.dart';

import '../../core/storage/local_db.dart';
import '../../core/sync/sync_queue.dart';
import '../../core/sync/sync_status.dart';
import '../../features/classes/data/class_repository.dart';
import '../../features/classes/domain/class_entry.dart';

class HiveClassRepository implements ClassRepository {
  Box<Map> get _box => LocalDb.classesBox;

  @override
  Future<List<ClassEntry>> getAll() async {
    return _box.values
        .map((map) => ClassEntry.fromMap(Map<String, dynamic>.from(map)))
        .where((c) => c.deletedAt == null) // filter out soft-deleted
        .toList()
      ..sort((a, b) => a.compareTo(b));
  }

  @override
  Future<ClassEntry?> getById(String id) async {
    final map = _box.get(id);
    if (map == null) return null;
    return ClassEntry.fromMap(Map<String, dynamic>.from(map));
  }

  @override
  Future<List<ClassEntry>> getBySubjectId(String subjectId) async {
    final all = await getAll();
    return all.where((e) => e.subjectId == subjectId).toList();
  }

  @override
  Future<List<ClassEntry>> getByDayOfWeek(int dayOfWeek) async {
    final all = await getAll();
    return all.where((e) => e.dayOfWeek == dayOfWeek).toList();
  }

  @override
  Future<void> add(ClassEntry entry) async {
    final e = entry.copyWith(syncStatus: SyncStatus.pendingUpload);
    await _box.put(e.id, e.toMap());
    await SyncQueue.enqueue(table: 'classes', recordId: e.id, action: 'upsert');
  }

  @override
  Future<void> update(ClassEntry entry) async {
    await _box.put(entry.id, entry.toMap());
    if (entry.syncStatus != SyncStatus.synced) {
      await SyncQueue.enqueue(table: 'classes', recordId: entry.id, action: 'upsert');
    }
  }

  @override
  Future<void> delete(String id) async {
    final map = _box.get(id);
    if (map != null) {
      final entry = ClassEntry.fromMap(Map<String, dynamic>.from(map));
      final deleted = entry.copyWith(
        deletedAt: DateTime.now(),
        updatedAt: DateTime.now(),
        syncStatus: SyncStatus.pendingUpload,
      );
      await _box.put(id, deleted.toMap());
      await SyncQueue.enqueue(table: 'classes', recordId: id, action: 'upsert');
    } else {
      await _box.delete(id);
    }
  }

  @override
  Future<void> deleteBySubjectId(String subjectId) async {
    final keys = _box.keys.where((key) {
      final map = _box.get(key);
      if (map == null) return false;
      return map['subjectId'] == subjectId;
    }).toList();
    for (final key in keys) {
      await delete(key as String);
    }
  }
}
