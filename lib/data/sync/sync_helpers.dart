import 'dart:convert';

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

/// Normalizes a PostgREST RPC JSON object. Decoded maps are often
/// `Map<dynamic, dynamic>`, and `as Map<String, dynamic>` throws — that
/// aborted bill push after a successful `create_bill`.
Map<String, dynamic> mapRpcObject(dynamic result) {
  if (result is Map<String, dynamic>) return result;
  if (result is Map) return Map<String, dynamic>.from(result);
  if (result is String && result.trim().isNotEmpty) {
    return mapRpcObject(jsonDecode(result));
  }
  if (result is List && result.isNotEmpty) {
    return mapRpcObject(result.first);
  }
  throw FormatException('Expected RPC object, got ${result.runtimeType}');
}

String? _nonEmptyString(dynamic value) {
  if (value is! String) return null;
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

/// Drops empty UUID strings so Postgres does not raise `invalid input syntax`.
Map<String, dynamic> sanitizeBillPayload(Map<String, dynamic> payload) {
  final out = Map<String, dynamic>.from(payload);
  for (final key in const ['customer_id', 'order_id', 'id']) {
    if (out[key] is String && (out[key] as String).trim().isEmpty) {
      out[key] = null;
    }
  }
  final items = out['items'];
  if (items is List) {
    out['items'] = [
      for (final item in items)
        if (item is Map)
          {
            ...Map<String, dynamic>.from(item),
            if (item['product_id'] is String &&
                (item['product_id'] as String).trim().isEmpty)
              'product_id': null,
          }
        else
          item,
    ];
  }
  return out;
}

/// Copies local customer identity onto a bill payload so `create_bill` can
/// remap a stale cached id after a server reset.
Map<String, dynamic> withCustomerSnapshot(
  Map<String, dynamic> payload, {
  String? shopName,
  String? phone,
}) {
  final out = Map<String, dynamic>.from(payload);
  final existingShop = _nonEmptyString(out['customer_shop_name']);
  final existingTel = _nonEmptyString(out['customer_phone']);
  final shop = existingShop ?? _nonEmptyString(shopName);
  final tel = existingTel ?? _nonEmptyString(phone);
  if (shop != null) {
    out['customer_shop_name'] = shop;
  }
  if (tel != null) {
    out['customer_phone'] = tel;
  }
  return out;
}

/// Distinguishes sync_complete outcomes for telemetry.
String syncCompletionOutcome({
  required int retryableCount,
  required int failedCount,
}) {
  if (retryableCount == 0 && failedCount == 0) return 'all_synced';
  if (retryableCount > 0 && failedCount > 0) {
    return 'pending_and_terminal_remain';
  }
  if (failedCount > 0) return 'terminal_failures_remain';
  return 'pending_retryable_remain';
}

/// Operator-safe detail from a stored queue error (no stack traces / tokens).
String? extractSyncErrorDetail(String? raw, {int maxLength = 180}) {
  if (raw == null) return null;
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return null;
  final messageMatch = RegExp(
    r"message:\s*([^,\)]+)",
    caseSensitive: false,
  ).firstMatch(trimmed);
  var text = (messageMatch?.group(1) ?? trimmed).trim();
  text = text.replaceAll(RegExp(r'\s+'), ' ');
  if (RegExp(
    r'https?://|Bearer |apikey|stack',
    caseSensitive: false,
  ).hasMatch(text)) {
    return null;
  }
  if (text.length > maxLength) text = text.substring(0, maxLength);
  return text;
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
  return {...payload, 'created_at': occurredAt.toUtc().toIso8601String()};
}

/// Keeps the earlier occurrence time so a delayed sync cannot rewrite a
/// yesterday bill to "today" on pull.
DateTime preferOccurredAt({DateTime? local, DateTime? remote}) {
  if (local == null) return remote ?? DateTime.now().toUtc();
  if (remote == null) return local;
  return local.isBefore(remote) ? local : remote;
}
