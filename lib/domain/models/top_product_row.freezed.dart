// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'top_product_row.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TopProductRow {

 String get productId; String get nameSnapshot; int get qtySold; int get revenue;
/// Create a copy of TopProductRow
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TopProductRowCopyWith<TopProductRow> get copyWith => _$TopProductRowCopyWithImpl<TopProductRow>(this as TopProductRow, _$identity);

  /// Serializes this TopProductRow to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TopProductRow&&(identical(other.productId, productId) || other.productId == productId)&&(identical(other.nameSnapshot, nameSnapshot) || other.nameSnapshot == nameSnapshot)&&(identical(other.qtySold, qtySold) || other.qtySold == qtySold)&&(identical(other.revenue, revenue) || other.revenue == revenue));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,productId,nameSnapshot,qtySold,revenue);

@override
String toString() {
  return 'TopProductRow(productId: $productId, nameSnapshot: $nameSnapshot, qtySold: $qtySold, revenue: $revenue)';
}


}

/// @nodoc
abstract mixin class $TopProductRowCopyWith<$Res>  {
  factory $TopProductRowCopyWith(TopProductRow value, $Res Function(TopProductRow) _then) = _$TopProductRowCopyWithImpl;
@useResult
$Res call({
 String productId, String nameSnapshot, int qtySold, int revenue
});




}
/// @nodoc
class _$TopProductRowCopyWithImpl<$Res>
    implements $TopProductRowCopyWith<$Res> {
  _$TopProductRowCopyWithImpl(this._self, this._then);

  final TopProductRow _self;
  final $Res Function(TopProductRow) _then;

/// Create a copy of TopProductRow
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? productId = null,Object? nameSnapshot = null,Object? qtySold = null,Object? revenue = null,}) {
  return _then(_self.copyWith(
productId: null == productId ? _self.productId : productId // ignore: cast_nullable_to_non_nullable
as String,nameSnapshot: null == nameSnapshot ? _self.nameSnapshot : nameSnapshot // ignore: cast_nullable_to_non_nullable
as String,qtySold: null == qtySold ? _self.qtySold : qtySold // ignore: cast_nullable_to_non_nullable
as int,revenue: null == revenue ? _self.revenue : revenue // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [TopProductRow].
extension TopProductRowPatterns on TopProductRow {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TopProductRow value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TopProductRow() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TopProductRow value)  $default,){
final _that = this;
switch (_that) {
case _TopProductRow():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TopProductRow value)?  $default,){
final _that = this;
switch (_that) {
case _TopProductRow() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String productId,  String nameSnapshot,  int qtySold,  int revenue)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TopProductRow() when $default != null:
return $default(_that.productId,_that.nameSnapshot,_that.qtySold,_that.revenue);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String productId,  String nameSnapshot,  int qtySold,  int revenue)  $default,) {final _that = this;
switch (_that) {
case _TopProductRow():
return $default(_that.productId,_that.nameSnapshot,_that.qtySold,_that.revenue);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String productId,  String nameSnapshot,  int qtySold,  int revenue)?  $default,) {final _that = this;
switch (_that) {
case _TopProductRow() when $default != null:
return $default(_that.productId,_that.nameSnapshot,_that.qtySold,_that.revenue);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TopProductRow implements TopProductRow {
  const _TopProductRow({required this.productId, required this.nameSnapshot, this.qtySold = 0, this.revenue = 0});
  factory _TopProductRow.fromJson(Map<String, dynamic> json) => _$TopProductRowFromJson(json);

@override final  String productId;
@override final  String nameSnapshot;
@override@JsonKey() final  int qtySold;
@override@JsonKey() final  int revenue;

/// Create a copy of TopProductRow
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TopProductRowCopyWith<_TopProductRow> get copyWith => __$TopProductRowCopyWithImpl<_TopProductRow>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TopProductRowToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TopProductRow&&(identical(other.productId, productId) || other.productId == productId)&&(identical(other.nameSnapshot, nameSnapshot) || other.nameSnapshot == nameSnapshot)&&(identical(other.qtySold, qtySold) || other.qtySold == qtySold)&&(identical(other.revenue, revenue) || other.revenue == revenue));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,productId,nameSnapshot,qtySold,revenue);

@override
String toString() {
  return 'TopProductRow(productId: $productId, nameSnapshot: $nameSnapshot, qtySold: $qtySold, revenue: $revenue)';
}


}

/// @nodoc
abstract mixin class _$TopProductRowCopyWith<$Res> implements $TopProductRowCopyWith<$Res> {
  factory _$TopProductRowCopyWith(_TopProductRow value, $Res Function(_TopProductRow) _then) = __$TopProductRowCopyWithImpl;
@override @useResult
$Res call({
 String productId, String nameSnapshot, int qtySold, int revenue
});




}
/// @nodoc
class __$TopProductRowCopyWithImpl<$Res>
    implements _$TopProductRowCopyWith<$Res> {
  __$TopProductRowCopyWithImpl(this._self, this._then);

  final _TopProductRow _self;
  final $Res Function(_TopProductRow) _then;

/// Create a copy of TopProductRow
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? productId = null,Object? nameSnapshot = null,Object? qtySold = null,Object? revenue = null,}) {
  return _then(_TopProductRow(
productId: null == productId ? _self.productId : productId // ignore: cast_nullable_to_non_nullable
as String,nameSnapshot: null == nameSnapshot ? _self.nameSnapshot : nameSnapshot // ignore: cast_nullable_to_non_nullable
as String,qtySold: null == qtySold ? _self.qtySold : qtySold // ignore: cast_nullable_to_non_nullable
as int,revenue: null == revenue ? _self.revenue : revenue // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
