// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'product.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Product {

 String get id; String get businessId; String? get categoryId; String get name; String? get nameNp; String? get sku; String get unit; int get costPrice; int get referencePrice; String? get imageUrl; int get lowStockThreshold; int get stockCached; bool get isActive; DateTime? get updatedAt; DateTime? get createdAt; String? get categoryName;
/// Create a copy of Product
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProductCopyWith<Product> get copyWith => _$ProductCopyWithImpl<Product>(this as Product, _$identity);

  /// Serializes this Product to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Product&&(identical(other.id, id) || other.id == id)&&(identical(other.businessId, businessId) || other.businessId == businessId)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.name, name) || other.name == name)&&(identical(other.nameNp, nameNp) || other.nameNp == nameNp)&&(identical(other.sku, sku) || other.sku == sku)&&(identical(other.unit, unit) || other.unit == unit)&&(identical(other.costPrice, costPrice) || other.costPrice == costPrice)&&(identical(other.referencePrice, referencePrice) || other.referencePrice == referencePrice)&&(identical(other.imageUrl, imageUrl) || other.imageUrl == imageUrl)&&(identical(other.lowStockThreshold, lowStockThreshold) || other.lowStockThreshold == lowStockThreshold)&&(identical(other.stockCached, stockCached) || other.stockCached == stockCached)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.categoryName, categoryName) || other.categoryName == categoryName));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,businessId,categoryId,name,nameNp,sku,unit,costPrice,referencePrice,imageUrl,lowStockThreshold,stockCached,isActive,updatedAt,createdAt,categoryName);

@override
String toString() {
  return 'Product(id: $id, businessId: $businessId, categoryId: $categoryId, name: $name, nameNp: $nameNp, sku: $sku, unit: $unit, costPrice: $costPrice, referencePrice: $referencePrice, imageUrl: $imageUrl, lowStockThreshold: $lowStockThreshold, stockCached: $stockCached, isActive: $isActive, updatedAt: $updatedAt, createdAt: $createdAt, categoryName: $categoryName)';
}


}

/// @nodoc
abstract mixin class $ProductCopyWith<$Res>  {
  factory $ProductCopyWith(Product value, $Res Function(Product) _then) = _$ProductCopyWithImpl;
@useResult
$Res call({
 String id, String businessId, String? categoryId, String name, String? nameNp, String? sku, String unit, int costPrice, int referencePrice, String? imageUrl, int lowStockThreshold, int stockCached, bool isActive, DateTime? updatedAt, DateTime? createdAt, String? categoryName
});




}
/// @nodoc
class _$ProductCopyWithImpl<$Res>
    implements $ProductCopyWith<$Res> {
  _$ProductCopyWithImpl(this._self, this._then);

  final Product _self;
  final $Res Function(Product) _then;

/// Create a copy of Product
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? businessId = null,Object? categoryId = freezed,Object? name = null,Object? nameNp = freezed,Object? sku = freezed,Object? unit = null,Object? costPrice = null,Object? referencePrice = null,Object? imageUrl = freezed,Object? lowStockThreshold = null,Object? stockCached = null,Object? isActive = null,Object? updatedAt = freezed,Object? createdAt = freezed,Object? categoryName = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,businessId: null == businessId ? _self.businessId : businessId // ignore: cast_nullable_to_non_nullable
as String,categoryId: freezed == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String?,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,nameNp: freezed == nameNp ? _self.nameNp : nameNp // ignore: cast_nullable_to_non_nullable
as String?,sku: freezed == sku ? _self.sku : sku // ignore: cast_nullable_to_non_nullable
as String?,unit: null == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as String,costPrice: null == costPrice ? _self.costPrice : costPrice // ignore: cast_nullable_to_non_nullable
as int,referencePrice: null == referencePrice ? _self.referencePrice : referencePrice // ignore: cast_nullable_to_non_nullable
as int,imageUrl: freezed == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String?,lowStockThreshold: null == lowStockThreshold ? _self.lowStockThreshold : lowStockThreshold // ignore: cast_nullable_to_non_nullable
as int,stockCached: null == stockCached ? _self.stockCached : stockCached // ignore: cast_nullable_to_non_nullable
as int,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,categoryName: freezed == categoryName ? _self.categoryName : categoryName // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [Product].
extension ProductPatterns on Product {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Product value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Product() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Product value)  $default,){
final _that = this;
switch (_that) {
case _Product():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Product value)?  $default,){
final _that = this;
switch (_that) {
case _Product() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String businessId,  String? categoryId,  String name,  String? nameNp,  String? sku,  String unit,  int costPrice,  int referencePrice,  String? imageUrl,  int lowStockThreshold,  int stockCached,  bool isActive,  DateTime? updatedAt,  DateTime? createdAt,  String? categoryName)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Product() when $default != null:
return $default(_that.id,_that.businessId,_that.categoryId,_that.name,_that.nameNp,_that.sku,_that.unit,_that.costPrice,_that.referencePrice,_that.imageUrl,_that.lowStockThreshold,_that.stockCached,_that.isActive,_that.updatedAt,_that.createdAt,_that.categoryName);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String businessId,  String? categoryId,  String name,  String? nameNp,  String? sku,  String unit,  int costPrice,  int referencePrice,  String? imageUrl,  int lowStockThreshold,  int stockCached,  bool isActive,  DateTime? updatedAt,  DateTime? createdAt,  String? categoryName)  $default,) {final _that = this;
switch (_that) {
case _Product():
return $default(_that.id,_that.businessId,_that.categoryId,_that.name,_that.nameNp,_that.sku,_that.unit,_that.costPrice,_that.referencePrice,_that.imageUrl,_that.lowStockThreshold,_that.stockCached,_that.isActive,_that.updatedAt,_that.createdAt,_that.categoryName);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String businessId,  String? categoryId,  String name,  String? nameNp,  String? sku,  String unit,  int costPrice,  int referencePrice,  String? imageUrl,  int lowStockThreshold,  int stockCached,  bool isActive,  DateTime? updatedAt,  DateTime? createdAt,  String? categoryName)?  $default,) {final _that = this;
switch (_that) {
case _Product() when $default != null:
return $default(_that.id,_that.businessId,_that.categoryId,_that.name,_that.nameNp,_that.sku,_that.unit,_that.costPrice,_that.referencePrice,_that.imageUrl,_that.lowStockThreshold,_that.stockCached,_that.isActive,_that.updatedAt,_that.createdAt,_that.categoryName);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Product implements Product {
  const _Product({required this.id, required this.businessId, this.categoryId, required this.name, this.nameNp, this.sku, this.unit = 'piece', this.costPrice = 0, this.referencePrice = 0, this.imageUrl, this.lowStockThreshold = 0, this.stockCached = 0, this.isActive = true, this.updatedAt, this.createdAt, this.categoryName});
  factory _Product.fromJson(Map<String, dynamic> json) => _$ProductFromJson(json);

@override final  String id;
@override final  String businessId;
@override final  String? categoryId;
@override final  String name;
@override final  String? nameNp;
@override final  String? sku;
@override@JsonKey() final  String unit;
@override@JsonKey() final  int costPrice;
@override@JsonKey() final  int referencePrice;
@override final  String? imageUrl;
@override@JsonKey() final  int lowStockThreshold;
@override@JsonKey() final  int stockCached;
@override@JsonKey() final  bool isActive;
@override final  DateTime? updatedAt;
@override final  DateTime? createdAt;
@override final  String? categoryName;

/// Create a copy of Product
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProductCopyWith<_Product> get copyWith => __$ProductCopyWithImpl<_Product>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProductToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Product&&(identical(other.id, id) || other.id == id)&&(identical(other.businessId, businessId) || other.businessId == businessId)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.name, name) || other.name == name)&&(identical(other.nameNp, nameNp) || other.nameNp == nameNp)&&(identical(other.sku, sku) || other.sku == sku)&&(identical(other.unit, unit) || other.unit == unit)&&(identical(other.costPrice, costPrice) || other.costPrice == costPrice)&&(identical(other.referencePrice, referencePrice) || other.referencePrice == referencePrice)&&(identical(other.imageUrl, imageUrl) || other.imageUrl == imageUrl)&&(identical(other.lowStockThreshold, lowStockThreshold) || other.lowStockThreshold == lowStockThreshold)&&(identical(other.stockCached, stockCached) || other.stockCached == stockCached)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.categoryName, categoryName) || other.categoryName == categoryName));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,businessId,categoryId,name,nameNp,sku,unit,costPrice,referencePrice,imageUrl,lowStockThreshold,stockCached,isActive,updatedAt,createdAt,categoryName);

@override
String toString() {
  return 'Product(id: $id, businessId: $businessId, categoryId: $categoryId, name: $name, nameNp: $nameNp, sku: $sku, unit: $unit, costPrice: $costPrice, referencePrice: $referencePrice, imageUrl: $imageUrl, lowStockThreshold: $lowStockThreshold, stockCached: $stockCached, isActive: $isActive, updatedAt: $updatedAt, createdAt: $createdAt, categoryName: $categoryName)';
}


}

/// @nodoc
abstract mixin class _$ProductCopyWith<$Res> implements $ProductCopyWith<$Res> {
  factory _$ProductCopyWith(_Product value, $Res Function(_Product) _then) = __$ProductCopyWithImpl;
@override @useResult
$Res call({
 String id, String businessId, String? categoryId, String name, String? nameNp, String? sku, String unit, int costPrice, int referencePrice, String? imageUrl, int lowStockThreshold, int stockCached, bool isActive, DateTime? updatedAt, DateTime? createdAt, String? categoryName
});




}
/// @nodoc
class __$ProductCopyWithImpl<$Res>
    implements _$ProductCopyWith<$Res> {
  __$ProductCopyWithImpl(this._self, this._then);

  final _Product _self;
  final $Res Function(_Product) _then;

/// Create a copy of Product
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? businessId = null,Object? categoryId = freezed,Object? name = null,Object? nameNp = freezed,Object? sku = freezed,Object? unit = null,Object? costPrice = null,Object? referencePrice = null,Object? imageUrl = freezed,Object? lowStockThreshold = null,Object? stockCached = null,Object? isActive = null,Object? updatedAt = freezed,Object? createdAt = freezed,Object? categoryName = freezed,}) {
  return _then(_Product(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,businessId: null == businessId ? _self.businessId : businessId // ignore: cast_nullable_to_non_nullable
as String,categoryId: freezed == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String?,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,nameNp: freezed == nameNp ? _self.nameNp : nameNp // ignore: cast_nullable_to_non_nullable
as String?,sku: freezed == sku ? _self.sku : sku // ignore: cast_nullable_to_non_nullable
as String?,unit: null == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as String,costPrice: null == costPrice ? _self.costPrice : costPrice // ignore: cast_nullable_to_non_nullable
as int,referencePrice: null == referencePrice ? _self.referencePrice : referencePrice // ignore: cast_nullable_to_non_nullable
as int,imageUrl: freezed == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String?,lowStockThreshold: null == lowStockThreshold ? _self.lowStockThreshold : lowStockThreshold // ignore: cast_nullable_to_non_nullable
as int,stockCached: null == stockCached ? _self.stockCached : stockCached // ignore: cast_nullable_to_non_nullable
as int,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,categoryName: freezed == categoryName ? _self.categoryName : categoryName // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
