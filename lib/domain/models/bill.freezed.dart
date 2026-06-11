// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'bill.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Bill {

 String get id; String get businessId; String? get customerId; String? get orderId; String get billNo; String? get devicePrefix; int get itemsTotal; int get discount; int get grandTotal; BillStatus get status; String get createdBy; DateTime? get createdAt; String? get customerShopName; List<BillItem> get items; bool get pendingSync;
/// Create a copy of Bill
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BillCopyWith<Bill> get copyWith => _$BillCopyWithImpl<Bill>(this as Bill, _$identity);

  /// Serializes this Bill to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Bill&&(identical(other.id, id) || other.id == id)&&(identical(other.businessId, businessId) || other.businessId == businessId)&&(identical(other.customerId, customerId) || other.customerId == customerId)&&(identical(other.orderId, orderId) || other.orderId == orderId)&&(identical(other.billNo, billNo) || other.billNo == billNo)&&(identical(other.devicePrefix, devicePrefix) || other.devicePrefix == devicePrefix)&&(identical(other.itemsTotal, itemsTotal) || other.itemsTotal == itemsTotal)&&(identical(other.discount, discount) || other.discount == discount)&&(identical(other.grandTotal, grandTotal) || other.grandTotal == grandTotal)&&(identical(other.status, status) || other.status == status)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.customerShopName, customerShopName) || other.customerShopName == customerShopName)&&const DeepCollectionEquality().equals(other.items, items)&&(identical(other.pendingSync, pendingSync) || other.pendingSync == pendingSync));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,businessId,customerId,orderId,billNo,devicePrefix,itemsTotal,discount,grandTotal,status,createdBy,createdAt,customerShopName,const DeepCollectionEquality().hash(items),pendingSync);

@override
String toString() {
  return 'Bill(id: $id, businessId: $businessId, customerId: $customerId, orderId: $orderId, billNo: $billNo, devicePrefix: $devicePrefix, itemsTotal: $itemsTotal, discount: $discount, grandTotal: $grandTotal, status: $status, createdBy: $createdBy, createdAt: $createdAt, customerShopName: $customerShopName, items: $items, pendingSync: $pendingSync)';
}


}

/// @nodoc
abstract mixin class $BillCopyWith<$Res>  {
  factory $BillCopyWith(Bill value, $Res Function(Bill) _then) = _$BillCopyWithImpl;
@useResult
$Res call({
 String id, String businessId, String? customerId, String? orderId, String billNo, String? devicePrefix, int itemsTotal, int discount, int grandTotal, BillStatus status, String createdBy, DateTime? createdAt, String? customerShopName, List<BillItem> items, bool pendingSync
});




}
/// @nodoc
class _$BillCopyWithImpl<$Res>
    implements $BillCopyWith<$Res> {
  _$BillCopyWithImpl(this._self, this._then);

  final Bill _self;
  final $Res Function(Bill) _then;

/// Create a copy of Bill
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? businessId = null,Object? customerId = freezed,Object? orderId = freezed,Object? billNo = null,Object? devicePrefix = freezed,Object? itemsTotal = null,Object? discount = null,Object? grandTotal = null,Object? status = null,Object? createdBy = null,Object? createdAt = freezed,Object? customerShopName = freezed,Object? items = null,Object? pendingSync = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,businessId: null == businessId ? _self.businessId : businessId // ignore: cast_nullable_to_non_nullable
as String,customerId: freezed == customerId ? _self.customerId : customerId // ignore: cast_nullable_to_non_nullable
as String?,orderId: freezed == orderId ? _self.orderId : orderId // ignore: cast_nullable_to_non_nullable
as String?,billNo: null == billNo ? _self.billNo : billNo // ignore: cast_nullable_to_non_nullable
as String,devicePrefix: freezed == devicePrefix ? _self.devicePrefix : devicePrefix // ignore: cast_nullable_to_non_nullable
as String?,itemsTotal: null == itemsTotal ? _self.itemsTotal : itemsTotal // ignore: cast_nullable_to_non_nullable
as int,discount: null == discount ? _self.discount : discount // ignore: cast_nullable_to_non_nullable
as int,grandTotal: null == grandTotal ? _self.grandTotal : grandTotal // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as BillStatus,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,customerShopName: freezed == customerShopName ? _self.customerShopName : customerShopName // ignore: cast_nullable_to_non_nullable
as String?,items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<BillItem>,pendingSync: null == pendingSync ? _self.pendingSync : pendingSync // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [Bill].
extension BillPatterns on Bill {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Bill value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Bill() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Bill value)  $default,){
final _that = this;
switch (_that) {
case _Bill():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Bill value)?  $default,){
final _that = this;
switch (_that) {
case _Bill() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String businessId,  String? customerId,  String? orderId,  String billNo,  String? devicePrefix,  int itemsTotal,  int discount,  int grandTotal,  BillStatus status,  String createdBy,  DateTime? createdAt,  String? customerShopName,  List<BillItem> items,  bool pendingSync)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Bill() when $default != null:
return $default(_that.id,_that.businessId,_that.customerId,_that.orderId,_that.billNo,_that.devicePrefix,_that.itemsTotal,_that.discount,_that.grandTotal,_that.status,_that.createdBy,_that.createdAt,_that.customerShopName,_that.items,_that.pendingSync);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String businessId,  String? customerId,  String? orderId,  String billNo,  String? devicePrefix,  int itemsTotal,  int discount,  int grandTotal,  BillStatus status,  String createdBy,  DateTime? createdAt,  String? customerShopName,  List<BillItem> items,  bool pendingSync)  $default,) {final _that = this;
switch (_that) {
case _Bill():
return $default(_that.id,_that.businessId,_that.customerId,_that.orderId,_that.billNo,_that.devicePrefix,_that.itemsTotal,_that.discount,_that.grandTotal,_that.status,_that.createdBy,_that.createdAt,_that.customerShopName,_that.items,_that.pendingSync);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String businessId,  String? customerId,  String? orderId,  String billNo,  String? devicePrefix,  int itemsTotal,  int discount,  int grandTotal,  BillStatus status,  String createdBy,  DateTime? createdAt,  String? customerShopName,  List<BillItem> items,  bool pendingSync)?  $default,) {final _that = this;
switch (_that) {
case _Bill() when $default != null:
return $default(_that.id,_that.businessId,_that.customerId,_that.orderId,_that.billNo,_that.devicePrefix,_that.itemsTotal,_that.discount,_that.grandTotal,_that.status,_that.createdBy,_that.createdAt,_that.customerShopName,_that.items,_that.pendingSync);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Bill implements Bill {
  const _Bill({required this.id, required this.businessId, this.customerId, this.orderId, required this.billNo, this.devicePrefix, this.itemsTotal = 0, this.discount = 0, this.grandTotal = 0, required this.status, required this.createdBy, this.createdAt, this.customerShopName, final  List<BillItem> items = const [], this.pendingSync = false}): _items = items;
  factory _Bill.fromJson(Map<String, dynamic> json) => _$BillFromJson(json);

@override final  String id;
@override final  String businessId;
@override final  String? customerId;
@override final  String? orderId;
@override final  String billNo;
@override final  String? devicePrefix;
@override@JsonKey() final  int itemsTotal;
@override@JsonKey() final  int discount;
@override@JsonKey() final  int grandTotal;
@override final  BillStatus status;
@override final  String createdBy;
@override final  DateTime? createdAt;
@override final  String? customerShopName;
 final  List<BillItem> _items;
@override@JsonKey() List<BillItem> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

@override@JsonKey() final  bool pendingSync;

/// Create a copy of Bill
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BillCopyWith<_Bill> get copyWith => __$BillCopyWithImpl<_Bill>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BillToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Bill&&(identical(other.id, id) || other.id == id)&&(identical(other.businessId, businessId) || other.businessId == businessId)&&(identical(other.customerId, customerId) || other.customerId == customerId)&&(identical(other.orderId, orderId) || other.orderId == orderId)&&(identical(other.billNo, billNo) || other.billNo == billNo)&&(identical(other.devicePrefix, devicePrefix) || other.devicePrefix == devicePrefix)&&(identical(other.itemsTotal, itemsTotal) || other.itemsTotal == itemsTotal)&&(identical(other.discount, discount) || other.discount == discount)&&(identical(other.grandTotal, grandTotal) || other.grandTotal == grandTotal)&&(identical(other.status, status) || other.status == status)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.customerShopName, customerShopName) || other.customerShopName == customerShopName)&&const DeepCollectionEquality().equals(other._items, _items)&&(identical(other.pendingSync, pendingSync) || other.pendingSync == pendingSync));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,businessId,customerId,orderId,billNo,devicePrefix,itemsTotal,discount,grandTotal,status,createdBy,createdAt,customerShopName,const DeepCollectionEquality().hash(_items),pendingSync);

@override
String toString() {
  return 'Bill(id: $id, businessId: $businessId, customerId: $customerId, orderId: $orderId, billNo: $billNo, devicePrefix: $devicePrefix, itemsTotal: $itemsTotal, discount: $discount, grandTotal: $grandTotal, status: $status, createdBy: $createdBy, createdAt: $createdAt, customerShopName: $customerShopName, items: $items, pendingSync: $pendingSync)';
}


}

/// @nodoc
abstract mixin class _$BillCopyWith<$Res> implements $BillCopyWith<$Res> {
  factory _$BillCopyWith(_Bill value, $Res Function(_Bill) _then) = __$BillCopyWithImpl;
@override @useResult
$Res call({
 String id, String businessId, String? customerId, String? orderId, String billNo, String? devicePrefix, int itemsTotal, int discount, int grandTotal, BillStatus status, String createdBy, DateTime? createdAt, String? customerShopName, List<BillItem> items, bool pendingSync
});




}
/// @nodoc
class __$BillCopyWithImpl<$Res>
    implements _$BillCopyWith<$Res> {
  __$BillCopyWithImpl(this._self, this._then);

  final _Bill _self;
  final $Res Function(_Bill) _then;

/// Create a copy of Bill
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? businessId = null,Object? customerId = freezed,Object? orderId = freezed,Object? billNo = null,Object? devicePrefix = freezed,Object? itemsTotal = null,Object? discount = null,Object? grandTotal = null,Object? status = null,Object? createdBy = null,Object? createdAt = freezed,Object? customerShopName = freezed,Object? items = null,Object? pendingSync = null,}) {
  return _then(_Bill(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,businessId: null == businessId ? _self.businessId : businessId // ignore: cast_nullable_to_non_nullable
as String,customerId: freezed == customerId ? _self.customerId : customerId // ignore: cast_nullable_to_non_nullable
as String?,orderId: freezed == orderId ? _self.orderId : orderId // ignore: cast_nullable_to_non_nullable
as String?,billNo: null == billNo ? _self.billNo : billNo // ignore: cast_nullable_to_non_nullable
as String,devicePrefix: freezed == devicePrefix ? _self.devicePrefix : devicePrefix // ignore: cast_nullable_to_non_nullable
as String?,itemsTotal: null == itemsTotal ? _self.itemsTotal : itemsTotal // ignore: cast_nullable_to_non_nullable
as int,discount: null == discount ? _self.discount : discount // ignore: cast_nullable_to_non_nullable
as int,grandTotal: null == grandTotal ? _self.grandTotal : grandTotal // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as BillStatus,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,customerShopName: freezed == customerShopName ? _self.customerShopName : customerShopName // ignore: cast_nullable_to_non_nullable
as String?,items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<BillItem>,pendingSync: null == pendingSync ? _self.pendingSync : pendingSync // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
