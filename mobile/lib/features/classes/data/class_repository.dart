import '../domain/class_entry.dart';

/// Abstract interface for class entry persistence.
abstract class ClassRepository {
  Future<List<ClassEntry>> getAll();
  Future<ClassEntry?> getById(String id);
  Future<List<ClassEntry>> getBySubjectId(String subjectId);
  Future<List<ClassEntry>> getByDayOfWeek(int dayOfWeek);
  Future<void> add(ClassEntry entry);
  Future<void> update(ClassEntry entry);
  Future<void> delete(String id);
  Future<void> deleteBySubjectId(String subjectId);
}
