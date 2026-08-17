/// Truncates sync failure messages for storage on [SyncQueue.lastError].
String truncateSyncError(Object error, {int maxLength = 500}) {
  final text = error.toString();
  if (text.length <= maxLength) return text;
  return text.substring(0, maxLength);
}

/// How long to wait between reachability probes while Supabase is down.
/// Wi-Fi staying up (e.g. local Docker stopped) does not fire connectivity
/// events, so sync retries on this schedule until the host responds.
const reachabilityRetryDelays = [
  Duration(seconds: 5),
  Duration(seconds: 15),
  Duration(seconds: 30),
  Duration(seconds: 60),
];

class ReachabilityBackoff {
  int attempts = 0;

  Duration next() {
    final index = attempts.clamp(0, reachabilityRetryDelays.length - 1);
    attempts++;
    return reachabilityRetryDelays[index];
  }

  void reset() => attempts = 0;
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

/// Copies [occurredAt] onto a sync payload when the queue item was created
/// before `created_at` was included (delayed offline bills).
Map<String, dynamic> stampOccurredAt(
  Map<String, dynamic> payload,
  DateTime? occurredAt,
) {
  final existing = payload['created_at'];
  if (existing is String && existing.trim().isNotEmpty) return payload;
  if (occurredAt == null) return payload;
  return {
    ...payload,
    'created_at': occurredAt.toUtc().toIso8601String(),
  };
}

/// Keeps the earlier occurrence time so a delayed sync cannot rewrite a
/// yesterday bill to "today" on pull.
DateTime preferOccurredAt({DateTime? local, DateTime? remote}) {
  if (local == null) return remote ?? DateTime.now().toUtc();
  if (remote == null) return local;
  return local.isBefore(remote) ? local : remote;
}
