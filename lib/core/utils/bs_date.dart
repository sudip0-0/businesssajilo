import 'package:intl/intl.dart';
import 'package:nepali_utils/nepali_utils.dart';

/// Bikram Sambat (BS) + AD date helpers. Store UTC in DB, display both.
abstract final class BsDate {
  static final _adFormat = DateFormat('d MMM yyyy');

  /// e.g. "२०८३ असार २८"
  static String bs(DateTime dateUtc, {Language language = Language.nepali}) {
    final nepaliDate = dateUtc.toLocal().toNepaliDateTime();
    return NepaliDateFormat('yyyy MMMM d', language).format(nepaliDate);
  }

  /// e.g. "12 Jul 2026"
  static String ad(DateTime dateUtc) => _adFormat.format(dateUtc.toLocal());

  /// e.g. "२०८३ असार २८ · 12 Jul 2026" — used on bills & ledgers.
  static String both(DateTime dateUtc) => '${bs(dateUtc)} · ${ad(dateUtc)}';
}
