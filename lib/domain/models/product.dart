import 'package:freezed_annotation/freezed_annotation.dart';

part 'product.freezed.dart';
part 'product.g.dart';

@freezed
abstract class Product with _$Product {
  const factory Product({
    required String id,
    required String businessId,
    String? categoryId,
    required String name,
    String? nameNp,
    String? sku,
    @Default('piece') String unit,
    @Default(0) int costPrice,
    @Default(0) int referencePrice,
    String? imageUrl,
    @Default(0) int lowStockThreshold,
    @Default(0) int stockCached,
    @Default(true) bool isActive,
    DateTime? updatedAt,
    DateTime? createdAt,
    String? categoryName,
  }) = _Product;

  factory Product.fromJson(Map<String, dynamic> json) =>
      _$ProductFromJson(json);
}
