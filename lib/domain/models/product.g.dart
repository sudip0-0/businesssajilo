// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Product _$ProductFromJson(Map<String, dynamic> json) => _Product(
  id: json['id'] as String,
  businessId: json['business_id'] as String,
  categoryId: json['category_id'] as String?,
  name: json['name'] as String,
  nameNp: json['name_np'] as String?,
  sku: json['sku'] as String?,
  unit: json['unit'] as String? ?? 'piece',
  costPrice: (json['cost_price'] as num?)?.toInt() ?? 0,
  referencePrice: (json['reference_price'] as num?)?.toInt() ?? 0,
  imageUrl: json['image_url'] as String?,
  lowStockThreshold: (json['low_stock_threshold'] as num?)?.toInt() ?? 0,
  stockCached: (json['stock_cached'] as num?)?.toInt() ?? 0,
  isActive: json['is_active'] as bool? ?? true,
  updatedAt: json['updated_at'] == null
      ? null
      : DateTime.parse(json['updated_at'] as String),
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
  categoryName: json['category_name'] as String?,
);

Map<String, dynamic> _$ProductToJson(_Product instance) => <String, dynamic>{
  'id': instance.id,
  'business_id': instance.businessId,
  'category_id': instance.categoryId,
  'name': instance.name,
  'name_np': instance.nameNp,
  'sku': instance.sku,
  'unit': instance.unit,
  'cost_price': instance.costPrice,
  'reference_price': instance.referencePrice,
  'image_url': instance.imageUrl,
  'low_stock_threshold': instance.lowStockThreshold,
  'stock_cached': instance.stockCached,
  'is_active': instance.isActive,
  'updated_at': instance.updatedAt?.toIso8601String(),
  'created_at': instance.createdAt?.toIso8601String(),
  'category_name': instance.categoryName,
};
