// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'top_customer_row.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TopCustomerRow {

 String get customerId; String get shopName; int get billCount; int get revenue;
/// Create a copy of TopCustomerRow
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TopCustomerRowCopyWith<TopCustomerRow> get copyWith => _$TopCustomerRowCopyWithImpl<TopCustomerRow>(this as TopCustomerRow, _$identity);

  /// Serializes this TopCustomerRow to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TopCustomerRow&&(identical(other.customerId, customerId) || other.customerId == customerId)&&(identical(other.shopName, shopName) || other.shopName == shopName)&&(identical(other.billCount, billCount) || other.billCount == billCount)&&(identical(other.revenue, revenue) || other.revenue == revenue));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,customerId,shopName,billCount,revenue);

@override
String toString() {
  return 'TopCustomerRow(customerId: $customerId, shopName: $shopName, billCount: $billCount, revenue: $revenue)';
}


}

/// @nodoc
abstract mixin class $TopCustomerRowCopyWith<$Res>  {
  factory $TopCustomerRowCopyWith(TopCustomerRow value, $Res Function(TopCustomerRow) _then) = _$TopCustomerRowCopyWithImpl;
@useResult
$Res call({
 String customerId, String shopName, int billCount, int revenue
});




}
/// @nodoc
class _$TopCustomerRowCopyWithImpl<$Res>
    implements $TopCustomerRowCopyWith<$Res> {
  _$TopCustomerRowCopyWithImpl(this._self, this._then);

  final TopCustomerRow _self;
  final $Res Function(TopCustomerRow) _then;

/// Create a copy of TopCustomerRow
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? customerId = null,Object? shopName = null,Object? billCount = null,Object? revenue = null,}) {
  return _then(_self.copyWith(
customerId: null == customerId ? _self.customerId : customerId // ignore: cast_nullable_to_non_nullable
as String,shopName: null == shopName ? _self.shopName : shopName // ignore: cast_nullable_to_non_nullable
as String,billCount: null == billCount ? _self.billCount : billCount // ignore: cast_nullable_to_non_nullable
as int,revenue: null == revenue ? _self.revenue : revenue // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [TopCustomerRow].
extension TopCustomerRowPatterns on TopCustomerRow {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TopCustomerRow value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TopCustomerRow() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TopCustomerRow value)  $default,){
final _that = this;
switch (_that) {
case _TopCustomerRow():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TopCustomerRow value)?  $default,){
final _that = this;
switch (_that) {
case _TopCustomerRow() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String customerId,  String shopName,  int billCount,  int revenue)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TopCustomerRow() when $default != null:
return $default(_that.customerId,_that.shopName,_that.billCount,_that.revenue);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String customerId,  String shopName,  int billCount,  int revenue)  $default,) {final _that = this;
switch (_that) {
case _TopCustomerRow():
return $default(_that.customerId,_that.shopName,_that.billCount,_that.revenue);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String customerId,  String shopName,  int billCount,  int revenue)?  $default,) {final _that = this;
switch (_that) {
case _TopCustomerRow() when $default != null:
return $default(_that.customerId,_that.shopName,_that.billCount,_that.revenue);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TopCustomerRow implements TopCustomerRow {
  const _TopCustomerRow({required this.customerId, required this.shopName, this.billCount = 0, this.revenue = 0});
  factory _TopCustomerRow.fromJson(Map<String, dynamic> json) => _$TopCustomerRowFromJson(json);

@override final  String customerId;
@override final  String shopName;
@override@JsonKey() final  int billCount;
@override@JsonKey() final  int revenue;

/// Create a copy of TopCustomerRow
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TopCustomerRowCopyWith<_TopCustomerRow> get copyWith => __$TopCustomerRowCopyWithImpl<_TopCustomerRow>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TopCustomerRowToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TopCustomerRow&&(identical(other.customerId, customerId) || other.customerId == customerId)&&(identical(other.shopName, shopName) || other.shopName == shopName)&&(identical(other.billCount, billCount) || other.billCount == billCount)&&(identical(other.revenue, revenue) || other.revenue == revenue));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,customerId,shopName,billCount,revenue);

@override
String toString() {
  return 'TopCustomerRow(customerId: $customerId, shopName: $shopName, billCount: $billCount, revenue: $revenue)';
}


}

/// @nodoc
abstract mixin class _$TopCustomerRowCopyWith<$Res> implements $TopCustomerRowCopyWith<$Res> {
  factory _$TopCustomerRowCopyWith(_TopCustomerRow value, $Res Function(_TopCustomerRow) _then) = __$TopCustomerRowCopyWithImpl;
@override @useResult
$Res call({
 String customerId, String shopName, int billCount, int revenue
});




}
/// @nodoc
class __$TopCustomerRowCopyWithImpl<$Res>
    implements _$TopCustomerRowCopyWith<$Res> {
  __$TopCustomerRowCopyWithImpl(this._self, this._then);

  final _TopCustomerRow _self;
  final $Res Function(_TopCustomerRow) _then;

/// Create a copy of TopCustomerRow
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? customerId = null,Object? shopName = null,Object? billCount = null,Object? revenue = null,}) {
  return _then(_TopCustomerRow(
customerId: null == customerId ? _self.customerId : customerId // ignore: cast_nullable_to_non_nullable
as String,shopName: null == shopName ? _self.shopName : shopName // ignore: cast_nullable_to_non_nullable
as String,billCount: null == billCount ? _self.billCount : billCount // ignore: cast_nullable_to_non_nullable
as int,revenue: null == revenue ? _self.revenue : revenue // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
