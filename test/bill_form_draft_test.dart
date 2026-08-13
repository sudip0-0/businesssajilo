import 'package:businesssajilo/domain/enums.dart';
import 'package:businesssajilo/domain/models/bill.dart';
import 'package:businesssajilo/domain/models/bill_item.dart';
import 'package:businesssajilo/domain/models/product.dart';
import 'package:businesssajilo/features/billing/bill_form_draft.dart';
import 'package:businesssajilo/features/billing/bill_form_validation.dart';
import 'package:flutter_test/flutter_test.dart';

Product _product({
  required String id,
  required String name,
  int referencePrice = 10000,
}) {
  return Product(
    id: id,
    businessId: 'biz',
    name: name,
    unit: 'pcs',
    referencePrice: referencePrice,
  );
}

void main() {
  test('addProduct merges qty for the same product', () {
    final draft = BillFormDraft();
    final rice = _product(id: 'p1', name: 'Rice');
    draft.addProduct(rice);
    draft.addProduct(rice);
    expect(draft.lines, hasLength(1));
    expect(draft.lines.single.qty, 2);
    expect(draft.itemsTotal, 20000);
  });

  test('validateBillForm reports empty lines', () {
    expect(validateBillForm(BillFormDraft()), BillFormValidationError.noLines);
  });

  test('validateBillForm reports bill discount over items', () {
    final draft = BillFormDraft(billDiscountText: '999');
    draft.addProduct(_product(id: 'p1', name: 'Rice', referencePrice: 10000));
    expect(
      validateBillForm(draft),
      BillFormValidationError.invalidBillDiscount,
    );
  });

  test('validateBillForm reports invalid line discount', () {
    final draft = BillFormDraft();
    draft.addProduct(_product(id: 'p1', name: 'Rice', referencePrice: 10000));
    draft.updateDiscount(0, 99999);
    expect(
      validateBillForm(draft),
      BillFormValidationError.invalidLineDiscount,
    );
  });

  test('toLineInputs maps draft lines', () {
    final draft = BillFormDraft();
    draft.addProduct(_product(id: 'p1', name: 'Rice', referencePrice: 5000));
    draft.updateQty(0, 3);
    final inputs = draft.toLineInputs();
    expect(inputs, hasLength(1));
    expect(inputs.single.productId, 'p1');
    expect(inputs.single.nameSnapshot, 'Rice');
    expect(inputs.single.qty, 3);
    expect(inputs.single.rate, 5000);
    expect(inputs.single.lineTotal, 15000);
  });

  test('setQty clamps below 1', () {
    final draft = BillFormDraft();
    draft.addProduct(_product(id: 'p1', name: 'Rice'));
    draft.updateQty(0, 0);
    expect(draft.lines.single.qty, 1);
  });

  test('loadFromBill copies lines even when catalog is empty', () {
    final draft = BillFormDraft();
    draft.addProduct(_product(id: 'old', name: 'Stale'));
    final bill = Bill(
      id: 'b1',
      businessId: 'biz',
      customerId: 'c1',
      billNo: 'BS-0001',
      createdBy: 'm1',
      status: BillStatus.due,
      discount: 500,
      items: const [
        BillItem(
          id: 'i1',
          billId: 'b1',
          productId: 'p1',
          nameSnapshot: 'Rice',
          qty: 2,
          rate: 12000,
          discount: 100,
          lineTotal: 23900,
        ),
      ],
    );
    draft.loadFromBill(bill, const []);
    expect(draft.lines, hasLength(1));
    expect(draft.lines.single.product.id, 'p1');
    expect(draft.lines.single.product.name, 'Rice');
    expect(draft.lines.single.qty, 2);
    expect(draft.lines.single.rate, 12000);
    expect(draft.lines.single.discount, 100);
    expect(draft.customerId, 'c1');
    expect(draft.billDiscount, 500);
  });

  test('loadFromBill with no items leaves the cart empty', () {
    final draft = BillFormDraft();
    draft.addProduct(_product(id: 'p1', name: 'Rice'));
    draft.loadFromBill(
      const Bill(
        id: 'b1',
        businessId: 'biz',
        billNo: 'BS-0001',
        createdBy: 'm1',
        status: BillStatus.due,
      ),
      [_product(id: 'p1', name: 'Rice')],
    );
    expect(draft.lines, isEmpty);
  });
}
