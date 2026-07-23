import '../../../core/logging/app_log.dart';
import '../sync_constants.dart';

/// Outcome of a budget-limited paged pull.
enum PullPageOutcome {
  /// All rows for the entity were fetched.
  complete,

  /// Budget exhausted before the entity finished — resume from [nextOffset].
  budgetExceeded,
}

/// Result of [SyncPullPage.pullPaged].
class PullPageResult {
  const PullPageResult({required this.outcome, required this.nextOffset});

  final PullPageOutcome outcome;
  final int nextOffset;
}

/// Budget tracker for resumable bootstrap passes.
class SyncPullBudget {
  SyncPullBudget({
    this.maxPages = syncBootstrapMaxPagesPerPass,
    Duration maxDuration = syncBootstrapMaxDuration,
  }) : _deadline = DateTime.now().toUtc().add(maxDuration);

  final int maxPages;
  final DateTime _deadline;
  int pagesFetched = 0;

  bool get hasBudget =>
      pagesFetched < maxPages && DateTime.now().toUtc().isBefore(_deadline);

  void recordPage() => pagesFetched++;
}

/// Paged remote fetch helper shared by entity pull strategies.
class SyncPullPage {
  const SyncPullPage();

  /// Fetches all pages when [budget] is null; otherwise stops when budget
  /// is exhausted and returns [PullPageOutcome.budgetExceeded].
  Future<PullPageResult> pullPaged({
    required Future<dynamic> Function(int from, int to) buildPage,
    required Future<void> Function(List<Map<String, dynamic>> rows) onPage,
    int pageSize = syncPullPageSize,
    int startOffset = 0,
    SyncPullBudget? budget,
    String? entityLabel,
  }) async {
    var offset = startOffset;
    while (true) {
      if (budget != null && !budget.hasBudget) {
        return PullPageResult(
          outcome: PullPageOutcome.budgetExceeded,
          nextOffset: offset,
        );
      }

      List<Map<String, dynamic>> rows;
      try {
        rows = _asMaps(await buildPage(offset, offset + pageSize - 1));
      } catch (e, st) {
        AppLog.warn(
          'Sync pull page failed entity=${entityLabel ?? 'unknown'} offset=$offset',
          e,
          st,
        );
        rethrow;
      }

      if (rows.isEmpty) {
        return const PullPageResult(
          outcome: PullPageOutcome.complete,
          nextOffset: 0,
        );
      }

      await onPage(rows);
      budget?.recordPage();

      if (rows.length < pageSize) {
        return const PullPageResult(
          outcome: PullPageOutcome.complete,
          nextOffset: 0,
        );
      }

      offset += pageSize;

      if (budget != null && !budget.hasBudget) {
        return PullPageResult(
          outcome: PullPageOutcome.budgetExceeded,
          nextOffset: offset,
        );
      }
    }
  }

  List<Map<String, dynamic>> _asMaps(dynamic rows) {
    return (rows as List)
        .map((r) => Map<String, dynamic>.from(r as Map))
        .toList();
  }
}
