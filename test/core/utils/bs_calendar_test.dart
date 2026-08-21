import 'dart:ui' show Locale;

import 'package:businesssajilo/core/utils/bs_calendar.dart';
import 'package:businesssajilo/core/utils/report_range.dart';
import 'package:businesssajilo/domain/models/sales_period_point.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BsCalendar', () {
    // Nepali New Year 2083 (Baishakh 1) falls on 2026-04-13 (AD).
    test('converts AD to known BS new year date', () {
      final bs = BsCalendar.bsDateOf(DateTime.utc(2026, 4, 13));
      expect(bs.year, 2083);
      expect(bs.month, 1);
      expect(bs.day, 1);
    });

    test('monthRange covers exactly one BS month on NPT boundaries', () {
      final range = BsCalendar.monthRange(
        BsCalendar.currentBsMonth(now: DateTime.utc(2026, 4, 14)),
      );
      // From must be an NPT-midnight UTC instant (adding offset back gives
      // a whole day at midnight).
      final nptStart = range.from.add(nptOffset);
      expect(nptStart.hour, 0);
      expect(nptStart.minute, 0);
      expect(range.to.isAfter(range.from), isTrue);
      // Next month start must equal this range's end.
      final nextStart = BsCalendar.instantFromBsDate(
        BsCalendar.bsDateOf(range.to),
      );
      expect(nextStart, range.to);
    });

    test('fiscal year runs Shrawan to Ashadh across two BS years', () {
      const startYear = 2083;
      final fy = BsCalendar.fiscalYearRange(startYear);
      // Fiscal start = Shrawan 1, 2083.
      final startBs = BsCalendar.bsDateOf(fy.from.add(nptOffset));
      expect(startBs.month, BsCalendar.fiscalYearStartMonth);
      expect(startBs.day, 1);
      expect(startBs.year, startYear);
      // End = Shrawan 1 of the following BS year.
      final endBs = BsCalendar.bsDateOf(fy.to.add(nptOffset));
      expect(endBs.year, startYear + 1);
      expect(endBs.month, BsCalendar.fiscalYearStartMonth);
      // Adjacent fiscal years tile without gaps.
      expect(BsCalendar.fiscalYearRange(startYear + 1).from, fy.to);
    });

    test('currentFiscalYearStartYear maps months before Shrawan back', () {
      // A date in Ashadh 2083 (month 3) belongs to FY starting 2082.
      final ashadh = BsCalendar.bsDateOf(DateTime.utc(2026, 7, 1));
      expect(ashadh.month, 3);
      expect(BsCalendar.fiscalYearStartYearOf(ashadh), 2082);
      // A date in Shrawan 2083 belongs to FY starting 2083.
      final shrawan = BsCalendar.bsDateOf(DateTime.utc(2026, 7, 20));
      expect(shrawan.month, 4);
      expect(BsCalendar.fiscalYearStartYearOf(shrawan), 2083);
    });

    test('groupSalesByBsMonth buckets daily points per BS month', () {
      // Two days within the same BS month + one in a later BS month.
      final points = [
        SalesPeriodPoint(saleDate: DateTime.utc(2026, 4, 15), totalSales: 100, billCount: 1),
        SalesPeriodPoint(saleDate: DateTime.utc(2026, 4, 20), totalSales: 250, billCount: 2),
        SalesPeriodPoint(saleDate: DateTime.utc(2026, 6, 10), totalSales: 70, billCount: 1),
      ];
      final months = BsCalendar.groupSalesByBsMonth(points);
      expect(months, hasLength(2));
      expect(months[0].month.year, 2083);
      expect(months[0].month.month, 1);
      expect(months[0].totalSales, 350);
      expect(months[0].billCount, 3);
      expect(months[1].totalSales, 70);
      expect(months[1].month.month, greaterThan(1));
    });

    test('monthLabel renders without throwing for both locales', () {
      final month = BsCalendar.currentBsMonth(now: DateTime.utc(2026, 4, 14));
      expect(BsCalendar.monthLabel(month), isNotEmpty);
      expect(BsCalendar.monthLabel(month, locale: const Locale('en')), isNotEmpty);
    });
  });
}
