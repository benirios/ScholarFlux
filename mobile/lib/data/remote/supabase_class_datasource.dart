import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/classes/domain/class_entry.dart';

/// Remote datasource for classes using Supabase.
class SupabaseClassDatasource {
  final SupabaseClient _client;

  SupabaseClassDatasource(this._client);

  Map<String, dynamic> _toRow(ClassEntry entry, String userId) => {
        'id': entry.id,
        'user_id': userId,
        'subject_id': entry.subjectId,
        'day_of_week': entry.dayOfWeek,
        'start_time': entry.startTime,
        'end_time': entry.endTime,
        'room': entry.room,
        'floor': entry.floor,
        'teacher': entry.teacher,
        'created_at': entry.createdAt.toUtc().toIso8601String(),
        'updated_at': entry.updatedAt.toUtc().toIso8601String(),
        'deleted_at': entry.deletedAt?.toUtc().toIso8601String(),
      };

  ClassEntry _fromRow(Map<String, dynamic> row) => ClassEntry(
        id: row['id'] as String,
        subjectId: row['subject_id'] as String,
        dayOfWeek: row['day_of_week'] as int,
        startTime: row['start_time'] as String,
        endTime: row['end_time'] as String,
        room: row['room'] as String?,
        floor: row['floor'] as String?,
        teacher: row['teacher'] as String?,
        createdAt: DateTime.parse(row['created_at'] as String),
        updatedAt: DateTime.parse(row['updated_at'] as String),
        deletedAt: row['deleted_at'] != null
            ? DateTime.parse(row['deleted_at'] as String)
            : null,
      );

  Future<List<ClassEntry>> getAll(String userId) async {
    final response = await _client
        .from('classes')
        .select()
        .eq('user_id', userId)
        .order('updated_at', ascending: false);
    return (response as List).map((r) => _fromRow(r)).toList();
  }

  Future<List<ClassEntry>> getModifiedSince(
      String userId, DateTime since) async {
    final response = await _client
        .from('classes')
        .select()
        .eq('user_id', userId)
        .gt('updated_at', since.toUtc().toIso8601String())
        .order('updated_at', ascending: false);
    return (response as List).map((r) => _fromRow(r)).toList();
  }

  Future<void> upsert(ClassEntry entry, String userId) async {
    await _client.from('classes').upsert(_toRow(entry, userId));
  }

  Future<void> upsertBatch(List<ClassEntry> entries, String userId) async {
    if (entries.isEmpty) return;
    final rows = entries.map((e) => _toRow(e, userId)).toList();
    await _client.from('classes').upsert(rows);
  }

  Future<void> hardDelete(String id) async {
    await _client.from('classes').delete().eq('id', id);
  }
}
