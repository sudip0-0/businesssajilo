import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/payments_repository.dart';
import '../../domain/enums.dart';
import '../../domain/models/payment.dart';
import '../auth/providers/auth_provider.dart';
import 'invalidate_billing.dart';
import 'payment_allocation.dart';

enum RecordPaymentValidationError {
  amountRequired,
  amountNotPositive,
  noCustomer,
}

RecordPaymentValidationError? validateRecordPayment({
  required String? customerId,
  required int? amountPaisa,
}) {
  if (amountPaisa == null) return RecordPaymentValidationError.amountRequired;
  if (amountPaisa <= 0) return RecordPaymentValidationError.amountNotPositive;
  if (customerId == null) return RecordPaymentValidationError.noCustomer;
  return null;
}

Future<Payment> recordCustomerPayment(
  Ref ref, {
  required String customerId,
  required int amountPaisa,
  required PaymentMethod method,
  String? refNote,
  PaymentAllocation allocation = const PaymentAllocation(
    mode: PaymentAllocateMode.account,
  ),
}) async {
  final memberId = ref.read(authProvider).value?.member?.id;
  if (memberId == null) {
    throw StateError('Not authenticated');
  }
  final payment = await ref
      .read(paymentsRepositoryProvider)
      .record(
        customerId: customerId,
        amount: amountPaisa,
        method: method,
        refNote: refNote,
        billId: allocation.rpcBillId,
        allocate: allocation.rpcAllocate,
        receivedByMemberId: memberId,
      );
  invalidateAfterCustomerPayment(ref, customerId: customerId);
  return payment;
}
