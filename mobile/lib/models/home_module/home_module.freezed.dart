// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'home_module.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$HomeModule {
  String get id => throw _privateConstructorUsedError;
  String get moduleType => throw _privateConstructorUsedError;
  String get reason => throw _privateConstructorUsedError;
  ModulePayload get payload => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $HomeModuleCopyWith<HomeModule> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $HomeModuleCopyWith<$Res> {
  factory $HomeModuleCopyWith(
          HomeModule value, $Res Function(HomeModule) then) =
      _$HomeModuleCopyWithImpl<$Res, HomeModule>;
  @useResult
  $Res call(
      {String id, String moduleType, String reason, ModulePayload payload});
}

/// @nodoc
class _$HomeModuleCopyWithImpl<$Res, $Val extends HomeModule>
    implements $HomeModuleCopyWith<$Res> {
  _$HomeModuleCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? moduleType = null,
    Object? reason = null,
    Object? payload = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      moduleType: null == moduleType
          ? _value.moduleType
          : moduleType // ignore: cast_nullable_to_non_nullable
              as String,
      reason: null == reason
          ? _value.reason
          : reason // ignore: cast_nullable_to_non_nullable
              as String,
      payload: null == payload
          ? _value.payload
          : payload // ignore: cast_nullable_to_non_nullable
              as ModulePayload,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$HomeModuleImplCopyWith<$Res>
    implements $HomeModuleCopyWith<$Res> {
  factory _$$HomeModuleImplCopyWith(
          _$HomeModuleImpl value, $Res Function(_$HomeModuleImpl) then) =
      __$$HomeModuleImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id, String moduleType, String reason, ModulePayload payload});
}

/// @nodoc
class __$$HomeModuleImplCopyWithImpl<$Res>
    extends _$HomeModuleCopyWithImpl<$Res, _$HomeModuleImpl>
    implements _$$HomeModuleImplCopyWith<$Res> {
  __$$HomeModuleImplCopyWithImpl(
      _$HomeModuleImpl _value, $Res Function(_$HomeModuleImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? moduleType = null,
    Object? reason = null,
    Object? payload = null,
  }) {
    return _then(_$HomeModuleImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      moduleType: null == moduleType
          ? _value.moduleType
          : moduleType // ignore: cast_nullable_to_non_nullable
              as String,
      reason: null == reason
          ? _value.reason
          : reason // ignore: cast_nullable_to_non_nullable
              as String,
      payload: null == payload
          ? _value.payload
          : payload // ignore: cast_nullable_to_non_nullable
              as ModulePayload,
    ));
  }
}

/// @nodoc

class _$HomeModuleImpl extends _HomeModule {
  const _$HomeModuleImpl(
      {required this.id,
      required this.moduleType,
      this.reason = '',
      this.payload = const UnknownModulePayload()})
      : super._();

  @override
  final String id;
  @override
  final String moduleType;
  @override
  @JsonKey()
  final String reason;
  @override
  @JsonKey()
  final ModulePayload payload;

  @override
  String toString() {
    return 'HomeModule(id: $id, moduleType: $moduleType, reason: $reason, payload: $payload)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$HomeModuleImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.moduleType, moduleType) ||
                other.moduleType == moduleType) &&
            (identical(other.reason, reason) || other.reason == reason) &&
            (identical(other.payload, payload) || other.payload == payload));
  }

  @override
  int get hashCode => Object.hash(runtimeType, id, moduleType, reason, payload);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$HomeModuleImplCopyWith<_$HomeModuleImpl> get copyWith =>
      __$$HomeModuleImplCopyWithImpl<_$HomeModuleImpl>(this, _$identity);
}

abstract class _HomeModule extends HomeModule {
  const factory _HomeModule(
      {required final String id,
      required final String moduleType,
      final String reason,
      final ModulePayload payload}) = _$HomeModuleImpl;
  const _HomeModule._() : super._();

  @override
  String get id;
  @override
  String get moduleType;
  @override
  String get reason;
  @override
  ModulePayload get payload;
  @override
  @JsonKey(ignore: true)
  _$$HomeModuleImplCopyWith<_$HomeModuleImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
