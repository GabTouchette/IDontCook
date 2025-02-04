// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'vote.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Vote _$VoteFromJson(Map<String, dynamic> json) {
  return _Vote.fromJson(json);
}

/// @nodoc
mixin _$Vote {
  int get id => throw _privateConstructorUsedError;
  User get user => throw _privateConstructorUsedError;
  Post get post => throw _privateConstructorUsedError;
  bool get is_upvote => throw _privateConstructorUsedError;
  DateTime? get created_at => throw _privateConstructorUsedError;

  /// Serializes this Vote to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Vote
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $VoteCopyWith<Vote> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $VoteCopyWith<$Res> {
  factory $VoteCopyWith(Vote value, $Res Function(Vote) then) =
      _$VoteCopyWithImpl<$Res, Vote>;
  @useResult
  $Res call(
      {int id, User user, Post post, bool is_upvote, DateTime? created_at});

  $UserCopyWith<$Res> get user;
  $PostCopyWith<$Res> get post;
}

/// @nodoc
class _$VoteCopyWithImpl<$Res, $Val extends Vote>
    implements $VoteCopyWith<$Res> {
  _$VoteCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Vote
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? user = null,
    Object? post = null,
    Object? is_upvote = null,
    Object? created_at = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      user: null == user
          ? _value.user
          : user // ignore: cast_nullable_to_non_nullable
              as User,
      post: null == post
          ? _value.post
          : post // ignore: cast_nullable_to_non_nullable
              as Post,
      is_upvote: null == is_upvote
          ? _value.is_upvote
          : is_upvote // ignore: cast_nullable_to_non_nullable
              as bool,
      created_at: freezed == created_at
          ? _value.created_at
          : created_at // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }

  /// Create a copy of Vote
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $UserCopyWith<$Res> get user {
    return $UserCopyWith<$Res>(_value.user, (value) {
      return _then(_value.copyWith(user: value) as $Val);
    });
  }

  /// Create a copy of Vote
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PostCopyWith<$Res> get post {
    return $PostCopyWith<$Res>(_value.post, (value) {
      return _then(_value.copyWith(post: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$VoteImplCopyWith<$Res> implements $VoteCopyWith<$Res> {
  factory _$$VoteImplCopyWith(
          _$VoteImpl value, $Res Function(_$VoteImpl) then) =
      __$$VoteImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int id, User user, Post post, bool is_upvote, DateTime? created_at});

  @override
  $UserCopyWith<$Res> get user;
  @override
  $PostCopyWith<$Res> get post;
}

/// @nodoc
class __$$VoteImplCopyWithImpl<$Res>
    extends _$VoteCopyWithImpl<$Res, _$VoteImpl>
    implements _$$VoteImplCopyWith<$Res> {
  __$$VoteImplCopyWithImpl(_$VoteImpl _value, $Res Function(_$VoteImpl) _then)
      : super(_value, _then);

  /// Create a copy of Vote
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? user = null,
    Object? post = null,
    Object? is_upvote = null,
    Object? created_at = freezed,
  }) {
    return _then(_$VoteImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      user: null == user
          ? _value.user
          : user // ignore: cast_nullable_to_non_nullable
              as User,
      post: null == post
          ? _value.post
          : post // ignore: cast_nullable_to_non_nullable
              as Post,
      is_upvote: null == is_upvote
          ? _value.is_upvote
          : is_upvote // ignore: cast_nullable_to_non_nullable
              as bool,
      created_at: freezed == created_at
          ? _value.created_at
          : created_at // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$VoteImpl implements _Vote {
  _$VoteImpl(
      {required this.id,
      required this.user,
      required this.post,
      required this.is_upvote,
      this.created_at});

  factory _$VoteImpl.fromJson(Map<String, dynamic> json) =>
      _$$VoteImplFromJson(json);

  @override
  final int id;
  @override
  final User user;
  @override
  final Post post;
  @override
  final bool is_upvote;
  @override
  final DateTime? created_at;

  @override
  String toString() {
    return 'Vote(id: $id, user: $user, post: $post, is_upvote: $is_upvote, created_at: $created_at)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$VoteImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.user, user) || other.user == user) &&
            (identical(other.post, post) || other.post == post) &&
            (identical(other.is_upvote, is_upvote) ||
                other.is_upvote == is_upvote) &&
            (identical(other.created_at, created_at) ||
                other.created_at == created_at));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, user, post, is_upvote, created_at);

  /// Create a copy of Vote
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$VoteImplCopyWith<_$VoteImpl> get copyWith =>
      __$$VoteImplCopyWithImpl<_$VoteImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$VoteImplToJson(
      this,
    );
  }
}

abstract class _Vote implements Vote {
  factory _Vote(
      {required final int id,
      required final User user,
      required final Post post,
      required final bool is_upvote,
      final DateTime? created_at}) = _$VoteImpl;

  factory _Vote.fromJson(Map<String, dynamic> json) = _$VoteImpl.fromJson;

  @override
  int get id;
  @override
  User get user;
  @override
  Post get post;
  @override
  bool get is_upvote;
  @override
  DateTime? get created_at;

  /// Create a copy of Vote
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$VoteImplCopyWith<_$VoteImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
