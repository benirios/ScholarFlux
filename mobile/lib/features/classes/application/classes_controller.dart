import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/sync/sync_service.dart';
import '../../../data/repositories/hive_class_repository.dart';
import '../data/class_repository.dart';
import '../domain/class_entry.dart';

/// Provides the ClassRepository implementation.
final classRepositoryProvider = Provider<ClassRepository>((ref) {
  return HiveClassRepository();
});

/// Async provider for all class entries.
final classesProvider =
    AsyncNotifierProvider<ClassesNotifier, List<ClassEntry>>(
        ClassesNotifier.new);

class ClassesNotifier extends AsyncNotifier<List<ClassEntry>> {
  ClassRepository get _repo => ref.read(classRepositoryProvider);

  @override
  Future<List<ClassEntry>> build() => _repo.getAll();

  Future<void> addClass({
    required String subjectId,
    required int dayOfWeek,
    required String startTime,
    required String endTime,
    String? room,
    String? floor,
    String? teacher,
  }) async {
    final now = DateTime.now();
    final entry = ClassEntry(
      id: _generateId(),
      subjectId: subjectId,
      dayOfWeek: dayOfWeek,
      startTime: startTime,
      endTime: endTime,
      room: room,
      floor: floor,
      teacher: teacher,
      createdAt: now,
      updatedAt: now,
    );
    await _repo.add(entry);
    ref.invalidateSelf();
    ref.read(syncServiceProvider).pushChanges();
  }

  Future<void> updateClass(ClassEntry entry) async {
    await _repo.update(entry.copyWith(updatedAt: DateTime.now()));
    ref.invalidateSelf();
    ref.read(syncServiceProvider).pushChanges();
  }

  Future<void> deleteClass(String id) async {
    await _repo.delete(id);
    ref.invalidateSelf();
    ref.read(syncServiceProvider).pushChanges();
  }

  Future<void> deleteClassesBySubject(String subjectId) async {
    await _repo.deleteBySubjectId(subjectId);
    ref.invalidateSelf();
    ref.read(syncServiceProvider).pushChanges();
  }

  String _generateId() =>
      DateTime.now().microsecondsSinceEpoch.toRadixString(36);
}

/// Classes filtered by day of week.
final classesByDayProvider =
    FutureProvider.family<List<ClassEntry>, int>((ref, dayOfWeek) async {
  final classes = await ref.watch(classesProvider.future);
  return classes.where((c) => c.dayOfWeek == dayOfWeek).toList()
    ..sort((a, b) => a.compareTo(b));
});

/// Classes filtered by subject.
final classesBySubjectProvider =
    FutureProvider.family<List<ClassEntry>, String>((ref, subjectId) async {
  final classes = await ref.watch(classesProvider.future);
  return classes.where((c) => c.subjectId == subjectId).toList()
    ..sort((a, b) => a.compareTo(b));
});

/// Today's classes.
final todayClassesProvider = FutureProvider<List<ClassEntry>>((ref) async {
  final classes = await ref.watch(classesProvider.future);
  final today = DateTime.now().weekday;
  return classes.where((c) => c.dayOfWeek == today).toList()
    ..sort((a, b) => a.compareTo(b));
});

/// Single class by ID.
final classByIdProvider =
    FutureProvider.family<ClassEntry?, String>((ref, id) async {
  await ref.watch(classesProvider.future);
  final repo = ref.watch(classRepositoryProvider);
  return repo.getById(id);
});
