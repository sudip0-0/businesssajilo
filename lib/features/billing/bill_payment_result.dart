import '../../domain/enums.dart';

class BillPaymentResult {
  const BillPaymentResult({
    required this.status,
    this.customerId,
    this.paymentAmount,
    this.paymentMethod = PaymentMethod.cash,
    this.paymentRefNote,
  });

  final BillStatus status;
  final String? customerId;
  final int? paymentAmount;
  final PaymentMethod paymentMethod;
  final String? paymentRefNote;
}
