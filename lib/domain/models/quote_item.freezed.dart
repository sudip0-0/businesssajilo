// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'quote_item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$QuoteItem {

 String get id; String get quoteId; String get productId; int get qty; int get rate; int get discount; int get lineTotal; String? get productName;
/// Create a copy of QuoteItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$QuoteItemCopyWith<QuoteItem> get copyWith => _$QuoteItemCopyWithImpl<QuoteItem>(this as QuoteItem, _$identity);

  /// Serializes this QuoteItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is QuoteItem&&(identical(other.id, id) || other.id == id)&&(identical(other.quoteId, quoteId) || other.quoteId == quoteId)&&(identical(other.productId, productId) || other.productId == productId)&&(identical(other.qty, qty) || other.qty == qty)&&(identical(other.rate, rate) || other.rate == rate)&&(identical(other.discount, discount) || other.discount == discount)&&(identical(other.lineTotal, lineTotal) || other.lineTotal == lineTotal)&&(identical(other.productName, productName) || other.productName == productName));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,quoteId,productId,qty,rate,discount,lineTotal,productName);

@override
String toString() {
  return 'QuoteItem(id: $id, quoteId: $quoteId, productId: $productId, qty: $qty, rate: $rate, discount: $discount, lineTotal: $lineTotal, productName: $productName)';
}


}

/// @nodoc
abstract mixin class $QuoteItemCopyWith<$Res>  {
  factory $QuoteItemCopyWith(QuoteItem value, $Res Function(QuoteItem) _then) = _$QuoteItemCopyWithImpl;
@useResult
$Res call({
 String id, String quoteId, String productId, int qty, int rate, int discount, int lineTotal, String? productName
});




}
/// @nodoc
class _$QuoteItemCopyWithImpl<$Res>
    implements $QuoteItemCopyWith<$Res> {
  _$QuoteItemCopyWithImpl(this._self, this._then);

  final QuoteItem _self;
  final $Res Function(QuoteItem) _then;

/// Create a copy of QuoteItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? quoteId = null,Object? productId = null,Object? qty = null,Object? rate = null,Object? discount = null,Object? lineTotal = null,Object? productName = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,quoteId: null == quoteId ? _self.quoteId : quoteId // ignore: cast_nullable_to_non_nullable
as String,productId: null == productId ? _self.productId : productId // ignore: cast_nullable_to_non_nullable
as String,qty: null == qty ? _self.qty : qty // ignore: cast_nullable_to_non_nullable
as int,rate: null == rate ? _self.rate : rate // ignore: cast_nullable_to_non_nullable
as int,discount: null == discount ? _self.discount : discount // ignore: cast_nullable_to_non_nullable
as int,lineTotal: null == lineTotal ? _self.lineTotal : lineTotal // ignore: cast_nullable_to_non_nullable
as int,productName: freezed == productName ? _self.productName : productName // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [QuoteItem].
extension QuoteItemPatterns on QuoteItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _QuoteItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _QuoteItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _QuoteItem value)  $default,){
final _that = this;
switch (_that) {
case _QuoteItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _QuoteItem value)?  $default,){
final _that = this;
switch (_that) {
case _QuoteItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String quoteId,  String productId,  int qty,  int rate,  int discount,  int lineTotal,  String? productName)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _QuoteItem() when $default != null:
return $default(_that.id,_that.quoteId,_that.productId,_that.qty,_that.rate,_that.discount,_that.lineTotal,_that.productName);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String quoteId,  String productId,  int qty,  int rate,  int discount,  int lineTotal,  String? productName)  $default,) {final _that = this;
switch (_that) {
case _QuoteItem():
return $default(_that.id,_that.quoteId,_that.productId,_that.qty,_that.rate,_that.discount,_that.lineTotal,_that.productName);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String quoteId,  String productId,  int qty,  int rate,  int discount,  int lineTotal,  String? productName)?  $default,) {final _that = this;
switch (_that) {
case _QuoteItem() when $default != null:
return $default(_that.id,_that.quoteId,_that.productId,_that.qty,_that.rate,_that.discount,_that.lineTotal,_that.productName);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _QuoteItem implements QuoteItem {
  const _QuoteItem({required this.id, required this.quoteId, required this.productId, required this.qty, this.rate = 0, this.discount = 0, this.lineTotal = 0, this.productName});
  factory _QuoteItem.fromJson(Map<String, dynamic> json) => _$QuoteItemFromJson(json);

@override final  String id;
@override final  String quoteId;
@override final  String productId;
@override final  int qty;
@override@JsonKey() final  int rate;
@override@JsonKey() final  int discount;
@override@JsonKey() final  int lineTotal;
@override final  String? productName;

/// Create a copy of QuoteItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$QuoteItemCopyWith<_QuoteItem> get copyWith => __$QuoteItemCopyWithImpl<_QuoteItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$QuoteItemToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _QuoteItem&&(identical(other.id, id) || other.id == id)&&(identical(other.quoteId, quoteId) || other.quoteId == quoteId)&&(identical(other.productId, productId) || other.productId == productId)&&(identical(other.qty, qty) || other.qty == qty)&&(identical(other.rate, rate) || other.rate == rate)&&(identical(other.discount, discount) || other.discount == discount)&&(identical(other.lineTotal, lineTotal) || other.lineTotal == lineTotal)&&(identical(other.productName, productName) || other.productName == productName));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,quoteId,productId,qty,rate,discount,lineTotal,productName);

@override
String toString() {
  return 'QuoteItem(id: $id, quoteId: $quoteId, productId: $productId, qty: $qty, rate: $rate, discount: $discount, lineTotal: $lineTotal, productName: $productName)';
}


}

/// @nodoc
abstract mixin class _$QuoteItemCopyWith<$Res> implements $QuoteItemCopyWith<$Res> {
  factory _$QuoteItemCopyWith(_QuoteItem value, $Res Function(_QuoteItem) _then) = __$QuoteItemCopyWithImpl;
@override @useResult
$Res call({
 String id, String quoteId, String productId, int qty, int rate, int discount, int lineTotal, String? productName
});




}
/// @nodoc
class __$QuoteItemCopyWithImpl<$Res>
    implements _$QuoteItemCopyWith<$Res> {
  __$QuoteItemCopyWithImpl(this._self, this._then);

  final _QuoteItem _self;
  final $Res Function(_QuoteItem) _then;

/// Create a copy of QuoteItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? quoteId = null,Object? productId = null,Object? qty = null,Object? rate = null,Object? discount = null,Object? lineTotal = null,Object? productName = freezed,}) {
  return _then(_QuoteItem(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,quoteId: null == quoteId ? _self.quoteId : quoteId // ignore: cast_nullable_to_non_nullable
as String,productId: null == productId ? _self.productId : productId // ignore: cast_nullable_to_non_nullable
as String,qty: null == qty ? _self.qty : qty // ignore: cast_nullable_to_non_nullable
as int,rate: null == rate ? _self.rate : rate // ignore: cast_nullable_to_non_nullable
as int,discount: null == discount ? _self.discount : discount // ignore: cast_nullable_to_non_nullable
as int,lineTotal: null == lineTotal ? _self.lineTotal : lineTotal // ignore: cast_nullable_to_non_nullable
as int,productName: freezed == productName ? _self.productName : productName // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
