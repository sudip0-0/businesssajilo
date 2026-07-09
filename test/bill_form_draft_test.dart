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
}
