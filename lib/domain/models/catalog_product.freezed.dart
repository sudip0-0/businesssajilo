// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'catalog_product.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CatalogProduct {

 String get id; String get businessId; String? get categoryId; String get name; String? get nameNp; String? get sku; String get unit; String? get imageUrl; int get stockCached; bool get isActive; String? get categoryName;
/// Create a copy of CatalogProduct
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CatalogProductCopyWith<CatalogProduct> get copyWith => _$CatalogProductCopyWithImpl<CatalogProduct>(this as CatalogProduct, _$identity);

  /// Serializes this CatalogProduct to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CatalogProduct&&(identical(other.id, id) || other.id == id)&&(identical(other.businessId, businessId) || other.businessId == businessId)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.name, name) || other.name == name)&&(identical(other.nameNp, nameNp) || other.nameNp == nameNp)&&(identical(other.sku, sku) || other.sku == sku)&&(identical(other.unit, unit) || other.unit == unit)&&(identical(other.imageUrl, imageUrl) || other.imageUrl == imageUrl)&&(identical(other.stockCached, stockCached) || other.stockCached == stockCached)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.categoryName, categoryName) || other.categoryName == categoryName));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,businessId,categoryId,name,nameNp,sku,unit,imageUrl,stockCached,isActive,categoryName);

@override
String toString() {
  return 'CatalogProduct(id: $id, businessId: $businessId, categoryId: $categoryId, name: $name, nameNp: $nameNp, sku: $sku, unit: $unit, imageUrl: $imageUrl, stockCached: $stockCached, isActive: $isActive, categoryName: $categoryName)';
}


}

/// @nodoc
abstract mixin class $CatalogProductCopyWith<$Res>  {
  factory $CatalogProductCopyWith(CatalogProduct value, $Res Function(CatalogProduct) _then) = _$CatalogProductCopyWithImpl;
@useResult
$Res call({
 String id, String businessId, String? categoryId, String name, String? nameNp, String? sku, String unit, String? imageUrl, int stockCached, bool isActive, String? categoryName
});




}
/// @nodoc
class _$CatalogProductCopyWithImpl<$Res>
    implements $CatalogProductCopyWith<$Res> {
  _$CatalogProductCopyWithImpl(this._self, this._then);

  final CatalogProduct _self;
  final $Res Function(CatalogProduct) _then;

/// Create a copy of CatalogProduct
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? businessId = null,Object? categoryId = freezed,Object? name = null,Object? nameNp = freezed,Object? sku = freezed,Object? unit = null,Object? imageUrl = freezed,Object? stockCached = null,Object? isActive = null,Object? categoryName = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,businessId: null == businessId ? _self.businessId : businessId // ignore: cast_nullable_to_non_nullable
as String,categoryId: freezed == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String?,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,nameNp: freezed == nameNp ? _self.nameNp : nameNp // ignore: cast_nullable_to_non_nullable
as String?,sku: freezed == sku ? _self.sku : sku // ignore: cast_nullable_to_non_nullable
as String?,unit: null == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as String,imageUrl: freezed == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String?,stockCached: null == stockCached ? _self.stockCached : stockCached // ignore: cast_nullable_to_non_nullable
as int,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,categoryName: freezed == categoryName ? _self.categoryName : categoryName // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [CatalogProduct].
extension CatalogProductPatterns on CatalogProduct {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CatalogProduct value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CatalogProduct() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CatalogProduct value)  $default,){
final _that = this;
switch (_that) {
case _CatalogProduct():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CatalogProduct value)?  $default,){
final _that = this;
switch (_that) {
case _CatalogProduct() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String businessId,  String? categoryId,  String name,  String? nameNp,  String? sku,  String unit,  String? imageUrl,  int stockCached,  bool isActive,  String? categoryName)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CatalogProduct() when $default != null:
return $default(_that.id,_that.businessId,_that.categoryId,_that.name,_that.nameNp,_that.sku,_that.unit,_that.imageUrl,_that.stockCached,_that.isActive,_that.categoryName);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String businessId,  String? categoryId,  String name,  String? nameNp,  String? sku,  String unit,  String? imageUrl,  int stockCached,  bool isActive,  String? categoryName)  $default,) {final _that = this;
switch (_that) {
case _CatalogProduct():
return $default(_that.id,_that.businessId,_that.categoryId,_that.name,_that.nameNp,_that.sku,_that.unit,_that.imageUrl,_that.stockCached,_that.isActive,_that.categoryName);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String businessId,  String? categoryId,  String name,  String? nameNp,  String? sku,  String unit,  String? imageUrl,  int stockCached,  bool isActive,  String? categoryName)?  $default,) {final _that = this;
switch (_that) {
case _CatalogProduct() when $default != null:
return $default(_that.id,_that.businessId,_that.categoryId,_that.name,_that.nameNp,_that.sku,_that.unit,_that.imageUrl,_that.stockCached,_that.isActive,_that.categoryName);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CatalogProduct implements CatalogProduct {
  const _CatalogProduct({required this.id, required this.businessId, this.categoryId, required this.name, this.nameNp, this.sku, this.unit = 'piece', this.imageUrl, this.stockCached = 0, this.isActive = true, this.categoryName});
  factory _CatalogProduct.fromJson(Map<String, dynamic> json) => _$CatalogProductFromJson(json);

@override final  String id;
@override final  String businessId;
@override final  String? categoryId;
@override final  String name;
@override final  String? nameNp;
@override final  String? sku;
@override@JsonKey() final  String unit;
@override final  String? imageUrl;
@override@JsonKey() final  int stockCached;
@override@JsonKey() final  bool isActive;
@override final  String? categoryName;

/// Create a copy of CatalogProduct
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CatalogProductCopyWith<_CatalogProduct> get copyWith => __$CatalogProductCopyWithImpl<_CatalogProduct>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CatalogProductToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CatalogProduct&&(identical(other.id, id) || other.id == id)&&(identical(other.businessId, businessId) || other.businessId == businessId)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.name, name) || other.name == name)&&(identical(other.nameNp, nameNp) || other.nameNp == nameNp)&&(identical(other.sku, sku) || other.sku == sku)&&(identical(other.unit, unit) || other.unit == unit)&&(identical(other.imageUrl, imageUrl) || other.imageUrl == imageUrl)&&(identical(other.stockCached, stockCached) || other.stockCached == stockCached)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.categoryName, categoryName) || other.categoryName == categoryName));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,businessId,categoryId,name,nameNp,sku,unit,imageUrl,stockCached,isActive,categoryName);

@override
String toString() {
  return 'CatalogProduct(id: $id, businessId: $businessId, categoryId: $categoryId, name: $name, nameNp: $nameNp, sku: $sku, unit: $unit, imageUrl: $imageUrl, stockCached: $stockCached, isActive: $isActive, categoryName: $categoryName)';
}


}

/// @nodoc
abstract mixin class _$CatalogProductCopyWith<$Res> implements $CatalogProductCopyWith<$Res> {
  factory _$CatalogProductCopyWith(_CatalogProduct value, $Res Function(_CatalogProduct) _then) = __$CatalogProductCopyWithImpl;
@override @useResult
$Res call({
 String id, String businessId, String? categoryId, String name, String? nameNp, String? sku, String unit, String? imageUrl, int stockCached, bool isActive, String? categoryName
});




}
/// @nodoc
class __$CatalogProductCopyWithImpl<$Res>
    implements _$CatalogProductCopyWith<$Res> {
  __$CatalogProductCopyWithImpl(this._self, this._then);

  final _CatalogProduct _self;
  final $Res Function(_CatalogProduct) _then;

/// Create a copy of CatalogProduct
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? businessId = null,Object? categoryId = freezed,Object? name = null,Object? nameNp = freezed,Object? sku = freezed,Object? unit = null,Object? imageUrl = freezed,Object? stockCached = null,Object? isActive = null,Object? categoryName = freezed,}) {
  return _then(_CatalogProduct(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,businessId: null == businessId ? _self.businessId : businessId // ignore: cast_nullable_to_non_nullable
as String,categoryId: freezed == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String?,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,nameNp: freezed == nameNp ? _self.nameNp : nameNp // ignore: cast_nullable_to_non_nullable
as String?,sku: freezed == sku ? _self.sku : sku // ignore: cast_nullable_to_non_nullable
as String?,unit: null == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as String,imageUrl: freezed == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String?,stockCached: null == stockCached ? _self.stockCached : stockCached // ignore: cast_nullable_to_non_nullable
as int,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,categoryName: freezed == categoryName ? _self.categoryName : categoryName // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
