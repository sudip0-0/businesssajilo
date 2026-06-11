// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'business.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Business {

 String get id; String get name; String? get nameNp; String? get address; String? get phone; String? get logoUrl; String get subscriptionPlan; DateTime? get createdAt;
/// Create a copy of Business
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BusinessCopyWith<Business> get copyWith => _$BusinessCopyWithImpl<Business>(this as Business, _$identity);

  /// Serializes this Business to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Business&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.nameNp, nameNp) || other.nameNp == nameNp)&&(identical(other.address, address) || other.address == address)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.logoUrl, logoUrl) || other.logoUrl == logoUrl)&&(identical(other.subscriptionPlan, subscriptionPlan) || other.subscriptionPlan == subscriptionPlan)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,nameNp,address,phone,logoUrl,subscriptionPlan,createdAt);

@override
String toString() {
  return 'Business(id: $id, name: $name, nameNp: $nameNp, address: $address, phone: $phone, logoUrl: $logoUrl, subscriptionPlan: $subscriptionPlan, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $BusinessCopyWith<$Res>  {
  factory $BusinessCopyWith(Business value, $Res Function(Business) _then) = _$BusinessCopyWithImpl;
@useResult
$Res call({
 String id, String name, String? nameNp, String? address, String? phone, String? logoUrl, String subscriptionPlan, DateTime? createdAt
});




}
/// @nodoc
class _$BusinessCopyWithImpl<$Res>
    implements $BusinessCopyWith<$Res> {
  _$BusinessCopyWithImpl(this._self, this._then);

  final Business _self;
  final $Res Function(Business) _then;

/// Create a copy of Business
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? nameNp = freezed,Object? address = freezed,Object? phone = freezed,Object? logoUrl = freezed,Object? subscriptionPlan = null,Object? createdAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,nameNp: freezed == nameNp ? _self.nameNp : nameNp // ignore: cast_nullable_to_non_nullable
as String?,address: freezed == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String?,phone: freezed == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String?,logoUrl: freezed == logoUrl ? _self.logoUrl : logoUrl // ignore: cast_nullable_to_non_nullable
as String?,subscriptionPlan: null == subscriptionPlan ? _self.subscriptionPlan : subscriptionPlan // ignore: cast_nullable_to_non_nullable
as String,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [Business].
extension BusinessPatterns on Business {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Business value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Business() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Business value)  $default,){
final _that = this;
switch (_that) {
case _Business():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Business value)?  $default,){
final _that = this;
switch (_that) {
case _Business() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String? nameNp,  String? address,  String? phone,  String? logoUrl,  String subscriptionPlan,  DateTime? createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Business() when $default != null:
return $default(_that.id,_that.name,_that.nameNp,_that.address,_that.phone,_that.logoUrl,_that.subscriptionPlan,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String? nameNp,  String? address,  String? phone,  String? logoUrl,  String subscriptionPlan,  DateTime? createdAt)  $default,) {final _that = this;
switch (_that) {
case _Business():
return $default(_that.id,_that.name,_that.nameNp,_that.address,_that.phone,_that.logoUrl,_that.subscriptionPlan,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String? nameNp,  String? address,  String? phone,  String? logoUrl,  String subscriptionPlan,  DateTime? createdAt)?  $default,) {final _that = this;
switch (_that) {
case _Business() when $default != null:
return $default(_that.id,_that.name,_that.nameNp,_that.address,_that.phone,_that.logoUrl,_that.subscriptionPlan,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Business implements Business {
  const _Business({required this.id, required this.name, this.nameNp, this.address, this.phone, this.logoUrl, this.subscriptionPlan = 'free', this.createdAt});
  factory _Business.fromJson(Map<String, dynamic> json) => _$BusinessFromJson(json);

@override final  String id;
@override final  String name;
@override final  String? nameNp;
@override final  String? address;
@override final  String? phone;
@override final  String? logoUrl;
@override@JsonKey() final  String subscriptionPlan;
@override final  DateTime? createdAt;

/// Create a copy of Business
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BusinessCopyWith<_Business> get copyWith => __$BusinessCopyWithImpl<_Business>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BusinessToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Business&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.nameNp, nameNp) || other.nameNp == nameNp)&&(identical(other.address, address) || other.address == address)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.logoUrl, logoUrl) || other.logoUrl == logoUrl)&&(identical(other.subscriptionPlan, subscriptionPlan) || other.subscriptionPlan == subscriptionPlan)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,nameNp,address,phone,logoUrl,subscriptionPlan,createdAt);

@override
String toString() {
  return 'Business(id: $id, name: $name, nameNp: $nameNp, address: $address, phone: $phone, logoUrl: $logoUrl, subscriptionPlan: $subscriptionPlan, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$BusinessCopyWith<$Res> implements $BusinessCopyWith<$Res> {
  factory _$BusinessCopyWith(_Business value, $Res Function(_Business) _then) = __$BusinessCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String? nameNp, String? address, String? phone, String? logoUrl, String subscriptionPlan, DateTime? createdAt
});




}
/// @nodoc
class __$BusinessCopyWithImpl<$Res>
    implements _$BusinessCopyWith<$Res> {
  __$BusinessCopyWithImpl(this._self, this._then);

  final _Business _self;
  final $Res Function(_Business) _then;

/// Create a copy of Business
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? nameNp = freezed,Object? address = freezed,Object? phone = freezed,Object? logoUrl = freezed,Object? subscriptionPlan = null,Object? createdAt = freezed,}) {
  return _then(_Business(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,nameNp: freezed == nameNp ? _self.nameNp : nameNp // ignore: cast_nullable_to_non_nullable
as String?,address: freezed == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String?,phone: freezed == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String?,logoUrl: freezed == logoUrl ? _self.logoUrl : logoUrl // ignore: cast_nullable_to_non_nullable
as String?,subscriptionPlan: null == subscriptionPlan ? _self.subscriptionPlan : subscriptionPlan // ignore: cast_nullable_to_non_nullable
as String,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
