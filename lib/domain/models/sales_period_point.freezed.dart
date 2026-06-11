// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'sales_period_point.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SalesPeriodPoint {

 DateTime get saleDate; int get billCount; int get totalSales;
/// Create a copy of SalesPeriodPoint
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SalesPeriodPointCopyWith<SalesPeriodPoint> get copyWith => _$SalesPeriodPointCopyWithImpl<SalesPeriodPoint>(this as SalesPeriodPoint, _$identity);

  /// Serializes this SalesPeriodPoint to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SalesPeriodPoint&&(identical(other.saleDate, saleDate) || other.saleDate == saleDate)&&(identical(other.billCount, billCount) || other.billCount == billCount)&&(identical(other.totalSales, totalSales) || other.totalSales == totalSales));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,saleDate,billCount,totalSales);

@override
String toString() {
  return 'SalesPeriodPoint(saleDate: $saleDate, billCount: $billCount, totalSales: $totalSales)';
}


}

/// @nodoc
abstract mixin class $SalesPeriodPointCopyWith<$Res>  {
  factory $SalesPeriodPointCopyWith(SalesPeriodPoint value, $Res Function(SalesPeriodPoint) _then) = _$SalesPeriodPointCopyWithImpl;
@useResult
$Res call({
 DateTime saleDate, int billCount, int totalSales
});




}
/// @nodoc
class _$SalesPeriodPointCopyWithImpl<$Res>
    implements $SalesPeriodPointCopyWith<$Res> {
  _$SalesPeriodPointCopyWithImpl(this._self, this._then);

  final SalesPeriodPoint _self;
  final $Res Function(SalesPeriodPoint) _then;

/// Create a copy of SalesPeriodPoint
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? saleDate = null,Object? billCount = null,Object? totalSales = null,}) {
  return _then(_self.copyWith(
saleDate: null == saleDate ? _self.saleDate : saleDate // ignore: cast_nullable_to_non_nullable
as DateTime,billCount: null == billCount ? _self.billCount : billCount // ignore: cast_nullable_to_non_nullable
as int,totalSales: null == totalSales ? _self.totalSales : totalSales // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [SalesPeriodPoint].
extension SalesPeriodPointPatterns on SalesPeriodPoint {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SalesPeriodPoint value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SalesPeriodPoint() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SalesPeriodPoint value)  $default,){
final _that = this;
switch (_that) {
case _SalesPeriodPoint():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SalesPeriodPoint value)?  $default,){
final _that = this;
switch (_that) {
case _SalesPeriodPoint() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DateTime saleDate,  int billCount,  int totalSales)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SalesPeriodPoint() when $default != null:
return $default(_that.saleDate,_that.billCount,_that.totalSales);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DateTime saleDate,  int billCount,  int totalSales)  $default,) {final _that = this;
switch (_that) {
case _SalesPeriodPoint():
return $default(_that.saleDate,_that.billCount,_that.totalSales);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DateTime saleDate,  int billCount,  int totalSales)?  $default,) {final _that = this;
switch (_that) {
case _SalesPeriodPoint() when $default != null:
return $default(_that.saleDate,_that.billCount,_that.totalSales);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SalesPeriodPoint implements SalesPeriodPoint {
  const _SalesPeriodPoint({required this.saleDate, this.billCount = 0, this.totalSales = 0});
  factory _SalesPeriodPoint.fromJson(Map<String, dynamic> json) => _$SalesPeriodPointFromJson(json);

@override final  DateTime saleDate;
@override@JsonKey() final  int billCount;
@override@JsonKey() final  int totalSales;

/// Create a copy of SalesPeriodPoint
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SalesPeriodPointCopyWith<_SalesPeriodPoint> get copyWith => __$SalesPeriodPointCopyWithImpl<_SalesPeriodPoint>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SalesPeriodPointToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SalesPeriodPoint&&(identical(other.saleDate, saleDate) || other.saleDate == saleDate)&&(identical(other.billCount, billCount) || other.billCount == billCount)&&(identical(other.totalSales, totalSales) || other.totalSales == totalSales));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,saleDate,billCount,totalSales);

@override
String toString() {
  return 'SalesPeriodPoint(saleDate: $saleDate, billCount: $billCount, totalSales: $totalSales)';
}


}

/// @nodoc
abstract mixin class _$SalesPeriodPointCopyWith<$Res> implements $SalesPeriodPointCopyWith<$Res> {
  factory _$SalesPeriodPointCopyWith(_SalesPeriodPoint value, $Res Function(_SalesPeriodPoint) _then) = __$SalesPeriodPointCopyWithImpl;
@override @useResult
$Res call({
 DateTime saleDate, int billCount, int totalSales
});




}
/// @nodoc
class __$SalesPeriodPointCopyWithImpl<$Res>
    implements _$SalesPeriodPointCopyWith<$Res> {
  __$SalesPeriodPointCopyWithImpl(this._self, this._then);

  final _SalesPeriodPoint _self;
  final $Res Function(_SalesPeriodPoint) _then;

/// Create a copy of SalesPeriodPoint
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? saleDate = null,Object? billCount = null,Object? totalSales = null,}) {
  return _then(_SalesPeriodPoint(
saleDate: null == saleDate ? _self.saleDate : saleDate // ignore: cast_nullable_to_non_nullable
as DateTime,billCount: null == billCount ? _self.billCount : billCount // ignore: cast_nullable_to_non_nullable
as int,totalSales: null == totalSales ? _self.totalSales : totalSales // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
