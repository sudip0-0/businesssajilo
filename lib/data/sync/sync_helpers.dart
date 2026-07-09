/// Truncates sync failure messages for storage on [SyncQueue.lastError].
String truncateSyncError(Object error, {int maxLength = 500}) {
  final text = error.toString();
  if (text.length <= maxLength) return text;
  return text.substring(0, maxLength);
}

/// Tracks whether overlapping [syncNow] calls should run again after the
/// current pass finishes. Extracted for unit testing without SyncService I/O.
class SyncCoalesce {
  bool syncing = false;
  bool queued = false;

  /// Marks a request while a sync may already be running.
  void markQueuedIfBusy() {
    if (syncing) queued = true;
  }

  /// Claims the sync lock. Returns false if another caller already holds it
  /// (and marks [queued] so a follow-up pass runs).
  bool tryEnter() {
    if (syncing) {
      queued = true;
      return false;
    }
    syncing = true;
    queued = false;
    return true;
  }

  void clearQueued() => queued = false;

  bool get shouldRepeat => queued;

  void end() {
    syncing = false;
  }
}
