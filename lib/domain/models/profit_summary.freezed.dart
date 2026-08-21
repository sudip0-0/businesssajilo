// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'profit_summary.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ProfitSummary {

@JsonKey(name: 'total_revenue') int get totalRevenue;@JsonKey(name: 'total_cogs') int get totalCogs;@JsonKey(name: 'gross_profit') int get grossProfit;@JsonKey(name: 'margin_pct') double get marginPct;@JsonKey(name: 'total_bills') int get totalBills;
/// Create a copy of ProfitSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProfitSummaryCopyWith<ProfitSummary> get copyWith => _$ProfitSummaryCopyWithImpl<ProfitSummary>(this as ProfitSummary, _$identity);

  /// Serializes this ProfitSummary to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProfitSummary&&(identical(other.totalRevenue, totalRevenue) || other.totalRevenue == totalRevenue)&&(identical(other.totalCogs, totalCogs) || other.totalCogs == totalCogs)&&(identical(other.grossProfit, grossProfit) || other.grossProfit == grossProfit)&&(identical(other.marginPct, marginPct) || other.marginPct == marginPct)&&(identical(other.totalBills, totalBills) || other.totalBills == totalBills));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,totalRevenue,totalCogs,grossProfit,marginPct,totalBills);

@override
String toString() {
  return 'ProfitSummary(totalRevenue: $totalRevenue, totalCogs: $totalCogs, grossProfit: $grossProfit, marginPct: $marginPct, totalBills: $totalBills)';
}


}

/// @nodoc
abstract mixin class $ProfitSummaryCopyWith<$Res>  {
  factory $ProfitSummaryCopyWith(ProfitSummary value, $Res Function(ProfitSummary) _then) = _$ProfitSummaryCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'total_revenue') int totalRevenue,@JsonKey(name: 'total_cogs') int totalCogs,@JsonKey(name: 'gross_profit') int grossProfit,@JsonKey(name: 'margin_pct') double marginPct,@JsonKey(name: 'total_bills') int totalBills
});




}
/// @nodoc
class _$ProfitSummaryCopyWithImpl<$Res>
    implements $ProfitSummaryCopyWith<$Res> {
  _$ProfitSummaryCopyWithImpl(this._self, this._then);

  final ProfitSummary _self;
  final $Res Function(ProfitSummary) _then;

/// Create a copy of ProfitSummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? totalRevenue = null,Object? totalCogs = null,Object? grossProfit = null,Object? marginPct = null,Object? totalBills = null,}) {
  return _then(_self.copyWith(
totalRevenue: null == totalRevenue ? _self.totalRevenue : totalRevenue // ignore: cast_nullable_to_non_nullable
as int,totalCogs: null == totalCogs ? _self.totalCogs : totalCogs // ignore: cast_nullable_to_non_nullable
as int,grossProfit: null == grossProfit ? _self.grossProfit : grossProfit // ignore: cast_nullable_to_non_nullable
as int,marginPct: null == marginPct ? _self.marginPct : marginPct // ignore: cast_nullable_to_non_nullable
as double,totalBills: null == totalBills ? _self.totalBills : totalBills // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [ProfitSummary].
extension ProfitSummaryPatterns on ProfitSummary {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProfitSummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProfitSummary() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProfitSummary value)  $default,){
final _that = this;
switch (_that) {
case _ProfitSummary():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProfitSummary value)?  $default,){
final _that = this;
switch (_that) {
case _ProfitSummary() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'total_revenue')  int totalRevenue, @JsonKey(name: 'total_cogs')  int totalCogs, @JsonKey(name: 'gross_profit')  int grossProfit, @JsonKey(name: 'margin_pct')  double marginPct, @JsonKey(name: 'total_bills')  int totalBills)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProfitSummary() when $default != null:
return $default(_that.totalRevenue,_that.totalCogs,_that.grossProfit,_that.marginPct,_that.totalBills);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'total_revenue')  int totalRevenue, @JsonKey(name: 'total_cogs')  int totalCogs, @JsonKey(name: 'gross_profit')  int grossProfit, @JsonKey(name: 'margin_pct')  double marginPct, @JsonKey(name: 'total_bills')  int totalBills)  $default,) {final _that = this;
switch (_that) {
case _ProfitSummary():
return $default(_that.totalRevenue,_that.totalCogs,_that.grossProfit,_that.marginPct,_that.totalBills);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'total_revenue')  int totalRevenue, @JsonKey(name: 'total_cogs')  int totalCogs, @JsonKey(name: 'gross_profit')  int grossProfit, @JsonKey(name: 'margin_pct')  double marginPct, @JsonKey(name: 'total_bills')  int totalBills)?  $default,) {final _that = this;
switch (_that) {
case _ProfitSummary() when $default != null:
return $default(_that.totalRevenue,_that.totalCogs,_that.grossProfit,_that.marginPct,_that.totalBills);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProfitSummary implements ProfitSummary {
  const _ProfitSummary({@JsonKey(name: 'total_revenue') this.totalRevenue = 0, @JsonKey(name: 'total_cogs') this.totalCogs = 0, @JsonKey(name: 'gross_profit') this.grossProfit = 0, @JsonKey(name: 'margin_pct') this.marginPct = 0.0, @JsonKey(name: 'total_bills') this.totalBills = 0});
  factory _ProfitSummary.fromJson(Map<String, dynamic> json) => _$ProfitSummaryFromJson(json);

@override@JsonKey(name: 'total_revenue') final  int totalRevenue;
@override@JsonKey(name: 'total_cogs') final  int totalCogs;
@override@JsonKey(name: 'gross_profit') final  int grossProfit;
@override@JsonKey(name: 'margin_pct') final  double marginPct;
@override@JsonKey(name: 'total_bills') final  int totalBills;

/// Create a copy of ProfitSummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProfitSummaryCopyWith<_ProfitSummary> get copyWith => __$ProfitSummaryCopyWithImpl<_ProfitSummary>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProfitSummaryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProfitSummary&&(identical(other.totalRevenue, totalRevenue) || other.totalRevenue == totalRevenue)&&(identical(other.totalCogs, totalCogs) || other.totalCogs == totalCogs)&&(identical(other.grossProfit, grossProfit) || other.grossProfit == grossProfit)&&(identical(other.marginPct, marginPct) || other.marginPct == marginPct)&&(identical(other.totalBills, totalBills) || other.totalBills == totalBills));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,totalRevenue,totalCogs,grossProfit,marginPct,totalBills);

@override
String toString() {
  return 'ProfitSummary(totalRevenue: $totalRevenue, totalCogs: $totalCogs, grossProfit: $grossProfit, marginPct: $marginPct, totalBills: $totalBills)';
}


}

/// @nodoc
abstract mixin class _$ProfitSummaryCopyWith<$Res> implements $ProfitSummaryCopyWith<$Res> {
  factory _$ProfitSummaryCopyWith(_ProfitSummary value, $Res Function(_ProfitSummary) _then) = __$ProfitSummaryCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'total_revenue') int totalRevenue,@JsonKey(name: 'total_cogs') int totalCogs,@JsonKey(name: 'gross_profit') int grossProfit,@JsonKey(name: 'margin_pct') double marginPct,@JsonKey(name: 'total_bills') int totalBills
});




}
/// @nodoc
class __$ProfitSummaryCopyWithImpl<$Res>
    implements _$ProfitSummaryCopyWith<$Res> {
  __$ProfitSummaryCopyWithImpl(this._self, this._then);

  final _ProfitSummary _self;
  final $Res Function(_ProfitSummary) _then;

/// Create a copy of ProfitSummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? totalRevenue = null,Object? totalCogs = null,Object? grossProfit = null,Object? marginPct = null,Object? totalBills = null,}) {
  return _then(_ProfitSummary(
totalRevenue: null == totalRevenue ? _self.totalRevenue : totalRevenue // ignore: cast_nullable_to_non_nullable
as int,totalCogs: null == totalCogs ? _self.totalCogs : totalCogs // ignore: cast_nullable_to_non_nullable
as int,grossProfit: null == grossProfit ? _self.grossProfit : grossProfit // ignore: cast_nullable_to_non_nullable
as int,marginPct: null == marginPct ? _self.marginPct : marginPct // ignore: cast_nullable_to_non_nullable
as double,totalBills: null == totalBills ? _self.totalBills : totalBills // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
