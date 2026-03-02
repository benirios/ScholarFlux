import 'package:hive_flutter/hive_flutter.dart';

import '../../core/storage/local_db.dart';
import '../../core/sync/sync_queue.dart';
import '../../core/sync/sync_status.dart';
import '../../features/items/data/item_repository.dart';
import '../../features/items/domain/item.dart';

class HiveItemRepository implements ItemRepository {
  Box<Map> get _box => LocalDb.itemsBox;

  @override
  Future<List<Item>> getAll() async {
    return _box.values
        .map((map) => Item.fromMap(Map<String, dynamic>.from(map)))
        .where((i) => i.deletedAt == null) // filter out soft-deleted
        .toList()
      ..sort((a, b) {
        // Sort: pending first, then by due date
        if (a.status != b.status) {
          return a.status.index.compareTo(b.status.index);
        }
        if (a.dueDate == null && b.dueDate == null) return 0;
        if (a.dueDate == null) return 1;
        if (b.dueDate == null) return -1;
        return a.dueDate!.compareTo(b.dueDate!);
      });
  }

  /// Get ALL items including soft-deleted (for sync push).
  List<Item> getAllIncludingDeleted() {
    return _box.values
        .map((map) => Item.fromMap(Map<String, dynamic>.from(map)))
        .toList();
  }

  @override
  Future<List<Item>> getBySubjectId(String subjectId) async {
    final all = await getAll();
    return all.where((item) => item.subjectId == subjectId).toList();
  }

  @override
  Future<Item?> getById(String id) async {
    final map = _box.get(id);
    if (map == null) return null;
    return Item.fromMap(Map<String, dynamic>.from(map));
  }

  @override
  Future<void> add(Item item) async {
    final i = item.copyWith(syncStatus: SyncStatus.pendingUpload);
    await _box.put(i.id, i.toMap());
    await SyncQueue.enqueue(table: 'items', recordId: i.id, action: 'upsert');
  }

  @override
  Future<void> update(Item item) async {
    await _box.put(item.id, item.toMap());
    if (item.syncStatus != SyncStatus.synced) {
      await SyncQueue.enqueue(table: 'items', recordId: item.id, action: 'upsert');
    }
  }

  @override
  Future<void> delete(String id) async {
    final map = _box.get(id);
    if (map != null) {
      final item = Item.fromMap(Map<String, dynamic>.from(map));
      final deleted = item.copyWith(
        deletedAt: DateTime.now(),
        updatedAt: DateTime.now(),
        syncStatus: SyncStatus.pendingUpload,
      );
      await _box.put(id, deleted.toMap());
      await SyncQueue.enqueue(table: 'items', recordId: id, action: 'upsert');
    } else {
      await _box.delete(id);
    }
  }

  /// Hard delete from Hive (used by sync when remote says deleted).
  Future<void> hardDelete(String id) async {
    await _box.delete(id);
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
