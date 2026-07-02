import 'package:freezed_annotation/freezed_annotation.dart';

import '../enums.dart';

part 'member.freezed.dart';
part 'member.g.dart';

@freezed
abstract class Member with _$Member {
  const factory Member({
    required String id,
    required String businessId,
    required String authUserId,
    required Role role,
    required String displayName,
    String? phone,
    @Default(true) bool isActive,
    @Default(false) bool mustChangePassword,
    DateTime? createdAt,
  }) = _Member;

  factory Member.fromJson(Map<String, dynamic> json) => _$MemberFromJson(json);
}
