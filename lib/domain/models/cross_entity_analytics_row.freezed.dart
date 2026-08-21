// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'cross_entity_analytics_row.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CrossEntityAnalyticsRow {

 String get id; String get label;@JsonKey(name: 'qty_sold') int get qtySold; int get revenue;@JsonKey(name: 'gross_profit') int get grossProfit;
/// Create a copy of CrossEntityAnalyticsRow
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CrossEntityAnalyticsRowCopyWith<CrossEntityAnalyticsRow> get copyWith => _$CrossEntityAnalyticsRowCopyWithImpl<CrossEntityAnalyticsRow>(this as CrossEntityAnalyticsRow, _$identity);

  /// Serializes this CrossEntityAnalyticsRow to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CrossEntityAnalyticsRow&&(identical(other.id, id) || other.id == id)&&(identical(other.label, label) || other.label == label)&&(identical(other.qtySold, qtySold) || other.qtySold == qtySold)&&(identical(other.revenue, revenue) || other.revenue == revenue)&&(identical(other.grossProfit, grossProfit) || other.grossProfit == grossProfit));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,label,qtySold,revenue,grossProfit);

@override
String toString() {
  return 'CrossEntityAnalyticsRow(id: $id, label: $label, qtySold: $qtySold, revenue: $revenue, grossProfit: $grossProfit)';
}


}

/// @nodoc
abstract mixin class $CrossEntityAnalyticsRowCopyWith<$Res>  {
  factory $CrossEntityAnalyticsRowCopyWith(CrossEntityAnalyticsRow value, $Res Function(CrossEntityAnalyticsRow) _then) = _$CrossEntityAnalyticsRowCopyWithImpl;
@useResult
$Res call({
 String id, String label,@JsonKey(name: 'qty_sold') int qtySold, int revenue,@JsonKey(name: 'gross_profit') int grossProfit
});




}
/// @nodoc
class _$CrossEntityAnalyticsRowCopyWithImpl<$Res>
    implements $CrossEntityAnalyticsRowCopyWith<$Res> {
  _$CrossEntityAnalyticsRowCopyWithImpl(this._self, this._then);

  final CrossEntityAnalyticsRow _self;
  final $Res Function(CrossEntityAnalyticsRow) _then;

/// Create a copy of CrossEntityAnalyticsRow
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? label = null,Object? qtySold = null,Object? revenue = null,Object? grossProfit = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,qtySold: null == qtySold ? _self.qtySold : qtySold // ignore: cast_nullable_to_non_nullable
as int,revenue: null == revenue ? _self.revenue : revenue // ignore: cast_nullable_to_non_nullable
as int,grossProfit: null == grossProfit ? _self.grossProfit : grossProfit // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [CrossEntityAnalyticsRow].
extension CrossEntityAnalyticsRowPatterns on CrossEntityAnalyticsRow {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CrossEntityAnalyticsRow value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CrossEntityAnalyticsRow() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CrossEntityAnalyticsRow value)  $default,){
final _that = this;
switch (_that) {
case _CrossEntityAnalyticsRow():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CrossEntityAnalyticsRow value)?  $default,){
final _that = this;
switch (_that) {
case _CrossEntityAnalyticsRow() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String label, @JsonKey(name: 'qty_sold')  int qtySold,  int revenue, @JsonKey(name: 'gross_profit')  int grossProfit)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CrossEntityAnalyticsRow() when $default != null:
return $default(_that.id,_that.label,_that.qtySold,_that.revenue,_that.grossProfit);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String label, @JsonKey(name: 'qty_sold')  int qtySold,  int revenue, @JsonKey(name: 'gross_profit')  int grossProfit)  $default,) {final _that = this;
switch (_that) {
case _CrossEntityAnalyticsRow():
return $default(_that.id,_that.label,_that.qtySold,_that.revenue,_that.grossProfit);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String label, @JsonKey(name: 'qty_sold')  int qtySold,  int revenue, @JsonKey(name: 'gross_profit')  int grossProfit)?  $default,) {final _that = this;
switch (_that) {
case _CrossEntityAnalyticsRow() when $default != null:
return $default(_that.id,_that.label,_that.qtySold,_that.revenue,_that.grossProfit);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CrossEntityAnalyticsRow implements CrossEntityAnalyticsRow {
  const _CrossEntityAnalyticsRow({required this.id, required this.label, @JsonKey(name: 'qty_sold') this.qtySold = 0, this.revenue = 0, @JsonKey(name: 'gross_profit') this.grossProfit = 0});
  factory _CrossEntityAnalyticsRow.fromJson(Map<String, dynamic> json) => _$CrossEntityAnalyticsRowFromJson(json);

@override final  String id;
@override final  String label;
@override@JsonKey(name: 'qty_sold') final  int qtySold;
@override@JsonKey() final  int revenue;
@override@JsonKey(name: 'gross_profit') final  int grossProfit;

/// Create a copy of CrossEntityAnalyticsRow
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CrossEntityAnalyticsRowCopyWith<_CrossEntityAnalyticsRow> get copyWith => __$CrossEntityAnalyticsRowCopyWithImpl<_CrossEntityAnalyticsRow>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CrossEntityAnalyticsRowToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CrossEntityAnalyticsRow&&(identical(other.id, id) || other.id == id)&&(identical(other.label, label) || other.label == label)&&(identical(other.qtySold, qtySold) || other.qtySold == qtySold)&&(identical(other.revenue, revenue) || other.revenue == revenue)&&(identical(other.grossProfit, grossProfit) || other.grossProfit == grossProfit));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,label,qtySold,revenue,grossProfit);

@override
String toString() {
  return 'CrossEntityAnalyticsRow(id: $id, label: $label, qtySold: $qtySold, revenue: $revenue, grossProfit: $grossProfit)';
}


}

/// @nodoc
abstract mixin class _$CrossEntityAnalyticsRowCopyWith<$Res> implements $CrossEntityAnalyticsRowCopyWith<$Res> {
  factory _$CrossEntityAnalyticsRowCopyWith(_CrossEntityAnalyticsRow value, $Res Function(_CrossEntityAnalyticsRow) _then) = __$CrossEntityAnalyticsRowCopyWithImpl;
@override @useResult
$Res call({
 String id, String label,@JsonKey(name: 'qty_sold') int qtySold, int revenue,@JsonKey(name: 'gross_profit') int grossProfit
});




}
/// @nodoc
class __$CrossEntityAnalyticsRowCopyWithImpl<$Res>
    implements _$CrossEntityAnalyticsRowCopyWith<$Res> {
  __$CrossEntityAnalyticsRowCopyWithImpl(this._self, this._then);

  final _CrossEntityAnalyticsRow _self;
  final $Res Function(_CrossEntityAnalyticsRow) _then;

/// Create a copy of CrossEntityAnalyticsRow
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? label = null,Object? qtySold = null,Object? revenue = null,Object? grossProfit = null,}) {
  return _then(_CrossEntityAnalyticsRow(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,qtySold: null == qtySold ? _self.qtySold : qtySold // ignore: cast_nullable_to_non_nullable
as int,revenue: null == revenue ? _self.revenue : revenue // ignore: cast_nullable_to_non_nullable
as int,grossProfit: null == grossProfit ? _self.grossProfit : grossProfit // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
