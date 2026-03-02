import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/sync/sync_service.dart';
import '../../../data/repositories/hive_subject_repository.dart';
import '../data/subject_repository.dart';
import '../domain/subject.dart';

/// Provides the SubjectRepository implementation.
final subjectRepositoryProvider = Provider<SubjectRepository>((ref) {
  return HiveSubjectRepository();
});

/// Async provider for the list of all subjects.
final subjectsProvider =
    AsyncNotifierProvider<SubjectsNotifier, List<Subject>>(
  SubjectsNotifier.new,
);

class SubjectsNotifier extends AsyncNotifier<List<Subject>> {
  SubjectRepository get _repo => ref.read(subjectRepositoryProvider);

  @override
  Future<List<Subject>> build() => _repo.getAll();

  Future<void> addSubject({
    required String name,
    String? room,
    List<SubjectDomain> domains = const [],
    double maxGrade = 20,
  }) async {
    final now = DateTime.now();
    final subject = Subject(
      id: _generateId(),
      name: name,
      room: room,
      domains: domains,
      maxGrade: maxGrade,
      createdAt: now,
      updatedAt: now,
    );
    await _repo.add(subject);
    ref.invalidateSelf();
    ref.read(syncServiceProvider).pushChanges();
  }

  Future<void> updateSubject(Subject subject) async {
    await _repo.update(subject.copyWith(updatedAt: DateTime.now()));
    ref.invalidateSelf();
    ref.read(syncServiceProvider).pushChanges();
  }

  Future<void> deleteSubject(String id) async {
    await _repo.delete(id);
    ref.invalidateSelf();
    ref.read(syncServiceProvider).pushChanges();
  }

  String _generateId() =>
      DateTime.now().microsecondsSinceEpoch.toRadixString(36);
}

/// Provider to get a single subject by ID.
final subjectByIdProvider =
    FutureProvider.family<Subject?, String>((ref, id) async {
  // Watch subjectsProvider to auto-refresh when subjects change
  await ref.watch(subjectsProvider.future);
  final repo = ref.watch(subjectRepositoryProvider);
  return repo.getById(id);
});
