// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'catalog_product.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CatalogProduct _$CatalogProductFromJson(Map<String, dynamic> json) =>
    _CatalogProduct(
      id: json['id'] as String,
      businessId: json['business_id'] as String,
      categoryId: json['category_id'] as String?,
      name: json['name'] as String,
      nameNp: json['name_np'] as String?,
      sku: json['sku'] as String?,
      unit: json['unit'] as String? ?? 'piece',
      imageUrl: json['image_url'] as String?,
      stockCached: (json['stock_cached'] as num?)?.toInt() ?? 0,
      isActive: json['is_active'] as bool? ?? true,
      categoryName: json['category_name'] as String?,
    );

Map<String, dynamic> _$CatalogProductToJson(_CatalogProduct instance) =>
    <String, dynamic>{
      'id': instance.id,
      'business_id': instance.businessId,
      'category_id': instance.categoryId,
      'name': instance.name,
      'name_np': instance.nameNp,
      'sku': instance.sku,
      'unit': instance.unit,
      'image_url': instance.imageUrl,
      'stock_cached': instance.stockCached,
      'is_active': instance.isActive,
      'category_name': instance.categoryName,
    };
