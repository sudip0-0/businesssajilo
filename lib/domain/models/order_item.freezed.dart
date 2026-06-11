// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'order_item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$OrderItem {

 String get id; String get orderId; String get productId; int get qty; String? get productName; String? get productNameNp; String? get unit; String? get imageUrl;
/// Create a copy of OrderItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OrderItemCopyWith<OrderItem> get copyWith => _$OrderItemCopyWithImpl<OrderItem>(this as OrderItem, _$identity);

  /// Serializes this OrderItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OrderItem&&(identical(other.id, id) || other.id == id)&&(identical(other.orderId, orderId) || other.orderId == orderId)&&(identical(other.productId, productId) || other.productId == productId)&&(identical(other.qty, qty) || other.qty == qty)&&(identical(other.productName, productName) || other.productName == productName)&&(identical(other.productNameNp, productNameNp) || other.productNameNp == productNameNp)&&(identical(other.unit, unit) || other.unit == unit)&&(identical(other.imageUrl, imageUrl) || other.imageUrl == imageUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,orderId,productId,qty,productName,productNameNp,unit,imageUrl);

@override
String toString() {
  return 'OrderItem(id: $id, orderId: $orderId, productId: $productId, qty: $qty, productName: $productName, productNameNp: $productNameNp, unit: $unit, imageUrl: $imageUrl)';
}


}

/// @nodoc
abstract mixin class $OrderItemCopyWith<$Res>  {
  factory $OrderItemCopyWith(OrderItem value, $Res Function(OrderItem) _then) = _$OrderItemCopyWithImpl;
@useResult
$Res call({
 String id, String orderId, String productId, int qty, String? productName, String? productNameNp, String? unit, String? imageUrl
});




}
/// @nodoc
class _$OrderItemCopyWithImpl<$Res>
    implements $OrderItemCopyWith<$Res> {
  _$OrderItemCopyWithImpl(this._self, this._then);

  final OrderItem _self;
  final $Res Function(OrderItem) _then;

/// Create a copy of OrderItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? orderId = null,Object? productId = null,Object? qty = null,Object? productName = freezed,Object? productNameNp = freezed,Object? unit = freezed,Object? imageUrl = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,orderId: null == orderId ? _self.orderId : orderId // ignore: cast_nullable_to_non_nullable
as String,productId: null == productId ? _self.productId : productId // ignore: cast_nullable_to_non_nullable
as String,qty: null == qty ? _self.qty : qty // ignore: cast_nullable_to_non_nullable
as int,productName: freezed == productName ? _self.productName : productName // ignore: cast_nullable_to_non_nullable
as String?,productNameNp: freezed == productNameNp ? _self.productNameNp : productNameNp // ignore: cast_nullable_to_non_nullable
as String?,unit: freezed == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as String?,imageUrl: freezed == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [OrderItem].
extension OrderItemPatterns on OrderItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OrderItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OrderItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OrderItem value)  $default,){
final _that = this;
switch (_that) {
case _OrderItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OrderItem value)?  $default,){
final _that = this;
switch (_that) {
case _OrderItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String orderId,  String productId,  int qty,  String? productName,  String? productNameNp,  String? unit,  String? imageUrl)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OrderItem() when $default != null:
return $default(_that.id,_that.orderId,_that.productId,_that.qty,_that.productName,_that.productNameNp,_that.unit,_that.imageUrl);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String orderId,  String productId,  int qty,  String? productName,  String? productNameNp,  String? unit,  String? imageUrl)  $default,) {final _that = this;
switch (_that) {
case _OrderItem():
return $default(_that.id,_that.orderId,_that.productId,_that.qty,_that.productName,_that.productNameNp,_that.unit,_that.imageUrl);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String orderId,  String productId,  int qty,  String? productName,  String? productNameNp,  String? unit,  String? imageUrl)?  $default,) {final _that = this;
switch (_that) {
case _OrderItem() when $default != null:
return $default(_that.id,_that.orderId,_that.productId,_that.qty,_that.productName,_that.productNameNp,_that.unit,_that.imageUrl);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _OrderItem implements OrderItem {
  const _OrderItem({required this.id, required this.orderId, required this.productId, required this.qty, this.productName, this.productNameNp, this.unit, this.imageUrl});
  factory _OrderItem.fromJson(Map<String, dynamic> json) => _$OrderItemFromJson(json);

@override final  String id;
@override final  String orderId;
@override final  String productId;
@override final  int qty;
@override final  String? productName;
@override final  String? productNameNp;
@override final  String? unit;
@override final  String? imageUrl;

/// Create a copy of OrderItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OrderItemCopyWith<_OrderItem> get copyWith => __$OrderItemCopyWithImpl<_OrderItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OrderItemToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OrderItem&&(identical(other.id, id) || other.id == id)&&(identical(other.orderId, orderId) || other.orderId == orderId)&&(identical(other.productId, productId) || other.productId == productId)&&(identical(other.qty, qty) || other.qty == qty)&&(identical(other.productName, productName) || other.productName == productName)&&(identical(other.productNameNp, productNameNp) || other.productNameNp == productNameNp)&&(identical(other.unit, unit) || other.unit == unit)&&(identical(other.imageUrl, imageUrl) || other.imageUrl == imageUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,orderId,productId,qty,productName,productNameNp,unit,imageUrl);

@override
String toString() {
  return 'OrderItem(id: $id, orderId: $orderId, productId: $productId, qty: $qty, productName: $productName, productNameNp: $productNameNp, unit: $unit, imageUrl: $imageUrl)';
}


}

/// @nodoc
abstract mixin class _$OrderItemCopyWith<$Res> implements $OrderItemCopyWith<$Res> {
  factory _$OrderItemCopyWith(_OrderItem value, $Res Function(_OrderItem) _then) = __$OrderItemCopyWithImpl;
@override @useResult
$Res call({
 String id, String orderId, String productId, int qty, String? productName, String? productNameNp, String? unit, String? imageUrl
});




}
/// @nodoc
class __$OrderItemCopyWithImpl<$Res>
    implements _$OrderItemCopyWith<$Res> {
  __$OrderItemCopyWithImpl(this._self, this._then);

  final _OrderItem _self;
  final $Res Function(_OrderItem) _then;

/// Create a copy of OrderItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? orderId = null,Object? productId = null,Object? qty = null,Object? productName = freezed,Object? productNameNp = freezed,Object? unit = freezed,Object? imageUrl = freezed,}) {
  return _then(_OrderItem(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,orderId: null == orderId ? _self.orderId : orderId // ignore: cast_nullable_to_non_nullable
as String,productId: null == productId ? _self.productId : productId // ignore: cast_nullable_to_non_nullable
as String,qty: null == qty ? _self.qty : qty // ignore: cast_nullable_to_non_nullable
as int,productName: freezed == productName ? _self.productName : productName // ignore: cast_nullable_to_non_nullable
as String?,productNameNp: freezed == productNameNp ? _self.productNameNp : productNameNp // ignore: cast_nullable_to_non_nullable
as String?,unit: freezed == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as String?,imageUrl: freezed == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
