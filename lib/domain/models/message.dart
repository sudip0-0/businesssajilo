import 'package:freezed_annotation/freezed_annotation.dart';

part 'message.freezed.dart';
part 'message.g.dart';

@freezed
abstract class Message with _$Message {
  const factory Message({
    required String id,
    required String orderId,
    required String businessId,
    required String senderMemberId,
    @Default('') String body,
    String? imageUrl,
    DateTime? createdAt,
    String? senderName,
  }) = _Message;

  factory Message.fromJson(Map<String, dynamic> json) =>
      _$MessageFromJson(json);
}
