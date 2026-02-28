import 'package:hive_flutter/hive_flutter.dart';

import '../../core/storage/local_db.dart';
import '../../features/items/data/item_repository.dart';
import '../../features/items/domain/item.dart';

class HiveItemRepository implements ItemRepository {
  Box<Map> get _box => LocalDb.itemsBox;

  @override
  Future<List<Item>> getAll() async {
    return _box.values
        .map((map) => Item.fromMap(Map<String, dynamic>.from(map)))
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
    await _box.put(item.id, item.toMap());
  }

  @override
  Future<void> update(Item item) async {
    await _box.put(item.id, item.toMap());
  }

  @override
  Future<void> delete(String id) async {
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
      await _box.delete(key);
    }
  }
}
