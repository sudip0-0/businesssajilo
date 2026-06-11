// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'dues_aging_report.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DuesAgingReport {

 int get bucket0to30; int get bucket31to60; int get bucket60plus; List<AgingCustomerRow> get customers;
/// Create a copy of DuesAgingReport
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DuesAgingReportCopyWith<DuesAgingReport> get copyWith => _$DuesAgingReportCopyWithImpl<DuesAgingReport>(this as DuesAgingReport, _$identity);

  /// Serializes this DuesAgingReport to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DuesAgingReport&&(identical(other.bucket0to30, bucket0to30) || other.bucket0to30 == bucket0to30)&&(identical(other.bucket31to60, bucket31to60) || other.bucket31to60 == bucket31to60)&&(identical(other.bucket60plus, bucket60plus) || other.bucket60plus == bucket60plus)&&const DeepCollectionEquality().equals(other.customers, customers));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,bucket0to30,bucket31to60,bucket60plus,const DeepCollectionEquality().hash(customers));

@override
String toString() {
  return 'DuesAgingReport(bucket0to30: $bucket0to30, bucket31to60: $bucket31to60, bucket60plus: $bucket60plus, customers: $customers)';
}


}

/// @nodoc
abstract mixin class $DuesAgingReportCopyWith<$Res>  {
  factory $DuesAgingReportCopyWith(DuesAgingReport value, $Res Function(DuesAgingReport) _then) = _$DuesAgingReportCopyWithImpl;
@useResult
$Res call({
 int bucket0to30, int bucket31to60, int bucket60plus, List<AgingCustomerRow> customers
});




}
/// @nodoc
class _$DuesAgingReportCopyWithImpl<$Res>
    implements $DuesAgingReportCopyWith<$Res> {
  _$DuesAgingReportCopyWithImpl(this._self, this._then);

  final DuesAgingReport _self;
  final $Res Function(DuesAgingReport) _then;

/// Create a copy of DuesAgingReport
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? bucket0to30 = null,Object? bucket31to60 = null,Object? bucket60plus = null,Object? customers = null,}) {
  return _then(_self.copyWith(
bucket0to30: null == bucket0to30 ? _self.bucket0to30 : bucket0to30 // ignore: cast_nullable_to_non_nullable
as int,bucket31to60: null == bucket31to60 ? _self.bucket31to60 : bucket31to60 // ignore: cast_nullable_to_non_nullable
as int,bucket60plus: null == bucket60plus ? _self.bucket60plus : bucket60plus // ignore: cast_nullable_to_non_nullable
as int,customers: null == customers ? _self.customers : customers // ignore: cast_nullable_to_non_nullable
as List<AgingCustomerRow>,
  ));
}

}


/// Adds pattern-matching-related methods to [DuesAgingReport].
extension DuesAgingReportPatterns on DuesAgingReport {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DuesAgingReport value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DuesAgingReport() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DuesAgingReport value)  $default,){
final _that = this;
switch (_that) {
case _DuesAgingReport():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DuesAgingReport value)?  $default,){
final _that = this;
switch (_that) {
case _DuesAgingReport() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int bucket0to30,  int bucket31to60,  int bucket60plus,  List<AgingCustomerRow> customers)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DuesAgingReport() when $default != null:
return $default(_that.bucket0to30,_that.bucket31to60,_that.bucket60plus,_that.customers);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int bucket0to30,  int bucket31to60,  int bucket60plus,  List<AgingCustomerRow> customers)  $default,) {final _that = this;
switch (_that) {
case _DuesAgingReport():
return $default(_that.bucket0to30,_that.bucket31to60,_that.bucket60plus,_that.customers);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int bucket0to30,  int bucket31to60,  int bucket60plus,  List<AgingCustomerRow> customers)?  $default,) {final _that = this;
switch (_that) {
case _DuesAgingReport() when $default != null:
return $default(_that.bucket0to30,_that.bucket31to60,_that.bucket60plus,_that.customers);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DuesAgingReport implements DuesAgingReport {
  const _DuesAgingReport({this.bucket0to30 = 0, this.bucket31to60 = 0, this.bucket60plus = 0, final  List<AgingCustomerRow> customers = const []}): _customers = customers;
  factory _DuesAgingReport.fromJson(Map<String, dynamic> json) => _$DuesAgingReportFromJson(json);

@override@JsonKey() final  int bucket0to30;
@override@JsonKey() final  int bucket31to60;
@override@JsonKey() final  int bucket60plus;
 final  List<AgingCustomerRow> _customers;
@override@JsonKey() List<AgingCustomerRow> get customers {
  if (_customers is EqualUnmodifiableListView) return _customers;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_customers);
}


/// Create a copy of DuesAgingReport
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DuesAgingReportCopyWith<_DuesAgingReport> get copyWith => __$DuesAgingReportCopyWithImpl<_DuesAgingReport>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DuesAgingReportToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DuesAgingReport&&(identical(other.bucket0to30, bucket0to30) || other.bucket0to30 == bucket0to30)&&(identical(other.bucket31to60, bucket31to60) || other.bucket31to60 == bucket31to60)&&(identical(other.bucket60plus, bucket60plus) || other.bucket60plus == bucket60plus)&&const DeepCollectionEquality().equals(other._customers, _customers));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,bucket0to30,bucket31to60,bucket60plus,const DeepCollectionEquality().hash(_customers));

@override
String toString() {
  return 'DuesAgingReport(bucket0to30: $bucket0to30, bucket31to60: $bucket31to60, bucket60plus: $bucket60plus, customers: $customers)';
}


}

/// @nodoc
abstract mixin class _$DuesAgingReportCopyWith<$Res> implements $DuesAgingReportCopyWith<$Res> {
  factory _$DuesAgingReportCopyWith(_DuesAgingReport value, $Res Function(_DuesAgingReport) _then) = __$DuesAgingReportCopyWithImpl;
@override @useResult
$Res call({
 int bucket0to30, int bucket31to60, int bucket60plus, List<AgingCustomerRow> customers
});




}
/// @nodoc
class __$DuesAgingReportCopyWithImpl<$Res>
    implements _$DuesAgingReportCopyWith<$Res> {
  __$DuesAgingReportCopyWithImpl(this._self, this._then);

  final _DuesAgingReport _self;
  final $Res Function(_DuesAgingReport) _then;

/// Create a copy of DuesAgingReport
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? bucket0to30 = null,Object? bucket31to60 = null,Object? bucket60plus = null,Object? customers = null,}) {
  return _then(_DuesAgingReport(
bucket0to30: null == bucket0to30 ? _self.bucket0to30 : bucket0to30 // ignore: cast_nullable_to_non_nullable
as int,bucket31to60: null == bucket31to60 ? _self.bucket31to60 : bucket31to60 // ignore: cast_nullable_to_non_nullable
as int,bucket60plus: null == bucket60plus ? _self.bucket60plus : bucket60plus // ignore: cast_nullable_to_non_nullable
as int,customers: null == customers ? _self._customers : customers // ignore: cast_nullable_to_non_nullable
as List<AgingCustomerRow>,
  ));
}


}

// dart format on
