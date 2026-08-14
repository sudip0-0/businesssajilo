import 'dart:ui' show Locale;

import 'package:intl/intl.dart';
import 'package:nepali_utils/nepali_utils.dart';

/// Bikram Sambat (BS) + AD date helpers. Store UTC in DB, display both.
abstract final class BsDate {
  static final _adFormat = DateFormat('d MMM yyyy');
  static final _timeFormat = DateFormat('h:mm a');

  static Language _languageFor(Locale? locale) =>
      locale?.languageCode == 'en' ? Language.english : Language.nepali;

  /// e.g. "२०८३ असार २८" (Nepali default) or "2083 Asar 28" for English locale.
  static String bs(DateTime dateUtc, {Locale? locale}) {
    final nepaliDate = dateUtc.toLocal().toNepaliDateTime();
    return NepaliDateFormat(
      'yyyy MMMM d',
      _languageFor(locale),
    ).format(nepaliDate);
  }

  /// e.g. "12 Jul 2026"
  static String ad(DateTime dateUtc) => _adFormat.format(dateUtc.toLocal());

  /// Local wall-clock time, e.g. "4:00 PM" or "०४:०० अपराह्न".
  static String time(DateTime dateUtc, {Locale? locale}) {
    final local = dateUtc.toLocal();
    if (locale?.languageCode == 'ne') {
      return NepaliDateFormat(
        'hh:mm a',
        Language.nepali,
      ).format(local.toNepaliDateTime());
    }
    return _timeFormat.format(local);
  }

  /// e.g. "२०८३ असार २८ · 12 Jul 2026" — used on bills & ledgers.
  static String both(DateTime dateUtc, {Locale? locale}) =>
      '${bs(dateUtc, locale: locale)} · ${ad(dateUtc)}';

  /// Date plus local time, e.g. "२०८३ असार २८ · 12 Jul 2026 · 4:00 PM".
  static String bothWithTime(DateTime dateUtc, {Locale? locale}) =>
      '${both(dateUtc, locale: locale)} · ${time(dateUtc, locale: locale)}';
}
