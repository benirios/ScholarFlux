import '../domain/item.dart';

abstract class ItemRepository {
  Future<List<Item>> getAll();
  Future<List<Item>> getBySubjectId(String subjectId);
  Future<Item?> getById(String id);
  Future<void> add(Item item);
  Future<void> update(Item item);
  Future<void> delete(String id);
  Future<void> deleteBySubjectId(String subjectId);
}
