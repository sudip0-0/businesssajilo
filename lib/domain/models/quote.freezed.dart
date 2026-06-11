// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'quote.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Quote {

 String get id; String get orderId; int get version; QuoteStatus get status; int get total; String? get responseComment; String get createdBy; DateTime? get createdAt; List<QuoteItem> get items;
/// Create a copy of Quote
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$QuoteCopyWith<Quote> get copyWith => _$QuoteCopyWithImpl<Quote>(this as Quote, _$identity);

  /// Serializes this Quote to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Quote&&(identical(other.id, id) || other.id == id)&&(identical(other.orderId, orderId) || other.orderId == orderId)&&(identical(other.version, version) || other.version == version)&&(identical(other.status, status) || other.status == status)&&(identical(other.total, total) || other.total == total)&&(identical(other.responseComment, responseComment) || other.responseComment == responseComment)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&const DeepCollectionEquality().equals(other.items, items));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,orderId,version,status,total,responseComment,createdBy,createdAt,const DeepCollectionEquality().hash(items));

@override
String toString() {
  return 'Quote(id: $id, orderId: $orderId, version: $version, status: $status, total: $total, responseComment: $responseComment, createdBy: $createdBy, createdAt: $createdAt, items: $items)';
}


}

/// @nodoc
abstract mixin class $QuoteCopyWith<$Res>  {
  factory $QuoteCopyWith(Quote value, $Res Function(Quote) _then) = _$QuoteCopyWithImpl;
@useResult
$Res call({
 String id, String orderId, int version, QuoteStatus status, int total, String? responseComment, String createdBy, DateTime? createdAt, List<QuoteItem> items
});




}
/// @nodoc
class _$QuoteCopyWithImpl<$Res>
    implements $QuoteCopyWith<$Res> {
  _$QuoteCopyWithImpl(this._self, this._then);

  final Quote _self;
  final $Res Function(Quote) _then;

/// Create a copy of Quote
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? orderId = null,Object? version = null,Object? status = null,Object? total = null,Object? responseComment = freezed,Object? createdBy = null,Object? createdAt = freezed,Object? items = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,orderId: null == orderId ? _self.orderId : orderId // ignore: cast_nullable_to_non_nullable
as String,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as QuoteStatus,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,responseComment: freezed == responseComment ? _self.responseComment : responseComment // ignore: cast_nullable_to_non_nullable
as String?,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<QuoteItem>,
  ));
}

}


/// Adds pattern-matching-related methods to [Quote].
extension QuotePatterns on Quote {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Quote value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Quote() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Quote value)  $default,){
final _that = this;
switch (_that) {
case _Quote():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Quote value)?  $default,){
final _that = this;
switch (_that) {
case _Quote() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String orderId,  int version,  QuoteStatus status,  int total,  String? responseComment,  String createdBy,  DateTime? createdAt,  List<QuoteItem> items)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Quote() when $default != null:
return $default(_that.id,_that.orderId,_that.version,_that.status,_that.total,_that.responseComment,_that.createdBy,_that.createdAt,_that.items);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String orderId,  int version,  QuoteStatus status,  int total,  String? responseComment,  String createdBy,  DateTime? createdAt,  List<QuoteItem> items)  $default,) {final _that = this;
switch (_that) {
case _Quote():
return $default(_that.id,_that.orderId,_that.version,_that.status,_that.total,_that.responseComment,_that.createdBy,_that.createdAt,_that.items);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String orderId,  int version,  QuoteStatus status,  int total,  String? responseComment,  String createdBy,  DateTime? createdAt,  List<QuoteItem> items)?  $default,) {final _that = this;
switch (_that) {
case _Quote() when $default != null:
return $default(_that.id,_that.orderId,_that.version,_that.status,_that.total,_that.responseComment,_that.createdBy,_that.createdAt,_that.items);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Quote implements Quote {
  const _Quote({required this.id, required this.orderId, required this.version, required this.status, this.total = 0, this.responseComment, required this.createdBy, this.createdAt, final  List<QuoteItem> items = const []}): _items = items;
  factory _Quote.fromJson(Map<String, dynamic> json) => _$QuoteFromJson(json);

@override final  String id;
@override final  String orderId;
@override final  int version;
@override final  QuoteStatus status;
@override@JsonKey() final  int total;
@override final  String? responseComment;
@override final  String createdBy;
@override final  DateTime? createdAt;
 final  List<QuoteItem> _items;
@override@JsonKey() List<QuoteItem> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}


/// Create a copy of Quote
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$QuoteCopyWith<_Quote> get copyWith => __$QuoteCopyWithImpl<_Quote>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$QuoteToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Quote&&(identical(other.id, id) || other.id == id)&&(identical(other.orderId, orderId) || other.orderId == orderId)&&(identical(other.version, version) || other.version == version)&&(identical(other.status, status) || other.status == status)&&(identical(other.total, total) || other.total == total)&&(identical(other.responseComment, responseComment) || other.responseComment == responseComment)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&const DeepCollectionEquality().equals(other._items, _items));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,orderId,version,status,total,responseComment,createdBy,createdAt,const DeepCollectionEquality().hash(_items));

@override
String toString() {
  return 'Quote(id: $id, orderId: $orderId, version: $version, status: $status, total: $total, responseComment: $responseComment, createdBy: $createdBy, createdAt: $createdAt, items: $items)';
}


}

/// @nodoc
abstract mixin class _$QuoteCopyWith<$Res> implements $QuoteCopyWith<$Res> {
  factory _$QuoteCopyWith(_Quote value, $Res Function(_Quote) _then) = __$QuoteCopyWithImpl;
@override @useResult
$Res call({
 String id, String orderId, int version, QuoteStatus status, int total, String? responseComment, String createdBy, DateTime? createdAt, List<QuoteItem> items
});




}
/// @nodoc
class __$QuoteCopyWithImpl<$Res>
    implements _$QuoteCopyWith<$Res> {
  __$QuoteCopyWithImpl(this._self, this._then);

  final _Quote _self;
  final $Res Function(_Quote) _then;

/// Create a copy of Quote
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? orderId = null,Object? version = null,Object? status = null,Object? total = null,Object? responseComment = freezed,Object? createdBy = null,Object? createdAt = freezed,Object? items = null,}) {
  return _then(_Quote(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,orderId: null == orderId ? _self.orderId : orderId // ignore: cast_nullable_to_non_nullable
as String,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as QuoteStatus,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,responseComment: freezed == responseComment ? _self.responseComment : responseComment // ignore: cast_nullable_to_non_nullable
as String?,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<QuoteItem>,
  ));
}


}

// dart format on
