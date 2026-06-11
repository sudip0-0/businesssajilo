// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'aging_customer_row.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AgingCustomerRow {

 String get customerId; String get shopName; int get balanceDue; DateTime get oldestDueAt; int get ageDays; String get bucket;
/// Create a copy of AgingCustomerRow
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AgingCustomerRowCopyWith<AgingCustomerRow> get copyWith => _$AgingCustomerRowCopyWithImpl<AgingCustomerRow>(this as AgingCustomerRow, _$identity);

  /// Serializes this AgingCustomerRow to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AgingCustomerRow&&(identical(other.customerId, customerId) || other.customerId == customerId)&&(identical(other.shopName, shopName) || other.shopName == shopName)&&(identical(other.balanceDue, balanceDue) || other.balanceDue == balanceDue)&&(identical(other.oldestDueAt, oldestDueAt) || other.oldestDueAt == oldestDueAt)&&(identical(other.ageDays, ageDays) || other.ageDays == ageDays)&&(identical(other.bucket, bucket) || other.bucket == bucket));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,customerId,shopName,balanceDue,oldestDueAt,ageDays,bucket);

@override
String toString() {
  return 'AgingCustomerRow(customerId: $customerId, shopName: $shopName, balanceDue: $balanceDue, oldestDueAt: $oldestDueAt, ageDays: $ageDays, bucket: $bucket)';
}


}

/// @nodoc
abstract mixin class $AgingCustomerRowCopyWith<$Res>  {
  factory $AgingCustomerRowCopyWith(AgingCustomerRow value, $Res Function(AgingCustomerRow) _then) = _$AgingCustomerRowCopyWithImpl;
@useResult
$Res call({
 String customerId, String shopName, int balanceDue, DateTime oldestDueAt, int ageDays, String bucket
});




}
/// @nodoc
class _$AgingCustomerRowCopyWithImpl<$Res>
    implements $AgingCustomerRowCopyWith<$Res> {
  _$AgingCustomerRowCopyWithImpl(this._self, this._then);

  final AgingCustomerRow _self;
  final $Res Function(AgingCustomerRow) _then;

/// Create a copy of AgingCustomerRow
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? customerId = null,Object? shopName = null,Object? balanceDue = null,Object? oldestDueAt = null,Object? ageDays = null,Object? bucket = null,}) {
  return _then(_self.copyWith(
customerId: null == customerId ? _self.customerId : customerId // ignore: cast_nullable_to_non_nullable
as String,shopName: null == shopName ? _self.shopName : shopName // ignore: cast_nullable_to_non_nullable
as String,balanceDue: null == balanceDue ? _self.balanceDue : balanceDue // ignore: cast_nullable_to_non_nullable
as int,oldestDueAt: null == oldestDueAt ? _self.oldestDueAt : oldestDueAt // ignore: cast_nullable_to_non_nullable
as DateTime,ageDays: null == ageDays ? _self.ageDays : ageDays // ignore: cast_nullable_to_non_nullable
as int,bucket: null == bucket ? _self.bucket : bucket // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [AgingCustomerRow].
extension AgingCustomerRowPatterns on AgingCustomerRow {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AgingCustomerRow value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AgingCustomerRow() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AgingCustomerRow value)  $default,){
final _that = this;
switch (_that) {
case _AgingCustomerRow():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AgingCustomerRow value)?  $default,){
final _that = this;
switch (_that) {
case _AgingCustomerRow() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String customerId,  String shopName,  int balanceDue,  DateTime oldestDueAt,  int ageDays,  String bucket)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AgingCustomerRow() when $default != null:
return $default(_that.customerId,_that.shopName,_that.balanceDue,_that.oldestDueAt,_that.ageDays,_that.bucket);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String customerId,  String shopName,  int balanceDue,  DateTime oldestDueAt,  int ageDays,  String bucket)  $default,) {final _that = this;
switch (_that) {
case _AgingCustomerRow():
return $default(_that.customerId,_that.shopName,_that.balanceDue,_that.oldestDueAt,_that.ageDays,_that.bucket);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String customerId,  String shopName,  int balanceDue,  DateTime oldestDueAt,  int ageDays,  String bucket)?  $default,) {final _that = this;
switch (_that) {
case _AgingCustomerRow() when $default != null:
return $default(_that.customerId,_that.shopName,_that.balanceDue,_that.oldestDueAt,_that.ageDays,_that.bucket);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AgingCustomerRow implements AgingCustomerRow {
  const _AgingCustomerRow({required this.customerId, required this.shopName, this.balanceDue = 0, required this.oldestDueAt, this.ageDays = 0, required this.bucket});
  factory _AgingCustomerRow.fromJson(Map<String, dynamic> json) => _$AgingCustomerRowFromJson(json);

@override final  String customerId;
@override final  String shopName;
@override@JsonKey() final  int balanceDue;
@override final  DateTime oldestDueAt;
@override@JsonKey() final  int ageDays;
@override final  String bucket;

/// Create a copy of AgingCustomerRow
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AgingCustomerRowCopyWith<_AgingCustomerRow> get copyWith => __$AgingCustomerRowCopyWithImpl<_AgingCustomerRow>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AgingCustomerRowToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AgingCustomerRow&&(identical(other.customerId, customerId) || other.customerId == customerId)&&(identical(other.shopName, shopName) || other.shopName == shopName)&&(identical(other.balanceDue, balanceDue) || other.balanceDue == balanceDue)&&(identical(other.oldestDueAt, oldestDueAt) || other.oldestDueAt == oldestDueAt)&&(identical(other.ageDays, ageDays) || other.ageDays == ageDays)&&(identical(other.bucket, bucket) || other.bucket == bucket));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,customerId,shopName,balanceDue,oldestDueAt,ageDays,bucket);

@override
String toString() {
  return 'AgingCustomerRow(customerId: $customerId, shopName: $shopName, balanceDue: $balanceDue, oldestDueAt: $oldestDueAt, ageDays: $ageDays, bucket: $bucket)';
}


}

/// @nodoc
abstract mixin class _$AgingCustomerRowCopyWith<$Res> implements $AgingCustomerRowCopyWith<$Res> {
  factory _$AgingCustomerRowCopyWith(_AgingCustomerRow value, $Res Function(_AgingCustomerRow) _then) = __$AgingCustomerRowCopyWithImpl;
@override @useResult
$Res call({
 String customerId, String shopName, int balanceDue, DateTime oldestDueAt, int ageDays, String bucket
});




}
/// @nodoc
class __$AgingCustomerRowCopyWithImpl<$Res>
    implements _$AgingCustomerRowCopyWith<$Res> {
  __$AgingCustomerRowCopyWithImpl(this._self, this._then);

  final _AgingCustomerRow _self;
  final $Res Function(_AgingCustomerRow) _then;

/// Create a copy of AgingCustomerRow
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? customerId = null,Object? shopName = null,Object? balanceDue = null,Object? oldestDueAt = null,Object? ageDays = null,Object? bucket = null,}) {
  return _then(_AgingCustomerRow(
customerId: null == customerId ? _self.customerId : customerId // ignore: cast_nullable_to_non_nullable
as String,shopName: null == shopName ? _self.shopName : shopName // ignore: cast_nullable_to_non_nullable
as String,balanceDue: null == balanceDue ? _self.balanceDue : balanceDue // ignore: cast_nullable_to_non_nullable
as int,oldestDueAt: null == oldestDueAt ? _self.oldestDueAt : oldestDueAt // ignore: cast_nullable_to_non_nullable
as DateTime,ageDays: null == ageDays ? _self.ageDays : ageDays // ignore: cast_nullable_to_non_nullable
as int,bucket: null == bucket ? _self.bucket : bucket // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
