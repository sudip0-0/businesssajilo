import 'package:flutter/material.dart' show Locale;
import 'package:nepali_utils/nepali_utils.dart';

import '../../domain/models/bill.dart';
import 'bs_date.dart';
import 'money.dart';

/// Whether [query] matches a bill by number, customer/guest name, amount, or date.
bool billMatchesSearch(
  Bill bill, {
  required String query,
  Locale locale = const Locale('en'),
}) {
  return billMatchesSearchFields(
    billNo: bill.billNo,
    customerShopName: bill.customerShopName,
    grandTotal: bill.grandTotal,
    createdAt: bill.createdAt,
    query: query,
    locale: locale,
  );
}

/// Field-level matcher so Drift rows can be checked before mapping items.
bool billMatchesSearchFields({
  required String billNo,
  String? customerShopName,
  required int grandTotal,
  DateTime? createdAt,
  required String query,
  Locale locale = const Locale('en'),
}) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return true;

  if (billNo.toLowerCase().contains(q)) return true;

  final name = customerShopName?.trim().toLowerCase();
  if (name != null && name.isNotEmpty && name.contains(q)) return true;

  if (_matchesAmount(grandTotal, q)) return true;

  if (createdAt != null && _matchesDate(createdAt, q, locale)) return true;

  return false;
}

/// Paisa amount parsed from a search query, if it looks like money.
int? billSearchAmountPaisa(String query) => parseNpr(query.trim())?.value;

bool _matchesAmount(int grandTotalPaisa, String q) {
  final parsed = parseNpr(q);
  if (parsed != null && parsed.value == grandTotalPaisa) return true;

  // Only treat the query as an amount when it is money-like (digits / commas /
  // currency), not mixed tokens like bill numbers ("B-3").
  if (!RegExp(r'^[\d,.\sरूrsNPR]*\d[\d,.\sरूrsNPR]*$', caseSensitive: false)
      .hasMatch(q)) {
    return false;
  }

  final digits = q.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.isEmpty) return false;

  final rupees = (grandTotalPaisa ~/ 100).toString();
  if (rupees == digits) return true;

  final formatted = formatNpr(
    Paisa(grandTotalPaisa),
    showSymbol: false,
    showPaisa: false,
  ).toLowerCase();
  final formattedDigits = formatted.replaceAll(',', '');
  return formatted.contains(q) || formattedDigits == digits;
}

bool _matchesDate(DateTime createdAt, String q, Locale locale) {
  final ad = BsDate.ad(createdAt).toLowerCase();
  if (ad.contains(q)) return true;

  final bsEn = BsDate.bs(createdAt, locale: const Locale('en')).toLowerCase();
  if (bsEn.contains(q)) return true;

  final bsLocale = BsDate.bs(createdAt, locale: locale).toLowerCase();
  if (bsLocale.contains(q)) return true;

  final local = createdAt.toLocal();
  final iso = local.toIso8601String().substring(0, 10); // yyyy-MM-dd
  if (iso.contains(q)) return true;

  final compact = DateTime(
    local.year,
    local.month,
    local.day,
  ).toIso8601String().substring(0, 10);
  if (compact.contains(q)) return true;

  // Year / day fragments: "2026", "2083", "11"
  if (RegExp(r'^\d{1,4}$').hasMatch(q)) {
    if (local.year.toString().contains(q)) return true;
    if (local.day.toString() == q ||
        local.day.toString().padLeft(2, '0') == q) {
      return true;
    }
    final nepaliYear = createdAt.toLocal().toNepaliDateTime().year.toString();
    if (nepaliYear.contains(q)) return true;
  }

  return false;
}
