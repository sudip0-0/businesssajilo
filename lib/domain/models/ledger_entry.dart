import 'package:freezed_annotation/freezed_annotation.dart';

part 'ledger_entry.freezed.dart';
part 'ledger_entry.g.dart';

@freezed
abstract class LedgerEntry with _$LedgerEntry {
  const factory LedgerEntry({
    required String customerId,
    required String businessId,
    required DateTime occurredAt,
    required String entryType,
    required String description,
    @Default(0) int debitPaisa,
    @Default(0) int creditPaisa,
    String? refId,
    @Default(0) int runningBalance,
  }) = _LedgerEntry;

  factory LedgerEntry.fromJson(Map<String, dynamic> json) =>
      _$LedgerEntryFromJson(json);
}
