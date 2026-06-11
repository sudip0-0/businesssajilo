import 'package:freezed_annotation/freezed_annotation.dart';

import '../enums.dart';
import 'quote_item.dart';

part 'quote.freezed.dart';
part 'quote.g.dart';

@freezed
abstract class Quote with _$Quote {
  const factory Quote({
    required String id,
    required String orderId,
    required int version,
    required QuoteStatus status,
    @Default(0) int total,
    String? responseComment,
    required String createdBy,
    DateTime? createdAt,
    @Default([]) List<QuoteItem> items,
  }) = _Quote;

  factory Quote.fromJson(Map<String, dynamic> json) => _$QuoteFromJson(json);
}
