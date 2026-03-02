import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/subjects/domain/subject.dart';

/// Remote datasource for subjects using Supabase.
class SupabaseSubjectDatasource {
  final SupabaseClient _client;

  SupabaseSubjectDatasource(this._client);

  /// Convert local Subject model to Supabase row (snake_case).
  Map<String, dynamic> _toRow(Subject subject, String userId) => {
        'id': subject.id,
        'user_id': userId,
        'name': subject.name,
        'room': subject.room,
        'domains': subject.domains.map((d) => d.toMap()).toList(),
        'max_grade': subject.maxGrade,
        'created_at': subject.createdAt.toUtc().toIso8601String(),
        'updated_at': subject.updatedAt.toUtc().toIso8601String(),
        'deleted_at': subject.deletedAt?.toUtc().toIso8601String(),
      };

  /// Convert Supabase row to local Subject model.
  Subject _fromRow(Map<String, dynamic> row) => Subject(
        id: row['id'] as String,
        name: row['name'] as String,
        room: row['room'] as String?,
        domains: (row['domains'] as List<dynamic>?)
                ?.map((d) =>
                    SubjectDomain.fromMap(Map<String, dynamic>.from(d as Map)))
                .toList() ??
            [],
        maxGrade: (row['max_grade'] as num?)?.toDouble() ?? 20,
        createdAt: DateTime.parse(row['created_at'] as String),
        updatedAt: DateTime.parse(row['updated_at'] as String),
        deletedAt: row['deleted_at'] != null
            ? DateTime.parse(row['deleted_at'] as String)
            : null,
      );

  /// Fetch all subjects for the current user (including soft-deleted).
  Future<List<Subject>> getAll(String userId) async {
    final response = await _client
        .from('subjects')
        .select()
        .eq('user_id', userId)
        .order('updated_at', ascending: false);
    return (response as List).map((r) => _fromRow(r)).toList();
  }

  /// Fetch subjects modified after a given timestamp.
  Future<List<Subject>> getModifiedSince(
      String userId, DateTime since) async {
    final response = await _client
        .from('subjects')
        .select()
        .eq('user_id', userId)
        .gt('updated_at', since.toUtc().toIso8601String())
        .order('updated_at', ascending: false);
    return (response as List).map((r) => _fromRow(r)).toList();
  }

  /// Upsert a subject (insert or update based on ID).
  Future<void> upsert(Subject subject, String userId) async {
    await _client.from('subjects').upsert(_toRow(subject, userId));
  }

  /// Upsert multiple subjects in a batch.
  Future<void> upsertBatch(List<Subject> subjects, String userId) async {
    if (subjects.isEmpty) return;
    final rows = subjects.map((s) => _toRow(s, userId)).toList();
    await _client.from('subjects').upsert(rows);
  }

  /// Hard delete a subject (for cleanup after confirmed sync).
  Future<void> hardDelete(String id) async {
    await _client.from('subjects').delete().eq('id', id);
  }
}
