import 'package:businesssajilo/domain/enums.dart';
import 'package:businesssajilo/domain/models/bill.dart';
import 'package:businesssajilo/domain/models/bill_item.dart';
import 'package:businesssajilo/features/billing/credit_note_draft.dart';
import 'package:flutter_test/flutter_test.dart';

Bill _billWithItems(List<BillItem> items) {
  return Bill(
    id: 'b1',
    businessId: 'biz',
    billNo: 'B-1',
    status: BillStatus.paid,
    createdBy: 'm1',
    items: items,
  );
}

void main() {
  group('buildReturnableLines', () {
    test('excludes fully returned items and sets maxQty', () {
      final bill = _billWithItems([
        const BillItem(
          id: 'i1',
          billId: 'b1',
          productId: 'p1',
          nameSnapshot: 'Rice',
          qty: 10,
          rate: 1000,
          discount: 500,
          lineTotal: 9500,
        ),
        const BillItem(
          id: 'i2',
          billId: 'b1',
          productId: 'p2',
          nameSnapshot: 'Oil',
          qty: 2,
          rate: 2000,
          discount: 0,
          lineTotal: 4000,
        ),
      ]);

      final lines = buildReturnableLines(bill, {'i1': 10, 'i2': 1});
      expect(lines, hasLength(1));
      expect(lines.single.billItemId, 'i2');
      expect(lines.single.maxQty, 1);
      expect(lines.single.name, 'Oil');
    });

    test('prorates discount and line total for partial return', () {
      final bill = _billWithItems([
        const BillItem(
          id: 'i1',
          billId: 'b1',
          productId: 'p1',
          nameSnapshot: 'Rice',
          qty: 10,
          rate: 1000,
          discount: 500,
          lineTotal: 9500,
        ),
      ]);
      final lines = buildReturnableLines(bill, {});
      expect(lines, hasLength(1));
      lines.single.qty = 4;
      // floor(500 * 4 / 10) = 200
      expect(lines.single.proratedDiscount, 200);
      expect(lines.single.lineTotal, 4 * 1000 - 200);
    });
  });

  group('validateCreditNoteSubmit', () {
    test('requires at least one returned qty', () {
      final lines = buildReturnableLines(
        _billWithItems([
          const BillItem(
            id: 'i1',
            billId: 'b1',
            productId: 'p1',
            nameSnapshot: 'Rice',
            qty: 5,
            rate: 100,
            lineTotal: 500,
          ),
        ]),
        {},
      );
      expect(
        validateCreditNoteSubmit(lines: lines, isOnline: true),
        CreditNoteValidationError.noLines,
      );
    });

    test('rejects qty over max', () {
      final lines = buildReturnableLines(
        _billWithItems([
          const BillItem(
            id: 'i1',
            billId: 'b1',
            productId: 'p1',
            nameSnapshot: 'Rice',
            qty: 5,
            rate: 100,
            lineTotal: 500,
          ),
        ]),
        {},
      );
      lines.single.qty = 6;
      expect(
        validateCreditNoteSubmit(lines: lines, isOnline: true),
        CreditNoteValidationError.qtyExceedsMax,
      );
    });

    test('requires online', () {
      final lines = buildReturnableLines(
        _billWithItems([
          const BillItem(
            id: 'i1',
            billId: 'b1',
            productId: 'p1',
            nameSnapshot: 'Rice',
            qty: 5,
            rate: 100,
            lineTotal: 500,
          ),
        ]),
        {},
      );
      lines.single.qty = 2;
      expect(
        validateCreditNoteSubmit(lines: lines, isOnline: false),
        CreditNoteValidationError.offlineNotAllowed,
      );
      expect(validateCreditNoteSubmit(lines: lines, isOnline: true), isNull);
    });
  });
}
