import 'package:uuid/uuid.dart';

import '../../data/repositories/stock_reconciliation_repository.dart';
import '../../domain/models/product.dart';

const _uuid = Uuid();
const int maxStockCountQty = 1000000000;

/// Normalizes ASCII and Devanagari digits (`०-९`) and parses a non-negative
/// integer stock count. Returns `null` when invalid or negative.
int? parseNonNegativeStockCount(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return null;
  final buf = StringBuffer();
  for (final rune in trimmed.runes) {
    if (rune >= 0x0966 && rune <= 0x096F) {
      buf.writeCharCode(0x30 + (rune - 0x0966));
    } else if (rune == 0x2C || rune == 0x20) {
      // Allow commas/spaces as grouping separators only when digits follow.
      continue;
    } else if (rune >= 0x30 && rune <= 0x39) {
      buf.writeCharCode(rune);
    } else {
      return null;
    }
  }
  final normalized = buf.toString();
  if (normalized.isEmpty) return null;
  final parsed = int.tryParse(normalized);
  if (parsed == null || parsed < 0 || parsed > maxStockCountQty) return null;
  return parsed;
}

class StockCountEntry {
  const StockCountEntry({required this.product, required this.countedQty});

  final Product product;
  final int countedQty;

  int get delta => countedQty - product.stockCached;
  bool get hasVariance => delta != 0;
}

/// Pure draft state for a physical stock count reconciliation session.
///
/// Retains [opId] across retries of the same payload so `reconcile_stock_count`
/// remains idempotent. Rotates [opId] only when the user edits counts or reason
/// after a submission attempt, preventing payload-mismatch errors on new edits.
class StockCountDraft {
  StockCountDraft({String? opId}) : _opId = opId ?? _uuid.v4();

  String _opId;
  bool _attemptStarted = false;
  final Map<String, String> _rawInputs = {};

  String get opId => _opId;

  String rawInputFor(String productId) => _rawInputs[productId] ?? '';

  void setRawInput(String productId, String raw) {
    if (_rawInputs[productId] == raw) return;
    if (_attemptStarted) {
      _opId = _uuid.v4();
      _attemptStarted = false;
    }
    if (raw.isEmpty) {
      _rawInputs.remove(productId);
    } else {
      _rawInputs[productId] = raw;
    }
  }

  void onReasonEdited() {
    if (_attemptStarted) {
      _opId = _uuid.v4();
      _attemptStarted = false;
    }
  }

  void markAttemptStarted() {
    _attemptStarted = true;
  }

  void clear() {
    _rawInputs.clear();
    _opId = _uuid.v4();
    _attemptStarted = false;
  }

  bool isInvalid(String productId) {
    final raw = _rawInputs[productId];
    if (raw == null || raw.trim().isEmpty) return false;
    return parseNonNegativeStockCount(raw) == null;
  }

  int? parsedCountFor(String productId) {
    final raw = _rawInputs[productId];
    if (raw == null || raw.trim().isEmpty) return null;
    return parseNonNegativeStockCount(raw);
  }

  bool hasAnyInvalid(Iterable<Product> products) {
    for (final p in products) {
      if (isInvalid(p.id)) return true;
    }
    return false;
  }

  List<StockCountEntry> countedEntries(Iterable<Product> products) {
    final entries = <StockCountEntry>[];
    for (final product in products) {
      final qty = parsedCountFor(product.id);
      if (qty != null) {
        entries.add(StockCountEntry(product: product, countedQty: qty));
      }
    }
    return entries;
  }

  List<StockCountEntry> changedEntries(Iterable<Product> products) {
    return countedEntries(products).where((e) => e.hasVariance).toList();
  }

  int netVariance(Iterable<Product> products) {
    var total = 0;
    for (final entry in changedEntries(products)) {
      total += entry.delta;
    }
    return total;
  }

  List<StockCountLineInput> buildPayload(Iterable<Product> products) {
    return changedEntries(products)
        .map(
          (entry) => StockCountLineInput(
            productId: entry.product.id,
            countedQty: entry.countedQty,
            systemStock: entry.product.stockCached,
          ),
        )
        .toList();
  }
}

String formatSignedVariance(int delta) {
  if (delta > 0) return '+$delta';
  return '$delta';
}
