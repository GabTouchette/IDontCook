// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'grocery_store.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

GroceryStore _$GroceryStoreFromJson(Map<String, dynamic> json) {
  return _GroceryStore.fromJson(json);
}

/// @nodoc
mixin _$GroceryStore {
  String get merchant => throw _privateConstructorUsedError;
  int get merchant_id => throw _privateConstructorUsedError;
  int? get flyer_id => throw _privateConstructorUsedError;
  String? get logo_url => throw _privateConstructorUsedError;
  String? get valid_from => throw _privateConstructorUsedError;
  String? get valid_to =>
      throw _privateConstructorUsedError; // Specific location name from OSM (e.g. "Metro Marcano"); falls back to the
// banner name. Present + lat/lng/distance_m set when a location matched.
  String? get name => throw _privateConstructorUsedError;
  double? get lat => throw _privateConstructorUsedError;
  double? get lng => throw _privateConstructorUsedError;
  int? get distance_m => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $GroceryStoreCopyWith<GroceryStore> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GroceryStoreCopyWith<$Res> {
  factory $GroceryStoreCopyWith(
          GroceryStore value, $Res Function(GroceryStore) then) =
      _$GroceryStoreCopyWithImpl<$Res, GroceryStore>;
  @useResult
  $Res call(
      {String merchant,
      int merchant_id,
      int? flyer_id,
      String? logo_url,
      String? valid_from,
      String? valid_to,
      String? name,
      double? lat,
      double? lng,
      int? distance_m});
}

/// @nodoc
class _$GroceryStoreCopyWithImpl<$Res, $Val extends GroceryStore>
    implements $GroceryStoreCopyWith<$Res> {
  _$GroceryStoreCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? merchant = null,
    Object? merchant_id = null,
    Object? flyer_id = freezed,
    Object? logo_url = freezed,
    Object? valid_from = freezed,
    Object? valid_to = freezed,
    Object? name = freezed,
    Object? lat = freezed,
    Object? lng = freezed,
    Object? distance_m = freezed,
  }) {
    return _then(_value.copyWith(
      merchant: null == merchant
          ? _value.merchant
          : merchant // ignore: cast_nullable_to_non_nullable
              as String,
      merchant_id: null == merchant_id
          ? _value.merchant_id
          : merchant_id // ignore: cast_nullable_to_non_nullable
              as int,
      flyer_id: freezed == flyer_id
          ? _value.flyer_id
          : flyer_id // ignore: cast_nullable_to_non_nullable
              as int?,
      logo_url: freezed == logo_url
          ? _value.logo_url
          : logo_url // ignore: cast_nullable_to_non_nullable
              as String?,
      valid_from: freezed == valid_from
          ? _value.valid_from
          : valid_from // ignore: cast_nullable_to_non_nullable
              as String?,
      valid_to: freezed == valid_to
          ? _value.valid_to
          : valid_to // ignore: cast_nullable_to_non_nullable
              as String?,
      name: freezed == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String?,
      lat: freezed == lat
          ? _value.lat
          : lat // ignore: cast_nullable_to_non_nullable
              as double?,
      lng: freezed == lng
          ? _value.lng
          : lng // ignore: cast_nullable_to_non_nullable
              as double?,
      distance_m: freezed == distance_m
          ? _value.distance_m
          : distance_m // ignore: cast_nullable_to_non_nullable
              as int?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$GroceryStoreImplCopyWith<$Res>
    implements $GroceryStoreCopyWith<$Res> {
  factory _$$GroceryStoreImplCopyWith(
          _$GroceryStoreImpl value, $Res Function(_$GroceryStoreImpl) then) =
      __$$GroceryStoreImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String merchant,
      int merchant_id,
      int? flyer_id,
      String? logo_url,
      String? valid_from,
      String? valid_to,
      String? name,
      double? lat,
      double? lng,
      int? distance_m});
}

/// @nodoc
class __$$GroceryStoreImplCopyWithImpl<$Res>
    extends _$GroceryStoreCopyWithImpl<$Res, _$GroceryStoreImpl>
    implements _$$GroceryStoreImplCopyWith<$Res> {
  __$$GroceryStoreImplCopyWithImpl(
      _$GroceryStoreImpl _value, $Res Function(_$GroceryStoreImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? merchant = null,
    Object? merchant_id = null,
    Object? flyer_id = freezed,
    Object? logo_url = freezed,
    Object? valid_from = freezed,
    Object? valid_to = freezed,
    Object? name = freezed,
    Object? lat = freezed,
    Object? lng = freezed,
    Object? distance_m = freezed,
  }) {
    return _then(_$GroceryStoreImpl(
      merchant: null == merchant
          ? _value.merchant
          : merchant // ignore: cast_nullable_to_non_nullable
              as String,
      merchant_id: null == merchant_id
          ? _value.merchant_id
          : merchant_id // ignore: cast_nullable_to_non_nullable
              as int,
      flyer_id: freezed == flyer_id
          ? _value.flyer_id
          : flyer_id // ignore: cast_nullable_to_non_nullable
              as int?,
      logo_url: freezed == logo_url
          ? _value.logo_url
          : logo_url // ignore: cast_nullable_to_non_nullable
              as String?,
      valid_from: freezed == valid_from
          ? _value.valid_from
          : valid_from // ignore: cast_nullable_to_non_nullable
              as String?,
      valid_to: freezed == valid_to
          ? _value.valid_to
          : valid_to // ignore: cast_nullable_to_non_nullable
              as String?,
      name: freezed == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String?,
      lat: freezed == lat
          ? _value.lat
          : lat // ignore: cast_nullable_to_non_nullable
              as double?,
      lng: freezed == lng
          ? _value.lng
          : lng // ignore: cast_nullable_to_non_nullable
              as double?,
      distance_m: freezed == distance_m
          ? _value.distance_m
          : distance_m // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$GroceryStoreImpl extends _GroceryStore {
  const _$GroceryStoreImpl(
      {required this.merchant,
      required this.merchant_id,
      this.flyer_id,
      this.logo_url,
      this.valid_from,
      this.valid_to,
      this.name,
      this.lat,
      this.lng,
      this.distance_m})
      : super._();

  factory _$GroceryStoreImpl.fromJson(Map<String, dynamic> json) =>
      _$$GroceryStoreImplFromJson(json);

  @override
  final String merchant;
  @override
  final int merchant_id;
  @override
  final int? flyer_id;
  @override
  final String? logo_url;
  @override
  final String? valid_from;
  @override
  final String? valid_to;
// Specific location name from OSM (e.g. "Metro Marcano"); falls back to the
// banner name. Present + lat/lng/distance_m set when a location matched.
  @override
  final String? name;
  @override
  final double? lat;
  @override
  final double? lng;
  @override
  final int? distance_m;

  @override
  String toString() {
    return 'GroceryStore(merchant: $merchant, merchant_id: $merchant_id, flyer_id: $flyer_id, logo_url: $logo_url, valid_from: $valid_from, valid_to: $valid_to, name: $name, lat: $lat, lng: $lng, distance_m: $distance_m)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GroceryStoreImpl &&
            (identical(other.merchant, merchant) ||
                other.merchant == merchant) &&
            (identical(other.merchant_id, merchant_id) ||
                other.merchant_id == merchant_id) &&
            (identical(other.flyer_id, flyer_id) ||
                other.flyer_id == flyer_id) &&
            (identical(other.logo_url, logo_url) ||
                other.logo_url == logo_url) &&
            (identical(other.valid_from, valid_from) ||
                other.valid_from == valid_from) &&
            (identical(other.valid_to, valid_to) ||
                other.valid_to == valid_to) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.lat, lat) || other.lat == lat) &&
            (identical(other.lng, lng) || other.lng == lng) &&
            (identical(other.distance_m, distance_m) ||
                other.distance_m == distance_m));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, merchant, merchant_id, flyer_id,
      logo_url, valid_from, valid_to, name, lat, lng, distance_m);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$GroceryStoreImplCopyWith<_$GroceryStoreImpl> get copyWith =>
      __$$GroceryStoreImplCopyWithImpl<_$GroceryStoreImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$GroceryStoreImplToJson(
      this,
    );
  }
}

abstract class _GroceryStore extends GroceryStore {
  const factory _GroceryStore(
      {required final String merchant,
      required final int merchant_id,
      final int? flyer_id,
      final String? logo_url,
      final String? valid_from,
      final String? valid_to,
      final String? name,
      final double? lat,
      final double? lng,
      final int? distance_m}) = _$GroceryStoreImpl;
  const _GroceryStore._() : super._();

  factory _GroceryStore.fromJson(Map<String, dynamic> json) =
      _$GroceryStoreImpl.fromJson;

  @override
  String get merchant;
  @override
  int get merchant_id;
  @override
  int? get flyer_id;
  @override
  String? get logo_url;
  @override
  String? get valid_from;
  @override
  String? get valid_to;
  @override // Specific location name from OSM (e.g. "Metro Marcano"); falls back to the
// banner name. Present + lat/lng/distance_m set when a location matched.
  String? get name;
  @override
  double? get lat;
  @override
  double? get lng;
  @override
  int? get distance_m;
  @override
  @JsonKey(ignore: true)
  _$$GroceryStoreImplCopyWith<_$GroceryStoreImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
