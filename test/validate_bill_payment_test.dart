import 'package:businesssajilo/domain/enums.dart';
import 'package:businesssajilo/features/billing/validate_bill_payment.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('validateBillPayment', () {
    test('rejects missing partial amount', () {
      expect(
        validateBillPayment(
          status: BillStatus.partial,
          grandTotal: 10000,
          walkIn: false,
          customerId: 'c1',
          partialAmountPaisa: null,
        ),
        BillPaymentValidationError.amountRequired,
      );
    });

    test('rejects non-positive partial amount', () {
      expect(
        validateBillPayment(
          status: BillStatus.partial,
          grandTotal: 10000,
          walkIn: false,
          customerId: 'c1',
          partialAmountPaisa: 0,
        ),
        BillPaymentValidationError.amountNotPositive,
      );
    });

    test('rejects partial amount over total', () {
      expect(
        validateBillPayment(
          status: BillStatus.partial,
          grandTotal: 10000,
          walkIn: false,
          customerId: 'c1',
          partialAmountPaisa: 15000,
        ),
        BillPaymentValidationError.amountExceedsTotal,
      );
    });

    test('requires customer for paid non-walk-in', () {
      expect(
        validateBillPayment(
          status: BillStatus.paid,
          grandTotal: 10000,
          walkIn: false,
          customerId: null,
        ),
        BillPaymentValidationError.selectCustomer,
      );
    });

    test('allows due without customer', () {
      expect(
        validateBillPayment(
          status: BillStatus.due,
          grandTotal: 10000,
          walkIn: false,
          customerId: null,
        ),
        isNull,
      );
    });

    test('bans walk-in credit (due/partial)', () {
      expect(
        validateBillPayment(
          status: BillStatus.due,
          grandTotal: 10000,
          walkIn: true,
        ),
        BillPaymentValidationError.walkInCreditNotAllowed,
      );
      expect(
        validateBillPayment(
          status: BillStatus.partial,
          grandTotal: 10000,
          walkIn: true,
          partialAmountPaisa: 5000,
        ),
        BillPaymentValidationError.walkInCreditNotAllowed,
      );
    });

    test('allows walk-in partial that covers full (becomes paid)', () {
      expect(
        validateBillPayment(
          status: BillStatus.partial,
          grandTotal: 10000,
          walkIn: true,
          partialAmountPaisa: 10000,
        ),
        isNull,
      );
    });

    test('allows walk-in paid', () {
      expect(
        validateBillPayment(
          status: BillStatus.paid,
          grandTotal: 10000,
          walkIn: true,
        ),
        isNull,
      );
    });
  });

  group('buildBillPaymentResult', () {
    test('partial covering full becomes paid', () {
      final result = buildBillPaymentResult(
        status: BillStatus.partial,
        grandTotal: 10000,
        walkIn: false,
        customerId: 'c1',
        partialAmountPaisa: 10000,
      );
      expect(result.status, BillStatus.paid);
      expect(result.paymentAmount, 10000);
      expect(result.customerId, 'c1');
    });

    test('true partial keeps amount', () {
      final result = buildBillPaymentResult(
        status: BillStatus.partial,
        grandTotal: 10000,
        walkIn: false,
        customerId: 'c1',
        partialAmountPaisa: 4000,
        paymentMethod: PaymentMethod.cheque,
        paymentRefNote: 'CHQ-1',
      );
      expect(result.status, BillStatus.partial);
      expect(result.paymentAmount, 4000);
      expect(result.paymentMethod, PaymentMethod.cheque);
      expect(result.paymentRefNote, 'CHQ-1');
    });

    test('paid uses grand total; due has null amount', () {
      final paid = buildBillPaymentResult(
        status: BillStatus.paid,
        grandTotal: 7500,
        walkIn: true,
      );
      expect(paid.status, BillStatus.paid);
      expect(paid.paymentAmount, 7500);
      expect(paid.customerId, isNull);

      final due = buildBillPaymentResult(
        status: BillStatus.due,
        grandTotal: 7500,
        walkIn: false,
        customerId: 'c1',
      );
      expect(due.status, BillStatus.due);
      expect(due.paymentAmount, isNull);
      expect(due.customerId, 'c1');
    });

    test('walk-in clears customerId', () {
      final result = buildBillPaymentResult(
        status: BillStatus.paid,
        grandTotal: 1000,
        walkIn: true,
        customerId: 'should-be-cleared',
      );
      expect(result.customerId, isNull);
    });
  });
}
