import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/hive_item_repository.dart';
import '../data/item_repository.dart';
import '../domain/item.dart';
import '../domain/item_type.dart';

/// Provides the ItemRepository implementation.
final itemRepositoryProvider = Provider<ItemRepository>((ref) {
  return HiveItemRepository();
});

/// Async provider for all items.
final itemsProvider =
    AsyncNotifierProvider<ItemsNotifier, List<Item>>(ItemsNotifier.new);

class ItemsNotifier extends AsyncNotifier<List<Item>> {
  ItemRepository get _repo => ref.read(itemRepositoryProvider);

  @override
  Future<List<Item>> build() => _repo.getAll();

  Future<void> addItem({
    required String subjectId,
    required String title,
    required ItemType type,
    String description = '',
    DateTime? dueDate,
    ItemPriority priority = ItemPriority.medium,
    String? origin,
    double? weight,
    double? grade,
    String? domainId,
  }) async {
    final now = DateTime.now();
    final item = Item(
      id: _generateId(),
      subjectId: subjectId,
      title: title,
      type: type,
      description: description,
      dueDate: dueDate,
      priority: priority,
      origin: origin,
      weight: weight,
      grade: grade,
      domainId: domainId,
      createdAt: now,
      updatedAt: now,
    );
    await _repo.add(item);
    ref.invalidateSelf();
  }

  Future<void> updateItem(Item item) async {
    await _repo.update(item.copyWith(updatedAt: DateTime.now()));
    ref.invalidateSelf();
  }

  Future<void> deleteItem(String id) async {
    await _repo.delete(id);
    ref.invalidateSelf();
  }

  Future<void> toggleComplete(Item item) async {
    final updated = item.copyWith(
      status: item.isCompleted ? ItemStatus.pending : ItemStatus.completed,
      updatedAt: DateTime.now(),
    );
    await _repo.update(updated);
    ref.invalidateSelf();
  }

  Future<void> deleteItemsBySubject(String subjectId) async {
    await _repo.deleteBySubjectId(subjectId);
    ref.invalidateSelf();
  }

  String _generateId() =>
      DateTime.now().microsecondsSinceEpoch.toRadixString(36);
}

/// Items filtered by subject.
final itemsBySubjectProvider =
    FutureProvider.family<List<Item>, String>((ref, subjectId) async {
  // Watch itemsProvider to auto-refresh when items change
  await ref.watch(itemsProvider.future);
  final repo = ref.watch(itemRepositoryProvider);
  return repo.getBySubjectId(subjectId);
});

/// Single item by ID.
final itemByIdProvider =
    FutureProvider.family<Item?, String>((ref, id) async {
  // Watch itemsProvider to auto-refresh when items change
  await ref.watch(itemsProvider.future);
  final repo = ref.watch(itemRepositoryProvider);
  return repo.getById(id);
});

/// Upcoming items (due within 7 days, not completed).
final upcomingItemsProvider = FutureProvider<List<Item>>((ref) async {
  final items = await ref.watch(itemsProvider.future);
  return items.where((item) => item.isUpcoming).toList();
});

/// Overdue items.
final overdueItemsProvider = FutureProvider<List<Item>>((ref) async {
  final items = await ref.watch(itemsProvider.future);
  return items.where((item) => item.isOverdue).toList();
});

/// Future items (due beyond 7 days, not completed).
final futureItemsProvider = FutureProvider<List<Item>>((ref) async {
  final items = await ref.watch(itemsProvider.future);
  final now = DateTime.now();
  return items
      .where((item) =>
          item.status == ItemStatus.pending &&
          item.dueDate != null &&
          item.dueDate!.isAfter(now) &&
          item.dueDate!.difference(now).inDays > 7)
      .toList();
});

/// Items due in a specific month/year.
final itemsByMonthProvider =
    FutureProvider.family<List<Item>, ({int year, int month})>(
        (ref, params) async {
  final items = await ref.watch(itemsProvider.future);
  return items
      .where((item) =>
          item.dueDate != null &&
          item.dueDate!.year == params.year &&
          item.dueDate!.month == params.month)
      .toList()
    ..sort((a, b) => a.dueDate!.compareTo(b.dueDate!));
});

/// Items due on a specific date.
final itemsByDateProvider =
    FutureProvider.family<List<Item>, DateTime>((ref, date) async {
  final items = await ref.watch(itemsProvider.future);
  return items
      .where((item) =>
          item.dueDate != null &&
          item.dueDate!.year == date.year &&
          item.dueDate!.month == date.month &&
          item.dueDate!.day == date.day)
      .toList()
    ..sort((a, b) => a.dueDate!.compareTo(b.dueDate!));
});
