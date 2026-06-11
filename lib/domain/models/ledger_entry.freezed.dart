// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'ledger_entry.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$LedgerEntry {

 String get customerId; String get businessId; DateTime get occurredAt; String get entryType; String get description; int get debitPaisa; int get creditPaisa; String? get refId; int get runningBalance;
/// Create a copy of LedgerEntry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LedgerEntryCopyWith<LedgerEntry> get copyWith => _$LedgerEntryCopyWithImpl<LedgerEntry>(this as LedgerEntry, _$identity);

  /// Serializes this LedgerEntry to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LedgerEntry&&(identical(other.customerId, customerId) || other.customerId == customerId)&&(identical(other.businessId, businessId) || other.businessId == businessId)&&(identical(other.occurredAt, occurredAt) || other.occurredAt == occurredAt)&&(identical(other.entryType, entryType) || other.entryType == entryType)&&(identical(other.description, description) || other.description == description)&&(identical(other.debitPaisa, debitPaisa) || other.debitPaisa == debitPaisa)&&(identical(other.creditPaisa, creditPaisa) || other.creditPaisa == creditPaisa)&&(identical(other.refId, refId) || other.refId == refId)&&(identical(other.runningBalance, runningBalance) || other.runningBalance == runningBalance));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,customerId,businessId,occurredAt,entryType,description,debitPaisa,creditPaisa,refId,runningBalance);

@override
String toString() {
  return 'LedgerEntry(customerId: $customerId, businessId: $businessId, occurredAt: $occurredAt, entryType: $entryType, description: $description, debitPaisa: $debitPaisa, creditPaisa: $creditPaisa, refId: $refId, runningBalance: $runningBalance)';
}


}

/// @nodoc
abstract mixin class $LedgerEntryCopyWith<$Res>  {
  factory $LedgerEntryCopyWith(LedgerEntry value, $Res Function(LedgerEntry) _then) = _$LedgerEntryCopyWithImpl;
@useResult
$Res call({
 String customerId, String businessId, DateTime occurredAt, String entryType, String description, int debitPaisa, int creditPaisa, String? refId, int runningBalance
});




}
/// @nodoc
class _$LedgerEntryCopyWithImpl<$Res>
    implements $LedgerEntryCopyWith<$Res> {
  _$LedgerEntryCopyWithImpl(this._self, this._then);

  final LedgerEntry _self;
  final $Res Function(LedgerEntry) _then;

/// Create a copy of LedgerEntry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? customerId = null,Object? businessId = null,Object? occurredAt = null,Object? entryType = null,Object? description = null,Object? debitPaisa = null,Object? creditPaisa = null,Object? refId = freezed,Object? runningBalance = null,}) {
  return _then(_self.copyWith(
customerId: null == customerId ? _self.customerId : customerId // ignore: cast_nullable_to_non_nullable
as String,businessId: null == businessId ? _self.businessId : businessId // ignore: cast_nullable_to_non_nullable
as String,occurredAt: null == occurredAt ? _self.occurredAt : occurredAt // ignore: cast_nullable_to_non_nullable
as DateTime,entryType: null == entryType ? _self.entryType : entryType // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,debitPaisa: null == debitPaisa ? _self.debitPaisa : debitPaisa // ignore: cast_nullable_to_non_nullable
as int,creditPaisa: null == creditPaisa ? _self.creditPaisa : creditPaisa // ignore: cast_nullable_to_non_nullable
as int,refId: freezed == refId ? _self.refId : refId // ignore: cast_nullable_to_non_nullable
as String?,runningBalance: null == runningBalance ? _self.runningBalance : runningBalance // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [LedgerEntry].
extension LedgerEntryPatterns on LedgerEntry {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LedgerEntry value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LedgerEntry() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LedgerEntry value)  $default,){
final _that = this;
switch (_that) {
case _LedgerEntry():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LedgerEntry value)?  $default,){
final _that = this;
switch (_that) {
case _LedgerEntry() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String customerId,  String businessId,  DateTime occurredAt,  String entryType,  String description,  int debitPaisa,  int creditPaisa,  String? refId,  int runningBalance)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LedgerEntry() when $default != null:
return $default(_that.customerId,_that.businessId,_that.occurredAt,_that.entryType,_that.description,_that.debitPaisa,_that.creditPaisa,_that.refId,_that.runningBalance);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String customerId,  String businessId,  DateTime occurredAt,  String entryType,  String description,  int debitPaisa,  int creditPaisa,  String? refId,  int runningBalance)  $default,) {final _that = this;
switch (_that) {
case _LedgerEntry():
return $default(_that.customerId,_that.businessId,_that.occurredAt,_that.entryType,_that.description,_that.debitPaisa,_that.creditPaisa,_that.refId,_that.runningBalance);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String customerId,  String businessId,  DateTime occurredAt,  String entryType,  String description,  int debitPaisa,  int creditPaisa,  String? refId,  int runningBalance)?  $default,) {final _that = this;
switch (_that) {
case _LedgerEntry() when $default != null:
return $default(_that.customerId,_that.businessId,_that.occurredAt,_that.entryType,_that.description,_that.debitPaisa,_that.creditPaisa,_that.refId,_that.runningBalance);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LedgerEntry implements LedgerEntry {
  const _LedgerEntry({required this.customerId, required this.businessId, required this.occurredAt, required this.entryType, required this.description, this.debitPaisa = 0, this.creditPaisa = 0, this.refId, this.runningBalance = 0});
  factory _LedgerEntry.fromJson(Map<String, dynamic> json) => _$LedgerEntryFromJson(json);

@override final  String customerId;
@override final  String businessId;
@override final  DateTime occurredAt;
@override final  String entryType;
@override final  String description;
@override@JsonKey() final  int debitPaisa;
@override@JsonKey() final  int creditPaisa;
@override final  String? refId;
@override@JsonKey() final  int runningBalance;

/// Create a copy of LedgerEntry
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LedgerEntryCopyWith<_LedgerEntry> get copyWith => __$LedgerEntryCopyWithImpl<_LedgerEntry>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LedgerEntryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LedgerEntry&&(identical(other.customerId, customerId) || other.customerId == customerId)&&(identical(other.businessId, businessId) || other.businessId == businessId)&&(identical(other.occurredAt, occurredAt) || other.occurredAt == occurredAt)&&(identical(other.entryType, entryType) || other.entryType == entryType)&&(identical(other.description, description) || other.description == description)&&(identical(other.debitPaisa, debitPaisa) || other.debitPaisa == debitPaisa)&&(identical(other.creditPaisa, creditPaisa) || other.creditPaisa == creditPaisa)&&(identical(other.refId, refId) || other.refId == refId)&&(identical(other.runningBalance, runningBalance) || other.runningBalance == runningBalance));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,customerId,businessId,occurredAt,entryType,description,debitPaisa,creditPaisa,refId,runningBalance);

@override
String toString() {
  return 'LedgerEntry(customerId: $customerId, businessId: $businessId, occurredAt: $occurredAt, entryType: $entryType, description: $description, debitPaisa: $debitPaisa, creditPaisa: $creditPaisa, refId: $refId, runningBalance: $runningBalance)';
}


}

/// @nodoc
abstract mixin class _$LedgerEntryCopyWith<$Res> implements $LedgerEntryCopyWith<$Res> {
  factory _$LedgerEntryCopyWith(_LedgerEntry value, $Res Function(_LedgerEntry) _then) = __$LedgerEntryCopyWithImpl;
@override @useResult
$Res call({
 String customerId, String businessId, DateTime occurredAt, String entryType, String description, int debitPaisa, int creditPaisa, String? refId, int runningBalance
});




}
/// @nodoc
class __$LedgerEntryCopyWithImpl<$Res>
    implements _$LedgerEntryCopyWith<$Res> {
  __$LedgerEntryCopyWithImpl(this._self, this._then);

  final _LedgerEntry _self;
  final $Res Function(_LedgerEntry) _then;

/// Create a copy of LedgerEntry
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? customerId = null,Object? businessId = null,Object? occurredAt = null,Object? entryType = null,Object? description = null,Object? debitPaisa = null,Object? creditPaisa = null,Object? refId = freezed,Object? runningBalance = null,}) {
  return _then(_LedgerEntry(
customerId: null == customerId ? _self.customerId : customerId // ignore: cast_nullable_to_non_nullable
as String,businessId: null == businessId ? _self.businessId : businessId // ignore: cast_nullable_to_non_nullable
as String,occurredAt: null == occurredAt ? _self.occurredAt : occurredAt // ignore: cast_nullable_to_non_nullable
as DateTime,entryType: null == entryType ? _self.entryType : entryType // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,debitPaisa: null == debitPaisa ? _self.debitPaisa : debitPaisa // ignore: cast_nullable_to_non_nullable
as int,creditPaisa: null == creditPaisa ? _self.creditPaisa : creditPaisa // ignore: cast_nullable_to_non_nullable
as int,refId: freezed == refId ? _self.refId : refId // ignore: cast_nullable_to_non_nullable
as String?,runningBalance: null == runningBalance ? _self.runningBalance : runningBalance // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
