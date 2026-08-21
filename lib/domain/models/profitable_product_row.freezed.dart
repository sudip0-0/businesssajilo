// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'profitable_product_row.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ProfitableProductRow {

@JsonKey(name: 'product_id') String get productId;@JsonKey(name: 'name_snapshot') String get nameSnapshot;@JsonKey(name: 'qty_sold') int get qtySold; int get revenue; int get cogs;@JsonKey(name: 'gross_profit') int get grossProfit;@JsonKey(name: 'margin_pct') double get marginPct;
/// Create a copy of ProfitableProductRow
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProfitableProductRowCopyWith<ProfitableProductRow> get copyWith => _$ProfitableProductRowCopyWithImpl<ProfitableProductRow>(this as ProfitableProductRow, _$identity);

  /// Serializes this ProfitableProductRow to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProfitableProductRow&&(identical(other.productId, productId) || other.productId == productId)&&(identical(other.nameSnapshot, nameSnapshot) || other.nameSnapshot == nameSnapshot)&&(identical(other.qtySold, qtySold) || other.qtySold == qtySold)&&(identical(other.revenue, revenue) || other.revenue == revenue)&&(identical(other.cogs, cogs) || other.cogs == cogs)&&(identical(other.grossProfit, grossProfit) || other.grossProfit == grossProfit)&&(identical(other.marginPct, marginPct) || other.marginPct == marginPct));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,productId,nameSnapshot,qtySold,revenue,cogs,grossProfit,marginPct);

@override
String toString() {
  return 'ProfitableProductRow(productId: $productId, nameSnapshot: $nameSnapshot, qtySold: $qtySold, revenue: $revenue, cogs: $cogs, grossProfit: $grossProfit, marginPct: $marginPct)';
}


}

/// @nodoc
abstract mixin class $ProfitableProductRowCopyWith<$Res>  {
  factory $ProfitableProductRowCopyWith(ProfitableProductRow value, $Res Function(ProfitableProductRow) _then) = _$ProfitableProductRowCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'product_id') String productId,@JsonKey(name: 'name_snapshot') String nameSnapshot,@JsonKey(name: 'qty_sold') int qtySold, int revenue, int cogs,@JsonKey(name: 'gross_profit') int grossProfit,@JsonKey(name: 'margin_pct') double marginPct
});




}
/// @nodoc
class _$ProfitableProductRowCopyWithImpl<$Res>
    implements $ProfitableProductRowCopyWith<$Res> {
  _$ProfitableProductRowCopyWithImpl(this._self, this._then);

  final ProfitableProductRow _self;
  final $Res Function(ProfitableProductRow) _then;

/// Create a copy of ProfitableProductRow
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? productId = null,Object? nameSnapshot = null,Object? qtySold = null,Object? revenue = null,Object? cogs = null,Object? grossProfit = null,Object? marginPct = null,}) {
  return _then(_self.copyWith(
productId: null == productId ? _self.productId : productId // ignore: cast_nullable_to_non_nullable
as String,nameSnapshot: null == nameSnapshot ? _self.nameSnapshot : nameSnapshot // ignore: cast_nullable_to_non_nullable
as String,qtySold: null == qtySold ? _self.qtySold : qtySold // ignore: cast_nullable_to_non_nullable
as int,revenue: null == revenue ? _self.revenue : revenue // ignore: cast_nullable_to_non_nullable
as int,cogs: null == cogs ? _self.cogs : cogs // ignore: cast_nullable_to_non_nullable
as int,grossProfit: null == grossProfit ? _self.grossProfit : grossProfit // ignore: cast_nullable_to_non_nullable
as int,marginPct: null == marginPct ? _self.marginPct : marginPct // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [ProfitableProductRow].
extension ProfitableProductRowPatterns on ProfitableProductRow {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProfitableProductRow value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProfitableProductRow() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProfitableProductRow value)  $default,){
final _that = this;
switch (_that) {
case _ProfitableProductRow():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProfitableProductRow value)?  $default,){
final _that = this;
switch (_that) {
case _ProfitableProductRow() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'product_id')  String productId, @JsonKey(name: 'name_snapshot')  String nameSnapshot, @JsonKey(name: 'qty_sold')  int qtySold,  int revenue,  int cogs, @JsonKey(name: 'gross_profit')  int grossProfit, @JsonKey(name: 'margin_pct')  double marginPct)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProfitableProductRow() when $default != null:
return $default(_that.productId,_that.nameSnapshot,_that.qtySold,_that.revenue,_that.cogs,_that.grossProfit,_that.marginPct);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'product_id')  String productId, @JsonKey(name: 'name_snapshot')  String nameSnapshot, @JsonKey(name: 'qty_sold')  int qtySold,  int revenue,  int cogs, @JsonKey(name: 'gross_profit')  int grossProfit, @JsonKey(name: 'margin_pct')  double marginPct)  $default,) {final _that = this;
switch (_that) {
case _ProfitableProductRow():
return $default(_that.productId,_that.nameSnapshot,_that.qtySold,_that.revenue,_that.cogs,_that.grossProfit,_that.marginPct);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'product_id')  String productId, @JsonKey(name: 'name_snapshot')  String nameSnapshot, @JsonKey(name: 'qty_sold')  int qtySold,  int revenue,  int cogs, @JsonKey(name: 'gross_profit')  int grossProfit, @JsonKey(name: 'margin_pct')  double marginPct)?  $default,) {final _that = this;
switch (_that) {
case _ProfitableProductRow() when $default != null:
return $default(_that.productId,_that.nameSnapshot,_that.qtySold,_that.revenue,_that.cogs,_that.grossProfit,_that.marginPct);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProfitableProductRow implements ProfitableProductRow {
  const _ProfitableProductRow({@JsonKey(name: 'product_id') required this.productId, @JsonKey(name: 'name_snapshot') required this.nameSnapshot, @JsonKey(name: 'qty_sold') this.qtySold = 0, this.revenue = 0, this.cogs = 0, @JsonKey(name: 'gross_profit') this.grossProfit = 0, @JsonKey(name: 'margin_pct') this.marginPct = 0.0});
  factory _ProfitableProductRow.fromJson(Map<String, dynamic> json) => _$ProfitableProductRowFromJson(json);

@override@JsonKey(name: 'product_id') final  String productId;
@override@JsonKey(name: 'name_snapshot') final  String nameSnapshot;
@override@JsonKey(name: 'qty_sold') final  int qtySold;
@override@JsonKey() final  int revenue;
@override@JsonKey() final  int cogs;
@override@JsonKey(name: 'gross_profit') final  int grossProfit;
@override@JsonKey(name: 'margin_pct') final  double marginPct;

/// Create a copy of ProfitableProductRow
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProfitableProductRowCopyWith<_ProfitableProductRow> get copyWith => __$ProfitableProductRowCopyWithImpl<_ProfitableProductRow>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProfitableProductRowToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProfitableProductRow&&(identical(other.productId, productId) || other.productId == productId)&&(identical(other.nameSnapshot, nameSnapshot) || other.nameSnapshot == nameSnapshot)&&(identical(other.qtySold, qtySold) || other.qtySold == qtySold)&&(identical(other.revenue, revenue) || other.revenue == revenue)&&(identical(other.cogs, cogs) || other.cogs == cogs)&&(identical(other.grossProfit, grossProfit) || other.grossProfit == grossProfit)&&(identical(other.marginPct, marginPct) || other.marginPct == marginPct));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,productId,nameSnapshot,qtySold,revenue,cogs,grossProfit,marginPct);

@override
String toString() {
  return 'ProfitableProductRow(productId: $productId, nameSnapshot: $nameSnapshot, qtySold: $qtySold, revenue: $revenue, cogs: $cogs, grossProfit: $grossProfit, marginPct: $marginPct)';
}


}

/// @nodoc
abstract mixin class _$ProfitableProductRowCopyWith<$Res> implements $ProfitableProductRowCopyWith<$Res> {
  factory _$ProfitableProductRowCopyWith(_ProfitableProductRow value, $Res Function(_ProfitableProductRow) _then) = __$ProfitableProductRowCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'product_id') String productId,@JsonKey(name: 'name_snapshot') String nameSnapshot,@JsonKey(name: 'qty_sold') int qtySold, int revenue, int cogs,@JsonKey(name: 'gross_profit') int grossProfit,@JsonKey(name: 'margin_pct') double marginPct
});




}
/// @nodoc
class __$ProfitableProductRowCopyWithImpl<$Res>
    implements _$ProfitableProductRowCopyWith<$Res> {
  __$ProfitableProductRowCopyWithImpl(this._self, this._then);

  final _ProfitableProductRow _self;
  final $Res Function(_ProfitableProductRow) _then;

/// Create a copy of ProfitableProductRow
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? productId = null,Object? nameSnapshot = null,Object? qtySold = null,Object? revenue = null,Object? cogs = null,Object? grossProfit = null,Object? marginPct = null,}) {
  return _then(_ProfitableProductRow(
productId: null == productId ? _self.productId : productId // ignore: cast_nullable_to_non_nullable
as String,nameSnapshot: null == nameSnapshot ? _self.nameSnapshot : nameSnapshot // ignore: cast_nullable_to_non_nullable
as String,qtySold: null == qtySold ? _self.qtySold : qtySold // ignore: cast_nullable_to_non_nullable
as int,revenue: null == revenue ? _self.revenue : revenue // ignore: cast_nullable_to_non_nullable
as int,cogs: null == cogs ? _self.cogs : cogs // ignore: cast_nullable_to_non_nullable
as int,grossProfit: null == grossProfit ? _self.grossProfit : grossProfit // ignore: cast_nullable_to_non_nullable
as int,marginPct: null == marginPct ? _self.marginPct : marginPct // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

// dart format on
