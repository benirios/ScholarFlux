import '../domain/subject.dart';

abstract class SubjectRepository {
  Future<List<Subject>> getAll();
  Future<Subject?> getById(String id);
  Future<void> add(Subject subject);
  Future<void> update(Subject subject);
  Future<void> delete(String id);
}
