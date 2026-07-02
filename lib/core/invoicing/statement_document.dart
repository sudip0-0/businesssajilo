import 'package:flutter/material.dart';

import '../../domain/models/business.dart';
import '../../domain/models/ledger_entry.dart';
import '../utils/ledger_balance.dart';

/// Localized labels used when rendering a statement PDF.
class StatementLabels {
  const StatementLabels({
    required this.title,
    required this.period,
    required this.customer,
    required this.date,
    required this.description,
    required this.debit,
    required this.credit,
    required this.balance,
    required this.openingBalance,
    required this.closingBalance,
  });

  final String title;
  final String period;
  final String customer;
  final String date;
  final String description;
  final String debit;
  final String credit;
  final String balance;
  final String openingBalance;
  final String closingBalance;
}

class StatementLine {
  const StatementLine({
    required this.date,
    required this.description,
    required this.debit,
    required this.credit,
    required this.balance,
  });

  final DateTime date;
  final String description;
  final int debit;
  final int credit;
  final int balance;
}

/// Data required to render a customer ledger statement for export.
///
/// Built from the full ledger so the opening balance for a date range is the
/// exact running balance before the range starts — the closing balance always
/// matches the in-app ledger.
class StatementDocument {
  const StatementDocument({
    required this.business,
    required this.customerLabel,
    required this.fromDate,
    required this.toDate,
    required this.openingBalance,
    required this.closingBalance,
    required this.lines,
    required this.locale,
    required this.labels,
  });

  /// [entries] must be the customer's complete ledger in ascending order
  /// with running balances applied (see [withRunningBalance]).
  factory StatementDocument.fromLedger({
    required Business business,
    required String customerLabel,
    required List<LedgerEntry> entries,
    DateTime? from,
    required DateTime to,
    required Locale locale,
    required StatementLabels labels,
    required String Function(LedgerEntry) describeEntry,
  }) {
    var opening = 0;
    final lines = <StatementLine>[];
    for (final entry in entries) {
      if (entry.occurredAt.isAfter(to)) break;
      if (from != null && entry.occurredAt.isBefore(from)) {
        opening = entry.runningBalance;
        continue;
      }
      lines.add(
        StatementLine(
          date: entry.occurredAt,
          description: describeEntry(entry),
          debit: entry.debitPaisa,
          credit: entry.creditPaisa,
          balance: entry.runningBalance,
        ),
      );
    }
    final closing = lines.isEmpty ? opening : lines.last.balance;
    return StatementDocument(
      business: business,
      customerLabel: customerLabel,
      fromDate: from,
      toDate: to,
      openingBalance: opening,
      closingBalance: closing,
      lines: lines,
      locale: locale,
      labels: labels,
    );
  }

  final Business business;
  final String customerLabel;
  final DateTime? fromDate;
  final DateTime toDate;
  final int openingBalance;
  final int closingBalance;
  final List<StatementLine> lines;
  final Locale locale;
  final StatementLabels labels;

  String get businessDisplayName {
    if (locale.languageCode == 'ne' &&
        business.nameNp != null &&
        business.nameNp!.trim().isNotEmpty) {
      return business.nameNp!;
    }
    return business.name;
  }
}
