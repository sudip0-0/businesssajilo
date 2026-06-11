// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'bill_item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BillItem {

 String get id; String get billId; String get productId; String get nameSnapshot; int get qty; int get rate; int get discount; int get lineTotal;
/// Create a copy of BillItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BillItemCopyWith<BillItem> get copyWith => _$BillItemCopyWithImpl<BillItem>(this as BillItem, _$identity);

  /// Serializes this BillItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BillItem&&(identical(other.id, id) || other.id == id)&&(identical(other.billId, billId) || other.billId == billId)&&(identical(other.productId, productId) || other.productId == productId)&&(identical(other.nameSnapshot, nameSnapshot) || other.nameSnapshot == nameSnapshot)&&(identical(other.qty, qty) || other.qty == qty)&&(identical(other.rate, rate) || other.rate == rate)&&(identical(other.discount, discount) || other.discount == discount)&&(identical(other.lineTotal, lineTotal) || other.lineTotal == lineTotal));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,billId,productId,nameSnapshot,qty,rate,discount,lineTotal);

@override
String toString() {
  return 'BillItem(id: $id, billId: $billId, productId: $productId, nameSnapshot: $nameSnapshot, qty: $qty, rate: $rate, discount: $discount, lineTotal: $lineTotal)';
}


}

/// @nodoc
abstract mixin class $BillItemCopyWith<$Res>  {
  factory $BillItemCopyWith(BillItem value, $Res Function(BillItem) _then) = _$BillItemCopyWithImpl;
@useResult
$Res call({
 String id, String billId, String productId, String nameSnapshot, int qty, int rate, int discount, int lineTotal
});




}
/// @nodoc
class _$BillItemCopyWithImpl<$Res>
    implements $BillItemCopyWith<$Res> {
  _$BillItemCopyWithImpl(this._self, this._then);

  final BillItem _self;
  final $Res Function(BillItem) _then;

/// Create a copy of BillItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? billId = null,Object? productId = null,Object? nameSnapshot = null,Object? qty = null,Object? rate = null,Object? discount = null,Object? lineTotal = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,billId: null == billId ? _self.billId : billId // ignore: cast_nullable_to_non_nullable
as String,productId: null == productId ? _self.productId : productId // ignore: cast_nullable_to_non_nullable
as String,nameSnapshot: null == nameSnapshot ? _self.nameSnapshot : nameSnapshot // ignore: cast_nullable_to_non_nullable
as String,qty: null == qty ? _self.qty : qty // ignore: cast_nullable_to_non_nullable
as int,rate: null == rate ? _self.rate : rate // ignore: cast_nullable_to_non_nullable
as int,discount: null == discount ? _self.discount : discount // ignore: cast_nullable_to_non_nullable
as int,lineTotal: null == lineTotal ? _self.lineTotal : lineTotal // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [BillItem].
extension BillItemPatterns on BillItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BillItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BillItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BillItem value)  $default,){
final _that = this;
switch (_that) {
case _BillItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BillItem value)?  $default,){
final _that = this;
switch (_that) {
case _BillItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String billId,  String productId,  String nameSnapshot,  int qty,  int rate,  int discount,  int lineTotal)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BillItem() when $default != null:
return $default(_that.id,_that.billId,_that.productId,_that.nameSnapshot,_that.qty,_that.rate,_that.discount,_that.lineTotal);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String billId,  String productId,  String nameSnapshot,  int qty,  int rate,  int discount,  int lineTotal)  $default,) {final _that = this;
switch (_that) {
case _BillItem():
return $default(_that.id,_that.billId,_that.productId,_that.nameSnapshot,_that.qty,_that.rate,_that.discount,_that.lineTotal);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String billId,  String productId,  String nameSnapshot,  int qty,  int rate,  int discount,  int lineTotal)?  $default,) {final _that = this;
switch (_that) {
case _BillItem() when $default != null:
return $default(_that.id,_that.billId,_that.productId,_that.nameSnapshot,_that.qty,_that.rate,_that.discount,_that.lineTotal);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BillItem implements BillItem {
  const _BillItem({required this.id, required this.billId, required this.productId, required this.nameSnapshot, required this.qty, this.rate = 0, this.discount = 0, this.lineTotal = 0});
  factory _BillItem.fromJson(Map<String, dynamic> json) => _$BillItemFromJson(json);

@override final  String id;
@override final  String billId;
@override final  String productId;
@override final  String nameSnapshot;
@override final  int qty;
@override@JsonKey() final  int rate;
@override@JsonKey() final  int discount;
@override@JsonKey() final  int lineTotal;

/// Create a copy of BillItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BillItemCopyWith<_BillItem> get copyWith => __$BillItemCopyWithImpl<_BillItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BillItemToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BillItem&&(identical(other.id, id) || other.id == id)&&(identical(other.billId, billId) || other.billId == billId)&&(identical(other.productId, productId) || other.productId == productId)&&(identical(other.nameSnapshot, nameSnapshot) || other.nameSnapshot == nameSnapshot)&&(identical(other.qty, qty) || other.qty == qty)&&(identical(other.rate, rate) || other.rate == rate)&&(identical(other.discount, discount) || other.discount == discount)&&(identical(other.lineTotal, lineTotal) || other.lineTotal == lineTotal));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,billId,productId,nameSnapshot,qty,rate,discount,lineTotal);

@override
String toString() {
  return 'BillItem(id: $id, billId: $billId, productId: $productId, nameSnapshot: $nameSnapshot, qty: $qty, rate: $rate, discount: $discount, lineTotal: $lineTotal)';
}


}

/// @nodoc
abstract mixin class _$BillItemCopyWith<$Res> implements $BillItemCopyWith<$Res> {
  factory _$BillItemCopyWith(_BillItem value, $Res Function(_BillItem) _then) = __$BillItemCopyWithImpl;
@override @useResult
$Res call({
 String id, String billId, String productId, String nameSnapshot, int qty, int rate, int discount, int lineTotal
});




}
/// @nodoc
class __$BillItemCopyWithImpl<$Res>
    implements _$BillItemCopyWith<$Res> {
  __$BillItemCopyWithImpl(this._self, this._then);

  final _BillItem _self;
  final $Res Function(_BillItem) _then;

/// Create a copy of BillItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? billId = null,Object? productId = null,Object? nameSnapshot = null,Object? qty = null,Object? rate = null,Object? discount = null,Object? lineTotal = null,}) {
  return _then(_BillItem(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,billId: null == billId ? _self.billId : billId // ignore: cast_nullable_to_non_nullable
as String,productId: null == productId ? _self.productId : productId // ignore: cast_nullable_to_non_nullable
as String,nameSnapshot: null == nameSnapshot ? _self.nameSnapshot : nameSnapshot // ignore: cast_nullable_to_non_nullable
as String,qty: null == qty ? _self.qty : qty // ignore: cast_nullable_to_non_nullable
as int,rate: null == rate ? _self.rate : rate // ignore: cast_nullable_to_non_nullable
as int,discount: null == discount ? _self.discount : discount // ignore: cast_nullable_to_non_nullable
as int,lineTotal: null == lineTotal ? _self.lineTotal : lineTotal // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
