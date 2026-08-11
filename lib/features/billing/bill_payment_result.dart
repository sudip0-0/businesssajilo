import '../../domain/enums.dart';

class BillPaymentResult {
  const BillPaymentResult({
    required this.status,
    this.customerId,
    this.guestName,
    this.paymentAmount,
    this.paymentMethod = PaymentMethod.cash,
    this.paymentRefNote,
  });

  final BillStatus status;
  final String? customerId;

  /// Optional walk-in display name stored on the bill only (not a customer row).
  final String? guestName;
  final int? paymentAmount;
  final PaymentMethod paymentMethod;
  final String? paymentRefNote;
}
