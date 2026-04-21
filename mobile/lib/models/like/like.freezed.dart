// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'like.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Like _$LikeFromJson(Map<String, dynamic> json) {
  return _Like.fromJson(json);
}

/// @nodoc
mixin _$Like {
  int get id => throw _privateConstructorUsedError;
  User get user => throw _privateConstructorUsedError;
  Post? get post => throw _privateConstructorUsedError;
  Comment? get comment => throw _privateConstructorUsedError;
  DateTime? get created_at => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $LikeCopyWith<Like> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LikeCopyWith<$Res> {
  factory $LikeCopyWith(Like value, $Res Function(Like) then) =
      _$LikeCopyWithImpl<$Res, Like>;
  @useResult
  $Res call(
      {int id, User user, Post? post, Comment? comment, DateTime? created_at});

  $UserCopyWith<$Res> get user;
  $PostCopyWith<$Res>? get post;
  $CommentCopyWith<$Res>? get comment;
}

/// @nodoc
class _$LikeCopyWithImpl<$Res, $Val extends Like>
    implements $LikeCopyWith<$Res> {
  _$LikeCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? user = null,
    Object? post = freezed,
    Object? comment = freezed,
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
      post: freezed == post
          ? _value.post
          : post // ignore: cast_nullable_to_non_nullable
              as Post?,
      comment: freezed == comment
          ? _value.comment
          : comment // ignore: cast_nullable_to_non_nullable
              as Comment?,
      created_at: freezed == created_at
          ? _value.created_at
          : created_at // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $UserCopyWith<$Res> get user {
    return $UserCopyWith<$Res>(_value.user, (value) {
      return _then(_value.copyWith(user: value) as $Val);
    });
  }

  @override
  @pragma('vm:prefer-inline')
  $PostCopyWith<$Res>? get post {
    if (_value.post == null) {
      return null;
    }

    return $PostCopyWith<$Res>(_value.post!, (value) {
      return _then(_value.copyWith(post: value) as $Val);
    });
  }

  @override
  @pragma('vm:prefer-inline')
  $CommentCopyWith<$Res>? get comment {
    if (_value.comment == null) {
      return null;
    }

    return $CommentCopyWith<$Res>(_value.comment!, (value) {
      return _then(_value.copyWith(comment: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$LikeImplCopyWith<$Res> implements $LikeCopyWith<$Res> {
  factory _$$LikeImplCopyWith(
          _$LikeImpl value, $Res Function(_$LikeImpl) then) =
      __$$LikeImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int id, User user, Post? post, Comment? comment, DateTime? created_at});

  @override
  $UserCopyWith<$Res> get user;
  @override
  $PostCopyWith<$Res>? get post;
  @override
  $CommentCopyWith<$Res>? get comment;
}

/// @nodoc
class __$$LikeImplCopyWithImpl<$Res>
    extends _$LikeCopyWithImpl<$Res, _$LikeImpl>
    implements _$$LikeImplCopyWith<$Res> {
  __$$LikeImplCopyWithImpl(_$LikeImpl _value, $Res Function(_$LikeImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? user = null,
    Object? post = freezed,
    Object? comment = freezed,
    Object? created_at = freezed,
  }) {
    return _then(_$LikeImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      user: null == user
          ? _value.user
          : user // ignore: cast_nullable_to_non_nullable
              as User,
      post: freezed == post
          ? _value.post
          : post // ignore: cast_nullable_to_non_nullable
              as Post?,
      comment: freezed == comment
          ? _value.comment
          : comment // ignore: cast_nullable_to_non_nullable
              as Comment?,
      created_at: freezed == created_at
          ? _value.created_at
          : created_at // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$LikeImpl implements _Like {
  _$LikeImpl(
      {required this.id,
      required this.user,
      this.post,
      this.comment,
      this.created_at});

  factory _$LikeImpl.fromJson(Map<String, dynamic> json) =>
      _$$LikeImplFromJson(json);

  @override
  final int id;
  @override
  final User user;
  @override
  final Post? post;
  @override
  final Comment? comment;
  @override
  final DateTime? created_at;

  @override
  String toString() {
    return 'Like(id: $id, user: $user, post: $post, comment: $comment, created_at: $created_at)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LikeImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.user, user) || other.user == user) &&
            (identical(other.post, post) || other.post == post) &&
            (identical(other.comment, comment) || other.comment == comment) &&
            (identical(other.created_at, created_at) ||
                other.created_at == created_at));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, user, post, comment, created_at);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$LikeImplCopyWith<_$LikeImpl> get copyWith =>
      __$$LikeImplCopyWithImpl<_$LikeImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$LikeImplToJson(
      this,
    );
  }
}

abstract class _Like implements Like {
  factory _Like(
      {required final int id,
      required final User user,
      final Post? post,
      final Comment? comment,
      final DateTime? created_at}) = _$LikeImpl;

  factory _Like.fromJson(Map<String, dynamic> json) = _$LikeImpl.fromJson;

  @override
  int get id;
  @override
  User get user;
  @override
  Post? get post;
  @override
  Comment? get comment;
  @override
  DateTime? get created_at;
  @override
  @JsonKey(ignore: true)
  _$$LikeImplCopyWith<_$LikeImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
