import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/items/domain/item.dart';
import '../../features/items/domain/item_type.dart';

/// Remote datasource for items using Supabase.
class SupabaseItemDatasource {
  final SupabaseClient _client;

  SupabaseItemDatasource(this._client);

  Map<String, dynamic> _toRow(Item item, String userId) => {
        'id': item.id,
        'user_id': userId,
        'subject_id': item.subjectId,
        'title': item.title,
        'type': item.type.name,
        'description': item.description,
        'due_date': item.dueDate?.toUtc().toIso8601String(),
        'priority': item.priority.name,
        'status': item.status.name,
        'grade': item.grade,
        'domain_id': item.domainId,
        'origin': item.origin,
        'weight': item.weight,
        'created_at': item.createdAt.toUtc().toIso8601String(),
        'updated_at': item.updatedAt.toUtc().toIso8601String(),
        'deleted_at': item.deletedAt?.toUtc().toIso8601String(),
      };

  Item _fromRow(Map<String, dynamic> row) => Item(
        id: row['id'] as String,
        subjectId: row['subject_id'] as String,
        title: row['title'] as String,
        type: ItemType.fromString(row['type'] as String),
        description: row['description'] as String? ?? '',
        dueDate: row['due_date'] != null
            ? DateTime.parse(row['due_date'] as String)
            : null,
        priority: ItemPriority.values.firstWhere(
          (e) => e.name == row['priority'],
          orElse: () => ItemPriority.medium,
        ),
        status: ItemStatus.values.firstWhere(
          (e) => e.name == row['status'],
          orElse: () => ItemStatus.pending,
        ),
        grade: (row['grade'] as num?)?.toDouble(),
        domainId: row['domain_id'] as String?,
        origin: row['origin'] as String?,
        weight: (row['weight'] as num?)?.toDouble(),
        createdAt: DateTime.parse(row['created_at'] as String),
        updatedAt: DateTime.parse(row['updated_at'] as String),
        deletedAt: row['deleted_at'] != null
            ? DateTime.parse(row['deleted_at'] as String)
            : null,
      );

  Future<List<Item>> getAll(String userId) async {
    final response = await _client
        .from('items')
        .select()
        .eq('user_id', userId)
        .order('updated_at', ascending: false);
    return (response as List).map((r) => _fromRow(r)).toList();
  }

  Future<List<Item>> getModifiedSince(String userId, DateTime since) async {
    final response = await _client
        .from('items')
        .select()
        .eq('user_id', userId)
        .gt('updated_at', since.toUtc().toIso8601String())
        .order('updated_at', ascending: false);
    return (response as List).map((r) => _fromRow(r)).toList();
  }

  Future<void> upsert(Item item, String userId) async {
    await _client.from('items').upsert(_toRow(item, userId));
  }

  Future<void> upsertBatch(List<Item> items, String userId) async {
    if (items.isEmpty) return;
    final rows = items.map((i) => _toRow(i, userId)).toList();
    await _client.from('items').upsert(rows);
  }

  Future<void> hardDelete(String id) async {
    await _client.from('items').delete().eq('id', id);
  }
}
