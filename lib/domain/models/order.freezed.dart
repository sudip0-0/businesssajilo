// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'order.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Order {

 String get id; String get businessId; String get customerId; OrderStatus get status; String? get customerNote; DateTime? get createdAt; DateTime? get updatedAt; String? get customerShopName; List<OrderItem> get items;
/// Create a copy of Order
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OrderCopyWith<Order> get copyWith => _$OrderCopyWithImpl<Order>(this as Order, _$identity);

  /// Serializes this Order to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Order&&(identical(other.id, id) || other.id == id)&&(identical(other.businessId, businessId) || other.businessId == businessId)&&(identical(other.customerId, customerId) || other.customerId == customerId)&&(identical(other.status, status) || other.status == status)&&(identical(other.customerNote, customerNote) || other.customerNote == customerNote)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.customerShopName, customerShopName) || other.customerShopName == customerShopName)&&const DeepCollectionEquality().equals(other.items, items));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,businessId,customerId,status,customerNote,createdAt,updatedAt,customerShopName,const DeepCollectionEquality().hash(items));

@override
String toString() {
  return 'Order(id: $id, businessId: $businessId, customerId: $customerId, status: $status, customerNote: $customerNote, createdAt: $createdAt, updatedAt: $updatedAt, customerShopName: $customerShopName, items: $items)';
}


}

/// @nodoc
abstract mixin class $OrderCopyWith<$Res>  {
  factory $OrderCopyWith(Order value, $Res Function(Order) _then) = _$OrderCopyWithImpl;
@useResult
$Res call({
 String id, String businessId, String customerId, OrderStatus status, String? customerNote, DateTime? createdAt, DateTime? updatedAt, String? customerShopName, List<OrderItem> items
});




}
/// @nodoc
class _$OrderCopyWithImpl<$Res>
    implements $OrderCopyWith<$Res> {
  _$OrderCopyWithImpl(this._self, this._then);

  final Order _self;
  final $Res Function(Order) _then;

/// Create a copy of Order
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? businessId = null,Object? customerId = null,Object? status = null,Object? customerNote = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,Object? customerShopName = freezed,Object? items = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,businessId: null == businessId ? _self.businessId : businessId // ignore: cast_nullable_to_non_nullable
as String,customerId: null == customerId ? _self.customerId : customerId // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as OrderStatus,customerNote: freezed == customerNote ? _self.customerNote : customerNote // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,customerShopName: freezed == customerShopName ? _self.customerShopName : customerShopName // ignore: cast_nullable_to_non_nullable
as String?,items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<OrderItem>,
  ));
}

}


/// Adds pattern-matching-related methods to [Order].
extension OrderPatterns on Order {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Order value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Order() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Order value)  $default,){
final _that = this;
switch (_that) {
case _Order():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Order value)?  $default,){
final _that = this;
switch (_that) {
case _Order() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String businessId,  String customerId,  OrderStatus status,  String? customerNote,  DateTime? createdAt,  DateTime? updatedAt,  String? customerShopName,  List<OrderItem> items)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Order() when $default != null:
return $default(_that.id,_that.businessId,_that.customerId,_that.status,_that.customerNote,_that.createdAt,_that.updatedAt,_that.customerShopName,_that.items);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String businessId,  String customerId,  OrderStatus status,  String? customerNote,  DateTime? createdAt,  DateTime? updatedAt,  String? customerShopName,  List<OrderItem> items)  $default,) {final _that = this;
switch (_that) {
case _Order():
return $default(_that.id,_that.businessId,_that.customerId,_that.status,_that.customerNote,_that.createdAt,_that.updatedAt,_that.customerShopName,_that.items);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String businessId,  String customerId,  OrderStatus status,  String? customerNote,  DateTime? createdAt,  DateTime? updatedAt,  String? customerShopName,  List<OrderItem> items)?  $default,) {final _that = this;
switch (_that) {
case _Order() when $default != null:
return $default(_that.id,_that.businessId,_that.customerId,_that.status,_that.customerNote,_that.createdAt,_that.updatedAt,_that.customerShopName,_that.items);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Order implements Order {
  const _Order({required this.id, required this.businessId, required this.customerId, required this.status, this.customerNote, this.createdAt, this.updatedAt, this.customerShopName, final  List<OrderItem> items = const []}): _items = items;
  factory _Order.fromJson(Map<String, dynamic> json) => _$OrderFromJson(json);

@override final  String id;
@override final  String businessId;
@override final  String customerId;
@override final  OrderStatus status;
@override final  String? customerNote;
@override final  DateTime? createdAt;
@override final  DateTime? updatedAt;
@override final  String? customerShopName;
 final  List<OrderItem> _items;
@override@JsonKey() List<OrderItem> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}


/// Create a copy of Order
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OrderCopyWith<_Order> get copyWith => __$OrderCopyWithImpl<_Order>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OrderToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Order&&(identical(other.id, id) || other.id == id)&&(identical(other.businessId, businessId) || other.businessId == businessId)&&(identical(other.customerId, customerId) || other.customerId == customerId)&&(identical(other.status, status) || other.status == status)&&(identical(other.customerNote, customerNote) || other.customerNote == customerNote)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.customerShopName, customerShopName) || other.customerShopName == customerShopName)&&const DeepCollectionEquality().equals(other._items, _items));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,businessId,customerId,status,customerNote,createdAt,updatedAt,customerShopName,const DeepCollectionEquality().hash(_items));

@override
String toString() {
  return 'Order(id: $id, businessId: $businessId, customerId: $customerId, status: $status, customerNote: $customerNote, createdAt: $createdAt, updatedAt: $updatedAt, customerShopName: $customerShopName, items: $items)';
}


}

/// @nodoc
abstract mixin class _$OrderCopyWith<$Res> implements $OrderCopyWith<$Res> {
  factory _$OrderCopyWith(_Order value, $Res Function(_Order) _then) = __$OrderCopyWithImpl;
@override @useResult
$Res call({
 String id, String businessId, String customerId, OrderStatus status, String? customerNote, DateTime? createdAt, DateTime? updatedAt, String? customerShopName, List<OrderItem> items
});




}
/// @nodoc
class __$OrderCopyWithImpl<$Res>
    implements _$OrderCopyWith<$Res> {
  __$OrderCopyWithImpl(this._self, this._then);

  final _Order _self;
  final $Res Function(_Order) _then;

/// Create a copy of Order
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? businessId = null,Object? customerId = null,Object? status = null,Object? customerNote = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,Object? customerShopName = freezed,Object? items = null,}) {
  return _then(_Order(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,businessId: null == businessId ? _self.businessId : businessId // ignore: cast_nullable_to_non_nullable
as String,customerId: null == customerId ? _self.customerId : customerId // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as OrderStatus,customerNote: freezed == customerNote ? _self.customerNote : customerNote // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,customerShopName: freezed == customerShopName ? _self.customerShopName : customerShopName // ignore: cast_nullable_to_non_nullable
as String?,items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<OrderItem>,
  ));
}


}

// dart format on
