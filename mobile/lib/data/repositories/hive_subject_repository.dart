import 'package:hive_flutter/hive_flutter.dart';

import '../../core/storage/local_db.dart';
import '../../core/sync/sync_queue.dart';
import '../../core/sync/sync_status.dart';
import '../../features/subjects/data/subject_repository.dart';
import '../../features/subjects/domain/subject.dart';

class HiveSubjectRepository implements SubjectRepository {
  Box<Map> get _box => LocalDb.subjectsBox;

  @override
  Future<List<Subject>> getAll() async {
    return _box.values
        .map((map) => Subject.fromMap(Map<String, dynamic>.from(map)))
        .where((s) => s.deletedAt == null) // filter out soft-deleted
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  @override
  Future<Subject?> getById(String id) async {
    final map = _box.get(id);
    if (map == null) return null;
    return Subject.fromMap(Map<String, dynamic>.from(map));
  }

  @override
  Future<void> add(Subject subject) async {
    final s = subject.copyWith(syncStatus: SyncStatus.pendingUpload);
    await _box.put(s.id, s.toMap());
    await SyncQueue.enqueue(table: 'subjects', recordId: s.id, action: 'upsert');
  }

  @override
  Future<void> update(Subject subject) async {
    await _box.put(subject.id, subject.toMap());
    if (subject.syncStatus != SyncStatus.synced) {
      await SyncQueue.enqueue(table: 'subjects', recordId: subject.id, action: 'upsert');
    }
  }

  @override
  Future<void> delete(String id) async {
    // Soft delete: mark with deletedAt and enqueue sync
    final map = _box.get(id);
    if (map != null) {
      final subject = Subject.fromMap(Map<String, dynamic>.from(map));
      final deleted = subject.copyWith(
        deletedAt: DateTime.now(),
        updatedAt: DateTime.now(),
        syncStatus: SyncStatus.pendingUpload,
      );
      await _box.put(id, deleted.toMap());
      await SyncQueue.enqueue(table: 'subjects', recordId: id, action: 'upsert');
    } else {
      await _box.delete(id);
    }
  }
}
