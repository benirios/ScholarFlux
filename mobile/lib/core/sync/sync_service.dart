import 'dart:async';
import 'dart:developer' as dev;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/remote/supabase_subject_datasource.dart';
import '../../data/remote/supabase_item_datasource.dart';
import '../../data/remote/supabase_class_datasource.dart';
import '../../data/remote/supabase_client.dart';
import '../../data/repositories/hive_subject_repository.dart';
import '../../data/repositories/hive_item_repository.dart';
import '../../data/repositories/hive_class_repository.dart';
import '../../features/subjects/domain/subject.dart';
import '../../features/items/domain/item.dart';
import '../../features/items/domain/item_type.dart';
import '../../features/classes/domain/class_entry.dart';
import '../auth/clerk_auth_service.dart';
import 'sync_queue.dart';
import 'sync_status.dart';
import 'connectivity_provider.dart';

/// Orchestrates local ↔ remote sync.
///
/// Responsibilities:
/// 1. Process the sync queue (push pending local changes to Supabase).
/// 2. Pull remote changes and merge into Hive (last-write-wins).
/// 3. Subscribe to Supabase Realtime for live updates.
class SyncService {
  final SupabaseClient _supabase;
  final String? userId;
  final HiveSubjectRepository _subjectRepo;
  final HiveItemRepository _itemRepo;
  final HiveClassRepository _classRepo;
  late final SupabaseSubjectDatasource _remoteSubjects;
  late final SupabaseItemDatasource _remoteItems;
  late final SupabaseClassDatasource _remoteClasses;

  final List<RealtimeChannel> _channels = [];
  bool _isSyncing = false;
  DateTime? _lastSyncTime;

  SyncService({
    required SupabaseClient supabase,
    required this.userId,
    required HiveSubjectRepository subjectRepo,
    required HiveItemRepository itemRepo,
    required HiveClassRepository classRepo,
  })  : _supabase = supabase,
        _subjectRepo = subjectRepo,
        _itemRepo = itemRepo,
        _classRepo = classRepo {
    _remoteSubjects = SupabaseSubjectDatasource(_supabase);
    _remoteItems = SupabaseItemDatasource(_supabase);
    _remoteClasses = SupabaseClassDatasource(_supabase);
  }

  String? get _userId => userId;

  // ── Full Sync (startup or reconnect) ──────────────────────

  /// Perform a full bidirectional sync.
  Future<void> fullSync() async {
    if (_isSyncing || _userId == null) return;
    _isSyncing = true;

    try {
      dev.log('[SyncService] Starting full sync...');

      // 1. Push local pending changes
      await _processQueue();

      // 2. Pull all remote data and merge
      await _pullAndMerge();

      _lastSyncTime = DateTime.now().toUtc();
      dev.log('[SyncService] Full sync complete.');
    } catch (e, st) {
      dev.log('[SyncService] Full sync error: $e', stackTrace: st);
    } finally {
      _isSyncing = false;
    }
  }

  // ── Process Sync Queue ────────────────────────────────────

  /// Push all pending local operations to Supabase.
  Future<void> _processQueue() async {
    final userId = _userId;
    if (userId == null) return;

    final operations = SyncQueue.getAll();
    dev.log('[SyncService] Processing ${operations.length} queued operations');

    for (final op in operations) {
      try {
        switch (op.table) {
          case 'subjects':
            if (op.action == 'upsert') {
              final subject = await _subjectRepo.getById(op.recordId);
              if (subject != null) {
                await _remoteSubjects.upsert(subject, userId);
                await _subjectRepo.update(
                    subject.copyWith(syncStatus: SyncStatus.synced));
              }
            }
            break;
          case 'items':
            if (op.action == 'upsert') {
              final item = await _itemRepo.getById(op.recordId);
              if (item != null) {
                await _remoteItems.upsert(item, userId);
                await _itemRepo
                    .update(item.copyWith(syncStatus: SyncStatus.synced));
              }
            }
            break;
          case 'classes':
            if (op.action == 'upsert') {
              final entry = await _classRepo.getById(op.recordId);
              if (entry != null) {
                await _remoteClasses.upsert(entry, userId);
                await _classRepo
                    .update(entry.copyWith(syncStatus: SyncStatus.synced));
              }
            }
            break;
        }
        await SyncQueue.remove(op.id);
      } catch (e) {
        dev.log('[SyncService] Failed to process op ${op.id}: $e');
        // Leave in queue for retry
      }
    }
  }

  // ── Pull & Merge ──────────────────────────────────────────

  /// Pull remote data and merge into local Hive storage.
  /// Uses last-write-wins: the record with the later updatedAt wins.
  Future<void> _pullAndMerge() async {
    final userId = _userId;
    if (userId == null) return;

    // Pull subjects
    final remoteSubjects = await _remoteSubjects.getAll(userId);
    for (final remote in remoteSubjects) {
      final local = await _subjectRepo.getById(remote.id);
      if (local == null ||
          remote.updatedAt.isAfter(local.updatedAt) &&
              local.syncStatus == SyncStatus.synced) {
        if (remote.deletedAt != null) {
          await _subjectRepo.delete(remote.id);
        } else {
          await _subjectRepo.add(remote.copyWith(syncStatus: SyncStatus.synced));
        }
      }
    }

    // Pull items
    final remoteItems = await _remoteItems.getAll(userId);
    for (final remote in remoteItems) {
      final local = await _itemRepo.getById(remote.id);
      if (local == null ||
          remote.updatedAt.isAfter(local.updatedAt) &&
              local.syncStatus == SyncStatus.synced) {
        if (remote.deletedAt != null) {
          await _itemRepo.delete(remote.id);
        } else {
          await _itemRepo.add(remote.copyWith(syncStatus: SyncStatus.synced));
        }
      }
    }

    // Pull classes
    final remoteClasses = await _remoteClasses.getAll(userId);
    for (final remote in remoteClasses) {
      final local = await _classRepo.getById(remote.id);
      if (local == null ||
          remote.updatedAt.isAfter(local.updatedAt) &&
              local.syncStatus == SyncStatus.synced) {
        if (remote.deletedAt != null) {
          await _classRepo.delete(remote.id);
        } else {
          await _classRepo.add(remote.copyWith(syncStatus: SyncStatus.synced));
        }
      }
    }
  }

  // ── Realtime Subscriptions ────────────────────────────────

  /// Subscribe to Supabase Realtime for live updates from other devices.
  void subscribeToRealtime() {
    final userId = _userId;
    if (userId == null) return;

    _unsubscribeAll();

    // Subjects channel
    final subjectsChannel = _supabase
        .channel('subjects_changes')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'subjects',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) => _handleRealtimeChange('subjects', payload),
        )
        .subscribe();
    _channels.add(subjectsChannel);

    // Items channel
    final itemsChannel = _supabase
        .channel('items_changes')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'items',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) => _handleRealtimeChange('items', payload),
        )
        .subscribe();
    _channels.add(itemsChannel);

    // Classes channel
    final classesChannel = _supabase
        .channel('classes_changes')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'classes',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) => _handleRealtimeChange('classes', payload),
        )
        .subscribe();
    _channels.add(classesChannel);

    dev.log('[SyncService] Realtime subscriptions active.');
  }

  /// Handle an incoming Realtime change event.
  Future<void> _handleRealtimeChange(
      String table, PostgresChangePayload payload) async {
    try {
      final newRecord = payload.newRecord;
      final oldRecord = payload.oldRecord;

      switch (table) {
        case 'subjects':
          if (payload.eventType == PostgresChangeEvent.delete) {
            if (oldRecord.containsKey('id')) {
              await _subjectRepo.delete(oldRecord['id'] as String);
            }
          } else if (newRecord.isNotEmpty) {
            final remote = _remoteSubjectFromRow(newRecord);
            final local = await _subjectRepo.getById(remote.id);
            // Only overwrite if local is synced (no pending local changes)
            if (local == null || local.syncStatus == SyncStatus.synced) {
              if (remote.deletedAt != null) {
                await _subjectRepo.delete(remote.id);
              } else {
                await _subjectRepo
                    .add(remote.copyWith(syncStatus: SyncStatus.synced));
              }
            }
          }
          break;
        case 'items':
          if (payload.eventType == PostgresChangeEvent.delete) {
            if (oldRecord.containsKey('id')) {
              await _itemRepo.delete(oldRecord['id'] as String);
            }
          } else if (newRecord.isNotEmpty) {
            final remote = _remoteItemFromRow(newRecord);
            final local = await _itemRepo.getById(remote.id);
            if (local == null || local.syncStatus == SyncStatus.synced) {
              if (remote.deletedAt != null) {
                await _itemRepo.delete(remote.id);
              } else {
                await _itemRepo
                    .add(remote.copyWith(syncStatus: SyncStatus.synced));
              }
            }
          }
          break;
        case 'classes':
          if (payload.eventType == PostgresChangeEvent.delete) {
            if (oldRecord.containsKey('id')) {
              await _classRepo.delete(oldRecord['id'] as String);
            }
          } else if (newRecord.isNotEmpty) {
            final remote = _remoteClassFromRow(newRecord);
            final local = await _classRepo.getById(remote.id);
            if (local == null || local.syncStatus == SyncStatus.synced) {
              if (remote.deletedAt != null) {
                await _classRepo.delete(remote.id);
              } else {
                await _classRepo
                    .add(remote.copyWith(syncStatus: SyncStatus.synced));
              }
            }
          }
          break;
      }
    } catch (e) {
      dev.log('[SyncService] Realtime handler error: $e');
    }
  }

  // ── Row converters for Realtime payloads ──────────────────

  Subject _remoteSubjectFromRow(Map<String, dynamic> row) => Subject(
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

  Item _remoteItemFromRow(Map<String, dynamic> row) => Item(
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

  ClassEntry _remoteClassFromRow(Map<String, dynamic> row) => ClassEntry(
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

  // ── Cleanup ───────────────────────────────────────────────

  void _unsubscribeAll() {
    for (final channel in _channels) {
      _supabase.removeChannel(channel);
    }
    _channels.clear();
  }

  void dispose() {
    _unsubscribeAll();
  }
}

// ── Riverpod Providers ────────────────────────────────────────

final syncServiceProvider = Provider<SyncService>((ref) {
  final supabase = ref.watch(supabaseProvider);
  final userId = ref.watch(currentUserIdProvider);
  final service = SyncService(
    supabase: supabase,
    userId: userId,
    subjectRepo: HiveSubjectRepository(),
    itemRepo: HiveItemRepository(),
    classRepo: HiveClassRepository(),
  );
  ref.onDispose(service.dispose);
  return service;
});

/// Provider that triggers sync when connectivity changes.
final syncOnConnectivityProvider = Provider<void>((ref) {
  final isOnline = ref.watch(isOnlineProvider);
  if (isOnline) {
    final syncService = ref.read(syncServiceProvider);
    syncService.fullSync();
  }
});
