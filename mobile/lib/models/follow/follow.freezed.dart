// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'follow.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Follow _$FollowFromJson(Map<String, dynamic> json) {
  return _Follow.fromJson(json);
}

/// @nodoc
mixin _$Follow {
  int get id => throw _privateConstructorUsedError;
  User get follower => throw _privateConstructorUsedError;
  User get followed => throw _privateConstructorUsedError;
  DateTime? get created_at => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $FollowCopyWith<Follow> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FollowCopyWith<$Res> {
  factory $FollowCopyWith(Follow value, $Res Function(Follow) then) =
      _$FollowCopyWithImpl<$Res, Follow>;
  @useResult
  $Res call({int id, User follower, User followed, DateTime? created_at});

  $UserCopyWith<$Res> get follower;
  $UserCopyWith<$Res> get followed;
}

/// @nodoc
class _$FollowCopyWithImpl<$Res, $Val extends Follow>
    implements $FollowCopyWith<$Res> {
  _$FollowCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? follower = null,
    Object? followed = null,
    Object? created_at = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      follower: null == follower
          ? _value.follower
          : follower // ignore: cast_nullable_to_non_nullable
              as User,
      followed: null == followed
          ? _value.followed
          : followed // ignore: cast_nullable_to_non_nullable
              as User,
      created_at: freezed == created_at
          ? _value.created_at
          : created_at // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $UserCopyWith<$Res> get follower {
    return $UserCopyWith<$Res>(_value.follower, (value) {
      return _then(_value.copyWith(follower: value) as $Val);
    });
  }

  @override
  @pragma('vm:prefer-inline')
  $UserCopyWith<$Res> get followed {
    return $UserCopyWith<$Res>(_value.followed, (value) {
      return _then(_value.copyWith(followed: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$FollowImplCopyWith<$Res> implements $FollowCopyWith<$Res> {
  factory _$$FollowImplCopyWith(
          _$FollowImpl value, $Res Function(_$FollowImpl) then) =
      __$$FollowImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int id, User follower, User followed, DateTime? created_at});

  @override
  $UserCopyWith<$Res> get follower;
  @override
  $UserCopyWith<$Res> get followed;
}

/// @nodoc
class __$$FollowImplCopyWithImpl<$Res>
    extends _$FollowCopyWithImpl<$Res, _$FollowImpl>
    implements _$$FollowImplCopyWith<$Res> {
  __$$FollowImplCopyWithImpl(
      _$FollowImpl _value, $Res Function(_$FollowImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? follower = null,
    Object? followed = null,
    Object? created_at = freezed,
  }) {
    return _then(_$FollowImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      follower: null == follower
          ? _value.follower
          : follower // ignore: cast_nullable_to_non_nullable
              as User,
      followed: null == followed
          ? _value.followed
          : followed // ignore: cast_nullable_to_non_nullable
              as User,
      created_at: freezed == created_at
          ? _value.created_at
          : created_at // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$FollowImpl implements _Follow {
  _$FollowImpl(
      {required this.id,
      required this.follower,
      required this.followed,
      this.created_at});

  factory _$FollowImpl.fromJson(Map<String, dynamic> json) =>
      _$$FollowImplFromJson(json);

  @override
  final int id;
  @override
  final User follower;
  @override
  final User followed;
  @override
  final DateTime? created_at;

  @override
  String toString() {
    return 'Follow(id: $id, follower: $follower, followed: $followed, created_at: $created_at)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FollowImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.follower, follower) ||
                other.follower == follower) &&
            (identical(other.followed, followed) ||
                other.followed == followed) &&
            (identical(other.created_at, created_at) ||
                other.created_at == created_at));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, follower, followed, created_at);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$FollowImplCopyWith<_$FollowImpl> get copyWith =>
      __$$FollowImplCopyWithImpl<_$FollowImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$FollowImplToJson(
      this,
    );
  }
}

abstract class _Follow implements Follow {
  factory _Follow(
      {required final int id,
      required final User follower,
      required final User followed,
      final DateTime? created_at}) = _$FollowImpl;

  factory _Follow.fromJson(Map<String, dynamic> json) = _$FollowImpl.fromJson;

  @override
  int get id;
  @override
  User get follower;
  @override
  User get followed;
  @override
  DateTime? get created_at;
  @override
  @JsonKey(ignore: true)
  _$$FollowImplCopyWith<_$FollowImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
