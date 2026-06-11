import 'package:freezed_annotation/freezed_annotation.dart';

part 'customer.freezed.dart';
part 'customer.g.dart';

@freezed
abstract class Customer with _$Customer {
  const factory Customer({
    required String id,
    required String businessId,
    required String memberId,
    required String shopName,
    String? contactName,
    String? phone,
    String? address,
    @Default(0) int openingBalance,
    @Default(0) int balanceDue,
    DateTime? createdAt,
  }) = _Customer;

  factory Customer.fromJson(Map<String, dynamic> json) =>
      _$CustomerFromJson(json);
}
