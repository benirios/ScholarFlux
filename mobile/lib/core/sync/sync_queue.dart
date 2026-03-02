import 'package:hive_flutter/hive_flutter.dart';

/// Represents a pending sync operation.
class SyncOperation {
  final String id; // unique operation ID
  final String table; // 'subjects', 'items', 'classes'
  final String recordId; // the record's ID
  final String action; // 'upsert' or 'delete'
  final DateTime createdAt;

  const SyncOperation({
    required this.id,
    required this.table,
    required this.recordId,
    required this.action,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'table': table,
        'recordId': recordId,
        'action': action,
        'createdAt': createdAt.toIso8601String(),
      };

  factory SyncOperation.fromMap(Map<String, dynamic> map) => SyncOperation(
        id: map['id'] as String,
        table: map['table'] as String,
        recordId: map['recordId'] as String,
        action: map['action'] as String,
        createdAt: DateTime.parse(map['createdAt'] as String),
      );
}

/// Hive-backed queue for pending sync operations.
/// Survives app restarts.
class SyncQueue {
  static const String _boxName = 'sync_queue';

  static Future<void> init() async {
    await Hive.openBox<Map>(_boxName);
  }

  static Box<Map> get _box => Hive.box<Map>(_boxName);

  /// Enqueue a sync operation.
  static Future<void> enqueue({
    required String table,
    required String recordId,
    required String action,
  }) async {
    final op = SyncOperation(
      id: '${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}_$recordId',
      table: table,
      recordId: recordId,
      action: action,
      createdAt: DateTime.now(),
    );
    await _box.put(op.id, op.toMap());
  }

  /// Get all pending operations, ordered by creation time.
  static List<SyncOperation> getAll() {
    return _box.values
        .map((m) => SyncOperation.fromMap(Map<String, dynamic>.from(m)))
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  /// Remove a completed operation.
  static Future<void> remove(String operationId) async {
    await _box.delete(operationId);
  }

  /// Remove all operations for a specific record (e.g., after full sync).
  static Future<void> removeForRecord(String recordId) async {
    final keys = _box.keys.where((key) {
      final map = _box.get(key);
      return map != null && map['recordId'] == recordId;
    }).toList();
    for (final key in keys) {
      await _box.delete(key);
    }
  }

  /// Clear all pending operations.
  static Future<void> clear() async {
    await _box.clear();
  }

  /// Whether there are pending operations.
  static bool get hasPending => _box.isNotEmpty;

  /// Number of pending operations.
  static int get pendingCount => _box.length;
}
