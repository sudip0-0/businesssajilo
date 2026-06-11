// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'member.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Member {

 String get id; String get businessId; String get authUserId; Role get role; String get displayName; String? get phone; bool get isActive; DateTime? get createdAt;
/// Create a copy of Member
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MemberCopyWith<Member> get copyWith => _$MemberCopyWithImpl<Member>(this as Member, _$identity);

  /// Serializes this Member to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Member&&(identical(other.id, id) || other.id == id)&&(identical(other.businessId, businessId) || other.businessId == businessId)&&(identical(other.authUserId, authUserId) || other.authUserId == authUserId)&&(identical(other.role, role) || other.role == role)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,businessId,authUserId,role,displayName,phone,isActive,createdAt);

@override
String toString() {
  return 'Member(id: $id, businessId: $businessId, authUserId: $authUserId, role: $role, displayName: $displayName, phone: $phone, isActive: $isActive, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $MemberCopyWith<$Res>  {
  factory $MemberCopyWith(Member value, $Res Function(Member) _then) = _$MemberCopyWithImpl;
@useResult
$Res call({
 String id, String businessId, String authUserId, Role role, String displayName, String? phone, bool isActive, DateTime? createdAt
});




}
/// @nodoc
class _$MemberCopyWithImpl<$Res>
    implements $MemberCopyWith<$Res> {
  _$MemberCopyWithImpl(this._self, this._then);

  final Member _self;
  final $Res Function(Member) _then;

/// Create a copy of Member
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? businessId = null,Object? authUserId = null,Object? role = null,Object? displayName = null,Object? phone = freezed,Object? isActive = null,Object? createdAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,businessId: null == businessId ? _self.businessId : businessId // ignore: cast_nullable_to_non_nullable
as String,authUserId: null == authUserId ? _self.authUserId : authUserId // ignore: cast_nullable_to_non_nullable
as String,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as Role,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,phone: freezed == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String?,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [Member].
extension MemberPatterns on Member {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Member value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Member() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Member value)  $default,){
final _that = this;
switch (_that) {
case _Member():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Member value)?  $default,){
final _that = this;
switch (_that) {
case _Member() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String businessId,  String authUserId,  Role role,  String displayName,  String? phone,  bool isActive,  DateTime? createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Member() when $default != null:
return $default(_that.id,_that.businessId,_that.authUserId,_that.role,_that.displayName,_that.phone,_that.isActive,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String businessId,  String authUserId,  Role role,  String displayName,  String? phone,  bool isActive,  DateTime? createdAt)  $default,) {final _that = this;
switch (_that) {
case _Member():
return $default(_that.id,_that.businessId,_that.authUserId,_that.role,_that.displayName,_that.phone,_that.isActive,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String businessId,  String authUserId,  Role role,  String displayName,  String? phone,  bool isActive,  DateTime? createdAt)?  $default,) {final _that = this;
switch (_that) {
case _Member() when $default != null:
return $default(_that.id,_that.businessId,_that.authUserId,_that.role,_that.displayName,_that.phone,_that.isActive,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Member implements Member {
  const _Member({required this.id, required this.businessId, required this.authUserId, required this.role, required this.displayName, this.phone, this.isActive = true, this.createdAt});
  factory _Member.fromJson(Map<String, dynamic> json) => _$MemberFromJson(json);

@override final  String id;
@override final  String businessId;
@override final  String authUserId;
@override final  Role role;
@override final  String displayName;
@override final  String? phone;
@override@JsonKey() final  bool isActive;
@override final  DateTime? createdAt;

/// Create a copy of Member
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MemberCopyWith<_Member> get copyWith => __$MemberCopyWithImpl<_Member>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MemberToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Member&&(identical(other.id, id) || other.id == id)&&(identical(other.businessId, businessId) || other.businessId == businessId)&&(identical(other.authUserId, authUserId) || other.authUserId == authUserId)&&(identical(other.role, role) || other.role == role)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,businessId,authUserId,role,displayName,phone,isActive,createdAt);

@override
String toString() {
  return 'Member(id: $id, businessId: $businessId, authUserId: $authUserId, role: $role, displayName: $displayName, phone: $phone, isActive: $isActive, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$MemberCopyWith<$Res> implements $MemberCopyWith<$Res> {
  factory _$MemberCopyWith(_Member value, $Res Function(_Member) _then) = __$MemberCopyWithImpl;
@override @useResult
$Res call({
 String id, String businessId, String authUserId, Role role, String displayName, String? phone, bool isActive, DateTime? createdAt
});




}
/// @nodoc
class __$MemberCopyWithImpl<$Res>
    implements _$MemberCopyWith<$Res> {
  __$MemberCopyWithImpl(this._self, this._then);

  final _Member _self;
  final $Res Function(_Member) _then;

/// Create a copy of Member
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? businessId = null,Object? authUserId = null,Object? role = null,Object? displayName = null,Object? phone = freezed,Object? isActive = null,Object? createdAt = freezed,}) {
  return _then(_Member(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,businessId: null == businessId ? _self.businessId : businessId // ignore: cast_nullable_to_non_nullable
as String,authUserId: null == authUserId ? _self.authUserId : authUserId // ignore: cast_nullable_to_non_nullable
as String,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as Role,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,phone: freezed == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String?,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
