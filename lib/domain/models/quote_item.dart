import 'package:freezed_annotation/freezed_annotation.dart';

part 'quote_item.freezed.dart';
part 'quote_item.g.dart';

@freezed
abstract class QuoteItem with _$QuoteItem {
  const factory QuoteItem({
    required String id,
    required String quoteId,
    required String productId,
    required int qty,
    @Default(0) int rate,
    @Default(0) int discount,
    @Default(0) int lineTotal,
    String? productName,
  }) = _QuoteItem;

  factory QuoteItem.fromJson(Map<String, dynamic> json) =>
      _$QuoteItemFromJson(json);
}
