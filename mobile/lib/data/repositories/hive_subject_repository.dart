import 'package:hive_flutter/hive_flutter.dart';

import '../../core/storage/local_db.dart';
import '../../features/subjects/data/subject_repository.dart';
import '../../features/subjects/domain/subject.dart';

class HiveSubjectRepository implements SubjectRepository {
  Box<Map> get _box => LocalDb.subjectsBox;

  @override
  Future<List<Subject>> getAll() async {
    return _box.values
        .map((map) => Subject.fromMap(Map<String, dynamic>.from(map)))
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
    await _box.put(subject.id, subject.toMap());
  }

  @override
  Future<void> update(Subject subject) async {
    await _box.put(subject.id, subject.toMap());
  }

  @override
  Future<void> delete(String id) async {
    await _box.delete(id);
  }
}
