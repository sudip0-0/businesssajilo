// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'message.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Message {

 String get id; String get orderId; String get businessId; String get senderMemberId; String get body; String? get imageUrl; DateTime? get createdAt; String? get senderName;
/// Create a copy of Message
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MessageCopyWith<Message> get copyWith => _$MessageCopyWithImpl<Message>(this as Message, _$identity);

  /// Serializes this Message to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Message&&(identical(other.id, id) || other.id == id)&&(identical(other.orderId, orderId) || other.orderId == orderId)&&(identical(other.businessId, businessId) || other.businessId == businessId)&&(identical(other.senderMemberId, senderMemberId) || other.senderMemberId == senderMemberId)&&(identical(other.body, body) || other.body == body)&&(identical(other.imageUrl, imageUrl) || other.imageUrl == imageUrl)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.senderName, senderName) || other.senderName == senderName));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,orderId,businessId,senderMemberId,body,imageUrl,createdAt,senderName);

@override
String toString() {
  return 'Message(id: $id, orderId: $orderId, businessId: $businessId, senderMemberId: $senderMemberId, body: $body, imageUrl: $imageUrl, createdAt: $createdAt, senderName: $senderName)';
}


}

/// @nodoc
abstract mixin class $MessageCopyWith<$Res>  {
  factory $MessageCopyWith(Message value, $Res Function(Message) _then) = _$MessageCopyWithImpl;
@useResult
$Res call({
 String id, String orderId, String businessId, String senderMemberId, String body, String? imageUrl, DateTime? createdAt, String? senderName
});




}
/// @nodoc
class _$MessageCopyWithImpl<$Res>
    implements $MessageCopyWith<$Res> {
  _$MessageCopyWithImpl(this._self, this._then);

  final Message _self;
  final $Res Function(Message) _then;

/// Create a copy of Message
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? orderId = null,Object? businessId = null,Object? senderMemberId = null,Object? body = null,Object? imageUrl = freezed,Object? createdAt = freezed,Object? senderName = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,orderId: null == orderId ? _self.orderId : orderId // ignore: cast_nullable_to_non_nullable
as String,businessId: null == businessId ? _self.businessId : businessId // ignore: cast_nullable_to_non_nullable
as String,senderMemberId: null == senderMemberId ? _self.senderMemberId : senderMemberId // ignore: cast_nullable_to_non_nullable
as String,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,imageUrl: freezed == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,senderName: freezed == senderName ? _self.senderName : senderName // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [Message].
extension MessagePatterns on Message {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Message value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Message() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Message value)  $default,){
final _that = this;
switch (_that) {
case _Message():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Message value)?  $default,){
final _that = this;
switch (_that) {
case _Message() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String orderId,  String businessId,  String senderMemberId,  String body,  String? imageUrl,  DateTime? createdAt,  String? senderName)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Message() when $default != null:
return $default(_that.id,_that.orderId,_that.businessId,_that.senderMemberId,_that.body,_that.imageUrl,_that.createdAt,_that.senderName);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String orderId,  String businessId,  String senderMemberId,  String body,  String? imageUrl,  DateTime? createdAt,  String? senderName)  $default,) {final _that = this;
switch (_that) {
case _Message():
return $default(_that.id,_that.orderId,_that.businessId,_that.senderMemberId,_that.body,_that.imageUrl,_that.createdAt,_that.senderName);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String orderId,  String businessId,  String senderMemberId,  String body,  String? imageUrl,  DateTime? createdAt,  String? senderName)?  $default,) {final _that = this;
switch (_that) {
case _Message() when $default != null:
return $default(_that.id,_that.orderId,_that.businessId,_that.senderMemberId,_that.body,_that.imageUrl,_that.createdAt,_that.senderName);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Message implements Message {
  const _Message({required this.id, required this.orderId, required this.businessId, required this.senderMemberId, this.body = '', this.imageUrl, this.createdAt, this.senderName});
  factory _Message.fromJson(Map<String, dynamic> json) => _$MessageFromJson(json);

@override final  String id;
@override final  String orderId;
@override final  String businessId;
@override final  String senderMemberId;
@override@JsonKey() final  String body;
@override final  String? imageUrl;
@override final  DateTime? createdAt;
@override final  String? senderName;

/// Create a copy of Message
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MessageCopyWith<_Message> get copyWith => __$MessageCopyWithImpl<_Message>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MessageToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Message&&(identical(other.id, id) || other.id == id)&&(identical(other.orderId, orderId) || other.orderId == orderId)&&(identical(other.businessId, businessId) || other.businessId == businessId)&&(identical(other.senderMemberId, senderMemberId) || other.senderMemberId == senderMemberId)&&(identical(other.body, body) || other.body == body)&&(identical(other.imageUrl, imageUrl) || other.imageUrl == imageUrl)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.senderName, senderName) || other.senderName == senderName));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,orderId,businessId,senderMemberId,body,imageUrl,createdAt,senderName);

@override
String toString() {
  return 'Message(id: $id, orderId: $orderId, businessId: $businessId, senderMemberId: $senderMemberId, body: $body, imageUrl: $imageUrl, createdAt: $createdAt, senderName: $senderName)';
}


}

/// @nodoc
abstract mixin class _$MessageCopyWith<$Res> implements $MessageCopyWith<$Res> {
  factory _$MessageCopyWith(_Message value, $Res Function(_Message) _then) = __$MessageCopyWithImpl;
@override @useResult
$Res call({
 String id, String orderId, String businessId, String senderMemberId, String body, String? imageUrl, DateTime? createdAt, String? senderName
});




}
/// @nodoc
class __$MessageCopyWithImpl<$Res>
    implements _$MessageCopyWith<$Res> {
  __$MessageCopyWithImpl(this._self, this._then);

  final _Message _self;
  final $Res Function(_Message) _then;

/// Create a copy of Message
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? orderId = null,Object? businessId = null,Object? senderMemberId = null,Object? body = null,Object? imageUrl = freezed,Object? createdAt = freezed,Object? senderName = freezed,}) {
  return _then(_Message(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,orderId: null == orderId ? _self.orderId : orderId // ignore: cast_nullable_to_non_nullable
as String,businessId: null == businessId ? _self.businessId : businessId // ignore: cast_nullable_to_non_nullable
as String,senderMemberId: null == senderMemberId ? _self.senderMemberId : senderMemberId // ignore: cast_nullable_to_non_nullable
as String,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,imageUrl: freezed == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,senderName: freezed == senderName ? _self.senderName : senderName // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
