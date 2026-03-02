/// Sync status for local records. Stored only in Hive, not sent to Supabase.
enum SyncStatus {
  synced,
  pendingUpload,
  pendingDelete;

  String get name {
    switch (this) {
      case SyncStatus.synced:
        return 'synced';
      case SyncStatus.pendingUpload:
        return 'pendingUpload';
      case SyncStatus.pendingDelete:
        return 'pendingDelete';
    }
  }

  static SyncStatus fromString(String value) {
    return SyncStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => SyncStatus.synced,
    );
  }
}
