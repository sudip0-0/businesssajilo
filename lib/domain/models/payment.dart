import 'package:freezed_annotation/freezed_annotation.dart';

import '../enums.dart';

part 'payment.freezed.dart';
part 'payment.g.dart';

@freezed
abstract class Payment with _$Payment {
  const factory Payment({
    required String id,
    required String businessId,
    required String customerId,
    String? billId,
    required int amount,
    required PaymentMethod method,
    String? refNote,
    required String receivedBy,
    DateTime? createdAt,
  }) = _Payment;

  factory Payment.fromJson(Map<String, dynamic> json) =>
      _$PaymentFromJson(json);
}
