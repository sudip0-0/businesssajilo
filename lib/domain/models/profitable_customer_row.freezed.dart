// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'profitable_customer_row.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ProfitableCustomerRow {

@JsonKey(name: 'customer_id') String get customerId;@JsonKey(name: 'shop_name') String get shopName;@JsonKey(name: 'bill_count') int get billCount; int get revenue; int get cogs;@JsonKey(name: 'gross_profit') int get grossProfit;@JsonKey(name: 'margin_pct') double get marginPct;
/// Create a copy of ProfitableCustomerRow
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProfitableCustomerRowCopyWith<ProfitableCustomerRow> get copyWith => _$ProfitableCustomerRowCopyWithImpl<ProfitableCustomerRow>(this as ProfitableCustomerRow, _$identity);

  /// Serializes this ProfitableCustomerRow to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProfitableCustomerRow&&(identical(other.customerId, customerId) || other.customerId == customerId)&&(identical(other.shopName, shopName) || other.shopName == shopName)&&(identical(other.billCount, billCount) || other.billCount == billCount)&&(identical(other.revenue, revenue) || other.revenue == revenue)&&(identical(other.cogs, cogs) || other.cogs == cogs)&&(identical(other.grossProfit, grossProfit) || other.grossProfit == grossProfit)&&(identical(other.marginPct, marginPct) || other.marginPct == marginPct));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,customerId,shopName,billCount,revenue,cogs,grossProfit,marginPct);

@override
String toString() {
  return 'ProfitableCustomerRow(customerId: $customerId, shopName: $shopName, billCount: $billCount, revenue: $revenue, cogs: $cogs, grossProfit: $grossProfit, marginPct: $marginPct)';
}


}

/// @nodoc
abstract mixin class $ProfitableCustomerRowCopyWith<$Res>  {
  factory $ProfitableCustomerRowCopyWith(ProfitableCustomerRow value, $Res Function(ProfitableCustomerRow) _then) = _$ProfitableCustomerRowCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'customer_id') String customerId,@JsonKey(name: 'shop_name') String shopName,@JsonKey(name: 'bill_count') int billCount, int revenue, int cogs,@JsonKey(name: 'gross_profit') int grossProfit,@JsonKey(name: 'margin_pct') double marginPct
});




}
/// @nodoc
class _$ProfitableCustomerRowCopyWithImpl<$Res>
    implements $ProfitableCustomerRowCopyWith<$Res> {
  _$ProfitableCustomerRowCopyWithImpl(this._self, this._then);

  final ProfitableCustomerRow _self;
  final $Res Function(ProfitableCustomerRow) _then;

/// Create a copy of ProfitableCustomerRow
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? customerId = null,Object? shopName = null,Object? billCount = null,Object? revenue = null,Object? cogs = null,Object? grossProfit = null,Object? marginPct = null,}) {
  return _then(_self.copyWith(
customerId: null == customerId ? _self.customerId : customerId // ignore: cast_nullable_to_non_nullable
as String,shopName: null == shopName ? _self.shopName : shopName // ignore: cast_nullable_to_non_nullable
as String,billCount: null == billCount ? _self.billCount : billCount // ignore: cast_nullable_to_non_nullable
as int,revenue: null == revenue ? _self.revenue : revenue // ignore: cast_nullable_to_non_nullable
as int,cogs: null == cogs ? _self.cogs : cogs // ignore: cast_nullable_to_non_nullable
as int,grossProfit: null == grossProfit ? _self.grossProfit : grossProfit // ignore: cast_nullable_to_non_nullable
as int,marginPct: null == marginPct ? _self.marginPct : marginPct // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [ProfitableCustomerRow].
extension ProfitableCustomerRowPatterns on ProfitableCustomerRow {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProfitableCustomerRow value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProfitableCustomerRow() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProfitableCustomerRow value)  $default,){
final _that = this;
switch (_that) {
case _ProfitableCustomerRow():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProfitableCustomerRow value)?  $default,){
final _that = this;
switch (_that) {
case _ProfitableCustomerRow() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'customer_id')  String customerId, @JsonKey(name: 'shop_name')  String shopName, @JsonKey(name: 'bill_count')  int billCount,  int revenue,  int cogs, @JsonKey(name: 'gross_profit')  int grossProfit, @JsonKey(name: 'margin_pct')  double marginPct)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProfitableCustomerRow() when $default != null:
return $default(_that.customerId,_that.shopName,_that.billCount,_that.revenue,_that.cogs,_that.grossProfit,_that.marginPct);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'customer_id')  String customerId, @JsonKey(name: 'shop_name')  String shopName, @JsonKey(name: 'bill_count')  int billCount,  int revenue,  int cogs, @JsonKey(name: 'gross_profit')  int grossProfit, @JsonKey(name: 'margin_pct')  double marginPct)  $default,) {final _that = this;
switch (_that) {
case _ProfitableCustomerRow():
return $default(_that.customerId,_that.shopName,_that.billCount,_that.revenue,_that.cogs,_that.grossProfit,_that.marginPct);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'customer_id')  String customerId, @JsonKey(name: 'shop_name')  String shopName, @JsonKey(name: 'bill_count')  int billCount,  int revenue,  int cogs, @JsonKey(name: 'gross_profit')  int grossProfit, @JsonKey(name: 'margin_pct')  double marginPct)?  $default,) {final _that = this;
switch (_that) {
case _ProfitableCustomerRow() when $default != null:
return $default(_that.customerId,_that.shopName,_that.billCount,_that.revenue,_that.cogs,_that.grossProfit,_that.marginPct);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProfitableCustomerRow implements ProfitableCustomerRow {
  const _ProfitableCustomerRow({@JsonKey(name: 'customer_id') required this.customerId, @JsonKey(name: 'shop_name') required this.shopName, @JsonKey(name: 'bill_count') this.billCount = 0, this.revenue = 0, this.cogs = 0, @JsonKey(name: 'gross_profit') this.grossProfit = 0, @JsonKey(name: 'margin_pct') this.marginPct = 0.0});
  factory _ProfitableCustomerRow.fromJson(Map<String, dynamic> json) => _$ProfitableCustomerRowFromJson(json);

@override@JsonKey(name: 'customer_id') final  String customerId;
@override@JsonKey(name: 'shop_name') final  String shopName;
@override@JsonKey(name: 'bill_count') final  int billCount;
@override@JsonKey() final  int revenue;
@override@JsonKey() final  int cogs;
@override@JsonKey(name: 'gross_profit') final  int grossProfit;
@override@JsonKey(name: 'margin_pct') final  double marginPct;

/// Create a copy of ProfitableCustomerRow
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProfitableCustomerRowCopyWith<_ProfitableCustomerRow> get copyWith => __$ProfitableCustomerRowCopyWithImpl<_ProfitableCustomerRow>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProfitableCustomerRowToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProfitableCustomerRow&&(identical(other.customerId, customerId) || other.customerId == customerId)&&(identical(other.shopName, shopName) || other.shopName == shopName)&&(identical(other.billCount, billCount) || other.billCount == billCount)&&(identical(other.revenue, revenue) || other.revenue == revenue)&&(identical(other.cogs, cogs) || other.cogs == cogs)&&(identical(other.grossProfit, grossProfit) || other.grossProfit == grossProfit)&&(identical(other.marginPct, marginPct) || other.marginPct == marginPct));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,customerId,shopName,billCount,revenue,cogs,grossProfit,marginPct);

@override
String toString() {
  return 'ProfitableCustomerRow(customerId: $customerId, shopName: $shopName, billCount: $billCount, revenue: $revenue, cogs: $cogs, grossProfit: $grossProfit, marginPct: $marginPct)';
}


}

/// @nodoc
abstract mixin class _$ProfitableCustomerRowCopyWith<$Res> implements $ProfitableCustomerRowCopyWith<$Res> {
  factory _$ProfitableCustomerRowCopyWith(_ProfitableCustomerRow value, $Res Function(_ProfitableCustomerRow) _then) = __$ProfitableCustomerRowCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'customer_id') String customerId,@JsonKey(name: 'shop_name') String shopName,@JsonKey(name: 'bill_count') int billCount, int revenue, int cogs,@JsonKey(name: 'gross_profit') int grossProfit,@JsonKey(name: 'margin_pct') double marginPct
});




}
/// @nodoc
class __$ProfitableCustomerRowCopyWithImpl<$Res>
    implements _$ProfitableCustomerRowCopyWith<$Res> {
  __$ProfitableCustomerRowCopyWithImpl(this._self, this._then);

  final _ProfitableCustomerRow _self;
  final $Res Function(_ProfitableCustomerRow) _then;

/// Create a copy of ProfitableCustomerRow
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? customerId = null,Object? shopName = null,Object? billCount = null,Object? revenue = null,Object? cogs = null,Object? grossProfit = null,Object? marginPct = null,}) {
  return _then(_ProfitableCustomerRow(
customerId: null == customerId ? _self.customerId : customerId // ignore: cast_nullable_to_non_nullable
as String,shopName: null == shopName ? _self.shopName : shopName // ignore: cast_nullable_to_non_nullable
as String,billCount: null == billCount ? _self.billCount : billCount // ignore: cast_nullable_to_non_nullable
as int,revenue: null == revenue ? _self.revenue : revenue // ignore: cast_nullable_to_non_nullable
as int,cogs: null == cogs ? _self.cogs : cogs // ignore: cast_nullable_to_non_nullable
as int,grossProfit: null == grossProfit ? _self.grossProfit : grossProfit // ignore: cast_nullable_to_non_nullable
as int,marginPct: null == marginPct ? _self.marginPct : marginPct // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

// dart format on
