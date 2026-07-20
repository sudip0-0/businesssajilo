import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/bills_repository.dart';
import '../../domain/enums.dart';
import '../../domain/models/bill.dart';
import '../auth/providers/auth_provider.dart';
import 'invalidate_billing.dart';

enum RecordSaleValidationError {
  amountRequired,
  amountNotPositive,
  noCustomer,
}

RecordSaleValidationError? validateRecordSale({
  required String? customerId,
  required int? amountPaisa,
}) {
  if (amountPaisa == null) return RecordSaleValidationError.amountRequired;
  if (amountPaisa <= 0) return RecordSaleValidationError.amountNotPositive;
  if (customerId == null) return RecordSaleValidationError.noCustomer;
  return null;
}

Future<Bill> recordCustomerSale(
  Ref ref, {
  required String customerId,
  required int amountPaisa,
  String? refNote,
  bool paidNow = false,
  PaymentMethod paymentMethod = PaymentMethod.cash,
}) async {
  final memberId = ref.read(authProvider).value?.member?.id;
  if (memberId == null) {
    throw StateError('Not authenticated');
  }
  final bill = await ref
      .read(billsRepositoryProvider)
      .recordAmountSale(
        customerId: customerId,
        createdByMemberId: memberId,
        amountPaisa: amountPaisa,
        refNote: refNote,
        paidNow: paidNow,
        paymentMethod: paymentMethod,
      );
  invalidateAfterBillSaved(ref, customerId: customerId, billId: bill.id);
  return bill;
}
