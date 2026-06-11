import 'package:freezed_annotation/freezed_annotation.dart';

part 'notification_item.freezed.dart';
part 'notification_item.g.dart';

@freezed
abstract class NotificationItem with _$NotificationItem {
  const NotificationItem._();

  const factory NotificationItem({
    required String id,
    required String businessId,
    required String recipientMemberId,
    required String type,
    @Default({}) Map<String, dynamic> payload,
    DateTime? readAt,
    DateTime? createdAt,
  }) = _NotificationItem;

  factory NotificationItem.fromJson(Map<String, dynamic> json) =>
      _$NotificationItemFromJson(json);

  bool get isUnread => readAt == null;
}
