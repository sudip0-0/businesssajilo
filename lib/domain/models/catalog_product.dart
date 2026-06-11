import 'package:freezed_annotation/freezed_annotation.dart';

part 'catalog_product.freezed.dart';
part 'catalog_product.g.dart';

@freezed
abstract class CatalogProduct with _$CatalogProduct {
  const factory CatalogProduct({
    required String id,
    required String businessId,
    String? categoryId,
    required String name,
    String? nameNp,
    String? sku,
    @Default('piece') String unit,
    String? imageUrl,
    @Default(0) int stockCached,
    @Default(true) bool isActive,
    String? categoryName,
  }) = _CatalogProduct;

  factory CatalogProduct.fromJson(Map<String, dynamic> json) =>
      _$CatalogProductFromJson(json);
}
