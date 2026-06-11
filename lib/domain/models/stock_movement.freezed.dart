// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'stock_movement.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$StockMovement {

 String get id; String get businessId; String get productId; StockMovementType get type; int get qtyDelta; String? get reason; String? get refOrderId; String get createdBy; DateTime? get createdAt; String? get createdByName;
/// Create a copy of StockMovement
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StockMovementCopyWith<StockMovement> get copyWith => _$StockMovementCopyWithImpl<StockMovement>(this as StockMovement, _$identity);

  /// Serializes this StockMovement to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StockMovement&&(identical(other.id, id) || other.id == id)&&(identical(other.businessId, businessId) || other.businessId == businessId)&&(identical(other.productId, productId) || other.productId == productId)&&(identical(other.type, type) || other.type == type)&&(identical(other.qtyDelta, qtyDelta) || other.qtyDelta == qtyDelta)&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.refOrderId, refOrderId) || other.refOrderId == refOrderId)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.createdByName, createdByName) || other.createdByName == createdByName));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,businessId,productId,type,qtyDelta,reason,refOrderId,createdBy,createdAt,createdByName);

@override
String toString() {
  return 'StockMovement(id: $id, businessId: $businessId, productId: $productId, type: $type, qtyDelta: $qtyDelta, reason: $reason, refOrderId: $refOrderId, createdBy: $createdBy, createdAt: $createdAt, createdByName: $createdByName)';
}


}

/// @nodoc
abstract mixin class $StockMovementCopyWith<$Res>  {
  factory $StockMovementCopyWith(StockMovement value, $Res Function(StockMovement) _then) = _$StockMovementCopyWithImpl;
@useResult
$Res call({
 String id, String businessId, String productId, StockMovementType type, int qtyDelta, String? reason, String? refOrderId, String createdBy, DateTime? createdAt, String? createdByName
});




}
/// @nodoc
class _$StockMovementCopyWithImpl<$Res>
    implements $StockMovementCopyWith<$Res> {
  _$StockMovementCopyWithImpl(this._self, this._then);

  final StockMovement _self;
  final $Res Function(StockMovement) _then;

/// Create a copy of StockMovement
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? businessId = null,Object? productId = null,Object? type = null,Object? qtyDelta = null,Object? reason = freezed,Object? refOrderId = freezed,Object? createdBy = null,Object? createdAt = freezed,Object? createdByName = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,businessId: null == businessId ? _self.businessId : businessId // ignore: cast_nullable_to_non_nullable
as String,productId: null == productId ? _self.productId : productId // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as StockMovementType,qtyDelta: null == qtyDelta ? _self.qtyDelta : qtyDelta // ignore: cast_nullable_to_non_nullable
as int,reason: freezed == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String?,refOrderId: freezed == refOrderId ? _self.refOrderId : refOrderId // ignore: cast_nullable_to_non_nullable
as String?,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdByName: freezed == createdByName ? _self.createdByName : createdByName // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [StockMovement].
extension StockMovementPatterns on StockMovement {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StockMovement value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StockMovement() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StockMovement value)  $default,){
final _that = this;
switch (_that) {
case _StockMovement():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StockMovement value)?  $default,){
final _that = this;
switch (_that) {
case _StockMovement() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String businessId,  String productId,  StockMovementType type,  int qtyDelta,  String? reason,  String? refOrderId,  String createdBy,  DateTime? createdAt,  String? createdByName)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StockMovement() when $default != null:
return $default(_that.id,_that.businessId,_that.productId,_that.type,_that.qtyDelta,_that.reason,_that.refOrderId,_that.createdBy,_that.createdAt,_that.createdByName);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String businessId,  String productId,  StockMovementType type,  int qtyDelta,  String? reason,  String? refOrderId,  String createdBy,  DateTime? createdAt,  String? createdByName)  $default,) {final _that = this;
switch (_that) {
case _StockMovement():
return $default(_that.id,_that.businessId,_that.productId,_that.type,_that.qtyDelta,_that.reason,_that.refOrderId,_that.createdBy,_that.createdAt,_that.createdByName);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String businessId,  String productId,  StockMovementType type,  int qtyDelta,  String? reason,  String? refOrderId,  String createdBy,  DateTime? createdAt,  String? createdByName)?  $default,) {final _that = this;
switch (_that) {
case _StockMovement() when $default != null:
return $default(_that.id,_that.businessId,_that.productId,_that.type,_that.qtyDelta,_that.reason,_that.refOrderId,_that.createdBy,_that.createdAt,_that.createdByName);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _StockMovement implements StockMovement {
  const _StockMovement({required this.id, required this.businessId, required this.productId, required this.type, required this.qtyDelta, this.reason, this.refOrderId, required this.createdBy, this.createdAt, this.createdByName});
  factory _StockMovement.fromJson(Map<String, dynamic> json) => _$StockMovementFromJson(json);

@override final  String id;
@override final  String businessId;
@override final  String productId;
@override final  StockMovementType type;
@override final  int qtyDelta;
@override final  String? reason;
@override final  String? refOrderId;
@override final  String createdBy;
@override final  DateTime? createdAt;
@override final  String? createdByName;

/// Create a copy of StockMovement
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StockMovementCopyWith<_StockMovement> get copyWith => __$StockMovementCopyWithImpl<_StockMovement>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StockMovementToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StockMovement&&(identical(other.id, id) || other.id == id)&&(identical(other.businessId, businessId) || other.businessId == businessId)&&(identical(other.productId, productId) || other.productId == productId)&&(identical(other.type, type) || other.type == type)&&(identical(other.qtyDelta, qtyDelta) || other.qtyDelta == qtyDelta)&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.refOrderId, refOrderId) || other.refOrderId == refOrderId)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.createdByName, createdByName) || other.createdByName == createdByName));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,businessId,productId,type,qtyDelta,reason,refOrderId,createdBy,createdAt,createdByName);

@override
String toString() {
  return 'StockMovement(id: $id, businessId: $businessId, productId: $productId, type: $type, qtyDelta: $qtyDelta, reason: $reason, refOrderId: $refOrderId, createdBy: $createdBy, createdAt: $createdAt, createdByName: $createdByName)';
}


}

/// @nodoc
abstract mixin class _$StockMovementCopyWith<$Res> implements $StockMovementCopyWith<$Res> {
  factory _$StockMovementCopyWith(_StockMovement value, $Res Function(_StockMovement) _then) = __$StockMovementCopyWithImpl;
@override @useResult
$Res call({
 String id, String businessId, String productId, StockMovementType type, int qtyDelta, String? reason, String? refOrderId, String createdBy, DateTime? createdAt, String? createdByName
});




}
/// @nodoc
class __$StockMovementCopyWithImpl<$Res>
    implements _$StockMovementCopyWith<$Res> {
  __$StockMovementCopyWithImpl(this._self, this._then);

  final _StockMovement _self;
  final $Res Function(_StockMovement) _then;

/// Create a copy of StockMovement
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? businessId = null,Object? productId = null,Object? type = null,Object? qtyDelta = null,Object? reason = freezed,Object? refOrderId = freezed,Object? createdBy = null,Object? createdAt = freezed,Object? createdByName = freezed,}) {
  return _then(_StockMovement(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,businessId: null == businessId ? _self.businessId : businessId // ignore: cast_nullable_to_non_nullable
as String,productId: null == productId ? _self.productId : productId // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as StockMovementType,qtyDelta: null == qtyDelta ? _self.qtyDelta : qtyDelta // ignore: cast_nullable_to_non_nullable
as int,reason: freezed == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String?,refOrderId: freezed == refOrderId ? _self.refOrderId : refOrderId // ignore: cast_nullable_to_non_nullable
as String?,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdByName: freezed == createdByName ? _self.createdByName : createdByName // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
