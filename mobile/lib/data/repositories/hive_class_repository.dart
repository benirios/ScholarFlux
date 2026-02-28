import 'package:hive_flutter/hive_flutter.dart';

import '../../core/storage/local_db.dart';
import '../../features/classes/data/class_repository.dart';
import '../../features/classes/domain/class_entry.dart';

class HiveClassRepository implements ClassRepository {
  Box<Map> get _box => LocalDb.classesBox;

  @override
  Future<List<ClassEntry>> getAll() async {
    return _box.values
        .map((map) => ClassEntry.fromMap(Map<String, dynamic>.from(map)))
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
    await _box.put(entry.id, entry.toMap());
  }

  @override
  Future<void> update(ClassEntry entry) async {
    await _box.put(entry.id, entry.toMap());
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
