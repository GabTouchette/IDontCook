// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'media_type.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

MediaType _$MediaTypeFromJson(Map<String, dynamic> json) {
  return _MediaType.fromJson(json);
}

/// @nodoc
mixin _$MediaType {
  String get mimeType => throw _privateConstructorUsedError;
  String get extension => throw _privateConstructorUsedError;

  /// Serializes this MediaType to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MediaType
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MediaTypeCopyWith<MediaType> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MediaTypeCopyWith<$Res> {
  factory $MediaTypeCopyWith(MediaType value, $Res Function(MediaType) then) =
      _$MediaTypeCopyWithImpl<$Res, MediaType>;
  @useResult
  $Res call({String mimeType, String extension});
}

/// @nodoc
class _$MediaTypeCopyWithImpl<$Res, $Val extends MediaType>
    implements $MediaTypeCopyWith<$Res> {
  _$MediaTypeCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MediaType
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? mimeType = null,
    Object? extension = null,
  }) {
    return _then(_value.copyWith(
      mimeType: null == mimeType
          ? _value.mimeType
          : mimeType // ignore: cast_nullable_to_non_nullable
              as String,
      extension: null == extension
          ? _value.extension
          : extension // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$MediaTypeImplCopyWith<$Res>
    implements $MediaTypeCopyWith<$Res> {
  factory _$$MediaTypeImplCopyWith(
          _$MediaTypeImpl value, $Res Function(_$MediaTypeImpl) then) =
      __$$MediaTypeImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String mimeType, String extension});
}

/// @nodoc
class __$$MediaTypeImplCopyWithImpl<$Res>
    extends _$MediaTypeCopyWithImpl<$Res, _$MediaTypeImpl>
    implements _$$MediaTypeImplCopyWith<$Res> {
  __$$MediaTypeImplCopyWithImpl(
      _$MediaTypeImpl _value, $Res Function(_$MediaTypeImpl) _then)
      : super(_value, _then);

  /// Create a copy of MediaType
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? mimeType = null,
    Object? extension = null,
  }) {
    return _then(_$MediaTypeImpl(
      mimeType: null == mimeType
          ? _value.mimeType
          : mimeType // ignore: cast_nullable_to_non_nullable
              as String,
      extension: null == extension
          ? _value.extension
          : extension // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$MediaTypeImpl implements _MediaType {
  const _$MediaTypeImpl({required this.mimeType, required this.extension});

  factory _$MediaTypeImpl.fromJson(Map<String, dynamic> json) =>
      _$$MediaTypeImplFromJson(json);

  @override
  final String mimeType;
  @override
  final String extension;

  @override
  String toString() {
    return 'MediaType(mimeType: $mimeType, extension: $extension)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MediaTypeImpl &&
            (identical(other.mimeType, mimeType) ||
                other.mimeType == mimeType) &&
            (identical(other.extension, extension) ||
                other.extension == extension));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, mimeType, extension);

  /// Create a copy of MediaType
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MediaTypeImplCopyWith<_$MediaTypeImpl> get copyWith =>
      __$$MediaTypeImplCopyWithImpl<_$MediaTypeImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MediaTypeImplToJson(
      this,
    );
  }
}

abstract class _MediaType implements MediaType {
  const factory _MediaType(
      {required final String mimeType,
      required final String extension}) = _$MediaTypeImpl;

  factory _MediaType.fromJson(Map<String, dynamic> json) =
      _$MediaTypeImpl.fromJson;

  @override
  String get mimeType;
  @override
  String get extension;

  /// Create a copy of MediaType
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MediaTypeImplCopyWith<_$MediaTypeImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
