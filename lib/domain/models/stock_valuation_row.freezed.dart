// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'stock_valuation_row.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$StockValuationRow {

 String get productId; String get name; int get stockCached; int get costPrice; int get valuation; bool get isLowStock;
/// Create a copy of StockValuationRow
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StockValuationRowCopyWith<StockValuationRow> get copyWith => _$StockValuationRowCopyWithImpl<StockValuationRow>(this as StockValuationRow, _$identity);

  /// Serializes this StockValuationRow to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StockValuationRow&&(identical(other.productId, productId) || other.productId == productId)&&(identical(other.name, name) || other.name == name)&&(identical(other.stockCached, stockCached) || other.stockCached == stockCached)&&(identical(other.costPrice, costPrice) || other.costPrice == costPrice)&&(identical(other.valuation, valuation) || other.valuation == valuation)&&(identical(other.isLowStock, isLowStock) || other.isLowStock == isLowStock));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,productId,name,stockCached,costPrice,valuation,isLowStock);

@override
String toString() {
  return 'StockValuationRow(productId: $productId, name: $name, stockCached: $stockCached, costPrice: $costPrice, valuation: $valuation, isLowStock: $isLowStock)';
}


}

/// @nodoc
abstract mixin class $StockValuationRowCopyWith<$Res>  {
  factory $StockValuationRowCopyWith(StockValuationRow value, $Res Function(StockValuationRow) _then) = _$StockValuationRowCopyWithImpl;
@useResult
$Res call({
 String productId, String name, int stockCached, int costPrice, int valuation, bool isLowStock
});




}
/// @nodoc
class _$StockValuationRowCopyWithImpl<$Res>
    implements $StockValuationRowCopyWith<$Res> {
  _$StockValuationRowCopyWithImpl(this._self, this._then);

  final StockValuationRow _self;
  final $Res Function(StockValuationRow) _then;

/// Create a copy of StockValuationRow
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? productId = null,Object? name = null,Object? stockCached = null,Object? costPrice = null,Object? valuation = null,Object? isLowStock = null,}) {
  return _then(_self.copyWith(
productId: null == productId ? _self.productId : productId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,stockCached: null == stockCached ? _self.stockCached : stockCached // ignore: cast_nullable_to_non_nullable
as int,costPrice: null == costPrice ? _self.costPrice : costPrice // ignore: cast_nullable_to_non_nullable
as int,valuation: null == valuation ? _self.valuation : valuation // ignore: cast_nullable_to_non_nullable
as int,isLowStock: null == isLowStock ? _self.isLowStock : isLowStock // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [StockValuationRow].
extension StockValuationRowPatterns on StockValuationRow {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StockValuationRow value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StockValuationRow() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StockValuationRow value)  $default,){
final _that = this;
switch (_that) {
case _StockValuationRow():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StockValuationRow value)?  $default,){
final _that = this;
switch (_that) {
case _StockValuationRow() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String productId,  String name,  int stockCached,  int costPrice,  int valuation,  bool isLowStock)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StockValuationRow() when $default != null:
return $default(_that.productId,_that.name,_that.stockCached,_that.costPrice,_that.valuation,_that.isLowStock);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String productId,  String name,  int stockCached,  int costPrice,  int valuation,  bool isLowStock)  $default,) {final _that = this;
switch (_that) {
case _StockValuationRow():
return $default(_that.productId,_that.name,_that.stockCached,_that.costPrice,_that.valuation,_that.isLowStock);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String productId,  String name,  int stockCached,  int costPrice,  int valuation,  bool isLowStock)?  $default,) {final _that = this;
switch (_that) {
case _StockValuationRow() when $default != null:
return $default(_that.productId,_that.name,_that.stockCached,_that.costPrice,_that.valuation,_that.isLowStock);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _StockValuationRow implements StockValuationRow {
  const _StockValuationRow({required this.productId, required this.name, this.stockCached = 0, this.costPrice = 0, this.valuation = 0, this.isLowStock = false});
  factory _StockValuationRow.fromJson(Map<String, dynamic> json) => _$StockValuationRowFromJson(json);

@override final  String productId;
@override final  String name;
@override@JsonKey() final  int stockCached;
@override@JsonKey() final  int costPrice;
@override@JsonKey() final  int valuation;
@override@JsonKey() final  bool isLowStock;

/// Create a copy of StockValuationRow
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StockValuationRowCopyWith<_StockValuationRow> get copyWith => __$StockValuationRowCopyWithImpl<_StockValuationRow>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StockValuationRowToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StockValuationRow&&(identical(other.productId, productId) || other.productId == productId)&&(identical(other.name, name) || other.name == name)&&(identical(other.stockCached, stockCached) || other.stockCached == stockCached)&&(identical(other.costPrice, costPrice) || other.costPrice == costPrice)&&(identical(other.valuation, valuation) || other.valuation == valuation)&&(identical(other.isLowStock, isLowStock) || other.isLowStock == isLowStock));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,productId,name,stockCached,costPrice,valuation,isLowStock);

@override
String toString() {
  return 'StockValuationRow(productId: $productId, name: $name, stockCached: $stockCached, costPrice: $costPrice, valuation: $valuation, isLowStock: $isLowStock)';
}


}

/// @nodoc
abstract mixin class _$StockValuationRowCopyWith<$Res> implements $StockValuationRowCopyWith<$Res> {
  factory _$StockValuationRowCopyWith(_StockValuationRow value, $Res Function(_StockValuationRow) _then) = __$StockValuationRowCopyWithImpl;
@override @useResult
$Res call({
 String productId, String name, int stockCached, int costPrice, int valuation, bool isLowStock
});




}
/// @nodoc
class __$StockValuationRowCopyWithImpl<$Res>
    implements _$StockValuationRowCopyWith<$Res> {
  __$StockValuationRowCopyWithImpl(this._self, this._then);

  final _StockValuationRow _self;
  final $Res Function(_StockValuationRow) _then;

/// Create a copy of StockValuationRow
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? productId = null,Object? name = null,Object? stockCached = null,Object? costPrice = null,Object? valuation = null,Object? isLowStock = null,}) {
  return _then(_StockValuationRow(
productId: null == productId ? _self.productId : productId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,stockCached: null == stockCached ? _self.stockCached : stockCached // ignore: cast_nullable_to_non_nullable
as int,costPrice: null == costPrice ? _self.costPrice : costPrice // ignore: cast_nullable_to_non_nullable
as int,valuation: null == valuation ? _self.valuation : valuation // ignore: cast_nullable_to_non_nullable
as int,isLowStock: null == isLowStock ? _self.isLowStock : isLowStock // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
