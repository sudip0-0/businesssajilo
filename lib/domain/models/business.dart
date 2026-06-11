import 'package:freezed_annotation/freezed_annotation.dart';

part 'business.freezed.dart';
part 'business.g.dart';

@freezed
abstract class Business with _$Business {
  const factory Business({
    required String id,
    required String name,
    String? nameNp,
    String? address,
    String? phone,
    String? logoUrl,
    @Default('free') String subscriptionPlan,
    DateTime? createdAt,
  }) = _Business;

  factory Business.fromJson(Map<String, dynamic> json) =>
      _$BusinessFromJson(json);
}
